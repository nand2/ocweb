<script setup>
import { ref, onMounted, watch, shallowRef } from 'vue'
const { default: markdownit } = await import('markdown-it')
// import markdownit from 'markdown-it'
const { basicSetup: codeMirrorBasicSetup, EditorView } = await import("codemirror")
const { keymap } = await import("@codemirror/view");
const { defaultKeymap } = await import("@codemirror/commands");
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
  websiteVersion: {
    type: Object,
    required: true
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
let editorThemeOverride = () => {
  let themeOverride = {}
  if(fullscreen.value) {
    themeOverride = {
      '&': { maxHeight: 'none' },
    }
  }
  return EditorView.theme(themeOverride)
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
  // Dynamic theme overrides (need to be before the static theme overrides)
  editorThemeOverrideCompartment.of(editorThemeOverride()),
  // Theme override for both light and dark
  EditorView.theme({
    '&': { fontSize: "16px", maxHeight: '500px', cursor: "text" },
    "&.cm-focused": { outline: "none",},
    '.cm-gutter,.cm-content': { minHeight: '200px' },
    '.cm-scroller': { overflow: 'auto' },
  }),
  // Readonly state, ready to be modified
  editorReadonlyCompartment.of(EditorState.readOnly.of(false)),
  // Update listener: Update the preview
  editorUpdateListenerExtension,
  // Keymap
  editorKeymapCompartment.of(keymap.of(defaultKeymap)),
]
let editorThemeOverrideCompartment = new codeMirrorCompartment()
let editorReadonlyCompartment = new codeMirrorCompartment()
let editorThemeCompartment = new codeMirrorCompartment()
let editorKeymapCompartment = new codeMirrorCompartment()

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

const setFullscreen = (value) => {
  fullscreen.value = value

  // Reload the theme override
  editor.value.dispatch({
    effects: editorThemeOverrideCompartment.reconfigure(
      editorThemeOverride()
    )
  });
}

const fullscreen = ref(false)
</script>

<template>
  <div class="editor-and-preview" :class="{'preview-active': fullscreen}">
    <div class="editor-and-preview-inner">
      <div class="editor-with-toolbar">
        <div class="toolbar" v-if="editor != null && contentType == 'text/markdown'">
          <TextEditorToolbarMarkdown 
            :editor="editor"
            :editorKeymapCompartment
            :contractAddress
            :chainId
            :pluginInfos
            :websiteVersion
            :websiteVersionIndex
            :staticFrontendPluginClient
            @enter-fullscreen="setFullscreen(true)"
            @exit-fullscreen="setFullscreen(false)" />
        </div>
        <div id="editor" ref="editorDOMElement">
          <!-- Markdown editor goes here -->
        </div>
      </div>
      <div class="preview" v-if="contentType == 'text/markdown'" v-html="markdownitEngine.render(text)">
      </div>
    </div>
  </div>
</template>

<style scoped>
.cm-editor {
  min-height: 5em;
}

.editor-and-preview {
}

.editor-with-toolbar {
  display: flex;
  flex-direction: column;
  gap: 0.25em;
}

#editor {
  overflow-y: auto;
}

.preview {
  display: none;
}

.editor-and-preview.preview-active {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;  
  z-index: 1;
}

.editor-and-preview.preview-active .editor-and-preview-inner {
  background-color: var(--color-root-bg);
  /* border-radius: 5px; */
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
  width: 100%;
  max-height: calc(100% - 2em);
  z-index: 1;
  padding: 1.5em 1em;
  display: flex;
  gap: 2em;
}
@media (max-width: 768px) {
  .editor-and-preview.preview-active .editor-and-preview-inner {
    flex-direction: column;
    gap: 1em;
  }
}

.editor-and-preview.preview-active .editor-and-preview-inner .editor-with-toolbar {
  flex: 0 0 50%;
}

.editor-and-preview.preview-active .editor-and-preview-inner .preview {
  display: block;
  flex: 1 1 50%;
  overflow-y: auto;
}

.preview {
  overflow-wrap: break-word;
}

.preview :deep(img) {
  max-width: 100%;
  height: auto;
}
@media (max-width: 768px) {
  .preview :deep(img) {
    width: 100%;
  }
}

.preview :deep(blockquote) {
  color: var(--color-text-muted);
  border-left: .25em solid var(--color-divider);
  padding: 0 1em;
  margin: 0;
}

.preview :deep(code) {
  background-color: var(--color-light-bg);
  padding: .2em .4em;
  border-radius: 6px;
}

.preview :deep(pre) {
  padding: 16px;
  background-color: var(--color-light-bg);
  overflow-y: auto;
}

.preview :deep(pre) table {
  border-spacing: 0;
  border-collapse: collapse;
}

.preview :deep(table) tr:nth-child(2n) {
  background-color: var(--color-light-bg);
}

.preview :deep(table) th, 
.preview :deep(table) td {
  padding: 6px 13px;
  border: 1px solid var(--color-divider);
}
</style>