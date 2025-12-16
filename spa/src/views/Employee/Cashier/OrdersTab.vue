<template>
    <div class="orders-tab">
      <!-- Overdue Reservations Warning Banner -->
      <div v-if="activeOrderTypeTab === 'reservation' && overdueReservations.length > 0" class="overdue-warning-banner">
        <div class="warning-content">
          <i class="fas fa-exclamation-triangle"></i>
          <div class="warning-text">
            <strong>Warning: {{ overdueReservations.length }} overdue reservations not arrived</strong>
            <ul class="overdue-list">
              <li v-for="res in overdueReservations.slice(0, 3)" :key="res.id">
                Table #{{ res.table_id || 'N/A' }} ({{ res.floor_name }}) - {{ res.branch_name }} - 
                {{ formatDate(res.reservation_date) }} {{ res.reservation_time }} 
                <span v-if="res.minutes_overdue" class="minutes-overdue">
                  ({{ Math.floor(res.minutes_overdue) }} minutes overdue)
                </span>
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div class="orders-box">
        <!-- Order Type Tabs -->
        <div class="order-type-tabs">
          <button 
            :class="['order-type-tab-btn', { active: activeOrderTypeTab === 'dine_in' }]"
            @click="activeOrderTypeTab = 'dine_in'"
          >
            <i class="fas fa-utensils"></i> Dine-in
            <span v-if="dineInOrdersCount > 0" class="tab-badge">{{ dineInOrdersCount }}</span>
          </button>
          <button 
            :class="['order-type-tab-btn', { active: activeOrderTypeTab === 'delivery' }]"
            @click="activeOrderTypeTab = 'delivery'"
          >
            <i class="fas fa-truck"></i> Delivery
            <span v-if="deliveryOrdersCount > 0" class="tab-badge">{{ deliveryOrdersCount }}</span>
          </button>
          <button 
            :class="['order-type-tab-btn', { active: activeOrderTypeTab === 'takeaway' }]"
            @click="activeOrderTypeTab = 'takeaway'"
          >
            <i class="fas fa-shopping-bag"></i> Takeaway
            <span v-if="takeawayOrdersCount > 0" class="tab-badge">{{ takeawayOrdersCount }}</span>
          </button>
          <button 
            :class="['order-type-tab-btn', { active: activeOrderTypeTab === 'reservation' }]"
            @click="activeOrderTypeTab = 'reservation'"
          >
            <i class="fas fa-calendar-check"></i> Reservations
            <span v-if="reservationsCount > 0" class="tab-badge">{{ reservationsCount }}</span>
          </button>
        </div>
        <!-- Search and Filter -->
        <div class="search-filter-section">
          <div class="search-bar">
            <i class="fas fa-search"></i>
            <input 
              v-model="orderFilters.search" 
              type="text" 
              placeholder="Search orders..."
            />
          </div>
          <select v-model="orderFilters.status" class="filter-select">
            <option value="">All statuses</option>
            <option value="pending">Pending</option>
            <option value="preparing">Preparing</option>
            <option value="ready">Ready</option>
            <option value="completed">Completed</option>
            <option value="cancelled">Cancelled</option>
          </select>
          <select v-model="orderFilters.payment_status" class="filter-select">
            <option value="">All payments</option>
            <option value="pending">Unpaid</option>
            <option value="paid">Paid</option>
          </select>
          <button class="btn-clear-filters" @click="clearOrderFilters">
            <i class="fas fa-times"></i> Clear filters
          </button>
          <button class="btn btn-secondary" @click="showExportModal = true">
            <i class="fas fa-file-excel"></i> Export Excel
          </button>
        </div>
        <!-- Orders/Reservations List -->
        <div class="orders-list">
          <!-- Loading State -->
          <div v-if="(activeOrderTypeTab !== 'reservation' && ordersLoading) || (activeOrderTypeTab === 'reservation' && reservationsLoading)" class="loading-state">
            <i class="fas fa-spinner fa-spin"></i>
            <p>Loading...</p>
          </div>
          <!-- Empty State for Orders -->
          <div v-else-if="activeOrderTypeTab !== 'reservation' && filteredOrders.length === 0" class="empty-state">
            <i class="fas fa-inbox"></i>
            <p>No orders</p>
          </div>
          <!-- Empty State for Reservations -->
          <div v-else-if="activeOrderTypeTab === 'reservation' && filteredReservations.length === 0" class="empty-state">
            <i class="fas fa-calendar"></i>
            <p>No reservations</p>
          </div>
          <!-- Orders Grid -->
          <div v-else-if="activeOrderTypeTab !== 'reservation'" class="orders-grid">
            <div 
              v-for="order in filteredOrders" 
              :key="order.id"
              class="order-card"
              @click="viewOrder(order)"
            >
              <div class="order-header">
                <span class="order-id">#{{ order.id }}</span>
                <span :class="['status-badge', getStatusClass(order.status)]">
                  {{ getStatusLabel(order.status) }}
                </span>
              </div>
              <div class="order-info">
                <p><i class="fas fa-user"></i> {{ order.customer_name || 'Walk-in customer' }}</p>
                <p v-if="order.order_type === 'dine_in' && order.table_id">
                  <i class="fas fa-table"></i> Table #{{ order.table_id }}
                  <span v-if="order.floor_name" class="floor-info">({{ order.floor_name }})</span>
                </p>
                <p v-else-if="order.order_type === 'delivery' && order.delivery_address">
                  <i class="fas fa-map-marker-alt"></i> {{ order.delivery_address }}
                </p>
                <p v-else-if="order.order_type === 'takeaway'">
                  <i class="fas fa-shopping-bag"></i> Takeaway order
                </p>
                <p><i class="fas fa-calendar"></i> {{ formatDate(order.created_at) }}</p>
                <p><i class="fas fa-money-bill"></i> {{ formatCurrency(order.total) }}</p>
                <p :class="['payment-status', order.payment_status === 'paid' ? 'paid' : 'unpaid']">
                  <i :class="order.payment_status === 'paid' ? 'fas fa-check-circle' : 'fas fa-clock'"></i>
                  {{ order.payment_status === 'paid' ? 'Paid' : 'Unpaid' }}
                </p>
              </div>
              <div class="order-actions">
                <button class="btn btn-sm btn-primary" @click.stop="viewOrder(order)">
                  <i class="fas fa-eye"></i> View details
                </button>
                <button 
                  v-if="order.status !== 'completed' && order.status !== 'cancelled'"
                  class="btn btn-sm btn-success" 
                  @click.stop="quickCompleteOrder(order)"
                  :disabled="updatingOrderId === order.id"
                >
                  <i v-if="updatingOrderId === order.id" class="fas fa-spinner fa-spin"></i>
                  <i v-else class="fas fa-check-circle"></i>
                  Complete
                </button>
                <button 
                  v-if="order.payment_status === 'paid'"
                  class="btn btn-sm btn-secondary" 
                  @click.stop="printInvoice(order)"
                >
                  <i class="fas fa-print"></i> Print invoice
                </button>
              </div>
            </div>
          </div>
          <!-- Reservations Grid -->
          <div v-else-if="activeOrderTypeTab === 'reservation'" class="orders-grid">
            <div 
              v-for="reservation in filteredReservations" 
              :key="reservation.id"
              :class="['order-card', { 'overdue-warning': isOverdueReservation(reservation) }]"
              @click="viewReservation(reservation)"
            >
              <div class="order-header">
                <span class="order-id">#{{ reservation.id }}</span>
                <span :class="['status-badge', getReservationStatusClass(reservation.status)]">
                  {{ getReservationStatusLabel(reservation.status) }}
                </span>
                <span v-if="isOverdueReservation(reservation)" class="overdue-badge">
                  <i class="fas fa-exclamation-triangle"></i> Overdue
                </span>
              </div>
              <div class="order-info">
                <p><i class="fas fa-user"></i> {{ reservation.customer_name || 'Walk-in customer' }}</p>
                <p v-if="reservation.table_id">
                  <i class="fas fa-table"></i> Table #{{ reservation.table_id }}
                  <span v-if="reservation.floor_name" class="floor-info">({{ reservation.floor_name }})</span>
                </p>
                <p><i class="fas fa-calendar"></i> {{ formatDate(reservation.reservation_date) }} {{ reservation.reservation_time }}</p>
                <p v-if="reservation.guest_count">
                  <i class="fas fa-users"></i> {{ reservation.guest_count }} guests
                </p>
                <p v-if="reservation.order_id">
                  <i class="fas fa-shopping-cart"></i> Has order (Order #{{ reservation.order_id }})
                </p>
                <p v-else>
                  <i class="fas fa-utensils"></i> Table only
                </p>
              </div>
              <div class="order-actions">
                <button class="btn btn-sm btn-primary" @click.stop="viewReservation(reservation)">
                  <i class="fas fa-eye"></i> View
                </button>
                <button 
                  v-if="reservation.status === 'confirmed' || reservation.status === 'pending'"
                  class="btn btn-sm btn-success" 
                  @click.stop="checkInReservation(reservation)"
                >
                  <i class="fas fa-check"></i> Check-in
                </button>
                <button 
                  v-if="reservation.status !== 'cancelled' && reservation.status !== 'completed'"
                  class="btn btn-sm btn-danger" 
                  @click.stop="cancelReservation(reservation)"
                >
                  <i class="fas fa-times"></i> Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Order Detail Modal -->
      <div v-if="selectedOrder" class="modal-overlay" @click="selectedOrder = null">
        <div class="modal-content large" @click.stop>
          <div class="modal-header">
            <h3>Order details #{{ selectedOrder.id }}</h3>
            <button class="modal-close" @click="selectedOrder = null">
              <i class="fas fa-times"></i>
            </button>
          </div>
          <div class="modal-body">
            <OrderDetailView 
              :order="selectedOrder"
              @updated="handleOrderUpdated"
            />
          </div>
        </div>
      </div>
      <!-- Invoice Print Modal -->
      <div v-if="invoiceToPrint" class="modal-overlay" @click="invoiceToPrint = null">
        <div class="modal-content large" @click.stop>
          <div class="modal-header">
            <h3>Invoice #{{ invoiceToPrint?.id }}</h3>
            <div class="header-actions">
              <button class="btn btn-secondary" @click="printInvoice(invoiceToPrint)">
                <i class="fas fa-print"></i> Print
              </button>
              <button class="modal-close" @click="invoiceToPrint = null">
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>
          <div class="modal-body">
            <InvoiceView :invoice="invoiceToPrint" />
          </div>
        </div>
      </div>
      <!-- Reservation Detail Modal -->
      <div v-if="selectedReservation" class="modal-overlay" @click="selectedReservation = null">
        <div class="modal-content large" @click.stop>
          <div class="modal-header">
            <h3>Reservation details #{{ selectedReservation.id }}</h3>
            <button class="modal-close" @click="selectedReservation = null">
              <i class="fas fa-times"></i>
            </button>
          </div>
          <div class="modal-body">
            <div class="reservation-detail">
              <div class="reservation-info-section">
                <h4>Reservation information</h4>
                <div class="info-grid">
                  <div class="info-item">
                    <strong>Customer:</strong>
                    <span>{{ selectedReservation.customer_name || selectedReservation.user_name || 'Walk-in customer' }}</span>
                  </div>
                  <div class="info-item" v-if="selectedReservation.customer_phone || selectedReservation.user_email">
                    <strong>Contact:</strong>
                    <span>{{ selectedReservation.customer_phone || selectedReservation.user_email }}</span>
                  </div>
                  <div class="info-item" v-if="selectedReservation.table_id">
                    <strong>Table:</strong>
                    <span>Table #{{ selectedReservation.table_id }}
                      <span v-if="selectedReservation.floor_name" class="floor-info">({{ selectedReservation.floor_name }})</span>
                    </span>
                  </div>
                  <div class="info-item">
                    <strong>Reservation date:</strong>
                    <span>{{ formatDate(selectedReservation.reservation_date) }} {{ selectedReservation.reservation_time }}</span>
                  </div>
                  <div class="info-item" v-if="selectedReservation.guest_count">
                    <strong>Guests:</strong>
                    <span>{{ selectedReservation.guest_count }} guests</span>
                  </div>
                  <div class="info-item">
                    <strong>Status:</strong>
                    <span :class="['status-badge', getReservationStatusClass(selectedReservation.status)]">
                      {{ getReservationStatusLabel(selectedReservation.status) }}
                    </span>
                  </div>
                  <div class="info-item" v-if="selectedReservation.special_requests">
                    <strong>Notes:</strong>
                    <span>{{ selectedReservation.special_requests }}</span>
                  </div>
                </div>
              </div>
              <!-- Order Details if exists -->
              <div v-if="selectedReservation.order_id || selectedReservationOrder" class="reservation-order-section">
                <h4>Related order</h4>
                <div v-if="selectedReservationOrder" class="order-detail-wrapper">
                  <OrderDetailView 
                    :order="selectedReservationOrder"
                  />
                </div>
                <div v-else-if="selectedReservation.order_id" class="loading-order">
                  <i class="fas fa-spinner fa-spin"></i>
                  <p>Loading order details...</p>
                </div>
                <div v-else class="no-order">
                  <p>No order for this reservation yet</p>
                </div>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-secondary" @click="selectedReservation = null">
              Close
            </button>
            <button 
              v-if="selectedReservation.status === 'confirmed' || selectedReservation.status === 'pending'"
              class="btn btn-success" 
              @click="checkInReservation(selectedReservation)"
            >
              <i class="fas fa-check"></i> Check-in
            </button>
            <button 
              v-if="selectedReservation.status !== 'cancelled' && selectedReservation.status !== 'completed'"
              class="btn btn-danger" 
              @click="cancelReservation(selectedReservation)"
            >
              <i class="fas fa-times"></i> Cancel reservation
            </button>
          </div>
        </div>
      </div>
      <!-- Export Excel Modal -->
      <div v-if="showExportModal" class="modal-overlay" @click="showExportModal = false">
        <div class="modal-content" @click.stop>
          <div class="modal-header">
            <h3><i class="fas fa-file-excel"></i> Export Excel</h3>
            <button class="modal-close" @click="showExportModal = false">
              <i class="fas fa-times"></i>
            </button>
          </div>
          <div class="modal-body">
            <div class="export-form">
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">From date</label>
                  <input 
                    v-model="exportFilters.dateFrom" 
                    type="date" 
                    class="form-input"
                  />
                </div>
                <div class="form-group">
                  <label class="form-label">To date</label>
                  <input 
                    v-model="exportFilters.dateTo" 
                    type="date" 
                    class="form-input"
                  />
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">Status</label>
                  <select v-model="exportFilters.status" class="form-select">
                    <option value="">All statuses</option>
                    <option value="pending">Pending</option>
                    <option value="preparing">Preparing</option>
                    <option value="ready">Ready</option>
                    <option value="completed">Completed</option>
                    <option value="cancelled">Cancelled</option>
                  </select>
                </div>
                <div class="form-group">
                  <label class="form-label">Payment status</label>
                  <select v-model="exportFilters.paymentStatus" class="form-select">
                    <option value="">All payments</option>
                    <option value="pending">Unpaid</option>
                    <option value="paid">Paid</option>
                  </select>
                </div>
              </div>
              <div class="form-group">
                <label class="form-label">Search</label>
                <input 
                  v-model="exportFilters.search" 
                  type="text" 
                  placeholder="Search by order ID, customer name..."
                  class="form-input"
                />
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-secondary" @click="showExportModal = false">
              Cancel
            </button>
            <button class="btn btn-primary" @click="handleExportOrders">
              <i class="fas fa-file-excel"></i> Export Excel
            </button>
          </div>
        </div>
      </div>
    </div>
    <!-- Error Modal -->
    <div v-if="showErrorModal" class="modal-overlay" @click.self="closeErrorModal">
      <div class="modal-content error-modal">
        <div class="modal-header">
          <h3>
            <i class="fas fa-exclamation-circle"></i>
            Error
          </h3>
          <button class="modal-close" @click="closeErrorModal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="error-content">
            <div class="error-icon">
              <i class="fas fa-exclamation-triangle"></i>
            </div>
            <p class="error-message">{{ formattedErrorMessage }}</p>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-primary" @click="closeErrorModal">
            OK
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
  </template>
  <script setup>
  import { ref, reactive, computed, onMounted, onUnmounted, watch } from 'vue';
  import { useToast } from 'vue-toastification';
  import AuthService from '@/services/AuthService';
  import OrderService from '@/services/OrderService';
  import ReservationService from '@/services/ReservationService';
  import SocketService from '@/services/SocketService';
  import OrderDetailView from '@/components/Cashier/OrderDetailView.vue';
  import InvoiceView from '@/components/Cashier/InvoiceView.vue';
  const toast = useToast();
  const orders = ref([]);
  const ordersLoading = ref(false);
  const activeOrderTypeTab = ref('dine_in'); 
  const orderFilters = reactive({
    status: '',
    payment_status: '',
    search: ''
  });
  const filteredOrders = computed(() => {
    let result = orders.value;
    if (activeOrderTypeTab.value === 'dine_in') {
      result = result.filter(o => o.order_type === 'dine_in');
    } else if (activeOrderTypeTab.value === 'delivery') {
      result = result.filter(o => o.order_type === 'delivery');
    } else if (activeOrderTypeTab.value === 'takeaway') {
      result = result.filter(o => o.order_type === 'takeaway');
    }
    else if (activeOrderTypeTab.value === 'reservation') {
      return [];
    }
    if (orderFilters.status) {
      result = result.filter(o => o.status === orderFilters.status);
    }
    if (orderFilters.payment_status) {
      result = result.filter(o => o.payment_status === orderFilters.payment_status);
    }
    if (orderFilters.search) {
      const search = orderFilters.search.toLowerCase();
      result = result.filter(o => 
        o.id.toString().includes(search) ||
        (o.customer_name && o.customer_name.toLowerCase().includes(search))
      );
    }
    return result;
  });
  const dineInOrdersCount = computed(() => {
    return orders.value.filter(o => o.order_type === 'dine_in').length;
  });
  const deliveryOrdersCount = computed(() => {
    return orders.value.filter(o => o.order_type === 'delivery').length;
  });
  const takeawayOrdersCount = computed(() => {
    return orders.value.filter(o => o.order_type === 'takeaway').length;
  });
  const reservations = ref([]);
  const reservationsLoading = ref(false);
  const overdueReservations = ref([]);
  const overdueReservationsLoading = ref(false);
  const reservationFilters = reactive({
    status: '',
    date: ''
  });
  const filteredReservations = computed(() => {
    let result = reservations.value;
    if (reservationFilters.status) {
      result = result.filter(r => r.status === reservationFilters.status);
    }
    if (reservationFilters.date) {
      result = result.filter(r => r.reservation_date === reservationFilters.date);
    }
    if (orderFilters.search && activeOrderTypeTab.value === 'reservation') {
      const search = orderFilters.search.toLowerCase();
      result = result.filter(r => 
        r.id.toString().includes(search) ||
        (r.customer_name && r.customer_name.toLowerCase().includes(search)) ||
        (r.customer_phone && r.customer_phone.includes(search))
      );
    }
    return result;
  });
  const reservationsCount = computed(() => {
    return reservations.value.length;
  });
  const selectedOrder = ref(null);
  const selectedReservation = ref(null);
  const selectedReservationOrder = ref(null);
  const invoiceToPrint = ref(null);
  const showExportModal = ref(false);
  const updatingOrderId = ref(null);
  const showErrorModal = ref(false);
  const formattedErrorMessage = ref('');
  const showConfirmModal = ref(false);
  const confirmMessage = ref('');
  const confirmCallback = ref(null);
  const exportFilters = reactive({
    dateFrom: '',
    dateTo: '',
    status: '',
    paymentStatus: '',
    search: ''
  });
  function getCurrentBranchId() {
    try {
      const user = AuthService.getUser();
      if (!user) {
        return null;
      }
      return user.branch_id || null;
    } catch (error) {
      return null;
    }
  }
  async function loadOrders() {
    ordersLoading.value = true;
    try {
      const id = getCurrentBranchId();
      if (!id) {
        orders.value = [];
        ordersLoading.value = false;
        return;
      }
      const branchIdNum = parseInt(id);
      if (isNaN(branchIdNum)) {
        orders.value = [];
        ordersLoading.value = false;
        return;
      }
      const data = await OrderService.getOrdersByBranch(branchIdNum, { 
        page: 1, 
        limit: 100
      });
      let ordersList = [];
      if (data && data.orders && Array.isArray(data.orders)) {
        ordersList = data.orders;
      } else if (data && data.items && Array.isArray(data.items)) {
        ordersList = data.items;
      } else if (data && data.data && data.data.orders && Array.isArray(data.data.orders)) {
        ordersList = data.data.orders;
      } else if (data && data.data && Array.isArray(data.data)) {
        ordersList = data.data;
      } else if (data && Array.isArray(data)) {
        ordersList = data;
      } else {
        ordersList = [];
      }
      if (branchIdNum && ordersList.length > 0) {
        ordersList = ordersList.filter(order => {
          const orderBranchId = order.branch_id ? parseInt(order.branch_id) : null;
          return orderBranchId === branchIdNum;
        });
      }
      orders.value = ordersList;
    } catch (error) {
      showError(error);
      orders.value = [];
    } finally {
      ordersLoading.value = false;
    }
  }
  function clearOrderFilters() {
    orderFilters.status = '';
    orderFilters.payment_status = '';
    orderFilters.search = '';
  }
  async function loadOverdueReservations() {
    overdueReservationsLoading.value = true;
    try {
      const branchId = getCurrentBranchId();
      if (!branchId) {
        overdueReservations.value = [];
        overdueReservationsLoading.value = false;
        return;
      }
      const data = await ReservationService.getReservationsNeedingWarning();
      const reservationsList = data?.reservations || data?.data?.reservations || data || [];
      const branchIdNum = parseInt(branchId);
      if (branchIdNum && reservationsList.length > 0) {
        overdueReservations.value = reservationsList.filter(res => {
          const resBranchId = res.branch_id ? parseInt(res.branch_id) : null;
          return resBranchId === branchIdNum;
        });
      } else {
        overdueReservations.value = reservationsList;
      }
    } catch (error) {
      overdueReservations.value = [];
    } finally {
      overdueReservationsLoading.value = false;
    }
  }
  async function loadReservations() {
    reservationsLoading.value = true;
    try {
      const branchId = getCurrentBranchId();
      if (!branchId) {
        reservations.value = [];
        reservationsLoading.value = false;
        return;
      }
      const data = await ReservationService.getAllReservations({ 
        page: 1, 
        limit: 100,
        branch_id: branchId
      });
      reservations.value = data.reservations || data.items || data.data || [];
    } catch (error) {
      toast.error('Failed to load reservations');
    } finally {
      reservationsLoading.value = false;
    }
  }
  watch(() => activeOrderTypeTab.value, (newTab) => {
    if (newTab === 'reservation') {
      loadReservations();
      loadOverdueReservations();
    }
  });
  async function viewOrder(order) {
    try {
      if (!order.items || order.items.length === 0) {
        const orderData = await OrderService.getOrderById(order.id);
        selectedOrder.value = orderData;
      } else {
        selectedOrder.value = order;
      }
    } catch (error) {
      showError(error);
      selectedOrder.value = order;
    }
  }
  async function viewReservation(reservation) {
    selectedReservation.value = reservation;
    selectedReservationOrder.value = null;
    if (reservation.order_id) {
      try {
        const orderData = await OrderService.getOrderById(reservation.order_id);
        selectedReservationOrder.value = orderData;
      } catch (error) {
      }
    }
  }
  const checkInReservation = async (reservation) => {
    try {
      await ReservationService.updateReservation(reservation.id, {
        status: 'checked_in'
      });
      toast.success('Check-in successful');
      await loadReservations();
      if (selectedReservation.value && selectedReservation.value.id === reservation.id) {
        selectedReservation.value.status = 'checked_in';
      }
    } catch (error) {
      showError(error);
    }
  };
  const cancelReservation = async (reservation) => {
    showConfirm(`Are you sure you want to cancel reservation #${reservation.id}?`, async () => {
      try {
        await ReservationService.updateReservation(reservation.id, {
          status: 'cancelled'
        });
        toast.success('Reservation cancelled successfully');
        await loadReservations();
        selectedReservation.value = null;
        selectedReservationOrder.value = null;
      } catch (error) {
        showError(error);
      }
    });
  };
  const printInvoice = async (invoice) => {
    try {
      let order = invoice;
      if (!order.items || order.items.length === 0) {
        const data = await OrderService.getOrderById(invoice.id);
        order = data;
      }
      const printWindow = window.open('', '_blank', 'width=800,height=600');
      if (!printWindow) {
        showError(new Error('Cannot open print window. Please allow popups.'));
        return;
      }
      let invoiceHTML = '<!DOCTYPE html><html><head><meta charset="UTF-8">';
      invoiceHTML += '<title>Invoice #' + order.id + '</title>';
      invoiceHTML += '<style>* { margin: 0; padding: 0; box-sizing: border-box; }';
      invoiceHTML += 'body { font-family: Arial, sans-serif; padding: 20px; }';
      invoiceHTML += '.invoice-header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #333; padding-bottom: 20px; }';
      invoiceHTML += '.invoice-header h1 { font-size: 24px; margin-bottom: 10px; }';
      invoiceHTML += '.invoice-info { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }';
      invoiceHTML += '.info-section h3 { font-size: 14px; margin-bottom: 10px; color: #666; }';
      invoiceHTML += '.info-section p { margin: 5px 0; font-size: 13px; }';
      invoiceHTML += 'table { width: 100%; border-collapse: collapse; margin: 20px 0; }';
      invoiceHTML += 'th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }';
      invoiceHTML += 'th { background: #f5f5f5; font-weight: bold; }';
      invoiceHTML += '.text-right { text-align: right; }';
      invoiceHTML += '.product-name { font-weight: 500; }';
      invoiceHTML += '.product-options { font-size: 11px; color: #666; font-style: italic; padding-left: 8px; margin-top: 4px; }';
      invoiceHTML += '.total-section { margin-top: 20px; padding-top: 20px; border-top: 2px solid #333; }';
      invoiceHTML += '.total-row { display: flex; justify-content: space-between; padding: 10px 0; font-size: 16px; }';
      invoiceHTML += '.total-amount { font-size: 20px; font-weight: bold; color: #FF8C42; }';
      invoiceHTML += '.footer { margin-top: 40px; text-align: center; font-size: 12px; color: #666; }';
      invoiceHTML += '@media print { body { padding: 0; } .no-print { display: none; } }</style></head><body>';
      invoiceHTML += '<div class="invoice-header"><h1>INVOICE</h1>';
      invoiceHTML += '<p>Order ID: #' + order.id + '</p>';
      invoiceHTML += '<p>Date: ' + formatDate(order.created_at) + '</p></div>';
      invoiceHTML += '<div class="invoice-info">';
      invoiceHTML += '<div class="info-section"><h3>Customer Information</h3>';
      invoiceHTML += '<p><strong>Name:</strong> ' + (order.customer_name || 'Walk-in customer') + '</p>';
      invoiceHTML += '<p><strong>Phone:</strong> ' + (order.customer_phone || 'N/A') + '</p></div>';
      invoiceHTML += '<div class="info-section"><h3>Order Information</h3>';
      invoiceHTML += '<p><strong>Branch:</strong> ' + (order.branch_name || 'N/A') + '</p>';
      invoiceHTML += '<p><strong>Order type:</strong> ' + getOrderTypeLabel(order.order_type) + '</p>';
      if (order.table_id) {
        invoiceHTML += '<p><strong>Table:</strong> #' + order.table_id + '</p>';
      }
      if (order.delivery_address) {
        invoiceHTML += '<p><strong>Address:</strong> ' + order.delivery_address + '</p>';
      }
      invoiceHTML += '</div></div>';
      invoiceHTML += '<table><thead><tr>';
      invoiceHTML += '<th>No.</th><th>Product</th>';
      invoiceHTML += '<th class="text-right">Quantity</th>';
      invoiceHTML += '<th class="text-right">Unit Price</th>';
      invoiceHTML += '<th class="text-right">Total</th></tr></thead><tbody>';
      const items = order.items || [];
      items.forEach((item, index) => {
        const price = item.price || 0;
        const quantity = item.quantity || 1;
        const total = price * quantity;
        invoiceHTML += '<tr>';
        invoiceHTML += '<td>' + (index + 1) + '</td>';
        let productDisplay = '<div class="product-name">' + (item.product_name || item.name || 'N/A') + '</div>';
        if (item.special_instructions) {
          const formattedOptions = formatItemOptions(item.special_instructions);
          if (formattedOptions) {
            productDisplay += '<div class="product-options">* ' + formattedOptions + '</div>';
          }
        }
        invoiceHTML += '<td>' + productDisplay + '</td>';
        invoiceHTML += '<td class="text-right">' + quantity + '</td>';
        invoiceHTML += '<td class="text-right">' + formatCurrency(price) + '</td>';
        invoiceHTML += '<td class="text-right">' + formatCurrency(total) + '</td>';
        invoiceHTML += '</tr>';
      });
      invoiceHTML += '</tbody></table>';
      invoiceHTML += '<div class="total-section">';
      invoiceHTML += '<div class="total-row"><span>Total items:</span>';
      invoiceHTML += '<span>' + (order.items_count || items.length || 0) + '</span></div>';
      invoiceHTML += '<div class="total-row total-amount"><span>TOTAL:</span>';
      invoiceHTML += '<span>' + formatCurrency(order.total) + '</span></div>';
      invoiceHTML += '<div class="total-row" style="margin-top: 10px;">';
      invoiceHTML += '<span>Payment status:</span>';
      invoiceHTML += '<span>' + getPaymentStatusLabel(order.payment_status) + '</span></div>';
      if (order.payment_method) {
        invoiceHTML += '<div class="total-row">';
        invoiceHTML += '<span>Payment method:</span>';
        invoiceHTML += '<span>' + getPaymentMethodLabel(order.payment_method) + '</span></div>';
      }
      invoiceHTML += '</div>';
      invoiceHTML += '<div class="footer">';
      invoiceHTML += '<p>Thank you for using our service!</p>';
      invoiceHTML += '<p>Electronic invoice - Legally valid</p></div>';
      invoiceHTML += '<' + 'script' + '>window.onload = function() { };<' + '/script' + '>';
      invoiceHTML += '</body></html>';
      printWindow.document.write(invoiceHTML);
      printWindow.document.close();
    } catch (error) {
      showError(error);
    }
  }
  function formatItemOptions(specialInstructions) {
    if (!specialInstructions) return '';
    if (typeof specialInstructions === 'string') {
      if (isJsonString(specialInstructions)) {
        try {
          const options = JSON.parse(specialInstructions);
          if (Array.isArray(options)) {
            return options.map(option => {
              const optionName = option.option_name || '';
              const selectedValues = option.selected_values || [];
              const valuesText = selectedValues.join(', ');
              return optionName + ': ' + valuesText;
            }).join(' | ');
          }
        } catch (e) {
          return specialInstructions;
        }
      } else {
        return specialInstructions;
      }
    }
    if (Array.isArray(specialInstructions)) {
      return specialInstructions.map(option => {
        const optionName = option.option_name || '';
        const selectedValues = option.selected_values || [];
        const valuesText = selectedValues.join(', ');
        return optionName + ': ' + valuesText;
      }).join(' | ');
    }
    if (typeof specialInstructions === 'object') {
      const optionName = specialInstructions.option_name || '';
      const selectedValues = specialInstructions.selected_values || [];
      const valuesText = selectedValues.join(', ');
      return optionName + ': ' + valuesText;
    }
    return '';
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
  function getOrderTypeLabel(type) {
    const labels = {
      dine_in: 'Dine-in',
      takeaway: 'Takeaway',
      delivery: 'Delivery'
    };
    return labels[type] || type;
  }
  function getPaymentStatusLabel(status) {
    const labels = {
      pending: 'Unpaid',
      paid: 'Paid',
      failed: 'Payment failed'
    };
    return labels[status] || status;
  }
  function getPaymentMethodLabel(method) {
    const labels = {
      cash: 'Cash'
    };
    return labels[method] || 'Cash';
  }
  async function handleExportOrders() {
    try {
      let ordersToExport = [...orders.value];
      if (exportFilters.dateFrom || exportFilters.dateTo) {
        ordersToExport = ordersToExport.filter(order => {
          const orderDate = new Date(order.created_at).toISOString().split('T')[0];
          const fromDate = exportFilters.dateFrom || '';
          const toDate = exportFilters.dateTo || '';
          if (fromDate && toDate) {
            return orderDate >= fromDate && orderDate <= toDate;
          } else if (fromDate) {
            return orderDate >= fromDate;
          } else if (toDate) {
            return orderDate <= toDate;
          }
          return true;
        });
      }
      if (exportFilters.status) {
        ordersToExport = ordersToExport.filter(order => order.status === exportFilters.status);
      }
      if (exportFilters.paymentStatus) {
        ordersToExport = ordersToExport.filter(order => order.payment_status === exportFilters.paymentStatus);
      }
      if (exportFilters.search) {
        const search = exportFilters.search.toLowerCase();
        ordersToExport = ordersToExport.filter(order => 
          order.id.toString().includes(search) ||
          (order.customer_name && order.customer_name.toLowerCase().includes(search)) ||
          (order.customer_phone && order.customer_phone.includes(search))
        );
      }
      if (ordersToExport.length === 0) {
        toast.warning('No orders to export');
        return;
      }
      exportToCSV(ordersToExport, exportFilters);
      showExportModal.value = false;
      exportFilters.dateFrom = '';
      exportFilters.dateTo = '';
      exportFilters.status = '';
      exportFilters.paymentStatus = '';
      exportFilters.search = '';
    } catch (error) {
      showError(error);
    }
  }
  function exportToCSV(orders, filters = {}) {
    const headers = [
      'ID', 'Customer', 'Phone', 'Order type', 'Table', 
      'Delivery address', 'Items', 'Total', 'Status', 
      'Payment', 'Payment method', 'Created date'
    ];
    const rows = orders.map(order => [
      order.id,
      order.customer_name || 'N/A',
      order.customer_phone || 'N/A',
      getOrderTypeLabel(order.order_type),
      (order.order_type === 'dine_in' && order.table_id ? '#' + order.table_id : (order.order_type === 'dine_in' ? 'N/A' : '-')),
      order.delivery_address || (order.order_type === 'delivery' ? 'N/A' : '-'),
      order.items_count || (order.items ? order.items.length : 0),
      order.total || 0,
      getStatusLabel(order.status),
      getPaymentStatusLabel(order.payment_status),
      getPaymentMethodLabel(order.payment_method),
      formatDate(order.created_at)
    ]);
    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
    ].join('\n');
    let filename = 'danh_sach_don_hang';
    if (filters.dateFrom && filters.dateTo) {
      const fromDate = filters.dateFrom.replace(/-/g, '');
      const toDate = filters.dateTo.replace(/-/g, '');
      filename += `_${fromDate}_${toDate}`;
    } else if (filters.dateFrom) {
      const fromDate = filters.dateFrom.replace(/-/g, '');
      filename += `_tu_${fromDate}`;
    } else if (filters.dateTo) {
      const toDate = filters.dateTo.replace(/-/g, '');
      filename += `_den_${toDate}`;
    } else {
      filename += `_${new Date().toISOString().split('T')[0].replace(/-/g, '')}`;
    }
    const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `${filename}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success(`Exported ${orders.length} orders successfully`);
  }
  async function handleOrderUpdated() {
    await loadOrders();
    if (selectedOrder.value && selectedOrder.value.id) {
      try {
        const orderData = await OrderService.getOrderById(selectedOrder.value.id);
        selectedOrder.value = orderData;
      } catch (error) {
        }
    }
  }
  async function quickCompleteOrder(order) {
    if (!order || updatingOrderId.value === order.id) return;
    showConfirm(`Confirm completing order #${order.id}?`, async () => {
      updatingOrderId.value = order.id;
      try {
        await OrderService.updateOrderStatus(order.id, 'completed');
        toast.success(`Order #${order.id} has been marked as completed`);
        const orderIndex = orders.value.findIndex(o => o.id === order.id);
        if (orderIndex !== -1) {
          orders.value[orderIndex].status = 'completed';
        }
        await loadOrders();
      } catch (error) {
        showError(error);
      } finally {
        updatingOrderId.value = null;
      }
    });
  }
  function showError(error) {
    let message = error.message || 'An error occurred';
    message = message.replace(/https?:\/\/localhost[^\s]*/gi, '');
    message = message.replace(/localhost[^\s]*/gi, '');
    message = message.replace(/http[^\s]*localhost[^\s]*/gi, '');
    message = message.replace(/Failed to fetch|Network error|fetch failed/gi, 'Connection error');
    message = message.replace(/\s+/g, ' ').trim();
    formattedErrorMessage.value = message || 'An unexpected error occurred';
    showErrorModal.value = true;
  }
  function closeErrorModal() {
    showErrorModal.value = false;
    formattedErrorMessage.value = '';
  }
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
  function formatCurrency(amount) {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND'
    }).format(amount);
  }
  function isOverdueReservation(reservation) {
    if (!reservation || reservation.status === 'cancelled' || reservation.status === 'completed' || reservation.check_in_time) {
      return false;
    }
    const now = new Date();
    const reservationDate = new Date(`${reservation.reservation_date} ${reservation.reservation_time}`);
    const minutesOverdue = Math.floor((now - reservationDate) / (1000 * 60));
    return minutesOverdue >= 30;
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
  function getReservationStatusLabel(status) {
    const labels = {
      pending: 'Pending',
      confirmed: 'Confirmed',
      checked_in: 'Checked in',
      completed: 'Completed',
      cancelled: 'Cancelled'
    };
    return labels[status] || status;
  }
  function getReservationStatusClass(status) {
    const classes = {
      pending: 'status-pending',
      confirmed: 'status-confirmed',
      checked_in: 'status-checked-in',
      completed: 'status-completed',
      cancelled: 'status-cancelled'
    };
    return classes[status] || 'status-default';
  }
  onMounted(async () => {
    loadOrders();
    loadReservations();
    loadOverdueReservations();
    
    // ✅ Ensure socket is connected before setting up listeners
    if (!SocketService.getConnectionStatus()) {
      SocketService.connect();
      // Wait for connection with timeout
      const connected = await SocketService.waitForConnection(3000);
      console.log('[Cashier OrdersTab] Socket connected:', connected);
    }
    
    // ✅ SETUP SOCKET.IO LISTENERS
    // Note: new-order listener is handled globally in Employee Dashboard to show notifications
    // We only listen here for order status and payment updates
    console.log('[Cashier OrdersTab] Setting up socket listeners for order updates...');
    console.log('[Cashier OrdersTab] Socket connection status:', SocketService.getConnectionStatus());
    
    // Note: new-order notification is handled by Employee Dashboard globally
    // No need to register here to avoid duplicate notifications
    
    // Test listener registration
    setTimeout(() => {
      if (SocketService.getConnectionStatus()) {
        console.log('[Cashier OrdersTab] ✅ Socket is connected, listener should be active');
        const socket = SocketService.getSocket();
        if (socket) {
          console.log('[Cashier OrdersTab] Socket ID:', socket.id);
          console.log('[Cashier OrdersTab] Socket connected:', socket.connected);
          const listenerCount = SocketService.testListener('new-order');
          console.log('[Cashier OrdersTab] new-order listener count:', listenerCount);
        }
      } else {
        console.warn('[Cashier OrdersTab] ⚠️ Socket is NOT connected, listener may not work');
      }
    }, 1000);
    
    // Listen for order status updates
    SocketService.on('order-status-updated', (data) => {
      const branchId = getCurrentBranchId();
      if (data.branchId === parseInt(branchId)) {
        loadOrders(); // Refresh order list
      }
    });
    
    // Listen for payment status updates
    SocketService.on('payment-status-updated', (data) => {
      const branchId = getCurrentBranchId();
      if (data.branchId === parseInt(branchId)) {
        loadOrders(); // Refresh order list
      }
    });
    
    // Listen for reservation overdue notifications
    SocketService.on('reservation-overdue', (data) => {
      const branchId = getCurrentBranchId();
      if (data.branchId === parseInt(branchId)) {
        toast.warning(data.title, {
          timeout: 8000,
          onClick: () => {
            if (activeOrderTypeTab.value !== 'reservation') {
              activeOrderTypeTab.value = 'reservation';
            }
            loadOverdueReservations();
            loadReservations();
          }
        });
        // Refresh overdue reservations list
        loadOverdueReservations();
      }
    });
  });
  
  onUnmounted(() => {
    // Clean up socket listeners (new-order is handled by Dashboard, don't off it here)
    SocketService.off('order-status-updated');
    SocketService.off('payment-status-updated');
    SocketService.off('reservation-overdue');
  });
  </script>
  <style scoped>
  .orders-tab {
    padding: 12px;
    background: #F5F7FA;
    min-height: calc(100vh - 124px);
  }
  .orders-box {
    background: white;
    border-radius: 10px;
    overflow-y: auto;
    overflow-x: hidden;
    display: flex;
    flex-direction: column;
    padding: 12px;
    border: 1px solid #E2E8F0;
  }
  .order-type-tabs {
    display: flex;
    gap: 6px;
    margin-bottom: 16px;
    background: white;
    padding: 6px;
    border-radius: 10px;
    border: 1px solid #E2E8F0;
  }
  .order-type-tab-btn {
    flex: 1;
    padding: 10px 16px;
    background: transparent;
    border: none;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    color: #64748B;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    position: relative;
  }
  .order-type-tab-btn:hover {
    background: #F8F9FA;
    color: #475569;
  }
  .order-type-tab-btn.active {
    background: #F59E0B;
    color: white;
  }
  .order-type-tab-btn i {
    font-size: 16px;
  }
  .order-type-tab-btn .tab-badge {
    background: rgba(255, 255, 255, 0.3);
    color: white;
    padding: 2px 8px;
    border-radius: 10px;
    font-size: 11px;
    font-weight: 700;
    margin-left: 4px;
  }
  .search-filter-section {
    display: flex;
    gap: 8px;
    margin-bottom: 12px;
    align-items: center;
    flex-wrap: wrap;
  }
  .search-bar {
    flex: 1;
    min-width: 200px;
    position: relative;
  }
  .search-bar i {
    position: absolute;
    left: 10px;
    top: 50%;
    transform: translateY(-50%);
    color: #999;
    font-size: 12px;
  }
  .search-bar input {
    width: 100%;
    padding: 10px 14px 10px 32px;
    border: 1px solid #E5E5E5;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 500;
    background: #FAFAFA;
    color: #1a1a1a;
    transition: all 0.2s ease;
  }
  .search-bar input:focus {
    outline: none;
    border-color: #F59E0B;
    background: white;
  }
  .filter-select {
    width: auto;
    min-width: 160px;
    padding: 8px 12px;
    border: 1px solid #E2E8F0;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 500;
    background: white;
    color: #1E293B;
    transition: all 0.2s ease;
    cursor: pointer;
  }
  .filter-select:focus {
    outline: none;
    border-color: #F59E0B;
    background: white;
  }
  .btn-clear-filters {
    padding: 8px 14px;
    background: white;
    color: #64748B;
    border: 1px solid #E2E8F0;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    gap: 6px;
    white-space: nowrap;
  }
  .btn-clear-filters:hover {
    background: #F8F9FA;
    border-color: #CBD5E1;
    color: #475569;
  }
  .loading-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 40px 20px;
    color: #64748B;
    gap: 12px;
  }
  .loading-state i {
    font-size: 28px;
    color: #F59E0B;
  }
  .loading-state p {
    font-size: 13px;
    margin: 0;
    color: #64748B;
  }
  .empty-state {
    text-align: center;
    padding: 60px 20px;
    color: #6B7280;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 12px;
    background: white;
    border-radius: 10px;
    border: 1px solid #E2E8F0;
  }
  .empty-state i {
    font-size: 48px;
    margin-bottom: 16px;
    color: #9CA3AF;
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
  .empty-state p {
    font-size: 14px;
    margin: 0;
    font-weight: 500;
  }
  .overdue-warning-banner {
    background: #EF4444;
    color: white;
    padding: 12px 16px;
    border-radius: 10px;
    margin-bottom: 12px;
    animation: pulse 2s infinite;
    border: 1px solid rgba(255, 255, 255, 0.2);
  }
  .overdue-warning-banner .warning-content {
    display: flex;
    align-items: flex-start;
    gap: 12px;
  }
  .overdue-warning-banner i {
    font-size: 24px;
    margin-top: 2px;
  }
  .overdue-warning-banner .warning-text {
    flex: 1;
  }
  .overdue-warning-banner strong {
    display: block;
    font-size: 14px;
    margin-bottom: 6px;
    font-weight: 700;
  }
  .overdue-list {
    margin: 6px 0 0 0;
    padding-left: 18px;
    font-size: 13px;
  }
  .overdue-list li {
    margin-bottom: 3px;
  }
  .minutes-overdue {
    font-weight: 600;
    opacity: 0.9;
  }
  .orders-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 12px;
  }
  .order-card {
    background: white;
    border: 1px solid #E2E8F0;
    border-radius: 10px;
    transition: all 0.2s ease;
    padding: 12px;
    cursor: pointer;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  .order-card.overdue-warning {
    border: 2px solid #EF4444;
    background: #FEE2E2;
  }
  .overdue-badge {
    background: #EF4444;
    color: white;
    padding: 4px 8px;
    border-radius: 6px;
    font-size: 11px;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    gap: 4px;
    margin-left: 8px;
  }
  @keyframes pulse {
    0%, 100% {
      opacity: 1;
    }
    50% {
      opacity: 0.9;
    }
  }
  @keyframes pulse-border {
    0%, 100% {
      border-color: #EF4444;
    }
    50% {
      border-color: #F59E0B;
    }
  }
  .order-card:hover {
    border-color: #F59E0B;
    box-shadow: 0 2px 8px rgba(245, 158, 11, 0.15);
  }
  .order-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0;
  }
  .order-id {
    font-weight: 600;
    color: #333;
  }
  .status-badge {
    padding: 5px 12px;
    border-radius: 8px;
    font-size: 11px;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    gap: 4px;
    letter-spacing: 0.2px;
  }
  .status-pending {
    background: #FEF3C7;
    color: #D97706;
    border: 1px solid #FCD34D;
  }
  .status-preparing {
    background: #DBEAFE;
    color: #2563EB;
    border: 1px solid #93C5FD;
  }
  .status-ready {
    background: #E0E7FF;
    color: #6366F1;
    border: 1px solid #A5B4FC;
  }
  .status-completed {
    background: #D1FAE5;
    color: #059669;
    border: 1px solid #6EE7B7;
  }
  .status-cancelled {
    background: #FEE2E2;
    color: #DC2626;
    border: 1px solid #FCA5A5;
  }
  .status-confirmed {
    background: #D1ECF1;
    color: #0C5460;
  }
  .status-checked-in {
    background: #D4EDDA;
    color: #155724;
  }
  .order-info {
    margin-bottom: 0;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }
  .order-info p {
    margin: 0;
    font-size: 13px;
    color: #64748B;
    display: flex;
    align-items: center;
    gap: 6px;
  }
  .order-info i {
    width: 14px;
    color: #94A3B8;
    font-size: 12px;
  }
  .floor-info {
    color: #94A3B8;
    font-size: 13px;
    font-weight: normal;
    margin-left: 4px;
  }
  .payment-status {
    font-weight: 500;
  }
  .payment-status.paid {
    color: #28A745;
  }
  .payment-status.unpaid {
    color: #DC3545;
  }
  .order-actions {
    display: flex;
    gap: 8px;
  }
  .btn {
    padding: 8px 16px;
    border-radius: 8px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    transition: all 0.2s ease;
    border: none;
  }
  .btn-primary {
    background-color: #F59E0B;
    color: white;
    font-weight: 600;
    transition: all 0.2s ease;
  }
  .btn-primary:hover {
    background-color: #D97706;
  }
  .btn-success {
    background-color: #D1FAE5;
    color: #059669;
    border: 1px solid #6EE7B7;
  }
  .btn-success:hover:not(:disabled) {
    background-color: #A7F3D0;
  }
  .btn-success:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
  .btn-secondary {
    background-color: white;
    color: #64748B;
    border: 1px solid #E2E8F0;
    font-weight: 600;
    transition: all 0.2s ease;
  }
  .btn-secondary:hover {
    border-color: #F59E0B;
    color: #F59E0B;
    background-color: #FFF7ED;
  }
  .btn-danger {
    background-color: #EF4444;
    color: white;
    border-radius: 10px;
    font-weight: 600;
    transition: all 0.2s ease;
  }
  .btn-danger:hover {
    background-color: #DC2626;
  }
  .btn-sm {
    padding: 6px 12px;
    font-size: 12px;
  }
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: 20px;
    backdrop-filter: blur(4px);
  }
  .modal-content {
    background: white;
    border-radius: 16px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15);
    max-width: 600px;
    width: 100%;
    max-height: 90vh;
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }
  .modal-content.large {
    max-width: 700px;
  }
  .modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px 20px;
    background: #FFF7ED;
    border-bottom: 1px solid #FED7AA;
    flex-shrink: 0;
  }
  .modal-header h3 {
    margin: 0;
    font-size: 20px;
    font-weight: 700;
    color: #1a1a1a;
    letter-spacing: -0.3px;
  }
  .header-actions {
    display: flex;
    gap: 12px;
    align-items: center;
  }
  .modal-close {
    background: none;
    border: none;
    font-size: 24px;
    cursor: pointer;
    color: #666;
    padding: 0;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .modal-close:hover {
    color: #333;
  }
  .modal-body {
    padding: 24px;
    overflow-y: auto;
    flex: 1;
    background: white;
  }
  .reservation-detail {
    display: flex;
    flex-direction: column;
    gap: 24px;
  }
  .reservation-info-section h4,
  .reservation-order-section h4 {
    font-size: 18px;
    margin: 0 0 16px 0;
    color: #333;
    border-bottom: 2px solid #F59E0B;
    padding-bottom: 8px;
  }
  .info-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
  }
  .info-item {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }
  .info-item strong {
    font-size: 13px;
    color: #666;
    font-weight: 600;
  }
  .info-item span {
    font-size: 14px;
    color: #333;
  }
  .reservation-order-section {
    margin-top: 24px;
    padding-top: 24px;
    border-top: 2px solid #E2E8F0;
  }
  .order-detail-wrapper {
    margin-top: 16px;
  }
  .loading-order {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 40px;
    gap: 12px;
    color: #999;
  }
  .loading-order i {
    font-size: 24px;
    color: #F59E0B;
  }
  .no-order {
    text-align: center;
    padding: 40px;
    color: #999;
    font-style: italic;
  }
  .modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    padding: 16px 20px;
    background: #FAFAFA;
    border-top: 1px solid #FED7AA;
    flex-shrink: 0;
  }
  .export-form {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }
  .form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
  }
  .form-group {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  .form-label {
    font-size: 14px;
    font-weight: 500;
    color: #333;
  }
  .form-input,
  .form-select {
    padding: 10px 12px;
    border: 1px solid #D1D5DB;
    border-radius: 6px;
    font-size: 14px;
    color: #333;
    background: white;
    transition: border-color 0.2s;
  }
  .form-input:focus,
  .form-select:focus {
    outline: none;
    border-color: #3B82F6;
  }
  .status-delivering {
    background: #E0E7FF;
    color: #6366F1;
    border: 1px solid #A5B4FC;
  }
  .status-default {
    background: #F3F4F6;
    color: #6B7280;
  }
  @media (max-width: 768px) {
    .orders-grid {
      grid-template-columns: 1fr;
    }
    .search-filter-section {
      flex-direction: column;
    }
    .filter-select {
      width: 100%;
    }
    .order-type-tabs {
      flex-direction: column;
    }
    .info-grid {
      grid-template-columns: 1fr;
    }
  .form-row {
    grid-template-columns: 1fr;
  }
}
.error-modal {
  max-width: 480px;
  width: 100%;
}
.error-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  text-align: center;
}
.error-icon {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: #FEE2E2;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #DC2626;
  font-size: 32px;
}
.error-message {
  font-size: 14px;
  color: #1E293B;
  line-height: 1.6;
  margin: 0;
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
</style>