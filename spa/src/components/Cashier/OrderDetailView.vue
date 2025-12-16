<template>
  <div class="order-detail-view">
    <div v-if="loading" class="loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Loading...</p>
    </div>
    <div v-else-if="order" class="order-content">
      <!-- Order Header -->
      <div class="order-header-section">
        <div class="order-id-display">
          <i class="fas fa-receipt"></i>
          <h2>Order #{{ order.id }}</h2>
        </div>
        <div class="order-status-badges">
          <span :class="['status-badge', getStatusClass(order.status)]">
            <i :class="getStatusIcon(order.status)"></i>
            {{ getStatusLabel(order.status) }}
          </span>
          <span :class="['payment-status-badge', order.payment_status === 'paid' ? 'paid' : 'unpaid']">
            <i :class="order.payment_status === 'paid' ? 'fas fa-check-circle' : 'fas fa-clock'"></i>
            {{ order.payment_status === 'paid' ? 'Paid' : 'Unpaid' }}
          </span>
        </div>
      </div>
      <!-- Order Info Cards -->
      <div class="order-info-grid">
        <!-- Customer Info Card -->
        <div class="info-card">
          <div class="card-header">
            <i class="fas fa-user"></i>
            <h3>Customer Information</h3>
          </div>
          <div class="card-content">
            <div class="info-item">
              <span class="info-label">Customer Name</span>
              <span class="info-value">{{ order.customer_name || 'Walk-in customer' }}</span>
            </div>
            <div v-if="order.customer_phone" class="info-item">
              <span class="info-label">Phone Number</span>
              <span class="info-value">{{ order.customer_phone }}</span>
            </div>
            <div v-if="order.order_type === 'dine_in' && order.table_id" class="info-item">
              <span class="info-label">Table</span>
              <span class="info-value">#{{ order.table_id }}<span v-if="order.floor_name" class="floor-info"> ({{ order.floor_name }})</span></span>
            </div>
            <div v-else-if="order.order_type === 'dine_in' && !order.table_id" class="info-item">
              <span class="info-label">Table</span>
              <span class="info-value" style="color: #94A3B8; font-style: italic;">Not assigned</span>
            </div>
            <div v-if="order.order_type === 'delivery' && order.delivery_address" class="info-item">
              <span class="info-label">Delivery Address</span>
              <span class="info-value">{{ order.delivery_address }}</span>
            </div>
            <div v-if="order.order_type === 'delivery' && order.delivery_phone" class="info-item">
              <span class="info-label">Delivery Phone</span>
              <span class="info-value">{{ order.delivery_phone }}</span>
            </div>
          </div>
        </div>
        <!-- Order Info Card -->
        <div class="info-card">
          <div class="card-header">
            <i class="fas fa-store"></i>
            <h3>Order Information</h3>
          </div>
          <div class="card-content">
            <div class="info-item">
              <span class="info-label">Order Type</span>
              <span class="info-value">
                <span class="badge small-badge" :class="getOrderTypeBadgeClass(order.order_type)">
                  <i :class="getOrderTypeIcon(order.order_type)"></i>
                  {{ getOrderTypeLabel(order.order_type) }}
                </span>
              </span>
            </div>
            <div v-if="order.branch_name" class="info-item">
              <span class="info-label">Branch</span>
              <span class="info-value">{{ order.branch_name }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">Created Date</span>
              <span class="info-value">{{ formatDate(order.created_at) }}</span>
            </div>
            <div v-if="order.updated_at && order.updated_at !== order.created_at" class="info-item">
              <span class="info-label">Updated Date</span>
              <span class="info-value">{{ formatDate(order.updated_at) }}</span>
            </div>
            <div v-if="order.payment_method" class="info-item">
              <span class="info-label">Payment Method</span>
              <span class="info-value">{{ getPaymentMethodLabel(order.payment_method) }}</span>
            </div>
          </div>
        </div>
      </div>
      <!-- Order Items -->
      <div v-if="order.items && order.items.length > 0" class="order-items-section">
        <div class="section-header">
          <i class="fas fa-utensils"></i>
          <h3>Items List ({{ order.items.length }})</h3>
        </div>
        <div class="items-list">
          <div v-for="(item, index) in order.items" :key="item.id || index" class="order-item">
            <div class="item-info">
              <div class="item-name">{{ item.product_name || item.name || 'N/A' }}</div>
              <div class="item-details">
                <span class="item-quantity">Quantity: {{ item.quantity || 1 }}</span>
                <span class="item-price">{{ formatCurrency(item.price || item.total || 0) }}</span>
              </div>
              <div v-if="getFormattedOptions(item)" class="item-options">
                <i class="fas fa-tags"></i>
                <span>{{ getFormattedOptions(item) }}</span>
              </div>
              <div v-else-if="item.special_instructions && !isJsonString(item.special_instructions)" class="item-notes">
                  <i class="fas fa-sticky-note"></i>
                  {{ item.special_instructions }}
                </div>
              </div>
            <div class="item-total">
              {{ formatCurrency((item.price || item.total || 0) * (item.quantity || 1)) }}
            </div>
          </div>
        </div>
      </div>
      <!-- Order Summary -->
      <div class="order-summary">
          <div class="summary-row">
          <span class="summary-label">Total Items:</span>
          <span class="summary-value">{{ order.items?.length || 0 }}</span>
          </div>
        <div v-if="order.subtotal && order.subtotal !== order.total" class="summary-row">
          <span class="summary-label">Subtotal:</span>
          <span class="summary-value">{{ formatCurrency(order.subtotal) }}</span>
        </div>
        <div v-if="order.discount" class="summary-row">
          <span class="summary-label">Discount:</span>
          <span class="summary-value discount">-{{ formatCurrency(order.discount) }}</span>
          </div>
          <div class="summary-row total-row">
          <span class="summary-label">Total:</span>
          <span class="summary-value total-amount">{{ formatCurrency(order.total) }}</span>
        </div>
      </div>
      <!-- Order Actions Cards -->
      <div class="order-info-grid">
        <!-- Order Status Update Card -->
        <div class="info-card">
          <div class="card-header">
            <i class="fas fa-info-circle"></i>
            <h3>Change Order Status</h3>
          </div>
          <div class="card-content">
            <div class="quick-status-buttons">
              <button 
                v-for="statusOption in statusOptions" 
                :key="statusOption.value"
                @click="updateOrderStatusByButton(statusOption.value)"
                class="btn-quick-status"
                :class="{ 
                  'btn-danger': statusOption.value === 'cancelled',
                  'active': localOrder.status === statusOption.value
                }"
                :disabled="updatingStatus || updatingPayment || isStatusDisabled(statusOption.value, localOrder.status)"
                :title="getStatusButtonTitle(statusOption.value, localOrder.status)"
              >
                {{ statusOption.label }}
              </button>
          </div>
        </div>
      </div>
        <!-- Payment Status Update Card -->
        <div class="info-card">
        <div class="card-header">
            <i class="fas fa-money-bill"></i>
            <h3>Update Payment</h3>
        </div>
          <div class="card-content">
            <div class="payment-status-controls">
              <div class="form-group-inline">
                <label>Payment Status</label>
                <select 
                  v-model="localOrder.payment_status" 
                  @change="updatePaymentStatus"
                  class="form-select"
                  :disabled="updatingPayment"
                >
                  <option value="pending">Pending Payment</option>
                  <option value="paid">Paid</option>
                  <option value="failed">Payment Failed</option>
                </select>
                <span v-if="updatingPayment" class="updating-indicator">
                  <i class="fas fa-spinner fa-spin"></i>
                </span>
              </div>
              <div v-if="localOrder.payment_status === 'paid'" class="form-group-inline">
                <label>Payment Method</label>
                <select 
                  v-model="localOrder.payment_method" 
                  @change="updatePaymentStatus"
                  class="form-select"
                  :disabled="updatingPayment"
                >
                  <option value="cash">Cash</option>
                </select>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div v-if="order.notes" class="info-card">
        <div class="card-header">
          <i class="fas fa-sticky-note"></i>
          <h3>Notes</h3>
        </div>
        <div class="card-content">
          <p class="notes-text">{{ order.notes }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useToast } from 'vue-toastification';
