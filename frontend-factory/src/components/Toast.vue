<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

const message = ref('')
const timeout = ref(null)

function showToast(msg) {
  message.value = msg
  clearTimeout(timeout.value)
  timeout.value = setTimeout(() => {
    message.value = ''
  }, 5000)
}

onUnmounted(() => {
  clearTimeout(timeout.value)
})
</script>

<template>
  <div class="toast">
    <div class="toast-content">
      <div class="toast-icon">
        <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-circle-check" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"></circle>
          <path d="M9 12l2 2 4-4"></path>
        </svg>
      </div>
      <div class="toast-message">
        {{ message }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.toast {
  position: fixed;
  bottom: 1rem;
  right: 1rem;
  z-index: 1000;
}

.toast-content {
  display: flex;
  align-items: center;
  padding: 1rem;
  background-color: #333;
  color: #fff;
  border-radius: 0.5rem;
  box-shadow: 0 0 1rem rgba(0, 0, 0, 0.1);
}

.toast-icon {
  margin-right: 0.5rem;
}

.toast-message {
  font-size: 1rem;
}

</style>