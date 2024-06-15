// import { encodeFunctionData } from 'viem'
import { strip_tags, uint8ArrayToHexString } from './utils.js'
import { encodeParameters } from '@zoltu/ethereum-abi-encoder'


export function setupBlogCreationPopup(element, blogFactoryAddress, blogImplementationAddress, chainId, topDomain, domain, subdomainFee, createdBlogCallback) {
  // Cancel button behavior
  element.querySelector('#cancel').addEventListener('click', () => {
    element.style.display = 'none'
  })
  // Close button behavior (step 2)
  element.querySelector('#success-close-popup').addEventListener('click', () => {
    element.style.display = 'none'
    element.querySelector('#step-1').style.display = 'block'
    element.querySelector('#step-2').style.display = 'none'
    if(createdBlogCallback) {
      createdBlogCallback()
    }
  })

  // Set the subdomain fee
  element.querySelector('#subdomain-fee').textContent = Number(subdomainFee / 1000000000000n) / 1000000;

  // Set the blog implementation address
  // element.querySelector('#blog-implementation-address').textContent = blogImplementationAddress

  // Copy link button behavior
  // element.querySelector('#copy-link').addEventListener('click', () => {
  //   const link = element.querySelector('#created-blog-address a').href
  //   navigator.clipboard.writeText(link)
  // })


  //
  // Subdomain check behavior
  //

  const subdomainInput = element.querySelector('#subdomain')
  const subdomainCheck = element.querySelector('#subdomain-check')
  let timeoutId

  subdomainInput.addEventListener('input', () => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => {
      const subdomain = subdomainInput.value
      if (subdomain.length === 0) {
        return
      }
      subdomainCheck.style.color = '';
      subdomainCheck.innerHTML = 'checking...'
      fetch(`web3://${blogFactoryAddress}:${chainId}/isSubdomainValidAndAvailable/string!${subdomain}?returns=(bool,string)`)
        .then(response => response.json())
        .then(data => {
          if (data[0] == true) {
            subdomainCheck.innerHTML = 'Available'
            subdomainCheck.style.color = 'rgb(0, 180, 0)';
          } else {
            subdomainCheck.innerHTML = 'Unavailable: ' + data[1]
            subdomainCheck.style.color = 'rgb(255, 80, 80)';
          }
        })
        .catch(error => {
          subdomainCheck.innerHTML = 'Call failed'
            subdomainCheck.style.color = 'rgb(255, 80, 80)';
          console.error(error)
        })
    }, 500)
  })


  //
  // Form validation
  //

  const titleField = element.querySelector('#title')
  const descriptionField = element.querySelector('#description')
  const subdomainField = element.querySelector('#subdomain')
  const errorMessageDiv = element.querySelector('#error-message')
  const submitButton = element.querySelector('button[type="submit"]')
  const cancelButton = element.querySelector('#cancel')

  // On submit, create a new blog by calling the createBlog method of the BlogFactory contract
  element.querySelector('form').addEventListener('submit', async event => {
    event.preventDefault()
    titleField.disabled = true
    descriptionField.disabled = true
    subdomainField.disabled = true
    cancelButton.disabled = true
    submitButton.disabled = true
    submitButton.innerHTML = 'Creating...'
    errorMessageDiv.innerHTML = '';
    const title = titleField.value
    const description = descriptionField.value
    const subdomain = subdomainField.value

    const stopWithError = (message) => {
      errorMessageDiv.innerHTML = message
      errorMessageDiv.style.display = 'block'
      titleField.disabled = false
      descriptionField.disabled = false
      subdomainField.disabled = false
      cancelButton.disabled = false
      submitButton.disabled = false
      submitButton.innerHTML = 'Create'
    }

    // Fetch a provider
    let provider = null;
    // Check presence of EI-1193 provider
    if (!window.ethereum) {
      stopWithError('No Ethereum provider found')
      return
    }
    provider = window.ethereum

    // Request EIP-1193 provider access authorization
    let walletList = null
    try {
      walletList = await provider.request({
        "method": "eth_requestAccounts",
        "params": []
      });
    }
    catch (error) {
      stopWithError('Wallet authorization failed : ' + error.message)
      return
    }

    // Request chain change
    try {
      await provider.request({
        "method": "wallet_switchEthereumChain",
        "params": [
          {
            "chainId": "0x" + Number(chainId).toString(16).padStart(2, '0')
          }
        ]
      });
    }
    catch (error) {
      stopWithError('Chain switch failed : ' + error.message)
      return
    }
    

    // Prepare the calldata
    // Viem's encodeFunctionData function cost 20kB, 7kB gziped
    // let calldata = encodeFunctionData({
    //   abi: [{
    //     inputs: [{ name: 'title', type: 'string' }, { name: 'description', type: 'string' }, { name: 'subdomain', type: 'string' }],
    //     name: 'addBlog',
    //     outputs: [{ name: 'blog', type: 'address' }],
    //     type: 'function',
    //   }],
    //   args: [title, description, subdomain]
    // })

    // encodeParameters function cost 6kB, 1.5kB gziped
    // addBlog(string title, string description, string subdomain)
    let calldata = "0x4639107c" + uint8ArrayToHexString(encodeParameters([{ name: 'title', type: 'string' }, { name: 'description', type: 'string' }, { name: 'subdomain', type: 'string' }], [title, description, subdomain]))

    // Prepare the value to send: subdomainFee wei if subdomain
    let value = '0x0'
    if(subdomain.length > 0) {
      value = '0x' + subdomainFee.toString(16)
    }

console.log("About to send with args:", title, description, subdomain)
console.log("Calldata", calldata)
console.log("value", value)
console.log("provider.selectedAddress", walletList[0])

    // Estimate gas
    let gasEstimate = null
    try {
      gasEstimate = await provider
        .request({
          method: 'eth_estimateGas',
          params: [
            {
              to: blogFactoryAddress,
              from: walletList[0],
              data: calldata,
              value: value,
              gasLimit: '0xf4240',
            }
          ],
        })
    }
    catch (error) {
      stopWithError('Gas estimation failed : ' + error.message)
      return
    } 

console.log("gasEstimate", gasEstimate)

    // Use the EIP-1193 Ethereum Provider JavaScript API to call the createBlog method of the BlogFactory contract
    let txHash = null
    try {
      txHash = await provider
        .request({
          method: 'eth_sendTransaction',
          params: [
            {
              to: blogFactoryAddress,
              from: walletList[0],
              data: calldata,
              value: value,
              gasLimit: gasEstimate,
            }
          ],
        })
    }
    catch (error) {
      stopWithError('Call failed : ' + error.message)
      return
    }
console.log("txHash", txHash)  

    // Wait for the transaction to be mined
    let txResult = null
    while(txResult == null) {
      try {
        txResult = await provider.request({
          "method": "eth_getTransactionReceipt",
          "params": [
            txHash
          ]
        });
      }
      catch (error) {
        stopWithError('Transaction check failed : ' + error.message)
        return
      }
      await new Promise(resolve => setTimeout(resolve, 5000))
    }
      
console.log("txResult", txResult)

    // Find the BlogCreated log : keccak256("BlogCreated(uint256,address,address)")
    const blogCreatedTopic = "0xe2461beb49977af01dc59a039737b13a3d0f37baf6140b87520953d9df959298";
    const log = txResult.logs.find(log => log.topics[0] == blogCreatedTopic)
    // Get the blog address from the log
    const newBlogAddress = "0x" + log.data.substring(26, 66)
    const newBlogFrontendAddress = "0x" + log.data.substring(90, 130)
    let newBlogFrontendWeb3Address = subdomain ? `web3://${subdomain}.${domain}.${topDomain}` : `web3://${newBlogFrontendAddress}`

    // Chain id addition
    let frontendUseEthStorageChain = false
    if(subdomain) {
      // With the subdomain, there is a TXT record pointing to ethStorage chain
      if(chainId > 1) {
        newBlogFrontendWeb3Address += `:${chainId}`
      }
    }
    else {
      // We need to point to the ethStorage chain in mainnet and sepolia
      // TODO: Better: Make a call to determine the storageMode of the blog frontend
      let targetChainId = chainId;
      if(chainId == 1) {
        frontendUseEthStorageChain = true;
        targetChainId = 333;
      }
      else if(chainId == 11155111) {
        frontendUseEthStorageChain = true;
        targetChainId = 3333;
      }
      newBlogFrontendWeb3Address += `:${targetChainId}`
    }

console.log("newBlogAddress", newBlogAddress)
console.log("newBlogFrontendAddress", newBlogFrontendAddress)
console.log("newBlogFrontendWeb3Address", newBlogFrontendWeb3Address)
console.log("frontendUseEthStorageChain", frontendUseEthStorageChain)

    // Inject it in the UI
    element.querySelector('#created-blog-address a').href = newBlogFrontendWeb3Address + "/"
    element.querySelector('#created-blog-address a').textContent = newBlogFrontendWeb3Address
    element.querySelector('#new-blog-address').textContent = newBlogFrontendAddress

    // Hide step 1 and show step 2
    titleField.disabled = false
    descriptionField.disabled = false
    subdomainField.disabled = false
    cancelButton.disabled = false
    submitButton.disabled = false
    submitButton.innerHTML = 'Create'
    element.querySelector('#step-1').style.display = 'none'
    element.querySelector('#create-popup').style.maxWidth = '700px'
    element.querySelector('#step-2').style.display = 'block'


    

  })
}
