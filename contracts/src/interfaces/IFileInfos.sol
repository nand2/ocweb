// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IStorageBackend } from "./IStorageBackend.sol";
import { IDecentralizedApp } from "./IDecentralizedApp.sol";

enum CompressionAlgorithm {
    NONE,
    GZIP,
    BROTLI
}

// A file : Filename, content type and pointer to the data 
// What remains unspecified: 
// - The storage backend address where the data is stored
// - The total file size (to be fetched from the storage backend)
// - The uploaded size (to be fetched from the storage backend)
struct PartialFileInfos {
    // The path of the file, without root slash. E.g. "images/logo.png"
    string filePath;
    // The content type of the file, e.g. "image/png"
    string contentType;

    // Compression algorithm used for the file data
    CompressionAlgorithm compressionAlgorithm;

    // Pointer to the file contents on a storage backend
    uint contentKey;
}

// File infos with the storage backend included
struct FileInfos {
    PartialFileInfos fileInfos;

    // Storage backend of the file
    IStorageBackend storageBackend;
}

struct NamedAddressAndChainId {
    string name;
    address addr;
    uint chainId;
}

struct ProxiedWebsite {
    // An web3:// resource request mode website, cf ERC-6944 / ERC-5219
    IDecentralizedApp website;
    string[] localPrefix;
    string[] remotePrefix;
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

    // A list of static contract addresses that can be used by the frontend
    // which will be served by the /contractAddresses.json URL
    NamedAddressAndChainId[] staticContractAddresses;

    // A list of websites that can be proxied by this frontend
    // They will be called once no file is found in the frontend
    ProxiedWebsite[] proxiedWebsites;

    // When not the live version, a frontend version can be viewed by this address,
    // which is a clone of a cheap proxy contract
    address viewer;
    bool isViewable;

    // When locked, the frontend version cannot be modified any longer
    bool locked;
}

