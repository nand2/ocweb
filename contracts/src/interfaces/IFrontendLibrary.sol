// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IFileInfos.sol";
import "./IStorageBackend.sol";

interface IFrontendLibrary {
  // Add/get/remove frontend versions
  function addFrontendVersion(IStorageBackend storageBackend, string memory description) external;
  function getFrontendVersions() external returns (FrontendFilesSet[] memory);
  function getFrontendVersion(uint256 frontendIndex) external view returns (FrontendFilesSet memory);
  function removeFrontendVersion(uint256 frontendIndex) external;

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
    // The data for the storage backend. May be only a part of the file and require
    // subsequent calls to appendToFileInFrontendVersion()
    bytes data;
  }
  function addFilesToFrontendVersion(uint256 frontendIndex, FileUploadInfos[] memory fileUploadInfos) external payable;
  function getFileUploadedSizeInFrontendVersion(uint256 frontendIndex, string memory filePath) external view returns (uint256);
  function appendToFileInFrontendVersion(uint256 frontendIndex, string memory filePath, bytes memory data) external payable;

  // Read a file
  function readFileFromFrontendVersion(uint256 frontendIndex, string memory filePath, uint256 chunkId) external view returns (bytes memory data, uint256 nextChunkId);

  // Remove files
  function removeFilesFromFrontendVersion(uint256 frontendIndex, string[] memory filePaths) external;
  function removeAllFilesFromFrontendVersion(uint256 frontendIndex) external;

  // Lock a frontend version: It won't be editable anymore, and cannot be deleted
  function lockFrontendVersion(uint256 frontendIndex) external;
}