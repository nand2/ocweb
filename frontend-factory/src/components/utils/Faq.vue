<script setup>
import { ref, defineProps } from 'vue';

const props = defineProps({
  entries: {
    type: Array,
    required: true,
  },
});


const showAnswer = ref(Array(props.entries.length).fill(false));
const toggleAnswer = (id) => {
  console.log('toggleAnswer', id);
  showAnswer.value[id] = !showAnswer.value[id]
};
</script>

<template>
  <div class="faq">
    <div class="faq-entry" v-for="(entry, index) in entries" :key="index">
      <a class="faq-entry-question white" @click.prevent.stop="toggleAnswer(index)" v-html="entry.question">
      </a>
      <div class="faq-entry-answer" v-show="showAnswer[index]" v-html="entry.answer">
      </div>
    </div>
  </div>
</template>

<style scoped>
.faq {
  display: flex;
  flex-direction: column;
}

.faq-entry {

}

.faq-entry-question {
  display: block;
  padding: 1em 0em;
  font-weight: bold;
  border-bottom: 1px solid var(--color-divider-secondary);
}

.faq-entry-answer {
  padding-top: 1em;
  padding-bottom: 0.5em;
}

</style>