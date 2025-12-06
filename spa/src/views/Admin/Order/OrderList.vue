<script setup>
import { ref, reactive, computed, onMounted, onBeforeUnmount, watch } from 'vue';
import OrderService from '@/services/OrderService';
import BranchService from '@/services/BranchService';
import UserService from '@/services/UserService';
import RevenueChart from '@/components/Charts/RevenueChart.vue';
import { useToast } from 'vue-toastification';
import { USER_ROLES, PAYMENT_STATUS } from '@/constants';
const props = defineProps({
  isManagerView: {
    type: Boolean,
    default: false
  },
  managerBranchId: {
    type: Number,
    default: null
  },
  hideBranchFilter: {
    type: Boolean,
    default: false
  }
});
const toast = useToast();
const orders = ref([]);
const branches = ref([]);
const isLoading = ref(true);
const error = ref(null);
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);
const itemsPerPage = ref(50);
const selectedBranch = ref(props.isManagerView && props.managerBranchId ? String(props.managerBranchId) : '');
const selectedStatus = ref('');
const selectedOrderType = ref('');
const selectedPaymentStatus = ref('');
const selectedPaymentMethod = ref('');
const dateFrom = ref('');
const dateTo = ref('');
const searchText = ref('');
const searchType = ref('all'); 
const sortBy = ref('created_at'); 
const sortOrder = ref('desc'); 
const selectedOrders = ref([]); 
const deliveryStaff = ref([]);
const showAssignModal = ref(false);
const orderToAssign = ref(null);
const selectedDeliveryStaff = ref('');
const isAssigning = ref(false);
const showExportModal = ref(false);
const exportFilters = reactive({
    dateFrom: '',
    dateTo: '',
    branch_id: '',
    status: '',
    order_type: '',
    payment_status: '',
    payment_method: ''
});
const isExporting = ref(false);
const statistics = ref({
    total_orders: 0,
    total_revenue: 0,
    average_order_value: 0,
    orders_by_status: {},
    orders_by_type: {}
});
const revenueChartData = ref({
    labels: [],
    datasets: [],
    summary: {}
});
const revenueChartLoading = ref(false);
const revenuePeriod = ref('week');
const chartDateFrom = ref('');
const chartDateTo = ref('');
const showCharts = ref(true);
const isChartExpanded = ref(false); 
const showQuickModal = ref(false);
const quickViewOrder = ref(null);
const isLoadingOrderDetails = ref(false);
const isUpdatingPayment = ref(false);
const orderLogs = ref([]);
const isLoadingLogs = ref(false);
const showLogsModal = ref(false);
const topProducts = ref([]);
const showDeleteModal = ref(false);
const orderToDelete = ref(null);
const deleteLoading = ref(false);
const showBulkDeleteModal = ref(false);
const bulkDeleteLoading = ref(false);
const showEditModal = ref(false);
const orderToEdit = ref(null);
const editForm = reactive({
    status: '',
    payment_status: '',
    payment_method: ''
});
const isUpdatingOrder = ref(false);
const lastOrderCount = ref(0);
const newOrdersCount = ref(0);
const pollingInterval = ref(null);
const isPollingEnabled = ref(true);
function initializeChartDateRange() {
    const today = new Date();
    const thirtyDaysAgo = new Date(today);
    thirtyDaysAgo.setDate(today.getDate() - 30);
    chartDateTo.value = today.toISOString().split('T')[0];
    chartDateFrom.value = thirtyDaysAgo.toISOString().split('T')[0];
}
const chartFilters = computed(() => {
  const filters = {};
  if (props.isManagerView && props.managerBranchId) {
    filters.branch_id = props.managerBranchId;
  } else if (selectedBranch.value) {
    filters.branch_id = selectedBranch.value;
  }
  if (dateFrom.value) filters.date_from = dateFrom.value;
  if (dateTo.value) filters.date_to = dateTo.value;
  return filters;
});
const filteredOrders = computed(() => {
    let result = [...orders.value];
    if (searchText.value) {
        const search = searchText.value.toLowerCase().trim();
        result = result.filter(order => {
            if (searchType.value === 'customer_name') {
                return (order.customer_name || '').toLowerCase().includes(search);
            } else if (searchType.value === 'phone') {
                return (order.customer_phone || '').includes(search);
            } else if (searchType.value === 'order_id') {
                return String(order.id).includes(search);
            } else {
                return (
                    (order.customer_name || '').toLowerCase().includes(search) ||
                    (order.customer_phone || '').includes(search) ||
                    String(order.id).includes(search)
                );
            }
        });
    }
    result.sort((a, b) => {
        let aVal, bVal;
        switch (sortBy.value) {
            case 'id':
                aVal = a.id;
                bVal = b.id;
                break;
            case 'total':
                aVal = parseFloat(a.total || 0);
                bVal = parseFloat(b.total || 0);
                break;
            case 'status':
                aVal = a.status;
                bVal = b.status;
                break;
            case 'created_at':
            default:
                aVal = new Date(a.created_at).getTime();
                bVal = new Date(b.created_at).getTime();
                break;
        }
        if (sortOrder.value === 'asc') {
            return aVal > bVal ? 1 : aVal < bVal ? -1 : 0;
        } else {
            return aVal < bVal ? 1 : aVal > bVal ? -1 : 0;
        }
    });
    return result;
});
const paginatedOrders = computed(() => {
    const start = (currentPage.value - 1) * itemsPerPage.value;
    const end = start + itemsPerPage.value;
    return filteredOrders.value.slice(start, end);
});
watch([filteredOrders, itemsPerPage], () => {
    totalCount.value = filteredOrders.value.length;
    totalPages.value = Math.max(1, Math.ceil(filteredOrders.value.length / itemsPerPage.value));
    if (currentPage.value > totalPages.value && totalPages.value > 0) {
        currentPage.value = totalPages.value;
    }
}, { immediate: true });
const statusOptions = computed(() => {
    const baseOptions = [
        { value: '', label: 'All Status' },
        { value: 'pending', label: 'Pending' },
        { value: 'preparing', label: 'Preparing' },
        { value: 'ready', label: 'Ready' },
        { value: 'out_for_delivery', label: 'Out for Delivery' },
        { value: 'completed', label: 'Completed' },
        { value: 'cancelled', label: 'Cancelled' }
    ];
    return baseOptions;
});
const orderTypeOptions = computed(() => {
    const baseOptions = [
        { value: '', label: props.isManagerView ? 'All Order Types' : 'Tất cả loại đơn' },
        { value: 'dine_in', label: props.isManagerView ? 'Dine In' : 'Tại quán' },
        { value: 'delivery', label: props.isManagerView ? 'Delivery' : 'Giao hàng' }
    ];
    return baseOptions;
});
const paymentStatusOptions = computed(() => {
    const baseOptions = [
        { value: '', label: props.isManagerView ? 'All Payment Status' : 'Tất cả trạng thái thanh toán' },
        { value: 'pending', label: props.isManagerView ? 'Pending Payment' : 'Chờ thanh toán' },
        { value: 'paid', label: props.isManagerView ? 'Paid' : 'Đã thanh toán' },
        { value: 'failed', label: props.isManagerView ? 'Payment Failed' : 'Thanh toán thất bại' }
    ];
    return baseOptions;
});
const paymentMethodOptions = computed(() => {
    const baseOptions = [
        { value: '', label: props.isManagerView ? 'All Payment Methods' : 'Tất cả phương thức' },
        { value: 'cash', label: props.isManagerView ? 'Cash' : 'Tiền mặt' }
    ];
    return baseOptions;
});
async function loadOrders(page = 1) {
    isLoading.value = true;
    error.value = null;
    currentPage.value = page; 
    try {
        const filters = {
            limit: 10000, 
            page: 1 
        };
        if (props.isManagerView && props.managerBranchId) {
            filters.branch_id = props.managerBranchId;
        } else if (selectedBranch.value) {
            filters.branch_id = selectedBranch.value;
        }
        if (selectedStatus.value) filters.status = selectedStatus.value;
        if (selectedOrderType.value) filters.order_type = selectedOrderType.value;
        if (selectedPaymentStatus.value) filters.payment_status = selectedPaymentStatus.value;
        if (selectedPaymentMethod.value) filters.payment_method = selectedPaymentMethod.value;
        if (dateFrom.value) filters.date_from = dateFrom.value;
        if (dateTo.value) filters.date_to = dateTo.value;
        const result = await OrderService.getAllOrders(filters);
        let allOrders = [];
        let paginationInfo = null;
        if (result.data) {
            if (result.data.orders) {
                allOrders = result.data.orders || [];
                paginationInfo = result.data.pagination;
            } else if (Array.isArray(result.data)) {
                allOrders = result.data;
            }
        } else if (result.orders) {
            allOrders = result.orders || [];
            paginationInfo = result.pagination;
        } else if (Array.isArray(result)) {
            allOrders = result;
        }
        if (paginationInfo && paginationInfo.pages && paginationInfo.pages > 1) {
            const totalPages = paginationInfo.pages;
            const allPagesPromises = [];
            for (let p = 2; p <= totalPages; p++) {
                const pageFilters = { ...filters, page: p, limit: 10000 };
                allPagesPromises.push(OrderService.getAllOrders(pageFilters));
            }
            const remainingPages = await Promise.all(allPagesPromises);
            remainingPages.forEach(pageResult => {
                let pageOrders = [];
                if (pageResult.data && pageResult.data.orders) {
                    pageOrders = pageResult.data.orders || [];
                } else if (pageResult.orders) {
                    pageOrders = pageResult.orders || [];
                } else if (Array.isArray(pageResult)) {
                    pageOrders = pageResult;
                }
                allOrders = allOrders.concat(pageOrders);
            });
        }
        allOrders.sort((a, b) => {
            const aTime = new Date(a.created_at).getTime();
            const bTime = new Date(b.created_at).getTime();
            return bTime - aTime; 
        });
        orders.value = allOrders;
        calculateOrdersByType();
        calculateOrdersByStatus();
    } catch (err) {
        error.value = 'Unable to load order list';
        toast.error(error.value);
    } finally {
isLoading.value = false;
    }
}
async function loadBranches() {
    try {
        const result = await BranchService.getAllBranches();
        branches.value = Array.isArray(result) ? result : [];
        if (branches.value.length === 0) {
            try {
                const activeResult = await BranchService.getActiveBranches();
                branches.value = Array.isArray(activeResult) ? activeResult : [];
            } catch (activeErr) {
                }
        }
    } catch (err) {
        showToast('error', 'Unable to load branch list', 'Unable to load branch list');
        try {
            const activeResult = await BranchService.getActiveBranches();
            branches.value = Array.isArray(activeResult) ? activeResult : [];
        } catch (fallbackErr) {
            }
    }
}
async function loadStatistics() {
    try {
        const filters = {};
        if (props.isManagerView && props.managerBranchId) {
            filters.branch_id = props.managerBranchId;
        } else if (selectedBranch.value) {
            filters.branch_id = selectedBranch.value;
        }
        if (chartDateFrom.value && chartDateTo.value) {
            filters.date_from = chartDateFrom.value;
            filters.date_to = chartDateTo.value;
        } else if (dateFrom.value && dateTo.value) {
            filters.date_from = dateFrom.value;
            filters.date_to = dateTo.value;
        }
        const stats = await OrderService.getOrderStatistics(filters);
        statistics.value = stats;
        calculateOrdersByType();
        calculateOrdersByStatus();
    } catch (err) {
        calculateOrdersByType();
    }
}
function getFilteredOrdersForStats() {
    if (!orders.value || orders.value.length === 0) {
        return [];
    }
    let filtered = orders.value;
    if (props.isManagerView && props.managerBranchId) {
        filtered = filtered.filter(order => order.branch_id === props.managerBranchId);
    } else if (selectedBranch.value) {
        filtered = filtered.filter(order => order.branch_id === selectedBranch.value);
    }
    let fromDate, toDate;
    if (chartDateFrom.value && chartDateTo.value) {
        fromDate = new Date(chartDateFrom.value);
        fromDate.setHours(0, 0, 0, 0);
        toDate = new Date(chartDateTo.value);
        toDate.setHours(23, 59, 59, 999);
    } else if (dateFrom.value && dateTo.value) {
        fromDate = new Date(dateFrom.value);
        fromDate.setHours(0, 0, 0, 0);
        toDate = new Date(dateTo.value);
        toDate.setHours(23, 59, 59, 999);
    }
    if (fromDate && toDate) {
        filtered = filtered.filter(order => {
            if (!order.created_at) return false;
            const orderDate = new Date(order.created_at);
            return orderDate >= fromDate && orderDate <= toDate;
        });
    }
    return filtered;
}
function calculateOrdersByType() {
    const ordersByType = {
        dine_in: 0,
        delivery: 0
    };
    const filtered = getFilteredOrdersForStats();
    filtered.forEach(order => {
        if (order.order_type === 'dine_in') {
            ordersByType.dine_in++;
        } else if (order.order_type === 'delivery') {
            ordersByType.delivery++;
        }
    });
    if (!statistics.value.orders_by_type) {
        statistics.value.orders_by_type = {};
    }
    statistics.value.orders_by_type = ordersByType;
}
function calculateOrdersByStatus() {
    const ordersByStatus = {
        pending: 0,
        preparing: 0,
        ready: 0,
        out_for_delivery: 0,
        completed: 0,
        cancelled: 0
    };
    const filtered = getFilteredOrdersForStats();
    filtered.forEach(order => {
        if (order.status && ordersByStatus.hasOwnProperty(order.status)) {
            ordersByStatus[order.status]++;
        }
    });
    let totalOrders = filtered.length;
    let totalRevenue = 0;
    filtered.forEach(order => {
        if (order.total) {
            totalRevenue += parseFloat(order.total) || 0;
        }
    });
    if (!statistics.value.orders_by_status) {
        statistics.value.orders_by_status = {};
    }
    statistics.value.orders_by_status = ordersByStatus;
    statistics.value.total_orders = totalOrders;
    statistics.value.total_revenue = totalRevenue;
    if (totalOrders > 0) {
        statistics.value.average_order_value = totalRevenue / totalOrders;
    } else {
        statistics.value.average_order_value = 0;
    }
}
async function loadTopProducts() {
    try {
        const filters = {};
        if (props.isManagerView && props.managerBranchId) {
            filters.branch_id = props.managerBranchId;
        } else if (selectedBranch.value) {
            filters.branch_id = selectedBranch.value;
        }
        const result = await OrderService.getTopProducts({ ...filters, limit: 4 });
        let products = [];
        if (Array.isArray(result)) {
            products = result;
        } else if (result?.data && Array.isArray(result.data)) {
            products = result.data;
        } else if (result?.products && Array.isArray(result.products)) {
            products = result.products;
        }
        topProducts.value = products.slice(0, 4);
    } catch (err) {
        topProducts.value = [];
    }
}
async function loadDeliveryStaff() {
    try {
        const result = await UserService.fetchUsers(1, 100, { role_id: USER_ROLES.DELIVERY_STAFF });
        deliveryStaff.value = result.users || [];
    } catch (err) {
        deliveryStaff.value = [];
    }
}
async function generateRevenueChartData() {
    revenueChartLoading.value = true;
    try {
        const chartFilters = {
            limit: 1000 
        };
        if (props.isManagerView && props.managerBranchId) {
            chartFilters.branch_id = props.managerBranchId;
        } else if (selectedBranch.value) {
            chartFilters.branch_id = selectedBranch.value;
        }
        let fromDate, toDate;
        const today = new Date();
        let actualPeriod = revenuePeriod.value; 
        let useMonthForYear = false; 
        if (chartDateFrom.value && chartDateTo.value) {
            fromDate = new Date(chartDateFrom.value);
            toDate = new Date(chartDateTo.value);
            if (revenuePeriod.value === 'year') {
                const daysDiff = Math.ceil((toDate - fromDate) / (1000 * 60 * 60 * 24));
                if (daysDiff <= 366) { 
                    useMonthForYear = true;
                }
            }
        } else if (dateFrom.value && dateTo.value) {
            fromDate = new Date(dateFrom.value);
            toDate = new Date(dateTo.value);
        } else {
            switch (revenuePeriod.value) {
                case 'day':
                    fromDate = new Date(today);
                    fromDate.setDate(fromDate.getDate() - 6);
                    toDate = new Date(today);
                    break;
                case 'week':
                    fromDate = new Date(today);
                    fromDate.setDate(fromDate.getDate() - 56); 
                    toDate = new Date(today);
                    break;
                case 'month':
                    fromDate = new Date(today.getFullYear(), today.getMonth() - 5, 1);
                    toDate = new Date(today);
                    break;
                case 'year':
                    const year = today.getFullYear();
                    fromDate = new Date(year, 0, 1);
                    toDate = new Date(year, 11, 31);
                    useMonthForYear = true; 
                    break;
            }
        }
        chartFilters.date_from = fromDate.toISOString().split('T')[0];
        chartFilters.date_to = toDate.toISOString().split('T')[0];
        const chartResult = await OrderService.getAllOrders(chartFilters);
        const ordersData = chartResult.orders || [];
    const groupedData = {};
    const summary = {
        total: 0,
        average: 0,
        max: 0,
        min: Infinity
    };
    const periodKeyFn = (date) => {
        if (revenuePeriod.value === 'year' && useMonthForYear) {
            return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        }
        return getPeriodKey(date, revenuePeriod.value);
    };
    ordersData.forEach(order => {
        if (order.status !== 'cancelled') {
            const date = new Date(order.created_at);
            const periodKey = periodKeyFn(date);
            if (!groupedData[periodKey]) {
                groupedData[periodKey] = {
                    dine_in: 0,
                    delivery: 0
                };
            }
            groupedData[periodKey][order.order_type] += parseFloat(order.total || 0);
            summary.total += parseFloat(order.total || 0);
        }
    });
    let sortedPeriods = Object.keys(groupedData).sort();
    const maxColumns = {
        'day': 7,       
        'week': 8,      
        'month': 6,     
        'year': 12      
    };
    const maxCols = maxColumns[actualPeriod] || 12;
    let allPeriods = [];
    const periodType = revenuePeriod.value === 'year' && useMonthForYear ? 'month' : revenuePeriod.value;
    if (periodType === 'day') {
        for (let i = 6; i >= 0; i--) {
            const d = new Date(today);
            d.setDate(d.getDate() - i);
            const key = getPeriodKey(d, 'day');
            allPeriods.push(key);
            if (!groupedData[key]) {
                groupedData[key] = { dine_in: 0, delivery: 0 };
            }
        }
        sortedPeriods = allPeriods;
    } else if (periodType === 'week') {
        sortedPeriods = sortedPeriods.slice(-maxCols);
    } else if (periodType === 'month') {
        if (revenuePeriod.value === 'year' && useMonthForYear) {
            const year = fromDate.getFullYear();
            for (let m = 0; m < 12; m++) {
                const key = `${year}-${String(m + 1).padStart(2, '0')}`;
                allPeriods.push(key);
                if (!groupedData[key]) {
                    groupedData[key] = { dine_in: 0, delivery: 0 };
                }
            }
            sortedPeriods = allPeriods;
        } else {
            sortedPeriods = sortedPeriods.slice(-maxCols);
        }
    } else if (periodType === 'year') {
        sortedPeriods = sortedPeriods.slice(-maxCols);
    }
    let labels;
    if (revenuePeriod.value === 'year' && useMonthForYear) {
        const monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        ];
        labels = sortedPeriods.map(period => {
            const [, monthNum] = period.split('-');
            return monthNames[parseInt(monthNum) - 1] || period;
        });
    } else {
        labels = sortedPeriods.map(period => formatPeriodLabel(period, revenuePeriod.value));
    }
    const datasets = [
        {
            label: 'Dine-in',
            data: sortedPeriods.map(period => groupedData[period].dine_in),
            fill: true
        },
        {
            label: 'Delivery',
            data: sortedPeriods.map(period => groupedData[period].delivery),
            fill: true
        }
    ];
    if (sortedPeriods.length > 0) {
        summary.average = summary.total / sortedPeriods.length;
        summary.max = Math.max(...sortedPeriods.map(period => 
            groupedData[period].dine_in + groupedData[period].delivery
        ));
        summary.min = Math.min(...sortedPeriods.map(period => 
            groupedData[period].dine_in + groupedData[period].delivery
        ));
    } else {
        summary.min = 0;
    }
    revenueChartData.value = {
        labels,
        datasets,
        summary
    };
    } catch (err) {
        revenueChartData.value = {
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
        revenueChartLoading.value = false;
    }
}
function getPeriodKey(date, period) {
    try {
        switch (period) {
            case 'day':
                return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
            case 'week':
                const year = date.getFullYear();
                const week = getWeekNumber(date);
                return `${year}-W${String(week).padStart(2, '0')}`;
            case 'month':
                return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
            case 'year':
                return `${date.getFullYear()}`;
            default:
                return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        }
    } catch (error) {
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
    }
}
function getWeekNumber(date) {
    const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const dayNum = d.getUTCDay() || 7;
    d.setUTCDate(d.getUTCDate() + 4 - dayNum);
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
}
function formatPeriodLabel(periodKey, period) {
    try {
        switch (period) {
            case 'day':
                const [year, month, day] = periodKey.split('-');
                return `${day}/${month}/${year}`;
            case 'week':
                const [yearWeek, weekStr] = periodKey.split('-W');
                const week = parseInt(weekStr);
                const date = new Date(yearWeek, 0, 1);
                const weekStart = new Date(date.getTime() + (week - 1) * 7 * 24 * 60 * 60 * 1000);
                const monthNames = [
                    'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'
                ];
                return `Week ${week} - ${monthNames[weekStart.getMonth()]} ${yearWeek}`;
            case 'month':
                const [yearMonth, monthNum] = periodKey.split('-');
                const monthNames2 = [
                    'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'
                ];
                return `${monthNames2[parseInt(monthNum) - 1]} ${yearMonth}`;
            case 'year':
                return `Year ${periodKey}`;
            default:
                return periodKey;
        }
    } catch (error) {
        return periodKey;
    }
}
async function onRevenuePeriodChange(period) {
    revenuePeriod.value = period;
    await Promise.all([
        generateRevenueChartData(),
        loadStatistics()
    ]);
}
async function setPeriod(period) {
    revenuePeriod.value = period;
    const today = new Date();
    let fromDate, toDate;
    switch (period) {
        case 'day':
            fromDate = new Date(today);
            fromDate.setDate(fromDate.getDate() - 30);
            toDate = new Date(today);
            break;
        case 'week':
            fromDate = new Date(today);
            fromDate.setDate(fromDate.getDate() - (12 * 7));
            toDate = new Date(today);
            break;
        case 'month':
            fromDate = new Date(today);
            fromDate.setMonth(fromDate.getMonth() - 12);
            fromDate.setDate(1);
            toDate = new Date(today);
            break;
        case 'year':
            fromDate = new Date(today);
            fromDate.setFullYear(fromDate.getFullYear() - 5);
            fromDate.setMonth(0);
            fromDate.setDate(1);
            toDate = new Date(today);
            break;
        default:
            fromDate = new Date(today);
            fromDate.setDate(fromDate.getDate() - 30);
            toDate = new Date(today);
    }
    chartDateFrom.value = fromDate.toISOString().split('T')[0];
    chartDateTo.value = toDate.toISOString().split('T')[0];
    await Promise.all([
        generateRevenueChartData(),
        loadStatistics()
    ]);
}
function navigateChartPeriod(direction) {
    const period = revenuePeriod.value;
    let from, to;
    if (!chartDateFrom.value || !chartDateTo.value || direction === 'today') {
        const today = new Date();
        switch (period) {
            case 'day':
                from = new Date(today);
                to = new Date(today);
                break;
            case 'week':
                const weekStart = new Date(today);
                weekStart.setDate(today.getDate() - today.getDay());
                from = weekStart;
                to = new Date(today);
                break;
            case 'month':
                from = new Date(today.getFullYear(), today.getMonth(), 1);
                const monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0);
                to = new Date(today);
                break;
            case 'year':
                from = new Date(today.getFullYear(), 0, 1);
                to = new Date(today);
                break;
        }
    } else {
        from = new Date(chartDateFrom.value);
        to = new Date(chartDateTo.value);
        if (direction === 'prev') {
            switch (period) {
                case 'day':
                    from.setDate(from.getDate() - 1);
                    to.setDate(to.getDate() - 1);
                    break;
                case 'week':
                    from.setDate(from.getDate() - 7);
                    to.setDate(to.getDate() - 7);
                    break;
                case 'month':
                    from.setMonth(from.getMonth() - 1);
                    to.setMonth(to.getMonth() - 1);
                    const lastDay = new Date(to.getFullYear(), to.getMonth() + 1, 0).getDate();
                    if (to.getDate() > lastDay) {
                        to.setDate(lastDay);
                    }
                    break;
                case 'year':
                    from.setFullYear(from.getFullYear() - 1);
                    to.setFullYear(to.getFullYear() - 1);
                    break;
            }
        } else if (direction === 'next') {
            switch (period) {
                case 'day':
                    from.setDate(from.getDate() + 1);
                    to.setDate(to.getDate() + 1);
                    break;
                case 'week':
                    from.setDate(from.getDate() + 7);
                    to.setDate(to.getDate() + 7);
                    break;
                case 'month':
                    from.setMonth(from.getMonth() + 1);
                    to.setMonth(to.getMonth() + 1);
                    const lastDay = new Date(to.getFullYear(), to.getMonth() + 1, 0).getDate();
                    if (to.getDate() > lastDay) {
                        to.setDate(lastDay);
                    }
                    break;
                case 'year':
                    from.setFullYear(from.getFullYear() + 1);
                    to.setFullYear(to.getFullYear() + 1);
                    break;
            }
        }
    }
    chartDateFrom.value = from.toISOString().split('T')[0];
    chartDateTo.value = to.toISOString().split('T')[0];
    generateRevenueChartData();
}
async function onChartDateRangeChange(from, to) {
    if (from) chartDateFrom.value = from;
    if (to) chartDateTo.value = to;
    await generateRevenueChartData();
}
async function toggleCharts() {
    await generateRevenueChartData();
}
async function updateOrderStatus(orderId, newStatus) {
    try {
        await OrderService.updateOrderStatus(orderId, newStatus);
        showToast('success', 'Order status updated successfully', 'Order status updated successfully');
        await loadOrders(currentPage.value);
        await loadStatistics();
    } catch (err) {
        showToast('error', 'Unable to update order status', 'Unable to update order status');
    }
}
async function cancelOrder(orderId) {
    const confirmMessage = 'Are you sure you want to cancel this order?';
    if (confirm(confirmMessage)) {
        try {
            await OrderService.cancelOrder(orderId);
            toast.success('Order cancelled successfully');
            await loadOrders(currentPage.value);
            await loadStatistics();
        } catch (err) {
            showToast('error', 'Unable to cancel order', 'Unable to cancel order');
        }
    }
}
function applyFilters() {
    currentPage.value = 1;
    loadOrders(1);
    loadStatistics();
    generateRevenueChartData();
}
function clearFilters() {
    selectedBranch.value = '';
    selectedStatus.value = '';
    selectedOrderType.value = '';
    selectedPaymentStatus.value = '';
    selectedPaymentMethod.value = '';
    dateFrom.value = '';
    dateTo.value = '';
    searchText.value = '';
    searchType.value = 'all';
    sortBy.value = 'created_at';
    sortOrder.value = 'desc';
    selectedOrders.value = [];
    applyFilters();
}
function getSearchPlaceholder() {
    switch (searchType.value) {
        case 'order_id':
            return 'Search by Order ID...';
            case 'customer_name':
            return 'Search by Customer Name...';
            case 'phone':
            return 'Search by Phone Number...';
            default:
            return 'Search orders...';
    }
}
function toggleOrderSelection(orderId) {
    const index = selectedOrders.value.indexOf(orderId);
    if (index > -1) {
        selectedOrders.value.splice(index, 1);
    } else {
        selectedOrders.value.push(orderId);
    }
}
function selectAllOrders() {
    if (selectedOrders.value.length === filteredOrders.value.length) {
        selectedOrders.value = [];
    } else {
        selectedOrders.value = filteredOrders.value.map(order => order.id);
    }
}
async function bulkUpdateStatus(status) {
    if (selectedOrders.value.length === 0) {
        showToast('warning', props.isManagerView ? 'Please select at least one order' : 'Vui lòng chọn ít nhất một đơn hàng', props.isManagerView ? 'Vui lòng chọn ít nhất một đơn hàng' : 'Please select at least one order');
        return;
    }
    if (!canBulkUpdateToStatus(status)) {
        toast.warning(props.isManagerView ? 'Cannot update status backwards. Please select orders that can be updated to this status.' : 'Không thể cập nhật trạng thái lùi. Vui lòng chọn đơn hàng có thể cập nhật sang trạng thái này.');
        return;
    }
    const confirmMessage = props.isManagerView 
        ? `Are you sure you want to update ${selectedOrders.value.length} order(s) status to "${getStatusLabel(status)}"?`
        : `Bạn có chắc muốn cập nhật trạng thái ${selectedOrders.value.length} đơn hàng thành "${getStatusLabel(status)}"?`;
    if (confirm(confirmMessage)) {
        try {
            const promises = selectedOrders.value.map(orderId => 
                OrderService.updateOrderStatus(orderId, status)
            );
            await Promise.all(promises);
            showToast('success', props.isManagerView ? `Updated ${selectedOrders.value.length} order(s) status successfully` : `Đã cập nhật trạng thái ${selectedOrders.value.length} đơn hàng thành công`, props.isManagerView ? `Đã cập nhật trạng thái ${selectedOrders.value.length} đơn hàng thành công` : `Updated ${selectedOrders.value.length} order(s) status successfully`);
            selectedOrders.value = [];
            await loadOrders(currentPage.value);
            await loadStatistics();
            await generateRevenueChartData();
        } catch (err) {
            toast.error('An error occurred while updating status');
        }
    }
}
function bulkDeleteOrders() {
    if (selectedOrders.value.length === 0) {
        toast.warning('Please select at least one order');
        return;
    }
    showBulkDeleteModal.value = true;
}
async function confirmBulkDelete() {
    if (selectedOrders.value.length === 0) return;
    bulkDeleteLoading.value = true;
    try {
        const promises = selectedOrders.value.map(orderId => 
            OrderService.deleteOrder(orderId)
        );
        await Promise.all(promises);
        const successMsg = props.isManagerView 
            ? `Deleted ${selectedOrders.value.length} order(s) successfully`
            : `Đã xóa ${selectedOrders.value.length} đơn hàng thành công`;
        toast.success(successMsg);
        selectedOrders.value = [];
        showBulkDeleteModal.value = false;
        await loadOrders(currentPage.value);
        await loadStatistics();
        await generateRevenueChartData();
    } catch (err) {
        showToast('error', props.isManagerView ? 'Unable to delete order' : 'Không thể xóa đơn hàng', props.isManagerView ? 'Không thể xóa đơn hàng' : 'Unable to delete order');
    } finally {
        bulkDeleteLoading.value = false;
    }
}
async function showQuickDetails(order) {
    quickViewOrder.value = order;
    showQuickModal.value = true;
    isLoadingOrderDetails.value = true;
    try {
        const orderDetails = await OrderService.getOrderById(order.id);
        quickViewOrder.value = {
            ...order,
            ...orderDetails,
            items: orderDetails.items || orderDetails.order_details || []
        };
    } catch (err) {
        toast.error('Unable to load order details');
    } finally {
        isLoadingOrderDetails.value = false;
    }
}
async function loadOrderLogs(orderId) {
    isLoadingLogs.value = true;
    try {
        const logs = await OrderService.getOrderLogs(orderId);
        orderLogs.value = logs || [];
        showLogsModal.value = true;
    } catch (err) {
        showToast('error', 'Unable to load change history', 'Unable to load change history');
    } finally {
        isLoadingLogs.value = false;
    }
}
function getActionLabel(action) {
    const labels = {
        status_change: 'Status Changed',
        payment_status_change: 'Payment Status Changed',
        note_update: 'Note Updated',
        delivery_assigned: 'Delivery Assigned'
    };
    return labels[action] || action;
}
function getLogActionClass(action) {
    const classes = {
        status_change: 'log-status',
        payment_status_change: 'log-payment',
        note_update: 'log-note',
        delivery_assigned: 'log-delivery'
    };
    return classes[action] || '';
}
const statusOrder = {
    'pending': 1,
    'preparing': 2,
    'ready': 3,
    'out_for_delivery': 4,
    'completed': 5,
    'cancelled': 6
};
function getStatusOrderValue(status) {
    return statusOrder[status] || 0;
}
function canUpdateToStatus(targetStatus, currentStatus) {
    if (currentStatus === 'completed' || currentStatus === 'cancelled') {
        return false;
    }
    const currentOrder = getStatusOrderValue(currentStatus);
    const targetOrder = getStatusOrderValue(targetStatus);
    return targetOrder >= currentOrder;
}
function canBulkUpdateToStatus(status) {
    if (selectedOrders.value.length === 0) return false;
    const selectedOrderObjects = filteredOrders.value.filter(order => 
        selectedOrders.value.includes(order.id)
    );
    const canUpdate = selectedOrderObjects.every(order => 
        canUpdateToStatus(status, order.status)
    );
    return canUpdate;
}
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
            return props.isManagerView ? 'Cannot change status of completed/cancelled orders' : 'Không thể thay đổi trạng thái của đơn hàng đã hoàn thành/hủy';
        }
        return props.isManagerView ? 'Cannot revert to previous status' : 'Không thể quay lại trạng thái trước đó';
    }
    return props.isManagerView ? `Thay đổi trạng thái thành: ${getStatusLabel(statusValue)}` : `Change status to: ${getStatusLabel(statusValue)}`;
}
async function updateQuickOrderStatus(newStatus) {
    if (!quickViewOrder.value || isUpdatingPayment.value) return;
    if (isStatusDisabled(newStatus, quickViewOrder.value.status)) {
        showToast('warning', props.isManagerView ? 'Cannot change to this status' : 'Không thể thay đổi sang trạng thái này', props.isManagerView ? 'Không thể thay đổi sang trạng thái này' : 'Cannot change to this status');
        return;
    }
    isUpdatingPayment.value = true;
    try {
        await OrderService.updateOrderStatus(quickViewOrder.value.id, newStatus);
        quickViewOrder.value.status = newStatus;
        const successMsg = props.isManagerView 
            ? `Order status updated to "${getStatusLabel(newStatus)}" successfully`
            : `Đã cập nhật trạng thái đơn hàng thành "${getStatusLabel(newStatus)}" thành công`;
        toast.success(successMsg);
        await loadOrders(currentPage.value);
        await loadStatistics();
    } catch (err) {
        showToast('error', 'Unable to update order status', 'Unable to update order status');
        await showQuickDetails(quickViewOrder.value);
    } finally {
        isUpdatingPayment.value = false;
    }
}
async function updatePaymentStatusHandler() {
    if (!quickViewOrder.value || isUpdatingPayment.value) return;
    isUpdatingPayment.value = true;
    try {
        await OrderService.updatePaymentStatus(
            quickViewOrder.value.id, 
            quickViewOrder.value.payment_status,
            quickViewOrder.value.payment_method || null
        );
        showToast('success', 'Payment status updated successfully', 'Payment status updated successfully');
        await loadOrders(currentPage.value);
        await loadStatistics();
    } catch (err) {
        toast.error('Unable to update payment status');
        await showQuickDetails(quickViewOrder.value);
    } finally {
        isUpdatingPayment.value = false;
    }
}
function printInvoice() {
    if (!quickViewOrder.value) return;
    const printWindow = window.open('', '_blank');
    const order = quickViewOrder.value;
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
    invoiceHTML += '<p><strong>Name:</strong> ' + (order.customer_name || 'N/A') + '</p>';
    invoiceHTML += '<p><strong>Phone:</strong> ' + (order.customer_phone || 'N/A') + '</p></div>';
    invoiceHTML += '<div class="info-section"><h3>Order Information</h3>';
    invoiceHTML += '<p><strong>Branch:</strong> ' + (order.branch_name || 'N/A') + '</p>';
    invoiceHTML += '<p><strong>Order Type:</strong> ' + getOrderTypeLabel(order.order_type) + '</p>';
    if (order.table_id) {
        invoiceHTML += '<p><strong>Table:</strong> #' + order.table_id + '</p>';
    }
    if (order.delivery_address) {
        invoiceHTML += '<p><strong>Address:</strong> ' + order.delivery_address + '</p>';
    }
    invoiceHTML += '</div></div>';
    invoiceHTML += '<table><thead><tr>';
    invoiceHTML += '<th>No.</th><th>Item Name</th>';
    invoiceHTML += '<th class="text-right">Quantity</th>';
    invoiceHTML += '<th class="text-right">Unit Price</th>';
    invoiceHTML += '<th class="text-right">Total</th></tr></thead><tbody>';
    const items = order.items || [];
    items.forEach((item, index) => {
        const price = item.price || item.total || 0;
        const quantity = item.quantity || 1;
        const total = price * quantity;
        invoiceHTML += '<tr>';
        invoiceHTML += '<td>' + (index + 1) + '</td>';
        let productDisplay = (item.product_name || item.name || 'N/A');
        if (item.special_instructions) {
            if (isJsonString(item.special_instructions)) {
                const formattedOptions = formatItemOptions(item.special_instructions);
                if (formattedOptions) {
                    productDisplay += '<br><small style="color: #666; font-style: italic;">* ' + formattedOptions + '</small>';
                }
            } else {
                productDisplay += '<br><small style="color: #666; font-style: italic;">* ' + item.special_instructions + '</small>';
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
    invoiceHTML += '<div class="total-row"><span>Total Items:</span>';
    invoiceHTML += '<span>' + (order.items_count || items.length || 0) + '</span></div>';
    invoiceHTML += '<div class="total-row total-amount"><span>TOTAL:</span>';
    invoiceHTML += '<span>' + formatCurrency(order.total) + '</span></div>';
    invoiceHTML += '<div class="total-row" style="margin-top: 10px;">';
    invoiceHTML += '<span>Payment Status:</span>';
    invoiceHTML += '<span>' + getPaymentStatusLabel(order.payment_status) + '</span></div>';
    if (order.payment_method) {
        invoiceHTML += '<div class="total-row">';
        invoiceHTML += '<span>Payment Method:</span>';
        invoiceHTML += '<span>' + getPaymentMethodLabel(order.payment_method) + '</span></div>';
    }
    invoiceHTML += '</div>';
    invoiceHTML += '<div class="footer">';
    invoiceHTML += '<p>Thank you for using our service!</p>';
    invoiceHTML += '<p>Electronic Invoice - No signature required</p></div>';
    invoiceHTML += '<' + 'script' + '>window.onload = function() { };<' + '/script' + '>';
    invoiceHTML += '</body></html>';
    printWindow.document.write(invoiceHTML);
    printWindow.document.close();
}
function printKitchenTicket() {
    if (!quickViewOrder.value) return;
    const printWindow = window.open('', '_blank');
    const order = quickViewOrder.value;
    let kitchenHTML = '<!DOCTYPE html><html><head><meta charset="UTF-8">';
    kitchenHTML += '<title>Kitchen Ticket #' + order.id + '</title>';
    kitchenHTML += '<style>* { margin: 0; padding: 0; box-sizing: border-box; }';
    kitchenHTML += 'body { font-family: Arial, sans-serif; padding: 20px; font-size: 14px; }';
    kitchenHTML += '.kitchen-header { text-align: center; margin-bottom: 20px; border-bottom: 3px solid #333; padding-bottom: 15px; }';
    kitchenHTML += '.kitchen-header h1 { font-size: 28px; margin-bottom: 8px; font-weight: bold; }';
    kitchenHTML += '.order-info { margin-bottom: 20px; padding: 15px; background: #F5F5F5; border-radius: 8px; }';
    kitchenHTML += '.order-info-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 13px; }';
    kitchenHTML += '.order-info-row strong { font-weight: bold; }';
    kitchenHTML += '.items-section { margin-top: 20px; }';
    kitchenHTML += '.item-row { padding: 10px 0; border-bottom: 1px solid #ddd; display: flex; justify-content: space-between; align-items: center; }';
    kitchenHTML += '.item-name { font-weight: bold; font-size: 15px; }';
    kitchenHTML += '.item-quantity { font-size: 18px; font-weight: bold; color: #FF8C42; }';
    kitchenHTML += '.special-instructions { margin-top: 5px; font-size: 12px; color: #666; font-style: italic; }';
    kitchenHTML += '.footer-note { margin-top: 30px; padding-top: 15px; border-top: 2px solid #333; text-align: center; font-size: 12px; font-weight: bold; }';
    kitchenHTML += '@media print { body { padding: 10px; } .no-print { display: none; } }</style></head><body>';
    kitchenHTML += '<div class="kitchen-header"><h1>KITCHEN TICKET</h1>';
    kitchenHTML += '<p style="font-size: 18px; font-weight: bold;">Order #' + order.id + '</p>';
    kitchenHTML += '<p>' + formatDate(order.created_at) + '</p></div>';
    kitchenHTML += '<div class="order-info">';
    kitchenHTML += '<div class="order-info-row"><span><strong>Branch:</strong></span>';
    kitchenHTML += '<span>' + (order.branch_name || 'N/A') + '</span></div>';
    if (order.table_id) {
        kitchenHTML += '<div class="order-info-row"><span><strong>Table:</strong></span>';
        kitchenHTML += '<span>#' + order.table_id + '</span></div>';
    }
    if (order.delivery_address) {
        kitchenHTML += '<div class="order-info-row"><span><strong>Delivery Address:</strong></span>';
        kitchenHTML += '<span>' + order.delivery_address + '</span></div>';
    }
    kitchenHTML += '<div class="order-info-row"><span><strong>Customer:</strong></span>';
    kitchenHTML += '<span>' + (order.customer_name || 'N/A') + '</span></div>';
    if (order.notes) {
        kitchenHTML += '<div class="order-info-row"><span><strong>Notes:</strong></span>';
        kitchenHTML += '<span>' + order.notes + '</span></div>';
    }
    kitchenHTML += '</div>';
    kitchenHTML += '<div class="items-section">';
    kitchenHTML += '<h2 style="font-size: 18px; margin-bottom: 15px; text-align: center;">ITEMS LIST</h2>';
    const items = order.items || [];
    items.forEach((item, index) => {
        kitchenHTML += '<div class="item-row">';
        kitchenHTML += '<div style="flex: 1;">';
        kitchenHTML += '<div class="item-name">' + (index + 1) + '. ' + (item.product_name || item.name || 'N/A') + '</div>';
        if (item.special_instructions) {
            if (isJsonString(item.special_instructions)) {
                const formattedOptions = formatItemOptions(item.special_instructions);
                if (formattedOptions) {
                    kitchenHTML += '<div class="special-instructions">* ' + formattedOptions + '</div>';
                }
            } else {
                kitchenHTML += '<div class="special-instructions">* ' + item.special_instructions + '</div>';
            }
        }
        kitchenHTML += '</div>';
        kitchenHTML += '<div class="item-quantity" style="min-width: 60px; text-align: center; padding: 8px 15px; background: #FF8C42; color: white; border-radius: 8px; font-size: 20px;">';
        kitchenHTML += 'x' + (item.quantity || 1);
        kitchenHTML += '</div></div>';
    });
    kitchenHTML += '</div>';
    kitchenHTML += '<div class="footer-note">';
    kitchenHTML += '<p>** In tại: ' + new Date().toLocaleString('vi-VN') + ' **</p>';
    kitchenHTML += '<p style="margin-top: 10px;">Total: ' + (order.items_count || items.length || 0) + ' items</p>';
    kitchenHTML += '</div>';
    kitchenHTML += '<' + 'script' + '>window.onload = function() { };<' + '/script' + '>';
    kitchenHTML += '</body></html>';
    printWindow.document.write(kitchenHTML);
    printWindow.document.close();
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
function isJsonString(str) {
    if (typeof str !== 'string') return false;
    try {
        const parsed = JSON.parse(str);
        return Array.isArray(parsed) && parsed.length > 0 && parsed[0].option_name;
    } catch (e) {
        return false;
    }
}
function formatLikes(likes) {
    if (!likes || likes === 0) return '0';
    if (likes >= 1000000) {
        return (likes / 1000000).toFixed(1) + 'M';
    } else if (likes >= 1000) {
        return (likes / 1000).toFixed(0) + 'K';
    }
    return likes.toString();
}
function handleImageError(event) {
    event.target.src = '/images/placeholder-product.png';
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
function getStatusBadgeClass(status) {
    const classes = {
        pending: 'badge-warning',
        preparing: 'badge-info',
        ready: 'badge-primary',
        out_for_delivery: 'badge-secondary',
        completed: 'badge-success',
        cancelled: 'badge-danger'
    };
    return classes[status] || 'badge-secondary';
}
function getStatusLabel(status) {
    const labels = {
        pending: 'Pending',
        preparing: 'Preparing',
        ready: 'Ready',
        out_for_delivery: 'Out for Delivery',
        completed: 'Completed',
        cancelled: 'Cancelled'
    };
    return labels[status] || status;
}
function getOrderTypeLabel(type) {
    const labels = {
        dine_in: 'Dine In',
        delivery: 'Delivery'
    };
    return labels[type] || type;
}
function getPaymentStatusLabel(status) {
    const labels = {
        pending: 'Pending Payment',
        paid: 'Paid',
        failed: 'Payment Failed'
    };
    return labels[status] || status;
}
function getPaymentMethodLabel(method) {
    const labels = {
        cash: 'Cash'
    };
    return labels[method] || 'Cash';
}
function getPaymentStatusBadgeClass(status) {
    const classes = {
        pending: 'badge-warning',
        paid: 'badge-success',
        failed: 'badge-danger'
    };
    return classes[status] || 'badge-secondary';
}
function openExportModal() {
    exportFilters.dateFrom = dateFrom.value || '';
    exportFilters.dateTo = dateTo.value || '';
    if (props.isManagerView && props.managerBranchId) {
        exportFilters.branch_id = String(props.managerBranchId);
    } else {
        exportFilters.branch_id = selectedBranch.value || '';
    }
    exportFilters.status = selectedStatus.value || '';
    exportFilters.order_type = selectedOrderType.value || '';
    exportFilters.payment_status = selectedPaymentStatus.value || '';
    exportFilters.payment_method = selectedPaymentMethod.value || '';
    showExportModal.value = true;
}
async function exportOrders(format = 'csv') {
    if (!exportFilters.dateFrom && !exportFilters.dateTo) {
        showToast('warning', props.isManagerView ? 'Please select at least one date (From Date or To Date) to export' : 'Vui lòng chọn ít nhất một ngày (Từ ngày hoặc Đến ngày) để xuất', props.isManagerView ? 'Vui lòng chọn ít nhất một ngày (Từ ngày hoặc Đến ngày) để xuất' : 'Please select at least one date (From Date or To Date) to export');
        return;
    }
    isExporting.value = true;
    try {
        const filters = {};
        if (exportFilters.branch_id && exportFilters.branch_id !== '') {
            filters.branch_id = exportFilters.branch_id;
        }
        if (exportFilters.status && exportFilters.status !== '') {
            filters.status = exportFilters.status;
        }
        if (exportFilters.order_type && exportFilters.order_type !== '') {
            filters.order_type = exportFilters.order_type;
        }
        if (exportFilters.payment_status && exportFilters.payment_status !== '') {
            filters.payment_status = exportFilters.payment_status;
        }
        if (exportFilters.payment_method && exportFilters.payment_method !== '') {
            filters.payment_method = exportFilters.payment_method;
        }
        if (exportFilters.dateFrom && exportFilters.dateFrom !== '') {
            filters.date_from = exportFilters.dateFrom;
        }
        if (exportFilters.dateTo && exportFilters.dateTo !== '') {
            const toDate = new Date(exportFilters.dateTo);
            toDate.setDate(toDate.getDate() + 1);
            filters.date_to = toDate.toISOString().split('T')[0];
        }
        if (!exportFilters.dateFrom && exportFilters.dateTo) {
            const oneYearAgo = new Date(exportFilters.dateTo);
            oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
            filters.date_from = oneYearAgo.toISOString().split('T')[0];
        }
        if (filters.date_from && filters.date_to) {
            const fromDate = new Date(filters.date_from);
            const toDate = new Date(filters.date_to);
            if (toDate < fromDate) {
                showToast('warning', props.isManagerView ? '"To Date" must be greater than or equal to "From Date"' : '"Đến ngày" phải lớn hơn hoặc bằng "Từ ngày"', props.isManagerView ? '"Đến ngày" phải lớn hơn hoặc bằng "Từ ngày"' : '"To Date" must be greater than or equal to "From Date"');
                return;
            }
        }
        if (props.isManagerView && props.managerBranchId && !filters.branch_id) {
            filters.branch_id = props.managerBranchId;
        }
        filters.limit = 10000; 
        filters.page = 1;
        const result = await OrderService.getAllOrders(filters);
        let ordersToExport = [];
        let paginationInfo = null;
        if (result.data) {
            if (result.data.orders) {
                ordersToExport = result.data.orders || [];
                paginationInfo = result.data.pagination;
            } else if (Array.isArray(result.data)) {
                ordersToExport = result.data;
            }
        } else if (result.orders) {
            ordersToExport = result.orders || [];
            paginationInfo = result.pagination;
        } else if (Array.isArray(result)) {
            ordersToExport = result;
        }
        if (paginationInfo && paginationInfo.pages && paginationInfo.pages > 1) {
            const totalPages = paginationInfo.pages;
            toast.info(`Loading ${totalPages} page(s) of orders...`);
            const allPagesPromises = [];
            for (let p = 2; p <= totalPages; p++) {
                const pageFilters = { ...filters, page: p, limit: 10000 };
                allPagesPromises.push(OrderService.getAllOrders(pageFilters));
            }
            const remainingPages = await Promise.all(allPagesPromises);
            remainingPages.forEach(pageResult => {
                let pageOrders = [];
                if (pageResult.data && pageResult.data.orders) {
                    pageOrders = pageResult.data.orders || [];
                } else if (pageResult.orders) {
                    pageOrders = pageResult.orders || [];
                } else if (Array.isArray(pageResult)) {
                    pageOrders = pageResult;
                }
                ordersToExport = ordersToExport.concat(pageOrders);
            });
        }
        console.log('Orders to export:', ordersToExport.length, ordersToExport);
        if (exportFilters.dateFrom || exportFilters.dateTo) {
            const fromDate = exportFilters.dateFrom ? new Date(exportFilters.dateFrom) : null;
            if (fromDate) {
                fromDate.setHours(0, 0, 0, 0);
            }
            const toDate = exportFilters.dateTo ? new Date(exportFilters.dateTo) : null;
            if (toDate) {
                toDate.setHours(23, 59, 59, 999);
            }
            console.log('Date range from', fromDate ? fromDate.toISOString() : null, 'to', toDate ? toDate.toISOString() : null);
            ordersToExport = ordersToExport.filter(order => {
                if (!order.created_at) return false;
                const orderDate = new Date(order.created_at);
                let match = true;
                if (fromDate && orderDate < fromDate) {
                    match = false;
                }
                if (toDate && orderDate > toDate) {
                    match = false;
                }
                if (!match) {
                    console.log('Order out of range:', fromDate?.toISOString(), 'to', toDate?.toISOString(), 'order:', order.id);
                }
                return match;
            });
            }
        if (ordersToExport.length === 0) {
            toast.warning('No orders match the selected filters');
            return;
        }
        if (format === 'excel' || format === 'csv') {
            await exportToCSV(ordersToExport, exportFilters);
        } else if (format === 'pdf') {
            toast.info('PDF export feature is under development');
        }
        showExportModal.value = false;
    } catch (err) {
        toast.error('Unable to export order list');
    } finally {
        isExporting.value = false;
    }
}
async function exportToCSV(orders, filters = {}) {
    const headers = [
        'ID', 'Customer', 'Phone', 'Branch', 'Order Type', 'Table', 
        'Delivery Address', 'Items Count', 'Items List', 'Total', 
        'Payment Status', 'Payment Method', 'Created Date'
    ];
    toast.info('Loading order details...');
    const ordersWithDetails = await Promise.all(
        orders.map(async (order) => {
            try {
                const orderDetails = await OrderService.getOrderById(order.id);
                return {
                    ...order,
                    items: orderDetails.items || orderDetails.order_details || []
                };
            } catch (err) {
                return {
                    ...order,
                    items: []
                };
            }
        })
    );
    const rows = ordersWithDetails.map(order => {
        let itemsList = 'N/A';
        if (order.items && order.items.length > 0) {
            itemsList = order.items.map(item => {
                const name = item.product_name || item.name || 'N/A';
                const quantity = item.quantity || 1;
                return `${name} (x${quantity})`;
            }).join(', ');
        }
        return [
        order.id,
        order.customer_name || 'N/A',
        order.customer_phone || 'N/A',
        order.branch_name || 'N/A',
        getOrderTypeLabel(order.order_type),
            (order.order_type === 'dine_in' && order.table_id ? '#' + order.table_id : (order.order_type === 'dine_in' ? 'N/A' : '-')),
        order.delivery_address || (order.order_type === 'delivery' ? 'N/A' : '-'),
            order.items_count || (order.items ? order.items.length : 0),
            itemsList,
        order.total || 0,
        getPaymentStatusLabel(order.payment_status),
        getPaymentMethodLabel(order.payment_method),
        formatDate(order.created_at)
        ];
    });
    const csvContent = [
        headers.join(','),
        ...rows.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
    ].join('\n');
    let filename = 'order_list';
    if (filters.dateFrom && filters.dateTo) {
        const fromDate = filters.dateFrom.replace(/-/g, '');
        const toDate = filters.dateTo.replace(/-/g, '');
        filename += `_${fromDate}_${toDate}`;
    } else {
        filename += `_${new Date().toISOString().split('T')[0]}`;
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
    toast.success(`Exported ${orders.length} order(s) successfully`);
}
function handleEdit(order) {
    orderToEdit.value = { ...order };
    editForm.status = order.status || '';
    editForm.payment_status = order.payment_status || '';
    editForm.payment_method = order.payment_method || '';
    showEditModal.value = true;
}
async function saveOrderEdit() {
    if (!orderToEdit.value || isUpdatingOrder.value) return;
    isUpdatingOrder.value = true;
    try {
        const updates = [];
        if (editForm.status !== orderToEdit.value.status) {
            await OrderService.updateOrderStatus(orderToEdit.value.id, editForm.status);
            updates.push('status');
        }
        const paymentStatusChanged = editForm.payment_status !== orderToEdit.value.payment_status;
        const paymentMethodChanged = editForm.payment_method !== (orderToEdit.value.payment_method || '');
        if (paymentStatusChanged || (editForm.payment_status === 'paid' && paymentMethodChanged)) {
            await OrderService.updatePaymentStatus(
                orderToEdit.value.id, 
                editForm.payment_status, 
                editForm.payment_status === 'paid' ? editForm.payment_method : null
            );
            if (paymentStatusChanged) updates.push('payment status');
            if (paymentMethodChanged && editForm.payment_status === 'paid') updates.push('payment method');
        }
        if (updates.length > 0) {
            toast.success(`Updated ${updates.join(', ')} successfully`);
            await loadOrders(currentPage.value);
            showEditModal.value = false;
        } else {
            toast.info('No changes made');
        }
    } catch (err) {
        toast.error('Unable to update order');
    } finally {
        isUpdatingOrder.value = false;
    }
}
function handleDelete(order) {
    orderToDelete.value = order;
    showDeleteModal.value = true;
}
async function confirmDelete() {
    if (!orderToDelete.value) return;
    deleteLoading.value = true;
    try {
        await OrderService.deleteOrder(orderToDelete.value.id);
        showToast('success', 'Order deleted successfully', 'Order deleted successfully');
        await loadOrders(currentPage.value);
        showDeleteModal.value = false;
        orderToDelete.value = null;
    } catch (err) {
        toast.error('Unable to delete order');
    } finally {
        deleteLoading.value = false;
    }
}
function openAssignModal(order) {
    orderToAssign.value = order;
    selectedDeliveryStaff.value = '';
    showAssignModal.value = true;
}
async function assignDeliveryStaff() {
    if (!orderToAssign.value || !selectedDeliveryStaff.value) {
        toast.warning('Please select a delivery staff');
        return;
    }
    isAssigning.value = true;
    try {
        await OrderService.assignDeliveryStaff(orderToAssign.value.id, selectedDeliveryStaff.value);
        toast.success('Successfully assigned delivery staff');
        showAssignModal.value = false;
        await loadOrders(currentPage.value);
    } catch (err) {
        toast.error('Unable to assign delivery staff');
    } finally {
        isAssigning.value = false;
    }
}
onMounted(async () => {
    initializeChartDateRange();
    await loadBranches();
    await loadDeliveryStaff();
    await loadOrders();
    await loadStatistics();
    await loadTopProducts();
    generateRevenueChartData();
    startOrderPolling();
});
function startOrderPolling() {
    if (!isPollingEnabled.value) return;
    setTimeout(async () => {
        try {
            const filters = {
                status: 'pending',
                limit: 1,
                page: 1
            };
            const result = await OrderService.getAllOrders(filters);
            lastOrderCount.value = result.pagination?.total_count || 0;
        } catch (err) {
            }
    }, 2000);
    pollingInterval.value = setInterval(async () => {
        try {
            const filters = {
                status: 'pending',
                limit: 1,
                page: 1
            };
            const result = await OrderService.getAllOrders(filters);
            const currentPendingCount = result.pagination?.total_count || 0;
            if (lastOrderCount.value > 0 && currentPendingCount > lastOrderCount.value) {
                const newCount = currentPendingCount - lastOrderCount.value;
                newOrdersCount.value += newCount;
                toast.info(`There are ${newCount} new orders pending!`, {
                    timeout: 5000,
                    onClick: () => {
                        selectedStatus.value = 'pending';
                        loadOrders(1);
                        newOrdersCount.value = 0;
                    }
                });
                playNotificationSound();
            }
            lastOrderCount.value = currentPendingCount;
        } catch (err) {
            }
    }, 10000); 
}
function stopOrderPolling() {
    if (pollingInterval.value) {
        clearInterval(pollingInterval.value);
        pollingInterval.value = null;
    }
}
function playNotificationSound() {
    try {
        const audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        oscillator.frequency.value = 800;
        oscillator.type = 'sine';
        gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2);
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + 0.2);
    } catch (err) {
        }
}
onBeforeUnmount(() => {
    stopOrderPolling();
});
watch([selectedBranch, selectedStatus, selectedOrderType, selectedPaymentStatus, selectedPaymentMethod, dateFrom, dateTo], () => {
    applyFilters();
    loadTopProducts();
    calculateOrdersByType();
    calculateOrdersByStatus();
});
watch(orders, () => {
    calculateOrdersByType();
    calculateOrdersByStatus();
}, { deep: true });
watch([chartDateFrom, chartDateTo], () => {
    calculateOrdersByType();
    calculateOrdersByStatus();
});
</script>
<template>
  <div class="order-list">
    <!-- Header -->
    <div class="header" v-if="newOrdersCount > 0">
      <div class="header-title-section">
        <span class="badge-new-orders" @click="selectedStatus = 'pending'; loadOrders(1); newOrdersCount = 0">
          <i class="fas fa-bell"></i>
          {{ newOrdersCount }} new orders
        </span>
      </div>
    </div>
    <!-- Top Products Section -->
    <div class="top-products-section">
      <div class="top-products-grid">
        <div v-for="product in topProducts" :key="product.id || product.product_id" class="top-product-card">
          <div class="product-image-wrapper">
            <img 
              :src="product.image || product.image_url || '/images/placeholder-product.png'" 
              :alt="product.name || product.product_name"
              class="product-image"
              @error="handleImageError"
            />
          </div>
          <div class="product-info">
            <h3 class="product-name">{{ product.name || product.product_name || 'N/A' }}</h3>
            <div class="product-stats">
              <div class="product-stat-item">
                <span class="stat-label-text">Total Sales</span>
                <span class="stat-value-text">{{ product.total_quantity || 0 }}</span>
              </div>
            </div>
            <div class="product-footer">
              <div class="product-rating">
                <i v-for="i in 5" :key="i" class="fas fa-star" :class="{ 'star-filled': i <= (product.rating || 4), 'star-empty': i > (product.rating || 4) }"></i>
              </div>
              <div class="product-likes">
                <i class="fas fa-heart"></i>
                <span>{{ formatLikes(product.likes || product.total_quantity * 10) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Charts Section with Order Statistics on Right -->
    <div class="charts-section">
      <!-- Left: Revenue Chart only -->
      <div class="charts-left">
        <div class="chart-card revenue-chart-card">
          <div class="chart-header-section">
            <h3 class="chart-title">Total Revenue</h3>
            <div class="period-filter-header">
              <button 
                @click="setPeriod('day')"
                :class="['period-filter-btn', { active: revenuePeriod === 'day' }]"
              >
                Day
              </button>
              <button 
                @click="setPeriod('week')"
                :class="['period-filter-btn', { active: revenuePeriod === 'week' }]"
              >
                Week
              </button>
              <button 
                @click="setPeriod('month')"
                :class="['period-filter-btn', { active: revenuePeriod === 'month' }]"
              >
                Month
              </button>
              <button 
                @click="setPeriod('year')"
                :class="['period-filter-btn', { active: revenuePeriod === 'year' }]"
              >
                Year
              </button>
            </div>
          </div>
          <div class="chart-card-wrapper">
            <div class="chart-card-body">
              <RevenueChart 
                :data="revenueChartData"
                :period="revenuePeriod"
                :loading="revenueChartLoading"
                :date-from="chartDateFrom"
                :date-to="chartDateTo"
                @period-change="onRevenuePeriodChange"
                @navigate="navigateChartPeriod"
                @date-range-change="onChartDateRangeChange"
              />
            </div>
          </div>
        </div>
      </div>
      <!-- Right: Order Statistics Column -->
      <div class="order-stats-column">
        <div class="order-stats-card">
          <div class="stats-header-section">
            <h3 class="stats-title">Order Statistics</h3>
          </div>
          <div class="order-stats-content">
            <div class="order-stat-item">
              <div class="stat-icon-wrapper" style="background: #ECFDF5; color: #10B981;">
                <i class="fas fa-shopping-cart"></i>
              </div>
              <div class="stat-content">
                <div class="stat-value">{{ statistics.total_orders || 0 }}</div>
                <div class="stat-label">Total Orders</div>
              </div>
            </div>
            <div class="order-stat-item">
              <div class="stat-icon-wrapper" style="background: #FEF3C7; color: #D97706;">
                <i class="fas fa-clock"></i>
              </div>
              <div class="stat-content">
                <div class="stat-value">{{ statistics.orders_by_status?.pending || 0 }}</div>
                <div class="stat-label">{{ isManagerView ? 'Processing' : 'Đang xử lý' }}</div>
              </div>
            </div>
            <div class="order-stat-item">
              <div class="stat-icon-wrapper" style="background: #DBEAFE; color: #2563EB;">
                <i class="fas fa-check-circle"></i>
              </div>
              <div class="stat-content">
                <div class="stat-value">{{ statistics.orders_by_status?.completed || 0 }}</div>
                <div class="stat-label">Completed</div>
              </div>
            </div>
            <div class="order-stat-item">
              <div class="stat-icon-wrapper" style="background: #FEE2E2; color: #EF4444;">
                <i class="fas fa-times-circle"></i>
              </div>
              <div class="stat-content">
                <div class="stat-value">{{ statistics.orders_by_status?.cancelled || 0 }}</div>
                <div class="stat-label">Cancelled</div>
              </div>
            </div>
            <div class="order-stat-item">
              <div class="stat-icon-wrapper" style="background: #F3E8FF; color: #9333EA;">
                <i class="fas fa-dollar-sign"></i>
              </div>
              <div class="stat-content">
                <div class="stat-value">{{ formatCurrency(statistics.total_revenue || 0) }}</div>
                <div class="stat-label">Total Revenue</div>
              </div>
            </div>
            <div class="order-stat-item">
              <div class="stat-icon-wrapper" style="background: #E0E7FF; color: #6366F1;">
                <i class="fas fa-table"></i>
              </div>
              <div class="stat-content">
                <div class="stat-value">{{ statistics.orders_by_type?.dine_in || 0 }}</div>
                <div class="stat-label">Dine-in Orders</div>
              </div>
            </div>
            <div class="order-stat-item">
              <div class="stat-icon-wrapper" style="background: #DCFCE7; color: #16A34A;">
                <i class="fas fa-truck"></i>
              </div>
              <div class="stat-content">
                <div class="stat-value">{{ statistics.orders_by_type?.delivery || 0 }}</div>
                <div class="stat-label">Delivery Orders</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Filters Section -->
    <div class="filters-card">
      <div class="filters-header">
        <h3>Filters</h3>
        <button v-if="selectedBranch || selectedStatus || selectedOrderType || selectedPaymentStatus || dateFrom || dateTo || searchText" 
                @click="clearFilters" class="btn-clear-filters">
          <i class="fas fa-times"></i>
          Clear Filters
        </button>
      </div>
      <div class="filters-grid">
        <div v-if="!hideBranchFilter" class="filter-group">
          <label>{{ isManagerView ? 'Branch' : 'Chi nhánh' }}</label>
          <select v-model="selectedBranch" class="filter-select">
            <option value="">{{ isManagerView ? 'All Branches' : 'Tất cả chi nhánh' }}</option>
            <option v-for="branch in branches" :key="branch.id" :value="branch.id">
              {{ branch.name }}
            </option>
          </select>
        </div>
        <div class="filter-group">
          <label>{{ isManagerView ? 'Order Type' : 'Loại đơn' }}</label>
        <select v-model="selectedOrderType" class="filter-select">
          <option v-for="option in orderTypeOptions" :key="option.value" :value="option.value">
            {{ option.label }}
          </option>
        </select>
        </div>
        <div class="filter-group">
          <label>{{ isManagerView ? 'Payment Status' : 'Trạng thái thanh toán' }}</label>
          <select v-model="selectedPaymentStatus" class="filter-select">
            <option v-for="option in paymentStatusOptions" :key="option.value" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </div>
        <div class="filter-group">
          <label>{{ isManagerView ? 'From Date' : 'Từ ngày' }}</label>
          <input v-model="dateFrom" type="date" class="filter-input">
        </div>
        <div class="filter-group">
          <label>{{ isManagerView ? 'To Date' : 'Đến ngày' }}</label>
          <input v-model="dateTo" type="date" class="filter-input">
        </div>
      </div>
    </div>
    <!-- Orders Table -->
    <div class="content-area">
      <div v-if="isLoading" class="loading">
        <div class="spinner"></div>
        <p>{{ isManagerView ? 'Loading order list...' : 'Đang tải danh sách đơn hàng...' }}</p>
      </div>
      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadOrders(currentPage)" class="btn btn-secondary">
          {{ isManagerView ? 'Try Again' : 'Thử lại' }}
        </button>
      </div>
      <!-- Orders Table -->
      <div class="orders-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>Order List</h3>
            <span class="table-count">{{ paginatedOrders.length }}/{{ totalCount }} orders (Page {{ currentPage }}/{{ totalPages }})</span>
          </div>
          <div class="header-actions-wrapper">
          <div v-if="selectedOrders.length > 0" class="bulk-actions">
            <span class="selected-count">{{ selectedOrders.length }} selected</span>
              <!-- Chỉ hiển thị nút cập nhật khi đã chọn một trạng thái cụ thể -->
              <template v-if="selectedStatus">
                <button 
                  @click="bulkUpdateStatus('preparing')" 
                  class="bulk-btn" 
                  :title="isManagerView ? 'Preparing' : 'Đang chuẩn bị'"
                  :disabled="!canBulkUpdateToStatus('preparing')"
                >
              <i class="fas fa-clock"></i>
            </button>
                <button 
                  @click="bulkUpdateStatus('ready')" 
                  class="bulk-btn" 
                  title="Ready"
                  :disabled="!canBulkUpdateToStatus('ready')"
                >
              <i class="fas fa-check-circle"></i>
            </button>
                <button 
                  @click="bulkUpdateStatus('completed')" 
                  class="bulk-btn" 
                  :title="isManagerView ? 'Completed' : 'Hoàn thành'"
                  :disabled="!canBulkUpdateToStatus('completed')"
                >
              <i class="fas fa-check-double"></i>
            </button>
                <button 
                  @click="bulkDeleteOrders" 
                  class="bulk-btn bulk-btn-delete" 
                  title="Delete orders"
                >
                  <i class="fas fa-trash"></i>
                </button>
              </template>
              <!-- Show delete button when "All Status" is selected -->
              <template v-if="!selectedStatus">
                <button 
                  @click="bulkDeleteOrders" 
                  class="bulk-btn bulk-btn-delete" 
                  title="Delete orders"
                >
                  <i class="fas fa-trash"></i>
                </button>
              </template>
            <button @click="selectedOrders = []" class="bulk-btn" :title="isManagerView ? 'Deselect' : 'Bỏ chọn'">
              <i class="fas fa-times"></i>
            </button>
            </div>
            <div class="header-actions">
              <button @click="openExportModal" class="btn-export" :disabled="isLoading">
                <i class="fas fa-file-excel"></i>
                Export Excel
              </button>
              <button @click="loadOrders(currentPage)" class="btn-refresh" :disabled="isLoading">{{ isManagerView ? 'Refresh' : 'Làm mới' }}</button>
            </div>
          </div>
        </div>
        <!-- Status Tabs -->
        <div class="tabs-section">
          <button 
            v-for="option in statusOptions" 
            :key="option.value"
            @click="selectedStatus = option.value"
            class="tab-btn"
            :class="{ 'active': selectedStatus === option.value }"
          >
            {{ option.label }}
            <span v-if="option.value && statistics.orders_by_status?.[option.value]" class="tab-count">
              {{ statistics.orders_by_status[option.value] }}
            </span>
          </button>
        </div>
        <div class="table-wrapper">
          <table class="modern-table">
            <thead>
              <tr>
                <th class="checkbox-col" style="width: 50px;">
                  <input 
                    type="checkbox" 
                    :checked="selectedOrders.length === filteredOrders.length && filteredOrders.length > 0"
                    @change="selectAllOrders"
                    class="checkbox-input"
                  />
                </th>
                <th style="width: 80px;">{{ isManagerView ? 'ID' : 'ID' }}</th>
                <th style="width: 12%;">{{ isManagerView ? 'Customer' : 'Khách hàng' }}</th>
                <th style="width: 18%;">{{ isManagerView ? 'Branch' : 'Chi nhánh' }}</th>
                <th style="width: 120px;">{{ isManagerView ? 'Type' : 'Loại' }}</th>
                <th style="width: 100px;">{{ isManagerView ? 'Table' : 'Bàn' }}</th>
                <th style="width: 120px;">{{ isManagerView ? 'Total' : 'Tổng tiền' }}</th>
                <th class="status-col" style="width: 140px;">{{ isManagerView ? 'Status' : 'Trạng thái' }}</th>
                <th style="width: 150px;">{{ isManagerView ? 'Created Date' : 'Ngày tạo' }}</th>
                <th style="width: 180px; min-width: 180px;">{{ isManagerView ? 'Actions' : 'Thao tác' }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="paginatedOrders.length === 0" class="empty-row">
                <td :colspan="10" class="empty-cell">
                  <div class="empty-state-inline">
                    <i class="fas fa-shopping-cart"></i>
                    <h3>{{ isManagerView ? 'No Orders' : 'Không có đơn hàng' }}</h3>
                    <p v-if="selectedBranch || selectedStatus || selectedOrderType || dateFrom || dateTo">
                      {{ isManagerView ? 'No orders match the current filters' : 'Không có đơn hàng nào khớp với bộ lọc hiện tại' }}
                    </p>
                    <p v-else>
                      {{ isManagerView ? 'No orders have been created yet' : 'Chưa có đơn hàng nào được tạo' }}
                    </p>
                  </div>
                </td>
              </tr>
              <tr v-for="order in paginatedOrders" :key="order.id" :class="{ 'row-selected': selectedOrders.includes(order.id) }">
                <td class="checkbox-col">
                  <input 
                    type="checkbox" 
                    :checked="selectedOrders.includes(order.id)"
                    @change="toggleOrderSelection(order.id)"
                    class="checkbox-input"
                  />
                </td>
                <td><strong class="order-id">#{{ order.id }}</strong></td>
                <td>
                  <div class="customer-cell">
                    <div class="customer-name">{{ order.customer_name || 'N/A' }}</div>
                    <div class="customer-phone">{{ order.customer_phone || 'N/A' }}</div>
                  </div>
                </td>
                <td class="branch-cell">{{ order.branch_name }}</td>
                <td class="order-type-cell">
                  <span class="badge-small" :class="order.order_type === 'dine_in' ? 'badge-primary' : 'badge-info'">
                    {{ getOrderTypeLabel(order.order_type) }}
                  </span>
                </td>
                <td class="table-number-cell">
                  <span v-if="order.order_type === 'dine_in' && order.table_id">#{{ order.table_id }}</span>
                  <span v-else-if="order.order_type === 'dine_in'">-</span>
                  <span v-else class="text-muted">-</span>
                </td>
                <td class="amount-cell">{{ formatCurrency(order.total) }}</td>
                <td class="status-cell">
                  <span class="badge-small" :class="getStatusBadgeClass(order.status)">
                    {{ getStatusLabel(order.status) }}
                  </span>
                </td>
                <td class="date-cell">{{ formatDate(order.created_at) }}</td>
                <td>
                  <div class="action-buttons">
                    <button 
                      class="btn-action btn-view" 
                      @click="showQuickDetails(order)"
                      :title="isManagerView ? 'Xem nhanh' : 'Quick View'"
                    >
                      <i class="fas fa-eye"></i>
                    </button>
                      <button 
                      class="btn-action btn-delete" 
                      @click="handleDelete(order)"
                      :title="isManagerView ? 'Delete' : 'Xóa'"
                      :disabled="isLoading || order.status === 'completed'"
                      >
                      <i class="fas fa-trash"></i>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <!-- Simple Pagination -->
      <div v-if="!isLoading && filteredOrders.length > 0" class="pagination-section">
        <nav class="pagination-nav">
          <div class="pagination-controls">
            <label class="pagination-label">Display:</label>
            <select v-model="itemsPerPage" @change="currentPage = 1" class="pagination-select">
              <option :value="20">20</option>
              <option :value="50">50</option>
              <option :value="100">100</option>
              <option :value="200">200</option>
            </select>
            <span class="pagination-label">per page</span>
          </div>
          <div class="pagination-buttons">
            <button 
              class="pagination-btn" 
              @click="currentPage = Math.max(1, currentPage - 1)" 
              :disabled="currentPage === 1"
            >
              <i class="fas fa-chevron-left"></i>
            </button>
            <span class="pagination-info">
              Page {{ currentPage }} / {{ totalPages }} ({{ totalCount }} orders)
            </span>
            <button 
              class="pagination-btn" 
              @click="currentPage = Math.min(totalPages, currentPage + 1)" 
              :disabled="currentPage === totalPages"
            >
              <i class="fas fa-chevron-right"></i>
            </button>
          </div>
        </nav>
      </div>
    </div>
    <!-- Quick View Modal -->
    <div v-if="showQuickModal" class="modal-overlay" @click.self="showQuickModal = false">
      <div class="modal-content quick-modal" @click.stop>
        <div class="modal-header">
          <div class="modal-header-left">
            <div class="order-id-badge">
              <i class="fas fa-receipt"></i>
              <span>Order #{{ quickViewOrder?.id }}</span>
            </div>
            <span class="badge modal-status-badge" :class="getStatusBadgeClass(quickViewOrder?.status)">
              {{ getStatusLabel(quickViewOrder?.status) }}
            </span>
          </div>
          <button @click="showQuickModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div v-if="isLoadingOrderDetails" class="modal-loading">
          <div class="spinner"></div>
          <p>Loading order details...</p>
        </div>
        <div v-else-if="quickViewOrder" class="modal-body">
          <!-- Order Info Cards -->
          <div class="order-info-grid">
            <!-- Customer Info Card -->
            <div class="info-card">
              <div class="card-header">
                <i class="fas fa-user"></i>
                <h3>{{ isManagerView ? 'Customer Information' : 'Thông tin khách hàng' }}</h3>
              </div>
              <div class="card-content">
                <div class="info-item">
                  <span class="info-label">{{ isManagerView ? 'Customer Name' : 'Tên khách hàng' }}</span>
                  <span class="info-value">{{ quickViewOrder.customer_name || (isManagerView ? 'N/A' : 'Chưa có') }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">{{ isManagerView ? 'Phone Number' : 'Số điện thoại' }}</span>
                  <span class="info-value">{{ quickViewOrder.customer_phone || (isManagerView ? 'N/A' : 'Chưa có') }}</span>
                </div>
              </div>
            </div>
            <!-- Order Info Card -->
            <div class="info-card">
              <div class="card-header">
                <i class="fas fa-store"></i>
                <h3>{{ isManagerView ? 'Order Information' : 'Thông tin đơn hàng' }}</h3>
              </div>
              <div class="card-content">
                <div class="info-item">
                  <span class="info-label">{{ isManagerView ? 'Branch' : 'Chi nhánh' }}</span>
                  <span class="info-value">{{ quickViewOrder.branch_name || (isManagerView ? 'N/A' : 'Chưa có') }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">{{ isManagerView ? 'Order Type' : 'Loại đơn' }}</span>
                  <span class="info-value">
                    <span class="badge small-badge" :class="quickViewOrder.order_type === 'dine_in' ? 'badge-primary' : 'badge-info'">
                      {{ getOrderTypeLabel(quickViewOrder.order_type) }}
                    </span>
                  </span>
                </div>
                <div class="info-item">
                  <span class="info-label">{{ isManagerView ? 'Created Date' : 'Ngày tạo' }}</span>
                  <span class="info-value">{{ formatDate(quickViewOrder.created_at) }}</span>
                </div>
              </div>
            </div>
          </div>
          <!-- Order Items -->
          <div v-if="quickViewOrder.items && quickViewOrder.items.length > 0" class="order-items-section">
            <div class="section-header">
              <i class="fas fa-utensils"></i>
              <h3>Items List ({{ quickViewOrder.items.length }})</h3>
            </div>
            <div class="items-list">
              <div v-for="(item, index) in quickViewOrder.items" :key="index" class="order-item">
                <div class="item-info">
                  <div class="item-name">{{ item.product_name || item.name || (isManagerView ? 'N/A' : 'Chưa có') }}</div>
                  <div class="item-details">
                    <span class="item-quantity">{{ isManagerView ? 'Quantity' : 'Số lượng' }}: {{ item.quantity || 1 }}</span>
                    <span class="item-price">{{ formatCurrency(item.price || item.total || 0) }}</span>
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
              <span class="summary-label">{{ isManagerView ? 'Total Items' : 'Tổng món' }}:</span>
              <span class="summary-value">{{ quickViewOrder.items_count || (quickViewOrder.items ? quickViewOrder.items.length : 0) }}</span>
            </div>
            <div class="summary-row total-row">
              <span class="summary-label">{{ isManagerView ? 'Tổng tiền' : 'Total' }}:</span>
              <span class="summary-value total-amount">{{ formatCurrency(quickViewOrder.total) }}</span>
            </div>
          </div>
          <!-- Order Actions Cards -->
          <div class="order-info-grid">
            <!-- Order Status Update Card -->
            <div class="info-card">
              <div class="card-header">
                <i class="fas fa-info-circle"></i>
                <h3>{{ isManagerView ? 'Thay đổi trạng thái đơn hàng' : 'Change Order Status' }}</h3>
              </div>
              <div class="card-content">
                <div class="quick-status-buttons">
                  <button 
                    v-for="statusOption in statusOptions.filter(s => s.value)" 
                    :key="statusOption.value"
                    @click="updateQuickOrderStatus(statusOption.value)"
                    class="btn-quick-status"
                    :class="{ 
                      'btn-danger': statusOption.value === 'cancelled',
                      'active': quickViewOrder.status === statusOption.value
                    }"
                    :disabled="isUpdatingPayment || isStatusDisabled(statusOption.value, quickViewOrder.status)"
                    :title="getStatusButtonTitle(statusOption.value, quickViewOrder.status)"
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
                    <label>{{ isManagerView ? 'Payment Status' : 'Trạng thái thanh toán' }}</label>
                <select v-model="quickViewOrder.payment_status" @change="updatePaymentStatusHandler" class="form-select">
                  <option value="pending">{{ isManagerView ? 'Chờ thanh toán' : 'Pending Payment' }}</option>
                  <option value="paid">{{ isManagerView ? 'Đã thanh toán' : 'Paid' }}</option>
                  <option value="failed">{{ isManagerView ? 'Thanh toán thất bại' : 'Payment Failed' }}</option>
                </select>
                  </div>
                  <div class="form-group-inline" v-if="quickViewOrder.payment_status === 'paid'">
                    <label>{{ isManagerView ? 'Phương thức thanh toán' : 'Payment Method' }}</label>
                    <select v-model="quickViewOrder.payment_method" @change="updatePaymentStatusHandler" class="form-select">
                  <option value="cash">{{ isManagerView ? 'Tiền mặt' : 'Cash' }}</option>
                </select>
              </div>
            </div>
          </div>
            </div>
          </div>
          <!-- Modal Actions -->
          <div class="modal-actions">
            <button @click="showQuickModal = false" class="btn-close">
              <i class="fas fa-times"></i>
              {{ isManagerView ? 'Đóng' : 'Close' }}
            </button>
            <button @click="loadOrderLogs(quickViewOrder.id)" class="btn-logs" :title="isManagerView ? 'Xem lịch sử thay đổi' : 'View Change History'">
              <i class="fas fa-history"></i>
              {{ isManagerView ? 'Lịch sử' : 'History' }}
            </button>
            <button @click="printKitchenTicket" class="btn-kitchen" :title="isManagerView ? 'In phiếu bếp' : 'Print Kitchen Ticket'" v-if="quickViewOrder.status !== 'completed' && quickViewOrder.status !== 'cancelled'">
              <i class="fas fa-utensils"></i>
              {{ isManagerView ? 'Phiếu bếp' : 'Kitchen Ticket' }}
            </button>
            <button @click="printInvoice" class="btn-print" :title="isManagerView ? 'In hóa đơn' : 'Print Invoice'">
              <i class="fas fa-print"></i>
              {{ isManagerView ? 'In hóa đơn' : 'Print Invoice' }}
            </button>
          </div>
        </div>
      </div>
    </div>
    <!-- Export Modal -->
    <div v-if="showExportModal" class="modal-overlay" @click.self="showExportModal = false">
      <div class="modal-content export-modal" @click.stop>
        <div class="modal-header">
          <h3>
            Export Order List
          </h3>
          <button @click="showExportModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <!-- Date Range Section -->
          <div class="export-section-card">
            <div class="export-section-header">
              <h4 class="section-title">
                {{ isManagerView ? 'Khoảng thời gian' : 'Time Range' }}<span class="required-asterisk">*</span>
              </h4>
            </div>
            <div class="export-section-body">
              <div class="filter-row">
                <div class="form-group">
                  <label>
                    <i class="fas fa-calendar-check label-icon"></i>
                    From Date
                  </label>
                  <input v-model="exportFilters.dateFrom" type="date" class="form-input" :max="exportFilters.dateTo || undefined">
                </div>
                <div class="form-group">
                  <label>
                    <i class="fas fa-calendar-check label-icon"></i>
                    {{ isManagerView ? 'Đến ngày' : 'To Date' }}
                  </label>
                  <input v-model="exportFilters.dateTo" type="date" class="form-input" :min="exportFilters.dateFrom || undefined">
                </div>
              </div>
              <div class="export-note">
                <i class="fas fa-info-circle note-icon"></i>
                <span>{{ isManagerView ? 'Vui lòng chọn ít nhất một ngày (Từ ngày hoặc Đến ngày) để xuất. Nếu chỉ chọn "Từ ngày", sẽ xuất đến hiện tại. Nếu chỉ chọn "Đến ngày", sẽ xuất từ đầu.' : 'Please select at least one date (From Date or To Date) to export. If only "From Date" is selected, it will export until now. If only "To Date" is selected, it will export from the beginning.' }}</span>
              </div>
            </div>
          </div>
          <!-- Filters Section -->
          <div class="export-section-card">
            <div class="export-section-header">
              <h4 class="section-title">
                {{ isManagerView ? 'Bộ lọc tùy chọn' : 'Optional Filters' }}
              </h4>
            </div>
            <div class="export-section-body">
              <div class="filter-grid">
                <div class="form-group">
                  <label>
                    <i class="fas fa-store label-icon"></i>
                    {{ isManagerView ? 'Chi nhánh' : 'Branch' }}
                  </label>
                  <select v-if="!hideBranchFilter" v-model="exportFilters.branch_id" class="form-select">
                    <option value="">{{ isManagerView ? 'Tất cả chi nhánh' : 'All Branches' }}</option>
                    <option v-for="branch in branches" :key="branch.id" :value="branch.id">
                      {{ branch.name }}
                    </option>
                  </select>
                </div>
                <div class="form-group">
                  <label>
                    <i class="fas fa-tag label-icon"></i>
                    {{ isManagerView ? 'Trạng thái đơn hàng' : 'Order Status' }}
                  </label>
                  <select v-model="exportFilters.status" class="form-select">
                    <option value="">{{ isManagerView ? 'Tất cả trạng thái' : 'All Status' }}</option>
                    <option v-for="option in statusOptions" :key="option.value" :value="option.value">
                      {{ option.label }}
                    </option>
                  </select>
                </div>
                <div class="form-group">
                  <label>
                    <i class="fas fa-shopping-bag label-icon"></i>
                    {{ isManagerView ? 'Loại đơn' : 'Order Type' }}
                  </label>
                  <select v-model="exportFilters.order_type" class="form-select">
                    <option value="">{{ isManagerView ? 'Tất cả loại đơn' : 'All Order Types' }}</option>
                    <option v-for="option in orderTypeOptions" :key="option.value" :value="option.value">
                      {{ option.label }}
                    </option>
                  </select>
                </div>
                <div class="form-group">
                  <label>
                    <i class="fas fa-money-bill-wave label-icon"></i>
                    {{ isManagerView ? 'Trạng thái thanh toán' : 'Payment Status' }}
                  </label>
                  <select v-model="exportFilters.payment_status" class="form-select">
                    <option value="">{{ isManagerView ? 'Tất cả trạng thái thanh toán' : 'All Payment Status' }}</option>
                    <option v-for="option in paymentStatusOptions" :key="option.value" :value="option.value">
                      {{ option.label }}
                    </option>
                  </select>
                </div>
                <div class="form-group">
                  <label>
                    <i class="fas fa-credit-card label-icon"></i>
                    {{ isManagerView ? 'Phương thức thanh toán' : 'Payment Method' }}
                  </label>
                  <select v-model="exportFilters.payment_method" class="form-select">
                    <option value="">{{ isManagerView ? 'Tất cả phương thức' : 'All Payment Methods' }}</option>
                    <option v-for="option in paymentMethodOptions" :key="option.value" :value="option.value">
                      {{ option.label }}
                    </option>
                  </select>
                </div>
              </div>
            </div>
          </div>
          <div class="modal-actions">
            <button @click="showExportModal = false" class="btn-close">
              Cancel
            </button>
            <button @click="exportOrders('csv')" class="btn-confirm" :disabled="(!exportFilters.dateFrom && !exportFilters.dateTo) || isExporting">
              <span v-if="isExporting">Exporting...</span>
              <span v-else>
                <i class="fas fa-download btn-icon"></i>
                Export Excel
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
    <!-- Order Logs Modal -->
    <div v-if="showLogsModal" class="modal-overlay" @click.self="showLogsModal = false">
      <div class="modal-content logs-modal" @click.stop>
        <div class="modal-header">
          <h3>Order Change History #{{ quickViewOrder?.id }}</h3>
          <button @click="showLogsModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div v-if="isLoadingLogs" class="modal-loading">
            <div class="spinner"></div>
            <p>{{ isManagerView ? 'Đang tải lịch sử...' : 'Loading history...' }}</p>
          </div>
          <div v-else-if="orderLogs.length === 0" class="empty-state">
            <i class="fas fa-history"></i>
            <p>{{ isManagerView ? 'Chưa có lịch sử thay đổi' : 'No change history yet' }}</p>
          </div>
          <div v-else class="logs-timeline">
            <div v-for="(log, index) in orderLogs" :key="log.id" class="log-item">
              <div class="log-time">{{ formatDate(log.created_at) }}</div>
              <div class="log-content">
                <div class="log-action">
                  <i class="fas fa-circle log-dot" :class="getLogActionClass(log.action)"></i>
                  <strong>{{ getActionLabel(log.action) }}</strong>
                </div>
                <div class="log-change">
                  <span v-if="log.old_value" class="old-value">{{ getStatusLabel(log.old_value) || log.old_value }}</span>
                  <i v-if="log.old_value" class="fas fa-arrow-right"></i>
                  <span class="new-value">{{ getStatusLabel(log.new_value) || log.new_value }}</span>
                </div>
                <div v-if="log.user_name" class="log-user">
                  <i class="fas fa-user"></i>
                  {{ log.user_name }}
                  <span v-if="log.user_email">({{ log.user_email }})</span>
                </div>
                <div v-if="log.metadata" class="log-metadata">
                  <small>{{ JSON.parse(log.metadata).payment_method ? (isManagerView ? 'Phương thức thanh toán: ' : 'Payment Method: ') + getPaymentMethodLabel(JSON.parse(log.metadata).payment_method) : '' }}</small>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-actions">
          <button @click="showLogsModal = false" class="btn-close">
            Close
          </button>
        </div>
      </div>
    </div>
    <!-- Assign Delivery Staff Modal -->
    <div v-if="showAssignModal" class="modal-overlay" @click.self="showAssignModal = false">
      <div class="modal-content assign-modal" @click.stop>
        <div class="modal-header">
          <h3>Assign Delivery Staff</h3>
          <button @click="showAssignModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div v-if="orderToAssign" class="modal-body">
          <div class="order-info-summary">
            <p><strong>Order #{{ orderToAssign.id }}</strong></p>
            <p>Address: {{ orderToAssign.delivery_address || 'N/A' }}</p>
            <p>Total: {{ formatCurrency(orderToAssign.total) }}</p>
          </div>
          <div class="form-group">
            <label>Select Delivery Staff</label>
            <select v-model="selectedDeliveryStaff" class="form-select">
              <option value="">-- Select Staff --</option>
              <option v-for="staff in deliveryStaff" :key="staff.id" :value="staff.id">
                {{ staff.name }}{{ staff.branch_name ? ' (' + staff.branch_name + ')' : '' }}
              </option>
            </select>
          </div>
          <div class="modal-actions">
            <button @click="showAssignModal = false" class="btn-close">
              Cancel
            </button>
            <button @click="assignDeliveryStaff" class="btn-confirm" :disabled="!selectedDeliveryStaff || isAssigning">
              <span v-if="isAssigning">Processing...</span>
              <span v-else>Confirm</span>
            </button>
          </div>
        </div>
      </div>
    </div>
    <!-- Edit Order Modal -->
    <div v-if="showEditModal" class="modal-overlay" @click.self="showEditModal = false">
      <div class="modal-content edit-modal" @click.stop>
        <div class="modal-header">
          <div class="edit-header">
            <div class="edit-header-icon">
              <i class="fas fa-edit"></i>
            </div>
            <h3>Edit Order #{{ orderToEdit?.id }}</h3>
          </div>
          <button @click="showEditModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div v-if="orderToEdit" class="modal-body">
          <div class="edit-form">
            <!-- Order Status Section -->
            <div class="form-section">
              <div class="section-title">
                <i class="fas fa-info-circle"></i>
                <span>Order Status</span>
              </div>
              <div class="form-group">
                <select v-model="editForm.status" class="form-select">
                  <option value="pending">Pending</option>
                  <option value="preparing">Preparing</option>
                  <option value="ready">Ready</option>
                  <option value="out_for_delivery">Out for Delivery</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
            </div>
            <!-- Payment Section -->
            <div class="form-section">
              <div class="section-title">
                <i class="fas fa-money-bill"></i>
                <span>Payment</span>
              </div>
              <div class="form-group">
                <label>Payment Status</label>
                <select v-model="editForm.payment_status" class="form-select">
                  <option value="pending">Pending Payment</option>
                  <option value="paid">Paid</option>
                  <option value="failed">Payment Failed</option>
                </select>
              </div>
              <div class="form-group" v-if="editForm.payment_status === 'paid'">
                <label>Payment Method</label>
                <select v-model="editForm.payment_method" class="form-select">
                  <option value="cash">Cash</option>
                </select>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-actions">
          <button @click="showEditModal = false" class="btn-close">
            <i class="fas fa-times"></i>
            Cancel
          </button>
          <button @click="saveOrderEdit" class="btn-print" :disabled="isUpdatingOrder">
            <i v-if="!isUpdatingOrder" class="fas fa-save"></i>
            <i v-else class="fas fa-spinner fa-spin"></i>
            <span v-if="isUpdatingOrder">Saving...</span>
            <span v-else>Save Changes</span>
          </button>
        </div>
      </div>
    </div>
    <!-- Delete Order Modal -->
    <div v-if="showDeleteModal" class="modal-overlay" @click.self="showDeleteModal = false">
      <div class="modal-content delete-modal" @click.stop>
        <div class="modal-header">
          <div class="delete-header">
            <div class="delete-header-icon">
              <i class="fas fa-exclamation-triangle"></i>
            </div>
            <h3>Confirm Delete</h3>
          </div>
          <button @click="showDeleteModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <p>Are you sure you want to delete order <strong>#{{ orderToDelete?.id }}</strong>?</p>
          <p class="warning">This action cannot be undone.</p>
        </div>
        <div class="modal-actions">
          <button @click="showDeleteModal = false" class="btn btn-secondary">
            <i class="fas fa-times"></i>
            Cancel
          </button>
          <button @click="confirmDelete" class="btn btn-danger" :disabled="deleteLoading">
            <i v-if="!deleteLoading" class="fas fa-trash"></i>
            <i v-else class="fas fa-spinner fa-spin"></i>
            <span v-if="deleteLoading">Deleting...</span>
            <span v-else>Delete</span>
          </button>
        </div>
      </div>
    </div>
    <!-- Bulk Delete Order Modal -->
    <div v-if="showBulkDeleteModal" class="modal-overlay" @click.self="showBulkDeleteModal = false">
      <div class="modal-content delete-modal" @click.stop>
        <div class="modal-header">
          <div class="delete-header">
            <div class="delete-header-icon">
              <i class="fas fa-exclamation-triangle"></i>
            </div>
            <h3>Confirm Delete</h3>
          </div>
          <button @click="showBulkDeleteModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <p>Are you sure you want to delete <strong>{{ selectedOrders.length }} selected order(s)</strong>?</p>
          <p class="warning">This action cannot be undone.</p>
        </div>
        <div class="modal-actions">
          <button @click="showBulkDeleteModal = false" class="btn btn-secondary">
            <i class="fas fa-times"></i>
            Cancel
          </button>
          <button @click="confirmBulkDelete" class="btn btn-danger" :disabled="bulkDeleteLoading">
            <i v-if="!bulkDeleteLoading" class="fas fa-trash"></i>
            <i v-else class="fas fa-spinner fa-spin"></i>
            <span v-if="bulkDeleteLoading">Deleting...</span>
            <span v-else>Delete</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<style scoped>
.order-list {
  padding: 20px;
  background: #F5F7FA;
  min-height: calc(100vh - 72px);
  overflow-x: hidden;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 16px;
  margin-bottom: 20px;
  padding: 16px 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  border: 1px solid #F0E6D9;
}
.header-title-section {
  display: flex;
  align-items: center;
  gap: 16px;
}
.header h1 {
  margin: 0;
  font-size: 22px;
  color: #333;
  font-weight: 700;
  letter-spacing: -0.3px;
}
.actions {
  display: flex;
  gap: 10px;
  align-items: center;
}
.btn-refresh {
  padding: 10px 18px;
  border: 2px solid #F0E6D9;
  background: white;
  color: #666;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-refresh:hover {
  border-color: #FF8C42;
  background: #FFF3E0;
  color: #FF8C42;
}
.btn-refresh:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.btn-export {
  padding: 10px 18px;
  border: 2px solid #10B981;
  background: white;
  color: #10B981;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-export:hover {
  border-color: #059669;
  background: #ECFDF5;
  color: #059669;
}
.btn-export:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 20px;
  margin-bottom: 24px;
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
}
.stat-icon.revenue {
  background: #FFF5E6;
  color: #FF8C42;
}
.stat-icon.pending {
  background: #FEF3C7;
  color: #F59E0B;
}
.stat-icon.completed {
  background: #ECFDF5;
  color: #10B981;
}
.stat-content {
  flex: 1;
}
.stat-label {
  font-size: 13px;
  color: #6B7280;
  font-weight: 500;
  margin-bottom: 4px;
}
.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: #1a1a1a;
  letter-spacing: -0.5px;
}
.top-products-section {
  margin-bottom: 24px;
  overflow-x: auto;
  max-width: 100%;
  -webkit-overflow-scrolling: touch;
  scrollbar-width: none; 
  -ms-overflow-style: none; 
}
.top-products-section::-webkit-scrollbar {
  display: none; 
}
.top-products-grid {
  display: flex;
  flex-direction: row;
  gap: 20px;
  min-width: max-content;
}
.top-product-card {
  background: white;
  border-radius: 20px;
  padding: 20px;
  display: flex;
  align-items: flex-start;
  gap: 16px;
  box-shadow: 
    0 2px 4px rgba(0, 0, 0, 0.02),
    0 8px 16px rgba(0, 0, 0, 0.03);
  border: 1px solid rgba(0, 0, 0, 0.04);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
  flex-shrink: 0;
  min-width: 280px;
  max-width: 280px;
}
.top-product-card::after {
  content: '';
  position: absolute;
  top: -50%;
  right: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, rgba(255, 140, 66, 0.05) 0%, transparent 70%);
  opacity: 0;
  transition: opacity 0.3s ease;
}
.product-image-wrapper {
  width: 72px;
  height: 72px;
  border-radius: 16px;
  overflow: hidden;
  flex-shrink: 0;
  background: linear-gradient(135deg, #FFF9F5 0%, #FFE5D4 100%);
  border: 2px solid #FFF3E8;
  position: relative;
}
.product-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}
.product-info {
  flex: 1;
  min-width: 0;
}
.product-name {
  margin: 0 0 12px 0;
  font-size: 15px;
  font-weight: 600;
  color: #1F2937;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.product-stats {
  margin-bottom: 12px;
}
.product-stat-item {
  display: flex;
  align-items: baseline;
  gap: 8px;
}
.stat-label-text {
  font-size: 11px;
  color: #9CA3AF;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.stat-value-text {
  font-size: 20px;
  font-weight: 700;
  color: #1F2937;
  background: linear-gradient(135deg, #FF8C42 0%, #FFB800 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
.product-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 12px;
  border-top: 1px dashed #E5E7EB;
}
.product-rating {
  display: flex;
  gap: 2px;
}
.product-rating .fa-star {
  font-size: 12px;
  transition: transform 0.2s ease;
}
.product-rating .star-filled {
  color: #FBBF24;
}
.product-rating .star-empty {
  color: #E5E7EB;
}
.product-likes {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: #6B7280;
  font-weight: 500;
  background: #FFF9F5;
  padding: 4px 10px;
  border-radius: 20px;
  border: 1px solid #FFE5D4;
}
.product-likes i {
  color: #EF4444;
  font-size: 11px;
  animation: heartbeat 1.5s ease-in-out infinite;
}
@keyframes heartbeat {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}
@media (max-width: 1400px) {
  .charts-section {
    grid-template-columns: 1fr;
  }
  .charts-left {
    order: 2;
  }
  .order-stats-column {
    order: 1;
  }
}
@media (max-width: 768px) {
  .charts-section {
    gap: 16px;
  }
  .chart-card-wrapper {
    padding: 20px;
  }
  .top-products-grid {
    flex-direction: row;
    overflow-x: auto;
  }
  .top-product-card {
    min-width: 260px;
    max-width: 260px;
  }
  .charts-left {
    gap: 16px;
  }
}
@media (max-width: 480px) {
  .chart-card-header h3 {
    font-size: 14px;
  }
  .chart-period-select {
    min-width: 100px;
    padding: 8px 30px 8px 12px;
    font-size: 12px;
  }
  .product-image-wrapper {
    width: 60px;
    height: 60px;
  }
}
.chart-loading {
  position: relative;
  overflow: hidden;
}
.chart-loading::after {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(255, 255, 255, 0.4) 50%,
    transparent 100%
  );
  animation: shimmer 2s infinite;
}
@keyframes shimmer {
  0% { left: -100%; }
  100% { left: 100%; }
}
.chart-card,
.top-product-card,
.donut-charts-column .stat-card {
  will-change: transform;
}
.charts-section {
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(320px, 0.6fr);
  gap: 24px;
  margin-bottom: 24px;
  padding: 0;
  background: transparent;
  align-items: stretch;
  overflow-x: hidden;
  max-width: 100%;
}
.charts-left {
  display: flex;
  grid-column: 1;
  height: 100%;
}
.chart-card-body {
  position: relative;
}
.orders-chart-card .chart-card-body {
  height: 220px;
  padding: 0 8px;
}
.revenue-chart-card {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: #FAFBFC;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #E2E8F0;
  overflow: hidden;
  min-height: 100%;
}
.chart-header-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 2px solid #E2E8F0;
  gap: 16px;
  padding: 0 0 12px 0;
}
.chart-title {
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
.chart-card-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
  background: white;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid #E2E8F0;
}
.revenue-chart-card .chart-card-body {
  flex: 1;
  min-height: 0;
  padding: 0;
}
.revenue-chart-card {
  flex: 1;
}
.orders-chart-card {
  flex: 1;
}
.chart-card-wrapper .chart-card-body {
  padding: 0;
}
.order-stats-column {
  grid-column: 2;
  display: flex;
  height: 100%;
  position: sticky;
  top: 12px;
}
.order-stats-card {
  flex: 1;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  min-height: 100%;
  height: 100%;
}
.stats-header-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #E2E8F0;
}
.stats-title {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: #1E293B;
}
.order-stats-content {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  flex: 1;
  overflow-y: auto;
}
.order-stat-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px;
  background: #FAFBFC;
  border-radius: 10px;
  border: 1px solid #E2E8F0;
  transition: all 0.2s ease;
}
.order-stat-item:hover {
  background: #F8F9FA;
  border-color: #CBD5E1;
}
.stat-icon-wrapper {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
}
.stat-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.stat-value {
  font-size: 20px;
  font-weight: 700;
  color: #1E293B;
  line-height: 1.2;
}
.stat-label {
  font-size: 13px;
  font-weight: 500;
  color: #64748B;
  line-height: 1.2;
}
.charts-card {
  background: white;
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}
.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}
.chart-header h2 {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: #1a1a1a;
}
.chart-controls {
  display: flex;
  align-items: center;
  gap: 12px;
}
.period-select {
  padding: 8px 12px;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  font-size: 14px;
  background: white;
  color: #1a1a1a;
  cursor: pointer;
  transition: all 0.2s ease;
}
.period-select:focus {
  outline: none;
  border-color: #FF8C42;
}
.btn-toggle-chart {
  width: 36px;
  height: 36px;
  border: 1px solid #E5E5E5;
  background: white;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  transition: all 0.2s ease;
}
.btn-toggle-chart:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.chart-section {
  transition: all 0.3s ease;
}
.chart-section.collapsed {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}
.chart-content {
  min-height: 180px;
  transition: all 0.3s ease;
}
.chart-section.collapsed .chart-content {
  min-height: 150px;
}
.stats-panel {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 16px;
  background: #FAFAFA;
  border-radius: 12px;
  border: 1px solid #E5E5E5;
}
.stat-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}
.stat-box {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
  background: white;
  border-radius: 10px;
  border: 1px solid #E5E5E5;
  transition: all 0.2s ease;
}
.stat-box:hover {
  border-color: #FF8C42;
  box-shadow: 0 2px 8px rgba(255, 140, 66, 0.1);
}
.stat-box-icon {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
}
.stat-box-icon.revenue-icon {
  background: #FFF5E6;
  color: #FF8C42;
}
.stat-box-icon.orders-icon {
  background: #EFF6FF;
  color: #3B82F6;
}
.stat-box-icon.delivery-icon {
  background: #ECFDF5;
  color: #10B981;
}
.stat-box-icon.preparing-icon {
  background: #FEF3C7;
  color: #F59E0B;
}
.stat-box-icon.ready-icon {
  background: #DBEAFE;
  color: #2563EB;
}
.stat-box-icon.delivery-status-icon {
  background: #F3E8FF;
  color: #9333EA;
}
.stat-box-content {
  flex: 1;
  min-width: 0;
}
.stat-box-label {
  font-size: 12px;
  font-weight: 600;
  color: #6B7280;
  margin-bottom: 4px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.stat-box-value {
  font-size: 18px;
  font-weight: 700;
  color: #1a1a1a;
  letter-spacing: -0.3px;
}
.filters-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 24px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  overflow-x: hidden;
  max-width: 100%;
}
.filters-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}
.filters-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: #1a1a1a;
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
.sort-controls {
  display: flex;
  gap: 8px;
  align-items: center;
}
.filter-select {
  flex: 1;
  min-width: 0;
}
.btn-sort-toggle {
  width: 40px;
  height: 40px;
  border: 1px solid #E5E5E5;
  background: white;
  border-radius: 10px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  transition: all 0.2s ease;
}
.btn-sort-toggle:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.content-area {
  min-height: 400px;
}
.loading,
.error,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
}
.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #007bff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
.loading i,
.error i,
.empty-state i {
  font-size: 3rem;
  margin-bottom: 16px;
  color: #9ca3af;
}
.error i {
  color: #dc3545;
}
.empty-state i {
  color: #6c757d;
}
.loading p,
.error p,
.empty-state p {
  margin: 8px 0;
  color: #6c757d;
}
.empty-state h3 {
  margin: 0 0 8px 0;
  color: #495057;
}
.empty-row {
  border: none;
}
.empty-row:hover {
  background: transparent;
}
.empty-cell {
  padding: 60px 20px !important;
  text-align: center;
  border: none;
}
.empty-state-inline {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  text-align: center;
}
.empty-state-inline i {
  font-size: 3rem;
  margin-bottom: 16px;
  color: #9ca3af;
}
.empty-state-inline h3 {
  margin: 0 0 8px 0;
  color: #495057;
  font-size: 18px;
}
.empty-state-inline p {
  margin: 8px 0;
  color: #6c757d;
  font-size: 14px;
}
.orders-card {
  background: #FAFBFC;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #E2E8F0;
  margin-bottom: 20px;
  overflow-x: hidden;
  max-width: 100%;
}
.tabs-section {
  display: flex;
  gap: 4px;
  padding: 0 0 16px 0;
  margin-bottom: 16px;
  border-bottom: 2px solid #E2E8F0;
  overflow-x: auto;
  scrollbar-width: thin;
  scrollbar-color: #CBD5E1 transparent;
}
.tabs-section::-webkit-scrollbar {
  height: 4px;
}
.tabs-section::-webkit-scrollbar-track {
  background: transparent;
}
.tabs-section::-webkit-scrollbar-thumb {
  background: #CBD5E1;
  border-radius: 2px;
}
.tab-btn {
  padding: 10px 18px;
  border: none;
  background: transparent;
  border-radius: 8px 8px 0 0;
  font-size: 13px;
  font-weight: 600;
  color: #64748B;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  display: flex;
  align-items: center;
  gap: 8px;
  white-space: nowrap;
  position: relative;
  border-bottom: 3px solid transparent;
  margin-bottom: -2px;
}
.tab-btn::after {
  content: '';
  position: absolute;
  bottom: -2px;
  left: 0;
  right: 0;
  height: 3px;
  background: #FED7AA;
  transform: scaleX(0);
  transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  border-radius: 2px 2px 0 0;
}
.tab-btn:hover {
  color: #475569;
  background: #F8F9FA;
}
.tab-btn:hover::after {
  transform: scaleX(0.5);
  background: #FED7AA;
}
.tab-btn.active {
  color: #F97316;
  background: #FEF7ED;
  border-bottom-color: #FED7AA;
}
.tab-btn.active::after {
  transform: scaleX(1);
  background: #FED7AA;
}
.tab-count {
  padding: 3px 9px;
  background: #F1F5F9;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
  color: #64748B;
  min-width: 22px;
  text-align: center;
  line-height: 1.2;
  transition: all 0.2s ease;
}
.tab-btn:hover .tab-count {
  background: #FED7AA;
  color: #F59E0B;
}
.tab-btn.active .tab-count {
  background: #FFEBD6;
  color: #FF8C42;
  box-shadow: 0 1px 3px rgba(255, 140, 66, 0.3);
}
.table-header-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0;
  background: transparent;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 2px solid #E2E8F0;
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
}
.table-title {
  display: flex;
  align-items: center;
  gap: 12px;
}
.table-title h3 {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
  color: #1E293B;
  letter-spacing: -0.2px;
  flex-shrink: 0;
}
.table-count {
  padding: 4px 12px;
  background: #F3F4F6;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
}
.bulk-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}
.selected-count {
  font-size: 13px;
  color: #6B7280;
  font-weight: 600;
  margin-right: 8px;
}
.bulk-btn {
  width: 36px;
  height: 36px;
  border: 1px solid #E5E5E5;
  background: white;
  cursor: pointer;
  border-radius: 8px;
  font-size: 14px;
  color: #666;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}
.bulk-btn:hover:not(:disabled) {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.bulk-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background: #F3F4F6;
  border-color: #E5E7EB;
  color: #9CA3AF;
}
.bulk-btn-delete {
  color: #EF4444;
  border-color: #FEE2E2;
  background: #FEF2F2;
}
.bulk-btn-delete:hover:not(:disabled) {
  background: #FEE2E2;
  border-color: #EF4444;
  color: #DC2626;
}
.table-wrapper {
  overflow-x: hidden;
}
.modern-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  background: white;
  border-radius: 10px;
  overflow: hidden;
  border: 1px solid #E2E8F0;
  table-layout: fixed;
}
.modern-table thead {
  background: #F8F9FA;
}
.modern-table th {
  padding: 14px 16px;
  text-align: left;
  font-size: 12px;
  font-weight: 700;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 2px solid #E2E8F0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.modern-table tbody tr {
  transition: all 0.2s ease;
  border-bottom: 1px solid #F1F5F9;
}
.modern-table tbody tr:hover {
  background: #F8F9FA;
  transform: scale(1);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}
