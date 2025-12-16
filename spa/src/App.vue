<script setup>
import { computed, provide, onMounted, onBeforeUnmount } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useToast } from 'vue-toastification';
import AdminSidebar from '@/components/Admin/Sidebar.vue';
import AdminHeader from '@/components/Admin/AdminHeader.vue';
import AuthService from '@/services/AuthService';
import SocketService from '@/services/SocketService';
import { USER_ROLES } from '@/constants';
const route = useRoute();
const router = useRouter();
const toast = useToast();
provide('toast', toast);
const isAuthPage = computed(() => {
  return route.path === '/auth' || route.path === '/login' || route.path === '/register';
});
const isEmployeePage = computed(() => {
  return route.path.startsWith('/employee');
});
const isAdminPage = computed(() => {
  if (isAuthPage.value || isEmployeePage.value) {
    return false;
  }
  if (!AuthService.isAuthenticated()) {
    return false;
  }
  const user = AuthService.getUser();
  if (user) {
    const isEmployee = user.role_id === 6 || user.role_id === 5 || user.role_id === 7 || user.role_id === 8 || user.role_id === 2;
    if (isEmployee && (route.path === '/' || route.path.startsWith('/admin'))) {
      return false; 
    }
  }
  return route.path.startsWith('/admin') || route.path === '/';
});

// ✅ GLOBAL SOCKET.IO LISTENERS FOR ADMIN
onMounted(async () => {
  // Only setup listeners if user is authenticated
  if (!AuthService.isAuthenticated()) {
    return;
  }
  
  const user = AuthService.getUser();
  if (!user) {
    return;
  }
  
  // Setup socket connection
  if (!SocketService.getConnectionStatus()) {
    SocketService.connect();
    const connected = await SocketService.waitForConnection(3000);
    console.log('[App] Socket connected:', connected);
  }
  
  // Setup global listeners based on user role
  const userRoleId = user.role_id;
  const userBranchId = user.branch_id ? parseInt(user.branch_id) : null;
  
  console.log('[App] Setting up global socket listeners...');
  console.log('[App] User role:', userRoleId, 'Branch:', userBranchId);
  
  // For Admin: Show notifications for ALL branches
  if (userRoleId === USER_ROLES.ADMIN) {
    console.log('[App] Admin detected - setting up global new-order listener for ALL branches');
    
    SocketService.on('new-order', (data) => {
      console.log('[App] 🔔 Admin received new-order notification:', data);
      
      const dataBranchId = parseInt(data.branchId);
      
      // Admin always sees notifications for all branches
      const orderTypeLabel = {
        'dine_in': 'Dine-in',
        'takeaway': 'Takeaway',
        'delivery': 'Delivery'
      }[data.orderType] || data.orderType;
      
      // Try to get branch name (we'll show branch ID if name not available)
      const notificationMessage = `Đơn hàng mới #${data.orderId} - Chi nhánh #${dataBranchId} (${orderTypeLabel})`;
      
      console.log('[App] ✅ Showing admin notification:', notificationMessage);
      
      try {
        toast.info(notificationMessage, {
          timeout: 8000,
          onClick: () => {
            // Navigate to orders page if not already there
            if (route.path !== '/admin/orders') {
              router.push('/admin/orders');
            }
          }
        });
      } catch (error) {
        console.error('[App] ❌ Error showing toast:', error);
        alert(notificationMessage);
      }
    });
    
    // Listen for order status updates
    SocketService.on('order-status-updated', (data) => {
      console.log('[App] 🔔 Admin received order-status-updated notification:', data);
      // Optionally show notification for status updates
    });
    
    // Listen for payment status updates
    SocketService.on('payment-status-updated', (data) => {
      console.log('[App] 🔔 Admin received payment-status-updated notification:', data);
      // Optionally show notification for payment updates
    });
  }
  
  // For Manager/Cashier: Show notifications only for their assigned branch
  // (This is handled in Employee Dashboard, but we can also add here as backup)
  
  console.log('[App] ✅ Global socket listeners registered');
});

onBeforeUnmount(() => {
  // Clean up global listeners
  console.log('[App] Cleaning up global socket listeners...');
  SocketService.off('new-order');
  SocketService.off('order-status-updated');
  SocketService.off('payment-status-updated');
});
</script>
<template>
  <div class="admin-layout" :class="{ 'auth-layout': isAuthPage }">
    <AdminSidebar v-if="isAdminPage" />
    <AdminHeader v-if="isAdminPage" />
    <div class="main-content" :class="{ 
      'auth-content': isAuthPage, 
      'employee-content': isEmployeePage, 
      'admin-content': isAdminPage 
    }">
      <div class="container-fluid" :class="{ 'auth-container': isAuthPage, 'admin-container': isAdminPage }">
        <router-view/>
      </div>
    </div>
  </div>
