<script setup>
import { ref, shallowRef, computed, defineProps } from 'vue';
import { useQuery, useMutation } from '@tanstack/vue-query'
import { useQueryClient } from '@tanstack/vue-query'

const props = defineProps({
  frontendVersion: {
    type: null,
    required: true
  },
  frontendVersionIndex: {
    type: Number,
    required: true,
  },
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  websiteClient: {
    type: [Object, null],
    required: true,
  },
})

</script>

<template>
  <div class="frontend-version">
    <div>
      #{{ frontendVersionIndex }} 
    </div>
    <div>
      <span>
        {{ frontendVersion.description }}
        <span class="text-muted" style="font-size: 0.8em">
          {{ frontendVersion.files.length }} files
        </span>
      </span>
    </div>
    <div>
      <!-- <span class="badge" v-if="frontendVersionIndex == liveFrontendVersionData.frontendIndex">
        Live
      </span> -->
      Live/Setlive
    </div>
    <div>
      locked:{{ frontendVersion.locked }}
    </div>
    <div>
      [rename][lock]
    </div>
  </div>
</template>

<style scoped>
.frontend-version {
  display: grid;
  grid-template-columns: 1fr 3fr 1.5fr 1fr 1fr;
  padding: 0.5em 0em;
  align-items: center;
}

.frontend-version > div {
  display: flex;
  line-height: 1em;
  gap: 0.5em;
  padding: 0em 1em;
  word-break: break-all;
}
</style>