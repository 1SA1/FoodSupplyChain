// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./FoodSupplyChain.sol";

contract Distributor {
    FoodSupplyChain public supplyChain;

    constructor(address _supplyChainAddress) {
        supplyChain = FoodSupplyChain(_supplyChainAddress);
    }

    function purchaseTokens(
        uint _amount
        ) public payable {
        require(
            msg.value ==_amount && _amount != 0,
            "Purchase Amount not Correct"
            );

        supplyChain.purchaseTokens{value: msg.value}(_amount);
    }

    function sellTokens(
        uint _amount
        ) public {
        require(
            _amount > 0,
            "Sell Token Amount not Correct"
            );
        supplyChain.withDraw(_amount);
    }

    //Purchase Food from Manufacturer
    function purchaseFood(
        string memory _name,
        uint256 _lotNumber
    ) public {
        supplyChain.purchaseFoodLot(
            _name,
            _lotNumber
            );
    }

    //sendReturnRequest to Manufacturer by Distributor
    function returnFood (
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity
    ) public {
        require(
            _quantity > 0, 
            "Invalid Return Quantity"
        );

        supplyChain.sendReturnRequest(
            _name, 
            _lotNumber, 
            _quantity, 
            supplyChain.owner()
            );
    }

    function acceptReturn (
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity, 
        address _Food
    ) public {
        require(
            _quantity > 0,
            "Invalid Return Quantity"
        );

        require(
            _Food!= address(0),
            "Invalid Return Consumer Address"
        );

          supplyChain.returnFoodbyDistributor(
            _name, 
            _lotNumber, 
            _quantity, 
            _Food
            );  

    }

    function addFood(
        address _Food
        ) public {

       supplyChain.addValidFood(_Food);
    }
    
}