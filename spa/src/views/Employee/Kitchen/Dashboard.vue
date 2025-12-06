<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import OrderService from '@/services/OrderService';
import AuthService from '@/services/AuthService';
import { useToast } from 'vue-toastification';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
const router = useRouter();
const toast = useToast();
const orders = ref([]);
const isLoading = ref(true);
const error = ref(null);
const updatingItems = ref(new Set());
const refreshInterval = ref(null);
const SLA_WARNING_MINUTES = 30; 
const user = AuthService.getUser();
const userBranchId = user?.branch_id;
const branchName = user?.branch_name || 'Current Branch';
const filters = ref({
  orderType: 'all', 
  timeRange: 'all' 
});
const sortBy = ref('time_asc'); 
const previousOrdersCount = ref(0);
const previousOrderIds = ref(new Set());
const showConfirmModal = ref(false);
const confirmMessage = ref('');
const confirmCallback = ref(null);
const soundEnabled = ref(true);
const newOrderSound = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGGa77+eeTBALUqfj8LVjHAY4kdnyz3ksBSV3x/Dej0AKFGCz6euoVhQKRp7g8r5sIQUrgc7y2Ik2CBhmu+/nnkwQC1Kn4/C1YxwGOJHZ8s95LAUld8fw3o9AChRgs+nrqFYUCkae4PK+bCEFK4HO8tiJNggYZrvv555MEAtSp+PwtWMcBjiR2fLPeSwFJXfH8N6PQAoUYLPp66hWFApGnuDyvmwhBSuBzvLYiTYIGGa77+eeTBALUqfj8LVjHAY4kdnyz3ksBSV3x/Dej0AKFGCz6euoVhQKRp7g8r5sIQUrgc7y2Ik2CBhmu+/nnkwQC1Kn4/C1YxwGOJHZ8s95LAUld8fw3o9AChRgs+nrqFYUCkae4PK+bCEFK4HO8tiJNggYZrvv555MEAtSp+PwtWMcBjiR2fLPeSwFJXfH8N6PQAoUYLPp66hWFApGnuDyvmwhBSuBzvLYiTYIGGa77+eeTBALUqfj8LVjHAY4kdnyz3ksBSV3x/Dej0A=');
function playNewOrderSound() {
  if (soundEnabled.value && newOrderSound) {
    try {
      newOrderSound.volume = 0.5;
      newOrderSound.play().catch(() => {});
    } catch (e) {
      // Ignore audio errors
    }
  }
}
function playWarningSound() {
  if (soundEnabled.value) {
    const audioContext = new (window.AudioContext || window.webkitAudioContext)();
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    oscillator.frequency.value = 800;
    oscillator.type = 'sine';
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + 0.5);
  }
}
const filteredOrders = computed(() => {
  let filtered = orders.value;
  if (filters.value.orderType !== 'all') {
    filtered = filtered.filter(o => o.order_type === filters.value.orderType);
  }
  if (filters.value.timeRange !== 'all') {
    filtered = filtered.filter(o => {
      const minutes = o.elapsed_minutes || 0;
      switch (filters.value.timeRange) {
        case 'under15':
          return minutes < 15;
        case '15-30':
          return minutes >= 15 && minutes < 30;
        case 'over30':
          return minutes >= 30;
        default:
          return true;
      }
    });
  }
  const pendingOrders = filtered.filter(o => o.status === 'pending');
  const preparingOrders = filtered.filter(o => o.status === 'preparing');
  const sortFunction = (a, b) => {
    switch (sortBy.value) {
      case 'time_desc':
        return (b.elapsed_minutes || 0) - (a.elapsed_minutes || 0);
      case 'time_asc':
        return (a.elapsed_minutes || 0) - (b.elapsed_minutes || 0);
      case 'order_id':
        return b.id - a.id;
      default:
        return new Date(a.created_at) - new Date(b.created_at);
    }
  };
  return {
    pending: pendingOrders.sort(sortFunction),
    preparing: preparingOrders.sort(sortFunction)
  };
});
async function loadKitchenOrders() {
  if (!userBranchId) {
    isLoading.value = false;
    error.value = 'You have not been assigned to any branch. Please contact the administrator.';
    return;
  }
  try {
    isLoading.value = true;
    error.value = null;
    const data = await OrderService.getKitchenOrders(userBranchId);
    let ordersList = [];
    if (Array.isArray(data)) {
      ordersList = data;
    } else if (data && Array.isArray(data.orders)) {
      ordersList = data.orders;
    } else if (data && data.data && Array.isArray(data.data)) {
      ordersList = data.data;
    }
    const currentOrderIds = new Set(ordersList.map(o => o.id));
    const hasNewOrders = ordersList.length > previousOrdersCount.value || 
      ordersList.some(o => !previousOrderIds.value.has(o.id));
    if (hasNewOrders && previousOrdersCount.value > 0) {
      playNewOrderSound();
    }
    const hasSLAWarnings = ordersList.some(o => isSLAWarning(o));
    if (hasSLAWarnings && soundEnabled.value) {
      setTimeout(() => playWarningSound(), 500);
    }
    previousOrdersCount.value = ordersList.length;
    previousOrderIds.value = currentOrderIds;
    orders.value = ordersList;
    if (orders.value.length === 0) {
      }
  } catch (err) {
    error.value = err.message || 'Unable to load order list';
    toast.error(`Error: ${err.message || 'Unable to load orders'}`);
  } finally {
    isLoading.value = false;
  }
}
async function markOrderReady(orderId) {
  if (updatingItems.value.has(`order-${orderId}`)) {
    return;
  }
  updatingItems.value.add(`order-${orderId}`);
  try {
    const result = await OrderService.markOrderReady(orderId);
    toast.success('Order marked as ready');
    await loadKitchenOrders();
  } catch (err) {
    const errorMessage = err.message || 'Error marking order as ready';
    toast.error(errorMessage);
  } finally {
    updatingItems.value.delete(`order-${orderId}`);
  }
}
function isSLAWarning(order) {
  return order.elapsed_minutes >= SLA_WARNING_MINUTES;
}
function formatTime(minutes) {
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`;
}
function formatSpecialInstructions(instructions) {
  if (!instructions) return '';
  try {
    const parsed = typeof instructions === 'string' ? JSON.parse(instructions) : instructions;
    if (Array.isArray(parsed)) {
      return parsed.map(option => {
        if (option.option_name && option.selected_values) {
          const values = Array.isArray(option.selected_values) 
            ? option.selected_values.join(', ') 
            : option.selected_values;
          return `${option.option_name}: ${values}`;
        }
        return '';
      }).filter(Boolean).join(' | ');
    }
    if (typeof parsed === 'object' && parsed.option_name && parsed.selected_values) {
      const values = Array.isArray(parsed.selected_values) 
        ? parsed.selected_values.join(', ') 
        : parsed.selected_values;
      return `${parsed.option_name}: ${values}`;
    }
    return String(instructions);
  } catch (e) {
    return String(instructions);
  }
}
function formatDateTime(dateString) {
  if (!dateString) return '';
  const date = new Date(dateString);
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  return `${hours}:${minutes}`;
}
function formatDate(dateString) {
  if (!dateString) return '';
  const date = new Date(dateString);
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = date.getFullYear();
  return `${day}/${month}/${year}`;
}
function formatCurrency(amount) {
  if (!amount && amount !== 0) return '₫0';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(amount);
}
function clearFilters() {
  filters.value = {
    orderType: 'all',
    timeRange: 'all'
  };
}
onMounted(async () => {
  if (userBranchId) {
    await loadKitchenOrders();
    refreshInterval.value = setInterval(() => {
      loadKitchenOrders();
    }, 10000);
  } else {
    isLoading.value = false;
  }
});
onUnmounted(() => {
  if (refreshInterval.value) {
    clearInterval(refreshInterval.value);
  }
});
function showConfirm(message, callback) {
  confirmMessage.value = message;
  confirmCallback.value = callback;
  showConfirmModal.value = true;
}
function handleConfirm() {
  if (confirmCallback.value) {
    confirmCallback.value();
  }
  closeConfirmModal();
}
function closeConfirmModal() {
  showConfirmModal.value = false;
  confirmMessage.value = '';
  confirmCallback.value = null;
}
function handleLogout() {
  showConfirm('Are you sure you want to logout?', () => {
    AuthService.logout();
    toast.success('Logout successful!');
    router.replace('/auth');
  });
}
</script>
<template>
  <div class="kitchen-dashboard">
    <!-- Statistics and Filters Section -->
    <div class="stats-filters-container">
      <!-- Statistics Section -->
      <div class="stats-section">
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-icon" style="background: #DBEAFE; color: #2563EB;">
              <i class="fas fa-fire"></i>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ filteredOrders.preparing.length }}</div>
              <div class="stat-label">Preparing</div>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon" style="background: #FEE2E2; color: #DC2626;">
              <i class="fas fa-exclamation-triangle"></i>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ filteredOrders.pending.filter(o => isSLAWarning(o)).length + filteredOrders.preparing.filter(o => isSLAWarning(o)).length }}</div>
              <div class="stat-label">Time Warnings</div>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon" style="background: #ECFDF5; color: #10B981;">
              <i class="fas fa-shopping-cart"></i>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ orders.length }}</div>
              <div class="stat-label">Total Orders</div>
            </div>
          </div>
        </div>
      </div>
      <!-- Filters Section -->
      <div v-if="orders.length > 0" class="filters-section">
        <div class="filters-card">
          <div v-if="filters.orderType !== 'all' || filters.timeRange !== 'all'" class="filters-header">
            <button 
              @click="clearFilters" 
              class="btn-clear-filters"
            >
              <i class="fas fa-times"></i>
              Clear Filters
            </button>
          </div>
          <div class="filters-grid">
            <div class="filter-group">
              <label>
                <i class="fas fa-shopping-bag"></i>
                Order Type
              </label>
              <select v-model="filters.orderType" class="filter-select">
                <option value="all">All</option>
                <option value="dine_in">Dine In</option>
                <option value="delivery">Delivery</option>
              </select>
            </div>
            <div class="filter-group">
              <label>
                <i class="fas fa-clock"></i>
                Wait Time
              </label>
              <select v-model="filters.timeRange" class="filter-select">
                <option value="all">All</option>
                <option value="under15">Under 15 minutes</option>
                <option value="15-30">15-30 minutes</option>
                <option value="over30">Over 30 minutes</option>
              </select>
            </div>
            <div class="filter-group">
              <label>
                <i class="fas fa-sort"></i>
                Sort By
              </label>
              <select v-model="sortBy" class="filter-select">
                <option value="time_desc">Oldest First</option>
                <option value="time_asc">Newest First</option>
                <option value="order_id">By Order Number</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div v-if="error" class="error-message">
      <i class="fas fa-exclamation-triangle"></i>
      {{ error }}
    </div>
    <div v-if="isLoading && orders.length === 0" class="loading">
      <LoadingSpinner />
      <p>Loading orders...</p>
    </div>
    <div v-else-if="!userBranchId" class="empty-state">
      <i class="fas fa-exclamation-triangle"></i>
      <h3>No Branch Assigned</h3>
      <p>You have not been assigned to any branch.</p>
      <p>Please contact the administrator to be assigned.</p>
    </div>
    <div v-else-if="orders.length === 0" class="empty-state">
      <i class="fas fa-clipboard-list"></i>
      <h3>No Orders</h3>
      <p>There are currently no orders to process.</p>
    </div>
    <div v-else class="orders-container">
      <!-- Pending Orders -->
      <div v-if="filteredOrders.pending.length > 0" class="orders-section">
        <div class="section-header">
        <h2 class="section-title">
            <i class="fas fa-clock"></i>
            Pending Orders
            <span class="section-badge">{{ filteredOrders.pending.length }}</span>
        </h2>
        </div>
        <div class="orders-grid">
          <div 
            v-for="order in filteredOrders.pending" 
            :key="order.id" 
            class="order-card"
            :class="{ 'sla-warning': isSLAWarning(order) }"
          >
            <!-- Order Header Info Card -->
            <div class="info-card">
              <div class="card-header">
                <i class="fas fa-receipt"></i>
                <h3>Order #{{ order.id }}</h3>
                <span class="status-badge status-pending">Pending</span>
                <span v-if="isSLAWarning(order)" class="priority-badge">
                  <i class="fas fa-exclamation-triangle"></i>
                  Priority
                </span>
              </div>
              <div class="card-content">
                <div class="info-item">
                  <span class="info-label">Order Type</span>
                  <span class="info-value">
                    <i v-if="order.table_id" class="fas fa-table"></i>
                    <i v-else-if="order.order_type === 'delivery'" class="fas fa-truck"></i>
                    <i v-else class="fas fa-shopping-bag"></i>
                    {{ order.table_id ? `Table #${order.table_id}` : (order.order_type === 'delivery' ? 'Delivery' : 'Takeaway') }}
                  </span>
                </div>
                <div class="info-item" v-if="order.customer_name">
                  <span class="info-label">Customer</span>
                  <span class="info-value">
                    <i class="fas fa-user"></i>
                    {{ order.customer_name }}
                  </span>
                </div>
                <div class="info-item" v-if="order.delivery_address">
                  <span class="info-label">Delivery Address</span>
                  <span class="info-value">
                    <i class="fas fa-map-marker-alt"></i>
                    {{ order.delivery_address }}
                  </span>
                </div>
                <div class="info-item">
                  <span class="info-label">Time Elapsed</span>
                  <span class="info-value" :class="{ 'warning-text': isSLAWarning(order) }">
                    <i class="fas fa-clock"></i>
                    {{ formatTime(order.elapsed_minutes) }}
                  </span>
                </div>
                <div class="info-item">
                  <span class="info-label">Created At</span>
                  <span class="info-value">
                    <i class="fas fa-calendar-alt"></i>
                    {{ formatDate(order.created_at) }} {{ formatDateTime(order.created_at) }}
                  </span>
                </div>
              </div>
            </div>
            
            <!-- Order Items Section -->
            <div class="order-items-section">
              <div class="section-header">
                <i class="fas fa-list"></i>
                <h3>Order Items</h3>
              </div>
              <div class="items-list">
                <div 
                  v-for="item in order.items" 
                  :key="item.id"
                  class="order-item"
                >
                  <div class="item-info">
                    <div class="item-image">
                      <img :src="item.product_image || '/default-product.jpg'" :alt="item.product_name" />
                    </div>
                    <div class="item-details">
                      <div class="item-name">{{ item.product_name }}</div>
                      <div class="item-details-row">
                        <span class="item-quantity">Qty: {{ item.quantity }}</span>
                        <span v-if="item.price" class="item-price">@ {{ formatCurrency(item.price) }}</span>
                      </div>
                      <p v-if="item.special_instructions" class="item-note">
                        <i class="fas fa-sticky-note"></i>
                        {{ formatSpecialInstructions(item.special_instructions) }}
                      </p>
                    </div>
                  </div>
                  <div v-if="item.price" class="item-total">
                    {{ formatCurrency(item.price * item.quantity) }}
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Order Footer -->
            <div class="order-footer">
              <div class="order-summary">
                <div class="summary-row">
                  <span class="summary-label">Total Items</span>
                  <span class="summary-value">{{ order.items_count }}</span>
                </div>
                <div v-if="order.total" class="summary-row total-row">
                  <span class="summary-label">Total Amount</span>
                  <span class="summary-value total-amount">{{ formatCurrency(order.total) }}</span>
                </div>
              </div>
              <button 
                @click="markOrderReady(order.id)" 
                class="btn-mark-ready"
                :disabled="updatingItems.has(`order-${order.id}`) || order.status === 'ready'"
                :class="{ 'all-ready': order.status === 'ready' }"
              >
                <i v-if="updatingItems.has(`order-${order.id}`)" class="fas fa-spinner fa-spin"></i>
                <i v-else class="fas fa-check-circle"></i>
                {{ order.status === 'ready' ? 'Ready' : 'Mark as Ready' }}
              </button>
            </div>
          </div>
        </div>
      </div>
      <!-- Preparing Orders -->
      <div v-if="filteredOrders.preparing.length > 0" class="orders-section">
        <div class="section-header">
        <h2 class="section-title">
            <i class="fas fa-fire"></i>
            Preparing
            <span class="section-badge">{{ filteredOrders.preparing.length }}</span>
        </h2>
        </div>
        <div class="orders-grid">
          <div 
            v-for="order in filteredOrders.preparing" 
            :key="order.id" 
            class="order-card"
            :class="{ 'sla-warning': isSLAWarning(order) }"
          >
            <!-- Order Header Info Card -->
            <div class="info-card">
              <div class="card-header">
                <i class="fas fa-receipt"></i>
                <h3>Order #{{ order.id }}</h3>
                <span class="status-badge status-preparing">Preparing</span>
                <span v-if="isSLAWarning(order)" class="priority-badge">
                  <i class="fas fa-exclamation-triangle"></i>
                  Priority
                </span>
              </div>
              <div class="card-content">
                <div class="info-item">
                  <span class="info-label">Order Type</span>
                  <span class="info-value">
                    <i v-if="order.table_id" class="fas fa-table"></i>
                    <i v-else-if="order.order_type === 'delivery'" class="fas fa-truck"></i>
                    <i v-else class="fas fa-shopping-bag"></i>
                    {{ order.table_id ? `Table #${order.table_id}` : (order.order_type === 'delivery' ? 'Delivery' : 'Takeaway') }}
                  </span>
                </div>
                <div class="info-item" v-if="order.customer_name">
                  <span class="info-label">Customer</span>
                  <span class="info-value">
                    <i class="fas fa-user"></i>
                    {{ order.customer_name }}
                  </span>
                </div>
                <div class="info-item" v-if="order.delivery_address">
                  <span class="info-label">Delivery Address</span>
                  <span class="info-value">
                    <i class="fas fa-map-marker-alt"></i>
                    {{ order.delivery_address }}
                  </span>
                </div>
                <div class="info-item">
                  <span class="info-label">Time Elapsed</span>
                  <span class="info-value" :class="{ 'warning-text': isSLAWarning(order) }">
                    <i class="fas fa-clock"></i>
                    {{ formatTime(order.elapsed_minutes) }}
                  </span>
                </div>
                <div class="info-item">
                  <span class="info-label">Created At</span>
                  <span class="info-value">
                    <i class="fas fa-calendar-alt"></i>
                    {{ formatDate(order.created_at) }} {{ formatDateTime(order.created_at) }}
                  </span>
                </div>
              </div>
            </div>
            
            <!-- Order Items Section -->
            <div class="order-items-section">
              <div class="section-header">
                <i class="fas fa-list"></i>
                <h3>Order Items</h3>
              </div>
              <div class="items-list">
                <div 
                  v-for="item in order.items" 
                  :key="item.id"
                  class="order-item"
                >
                  <div class="item-info">
                    <div class="item-image">
                      <img :src="item.product_image || '/default-product.jpg'" :alt="item.product_name" />
                    </div>
                    <div class="item-details">
                      <div class="item-name">{{ item.product_name }}</div>
                      <div class="item-details-row">
                        <span class="item-quantity">Qty: {{ item.quantity }}</span>
                        <span v-if="item.price" class="item-price">@ {{ formatCurrency(item.price) }}</span>
                      </div>
                      <p v-if="item.special_instructions" class="item-note">
                        <i class="fas fa-sticky-note"></i>
                        {{ formatSpecialInstructions(item.special_instructions) }}
                      </p>
                    </div>
                  </div>
                  <div v-if="item.price" class="item-total">
                    {{ formatCurrency(item.price * item.quantity) }}
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Order Footer -->
            <div class="order-footer">
              <div class="order-summary">
                <div class="summary-row">
                  <span class="summary-label">Total Items</span>
                  <span class="summary-value">{{ order.items_count }}</span>
                </div>
                <div v-if="order.total" class="summary-row total-row">
                  <span class="summary-label">Total Amount</span>
                  <span class="summary-value total-amount">{{ formatCurrency(order.total) }}</span>
                </div>
              </div>
              <button 
                @click="markOrderReady(order.id)" 
                class="btn-mark-ready"
                :disabled="updatingItems.has(`order-${order.id}`) || order.status === 'ready'"
                :class="{ 'all-ready': order.status === 'ready' }"
              >
                <i v-if="updatingItems.has(`order-${order.id}`)" class="fas fa-spinner fa-spin"></i>
                <i v-else class="fas fa-check-circle"></i>
                {{ order.status === 'ready' ? 'Ready' : 'Mark as Ready' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Confirmation Modal -->
    <div v-if="showConfirmModal" class="modal-overlay" @click.self="closeConfirmModal">
      <div class="modal-content confirm-modal">
        <div class="modal-header">
          <h3>
            <i class="fas fa-question-circle"></i>
            Confirmation
          </h3>
          <button class="modal-close" @click="closeConfirmModal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="confirm-content">
            <div class="confirm-icon">
              <i class="fas fa-question-circle"></i>
            </div>
            <p class="confirm-message">{{ confirmMessage }}</p>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="closeConfirmModal">
            Cancel
          </button>
          <button class="btn btn-primary" @click="handleConfirm">
            Confirm
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<style scoped>
.kitchen-dashboard {
  background: #F5F7FA;
  min-height: calc(100vh - 124px);
  width: 100%;
  max-width: 100vw;
  box-sizing: border-box;
  overflow-x: hidden;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
  padding: 20px;
}
.stats-filters-container {
  display: grid;
  grid-template-columns: 1fr 1.5fr;
  gap: 20px;
  margin-bottom: 24px;
  align-items: stretch;
}
@media (max-width: 1024px) {
  .stats-filters-container {
    grid-template-columns: 1fr;
  }
}
.stats-section {
  min-width: 0;
  display: flex;
  align-items: stretch;
  height: 100%;
}
.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  width: 100%;
  align-items: stretch;
  height: 100%;
}
@media (max-width: 768px) {
  .stats-grid {
    grid-template-columns: 1fr;
  }
}
.stat-card {
  background: white;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  transition: all 0.2s ease;
  border: 1px solid transparent;
}
.stat-card:hover {
  border-color: #FF8C42;
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);
}
.stat-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  background: #FFF9F5;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  color: #FF8C42;
  flex-shrink: 0;
}
.stat-info {
  flex: 1;
  min-width: 0;
}
.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: #1a1a1a;
  letter-spacing: -0.5px;
  line-height: 1.2;
}
.stat-label {
  font-size: 13px;
  color: #6B7280;
  font-weight: 500;
  margin-top: 4px;
}
.error-message {
  background: #FEE2E2;
  color: #DC2626;
  padding: 12px 16px;
  border-radius: 8px;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 10px;
  border: 1px solid #FCA5A5;
  font-weight: 600;
  font-size: 14px;
}
.loading, .empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
}
.empty-state {
  background: white;
  border-radius: 8px;
  padding: 60px 20px;
  text-align: center;
  border: 1px solid #E2E8F0;
}
.empty-state i {
  font-size: 48px;
  color: #9CA3AF;
  margin-bottom: 16px;
}
.empty-state h3 {
  margin: 0 0 8px 0;
  color: #1a1a1a;
  font-size: 18px;
  font-weight: 700;
}
.empty-state p {
  margin: 8px 0;
  color: #6B7280;
  font-size: 14px;
}
.orders-container {
  display: flex;
  flex-direction: column;
  gap: 24px;
  width: 100%;
  max-width: 100%;
  box-sizing: border-box;
  overflow-x: hidden;
}
.orders-section {
  background: white;
  border-radius: 12px;
  padding: 24px;
  border: 1px solid #E2E8F0;
  margin-bottom: 24px;
  width: 100%;
  max-width: 100%;
  box-sizing: border-box;
  overflow-x: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}
