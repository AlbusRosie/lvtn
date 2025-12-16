<template>
  <div class="manager-tables-tab">
    <div class="tables-content">
      <!-- Include full TableList functionality from Admin -->
      <!-- Manager can only see tables from their branch -->
      <TableList 
        v-if="managerBranchId"
        :is-manager-view="true"
        :manager-branch-id="managerBranchId"
        :hide-branch-filter="true"
      />
      <div v-else class="loading-state">
        <i class="fas fa-spinner fa-spin"></i>
        <p>Loading...</p>
      </div>
    </div>
  </div>
</template>
<script setup>
import { defineAsyncComponent, computed } from 'vue';
import AuthService from '@/services/AuthService';
const TableList = defineAsyncComponent(() => 
  import('@/views/Admin/Table/TableList.vue')
);
const managerBranchId = computed(() => {
  const user = AuthService.getUser();
  const branchId = user?.branch_id || null;
  console.log('TablesTab - managerBranchId computed:', branchId, 'user:', user);
  return branchId;
});
</script>
<style scoped>
.manager-tables-tab {
  background: transparent;
  min-height: calc(100vh - 124px);
  padding: 0;
}
.tables-content {
  width: 100%;
  height: 100%;
}
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  gap: 16px;
}
.loading-state i {
  font-size: 32px;
  color: #F59E0B;
}
.loading-state p {
  color: #6B7280;
  font-size: 14px;
  margin: 0;
}
</style>
