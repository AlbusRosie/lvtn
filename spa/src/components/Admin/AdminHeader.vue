<script setup>
import { ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import AuthService from '@/services/AuthService';
const route = useRoute();
const router = useRouter();
const user = AuthService.getUser();
const pageTitles = {
  '/': 'Reports & Analytics',
  '/admin': 'Reports & Analytics',
  '/admin/orders': 'Order Management',
  '/admin/reservations': 'Reservation Management',
  '/admin/tables': 'Table Management',
  '/admin/customers': 'Customer Management',
  '/admin/staff': 'Staff Management',
  '/admin/branches': 'Branch Management',
  '/admin/floors': 'Floor Management',
  '/admin/products/branch-menu': 'Branch Menu Management',
  '/admin/categories': 'Category Management'
};
const pageTitle = computed(() => {
  return pageTitles[route.path] || 'Admin Dashboard';
});
function handleLogout() {
  AuthService.logout();
  router.replace('/auth');
}
</script>
<template>
  <div class="admin-header">
    <!-- Title & Greeting -->
    <div class="header-left">
      <h1 class="page-title">{{ pageTitle }}</h1>
      <span class="greeting-text">Hello, {{ user?.name || 'Administrator' }}</span>
    </div>
    <!-- User Info -->
    <div class="user-section">
      <div class="notification-icons">
        <button class="icon-btn">
          <i class="fas fa-bell"></i>
        </button>
        <button class="icon-btn">
          <i class="fas fa-envelope"></i>
        </button>
      </div>
      <div class="user-info">
        <div class="user-avatar">
          <i class="fas fa-user"></i>
        </div>
        <div class="user-details">
          <p class="user-name">{{ user?.name || 'Admin' }}</p>
          <p class="user-role">{{ user?.role_name || 'Administrator' }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
<style scoped>
.admin-header {
  position: fixed;
  top: 0;
  left: 260px;
  right: 0;
  height: 72px;
  background: #FFFFFF;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  z-index: 100;
  transition: left 0.3s ease;
  border-bottom: 1px solid #E2E8F0;
}
@media (max-width: 768px) {
  .admin-header {
    left: 0;
  }
}
.header-left {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
  flex-shrink: 0;
}
.page-title {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: #1E293B;
  letter-spacing: -0.2px;
  line-height: 1.3;
}
.greeting-text {
  font-size: 12px;
  font-weight: 500;
  color: #94A3B8;
  line-height: 1.2;
}
.user-section {
  display: flex;
  align-items: center;
  gap: 16px;
}
.notification-icons {
  display: flex;
  gap: 8px;
  align-items: center;
}
.icon-btn {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  border: none;
  background: #F8F9FA;
  color: #64748B;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  transition: all 0.25s ease;
}
.icon-btn:hover {
  background: #FED7AA;
  color: #F97316;
}
.user-info {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 12px;
  border-radius: 10px;
  transition: all 0.25s ease;
  cursor: pointer;
}
.user-info:hover {
  background: #F8F9FA;
}
.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: #FED7AA;
  color: #F97316;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  flex-shrink: 0;
}
.user-details {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
}
.user-name {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  line-height: 1.3;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.user-role {
  margin: 0;
  font-size: 11px;
  color: #94A3B8;
  font-weight: 500;
  line-height: 1.2;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
@media (max-width: 1024px) {
  .admin-header {
    left: 260px;
  }
  .page-title {
    font-size: 18px;
  }
  .greeting-text {
    font-size: 12px;
  }
}
@media (max-width: 768px) {
  .admin-header {
    left: 0;
    padding: 0 16px;
  }
  .page-title {
    font-size: 16px;
  }
  .greeting-text {
    font-size: 11px;
  }
  .notification-icons {
    gap: 8px;
  }
  .icon-btn {
    width: 36px;
    height: 36px;
    font-size: 14px;
  }
  .user-details {
    display: none;
  }
}
</style>
