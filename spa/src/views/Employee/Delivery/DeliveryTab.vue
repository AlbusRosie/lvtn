<template>
  <div class="delivery-tab">
    <div v-if="orders.length === 0 && !isLoading" class="empty-state">
      <i class="fas fa-truck"></i>
      <h2>Giao hàng</h2>
      <p>Chưa có đơn hàng được phân công</p>
    </div>
    <div v-else-if="isLoading" class="loading-state">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Đang tải...</p>
    </div>
    <div v-else class="orders-list">
      <div v-for="order in orders" :key="order.id" class="order-card" @click="viewOrder(order)">
        <div class="order-header">
          <h3>Đơn hàng #{{ order.id }}</h3>
          <span :class="['status-badge', getStatusClass(order.status)]">
            {{ getStatusLabel(order.status) }}
          </span>
        </div>
        <div class="order-info">
          <p><i class="fas fa-map-marker-alt"></i> {{ order.delivery_address || 'N/A' }}</p>
          <p><i class="fas fa-money-bill-wave"></i> {{ formatCurrency(order.total) }}</p>
          <p><i class="fas fa-clock"></i> {{ formatDate(order.created_at) }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { useToast } from 'vue-toastification';
import OrderService from '@/services/OrderService';
import SocketService from '@/services/SocketService';
import AuthService from '@/services/AuthService';

const toast = useToast();
const orders = ref([]);
const isLoading = ref(false);

function getCurrentUserId() {
  const user = AuthService.getUser();
  return user?.id || null;
}

async function loadOrders() {
  isLoading.value = true;
  try {
    const userId = getCurrentUserId();
    if (!userId) return;
    
    const deliveryOrders = await OrderService.getDeliveryOrders({
      delivery_staff_id: userId
    });
    orders.value = deliveryOrders || [];
  } catch (error) {
    console.error('Error loading delivery orders:', error);
    toast.error('Không thể tải danh sách đơn hàng');
  } finally {
    isLoading.value = false;
  }
}

function viewOrder(order) {
  // TODO: Implement order detail view
  console.log('View order:', order);
}

function getStatusClass(status) {
  const classes = {
    ready: 'status-ready',
    out_for_delivery: 'status-out-for-delivery',
    completed: 'status-completed',
    cancelled: 'status-cancelled'
  };
  return classes[status] || 'status-default';
}

function getStatusLabel(status) {
  const labels = {
    ready: 'Sẵn sàng',
    out_for_delivery: 'Đang giao',
    completed: 'Hoàn thành',
    cancelled: 'Đã hủy'
  };
  return labels[status] || status;
}

function formatCurrency(amount) {
  if (!amount && amount !== 0) return '₫0';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(amount);
}

function formatDate(dateString) {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleString('vi-VN');
}

onMounted(async () => {
  await loadOrders();
  
  // ✅ SETUP SOCKET.IO LISTENERS
  // Listen for order assignments
  SocketService.on('order-assigned', (data) => {
    const userId = getCurrentUserId();
    // Only show if assigned to this delivery staff (check deliveryStaffId in data)
    if (data.deliveryStaffId === userId || data.delivery_staff_id === userId) {
      toast.info(`Đơn hàng #${data.orderId} đã được phân công cho bạn!`, {
        timeout: 5000,
        onClick: () => {
          loadOrders();
        }
      });
      loadOrders(); // Refresh order list
    }
  });
  
  // Listen for order status updates
  SocketService.on('order-status-updated', (data) => {
    // Refresh if order is in current list
    if (orders.value.some(o => o.id === data.orderId)) {
      loadOrders();
    }
  });
});

onUnmounted(() => {
  // Clean up socket listeners
  SocketService.off('order-assigned');
  SocketService.off('order-status-updated');
});
</script>
<style scoped>
.delivery-tab {
  padding: 0;
  background: transparent;
}
.empty-state {
  text-align: center;
  padding: 60px 20px;
  background: white;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
}
.empty-state i {
  font-size: 48px;
  color: #9CA3AF;
  margin-bottom: 16px;
}
.empty-state h2 {
  font-size: 18px;
  color: #1a1a1a;
  margin: 0 0 8px 0;
  font-weight: 700;
}
.empty-state p {
  color: #6B7280;
  font-size: 14px;
  margin: 0;
  font-weight: 500;
}
</style>
