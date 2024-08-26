<script setup>
import { ref, defineProps, defineEmits, computed } from 'vue';
import { useQueryClient, useMutation } from '@tanstack/vue-query'

import { useStaticFrontendPluginClient, useStaticFrontend } from '../../../../../../src/plugins/staticFrontend/tanstack-vue.js';
import Modal from '../../../utils/Modal.vue';
import FilesUploadOperation from '../staticFrontendPluginEditor/FilesUploadOperation.vue';
import TypeBoldIcon from '../../../../icons/TypeBoldIcon.vue';
import TypeItalicIcon from '../../../../icons/TypeItalicIcon.vue';
import ImageIcon from '../../../../icons/ImageIcon.vue';
import TypeH1Icon from '../../../../icons/TypeH1Icon.vue';
import TypeH2Icon from '../../../../icons/TypeH2Icon.vue';
import TypeH3Icon from '../../../../icons/TypeH3Icon.vue';
import ArrowsFullscreenIcon from '../../../../icons/ArrowsFullscreenIcon.vue';
import FullscreenExitIcon from '../../../../icons/FullscreenExitIcon.vue';
import Link45DegIcon from '../../../../icons/Link45DegIcon.vue';
import ListUlIcon from '../../../../icons/ListUlIcon.vue';
import CodeSlashIcon from '../../../../icons/CodeSlashIcon.vue';
import QuoteIcon from '../../../../icons/QuoteIcon.vue';

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
const emit = defineEmits(['enterFullscreen', 'exitFullscreen'])

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
            anchor: range.from + startString.length,
            head: range.to + startString.length
        }
    })
  }

  // Give back the focus to the editor
  props.editor.focus();
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
  
  // Give back the focus to the editor
  props.editor.focus();
}

const toggleBlockquote = () => {
  const state = props.editor.viewState.state;
  const range = state.selection.ranges[0];
  const line = state.doc.lineAt(range.from);
  const textBeforeInLine = line.text.slice(0, range.from - line.from);

  // If the line where the cursor is already start with a blockquote, remove it
  const match = textBeforeInLine.match(/^> /);
  if (match) {
    props.editor.dispatch({
        changes: {
            from: line.from + match.index,
            to: line.from + match.index + 2,
            insert: ''
        },
        selection: {
            anchor: range.from - 2,
            head: range.to - 2
        }
    })
  }
  // Otherwise, add the blockquote
  else {
    props.editor.dispatch({
        changes: {
            from: line.from,
            to: line.from,
            insert: `> `
        },
        selection: {
            anchor: range.from + 2,
            head: range.to + 2
        }
    })
  }

  // Give back the focus to the editor
  props.editor.focus();
}

// Insert a link around the currently selected text
const insertLink = () => {
  const state = props.editor.viewState.state;
  const range = state.selection.ranges[0];
  const cursorPosition = state.selection.main.head;
  const selectedText = state.sliceDoc(range.from, range.to);

  let processingDone = false;
  // If the selected text is a link, remove the link
  const linkMatch = selectedText.match(/^\[([^\]]+)\]\(([^)]+)\)$/);
  if(linkMatch) {
    props.editor.dispatch({
      changes: {
        from: range.from,
        to: range.to,
        insert: linkMatch[1]
      },
      selection: {
        anchor: range.from,
        head: range.from + linkMatch[1].length
    }
    })
    processingDone = true;
  }
  // Otherwise : check if the cursor is inside a link: if so, remove the link
  else {
    const line = state.doc.lineAt(cursorPosition);
    const textBeforeInLine = line.text.slice(0, cursorPosition - line.from);
    const textAfterInLine = line.text.slice(cursorPosition - line.from);

    // Find the first "[" before the cursor
    let startLinkIndex = textBeforeInLine.lastIndexOf('[');
    // Find the first ")" after the cursor
    let endLinkIndex = textAfterInLine.indexOf(')');
    if(startLinkIndex !== -1 && endLinkIndex !== -1) {
      // Extract the text between the "[" and the "]" (including them), and check if it is a link
      const linkText = line.text.slice(startLinkIndex, cursorPosition - line.from + endLinkIndex + 1);
      const linkMatch = linkText.match(/^\[([^\]]*)\]\(([^)]+)\)$/);
      if(linkMatch) {
        props.editor.dispatch({
          changes: {
            from: line.from + startLinkIndex,
            to: line.from + startLinkIndex + linkText.length,
            insert: linkMatch[1]
          },
          selection: {
            anchor: line.from + startLinkIndex,
            head: line.from + startLinkIndex + linkMatch[1].length
          }
        })
        processingDone = true;
      }
    }
  }
  
  // Otherwise, add the link
  if(processingDone === false) {
    const urlPlaceholder = 'url';
    props.editor.dispatch({
        changes: {
          from: range.from,
          to: range.to,
          insert: `[${selectedText}](${urlPlaceholder})`
        },
        selection: {
          anchor: range.from + selectedText.length + 3,
          head: range.from + selectedText.length + 3 + urlPlaceholder.length
        }
    })
    processingDone = true;
  }

  // Give back the focus to the editor
  props.editor.focus();
}

