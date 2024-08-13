<script setup>
import { ref, onMounted } from 'vue'
const { default: markdownit } = await import('markdown-it')
// import markdownit from 'markdown-it'
const { basicSetup: codeMirrorBasicSetup, EditorView } = await import("codemirror")
const { markdown: codeMirrorMarkdown } = await import("@codemirror/lang-markdown")
const { EditorState, Compartment: codeMirrorCompartment } = await import("@codemirror/state")
const { oneDark: codeMirrorOneDarkTheme } = await import('@codemirror/theme-one-dark');

const text = defineModel('text')

// Initialize the markdown editor
const editor = ref(null)
onMounted(() => {
  // Initialize the markdown engine
  const markdownitEngine = markdownit()
  // Initialize the markdown editor
  let markdownEditorTheme = (isDark) => {
    // return isDark ? codeMirrorOneDarkTheme : EditorView.baseTheme({
    //   "&.cm-focused": {
    //     outline: "none",
    //   },
    // })
    return codeMirrorOneDarkTheme;
  }
  let markdownEditorUpdateListenerExtension = EditorView.updateListener.of((update) => {
    if (update.docChanged) {
      // Update the model
      text.value = markdownEditor.state.doc.toString()
    }
  });
  let markdownEditorExtensions = () => [
    codeMirrorBasicSetup, 
    codeMirrorMarkdown(),
    EditorView.lineWrapping,
    // Theme, ready to be switched from light to dark
    markdownEditorThemeCompartment.of(markdownEditorTheme(window.matchMedia('(prefers-color-scheme: dark)').matches)),
    // Theme override for both light and dark
    EditorView.theme({
      "&": {
        fontSize: "16px",
      },
    }),
    // Readonly state, ready to be modified
    markdownEditorReadonlyCompartment.of(EditorState.readOnly.of(false)),
    // Update listener: Update the preview
    markdownEditorUpdateListenerExtension
  ]
  let markdownEditorReadonlyCompartment = new codeMirrorCompartment()
  let markdownEditorThemeCompartment = new codeMirrorCompartment()

  const markdownEditor = new EditorView({
    doc: text.value,
    extensions: markdownEditorExtensions(),
    parent: editor.value
  })

  // // Setup light/dark mode switch listener
  // window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', event => {
  //   markdownEditor.dispatch({
  //     effects: markdownEditorThemeCompartment.reconfigure(
  //       markdownEditorTheme(event.matches)
  //     )
  //   });
  // })

  return () => {
    view.destroy()
  }
})





</script>

<template>
  <div>
    <div id="editor" ref="editor">
      <!-- Markdown editor goes here -->
    </div>
  </div>
</template>

<style scoped>

</style>