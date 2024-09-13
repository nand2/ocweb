# web3://ocweb.eth

`web3://ocweb.eth` ([HTTPS gateway link](https://ocweb.eth.eth.web3gateway.dev/)) is a [`web3://`](https://docs.web3url.io/) website which lets you mint OCWebsites.

## ``web3://`` protocol

In short, ``web3://`` is like ``https://``, but websites are smart contracts, and the blockchain is the server. This is standardized by [several Ethereum ERCs](https://docs.web3url.io/web3-url-structure/base#standards). Learn more with the [presentation website](https://web3url.io) and [documentation website](https://docs.web3url.io/). Try live with the [``web3://`` sandbox](https://w3-sandbox.eth.eth.web3gateway.dev/). Download the [native EVM Browser](https://github.com/web3-protocol/evm-browser) or learn about the [HTTPS gateways](https://docs.web3url.io/web3-clients/https-gateway).

## OCWebsites

OCWebsites are ``web3://`` websites prepackaged with a plugin system (themes, features, ...), a versioning system and an admin interface. They appear as NFTs in your wallet.

They are useful for both : 

- Developers: ability to upload a frontend (via admin or CLI) to your OCWebsite, manage multiple versions (switch live version), create and add your own plugins
- Non-developers : Use the admin interface to configure themes, add and publish pages (at the moment, only one theme available)

![](./assets/ocWebAdmin.png)

## ocweb CLI

``ocweb`` is a CLI tool to interact with OCWebsites. Install it with ``npm i ocweb``

```
ocweb [options] <command>

Commands:
  mint <chainId> <subdomain>  Mint a new OCWebsite on a blockchain
  list <chainId>              List the OCWebsites owned by the wallet
  upload [arguments..]        Upload a static frontend to the website. Require the Static Frontend plugin installed.
  ls [folder]                 List the files in the static frontend
  rm <files..>                Remove a file from the static frontend
```

## OCWebsite versioning

New OCWebsites comes with an initial version. You can create a new version anytime, which will duplicate another version. Each version is totally independant, including the installed plugin list and their configuration.

- You can change the version being the live version served by your OCWebsite.
- You can enable a viewer for non-live versions, in order to preview them, and/or to make available a historical version.
- You can lock a version, which becomes immutable.

![](./assets/ocWebAdminVersioning.png)

## OCWebsite plugins

Several plugins come pre-installed with a newly minted OCWebsite.

![](./assets/ocWebAdminPlugins.png)

## Develop your own OCWebsite plugin

A plugin must implement the [IVersionableWebsitePlugin interface](https://github.com/nand2/ocweb/blob/master/contracts/src/interfaces/IVersionableWebsite.sol). 

The ["Theme About Me" plugin](https://github.com/nand2/ocweb-theme-about-me) is an example of standalone plugin providing a theme, and an admin panel loaded in the OCWebsite admin interface.
