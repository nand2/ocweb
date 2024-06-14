// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { Strings } from "../library/Strings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IFrontendLibrary.sol";
import "../interfaces/IStorageBackend.sol";
import "./FrontendLibrary.sol";
import "./StaticWebsite.sol";

contract OCWebsite is FrontendLibrary, FrontendWebsite {

    constructor(address owner, IFrontendLibrary _frontendLibrary) FrontendWebsite(owner) FrontendWebsite(_frontendLibrary) {
    }

    // FrontendFilesSet[] public frontendVersions;
    // // The index of the frontend being used
    // uint256 public defaultFrontendIndex;

    // // The owner of the website
    // address public owner;
    // // An optional controller for the ownership. 
    // // E.g. if this OCWebsite is created as an ERC721 token, the ownership 
    // // controller will be the ERC721 contract
    // // If the ownership controller is set, the ownership controller only can transfer the ownership
    // // If the ownership controller is not set, the owner only can transfer the ownership
    // address public ownershipController;

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "Not owner");
    //     _;
    // }

    // modifier onlyOwnershipControllerOrOwnerIfNotSet() {
    //     require(
    //         (ownershipController != address(0) && msg.sender == ownershipController) || 
    //         (ownershipController == address(0) && msg.sender == owner), "Not authorized");
    //     _;
    // }

    // constructor() {}

    // /**
    //  * Initialize the OCWebsite after a cloning.
    //  * @param _owner The owner of the website
    //  * @param _ownershipController The controller of the ownership. Can be null.
    //  */
    // function initialize(address _owner, address _ownershipController) public {
    //     require(owner == address(0), "Already initialized");
    //     owner = _owner;
    //     ownershipController = _ownershipController;
    // }

    // /**
    //  * Transfer the ownership of the website. If there is a controller for the ownership,
    //  * only the controller can transfer the ownership. If there is no controller, the owner only
    //  * can transfer the ownership.
    //  * @param _newOwner The new owner of the website
    //  */
    // function transferOwnership(address _newOwner) public onlyOwnershipControllerOrOwnerIfNotSet {
    //     owner = _newOwner;
    // }


    // //
    // // IFrontendLibrary implementation
    // //

    // /**
    //  * Add a new frontend version
    //  * @param storageBackend Address of the storage backend
    //  * @param _description A description of the frontend version
    //  */
    // function addFrontendVersion(IStorageBackend storageBackend, string memory _description) public onlyOwner {
    //     frontendVersions.push();
    //     FrontendFilesSet storage newFrontend = frontendVersions[frontendVersions.length - 1];
    //     newFrontend.storageBackend = storageBackend;
    //     newFrontend.description = _description;
    // }

    // /**
    //  * Get all frontend versions
    //  */
    // function getFrontendVersions() public returns (FrontendFilesSet[] memory) {
    //     return frontendVersions;
    // }

    // /**
    //  * Get a frontend version
    //  */
    // function getFrontendVersion(uint256 frontendIndex) public view returns (FrontendFilesSet memory) {
    //     require(frontendIndex < frontendVersions.length, "Index out of bounds");
    //     return frontendVersions[frontendIndex];
    // }

    // /**
    //  * Remove a frontend version
    //  * @param frontendIndex The index of the frontend version
    //  */
    // function removeFrontendVersion(uint256 frontendIndex) public onlyOwner {
    //     require(frontendIndex < frontendVersions.length, "Index out of bounds");
    //     require(!frontendVersions[frontendIndex].locked, "Frontend version is locked");
    //     frontendVersions[frontendIndex] = frontendVersions[frontendVersions.length - 1];
    //     frontendVersions.pop();
    // }

    // /**
    //  * Get the default frontend version used in the website
    //  */
    // function getDefaultFrontendIndex() public view returns (uint256 frontendIndex) {
    //     return defaultFrontendIndex;
    // }

    // /**
    //  * Set the default frontend version used in the website
    //  * @param frontendIndex The index of the frontend version
    //  */
    // function setDefaultFrontendIndex(uint256 frontendIndex) public onlyOwner {
    //     require(frontendIndex < frontendVersions.length, "Index out of bounds");
    //     defaultFrontendIndex = frontendIndex;
    // }

    // /**
    //  * Add several files to a frontend version. If a file already exists, it is replaced.
    //  * @param frontendIndex The index of the frontend version
    //  * @param fileUploadInfos The files to add
    //  */
    // function addFilesToFrontendVersion(uint256 frontendIndex, FileUploadInfos[] memory fileUploadInfos) public payable onlyOwner {
    //     require(frontendIndex < frontendVersions.length, "Index out of bounds");
    //     FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
    //     require(!frontend.locked, "Frontend version is locked");

    //     uint totalFundsUsed = 0;
    //     for(uint i = 0; i < fileUploadInfos.length; i++) {
    //         // Search if the file already exists
    //         (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, fileUploadInfos[i].filePath);
    //         // If it does, remove it from the storage backend
    //         // (we do it before the create, as remove() may free a slot for the new file in the
    //         // storage backend)
    //         if(fileFound) {
    //             frontend.storageBackend.remove(frontend.files[fileIndex].contentKey);
    //         }

    //         // Create the new file on the storage backend
    //         (uint contentKey, uint fundsUsed) = frontend.storageBackend.create(fileUploadInfos[i].data, fileUploadInfos[i].fileSize);
    //         totalFundsUsed += fundsUsed;

    //         // If the file was found, reuse the existing fileInfos entry
    //         if(fileFound) {
    //             frontend.files[fileIndex].contentKey = contentKey;
    //             frontend.files[fileIndex].contentType = fileUploadInfos[i].contentType;
    //             frontend.files[fileIndex].complete = frontend.storageBackend.isComplete(contentKey);
    //         }
    //         // If not found, add the file
    //         else {
    //             FileInfos memory fileInfos = FileInfos({
    //                 contentKey: contentKey,
    //                 filePath: fileUploadInfos[i].filePath,
    //                 contentType: fileUploadInfos[i].contentType,
    //                 complete: frontend.storageBackend.isComplete(contentKey)
    //             });
    //             frontend.files.push(fileInfos);
    //         }
    //     }

    //     // Send back remaining funds sent by the caller
    //     if(msg.value - totalFundsUsed > 0) {
    //         payable(msg.sender).transfer(msg.value - totalFundsUsed);
    //     }
    // }

    // /**
    //  * Get the uploaded size of a file in a frontend version.
    //  * @param frontendIndex The index of the frontend version
    //  * @param filePath The path of the file to read
    //  */
    // function getFileUploadedSizeInFrontendVersion(uint256 frontendIndex, string memory filePath) public view returns (uint256) {
    //     require(frontendIndex < frontendVersions.length, "Index out of bounds");
    //     FrontendFilesSet storage frontend = frontendVersions[frontendIndex];

    //     for(uint i = 0; i < frontend.files.length; i++) {
    //         if(Strings.compare(filePath, frontend.files[i].filePath)) {
    //             return frontend.storageBackend.uploadedSize(frontend.files[i].contentKey);
    //         }
    //     }

    //     return 0;
    // }

    // /**
    //  * Append data to a file in a frontend version.
    //  * @param frontendIndex The index of the frontend version
    //  * @param filePath The path of the file to read
    //  * @param data The data to give to the storage backend
    //  */
    // function appendToFileInFrontendVersion(uint256 frontendIndex, string memory filePath, bytes memory data) public payable onlyOwner {
    //     require(frontendIndex < frontendVersions.length, "Index out of bounds");
    //     FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
    //     require(!frontend.locked, "Frontend version is locked");

    //     (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, filePath);
    //     require(fileFound, "File not found");

    //     uint fundsUsed = frontend.storageBackend.append(frontend.files[fileIndex].contentKey, data);

    //     // Send back remaining funds sent by the caller
    //     if(msg.value - fundsUsed > 0) {
    //         payable(msg.sender).transfer(msg.value - fundsUsed);
    //     }
    // }

    // /**
    //  * Read a file from a frontend version. It will read as much chunks as possible.
    //  * @param frontendIndex The index of the frontend version
    //  * @param filePath The path of the file to read
    //  * @param chunkId The starting chunk ID
    //  * @return result The read data
    //  * @return nextChunkId The next chunk ID to read. 0 if none.
    //  */
    // function readFileFromFrontendVersion(uint256 frontendIndex, string memory filePath, uint256 chunkId) public view returns (bytes memory data, uint256 nextChunkId) {
    //     require(frontendIndex < frontendVersions.length, "Index out of bounds");
    //     FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
        
    //     (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, filePath);
    //     require(fileFound, "File not found");

    //     (data, nextChunkId) = frontend.storageBackend.read(address(this), frontend.files[fileIndex].contentKey, chunkId);
    // }

    // /**
    //  * Remove files from the backend
    //  * @param frontendIndex The index of the frontend version
    //  * @param filePaths The paths of the files to remove
    //  */
    // function removeFilesFromFrontendVersion(uint256 frontendIndex, string[] memory filePaths) public onlyOwner {
    //     require(frontendIndex < frontendVersions.length, "Index out of bounds");
    //     FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
    //     require(!frontend.locked, "Frontend version is locked");

    //     for(uint i = 0; i < filePaths.length; i++) {
    //         (bool fileFound, uint fileIndex) = _findFileIndexByNameInFrontendVersion(frontend, filePaths[i]);
    //         if(fileFound) {
    //             frontend.storageBackend.remove(frontend.files[fileIndex].contentKey);
    //             frontend.files[fileIndex] = frontend.files[frontend.files.length - 1];
    //             frontend.files.pop();
    //         }
    //     }
    // }

    // /**
    //  * Remove all files from a frontend version
    //  * @param frontendIndex The index of the frontend version
    //  */
    // function removeAllFilesFromFrontendVersion(uint256 frontendIndex) public onlyOwner {
    //     require(frontendIndex < frontendVersions.length, "Index out of bounds");
    //     FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
    //     require(!frontend.locked, "Frontend version is locked");

    //     for(uint i = 0; i < frontend.files.length; i++) {
    //         frontend.storageBackend.remove(frontend.files[i].contentKey);
    //         frontend.files.pop();
    //     }
    // }

    // /**
    //  * Lock a frontend version
    //  * @param frontendIndex The index of the frontend version
    //  */
    // function lockFrontendVersion(uint256 frontendIndex) public onlyOwner {
    //     require(frontendIndex < frontendVersions.length, "Index out of bounds");
    //     FrontendFilesSet storage frontend = frontendVersions[frontendIndex];
    //     require(!frontend.locked, "Frontend version is already locked");
    //     frontend.locked = true;
    // }

    // function _findFileIndexByNameInFrontendVersion(FrontendFilesSet storage frontend, string memory filePath) internal view returns (bool, uint) {
    //     for(uint i = 0; i < frontend.files.length; i++) {
    //         if(Strings.compare(filePath, frontend.files[i].filePath)) {
    //             return (true, i);
    //         }
    //     }
    //     return (false, 0);
    // }


    // //
    // // web3:// protocol part
    // //

    // // Indicate we are serving a website with the resource request mode
    // function resolveMode() external pure returns (bytes32) {
    //     return "5219";
    // }

    // // Implementation for the ERC-5219 resource request mode
    // function request(string[] memory resource, KeyValue[] memory params) external view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
    //     FrontendFilesSet memory frontend = frontendVersion();

    //     // Compute the filePath of the requested resource
    //     string memory filePath = "";
    //     // Root path requested("/")? Serve the index.html
    //     // We handle frontpage or single-page javascript app pages (#/page/1, #/page/2, etc.)
    //     // -> At the moment, in EVM browser, proper SPA routing in JS with history.pushState() 
    //     // is broken (due to bad web3:// URL parsing in the browser)
    //     // Todo: clarify the behavior of the "#" character in resourceRequest mode, this 
    //     // character is not forwarded to the web server in HTTP
    //     if(resource.length == 0 || Strings.compare(resource[0], "#")) {
    //         filePath = "index.html";
    //     }
    //     else {
    //         for(uint i = 0; i < resource.length; i++) {
    //             if(i > 0) {
    //                 filePath = string.concat(filePath, "/");
    //             }
    //             filePath = string.concat(filePath, resource[i]);
    //         }
    //     }

    //     // Search for the requested resource in our static file list
    //     for(uint i = 0; i < frontend.files.length; i++) {
    //         if(Strings.compare(filePath, frontend.files[i].filePath)) {
    //             // web3:// chunk feature : if the file is big, we will send the file
    //             // in chunks
    //             // Determine the requested chunk
    //             uint chunkIndex = 0;
    //             for(uint j = 0; j < params.length; j++) {
    //                 if(Strings.compare(params[j].key, "chunk")) {
    //                     chunkIndex = Strings.stringToUint(params[j].value);
    //                     break;
    //                 }
    //             }

    //             IStorageBackend storageBackend = blogFactory.storageBackends(frontend.storageBackendIndex);
    //             (bytes memory data, uint nextChunkId) = storageBackend.read(address(this), frontend.files[i].contentKey, chunkIndex);
    //             body = string(data);
    //             statusCode = 200;

    //             uint headersCount = 2;
    //             if(nextChunkId > 0) {
    //                 headersCount = 3;
    //             }
    //             headers = new KeyValue[](headersCount);
    //             headers[0].key = "Content-type";
    //             headers[0].value = frontend.files[i].contentType;
    //             headers[1].key = "Content-Encoding";
    //             headers[1].value = "gzip";
    //             // If there is more chunk remaining, add a pointer to the next chunk
    //             if(nextChunkId > 0) {
    //                 headers[2].key = "web3-next-chunk";
    //                 headers[2].value = string.concat("/", filePath, "?chunk=", Strings.toString(nextChunkId));
    //             }

    //             return (statusCode, body, headers);
    //         }
    //     }

    //     // blogFactoryAddress.json : it exposes the addess of the blog factory
    //     if(resource.length == 1 && Strings.compare(resource[0], "blogFactoryAddress.json")) {
    //         uint chainid = block.chainid;
    //         // Special case: Sepolia chain id 11155111 is > 65k, which breaks URL parsing in EVM browser
    //         // As a temporary measure, we will test Sepolia with a fake chain id of 11155
    //         // if(chainid == 11155111) {
    //         //     chainid = 11155;
    //         // }
    //         // Manual JSON serialization, safe with the vars we encode
    //         body = string.concat("{\"address\":\"", Strings.toHexString(address(blogFactory)), "\", \"chainId\":", Strings.toString(chainid), "}");
    //         statusCode = 200;
    //         headers = new KeyValue[](1);
    //         headers[0].key = "Content-type";
    //         headers[0].value = "application/json";
    //         return (statusCode, body, headers);
    //     }
        
    //     statusCode = 404;
    // }

}
