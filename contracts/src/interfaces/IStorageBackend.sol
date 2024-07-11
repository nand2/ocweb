// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IStorageBackend is IERC165 {
    // Technical name
    function name() external view returns (string memory);
    // Human title
    function title() external view returns (string memory);
    function version() external view returns (string memory);

    // Create a new file of a specified size
    // data can be either the actual data, or an abi-encoded struct
    // Only a portion of the data can be uploaded first, and subsequent calls to append() will be needed
    function create(bytes calldata data, uint fileSize) external payable returns (uint index, uint fundsUsed);
    // Append data to an existing file
    function append(uint index, bytes calldata data) external payable returns (uint fundsUsed);
    // Remove a file: It won't be accessible anymore
    function remove(uint index) external;
    
    // The sizes of the files, and their uploaded sizes. If uploadedSize < size, 
    // the file upload is not complete
    struct Sizes {
        uint256 size;
        // If uploadedSize < size, the file is not complete
        uint256 uploadedSize;
    }
    function sizeAndUploadSizes(address owner, uint[] memory indexes) external view returns (Sizes[] memory);

    // Some storage backends (e.g. EthStorage) require a different chain ID to read the data
    // than to store the data. This function returns the chain ID to use to read the data
    function getReadChainId() external view returns (uint);
    // Read the file contents, starting from a chunk ID
    // It will try to read as much as possible in a single call, and may return 
    // a nextChunkId if the data is too large to fit in a single call
    function read(address owner, uint index, uint startingChunkId) external view returns (bytes memory result, uint nextChunkId);
}