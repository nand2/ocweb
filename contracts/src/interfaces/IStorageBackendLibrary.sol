// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IStorageBackend } from "./IStorageBackend.sol";

interface IStorageBackendLibrary {
    function addStorageBackend(IStorageBackend storageBackend) external;
    struct IStorageBackendWithName {
        IStorageBackend storageBackend;
        string name;
    }
    function getStorageBackends() external view returns (IStorageBackendWithName[] memory);
    function getStorageBackendByName(string memory name) external view returns (IStorageBackend);
}