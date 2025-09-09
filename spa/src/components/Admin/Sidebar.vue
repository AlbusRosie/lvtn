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
        title: 'Dashboard',
        icon: 'fas fa-home',
        route: '/'
    },
    {
        title: 'Products',
        icon: 'fas fa-box',
        route: '/admin/products'
    },
    {
        title: 'Tables',
        icon: 'fas fa-table',
        route: '/admin/tables'
    },
    {
        title: 'Branches',
        icon: 'fas fa-building',
        route: '/admin/branches'
    },
    {
        title: 'Floors',
        icon: 'fas fa-layer-group',
        route: '/admin/floors'
    },
    {
        title: 'Categories',
        icon: 'fas fa-tags',
        route: '/admin/categories'
    },
    {
        title: 'Orders',
        icon: 'fas fa-shopping-cart',
        route: '/orders'
    },
    {
        title: 'Customers',
        icon: 'fas fa-users',
        route: '/customers'
    },
    {
        title: 'Categories',
        icon: 'fas fa-tags',
        route: '/categories'
    },
    {
        title: 'Promotions',
        icon: 'fas fa-percent',
        route: '/promotions'
    },
    {
        title: 'Reports',
        icon: 'fas fa-chart-bar',
        route: '/reports'
    },
    {
        title: 'Settings',
        icon: 'fas fa-cog',
        route: '/settings'
    }
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
            <span v-if="!isCollapsed">Đăng xuất</span>
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