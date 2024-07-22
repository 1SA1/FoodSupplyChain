// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FoodSupplyChain.sol";

contract Consumer {
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

    function verifyFood (
        string memory _name, 
        uint256 _lotNumber, 
        address _Food
        ) public returns(bool) {
        
        return supplyChain.verifyFood(
            _name,
            _lotNumber,
            _Food
            );
    }

    //Purchase Food from Food
    function purchaseFood(
        string memory _name,
        uint256 _lotNumber,
        uint256 _quantity,
        address _Food
    ) public {
        require(
            _quantity > 0, 
            "Invalid Purchase Quantity"
        );

        supplyChain.purchaseFromFood(
            _name,
            _lotNumber,
            _quantity,
            _Food
            );
    }

    //sendReturnRequest to Foodby Consumer
    function returnFood (
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
            _Food!=address(0),
            "Invalid FoodAddress"
        );

        supplyChain.sendReturnRequest(
            _name, 
            _lotNumber, 
            _quantity, 
            _Food
            );
    }
    //No Need here because Approval will be done at time of purchase for the exact amount of tokens
    // function approveContract(uint256 _amount) public {
    //     supplyChain.approveContract(_amount);
    // }
}