<script setup>

const props = defineProps({
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  websiteVersion: {
    type: Object,
    required: true
  },
  websiteVersionIndex: {
    type: Number,
    required: true,
  },
  websiteClient: {
    type: Object,
    required: true,
  },
})


// A list of chain short names (unfortunately not packaged with Viem)
// Infos from https://chainid.network/chains.json
const chainShortNames = {
  1: 'eth',
  11155111: 'sep',
  17000: 'holesky',
  10: 'oeth',
  11155420: 'opsep',
  42161: 'arb1',
  42170: 'arb-nova',
  421614: 'arb-sep',
  8543: 'base',
  85432: 'basesep',
  31337: 'hardhat'
}
</script>

<template>
  <div class="title">
    Website addresses
    <small class="text-muted" style="font-weight: normal; font-size:0.7em;">
      Ways to access your website
    </small>
  </div>

  <div class="text-90" style="font-weight: bold;">
    Default <code>web3://</code> address
  </div>
  <div>
    <code>web3://{{ contractAddress }}{{ chainId > 1 ? ':' + chainId : '' }}</code>
  </div>
  
  <div v-if="chainShortNames[chainId]" style="margin-top: 1em;">
    <div style="font-size: 0.9em; font-weight: bold; margin-bottom: 0.4em">
      Using your own ENS domain name
    </div>

    <div class="text-90" style="margin-bottom: 0.7em">
      To access this website with <code style="font-weight: bold;">web3://my-domain.eth</code>, edit <code style="font-weight: bold;">my-domain.eth</code> in the official ENS app, and add the following Text Record:
    </div>

    <div class="table-header">
      <div>
        Text Record Name
      </div>
      <div>
        Text Record Value
      </div>
      <div>

      </div>
    </div>

    <div class="table-row">
      <div>
        <code>
          contentcontract
        </code>
      </div>
      <div>
        <code>
          {{ chainShortNames[chainId] }}:{{ contractAddress }}
        </code>
      </div>
    </div>
  </div>

  <div class="text-90" style="font-weight: bold; margin-top: 1em;">
    Using a <code>web3://</code> HTTPS gateway
  </div>
  <div>
    <code>https://{{ contractAddress }}.{{ chainId }}.<span class="text-muted">gateway-domain.tld</span></code>
  </div>
  <div class="text-muted text-80">
    Replace <code>gateway-domain.tld</code> with the domain of the HTTPS gateway you want to use.
  </div>
</template>

<style scoped>
.title {
  font-size: 1.1em;
  font-weight: bold;
  margin-bottom: 0.75em;
}

.table-header,
.table-row {
  grid-template-columns: 1fr 3fr;
}
</style>