.modern-table tbody tr.row-selected {
  background: #FFF9F5 !important;
}
.modern-table tbody tr:active {
  background: transparent !important;
}
.modern-table tbody tr:focus {
  background: transparent !important;
  outline: none;
}
.modern-table tbody tr:last-child td {
  border-bottom: none;
}
.modern-table td {
  padding: 14px 16px;
  font-size: 13px;
  color: #1E293B;
  vertical-align: middle;
  overflow: hidden;
  text-overflow: ellipsis;
  word-wrap: break-word;
}
.checkbox-col {
  width: 40px;
  padding: 16px !important;
}
.checkbox-input {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #FF8C42;
}
.order-id {
  color: #0F172A;
  font-weight: 700;
  font-size: 13px;
}
.customer-cell {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.customer-name {
  font-weight: 600;
  color: #0F172A;
  font-size: 13px;
}
.customer-phone {
  font-size: 12px;
  color: #475569;
  font-weight: 500;
}
.branch-cell {
  color: #334155;
  font-weight: 600;
  font-size: 13px;
}
.items-count {
  font-weight: 600;
  color: #1a1a1a;
}
.amount-cell {
  font-weight: 700;
  color: #FF8C42;
  font-size: 13px;
}
.date-cell {
  font-size: 13px;
  color: #475569;
  font-weight: 500;
}
.table-number-cell {
  font-weight: 600;
  color: #0F172A;
  font-size: 13px;
}
.delivery-address-cell {
  font-size: 13px;
  color: #6B7280;
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
}
.text-muted {
  color: #9CA3AF;
  font-style: italic;
}
.payment-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  align-items: flex-start;
}
.payment-method-text {
  font-size: 11px;
  color: #6B7280;
  font-weight: 500;
}
.btn-assign {
  color: #9333EA;
  border-color: #F3E8FF;
  background: #FAF5FF;
}
.btn-assign:hover:not(:disabled) {
  background: #F3E8FF;
  border-color: #9333EA;
  color: #7C3AED;
}
.assign-modal {
  background: white;
  border-radius: 14px;
  max-width: 500px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
}
.assign-modal .modal-header {
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.assign-modal .modal-header h3 {
  font-size: 15px;
  font-weight: 600;
  color: #1E293B;
  letter-spacing: -0.2px;
  margin: 0;
}
.assign-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.assign-modal .modal-actions {
  padding: 16px 20px;
  background: #FFF7ED;
  border-top: 1px solid #FED7AA;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
.export-modal {
  background: white;
  border-radius: 14px;
  max-width: 750px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
}
.export-modal .modal-header {
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-shrink: 0;
}
.export-modal .modal-header h3 {
  font-size: 15px;
  font-weight: 600;
  margin: 0;
  color: #1E293B;
  display: flex;
  align-items: center;
  gap: 8px;
  letter-spacing: -0.2px;
}
.header-icon {
  font-size: 18px;
  vertical-align: middle;
  margin-right: 8px;
}
.export-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.export-modal .modal-actions {
  padding: 16px 20px;
  gap: 10px;
  background: #FFF7ED;
  border-top: 1px solid #FED7AA;
  display: flex;
  justify-content: flex-end;
  flex-shrink: 0;
}
.export-modal .modal-actions .btn-close,
.export-modal .modal-actions .btn-confirm {
  padding: 12px 20px;
  border: 2px solid #F59E0B;
  background: #F59E0B;
  color: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  white-space: nowrap;
  line-height: 1;
}
.export-modal .modal-actions .btn-confirm:hover:not(:disabled) {
  background: #D97706;
  border-color: #D97706;
  color: white;
}
.export-modal .modal-actions .btn-confirm:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  background: #F59E0B;
  border-color: #F59E0B;
  color: white;
}
.export-section-card {
  background: #FAFBFC;
  border-radius: 10px;
  border: 1px solid #E2E8F0;
  margin-bottom: 16px;
  overflow: hidden;
}
.export-section-card:last-child {
  margin-bottom: 0;
}
.export-section-header {
  padding: 12px 16px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.section-title {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  display: flex;
  align-items: center;
  gap: 8px;
  letter-spacing: -0.2px;
}
.section-icon {
  font-size: 16px;
  vertical-align: middle;
  margin-right: 8px;
}
.export-section-body {
  padding: 14px 16px;
  background: white;
}
.required-asterisk {
  color: #EF4444;
  font-weight: 700;
}
.export-filters {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 24px;
}
.filter-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}
.filter-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}
@media (min-width: 600px) {
  .filter-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
.filter-row .form-group,
.filter-grid .form-group {
  margin-bottom: 0;
}
.form-input {
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
.form-input:focus {
  outline: none;
  border-color: #CBD5E1;
  box-shadow: 0 0 0 3px rgba(226, 232, 240, 0.3);
}
.form-group {
  display: flex;
  flex-direction: column;
}
.form-group label {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #64748B;
}
.label-icon {
  font-size: 14px;
  vertical-align: middle;
  margin-right: 6px;
}
.export-note {
  margin-top: 12px;
  padding: 10px 12px;
  background: #FEF3C7;
  border: 1px solid #FCD34D;
  border-left: 3px solid #F59E0B;
  border-radius: 8px;
  font-size: 12px;
  color: #92400E;
  line-height: 1.5;
  display: flex;
  align-items: flex-start;
  gap: 8px;
}
.note-icon {
  font-size: 16px;
  flex-shrink: 0;
  margin-top: 2px;
  vertical-align: middle;
}
@media (max-width: 768px) {
  .filter-row {
    grid-template-columns: 1fr;
  }
  .export-modal {
    max-width: 95%;
    max-height: 90vh;
  }
  .section-title {
    font-size: 14px;
  }
}
.order-info-summary {
  padding: 14px 16px;
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  margin-bottom: 16px;
}
.order-info-summary p {
  margin: 0 0 8px 0;
  font-size: 13px;
  color: #1E293B;
}
.order-info-summary p:last-child {
  margin-bottom: 0;
}
.order-info-summary strong {
  font-weight: 600;
  color: #1E293B;
}
.order-info-summary p {
  margin: 8px 0;
  font-size: 14px;
  color: #333;
}
.form-group {
  margin-bottom: 20px;
}
.form-group label {
  display: block;
  margin-bottom: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
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
  cursor: pointer;
  transition: all 0.2s ease;
}
.form-select:focus {
  outline: none;
  border-color: #CBD5E1;
  box-shadow: 0 0 0 3px rgba(226, 232, 240, 0.3);
}
.btn-close {
  padding: 12px 24px;
  border: 2px solid #F0E6D9;
  background: white;
  color: #666;
  cursor: pointer;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
}
.btn-close:hover {
  background: #FFF9F5;
  border-color: #FF8C42;
  color: #D35400;
}
.btn-confirm {
  padding: 10px 20px;
  border: none;
  background: linear-gradient(135deg, #FF8C42, #E67E22);
  color: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-icon {
  font-size: 14px;
  vertical-align: middle;
  margin-right: 6px;
  color: white;
}
.btn-close-modal {
  font-size: 18px;
}
.btn-confirm:hover:not(:disabled) {
  background: linear-gradient(135deg, #E67E22, #D35400);
}
.btn-confirm:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  background: linear-gradient(135deg, #FF8C42, #E67E22);
  color: white;
}
.badge-small {
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  display: inline-block;
  white-space: nowrap;
  pointer-events: none;
  user-select: none;
}
.order-type-cell {
  overflow: visible !important;
  text-overflow: clip !important;
}
.status-col,
.status-cell {
  overflow: visible !important;
  text-overflow: clip !important;
  white-space: normal !important;
}
.status-cell {
  min-width: 140px;
}
.badge-primary {
  background: #DBEAFE;
  color: #1E40AF;
  border: 1px solid #93C5FD;
}
.badge-info {
  background: #E0E7FF;
  color: #4F46E5;
  border: 1px solid #C7D2FE;
}
.badge-warning {
  background: #FEF3C7;
  color: #92400E;
  border: 1px solid #FDE68A;
}
.badge-success {
  background: #D1FAE5;
  color: #065F46;
  border: 1px solid #A7F3D0;
}
.badge-danger {
  background: #FEE2E2;
  color: #991B1B;
  border: 1px solid #FECACA;
}
.badge-secondary {
  background: #F1F5F9;
  color: #334155;
  border: 1px solid #E2E8F0;
}
.action-buttons {
  display: flex;
  gap: 6px;
  align-items: center;
  flex-wrap: nowrap;
  min-width: 0;
}
.btn-action {
  width: 36px;
  height: 36px;
  min-width: 36px;
  flex-shrink: 0;
  border: 1px solid #E5E5E5;
  background: white;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748B;
  transition: all 0.2s ease;
  font-size: 14px;
}
.btn-action:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}
.btn-action:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-action.btn-view {
  color: #3B82F6;
  border-color: #DBEAFE;
  background: #EFF6FF;
}
.btn-action.btn-view:hover:not(:disabled) {
  background: #DBEAFE;
  border-color: #3B82F6;
  color: #2563EB;
}
.btn-action.btn-view-detail {
  color: #6B7280;
  border-color: #E5E7EB;
  background: #F9FAFB;
}
.btn-action.btn-view-detail:hover:not(:disabled) {
  background: #E5E7EB;
  border-color: #6B7280;
  color: #4B5563;
}
.btn-action.btn-edit {
  color: #10B981;
  border-color: #D1FAE5;
  background: #ECFDF5;
}
.btn-action.btn-edit:hover:not(:disabled) {
  background: #D1FAE5;
  border-color: #10B981;
  color: #059669;
}
.btn-action.btn-delete {
  color: #EF4444;
  border-color: #FEE2E2;
  background: #FEF2F2;
}
.btn-action.btn-delete:hover:not(:disabled) {
  background: #FEE2E2;
  border-color: #EF4444;
  color: #DC2626;
}
.delete-modal {
  background: white;
  border-radius: 14px;
  max-width: 500px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
}
.delete-modal .modal-header {
  padding: 24px;
  background: white;
  border-bottom: 1px solid #F0E6D9;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.delete-header {
  display: flex;
  align-items: center;
  gap: 16px;
}
.delete-header-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: #FEE2E2;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #EF4444;
  font-size: 24px;
}
.delete-modal .modal-body {
  padding: 24px;
  flex: 1;
  overflow-y: auto;
  background: white;
}
.delete-modal .modal-body p {
  margin: 0 0 12px 0;
  color: #333;
  font-size: 14px;
}
.delete-modal .modal-body .warning {
  color: #EF4444;
  font-weight: 500;
}
.delete-modal .modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 20px 24px;
  border-top: 1px solid #F0E6D9;
}
.delete-modal .modal-actions .btn {
  padding: 10px 20px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.delete-modal .modal-actions .btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.delete-modal .modal-actions .btn-secondary {
  background: #F3F4F6;
  color: #6B7280;
  border: 1px solid #E5E5E5;
}
.delete-modal .modal-actions .btn-secondary:hover:not(:disabled) {
  background: #E5E7EB;
}
.delete-modal .modal-actions .btn-danger {
  background: #EF4444;
  color: white;
  border: none;
}
.delete-modal .modal-actions .btn-danger:hover:not(:disabled) {
  background: #DC2626;
}
.delete-modal .modal-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: #1a1a1a;
}
.edit-modal {
  background: white;
  border-radius: 14px;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
}
.edit-modal .modal-header {
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.edit-header {
  display: flex;
  align-items: center;
  gap: 12px;
}
.edit-header-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: #FEF3C7;
  color: #F59E0B;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
}
.edit-modal .modal-header h3 {
  font-size: 16px;
  font-weight: 600;
  color: #1E293B;
  margin: 0;
}
.edit-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.edit-form {
  display: flex;
  flex-direction: column;
  gap: 24px;
}
.form-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px;
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
}
.section-title {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
  margin-bottom: 4px;
}
.section-title i {
  color: #F59E0B;
  font-size: 16px;
  width: 20px;
  text-align: center;
}
.edit-form .form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.edit-form .form-group label {
  font-size: 13px;
  font-weight: 500;
  color: #64748B;
  margin-bottom: 4px;
}
.edit-form .form-select,
.edit-form .form-textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  color: #1E293B;
  font-weight: 500;
  transition: all 0.2s ease;
  font-family: inherit;
}
.edit-form .form-select:focus,
.edit-form .form-textarea:focus {
  outline: none;
  border-color: #F59E0B;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1);
}
.edit-form .form-textarea {
  resize: vertical;
  min-height: 80px;
}
.edit-modal .modal-actions {
  padding: 16px 20px;
  border-top: 1px solid #FED7AA;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
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
.sort-toggle-btn {
  padding: 10px 14px;
  border: 2px solid #F0E6D9;
  background: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  color: #666;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 40px;
  height: 40px;
  transition: all 0.2s ease;
}
.sort-toggle-btn:hover {
  background: #FFF9F5;
  border-color: #FF8C42;
  color: #FF8C42;
}
.dropdown-item.disabled {
  opacity: 0.5;
  pointer-events: none;
}
.pagination-section {
  display: flex;
  justify-content: center;
  margin-top: 24px;
  margin-bottom: 24px;
  padding: 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}
.pagination-nav {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  width: 100%;
}
.pagination-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}
.pagination-label {
  font-size: 13px;
  color: #6B7280;
  font-weight: 500;
}
.pagination-select {
  padding: 6px 10px;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  color: #1a1a1a;
  cursor: pointer;
  transition: all 0.2s ease;
}
.pagination-select:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.pagination-buttons {
  display: flex;
  align-items: center;
  gap: 16px;
}
.pagination-btn {
  width: 40px;
  height: 40px;
  border: 1px solid #E5E5E5;
  background: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  color: #666;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}
.pagination-btn:hover:not(:disabled) {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.pagination-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  background: #F8F8F8;
}
.pagination-info {
  font-size: 14px;
  font-weight: 600;
  color: #1a1a1a;
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
.quick-modal {
  background: white;
  border-radius: 14px;
  max-width: 700px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
}
.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.modal-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}
.order-id-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  background: #FFF7ED;
  border: 1px solid #FED7AA;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
}
.order-id-badge i {
  color: #F59E0B;
  font-size: 14px;
}
.modal-status-badge {
  padding: 8px 14px;
  font-size: 12px;
  font-weight: 600;
}
.btn-close-modal {
  padding: 0;
  border: none;
  background: transparent;
  cursor: pointer;
  color: #64748B;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  line-height: 1;
  font-size: 20px;
}
.btn-close-modal:hover {
  color: #475569;
}
.modal-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  gap: 16px;
}
.modal-loading p {
  color: #666;
  font-size: 14px;
}
.modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.order-info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
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
.card-content .quick-status-buttons {
  margin-top: 4px;
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
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1);
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
}
.small-badge {
  padding: 4px 10px;
  font-size: 11px;
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
.modal-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  padding-top: 16px;
  border-top: 1px solid #FED7AA;
  flex-wrap: wrap;
}
.btn-view-full {
  padding: 10px 18px;
  border: 1px solid #3B82F6;
  background: white;
  color: #3B82F6;
  cursor: pointer;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s ease;
}
.btn-view-full:hover {
  background: #EFF6FF;
  border-color: #2563EB;
  color: #2563EB;
}
.btn-close {
  padding: 12px 20px;
  border: 2px solid #EF4444;
  background: white;
  color: #EF4444;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  white-space: nowrap;
  line-height: 1;
}
.btn-close:hover {
  background: #FEE2E2;
  border-color: #DC2626;
  color: #DC2626;
}
.btn-print {
  padding: 12px 20px;
  border: 2px solid #F59E0B;
  background: #F59E0B;
  color: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  white-space: nowrap;
  line-height: 1;
}
.btn-print:hover {
  background: #D97706;
  border-color: #D97706;
  color: white;
}
.btn-kitchen {
  padding: 10px 18px;
  border: 1px solid #10B981;
  background: white;
  color: #10B981;
  cursor: pointer;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-kitchen:hover {
  background: #ECFDF5;
  border-color: #059669;
  color: #059669;
}
.form-textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  color: #1E293B;
  font-weight: 500;
  transition: all 0.2s ease;
  resize: vertical;
  font-family: inherit;
}
.form-textarea:focus {
  outline: none;
  border-color: #CBD5E1;
  box-shadow: 0 0 0 3px rgba(226, 232, 240, 0.3);
}
.btn-logs {
  padding: 12px 20px;
  border: 2px solid #6B7280;
  background: white;
  color: #6B7280;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  white-space: nowrap;
  line-height: 1;
}
.btn-logs:hover {
  background: #F9FAFB;
  border-color: #4B5563;
  color: #4B5563;
}
.logs-modal {
  background: white;
  border-radius: 14px;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
}
.logs-modal .modal-header {
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.logs-modal .modal-header h3 {
  font-size: 15px;
  font-weight: 600;
  color: #1E293B;
  letter-spacing: -0.2px;
  margin: 0;
}
.logs-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.logs-modal .modal-actions {
  padding: 16px 20px;
  background: #FFF7ED;
  border-top: 1px solid #FED7AA;
  display: flex;
  justify-content: flex-end;
}
.logs-timeline {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 0;
}
.log-item {
  display: flex;
  gap: 16px;
  position: relative;
  padding-left: 24px;
}
.log-item:not(:last-child)::before {
  content: '';
  position: absolute;
  left: 7px;
  top: 24px;
  bottom: -20px;
  width: 2px;
  background: #E5E5E5;
}
.log-time {
  min-width: 140px;
  font-size: 12px;
  color: #9CA3AF;
  font-weight: 500;
  padding-top: 4px;
}
.log-content {
  flex: 1;
  padding: 12px 14px;
  background: #FAFBFC;
  border-radius: 8px;
  border: 1px solid #E2E8F0;
  border-left: 3px solid #64748B;
}
.log-action {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  font-size: 14px;
  color: #1a1a1a;
}
.log-dot {
  font-size: 8px;
  margin-right: 4px;
}
.log-dot.log-status {
  color: #3B82F6;
}
.log-dot.log-payment {
  color: #10B981;
}
.log-dot.log-note {
  color: #F59E0B;
}
.log-dot.log-delivery {
  color: #8B5CF6;
}
.log-change {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
  font-size: 13px;
}
.old-value {
  color: #6B7280;
  text-decoration: line-through;
}
.new-value {
  color: #1a1a1a;
  font-weight: 600;
}
.log-user {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #6B7280;
  margin-top: 8px;
}
.log-user i {
  font-size: 10px;
}
.log-metadata {
  margin-top: 6px;
  font-size: 11px;
  color: #9CA3AF;
}
.badge-new-orders {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: #EF4444;
  color: white;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  animation: pulse-badge 2s infinite;
  cursor: pointer;
  transition: all 0.2s ease;
}
.badge-new-orders:hover {
  background: #DC2626;
  transform: scale(1.05);
}
@keyframes pulse-badge {
  0%, 100% {
    opacity: 1;
    box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7);
  }
  50% {
    opacity: 0.9;
    box-shadow: 0 0 0 8px rgba(239, 68, 68, 0);
  }
}
.pagination-info {
  font-size: 13px;
  font-weight: 600;
  color: #333;
  padding: 0 8px;
}
@media (max-width: 768px) {
  .stats-section {
    flex-direction: column;
    gap: 15px;
  }
  .filter-row {
    flex-direction: column;
    align-items: stretch;
  }
  .filter-select,
  .filter-input {
    min-width: auto;
  }
  .table-responsive {
    font-size: 12px;
  }
  .action-buttons {
    flex-direction: column;
  }
}
.charts-section {
  margin-top: 20px;
  margin-bottom: 20px;
  border-radius: 12px;
}
.charts-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 2px solid #F0E6D9;
}
.charts-header h2 {
  margin: 0;
  font-size: 22px;
  font-weight: 700;
  color: #333;
  letter-spacing: -0.3px;
}
.btn-close-charts {
  padding: 10px 18px;
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
}
.charts-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}
.chart-item {
  background: #FFF9F5;
  border-radius: 12px;
  border: 1px solid #F0E6D9;
  overflow: hidden;
  padding: 16px;
}
@media (max-width: 1200px) {
  .charts-grid {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 768px) {
  .charts-section {
    padding: 15px;
  }
  .charts-header {
    flex-direction: column;
    gap: 15px;
    align-items: stretch;
  }
  .charts-header h2 {
    text-align: center;
  }
}
</style>