import OrderService from '@/services/OrderService';
const props = defineProps({
  order: {
    type: Object,
    required: true
  }
});
const emit = defineEmits(['updated']);
const toast = useToast();
const loading = ref(false);
const orderDetails = ref(null);
const updatingStatus = ref(false);
const updatingPayment = ref(false);
const localOrder = ref({
  status: props.order.status,
  payment_status: props.order.payment_status,
  payment_method: props.order.payment_method || 'cash'
});
const order = computed(() => {
  return orderDetails.value || props.order;
});
watch(() => props.order, (newOrder) => {
  if (newOrder) {
    localOrder.value = {
      status: newOrder.status,
      payment_status: newOrder.payment_status,
      payment_method: newOrder.payment_method || 'cash'
    };
  }
}, { immediate: true, deep: true });
async function loadOrderDetails() {
  if (!props.order.id) return;
  loading.value = true;
  try {
    const data = await OrderService.getOrderById(props.order.id);
    orderDetails.value = data;
  } catch (error) {
    toast.error('Failed to load order details');
  } finally {
    loading.value = false;
  }
}
  function getPaymentMethodLabel(method) {
    const labels = {
      cash: 'Cash'
    };
    return labels[method] || 'Cash';
  }
function getStatusIcon(status) {
  const icons = {
    pending: 'fas fa-clock',
    preparing: 'fas fa-utensils',
    ready: 'fas fa-check-circle',
    out_for_delivery: 'fas fa-truck',
    completed: 'fas fa-check-double',
    cancelled: 'fas fa-times-circle'
  };
  return icons[status] || 'fas fa-circle';
}
function getOrderTypeIcon(type) {
  const icons = {
    dine_in: 'fas fa-utensils',
    takeaway: 'fas fa-shopping-bag',
    delivery: 'fas fa-truck'
  };
  return icons[type] || 'fas fa-box';
}
async function updateOrderStatus() {
  if (updatingStatus.value || localOrder.value.status === order.value.status) return;
  updatingStatus.value = true;
  try {
    await OrderService.updateOrderStatus(order.value.id, localOrder.value.status);
    toast.success('Order status updated successfully');
    if (orderDetails.value) {
      orderDetails.value.status = localOrder.value.status;
    }
    emit('updated');
  } catch (error) {
    toast.error('Failed to update order status');
    localOrder.value.status = order.value.status;
  } finally {
    updatingStatus.value = false;
  }
}
async function updatePaymentStatus() {
  if (updatingPayment.value) return;
  updatingPayment.value = true;
  try {
    await OrderService.updatePaymentStatus(
      order.value.id, 
      localOrder.value.payment_status,
      localOrder.value.payment_method
    );
    toast.success('Payment status updated successfully');
    if (orderDetails.value) {
      orderDetails.value.payment_status = localOrder.value.payment_status;
      orderDetails.value.payment_method = localOrder.value.payment_method;
    }
    emit('updated');
  } catch (error) {
    toast.error('Failed to update payment status');
    localOrder.value.payment_status = order.value.payment_status;
    localOrder.value.payment_method = order.value.payment_method || 'cash';
  } finally {
    updatingPayment.value = false;
  }
}
function printOrder() {
  }
