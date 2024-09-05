import { reactive } from 'vue'

// Load the default values from localStorage
let devMode = false;
// In current EVM Browser, localStorage is not available
try {
  devMode = localStorage.getItem('ocWebAdminPlugin-devMode') === 'true'
} catch (e) {
  console.debug('Failed to read devMode setting from localStorage, using the default value. Reason:', e)
}

export const store = reactive({
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
  }
})