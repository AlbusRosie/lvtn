<template>
  <div class="delivery-assignment-tab">
    <!-- Statistics Section -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon" style="background: #FEF3C7; color: #D97706;">
          <i class="fas fa-clock"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ stats.ready }}</div>
          <div class="stat-label">Pending Assignment</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #DBEAFE; color: #2563EB;">
          <i class="fas fa-truck"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ stats.assigned }}</div>
          <div class="stat-label">Assigned</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #D1FAE5; color: #059669;">
          <i class="fas fa-check-circle"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ stats.delivered }}</div>
          <div class="stat-label">Delivered</div>
        </div>
      </div>
    </div>
    <!-- Orders List -->
    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Loading orders...</p>
      </div>
      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadReadyOrders" class="btn btn-secondary">
          Try Again
        </button>
      </div>
      <div v-else class="orders-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>
              <i class="fas fa-truck"></i>
              Delivery Assignment
            </h3>
            <span class="table-count">{{ readyOrders.length }} {{ readyOrders.length === 1 ? 'order' : 'orders' }} pending assignment</span>
          </div>
          <div class="header-actions-wrapper">
            <div class="header-actions">
              <button @click="loadReadyOrders" class="btn-refresh" :disabled="loading">
                <i class="fas fa-sync" :class="{ 'fa-spin': loading }"></i>
                Refresh
              </button>
            </div>
          </div>
        </div>
        <div v-if="readyOrders.length === 0" class="empty-state">
          <i class="fas fa-check-circle"></i>
          <h3>No orders need assignment</h3>
          <p>All orders have been assigned or there are no ready orders.</p>
        </div>
        <div v-else class="orders-grid">
          <div v-for="order in readyOrders" :key="order.id" class="order-card">
            <div class="order-header">
              <div class="order-header-top">
                <div class="order-id-section">
                  <div class="order-id">
                    <i class="fas fa-receipt"></i>
                    <span>Order #{{ order.id }}</span>
                  </div>
                  <div class="order-time">
                    <i class="fas fa-clock"></i>
                    <span>{{ formatDate(order.created_at) }}</span>
                  </div>
                </div>
                <span class="badge badge-warning">
                  <i class="fas fa-hourglass-half"></i>
                  Pending Assignment
                </span>
              </div>
              <div class="shipper-select-header">
                <div class="form-group-inline">
                  <label class="form-label-inline">
                    <i class="fas fa-user-tie"></i>
                    <span>Select Shipper</span>
                  </label>
                  <div class="select-wrapper">
                    <select 
                      v-model="orderAssignments[order.id]" 
                      class="form-select"
                      @change="handleAssignmentChange(order.id, orderAssignments[order.id])"
                    >
                      <option value="">-- Select Shipper --</option>
                      <option 
                        v-for="shipper in branchShippers" 
                        :key="shipper.id" 
                        :value="shipper.id"
                      >
                        {{ shipper.name }} {{ shipper.phone ? `(${shipper.phone})` : '' }}
                      </option>
                    </select>
                    <i class="fas fa-chevron-down select-arrow"></i>
                  </div>
                </div>
                <button 
                  v-if="orderAssignments[order.id]"
                  @click="confirmAssign(order.id, orderAssignments[order.id])"
                  class="btn-assign"
                  :disabled="assigning[order.id]"
                >
                  <i v-if="assigning[order.id]" class="fas fa-spinner fa-spin"></i>
                  <i v-else class="fas fa-check-circle"></i>
                  <span>{{ assigning[order.id] ? 'Processing...' : 'Confirm' }}</span>
                </button>
              </div>
            </div>
            <div class="order-body">
              <div class="order-info-grid">
                <div class="info-item">
                  <div class="info-icon">
                    <i class="fas fa-user"></i>
                  </div>
                  <div class="info-content">
                    <span class="info-label">Customer</span>
                    <span class="info-value">{{ order.customer_name || 'N/A' }}</span>
                  </div>
                </div>
                <div class="info-item">
                  <div class="info-icon">
                    <i class="fas fa-phone"></i>
                  </div>
                  <div class="info-content">
                    <span class="info-label">Phone</span>
                    <span class="info-value">{{ order.customer_phone || 'N/A' }}</span>
                  </div>
                </div>
                <div class="info-item info-item-full">
                  <div class="info-icon">
                    <i class="fas fa-map-marker-alt"></i>
                  </div>
                  <div class="info-content">
                    <span class="info-label">Delivery Address</span>
                    <span class="info-value">{{ order.delivery_address || 'N/A' }}</span>
                  </div>
                </div>
                <div class="info-item">
                  <div class="info-icon">
                    <i class="fas fa-money-bill-wave"></i>
                  </div>
                  <div class="info-content">
                    <span class="info-label">Total Amount</span>
                    <span class="info-value amount-value">{{ formatCurrency(order.total) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { inject } from 'vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import OrderService from '@/services/OrderService';
import UserService from '@/services/UserService';
import BranchService from '@/services/BranchService';
import AuthService from '@/services/AuthService';
import SocketService from '@/services/SocketService';
import { USER_ROLES } from '@/constants';
export default {
  name: 'DeliveryAssignmentTab',
  components: {
    LoadingSpinner
  },
  setup() {
    const toast = inject('toast');
    return { toast };
  },
  data() {
    return {
      readyOrders: [],
      allDeliveryOrders: [], 
      branchShippers: [],
      loading: false,
      error: null,
      branchName: '',
      orderAssignments: {}, 
      assigning: {}, 
      stats: {
        ready: 0,
        assigned: 0,
        delivered: 0
      }
    };
  },
  async mounted() {
    await this.loadBranchInfo();
    await Promise.all([
      this.loadReadyOrders(),
      this.loadBranchShippers()
    ]);
    
    // ✅ SETUP SOCKET.IO LISTENERS FOR REAL-TIME UPDATES
    console.log('[DeliveryAssignmentTab] Setting up socket listeners...');
    
    // Ensure socket is connected
    if (!SocketService.getConnectionStatus()) {
      SocketService.connect();
      await SocketService.waitForConnection(3000);
    }
    
    // Listen for order status updates (when kitchen staff marks order as ready)
    SocketService.on('order-status-updated', (data) => {
      console.log('[DeliveryAssignmentTab] 🔔 Received order-status-updated notification:', data);
      
      const user = AuthService.getUser();
      const branchId = user?.branch_id;
      
      // Only refresh if order is from this branch, is delivery type, and status changed to 'ready'
      if (branchId && 
          parseInt(data.branchId) === parseInt(branchId) && 
          data.orderType === 'delivery' && 
          data.newStatus === 'ready') {
        console.log('[DeliveryAssignmentTab] ✅ Delivery order marked as ready, refreshing list...');
        
        // Hiển thị thông báo cho quản lý
        if (this.toast) {
          this.toast.info(`Đơn hàng #${data.orderId} đã sẵn sàng! Vui lòng assign cho shipper.`, {
            timeout: 8000,
            onClick: () => {
              // Scroll to order if needed
            }
          });
        }
        
        // Refresh danh sách đơn ready
        this.loadReadyOrders();
      } else {
        console.log('[DeliveryAssignmentTab] ⚠️ Order status update ignored:', {
          branchMatch: branchId && parseInt(data.branchId) === parseInt(branchId),
          isDelivery: data.orderType === 'delivery',
          isReady: data.newStatus === 'ready'
        });
      }
    });
    
    // Listen for new orders (in case a delivery order is created)
    SocketService.on('new-order', (data) => {
      console.log('[DeliveryAssignmentTab] 🔔 Received new-order notification:', data);
      
      const user = AuthService.getUser();
      const branchId = user?.branch_id;
      
      // Only refresh if order is from this branch and is delivery type
      if (branchId && parseInt(data.branchId) === parseInt(branchId) && data.orderType === 'delivery') {
        console.log('[DeliveryAssignmentTab] ✅ New delivery order, refreshing list...');
        // Don't refresh immediately, wait for it to be ready
        // The order-status-updated event will handle it when it becomes ready
      }
    });
  },
  beforeUnmount() {
    // Clean up socket listeners
    console.log('[DeliveryAssignmentTab] Cleaning up socket listeners...');
    SocketService.off('order-status-updated');
    SocketService.off('new-order');
  },
  methods: {
    async loadBranchInfo() {
      try {
        const user = AuthService.getUser();
        if (user?.branch_id) {
          const branch = await BranchService.getBranchById(user.branch_id);
          this.branchName = branch?.name || '';
        }
      } catch (error) {
        }
    },
    async loadReadyOrders() {
      this.loading = true;
      this.error = null;
      try {
        const user = AuthService.getUser();
        const branchId = user?.branch_id;
        if (!branchId) {
          this.error = 'You have not been assigned to any branch';
          return;
        }
        console.log('[DeliveryAssignmentTab] Loading ready orders for branch:', branchId);
        
        const readyFilters = {
          branch_id: branchId,
          status: 'ready',
          order_type: 'delivery',
          unassigned_only: true, // Only show orders that haven't been assigned yet
          limit: 1000
        };
        const allFilters = {
          branch_id: branchId,
          order_type: 'delivery',
          limit: 1000
        };
        
        console.log('[DeliveryAssignmentTab] Ready filters:', readyFilters);
        console.log('[DeliveryAssignmentTab] All filters:', allFilters);
        
        const [readyResult, allResult] = await Promise.all([
          OrderService.getAllOrders(readyFilters),
          OrderService.getAllOrders(allFilters)
        ]);
        
        console.log('[DeliveryAssignmentTab] Ready result:', readyResult);
        console.log('[DeliveryAssignmentTab] All result:', allResult);
        
        let readyOrders = [];
        if (readyResult && readyResult.data) {
          readyOrders = Array.isArray(readyResult.data) ? readyResult.data : (readyResult.data.orders || []);
        } else if (readyResult && readyResult.orders) {
          readyOrders = readyResult.orders;
        } else if (Array.isArray(readyResult)) {
          readyOrders = readyResult;
        }
        
        let allOrders = [];
        if (allResult && allResult.data) {
          allOrders = Array.isArray(allResult.data) ? allResult.data : (allResult.data.orders || []);
        } else if (allResult && allResult.orders) {
          allOrders = allResult.orders;
        } else if (Array.isArray(allResult)) {
          allOrders = allResult;
        }
        
        console.log('[DeliveryAssignmentTab] Raw ready orders:', readyOrders);
        console.log('[DeliveryAssignmentTab] Raw all orders:', allOrders);
        
        // Debug: Check status distribution of delivery orders
        if (allOrders.length > 0) {
          const statusCount = {};
          const readyOrdersDebug = [];
          allOrders.forEach(order => {
            if (order.order_type === 'delivery') {
              statusCount[order.status] = (statusCount[order.status] || 0) + 1;
              if (order.status === 'ready') {
                readyOrdersDebug.push({
                  id: order.id,
                  status: order.status,
                  delivery_staff_id: order.delivery_staff_id,
                  unassigned: !order.delivery_staff_id
                });
              }
            }
          });
          console.log('[DeliveryAssignmentTab] Delivery orders status distribution:', statusCount);
          console.log('[DeliveryAssignmentTab] Delivery ready orders found:', readyOrdersDebug);
        }
        
        // Filter for delivery orders and unassigned orders
        // If readyOrders is empty, try to get from allOrders (fallback)
        if (readyOrders.length === 0 && allOrders.length > 0) {
          console.log('[DeliveryAssignmentTab] ⚠️ No ready orders from API with unassigned_only filter, filtering from all orders...');
          // Filter from allOrders: delivery + ready + unassigned
          const readyFromAll = allOrders.filter(order => {
            const isDelivery = order.order_type === 'delivery';
            const isReady = order.status === 'ready';
            const isUnassigned = !order.delivery_staff_id;
            if (isDelivery && isReady) {
              console.log(`[DeliveryAssignmentTab] Order #${order.id}: status=${order.status}, order_type=${order.order_type}, delivery_staff_id=${order.delivery_staff_id}, unassigned=${isUnassigned}`);
            }
            return isDelivery && isReady && isUnassigned;
          });
          console.log('[DeliveryAssignmentTab] Found ready orders from allOrders:', readyFromAll.length);
          if (readyFromAll.length > 0) {
            console.log('[DeliveryAssignmentTab] Ready order IDs from allOrders:', readyFromAll.map(o => o.id));
          } else {
            console.log('[DeliveryAssignmentTab] ⚠️ No ready delivery orders found in allOrders');
          }
          readyOrders = readyFromAll;
        }
        
        // Final filter (should already be filtered, but double-check)
        this.readyOrders = readyOrders.filter(order => {
          const isDelivery = order.order_type === 'delivery';
          const isReady = order.status === 'ready';
          const isUnassigned = !order.delivery_staff_id;
          return isDelivery && isReady && isUnassigned;
        });
        
        this.allDeliveryOrders = allOrders.filter(order => order.order_type === 'delivery');
        
        console.log('[DeliveryAssignmentTab] Filtered ready orders:', this.readyOrders);
        console.log('[DeliveryAssignmentTab] Filtered all delivery orders:', this.allDeliveryOrders);
        
        this.calculateStats();
        this.readyOrders.forEach(order => {
          if (!this.orderAssignments[order.id]) {
            this.orderAssignments[order.id] = '';
          }
        });
      } catch (error) {
        console.error('[DeliveryAssignmentTab] Error loading ready orders:', error);
        const errorMessage = error.message || 'An error occurred while loading orders';
        this.error = errorMessage;
        if (this.toast) {
          this.toast.error(errorMessage);
        }
      } finally {
        this.loading = false;
      }
    },
    async loadBranchShippers() {
      try {
        const user = AuthService.getUser();
        const branchId = user?.branch_id;
        if (!branchId) {
          return;
        }
        const result = await UserService.fetchUsers(1, 100, { 
          role_id: USER_ROLES.DELIVERY_STAFF,
          branch_id: branchId
        });
        let allShippers = result.users || [];
        this.branchShippers = allShippers.filter(shipper => 
          shipper.branch_id === branchId || shipper.branch_id === parseInt(branchId)
        );
        if (this.branchShippers.length === 0) {
          if (this.toast) {
            this.toast.warning('This branch has no shippers. Please add shippers to the branch first.');
          }
        }
      } catch (error) {
        this.branchShippers = [];
        if (this.toast) {
          this.toast.error('Unable to load shipper list');
        }
      }
    },
    handleAssignmentChange(orderId, shipperId) {
      this.orderAssignments[orderId] = shipperId;
    },
    async confirmAssign(orderId, shipperId) {
      if (!orderId || !shipperId) {
        if (this.toast) {
          this.toast.warning('Please select a shipper');
        }
        return;
      }
      this.assigning[orderId] = true;
      try {
        await OrderService.assignDeliveryStaff(orderId, shipperId);
        if (this.toast) {
          this.toast.success('Shipper assigned successfully');
        }
        await this.loadReadyOrders();
      } catch (error) {
        const errorMessage = error.message || 'Unable to assign shipper';
        if (this.toast) {
          this.toast.error(errorMessage);
        }
      } finally {
        this.assigning[orderId] = false;
      }
    },
    calculateStats() {
      this.stats = {
        ready: this.allDeliveryOrders.filter(o => o.status === 'ready').length,
        assigned: this.allDeliveryOrders.filter(o => o.status === 'out_for_delivery').length,
        delivered: this.allDeliveryOrders.filter(o => o.status === 'completed').length
      };
    },
    formatCurrency(amount) {
      return new Intl.NumberFormat('vi-VN', {
        style: 'currency',
        currency: 'VND'
      }).format(amount || 0);
    },
    formatDate(dateString) {
      if (!dateString) return '-';
      const date = new Date(dateString);
      return date.toLocaleDateString('en-US', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    }
  }
};
</script>
<style scoped>
.delivery-assignment-tab {
  padding: 20px;
  background: #F5F7FA;
  min-height: calc(100vh - 124px);
  overflow-x: hidden;
}
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 24px;
}
.stat-card {
  background: white;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  transition: all 0.2s ease;
}
.stat-card:hover {
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.08);
  transform: translateY(-2px);
}
.stat-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  flex-shrink: 0;
}
.stat-info {
  flex: 1;
  min-width: 0;
}
.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: #1E293B;
  margin-bottom: 4px;
  line-height: 1.2;
  letter-spacing: -0.3px;
}
.stat-label {
  font-size: 14px;
  color: #64748B;
  font-weight: 500;
  letter-spacing: 0.1px;
}
.content-area {
  min-height: 400px;
}
.loading,
.error {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
  background: white;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
}
.loading i,
.error i {
  font-size: 48px;
  margin-bottom: 16px;
  color: #9CA3AF;
}
.error i {
  color: #EF4444;
}
.loading p,
.error p {
  margin: 8px 0;
  color: #6B7280;
  font-size: 14px;
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
.orders-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(450px, 1fr));
  gap: 24px;
  margin-top: 20px;
}
.order-card {
  border: 1px solid #E2E8F0;
  border-radius: 16px;
  padding: 24px;
  background: white;
  box-shadow: 
    0 1px 3px rgba(0, 0, 0, 0.04),
    0 2px 8px rgba(0, 0, 0, 0.02);
  position: relative;
  overflow: hidden;
}
.order-header {
  margin-bottom: 24px;
  padding-bottom: 20px;
  border-bottom: 2px solid #F1F5F9;
}
.order-header-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
  gap: 16px;
}
.order-id-section {
  flex: 1;
  min-width: 0;
}
.order-id {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 700;
  color: #1E293B;
  font-size: 18px;
  margin-bottom: 8px;
}
.order-id i {
  color: #FF8C42;
  font-size: 20px;
}
.order-time {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #64748B;
  font-weight: 500;
}
.order-time i {
  font-size: 11px;
  color: #94A3B8;
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
  color: #D97706;
  border: 1px solid #FCD34D;
  box-shadow: 0 2px 4px rgba(217, 119, 6, 0.1);
}
.badge-warning i {
  font-size: 11px;
}
.order-body {
  margin-bottom: 24px;
}
.order-info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
.info-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 12px;
  background: #FAFBFC;
  border-radius: 10px;
  border: 1px solid #F1F5F9;
}
.info-item-full {
  grid-column: 1 / -1;
}
.info-icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: #FFF7ED;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border: 1px solid #FFE5D4;
}
.info-icon i {
  color: #FF8C42;
  font-size: 16px;
}
.info-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}
.info-label {
  font-size: 11px;
  color: #64748B;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.info-value {
  font-size: 14px;
  color: #1E293B;
  font-weight: 600;
  word-break: break-word;
  line-height: 1.4;
}
.amount-value {
  color: #FF8C42;
  font-size: 16px;
  font-weight: 700;
}
.shipper-select-header {
  display: flex;
  align-items: flex-end;
  gap: 12px;
}
.form-group-inline {
  flex: 1;
  min-width: 0;
}
.form-label-inline {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  font-size: 12px;
  font-weight: 600;
  color: #64748B;
}
.form-label-inline i {
  color: #FF8C42;
  font-size: 13px;
}
.select-wrapper {
  position: relative;
}
.form-select {
  width: 100%;
  padding: 10px 40px 10px 12px;
  border: 2px solid #E2E8F0;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  color: #1F2937;
  cursor: pointer;
  font-weight: 500;
  appearance: none;
  -webkit-appearance: none;
  -moz-appearance: none;
}
.form-select:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.select-arrow {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #94A3B8;
  font-size: 11px;
  pointer-events: none;
}
.form-select:focus + .select-arrow {
  color: #FF8C42;
}
.btn-assign {
  background: #FF8C42;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  white-space: nowrap;
  flex-shrink: 0;
}
.btn-assign:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-assign i {
  font-size: 13px;
}
.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}
.btn-secondary {
  background: #F3F4F6;
  color: #6B7280;
  border: 1px solid #E5E5E5;
}
.btn-secondary:hover {
  background: #E5E7EB;
}
@media (max-width: 1200px) {
  .orders-grid {
    grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
    gap: 20px;
  }
}
@media (max-width: 768px) {
  .delivery-assignment-tab {
    padding: 16px;
  }
  .orders-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }
  .order-card {
    padding: 20px;
  }
  .order-info-grid {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  .info-item-full {
    grid-column: 1;
  }
  .table-header-section {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
  .table-title {
    width: 100%;
  }
  .table-count {
    margin-left: 0;
    margin-top: 8px;
  }
  .stat-card {
    padding: 16px;
  }
  .stat-icon {
    width: 48px;
    height: 48px;
    font-size: 20px;
  }
  .stat-value {
    font-size: 24px;
  }
  .order-header-top {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
  .badge {
    align-self: flex-start;
  }
  .order-id-section {
    width: 100%;
  }
  .shipper-select-header {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  .btn-assign {
    width: 100%;
  }
}
@media (max-width: 480px) {
  .delivery-assignment-tab {
    padding: 12px;
  }
  .order-card {
    padding: 16px;
  }
  .order-id {
    font-size: 16px;
  }
  .info-icon {
    width: 32px;
    height: 32px;
  }
  .info-icon i {
    font-size: 14px;
  }
  .btn-assign {
    padding: 12px 16px;
    font-size: 13px;
  }
}
</style>
