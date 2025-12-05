<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { Bar, Line } from 'vue-chartjs';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js';
ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
);
const props = defineProps({
  data: {
    type: Object,
    default: () => ({
      labels: [],
      datasets: []
    })
  },
  period: {
    type: String,
    default: 'week' 
  },
  loading: {
    type: Boolean,
    default: false
  },
  dateFrom: {
    type: String,
    default: ''
  },
  dateTo: {
    type: String,
    default: ''
  }
});
const emit = defineEmits(['period-change', 'navigate', 'date-range-change', 'pan']);
const chartType = ref('bar'); 
const isPanning = ref(false);
const panStartX = ref(0);
const panThreshold = 50; 
const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'top',
      align: 'end',
      labels: {
        usePointStyle: true,
        padding: 16,
        font: {
          size: 12,
          weight: 600
        },
        color: '#64748B',
        boxWidth: 8,
        boxHeight: 8
      }
    },
    title: {
      display: false
    },
    tooltip: {
      mode: 'index',
      intersect: false,
      backgroundColor: 'rgba(30, 41, 59, 0.95)',
      titleColor: '#F1F5F9',
      bodyColor: '#F1F5F9',
      borderColor: 'rgba(255, 255, 255, 0.1)',
      borderWidth: 1,
      cornerRadius: 10,
      displayColors: true,
      padding: 12,
      titleFont: {
        size: 12,
        weight: 600
      },
      bodyFont: {
        size: 12
      },
      callbacks: {
        label: function(context) {
          const label = context.dataset.label || '';
          const value = context.parsed.y;
          return `${label}: ${formatCurrency(value)}`;
        }
      }
    }
  },
  scales: {
    x: {
      display: true,
      stacked: chartType.value === 'bar',
      grid: {
        display: false,
        drawBorder: false
      },
      ticks: {
        font: {
          size: 11,
          weight: 500
        },
        color: '#64748B',
        padding: 8
      }
    },
    y: {
      display: true,
      stacked: chartType.value === 'bar',
      beginAtZero: true,
      grid: {
        color: 'rgba(226, 232, 240, 0.6)',
        drawBorder: false,
        lineWidth: 1
      },
      ticks: {
        font: {
          size: 11,
          weight: 500
        },
        color: '#64748B',
        padding: 8,
        callback: function(value) {
          return formatCurrency(value);
        }
      }
    }
  },
  interaction: {
    mode: 'nearest',
    axis: 'x',
    intersect: false
  },
  elements: {
    line: {
      tension: 0.4,
      borderWidth: 3,
      fill: true
    },
    point: {
      radius: 4,
      hoverRadius: 6,
      borderWidth: 2,
      hoverBorderWidth: 3
    }
  }
}));
const chartData = computed(() => {
  if (!props.data || !props.data.labels || !props.data.datasets) {
    return {
      labels: [],
      datasets: []
    };
  }
  return {
    labels: props.data.labels,
    datasets: props.data.datasets.map((dataset, index) => {
      if (chartType.value === 'bar') {
        return {
          ...dataset,
          type: 'bar',
          backgroundColor: dataset.backgroundColor || getDatasetColor(index, 0.7),
          borderColor: dataset.borderColor || getDatasetColor(index, 1),
          borderWidth: 0,
          borderRadius: 6,
          maxBarThickness: 32,
          categoryPercentage: 0.7,
          barPercentage: 0.85
        };
      }
      return {
        ...dataset,
        type: 'line',
        fill: true,
        backgroundColor: dataset.backgroundColor || getDatasetColor(index, 0.1),
        borderColor: dataset.borderColor || getDatasetColor(index, 1),
        pointBackgroundColor: getDatasetColor(index, 1),
        pointBorderColor: '#ffffff',
        pointHoverBackgroundColor: getDatasetColor(index, 1),
        pointHoverBorderColor: '#ffffff'
      };
    })
  };
});
function getDatasetColor(index, alpha = 1) {
  const colors = [
    `rgba(59, 130, 246, ${alpha})`, 
    `rgba(34, 197, 94, ${alpha})`, 
    `rgba(255, 193, 7, ${alpha})`, 
    `rgba(220, 53, 69, ${alpha})`, 
    `rgba(108, 117, 125, ${alpha})`, 
    `rgba(23, 162, 184, ${alpha})` 
  ];
  return colors[index % colors.length];
}
function formatCurrency(amount) {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(amount);
}
const periodOptions = [
  { value: 'day', label: 'Day' },
  { value: 'week', label: 'Week' },
  { value: 'month', label: 'Month' },
  { value: 'year', label: 'Year' }
];
function handlePeriodChange(period) {
  emit('period-change', period);
}
function handleNavigate(direction) {
  emit('navigate', direction);
}
function handleDateRangeChange(event, type) {
  const value = event.target.value;
  if (type === 'from') {
    emit('date-range-change', value, props.dateTo);
  } else if (type === 'to') {
    emit('date-range-change', props.dateFrom, value);
  }
}
function handlePanStart(event) {
  isPanning.value = true;
  panStartX.value = event.clientX;
}
function handlePanMove(event) {
  if (!isPanning.value) return;
  const deltaX = event.clientX - panStartX.value;
  if (Math.abs(deltaX) > panThreshold) {
  }
}
function handlePanEnd(event) {
  if (!isPanning.value) return;
  const deltaX = event.clientX - panStartX.value;
  if (Math.abs(deltaX) > panThreshold) {
    if (deltaX > 0) {
      emit('pan', 'right');
    } else {
      emit('pan', 'left');
    }
  }
  isPanning.value = false;
  panStartX.value = 0;
}
</script>
<template>
  <div class="revenue-chart">
    <!-- Compact Header -->
    <div class="chart-header">
      <div class="header-left">
        <div class="chart-type-toggle">
          <button 
            class="toggle-btn"
            :class="{ active: chartType === 'bar' }"
            @click="chartType = 'bar'"
            title="Bar Chart"
          >
            <i class="fas fa-chart-bar"></i>
          </button>
          <button 
            class="toggle-btn"
            :class="{ active: chartType === 'line' }"
            @click="chartType = 'line'"
            title="Line Chart"
          >
            <i class="fas fa-chart-line"></i>
          </button>
        </div>
        <div class="period-tabs" style="display: none;">
          <button 
            v-for="option in periodOptions" 
            :key="option.value"
            @click="handlePeriodChange(option.value)"
            :class="['period-tab', { active: period === option.value }]"
          >
            {{ option.label }}
          </button>
        </div>
      </div>
      <div class="header-right">
        <div class="date-range-compact">
          <input 
            type="date"
            :value="dateFrom"
            @change="handleDateRangeChange($event, 'from')"
            class="date-input-compact"
            title="From Date"
          />
          <span class="date-separator">→</span>
          <input 
            type="date"
            :value="dateTo"
            @change="handleDateRangeChange($event, 'to')"
            class="date-input-compact"
            title="To Date"
          />
        </div>
      </div>
    </div>
    <!-- Chart Container -->
    <div class="chart-container">
      <div v-if="loading" class="chart-loading">
        <div class="spinner"></div>
        <p>Loading data...</p>
      </div>
      <div v-else-if="!data.labels || data.labels.length === 0" class="chart-empty">
        <i class="fas fa-chart-line"></i>
        <p>No data to display</p>
      </div>
      <div 
        v-else 
        class="chart-wrapper"
        @mousedown="handlePanStart"
        @mousemove="handlePanMove"
        @mouseup="handlePanEnd"
        @mouseleave="handlePanEnd"
        :class="{ 'panning': isPanning }"
      >
        <component :is="chartType === 'bar' ? Bar : Line"
                   :data="chartData"
                   :options="chartOptions" />
        <div v-if="isPanning" class="pan-indicator">
          <i class="fas fa-arrows-alt-h"></i>
          <span>Drag to view more data</span>
        </div>
      </div>
    </div>
    <!-- Summary Cards -->
    <div v-if="data.summary" class="chart-summary">
      <div class="summary-card">
        <div class="summary-icon" style="background: rgba(59, 130, 246, 0.1); color: #3b82f6;">
          <i class="fas fa-coins"></i>
        </div>
        <div class="summary-content">
          <div class="summary-label">Total Revenue</div>
          <div class="summary-value">{{ formatCurrency(data.summary.total) }}</div>
        </div>
      </div>
      <div class="summary-card">
        <div class="summary-icon" style="background: rgba(34, 197, 94, 0.1); color: #22c55e;">
          <i class="fas fa-chart-area"></i>
        </div>
        <div class="summary-content">
          <div class="summary-label">Average</div>
          <div class="summary-value">{{ formatCurrency(data.summary.average) }}</div>
        </div>
      </div>
      <div class="summary-card">
        <div class="summary-icon" style="background: rgba(255, 140, 66, 0.1); color: #FF8C42;">
          <i class="fas fa-arrow-up"></i>
        </div>
        <div class="summary-content">
          <div class="summary-label">Highest</div>
          <div class="summary-value">{{ formatCurrency(data.summary.max) }}</div>
        </div>
      </div>
    </div>
  </div>
