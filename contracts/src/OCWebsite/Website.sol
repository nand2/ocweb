// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IDecentralizedApp.sol";

contract Website is IDecentralizedApp {

    // Indicate we are serving a website with the resource request mode
    function resolveMode() external pure returns (bytes32) {
        return "5219";
    }

    /**
     * Hook to override
     * Return an answer to a web3:// request before the static frontend is served
     * @return statusCode The HTTP status code to return. Returns 0 if you do not wish to
     *                    process the call
     */
    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal virtual view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
        return (0, "", new KeyValue[](0));
    }
        

    // Implementation for the ERC-5219 resource request mode
    function request(string[] memory resource, KeyValue[] memory params) external view returns (uint statusCode, string memory body, KeyValue[] memory headers) {

        // Call the hook to process the request
        uint _statusCode;
        string memory _body;
        KeyValue[] memory _headers;
        (_statusCode, _body, _headers) = _processWeb3Request(resource, params);
        if(_statusCode != 0) {
            return (_statusCode, _body, _headers);
        }

        // Default: Returning 404
        statusCode = 404;
    }
}