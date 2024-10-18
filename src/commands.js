import chalk from "chalk";
import readline from 'node:readline/promises';

import { FactoryClient } from './factoryClient.js'
import { getDeploymentAddressByChainId } from './deployments.js'

async function processCommand(command, args, viemClient) {

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
}

export { processCommand };