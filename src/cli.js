#!/usr/bin/env node

import yargs from "yargs";
import { hideBin } from 'yargs/helpers'
import fs from 'fs'
import path from 'path'
import mime from 'mime';
import { createWalletClient, http, publicActions, toBlobs, toHex, setupKzg, encodeFunctionData, getContract, formatEther } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import * as viemChains from 'viem/chains'
import { VersionableWebsiteClient } from './versionableWebsiteClient.js'
import { StaticFrontendPluginClient } from './plugins/staticFrontend/client.js'
import readline from 'node:readline/promises';
import chalk from "chalk";
import { exit } from "process";
import { processCommand as processStaticFrontendPluginCommand } from './plugins/staticFrontend/commands.js'

const y = yargs(hideBin(process.argv))
  .usage("ocweb [options] <command>")
  .option('rpc', {
    alias: 'r',
    type: 'string',
    requiresArg: true,
    description: "The RPC provider URL. Example: https://your.provider.com/"
  })
  .option('private-key', {
    alias: 'k',
    type: 'string',
    requiresArg: true,
    description: "The private key of the wallet to use for signing transactions (Environment variable: PRIVATE_KEY)"
  })
  .option('web3-address', {
    alias: 'a',
    type: 'string',
    requiresArg: true,
    description: "The web3:// address of the OCWebsite. Format: web3://<address>:<chain-id>. Example: web3://0x9bd03768a7DCc129555dE410FF8E85528A4F88b5:31337 (Environment variable: WEB3_ADDRESS)"
  })
  .option('website-version', {
    alias: 'w',
    type: 'string',
    requiresArg: true,
    default: 'live',
    description: "The version of your OCWebsite. Either 'live' or a version index."
  })
  .option('skip-tx-confirmation', {
    alias: 's',
    type: 'boolean',
    description: "Skip the confirmation prompt for transactions",
    default: false
  })
  .command('upload [arguments..]', 
    'Upload a static frontend to the website. Require the Static Frontend plugin installed.', 
    (yargs) => {
      yargs.positional('arguments', {
        type: 'string',
        description: 'The files or directories to upload, followed by the destination folder on the website. Examples: oweb upload ; ocweb upload ./folder ; ocweb upload ./img.jpg ; ocweb upload ./folder /remote-folder ; ocweb upload ./folder1 ./folder2 /remote-folder',
        array: true,
        default: ['.', '/']
      })
    }
  )
  .command('ls [folder]', 
    'List the files in the static frontend', 
    (yargs) => {
      yargs.option('tree', {
        alias: 't',
        type: 'boolean',
        description: 'Display the files in a tree structure',
        default: false
      })
      yargs.positional('folder', {
        type: 'string',
        description: 'The folder/file to list',
        default: '/'
      })
    }
  )
  .command('rm <files..>',
    'Remove a file from the static frontend',
    (yargs) => {
      yargs.option('recursive', {
        alias: 'R',
        type: 'boolean',
        description: 'Remove directories recursively',
        default: false
      })
      yargs.positional('files', {
        type: 'string',
        description: 'The files to remove',
        array: true
      })
    }
  )
  .demandCommand(1)
  .strict()
let args = y.parse()



// Private key and web3 address are required
// Fetch from the arguments, and if not provided, from the environment variables
if(args.privateKey == null) {
  args.privateKey = process.env.PRIVATE_KEY
}
if(args.web3Address == null) {
  args.web3Address = process.env.WEB3_ADDRESS
}
if(args.privateKey == null || args.web3Address == null) { 
  console.error("Private key and web3 address are required.")
  process.exit(1)
}

// Website version: Ensure it is "live" or a number
if(args.websiteVersion != "live") {
  const versionNumber = parseInt(args.websiteVersion)
  if(isNaN(versionNumber)) {
    console.error("Invalid website version. Please use 'live' or a number.")
    process.exit(1)
  }
  args.websiteVersion = versionNumber
}


// Parse the web3 address: extract the contract address and the chain id
const web3Address = args.web3Address
// Do a regex to extract the address and the chain id
const web3AddressRegex = /^web3:\/\/(?<address>[0-9a-fA-Fx]{42})(:(?<chainId>[1-9][0-9]*))?/
const web3AddressMatch = web3Address.match(web3AddressRegex)
if(web3AddressMatch == null) {
  console.error("Invalid web3 address. Please use the format web3://<address>:<chain-id>")
  process.exit(1)
}
const contractAddress = web3AddressMatch.groups.address
const chainId = parseInt(web3AddressMatch.groups.chainId) || 1

// Find the viem chain for the chain id
const viemChain = Object.values(viemChains).find(chain => chain.id == chainId)
if(viemChain == null) {
  console.error("Invalid chain id", chainId)
  process.exit()
}

// Determine the RPC we use
let rpcUrl = viemChain.rpcUrls.default.http[0]
// If overriden by the command line, use the provided RPC
if(args.rpc) {
  rpcUrl = args.rpc
}

// Prepare the viem client
const account = privateKeyToAccount(args.privateKey)
const viemClient = createWalletClient({
  account,
  chain: viemChain,
  transport: http(rpcUrl)
}).extend(publicActions)

// Print the account address, and its balance
const accountAddress = account.address
const accountBalance = formatEther((await viemClient.getBalance({address: accountAddress})) / BigInt(10**13) * BigInt(10**13))
console.log("Wallet: " + chalk.bold(accountAddress) + " Balance: " + chalk.bold(accountBalance + " " + viemChain.nativeCurrency.symbol))


console.log("OCWebsite: " + chalk.bold(contractAddress) + " on chain " + chalk.bold(viemChain.name) + " (id " + viemChain.id + ")")


// Prepare the VersionableWebsiteClient
const websiteClient = new VersionableWebsiteClient(viemClient, contractAddress);

// Get the live website version
const liveWebsiteVersionInfos = await websiteClient.getLiveWebsiteVersion();

// Determine the website version index we are working with
const websiteVersionIndex = args.websiteVersion == "live" ? liveWebsiteVersionInfos.websiteVersionIndex : args.websiteVersion

// Get the website version
const websiteVersion = await websiteClient.getWebsiteVersion(websiteVersionIndex);

console.log("Website version: " + chalk.bold(websiteVersionIndex) + chalk.bold(websiteVersionIndex == liveWebsiteVersionInfos.websiteVersionIndex ? " (live version)" : "") + (websiteVersion.locked ? " (locked)" : ""))

// Get the installed plugins
const installedPlugins = await websiteClient.getFrontendVersionPlugins(websiteVersionIndex)
// console.log("Installed plugins:", installedPlugins.map(plugin => plugin.infos.title).join(", "))
console.log("")


// Static frontend plugin commands
if(["upload", "ls", "rm"].includes(args._[0])) {
  await processStaticFrontendPluginCommand(args._[0], args, viemClient, contractAddress, websiteVersionIndex, installedPlugins);
}

