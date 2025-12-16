<template>
  <div class="manager-branch-menu-tab">
    <div class="branch-menu-content">
      <!-- Include full BranchMenuManagement functionality from Admin -->
      <!-- Manager can only manage menu for their assigned branch -->
      <BranchMenuManagement 
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

const BranchMenuManagement = defineAsyncComponent(() => 
  import('@/views/Admin/Product/BranchMenuManagement.vue')
);

const managerBranchId = computed(() => {
  const user = AuthService.getUser();
  return user?.branch_id || null;
});
</script>
<style scoped>
.manager-branch-menu-tab {
  background: transparent;
  min-height: calc(100vh - 124px);
  padding: 0;
}

.branch-menu-content {
  width: 100%;
  height: 100%;
}
</style>

