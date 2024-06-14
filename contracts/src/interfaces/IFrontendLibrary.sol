// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./FileInfos.sol";
import "./IStorageBackend.sol";
// EthFs
import {FileStore} from "ethfs/FileStore.sol";

interface IFrontendLibrary {
  function getStorageBackendIndexByName(string memory name) external view returns (uint16 index);
  function getStorageBackend(uint16 index) external view returns (IStorageBackend storageBackend);

  function addFrontendVersion(uint16 storageBackendIndex, string memory _infos) external;
  struct FileUploadInfos {
    // The path of the file, without root slash. E.g. "images/logo.png"
    string filePath;
    // The file size
    uint256 fileSize;
    // The content type of the file, e.g. "image/png"
    string contentType;
    // The data of the file for the storage backend
    bytes data;
  }
  function addFilesToCurrentFrontendVersion(FileUploadInfos[] memory fileUploadInfos) external payable;
  function appendToFileInCurrentFrontendVersion(uint256 fileIndex, bytes memory data) external payable;

  function lockLatestFrontendVersion() external;
  function resetLatestFrontendVersion() external;

  function frontendVersionsCount() external view returns (uint256);
  function getFrontendVersion(uint256 _index) external view returns (FrontendFilesSet memory);
  function setDefaultFrontend(uint256 _index) external;
  function getDefaultFrontend() external view returns (FrontendFilesSet memory);
}