</template>
<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}
html, body {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  overflow-x: hidden;
}
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
  background: #FDFBF8;
  color: #333;
  max-width: 100vw;
}
body.auth-page {
  background: transparent !important;
}
html.auth-page {
  background: transparent !important;
  height: 100% !important;
  width: 100% !important;
}
html.auth-page,
html.auth-page body {
  margin: 0 !important;
  padding: 0 !important;
  height: 100% !important;
  width: 100% !important;
  overflow: hidden !important;
}
.admin-layout {
  display: flex;
  min-height: 100vh;
  transition: all 0.3s ease;
  background: #FDFBF8;
  overflow-x: hidden;
  max-width: 100vw;
}
.main-content {
  flex: 1;
  transition: margin-left 0.3s ease;
  min-height: 100vh;
  overflow-x: hidden;
  max-width: 100%;
}
.admin-content {
  margin-top: 70px;
  margin-left: 250px;
  padding: 0;
  transition: margin-left 0.3s ease;
}
.admin-container {
  width: 100%;
  max-width: 100%;
  padding: 24px;
  box-sizing: border-box;
  overflow-x: hidden;
}
.auth-layout {
  display: block;
  width: 100%;
  min-height: 100vh;
  height: 100vh;
  overflow: hidden;
  background: transparent;
  margin: 0;
  padding: 0;
  position: relative;
}
.auth-content {
  margin-left: 0;
  margin-top: 0;
  padding: 0;
  transition: margin-left 0.3s ease;
  width: 100%;
  min-height: 100vh;
  height: 100vh;
  overflow: hidden;
  background: transparent;
  position: relative;
}
.employee-content {
  margin-left: 0;
  padding: 0;
  transition: margin-left 0.3s ease;
}
.auth-container {
  max-width: none;
  margin: 0;
  padding: 0;
  width: 100%;
  min-height: 100vh;
  height: 100vh;
  overflow: hidden;
  background: transparent;
  position: relative;
}

/* Hide pagination on auth pages */
.auth-layout .pagination,
.auth-layout .pagination-section,
.auth-layout .pagination-nav,
.auth-layout .pagination-controls,
.auth-layout .pagination-buttons,
.auth-layout .pagination-info,
.auth-layout .pagination-label,
.auth-layout .pagination-select,
.auth-content .pagination,
.auth-content .pagination-section,
.auth-content .pagination-nav,
.auth-content .pagination-controls,
.auth-content .pagination-buttons,
.auth-content .pagination-info,
.auth-content .pagination-label,
.auth-content .pagination-select,
.auth-container .pagination,
.auth-container .pagination-section,
.auth-container .pagination-nav,
.auth-container .pagination-controls,
.auth-container .pagination-buttons,
.auth-container .pagination-info,
.auth-container .pagination-label,
.auth-container .pagination-select,
.auth-layout nav.pagination,
.auth-content nav.pagination,
.auth-container nav.pagination {
  display: none !important;
  visibility: hidden !important;
  opacity: 0 !important;
  height: 0 !important;
  width: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  overflow: hidden !important;
}
.container-fluid {
  width: 100%;
  max-width: 100%;
  box-sizing: border-box;
  overflow-x: hidden;
}
.employee-content .container-fluid {
  padding: 0;
}
.page {
  max-width: 400px;
  margin: auto;
}
.admin-card {
  background: white;
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  margin-bottom: 24px;
}
.admin-btn {
  padding: 10px 20px;
  border: none;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}
.admin-btn-primary {
  background: #FF8C42;
  color: white;
  box-shadow: 0 2px 8px rgba(255, 140, 66, 0.3);
}
.admin-btn-primary:hover {
  background: #E67E22;
  box-shadow: 0 4px 12px rgba(255, 140, 66, 0.4);
  transform: translateY(-1px);
}
.admin-btn-secondary {
  background: white;
  color: #666;
  border: 2px solid #ddd;
}
.admin-btn-secondary:hover {
  border-color: #FF8C42;
  color: #FF8C42;
}
.admin-input {
  padding: 10px 14px;
  border: 2px solid #F0E6D9;
  border-radius: 12px;
  font-size: 14px;
  background: white;
  color: #333;
  transition: all 0.3s ease;
  font-weight: 500;
}
.admin-input:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
</style>