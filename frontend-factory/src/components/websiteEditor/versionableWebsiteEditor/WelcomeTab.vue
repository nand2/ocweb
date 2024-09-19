<script setup>
import { ref, computed, defineProps } from 'vue';

import { store } from '../../../utils/store.js';



const props = defineProps({
  websiteVersion: {
    type: Object,
    required: true
  },
  websiteVersionIndex: {
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
    type: Object,
    required: true,
  },
})


</script>

<template>
  <div class="welcome">
    <h2>Welcome to your OCWebsite admin panel</h2>

    <div class="text-90 mb-3 text-center">
      Your OCWebsite is a <code>web3://</code> website made of plugins, which provide features (themes, ...)
    </div>
        
    <div class="text-90 text-center">
      You can configure them by going to the <strong>Plugins</strong> tab, or by using the tabs they may add in the menu above.
    </div>

    <div class="cards">
      <div>
        <h3>Configure the default plugin theme</h3>

        <div class="text-90 mb-3">
          By default the <strong>About Me</strong> theme is installed. To configure it, go to the <strong>Plugins</strong> tab and click on the <strong>Configure</strong> button.
        </div>

        <div class="text-90">
          You will need to create pages for the theme. Do it in the <strong>Pages</strong> tab.
        </div>
      </div>

      <div>
        <h3>Developer mode</h3>

        <div class="text-90 mb-3">
          Are you a developer? Go to the <strong>Settings</strong> tab and enable the <strong>Developer mode</strong> to access advanced features. 
        </div>

        <div class="text-90">
          For example, uninstall the default theme plugin and upload files directly (html, js, ...) by using the <strong>Files</strong> tab.
        </div>
      </div>
    </div>

    <div style="text-align: center; margin-top: 1.5em; ">
      <button style="font-size: 0.9em" @click="store.setHideWelcomeTab(true)">
        Don't show this welcome message again
      </button>
    </div>
  </div>
</template>

<style scoped>
.welcome {
  margin: 2em;
}

h2 {
  margin-top: 0em;
  margin-bottom: 0.4em;
  text-align: center;
}

h3 {
  margin-bottom: 0.4em
}

.text-center {
  text-align: center;
}

.mb-3 {
  margin-bottom: 0.4em;
}

code {
  font-weight: bold;
}

.cards {
  display: grid;
  grid-template-columns: 1fr 1fr;
  margin-top: 0.5em;
  margin-left: 1em;
  margin-right: 1em;
  gap: 2em;
  text-align: center;
}
@media (max-width: 700px) {
  .cards {
    grid-template-columns: 1fr;
  }
}

</style>