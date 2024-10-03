// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IVersionableWebsite.sol";
import "../interfaces/IERC7774.sol";

import '../library/Ownable.sol';
import './ResourceRequestWebsite.sol';
import "./ClonableWebsiteVersionViewer.sol";

contract VersionableWebsite is IVersionableWebsite, ResourceRequestWebsite, Ownable {

    // The list of website versions
    WebsiteVersion[] public websiteVersions;
    // The index of the live frontend version
    uint256 public liveWebsiteVersionIndex;

    // Global lock! Store when it was locked
    uint256 lockedAt;

    // When not the live version, a frontend version can be viewed by this address,
    // which is a clone of a cheap proxy contract
    // This is the implementation of the viewer
    ClonableWebsiteVersionViewer public websiteVersionViewerImplementation;
    


    constructor(ClonableWebsiteVersionViewer _viewerImplementation)  {
        websiteVersionViewerImplementation = _viewerImplementation;
    }




    function addWebsiteVersion(string memory _description, uint copyPluginsFromWebsiteVersionIndex) public onlyOwner {
        _addWebsiteVersion(_description, copyPluginsFromWebsiteVersionIndex);
    }

    function _addWebsiteVersion(string memory _description, uint copyPluginsFromWebsiteVersionIndex) internal {
        // copyPluginsFromWebsiteVersionIndex = websiteVersions.length for no copy
        require(copyPluginsFromWebsiteVersionIndex <= websiteVersions.length, "Invalid index");

        // Add the new website version
        websiteVersions.push();
        WebsiteVersion storage newVersion = websiteVersions[websiteVersions.length - 1];
        newVersion.description = _description;
        
        // Copy the plugins
        if(copyPluginsFromWebsiteVersionIndex != websiteVersions.length - 1) {
            WebsiteVersion storage versionToCopyFrom = websiteVersions[copyPluginsFromWebsiteVersionIndex];
            for(uint i = 0; i < versionToCopyFrom.pluginNodes.length; i++) {
                newVersion.pluginNodes.push(versionToCopyFrom.pluginNodes[i]);
                newVersion.pluginNodes[i].plugin.copyFrontendSettings(this, copyPluginsFromWebsiteVersionIndex, websiteVersions.length - 1);
            }
        }
    }

    function getWebsiteVersionCount() public view returns (uint) {
        return websiteVersions.length;
    }

    /**
     * Get website versions
     * @param startIndex The index of the first website version to get
     * @param count The number of website versions to get. If 0, get all versions
     */
    function getWebsiteVersions(uint startIndex, uint count) public view returns (WebsiteVersion[] memory, uint totalCount) {
        require(startIndex < websiteVersions.length, "Index out of bounds");
        
        if(count == 0) {
            count = websiteVersions.length - startIndex;
        }
        else if(startIndex + count > websiteVersions.length) {
            count = websiteVersions.length - startIndex;
        }
        WebsiteVersion[] memory result = new WebsiteVersion[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = websiteVersions[startIndex + i];
        }
        return (result, websiteVersions.length);
    }

    function getWebsiteVersion(uint256 websiteVersionIndex) public view returns (WebsiteVersion memory) {
        require(websiteVersionIndex < websiteVersions.length, "Index out of bounds");
        return websiteVersions[websiteVersionIndex];
    }

    /**
     * Set the live website version index
     */
    function setLiveWebsiteVersionIndex(uint256 newLiveWebsiteVersionIndex) public onlyOwner {
        require(newLiveWebsiteVersionIndex < websiteVersions.length, "Invalid index");
        require(newLiveWebsiteVersionIndex != liveWebsiteVersionIndex, "Already live");
        
        // Clear the cache of the requested website version index viewer, if enabled
        if(websiteVersions[newLiveWebsiteVersionIndex].isViewable) {
            string[] memory paths = new string[](1);
            paths[0] = "*";
            _clearPathCache(newLiveWebsiteVersionIndex, paths);
        }

        liveWebsiteVersionIndex = newLiveWebsiteVersionIndex;

        // Clear the cache of the live version
        string[] memory paths = new string[](1);
        paths[0] = "*";
        _clearPathCache(liveWebsiteVersionIndex, paths);
    }

    /**
     * Get the current live frontend version, and its index
     */
    function getLiveWebsiteVersion() public view returns (WebsiteVersion memory websiteVersion, uint256 websiteVersionIndex) {
        websiteVersionIndex = liveWebsiteVersionIndex;
        websiteVersion = websiteVersions[websiteVersionIndex];
    }

    function renameWebsiteVersion(uint256 websiteVersionIndex, string memory newDescription) public onlyOwner {
        require(websiteVersionIndex < websiteVersions.length, "Index out of bounds");
        websiteVersions[websiteVersionIndex].description = newDescription;
    }

    function lockWebsiteVersion(uint256 websiteVersionIndex) public onlyOwner {
        require(websiteVersionIndex < websiteVersions.length, "Index out of bounds");
        websiteVersions[websiteVersionIndex].locked = true;
    }


    //
    // Global lock
    // 

    function lock() public onlyOwner {
        require(lockedAt == 0, "Already locked");
        lockedAt = block.timestamp;
    }

    function isLocked() public view returns (bool) {
        return lockedAt != 0;
    }


    //
    // Plugins
    // 

    function addPlugin(uint websiteVersionIndex, IVersionableWebsitePlugin plugin, uint position) public override onlyOwner {
        _addPlugin(websiteVersionIndex, plugin, position);

        // Clear the cache of the whole website version : we don't know how this plugin
        // will affect the website
        string[] memory paths = new string[](1);
        paths[0] = "*";
        _clearPathCache(websiteVersionIndex, paths);
    }

    function _addPlugin(uint websiteVersionIndex, IVersionableWebsitePlugin plugin, uint position) internal {
        // Ensure that the plugin support one of the requested interfaces
        bytes4[] memory supportedInterfaces = getSupportedPluginInterfaces();
        bool supported = false;
        for(uint i = 0; i < supportedInterfaces.length; i++) {
            if(plugin.supportsInterface(supportedInterfaces[i])) {
                supported = true;
                break;
            }
        }
        require(supported, "Plugin does not support any of the required interfaces");

        // Ensure that the global lock is not active
        require(lockedAt == 0, "Frontend library is locked");

        // Ensure that the websiteVersionIndex is within bounds
        require(websiteVersionIndex < websiteVersions.length, "Invalid website version index");

        WebsiteVersion storage websiteVersion = websiteVersions[websiteVersionIndex];

        // Ensure that the websiteVersion is not locked
        require(websiteVersion.locked == false, "Website version is locked");

        // Ensure that the plugin is not already added
        for(uint i = 0; i < websiteVersion.pluginNodes.length; i++) {
            require(address(websiteVersion.pluginNodes[i].plugin) != address(plugin), "Plugin already added");
        }

        // Check that position is valid
        require(position <= websiteVersion.pluginNodes.length, "Invalid position");


        // If it has dependencies, ensure that they are installed : 
        // If they are present, do nothing. Otherwise, install them.
        IVersionableWebsitePlugin.Infos memory infos = plugin.infos();
        for(uint i = 0; i < infos.dependencies.length; i++) {
            bool found = false;
            for(uint j = 0; j < websiteVersion.pluginNodes.length; j++) {
                if(address(websiteVersion.pluginNodes[j].plugin) == address(infos.dependencies[i])) {
                    found = true;
                    break;
                }
            }
            if(!found) {
                addPlugin(websiteVersionIndex, infos.dependencies[i], position);
            }
        }
        

        // Insert into the linked list
        websiteVersion.pluginNodes.push(LinkedListNodePlugin({
            plugin: plugin,
            next: 0
        }));

        if(position == 0) {
            websiteVersion.pluginNodes[websiteVersion.pluginNodes.length - 1].next = websiteVersion.headPluginLinkedList;
            websiteVersion.headPluginLinkedList = uint96(websiteVersion.pluginNodes.length - 1);
        }
        else {
            // Find the previous plugin
            uint96 previous = websiteVersion.headPluginLinkedList;
            for(uint i = 0; i < position - 1; i++) {
                previous = websiteVersion.pluginNodes[previous].next;
            }
            websiteVersion.pluginNodes[websiteVersion.pluginNodes.length - 1].next = websiteVersion.pluginNodes[previous].next;
            websiteVersion.pluginNodes[previous].next = uint96(websiteVersion.pluginNodes.length - 1);
        }
    }

    function getPlugins(uint websiteVersionIndex) external view returns (IVersionableWebsitePluginWithInfos[] memory pluginWithInfos) {
        // Ensure that the websiteVersionIndex is within bounds
        require(websiteVersionIndex < websiteVersions.length, "Invalid website version index");

        WebsiteVersion storage websiteVersion = websiteVersions[websiteVersionIndex];

        pluginWithInfos = new IVersionableWebsitePluginWithInfos[](websiteVersion.pluginNodes.length);
        // Put them in the ordered way
        uint96 current = websiteVersion.headPluginLinkedList;
        for(uint i = 0; i < websiteVersion.pluginNodes.length; i++) {
            pluginWithInfos[i].plugin = websiteVersion.pluginNodes[current].plugin;
            pluginWithInfos[i].infos = websiteVersion.pluginNodes[current].plugin.infos();
            current = websiteVersion.pluginNodes[current].next;
        }
    }

    function reorderPlugin(uint websiteVersionIndex, IVersionableWebsitePlugin plugin, uint newPosition) public onlyOwner {
        // Ensure that the global lock is not active
        require(lockedAt == 0, "Frontend library is locked");

        // Ensure that the websiteVersionIndex is within bounds
        require(websiteVersionIndex < websiteVersions.length, "Invalid website version index");

        WebsiteVersion storage websiteVersion = websiteVersions[websiteVersionIndex];

        // Ensure that the websiteVersion is not locked
        require(websiteVersion.locked == false, "Website version is locked");

        // Ensure that newPosition is valid
        require(newPosition < websiteVersion.pluginNodes.length, "Invalid position");

        // Find the plugin
        uint96 previous = 0;
        uint96 current = websiteVersion.headPluginLinkedList;
        uint posInList = 0;
        bool found = false;
        for(posInList = 0; posInList < websiteVersion.pluginNodes.length; posInList++) {
            if(address(websiteVersion.pluginNodes[current].plugin) == address(plugin)) {
                found = true;
                break;
            }
            previous = current;
            current = websiteVersion.pluginNodes[current].next;
        }
        require(found, "Plugin not found");

        // Remove from the linked list
        if(posInList == 0) {
            websiteVersion.headPluginLinkedList = websiteVersion.pluginNodes[current].next;
        }
        else {
            websiteVersion.pluginNodes[previous].next = websiteVersion.pluginNodes[current].next;
        }

        // Insert at the new position
        if(newPosition == 0) {
            websiteVersion.pluginNodes[current].next = websiteVersion.headPluginLinkedList;
            websiteVersion.headPluginLinkedList = current;
        }
        else {
            // Find the previous plugin
            uint96 newPrevious = websiteVersion.headPluginLinkedList;
            for(uint i = 0; i < newPosition - 1; i++) {
                newPrevious = websiteVersion.pluginNodes[newPrevious].next;
            }
            websiteVersion.pluginNodes[current].next = websiteVersion.pluginNodes[newPrevious].next;
            websiteVersion.pluginNodes[newPrevious].next = current;
        }

        // Clear the cache of the whole website version : we don't know how this reordering
        // will affect the website
        string[] memory paths = new string[](1);
        paths[0] = "*";
        _clearPathCache(websiteVersionIndex, paths);
    }

    function removePlugin(uint websiteVersionIndex, address plugin) public onlyOwner {
        // Ensure that the global lock is not active
        require(lockedAt == 0, "Frontend library is locked");

        // Ensure that the websiteVersionIndex is within bounds
        require(websiteVersionIndex < websiteVersions.length, "Invalid website version index");

        WebsiteVersion storage websiteVersion = websiteVersions[websiteVersionIndex];

        // Ensure that the websiteVersion is not locked
        require(websiteVersion.locked == false, "Website version is locked");

        // Lookup all installed plugins: If one has the plugin as a dependency, it cannot be removed
        for(uint i = 0; i < websiteVersion.pluginNodes.length; i++) {
            IVersionableWebsitePlugin.Infos memory infos = websiteVersion.pluginNodes[i].plugin.infos();
            for(uint j = 0; j < infos.dependencies.length; j++) {
                if(address(infos.dependencies[j]) == address(plugin)) {
                    revert("Plugin is a dependency of another installed plugin");
                }
            }
        }

        // Find the plugin
        uint96 previous = 0;
        uint96 current = websiteVersion.headPluginLinkedList;
        uint posInList = 0;
        bool found = false;
        for(posInList = 0; posInList < websiteVersion.pluginNodes.length; posInList++) {
            if(address(websiteVersion.pluginNodes[current].plugin) == plugin) {
                found = true;
                break;
            }
            previous = current;
            current = websiteVersion.pluginNodes[current].next;
        }
        require(found, "Plugin not found");

        // Update the pointer: The previous point to the next
        if(posInList == 0) {
            // First entry is now the second one
            websiteVersion.headPluginLinkedList = websiteVersion.pluginNodes[current].next;
        }
        else {
            websiteVersion.pluginNodes[previous].next = websiteVersion.pluginNodes[current].next;
        }

        // Remove from the array, which move the last element to the current position
        websiteVersion.pluginNodes[current] = websiteVersion.pluginNodes[websiteVersion.pluginNodes.length - 1];
        websiteVersion.pluginNodes.pop();

        // If headPluginLinkedList is pointing to pluginNodes.length, it should now point
        // to current
        if(websiteVersion.headPluginLinkedList == websiteVersion.pluginNodes.length) {
            websiteVersion.headPluginLinkedList = current;
        }
        // Scan the pluginNodes: the one which is pointing to pluginNodes.length should now
        // point to current
        for(uint i = 0; i < websiteVersion.pluginNodes.length; i++) {
            if(websiteVersion.pluginNodes[i].next == websiteVersion.pluginNodes.length) {
                websiteVersion.pluginNodes[i].next = current;
                break;
            }
        }

        // Clear the cache of the whole website version : we don't know how this plugin removal
        // will affect the website
        string[] memory paths = new string[](1);
        paths[0] = "*";
        _clearPathCache(websiteVersionIndex, paths);
    }

    /**
     * Get th elist of supported plugins interfaces
     * Unfortunately constant arrays are not supported...
     */
    function getSupportedPluginInterfaces() public pure returns (bytes4[] memory) {
        unchecked {
            bytes4[] memory supportedInterfaces = new bytes4[](1);
            supportedInterfaces[0] = type(IVersionableWebsitePlugin).interfaceId;
            return supportedInterfaces;
        }
    }

    
    //
    // Frontend version viewer
    //

    /**
     * Enable/disable the viewing of a non-live frontend version
     * @param websiteVersionIndex The index of the frontend version
     * @param enable Enable or disable the viewer
     */
    function enableViewerForWebsiteVersion(uint256 websiteVersionIndex, bool enable) public onlyOwner {
        // Ensure that the global lock is not active
        require(lockedAt == 0, "Frontend library is locked");

        // Ensure that the website frontend index is within bounds
        require(websiteVersionIndex < websiteVersions.length, "Invalid frontend index");

        WebsiteVersion storage version = websiteVersions[websiteVersionIndex];
        
        // Create the viewer if not done so yet
        if(enable && address(version.viewer) == address(0)) {
            ClonableWebsiteVersionViewer viewer = ClonableWebsiteVersionViewer(Clones.clone(address(websiteVersionViewerImplementation)));
            viewer.initialize(IVersionableWebsite(address(this)), websiteVersionIndex);
            version.viewer = IVersionableWebsiteViewer(viewer);
        }

        // If we disable a viewer, clear cache for all paths
        if(enable == false) {
            string[] memory paths = new string[](1);
            paths[0] = "*";
            _clearPathCache(websiteVersionIndex, paths);
        }

        version.isViewable = enable;
    }



    //
    // web3://
    //

    /**
     * Return an response to a web3:// request
     */
    function request(string[] memory resource, KeyValue[] memory params) external virtual override(IDecentralizedApp, ResourceRequestWebsite) view returns (uint statusCode, string memory body, KeyValue[] memory headers) {

        WebsiteVersion storage websiteVersion = websiteVersions[liveWebsiteVersionIndex];

        // To remain gas efficient, this function do not call requestWebsiteVersion()
        // (this would force requestWebsiteVersion() to be public instead of external)

        // Plugins: rewrite the request
        uint96 current = websiteVersion.headPluginLinkedList;
        for(uint i = 0; i < websiteVersion.pluginNodes.length; i++) {
            bool rewritten;
            string[] memory newResource;
            KeyValue[] memory newParams;
            (rewritten, newResource, newParams) = websiteVersion.pluginNodes[current].plugin.rewriteWeb3Request(this, liveWebsiteVersionIndex, resource, params);
            if(rewritten) {
                resource = newResource;
                params = newParams;
            }
            current = websiteVersion.pluginNodes[current].next;
        }

        // Plugins: return content
        current = websiteVersion.headPluginLinkedList;
        for(uint i = 0; i < websiteVersion.pluginNodes.length; i++) {
            (statusCode, body, headers) = websiteVersion.pluginNodes[current].plugin.processWeb3Request(this, liveWebsiteVersionIndex, resource, params);
            if(statusCode != 0) {
                return (statusCode, body, headers);
            }
            current = websiteVersion.pluginNodes[current].next;
        }

        // Default: Returning 404
        return (404, "", new KeyValue[](0));
    }

    /**
     * Non-standard way to fetch web3:// resources, used by the frontend viewer contract 
     * (used to preview viewable non-live versions)
     */
    function requestWebsiteVersion(uint256 websiteVersionIndex, string[] memory resource, KeyValue[] memory params) external view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
        // Ensure that the website frontend index is within bounds
        require(websiteVersionIndex < websiteVersions.length, "Invalid frontend index");

        // Get the frontend version
        WebsiteVersion storage websiteVersion = websiteVersions[websiteVersionIndex];

        // If we are serving a non-live, non-viewable frontend, we return a 404
        if(websiteVersionIndex != liveWebsiteVersionIndex && websiteVersion.isViewable == false) {
            statusCode = 404;
            return (statusCode, body, headers);
        }

        // Plugins: rewrite the request
        uint96 current = websiteVersion.headPluginLinkedList;
        for(uint i = 0; i < websiteVersion.pluginNodes.length; i++) {
            bool rewritten;
            string[] memory newResource;
            KeyValue[] memory newParams;
            (rewritten, newResource, newParams) = websiteVersion.pluginNodes[current].plugin.rewriteWeb3Request(this, websiteVersionIndex, resource, params);
            if(rewritten) {
                resource = newResource;
                params = newParams;
            }
            current = websiteVersion.pluginNodes[current].next;
        }

        // Plugins: return content
        current = websiteVersion.headPluginLinkedList;
        for(uint i = 0; i < websiteVersion.pluginNodes.length; i++) {
            (statusCode, body, headers) = websiteVersion.pluginNodes[current].plugin.processWeb3Request(this, websiteVersionIndex, resource, params);
            if(statusCode != 0) {
                return (statusCode, body, headers);
            }
            current = websiteVersion.pluginNodes[current].next;
        }

        // Default: Returning 404
        return (404, "", new KeyValue[](0));
    }

    /**
     * ERC-7774 support: Plugins can call this function to emit the clear path cache event
     * Paths must be relative to the website root e.g. "/", "/index.html", "/css/style.css", ...
     */
    function clearPathCache(uint256 websiteVersionIndex, string[] memory paths) public {
        // Ensure that the website frontend index is within bounds
        require(websiteVersionIndex < websiteVersions.length, "Invalid frontend index");

        // The caller must either be an installed plugin, or the owner
        bool found = false;
        WebsiteVersion storage version = websiteVersions[websiteVersionIndex];
        for(uint i = 0; i < version.pluginNodes.length; i++) {
            if(address(version.pluginNodes[i].plugin) == msg.sender) {
                found = true;
                break;
            }
        }
        require(found || msg.sender == owner, "Unauthorized");

        _clearPathCache(websiteVersionIndex, paths);
    }

    function _clearPathCache(uint256 websiteVersionIndex, string[] memory paths) private {
        WebsiteVersion storage version = websiteVersions[websiteVersionIndex];

        // If the version is live, emit the event
        if(websiteVersionIndex == liveWebsiteVersionIndex) {
            emit ClearPathCache(paths);
        }
        else {
            // If the non-live version is viewable, tell the viewer to send the event
            if(version.isViewable) {
                version.viewer.clearPathCache(paths);
            }
        }
    }
}