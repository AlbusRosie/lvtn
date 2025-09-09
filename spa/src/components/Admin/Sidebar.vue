<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import authService from '@/services/AuthService';
import { useToast } from 'vue-toastification';

const router = useRouter();
const toast = useToast();
const isCollapsed = ref(false);

const menuItems = [
    {
        title: 'TRANG CHỦ',
        icon: 'fas fa-home',
        route: '/'
    },
    {
        title: 'SẢN PHẨM',
        icon: 'fas fa-box',
        route: '/admin/products'
    },
    {
        title: 'BÀN',
        icon: 'fas fa-table',
        route: '/admin/tables'
    },
    {
        title: 'CHI NHÁNH',
        icon: 'fas fa-building',
        route: '/admin/branches'
    },
    {
        title: 'TẦNG',
        icon: 'fas fa-layer-group',
        route: '/admin/floors'
    },
    {
        title: 'DANH MỤC THỰC ĐƠN',
        icon: 'fas fa-tags',
        route: '/admin/categories'
    },
];

const toggleSidebar = () => {
  isCollapsed.value = !isCollapsed.value;
};

function handleLogout() {
  authService.logout();
  localStorage.removeItem('currentUser');
  toast.success('Đăng xuất thành công!');
  router.push('/auth');
}
</script>

<template>
  <div class="admin-sidebar" :class="{ 'collapsed': isCollapsed }">
    <div class="sidebar-header">
        <img src="#" alt="Logo" class="logo" v-if="!isCollapsed">
        <button class="toggle-btn" @click="toggleSidebar">
            <i :class="isCollapsed ? 'fas fa-chevron-right' : 'fas fa-chevron-left'"></i>
        </button>
    </div>

    <nav class="sidebar-nav">
        <router-link
            v-for="item in menuItems"
            :key="item.route"
            :to="item.route"
            class="nav-item"
            :title="isCollapsed ? item.title : ''"
        >
            <i :class="item.icon"></i>
            <span v-if="!isCollapsed">{{ item.title }}</span>
        </router-link>
        <button class="nav-item logout-btn" @click="handleLogout">
            <i class="fas fa-sign-out-alt"></i>
            <span v-if="!isCollapsed">ĐĂNG XUẤT</span>
        </button>
    </nav>
  </div>
</template>

<style scoped>
.admin-sidebar {
  width: 250px;
  height: 100vh;
  background-color: #2c3e50;
  color: white;
  transition: all 0.3s ease;
  position: fixed;
  left: 0;
  top: 0;
  z-index: 1000;
}

.admin-sidebar.collapsed {
  width: 60px;
}

.sidebar-header {
  padding: 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.logo {
  height: 40px;
  width: auto;
}

.toggle-btn {
  background: none;
  border: none;
  color: white;
  cursor: pointer;
  padding: 0.5rem;
}

.sidebar-nav {
  padding: 1rem 0;
}

.nav-item {
  display: flex;
  align-items: center;
  padding: 0.8rem 1rem;
  color: white;
  text-decoration: none;
  transition: background-color 0.3s;
}

.nav-item:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.nav-item i {
  width: 20px;
  margin-right: 1rem;
}

.nav-item.router-link-active {
  background-color: #3498db;
}

.collapsed .nav-item span {
  display: none;
}

.collapsed .nav-item i {
  margin-right: 0;
}

.logout-btn {
  background: none;
  border: none;
  color: white;
  width: 100%;
  text-align: left;
  padding: 0.8rem 1rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  transition: background-color 0.3s;
}

.logout-btn:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.logout-btn i {
  width: 20px;
  margin-right: 1rem;
}
</style>