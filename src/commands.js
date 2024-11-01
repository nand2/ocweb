import chalk from "chalk";
import readline from 'node:readline/promises';

import { FactoryClient } from './factoryClient.js'
import { getDeploymentAddressByChainId } from './deployments.js'

async function processFactoryCommand(command, args, viemClient) {

  // Validate the factory address
  let factoryAddress = args.factoryAddress || getDeploymentAddressByChainId(viemClient.chain.id) || null
  // Later: we will ship a list of factory addresses
  if(factoryAddress == null) {
    console.error("Factory address is required.")
    process.exit(1)
  }
  // Ensure the factory address is a valid address
  if(!factoryAddress.match(/^0x[0-9a-fA-F]{40}$/)) {
    console.error("Invalid factory address")
    process.exit(1)
  }

  if(command != "factory-infos") {
    console.log("Factory: " + chalk.bold(factoryAddress) + " on chain " + chalk.bold(viemClient.chain.name) + " (id " + viemClient.chain.id + ")")
    console.log("")
  }

  // Prepare the FactoryClient
  const factoryClient = new FactoryClient(viemClient, factoryAddress);

  // Command switch
  switch(command) {
    case "mint":
      await mint(factoryClient, args)
      break

    case "list":
      await list(factoryClient, args)
      break

    case "factory-infos":
      await factoryInfos(factoryClient, args)
      break
  }
}

async function mint(factoryClient, args) {
  // Prepare the transaction
  const transaction = await factoryClient.prepareMintTransaction(args.subdomain);

  // Simulate the transaction
  try {
    const simulationResult = await factoryClient.simulateTransaction(transaction)
  }
  catch(e) {
    console.error("Transaction simulation failed:", e.shortMessage || e.message)
    process.exit(1)
  }

  // Ask for confirmation (if not requested to be skipped)
  if(args.skipTxValidation == false) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    const confirmationAnswer = await rl.question("A transaction is about to be sent, which will cost some ETH. Do you confirm? (y/n) ");
    rl.close();
    if(confirmationAnswer != "y") {
      console.log("Cancelled.")
      process.exit(1)
    }
    console.log("")
  }

  // Execute the transaction (resimulate again, as time may have passed since the user confirmation)
  let transactionHash = null
  try {
    transactionHash = await factoryClient.executeTransaction(transaction);
    console.log("Transaction sent: " + transactionHash)
  }
  catch(e) {
    console.error("Transaction failed:", e.shortMessage || e.message)
    process.exit(1)
  }

  // Wait for the transaction receipt
  let transactionReceipt = null
  try {
    transactionReceipt = await factoryClient.waitForTransactionReceipt(transactionHash);
    console.log("Transaction confirmed")
  }
  catch(e) {
    console.error("Transaction failed:", e.shortMessage || e.message)
    process.exit(1)
  }

  // Find the new OCWebsite address
  // Find the WebsiteCreated log : keccak256("WebsiteCreated(uint256,address)")
  const websiteCreatedTopic = "0x0aff572d1069f7e62f493a4df8d35dc160c72a08c2749f1f3a87d08606cb3725";
  const log = transactionReceipt.logs.find(l => l.topics[0] == websiteCreatedTopic)
  const newOCWebsiteContractAddress =  "0x" + log.data.substring(26, 66)

  console.log("")
  console.log("New OCWebsite smart contract: " + chalk.bold(newOCWebsiteContractAddress) + " on chain " + chalk.bold(factoryClient.chain().name) + " (id " + factoryClient.chain().id + ")")
  console.log("New OCWebsite web3:// address : " + chalk.bold("web3://" + newOCWebsiteContractAddress + (factoryClient.chain().id > 1 ? ":" + factoryClient.chain().id : "")))
}

