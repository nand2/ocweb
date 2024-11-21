# Plugin: Developing an admin interface for the OCWeb `Admin interface` plugin

This should be read in the context of the [plugins development documentation](./plugins.md).

Developing an admin interface for the OCWeb `Admin interface` plugin is quite technical, and a bit hackish. Examples will be provided to guide you.

The OCWeb `Admin interface` plugin use Vue 3, Tanstack Vue, Wagmi and Viem, which will be made available to the UMD module. Your admin panel will thus be a Vue 3 component.

When making your admin panel :
- The UMD library name should be : `<pluginName>AdminPanels`, with `<pluginName>` being the `Infos.name` field you declare on your plugin.
- The export of your library should be an object 
```
export { 
  AdminPanel as Panel<AdminPanelIndex>,
  ...
}
```
With `<AdminPanelIndex>` being the index of the admin panel in the `Infos.adminPanels` array. For example, for a single admin panel, it should be `AdminPanel as Panel0`.

## Example: "Theme About me" plugin

The ["Theme About me" plugin](https://github.com/nand2/ocweb-theme-about-me) expose a panel for the OCWeb `Admin interface` plugin.

- Its [plugin solidity contract](https://github.com/nand2/ocweb-theme-about-me/blob/master/src/ThemeAboutMePlugin.sol) declare the admin panel in the `infos()` method.
- Its [vite.config.js](https://github.com/nand2/ocweb-theme-about-me/blob/master/admin/vite.config.js) declare the UMD module, its name following the `<pluginName>AdminPanels` format.
- Its [library.js](https://github.com/nand2/ocweb-theme-about-me/blob/master/admin/src/library.js) export the Vue component.
- Its [AdminPanel.vue](https://github.com/nand2/ocweb-theme-about-me/blob/master/admin/src/components/AdminPanel.vue) is the Vue component being exported.


**How to develop and test** 

- Install [OCWeb](https://github.com/nand2/ocweb) locally.
- Run the dev version of the OCWeb admin interface (via `npm run dev-factory`). Go to `http://localhost:5173/`.
- Edit [SettingsTab.vue](https://github.com/nand2/ocweb/blob/master/frontend-factory/src/components/websiteEditor/versionableWebsiteEditor/SettingsTab.vue), import your admin panel from outside the OCWeb folder (e.g. `import AdminPanel from '../../../../../../ocweb-theme-about-me/admin/src/components/AdminPanel.vue';`), and insert it into the page with:
```
<AdminPanel
      v-if="websiteVersionPluginsLoaded"
      :contractAddress 
      :chainId 
      :websiteVersion
      :websiteVersionIndex
      :websiteClient
      :pluginsInfos="websiteVersionPlugins"
      :pluginInfos="websiteVersionPlugins.find(plugin => plugin.infos.name == '<yourPluginName>')" />
```
with `<yourPluginName>` being your `Infos.name` field you declare on your plugin.

You can now edit your Vue admin panel component live. 