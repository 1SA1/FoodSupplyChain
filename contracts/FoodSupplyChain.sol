// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./FoodToken.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ReentrancyGuard.sol";

contract FoodSupplyChain is ReentrancyGuard , AccessControl {
    address public owner;
    // Linking ERC20 token
    FoodToken public tokenContract;
    address immutable tokenCOntractAddress;
    // Define roles

    //Food Category
    enum Category {
        Snack,
        Gourmet,
        Organic,
        Dietary
    }
    // Define a struct for a Food
    struct Food {
        Category cat; 
        uint256 quantity; // will reamin fixed after lot is manufactured
        uint256 cirSupply;
        bool cirSuply;
        uint256 totalDistQty; //added cumulative sum for all distributor
        uint256 totalPharmQty; //added cumulative sum for all Pharm
        uint256 totalSoldQty; //added cumulative sum for total sold
        uint256 price;
        uint256 dateOfProduction; //added
        uint256 dateOfExpiry; // added
        mapQuantity qty; // to maintain Food qty for dist, Foodand consumer
    }
    //added structure to be used in mapQuantity
    struct medQuantity {
        uint256 medPurchased;
        uint256 medSold;
    }

    //this mapping will be needed for purchase and return Foods function
    struct mapQuantity {
        mapping(address => medQuantity) distributorQuantity;
        mapping(address => medQuantity) FoodQuantity;
        mapping(address => uint256) consumerQuantity;
    }

    // Define a mapping for Foods --- name => Food -- Updated
    mapping(string => mapping(uint256 => Food)) Foods;

    //mapping for return requests
    mapping (string => mapping(uint256 =>mapping (address => mapping (address => mapping (uint256 => bool))))) returnMedStatus; 
    //medName=>lotNumber=>addressOfRequestor=>addressOfReturnee=>quantityofReturn=>Status
    

    
    //Roles - for Access Control
    bytes32 public constant Manufacturer = keccak256("Manufacturer");
    bytes32 public constant Distributor = keccak256("Distributor");
    bytes32 public constant Food1 = keccak256("Food");


    uint256 minimumLotQuantity = 1000;
    // Constructor
    constructor(address _tokenAddress) {
        owner = msg.sender;
        _grantRole(Manufacturer, owner);
        tokenCOntractAddress = _tokenAddress;  
        // Initialize the token, adjust the parameters as needed
        tokenContract =  FoodToken(_tokenAddress);
    }

    // Function to mint tokens (only manufacturer can do this)
    function mintTokens(uint256 _amount)
        public 
        onlyManufacturer() {
            uint _approveAmount = _amount + tokenContract.getBalance();
            tokenContract.approve(_approveAmount);
            tokenContract.mint(owner, _amount);
    }

    // Function to purchase tokens (pays in wei) 
    //Anyone can buy tokens - eth will be tranferred to contract
    function purchaseTokens(uint256 _amount) public payable {
        require(
            msg.value == _amount && _amount != 0, 
            "Incorrect payment amount"
        );

        require(
            tx.origin != owner,
            "Owner cannot purchase tokens he already owns"
        );
        // Transfer tokens from manufacturer to distributor
        tokenContract.transferFrom(owner, tx.origin, _amount);
    }

    //this functions enables distributor, Foodand consumer to sell their tokens to owner
    //the eth will be held in contract which will be transferred to called
    //the token selling amount will be transfered to owner
    function withDraw (uint256 _amount) external nonReentrant {
        require(
            tx.origin != owner, 
            "Owner Cannot withdraw funds from Contract"
        );

        require(
            msg.sender != address(this), 
            "Cannot transfer Ether to the contract itself"
        );

        require(
            address(this).balance >= _amount, 
            "Insufficient Funds in Contract"
        );

        require(
            _amount != 0, 
            "Invalid withdrawl Amount"
        );

        require(
            tokenContract.balanceOf(tx.origin) >= _amount,
            "Not enough tokens to Sell"
        );

        // Transfer tokens from manufacturer to distributor
        tokenContract.approve(_amount);
        tokenContract.transferFrom(tx.origin, owner, _amount); // transfer tokens to owner i.e. Manufacturer
        payable(tx.origin).transfer(_amount); //pay ether to caller address from contract
        tokenContract.approve(0);
    }

    // Modifier to check role
    modifier onlyManufacturer() {
        require(
            hasRole(Manufacturer,tx.origin), 
            "Restricted to Manufacturer"
        );
        _;
    }

    modifier onlyDistributor() {
        require(
            hasRole(Distributor, tx.origin), 
            "Restricted to Distributor"
        );
        _;
    }
    modifier onlyFood() {
        require(
            hasRole(Food1, tx.origin), 
            "Restricted to Food"
        );
        _;
    }
    modifier onlyConsumer() {
        require(!
            hasRole(Food1, tx.origin) && !hasRole(Distributor, tx.origin) && !hasRole(Manufacturer,tx.origin), 
            "Only Consumer can buy Food From Food"
        );
        _;
    }

    // Add Food
    //date of production and expiry will be sent in seconds from frontEnd
    function addFood(
        string memory _name,
        uint256 _lotNumber,
        uint8 _cat,
        uint256 _quantity,
        uint256 _price,
        uint256 _dateOfProduction,
        uint256 _dateofExpiry
    ) public onlyManufacturer() {

        //add check if this lot is not already added
         Food storage med = Foods[_name][_lotNumber];
        require(
            _dateofExpiry >= _dateOfProduction && _price > 0,
            "Invalid Expiry/Production Date or Unit Price of Food"
        );

        require(
            _quantity >= minimumLotQuantity,
            "Food Quanity for Lot Not Valid / Minimum is 1000"
        );

        require(
            med.quantity == 0,
            "Lot Already Added"
        );

        Category c;
        if (_cat==0)
            c = Category.Snack;
        else if(_cat==1)
            c = Category.Gourmet;
        else if(_cat==2)
            c = Category.Organic;
        else if(_cat==3)
            c = Category.Dietary;
        
        Foods[_name][_lotNumber].cat = c;
        Foods[_name][_lotNumber].quantity = _quantity;
        Foods[_name][_lotNumber].cirSupply = 0;
        Foods[_name][_lotNumber].cirSuply=false;
        Foods[_name][_lotNumber].totalDistQty = 0;
        Foods[_name][_lotNumber].totalPharmQty = 0;
        Foods[_name][_lotNumber].totalSoldQty = 0;
        Foods[_name][_lotNumber].price = _price;
        Foods[_name][_lotNumber].dateOfProduction = _dateOfProduction;
        Foods[_name][_lotNumber].dateOfExpiry = _dateofExpiry;
      
    }

    // Destroy Food only Manufacturer can call
    //this can be called in case of returned meds which are expired
    function destroyFood(
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity
    ) public onlyManufacturer() {
        
        require (
            _quantity != 0,
            "Invalid Quantity to Destroy"
        );
        Food storage med = Foods[_name][_lotNumber];
        require(
            med.quantity - (med.cirSupply + med.totalSoldQty) >= _quantity,
            "Not enough quantity to destroy"
        ); //updated

        med.quantity -= _quantity;
    
    }
    

    // Distributor Purchase Food from Manufacturer 
    //Assumption Distributor purchase whole lot from manufacturer
    function purchaseFoodLot(
        string memory _name,
        uint256 _lotNumber
    ) public  onlyDistributor() {
        Food storage med = Foods[_name][_lotNumber];
        require(
            med.quantity != med.cirSupply,
            "Food not available in mentioned Lot"
        );

        //FRONTEND check if lot number and med exists
        uint256 totalPrice = med.price * med.quantity;
        Foods[_name][_lotNumber].cirSuply=true;
        med.cirSupply += med.quantity;
        med.totalDistQty = med.quantity; //conmulative sum of qty purchased by all distributors
        med.qty.distributorQuantity[tx.origin].medPurchased =med.quantity; //update distributor quantity
        //distributor has to approve contract first to transfer to owner
        tokenContract.approve(totalPrice);
        tokenContract.transferFrom(tx.origin, owner, totalPrice);// Transfer tokens to Manufacturer
        tokenContract.approve(0);
      
    }

    // FoodPurchase Food from distributor
    function purchaseFromDistributor(
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity,
        address _distributor
    ) public onlyFood() {
        require(
            hasRole(Distributor,_distributor), 
            "Invalid distributor"
        );

        Food storage med = Foods[_name][_lotNumber];
        uint256 DistQuantity = med.qty.distributorQuantity[_distributor].medPurchased-med.qty.distributorQuantity[_distributor].medSold;
        require(
             DistQuantity >= _quantity && _quantity != 0,
            "Not enough quantity with Distributor / Invalid Quantity"
        );

        uint256 totalPrice = med.price * _quantity;
        med.qty.distributorQuantity[_distributor].medSold += _quantity;
        med.qty.FoodQuantity[tx.origin].medPurchased += _quantity; //update distributor quantity
        med.totalPharmQty += _quantity;
        med.totalDistQty -= _quantity;
        tokenContract.approve(totalPrice);
        tokenContract.transferFrom(tx.origin, _distributor, totalPrice); // Transfer tokens to distributer
        tokenContract.approve(0);
  
    }

    // Customer Purchase Food from Foodusing tokens
    function purchaseFromFood(
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity,
        address _Food
    )  external onlyConsumer() {
        require(
            hasRole(Food1, _Food),
            "Invalid Food"
        );

        Food storage med = Foods[_name][_lotNumber];
        require(
            verifyFood(_name,_lotNumber,_Food),
            "Food not Verifed"
        );

        uint256 PharmQuantity = med.qty.FoodQuantity[_Food].medPurchased - med.qty.FoodQuantity[_Food].medSold;
        require(
              PharmQuantity >= _quantity && _quantity != 0,
            "Not enough quantity to purchase from Food/ Invalid Quantity"
        );

        uint256 totalPrice = med.price * _quantity;
        med.cirSupply -= _quantity; // updated
        med.qty.FoodQuantity[_Food].medSold += _quantity; //update Foodquantity
        med.qty.consumerQuantity[tx.origin] += _quantity; //Update consumer quantity - can be used for returns
        med.totalSoldQty += _quantity;
        med.totalPharmQty -= _quantity;
        //Transfer will be called but we might face issue here
        //if tranferFrom is called then we need to authorize contract first to trnasfer the token on msg.sender behalf
        tokenContract.approve(totalPrice);
        tokenContract.transferFrom(tx.origin, _Food, totalPrice); // Transfer tokens from customer to Food
        tokenContract.approve(0);
      
    }

    // LOT EXPIRE CHECK, LOT AVAILABILITY CHECK
    //Verify Food
    function verifyFood(
        string memory _name,
        uint256 _lotNumber,
        address _Food
    ) public returns (bool) {
        Food storage med = Foods[_name][_lotNumber];
        bool check = true;
        string memory mesg = "Not Verified";
        if (med.dateOfExpiry >= block.timestamp) {
            mesg = "Food in this Lot are Expired";
            check = false;
        }
        else if(Foods[_name][_lotNumber].cirSuply == false){
            mesg = "Food in this Lot is not in Circulation Yet";//not purchased by distributor
            check = false;
        }
        else if (med.cirSupply == 0) {
            mesg = "Food in this Lot in no Longer in Circulating Supply";//sold all to consumers
            check = false;
        }
        else if (med.qty.FoodQuantity[_Food].medPurchased - med.qty.FoodQuantity[_Food].medSold == 0) {
            mesg = "Food Stock not available at Mentioned Food";
            check = false;
        }
      
        return check;
    }

    
    // Return Food by Distributor
    //Manufacturer can call this function after verification of returned  by distributor
    function returnFoodbyManufacturer (
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity,
        address _distributor
    ) public onlyManufacturer() {

        require(
            hasRole(Distributor, _distributor), 
            "Invalid Distributor"
        );

        //    //medName=>lotNumber=>addressOfRequestor=>addressOfReturnee=>quantityofReturn=>Status
        require(
            returnMedStatus[_name][_lotNumber][_distributor][owner][_quantity], 
            "No Return Request Found"
        );

        Food storage med = Foods[_name][_lotNumber];
        require(
            med.qty.distributorQuantity[_distributor].medPurchased - med.qty.distributorQuantity[_distributor].medSold  >= _quantity,
            "Return Quantity Not Valid"
        );

        uint totalPrice = _quantity * med.price;
        
        med.cirSupply += _quantity;
        med.totalDistQty -= _quantity;

        med.qty.distributorQuantity[_distributor].medPurchased -= _quantity;
        tokenContract.transferFrom(owner, _distributor, totalPrice);
        delete returnMedStatus[_name][_lotNumber][_distributor][owner][_quantity];
      
    }

    // Accept return by Food
    //Only distributor can call this function after verification of returned Food by Food
    function returnFoodbyDistributor(
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity, 
        address _Food
    ) public  onlyDistributor() {
        require(
            returnMedStatus[_name][_lotNumber][_Food][tx.origin][_quantity], 
            "No Return Request Found"
        );

        Food storage med = Foods[_name][_lotNumber];
        uint256 totalQuantity = med.qty.FoodQuantity[_Food].medPurchased - med.qty.FoodQuantity[_Food].medSold;
        require (
            hasRole(Food1,_Food),
            "FoodAddress not Valid"
        );

        require(
            totalQuantity >= _quantity,
            "Invalid Return Quantity / Not enough quantity to Return"
        );
        
        uint totalPrice = _quantity * med.price;
      
        med.qty.distributorQuantity[tx.origin].medPurchased += _quantity;
        med.qty.distributorQuantity[tx.origin].medSold -= _quantity;
        med.qty.FoodQuantity[_Food].medPurchased -= _quantity;

        med.totalDistQty += _quantity;
        med.totalPharmQty -= _quantity;
        delete returnMedStatus[_name][_lotNumber][_Food][tx.origin][_quantity];
        tokenContract.approve(totalPrice);
        //there will be issue in transfer from here
        tokenContract.transferFrom(tx.origin, _Food, totalPrice);
        tokenContract.approve(0);
        
        
    }

    // Accept return by Consumer Food
    //Only Foodcan call this function after verification of returned Food by consumer
    function returnFoodbyFood(
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity, 
        address _consumer
    ) public onlyFood() {

        require(
            returnMedStatus[_name][_lotNumber][_consumer][tx.origin][_quantity], 
            "No Return Request Found"
        );

        Food storage med = Foods[_name][_lotNumber];
        require(
            med.qty.consumerQuantity[_consumer] >= _quantity && _quantity != 0,
            "Invalid Return Quantity by Consumer"
        );

        require (
            hasRole(Food1,tx.origin),
            "FoodAddress not Valid"
        );

        uint totalPrice = _quantity * med.price;
        
        med.qty.FoodQuantity[tx.origin].medPurchased += _quantity;
        med.qty.FoodQuantity[tx.origin].medSold -= _quantity;
        med.qty.consumerQuantity[_consumer] -= _quantity;
        
        med.totalPharmQty += _quantity;
        med.totalSoldQty -= _quantity;
        delete returnMedStatus[_name][_lotNumber][_consumer][tx.origin][_quantity];
        tokenContract.approve(totalPrice);
        //again transfer from issue here
        tokenContract.transferFrom(tx.origin, _consumer, totalPrice);
        tokenContract.approve(0);
        
       
    }
    
    // Add valid distributor
    function addValidDistributor(address _distributor)
        external
        onlyManufacturer()
    {
        require(
            _distributor != address(0),
            "Distributor Address Invalid"
        );
        _grantRole(Distributor, _distributor);
   
    }

    //         // Add valid Food
    function addValidFood(address _Food)
        public
        onlyDistributor()
    {
        require(
            _Food!= address(0),
            "FoodAddress Invalid"
        );
        _grantRole(Food1, _Food);
       
    }

    // function approveContract(uint256 _amount) public {
    //     tokenContract.approve(_amount);
    // }
    //Additional function to get stats of particular Food quantity
    //it will return meds quantity for whoever is calls this function
    function getFoodCount(string memory _name, uint256 _lotNumber) public view returns(uint256 qty) {
        Food storage med = Foods[_name][_lotNumber];
        uint256 quantity;
        if(tx.origin == owner) {
            quantity = med.quantity - med.totalDistQty;
            return quantity;
        }
        else if(hasRole(Distributor, tx.origin)) {
            quantity = med.qty.distributorQuantity[tx.origin].medPurchased - med.qty.distributorQuantity[tx.origin].medSold;
           return quantity;
        }
        else if (hasRole(Food1,tx.origin)) {
            quantity = med.qty.FoodQuantity[tx.origin].medPurchased - med.qty.FoodQuantity[tx.origin].medSold;
            return quantity;
        }
        else {
            return med.qty.consumerQuantity[tx.origin];
        }
    }

    //Create Return Request
    function sendReturnRequest(string memory _name, uint256 _lotNumber, uint256 _quantity, address _retAddress) public  {
        Food storage med = Foods[_name][_lotNumber];
        require(
            tx.origin != owner,
            "Manufacturer Cannot Send Return Request"
        );

        require(
            !(returnMedStatus[_name][_lotNumber][tx.origin][_retAddress][_quantity]), 
            "Cannot Add multiple Return Requests at one time  to same Party, Wait till previous is accepted"
        );
            
        if(hasRole(Distributor, tx.origin)) {
            require(
                _retAddress==owner,
                "Return Adddress not Valid"
            );

            require(
                med.qty.distributorQuantity[tx.origin].medPurchased - med.qty.distributorQuantity[tx.origin].medSold  >= _quantity,
                "Return Quantity Not Valid by Distributor"
            );
        
            returnMedStatus[_name][_lotNumber][tx.origin][owner][_quantity] = true;
        }
        else if (hasRole(Food1,tx.origin)) {
            require(
                hasRole(Distributor, _retAddress) && med.qty.distributorQuantity[_retAddress].medPurchased > _quantity, 
                "Return Distributor Adddress not Valid / Distributor Didn't sold the selected Quantity"
            );
            
            uint256 totalQuantity = med.qty.FoodQuantity[tx.origin].medPurchased - med.qty.FoodQuantity[tx.origin].medSold;
            
            require(
                totalQuantity >= _quantity,
                "Invalid Return Quantity by Food"
            );

            returnMedStatus[_name][_lotNumber][tx.origin][_retAddress][_quantity] = true;
        }
        else {

            require(
                hasRole(Food1,_retAddress) && 
                med.qty.FoodQuantity[_retAddress].medPurchased >= _quantity,
                "Return FoodAdddress not Valid / FoodDidn't sold the selected Quantity"
            );
            
            require(
                med.qty.consumerQuantity[tx.origin] >= _quantity,
                "Invalid Return Quantity by Consumer"
            );
            
            returnMedStatus[_name][_lotNumber][tx.origin][_retAddress][_quantity] = true;
        }
    }
}