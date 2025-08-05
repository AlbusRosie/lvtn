import { createWebHistory, createRouter } from 'vue-router';
import AdminHome from '@/views/Admin/User/Home.vue';

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
    meta: { requiresAuth: true }
  },
  
  {
    path: '/admin/products',
    name: 'admin.products',
    component: () => import('@/views/Admin/Product/ProductList.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/admin/products/:id',
    name: 'admin.product.detail',
    component: () => import('@/views/Admin/Product/ProductDetail.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/admin/products/create',
    name: 'admin.product.create',
    component: () => import('@/views/Admin/Product/ProductCreate.vue'),
    meta: { requiresAuth: true }
  },
  
  {
    path: '/admin/tables',
    name: 'admin.tables',
    component: () => import('@/views/Admin/Table/TableList.vue'),
    meta: { requiresAuth: true }
  },
  
  {
    path: '/admin/branches',
    name: 'admin.branches',
    component: () => import('@/views/Admin/Branch/BranchList.vue'),
    meta: { requiresAuth: true }
  },
  
  {
    path: '/admin/floors',
    name: 'admin.floors',
    component: () => import('@/views/Admin/Floor/FloorList.vue'),
    meta: { requiresAuth: true }
  },
  
  {
    path: '/admin/categories',
    name: 'admin.categories',
    component: () => import('@/views/Admin/Category/CategoryList.vue'),
    meta: { requiresAuth: true }
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
    meta: { requiresAuth: true }
  },
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
});


router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('auth_token');
  const userStr = localStorage.getItem('auth_user');
  const user = userStr ? JSON.parse(userStr) : null;
  const isAuthenticated = !!token;

  
  if (to.meta.requiresAuth && !isAuthenticated) {
    return next('/auth');
  }

  
  if (to.path === '/auth' && isAuthenticated) {
    
    if (user && user.role_id === 1) {
      return next('/');
    }
    
    return next();
  }

  
  if (to.path === '/' && user && user.role_id !== 1) {
    return next('/');
  }

  next();
});

export default router;