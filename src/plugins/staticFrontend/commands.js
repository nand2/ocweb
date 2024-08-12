import chalk from "chalk";
import { StaticFrontendPluginClient } from './client.js'
import path from 'path'
import mime from 'mime';
import fs from 'fs'
import readline from 'node:readline/promises';

async function processCommand(command, args, viemClient, contractAddress, websiteVersionIndex, installedPlugins) {
  // Ensure the Static Frontend plugin is installed
  const staticFrontendPlugin = installedPlugins.find(plugin => plugin.infos.name == "staticFrontend")
  if(staticFrontendPlugin == null) {
    console.error("The Static Frontend plugin is not installed on this website.")
    process.exit(1)
  }

  // Prepare the StaticFrontendPluginClient
  const staticFrontendPluginClient = new StaticFrontendPluginClient(viemClient, contractAddress, staticFrontendPlugin.plugin);

  // Get the static frontend
  const staticFrontend = await staticFrontendPluginClient.getStaticFrontend(websiteVersionIndex);

  // staticFrontend.files is an array of objects containing the file path
  // Make a tree structure out of it
  let fileTree = {}
  staticFrontend.files.forEach((file, fileIndex) => {
    let pathParts = file.filePath.split('/')
    let currentTree = fileTree
    pathParts.forEach((part, index) => {
      if(index == pathParts.length - 1) {
        currentTree[part] = fileIndex
      }
      else {
        if(currentTree[part] == undefined) {
          currentTree[part] = {}
        }
        currentTree = currentTree[part]
      }
    })
  })

  // Command switch
  switch(command) {
    case "upload":
      await upload(staticFrontendPluginClient, websiteVersionIndex, staticFrontend, fileTree, args)
      break
    case "ls":
      await ls(staticFrontendPluginClient, websiteVersionIndex, staticFrontend, fileTree, args)
      break
    case "rm":
      await rm(staticFrontendPluginClient, websiteVersionIndex, staticFrontend, fileTree, args)
      break
    default:
      console.error("Unknown command: " + command)
      process.exit(1)
  }
}

