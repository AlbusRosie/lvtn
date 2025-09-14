<script setup>
import { ref } from 'vue';

const props = defineProps({
  searchType: {
    type: String,
    default: 'name'
  }
});

const model = defineModel({
  type: String,
  default: '',
});

const searchTypes = [
  { value: 'name', label: 'Tên' },
  { value: 'phone', label: 'Điện thoại' },
  { value: 'email', label: 'Email' }
];

const selectedType = ref(props.searchType);
</script>

<template>
  <div class="input-group">
    <select
      class="form-select"
      style="max-width: 120px;"
      v-model="selectedType"
    >
      <option v-for="type in searchTypes" :key="type.value" :value="type.value">
        {{ type.label }}
      </option>
    </select>
    <input
      type="text"
      class="form-control px-3"
      :placeholder="`Nhập ${searchTypes.find(t => t.value === selectedType)?.label?.toLowerCase()} cần tìm`"
      v-model="model"
    />
    <button
      class="btn btn-outline-secondary"
      type="button"
      @click="$emit('submit', selectedType)"
    >
      <i class="fas fa-search"></i>
    </button>
  </div>
</template>
