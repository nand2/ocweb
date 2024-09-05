// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IDecentralizedApp, KeyValue } from "./IDecentralizedApp.sol";
import { IOwnable } from "./IOwnable.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IVersionableWebsite is IDecentralizedApp, IOwnable {
    struct LinkedListNodePlugin {
        IVersionableWebsitePlugin plugin;
        uint96 next;
    }
    struct WebsiteVersion {
        string description;

        // The list of enabled plugins for this version
        // Linked list for the execution order
        LinkedListNodePlugin[] pluginNodes;
        uint96 headPluginLinkedList;
        
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
    function enableViewerForWebsiteVersion(uint256 frontendIndex, bool enable) external;

    function addPlugin(uint frontendIndex, IVersionableWebsitePlugin plugin, uint position) external;
    struct IVersionableWebsitePluginWithInfos {
        IVersionableWebsitePlugin plugin;
        IVersionableWebsitePlugin.Infos infos;
    }
    function getPlugins(uint frontendIndex) external view returns (IVersionableWebsitePluginWithInfos[] memory pluginWithInfos);
    function reorderPlugin(uint frontendIndex, IVersionableWebsitePlugin plugin, uint newPosition) external;
    function removePlugin(uint frontendIndex, address plugin) external;
}

interface IVersionableWebsitePlugin is IERC165 {
    enum AdminPanelType {
        Primary,
        Secondary
    }
    // Represent an admin panel for this plugin
    // 2 types : 
    // - An autonomous webpage (which can be iframed by global admin panels)
    // - A ES/UMD module which is loaded by a global admin panel
    //   In this case, the moduleForGlobalAdminPanel is the address of the
    //   admin panel plugin for which this plugin is a module
    struct AdminPanel {
        // Title of the panel, can be empty
        string title;
        // The web3:// URL of the panel (either a HTML webpage, or a JS module)
        string url;

        // If the panel is a module, this is the address of the admin panel plugin
        // for which this plugin is a module
        IVersionableWebsitePlugin moduleForGlobalAdminPanel;

        // The type of the panel
        // This is mostly an hint on how to embed the panel
        // Primary will be for a full page, Secondary will be for being inserted inside
        // a common Settings page
        AdminPanelType panelType;
    }

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
        // Point to a web3:// address of the homepage
        string homepage;

        // Dependencies of this plugin
        IVersionableWebsitePlugin[] dependencies;

        // Admin panels
        AdminPanel[] adminPanels;
    }
    function infos() external view returns (Infos memory);

    function rewriteWeb3Request(IVersionableWebsite website, uint frontendIndex, string[] memory resource, KeyValue[] memory params) external view returns (bool rewritten, string[] memory newResource, KeyValue[] memory newParams);

    function processWeb3Request(IVersionableWebsite website, uint frontendIndex, string[] memory resource, KeyValue[] memory params) external view returns (uint statusCode, string memory body, KeyValue[] memory headers);

    function copyFrontendSettings(IVersionableWebsite website, uint fromFrontendIndex, uint toFrontendIndex) external;
}

