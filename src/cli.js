#!/usr/bin/env node

import yargs from "yargs";
import { hideBin } from 'yargs/helpers'
import fs from 'fs'
import path from 'path'
import mime from 'mime';
import { createWalletClient, http, publicActions, toBlobs, toHex, setupKzg, encodeFunctionData, getContract } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import * as viemChains from 'viem/chains'
import { VersionableWebsiteClient } from './versionableWebsiteClient.js'
import { StaticFrontendPluginClient } from './plugins/staticFrontend/client.js'
import readline from 'node:readline/promises';
import chalk from "chalk";
import { exit } from "process";

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
    description: "The private key of the wallet to use for signing transactions"
  })
  .option('web3-address', {
    alias: 'a',
    type: 'string',
    requiresArg: true,
    description: "The web3:// address of the OCWebsite. Format: web3://<address>:<chain-id>. Example: web3://0x9bd03768a7DCc129555dE410FF8E85528A4F88b5:31337"
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
      // yargs.positional('source', {
      //   type: 'string',
      //   description: 'The file or directory to upload',
      //   default: '.'
      // })
      // yargs.positional('destination', {
      //   type: 'string',
      //   description: 'The folder on the website to upload to',
      //   default: '/'
      // })
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
  console.error("Private key and web3 address are required. You can provide them as arguments, or set the PRIVATE_KEY and WEB3_ADDRESS environment variables.")
  process.exit()
}

// Website version: Ensure it is "live" or a number
if(args.websiteVersion != "live") {
  const versionNumber = parseInt(args.websiteVersion)
  if(isNaN(versionNumber)) {
    console.error("Invalid website version. Please use 'live' or a number.")
    process.exit()
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
  process.exit()
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

console.log("OCWebsite: " + chalk.bold(contractAddress) + " on chain " + chalk.bold(viemChain.name) + " (id " + viemChain.id + ")")

// Prepare the viem client
const account = privateKeyToAccount(args.privateKey)
const viemClient = createWalletClient({
  account,
  chain: viemChain,
  transport: http(rpcUrl)
}).extend(publicActions)

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
console.log("Installed plugins:", installedPlugins.map(plugin => plugin.infos.title).join(", "))
console.log("")


if(args._[0] == "upload") {
  // Ensure the Static Frontend plugin is installed
  const staticFrontendPlugin = installedPlugins.find(plugin => plugin.infos.name == "staticFrontend")
  if(staticFrontendPlugin == null) {
    console.error("The Static Frontend plugin is not installed on this website.")
    process.exit()
  }
  console.log(chalk.bold(chalk.underline("Uploading files to static frontend")))
  console.log("")

  // Prepare the StaticFrontendPluginClient
  const staticFrontendPluginClient = new StaticFrontendPluginClient(viemClient, contractAddress, staticFrontendPlugin.plugin);

  // Process the arguments
  if(args.arguments.length == 1) {
    args.arguments.push("/")
  }
  // Destination is always the last argument
  const destination = args.arguments.pop().replace(/^\/|\/$/g, '');
  // Source is the rest
  const sources = args.arguments

  
  // Prepare the files to upload : 
  // For each file in the source directory (if source is a directory), or the file itself (if source 
  // is a file), fetch the file size, content, content type, and relative path to the source directory, 
  // and store them in fileInfos
  
  // First : get the list of files to upload
  let filePaths = []
  sources.forEach(source => {
    let additionalFilePaths = []

    // List all the files in the source directory
    const lstat = fs.lstatSync(source)
    if (lstat.isDirectory()) {
      additionalFilePaths = fs.readdirSync(source, { withFileTypes: true, recursive: true })
        .filter(dirent => dirent.isFile())
        .map(dirent => path.join(dirent.parentPath, dirent.name));
    } else if (lstat.isFile()) {
      additionalFilePaths = [source]
    }

    // For each file: Make 2 entries: the file itself, and the destination on the website
    additionalFilePaths = additionalFilePaths.map(sourceFilePath => {
      // Compute the path on the website
      let destinationFilePath = sourceFilePath
      if(lstat.isDirectory()) {
        destinationFilePath = path.relative(source, destinationFilePath)
        destinationFilePath = path.join(path.basename(source), destinationFilePath)
      }
      else if(lstat.isFile()) {
        destinationFilePath = path.basename(destinationFilePath)
      }
      if(destination.length > 0) {
        destinationFilePath = path.join(destination, destinationFilePath)
      }

      return {
        source: sourceFilePath,
        destination: destinationFilePath
      }
    })

    // Append to the list
    filePaths = filePaths.concat(additionalFilePaths)
  })

  // Then, for each file, get the file size, content, content type
  let fileInfos = filePaths.map(filePath => {
    // File data
    const data = new Uint8Array(fs.readFileSync(filePath.source))
    // File size
    const size = fs.statSync(filePath.source).size

    // Content type detection
    let contentType = mime.getType(filePath.source.split('.').pop())
    if(contentType == "") {
      contentType = "application/octet-stream"
    }

    return {
      filePath: filePath.destination,
      size,
      contentType,
      data,
    }
  })

  // Prepare the upload transactions
  const { transactions: uploadTransactions, skippedFiles } = await staticFrontendPluginClient.prepareAddFilesToStaticFrontendTransactions(websiteVersionIndex, fileInfos)

  // Print about the transactions
  if(uploadTransactions.length == 0) {
    console.log("All files are already uploaded. Nothing to do.")
    process.exit()
  }
  console.log(chalk.bold("" + uploadTransactions.length + " transaction(s) will be needed") + " Uploading " + Math.round(uploadTransactions.reduce((acc, tx) => acc + (tx.metadata.sizeSent || tx.metadata.files.reduce((acc, file) => acc + file.sizeSent, 0)), 0) / 1024) + "KB")
  console.log();
  const txFunctionToLabel = {
    "addFiles": "Uploading files",
    "appendToFile": "Add data to file",
  }
  uploadTransactions.forEach((transaction, transactionIndex) => {
    console.log(chalk.bold(`Transaction ${transactionIndex + 1}:` + (txFunctionToLabel[transaction.functionName] ? ` ${txFunctionToLabel[transaction.functionName]}` : "Unrecognized function")))
    
    if(transaction.functionName == "addFiles") {
      transaction.args[2].forEach((file, fileIndex) => {
        let line = " - " + chalk.bold(file.filePath) + " ";
        if(transaction.metadata.files[fileIndex].chunksCount > 1) {
          line += Math.round(transaction.metadata.files[fileIndex].sizeSent / 1024) + "/";
        }
        line += Math.round(file.fileSize / 1024) + " KB";
        if(transaction.metadata.files[fileIndex].chunksCount > 1) {
          line += " (chunk 1/" + transaction.metadata.files[fileIndex].chunksCount + ")";
        }
        line += " " + chalk.dim("(zipped from " + Math.round(transaction.metadata.files[fileIndex].originalSize / 1024) + " KB)")
        if(transaction.metadata.files[fileIndex].alreadyExists) {
          line += " " + chalk.yellow("Overwrite existing file")
        }
        console.log(line)
      })
    }
    else if(transaction.functionName == "appendToFile") {
      console.log("   " + chalk.bold(transaction.args[2]) + " +" + Math.round(transaction.metadata.sizeSent / 1024) + " KB (chunk " + (transaction.metadata.chunkId + 1) + "/" + transaction.metadata.chunksCount + ")")
    }
    console.log("")
  });

  // Print about the skipped files
  if(skippedFiles.length > 0) {
    console.log(chalk.bold("Skipped files") + " (identical file already uploaded)")
    skippedFiles.forEach(file => {
      console.log(" - " + file.filePath)
    })
    console.log()
  }

  // Ask for confirmation (if not requested to be skipped)
  if(args.skipTxConfirmation == false) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    const confirmationAnswer = await rl.question("Transactions are about to be sent. Do you confirm? (y/n) ");
    rl.close();
    if(confirmationAnswer != "y") {
      console.log("Cancelled.")
      process.exit()
    }
    console.log("")
  }

  
  
  // Execute the transactions
  for(let transactionIndex = 0; transactionIndex < uploadTransactions.length; transactionIndex++) {
    const transaction = uploadTransactions[transactionIndex]
    console.log("Submitting transaction " + (transactionIndex + 1) + "/" + uploadTransactions.length + "...")
    
    const hash = await staticFrontendPluginClient.executeTransaction(transaction);
    console.log("Transaction submitted with hash " + hash)
    console.log("Waiting for confirmation...");

    // Wait for the transaction to be mined
    await staticFrontendPluginClient.waitForTransactionReceipt(hash);
    console.log("Transaction confirmed");
    console.log("");
  }
    


}