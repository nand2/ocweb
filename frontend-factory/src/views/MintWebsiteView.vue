<script setup>
import HelloWorld from '../components/MintForm.vue'
</script>

<template>
  <div class="mint-area-container">
    <div class="mint-area">
      <HelloWorld />
    </div>
  </div>
</template>

<style scoped>
  .mint-area-container {
    display: flex;
    place-items: center;
    height: calc(100vh - 5em);
  }

  .mint-area {
    max-width: 500px;
    margin: 0 auto;
  }
</style>