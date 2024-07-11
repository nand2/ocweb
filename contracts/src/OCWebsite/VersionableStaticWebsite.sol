// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IVersionableStaticWebsite.sol";

import '../library/Ownable.sol';
import './ResourceRequestWebsite.sol';
import "./ClonableWebsiteVersionViewer.sol";

contract VersionableStaticWebsite is IVersionableStaticWebsite, ResourceRequestWebsite, Ownable {

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
        websiteVersions.push(WebsiteVersion({
            description: _description,
            plugins: new IVersionableStaticWebsitePlugin[](0),
            viewer: IDecentralizedApp(address(0)),
            isViewable: false,
            locked: false
        }));
        
        // Copy the plugins
        if(copyPluginsFromWebsiteVersionIndex != websiteVersions.length - 1) {
            WebsiteVersion storage newVersion = websiteVersions[websiteVersions.length - 1];
            WebsiteVersion storage versionToCopyFrom = websiteVersions[copyPluginsFromWebsiteVersionIndex];
            for(uint i = 0; i < versionToCopyFrom.plugins.length; i++) {
                newVersion.plugins.push(versionToCopyFrom.plugins[i]);
                newVersion.plugins[i].copyFrontendSettings(this, copyPluginsFromWebsiteVersionIndex, websiteVersions.length - 1);
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

    function addPlugin(uint websiteVersionIndex, IVersionableStaticWebsitePlugin plugin) public override onlyOwner {
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
        for(uint i = 0; i < websiteVersion.plugins.length; i++) {
            require(address(websiteVersion.plugins[i]) != address(plugin), "Plugin already added");
        }

        websiteVersion.plugins.push(plugin);
    }

    function getPlugins(uint websiteVersionIndex) external view returns (IVersionableStaticWebsitePluginWithInfos[] memory pluginWithInfos) {
        // Ensure that the websiteVersionIndex is within bounds
        require(websiteVersionIndex < websiteVersions.length, "Invalid website version index");

        WebsiteVersion storage websiteVersion = websiteVersions[websiteVersionIndex];

        pluginWithInfos = new IVersionableStaticWebsitePluginWithInfos[](websiteVersion.plugins.length);
        for(uint i = 0; i < websiteVersion.plugins.length; i++) {
            pluginWithInfos[i].plugin = websiteVersion.plugins[i];
            pluginWithInfos[i].infos = websiteVersion.plugins[i].infos();
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

        IVersionableStaticWebsitePlugin[] storage _plugins = websiteVersion.plugins;
        for(uint i = 0; i < _plugins.length; i++) {
            if(address(_plugins[i]) == plugin) {
                _plugins[i] = _plugins[_plugins.length - 1];
                _plugins.pop();
                return;
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
            supportedInterfaces[0] = type(IVersionableStaticWebsitePlugin).interfaceId;
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
    function enableViewerForFrontendVersion(uint256 websiteVersionIndex, bool enable) public onlyOwner {
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
    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal virtual override view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
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
        IVersionableStaticWebsitePlugin[] storage plugins = websiteVersion.plugins;

        // Plugins: rewrite the request
        for(uint i = 0; i < plugins.length; i++) {
            bool rewritten;
            string[] memory newResource;
            KeyValue[] memory newParams;
            (rewritten, newResource, newParams) = plugins[i].rewriteWeb3Request(this, frontendIndex, resource, params);
            if(rewritten) {
                resource = newResource;
                params = newParams;
            }
        }

        // Plugins: return content before the static content
        for(uint i = 0; i < plugins.length; i++) {
            (statusCode, body, headers) = plugins[i].processWeb3RequestBeforeStaticContent(this, frontendIndex, resource, params);
            if(statusCode != 0) {
                return (statusCode, body, headers);
            }
        }

        // Plugins: return content after the static content
        for(uint i = 0; i < plugins.length; i++) {
            (statusCode, body, headers) = plugins[i].processWeb3RequestAfterStaticContent(this, frontendIndex, resource, params);
            if(statusCode != 0) {
                return (statusCode, body, headers);
            }
        }
    }


}