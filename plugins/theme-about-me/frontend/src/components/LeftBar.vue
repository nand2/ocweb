<script setup>
import { ref, computed, defineProps, inject } from 'vue';
import EnvelopeIcon from '../icons/EnvelopeIcon.vue';
import GeoAltIcon from '../icons/GeoAltIcon.vue';

const themeConfig = inject('themeConfig')

</script>

<template>
  <div class="left-bar">

    <h1 class="site-title">
      {{ themeConfig.title }}
    </h1>
    <div v-if="themeConfig.subtitle" class="site-subtitle">
      {{ themeConfig.subtitle }}
    </div>

    <div class="entries">
      <div v-if="themeConfig.email">
        <EnvelopeIcon />
        <a :href="'mailto:' + themeConfig.email">{{ themeConfig.email }}</a>
      </div>
      <div v-if="themeConfig.location">
        <GeoAltIcon />
        {{ themeConfig.location }}
      </div>
    </div>

    <hr />

    <div class="menu">
      <router-link v-for="menuEntry in themeConfig.menu" :to="menuEntry.path">{{ menuEntry.title }}</router-link>
    </div>

    <hr v-if="themeConfig.externalLinks.length > 0" />

    <div class="external-links" v-if="themeConfig.externalLinks.length > 0">
      <a v-for="externalLink in themeConfig.externalLinks" :href="externalLink.url" target="_blank">{{ externalLink.title }}</a>
    </div>
    
  </div>
</template>

<style scoped>
  .left-bar {
    flex: 0 0 270px;
  }

  .site-title {
    margin-block-end: 0.5em;
  }

  .site-subtitle {
    margin-bottom: 1em;
  }

  .entries {
    display: flex;
    flex-direction: column;
    gap: 0.3em;
    font-size: 0.9em;
  }

  .entries div {
    display: flex;
    gap: 0.4em;
    align-items: center;
  }

  hr {
    margin: 1.5em 0;
  }

  .menu {
    display: flex;
    flex-direction: column;
    gap: 1em;
  }

  .external-links {
    display: flex;
    flex-direction: column;
    gap: 0.5em;
  }
</style>
