// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IDecentralizedApp.sol";

contract ResourceRequestWebsite is IDecentralizedApp {

    // Indicate we are serving a website with the resource request mode
    function resolveMode() external pure returns (bytes32) {
        return "5219";
    }
        

    // Implementation for the ERC-5219 resource request mode
    function request(string[] memory resource, KeyValue[] memory params) external virtual view returns (uint statusCode, string memory body, KeyValue[] memory headers) {

        // Default: Returning 404
        statusCode = 404;
    }
}