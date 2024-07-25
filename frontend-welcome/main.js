import './style.css'
import logo from '../frontend-factory/public/logo.svg'
import { getWeb3Address } from './index.js'

document.querySelector('#app').innerHTML = `
  <div>
    <a href="https://vitejs.dev" target="_blank">
      
    </a>
    <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript" target="_blank">
      <img src="${logo}" class="logo vanilla" alt="JavaScript logo" />
    </a>
    <h1>Welcome to your web3:// website</h1>

    <div id="your-address">
    </div>

    <div class="card">
      Your website is a smart contract. You can administer it by going to your <a href="#" id="admin-page-link">admin page</a>.
    </div>


    <div class="text-muted text-90">
      This is the default page served by the Welcome Homepage plugin.
    </div>
  </div>
`

try {
  const web3Address = await getWeb3Address()
  document.querySelector('#your-address').innerText = `${web3Address}`
  document.querySelector('#admin-page-link').href = `${web3Address}/admin`
}
catch (e) {
  console.error(e)
}
