// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IStorageBackend } from "./IStorageBackend.sol";

enum CompressionAlgorithm {
    NONE,
    GZIP,
    BROTLI
}

// A file : Filename, content type and pointer to the data 
// What remains unspecified: The storage backend address where the data is stored
struct PartialFileInfos {
    // The path of the file, without root slash. E.g. "images/logo.png"
    string filePath;
    // The content type of the file, e.g. "image/png"
    string contentType;

    // Compression algorithm used for the file data
    CompressionAlgorithm compressionAlgorithm;
    // Is the file complete? Has it been uploaded fully?
    bool complete;

    // Pointer to the file contents on a storage backend
    uint contentKey;
}

// File infos with the storage backend included
struct FileInfos {
    PartialFileInfos fileInfos;

    // Storage backend of the file
    IStorageBackend storageBackend;
}

// A set of files making a full frontend, containing static files
// The whole frontend share the same storage backend
struct FrontendFilesSet {
    // The files of the frontend
    PartialFileInfos[] files;

    // Storage backend of the frontend files
    IStorageBackend storageBackend;

    // Description of the frontend
    string description;

    // When locked, the frontend version cannot be modified any longer
    bool locked;
}

