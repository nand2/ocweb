import { reactive } from 'vue'

// Load the default values from localStorage
let devMode = false;
let showWebsiteVersionsSection = false;
let hideWelcomeTab = true;
// In current EVM Browser, localStorage is not available
try {
  devMode = localStorage.getItem('ocWebAdminPlugin-devMode') === 'true'
  showWebsiteVersionsSection = localStorage.getItem('ocWebAdminPlugin-showWebsiteVersionsSection') === 'true'
  hideWelcomeTab = localStorage.getItem('ocWebAdminPlugin-hideWelcomeTab') === 'true'
} catch (e) {
  console.debug('Failed to read devMode setting from localStorage, using the default value. Reason:', e)
}

export const store = reactive({
  // Dev mode: Show more technical settings and details
  devMode: devMode,
  setDevMode(value) {
    this.devMode = value
    // Save it to localStorage
    try {
      localStorage.setItem('ocWebAdminPlugin-devMode', value)
    }
    catch (e) {
      console.debug('Failed to save devMode setting to localStorage. Reason:', e)
    }
  },

  // Show the website version section
  showWebsiteVersionsSection: showWebsiteVersionsSection,
  setShowWebsiteVersionsSection(value) {
    this.showWebsiteVersionsSection = value
    // Save it to localStorage
    try {
      localStorage.setItem('ocWebAdminPlugin-showWebsiteVersionsSection', value)
    }
    catch (e) {
      console.debug('Failed to save showWebsiteVersionsSection setting to localStorage. Reason:', e)
    }
  },

  // Hide the welcome tab
  hideWelcomeTab: hideWelcomeTab,
  setHideWelcomeTab(value) {
    this.hideWelcomeTab = value
    // Save it to localStorage
    try {
      localStorage.setItem('ocWebAdminPlugin-hideWelcomeTab', value)
    }
    catch (e) {
      console.debug('Failed to save hideWelcomeTab setting to localStorage. Reason:', e)
    }
  }
})