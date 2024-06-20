// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IFrontendLibrary.sol";

import "./Website.sol";

contract StaticWebsite is Website {

    IFrontendLibrary public frontendLibrary;
  
    constructor(IFrontendLibrary _frontendLibrary) {
        frontendLibrary = _frontendLibrary;
    }

    function getFrontendLibrary() public view virtual returns (IFrontendLibrary) {
        return frontendLibrary;
    }

    /**
     * Hook to override
     * Get the index of the frontend version to use.
     */
    function _getLiveFrontendVersionIndex() internal virtual view returns (uint256) {
        return frontendLibrary.getDefaultFrontendIndex();
    }

    function getLiveFrontendVersion() public view returns (FrontendFilesSet memory) {
        return frontendLibrary.getFrontendVersion(_getLiveFrontendVersionIndex());
    }


    //
    // web3:// protocol
    //

    /**
     * Hook to override
     * Static frontend serving: For a given web3:// request, compute the file path of 
     * the requested static asset to serve
     */
    function _getStaticFrontendAssetFilePathForRequest(string[] memory resource, KeyValue[] memory params) internal virtual view returns (string memory filePath) {
        if(resource.length == 0) {
            filePath = "index.html";
        }
        else {
            for(uint i = 0; i < resource.length; i++) {
                if(i > 0) {
                    filePath = string.concat(filePath, "/");
                }
                filePath = string.concat(filePath, resource[i]);
            }
        }
    }

    /**
     * Return an answer to a web3:// request after the static frontend is served
     * @return statusCode The HTTP status code to return. Returns 0 if you do not wish to
     *                   process the call
     */
    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal virtual override view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
        FrontendFilesSet memory frontend = getLiveFrontendVersion();

        // Compute the filePath of the requested resource
        string memory filePath = _getStaticFrontendAssetFilePathForRequest(resource, params);

        // Search for the requested resource in our static file list
        for(uint i = 0; i < frontend.files.length; i++) {
            if(LibStrings.compare(filePath, frontend.files[i].filePath)) {
                IStorageBackend storageBackend = frontend.storageBackend;

                // Storage backend read chain id check. If not the same, we need to redirect
                if(storageBackend.getReadChainId() != block.chainid) {
                    headers = new KeyValue[](1);
                    headers[0].key = "Location";
                    headers[0].value = string.concat("web3://", LibStrings.toHexString(address(this)), ":", LibStrings.toString(storageBackend.getReadChainId()), "/", filePath);
                    statusCode = 302;
                    return (statusCode, body, headers);
                }

                // web3:// chunk feature : if the file is big, we will send the file
                // in chunks
                // Determine the requested chunk
                uint chunkIndex = 0;
                for(uint j = 0; j < params.length; j++) {
                    if(LibStrings.compare(params[j].key, "chunk")) {
                        chunkIndex = LibStrings.stringToUint(params[j].value);
                        break;
                    }
                }

                (bytes memory data, uint nextChunkId) = storageBackend.read(address(this), frontend.files[i].contentKey, chunkIndex);
                body = string(data);
                statusCode = 200;

                uint headersCount = 2;
                if(nextChunkId > 0) {
                    headersCount = 3;
                }
                headers = new KeyValue[](headersCount);
                headers[0].key = "Content-type";
                headers[0].value = frontend.files[i].contentType;
                headers[1].key = "Content-Encoding";
                headers[1].value = "gzip";
                // If there is more chunk remaining, add a pointer to the next chunk
                if(nextChunkId > 0) {
                    headers[2].key = "web3-next-chunk";
                    headers[2].value = string.concat("/", filePath, "?chunk=", LibStrings.toString(nextChunkId));
                }

                return (statusCode, body, headers);
            }
        }

        (statusCode, body, headers) = super._processWeb3Request(resource, params);
    }
}