async function list(factoryClient, args) {
  // Fetch the list of minted websites
  const websites = await factoryClient.detailedTokensOfOwner(factoryClient.viemClient().account.address, 0, 0);

  // Display the list
  console.log("Minted websites:")
  websites.forEach(website => {
    console.log(chalk.bold(website.contractAddress) + " (token " + website.tokenId + " subdomain " + website.subdomain + ")")
  })
}

async function factoryInfos(factoryClient, args) {
  console.log("Address: " + chalk.bold(factoryClient.address()))

  const websiteAddress = await factoryClient.website()
  console.log("Website: " + chalk.bold("web3://" + websiteAddress + (factoryClient.chain().id > 1 ? ":" + factoryClient.chain().id : "")))
  
  const plugins = await factoryClient.getWebsitePlugins([]);
  console.log("Default installed plugins:")
  plugins.forEach(plugin => {
    console.log("  " + chalk.bold(plugin.plugin) + " " + plugin.infos.name + " " + plugin.infos.version)
  })
}

async function processCommand(command, args, websiteClient) {

  // Command switch
  switch(command) {
    case "version-ls":
      await versionLs(websiteClient, args)
      break
    
    case "version-add":
      await versionAdd(websiteClient, args)
      break
  }
}

async function versionLs(websiteClient, args) {
  // Get the live website version
  const liveWebsiteVersionInfos = await websiteClient.getLiveWebsiteVersion();

  // Fetch the list of versions
  const versions = await websiteClient.getWebsiteVersions(0, 0)

  // Display the list
  console.log("Versions:")
  versions[0].forEach((version, index) => {
    // Prepare the web3 address
    const web3AddressChainPart = websiteClient.chain().id > 1 ? ":" + websiteClient.chain().id : ""
    let web3Address = "";
    if(index == liveWebsiteVersionInfos.websiteVersionIndex) {
      web3Address = "web3://" + websiteClient.address() + web3AddressChainPart
    } else if(version.isViewable) {
      web3Address = "web3://" + version.viewer + web3AddressChainPart
    }
    else {
      const web3AdressLength = "web3://".length + 42 + web3AddressChainPart.length
      const labelToPrint = " not viewable "
      const dashesToPrint = web3AdressLength - labelToPrint.length
      const labelWithDashes = "-".repeat(Math.floor(dashesToPrint / 2)) + labelToPrint + "-".repeat(Math.ceil(dashesToPrint / 2))
      web3Address = chalk.dim(labelWithDashes)
    }

    // Print it
    let logEntry = index + "  " + web3Address + "  " + version.description
    if(index == liveWebsiteVersionInfos.websiteVersionIndex) {
      logEntry = chalk.bold(logEntry)
    }
    if(version.locked) {
      logEntry += " " + chalk.bold("(locked)")
    }
    if(index == liveWebsiteVersionInfos.websiteVersionIndex) {
      logEntry += " " + chalk.bold("(live)")
    }
    console.log(logEntry)
  })
}

async function versionAdd(websiteClient, args) {
  // Get the live website version
  const liveWebsiteVersionInfos = await websiteClient.getLiveWebsiteVersion();

  // Prepare the transaction
  const transaction = await websiteClient.prepareAddWebsiteVersionTransaction(args.title, liveWebsiteVersionInfos.websiteVersionIndex);

  // Ask for confirmation (if not requested to be skipped)
  if(args.skipTxValidation == false) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    const confirmationAnswer = await rl.question("A transaction is about to be sent, which will cost some ETH. Do you confirm? (y/n) ");
    rl.close();
    if(confirmationAnswer != "y") {
      console.log("Cancelled.")
      process.exit(1)
    }
    console.log("")
  }

  // Execute the transaction (resimulate again, as time may have passed since the user confirmation)
  let transactionHash = null
  try {
    transactionHash = await websiteClient.executeTransaction(transaction);
    console.log("Transaction sent: " + transactionHash)
  }
  catch(e) {
    console.error("Transaction failed:", e.shortMessage || e.message)
    process.exit(1)
  }

  // Wait for the transaction receipt
  let transactionReceipt = null
  try {
    transactionReceipt = await websiteClient.waitForTransactionReceipt(transactionHash);
    console.log("Transaction confirmed")
  }
  catch(e) {
    console.error("Transaction failed:", e.shortMessage || e.message)
    process.exit(1)
  }
}

