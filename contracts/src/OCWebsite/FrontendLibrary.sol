// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";
import { Ownable } from "../library/Ownable.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IFrontendLibrary.sol";
import "../interfaces/IStorageBackend.sol";

contract FrontendLibrary is IFrontendLibrary, Ownable {

    FrontendFilesSet[] public frontendVersions;
    // The index of the frontend being used
    uint256 public defaultFrontendIndex;


    //
    // IFrontendLibrary implementation
    //

    /**
     * Add a new frontend version
     * @param storageBackend Address of the storage backend
     * @param _description A description of the frontend version
     */
    function addFrontendVersion(IStorageBackend storageBackend, string memory _description) public onlyOwner {
        frontendVersions.push();
        FrontendFilesSet storage newFrontend = frontendVersions[frontendVersions.length - 1];
        newFrontend.storageBackend = storageBackend;
        newFrontend.description = _description;
    }

    /**
     * Get all frontend versions
     */
    function getFrontendVersions() public view returns (FrontendFilesSet[] memory) {
        return frontendVersions;
    }

    /**
     * Get a frontend version
     * @param frontendIndex The index of the frontend version
     */
    function getFrontendVersion(uint256 frontendIndex) public view returns (FrontendFilesSet memory) {
        require(frontendIndex < frontendVersions.length, "Index out of bounds");
        return frontendVersions[frontendIndex];
    }

    /**
     * Remove a frontend version
     * @param frontendIndex The index of the frontend version
     */
    function removeFrontendVersion(uint256 frontendIndex) public onlyOwner {
        require(frontendIndex < frontendVersions.length, "Index out of bounds");
        require(!frontendVersions[frontendIndex].locked, "Frontend version is locked");
        frontendVersions[frontendIndex] = frontendVersions[frontendVersions.length - 1];
        frontendVersions.pop();
    }

    /**
     * Get the default frontend version used in the website
     */
    function getDefaultFrontendIndex() public view returns (uint256 frontendIndex) {
        return defaultFrontendIndex;
    }

    /**
     * Set the default frontend version used in the website
     * @param frontendIndex The index of the frontend version
     */
    function setDefaultFrontendIndex(uint256 frontendIndex) public onlyOwner {
        require(frontendIndex < frontendVersions.length, "Index out of bounds");
        defaultFrontendIndex = frontendIndex;
    }

    /**
     * Add several files to a frontend version. If a file already exists, it is replaced.
     * @param frontendIndex The index of the frontend version
     * @param fileUploadInfos The files to add
     */
    function addFilesToFrontendVersion(uint256 frontendIndex, FileUploadInfos[] memory fileUploadInfos) public payable onlyOwner {
        require(frontendIndex < frontendVersions.length, "Index out of bounds");
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        require(!frontend.locked, "Frontend version is locked");

        uint totalFundsUsed = 0;
        for(uint i = 0; i < fileUploadInfos.length; i++) {
            // Search if the file already exists
            (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, fileUploadInfos[i].filePath);
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
                frontend.files[fileIndex].complete = frontend.storageBackend.isComplete(address(this), contentKey);
            }
            // If not found, add the file
            else {
                PartialFileInfos memory fileInfos = PartialFileInfos({
                    contentKey: contentKey,
                    filePath: fileUploadInfos[i].filePath,
                    contentType: fileUploadInfos[i].contentType,
                    compressionAlgorithm: fileUploadInfos[i].compressionAlgorithm,
                    complete: frontend.storageBackend.isComplete(address(this), contentKey)
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
     * Get the uploaded size of a file in a frontend version.
     * @param frontendIndex The index of the frontend version
     * @param filePath The path of the file to read
     */
    function getFileUploadedSizeInFrontendVersion(uint256 frontendIndex, string memory filePath) public view returns (uint256) {
        require(frontendIndex < frontendVersions.length, "Index out of bounds");
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];

        for(uint i = 0; i < frontend.files.length; i++) {
            if(LibStrings.compare(filePath, frontend.files[i].filePath)) {
                return frontend.storageBackend.uploadedSize(address(this), frontend.files[i].contentKey);
            }
        }

        return 0;
    }

    /**
     * Append data to a file in a frontend version.
     * @param frontendIndex The index of the frontend version
     * @param filePath The path of the file to read
     * @param data The data to give to the storage backend
     */
    function appendToFileInFrontendVersion(uint256 frontendIndex, string memory filePath, bytes memory data) public payable onlyOwner {
        require(frontendIndex < frontendVersions.length, "Index out of bounds");
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        require(!frontend.locked, "Frontend version is locked");

        (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, filePath);
        require(fileFound, "File not found");

        uint fundsUsed = frontend.storageBackend.append(frontend.files[fileIndex].contentKey, data);

        // Send back remaining funds sent by the caller
        if(msg.value - fundsUsed > 0) {
            payable(msg.sender).transfer(msg.value - fundsUsed);
        }
    }

    /**
     * Read a file from a frontend version. It will read as much chunks as possible.
     * @param frontendIndex The index of the frontend version
     * @param filePath The path of the file to read
     * @param chunkId The starting chunk ID
     * @return data The read data
     * @return nextChunkId The next chunk ID to read. 0 if none.
     */
    function readFileFromFrontendVersion(uint256 frontendIndex, string memory filePath, uint256 chunkId) public view returns (bytes memory data, uint256 nextChunkId) {
        require(frontendIndex < frontendVersions.length, "Index out of bounds");
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        
        (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, filePath);
        require(fileFound, "File not found");

        (data, nextChunkId) = frontend.storageBackend.read(address(this), frontend.files[fileIndex].contentKey, chunkId);
    }

    /**
     * Remove files from the backend
     * @param frontendIndex The index of the frontend version
     * @param filePaths The paths of the files to remove
     */
    function removeFilesFromFrontendVersion(uint256 frontendIndex, string[] memory filePaths) public onlyOwner {
        require(frontendIndex < frontendVersions.length, "Index out of bounds");
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        require(!frontend.locked, "Frontend version is locked");

        for(uint i = 0; i < filePaths.length; i++) {
            (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, filePaths[i]);
            if(fileFound) {
                frontend.storageBackend.remove(frontend.files[fileIndex].contentKey);
                frontend.files[fileIndex] = frontend.files[frontend.files.length - 1];
                frontend.files.pop();
            }
        }
    }

    /**
     * Remove all files from a frontend version
     * @param frontendIndex The index of the frontend version
     */
    function removeAllFilesFromFrontendVersion(uint256 frontendIndex) public onlyOwner {
        require(frontendIndex < frontendVersions.length, "Index out of bounds");
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        require(!frontend.locked, "Frontend version is locked");

        for(uint i = 0; i < frontend.files.length; i++) {
            frontend.storageBackend.remove(frontend.files[i].contentKey);
            frontend.files.pop();
        }
    }

    /**
     * Lock a frontend version
     * @param frontendIndex The index of the frontend version
     */
    function lockFrontendVersion(uint256 frontendIndex) public onlyOwner {
        require(frontendIndex < frontendVersions.length, "Index out of bounds");
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        require(!frontend.locked, "Frontend version is already locked");
        frontend.locked = true;
    }

    function _findFileIndexByNameInFrontendVersion(FrontendFilesSet storage frontend, string memory filePath) internal view returns (bool, uint) {
        for(uint i = 0; i < frontend.files.length; i++) {
            if(LibStrings.compare(filePath, frontend.files[i].filePath)) {
                return (true, i);
            }
        }
        return (false, 0);
    }
}
