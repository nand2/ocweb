<script setup>
import { Suspense } from 'vue';
import LeftBar from './components/LeftBar.vue';
</script>

<template>
  <Suspense>
    <div class="root">
      <LeftBar />
      <RouterView />
    </div>
  </Suspense>
</template>

<style scoped>
  .root {
    display: flex;
    gap: 80px;
  }

  @media (max-width: 768px) {
    .root {
      flex-direction: column;
      gap: 0;
    }
  }
</style>
