// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    DeployFundMe deployFundMe;
    address alice = makeAddr("alice");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(alice, STARTING_BALANCE);
    }

    function testMinimumUsd() external view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }
    function testOwnerIsMsgSender() public view {
    assertEq(fundMe.getOwner(), msg.sender);
        // assertEq(fundMe.i_owner(), msg.sender);    // ❌ will fail
        // Because:msg.sender here is not address(this) — it's a random Foundry test address
        // But address(this) is still the test contract — the deployer — the owner ✅
    }
        // Yes. `address(this)` became the owner because it called `new FundMe()`, 
        // making it the `msg.sender` inside the constructor. 
        // Since `msg.sender` is the deployer, and the constructor sets `i_owner = msg.sender`,
        // `address(this)` became the owner.
    function testPriceFeedVersionIsAccurate() public view {
    uint256 version = fundMe.getVersion();
    if (block.chainid == 1) {
        // Mainnet
        assertEq(version, 6);
    } else if (block.chainid == 11155111) {
        // Sepolia
        assertEq(version, 4);
    } else {
        // Local mock or default
        assertEq(version, 4);
    }
    }
    function testFundFailsWithoutEnoughETH() public {
       vm.expectRevert(); //The next line after this one should revert! if not test fails 
        fundMe.fund(); //we send 0 value
    }
    // Test whether the fund() function properly updates the internal mapping that keeps track of who funded how much.
    function testFundUpdatesFundDataStructure() public {
    vm.prank(alice);
    fundMe.fund{value: SEND_VALUE}();
    uint256 amountFunded = fundMe.getAddressToAmountFunded(alice);
    assertEq(amountFunded, SEND_VALUE);
    }
    // Test That the fund() function:
        // Adds new funders to an array (funders) when they send ETH.
        // Keeps the order and uniqueness of funders intact (assuming you prevent duplicates elsewhere).
    function testAddsFunderToArrayOfFunders() public {
    vm.startPrank(alice);
    fundMe.fund{value: SEND_VALUE}();
    vm.stopPrank();
    address funder = fundMe.getFunder(0);
    assertEq(funder, alice);
    }

    modifier funded() {
    vm.prank(alice);
    fundMe.fund{value: SEND_VALUE}();
    assert(address(fundMe).balance > 0);
    _;
    }
    // Tests that only owner can withraw
    function testOnlyOwnerCanWithdraw() public funded {
    vm.expectRevert();
    fundMe.withdraw();
    }
    // Tests that owner can withraw
    function testWithdrawFromASingleFunder() public funded {
    //Arrange: Set up the test by initializing variables, and objects and prepping preconditions.

        // check the initial balance of the owner and the initial balance of the contract.
    uint256 startingFundMeBalance = address(fundMe).balance;
    uint256 startingOwnerBalance = fundMe.getOwner().balance;

    vm.txGasPrice(GAS_PRICE);
    uint256 gasStart = gasleft();

    //Act: Perform the action to be tested like a function invocation.
    vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    vm.stopPrank();

    uint256 gasEnd = gasleft();
    uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
    console.log("Withdraw consumed: %d gas", gasUsed);

    //Assert: Compare the received output with the expected output.
    uint256 endingFundMeBalance = address(fundMe).balance;
    uint256 endingOwnerBalance = fundMe.getOwner().balance;
    assertEq(endingFundMeBalance, 0);
    assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 1;
    for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
        // we get hoax from stdcheats
        // prank + deal
        hoax(address(i), SEND_VALUE); // Give address(i) some ETH and Make address(i) the msg.sender for the next call
        fundMe.fund{value: SEND_VALUE}();
    }
    uint256 startingFundMeBalance = address(fundMe).balance;
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    vm.stopPrank();
    assert(address(fundMe).balance == 0);
    assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }
    function testCheapWithdrawFromMultipleFunders() public funded {
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 1;
    for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
        // we get hoax from stdcheats
        // prank + deal
        hoax(address(i), SEND_VALUE); // Give address(i) some ETH and Make address(i) the msg.sender for the next call
        fundMe.fund{value: SEND_VALUE}();
    }
    uint256 startingFundMeBalance = address(fundMe).balance;
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    vm.stopPrank();
    assert(address(fundMe).balance == 0);
    assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
}


}