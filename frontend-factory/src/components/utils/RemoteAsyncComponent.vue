<script setup>
import { defineAsyncComponent, shallowRef, ref, onMounted, useAttrs } from 'vue';
import * as Vue from 'vue';
import * as TanstackVueQuery from '@tanstack/vue-query';
import * as WagmiVue from '@wagmi/vue';
import RemoteAsyncComponentError from './RemoteAsyncComponentError.vue';

const attrs = useAttrs();
const props = defineProps({
  url: {
    type: String,
    required: true,
  },
});

console.log(attrs);

// We need to give the component access to some libs
// For UMD packaging, we need to do this:
globalThis.Vue = Vue;
globalThis.TanstackVueQuery = TanstackVueQuery;
globalThis.WagmiVue = WagmiVue;

const asyncComponent = shallowRef(null);

onMounted(() => {
  asyncComponent.value = defineAsyncComponent({
    loader: () => {
      return new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = props.url;
        script.onload = () => {
          resolve(globalThis.HelloWorld);
        };
        script.onerror = (error) => {
          const message = 'Failed to load the component located at ' + props.url;
          reject(message);
        };
        document.body.appendChild(script);
      });
    },
    errorComponent: RemoteAsyncComponentError,
  })
})

</script>

<template>
  <div>
    <component v-if="asyncComponent" :is="asyncComponent" v-bind="attrs"></component>
  </div>
</template>