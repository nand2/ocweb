<script setup>
import { ref, onMounted } from 'vue'
import TextEditor from './TextEditor.vue';

const text = defineModel('text')



</script>

<template>
  <div>
    <TextEditor v-model:text="text" />
  </div>
</template>

<style scoped>

</style>