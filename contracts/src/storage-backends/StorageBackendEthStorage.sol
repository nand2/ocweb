// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IStorageBackend} from "./interfaces/IStorageBackend.sol";

// EthStorage
import {TestEthStorageContractKZG} from "storage-contracts-v1/TestEthStorageContractKZG.sol";
import { DecentralizedKV } from "storage-contracts-v1/DecentralizedKV.sol";

contract StorageBackendEthStorage is IStorageBackend {

    struct File {
        bytes32[] chunkIds;
        uint size;
        bool deleted;
    }
    mapping (address => File[]) files;

    // Size of the data that can be stored in a single chunk in a blob
    uint public MAX_CHUNK_SIZE = (32 - 1) * 4096;
    
    // EthStorage contract
    TestEthStorageContractKZG public ethStorage;
    // EthStorage content keys: we use a simple incrementing key
    uint256 public ethStorageLastUsedKey = 0;
    // When deleting files, we store the keys to reuse them (we don't need to pay EthStorage again)
    mapping(address => bytes32[]) public reusableEthStorageKeys;


    constructor(TestEthStorageContractKZG _ethStorage) {
        ethStorage = _ethStorage;
    }

    function backendName() public pure returns (string memory) {
        return "EthStorage";
    }

    /**
     * @param data abi.encoded structure: array of uint256 containing the data size of the blobs
     * @param fileSize The total filesize of the file to store.
     */
    function create(bytes memory data, uint fileSize) public returns (uint index, uint fundsUsed) {
        // Determine the number of chunks. All chunks must be full except the last one.
        uint chunkCount = fileSize / MAX_CHUNK_SIZE;
        if (fileSize % MAX_CHUNK_SIZE != 0) {
            chunkCount++;
        }

        // Decode args: Get the starting blob index, and the blob data sizes
        (uint startingBlobIndex, uint[] memory blobDataSizes) = abi.decode(data, (uint, uint[]));

        // Check that the blob data sizes are correct
        require(blobDataSizes.length <= chunkCount, "Too many blob data sizes");
        uint totalSize = 0;
        for(uint i = 0; i < blobDataSizes.length; i++) {
            if(i < chunkCount - 1) {
                require(blobDataSizes[i] == MAX_CHUNK_SIZE, "Blob must be full");
            }
            
            totalSize += blobDataSizes[i];

            // Note that not all blobs may be given in this create() call
            if(i == blobDataSizes.length - 1) {
                require(totalSize == fileSize, "Total blob data size must be equal to the given file size");
            }
        }
        
        File memory file = File({
            chunkIds: new bytes32[](chunkCount),
            size: fileSize,
            deleted: false
        });

        for(uint i = 0; i < blobDataSizes.length; i++) {
            uint payment = 0;

            if(reusableEthStorageKeys[msg.sender].length > 0) {
                file.chunkIds[i] = reusableEthStorageKeys[msg.sender][reusableEthStorageKeys[msg.sender].length - 1];
                reusableEthStorageKeys[msg.sender].pop();
            }
            else {
                ethStorageLastUsedKey++;
                file.chunkIds[i] = bytes32(ethStorageLastUsedKey);
                payment = ethStorage.upfrontPayment();
            }
            ethStorage.putBlob{value: payment}(file.chunkIds[i], startingBlobIndex + i, blobDataSizes[i]);
            fundsUsed += payment;
        }

        files[msg.sender].push(file);

        return (files[msg.sender].length - 1, fundsUsed);
    }

    function append(uint index, bytes memory data) public returns (uint fundsUsed) {
        require(index < files[msg.sender].length, "File not found");
        File storage file = files[msg.sender][index];
        require(file.chunkIds[file.chunkIds.length - 1] == 0, "File is already complete");
        require(file.deleted == false, "File is deleted");
        
        // Find the first empty chunk pointer
        uint startingChunkIdIndex = 0;
        while(file.chunkIds[startingChunkIdIndex] != 0) {
            startingChunkIdIndex++;
        }

        // Decode args: Get the starting blob index, and the blob data sizes
        (uint startingBlobIndex, uint[] memory blobDataSizes) = abi.decode(data, (uint, uint[]));
        
        // Too much blobs?
        require(startingChunkIdIndex + (blobDataSizes.length - 1) < file.chunkIds.length, "Too much blobs");
        // Check that the blob data sizes are correct
        uint totalSize = startingChunkIdIndex * MAX_CHUNK_SIZE;
        for(uint i = startingChunkIdIndex; i < blobDataSizes.length; i++) {
            if(i < file.chunkIds.length - 1) {
                require(blobDataSizes[i] == MAX_CHUNK_SIZE, "Blob must be full");
            }
            
            totalSize += blobDataSizes[i];

            // Note that not all blobs may be given in this create() call
            if(i == blobDataSizes.length - 1) {
                require(totalSize == file.size, "Last blob data size must be equal to the remaining size");
            }
        }

        for(uint i = startingChunkIdIndex; i < blobDataSizes.length; i++) {
            uint payment = 0;

            if(reusableEthStorageKeys[msg.sender].length > 0) {
                file.chunkIds[i] = reusableEthStorageKeys[msg.sender][reusableEthStorageKeys[msg.sender].length - 1];
                reusableEthStorageKeys[msg.sender].pop();
            }
            else {
                ethStorageLastUsedKey++;
                file.chunkIds[i] = bytes32(ethStorageLastUsedKey);
                payment = ethStorage.upfrontPayment();
            }
            ethStorage.putBlob{value: payment}(file.chunkIds[i], startingBlobIndex + i, blobDataSizes[i]);
            fundsUsed += payment;
        }

        return fundsUsed;
    }

    function remove(uint index) public {
        require(index < files[msg.sender].length, "File not found");
        File memory file = files[msg.sender][index];

        require(file.deleted == false, "File is deleted");
        files[msg.sender][index].deleted = true;

        // Store the keys to reuse them
        for(uint i = 0; i < file.chunkIds.length; i++) {
            reusableEthStorageKeys[msg.sender].push(file.chunkIds[i]);
        }
    }

    function isComplete(address owner, uint index) public view returns (bool) {
        require(index < files[owner].length, "File not found");
        
        File memory file = files[owner][index];
        return file.chunkIds[file.chunkIds.length - 1] != 0;
    }
    
    function uploadedSize(address owner, uint index) public view returns (uint) {
        require(index < files[owner].length, "File not found");
        File memory file = files[owner][index];

        if(isComplete(owner, index) == false) {
            // Count the number of chunks that are not empty
            uint count = 0;
            for(uint i = 0; i < file.chunkIds.length; i++) {
                if(file.chunkIds[i] != 0) {
                    count++;
                }
                else {
                    break;
                }
            }
            return count * MAX_CHUNK_SIZE;
        }
        
        return file.size;
    }

    function size(address owner, uint index) public view returns (uint) {
        require(index < files[owner].length, "File not found");
        return files[owner][index].size;
    }

    /**
     * Read the file starting from a specific chunk.
     * @param index The index of the file to read.
     * @param startingChunkId The index of the chunk to start reading from.
     * @return result The data read.
     * @return nextChunkId The index of the next chunk to read from. 0 if the file is fully read.
     */
    function read(address owner, uint index, uint startingChunkId) public view returns (bytes memory result, uint nextChunkId) {
        require(index < files[owner].length, "File not found");
        File memory file = files[owner][index];
        require(file.deleted == false, "File is deleted");
        require(startingChunkId < file.chunkIds.length, "Chunk not found");

        // Read as much chunks as possible, but keep a wide margin (50%)
        uint initialGasLeft = gasleft();
        uint maxGasUsage = initialGasLeft / 2;
        nextChunkId = startingChunkId;
        while(initialGasLeft - gasleft() < maxGasUsage) {
            result = bytes.concat(result, ethStorage.get(
                file.chunkIds[nextChunkId], 
                DecentralizedKV.DecodeType.PaddingPer31Bytes, 
                0, 
                ethStorage.size(file.chunkIds[nextChunkId])));
            nextChunkId++;

            if(nextChunkId >= file.chunkIds.length) {
                nextChunkId = 0;
                break;
            }
        }

        return (result, nextChunkId);
    }



    /**
     * Non-IStorageBackend functions
     */

    function getFileStruct(address owner, uint index) public view returns (File memory) {
        require(index < files[owner].length, "File not found");
        return files[owner][index];
    }

    function blobStorageUpfrontCost() public view returns (uint) {
        return ethStorage.upfrontPayment();
    }
}