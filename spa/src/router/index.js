import { createWebHistory, createRouter } from 'vue-router';
import AdminHome from '@/views/Admin/User/Home.vue';
import AuthService from '@/services/AuthService';

const routes = [
  {
    path: '/auth',
    name: 'auth',
    component: () => import('@/views/Admin/Auth/AuthPage.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    name: 'home',
    component: AdminHome,
    meta: { requiresAuth: true, requiresAdmin: true }
  },

  {
    path: '/admin/products/:id',
    name: 'admin.product.detail',
    component: () => import('@/views/Admin/Product/ProductDetail.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/admin/products/create',
    name: 'admin.product.create',
    component: () => import('@/views/Admin/Product/ProductCreate.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/admin/products/branch-menu',
    name: 'admin.products.branch-menu',
    component: () => import('@/views/Admin/Product/BranchMenuManagement.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },

  {
    path: '/admin/tables',
    name: 'admin.tables',
    component: () => import('@/views/Admin/Table/TableList.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },

  {
    path: '/admin/branches',
    name: 'admin.branches',
    component: () => import('@/views/Admin/Branch/BranchList.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },

  {
    path: '/admin/floors',
    name: 'admin.floors',
    component: () => import('@/views/Admin/Floor/FloorList.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },

  {
    path: '/admin/categories',
    name: 'admin.categories',
    component: () => import('@/views/Admin/Category/CategoryList.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'notfound',
    component: () => import('@/views/Admin/User/NotFound.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/management/users/:id',
    name: 'user.edit',
    component: () => import('@/views/Admin/User/UserEdit.vue'),
    props: (route) => ({ userId: route.params.id }),
    meta: { requiresAuth: true, requiresAdmin: true }
  },
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
});

router.beforeEach((to, from, next) => {
  const isAuthenticated = AuthService.isAuthenticated();
  const user = AuthService.getUser();

  if (to.meta.requiresAuth && !isAuthenticated) {
    return next('/auth');
  }

  if (to.meta.requiresAdmin && !AuthService.canAccessAdmin()) {
    return next('/auth');
  }

  if (to.path === '/auth' && isAuthenticated) {
    return next('/');
  }

  next();
});

export default router;