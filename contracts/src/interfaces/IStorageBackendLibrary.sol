// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IStorageBackend } from "./IStorageBackend.sol";

interface IStorageBackendLibrary {
    function addStorageBackend(IStorageBackend storageBackend) external;
    struct IStorageBackendWithInfos {
        IStorageBackend storageBackend;
        string name;
        string title;
        string version;
        bool interfaceValid;
    }
    function getStorageBackends(bytes4[] memory interfaceFilters) external view returns (IStorageBackendWithInfos[] memory);
    function getStorageBackendByName(string memory name) external view returns (IStorageBackend);
}