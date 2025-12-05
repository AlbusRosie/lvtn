<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { Bar, Doughnut } from 'vue-chartjs';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js';
ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
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
  chartType: {
    type: String,
    default: 'bar' 
  }
});
const emit = defineEmits(['period-change', 'chart-type-change']);
const barChartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'top',
      labels: {
        usePointStyle: true,
        padding: 20,
        font: {
          size: 12
        }
      }
    },
    title: {
      display: false
    },
    tooltip: {
      mode: 'index',
      intersect: false,
      backgroundColor: 'rgba(0, 0, 0, 0.8)',
      titleColor: 'white',
      bodyColor: 'white',
      borderColor: 'rgba(255, 255, 255, 0.1)',
      borderWidth: 1,
      cornerRadius: 8,
      displayColors: true,
      callbacks: {
        label: function(context) {
          const label = context.dataset.label || '';
          const value = context.parsed.y;
          return `${label}: ${value} đặt lịch`;
        }
      }
    }
  },
  scales: {
    x: {
      display: true,
      grid: {
        display: false
      },
      ticks: {
        font: {
          size: 11
        },
        color: '#6c757d'
      }
    },
    y: {
      display: true,
      grid: {
        color: 'rgba(0, 0, 0, 0.05)',
        drawBorder: false
      },
      ticks: {
        font: {
          size: 11
        },
        color: '#6c757d',
        stepSize: 1
      }
    }
  },
  interaction: {
    mode: 'nearest',
    axis: 'x',
    intersect: false
  }
}));
const doughnutChartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom',
      labels: {
        usePointStyle: true,
        padding: 20,
        font: {
          size: 12
        }
      }
    },
    title: {
      display: false
    },
    tooltip: {
      backgroundColor: 'rgba(0, 0, 0, 0.8)',
      titleColor: 'white',
      bodyColor: 'white',
      borderColor: 'rgba(255, 255, 255, 0.1)',
      borderWidth: 1,
      cornerRadius: 8,
      displayColors: true,
      callbacks: {
        label: function(context) {
          const label = context.label || '';
          const value = context.parsed;
          const total = context.dataset.data.reduce((a, b) => a + b, 0);
          const percentage = ((value / total) * 100).toFixed(1);
          return `${label}: ${value} (${percentage}%)`;
        }
      }
    }
  },
  cutout: '60%'
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
    datasets: props.data.datasets.map((dataset, index) => ({
      ...dataset,
      backgroundColor: dataset.backgroundColor || getDatasetColor(index, 0.8),
      borderColor: dataset.borderColor || getDatasetColor(index, 1),
      borderWidth: dataset.borderWidth || 1
    }))
  };
});
function getDatasetColor(index, alpha = 1) {
  const colors = [
    `rgba(0, 123, 255, ${alpha})`, 
    `rgba(40, 167, 69, ${alpha})`, 
    `rgba(255, 193, 7, ${alpha})`, 
    `rgba(220, 53, 69, ${alpha})`, 
    `rgba(108, 117, 125, ${alpha})`, 
    `rgba(23, 162, 184, ${alpha})`, 
    `rgba(111, 66, 193, ${alpha})`, 
    `rgba(253, 126, 20, ${alpha})` 
  ];
  return colors[index % colors.length];
}
const periodOptions = [
  { value: 'day', label: 'Ngày' },
  { value: 'week', label: 'Tuần' },
  { value: 'month', label: 'Tháng' },
  { value: 'year', label: 'Năm' }
];
const chartTypeOptions = [
  { value: 'bar', label: 'Biểu đồ cột', icon: 'fas fa-chart-bar' },
  { value: 'doughnut', label: 'Biểu đồ tròn', icon: 'fas fa-chart-pie' }
];
function handlePeriodChange(period) {
  emit('period-change', period);
}
function handleChartTypeChange(event) {
  emit('chart-type-change', event.target.value);
}
</script>
<template>
  <div class="reservation-chart">
    <div class="chart-header">
      <h3>Biểu đồ đặt lịch</h3>
    </div>
    <div class="chart-container">
      <!-- Period buttons on top of chart -->
      <div class="chart-period-controls">
        <div class="period-buttons">
          <button 
            v-for="option in periodOptions" 
            :key="option.value"
            @click="handlePeriodChange(option.value)"
            :class="['period-btn', { active: period === option.value }]"
          >
            {{ option.label }}
          </button>
        </div>
        <select 
          :value="chartType" 
          @change="handleChartTypeChange"
          class="chart-type-select"
        >
          <option 
            v-for="option in chartTypeOptions" 
            :key="option.value" 
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>
      </div>
      <div v-if="loading" class="chart-loading">
        <div class="spinner"></div>
        <p>Đang tải dữ liệu...</p>
      </div>
      <div v-else-if="!data.labels || data.labels.length === 0" class="chart-empty">
        <i class="fas fa-calendar-alt"></i>
        <p>Không có dữ liệu để hiển thị</p>
      </div>
      <div v-else class="chart-wrapper">
        <Bar 
          v-if="chartType === 'bar'"
          :data="chartData" 
          :options="barChartOptions"
        />
        <Doughnut 
          v-else-if="chartType === 'doughnut'"
          :data="chartData" 
          :options="doughnutChartOptions"
        />
      </div>
    </div>
    <div v-if="data.summary" class="chart-summary">
      <div class="summary-item">
        <span class="summary-label">Tổng đặt lịch:</span>
        <span class="summary-value">{{ data.summary.total }}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">Trung bình:</span>
        <span class="summary-value">{{ Math.round(data.summary.average) }}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">Cao nhất:</span>
        <span class="summary-value">{{ data.summary.max }}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">Tỷ lệ thành công:</span>
        <span class="summary-value">{{ data.summary.successRate }}%</span>
      </div>
    </div>
  </div>
