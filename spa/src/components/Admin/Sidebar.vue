<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import authService from '@/services/AuthService';
import { useToast } from 'vue-toastification';
const router = useRouter();
const toast = useToast();
const expandedMenus = ref(new Set());
const menuItems = [
    {
        title: 'HOME',
        icon: 'fas fa-home',
        route: '/'
    },
    {
        title: 'ORDERS',
        icon: 'fas fa-shopping-cart',
        route: '/admin/orders'
    },
    {
        title: 'RESERVATIONS',
        icon: 'fas fa-calendar-check',
        route: '/admin/reservations'
    },
    {
        title: 'TABLES',
        icon: 'fas fa-table',
        route: '/admin/tables'
    },
    {
        title: 'USERS',
        icon: 'fas fa-users',
        hasSubmenu: true,
        submenu: [
            {
                title: 'Customers',
                route: '/admin/customers'
            },
            {
                title: 'Staff Management',
                route: '/admin/staff'
            }
        ]
    },
    {
        title: 'BRANCHES',
        icon: 'fas fa-building',
        route: '/admin/branches'
    },
    {
        title: 'FLOORS',
        icon: 'fas fa-layer-group',
        route: '/admin/floors'
    },
    {
        title: 'BRANCH MENU',
        icon: 'fas fa-shop',
        route: '/admin/products/branch-menu'
    },
    {
        title: 'CATEGORIES',
        icon: 'fas fa-tags',
        route: '/admin/categories'
    },
];
const toggleSubmenu = (title) => {
    if (expandedMenus.value.has(title)) {
        expandedMenus.value.delete(title);
    } else {
        expandedMenus.value.add(title);
    }
};
function handleLogout() {
  authService.logout();
  localStorage.removeItem('currentUser');
  toast.success('Logged out successfully!');
  router.replace('/auth');
}
</script>
<template>
  <div class="sidebar">
    <div class="header">
      <div class="logo-text">
        <div class="logo-icon">
          <img src="@/assets/logo.png" alt="Beast Bite" class="logo-img" />
        </div>
      </div>
    </div>
    <div class="nav">
      <div v-for="item in menuItems" :key="item.title" class="menu-group">
        <!-- Menu item with submenu -->
        <div v-if="item.hasSubmenu" class="menu-item-with-submenu">
          <button 
            class="nav-item parent-item" 
            @click="toggleSubmenu(item.title)"
            :class="{ 
              'expanded': expandedMenus.has(item.title),
              'active': item.submenu.some(sub => $route.path === sub.route)
            }"
          >
            <div class="nav-icon-wrapper">
              <i :class="item.icon"></i>
            </div>
            <span class="nav-text">{{ item.title }}</span>
            <i class="fas fa-chevron-right expand-icon"></i>
          </button>
          <!-- Submenu -->
          <div 
            v-if="expandedMenus.has(item.title)" 
            class="submenu"
          >
            <router-link
              v-for="subItem in item.submenu"
              :key="subItem.route"
              :to="subItem.route"
              class="submenu-item"
              active-class="active"
            >
              <span class="submenu-dot"></span>
              <span>{{ subItem.title }}</span>
            </router-link>
          </div>
        </div>
        <!-- Regular menu item -->
        <router-link
          v-else
          :to="item.route"
          class="nav-item"
          active-class="active"
        >
          <div class="nav-icon-wrapper">
            <i :class="item.icon"></i>
          </div>
          <span class="nav-text">{{ item.title }}</span>
        </router-link>
      </div>
      <button class="nav-item logout" @click="handleLogout">
        <div class="nav-icon-wrapper">
          <i class="fas fa-sign-out-alt"></i>
        </div>
        <span class="nav-text">LOGOUT</span>
      </button>
    </div>
    <!-- Footer -->
    <div class="sidebar-footer">
      <a href="#" class="footer-link">Privacy Policy</a>
      <a href="#" class="footer-link">Terms of Use</a>
    </div>
  </div>
