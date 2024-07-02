// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ownable {
    address public owner;

    error Unauthorized();
    error InvalidNewOwner();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        if(_newOwner == address(0)) {
            revert InvalidNewOwner();
        }

        owner = _newOwner;
    }
}