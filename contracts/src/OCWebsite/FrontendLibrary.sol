// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";
import { Ownable } from "../library/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IFrontendLibrary.sol";
import "../interfaces/IStorageBackend.sol";
import "./ClonableFrontendVersionViewer.sol";

contract FrontendLibrary is IFrontendLibrary, Ownable {

    FrontendFilesSet[] public frontendVersions;
    // The index of the default frontend to use
    uint256 public defaultFrontendIndex;
    // Is the frontend library locked?
    bool public frontendLibraryLocked;

    ClonableFrontendVersionViewer public frontendVersionViewerImplementation;


    //
    // IFrontendLibrary implementation
    //

    modifier frontendLibraryUnlocked() {
        if(frontendLibraryLocked) {
            revert FrontendLibraryLocked();
        }
        _;
    }

    constructor(ClonableFrontendVersionViewer _viewerImplementation) {
        frontendVersionViewerImplementation = _viewerImplementation;
    }

    /**
     * Add a new frontend version
     * @param storageBackend Address of the storage backend
     * @param _description A description of the frontend version
     * @param settingsCopiedFromFrontendVersionIndex If > 0, copy static contract addresses and proxied websites from this frontend version
     */
    function addFrontendVersion(IStorageBackend storageBackend, string memory _description, int settingsCopiedFromFrontendVersionIndex) public onlyOwner frontendLibraryUnlocked {
        _addFrontendVersion(storageBackend, _description);

        if(settingsCopiedFromFrontendVersionIndex >= 0) {
            if(uint(settingsCopiedFromFrontendVersionIndex) >= frontendVersions.length) {
                revert FrontendIndexOutOfBounds();
            }
            FrontendFilesSet storage newFrontend = frontendVersions[frontendVersions.length - 1];
            FrontendFilesSet storage sourceFrontend = frontendVersions[uint(settingsCopiedFromFrontendVersionIndex)];
            
            newFrontend.staticContractAddresses = sourceFrontend.staticContractAddresses;
            newFrontend.proxiedWebsites = sourceFrontend.proxiedWebsites;
        }
    }

    function _addFrontendVersion(IStorageBackend storageBackend, string memory _description) internal {
        frontendVersions.push();
        FrontendFilesSet storage newFrontend = frontendVersions[frontendVersions.length - 1];
        newFrontend.storageBackend = storageBackend;
        newFrontend.description = _description;

        newFrontend.viewer = IDecentralizedApp(Clones.clone(address(frontendVersionViewerImplementation)));
        ClonableFrontendVersionViewer(address(newFrontend.viewer)).initialize(IDecentralizedApp(address(this)), frontendVersions.length - 1);
        
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
    function addFilesToFrontendVersion(uint256 frontendIndex, FileUploadInfos[] memory fileUploadInfos) public payable onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

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
    function appendToFileInFrontendVersion(uint256 frontendIndex, string memory filePath, bytes memory data) public payable onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

        (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, filePath);
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
    function readFileFromFrontendVersion(uint256 frontendIndex, string memory filePath, uint256 chunkId) public view returns (bytes memory data, uint256 nextChunkId) {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        
        (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, filePath);
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
    function renameFilesInFrontendVersion(uint256 frontendIndex, string[] memory oldFilePaths, string[] memory newFilePaths) public onlyOwner frontendLibraryUnlocked {
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
            (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, oldFilePaths[i]);
            if(fileFound == false) {
                revert FileNotFound();
            }
            
            (bool fileFoundAtNewLocation,) = _findFileIndexByNameInFrontendVersion(frontend, newFilePaths[i]);
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
    function removeFilesFromFrontendVersion(uint256 frontendIndex, string[] memory filePaths) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

        for(uint i = 0; i < filePaths.length; i++) {
            (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, filePaths[i]);
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
    function removeAllFilesFromFrontendVersion(uint256 frontendIndex) public onlyOwner frontendLibraryUnlocked  {
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
     * Add a static contract address served at /contractAddresses.json 
     * @param frontendIndex The index of the frontend version
     * @param name The name of the contract address
     * @param addr The address of the contract
     * @param chainId The chain ID of the contract
     */
    function addStaticContractAddressToFrontend(uint256 frontendIndex, string memory name, address addr, uint chainId) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

        // Reserved names
        if(LibStrings.compare(name, "self")) {
            revert ContractAddressNameReserved();
        }
        // Ensure the name was not used yet
        for(uint i = 0; i < frontend.staticContractAddresses.length; i++) {
            if(LibStrings.compare(frontend.staticContractAddresses[i].name, name)) {
                revert ContractAddressNameAlreadyUsed();
            }
        }

        frontend.staticContractAddresses.push(NamedAddressAndChainId(name, addr, chainId));
    }

    /**
     * Remove a static contract address served at /contractAddresses.json 
     * @param frontendIndex The index of the frontend version
     * @param index The index of the contract address to remove
     */
    function removeStaticContractAddressFromFrontend(uint256 frontendIndex, uint index) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

        if(index >= frontend.staticContractAddresses.length) {
            revert IndexOutOfBounds();
        }

        frontend.staticContractAddresses[index] = frontend.staticContractAddresses[frontend.staticContractAddresses.length - 1];
        frontend.staticContractAddresses.pop();
    }

    /**
     * Add a proxied website to a frontend version
     * @param frontendIndex The index of the frontend version
     * @param website The website to proxy
     * @param localPrefix The proxy behavior will be at our local path /{localPrefix}/...
     * @param remotePrefix We will call the proxy at the remote path /{remotePrefix}/...
     */
    function addProxiedWebsiteToFrontend(uint256 frontendIndex, IDecentralizedApp website, string[] memory localPrefix, string[] memory remotePrefix) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

        frontend.proxiedWebsites.push(ProxiedWebsite(website, localPrefix, remotePrefix));
    }

    /**
     * Remove a proxied website from a frontend version
     * @param frontendIndex The index of the frontend version
     * @param index The index of the proxied website to remove
     */
    function removeProxiedWebsiteFromFrontend(uint256 frontendIndex, uint index) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }
        FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        if(frontend.locked) {
            revert FrontendVersionLocked();
        }

        if(index >= frontend.proxiedWebsites.length) {
            revert IndexOutOfBounds();
        }

        frontend.proxiedWebsites[index] = frontend.proxiedWebsites[frontend.proxiedWebsites.length - 1];
        frontend.proxiedWebsites.pop();
    }

    /**
     * Enable/disable the viewing of a non-live frontend version
     * @param frontendIndex The index of the frontend version
     * @param enable Enable or disable the viewer
     */
    function enableViewerForFrontendVersion(uint256 frontendIndex, bool enable) public onlyOwner frontendLibraryUnlocked {
        if(frontendIndex >= frontendVersions.length) {
            revert FrontendIndexOutOfBounds();
        }

        frontendVersions[frontendIndex].isViewable = enable;
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

    /**
     * Lock the whole frontend library
     */
    function lockFrontendLibrary() public onlyOwner {
        frontendLibraryLocked = true;
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
