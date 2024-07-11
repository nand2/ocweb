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
    // The index of the default frontend to use
    uint256 public defaultFrontendIndex;
    // Is the frontend library locked?
    bool public frontendLibraryLocked;

    modifier onlyOwnerOrSelf() {
        if(msg.sender != owner && msg.sender != address(this)) {
            revert Unauthorized();
        }
        _;
    }


    //
    // IFrontendLibrary implementation
    //

    modifier frontendLibraryUnlocked() {
        if(frontendLibraryLocked) {
            revert FrontendLibraryLocked();
        }
        _;
    }

    /**
     * Add a new frontend version
     * @param storageBackend Address of the storage backend
     * @param _description A description of the frontend version
     */
    function addFrontendVersion(IStorageBackend storageBackend, string memory _description) public onlyOwnerOrSelf frontendLibraryUnlocked {
        // Ensure that the plugin support one of the requested interfaces
        bool supported = false;
        bytes4[] memory supportedInterfaces = getSupportedStorageBackendInterfaces();
        for(uint i = 0; i < supportedInterfaces.length; i++) {
            if(supportedInterfaces[i] == type(IStorageBackend).interfaceId) {
                supported = true;
                break;
            }
        }
        if(supported == false) {
            revert UnsupportedStorageBackendInterface();
        }

        frontendVersions.push();
        FrontendFilesSet storage newFrontend = frontendVersions[frontendVersions.length - 1];
        newFrontend.storageBackend = storageBackend;
        newFrontend.description = _description;
    }

    /**
     * Get the number of frontend versions
     */
    function getFrontendVersionCount() external view returns (uint) {
        return frontendVersions.length;
    }

    /**
     * Get frontend versions
     * @param startIndex The index of the first frontend version to get
     * @param count The number of frontend versions to get. If 0, get all versions
     */
    function getFrontendVersions(uint startIndex, uint count) public view returns (FrontendFilesSet[] memory, uint totalCount) {
        if(startIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        
        if(count == 0) {
            count = frontendVersions.length - startIndex;
        }
        else if(startIndex + count > frontendVersions.length) {
            count = frontendVersions.length - startIndex;
        }
        FrontendFilesSet[] memory result = new FrontendFilesSet[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = frontendVersions[startIndex + i];
        }
        return (result, frontendVersions.length);
    }

    /**
     * Get a frontend version
     * @param frontendIndex The index of the frontend version
     */
    function getFrontendVersion(uint256 frontendIndex) public view returns (FrontendFilesSet memory) {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        return frontendVersions[frontendIndex];
    }

    /**
     * Rename a frontend version
     */
    function renameFrontendVersion(uint256 frontendIndex, string memory newDescription) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        if(frontendVersions[frontendIndex].locked) {
            revert FrontendVersionLocked();
        }

        frontendVersions[frontendIndex].description = newDescription;
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
    function setDefaultFrontendIndex(uint256 frontendIndex) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        defaultFrontendIndex = frontendIndex;
    }

    /**
     * Add several files to a frontend version. If a file already exists, it is replaced.
     * @param frontendIndex The index of the frontend version
     * @param fileUploadInfos The files to add
     */
    function addFiles(uint256 frontendIndex, FileUploadInfos[] memory fileUploadInfos) public payable onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
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
                if(identical) {
                    revert FileAlreadyExistsAsDirectory();
                }
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
     * Append data to a file in a frontend version.
     * @param frontendIndex The index of the frontend version
     * @param filePath The path of the file to read
     * @param data The data to give to the storage backend
     */
    function appendToFile(uint256 frontendIndex, string memory filePath, bytes memory data) public payable onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

        (bool fileFound, uint fileIndex) = _findFileIndexByName(frontend, filePath);
        if(fileFound == false) {
            revert FileNotFound();
        }

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
    function readFile(uint256 frontendIndex, string memory filePath, uint256 chunkId) public view returns (bytes memory data, uint256 nextChunkId) {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        
        (bool fileFound, uint fileIndex) = _findFileIndexByName(frontend, filePath);
        if(fileFound == false) {
            revert FileNotFound();
        }

        (data, nextChunkId) = frontend.storageBackend.read(address(this), frontend.files[fileIndex].contentKey, chunkId);
    }

    /**
     * Rename a file in a frontend version
     * @param frontendIndex The index of the frontend version
     * @param oldFilePaths The old path of the file
     * @param newFilePaths The new path of the file
     */
    function renameFiles(uint256 frontendIndex, string[] memory oldFilePaths, string[] memory newFilePaths) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

        if(oldFilePaths.length != newFilePaths.length) {
            revert ArraysLengthMismatch();
        }

        for(uint i = 0; i < oldFilePaths.length; i++) {
            (bool fileFound, uint fileIndex) = _findFileIndexByName(frontend, oldFilePaths[i]);
            if(fileFound == false) {
                revert FileNotFound();
            }
            
            (bool fileFoundAtNewLocation,) = _findFileIndexByName(frontend, newFilePaths[i]);
            if(fileFoundAtNewLocation) {
                revert FileAlreadyExistsAtNewLocation();
            }
            
            frontend.files[fileIndex].filePath = newFilePaths[i];
        }
    }

    /**
     * Remove files from the backend
     * @param frontendIndex The index of the frontend version
     * @param filePaths The paths of the files to remove
     */
    function removeFiles(uint256 frontendIndex, string[] memory filePaths) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

        for(uint i = 0; i < filePaths.length; i++) {
            (bool fileFound, uint fileIndex) = _findFileIndexByName(frontend, filePaths[i]);
            if(fileFound == false) {
                revert FileNotFound();
            }

            frontend.storageBackend.remove(frontend.files[fileIndex].contentKey);
            frontend.files[fileIndex] = frontend.files[frontend.files.length - 1];
            frontend.files.pop();
        }
    }

    /**
     * Remove all files from a frontend version
     * @param frontendIndex The index of the frontend version
     */
    function removeAllFiles(uint256 frontendIndex) public onlyOwner frontendLibraryUnlocked  {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

        for(uint i = 0; i < frontend.files.length; i++) {
            frontend.storageBackend.remove(frontend.files[i].contentKey);
            frontend.files.pop();
        }
    }

    /**
     * Lock a frontend version
     * @param frontendIndex The index of the frontend version
     */
    function lockFrontendVersion(uint256 frontendIndex) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionIsAlreadyLocked();
        }
        frontend.locked = true;
    }

    // /**
    //  * Lock the whole frontend library
    //  */
    // function lock() public onlyOwner {
    //     frontendLibraryLocked = true;
    // }

    // /**
    //  * Is the frontend library locked?
    //  */
    // function isLocked() public view returns (bool) {
    //     return frontendLibraryLocked;
    // }

    /**
     * Get the list of supported storage backend interfaces
     * Unfortunately constant arrays are not supported...
     */
    function getSupportedStorageBackendInterfaces() public pure returns (bytes4[] memory) {
        unchecked {
            bytes4[] memory supportedInterfaces = new bytes4[](1);
            supportedInterfaces[0] = type(IStorageBackend).interfaceId;
            return supportedInterfaces;
        }
    }


    function _findFileIndexByName(FrontendFilesSet storage frontend, string memory filePath) internal view returns (bool, uint) {
        for(uint i = 0; i < frontend.files.length; i++) {
            if(LibStrings.compare(filePath, frontend.files[i].filePath)) {
                return (true, i);
            }
        }
        return (false, 0);
    }
}
