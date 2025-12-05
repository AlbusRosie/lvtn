<script setup>
import { computed, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import AuthService from '@/services/AuthService';
import BranchService from '@/services/BranchService';
import { ROLE_NAMES } from '@/constants';
const props = defineProps({
  tabs: {
    type: Array,
    default: () => []
  },
  activeTab: {
    type: String,
    default: ''
  }
});
const emit = defineEmits(['tab-change', 'logout']);
const route = useRoute();
const router = useRouter();
const user = AuthService.getUser();
const currentBranch = ref(null);
const branchLoading = ref(false);
const roleTitle = computed(() => {
  if (!user) return 'Employee';
  return ROLE_NAMES[user.role_id] || user.role_name || 'Employee';
});
const branchDisplayName = computed(() => {
  if (!currentBranch.value) return '';
  const name = currentBranch.value.name || '';
  const address = currentBranch.value.address_detail || currentBranch.value.address || '';
  if (address) {
    return `${name} - ${address}`;
  }
  return name;
});
async function loadBranch() {
  branchLoading.value = true;
  try {
    const userData = AuthService.getUser();
    const branchId = userData?.branch_id || null;
    if (!branchId) {
      currentBranch.value = null;
      return;
    }
    try {
      const branchData = await BranchService.getBranchById(branchId);
      if (branchData && (branchData.name || branchData.id)) {
        currentBranch.value = branchData;
        return;
      }
    } catch (apiError) {
      }
    if (userData.branch_name) {
      currentBranch.value = {
        id: branchId,
        name: userData.branch_name,
        address_detail: userData.branch_address || ''
      };
      return;
    }
    try {
      const data = await BranchService.getAllBranches();
      const allBranches = data.branches || data.items || data.data || data || [];
      const foundBranch = allBranches.find(b => b.id === parseInt(branchId));
      if (foundBranch) {
        currentBranch.value = foundBranch;
      }
    } catch (listError) {
      }
  } catch (error) {
    } finally {
    branchLoading.value = false;
  }
}
function getCurrentBranchId() {
  const userData = AuthService.getUser();
  return userData?.branch_id || null;
}
function handleTabClick(tabId) {
  emit('tab-change', tabId);
}
function handleLogout() {
  emit('logout');
}
onMounted(() => {
  loadBranch();
});
</script>
<template>
  <div class="employee-header">
    <!-- Top Row: Title, Branch, User Info -->
    <div class="header-top">
      <div class="header-content">
        <!-- Left Section: Title & Branch -->
        <div class="header-left">
          <div class="title-section">
            <h1 class="page-title">
              <span class="title-text">{{ roleTitle }}</span>
            </h1>
          </div>
          <div class="branch-section">
            <div v-if="!getCurrentBranchId()" class="branch-info warning">
              <i class="fas fa-exclamation-triangle"></i>
              <span>Chưa được phân công chi nhánh</span>
            </div>
            <div v-else-if="branchLoading" class="branch-info loading">
              <i class="fas fa-spinner fa-spin"></i>
              <span>Đang tải thông tin...</span>
            </div>
            <div v-else-if="currentBranch" class="branch-info">
              <i class="fas fa-map-marker-alt"></i>
              <span class="branch-text">{{ branchDisplayName || currentBranch.name || 'Không có thông tin' }}</span>
            </div>
            <div v-else class="branch-info">
              <i class="fas fa-map-marker-alt"></i>
              <span>Không có thông tin</span>
            </div>
          </div>
        </div>
        <!-- Right Section: Actions & User -->
        <div class="header-right">
          <!-- Notification Icons -->
          <div class="action-buttons">
            <button class="action-btn" title="Thông báo">
              <i class="fas fa-bell"></i>
            </button>
            <button class="action-btn" title="Tin nhắn">
              <i class="fas fa-envelope"></i>
            </button>
          </div>
          <!-- User Profile -->
          <div class="user-profile">
            <div class="user-avatar">
              <i class="fas fa-user"></i>
            </div>
            <div class="user-info">
              <div class="user-name">{{ user?.name || user?.username || 'Nhân viên' }}</div>
              <div class="user-role">{{ user?.role_name || roleTitle }}</div>
            </div>
          </div>
          <!-- Logout Button -->
          <button class="action-btn logout-btn" @click="handleLogout" title="Đăng xuất">
            <i class="fas fa-sign-out-alt"></i>
          </button>
        </div>
      </div>
    </div>
    <!-- Bottom Row: Tabs Navigation -->
    <div v-if="tabs.length > 0" class="header-tabs">
      <div class="tabs-container">
        <button 
          v-for="tab in tabs" 
          :key="tab.id"
          :class="['tab-button', { 'active': activeTab === tab.id }]"
          @click="handleTabClick(tab.id)"
        >
          <i :class="tab.icon"></i>
          <span class="tab-label">{{ tab.label }}</span>
        </button>
      </div>
    </div>
  </div>
</template>
<style scoped>
.employee-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background: #FFFFFF;
  z-index: 1000;
  border-bottom: 1px solid #E2E8F0;
}
.header-top {
  height: 72px;
  border-bottom: 1px solid #F1F5F9;
  background: #FFFFFF;
}
.header-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 100%;
  padding: 0 28px;
  max-width: 100%;
}
.header-left {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
  min-width: 0;
}
.title-section {
  display: flex;
  align-items: center;
}
.page-title {
  margin: 0;
  font-size: 22px;
  font-weight: 700;
  color: #1a1a1a;
  letter-spacing: -0.4px;
  line-height: 1.2;
}
.title-text {
  display: inline-block;
}
.branch-section {
  display: flex;
  align-items: center;
}
.branch-info {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #64748B;
  line-height: 1.4;
}
.branch-info i {
  color: #F59E0B;
  font-size: 14px;
  flex-shrink: 0;
}
.branch-text {
  color: #475569;
  font-weight: 500;
  word-break: break-word;
}
.branch-info.warning {
  color: #F59E0B;
}
.branch-info.warning i {
  color: #F59E0B;
}
.branch-info.loading {
  color: #94A3B8;
}
.branch-info.loading i {
  color: #94A3B8;
}
.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-shrink: 0;
}
.action-buttons {
  display: flex;
  gap: 8px;
  align-items: center;
}
.action-btn {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  border: none;
  background: #F8F9FA;
  color: #64748B;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  flex-shrink: 0;
  position: relative;
}
.action-btn:hover {
  background: #FEF7ED;
  color: #FF8C42;
}
.action-btn.logout-btn:hover {
  background: #FEE2E2;
  color: #EF4444;
}
.user-profile {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 6px 14px;
  border-radius: 12px;
  transition: all 0.2s ease;
  cursor: pointer;
  min-width: 0;
}
.user-profile:hover {
  background: #F8F9FA;
}
.user-avatar {
  width: 42px;
  height: 42px;
  border-radius: 8px;
  background: #FFF7ED;
  color: #F59E0B;
  border: 1px solid #FED7AA;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}
.user-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}
.user-name {
  font-size: 14px;
  font-weight: 600;
  color: #1a1a1a;
  line-height: 1.3;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 150px;
}
.user-role {
  font-size: 12px;
  color: #94A3B8;
  font-weight: 500;
  line-height: 1.2;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 150px;
}
.header-tabs {
  height: 56px;
  background: #FFFFFF;
  border-top: 1px solid #F1F5F9;
  overflow-x: auto;
  overflow-y: hidden;
}
.header-tabs::-webkit-scrollbar {
  height: 4px;
}
.header-tabs::-webkit-scrollbar-track {
  background: transparent;
}
.header-tabs::-webkit-scrollbar-thumb {
  background: #CBD5E1;
  border-radius: 2px;
}
.header-tabs::-webkit-scrollbar-thumb:hover {
  background: #94A3B8;
}
.tabs-container {
  display: flex;
  align-items: center;
  height: 100%;
  padding: 0 28px;
  gap: 4px;
}
.tab-button {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 20px;
  border: none;
  background: transparent;
  color: #64748B;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.2s ease;
  position: relative;
  white-space: nowrap;
  letter-spacing: 0.1px;
  height: 40px;
  margin: 0 2px;
}
.tab-button i {
  font-size: 15px;
  transition: color 0.2s ease;
}
.tab-label {
  font-weight: 600;
}
.tab-button:hover {
  color: #F59E0B;
  background: #FFF7ED;
}
.tab-button.active {
  color: #F59E0B;
  background: #FFF7ED;
}
.tab-button.active::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 40px;
  height: 2px;
  background: #F59E0B;
  border-radius: 2px 2px 0 0;
}
.tab-button.active i {
  color: #F59E0B;
}
@media (max-width: 1024px) {
  .header-content {
    padding: 0 20px;
  }
  .page-title {
    font-size: 20px;
  }
  .branch-info {
    font-size: 12px;
  }
  .tabs-container {
    padding: 0 20px;
  }
}
@media (max-width: 768px) {
  .header-top {
    height: auto;
    min-height: 72px;
    padding: 12px 0;
  }
  .header-content {
    flex-wrap: wrap;
    gap: 12px;
    padding: 0 16px;
  }
  .header-left {
    width: 100%;
    order: 1;
  }
  .header-right {
    width: 100%;
    order: 2;
    justify-content: space-between;
  }
  .page-title {
    font-size: 18px;
  }
  .branch-info {
    font-size: 12px;
  }
  .action-btn {
    width: 38px;
    height: 38px;
    font-size: 15px;
  }
  .user-avatar {
    width: 38px;
    height: 38px;
    font-size: 16px;
  }
  .user-info {
    display: none;
  }
  .header-tabs {
    height: 52px;
  }
  .tabs-container {
    padding: 0 16px;
    gap: 2px;
  }
  .tab-button {
    padding: 10px 16px;
    font-size: 13px;
    height: 40px;
    gap: 8px;
  }
  .tab-button i {
    font-size: 14px;
  }
}
@media (max-width: 480px) {
  .header-content {
    padding: 0 12px;
  }
  .page-title {
    font-size: 16px;
  }
  .branch-info {
    font-size: 11px;
  }
  .action-buttons {
    gap: 6px;
  }
  .action-btn {
    width: 36px;
    height: 36px;
    font-size: 14px;
  }
  .tabs-container {
    padding: 0 12px;
  }
  .tab-button {
    padding: 8px 12px;
    font-size: 12px;
  }
  .tab-label {
    display: none;
  }
  .tab-button i {
    font-size: 16px;
  }
}
</style>
