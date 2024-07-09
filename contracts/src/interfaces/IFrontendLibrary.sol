// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IFileInfos.sol";
import "./IStorageBackend.sol";

interface IFrontendLibrary {
    error IndexOutOfBounds();
    error FrontendLibraryLocked();
    error FrontendIndexOutOfBounds();
    error FrontendVersionLocked();
    error FrontendVersionIsAlreadyLocked();
    error FileNotFound();
    error FileAlreadyExistsAsDirectory();
    error FileAlreadyExistsAtNewLocation();
    error ArraysLengthMismatch();
    error ContractAddressNameReserved();
    error ContractAddressNameAlreadyUsed();

    // Add/get/remove frontend versions
    function addFrontendVersion(IStorageBackend storageBackend, string memory description) external;
    function getFrontendVersionCount() external view returns (uint);
    function getFrontendVersions(uint startIndex, uint count) external view returns (FrontendFilesSet[] memory, uint totalCount);
    function getFrontendVersion(uint256 frontendIndex) external view returns (FrontendFilesSet memory);
    function renameFrontendVersion(uint256 frontendIndex, string memory newDescription) external;

    // Get/set the default frontend version used in the website
    function getDefaultFrontendIndex() external view returns (uint256 frontendIndex);
    function setDefaultFrontendIndex(uint256 frontendIndex) external;

    // Add several files to a frontend version
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
        // subsequent calls to appendToFileInFrontendVersion()
        bytes data;
    }
    function addFilesToFrontendVersion(uint256 frontendIndex, FileUploadInfos[] memory fileUploadInfos) external payable;
    function appendToFileInFrontendVersion(uint256 frontendIndex, string memory filePath, bytes memory data) external payable;

    // Read a file
    function readFileFromFrontendVersion(uint256 frontendIndex, string memory filePath, uint256 chunkId) external view returns (bytes memory data, uint256 nextChunkId);

    // Rename files
    function renameFilesInFrontendVersion(uint256 frontendIndex, string[] memory oldFilePaths, string[] memory newFilePaths) external;

    // Remove files
    function removeFilesFromFrontendVersion(uint256 frontendIndex, string[] memory filePaths) external;
    function removeAllFilesFromFrontendVersion(uint256 frontendIndex) external;

    // Lock a frontend version: It won't be editable anymore, and cannot be deleted
    function lockFrontendVersion(uint256 frontendIndex) external;
    // Lock the whole frontend library
    function lock() external;
    function isLocked() external view returns (bool);

    // Get the list of supported storage backend interfaces
    function getSupportedStorageBackendInterfaces() external view returns (bytes4[] memory);
}