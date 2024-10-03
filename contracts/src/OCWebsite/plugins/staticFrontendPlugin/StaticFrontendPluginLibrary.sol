// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../../library/LibStrings.sol";

// Strings... always a mess of cherry-picking from different sources
library StaticFrontendPluginLibrary {
    
    function _preparePathsForClearPathCacheEvent(string[] memory paths) external pure returns (string[] memory) {
        // Count the path to clear
        uint pathsToClearCount = paths.length;
        // For all paths, we will prefix with "/", so e.g. "index.html" becomes "/index.html"
        // If the path is "index.html", we will return an extra "/"
        // If the path is "<somePath>/index.html", we will return an extra "/<somePath>"
        for(uint i = 0; i < paths.length; i++) {
            if(LibStrings.compare(paths[i], "index.html")) {
                pathsToClearCount++;
            }
            else if(bytes(paths[i]).length > 11 &&
                 LibStrings.compare(LibStrings.substring(paths[i], bytes(paths[i]).length - 11, bytes(paths[i]).length), "/index.html")) {
                pathsToClearCount++;
            }
        }

        string[] memory pathsToClear = new string[](pathsToClearCount);
        uint addedPathCount = 0;
        for(uint i = 0; i < paths.length; i++) {
            if(LibStrings.compare(paths[i], "index.html")) {
                pathsToClear[addedPathCount] = "/";
                addedPathCount++;
            }
            else if(bytes(paths[i]).length > 11 &&
                 LibStrings.compare(LibStrings.substring(paths[i], bytes(paths[i]).length - 11, bytes(paths[i]).length), "/index.html")) {
                pathsToClear[addedPathCount] = string.concat("/", LibStrings.substring(paths[i], 0, bytes(paths[i]).length - 11));
                addedPathCount++;
            }
            pathsToClear[addedPathCount] = string.concat("/", paths[i]);
            addedPathCount++;
        }
            
        return pathsToClear;
    }
}
