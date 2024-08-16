<script setup>
import { ref, defineProps, defineEmits, computed } from 'vue';
import { useQueryClient, useMutation } from '@tanstack/vue-query'

import { useStaticFrontendPluginClient, useStaticFrontend } from '../../../../utils/pluginStaticFrontendQueries.js';

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

const uploadImage = () => {
  const fileInput = document.createElement('input');
  fileInput.type = 'file';
  fileInput.style.display = 'none';
  fileInput.accept = 'image/*';
  fileInput.onchange = async (e) => {
    const file = e.target.files[0];
    const reader = new FileReader();
    reader.onload = async (e) => {
      const data = e.target.result;
      const blob = await fetch(data).then(res => res.blob());
      const arrayBuffer = await new Response(blob).arrayBuffer();
      const uint8Array = new Uint8Array(arrayBuffer);
      prepareAddImageMutate({data: uint8Array, name: file.name, contentType: file.type});
    }
    reader.readAsDataURL(file);
  }
  document.body.appendChild(fileInput);
  fileInput.click();
  document.body.removeChild(fileInput); 
}

// Prepare the addition of image
const addImageTransactions = ref([])
const skippedFilesAdditions = ref([])
const newImageFilePath = ref('')
const { isPending: prepareAddImageIsPending, isError: prepareAddImageIsError, error: prepareAddImageError, isSuccess: prepareAddImageIsSuccess, mutate: prepareAddImageMutate, reset: prepareAddImageReset } = useMutation({
  mutationFn: async (args) => {
    // Reset any previous upload
    addImageTransactionBeingExecutedIndex.value = -1
    addImageTransactionResults.value = []

    // Prepare the filepath
    // Ensure it does not exists yet
    newImageFilePath.value = "images/" + args.name;
    if(staticFrontend.value.files.find(file => file.filePath == newImageFilePath.value)) {
      let i = 1;
      while(staticFrontend.value.files.find(file => file.filePath == newImageFilePath.value + `-${i}`)) {
        i++;
      }
      newImageFilePath.value = newImageFilePath.value + `-${i}`;
    }

    // Prepare the files for upload
    const fileInfos = [{
      filePath: newImageFilePath.value,
      size: args.data.length,
      contentType: args.contentType,
      data: args.data,
    }]
    console.log(fileInfos)
  
    // Prepare the transaction to upload the files
    const transactionsData = await props.staticFrontendPluginClient.prepareAddFilesTransactions(props.websiteVersionIndex, fileInfos);

    return transactionsData;
  },
  onSuccess: (data) => {
    addImageTransactions.value = data.transactions
    skippedFilesAdditions.value = data.skippedFiles
    // Execute right away, don't wait for user confirmation
    executePreparedAddFilesTransactions()
  }
})

// Execute an upload transaction
const addImageTransactionBeingExecutedIndex = ref(-1)
const addImageTransactionResults = ref([])
const { isPending: addImageIsPending, isError: addImageIsError, error: addImageError, isSuccess: addImageIsSuccess, mutate: addImageMutate, reset: addImageReset } = useMutation({
  mutationFn: async ({index, transaction}) => {
    // Store infos about the state of the transaction
    addImageTransactionResults.value.push({status: 'pending'})
    addImageTransactionBeingExecutedIndex.value = index

    const hash = await props.staticFrontendPluginClient.executeTransaction(transaction);
    console.log(hash);

    // Wait for the transaction to be mined
    return await props.staticFrontendPluginClient.waitForTransactionReceipt(hash);
  },
  scope: {
    // This scope will make the mutations run serially
    id: 'addImage'
  },
  onSuccess: async (data) => {
    // Mark the transaction as successful
    addImageTransactionResults.value[addImageTransactionBeingExecutedIndex.value] = {status: 'success'}

    // Refresh the static website
    await queryClient.invalidateQueries({ queryKey: ['StaticFrontendPluginStaticFrontend', props.contractAddress, props.chainId, props.websiteVersionIndex] })

    // Insert the image in the editor, once all transactions have been done
    if(addImageTransactionBeingExecutedIndex.value == addImageTransactions.value.length - 1) {
      const state = props.editor.viewState.state;
      const range = state.selection.ranges[0];
      const imageMarkdown = `![${newImageFilePath.value}](${newImageFilePath.value})`;
      props.editor.dispatch({
          changes: {
              from: range.from,
              to: range.to,
              insert: imageMarkdown
          },
          selection: {
              anchor: range.from,
              head: range.from + imageMarkdown.length
          }
      })
    }
  },
  onError: (error) => {
    // Mark the transaction as failed
    addImageTransactionResults.value[addImageTransactionBeingExecutedIndex.value] = {status: 'error', error}
  }
})
const executePreparedAddFilesTransactions = async () => {
  for(const [index, transaction] of addImageTransactions.value.entries()) {
    addImageMutate({index, transaction})
  }
}
</script>

<template>
  <div>
    <div>
      <button @click="toggleSurroundWithStrings('**', '**')" class="btn btn-primary">Bold</button>

      <button @click="toggleHeading(1)" class="btn btn-primary">Heading 1</button>
      
      <button @click="uploadImage()" class="btn btn-primary">Upload image</button>
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

    <div>
      <div v-if="prepareAddImageIsError" class="mutation-error">
        <span>
          Error preparing the transaction: {{ prepareAddImageError.shortMessage || prepareAddImageError.message }} <a @click.stop.prevent="prepareAddImageReset()">Hide</a>
        </span>
      </div>
      <div v-if="addImageIsError" class="mutation-error">
        <span>
          Error executing the transaction: {{ addImageError.shortMessage || addImageError.message }} <a @click.stop.prevent="addImageReset()">Hide</a>
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
  .mutation-error {
    margin-top: 0.25em;
  }

  .mutation-error span {
    font-size: 0.8em;
  }
</style>