</template>
<style scoped>
.sidebar {
  width: 260px;
  height: 100vh;
  background: #FFFFFF;
  position: fixed;
  left: 0;
  top: 0;
  box-shadow: 2px 0 12px rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  z-index: 200;
  overflow-y: auto;
  overflow-x: hidden;
  scrollbar-width: none;
  -ms-overflow-style: none;
  border-right: 1px solid #E2E8F0;
}
.sidebar::-webkit-scrollbar {
  display: none;
}
.header {
  padding: 20px 16px;
  border-bottom: 1px solid #E2E8F0;
  display: flex;
  align-items: center;
  background: #FFFFFF;
  position: sticky;
  top: 0;
  z-index: 10;
  backdrop-filter: blur(10px);
}
.logo-text {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
}
.logo-icon {
  width: 70px;
  height: 70px;
  border-radius: 12px;
  background: transparent;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  overflow: hidden;
  padding: 4px;
}
.logo-img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  object-position: center;
}
.brand-name {
  font-size: 18px;
  font-weight: 700;
  color: #333;
}
.nav {
  padding: 12px 8px;
  flex: 1;
  width: 100%;
  box-sizing: border-box;
}
.menu-group {
  margin-bottom: 4px;
  width: 100%;
}
.menu-item-with-submenu {
  position: relative;
  width: 100%;
}
.nav-item {
  display: flex;
  align-items: center;
  padding: 10px 12px;
  color: #64748B;
  text-decoration: none;
  border: none;
  background: none;
  width: 100%;
  cursor: pointer;
  border-radius: 10px;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  margin-bottom: 2px;
  gap: 12px;
  font-size: 13px;
  font-weight: 600;
  min-height: 42px;
  box-sizing: border-box;
  flex-shrink: 0;
  position: relative;
}
.nav-item::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 3px;
  height: 0;
  background: #FED7AA;
  border-radius: 0 3px 3px 0;
  transition: height 0.25s ease;
}
.nav-item:hover {
  background: #F8F9FA;
  color: #475569;
  transform: translateX(2px);
}
.nav-item:hover::before {
  height: 60%;
  background: #FED7AA;
}
.nav-item.active {
  background: #FEF7ED;
  color: #F59E0B;
  box-shadow: none;
}
.nav-item.active::before {
  height: 100%;
  width: 4px;
  background: #FED7AA;
}
.nav-icon-wrapper {
  width: 36px;
  height: 36px;
  border-radius: 9px;
  background: transparent;
  color: #64748B;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.25s ease;
}
.nav-item:not(.active) .nav-icon-wrapper {
  background: #F8F9FA;
  color: #64748B;
}
.nav-item:not(.active):hover .nav-icon-wrapper {
  background: #FED7AA;
  color: #F59E0B;
  transform: scale(1.05);
}
.nav-item.active .nav-icon-wrapper {
  background: #FED7AA;
  color: #F97316;
}
.nav-item i {
  font-size: 15px;
  color: inherit;
}
.nav-text {
  flex: 1;
  text-align: left;
  letter-spacing: 0.2px;
}
.logout {
  margin-top: 8px;
  border-top: 1px solid #E2E8F0;
  padding-top: 12px;
  color: #EF4444;
}
.logout:hover {
  background: #FEF2F2;
  color: #DC2626;
}
.logout .nav-icon-wrapper {
  background: #FEE2E2;
  color: #EF4444;
}
.logout:hover .nav-icon-wrapper {
  background: #FECACA;
  color: #DC2626;
  transform: scale(1.05);
}
.parent-item {
  justify-content: space-between;
}
.expand-icon {
  transition: transform 0.2s ease;
  font-size: 12px;
  margin-left: auto;
  color: inherit;
}
.parent-item.expanded .expand-icon {
  transform: rotate(90deg);
}
.submenu {
  margin-left: 20px;
  margin-top: 6px;
  padding: 4px 0;
  border-left: 2px solid #E2E8F0;
  padding-left: 16px;
  animation: slideDown 0.2s ease;
}
@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
.submenu-item {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  color: #64748B;
  text-decoration: none;
  font-size: 12px;
  font-weight: 500;
  border-radius: 8px;
  margin-bottom: 2px;
  transition: all 0.2s ease;
  gap: 10px;
  min-height: 36px;
  box-sizing: border-box;
  position: relative;
}
.submenu-item:hover {
  background: #F8F9FA;
  color: #F59E0B;
  transform: translateX(4px);
}
.submenu-item.active {
  background: #FEF7ED;
  color: #F59E0B;
  font-weight: 600;
  box-shadow: none;
}
.submenu-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: #CBD5E1;
  flex-shrink: 0;
  transition: all 0.2s ease;
}
.submenu-item:hover .submenu-dot {
  background: #FED7AA;
  transform: scale(1.2);
}
.submenu-item.active .submenu-dot {
  background: #FED7AA;
  width: 6px;
  height: 6px;
}
.sidebar-footer {
  padding: 16px 20px;
  border-top: 1px solid #E2E8F0;
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: auto;
  background: #FAFBFC;
}
.footer-link {
  color: #94A3B8;
  text-decoration: none;
  font-size: 11px;
  font-weight: 500;
  transition: color 0.2s ease;
}
.footer-link:hover {
  color: #FF8C42;
}
@media (max-width: 768px) {
  .sidebar {
    width: 250px;
    transform: translateX(-100%);
    transition: transform 0.3s ease;
  }
  .sidebar.mobile-open {
    transform: translateX(0);
  }
}
</style>
