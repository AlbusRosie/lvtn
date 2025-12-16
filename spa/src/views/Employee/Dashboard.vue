<script setup>
import { ref, computed, onMounted, onBeforeUnmount, shallowRef, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import AuthService from '@/services/AuthService';
import BranchService from '@/services/BranchService';
import UserService from '@/services/UserService';
import SocketService from '@/services/SocketService';
import { USER_ROLES, ROLE_NAMES } from '@/constants';
import { useToast } from 'vue-toastification';
import EmployeeHeader from '@/components/Employee/EmployeeHeader.vue';
const router = useRouter();
const route = useRoute();
const toast = useToast();
const user = computed(() => AuthService.getUser());
const currentBranch = ref(null);
const branchLoading = ref(false);
const activeTab = ref('');
const currentComponent = shallowRef(null);
const roleTabs = {
  [USER_ROLES.CASHIER]: [
    { id: 'create-order', label: 'Create Order', icon: 'fas fa-plus-circle', component: () => import('@/views/Employee/Cashier/CreateOrder.vue') },
    { id: 'orders', label: 'Orders', icon: 'fas fa-shopping-cart', component: () => import('@/views/Employee/Cashier/OrdersTab.vue') }
  ],
  [USER_ROLES.KITCHEN_STAFF]: [
    { id: 'kitchen', label: 'Kitchen', icon: 'fas fa-utensils', component: () => import('@/views/Employee/Kitchen/Dashboard.vue') }
  ],
  [USER_ROLES.MANAGER]: [
    { id: 'reports', label: 'Reports', icon: 'fas fa-chart-line', component: () => import('@/views/Employee/Manager/ReportsTab.vue') },
    { id: 'orders', label: 'Orders', icon: 'fas fa-shopping-cart', component: () => import('@/views/Employee/Manager/OrdersTab.vue') },
    { id: 'delivery-assignment', label: 'Delivery Assignment', icon: 'fas fa-truck', component: () => import('@/views/Employee/Manager/DeliveryAssignmentTab.vue') },
    { id: 'reservations', label: 'Reservations', icon: 'fas fa-calendar-check', component: () => import('@/views/Employee/Manager/ReservationsTab.vue') },
    { id: 'branch-menu', label: 'Branch Menu', icon: 'fas fa-utensils', component: () => import('@/views/Employee/Manager/BranchMenuTab.vue') },
    { id: 'tables', label: 'Tables', icon: 'fas fa-table', component: () => import('@/views/Employee/Manager/TablesTab.vue') },
    { id: 'floors', label: 'Floors', icon: 'fas fa-layer-group', component: () => import('@/views/Employee/Manager/FloorsTab.vue') },
    { id: 'staff', label: 'Staff', icon: 'fas fa-users', component: () => import('@/views/Employee/Manager/StaffTab.vue') }
  ],
  [USER_ROLES.STAFF]: [
    { id: 'floor', label: 'Nhân viên sàn', icon: 'fas fa-user-tie', component: () => import('@/views/Employee/Staff/FloorTab.vue') }
  ],
  [USER_ROLES.DELIVERY_STAFF]: [
    { id: 'delivery', label: 'Giao hàng', icon: 'fas fa-truck', component: () => import('@/views/Employee/Delivery/DeliveryTab.vue') }
  ]
};
const tabs = computed(() => {
  if (!user.value) return [];
  return roleTabs[user.value.role_id] || [];
});
const roleTitle = computed(() => {
  if (!user.value) return '';
  return ROLE_NAMES[user.value.role_id] || 'Employee';
});
const roleIcon = computed(() => {
  if (!user.value) return 'fas fa-user-tie';
  const icons = {
    [USER_ROLES.CASHIER]: 'fas fa-cash-register',
    [USER_ROLES.KITCHEN_STAFF]: 'fas fa-utensils',
    [USER_ROLES.MANAGER]: 'fas fa-chart-line',
    [USER_ROLES.STAFF]: 'fas fa-user-tie',
    [USER_ROLES.DELIVERY_STAFF]: 'fas fa-truck'
  };
  return icons[user.value.role_id] || 'fas fa-user-tie';
});
function getCurrentBranchId() {
  const userData = AuthService.getUser();
  return userData?.branch_id || null;
}
async function loadBranch() {
  branchLoading.value = true;
  try {
    const userData = AuthService.getUser();
    const branchId = getCurrentBranchId();
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
        } else {
        }
    } catch (listError) {
      }
  } catch (error) {
    } finally {
    branchLoading.value = false;
  }
}
async function refreshUserData() {
  try {
    const userData = AuthService.getUser();
    if (!userData || !userData.id) return;
    const freshUserData = await UserService.fetchUser(userData.id);
    let updatedUser = null;
    if (freshUserData && (freshUserData.id || freshUserData.username)) {
      updatedUser = freshUserData;
    } else if (freshUserData && freshUserData.user) {
      updatedUser = freshUserData.user;
    }
    if (updatedUser) {
      const existingUser = AuthService.getUser();
      const mergedUser = {
        ...existingUser,
        ...updatedUser,
        branch_id: updatedUser.branch_id || existingUser.branch_id
      };
      localStorage.setItem('auth_user', JSON.stringify(mergedUser));
    }
  } catch (error) {
    }
}
function handleTabChange(tabId) {
  activeTab.value = tabId;
}
function handleLogout() {
  AuthService.logout();
  toast.success('Đăng xuất thành công!');
  router.replace('/auth');
}
function handleOrderCreated(order) {
  if (tabs.value.find(t => t.id === 'orders')) {
    activeTab.value = 'orders';
  }
}
async function loadComponent() {
  const tab = tabs.value.find(t => t.id === activeTab.value);
  if (tab && tab.component) {
    try {
      const module = await tab.component();
      currentComponent.value = module.default || module;
    } catch (error) {
      currentComponent.value = null;
    }
  } else {
    currentComponent.value = null;
  }
}
watch(activeTab, () => {
  loadComponent();
});
onMounted(async () => {
  await refreshUserData();
  await loadBranch();
  if (tabs.value.length > 0) {
    activeTab.value = tabs.value[0].id;
    await loadComponent();
  }
  
  // ✅ SETUP SOCKET.IO LISTENERS FOR GLOBAL NOTIFICATIONS
  console.log('[Employee Dashboard] Setting up global socket listeners...');
  
  // Ensure socket is connected
  if (!SocketService.getConnectionStatus()) {
    SocketService.connect();
    const connected = await SocketService.waitForConnection(3000);
    console.log('[Employee Dashboard] Socket connected:', connected);
  }
  
  const currentUser = AuthService.getUser();
  const userBranchId = currentUser?.branch_id ? parseInt(currentUser.branch_id) : null;
  const userRoleId = currentUser?.role_id;
  
  console.log('[Employee Dashboard] User info:', { 
    role_id: userRoleId, 
    branch_id: userBranchId,
    username: currentUser?.username 
  });
  
  // Listen for new orders - show notification based on role and branch
  SocketService.on('new-order', (data) => {
    console.log('[Employee Dashboard] 🔔 Received new-order notification:', data);
    
    const dataBranchId = parseInt(data.branchId);
    let shouldShowNotification = false;
    
    // Manager (role_id === 2): show if order is from their assigned branch
    // Cashier (role_id === 6): show if order is from their assigned branch
    // Kitchen Staff (role_id === 5): show if order is from their assigned branch
    // Staff (role_id === 8): show if order is from their assigned branch
    if (userBranchId && dataBranchId === userBranchId) {
      shouldShowNotification = true;
      console.log('[Employee Dashboard] ✅ Branch match - showing notification');
    } else {
      console.log('[Employee Dashboard] ❌ Branch mismatch - userBranchId:', userBranchId, 'dataBranchId:', dataBranchId);
    }
    
    if (shouldShowNotification) {
      const orderTypeLabel = {
        'dine_in': 'Dine-in',
        'takeaway': 'Takeaway',
        'delivery': 'Delivery'
      }[data.orderType] || data.orderType;
      
      const totalAmount = data.total ? new Intl.NumberFormat('vi-VN').format(data.total) + 'đ' : '';
      const customerInfo = data.customerName ? ` - ${data.customerName}` : '';
      
      const notificationMessage = `Đơn hàng mới #${data.orderId} (${orderTypeLabel})${customerInfo}${totalAmount ? ' - ' + totalAmount : ''}`;
      
      console.log('[Employee Dashboard] ✅ Showing notification:', notificationMessage);
      
      try {
        toast.info(notificationMessage, {
          timeout: 8000,
          onClick: () => {
            // Navigate to orders tab if available
            if (tabs.value.find(t => t.id === 'orders')) {
              activeTab.value = 'orders';
            }
          }
        });
      } catch (error) {
        console.error('[Employee Dashboard] ❌ Error showing toast:', error);
        alert(notificationMessage);
      }
    } else {
      console.log('[Employee Dashboard] ❌ Notification filtered out - branch mismatch or not applicable');
    }
  });
  
  // Listen for order status updates - show notification if order is from user's branch
  SocketService.on('order-status-updated', (data) => {
    console.log('[Employee Dashboard] 🔔 Received order-status-updated notification:', data);
    
    const dataBranchId = data.branchId ? parseInt(data.branchId) : null;
    
    if (userBranchId && dataBranchId === userBranchId) {
      console.log('[Employee Dashboard] ✅ Order status updated for branch:', userBranchId);
      
      // Manager: Hiển thị thông báo khi có đơn delivery ready cần assign
      if (userRoleId === USER_ROLES.MANAGER && 
          data.orderType === 'delivery' && 
          data.newStatus === 'ready') {
        const notificationMessage = `Đơn hàng #${data.orderId} đã sẵn sàng! Vui lòng assign cho shipper.`;
        toast.info(notificationMessage, {
          timeout: 8000,
          onClick: () => {
            // Navigate to Delivery Assignment tab if available
            if (tabs.value.find(t => t.id === 'delivery-assignment')) {
              activeTab.value = 'delivery-assignment';
            }
          }
        });
      }
      
      // Refresh orders if on orders tab
      if (tabs.value.find(t => t.id === 'orders') && activeTab.value === 'orders') {
        // Component will handle refresh via its own listener
      }
    }
  });
  
  // Listen for payment status updates
  SocketService.on('payment-status-updated', (data) => {
    console.log('[Employee Dashboard] 🔔 Received payment-status-updated notification:', data);
    
    const dataBranchId = data.branchId ? parseInt(data.branchId) : null;
    
    if (userBranchId && dataBranchId === userBranchId) {
      console.log('[Employee Dashboard] ✅ Payment status updated for branch:', userBranchId);
      // Refresh orders if on orders tab
      if (tabs.value.find(t => t.id === 'orders') && activeTab.value === 'orders') {
        // Component will handle refresh via its own listener
      }
    }
  });
  
  console.log('[Employee Dashboard] ✅ Global socket listeners registered');
});

