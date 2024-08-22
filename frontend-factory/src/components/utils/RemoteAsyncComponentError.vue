<script setup>

const props = defineProps({
  error: {
    type: Object,
    required: true,
  },
})
</script>
<template>
  <div class="text-danger" style="text-align: center;">
    Error loading remote component: {{ props.error.message }}
  </div>
</template>