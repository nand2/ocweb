// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IVersionableWebsite.sol";

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
    function setLiveWebsiteVersionIndex(uint256 index) public onlyOwner {
        require(index < websiteVersions.length, "Invalid index");
        liveWebsiteVersionIndex = index;
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

    function reorderPlugin(uint frontendIndex, IVersionableWebsitePlugin plugin, uint newPosition) public onlyOwner {
        // Ensure that the global lock is not active
        require(lockedAt == 0, "Frontend library is locked");

        // Ensure that the websiteVersionIndex is within bounds
        require(frontendIndex < websiteVersions.length, "Invalid website version index");

        WebsiteVersion storage websiteVersion = websiteVersions[frontendIndex];

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
            viewer.initialize(IDecentralizedApp(address(this)), websiteVersionIndex);
            version.viewer = IDecentralizedApp(viewer);
        }
        version.isViewable = enable;
    }



    //
    // web3://
    //

    /**
     * Return an answer to a web3:// request after the static frontend is served
     * @return statusCode The HTTP status code to return. Returns 0 if you do not wish to
     *                   process the call
     */
    function request(string[] memory resource, KeyValue[] memory params) external virtual override(IDecentralizedApp, ResourceRequestWebsite) view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
        uint frontendIndex = liveWebsiteVersionIndex;

        // Get the frontend version to use
        {
            // Special path prefix : /__website_version/{id}
            // Combined with the CLonableFrontendVersionViewer, this allows to serve a 
            // specific frontend version
            if(resource.length >= 2 && LibStrings.compare(resource[0], "__website_version")) {
                uint overridenFrontendIndex = LibStrings.stringToUint(resource[1]);
                if(overridenFrontendIndex < websiteVersions.length) {
                    frontendIndex = overridenFrontendIndex;

                    string[] memory newResource = new string[](resource.length - 2);
                    for(uint i = 0; i < newResource.length; i++) {
                        newResource[i] = resource[i + 2];
                    }
                    resource = newResource;
                }
            }

            // Get the frontend version
            WebsiteVersion storage websiteVersion = websiteVersions[frontendIndex];
            // If we are serving a non-live, non-viewable frontend, we return a 404
            if(frontendIndex != liveWebsiteVersionIndex && websiteVersion.isViewable == false) {
                statusCode = 404;
                return (statusCode, body, headers);
            }
        }

        WebsiteVersion storage websiteVersion = websiteVersions[frontendIndex];

        // Plugins: rewrite the request
        uint96 current = websiteVersion.headPluginLinkedList;
        for(uint i = 0; i < websiteVersion.pluginNodes.length; i++) {
            bool rewritten;
            string[] memory newResource;
            KeyValue[] memory newParams;
            (rewritten, newResource, newParams) = websiteVersion.pluginNodes[current].plugin.rewriteWeb3Request(this, frontendIndex, resource, params);
            if(rewritten) {
                resource = newResource;
                params = newParams;
            }
            current = websiteVersion.pluginNodes[current].next;
        }

        // Plugins: return content before the static content
        current = websiteVersion.headPluginLinkedList;
        for(uint i = 0; i < websiteVersion.pluginNodes.length; i++) {
            (statusCode, body, headers) = websiteVersion.pluginNodes[current].plugin.processWeb3Request(this, frontendIndex, resource, params);
            if(statusCode != 0) {
                return (statusCode, body, headers);
            }
            current = websiteVersion.pluginNodes[current].next;
        }

        // Default: Returning 404
        return (404, "", new KeyValue[](0));
    }


}