function formatCurrency(amount) {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(amount);
}
function formatDate(dateString) {
  return new Date(dateString).toLocaleString('vi-VN');
}
  function getStatusLabel(status) {
    const labels = {
      pending: 'Pending',
      preparing: 'Preparing',
      ready: 'Ready',
      out_for_delivery: 'Out for delivery',
      completed: 'Completed',
      cancelled: 'Cancelled'
    };
    return labels[status] || status;
  }
function getStatusClass(status) {
  const classes = {
    pending: 'status-pending',
    preparing: 'status-preparing',
    ready: 'status-ready',
    out_for_delivery: 'status-delivering',
    completed: 'status-completed',
    cancelled: 'status-cancelled'
  };
  return classes[status] || 'status-default';
}
  function getOrderTypeLabel(type) {
    const labels = {
      dine_in: 'Dine-in',
      takeaway: 'Takeaway',
      delivery: 'Delivery'
    };
    return labels[type] || type;
  }
  function getOrderTypeBadgeClass(type) {
    const classes = {
      dine_in: 'badge-primary',
      takeaway: 'badge-warning',
      delivery: 'badge-info'
    };
    return classes[type] || 'badge-info';
  }
function isJsonString(str) {
  if (typeof str !== 'string') return false;
  try {
    const parsed = JSON.parse(str);
    return Array.isArray(parsed) && parsed.length > 0 && parsed[0].option_name;
  } catch (e) {
    return false;
  }
}
function formatItemOptions(options) {
  if (!options) {
    return '';
  }
  if (typeof options === 'string') {
    try {
      options = JSON.parse(options);
    } catch (e) {
      return '';
    }
  }
  if (Array.isArray(options)) {
    return options.map(option => {
      const optionName = option.option_name || '';
      const selectedValues = option.selected_values || [];
      const valuesText = selectedValues.join(', ');
      return optionName + ': ' + valuesText;
    }).join(' | ');
  }
  if (typeof options === 'object') {
    const optionName = options.option_name || '';
    const selectedValues = options.selected_values || [];
    const valuesText = selectedValues.join(', ');
    return optionName + ': ' + valuesText;
  }
  return '';
}
function getFormattedOptions(item) {
  if (!item.special_instructions) return '';
  if (isJsonString(item.special_instructions)) {
    return formatItemOptions(item.special_instructions);
  }
  if (item.options) {
    return formatItemOptions(item.options);
  }
  return '';
}
const statusOptions = computed(() => [
  { value: 'pending', label: 'Pending' },
  { value: 'preparing', label: 'Preparing' },
  { value: 'ready', label: 'Ready' },
  { value: 'out_for_delivery', label: 'Out for delivery' },
  { value: 'completed', label: 'Completed' },
  { value: 'cancelled', label: 'Cancelled' }
]);
const statusOrder = {
  pending: 0,
  preparing: 1,
  ready: 2,
  out_for_delivery: 3,
  completed: 4,
  cancelled: -1
};
function isStatusDisabled(statusValue, currentStatus) {
  if (currentStatus === 'completed' || currentStatus === 'cancelled') {
    return statusValue !== currentStatus;
  }
  const currentOrder = statusOrder[currentStatus] || 0;
  const targetOrder = statusOrder[statusValue] || 0;
  if (statusValue === 'cancelled') {
    return false; 
  }
  return targetOrder < currentOrder;
}
function getStatusButtonTitle(statusValue, currentStatus) {
  if (isStatusDisabled(statusValue, currentStatus)) {
    if (currentStatus === 'completed' || currentStatus === 'cancelled') {
      return 'Cannot change status of completed/cancelled orders';
    }
    return 'Cannot revert to previous status';
  }
  return `Change status to: ${getStatusLabel(statusValue)}`;
}
async function updateOrderStatusByButton(newStatus) {
  if (updatingStatus.value || newStatus === localOrder.value.status) return;
  localOrder.value.status = newStatus;
  await updateOrderStatus();
  }
