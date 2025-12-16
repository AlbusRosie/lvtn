<template>
  <div class="manager-floors-tab">
    <div class="floors-content">
      <!-- Include full FloorList functionality from Admin -->
      <!-- Manager can only see and manage floors from their branch -->
      <FloorList 
        :is-manager-view="true"
        :manager-branch-id="managerBranchId"
        :hide-branch-filter="true"
      />
    </div>
  </div>
</template>
<script setup>
import { defineAsyncComponent, computed } from 'vue';
import AuthService from '@/services/AuthService';

const FloorList = defineAsyncComponent(() => 
  import('@/views/Admin/Floor/FloorList.vue')
);

const managerBranchId = computed(() => {
  const user = AuthService.getUser();
  return user?.branch_id || null;
});
</script>
<style scoped>
.manager-floors-tab {
  background: transparent;
  min-height: calc(100vh - 124px);
  padding: 0;
}

.floors-content {
  width: 100%;
  height: 100%;
}
</style>

