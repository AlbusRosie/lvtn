<script setup>
  defineProps({
    users: { type: Array, default: () => [] },
    selectedIndex: { type: Number, default: -1 },
  });
  const $emit = defineEmits(['update:selectedIndex']);
</script>
<template>
  <ul class="list-group">
    <li
      class="list-group-item px-3"
      v-for="(user, index) in users"
      :class="{ active: index === selectedIndex }"
      :key="user.id"
      @click="$emit('update:selectedIndex', index)"
    >
      {{ user.name }}
    </li>
  </ul>
</template>