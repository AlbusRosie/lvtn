<script setup>
import { computed, provide } from 'vue';
import { useRoute } from 'vue-router';
import { useToast } from 'vue-toastification';
import AdminSidebar from '@/components/Admin/Sidebar.vue';
import AdminHeader from '@/components/Admin/AdminHeader.vue';
import AuthService from '@/services/AuthService';
const route = useRoute();
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
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
  background: #FDFBF8;
  color: #333;
  overflow-x: hidden;
  max-width: 100vw;
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
}
.auth-content {
  margin-left: 0;
  padding: 0;
  transition: margin-left 0.3s ease;
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