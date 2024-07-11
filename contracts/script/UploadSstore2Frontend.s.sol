// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LibString} from "solady/utils/LibString.sol";

import "../src/interfaces/IFrontendLibrary.sol";
import "../src/interfaces/IStorageBackendLibrary.sol";
import "../src/interfaces/IStorageBackend.sol";
import "../src/OCWebsite/plugins/StaticFrontendPlugin.sol";
import "../src/library/LibStrings.sol";

contract UploadSstore2Frontend is Script {

    function setUp() public {}

    struct FileNameAndCompressedName {
        string filename;
        string compressedFileName;
        string mimeType;
        string subFolder;
    }
    function run() public {
        vm.startBroadcast();

        IVersionableStaticWebsite versionableStaticWebsite = IVersionableStaticWebsite(vm.envAddress("IFRONTEND_LIBRARY_CONTRACT_ADDRESS"));

        StaticFrontendPlugin staticFrontendPlugin = StaticFrontendPlugin(vm.envAddress("STATIC_FRONTEND_PLUGIN_ADDRESS"));

        // If there is already a frontend version which is unlocked, we wipe it and replace it
        (,uint256 websiteVersionCount) = versionableStaticWebsite.getWebsiteVersions(0, 0);
        if(websiteVersionCount > 0 && versionableStaticWebsite.getWebsiteVersion(websiteVersionCount - 1).locked == false) {
            console.log("Resetting and replacing latest frontend version");
            staticFrontendPlugin.removeAllFiles(versionableStaticWebsite, websiteVersionCount - 1);
        }
        // Otherwise we add a new version
        else {
            console.log("Adding new frontend version");

            // Get the SSTORE2 storage backend
            IStorageBackend storageBackend;
            {
                StaticFrontendPlugin.StorageBackendWithInfos[] memory storageBackends = staticFrontendPlugin.getStorageBackends(new bytes4[](0));
                for(uint256 i = 0; i < storageBackends.length; i++) {
                    if(LibStrings.compare(storageBackends[i].name, "sstore2") && LibStrings.compare(storageBackends[i].version, "0.1.0")) {
                        storageBackend = storageBackends[i].storageBackend;
                        break;
                    }
                }
                require(address(storageBackend) != address(0), "SSTORE2 storage backend not found");
            }

            versionableStaticWebsite.addWebsiteVersion("Initial version", 0);
        }

        // Get the files to upload
        FileNameAndCompressedName[] memory files = abi.decode(vm.envBytes("FILE_ARGS"), (FileNameAndCompressedName[]));
        string memory compressedFilesBasePath = vm.envString("COMPRESSED_FILES_BASE_PATH");

        // Upload them, store them into PartialFileInfos format
        for (uint256 i = 0; i < files.length; i++) {
            console.log("Handling file", files[i].filename, files[i].compressedFileName);
            console.log("    ", files[i].mimeType, files[i].subFolder);

            bytes memory fileContents = vm.readFileBinary(string.concat(compressedFilesBasePath, files[i].subFolder, files[i].compressedFileName));

            // Transaction size limit is 131072 bytes, so we need to split the file in chunks
            // We also get "exceeds block gas limit" when trying to put too much
            // Let's put 3 * (0x6000-1) bytes ((0x6000-1) being the size of a SSTORE2 chunk)
            uint256 chunkSize = 3 * (0x6000-1);
            uint256 chunksCount = fileContents.length / chunkSize;
            if (fileContents.length % chunkSize != 0) {
                chunksCount++;
            }

            (,websiteVersionCount) = versionableStaticWebsite.getWebsiteVersions(0, 0);
            for(uint256 j = 0; j < chunksCount; j++) {
                bytes memory chunk;
                {
                    uint256 start = j * chunkSize;
                    uint256 end = start + chunkSize;
                    if(end > fileContents.length) {
                        end = fileContents.length;
                    }
                    chunk = bytes(LibString.slice(string(fileContents), start, end));
                }
                console.log("    - Uploading chunk", j, "of size", chunk.length);
                if(j == 0) {
                    StaticFrontendPlugin.FileUploadInfos[] memory fileUploadInfos = new StaticFrontendPlugin.FileUploadInfos[](1);
                    fileUploadInfos[0] = StaticFrontendPlugin.FileUploadInfos({
                        filePath: string.concat(files[i].subFolder, files[i].filename),
                        fileSize: fileContents.length,
                        contentType: files[i].mimeType,
                        compressionAlgorithm: CompressionAlgorithm.GZIP,
                        data: chunk
                    });
                    staticFrontendPlugin.addFiles(versionableStaticWebsite, websiteVersionCount - 1, fileUploadInfos);
                }
                else {

                    staticFrontendPlugin.appendToFile(versionableStaticWebsite, websiteVersionCount - 1, string.concat(files[i].subFolder, files[i].filename), chunk);
                }
            }
        }

        vm.stopBroadcast();
    }

}