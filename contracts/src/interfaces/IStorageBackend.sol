// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStorageBackend {
    function backendName() external view returns (string memory);

    function create(bytes memory data, uint fileSize) external returns (uint index, uint fundsUsed);
    function append(uint index, bytes memory data) external returns (uint fundsUsed);
    function remove(uint index) external;
    
    function isComplete(address owner, uint index) external view returns (bool);
    function uploadedSize(address owner, uint index) external view returns (uint);
    function size(address owner, uint index) external view returns (uint);

    function read(address owner, uint index, uint startingChunkId) external view returns (bytes memory result, uint nextChunkId);
}