// Insert a UL list entry
const insertListEntry = () => {
  const state = props.editor.viewState.state;
  const range = state.selection.ranges[0];
  const cursorPosition = state.selection.main.head;
  const line = state.doc.lineAt(cursorPosition);
  const textBeforeInLine = line.text.slice(0, cursorPosition - line.from);
  const textAfterInLine = line.text.slice(cursorPosition - line.from);

  // If the cursor is already in a list, remove the list
  const listMatch = textBeforeInLine.match(/^(\s*)- /);
  if(listMatch) {
    props.editor.dispatch({
      changes: {
        from: line.from + listMatch[1].length,
        to: line.from + listMatch[1].length + 2,
        insert: ''
      },
      selection: {
        anchor: cursorPosition - 2,
        head: cursorPosition - 2
      }
    })
  }
  // Otherwise, add the list
  else {
    props.editor.dispatch({
      changes: {
        from: line.from,
        to: line.from,
        insert: `- `
      },
      selection: {
        anchor: cursorPosition + 2,
        head: cursorPosition + 2
      }
    })
  }

  // Give back the focus to the editor
  props.editor.focus();
}

// Insert an image
const insertImage = (filePath, altText) => {
  const state = props.editor.viewState.state;
  const range = state.selection.ranges[0];
  const imageMarkdown = `![${altText}](/${filePath.replace(/ /g, '%20')})`;

  // We insert at range.to
  // Ensure the image is surrounded by new lines
  let before = '';
  const line = state.doc.lineAt(range.to);
  const textBeforeInLine = line.text.slice(0, range.to - line.from);
  if(textBeforeInLine.trim() != '') {
    before = '\n\n';
  }
  else if(line.number > 1) {
    const previousLine = state.doc.line(line.number - 1);
    if(previousLine.text.trim() != '') {
      before = '\n';
    }
  }
  let after = '';
  const textAfterInLine = line.text.slice(range.to - line.from);
  if(textAfterInLine.trim() != '') {
    after = '\n\n';
  }
  else if(line.number < state.doc.lines) {
    const nextLine = state.doc.line(line.number + 1);
    if(nextLine.text.trim() != '') {
      after = '\n';
    }
  }

  // Insert the image
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

  // Give back the focus to the editor
  props.editor.focus();
}

const showImageModal = ref(false)
const imageModalProcessComputedTransactionList = (transactionList) => {
  showImageModalExistingImageSelector.value = false;

  // For each file skipped (because alreayd uploaded), insert the image
  for(const file of transactionList.skippedFiles) {
    insertImage(file.filePath, '');
  }
}

