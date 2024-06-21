<script setup>
import { useContractAddresses } from '../utils/queries.js';

const { isSuccess: contractAddressesLoaded, data: contractAddresses } = useContractAddresses()


</script>


<template>
  My websites
</template>