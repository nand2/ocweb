# OCWebsite plugin development

A OCWebsite plugin is a smart contract which implements the [IVersionableWebsitePlugin interface](https://github.com/nand2/ocweb/blob/master/contracts/src/interfaces/IVersionableWebsite.sol).

## IVersionableWebsitePlugin interface

The following functions need to be implemented :

### processWeb3Request()

```
function processWeb3Request(IVersionableWebsite website, uint websiteVersionIndex, string[] memory resource, KeyValue[] memory params) external view returns (uint statusCode, string memory body, KeyValue[] memory headers);
```

Very basically, when a page is requested from an OCWebsite, each installed plugin is asked one after the other if it wants to answer this page. It does so by calling the `processWeb3Request` method of each plugin. The first one to answer will be returned to the client.


Arguments:
- `IVersionableWebsite website` : The address of the OCWebsite asked to process a page request.
- `uint websiteVersionIndex` : The version of the OCWebsite for which we are asked to process a page request. ([Read about OCWebsite versions](https://github.com/nand2/ocweb/tree/master?tab=readme-ov-file#ocwebsite-versioning))
- ` string[] memory resource, KeyValue[] memory params` : The path requested, using the [Resource request  mode IDecentralizedApp interface](https://docs.web3url.io/web3-url-structure/resolve-mode/mode-resource-request). Basic example: `/aa/bb?c=1&d=2` will be sent as `resource`=`['aa', 'bb']` and `params`=`[KeyValue{key='c', value='1"}, KeyValue{key='d', value='2"}]`.

Return:
- `uint statusCode` : If you want to respond to this request, return a non-zero standard HTTP response code here (usually `200`).
- `string memory body` : The data you want to return as a response. Note that, even though it has a `string` type, you can return any binary data. (Reason is: the [IDecentralizedApp interface](https://docs.web3url.io/web3-url-structure/resolve-mode/mode-resource-request) unfortunately use a `string` type.)
- `KeyValue[] memory headers` : The HTTP headers you want to return. Can be any valid HTTP headers, such as `Content-type`, ...
 
Here is a basic example, ignoring the OCWebsite it comes from. It will answer to the `/` and `/index/[uint]` pages.

```solidity
    function processWeb3Request(IVersionableWebsite website, uint websiteVersionIndex, string[] memory resource, KeyValue[] memory params)
        external view override returns (uint statusCode, string memory body, KeyValue[] memory headers)
    {
        // Frontpage
        if(resource.length == 0) {
            body = indexHTML(1); // Function to do
            statusCode = 200;
            headers = new KeyValue[](1);
            headers[0].key = "Content-type";
            headers[0].value = "text/html";
        }
        // /index/[uint]
        else if(resource.length >= 1 && resource.length <= 2 && ToString.compare(resource[0], "index")) {
            uint page = 1;
            if(resource.length == 2) {
                page = ToString.stringToUint(resource[1]);
            }
            if(page == 0) {
                statusCode = 404;
            }
            else {
                body = indexHTML(page); // Function to do
                statusCode = 200;
                headers = new KeyValue[](1);
                headers[0].key = "Content-type";
                headers[0].value = "text/html";
            }
        }
    }
```

### copyFrontendSettings()

`function copyFrontendSettings(IVersionableWebsite website, uint fromWebsiteVersionIndex, uint toWebsiteVersionIndex) external;`

A better naming would have been `copyWebsiteVersionSettings`. This function is called when the plugin is requested to copy the plugin settings of a OCWebsite version to another. The main usecase is : When creating a new OCWebsite version, the user can choose to "copy" a version, a bit like forking. So each plugin is requested to copy his settings.

Example : 

```solidity
contract MyPlugin is ERC165, IVersionableWebsitePlugin {
    // Some settings for your plugin
    struct Settings {
        uint setting1;
        string setting2;
    }
    // Storing settings for each OCWebsite version
    mapping(IVersionableWebsite => mapping(uint => Settings) public settings;
    
    function copyFrontendSettings(IVersionableWebsite website, uint fromFrontendIndex, uint toFrontendIndex) public {
        require(address(website) == msg.sender);

        settings[website][toFrontendIndex] = settings[website][fromFrontendIndex];
    }
}

```

### infos()

```
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
```

Return the details of your plugin, to be displayed by UI frontend.

#### Dependencies

Right now dependencies handling is very basic : `IVersionableWebsitePlugin[] dependencies;` is a list of other plugins that are required to be installed before this plugin is installed.

There is no minimal/maximal version handling for dependencies, and there isn't even a link between different versions of a same plugin. You cannot upgrade from a version to another. As such, `version` can be anything you like, such as `0.1.0`.

It is expected later a second version of plugins with much more advanced versioning, upgrading and dependencies handling, if OCWebsites does gain traction.

#### Admin panels

A plugin can expose admin panels to let user configure the plugin, via the `AdminPanel[] adminPanels` value.

```
    enum AdminPanelType {
        Primary,
        Secondary
    }
    // Represent an admin panel for this plugin
    // 2 types : 
    // - An autonomous webpage (which can be iframed by global admin panels)
    // - A UMD module which is loaded by a global admin panel
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
```

The admin panel can be of 2 types :

##### A standalone HTML page

- `url` should contains the `web3://` address of this standalone page, 
- `moduleForGlobalAdminPanel` should be empty. 

The standalone page will be iframe'd by the current default `Admin interface` plugin.
  
##### A javascript UMD module to be embedded in an existing admin interface

This is more complex :

- `url` should contains the `web3://` address of the javascript UMD file.
- `moduleForGlobalAdminPanel` should be the address of the OCWebsite plugin providing the admin interface.
 
If you want to develop a admin panel for the OCWeb `Admin interface` plugin, please [follow this guide](./plugins-ocweb-admin-panel-dev.md)

