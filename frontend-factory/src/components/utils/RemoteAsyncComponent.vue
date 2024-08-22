<script setup>
import { defineAsyncComponent, shallowRef, ref, onMounted } from 'vue';
import * as Vue from 'vue';
import * as TanstackVueQuery from '@tanstack/vue-query';
import * as WagmiVue from '@wagmi/vue';
import RemoteAsyncComponentError from './RemoteAsyncComponentError.vue';

const props = defineProps({
  url: {
    type: String,
    required: true,
  },
  props: {
    type: Object,
    default: {},
  },
});

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
  <component v-if="asyncComponent" :is="asyncComponent" v-bind="props.props"></component>
</template>