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
    path: '/admin/reservations',
    name: 'admin.reservations',
    component: () => import('@/views/Admin/Reservation/ReservationList.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'notfound',
    component: () => import('@/views/Admin/User/NotFound.vue'),
    meta: { requiresAuth: false }
  },
];
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
});
router.beforeEach((to, from, next) => {
  const isAuthenticated = AuthService.isAuthenticated();
  const user = AuthService.getUser();
  
  // QUAN TRỌNG: Kiểm tra delivery driver TRƯỚC TẤT CẢ các logic khác
  if (isAuthenticated && user && user.role_id === 7) {
    // Nếu là delivery driver, LUÔN redirect về /employee/delivery (trừ khi đang ở đó)
    if (to.path !== '/employee/delivery') {
      return next('/employee/delivery');
    }
    // Nếu đã ở đúng route, cho phép tiếp tục
    return next();
  }
  
  // Nếu route yêu cầu auth nhưng chưa đăng nhập hoặc không có user hợp lệ
  if (to.meta.requiresAuth && (!isAuthenticated || !user)) {
    return next('/auth');
  }
  
  // Nếu đã đăng nhập và có user hợp lệ
  if (isAuthenticated && user) {
    // Kiểm tra và redirect employee về route phù hợp TRƯỚC khi xử lý các logic khác
    const isEmployee = user.role_id === 6 || user.role_id === 5 || user.role_id === 7 || user.role_id === 8 || user.role_id === 2;
    
    // Nếu là employee khác và đang truy cập route không phù hợp, redirect về route phù hợp
    if (isEmployee && (to.path === '/' || to.path.startsWith('/admin'))) {
      if (user.role_id === 6) return next('/employee/cashier'); 
      if (user.role_id === 5) return next('/employee/kitchen'); 
      if (user.role_id === 7) return next('/employee/delivery'); 
      if (user.role_id === 8) return next('/employee/cashier'); 
      if (user.role_id === 2) return next('/employee/manager'); 
      return next('/employee');
    }
    
    // Nếu là employee và đang truy cập route không tồn tại (404), redirect về route phù hợp
    if (isEmployee && to.name === 'notfound') {
      if (user.role_id === 6) return next('/employee/cashier'); 
      if (user.role_id === 5) return next('/employee/kitchen'); 
      if (user.role_id === 7) return next('/employee/delivery'); 
      if (user.role_id === 8) return next('/employee/cashier'); 
      if (user.role_id === 2) return next('/employee/manager'); 
      return next('/employee');
    }
    
    // Nếu là delivery driver, đảm bảo không được truy cập route khác
    if (user.role_id === 7 && to.path !== '/employee/delivery') {
      return next('/employee/delivery');
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
  
  // Nếu chưa đăng nhập và không phải route /auth, redirect về /auth
  if (!isAuthenticated || !user) {
    if (to.path !== '/auth') {
      return next('/auth');
    }
  }
  
  next();
});
export default router;