onMounted(() => {
  if (props.order && props.order.id) {
    if (!props.order.items || props.order.items.length === 0) {
      loadOrderDetails();
    }
  }
});
</script>
<style scoped>
.order-detail-view {
  max-width: 100%;
}
.loading {
  text-align: center;
  padding: 60px 20px;
  color: #6B7280;
}
.loading i {
  font-size: 32px;
  margin-bottom: 16px;
  color: #3B82F6;
}
.loading p {
  margin: 0;
  font-size: 16px;
}
.order-content {
  display: flex;
  flex-direction: column;
  gap: 0;
}
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  border: 1px solid;
}
.status-pending {
  background: #FFF3CD;
  color: #856404;
  border-color: #FFE69C;
}
.status-preparing {
  background: #D1ECF1;
  color: #0C5460;
  border-color: #BEE5EB;
}
.status-ready {
  background: #D4EDDA;
  color: #155724;
  border-color: #C3E6CB;
}
.status-completed {
  background: #D4EDDA;
  color: #155724;
  border-color: #C3E6CB;
}
.status-cancelled {
  background: #F8D7DA;
  color: #721C24;
  border-color: #F5C6CB;
}
.status-delivering {
  background: #E0E7FF;
  color: #6366F1;
  border-color: #A5B4FC;
}
.order-info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}
.info-card {
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
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
.small-badge {
  padding: 4px 10px;
  font-size: 11px;
  border-radius: 6px;
  font-weight: 600;
}
.badge-primary {
  background: #DBEAFE;
  color: #1E40AF;
  border: 1px solid #BFDBFE;
}
.badge-info {
  background: #D1FAE5;
  color: #065F46;
  border: 1px solid #A7F3D0;
}
.badge-warning {
  background: #FEF3C7;
  color: #92400E;
  border: 1px solid #FDE68A;
}
.order-header-section {
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  padding: 16px 20px;
  margin-bottom: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
}
.order-id-display {
  display: flex;
  align-items: center;
  gap: 12px;
}
.order-id-display i {
  color: #F59E0B;
  font-size: 24px;
}
.order-id-display h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
  color: #1E293B;
  letter-spacing: -0.3px;
}
.order-status-badges {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}
.floor-info {
  color: #94A3B8;
  font-size: 12px;
  font-weight: normal;
  margin-left: 4px;
}
.badge i {
  margin-right: 4px;
  font-size: 10px;
}
.payment-status-controls {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.form-group-inline {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.form-group-inline label {
  font-size: 12px;
  font-weight: 500;
  color: #64748B;
}
.form-group-inline .form-select {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  color: #1E293B;
  font-weight: 500;
  transition: all 0.2s ease;
}
.form-group-inline .form-select:focus {
  outline: none;
  border-color: #F59E0B;
}
.form-select {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  color: #1E293B;
  font-weight: 500;
  transition: all 0.2s ease;
  cursor: pointer;
}
.form-select:focus {
  outline: none;
  border-color: #F59E0B;
}
.form-select:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.form-group-inline .form-select:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.payment-status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 16px;
  font-size: 13px;
  font-weight: 600;
}
.payment-status-badge.paid {
  background: #D1FAE5;
  color: #065F46;
}
.payment-status-badge.unpaid {
  background: #FEF3C7;
  color: #92400E;
}
.info-value-group {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
}
.updating-indicator {
  color: #F59E0B;
  font-size: 14px;
}
.order-items-section {
  margin-bottom: 20px;
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  overflow: hidden;
}
.section-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.section-header i {
  color: #F59E0B;
  font-size: 14px;
}
.section-header h3 {
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
  flex-direction: column;
  gap: 6px;
}
.item-name {
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
}
.item-details {
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
}
.item-options {
  display: flex;
  align-items: flex-start;
  gap: 6px;
  font-size: 11px;
  color: #475569;
  margin-top: 4px;
  padding: 4px 8px;
  background: #F8F9FA;
  border-radius: 4px;
  border-left: 2px solid #F59E0B;
}
.item-options i {
  font-size: 10px;
  color: #F59E0B;
  margin-top: 2px;
  flex-shrink: 0;
}
.item-options span {
  line-height: 1.4;
}
.item-notes {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: #64748B;
  font-style: italic;
  margin-top: 2px;
}
.item-notes i {
  font-size: 10px;
}
.item-total {
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
  min-width: 100px;
  text-align: right;
}
.order-summary {
  padding: 14px 16px;
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  margin-bottom: 20px;
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
.summary-row.total-row {
  padding-top: 12px;
  margin-top: 8px;
  border-top: 1px solid #E2E8F0;
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
  color: #1E293B;
}
.summary-value.discount {
  color: #059669;
}
.notes-text {
  margin: 0;
  color: #475569;
  font-size: 13px;
  line-height: 1.6;
}
.quick-status-buttons {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  align-items: stretch;
}
.btn-quick-status {
  padding: 10px 16px;
  border: 1px solid #86EFAC;
  background: white;
  color: #16A34A;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
  min-width: 120px;
  text-align: center;
  flex: 1;
  box-sizing: border-box;
}
.btn-quick-status:hover:not(:disabled) {
  background: #F0FDF4;
  border-color: #4ADE80;
  color: #15803D;
}
.btn-quick-status:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-quick-status.active {
  background: #16A34A;
  border-color: #16A34A;
  color: white;
  font-weight: 600;
}
.btn-quick-status.btn-danger {
  color: #DC2626;
  border-color: #FCA5A5;
  background: white;
}
.btn-quick-status.btn-danger:hover:not(:disabled) {
  background: #FEF2F2;
  border-color: #F87171;
  color: #B91C1C;
}
.btn-quick-status.btn-danger.active {
  background: #DC2626;
  border-color: #DC2626;
  color: white;
}
@media (max-width: 768px) {
  .order-info-grid {
    grid-template-columns: 1fr;
  }
  .order-item {
    flex-wrap: wrap;
  }
  .item-total {
    width: 100%;
    text-align: left;
    margin-top: 8px;
  }
}
</style>
