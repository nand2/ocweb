// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LibString} from "solady/utils/LibString.sol";

import "../src/interfaces/IFrontendLibrary.sol";
import "../src/interfaces/IStorageBackendLibrary.sol";
import "../src/interfaces/IStorageBackend.sol";

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

        IFrontendLibrary frontendLibrary = IFrontendLibrary(vm.envAddress("IFRONTEND_LIBRARY_CONTRACT_ADDRESS"));

        // Get the SSTORE2 storage backend
        IStorageBackend storageBackend;
        {
            IStorageBackendLibrary storageBackendLibrary = IStorageBackendLibrary(vm.envAddress("ISTORAGE_BACKEND_LIBRARY_CONTRACT_ADDRESS"));
            storageBackend = storageBackendLibrary.getStorageBackendByName("SSTORE2");
        }

        // If there is already a frontend version which is unlocked, we wipe it and replace it
        (,uint256 frontendVersionCount) = frontendLibrary.getFrontendVersions(0, 0);
        if(frontendVersionCount > 0 && frontendLibrary.getFrontendVersion(frontendVersionCount - 1).locked == false) {
            console.log("Resetting and replacing latest frontend version");
            frontendLibrary.removeAllFilesFromFrontendVersion(frontendVersionCount - 1);
        }
        // Otherwise we add a new version
        else {
            console.log("Adding new frontend version");
            frontendLibrary.addFrontendVersion(storageBackend, "Initial version", -1);
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

            (,uint256 frontendVersionCount) = frontendLibrary.getFrontendVersions(0, 0);
            for(uint256 j = 0; j < chunksCount; j++) {
                uint256 start = j * chunkSize;
                uint256 end = start + chunkSize;
                if(end > fileContents.length) {
                    end = fileContents.length;
                }
                bytes memory chunk = bytes(LibString.slice(string(fileContents), start, end));
                console.log("    - Uploading chunk", j, "of size", chunk.length);
                if(j == 0) {
                    IFrontendLibrary.FileUploadInfos[] memory fileUploadInfos = new IFrontendLibrary.FileUploadInfos[](1);
                    fileUploadInfos[0] = IFrontendLibrary.FileUploadInfos({
                        filePath: string.concat(files[i].subFolder, files[i].filename),
                        fileSize: fileContents.length,
                        contentType: files[i].mimeType,
                        compressionAlgorithm: CompressionAlgorithm.GZIP,
                        data: chunk
                    });
                    frontendLibrary.addFilesToFrontendVersion(frontendVersionCount - 1, fileUploadInfos);
                }
                else {
                    frontendLibrary.appendToFileInFrontendVersion(frontendVersionCount - 1, string.concat(files[i].subFolder, files[i].filename), chunk);
                }
            }
        }

        vm.stopBroadcast();
    }

}