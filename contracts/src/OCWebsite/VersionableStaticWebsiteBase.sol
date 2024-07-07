// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IFrontendLibrary.sol";
import "../interfaces/IVersionableStaticWebsite.sol";

import '../library/Ownable.sol';
import './ResourceRequestWebsite.sol';
import './FrontendLibrary.sol';

abstract contract VersionableStaticWebsiteBase is IVersionableStaticWebsite, ResourceRequestWebsite, Ownable {
    // For each frontend version, the list of plugins to execute before and after the static content
    mapping(uint => IVersionableStaticWebsitePlugin[]) public preStaticContentplugins;
    mapping(uint => IVersionableStaticWebsitePlugin[]) public postStaticContentplugins;

    
    function getLiveFrontendIndex() public view virtual returns (uint256);

    function getFrontendLibrary() public view virtual returns (IFrontendLibrary);

    /**
     * Get the current live frontend version, and its index
     */
    function getLiveFrontendVersion() public view returns (FrontendFilesSet memory frontendVersion, uint256 frontendIndex) {
        frontendIndex = getLiveFrontendIndex();
        frontendVersion = getFrontendLibrary().getFrontendVersion(frontendIndex);
    }


    /**
     * Add a new frontend version, copy the plugins and settings
     * @param storageBackend Address of the storage backend
     * @param _description A description of the frontend version
     */
    function addFrontendVersionAndCopyPlugins(IStorageBackend storageBackend, string memory _description, uint frontendVersionIndexToCopyFrom) public onlyOwner {
        // Check that the frontend version to copy from exists
        require(frontendVersionIndexToCopyFrom < getFrontendLibrary().getFrontendVersionCount(), "Invalid index");

        // Add the frontend version
        getFrontendLibrary().addFrontendVersion(storageBackend, _description);
        
        // Copy the plugins
        uint newFrontendIndex = getFrontendLibrary().getFrontendVersionCount() - 1;
        for(uint i = 0; i < preStaticContentplugins[frontendVersionIndexToCopyFrom].length; i++) {
            preStaticContentplugins[newFrontendIndex].push(preStaticContentplugins[frontendVersionIndexToCopyFrom][i]);
            preStaticContentplugins[newFrontendIndex][i].copyFrontendSettings(this, frontendVersionIndexToCopyFrom, newFrontendIndex);
        }
        for(uint i = 0; i < postStaticContentplugins[frontendVersionIndexToCopyFrom].length; i++) {
            postStaticContentplugins[newFrontendIndex].push(postStaticContentplugins[frontendVersionIndexToCopyFrom][i]);
            postStaticContentplugins[newFrontendIndex][i].copyFrontendSettings(this, frontendVersionIndexToCopyFrom, newFrontendIndex);
        }
    }

    //
    // Plugins
    // 

    function addPlugin(uint frontendIndex, IVersionableStaticWebsitePlugin plugin, bool executeBeforeStaticContent) public override onlyOwner {
        if(executeBeforeStaticContent) {
            preStaticContentplugins[frontendIndex].push(plugin);
        }
        else {
            postStaticContentplugins[frontendIndex].push(plugin);
        }
    }

    function getPlugins(uint frontendIndex) external view returns (IVersionableStaticWebsitePluginWithInfos[] memory pluginsExecutedBeforeStaticContent, IVersionableStaticWebsitePluginWithInfos[] memory pluginsExecutedAfterStaticContent) {
        pluginsExecutedBeforeStaticContent = new IVersionableStaticWebsitePluginWithInfos[](preStaticContentplugins[frontendIndex].length);
        for(uint i = 0; i < preStaticContentplugins[frontendIndex].length; i++) {
            pluginsExecutedBeforeStaticContent[i].plugin = preStaticContentplugins[frontendIndex][i];
            pluginsExecutedBeforeStaticContent[i].infos = preStaticContentplugins[frontendIndex][i].infos();
        }

        pluginsExecutedAfterStaticContent = new IVersionableStaticWebsitePluginWithInfos[](postStaticContentplugins[frontendIndex].length);
        for(uint i = 0; i < postStaticContentplugins[frontendIndex].length; i++) {
            pluginsExecutedAfterStaticContent[i].plugin = postStaticContentplugins[frontendIndex][i];
            pluginsExecutedAfterStaticContent[i].infos = postStaticContentplugins[frontendIndex][i].infos();
        }
    }

    function removePlugin(uint frontendIndex, address plugin, bool removeFromExecutedBeforeStaticContentList) public onlyOwner {
        IVersionableStaticWebsitePlugin[] storage plugins = removeFromExecutedBeforeStaticContentList ? preStaticContentplugins[frontendIndex] : postStaticContentplugins[frontendIndex];
        for(uint i = 0; i < plugins.length; i++) {
            if(address(plugins[i]) == plugin) {
                plugins[i] = plugins[plugins.length - 1];
                plugins.pop();
                return;
            }
        }
    }

    

    /**
     * Return an answer to a web3:// request after the static frontend is served
     * @return statusCode The HTTP status code to return. Returns 0 if you do not wish to
     *                   process the call
     */
    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal virtual override view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
        FrontendFilesSet memory frontend;
        uint liveFrontendIndex = getLiveFrontendIndex();
        uint frontendIndex = liveFrontendIndex;

        // Get the frontend version to use
        {
            IFrontendLibrary frontendLibrary = getFrontendLibrary();

            // Special path prefix : /__frontend_version/{id}
            // Combined with the CLonableFrontendVersionViewer, this allows to serve a 
            // specific frontend version
            if(resource.length >= 2 && LibStrings.compare(resource[0], "__frontend_version")) {
                uint overridenFrontendIndex = LibStrings.stringToUint(resource[1]);
                if(overridenFrontendIndex < frontendLibrary.getFrontendVersionCount()) {
                    frontendIndex = overridenFrontendIndex;

                    string[] memory newResource = new string[](resource.length - 2);
                    for(uint i = 0; i < newResource.length; i++) {
                        newResource[i] = resource[i + 2];
                    }
                    resource = newResource;
                }
            }

            // Get the frontend version
            frontend = frontendLibrary.getFrontendVersion(frontendIndex);
            // If we are serving a non-live, non-viewable frontend, we return a 404
            if(frontendIndex != liveFrontendIndex && frontend.isViewable == false) {
                statusCode = 404;
                return (statusCode, body, headers);
            }
        }

        // Process the pre-static-content plugins
        for(uint i = 0; i < preStaticContentplugins[frontendIndex].length; i++) {
            (statusCode, body, headers) = preStaticContentplugins[frontendIndex][i].processWeb3Request(this, getLiveFrontendIndex(), resource, params);
            if(statusCode != 0) {
                return (statusCode, body, headers);
            }
        }

        // Compute the filePaths of the requested resource. 2 paths:
        // - The path as a file path (e.g. "images/logo.png") if "logo.png" is a file
        // - The path as a folder path (e.g. "images/logo.png/index.html") if "logo.png" is a folder
        string memory filePath;
        string memory filePathAsFolder;
        if(resource.length == 0) {
            filePath = "index.html";
            filePathAsFolder = filePath;
        }
        else {
            for(uint i = 0; i < resource.length; i++) {
                if(i > 0) {
                    filePath = string.concat(filePath, "/");
                }
                filePath = string.concat(filePath, resource[i]);
            }
            filePathAsFolder = string.concat(filePath, "/index.html");
        }

        // Search for the requested resource in our static file list
        for(uint i = 0; i < frontend.files.length; i++) {
            string memory matchedPath;
            if(LibStrings.compare(frontend.files[i].filePath, filePath)) {
                matchedPath = filePath;
            }
            else if(LibStrings.compare(frontend.files[i].filePath, filePathAsFolder)) {
                matchedPath = filePathAsFolder;
            }
            if(bytes(matchedPath).length > 0) {
                IStorageBackend storageBackend = frontend.storageBackend;

                // Storage backend read chain id check. If not the same, we need to redirect
                if(storageBackend.getReadChainId() != block.chainid) {
                    headers = new KeyValue[](1);
                    headers[0].key = "Location";
                    headers[0].value = string.concat("web3://", LibStrings.toHexString(address(this)), ":", LibStrings.toString(storageBackend.getReadChainId()), "/", matchedPath);
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
                    headers[headers.length - 1].value = string.concat("/", matchedPath, "?chunk=", LibStrings.toString(nextChunkId));
                }

                return (statusCode, body, headers);
            }
        }

        // Process the post-static-content plugins
        for(uint i = 0; i < postStaticContentplugins[frontendIndex].length; i++) {
            (statusCode, body, headers) = postStaticContentplugins[frontendIndex][i].processWeb3Request(this, getLiveFrontendIndex(), resource, params);
            if(statusCode != 0) {
                return (statusCode, body, headers);
            }
        }
    }


}