async function upload(staticFrontendPluginClient, websiteVersionIndex, staticFrontend, fileTree, args) {
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
    try {
      fs.accessSync(source, fs.constants.R_OK)
    }
    catch(e) {
      console.error("Cannot access " + source + ": " + e.message)
      process.exit(1)
    }
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

  // Apply the exclude options : Remove the files that match the exclude patterns
  // Only do the matching on the filename part, and only the "*" wildcard is supported
  if(args.exclude.length > 0) {
    filePaths = filePaths.filter(filePath => {
      return !args.exclude.some(pattern => {
        return new RegExp("^" + pattern.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*') + "$").test(path.basename(filePath.source))
      })
    })
  }

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
  const { transactions: uploadTransactions, skippedFiles } = await staticFrontendPluginClient.prepareAddFilesTransactions(websiteVersionIndex, fileInfos)

  // Print about the transactions
  if(uploadTransactions.length > 0) {
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
  }

  // Print about the skipped files
  if(skippedFiles.length > 0) {
    console.log(chalk.bold("Skipped files") + " (identical file already uploaded)")
    skippedFiles.forEach(file => {
      console.log(" - " + file.filePath)
    })
    console.log()
  }

  if(uploadTransactions.length == 0) {
    console.log("All files are already uploaded. Nothing to do.")
    process.exit()
  }

  // Ask for confirmation (if not requested to be skipped)
  if(args.skipTxValidation == false) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    const confirmationAnswer = await rl.question("Transactions are about to be sent, which will cost some ETH. Do you confirm? (y/n) ");
    rl.close();
    if(confirmationAnswer != "y") {
      console.log("Cancelled.")
      process.exit(1)
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

async function ls(staticFrontendPluginClient, websiteVersionIndex, staticFrontend, fileTree, args) {
  // Find the folder to list
  const folder = args.folder.replace(/^\/|\/$/g, '')
  let currentTree = fileTree
  if(folder.length > 0) {
    folder.split('/').forEach(part => {
      if(currentTree[part] == undefined) {
        console.error("Folder not found")
        process.exit(1)
      }
      currentTree = currentTree[part]
    })
  }

  // List the files : Normal way
  if(args.tree == false) {
    if(typeof currentTree == "object") {
      if(Object.entries(currentTree).length == 0) {
        console.log(chalk.dim("Empty directory"))
      }
      else {
        Object.entries(currentTree).forEach(([filePathPart, subTree]) => {
          // If the subTree is an object, it is a folder
          if(typeof subTree == "object") {
            process.stdout.write(chalk.bold(chalk.blue(filePathPart)) + "  ");
          }
          // If the subTree is a number, it is a file
          else {
            process.stdout.write(filePathPart + "  ");
          }
        })
      }
    }
    else if(typeof currentTree == "number") {
      process.stdout.write(staticFrontend.files[currentTree].filePath);
    }
    console.log("")
  }
  // List the files : tree way
  else if(args.tree == true) {
    function printTree(tree, depth) {
      Object.entries(tree).forEach(([filePathPart, subTree]) => {
        // If the subTree is an object, it is a folder
        if(typeof subTree == "object") {
          process.stdout.write("  ".repeat(depth) + chalk.bold(chalk.blue(filePathPart)) + "\n");
          printTree(subTree, depth + 1)
        }
        // If the subTree is a number, it is a file
        else {
          process.stdout.write("  ".repeat(depth) + filePathPart + "\n");
        }
      })
    }
    printTree(currentTree, 0)
  }
}

async function rm(staticFrontendPluginClient, websiteVersionIndex, staticFrontend, fileTree, args) {
  // Process the arguments : List the files to remove
  let filesToRemove = []
  let removeAllFiles = false;
  // No usage of recursive option: All files given should be files
  if(args.recursive == false) {
    args.files.forEach(file => {
      // Search for the file in the staticFrontend.files array
      let fileIndex = staticFrontend.files.findIndex(f => f.filePath == file)
      if(fileIndex == -1) {
        console.error("File not found: " + file)
        process.exit(1)
      }
      filesToRemove.push(file)
    })
  }
  // Recursive option: All files given can be files or directories
  else if(args.recursive == true) {
    // If one of the files is ".", we remove all the files
    if(args.files.includes(".")) {
      removeAllFiles = true;
    }
    // We remove a subsection of files
    else {
      args.files.forEach(file => {
        // Search for the file in the staticFrontend.files array
        let fileIndex = staticFrontend.files.findIndex(f => f.filePath == file)
        if(fileIndex != -1) {
          filesToRemove.push(file)
        }
        else {
          // Search for the directory in the fileTree
          let currentTree = fileTree
          let pathParts = file.split('/')
          pathParts.forEach(part => {
            if(currentTree[part] == undefined) {
              console.error("Directory not found: " + file)
              process.exit(1)
            }
            currentTree = currentTree[part]
          })

          let directoryFiles = []
          function getFiles(tree, currentPath = '') {
            Object.entries(tree).forEach(([filePathPart, subTree]) => {
              const filePath = path.join(currentPath, filePathPart);
              if (typeof subTree == "number") {
                directoryFiles.push(filePath);
              } else {
                getFiles(subTree, filePath);
              }
            });
          }
          getFiles(currentTree)
          directoryFiles.forEach(directoryFile => {
            filesToRemove.push(path.join(file, directoryFile))
          })
        }
      })
    }
  }

  // Unduplicate the list
  filesToRemove = [...new Set(filesToRemove)]

  // Prepare the remove transactions
  let removeTransaction = null
  if(removeAllFiles) {
    removeTransaction = await staticFrontendPluginClient.prepareRemoveAllFilesTransaction(websiteVersionIndex)
  }
  else {
    removeTransaction = await staticFrontendPluginClient.prepareRemoveFilesTransaction(websiteVersionIndex, filesToRemove)
  }

  // Print about the transaction
  console.log(chalk.bold("1 transaction will be needed"))
  console.log("")
  if(removeTransaction.functionName == "removeAllFiles") {
    console.log(chalk.bold("Transaction 1: " + chalk.yellow("Removing all files")))
  }
  else if(removeTransaction.functionName == "removeFiles") {
    console.log(chalk.bold("Transaction 1: Removing files"))
    filesToRemove.forEach(file => {
      console.log(" - " + file)
    })
  }
  console.log("")

  // Ask for confirmation (if not requested to be skipped)
  if(args.skipTxValidation == false) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    const confirmationAnswer = await rl.question("Transactions are about to be sent, which will cost some ETH. Do you confirm? (y/n) ");
    rl.close();
    if(confirmationAnswer != "y") {
      console.log("Cancelled.")
      process.exit(1)
    }
    console.log("")
  }

  // Execute the transaction
  console.log("Submitting transaction...")
  const hash = await staticFrontendPluginClient.executeTransaction(removeTransaction);
  console.log("Transaction submitted with hash " + hash)
  console.log("Waiting for confirmation...");

  // Wait for the transaction to be mined
  await staticFrontendPluginClient.waitForTransactionReceipt(hash);
  console.log("Transaction confirmed");
  console.log("");
}



export {
  processCommand
}