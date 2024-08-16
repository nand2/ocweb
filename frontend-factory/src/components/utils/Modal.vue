<script setup>
import XCircleIcon from '../../icons/XCircleIcon.vue';

const show = defineModel('show', {
  type: Boolean,
  required: true,
})
const props = defineProps({
  title: {
    type: String,
    required: false,
  },
})

const emit = defineEmits(['close'])

</script>

<template>
  <div class="modal" v-show="show">
    <div class="modal-inner">
      <h3 v-if="title" class="modal-title">
        <span>
          {{ title }}
        </span>
        <a class="white" @click.stop.prevent="show = false; $emit('close')" style="line-height: 0em;">
          <XCircleIcon />
        </a>
      </h3>
      <div class="modal-content">
        <slot />
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;  
  z-index: 1;
}

.modal-inner {
  background-color: var(--color-root-bg);
  border-radius: 5px;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
  max-width: 90%;
  max-height: 90%;
  overflow: auto;
  z-index: 1;
}

.modal-title {
  margin: 0;
  padding: 0.4em 1em 0.4em 1em;
  border-bottom: 1px solid var(--color-divider-secondary);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 3em;
}

.modal-content {
  padding: 1em 1em 1em 1em;
}
</style>
