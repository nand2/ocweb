// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IStorageBackend } from "./IStorageBackend.sol";

// A file : Filename, content type and pointer to the data on an unspecified storage backend
struct FileInfos {
    // The path of the file, without root slash. E.g. "images/logo.png"
    string filePath;
    // The content type of the file, e.g. "image/png"
    string contentType;

    // Pointer to the file contents on a storage backend
    uint contentKey;
    // Is the file complete? Has it been uploaded fully?
    bool complete;
}

// File infos with the storage backend included
struct FileInfosWithStorageBackend {
    FileInfos fileInfos;

    // Storage backend of the file
    IStorageBackend storageBackend;
}

// A set of files making a full frontend, containing static files
// The whole frontend share the same storage backend
struct FrontendFilesSet {
    // The files of the frontend
    FileInfos[] files;

    // Storage backend of the frontend files
    IStorageBackend storageBackend;

    // Description of the frontend
    string description;

    // When locked, the frontend version cannot be modified any longer
    bool locked;
}

