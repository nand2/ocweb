<script setup>
import { ref, defineProps, defineEmits, computed } from 'vue';
import { useQueryClient, useMutation } from '@tanstack/vue-query'

import { useStaticFrontendPluginClient, useStaticFrontend } from '../../../../utils/pluginStaticFrontendQueries.js';
import Modal from '../../../utils/Modal.vue';
import FilesUploadOperation from '../staticFrontendPluginEditor/FilesUploadOperation.vue';

const props = defineProps({
  editor: {
    type: Object,
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

const queryClient = useQueryClient()

// Fetch the static frontend
const { data: staticFrontend, isLoading: staticFrontendLoading, isFetching: staticFrontendFetching, isError: staticFrontendIsError, error: staticFrontendError, isSuccess: staticFrontendLoaded } = useStaticFrontend(queryClient, props.contractAddress, props.chainId, props.pluginInfos.plugin, computed(() => props.websiteVersionIndex))



const toggleSurroundWithStrings = (startString, endString) => {
  const state = props.editor.viewState.state;
  const range = state.selection.ranges[0];

  // If the selection is already surrounded by the start and end strings, remove them
  if (state.sliceDoc(range.from - startString.length, range.from) === startString && state.sliceDoc(range.to, range.to + endString.length) === endString) {
      props.editor.dispatch({
          changes: {
              from: range.from - startString.length,
              to: range.to + endString.length,
              insert: `${state.sliceDoc(range.from, range.to)}`
          },
          selection: {
              anchor: range.from - startString.length,
              head: range.to - endString.length
          }
      })
  }
  // If the selection contains already the start and end strings, remove them
  else if (state.sliceDoc(range.from, range.from + startString.length) === startString && state.sliceDoc(range.to - endString.length, range.to) === endString) {
    props.editor.dispatch({
        changes: {
            from: range.from,
            to: range.to,
            insert: `${state.sliceDoc(range.from + startString.length, range.to - endString.length)}`
        },
        selection: {
            anchor: range.from,
            head: range.to - startString.length - endString.length
        }
    })
  }
  // Otherwise add them
  else {
    props.editor.dispatch({
        changes: {
            from: range.from,
            to: range.to,
            insert: `${startString}${state.sliceDoc(range.from, range.to)}${endString}`
        },
        selection: {
            anchor: range.from,
            head: range.to + startString.length + endString.length
        }
    })
  }
}

const toggleHeading = (level) => {
  const state = props.editor.viewState.state;
  const range = state.selection.ranges[0];

  // If the line where the cursor is already start with a heading (whatever level), remove it
  const line = state.doc.lineAt(range.from);
  const match = line.text.match(/^#+ /);
  let removedHeadingLevel = 0;
  if (match) {
    props.editor.dispatch({
        changes: {
            from: line.from,
            to: line.from + match[0].length,
            insert: ''
        },
        selection: {
            anchor: range.from - match[0].length,
            head: range.to - match[0].length
        }
    })
    removedHeadingLevel = match[0].length - 1;
  }
  // If no heading removed, or the heading removed was of a different level, add the new heading
  if (removedHeadingLevel !== level) {
    props.editor.dispatch({
        changes: {
            from: line.from,
            to: line.from,
            insert: `${'#'.repeat(level)} `
        },
        selection: {
            anchor: range.from - (removedHeadingLevel > 0 ? removedHeadingLevel + 1 : 0) + level + 1,
            head: range.to - (removedHeadingLevel > 0 ? removedHeadingLevel + 1 : 0) + level + 1
        }
    })
  }
  
}

// Insert an image
const insertImage = (filePath, altText) => {
  const state = props.editor.viewState.state;
  const range = state.selection.ranges[0];
  const imageMarkdown = `![${altText}](${filePath})`;
  // Ensure that the image is inserted on a line on its own
  const before = state.doc.lineAt(range.to).text === '' ? '' : '\n';
  const after = state.doc.lineAt(range.to).text === '' ? '' : '\n';

  const imageMarkdownWithNewLines = `${before}${imageMarkdown}${after}`;
  props.editor.dispatch({
      changes: {
          from: range.to,
          to: range.to,
          insert: imageMarkdownWithNewLines
      },
      selection: {
          anchor: range.to + before.length,
          head: range.to  + before.length + imageMarkdown.length
      }
  })
}

const showImageModal = ref(false)
const showImageModalExistingImageSelector = ref(true)

// Get the list of existing images
const images = computed(() => {
  if(staticFrontend.value == null) {
    return [];
  }

  return staticFrontend.value.files.filter(file => file.contentType.startsWith('image/')).sort((a, b) => a.filePath.localeCompare(b.filePath));
})
// The existing image to insert
const selectedExistingImageToInsert = ref(null)
</script>

<template>
  <div>
    <div>
      <button @click="toggleSurroundWithStrings('**', '**')" class="btn btn-primary">Bold</button>

      <button @click="toggleHeading(1)" class="btn btn-primary">Heading 1</button>
      
      <button @click="showImageModal = true" class="btn btn-primary">Insert image</button>
      <Modal 
        v-model:show="showImageModal" 
        title="Inserting image" 
        @close="">
        <div class="image-modal-content">
          <div class="operations">
            <FilesUploadOperation 
              :uploadFolder="'images/'" 
              :contentTypeAccept="'image/*'"
              :contractAddress
              :chainId
              :websiteVersionIndex
              :staticFrontendPluginClient
              @transaction-list-computed="showImageModalExistingImageSelector = false"
              @complete-file-added="(filePath) => insertImage(filePath, '')"
              @all-files-added="showImageModal = false"
              @form-reinitialized="showImageModalExistingImageSelector = true" />
          </div>
          <div class="text-muted" v-if="showImageModalExistingImageSelector">
            - or -
          </div>
          <div v-if="showImageModalExistingImageSelector">
            <select v-model="selectedExistingImageToInsert" class="form-select" @change="insertImage(selectedExistingImageToInsert, ''); selectedExistingImageToInsert = null; showImageModal = false">
              <option :value="null">- Select an existing image -</option>
              <option v-for="image in images" :key="image.filePath" :value="image.filePath">{{ image.filePath }}</option>
            </select>
          </div>
        </div>
      </Modal>

      <!-- <button @click="editor.toggleItalic()" class="btn btn-primary">Italic</button>
      <button @click="editor.toggleUnderline()" class="btn btn-primary">Underline</button>
      <button @click="editor.toggleStrikethrough()" class="btn btn-primary">Strikethrough</button>
      <button @click="editor.toggleCode()" class="btn btn-primary">Code</button>
      <button @click="editor.toggleBlockquote()" class="btn btn-primary">Blockquote</button>
      <button @click="editor.toggleUnorderedList()" class="btn btn-primary">Unordered List</button>
      <button @click="editor.toggleOrderedList()" class="btn btn-primary">Ordered List</button>
      <button @click="editor.toggleHeading(1)" class="btn btn-primary">Heading 1</button>
      <button @click="editor.toggleHeading(2)" class="btn btn-primary">Heading 2</button>
      <button @click="editor.toggleHeading(3)" class="btn btn-primary">Heading 3</button>
      <button @click="editor.toggleHeading(4)" class="btn btn-primary">Heading 4</button>
      <button @click="editor.toggleHeading(5)" class="btn btn-primary">Heading 5</button>
      <button @click="editor.toggleHeading(6)" class="btn btn-primary">Heading 6</button>
      <button @click="editor.toggleLink()" class="btn btn-primary">Link</button>
      <button @click="editor.toggleImage()" class="btn btn-primary">Image</button>
      <button @click="editor.toggleTable()" class="btn btn-primary">Table</button>
      <button @click="editor.toggleHorizontalRule()" class="btn btn-primary">Horizontal Rule</button>
      <button @click="editor.toggleCodeBlock()" class="btn btn-primary">Code Block</button>
      <button @click="editor.toggleMath()" class="btn btn-primary">Math</button>
      <button @click="editor.toggleHtml()" class="btn btn-primary">HTML</button>
      <button @click="editor.toggleMarkdown()" class="btn btn-primary">Markdown</button> -->
    </div>

  </div>
</template>

<style scoped>
  /* .mutation-error {
    margin-top: 0.25em;
  }

  .mutation-error span {
    font-size: 0.8em;
  } */


  .image-modal-content {
    display: flex;
    gap: 1.5em;
    align-items: center;
  }

  .image-modal-content .operations {
    margin-top: 0em;
  }
</style>