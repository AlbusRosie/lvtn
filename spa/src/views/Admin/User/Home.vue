<template>
  <div class="reports-page">
    <!-- Statistics Overview - 5 Main Cards -->
    <div class="stats-grid-main">
      <div class="stat-card-large">
        <div class="stat-icon-large" style="background: #ECFDF5; color: #10B981;">
          <i class="fas fa-dollar-sign"></i>
        </div>
        <div class="stat-info-large">
          <div class="stat-label-large">Total Revenue</div>
          <div class="stat-value-large">{{ formatCurrency(reportStats.totalRevenue || 0) }}</div>
          <div class="stat-indicator positive" v-if="orderStats.revenueChange">
            <i class="fas fa-arrow-up"></i>
            <span>{{ orderStats.revenueChange }}% growth</span>
          </div>
        </div>
      </div>
      <div class="stat-card-large">
        <div class="stat-icon-large" style="background: #DBEAFE; color: #2563EB;">
          <i class="fas fa-shopping-cart"></i>
        </div>
        <div class="stat-info-large">
          <div class="stat-label-large">Total Orders</div>
          <div class="stat-value-large">{{ reportStats.totalOrders || 0 }}</div>
          <div class="stat-indicator positive" v-if="orderStats.completedOrders">
            <i class="fas fa-check-circle"></i>
            <span>{{ orderStats.completedOrders }} completed</span>
          </div>
        </div>
      </div>
      <div class="stat-card-large">
        <div class="stat-icon-large" style="background: #FEF3C7; color: #D97706;">
          <i class="fas fa-users"></i>
        </div>
        <div class="stat-info-large">
          <div class="stat-label-large">Total Customers</div>
          <div class="stat-value-large">{{ reportStats.totalCustomers || 0 }}</div>
          <div class="stat-indicator positive" v-if="orderStats.newCustomers">
            <i class="fas fa-user-plus"></i>
            <span>{{ orderStats.newCustomers }} new customers</span>
          </div>
        </div>
      </div>
      <div class="stat-card-large">
        <div class="stat-icon-large" style="background: #F3E8FF; color: #9333EA;">
          <i class="fas fa-calculator"></i>
        </div>
        <div class="stat-info-large">
          <div class="stat-label-large">Average Revenue per Order</div>
          <div class="stat-value-large">{{ formatCurrency(averageOrderValue) }}</div>
          <div class="stat-indicator positive" v-if="averageOrderValue > 0">
            <i class="fas fa-chart-line"></i>
            <span>Average value</span>
          </div>
        </div>
      </div>
      <div class="stat-card-large stat-card-ratio">
        <div class="stat-info-large">
          <div class="stat-ratio-content">
            <div class="ratio-donut-wrapper">
              <Doughnut 
                :data="ratioChartData"
                :options="ratioChartOptions"
              />
            </div>
            <div class="ratio-legend">
              <div class="ratio-legend-item">
                <div class="ratio-legend-color" style="background: #10B981;"></div>
                <div class="ratio-legend-label">Success</div>
                <div class="ratio-legend-value">{{ successRate }}%</div>
              </div>
              <div class="ratio-legend-item">
                <div class="ratio-legend-color" style="background: #EF4444;"></div>
                <div class="ratio-legend-label">Cancelled</div>
                <div class="ratio-legend-value">{{ cancelRate }}%</div>
              </div>
              <div class="ratio-legend-item" v-if="remainingRate > 0">
                <div class="ratio-legend-color" style="background: #E2E8F0;"></div>
                <div class="ratio-legend-label">Processing</div>
                <div class="ratio-legend-value">{{ remainingRate }}%</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Reports Content -->
    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Loading reports...</p>
      </div>
      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadReports" class="btn btn-secondary">
          Retry
        </button>
      </div>
      <div v-else class="reports-content">
        <!-- Middle Row: Revenue Chart (Large) + Side Sections -->
        <div class="dashboard-middle-row">
          <!-- Revenue Chart - Large -->
          <div class="report-section revenue-chart-large">
            <div class="section-header">
              <h3>Revenue Over Time</h3>
              <div class="period-filter-header">
                <button 
                  @click="setCommonPeriod('day')"
                  :class="['period-filter-btn', { active: commonPeriod === 'day' }]"
                >
                  Day
                </button>
                <button 
                  @click="setCommonPeriod('week')"
                  :class="['period-filter-btn', { active: commonPeriod === 'week' }]"
                >
                  Week
                </button>
                <button 
                  @click="setCommonPeriod('month')"
                  :class="['period-filter-btn', { active: commonPeriod === 'month' }]"
                >
                  Month
                </button>
                <button 
                  @click="setCommonPeriod('year')"
                  :class="['period-filter-btn', { active: commonPeriod === 'year' }]"
                >
                  Year
                </button>
              </div>
            </div>
            <div class="chart-container-wrapper">
              <RevenueChart 
                :data="revenueChartData"
                :period="commonPeriod"
                :loading="revenueChartLoading"
                :date-from="chartDateFrom"
                :date-to="chartDateTo"
                @period-change="onRevenuePeriodChange"
                @navigate="navigateChartPeriod"
                @date-range-change="onChartDateRangeChange"
                @pan="loadMoreChartData"
              />
            </div>
          </div>
          <!-- Right Side: Order Stats + Top Products -->
          <div class="dashboard-side-column">
            <!-- Order Stats -->
            <div class="report-section compact">
              <div class="section-header">
                <h3>Order Statistics</h3>
              </div>
              <div class="order-stats-grid-compact">
                <div class="order-stat-item-compact">
                  <div class="order-stat-icon-compact" style="background: #DBEAFE; color: #2563EB;">
                    <i class="fas fa-shopping-cart"></i>
                  </div>
                  <div class="order-stat-info-compact">
                    <div class="order-stat-value-compact">{{ filteredOrderStats.totalOrders || 0 }}</div>
                    <div class="order-stat-label-compact">Total Orders</div>
                  </div>
                </div>
                <div class="order-stat-item-compact">
                  <div class="order-stat-icon-compact" style="background: #D1FAE5; color: #059669;">
                    <i class="fas fa-dollar-sign"></i>
                  </div>
                  <div class="order-stat-info-compact">
                    <div class="order-stat-value-compact">{{ formatCompactCurrency(filteredOrderStats.revenue || 0) }}</div>
                    <div class="order-stat-label-compact">Revenue</div>
                  </div>
                </div>
                <div class="order-stat-item-compact">
                  <div class="order-stat-icon-compact" style="background: #FEF3C7; color: #D97706;">
                    <i class="fas fa-table"></i>
                  </div>
                  <div class="order-stat-info-compact">
                    <div class="order-stat-value-compact">{{ filteredOrderStats.reservations || 0 }}</div>
                    <div class="order-stat-label-compact">Reservations</div>
                  </div>
                </div>
                <div class="order-stat-item-compact">
                  <div class="order-stat-icon-compact" style="background: #FEE2E2; color: #DC2626;">
                    <i class="fas fa-shopping-bag"></i>
                  </div>
                  <div class="order-stat-info-compact">
                    <div class="order-stat-value-compact">{{ filteredOrderStats.takeawayOrders || 0 }}</div>
                    <div class="order-stat-label-compact">Takeaway Orders</div>
                  </div>
                </div>
              </div>
            </div>
            <!-- Top Products -->
            <div class="report-section compact">
              <div class="section-header">
                <h3>Top Products</h3>
                <span class="section-badge">{{ topProducts.length }}</span>
              </div>
              <div v-if="topProducts.length === 0" class="empty-data compact">
                <i class="fas fa-box-open"></i>
                <p>No data available</p>
              </div>
              <div v-else class="top-products-list compact">
                <div 
                  v-for="(product, index) in topProducts.slice(0, 5)" 
                  :key="product.product_id || index"
                  :class="['product-item', 'compact', { 'top-three': index < 3, 'top-other': index >= 3 }]"
                >
                  <div :class="['product-rank', `rank-${index + 1}`]">{{ index + 1 }}</div>
                  <div v-if="product.image_url || product.image" class="product-image">
                    <img :src="product.image_url || product.image" :alt="product.product_name || product.name" />
                  </div>
                  <div v-else class="product-image-placeholder">
                    <i class="fas fa-image"></i>
                  </div>
                  <div class="product-info">
                    <div class="product-name">{{ product.product_name || product.name || 'N/A' }}</div>
                    <div class="product-stats">
                      <span class="stat-badge small">
                        {{ product.total_quantity || 0 }} sold
                      </span>
                    </div>
                  </div>
                  <div class="product-revenue">{{ formatCurrency(product.total_revenue || 0) }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <!-- Bottom Row: Recent Orders -->
        <div class="report-section recent-orders-section">
          <div class="section-header">
            <h3>Recent Orders</h3>
            <button @click="goToOrders" class="btn-view-all">
              View All
              <i class="fas fa-arrow-right"></i>
            </button>
          </div>
          <div v-if="safeRecentOrders.length === 0" class="empty-data">
            <i class="fas fa-shopping-cart"></i>
            <p>No orders yet</p>
          </div>
          <div v-else class="recent-orders-table">
            <table class="orders-table">
              <thead>
                <tr>
                  <th>Order ID</th>
                  <th>Customer</th>
                  <th>Branch</th>
                  <th>Total</th>
                  <th>Status</th>
                  <th>Created Date</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="order in safeRecentOrders.slice(0, 5)" :key="order.id">
                  <td class="order-id">#{{ order.id }}</td>
                  <td class="customer-name">{{ order.customer_name || 'N/A' }}</td>
                  <td class="branch-name">{{ order.branch_name || 'N/A' }}</td>
                  <td class="order-total">{{ formatCurrency(order.total_amount || 0) }}</td>
                  <td>
                    <span class="status-badge" :class="`status-${order.status}`">
                      {{ getStatusLabel(order.status) }}
                    </span>
                  </td>
                  <td class="order-date">{{ formatDate(order.created_at) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { inject } from 'vue';
import { useRouter } from 'vue-router';
import { Doughnut } from 'vue-chartjs';
import {
  Chart as ChartJS,
  ArcElement,
  Tooltip,
  Legend
} from 'chart.js';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import RevenueChart from '@/components/Charts/RevenueChart.vue';
import ReportService from '@/services/ReportService';
import OrderService from '@/services/OrderService';
import ReservationService from '@/services/ReservationService';
import AuthService from '@/services/AuthService';
ChartJS.register(ArcElement, Tooltip, Legend);
export default {
  name: 'Home',
  components: {
    LoadingSpinner,
    RevenueChart,
    Doughnut
  },
  props: {
    isManagerView: {
      type: Boolean,
      default: false
    },
    managerBranchId: {
      type: Number,
      default: null
    }
  },
  setup() {
    const toast = inject('toast');
    const router = useRouter();
    return { toast, router };
  },
  data() {
    return {
      loading: false,
      error: null,
      reportStats: {
        totalRevenue: 0,
        totalOrders: 0,
        totalCustomers: 0,
        totalProducts: 0
      },
      orderStats: {
        completedOrders: 0,
        pendingOrders: 0,
        preparingOrders: 0,
        cancelledOrders: 0,
        revenueChange: 0,
        newCustomers: 0
      },
      topProducts: [],
      commonPeriod: 'month', 
      filteredOrderStatsData: {
        totalOrders: 0,
        revenue: 0,
        reservations: 0,
        takeawayOrders: 0
      },
      recentOrders: [],
      revenueData: [],
      revenueChartData: {
        labels: [],
        datasets: [],
        summary: {}
      },
      revenueChartLoading: false,
      chartDateFrom: '',
      chartDateTo: '',
      tooltip: {
        show: false,
        x: 0,
        y: 0,
        date: '',
        value: 0
      }
    };
  },
  computed: {
    isAdmin() {
      return AuthService.isAdmin();
    },
    maxRevenue() {
      if (this.revenueData.length === 0) return 1;
      return Math.max(...this.revenueData.map(item => item.value || 0), 1);
    },
    maxProductQuantity() {
      if (this.topProducts.length === 0) return 1;
      return Math.max(...this.topProducts.map(p => p.total_quantity || 0), 1);
    },
    safeRecentOrders() {
      return Array.isArray(this.recentOrders) ? this.recentOrders : [];
    },
    yAxisTicks() {
      if (this.maxRevenue === 0) return [0];
      const ticks = 5;
      const step = this.maxRevenue / ticks;
      const result = [];
      for (let i = ticks; i >= 0; i--) {
        result.push(Math.round(step * i));
      }
      return result;
    },
    totalOrders() {
      return this.filteredOrderStatsData.totalOrders || 0;
    },
    averageOrderValue() {
      const totalOrders = this.filteredOrderStatsData.totalOrders || 0;
      const revenue = this.filteredOrderStatsData.revenue || 0;
      if (totalOrders === 0) return 0;
      return revenue / totalOrders;
    },
    successRate() {
      const total = this.filteredOrderStatsData.totalOrders || 0;
      if (total === 0) return 0;
      const completed = this.orderStats.completedOrders || 0;
      return Math.round((completed / total) * 100);
    },
    cancelRate() {
      const total = this.filteredOrderStatsData.totalOrders || 0;
      if (total === 0) return 0;
      const cancelled = this.orderStats.cancelledOrders || 0;
      return Math.round((cancelled / total) * 100);
    },
    remainingRate() {
      const total = this.filteredOrderStatsData.totalOrders || 0;
      if (total === 0) return 0;
      const success = Math.round((this.successRate / 100) * total);
      const cancel = Math.round((this.cancelRate / 100) * total);
      const other = Math.max(0, total - success - cancel);
      return Math.round((other / total) * 100);
    },
    ratioChartData() {
      const total = this.filteredOrderStatsData.totalOrders || 0;
      if (total === 0) {
        return {
          labels: ['Success', 'Cancelled'],
          datasets: [{
            data: [0, 0],
            backgroundColor: ['#10B981', '#EF4444'],
            borderWidth: 0
          }]
        };
      }
      const success = Math.round((this.successRate / 100) * total);
      const cancel = Math.round((this.cancelRate / 100) * total);
      const other = Math.max(0, total - success - cancel);
      return {
        labels: ['Success', 'Cancelled', 'Other'],
        datasets: [{
          data: [success, cancel, other],
          backgroundColor: [
            '#10B981', 
            '#EF4444', 
            '#E2E8F0'  
          ],
          borderWidth: 0
        }]
      };
    },
    ratioChartOptions() {
      return {
        responsive: true,
        maintainAspectRatio: true,
        aspectRatio: 1,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            enabled: false
          }
        },
        cutout: '75%'
      };
    },
    filteredOrderStats() {
      return this.filteredOrderStatsData;
    }
  },
  async mounted() {
    this.initializeChartDateRange();
    await this.loadReports();
    await this.loadFilteredOrderStats();
  },
  methods: {
    async loadReports() {
      this.loading = true;
      this.error = null;
      try {
        const filters = {};
        if (this.isManagerView && this.managerBranchId) {
          filters.branch_id = this.managerBranchId;
        }
        const [
          revenueReport,
          orderReport,
          customerReport,
          productReport,
          orderStatistics,
          topProductsData,
          recentOrdersData
        ] = await Promise.all([
          ReportService.getRevenueReport(filters).catch((err) => {
            return { total: 0, revenue: 0, data: [] };
          }),
          ReportService.getOrderReport(filters).catch((err) => {
            return { total: 0, count: 0 };
          }),
          ReportService.getCustomerReport(filters).catch((err) => {
            return { total: 0, count: 0 };
          }),
          ReportService.getProductReport(filters).catch((err) => {
            return { total: 0, count: 0 };
          }),
          OrderService.getOrderStatistics(filters).catch((err) => {
            return {};
          }),
          OrderService.getTopProducts({ ...filters, ...this.getCommonPeriodDateRange(), limit: 10 }).catch((err) => {
            return [];
          }),
          OrderService.getAllOrders({ ...filters, page: 1, limit: 10 }).catch((err) => {
            return { items: [], data: [] };
          })
        ]);
        this.reportStats = {
          totalRevenue: revenueReport?.total || revenueReport?.revenue || revenueReport?.data?.total || 0,
          totalOrders: orderReport?.total || orderReport?.count || orderReport?.data?.total || 0,
          totalCustomers: customerReport?.total || customerReport?.count || customerReport?.data?.total || 0,
          totalProducts: productReport?.total || productReport?.count || productReport?.data?.total || 0
        };
        if (orderStatistics && Object.keys(orderStatistics).length > 0) {
          this.orderStats = {
            completedOrders: orderStatistics.completed || orderStatistics.completed_orders || orderStatistics.completed_count || 0,
            pendingOrders: orderStatistics.pending || orderStatistics.pending_orders || orderStatistics.pending_count || 0,
            preparingOrders: orderStatistics.preparing || orderStatistics.preparing_orders || orderStatistics.preparing_count || 0,
            cancelledOrders: orderStatistics.cancelled || orderStatistics.cancelled_orders || orderStatistics.cancelled_count || 0,
            revenueChange: orderStatistics.revenue_change || orderStatistics.revenueChange || 0,
            newCustomers: orderStatistics.new_customers || orderStatistics.newCustomers || 0
          };
        } else {
          this.orderStats = {
            completedOrders: 0,
            pendingOrders: 0,
            preparingOrders: 0,
            cancelledOrders: 0,
            revenueChange: 0,
            newCustomers: 0
          };
        }
        let products = [];
        if (Array.isArray(topProductsData)) {
          products = topProductsData;
        } else if (topProductsData?.data && Array.isArray(topProductsData.data)) {
          products = topProductsData.data;
        } else if (topProductsData?.items && Array.isArray(topProductsData.items)) {
          products = topProductsData.items;
        }
        this.topProducts = products.map(product => ({
          ...product,
          product_name: product.name || product.product_name || 'N/A',
          name: product.name || product.product_name || 'N/A'
        }));
        let orders = [];
        if (recentOrdersData) {
          if (Array.isArray(recentOrdersData)) {
            orders = recentOrdersData;
          } else if (Array.isArray(recentOrdersData.items)) {
            orders = recentOrdersData.items;
          } else if (Array.isArray(recentOrdersData.data)) {
            orders = recentOrdersData.data;
          } else if (recentOrdersData.orders && Array.isArray(recentOrdersData.orders)) {
            orders = recentOrdersData.orders;
          }
        }
        this.recentOrders = orders.map(order => ({
          ...order,
          total_amount: order.total || order.total_amount || 0
        }));
        this.generateRevenueData(revenueReport);
        await this.generateRevenueChartData();
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while loading the report';
        this.error = errorMessage;
        if (this.toast) {
          this.toast.error(errorMessage);
        }
      } finally {
        this.loading = false;
      }
    },
    generateRevenueData(revenueReport = null) {
      const days = [];
      const today = new Date();
      const dateMap = new Map(); 
      if (revenueReport && revenueReport.data && Array.isArray(revenueReport.data)) {
        revenueReport.data.forEach(day => {
          if (day.date) {
            const dateStr = new Date(day.date).toISOString().split('T')[0]; 
            dateMap.set(dateStr, parseFloat(day.revenue) || 0);
          }
        });
      }
      for (let i = 6; i >= 0; i--) {
        const date = new Date(today);
        date.setDate(date.getDate() - i);
        date.setHours(0, 0, 0, 0);
        const dateStr = date.toISOString().split('T')[0]; 
        const dayName = date.toLocaleDateString(this.isManagerView ? 'en-US' : 'vi-VN', { weekday: 'short' });
        const dayNumber = date.getDate();
        const revenue = dateMap.get(dateStr) || 0;
        days.push({
          label: `${dayName}\n${dayNumber}`,
          value: revenue
        });
      }
      this.revenueData = days;
    },
    refreshReports() {
      this.loadReports();
    },
    formatCurrency(amount) {
      return new Intl.NumberFormat('vi-VN', {
        style: 'currency',
        currency: 'VND'
      }).format(amount);
    },
    formatCompactCurrency(amount) {
      if (!amount || amount === 0) return '0 ₫';
      const millions = amount / 1000000;
      const billions = amount / 1000000000;
      if (billions >= 1) {
        return (billions % 1 === 0 ? billions : billions.toFixed(1)) + ' tỷ ₫';
      } else if (millions >= 1) {
        return (millions % 1 === 0 ? millions : millions.toFixed(1)) + ' triệu ₫';
      } else {
        return new Intl.NumberFormat('vi-VN', {
          style: 'currency',
          currency: 'VND',
          maximumFractionDigits: 0
        }).format(amount);
      }
    },
    formatDate(dateString) {
      if (!dateString) return '-';
      const date = new Date(dateString);
      return date.toLocaleDateString('vi-VN', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    },
    getStatusLabel(status) {
      const labels = {
        'pending': 'Pending',
        'confirmed': 'Confirmed',
        'preparing': 'Preparing',
        'ready': 'Ready',
        'delivering': 'Delivering',
        'completed': 'Completed',
        'cancelled': 'Cancelled'
      };
      return labels[status] || status;
    },
    goToOrders() {
      this.router.push('/admin/orders');
    },
    showTooltip(event, item) {
      const rect = event.currentTarget.getBoundingClientRect();
      const chartRect = event.currentTarget.closest('.chart-wrapper').getBoundingClientRect();
      this.tooltip = {
        show: true,
        x: rect.left - chartRect.left + rect.width / 2,
        y: chartRect.top - rect.top - 50,
        date: item.label,
        value: item.value
      };
    },
    hideTooltip() {
      this.tooltip.show = false;
    },
    initializeChartDateRange() {
      const dateRange = this.getCommonPeriodDateRange();
      this.chartDateFrom = dateRange.date_from;
      this.chartDateTo = dateRange.date_to;
    },
    async loadMoreChartData(direction) {
      if (!this.chartDateFrom || !this.chartDateTo) {
        this.initializeChartDateRange();
        await this.generateRevenueChartData();
        return;
      }
      let from = new Date(this.chartDateFrom);
      let to = new Date(this.chartDateTo);
      const diff = Math.ceil((to - from) / (1000 * 60 * 60 * 24));
      if (direction === 'left') {
        from.setDate(from.getDate() - diff);
        to.setDate(to.getDate() - diff);
      } else if (direction === 'right') {
        const today = new Date();
        const maxTo = new Date(today);
        from.setDate(from.getDate() + diff);
        to.setDate(to.getDate() + diff);
        if (to > maxTo) {
          to = new Date(maxTo);
          from = new Date(maxTo);
          from.setDate(from.getDate() - diff);
        }
      }
      this.chartDateFrom = from.toISOString().split('T')[0];
      this.chartDateTo = to.toISOString().split('T')[0];
      await this.generateRevenueChartData();
    },
    async generateRevenueChartData() {
      this.revenueChartLoading = true;
      try {
        const filters = {};
        if (this.isManagerView && this.managerBranchId) {
          filters.branch_id = this.managerBranchId;
        }
        let fromDate, toDate;
        const today = new Date();
        if (this.chartDateFrom && this.chartDateTo) {
          fromDate = new Date(this.chartDateFrom);
          toDate = new Date(this.chartDateTo);
        } else {
          fromDate = new Date(today);
          fromDate.setDate(fromDate.getDate() - 7);
          toDate = new Date(today);
        }
        filters.date_from = fromDate.toISOString().split('T')[0];
        filters.date_to = toDate.toISOString().split('T')[0];
        filters.limit = 1000;
        const chartResult = await OrderService.getAllOrders(filters);
        const ordersData = chartResult.orders || [];
        const groupedData = {};
        const summary = {
          total: 0,
          average: 0,
          max: 0,
          min: Infinity
        };
        const getPeriodKey = (date) => {
          const d = new Date(date);
          if (this.commonPeriod === 'day') {
            return d.toISOString().split('T')[0];
          } else if (this.commonPeriod === 'week') {
            const weekStart = new Date(d);
            weekStart.setDate(d.getDate() - d.getDay());
            return weekStart.toISOString().split('T')[0];
          } else if (this.commonPeriod === 'month') {
            return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
          } else if (this.commonPeriod === 'year') {
            return `${d.getFullYear()}`;
          }
          return d.toISOString().split('T')[0];
        };
        ordersData.forEach(order => {
          if (order.status === 'completed' && order.total) {
            const periodKey = getPeriodKey(order.created_at);
            if (!groupedData[periodKey]) {
              groupedData[periodKey] = {
                dine_in: 0,
                delivery: 0
              };
            }
            if (order.order_type === 'dine_in') {
              groupedData[periodKey].dine_in += parseFloat(order.total) || 0;
            } else if (order.order_type === 'delivery') {
              groupedData[periodKey].delivery += parseFloat(order.total) || 0;
            }
          }
        });
        const sortedPeriods = Object.keys(groupedData).sort();
        sortedPeriods.forEach(period => {
          const total = groupedData[period].dine_in + groupedData[period].delivery;
          summary.total += total;
          if (total > summary.max) summary.max = total;
          if (total < summary.min) summary.min = total;
        });
        if (sortedPeriods.length > 0) {
          summary.average = summary.total / sortedPeriods.length;
        } else {
          summary.min = 0;
        }
        const formatPeriodLabel = (period, periodType) => {
          if (periodType === 'day') {
            const date = new Date(period);
            const dayName = date.toLocaleDateString(this.isManagerView ? 'en-US' : 'vi-VN', { weekday: 'short' });
            const dayNumber = date.getDate();
            return `${dayName}\n${dayNumber}`;
          } else if (periodType === 'week') {
            const date = new Date(period);
            if (this.isManagerView) {
              return `Week ${date.getDate()}/${date.getMonth() + 1}`;
            }
            return `Tuần ${date.getDate()}/${date.getMonth() + 1}`;
          } else if (periodType === 'month') {
            const [year, month] = period.split('-');
            if (this.isManagerView) {
              const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              return monthNames[parseInt(month) - 1] || period;
            }
            const monthNames = ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
              'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];
            return monthNames[parseInt(month) - 1] || period;
          } else if (periodType === 'year') {
            return this.isManagerView ? `Year ${period}` : `Năm ${period}`;
          }
          return period;
        };
        const labels = sortedPeriods.map(period => formatPeriodLabel(period, this.commonPeriod));
        const datasets = [
          {
            label: this.isManagerView ? 'Dine In' : 'Tại chỗ',
            data: sortedPeriods.map(period => groupedData[period].dine_in),
            fill: true
          },
          {
            label: this.isManagerView ? 'Delivery' : 'Giao hàng',
            data: sortedPeriods.map(period => groupedData[period].delivery),
            fill: true
          }
        ];
        this.revenueChartData = {
          labels,
          datasets,
          summary
        };
      } catch (err) {
        this.revenueChartData = {
          labels: [],
          datasets: [],
          summary: {
            total: 0,
            average: 0,
            max: 0,
            min: 0
          }
        };
      } finally {
        this.revenueChartLoading = false;
      }
    },
    async onRevenuePeriodChange(period) {
      this.commonPeriod = period;
      await Promise.all([
        this.generateRevenueChartData(),
        this.loadFilteredOrderStats(),
        this.loadTopProducts()
      ]);
    },
    async navigateChartPeriod(direction) {
      if (!this.chartDateFrom || !this.chartDateTo) {
        this.initializeChartDateRange();
        await this.generateRevenueChartData();
        return;
      }
      let from = new Date(this.chartDateFrom);
      let to = new Date(this.chartDateTo);
      const diff = Math.ceil((to - from) / (1000 * 60 * 60 * 24));
      if (direction === 'today') {
        const today = new Date();
        to = new Date(today);
        from = new Date(today);
        from.setDate(from.getDate() - diff);
      } else if (direction === 'prev') {
        from.setDate(from.getDate() - diff - 1);
        to.setDate(to.getDate() - diff - 1);
      } else if (direction === 'next') {
        const today = new Date();
        const maxTo = new Date(today);
        from.setDate(from.getDate() + diff + 1);
        to.setDate(to.getDate() + diff + 1);
        if (to > maxTo) {
          to = new Date(maxTo);
          from = new Date(maxTo);
          from.setDate(from.getDate() - diff);
        }
      }
      this.chartDateFrom = from.toISOString().split('T')[0];
      this.chartDateTo = to.toISOString().split('T')[0];
      await this.generateRevenueChartData();
    },
    async onChartDateRangeChange(from, to) {
      if (from) this.chartDateFrom = from;
      if (to) this.chartDateTo = to;
      await this.generateRevenueChartData();
    },
    getCommonPeriodDateRange() {
      const now = new Date();
      let dateFrom, dateTo;
      if (this.commonPeriod === 'day') {
        dateTo = new Date(now);
        dateTo.setHours(23, 59, 59, 999);
        dateFrom = new Date(now);
        dateFrom.setDate(dateFrom.getDate() - 30);
        dateFrom.setHours(0, 0, 0, 0);
      } else if (this.commonPeriod === 'week') {
        dateTo = new Date(now);
        dateTo.setHours(23, 59, 59, 999);
        dateFrom = new Date(now);
        dateFrom.setDate(dateFrom.getDate() - (12 * 7));
        dateFrom.setHours(0, 0, 0, 0);
      } else if (this.commonPeriod === 'month') {
        dateTo = new Date(now);
        dateTo.setHours(23, 59, 59, 999);
        dateFrom = new Date(now);
        dateFrom.setMonth(dateFrom.getMonth() - 12);
        dateFrom.setDate(1);
        dateFrom.setHours(0, 0, 0, 0);
      } else if (this.commonPeriod === 'year') {
        dateTo = new Date(now);
        dateTo.setHours(23, 59, 59, 999);
        dateFrom = new Date(now);
        dateFrom.setFullYear(dateFrom.getFullYear() - 5);
        dateFrom.setMonth(0);
        dateFrom.setDate(1);
        dateFrom.setHours(0, 0, 0, 0);
      } else {
        dateTo = new Date(now);
        dateTo.setHours(23, 59, 59, 999);
        dateFrom = new Date(now);
        dateFrom.setMonth(dateFrom.getMonth() - 12);
        dateFrom.setDate(1);
        dateFrom.setHours(0, 0, 0, 0);
      }
      return {
        date_from: dateFrom.toISOString().split('T')[0],
        date_to: dateTo.toISOString().split('T')[0]
      };
    },
    async setCommonPeriod(period) {
      this.commonPeriod = period;
      this.initializeChartDateRange();
      await Promise.all([
        this.generateRevenueChartData(),
        this.loadFilteredOrderStats(),
        this.loadTopProducts()
      ]);
    },
    async loadFilteredOrderStats() {
      try {
        const filters = {};
        if (this.isManagerView && this.managerBranchId) {
          filters.branch_id = this.managerBranchId;
        }
        const dateRange = this.getCommonPeriodDateRange();
        filters.date_from = dateRange.date_from;
        filters.date_to = dateRange.date_to;
        filters.limit = 10000; 
        const ordersResult = await OrderService.getAllOrders(filters);
        const orders = ordersResult.orders || ordersResult.data?.orders || [];
        const reservationsResult = await ReservationService.getAllReservations({
          branch_id: filters.branch_id,
          start_date: dateRange.date_from,
          end_date: dateRange.date_to
        });
        const reservations = Array.isArray(reservationsResult) 
          ? reservationsResult 
          : (reservationsResult.data || reservationsResult.reservations || []);
        const totalOrders = orders.length;
        const revenue = orders.reduce((sum, order) => sum + (parseFloat(order.total) || 0), 0);
        const reservationsCount = reservations.length;
        const takeawayOrders = orders.filter(order => order.order_type === 'takeaway').length;
        const completedOrders = orders.filter(order => order.status === 'completed').length;
        const cancelledOrders = orders.filter(order => order.status === 'cancelled').length;
        this.orderStats.completedOrders = completedOrders;
        this.orderStats.cancelledOrders = cancelledOrders;
        this.filteredOrderStatsData = {
          totalOrders,
          revenue,
          reservations: reservationsCount,
          takeawayOrders
        };
      } catch (err) {
        this.filteredOrderStatsData = {
          totalOrders: 0,
          revenue: 0,
          reservations: 0,
          takeawayOrders: 0
        };
      }
    },
    async loadTopProducts() {
      try {
        const filters = {};
        if (this.isManagerView && this.managerBranchId) {
          filters.branch_id = this.managerBranchId;
        }
        const dateRange = this.getCommonPeriodDateRange();
        const topProductsData = await OrderService.getTopProducts({ 
          ...filters, 
          ...dateRange, 
          limit: 10 
        });
        let products = [];
        if (Array.isArray(topProductsData)) {
          products = topProductsData;
        } else if (topProductsData?.data && Array.isArray(topProductsData.data)) {
          products = topProductsData.data;
        } else if (topProductsData?.items && Array.isArray(topProductsData.items)) {
          products = topProductsData.items;
        }
        this.topProducts = products.map(product => ({
          ...product,
          product_name: product.name || product.product_name || 'N/A',
          name: product.name || product.product_name || 'N/A'
        }));
      } catch (err) {
        this.topProducts = [];
      }
    }
  }
};
</script>
<style scoped>
.reports-page {
  padding: 20px;
  min-height: 100vh;
}
.stats-grid-main {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}
.stat-card-large {
  background: white;
  border-radius: 12px;
  padding: 14px;
  display: flex;
  align-items: center;
  gap: 12px;
  border: 1px solid #E2E8F0;
}
.stat-icon-large {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}
.stat-info-large {
  flex: 1;
  min-width: 0;
}
.stat-label-large {
  font-size: 12px;
  color: #64748B;
  font-weight: 500;
  margin-bottom: 4px;
  letter-spacing: 0.1px;
}
.stat-value-large {
  font-size: 20px;
  font-weight: 700;
  color: #1E293B;
  line-height: 1.2;
  word-wrap: break-word;
  letter-spacing: -0.2px;
  margin-bottom: 2px;
}
.stat-indicator {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 600;
  margin-top: 6px;
}
.stat-indicator.positive {
  color: #10B981;
}
.stat-indicator i {
  font-size: 10px;
}
.stat-card-ratio {
  align-items: center;
}
.stat-card-ratio .stat-info-large {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.stat-ratio-content {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
}
.ratio-donut-wrapper {
  position: relative;
  width: 50px;
  height: 50px;
  flex-shrink: 0;
}
.ratio-legend {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
  justify-content: center;
  min-width: 0;
}
.ratio-legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
}
.ratio-legend-color {
  width: 6px;
  height: 6px;
  border-radius: 2px;
  flex-shrink: 0;
}
.ratio-legend-label {
  font-size: 12px;
  color: #64748B;
  font-weight: 500;
  flex: 1;
  min-width: 0;
}
.ratio-legend-value {
  font-size: 13px;
  font-weight: 700;
  color: #1E293B;
  flex-shrink: 0;
  text-align: right;
  min-width: 35px;
}
.stat-card {
  background: white;
  border-radius: 14px;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 14px;
  border: 1px solid #E2E8F0;
}
.stat-icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}
.stat-info {
  flex: 1;
  min-width: 0;
}
.stat-value {
  font-size: 18px;
  font-weight: 700;
  color: #1E293B;
  line-height: 1.3;
  word-wrap: break-word;
  letter-spacing: -0.3px;
}
.stat-label {
  font-size: 12px;
  color: #64748B;
  font-weight: 500;
  margin-top: 4px;
  letter-spacing: 0.2px;
}
.loading,
.error {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
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
.reports-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.dashboard-middle-row {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 16px;
  margin-bottom: 16px;
  align-items: stretch;
  min-height: 800px;
}
.dashboard-middle-row > * {
  height: 100%;
}
.dashboard-side-column {
  display: flex;
  flex-direction: column;
  gap: 16px;
  height: 100%;
  justify-content: flex-start;
  overflow: visible;
}
.revenue-chart-large {
  grid-column: 1;
  height: 100%;
  display: flex;
  flex-direction: column;
}
.revenue-chart-large .report-section {
  display: flex;
  flex-direction: column;
}
.revenue-chart-large .report-section:first-child {
  flex: 1;
  min-height: 0;
}
.chart-container-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
  background: white;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid #E2E8F0;
}
.recent-orders-section {
  width: 100%;
}
.report-section {
  background: #FAFBFC;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #E2E8F0;
}
.report-section.compact {
  padding: 16px;
  display: flex;
  flex-direction: column;
  overflow: visible;
}
.dashboard-side-column .report-section.compact:not(.filter-section):first-of-type {
  padding: 16px;
  width: 100%;
}
.dashboard-side-column .report-section.compact {
  display: flex;
  flex-direction: column;
}
.dashboard-side-column .report-section.compact.filter-section {
  flex: 0 0 auto;
  margin-bottom: 0;
}
.dashboard-side-column .report-section.compact:not(.filter-section):first-of-type {
  flex: 0 0 auto;
  height: fit-content;
  min-height: auto;
  width: 100%;
}
.dashboard-side-column .report-section.compact:not(.filter-section):last-of-type {
  flex: 1;
  min-height: 0;
  width: 100%;
}
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 2px solid #E2E8F0;
  gap: 16px;
}
.dashboard-side-column .report-section.compact:not(.filter-section):first-of-type .section-header {
  margin-bottom: 16px;
  padding-bottom: 12px;
}
.section-header h3 {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
  color: #1E293B;
  letter-spacing: -0.2px;
  flex-shrink: 0;
}
.period-filter-header {
  display: flex;
  gap: 4px;
  align-items: center;
}
.period-filter-btn {
  padding: 6px 16px;
  border: 1px solid #E2E8F0;
  background: #F8F9FA;
  color: #64748B;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}
.period-filter-btn:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.period-filter-btn.active {
  background: #FF8C42;
  color: white;
  border-color: #FF8C42;
}
.period-filter-btn.active:hover {
  background: #E67E22;
  border-color: #E67E22;
}
.chart-legend {
  display: flex;
  gap: 16px;
  align-items: center;
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #6B7280;
}
.legend-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}
.section-badge {
  padding: 4px 12px;
  background: #F3F4F6;
  border: 1px solid #E5E7EB;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  color: #6B7280;
}
.top-products-filter,
.order-stats-filter {
  display: flex;
  gap: 6px;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #E2E8F0;
}
.filter-btn {
  flex: 1;
  padding: 6px 10px;
  border: 1px solid #E2E8F0;
  background: white;
  color: #64748B;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: center;
}
.filter-btn:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.filter-btn.active {
  background: #FF8C42;
  color: white;
  border-color: #FF8C42;
}
.filter-btn.active:hover {
  background: #E67E22;
  border-color: #E67E22;
}
.filter-section {
  flex: 0 0 auto !important;
  padding: 12px;
}
.filter-buttons-unified {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
  margin-top: 4px;
}
.filter-btn-unified {
  padding: 8px 12px;
  border: 1px solid #E2E8F0;
  background: white;
  color: #64748B;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: center;
  white-space: nowrap;
}
.filter-btn-unified:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
  transform: translateY(-1px);
}
.filter-btn-unified.active {
  background: #FF8C42;
  color: white;
  border-color: #FF8C42;
  box-shadow: 0 2px 4px rgba(255, 140, 66, 0.2);
}
.filter-btn-unified.active:hover {
  background: #E67E22;
  border-color: #E67E22;
  transform: translateY(-1px);
  box-shadow: 0 2px 6px rgba(255, 140, 66, 0.3);
}
.chart-container {
  background: white;
  border-radius: 12px;
  padding: 16px;
  min-height: 200px;
  border: 1px solid #E2E8F0;
}
.chart-container.compact {
  min-height: 180px;
  padding: 14px;
}
.chart-placeholder,
.empty-data {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 30px 10px;
  text-align: center;
  background: white;
  border-radius: 6px;
  border: 2px dashed #E5E5E5;
}
.chart-placeholder.compact,
.empty-data.compact {
  padding: 20px 10px;
  min-height: 140px;
}
.chart-placeholder i,
.empty-data i {
  font-size: 32px;
  color: #9CA3AF;
  margin-bottom: 8px;
}
.chart-placeholder.compact i,
.empty-data.compact i {
  font-size: 24px;
}
.chart-placeholder p,
.empty-data p {
  margin: 0;
  color: #6B7280;
  font-size: 12px;
}
.chart-wrapper {
  height: 200px;
  display: flex;
  align-items: flex-end;
  padding: 12px 0;
}
.chart-wrapper.compact {
  height: 180px;
  padding: 10px 0;
}
.chart-y-axis {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  height: 100%;
  padding-right: 8px;
  min-width: 80px;
}
.y-axis-tick {
  display: flex;
  align-items: center;
  gap: 8px;
  position: relative;
  height: 0;
}
.y-axis-label {
  font-size: 11px;
  color: #64748B;
  font-weight: 600;
  white-space: nowrap;
  min-width: 70px;
  text-align: right;
}
.y-axis-line {
  width: 1px;
  height: 1px;
  background: transparent;
}
.chart-area {
  flex: 1;
  position: relative;
  height: 100%;
  display: flex;
  flex-direction: column;
}
.chart-grid {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  pointer-events: none;
}
.grid-line {
  width: 100%;
  height: 1px;
  background: #E2E8F0;
  opacity: 0.6;
}
.chart-bars {
  display: flex;
  align-items: flex-end;
  justify-content: space-around;
  width: 100%;
  height: 100%;
  gap: 12px;
  position: relative;
  z-index: 1;
}
.chart-bar-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 100%;
  gap: 10px;
}
.bar-container {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}
.bar {
  width: 100%;
  max-width: 44px;
  background: #FF8C42;
  border-radius: 8px 8px 0 0;
  cursor: pointer;
  min-height: 4px;
  position: relative;
  overflow: visible;
}
.bar:hover {
  background: #E67E22;
}
.bar-value {
  position: absolute;
  top: -28px;
  left: 50%;
  transform: translateX(-50%);
  background: #1E293B;
  color: white;
  padding: 4px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 700;
  white-space: nowrap;
  opacity: 0;
  transition: opacity 0.3s ease;
  pointer-events: none;
  z-index: 10;
}
.bar-value::after {
  content: '';
  position: absolute;
  bottom: -4px;
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 0;
  border-left: 4px solid transparent;
  border-right: 4px solid transparent;
  border-top: 4px solid #334155;
}
.bar:hover .bar-value {
  opacity: 1;
}
.bar-label {
  font-size: 11px;
  color: #475569;
  text-align: center;
  white-space: pre-line;
  line-height: 1.4;
  font-weight: 600;
  margin-top: 8px;
  letter-spacing: 0.2px;
}
.chart-tooltip {
  position: absolute;
  background: #1E293B;
  color: white;
  padding: 10px 14px;
  border-radius: 8px;
  font-size: 12px;
  z-index: 1000;
  pointer-events: none;
  transform: translateX(-50%);
  animation: tooltipFadeIn 0.2s ease;
}
.chart-tooltip::after {
  content: '';
  position: absolute;
  bottom: -6px;
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 0;
  border-left: 6px solid transparent;
  border-right: 6px solid transparent;
  border-top: 6px solid #334155;
}
.tooltip-date {
  font-weight: 600;
  margin-bottom: 4px;
  color: #F1F5F9;
}
.tooltip-value {
  font-size: 14px;
  font-weight: 700;
  color: #FFD700;
}
@keyframes tooltipFadeIn {
  from {
    opacity: 0;
    transform: translateX(-50%) translateY(-4px);
  }
  to {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
  }
}
.top-products-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  overflow-y: auto;
  overflow-x: hidden;
  flex: 1;
  min-height: 0;
  padding-right: 4px;
}
.top-products-list.compact {
  gap: 8px;
  max-height: 100%;
}
.top-products-list::-webkit-scrollbar {
  width: 6px;
}
.top-products-list::-webkit-scrollbar-track {
  background: transparent;
}
.top-products-list::-webkit-scrollbar-thumb {
  background: #E2E8F0;
  border-radius: 3px;
}
.top-products-list::-webkit-scrollbar-thumb:hover {
  background: #CBD5E1;
}
.product-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: white;
  border-radius: 10px;
  border: 1px solid #E2E8F0;
}
.product-item.compact {
  padding: 10px;
  gap: 10px;
}
.product-item.top-three {
  background: white;
  border-color: #E2E8F0;
}
.product-item.top-other {
  background: white;
  border-color: #F1F5F9;
}
.product-item.top-other .product-name {
  color: #94A3B8;
  font-weight: 500;
}
.product-item.top-other .product-revenue {
  color: #94A3B8;
}
.product-item.top-other .stat-badge {
  background: #F8F9FA;
  border-color: #E2E8F0;
  color: #94A3B8;
}
.product-item.top-other .product-rank {
  background: #E2E8F0;
  color: #94A3B8;
}
.product-rank {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #E2E8F0;
  color: #64748B;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 12px;
  flex-shrink: 0;
}
.product-rank.rank-1 {
  background: #FEF3C7;
  color: #D97706;
}
.product-rank.rank-2 {
  background: #E2E8F0;
  color: #475569;
}
.product-rank.rank-3 {
  background: #FED7AA;
  color: #C2410C;
}
.product-image,
.product-image-placeholder {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  overflow: hidden;
  flex-shrink: 0;
  background: #F3F4F6;
  display: flex;
  align-items: center;
  justify-content: center;
}
.product-item.top-three .product-image,
.product-item.top-three .product-image-placeholder {
  width: 48px;
  height: 48px;
}
.product-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.product-image-placeholder i {
  font-size: 20px;
  color: #9CA3AF;
}
.product-item.top-other .product-image-placeholder i {
  color: #CBD5E1;
}
.product-info {
  flex: 1;
  min-width: 0;
}
.product-name {
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  margin-bottom: 6px;
  word-wrap: break-word;
  line-height: 1.4;
  letter-spacing: -0.2px;
}
.product-stats {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.stat-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
  background: #F1F5F9;
  border: 1px solid #E2E8F0;
  border-radius: 6px;
  font-size: 11px;
  color: #475569;
  font-weight: 600;
}
.stat-badge.small {
  font-size: 10px;
  padding: 3px 6px;
}
.stat-badge.revenue {
  background: #ECFDF5;
  border-color: #10B981;
  color: #059669;
}
.stat-badge i {
  font-size: 10px;
}
.product-revenue {
  font-size: 13px;
  font-weight: 700;
  color: #10B981;
  flex-shrink: 0;
  white-space: nowrap;
  letter-spacing: -0.2px;
}
.order-stats-grid-compact {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  flex: 0 0 auto;
  height: fit-content;
}
.order-stat-item-compact {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: white;
  border-radius: 8px;
  border: 1px solid #E2E8F0;
}
.order-stat-item-compact:hover {
  border-color: #FF8C42;
}
.order-stat-icon-compact {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  flex-shrink: 0;
}
.order-stat-info-compact {
  flex: 1;
  min-width: 0;
}
.order-stat-value-compact {
  font-size: 18px;
  font-weight: 700;
  color: #1E293B;
  line-height: 1.3;
  letter-spacing: -0.2px;
}
.order-stat-label-compact {
  font-size: 12px;
  color: #64748B;
  margin-top: 4px;
  font-weight: 500;
}
.order-stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 16px;
}
.order-stat-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
  background: white;
  border-radius: 8px;
  border: 1px solid #F0E6D9;
}
.order-stat-icon {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}
.order-stat-info {
  flex: 1;
}
.order-stat-value {
  font-size: 18px;
  font-weight: 700;
  color: #1a1a1a;
  line-height: 1.2;
}
.order-stat-label {
  font-size: 12px;
  color: #6B7280;
  margin-top: 2px;
}
.recent-orders-table {
  overflow-x: auto;
}
.recent-orders-table.compact {
  max-height: 300px;
  overflow-y: auto;
}
.orders-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  background: white;
  border-radius: 10px;
  overflow: hidden;
  border: 1px solid #E2E8F0;
}
.orders-table.compact {
  font-size: 12px;
}
.orders-table thead {
  background: #F8F9FA;
}
.orders-table th {
  padding: 12px 14px;
  text-align: left;
  font-size: 11px;
  font-weight: 700;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 2px solid #E2E8F0;
}
.orders-table.compact th {
  padding: 10px 12px;
  font-size: 10px;
}
.orders-table tbody tr {
  border-bottom: 1px solid #F1F5F9;
}
.orders-table tbody tr:hover {
  background: #F8F9FA;
}
.orders-table td {
  padding: 12px 14px;
  font-size: 12px;
  color: #1E293B;
}
.orders-table.compact td {
  padding: 10px 12px;
  font-size: 11px;
}
.order-id {
  font-weight: 600;
  color: #FF8C42;
}
.customer-name {
  font-weight: 500;
}
.branch-name {
  color: #6B7280;
}
.order-total {
  font-weight: 600;
  color: #10B981;
}
.status-badge {
  padding: 5px 12px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  display: inline-block;
  letter-spacing: 0.2px;
}
.status-pending {
  background: #FFF5F0;
  color: #E67E22;
  border: 1px solid #FED7AA;
}
.status-confirmed {
  background: #DBEAFE;
  color: #2563EB;
  border: 1px solid #93C5FD;
}
.status-preparing {
  background: #FEF3C7;
  color: #D97706;
  border: 1px solid #FCD34D;
}
.status-ready {
  background: #D1FAE5;
  color: #059669;
  border: 1px solid #6EE7B7;
}
.status-delivering {
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
.order-date {
  color: #64748B;
  font-size: 11px;
}
.btn-view-all {
  padding: 8px 14px;
  border: 2px solid #E2E8F0;
  background: white;
  color: #475569;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  letter-spacing: 0.2px;
}
.btn-view-all.compact {
  padding: 6px 12px;
  font-size: 11px;
}
.btn-view-all:hover {
  border-color: #FF8C42;
  background: #FFF9F5;
  color: #FF8C42;
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
@media (max-width: 1400px) {
  .stats-grid-main {
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
  }
}
@media (max-width: 1200px) {
  .stats-grid-main {
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
  }
  .dashboard-middle-row {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  .chart-container.large {
    min-height: 240px;
  }
  .chart-wrapper.large {
    height: 240px;
    min-height: 240px;
  }
}
@media (max-width: 768px) {
  .reports-page {
    padding: 12px;
  }
  .stats-grid-main {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  .stat-card-large {
    padding: 12px;
    gap: 10px;
  }
  .stat-icon-large {
    width: 40px;
    height: 40px;
    font-size: 16px;
  }
  .stat-value-large {
    font-size: 16px;
  }
  .stat-label-large {
    font-size: 10px;
    margin-bottom: 3px;
  }
  .stat-ratio-content {
    flex-direction: row;
    align-items: center;
    gap: 8px;
  }
  .ratio-donut-wrapper {
    width: 45px;
    height: 45px;
  }
  .ratio-center-value {
    font-size: 10px;
  }
  .ratio-center-label {
    font-size: 6px;
  }
  .ratio-legend {
    gap: 4px;
  }
  .ratio-legend-color {
    width: 5px;
    height: 5px;
  }
  .ratio-legend-label {
    font-size: 8px;
  }
  .ratio-legend-value {
    font-size: 9px;
  }
  .dashboard-middle-row {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  .chart-container.large {
    min-height: 240px;
    padding: 16px;
  }
  .chart-wrapper.large {
    height: 240px;
    padding: 12px 0;
  }
  .chart-bars {
    gap: 6px;
  }
  .bar {
    max-width: 28px;
  }
  .bar-label {
    font-size: 9px;
  }
  .order-stats-grid-compact {
    grid-template-columns: 1fr;
  }
  .orders-table {
    font-size: 11px;
  }
  .orders-table th,
  .orders-table td {
    padding: 8px 10px;
  }
}
</style>
