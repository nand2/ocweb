// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


struct FileInfos {
    // The path of the file, without root slash. E.g. "images/logo.png"
    string filePath;
    // The content type of the file, e.g. "image/png"
    string contentType;

    // Pointers to the file contents on a storage backend
    uint contentKey;
}

// A version of a frontend, containing some static files
struct FrontendFilesSet {
    // Storage backend for the frontend files
    uint16 storageBackendIndex;

    // The files of the frontend
    FileInfos[] files;

    // Infos about this frontend version
    string infos;

    // When locked, the frontend version cannot be modified any longer
    bool locked;
}

// When we want to store the storage backend of individual files
struct FileInfosWithStorageBackend {
    // Storage backend of the file
    uint16 storageBackendIndex;

    FileInfos fileInfos;
}