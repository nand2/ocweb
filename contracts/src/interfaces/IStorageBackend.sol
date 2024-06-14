// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStorageBackend {
    function name() external view returns (string memory);

    // Create a new file of a specified size
    // data can be either the actual data, or an abi-encoded struct
    // Only a portion of the data can be uploaded first, and subsequent calls to append() will be needed
    function create(bytes memory data, uint fileSize) external payable returns (uint index, uint fundsUsed);
    // Append data to an existing file
    function append(uint index, bytes memory data) external payable returns (uint fundsUsed);
    // Remove a file: It won't be accessible anymore
    function remove(uint index) external;
    
    // Is a file complete, i.e. if it was necessary, has all the calls to append() been made?
    function isComplete(address owner, uint index) external view returns (bool);
    // The currently uploaded size to the file. Can be below size() if not complete
    function uploadedSize(address owner, uint index) external view returns (uint);
    // The total size of the file
    function size(address owner, uint index) external view returns (uint);

    // Read the file contents, starting from a chunk ID
    // It will try to read as much as possible in a single call, and may return 
    // a nextChunkId if the data is too large to fit in a single call
    function read(address owner, uint index, uint startingChunkId) external view returns (bytes memory result, uint nextChunkId);
}