</template>
<style scoped>
.reservation-chart {
  background: white;
  border-radius: 8px;
  border: 1px solid #e9ecef;
  overflow: hidden;
}
.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  background: #f8f9fa;
  border-bottom: 1px solid #e9ecef;
}
.chart-header h3 {
  margin: 0;
  font-size: 18px;
  color: #495057;
}
.chart-container {
  position: relative;
  height: 400px;
  padding: 20px;
}
.chart-period-controls {
  position: absolute;
  top: 10px;
  right: 20px;
  z-index: 10;
  display: flex;
  gap: 10px;
  align-items: center;
}
.period-buttons {
  display: flex;
  gap: 3px;
}
.period-btn {
  padding: 2px 6px;
  border: 1px solid #ccc;
  background: white;
  cursor: pointer;
  border-radius: 2px;
  font-size: 11px;
  color: #666;
  transition: none;
}
.period-btn:hover {
  background: #f5f5f5;
}
.period-btn.active {
  background: #f5f5f5;
  color: #333;
  border-color: #999;
}
.chart-type-select {
  padding: 2px 6px;
  border: 1px solid #ccc;
  border-radius: 2px;
  background: white;
  font-size: 11px;
  color: #666;
}
.chart-type-select:focus {
  outline: none;
  border-color: #999;
}
.chart-container {
  position: relative;
  height: 400px;
  padding: 20px;
}
.chart-loading,
.chart-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #6c757d;
}
.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #007bff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 16px;
}
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
.chart-empty i {
  font-size: 3rem;
  margin-bottom: 16px;
  color: #9ca3af;
}
.chart-empty p {
  margin: 0;
  font-size: 14px;
}
.chart-wrapper {
  height: 100%;
  width: 100%;
}
.chart-summary {
  display: flex;
  justify-content: space-around;
  padding: 20px;
  background: #f8f9fa;
  border-top: 1px solid #e9ecef;
}
.summary-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}
.summary-label {
  font-size: 12px;
  color: #6c757d;
  margin-bottom: 4px;
}
.summary-value {
  font-size: 16px;
  font-weight: 600;
  color: #333;
}
@media (max-width: 768px) {
  .chart-header {
    flex-direction: column;
    gap: 15px;
    align-items: stretch;
  }
  .chart-controls {
    justify-content: center;
    flex-wrap: wrap;
  }
  .chart-container {
    height: 300px;
    padding: 15px;
  }
  .chart-summary {
    flex-direction: column;
    gap: 15px;
  }
  .summary-item {
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
  }
}
@media (max-width: 480px) {
  .chart-controls {
    flex-direction: column;
  }
  .chart-type-select,
  .period-select {
    width: 100%;
  }
}
</style>
