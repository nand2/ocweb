<script setup>
import WalletConnect from './components/WalletConnect.vue'
import LayourTextWindowReverseIcon from './icons/LayoutTextWindowReverseIcon.vue'
import MagicIcon from './icons/MagicIcon.vue';
</script>


<template>
  <div class="app">
    <div class="sidebar">
      
      <div class="brand">
        <img src="/logo.svg" class="logo" alt="Vue logo" />
        <span class="logo-text">
          OCWeb.eth
        </span>
      </div>

      <div class="menu">
        <RouterLink to="/"><span class="menu-icon"><LayourTextWindowReverseIcon /></span><span class="menu-text">My OCWebsites</span></RouterLink>
        <RouterLink to="/mint"><span class="menu-icon"><MagicIcon /></span><span class="menu-text">Mint an OCWebsite</span></RouterLink>
      </div>

    </div>
    <div class="body">

      <div class="body-top-menu">
        <WalletConnect />
      </div>

      <RouterView />

    </div>
  </div>
</template>


<style scoped>
.app {
  display: flex;
  min-height: 100vh;
}

@media (max-width: 560px) {
  .app {
    flex-direction: column;
  }
}

.sidebar {
  border-right: 1px solid var(--color-divider);
  padding: 1.5em 1em;
  display: flex;
  flex-direction: column;
  gap: 2em;
}

@media (max-width: 560px) {
  .sidebar {
    border-right: none;
    border-bottom: 1px solid var(--color-divider);
    padding: 1em 1.5em;
    flex-direction: row;
  }
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
  height: 1.5em;
}

@media (max-width: 1080px) {
  .logo-text {
    display: none;
  }
}

.menu {
  display: flex;
  flex-direction: column;
  gap: 0.5em;
}

@media (max-width: 560px) {
  .menu {
    flex-direction: row;
  }
}

.menu > a {
  padding: 0.5em 1em;
  border-radius: 1.5em;
  font-size: 1.3em;
  color: var(--color-bglink);
  text-decoration: none;
  white-space: nowrap;
  display: flex;
  gap: 0.75em;
}
.menu > a:hover {
  background-color: var(--color-button-hover-border);
}
.menu > a.router-link-active {
  background-color: var(--color-bglink-selected-bg);

}

.menu > a .menu-icon svg {
  scale: 1.5;
}

@media (max-width: 1080px) {
  .menu > a .menu-text {
    display: none;
  }
}

.body-top-menu {
  padding: 1em 1.5em;
  border-bottom: 1px solid var(--color-divider);
  display: flex;
  justify-content: flex-end;
}

.body {
  width: 100%;
}
</style>
