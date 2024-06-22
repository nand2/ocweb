// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IDecentralizedApp.sol";

contract ResourceRequestWebsite is IDecentralizedApp {

    // Indicate we are serving a website with the resource request mode
    function resolveMode() external pure returns (bytes32) {
        return "5219";
    }

    /**
     * Hook to override
     * Return an answer to a web3:// request
     * @return statusCode The HTTP status code to return. Returns 0 if you do not wish to
     *                    return an answer to this request.
     * @return body The body of the response
     * @return headers The headers of the response
     * @return internalRedirectResource An internal redirect to another resource. 
     *                                  Mutually exclusive with statusCode, body and headers.
     * @return internalRedirectParams Parameters to pass to the internal redirect
     */
    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal virtual view returns (uint statusCode, string memory body, KeyValue[] memory headers, string[] memory internalRedirectResource, KeyValue[] memory internalRedirectParams) {
        return (0, "", new KeyValue[](0), new string[](0), new KeyValue[](0));
    }
        

    // Implementation for the ERC-5219 resource request mode
    function request(string[] memory resource, KeyValue[] memory params) external view returns (uint statusCode, string memory body, KeyValue[] memory headers) {

        // Call the hook to process the request
        uint internalRedirectCount = 0;
        uint _statusCode;
        string memory _body;
        KeyValue[] memory _headers;
        string[] memory _internalRedirect;
        KeyValue[] memory _internalRedirectParams;
        do {
            (_statusCode, _body, _headers, _internalRedirect, _internalRedirectParams) = _processWeb3Request(resource, params);
            if(_statusCode != 0) {
                return (_statusCode, _body, _headers);
            }
            if(_internalRedirect.length > 0) {
                resource = _internalRedirect;
                params = _internalRedirectParams;
                internalRedirectCount++;
            }
            if(internalRedirectCount > 10) {
                return (500, "Internal redirect loop", new KeyValue[](0));
            }
        } while(_internalRedirect.length > 0);

        // Default: Returning 404
        statusCode = 404;
    }
}