onBeforeUnmount(() => {
  // Clean up socket listeners
  console.log('[Employee Dashboard] Cleaning up socket listeners...');
  SocketService.off('new-order');
  SocketService.off('order-status-updated');
  SocketService.off('payment-status-updated');
});
</script>
<template>
  <div class="employee-dashboard-layout" :class="{ 'has-sidebar': activeTab === 'create-order' }">
    <!-- Employee Header Component -->
    <EmployeeHeader 
      :tabs="tabs"
      :active-tab="activeTab"
      @tab-change="handleTabChange"
      @logout="handleLogout"
    />
    <!-- Tab Content -->
    <div class="tab-content">
      <div v-if="tabs.length === 0" class="empty-state">
        <i class="fas fa-info-circle"></i>
        <p>No functions assigned to your role.</p>
        <p>Please contact the administrator.</p>
      </div>
      <component 
        v-else-if="currentComponent"
        :is="currentComponent"
        :key="activeTab"
        @order-created="handleOrderCreated"
      />
      <div v-else class="loading-state">
        <i class="fas fa-spinner fa-spin"></i>
        <p>Loading...</p>
      </div>
    </div>
  </div>
</template>
<style scoped>
.employee-dashboard-layout {
  min-height: 100vh;
  background: white;
  padding-top: 128px; 
}
.tab-content {
  padding: 0;
  min-height: calc(100vh - 128px);
  background: white;
}
.empty-state {
  background: white;
  padding: 60px 20px;
  border-radius: 12px;
  text-align: center;
  border: 1px solid #E2E8F0;
}
.empty-state i {
  font-size: 48px;
  color: #9CA3AF;
  margin-bottom: 16px;
}
.empty-state h3 {
  margin: 0 0 8px 0;
  color: #1a1a1a;
  font-size: 18px;
  font-weight: 700;
}
.empty-state p {
  color: #6B7280;
  margin: 8px 0;
  font-size: 14px;
  font-weight: 500;
}
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  background: white;
  border-radius: 8px;
  gap: 16px;
  border: 1px solid #E2E8F0;
  margin: 20px;
}
.loading-state i {
  font-size: 32px;
  color: #F59E0B;
}
.loading-state p {
  color: #6B7280;
  font-size: 14px;
  margin: 0;
  font-weight: 500;
}
.employee-dashboard-layout.has-sidebar :deep(.employee-header) {
  right: 420px;
}
@media (max-width: 768px) {
  .employee-dashboard-layout {
    padding-top: 128px; 
  }
  .employee-dashboard-layout.has-sidebar :deep(.employee-header) {
    right: 0;
  }
  .tab-content {
    padding: 0;
    min-height: calc(100vh - 128px);
  }
}
</style>
