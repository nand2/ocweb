<script setup>
import MintForm from '../components/MintForm.vue'
</script>

<template>
  <div class="mint-area-container">
    <div class="mint-area">
      <MintForm />
    </div>
  </div>
</template>

<style scoped>
  .mint-area-container {
    display: flex;
    place-items: center;
    height: calc(100vh - 5em);
  }

  @media (max-width: 700px) {
    .mint-area-container {
      height: auto;
    }
  }

  .mint-area {
    margin: 0 auto;
  }
</style>