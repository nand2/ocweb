// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IFrontendLibrary.sol";

import "./ResourceRequestWebsite.sol";

abstract contract StaticWebsiteBase is ResourceRequestWebsite {

    /**
     * Hook: Get the frontend to use
     * @return frontendVersion The frontend version to use
     * @return frontendIndex The index of the frontend version to use. 0 for mono-frontend websites
     */
    function getLiveFrontendVersion() public virtual view returns (FrontendFilesSet memory, uint256 frontendIndex);


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
        (FrontendFilesSet memory frontend, ) = getLiveFrontendVersion();

        // Special path : contractAddresses.json
        // Serve static contract addresses to be consumed by the frontend to boostrap
        if(resource.length == 1 && LibStrings.compare(resource[0], "contractAddresses.json")) {
            // We output all the static contract addresses and ourselves
            // Manual JSON serialization, safe with the vars we encode
            body = string.concat('{'
                '"self":{'
                    '"address":"', LibStrings.toHexString(address(this)), '",'
                    '"chainId":', LibStrings.toString(block.chainid), 
                '}');

            NamedAddressAndChainId[] memory contractAddresses = frontend.staticContractAddresses;
            for(uint i = 0; i < contractAddresses.length; i++) {
                body = string.concat(body, ','
                '"', contractAddresses[i].name, '":{'
                    '"address":"', LibStrings.toHexString(contractAddresses[i].addr), '",',
                    '"chainId":', LibStrings.toString(contractAddresses[i].chainId), 
                '}');
            }
            body = string.concat(body, '}');
            
            statusCode = 200;
            headers = new KeyValue[](1);
            headers[0].key = "Content-type";
            headers[0].value = "application/json";
            return (statusCode, body, headers);
        }

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

                uint headersCount = 1;
                if(frontend.files[i].compressionAlgorithm != CompressionAlgorithm.NONE) {
                    headersCount++;
                }
                if(nextChunkId > 0) {
                    headersCount++;
                }
                headers = new KeyValue[](headersCount);
                headers[0].key = "Content-type";
                headers[0].value = frontend.files[i].contentType;
                if(frontend.files[i].compressionAlgorithm != CompressionAlgorithm.NONE) {
                    headers[1].key = "Content-Encoding";
                    // We support brotli or gzip only
                    headers[1].value = frontend.files[i].compressionAlgorithm == CompressionAlgorithm.BROTLI ? "br" : "gzip";
                }
                // If there is more chunk remaining, add a pointer to the next chunk
                if(nextChunkId > 0) {
                    headers[headers.length - 1].key = "web3-next-chunk";
                    headers[headers.length - 1].value = string.concat("/", filePath, "?chunk=", LibStrings.toString(nextChunkId));
                }

                return (statusCode, body, headers);
            }
        }

        // If the file was not found: Now let's query the proxies
        for(uint i = 0; i < frontend.proxiedWebsites.length; i++) {
            ProxiedWebsite memory proxiedWebsite = frontend.proxiedWebsites[i];
            if(resource.length < proxiedWebsite.localPrefix.length) {
                continue;
            }

            bool prefixMatch = true;
            for(uint j = 0; j < proxiedWebsite.localPrefix.length; j++) {
                if(LibStrings.compare(resource[j], proxiedWebsite.localPrefix[j]) == false) {
                    prefixMatch = false;
                    break;
                }
            }

            if(prefixMatch) {
                string[] memory newResource = new string[](resource.length - proxiedWebsite.localPrefix.length + proxiedWebsite.remotePrefix.length);
                for(uint j = 0; j < proxiedWebsite.remotePrefix.length; j++) {
                    newResource[j] = proxiedWebsite.remotePrefix[j];
                }
                for(uint j = 0; j < resource.length - proxiedWebsite.localPrefix.length; j++) {
                    newResource[j + proxiedWebsite.remotePrefix.length] = resource[j + proxiedWebsite.localPrefix.length];
                }

                (statusCode, body, headers) = proxiedWebsite.website.request(newResource, params);

                if (statusCode != 0 && statusCode != 404) {
                    return (statusCode, body, headers);
                }
            }
        }
    }


}