</template>
<style scoped>
.revenue-chart {
  background: white;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  height: 100%;
}
.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 20px;
  background: linear-gradient(to right, #F8F9FA 0%, #FFFFFF 100%);
  border-bottom: 1px solid #E2E8F0;
  gap: 16px;
  flex-wrap: wrap;
}
.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
  flex: 1;
}
.header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}
.chart-type-toggle {
  display: flex;
  background: #F1F5F9;
  border-radius: 8px;
  padding: 2px;
  gap: 2px;
}
.toggle-btn {
  padding: 8px 12px;
  border: none;
  background: transparent;
  cursor: pointer;
  border-radius: 6px;
  color: #64748B;
  font-size: 14px;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}
.toggle-btn:hover {
  background: rgba(255, 255, 255, 0.5);
  color: #334155;
}
.toggle-btn.active {
  background: white;
  color: #FF8C42;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}
.period-tabs {
  display: flex;
  background: #F1F5F9;
  border-radius: 8px;
  padding: 2px;
  gap: 2px;
}
.period-tab {
  padding: 8px 16px;
  border: none;
  background: transparent;
  cursor: pointer;
  border-radius: 6px;
  color: #64748B;
  font-size: 12px;
  font-weight: 600;
  transition: all 0.2s ease;
  white-space: nowrap;
}
.period-tab:hover {
  background: rgba(255, 255, 255, 0.5);
  color: #334155;
}
.period-tab.active {
  background: white;
  color: #FF8C42;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}
.date-range-compact {
  display: flex;
  align-items: center;
  gap: 8px;
  background: white;
  padding: 6px 12px;
  border-radius: 8px;
  border: 1px solid #E2E8F0;
}
.date-input-compact {
  border: none;
  background: transparent;
  padding: 4px 0;
  font-size: 12px;
  color: #334155;
  font-weight: 500;
  width: 110px;
  cursor: pointer;
}
.date-input-compact:focus {
  outline: none;
}
.date-input-compact::-webkit-calendar-picker-indicator {
  cursor: pointer;
  opacity: 0.6;
}
.date-separator {
  color: #94A3B8;
  font-size: 12px;
  font-weight: 500;
}
.nav-controls-compact {
  display: flex;
  gap: 4px;
  background: #F1F5F9;
  border-radius: 8px;
  padding: 2px;
}
.nav-controls-bottom {
  display: flex;
  justify-content: center;
  gap: 8px;
  padding: 12px 0;
  border-top: 1px solid #E2E8F0;
}
.nav-btn-compact {
  padding: 8px 10px;
  border: none;
  background: transparent;
  cursor: pointer;
  border-radius: 6px;
  color: #64748B;
  font-size: 12px;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 32px;
}
.nav-btn-compact:hover {
  background: white;
  color: #FF8C42;
}
.nav-controls-bottom .nav-btn-compact {
  width: 36px;
  height: 36px;
  border: 1px solid #E2E8F0;
  background: white;
  border-radius: 8px;
  min-width: 36px;
  padding: 0;
}
.nav-controls-bottom .nav-btn-compact:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
  transform: translateY(-1px);
}
.chart-container {
  position: relative;
  flex: 1;
  min-height: 400px;
  padding: 20px;
  background: white;
}
.chart-loading,
.chart-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #94A3B8;
}
.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #F1F5F9;
  border-top: 3px solid #FF8C42;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin-bottom: 16px;
}
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
.chart-empty i {
  font-size: 48px;
  margin-bottom: 12px;
  color: #CBD5E1;
}
.chart-empty p {
  margin: 0;
  font-size: 14px;
  color: #64748B;
}
.chart-wrapper {
  height: 100%;
  width: 100%;
  position: relative;
  cursor: grab;
  user-select: none;
}
.chart-wrapper.panning {
  cursor: grabbing;
}
.pan-indicator {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: rgba(30, 41, 59, 0.9);
  color: white;
  padding: 12px 20px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  font-weight: 600;
  z-index: 10;
  pointer-events: none;
  animation: panPulse 0.3s ease;
}
.pan-indicator i {
  font-size: 16px;
}
@keyframes panPulse {
  0% {
    opacity: 0;
    transform: translate(-50%, -50%) scale(0.9);
  }
  100% {
    opacity: 1;
    transform: translate(-50%, -50%) scale(1);
  }
}
.chart-summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  padding: 16px 20px;
  background: #F8F9FA;
  border-top: 1px solid #E2E8F0;
}
.summary-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: white;
  border-radius: 10px;
  border: 1px solid #E2E8F0;
  transition: all 0.2s ease;
}
.summary-card:hover {
  border-color: #FF8C42;
  box-shadow: 0 2px 8px rgba(255, 140, 66, 0.1);
}
.summary-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}
.summary-content {
  flex: 1;
  min-width: 0;
}
.summary-label {
  font-size: 11px;
  color: #64748B;
  font-weight: 500;
  margin-bottom: 4px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.summary-value {
  font-size: 16px;
  font-weight: 700;
  color: #1E293B;
  line-height: 1.2;
}
@media (max-width: 1024px) {
  .chart-header {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  .header-left,
  .header-right {
    width: 100%;
    justify-content: space-between;
  }
  .chart-summary {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 768px) {
  .chart-header {
    padding: 12px 16px;
  }
  .header-left {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  .header-right {
    flex-direction: column;
    width: 100%;
    gap: 8px;
  }
  .date-range-compact {
    width: 100%;
    justify-content: space-between;
  }
  .date-input-compact {
    flex: 1;
  }
  .chart-container {
    min-height: 300px;
    padding: 16px;
  }
  .chart-summary {
    grid-template-columns: 1fr;
    gap: 10px;
    padding: 12px 16px;
  }
}
</style>
