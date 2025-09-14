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
        title: 'MENU CHI NHÁNH',
        icon: 'fas fa-shop',
        route: '/admin/products/branch-menu'
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
  <div class="sidebar" :class="{ 'collapsed': isCollapsed }">
    <div class="header">
      <span v-if="!isCollapsed">Menu</span>
      <button @click="toggleSidebar">☰</button>
    </div>

    <div class="nav">
      <router-link
        v-for="item in menuItems"
        :key="item.route"
        :to="item.route"
        class="item"
      >
        <i :class="item.icon"></i>
        <span v-if="!isCollapsed">{{ item.title }}</span>
      </router-link>
      
      <button class="item logout" @click="handleLogout">
        <i class="fas fa-sign-out-alt"></i>
        <span v-if="!isCollapsed">ĐĂNG XUẤT</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.sidebar {
  width: 200px;
  height: 100vh;
  background: #333;
  color: white;
  position: fixed;
  left: 0;
  top: 0;
  transition: width 0.3s;
}

.sidebar.collapsed {
  width: 50px;
}

.header {
  padding: 15px;
  border-bottom: 1px solid #555;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header button {
  background: none;
  border: none;
  color: white;
  cursor: pointer;
  font-size: 18px;
}

.nav {
  padding: 10px 0;
}

.item {
  display: flex;
  align-items: center;
  padding: 12px 15px;
  color: white;
  text-decoration: none;
  border: none;
  background: none;
  width: 100%;
  cursor: pointer;
}

.item:hover {
  background: #555;
}

.item i {
  width: 20px;
  margin-right: 10px;
}

.item.router-link-active {
  background: #007bff;
}

.collapsed .item span {
  display: none;
}

.collapsed .item i {
  margin-right: 0;
}

.logout {
  margin-top: 10px;
  border-top: 1px solid #555;
  padding-top: 10px;
}
</style>