// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IStorageBackend } from "../../interfaces/IStorageBackend.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// Solady
import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibString } from "solady/utils/LibString.sol";

contract StorageBackendSSTORE2 is ERC165, IStorageBackend {

    struct File {
        address[] chunks;
        uint size;
        bool deleted;
    }
    mapping (address => File[]) files;

    // Size of the data that can be stored in a single chunk with SSTORE2
    uint public constant MAX_CHUNK_SIZE = 0x6000 - 1;
    
    function name() public pure returns (string memory) {
        return "sstore2";
    }

    function title() public pure returns (string memory) {
        return "SSTORE2";
    }

    function version() public pure returns (string memory) {
        return "0.1.0";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IStorageBackend).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @param data Initial data to store. Its length can be below the file size, but it must be a multiple of the chunk size if it is not a complete upload.
     * @param fileSize The total filesize of the file to store.
     */
    function create(bytes calldata data, uint fileSize) public payable returns (uint index, uint fundsUsed) {
        require(data.length <= fileSize, "Data length must be less than or equal to file size");

        // Determine the number of chunks. All chunks must be full except the last one.
        uint chunkCount = fileSize / MAX_CHUNK_SIZE;
        if (fileSize % MAX_CHUNK_SIZE != 0) {
            chunkCount++;
        }
        
        File memory file = File({
            chunks: new address[](chunkCount),
            size: fileSize,
            deleted: false
        });

        // If not a complete upload: Ensure all chunks are full
        if(data.length != fileSize) {
            require(data.length % MAX_CHUNK_SIZE == 0, "Data length must be a multiple of the chunk size");
        }

        // Determine the number of chunks to write
        uint chunksToAdd = data.length / MAX_CHUNK_SIZE;
        if(data.length % MAX_CHUNK_SIZE != 0) {
            chunksToAdd++;
        }
        
        uint remainingBytes = data.length;
        for(uint i = 0; i < chunksToAdd; i++) {
            uint chunkSize = remainingBytes > MAX_CHUNK_SIZE ? MAX_CHUNK_SIZE : remainingBytes;
            bytes memory chunk = bytes(LibString.slice(string(data), i * MAX_CHUNK_SIZE, i * MAX_CHUNK_SIZE + chunkSize));
            file.chunks[i] = SSTORE2.write(chunk);
        }

        files[msg.sender].push(file);

        fundsUsed = 0;
        return (files[msg.sender].length - 1, fundsUsed);
    }

    function append(uint index, bytes calldata data) public payable returns (uint fundsUsed) {
        require(index < files[msg.sender].length, "File not found");
        File storage file = files[msg.sender][index];
        require(file.chunks[file.chunks.length - 1] == address(0), "File is already complete");
        require(file.deleted == false, "File is deleted");
        
        // Find the first empty chunk pointer
        uint startingChunkIndex = 0;
        while(file.chunks[startingChunkIndex] != address(0)) {
            startingChunkIndex++;
        }
        
        // Determine how many chunks we need to write
        uint chunksToAdd = data.length / MAX_CHUNK_SIZE;
        if(data.length % MAX_CHUNK_SIZE != 0) {
            chunksToAdd++;
        }
        // Too much data?
        require(startingChunkIndex + (chunksToAdd - 1) < file.chunks.length, "Too much data");
        // If we are not finishing the file, we must only write full chunks
        if(startingChunkIndex + (chunksToAdd - 1) < file.chunks.length - 1) {
            require(data.length == MAX_CHUNK_SIZE * chunksToAdd, "Data length must be a multiple of the chunk size");
        }
        // If we are finishing, the data length must be equal to the remaining size
        else {
            require(data.length == file.size - _uploadedSize(msg.sender, index), "Data length must be equal to the remaining size");
        }

        uint remainingBytes = data.length;
        for(uint i = startingChunkIndex; i < startingChunkIndex + chunksToAdd; i++) {
            uint chunkSize = remainingBytes > MAX_CHUNK_SIZE ? MAX_CHUNK_SIZE : remainingBytes;
            bytes memory chunk = bytes(LibString.slice(string(data), (i - startingChunkIndex) * MAX_CHUNK_SIZE, (i - startingChunkIndex) * MAX_CHUNK_SIZE + chunkSize));
            file.chunks[i] = SSTORE2.write(chunk);
        }

        fundsUsed = 0;
        return fundsUsed;
    }

    function remove(uint index) public {
        require(index < files[msg.sender].length, "File not found");
        File memory file = files[msg.sender][index];

        require(file.deleted == false, "File is deleted");
        files[msg.sender][index].deleted = true;
    }
    
    function _uploadedSize(address owner, uint index) internal view returns (uint) {
        File memory file = files[owner][index];

        // IF the file is not complete yet
        if(file.chunks[file.chunks.length - 1] == address(0)) {
            // Count the number of chunks that are not empty
            uint count = 0;
            for(uint i = 0; i < file.chunks.length; i++) {
                if(file.chunks[i] != address(0)) {
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

    function sizeAndUploadSizes(address owner, uint[] memory indexes) public view returns (Sizes[] memory) {
        Sizes[] memory results = new Sizes[](indexes.length);
        for(uint i = 0; i < indexes.length; i++) {
            require(indexes[i] < files[owner].length, "File not found");
            results[i].size = files[owner][indexes[i]].size;
            results[i].uploadedSize = _uploadedSize(owner, indexes[i]);
        }
        return results;
    }

    function getReadChainId() public view returns (uint) {
        return block.chainid;
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
        require(startingChunkId < file.chunks.length, "Chunk not found");

        // Read as much chunks as possible, but keep a wide margin (50%)
        uint initialGasLeft = gasleft();
        uint maxGasUsage = initialGasLeft / 2;
        nextChunkId = startingChunkId;
        while(initialGasLeft - gasleft() < maxGasUsage) {
            result = bytes.concat(result, SSTORE2.read(file.chunks[nextChunkId]));
            nextChunkId++;

            if(nextChunkId >= file.chunks.length) {
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
}