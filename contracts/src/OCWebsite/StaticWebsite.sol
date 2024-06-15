// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IFrontendLibrary.sol";

contract StaticWebsite {

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
    // web3:// protocol implementation
    //

    // Indicate we are serving a website with the resource request mode
    function resolveMode() external pure returns (bytes32) {
        return "5219";
    }

    /**
     * Hook to override
     * For a given web3:// request, compute the file path of the requested asset to serve
     */
    function _getAssetFilePathForRequest(string[] memory resource, KeyValue[] memory params) internal view returns (string memory filePath) {
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
        

    // Implementation for the ERC-5219 resource request mode
    function request(string[] memory resource, KeyValue[] memory params) external view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
        FrontendFilesSet memory frontend = getLiveFrontendVersion();

        // Compute the filePath of the requested resource
        string memory filePath = _getAssetFilePathForRequest(resource, params);

        // Search for the requested resource in our static file list
        for(uint i = 0; i < frontend.files.length; i++) {
            if(LibStrings.compare(filePath, frontend.files[i].filePath)) {
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

                IStorageBackend storageBackend = frontend.storageBackend;
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

        // // blogFactoryAddress.json : it exposes the addess of the blog factory
        // if(resource.length == 1 && LibStrings.compare(resource[0], "blogFactoryAddress.json")) {
        //     uint chainid = block.chainid;
        //     // Special case: Sepolia chain id 11155111 is > 65k, which breaks URL parsing in EVM browser
        //     // As a temporary measure, we will test Sepolia with a fake chain id of 11155
        //     // if(chainid == 11155111) {
        //     //     chainid = 11155;
        //     // }
        //     // Manual JSON serialization, safe with the vars we encode
        //     body = string.concat("{\"address\":\"", LibStrings.toHexString(address(blogFactory)), "\", \"chainId\":", LibStrings.toString(chainid), "}");
        //     statusCode = 200;
        //     headers = new KeyValue[](1);
        //     headers[0].key = "Content-type";
        //     headers[0].value = "application/json";
        //     return (statusCode, body, headers);
        // }
        
        statusCode = 404;
    }

}