// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IDecentralizedApp, KeyValue } from "./IDecentralizedApp.sol";
import { IOwnable } from "./IOwnable.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IVersionableWebsite is IDecentralizedApp, IOwnable {
    struct WebsiteVersion {
        string description;

        // The list of enabled plugins for this version
        IVersionableWebsitePlugin[] plugins;
        
        // When not the live version, a frontend version can be viewed by this address,
        // which is a clone of a cheap proxy contract
        IDecentralizedApp viewer;
        bool isViewable;

        // A lock at the version level: Plugins cannot be added, edited, or removed
        // Only the isViewable toggle can be changed
        bool locked;
    }

    function liveWebsiteVersionIndex() external view returns (uint256);
    function setLiveWebsiteVersionIndex(uint256 index) external;
    // Shortcut for frontends
    function getLiveWebsiteVersion() external view returns (WebsiteVersion memory websiteVersion, uint256 websiteVersionIndex);

    function addWebsiteVersion(string memory description, uint copyPluginsFromWebsiteVersionIndex) external;
    function getWebsiteVersionCount() external view returns (uint);
    function getWebsiteVersions(uint startIndex, uint count) external view returns (WebsiteVersion[] memory, uint totalCount);
    function getWebsiteVersion(uint256 websiteVersionIndex) external view returns (WebsiteVersion memory);
    function renameWebsiteVersion(uint256 websiteVersionIndex, string memory newDescription) external;
    
    // Lock a website version: It won't be editable anymore
    function lockWebsiteVersion(uint256 websiteVersionIndex) external;
    // Lock the whole website
    function lock() external;
    function isLocked() external view returns (bool);


    // Enable/disable the viewer, for a frontend version which is not the live one
    function enableViewerForFrontendVersion(uint256 frontendIndex, bool enable) external;

    function addPlugin(uint frontendIndex, IVersionableWebsitePlugin plugin) external;
    struct IVersionableWebsitePluginWithInfos {
        IVersionableWebsitePlugin plugin;
        IVersionableWebsitePlugin.Infos infos;
    }
    function getPlugins(uint frontendIndex) external view returns (IVersionableWebsitePluginWithInfos[] memory pluginWithInfos);
    function removePlugin(uint frontendIndex, address plugin) external;
}

interface IVersionableWebsitePlugin is IERC165 {
    struct Infos {
        // Technical name
        string name;
        // Version of the plugin
        string version;
        // Display name
        string title;
        string subTitle;
        // Author
        string author;
        // Point to a web3:// address of the homepage, where it can be configured
        string homepage;
    }
    function infos() external view returns (Infos memory);

    function rewriteWeb3Request(IVersionableWebsite website, uint frontendIndex, string[] memory resource, KeyValue[] memory params) external view returns (bool rewritten, string[] memory newResource, KeyValue[] memory newParams);

    function processWeb3Request(IVersionableWebsite website, uint frontendIndex, string[] memory resource, KeyValue[] memory params) external view returns (uint statusCode, string memory body, KeyValue[] memory headers);

    function copyFrontendSettings(IVersionableWebsite website, uint fromFrontendIndex, uint toFrontendIndex) external;
}

