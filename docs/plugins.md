# OCWebsite plugin development

## Plugin interface

A OCWebsite plugin is a smart contract which implements the [IVersionableWebsitePlugin interface](./plugins-interface.md).

See [the interface description](./plugins-interface.md).

## Plugin starter kit

The [OCWebsite Starter Kit Plugin](https://github.com/nand2/ocweb-plugin-starter-kit) is a template to help you make your OCWebsite plugin. Fork it, build it, and experiment with it.

## Existing plugins

The following plugins were developed in separate repositories : 

- [Theme "About Me"](https://github.com/nand2/ocweb-theme-about-me) : A theme with a configurable left menu. The user is able to configure the theme and publish pages.
- [VisualizeValue Mint Frontend](https://github.com/nand2/ocweb-visualizevalue-mint) : A plugin to host your own [artist Mint page by VisualizeValue](https://docs.mint.vv.xyz/). The user can configure the theme and other settings in the admin panel.

The following plugins were developed inside the Ocweb repository : 

- [Injected Variables](https://github.com/nand2/ocweb/blob/master/contracts/src/OCWebsite/plugins/InjectedVariablesPlugin.sol) : Let users add some key/values, which will be made available at the `/variables.json` path. Include the hardcoded address of the OCWebsite being viewed in the `self` value.
- [Static Frontend](https://github.com/nand2/ocweb/blob/master/contracts/src/OCWebsite/plugins/StaticFrontendPlugin.sol) : A major brick: Let users upload files in a filesystem-like structure, which is then served. Useful to upload static frontend. (`web3://ocweb.eth` is a static website hosted via this plugin).
- [Admin interface](https://github.com/nand2/ocweb/blob/master/contracts/src/OCWebsite/plugins/OCWebAdminPlugin.sol) : This add an admin interface to the OCWebsite at the `/admin` path. This plugin is actually proxying the request to the OCWebsite hosting `web3://ocweb.eth`, which detect it is called from another OCWebsite, and adapt slightly his interface.

## Common patterns

### Served content

So far, 2 main patterns have emerged:

- For plugins with small basic output (such as [Injected Variables](https://github.com/nand2/ocweb/blob/master/contracts/src/OCWebsite/plugins/InjectedVariablesPlugin.sol)), the whole output is generated in Solidity in the smart contract.
- For plugins with larger output (such as [Theme "About Me"](https://github.com/nand2/ocweb-theme-about-me)), one or more separate OCWebsites are used to host static files (thanks to the [Static Frontend](https://github.com/nand2/ocweb/blob/master/contracts/src/OCWebsite/plugins/StaticFrontendPlugin.sol) plugin), and the plugin will basically proxy the requests to this OCWebsite, and expose an extra path that will contains configuration elements.

### Configuration storage

So far, 2 main patterns have emerged:

- For configuration elements that impact the output at the smart contract level (e.g. on which root path will the plugin content be served) : they are stored on the smart contract. Example : 
    ```
        struct Config {
            string[] rootPath;
        }
        mapping(IVersionableWebsite => mapping(uint => Config)) private configs;
    ```
- For the other configuration elements : they are stored as JSON/YAML/... in a file stored in the filesystem provided by the [Static Frontend](https://github.com/nand2/ocweb/blob/master/contracts/src/OCWebsite/plugins/StaticFrontendPlugin.sol) plugin. This approach offers more flexibility, and is used (alongside the first pattern) by the [Theme "About Me"](https://github.com/nand2/ocweb-theme-about-me) and [VisualizeValue Mint Frontend](https://github.com/nand2/ocweb-visualizevalue-mint) plugin.
