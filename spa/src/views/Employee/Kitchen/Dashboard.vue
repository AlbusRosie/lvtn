<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import OrderService from '@/services/OrderService';
import AuthService from '@/services/AuthService';
import SocketService from '@/services/SocketService';
import { useToast } from 'vue-toastification';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
const router = useRouter();
const toast = useToast();
const orders = ref([]);
const isLoading = ref(true);
const error = ref(null);
const updatingItems = ref(new Set());
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
const showSpecialNoteModal = ref(false);
const specialNoteContent = ref('');
const specialNoteProductName = ref('');
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
    // ✅ SETUP SOCKET.IO LISTENERS
    SocketService.on('new-order', (data) => {
      if (data.branchId === userBranchId) {
        toast.info(`New order #${data.orderId} received!`);
        playNewOrderSound();
        loadKitchenOrders(); // Refresh
      }
    });
    
    SocketService.on('order-status-updated', (data) => {
      if (data.branchId === userBranchId) {
        loadKitchenOrders(); // Refresh
      }
    });
  } else {
    isLoading.value = false;
  }
});
onUnmounted(() => {
  // Clean up socket listeners
  SocketService.off('new-order');
  SocketService.off('order-status-updated');
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
function showSpecialInstructions(instructions, productName) {
  specialNoteContent.value = formatSpecialInstructions(instructions);
  specialNoteProductName.value = productName;
  showSpecialNoteModal.value = true;
}
function closeSpecialNoteModal() {
  showSpecialNoteModal.value = false;
  specialNoteContent.value = '';
  specialNoteProductName.value = '';
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
    <div v-else class="content-area">
      <!-- Pending Orders -->
      <div v-if="filteredOrders.pending.length > 0" class="orders-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>
              <i class="fas fa-clock"></i>
              Pending Orders
            </h3>
            <span class="table-count">{{ filteredOrders.pending.length }} {{ filteredOrders.pending.length === 1 ? 'order' : 'orders' }} pending</span>
          </div>
          <div class="header-actions-wrapper">
            <div class="header-actions">
              <button @click="loadKitchenOrders" class="btn-refresh" :disabled="isLoading">
                <i class="fas fa-sync" :class="{ 'fa-spin': isLoading }"></i>
                Refresh
              </button>
            </div>
          </div>
        </div>
        <div v-if="filteredOrders.pending.length === 0" class="empty-state">
          <i class="fas fa-check-circle"></i>
          <h3>No pending orders</h3>
          <p>All orders are being processed or there are no pending orders.</p>
        </div>
        <div v-else class="orders-grid">
          <div 
            v-for="order in filteredOrders.pending" 
            :key="order.id" 
            class="order-card"
          >
            <div class="order-header">
              <div class="order-header-content">
                <div class="order-title-row">
                  <div class="order-type-badge">
                    <i v-if="order.table_id" class="fas fa-table"></i>
                    <i v-else-if="order.order_type === 'delivery'" class="fas fa-truck"></i>
                    <i v-else class="fas fa-shopping-bag"></i>
                    <span>{{ order.table_id ? `Table #${order.table_id}` : (order.order_type === 'delivery' ? 'Delivery' : 'Takeaway') }}</span>
                  </div>
                  <div v-if="isSLAWarning(order)" class="priority-badge">
                    <i class="fas fa-exclamation-triangle"></i>
                    <span>Priority Order</span>
                  </div>
                </div>
                <div class="order-id-row">
                  <span class="order-id-text">Order #{{ order.id }}</span>
                  <span class="order-time-text" :class="{ 'warning-text': isSLAWarning(order) }">
                    <i class="fas fa-clock"></i>
                    {{ formatTime(order.elapsed_minutes) }}
                  </span>
                </div>
              </div>
            </div>
            <!-- Order Items Section -->
            <div class="order-items-section">
              <div class="section-header">
                <i class="fas fa-shopping-bag"></i>
                <span>Order Items ({{ order.items_count }})</span>
              </div>
              <div class="items-list">
                <div 
                  v-for="item in order.items" 
                  :key="item.id"
                  class="order-item-card"
                >
                  <div class="item-image-wrapper">
                    <img 
                      :src="item.product_image || '/default-product.jpg'" 
                      :alt="item.product_name"
                      class="item-image"
                      @error="$event.target.src='/default-product.jpg'"
                    />
                  </div>
                  <div class="item-content">
                    <div class="item-name-row">
                      <span class="item-name">{{ item.product_name }}</span>
                      <span v-if="item.price" class="item-price">{{ formatCurrency(item.price * item.quantity) }}</span>
                    </div>
                    <div class="item-meta">
                      <span class="item-quantity">x{{ item.quantity }}</span>
                      <span v-if="item.price" class="item-unit-price">{{ formatCurrency(item.price) }}</span>
                    </div>
                    <div 
                      v-if="item.special_instructions" 
                      class="special-note-display"
                    >
                      <i class="fas fa-sticky-note"></i>
                      <span>{{ formatSpecialInstructions(item.special_instructions) }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Order Footer -->
            <div class="order-footer">
              <button 
                @click="markOrderReady(order.id)" 
                class="btn-mark-ready"
                :disabled="updatingItems.has(`order-${order.id}`) || order.status === 'ready'"
                :class="{ 'all-ready': order.status === 'ready' }"
              >
                <i v-if="updatingItems.has(`order-${order.id}`)" class="fas fa-spinner fa-spin"></i>
                <i v-else class="fas fa-check-circle"></i>
                {{ order.status === 'ready' ? 'Order Ready' : 'Mark as Ready' }}
              </button>
            </div>
          </div>
        </div>
      </div>
      <!-- Preparing Orders -->
      <div v-if="filteredOrders.preparing.length > 0" class="orders-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>
              <i class="fas fa-fire"></i>
              Preparing Orders
            </h3>
            <span class="table-count">{{ filteredOrders.preparing.length }} {{ filteredOrders.preparing.length === 1 ? 'order' : 'orders' }} preparing</span>
          </div>
          <div class="header-actions-wrapper">
            <div class="header-actions">
              <button @click="loadKitchenOrders" class="btn-refresh" :disabled="isLoading">
                <i class="fas fa-sync" :class="{ 'fa-spin': isLoading }"></i>
                Refresh
              </button>
            </div>
          </div>
        </div>
        <div v-if="filteredOrders.preparing.length === 0" class="empty-state">
          <i class="fas fa-check-circle"></i>
          <h3>No preparing orders</h3>
          <p>All orders are ready or there are no preparing orders.</p>
        </div>
        <div v-else class="orders-grid">
          <div 
            v-for="order in filteredOrders.preparing" 
            :key="order.id" 
            class="order-card"
          >
            <div class="order-header">
              <div class="order-header-content">
                <div class="order-title-row">
                  <div class="order-type-badge">
                    <i v-if="order.table_id" class="fas fa-table"></i>
                    <i v-else-if="order.order_type === 'delivery'" class="fas fa-truck"></i>
                    <i v-else class="fas fa-shopping-bag"></i>
                    <span>{{ order.table_id ? `Table #${order.table_id}` : (order.order_type === 'delivery' ? 'Delivery' : 'Takeaway') }}</span>
                  </div>
                  <div v-if="isSLAWarning(order)" class="priority-badge">
                    <i class="fas fa-exclamation-triangle"></i>
                    <span>Priority Order</span>
                  </div>
                </div>
                <div class="order-id-row">
                  <span class="order-id-text">Order #{{ order.id }}</span>
                  <span class="order-time-text" :class="{ 'warning-text': isSLAWarning(order) }">
                    <i class="fas fa-clock"></i>
                    {{ formatTime(order.elapsed_minutes) }}
                  </span>
                </div>
              </div>
            </div>
            <div class="order-items-section">
              <div class="section-header">
                <i class="fas fa-shopping-bag"></i>
                <span>Order Items ({{ order.items_count }})</span>
              </div>
              <div class="items-list">
                <div 
                  v-for="item in order.items" 
                  :key="item.id"
                  class="order-item-card"
                >
                  <div class="item-image-wrapper">
                    <img 
                      :src="item.product_image || '/default-product.jpg'" 
                      :alt="item.product_name"
                      class="item-image"
                      @error="$event.target.src='/default-product.jpg'"
                    />
                  </div>
                  <div class="item-content">
                    <div class="item-name-row">
                      <span class="item-name">{{ item.product_name }}</span>
                      <span v-if="item.price" class="item-price">{{ formatCurrency(item.price * item.quantity) }}</span>
                    </div>
                    <div class="item-meta">
                      <span class="item-quantity">x{{ item.quantity }}</span>
                      <span v-if="item.price" class="item-unit-price">{{ formatCurrency(item.price) }}</span>
                    </div>
                    <div 
                      v-if="item.special_instructions" 
                      class="special-note-display"
                    >
                      <i class="fas fa-sticky-note"></i>
                      <span>{{ formatSpecialInstructions(item.special_instructions) }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="order-footer">
              <button 
                @click="markOrderReady(order.id)" 
                class="btn-mark-ready"
                :disabled="updatingItems.has(`order-${order.id}`) || order.status === 'ready'"
                :class="{ 'all-ready': order.status === 'ready' }"
              >
                <i v-if="updatingItems.has(`order-${order.id}`)" class="fas fa-spinner fa-spin"></i>
                <i v-else class="fas fa-check-circle"></i>
                {{ order.status === 'ready' ? 'Order Ready' : 'Mark as Ready' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Special Note Modal -->
    <div v-if="showSpecialNoteModal" class="modal-overlay" @click.self="closeSpecialNoteModal">
      <div class="modal-content special-note-modal">
        <div class="modal-header">
          <h3>
            <i class="fas fa-sticky-note"></i>
            Special Note - {{ specialNoteProductName }}
          </h3>
          <button class="modal-close" @click="closeSpecialNoteModal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="special-note-content">
            <p>{{ specialNoteContent }}</p>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-primary" @click="closeSpecialNoteModal">
            Close
          </button>
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
  text-align: center;
  padding: 60px 20px;
  background: white;
  border-radius: 12px;
  border: 2px dashed #E5E5E5;
  margin-top: 20px;
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
  color: #6B7280;
  margin: 8px 0;
  font-size: 14px;
  font-weight: 500;
}
.content-area {
  min-height: 400px;
}
.orders-card {
  background: #FAFBFC;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #E2E8F0;
  margin-bottom: 20px;
  max-width: 100%;
  box-sizing: border-box;
}
.table-header-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0;
  background: transparent;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 2px solid #E2E8F0;
}
.table-title {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  max-width: 100%;
}
.table-title h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: #1E293B;
  letter-spacing: -0.2px;
  display: flex;
  align-items: center;
  gap: 10px;
}
.table-title h3 i {
  color: #FF8C42;
  font-size: 20px;
}
.table-count {
  padding: 4px 12px;
  background: #F3F4F6;
  border: 1px solid #E5E7EB;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
  margin-left: 12px;
}
.header-actions-wrapper {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}
.header-actions {
  display: flex;
  flex-direction: row;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
  flex-shrink: 0;
  max-width: 100%;
  box-sizing: border-box;
}
.btn-refresh {
  padding: 10px 18px;
  border: none;
  background: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
  border: 1px solid #E2E8F0;
  color: #475569;
}
.btn-refresh:hover:not(:disabled) {
  background: #F8F9FA;
  border-color: #FF8C42;
  color: #FF8C42;
}
.btn-refresh:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.orders-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 16px;
  margin-top: 20px;
}
@media (max-width: 1200px) {
  .orders-grid {
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
    gap: 16px;
  }
}
@media (max-width: 768px) {
  .orders-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }
}
.order-card {
  border: none;
  border-radius: 16px;
  padding: 0;
  background: #FFFFFF;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
  position: relative;
  overflow: hidden;
  margin-bottom: 16px;
  transition: all 0.3s ease;
}
.order-card:hover {
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  transform: translateY(-2px);
}
.order-header {
  padding: 16px;
  background: #FFFFFF;
  border-bottom: 1px solid #F0F0F0;
}
.order-header-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.order-title-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}
.order-type-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 500;
  color: #666666;
}
.order-type-badge i {
  font-size: 14px;
  color: #666666;
}
.status-badge {
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  display: inline-block;
  letter-spacing: 0.2px;
  border: 1px solid;
}
.status-badge.status-pending {
  background: #FEF3C7;
  color: #92400E;
  border-color: #FDE68A;
}
.status-badge.status-preparing {
  background: #DBEAFE;
  color: #1E40AF;
  border-color: #93C5FD;
}
.status-badge.status-ready {
  background: #D1FAE5;
  color: #065F46;
  border-color: #A7F3D0;
}
.order-id-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}
.order-id-text {
  font-size: 12px;
  color: #95A5A6;
  font-weight: 400;
}
.order-time-text {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #95A5A6;
  font-weight: 400;
}
.order-time-text.warning-text {
  color: #DC2626;
  font-weight: 600;
}
.order-time-text i {
  font-size: 11px;
}
.priority-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: #FEE2E2;
  border: 1px solid #FECACA;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  color: #991B1B;
  margin-top: 4px;
}
.priority-badge i {
  font-size: 12px;
  color: #991B1B;
}
.badge {
  padding: 8px 14px;
  border-radius: 10px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.2px;
  display: flex;
  align-items: center;
  gap: 6px;
  white-space: nowrap;
  flex-shrink: 0;
}
.badge-warning {
  background: #FEF3C7;
  color: #B45309;
  border: 1px solid #FCD34D;
  box-shadow: none;
}
.badge-info {
  background: #DBEAFE;
  color: #1E40AF;
  border: 1px solid #60A5FA;
  box-shadow: none;
}
.badge-danger {
  background: #FEE2E2;
  color: #B91C1C;
  border: 1px solid #FCA5A5;
  box-shadow: none;
}
.badge i {
  font-size: 11px;
}
.order-body {
  padding: 16px;
  border-bottom: 1px solid #F0F0F0;
}
.customer-info-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.customer-info-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}
.customer-icon {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: #F5F5F5;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.customer-icon i {
  color: #95A5A6;
  font-size: 18px;
}
.customer-icon.delivery-icon {
  background: #FFF0E6;
}
.customer-icon.delivery-icon i {
  color: #FF8C00;
}
.customer-details {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}
.customer-label {
  font-size: 12px;
  color: #95A5A6;
  font-weight: 400;
}
.customer-name {
  font-size: 14px;
  color: #2D3436;
  font-weight: 500;
  word-break: break-word;
  line-height: 1.4;
}
.amount-value {
  color: #1E293B;
  font-size: 16px;
  font-weight: 600;
}
.btn-mark-ready {
  width: 100%;
  padding: 16px;
  background: #FF8C00;
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(255, 140, 0, 0.3);
}
.btn-mark-ready:hover:not(:disabled) {
  background: #E67E22;
  box-shadow: 0 4px 12px rgba(255, 140, 0, 0.4);
  transform: translateY(-1px);
}
.btn-mark-ready:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}
.btn-mark-ready.all-ready {
  background: #4CAF50;
  box-shadow: 0 2px 8px rgba(76, 175, 80, 0.3);
}
.btn-mark-ready.all-ready:hover:not(:disabled) {
  background: #45A049;
  box-shadow: 0 4px 12px rgba(76, 175, 80, 0.4);
}
.btn-mark-ready i {
  font-size: 16px;
}
.order-items-section {
  padding: 16px;
  background: #FFFFFF;
}
.section-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
  font-size: 16px;
  font-weight: 700;
  color: #2D3436;
}
.section-header i {
  color: #FF8C00;
  font-size: 18px;
  flex-shrink: 0;
}
.items-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.order-item-card {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 0;
}
.item-image-wrapper {
  width: 50px;
  height: 50px;
  border-radius: 12px;
  overflow: hidden;
  flex-shrink: 0;
  background: #F5F5F5;
  display: flex;
  align-items: center;
  justify-content: center;
}
.item-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.item-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 0;
}
.item-name-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}
.item-name {
  font-size: 14px;
  font-weight: 500;
  color: #2D3436;
  line-height: 1.4;
  flex: 1;
}
.item-price {
  font-size: 14px;
  font-weight: 600;
  color: #2D3436;
  white-space: nowrap;
}
.item-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #95A5A6;
}
.item-quantity {
  font-weight: 400;
}
.item-unit-price {
  color: #95A5A6;
  font-size: 12px;
}
.special-note-display {
  margin-top: 8px;
  padding: 8px 12px;
  background: #FFF4E6;
  color: #B45309;
  border: 1px solid #FED7AA;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 400;
  display: flex;
  align-items: flex-start;
  gap: 8px;
  line-height: 1.5;
}
.special-note-display i {
  font-size: 12px;
  color: #B45309;
  margin-top: 2px;
  flex-shrink: 0;
}
.special-note-display span {
  flex: 1;
  word-break: break-word;
}
.special-note-modal {
  max-width: 500px;
  width: 100%;
}
.special-note-content {
  padding: 16px;
  background: #FFF7ED;
  border: 1px solid #FED7AA;
  border-radius: 8px;
  font-size: 14px;
  line-height: 1.6;
  color: #1E293B;
}
.special-note-content p {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
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
  padding: 16px;
  background: #FFFFFF;
  border-top: 1px solid #F0F0F0;
}
@media (max-width: 768px) {
  .orders-grid {
    grid-template-columns: 1fr;
  }
}
.filters-section {
  margin-bottom: 24px;
}
.filters-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: none;
  border: 1px solid #E2E8F0;
  overflow-x: hidden;
  max-width: 100%;
  width: 100%;
  display: flex;
  flex-direction: column;
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
  border-color: #CBD5E1;
  background: #FFFFFF;
  box-shadow: none;
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
  .order-header {
    padding: 12px;
  }
  .order-body {
    padding: 12px;
  }
  .order-items-section {
    padding: 12px;
  }
  .order-footer {
    padding: 12px;
  }
  .order-title-row {
    flex-wrap: wrap;
  }
  .order-id-row {
    flex-wrap: wrap;
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
