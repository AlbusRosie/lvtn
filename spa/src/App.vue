<script setup>
import { computed, provide } from 'vue';
import { useRoute } from 'vue-router';
import { useToast } from 'vue-toastification';
import AdminSidebar from '@/components/Admin/Sidebar.vue';

const route = useRoute();
const toast = useToast();
provide('toast', toast);
const isAuthPage = computed(() => {
  return route.path === '/auth' || route.path === '/login' || route.path === '/register';
});
</script>

<template>
  <div class="admin-layout" :class="{ 'auth-layout': isAuthPage }">
    <AdminSidebar v-if="!isAuthPage" />
    <div class="main-content" :class="{ 'auth-content': isAuthPage }">
      <div class="container-fluid mt-3" :class="{ 'auth-container': isAuthPage }">
        <router-view/>
      </div>
    </div>
  </div>
</template>

<style>
.admin-layout {
  display: flex;
  min-height: 100vh;
  transition: all 0.3s ease;
}

.main-content {
  flex: 1;
  margin-left: 250px;
  transition: margin-left 0.3s ease;
}

.main-content.sidebar-collapsed {
  margin-left: 60px;
}

.auth-layout {
  display: block;
}

.auth-content {
  margin-left: 0;
  padding: 0;
  transition: margin-left 0.3s ease;
}

.auth-container {
  max-width: none;
  margin: 0;
  padding: 0;
}

.page {
  max-width: 400px;
  margin: auto;
}
</style>