async function processWebsiteVersionCommand(command, args, websiteClient, websiteVersionIndex) {
  switch(command) {
    case "version-set-live":
      await versionSetLive(websiteClient, websiteVersionIndex, args)
      break
    
    case "version-set-viewable":
      await versionSetViewable(websiteClient, websiteVersionIndex, args)
      break
  }
}

async function versionSetLive(websiteClient, websiteVersionIndex, args) {
  // Get the live website version
  const liveWebsiteVersionInfos = await websiteClient.getLiveWebsiteVersion();
  if(websiteVersionIndex == liveWebsiteVersionInfos.websiteVersionIndex) {
    console.error("This version is already the live version")
    return;
  }

  // Prepare the transaction
  const transaction = await websiteClient.prepareSetLiveWebsiteVersionIndexTransaction(websiteVersionIndex);

  // Ask for confirmation (if not requested to be skipped)
  if(args.skipTxValidation == false) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    const confirmationAnswer = await rl.question("A transaction is about to be sent, which will cost some ETH. Do you confirm? (y/n) ");
    rl.close();
    if(confirmationAnswer != "y") {
      console.log("Cancelled.")
      process.exit(1)
    }
    console.log("")
  }

  // Execute the transaction (resimulate again, as time may have passed since the user confirmation)
  let transactionHash = null
  try {
    transactionHash = await websiteClient.executeTransaction(transaction);
    console.log("Transaction sent: " + transactionHash)
  }
  catch(e) {
    console.error("Transaction failed:", e.shortMessage || e.message)
    process.exit(1)
  }

  // Wait for the transaction receipt
  let transactionReceipt = null
  try {
    transactionReceipt = await websiteClient.waitForTransactionReceipt(transactionHash);
    console.log("Transaction confirmed")
  }
  catch(e) {
    console.error("Transaction failed:", e.shortMessage || e.message)
    process.exit(1)
  }
}

async function versionSetViewable(websiteClient, websiteVersionIndex, args) {
  // Get the live website version
  const liveWebsiteVersionInfos = await websiteClient.getLiveWebsiteVersion();
  if(websiteVersionIndex == liveWebsiteVersionInfos.websiteVersionIndex) {
    console.warn("This version is the live version: it is always viewable. The updated viewer status will only have effect when another version is set as live.")
  }
  
  // Prepare the transaction
  const transaction = await websiteClient.prepareEnableViewerForWebsiteVersionTransaction(websiteVersionIndex, args.isViewable);

  // Ask for confirmation (if not requested to be skipped)
  if(args.skipTxValidation == false) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    const confirmationAnswer = await rl.question("A transaction is about to be sent, which will cost some ETH. Do you confirm? (y/n) ");
    rl.close();
    if(confirmationAnswer != "y") {
      console.log("Cancelled.")
      process.exit(1)
    }
    console.log("")
  }

  // Execute the transaction (resimulate again, as time may have passed since the user confirmation)
  let transactionHash = null
  try {
    transactionHash = await websiteClient.executeTransaction(transaction);
    console.log("Transaction sent: " + transactionHash)
  }
  catch(e) {
    console.error("Transaction failed:", e.shortMessage || e.message)
    process.exit(1)
  }

  // Wait for the transaction receipt
  let transactionReceipt = null
  try {
    transactionReceipt = await websiteClient.waitForTransactionReceipt(transactionHash);
    console.log("Transaction confirmed")
  }
  catch(e) {
    console.error("Transaction failed:", e.shortMessage || e.message)
    process.exit(1)
  }
}

export { processFactoryCommand, processCommand, processWebsiteVersionCommand };