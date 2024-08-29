<script setup>
import { defineAsyncComponent, shallowRef, ref, onMounted, useAttrs } from 'vue';
import * as Vue from 'vue';
import * as TanstackVueQuery from '@tanstack/vue-query';
import * as WagmiVue from '@wagmi/vue';
import * as Viem from 'viem'
import RemoteAsyncComponentError from './RemoteAsyncComponentError.vue';

const attrs = useAttrs();
const props = defineProps({
  umdModuleUrl: {
    type: String,
    required: true,
  },
  moduleName: {
    type: String,
    required: true,
  },
  cssUrl: {
    type: String,
    required: false,
  },
});

// We need to give the component access to some libs
// For UMD packaging, we need to do this:
globalThis.Vue = Vue;
globalThis.TanstackVueQuery = TanstackVueQuery;
globalThis.WagmiVue = WagmiVue;
globalThis.Viem = Viem;

const asyncComponent = shallowRef(null);

// Helper function to resolve a path in an object, e.g. resolvePath(window, "a.b.c") will
// return window.a.b.c
function resolvePath(obj, path) {
  return path.split('.').reduce((acc, part) => acc && acc[part], obj);
}

onMounted(() => {
  asyncComponent.value = defineAsyncComponent({
    loader: () => {
      return new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = props.umdModuleUrl;
        script.onload = () => {
          // Check if CSS URL is provided
          if (props.cssUrl) {
            // Load the CSS
            const link = document.createElement('link');
            link.rel = 'stylesheet';
            link.href = props.cssUrl;
            link.onload = () => {
              resolve(resolvePath(globalThis, props.moduleName));
            };
            link.onerror = (error) => {
              // If CSS fails to load: We resolve the component, but log an error
              const message = 'Failed to load the CSS located at ' + props.cssUrl;
              console.error(message);
              resolve(resolvePath(globalThis, props.moduleName));
            };
            document.head.appendChild(link); // Append CSS to head
          } else {
            // If no CSS URL, resolve component immediately
            resolve(resolvePath(globalThis, props.moduleName));
          }
        };
        script.onerror = (error) => {
          const message = 'Failed to load the component located at ' + props.umdModuleUrl;
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