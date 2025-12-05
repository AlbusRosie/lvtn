import { createWebHistory, createRouter } from 'vue-router';
import AdminHome from '@/views/Admin/User/Home.vue';
import UserList from '@/views/Admin/User/UserList.vue';
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
    path: '/admin/customers',
    name: 'admin.customers',
    component: UserList,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/admin/staff',
    name: 'admin.staff',
    component: () => import('@/views/Admin/Staff/StaffList.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/employee',
    name: 'employee.home',
    component: () => import('@/views/Employee/Dashboard.vue'),
    meta: { requiresAuth: true, requiresEmployee: true }
  },
  {
    path: '/employee/kitchen',
    name: 'employee.kitchen',
    component: () => import('@/views/Employee/Dashboard.vue'),
    meta: { requiresAuth: true, requiresEmployee: true }
  },
  {
    path: '/employee/cashier',
    name: 'employee.cashier',
    component: () => import('@/views/Employee/Dashboard.vue'),
    meta: { requiresAuth: true, requiresEmployee: true }
  },
  {
    path: '/employee/delivery',
    name: 'employee.delivery',
    component: () => import('@/views/Employee/Dashboard.vue'),
    meta: { requiresAuth: true, requiresEmployee: true }
  },
  {
    path: '/employee/manager',
    name: 'employee.manager',
    component: () => import('@/views/Employee/Dashboard.vue'),
    meta: { requiresAuth: true, requiresEmployee: true }
  },
  {
    path: '/employee/staff',
    name: 'employee.staff',
    component: () => import('@/views/Employee/Dashboard.vue'),
    meta: { requiresAuth: true, requiresEmployee: true }
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
    path: '/admin/orders',
    name: 'admin.orders',
    component: () => import('@/views/Admin/Order/OrderList.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'notfound',
    component: () => import('@/views/Admin/User/NotFound.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/admin/reservations',
    name: 'admin.reservations',
    component: () => import('@/views/Admin/Reservation/ReservationList.vue'),
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
  if (isAuthenticated && user) {
    const isEmployee = user.role_id === 6 || user.role_id === 5 || user.role_id === 7 || user.role_id === 8 || user.role_id === 2;
    if (isEmployee && (to.path === '/' || to.path.startsWith('/admin'))) {
      if (user.role_id === 6) return next('/employee/cashier'); 
      if (user.role_id === 5) return next('/employee/kitchen'); 
      if (user.role_id === 7) return next('/employee/delivery'); 
      if (user.role_id === 8) return next('/employee/cashier'); 
      if (user.role_id === 2) return next('/employee/manager'); 
      return next('/employee');
    }
    if (to.path === '/') {
      if (user.role_id === 1 || user.role_id === 3) return next(); 
      if (user.role_id === 6) return next('/employee/cashier'); 
      if (user.role_id === 5) return next('/employee/kitchen'); 
      if (user.role_id === 7) return next('/employee/delivery'); 
      if (user.role_id === 8) return next('/employee/cashier'); 
      if (user.role_id === 2) return next('/employee/manager'); 
      if (AuthService.canAccessEmployee()) return next('/employee');
    }
    if (to.meta.requiresAdmin && !AuthService.canAccessAdmin()) {
      if (user.role_id === 6) return next('/employee/cashier'); 
      if (user.role_id === 5) return next('/employee/kitchen'); 
      if (user.role_id === 7) return next('/employee/delivery'); 
      if (user.role_id === 2) return next('/employee/manager'); 
      if (user.role_id === 8) return next('/employee/cashier'); 
      if (AuthService.canAccessEmployee()) return next('/employee');
      return next('/auth');
    }
    if (to.meta.requiresEmployee && !AuthService.canAccessEmployee()) {
      if (user.role_id === 1 || user.role_id === 3) return next('/');
      return next('/auth');
    }
    if (to.path === '/auth' && isAuthenticated && user) {
      if (user.role_id === 1 || user.role_id === 3) return next('/'); 
      if (user.role_id === 6) return next('/employee/cashier'); 
      if (user.role_id === 5) return next('/employee/kitchen'); 
      if (user.role_id === 7) return next('/employee/delivery'); 
      if (user.role_id === 8) return next('/employee/cashier'); 
      if (user.role_id === 2) return next('/employee/manager'); 
      if (AuthService.canAccessEmployee()) return next('/employee');
      return next('/');
    }
  }
  next();
});
export default router;