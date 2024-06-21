<script setup>
import HelloWorld from './components/MintForm.vue'
</script>


<template>
  <div class="app">
    <div class="sidebar">
      
      <div class="brand">
        <img src="/logo.svg" class="logo vue" alt="Vue logo" />
        OCWeb.eth
      </div>

      <div class="menu">
        <RouterLink to="/">My OCWebsites</RouterLink>
        <RouterLink to="/mint">Mint OCWebsite</RouterLink>
      </div>

    </div>
    <div class="body">

      <RouterView />

    </div>
  </div>
</template>


<style scoped>
.app {
  display: flex;
  height: 100vh;
}

.sidebar {
  border-right: 1px solid var(--color-divider);
  padding: 2em 1em;
  display: flex;
  flex-direction: column;
  gap: 2em;
}

.brand {
  display: flex;
  align-items: center;
  font-size: 1.5em;
  font-weight: bold;
  gap: 0.5em;
  padding: 0em 0.5em;
}

.logo {
  height: 1.8em;
}

.menu {
  display: flex;
  flex-direction: column;
  gap: 0.5em;
}

.menu > a {
  padding: 0.5em 1em;
  border-radius: 1.5em;
  font-size: 1.3em;
  color: var(--color-bglink);
  text-decoration: none;
}
.menu > a:hover {
  background-color: var(--color-button-hover-border);
}
.menu > a.router-link-active {
  background-color: var(--color-bglink-selected-bg);

}

.body {
  width: 100%;
}
</style>
