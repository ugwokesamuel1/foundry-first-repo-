// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {Test, console} from "forge-std/Test.sol";

contract InteractionsTest is Test {
    FundMe public fundMe;
    DeployFundMe deployFundMe;

    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    address alice = makeAddr("alice");

    function setUp() external {
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        //Set the ETH balance of the address alice to STARTING_USER_BALANCE
        vm.deal(alice, STARTING_USER_BALANCE);
    }

    function testUserCanFundAndOwnerWithdraw() public {
        //Store the current ETH balance of alice in the variable preUserBalance
        uint256 preUserBalance = address(alice).balance;
        //Get the current ETH balance of the owner of the FundMe contract, and store it in preOwnerBalance
        uint256 preOwnerBalance = address(fundMe.getOwner()).balance;

        // Using vm.prank to simulate funding from the USER address
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        // Call the withdrawFundMe function on the WithdrawFundMe contract, 
        // passing in the address of the FundMe contract so it can perform a withdrawal.
        withdrawFundMe.withdrawFundMe(address(fundMe));

        uint256 afterUserBalance = address(alice).balance;
        uint256 afterOwnerBalance = address(fundMe.getOwner()).balance;

        //Check that the FundMe contract’s ETH balance is now zero
        assert(address(fundMe).balance == 0);
        //Check that the user’s balance after funding, plus the amount they sent, equals their original balance.
        assertEq(afterUserBalance + SEND_VALUE, preUserBalance);
        //Check that the contract owner's balance increased by exactly SEND_VALUE
        assertEq(preOwnerBalance + SEND_VALUE, afterOwnerBalance);
    }
}