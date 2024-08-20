<script setup>
const { default: markdownit } = await import('markdown-it')

import { ref, onMounted, computed } from 'vue';
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'


const props = defineProps({
  page: {
    type: Object,
    required: true
  },
})

// Initialize the markdown engine
const markdownitEngine = markdownit()

// Fetch the page content with tanstack
const { isLoading, isError, isSuccess, error, data } = useQuery({
  queryKey: ['page', computed(() => props.page.markdownFile)],
  queryFn: async () => {
    if(!props.page.markdownFile) {
      throw new Error('Page not configured');
    }
    const response = await fetch(`/${props.page.markdownFile}`);
    if (!response.ok) {
      throw new Error('Network response was not ok');
    }
    return response.text();
  }
});

const renderedMarkdown = computed(() => {
  return isSuccess.value ? markdownitEngine.render(data.value) : '';
})

</script>

<template>
  <div class="page">
    <div v-if="isLoading" style="margin-top: 10em; text-align: center;">
      <span class="dot"></span>
      <span class="dot"></span>
      <span class="dot"></span>
    </div>
    <div v-else-if="isError" class="text-danger" style="margin: 2em; text-align: center; font-size: 0.9em;">
      Failed fetching the page: {{ error.message }}
    </div>
    <div v-else v-html="renderedMarkdown" class="page-content">
    </div>
    
  </div>
</template>

<style scoped>
.page {
  flex: 1 1 500px;
}

.dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background-color: #333;
  margin: 0 5px;
  animation: bounce 0.5s infinite alternate;
}

@keyframes bounce {
  to {
    transform: translateY(-10px);
  }
}


</style>