const showImageModalExistingImageSelector = ref(true)
// Get the list of existing images
const existingImages = computed(() => {
  if(staticFrontend.value == null) {
    return [];
  }

  return staticFrontend.value.files.filter(file => file.contentType.startsWith('image/')).sort((a, b) => a.filePath.localeCompare(b.filePath));
})
// The existing image to insert
const selectedExistingImageToInsert = ref(null)

const fullScreen = ref(false)
const toggleFullscreen = () => {
  fullScreen.value = !fullScreen.value;
  if(fullScreen.value) {
    emit('enterFullscreen');
  }
  else {
    emit('exitFullscreen');
  }
}
</script>

<template>
  <div>
    <div class="toolbar">
      <a @click.prevent.stop="toggleSurroundWithStrings('**', '**')" class="white"><TypeBoldIcon /></a>
      <a @click.prevent.stop="toggleSurroundWithStrings('*', '*')" class="white"><TypeItalicIcon /></a>

      <a @click.prevent.stop="toggleHeading(1)" class="white"><TypeH1Icon /></a>
      <a @click.prevent.stop="toggleHeading(2)" class="white"><TypeH2Icon /></a>
      <a @click.prevent.stop="toggleHeading(3)" class="white"><TypeH3Icon /></a>

      <a @click.prevent.stop="insertListEntry()" class="white"><ListUlIcon /></a>

      <a @click.prevent.stop="toggleSurroundWithStrings('\n```\n', '\n```\n')" class="white"><CodeSlashIcon /></a>

      <a @click.prevent.stop="toggleBlockquote()" class="white"><QuoteIcon /></a>
      
      <a @click.prevent.stop="insertLink()" class="white"><Link45DegIcon /></a>

      <a @click.prevent.stop="showImageModal = true" class="white"><ImageIcon /></a>

      <a @click.prevent.stop="toggleFullscreen()" class="white">
        <ArrowsFullscreenIcon v-if="fullScreen == false" />
        <FullscreenExitIcon v-else />
        Preview
      </a>
    </div>

    <Modal 
      v-model:show="showImageModal" 
      title="Inserting image" 
      @close="editor.focus()">
      <div class="image-modal-content">
        <div class="operations">
          <FilesUploadOperation 
            :uploadFolder="'images/'" 
            :contentTypeAccept="'image/*'"
            :contractAddress
            :chainId
            :websiteVersion
            :websiteVersionIndex
            :staticFrontendPluginClient
            @transaction-list-computed="imageModalProcessComputedTransactionList"
            @complete-file-uploaded="(filePath) => insertImage(filePath, '')"
            @all-files-uploaded="showImageModal = false"
            @form-reinitialized="showImageModalExistingImageSelector = true" />
        </div>
        <div class="text-muted" v-if="showImageModalExistingImageSelector">
          - or -
        </div>
        <div v-if="showImageModalExistingImageSelector">
          <select v-model="selectedExistingImageToInsert" class="form-select" @change="insertImage(selectedExistingImageToInsert, ''); selectedExistingImageToInsert = null; showImageModal = false">
            <option :value="null">- Select an existing image -</option>
            <option v-for="image in existingImages" :key="image.filePath" :value="image.filePath">{{ image.filePath }}</option>
          </select>
        </div>
      </div>
    </Modal>
  </div>
</template>

<style scoped>
  /* .mutation-error {
    margin-top: 0.25em;
  }

  .mutation-error span {
    font-size: 0.8em;
  } */

  .toolbar {
    display: flex;
    gap: 0.5em;
  }

  .toolbar > a {
    font-size: 0.9em;
    background-color: var(--color-input-bg);
    /* line-height: 0em; */
    padding: 0.2em 0.4em;
    border-radius: 0.25em;
    display: flex;
    gap: 0.5em;
  }

  .toolbar > a > svg {
    display: block;
    height: 100%;
  }


  .image-modal-content {
    display: flex;
    gap: 1.5em;
    align-items: center;
  }

  .image-modal-content .operations {
    margin-top: 0em;
  }
</style>