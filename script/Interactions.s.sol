//SPDX-License-Identifier:MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    uint256 SEND_VALUE = 0.1 ether;

     function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        // Call the fund() function on the FundMe contract and send 0.1 ETH along with it
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        // Log a confirmation message to the terminal showing the amount sent
        console.log("Funded FundMe with %s", SEND_VALUE);
    }
    function run() external {
        //Get the address of the latest deployed FundMe contract on the current chain and assign it to mostRecentlyDeployed addr
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        //Call the funding function using the retrieved address
        fundFundMe(mostRecentlyDeployed);

    }

}

contract WithdrawFundMe is Script {

    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        // Call the withdraw() function on the FundMe contract to transfer its balance to the owner
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        // Log a message to confirm withdrawal was executed
        console.log("Withdraw FundMe balance!");
    }

    function run() external {
        // Get the address of the latest deployed FundMe contract on the current chain and assign it to 
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        // Call the withdrawal function using the retrieved address
        withdrawFundMe(mostRecentlyDeployed);
    }

}