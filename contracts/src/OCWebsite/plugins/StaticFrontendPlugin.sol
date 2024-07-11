// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../interfaces/IVersionableStaticWebsite.sol";
import "../../library/LibStrings.sol";
import "../../interfaces/IFileInfos.sol";
import "../../library/Ownable.sol";

contract StaticFrontendPlugin is ERC165, IVersionableStaticWebsitePlugin, Ownable {
    struct StaticFrontend {
        // The files of the frontend
        PartialFileInfos[] files;

        // Storage backend of the frontend files
        IStorageBackend storageBackend;
    }
    mapping(IVersionableStaticWebsite => mapping(uint => StaticFrontend)) public websiteVersionStaticFrontends;

    // Storage backends
    IStorageBackend[] public storageBackends;




    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IVersionableStaticWebsitePlugin).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function infos() external view returns (Infos memory) {
        return
            Infos({
                name: "staticFrontend",
                version: "0.1.0",
                title: "Static frontend",
                subTitle: "Host and serve static files",
                author: "nand",
                homepage: "web3://ocweb.eth/"
            });
    }

    function rewriteWeb3Request(IVersionableStaticWebsite website, uint websiteVersionIndex, string[] memory resource, KeyValue[] memory params) public view returns (bool rewritten, string[] memory newResource, KeyValue[] memory newParams) {
        return (false, new string[](0), new KeyValue[](0));
    }

    function processWeb3RequestBeforeStaticContent(
        IVersionableStaticWebsite website,
        uint websiteVersionIndex,
        string[] memory resource,
        KeyValue[] memory params
    )
        public view override returns (uint statusCode, string memory body, KeyValue[] memory headers)
    {
        return (0, "", new KeyValue[](0));
    }

    function processWeb3RequestAfterStaticContent(
        IVersionableStaticWebsite website,
        uint websiteVersionIndex,
        string[] memory resource,
        KeyValue[] memory params
    )
        public view override returns (uint statusCode, string memory body, KeyValue[] memory headers)
    {
        StaticFrontend storage frontend = websiteVersionStaticFrontends[website][websiteVersionIndex];

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
    }

    function copyFrontendSettings(IVersionableStaticWebsite website, uint fromFrontendIndex, uint toFrontendIndex) public {
        require(address(website) == msg.sender);

        StaticFrontend storage frontend = websiteVersionStaticFrontends[website][fromFrontendIndex];
        websiteVersionStaticFrontends[website][toFrontendIndex].storageBackend = frontend.storageBackend;
    }

    function getStaticFrontend(IVersionableStaticWebsite website, uint websiteVersionIndex) public view returns (StaticFrontend memory) {
        return websiteVersionStaticFrontends[website][websiteVersionIndex];
    }


    // Add several files to a website version
    // If a file already exists, it is replaced
    struct FileUploadInfos {
        // The path of the file, without root slash. E.g. "images/logo.png"
        string filePath;
        // The total file size
        uint256 fileSize;
        // The content type of the file, e.g. "image/png"
        string contentType;
        // The compression algorithm used for the file data
        CompressionAlgorithm compressionAlgorithm;
        // The data for the storage backend. May be only a part of the file and require
        // subsequent calls to appendToFile()
        bytes data;
    }

    /**
     * Add several files to a website version. If a file already exists, it is replaced.
     * @param websiteVersionIndex The website version
     * @param fileUploadInfos The files to add
     */
    function addFiles(IVersionableStaticWebsite website, uint256 websiteVersionIndex, FileUploadInfos[] memory fileUploadInfos) public payable {
        require(website.owner() == msg.sender, "Not the owner");

        require(website.isLocked() == false, "Website is locked");

        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");
        IVersionableStaticWebsite.WebsiteVersion memory websiteVersion = website.getWebsiteVersion(websiteVersionIndex);
        require(websiteVersion.locked == false, "Website version is locked");


        StaticFrontend storage frontend = websiteVersionStaticFrontends[website][websiteVersionIndex];

        // If the frontend does not have a storage backend yet, use the first one
        if(frontend.storageBackend == IStorageBackend(address(0))) {
            require(storageBackends.length > 0, "No storage backend available");
            frontend.storageBackend = storageBackends[0];
        }


        uint totalFundsUsed = 0;
        for(uint i = 0; i < fileUploadInfos.length; i++) {
            // Check if the file already exists as a directory
            bytes memory newFilePathAsDir = bytes(string.concat(fileUploadInfos[i].filePath, "/"));
            uint newFilePathAsDirLength = newFilePathAsDir.length;
            for(uint j = 0; j < frontend.files.length; j++) {
                // Crude string and substring comparaison, but the most contract-size efficient
                // (that I know of)
                bool identical = true;
                if(bytes(frontend.files[j].filePath).length < newFilePathAsDirLength) {
                    continue;
                }
                for(uint k = 0; k < newFilePathAsDirLength; k++) {
                    if(bytes(frontend.files[j].filePath)[k] != newFilePathAsDir[k]) {
                        identical = false;
                        break;
                    }
                }
                require(!identical, "File already exists as directory");
            }
            // Search if the file already exists
            (bool fileFound, uint fileIndex) = _findFileIndexByName(frontend, fileUploadInfos[i].filePath);
            // If it does, remove it from the storage backend
            // (we do it before the create, as remove() may free a slot for the new file in the
            // storage backend)
            if(fileFound) {
                frontend.storageBackend.remove(frontend.files[fileIndex].contentKey);
            }

            // Create the new file on the storage backend
            (uint contentKey, uint fundsUsed) = frontend.storageBackend.create(fileUploadInfos[i].data, fileUploadInfos[i].fileSize);
            totalFundsUsed += fundsUsed;

            // If the file was found, reuse the existing fileInfos entry
            if(fileFound) {
                frontend.files[fileIndex].contentKey = contentKey;
                frontend.files[fileIndex].contentType = fileUploadInfos[i].contentType;
            }
            // If not found, add the file
            else {
                PartialFileInfos memory fileInfos = PartialFileInfos({
                    contentKey: contentKey,
                    filePath: fileUploadInfos[i].filePath,
                    contentType: fileUploadInfos[i].contentType,
                    compressionAlgorithm: fileUploadInfos[i].compressionAlgorithm
                });
                frontend.files.push(fileInfos);
            }
        }

        // Send back remaining funds sent by the caller
        if(msg.value - totalFundsUsed > 0) {
            payable(msg.sender).transfer(msg.value - totalFundsUsed);
        }
    }

    /**
     * Append data to a file in a website version.
     * @param websiteVersionIndex The website version
     * @param filePath The path of the file to read
     * @param data The data to give to the storage backend
     */
    function appendToFile(IVersionableStaticWebsite website, uint256 websiteVersionIndex, string memory filePath, bytes memory data) public payable {
        require(website.owner() == msg.sender, "Not the owner");

        require(website.isLocked() == false, "Website is locked");

        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");
        IVersionableStaticWebsite.WebsiteVersion memory websiteVersion = website.getWebsiteVersion(websiteVersionIndex);
        require(websiteVersion.locked == false, "Website version is locked");


        StaticFrontend storage frontend = websiteVersionStaticFrontends[website][websiteVersionIndex];

        (bool fileFound, uint fileIndex) = _findFileIndexByName(frontend, filePath);
        require(fileFound, "File not found");

        uint fundsUsed = frontend.storageBackend.append(frontend.files[fileIndex].contentKey, data);

        // Send back remaining funds sent by the caller
        if(msg.value - fundsUsed > 0) {
            payable(msg.sender).transfer(msg.value - fundsUsed);
        }
    }

    /**
     * Read a file from a website version. It will read as much chunks as possible.
     * @param websiteVersionIndex The website version
     * @param filePath The path of the file to read
     * @param chunkId The starting chunk ID
     * @return data The read data
     * @return nextChunkId The next chunk ID to read. 0 if none.
     */
    function readFile(IVersionableStaticWebsite website, uint256 websiteVersionIndex, string memory filePath, uint256 chunkId) public view returns (bytes memory data, uint256 nextChunkId) {
        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");

        StaticFrontend storage frontend = websiteVersionStaticFrontends[website][websiteVersionIndex];
        
        (bool fileFound, uint fileIndex) = _findFileIndexByName(frontend, filePath);
        require(fileFound, "File not found");

        (data, nextChunkId) = frontend.storageBackend.read(address(this), frontend.files[fileIndex].contentKey, chunkId);
    }

    /**
     * Rename a file in a website version
     * @param websiteVersionIndex The website version
     * @param oldFilePaths The old path of the file
     * @param newFilePaths The new path of the file
     */
    function renameFiles(IVersionableStaticWebsite website, uint256 websiteVersionIndex, string[] memory oldFilePaths, string[] memory newFilePaths) public {
        require(website.owner() == msg.sender, "Not the owner");

        require(website.isLocked() == false, "Website is locked");

        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");
        IVersionableStaticWebsite.WebsiteVersion memory websiteVersion = website.getWebsiteVersion(websiteVersionIndex);
        require(websiteVersion.locked == false, "Website version is locked");


        StaticFrontend storage frontend = websiteVersionStaticFrontends[website][websiteVersionIndex];

        require(oldFilePaths.length == newFilePaths.length, "Arrays length mismatch");

        for(uint i = 0; i < oldFilePaths.length; i++) {
            (bool fileFound, uint fileIndex) = _findFileIndexByName(frontend, oldFilePaths[i]);
            require(fileFound, "File not found");
            
            (bool fileFoundAtNewLocation,) = _findFileIndexByName(frontend, newFilePaths[i]);
            require(fileFoundAtNewLocation == false, "File already exists at new location");
            
            frontend.files[fileIndex].filePath = newFilePaths[i];
        }
    }

    /**
     * Remove files from the backend
     * @param websiteVersionIndex The website version
     * @param filePaths The paths of the files to remove
     */
    function removeFiles(IVersionableStaticWebsite website, uint256 websiteVersionIndex, string[] memory filePaths) public {
        require(website.owner() == msg.sender, "Not the owner");

        require(website.isLocked() == false, "Website is locked");

        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");
        IVersionableStaticWebsite.WebsiteVersion memory websiteVersion = website.getWebsiteVersion(websiteVersionIndex);
        require(websiteVersion.locked == false, "Website version is locked");


        StaticFrontend storage frontend = websiteVersionStaticFrontends[website][websiteVersionIndex];

        for(uint i = 0; i < filePaths.length; i++) {
            (bool fileFound, uint fileIndex) = _findFileIndexByName(frontend, filePaths[i]);
            require(fileFound, "File not found");

            frontend.storageBackend.remove(frontend.files[fileIndex].contentKey);
            frontend.files[fileIndex] = frontend.files[frontend.files.length - 1];
            frontend.files.pop();
        }
    }

    /**
     * Remove all files from a website version
     * @param websiteVersionIndex The website version
     */
    function removeAllFiles(IVersionableStaticWebsite website, uint256 websiteVersionIndex) public {
        require(website.owner() == msg.sender, "Not the owner");

        require(website.isLocked() == false, "Website is locked");

        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");
        IVersionableStaticWebsite.WebsiteVersion memory websiteVersion = website.getWebsiteVersion(websiteVersionIndex);
        require(websiteVersion.locked == false, "Website version is locked");


        StaticFrontend storage frontend = websiteVersionStaticFrontends[website][websiteVersionIndex];

        for(uint i = 0; i < frontend.files.length; i++) {
            frontend.storageBackend.remove(frontend.files[i].contentKey);
            frontend.files.pop();
        }
    }

    function _findFileIndexByName(StaticFrontend storage frontend, string memory filePath) internal view returns (bool, uint) {
        for(uint i = 0; i < frontend.files.length; i++) {
            if(LibStrings.compare(filePath, frontend.files[i].filePath)) {
                return (true, i);
            }
        }
        return (false, 0);
    }


    //
    // Storage backends
    //

    function addStorageBackend(IStorageBackend storageBackend) public onlyOwner {
        // Make sure it is not inserted yet
        // Make sure name is unique
        for(uint i = 0; i < storageBackends.length; i++) {
            require(address(storageBackends[i]) != address(storageBackend), "Storage backend already added");
            require((LibStrings.compare(storageBackends[i].name(), storageBackend.name()) && LibStrings.compare(storageBackends[i].version(), storageBackend.version())) == false, "Storage backend name/version already used");
        }

        storageBackends.push(storageBackend);
    }

    /**
     * Frontend helper
     */
    struct StorageBackendWithInfos {
        IStorageBackend storageBackend;
        string name;
        string title;
        string version;
        bool interfaceValid;
    }
    function getStorageBackends(bytes4[] memory interfaceFilters) public view returns (StorageBackendWithInfos[] memory) {
        StorageBackendWithInfos[] memory backends = new StorageBackendWithInfos[](storageBackends.length);
        for(uint i = 0; i < storageBackends.length; i++) {
            // Is interface supported?
            bool interfaceValid = (interfaceFilters.length == 0);
            for(uint j = 0; j < interfaceFilters.length; j++) {
                if(storageBackends[i].supportsInterface(interfaceFilters[j])) {
                    interfaceValid = true;
                    break;
                }
            }

            backends[i] = StorageBackendWithInfos({
                storageBackend: storageBackends[i],
                name: storageBackends[i].name(),
                title: storageBackends[i].title(),
                version: storageBackends[i].version(),
                interfaceValid: interfaceValid
            });
        }

        return backends;
    }
}