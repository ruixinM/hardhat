// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract EthCallTest{
    function caller() public view returns (address) {
        return msg.sender;
    }
}