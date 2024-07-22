// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./FoodSupplyChain.sol";
import "./FoodToken.sol";

contract Manufacturer {
    FoodSupplyChain public supplyChain;
    FoodToken public token;

    constructor(address _supplyChainAddress) {
        supplyChain = FoodSupplyChain(_supplyChainAddress);
    }

    function mintTokens(uint _amount)  public {
        require(
            _amount>0, 
            "INvalid Token Amount"
            );
            
        supplyChain.mintTokens(_amount);
    }

    function addFood(
        string memory _name,
        uint256 _lotNumber,
        uint8 _cat,
        uint256 _quantity,
        uint256 _price,
        uint256 _dateOfProduction,
        uint256 _dateofExpiry ) public {

        supplyChain.addFood(
            _name, 
            _lotNumber,
            _cat, 
            _quantity, 
            _price,
            _dateOfProduction,
            _dateofExpiry
        );
    }

      function destroyMed(
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity
        )  public {
       supplyChain.destroyFood(_name, _lotNumber, _quantity);
    }

    function acceptReturn (
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity, 
        address _distributor
    ) public {
        require(
            _quantity > 0,
            "Invalid Return Quantity"
        );

        require(
            _distributor != address(0),
            "Invalid Return Consumer Address"
        );

          supplyChain.returnFoodbyManufacturer(
            _name, 
            _lotNumber, 
            _quantity, 
            _distributor
            );  

    }


     function addValidDistributor(address _address) public {
        supplyChain.addValidDistributor(_address);
    }
}