.section-header {
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 1px solid #E2E8F0;
}
.section-title {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0;
  font-size: 18px;
  color: #1E293B;
  font-weight: 700;
  letter-spacing: -0.3px;
}
.section-title i {
  color: #FF8C42;
  font-size: 18px;
}
.section-badge {
  padding: 4px 10px;
  background: #F3F4F6;
  border: 1px solid #E5E7EB;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #6B7280;
  margin-left: auto;
}
.orders-grid {
  display: grid !important;
  grid-template-columns: repeat(2, 1fr) !important;
  grid-auto-rows: auto !important;
  gap: 20px !important;
  width: 100% !important;
  max-width: 100% !important;
  box-sizing: border-box !important;
  overflow-x: hidden !important;
}
@media (max-width: 1024px) {
  .orders-grid {
    grid-template-columns: 1fr !important;
  }
}
.order-card {
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  padding: 0;
  background: white;
  min-width: 0;
  width: 100%;
  max-width: 100%;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  gap: 0;
  overflow: hidden;
}
.order-card.sla-warning {
  border-color: #F59E0B;
  background: #FFF7ED;
}
.info-card {
  background: #FAFBFC;
  border: none;
  border-bottom: 1px solid #E2E8F0;
  border-radius: 0;
  overflow: hidden;
}
.card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.card-header i {
  color: #F59E0B;
  font-size: 14px;
}
.card-header h3 {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  letter-spacing: -0.2px;
  flex: 1;
}
.card-content {
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.info-item .info-label {
  font-size: 12px;
  font-weight: 500;
  color: #64748B;
  letter-spacing: 0;
  text-transform: none;
}
.info-item .info-value {
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  display: flex;
  align-items: center;
  gap: 6px;
}
.info-item .info-value i {
  color: #F59E0B;
  font-size: 12px;
}
.info-item .info-value.warning-text {
  color: #F59E0B;
  font-weight: 700;
}
.status-badge {
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  margin-left: auto;
}
.status-badge.status-pending {
  background: #FEF3C7;
  color: #92400E;
  border: 1px solid #FCD34D;
}
.status-badge.status-preparing {
  background: #DBEAFE;
  color: #1E40AF;
  border: 1px solid #60A5FA;
}
.status-badge.status-ready {
  background: #D1FAE5;
  color: #065F46;
  border: 1px solid #34D399;
}
.btn-mark-ready {
  padding: 10px 20px;
  background: #FF8C42;
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s ease;
  white-space: nowrap;
}
.btn-mark-ready:hover:not(:disabled) {
  background: #E67E22;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(255, 140, 66, 0.3);
}
.btn-mark-ready:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-mark-ready.all-ready {
  background: #10B981;
}
.btn-mark-ready.all-ready:hover:not(:disabled) {
  background: #059669;
  box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
}
.order-items-section {
  margin-bottom: 0;
  background: #FAFBFC;
  border: none;
  border-bottom: 1px solid #E2E8F0;
  border-radius: 0;
  overflow: hidden;
}
.order-items-section .section-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.order-items-section .section-header i {
  color: #F59E0B;
  font-size: 14px;
}
.order-items-section .section-header h3 {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  letter-spacing: -0.2px;
}
.items-list {
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.order-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px;
  background: white;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
}
.item-info {
  flex: 1;
  display: flex;
  gap: 12px;
  align-items: flex-start;
}
.item-image {
  width: 60px;
  height: 60px;
  border-radius: 8px;
  overflow: hidden;
  flex-shrink: 0;
  background: #FFF7ED;
  border: 1px solid #FED7AA;
}
.item-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.item-details {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.item-name {
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  margin: 0;
}
.item-details-row {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 12px;
  color: #64748B;
}
.item-quantity {
  font-weight: 500;
}
.item-price {
  color: #94A3B8;
  font-size: 11px;
}
.item-total {
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
  min-width: 100px;
  text-align: right;
}
.item-note {
  margin: 6px 0 0 0;
  font-size: 12px;
  color: #D97706;
  font-style: italic;
  background: #FFF7ED;
  padding: 6px 10px;
  border-radius: 6px;
  display: inline-block;
  border: 1px solid #FED7AA;
}
.item-note i {
  color: #F59E0B;
  margin-right: 6px;
}
.item-actions {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
}
.status-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
}
.status-badge.status-pending {
  background: #ffc107;
  color: #000;
}
.status-badge.status-preparing {
  background: #0d6efd;
  color: white;
}
.status-badge.status-ready {
  background: #198754;
  color: white;
}
.btn-status {
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s;
}
.btn-start {
  background: #0d6efd;
  color: white;
}
.btn-start:hover:not(:disabled) {
  background: #0a58ca;
}
.btn-ready {
  background: #198754;
  color: white;
}
.btn-ready:hover:not(:disabled) {
  background: #157347;
}
.btn-status:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.status-ready {
  color: #198754;
  font-weight: 600;
}
.order-footer {
  padding: 14px 16px;
  background: #FAFBFC;
  border-top: 1px solid #E2E8F0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.order-summary {
  padding: 0;
  background: transparent;
  border: none;
  border-radius: 0;
  margin-bottom: 0;
}
.summary-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #E2E8F0;
}
.summary-row:last-child {
  border-bottom: none;
}
.summary-label {
  font-size: 13px;
  font-weight: 500;
  color: #64748B;
}
.summary-value {
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
}
.summary-value.total-amount {
  font-size: 16px;
  font-weight: 700;
  color: #FF8C42;
}
.priority-badge {
  padding: 4px 10px;
  background: #FEE2E2;
  color: #DC2626;
  border: 1px solid #FCA5A5;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 4px;
}
.priority-badge i {
  font-size: 10px;
}
.priority-badge {
  padding: 4px 10px;
  background: #FEE2E2;
  color: #DC2626;
  border: 1px solid #FCA5A5;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 4px;
}
.priority-badge i {
  font-size: 10px;
}
.order-footer .btn-mark-ready {
  width: 100%;
  justify-content: center;
}
@media (max-width: 768px) {
  .orders-grid {
    grid-template-columns: 1fr;
  }
}
.filters-section {
  min-width: 0;
  display: flex;
  align-items: stretch;
  height: 100%;
}
.filters-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  overflow-x: hidden;
  max-width: 100%;
  width: 100%;
  display: flex;
  flex-direction: column;
  height: 100%;
  border: 1px solid transparent;
}
.filters-header {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  margin-bottom: 20px;
}
.filters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}
.filter-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.filter-group label {
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
  display: flex;
  align-items: center;
  gap: 6px;
}
.filter-group label i {
  color: #FF8C42;
  font-size: 12px;
}
.filter-select,
.filter-input {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  font-size: 14px;
  background: #FAFAFA;
  color: #1a1a1a;
  font-weight: 500;
  transition: all 0.2s ease;
  box-sizing: border-box;
}
.filter-select:focus,
.filter-input:focus {
  outline: none;
  border-color: #FF8C42;
  background: white;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.btn-clear-filters {
  padding: 8px 16px;
  border: 1px solid #E5E5E5;
  background: white;
  color: #666;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s ease;
}
.btn-clear-filters:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.btn-sound {
  padding: 8px 16px;
  background: white;
  color: #F59E0B;
  border: 1px solid #F59E0B;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  font-size: 13px;
  transition: all 0.2s ease;
}
.btn-sound:hover {
  background: #F59E0B;
  color: white;
}
.btn-sound.disabled {
  background: #f5f5f5;
  color: #999;
  border-color: #ddd;
}
.btn-logout {
  padding: 8px 16px;
  background: #EF4444;
  color: white;
  border: 1px solid #EF4444;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  font-size: 13px;
  transition: all 0.2s ease;
}
.btn-logout:hover {
  background: #DC2626;
  border-color: #DC2626;
  color: white;
}
.order-time {
  margin: 8px 0 0 0;
  font-size: 12px;
  color: #999;
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 500;
}
.order-time i {
  color: #F59E0B;
}
@media (max-width: 1024px) {
  .stats-filters-container {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  .stats-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
  }
}
@media (max-width: 768px) {
  .kitchen-dashboard {
    padding: 10px 12px;
  }
  .stats-filters-container {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
  }
  .stat-card {
    padding: 16px;
  }
  .filters-grid {
    grid-template-columns: 1fr;
  }
  .filter-group {
    width: 100%;
  }
  .btn-clear-filters {
    width: 100%;
    justify-content: center;
  }
  .orders-grid {
    grid-template-columns: 1fr !important;
  }
}
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10000;
  padding: 20px;
}
.modal-content {
  background: white;
  border-radius: 8px;
  border: 1px solid #E2E8F0;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 16px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
  flex-shrink: 0;
}
.modal-header h3 {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
  color: #1a1a1a;
  letter-spacing: -0.2px;
  display: flex;
  align-items: center;
  gap: 8px;
}
.modal-header h3 i {
  color: #F59E0B;
  font-size: 18px;
}
.modal-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #64748B;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}
.modal-close:hover {
  color: #1E293B;
}
.modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 16px;
  background: #FAFBFC;
  border-top: 1px solid #E2E8F0;
  flex-shrink: 0;
}
.confirm-modal {
  max-width: 480px;
  width: 100%;
}
.confirm-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  text-align: center;
}
.confirm-icon {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: #DBEAFE;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #2563EB;
  font-size: 32px;
}
.confirm-message {
  font-size: 14px;
  color: #1E293B;
  line-height: 1.6;
  margin: 0;
}
.btn {
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-secondary {
  background: white;
  color: #64748B;
  border: 1px solid #E2E8F0;
}
.btn-secondary:hover {
  background: #F8F9FA;
  border-color: #CBD5E1;
}
.btn-primary {
  background: #F59E0B;
  color: white;
}
.btn-primary:hover {
  background: #D97706;
}
</style>
