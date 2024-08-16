<script setup>
import { ref, onMounted, watch, shallowRef } from 'vue'
const { default: markdownit } = await import('markdown-it')
// import markdownit from 'markdown-it'
const { basicSetup: codeMirrorBasicSetup, EditorView } = await import("codemirror")
const { markdown: codeMirrorMarkdown } = await import("@codemirror/lang-markdown")
const { EditorState, Compartment: codeMirrorCompartment } = await import("@codemirror/state")
const { oneDark: codeMirrorOneDarkTheme } = await import('@codemirror/theme-one-dark');

import TextEditorToolbarMarkdown from './TextEditorToolbarMarkdown.vue';


const text = defineModel('text')
const props = defineProps({
  contentType: {
    type: String,
    default: "text/plain"
  },
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  pluginInfos: {
    type: Object,
    required: true,
  },
  websiteVersionIndex: {
    type: Number,
    required: true,
  },
  staticFrontendPluginClient: {
    type: Object,
    required: true,
  },
})

// Initialize the markdown engine
const markdownitEngine = markdownit()


const editorDOMElement = ref(null)
const editor = shallowRef(null)

// Editor configuration items
let editorTheme = (isDark) => {
  // return isDark ? codeMirrorOneDarkTheme : EditorView.baseTheme({
  //   "&.cm-focused": {
  //     outline: "none",
  //   },
  // })
  return codeMirrorOneDarkTheme;
}
let editorUpdateListenerExtension = EditorView.updateListener.of((update) => {
  if (update.docChanged) {
    // Update the model
    text.value = editor.value.state.doc.toString()
  }
});
let editorExtensions = () => [
  codeMirrorBasicSetup, 
  codeMirrorMarkdown(),
  EditorView.lineWrapping,
  // Theme, ready to be switched from light to dark
  editorThemeCompartment.of(editorTheme(window.matchMedia('(prefers-color-scheme: dark)').matches)),
  // Theme override for both light and dark
  EditorView.theme({
    '&': { fontSize: "16px", maxHeight: '500px', cursor: "text" },
    '.cm-gutter,.cm-content': { minHeight: '200px' },
    '.cm-scroller': { overflow: 'auto' },
  }),
  // Readonly state, ready to be modified
  editorReadonlyCompartment.of(EditorState.readOnly.of(false)),
  // Update listener: Update the preview
  editorUpdateListenerExtension
]
let editorReadonlyCompartment = new codeMirrorCompartment()
let editorThemeCompartment = new codeMirrorCompartment()

// Initialize the editor
onMounted(() => {
  editor.value = EditorView.findFromDOM(editorDOMElement.value)
  if(editor.value == null) {
    editor.value = new EditorView({
      doc: "",
      extensions: editorExtensions(),
      parent: editorDOMElement.value
    })
    // // Setup light/dark mode switch listener
    // window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', event => {
    //   editor.dispatch({
    //     effects: editorThemeCompartment.reconfigure(
    //       editorTheme(event.matches)
    //     )
    //   });
    // })
  }

  // Set the initial text
  editor.value.setState(EditorState.create({doc: text.value, extensions: editorExtensions()}))

  return () => {
    view.destroy()
  }
})


</script>

<template>
  <div>
    <div class="toolbar" v-if="editor != null && contentType == 'text/markdown'">
      <TextEditorToolbarMarkdown 
        :editor="editor"
        :contractAddress
        :chainId
        :pluginInfos
        :websiteVersionIndex
        :staticFrontendPluginClient />
    </div>
    <div id="editor" ref="editorDOMElement">
      <!-- Markdown editor goes here -->
    </div>
  </div>
</template>

<style scoped>
.cm-editor {
  min-height: 5em;
}
</style>