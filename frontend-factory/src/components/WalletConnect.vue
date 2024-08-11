<script setup>
import { useConnect, useAccount, useDisconnect, useBalance, useChainId, useChains } from '@wagmi/vue';

const chains = useChains();
const { connectors, connect } = useConnect();
const { isConnected, address, connector, chainId } = useAccount();
const { disconnect } = useDisconnect();
const { data: balance, isSuccess: balanceFetchIsSuccess } = useBalance({ address: address, unit: 'ether' });

// Balance with the last 4 digits
function formattedBalance() {
  return balanceFetchIsSuccess.value ? `${Number(balance.value.value / (BigInt(10) ** BigInt(balance.value.decimals - 5))) / 100000 } ${balance.value.symbol}` : '';
}
</script>


<template>
  <div class="wallet-connect">
    <div v-if="isConnected == false" class="connect-buttons">
      <button
        v-for="connector in connectors"
        @click="connect({ connector, chainId })"
      >
        Connect with {{ connector.name }}
      </button>
    </div>
    <div v-else class="connected-dashboard">
      <div class="address">
        {{ address.slice(0, 6) }}...{{ address.slice(-4) }}
        @ 
        {{ chains.find(chain => chain.id === chainId)?.name }}
      </div>
      <div class="balance">
        {{ formattedBalance() }}
      </div>
      <button @click="disconnect()">Disconnect</button>
    </div>
  </div>
</template>


<style scoped>
  .wallet-connect {
    font-size: 1em;
  }

  .connect-buttons {
    display: flex;
    gap: 1em;
  }

  .connected-dashboard {
    display: flex;
    align-items: center;
  }

  .connected-dashboard button {
    border-top-left-radius: 0px;
    border-bottom-left-radius: 0px;
  }

  .address, .balance {
    padding: 0.28em 1em;
    border-width: 2px 0px 2px 2px;
    border-style: solid;
    border-color: #1a1a1a;
  }

  .address {
    border-top-left-radius: 0.5em;
    border-bottom-left-radius: 0.5em;
  }

  @media (max-width: 700px) {
    .address {
      white-space: nowrap;
    }

    .balance {
      display: none;
    }
  }
</style>