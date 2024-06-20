// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        owner = _newOwner;
    }
}