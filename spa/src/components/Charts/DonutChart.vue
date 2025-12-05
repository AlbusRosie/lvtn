<script setup>
import { computed } from 'vue';
import { Doughnut } from 'vue-chartjs';
import {
  Chart as ChartJS,
  ArcElement,
  Tooltip,
  Legend
} from 'chart.js';
ChartJS.register(ArcElement, Tooltip, Legend);
const props = defineProps({
  value: {
    type: Number,
    required: true
  },
  total: {
    type: Number,
    default: 100
  },
  label: {
    type: String,
    required: true
  },
  color: {
    type: String,
    default: '#FF8C42'
  },
  percentage: {
    type: Number,
    default: null
  }
});
const percentage = computed(() => {
  if (props.percentage !== null) {
    return props.percentage;
  }
  if (props.total === 0) return 0;
  return Math.round((props.value / props.total) * 100);
});
const chartData = computed(() => {
  const pct = Math.abs(percentage.value);
  const remaining = 100 - pct;
  const getLighterColor = (color) => {
    if (color.startsWith('#')) {
      const hex = color.slice(1);
      const r = parseInt(hex.slice(0, 2), 16);
      const g = parseInt(hex.slice(2, 4), 16);
      const b = parseInt(hex.slice(4, 6), 16);
      return `rgba(${r}, ${g}, ${b}, 0.2)`;
    }
    return color + '33'; 
  };
  return {
    labels: [props.label, ''],
    datasets: [{
      data: [pct, remaining],
      backgroundColor: [props.color, getLighterColor(props.color)],
      borderWidth: 0,
      cutout: '70%'
    }]
  };
});
const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: false
    },
    tooltip: {
      enabled: false
    }
  }
}));
</script>
<template>
  <div class="donut-chart-card">
    <div class="donut-icon" v-if="$slots.icon">
      <slot name="icon"></slot>
    </div>
    <div v-else class="donut-icon">
      <i class="fas fa-chart-pie"></i>
    </div>
    <div class="donut-info">
      <div class="donut-value">{{ value.toLocaleString('vi-VN') }}</div>
      <div class="donut-label">{{ label }}</div>
    </div>
    <div class="donut-chart-wrapper">
      <Doughnut 
        :data="chartData" 
        :options="chartOptions"
      />
      <div class="chart-center">
        <span class="chart-percentage" :style="{ color: percentage < 0 ? '#EF4444' : color }">
          {{ percentage > 0 ? '+' : '' }}{{ percentage }}%
        </span>
      </div>
    </div>
  </div>
</template>
<style scoped>
.donut-chart-card {
  background: white;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  border: 1px solid #E5E5E5;
  transition: all 0.2s ease;
}
.donut-chart-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}
.donut-icon {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  background: #F3F4F6;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  color: #6B7280;
  flex-shrink: 0;
}
.donut-info {
  flex: 1;
  min-width: 0;
}
.donut-value {
  font-size: 24px;
  font-weight: 700;
  color: #1a1a1a;
  margin-bottom: 4px;
  letter-spacing: -0.5px;
  line-height: 1.2;
}
.donut-label {
  font-size: 13px;
  color: #6B7280;
  font-weight: 500;
  line-height: 1.4;
}
.donut-chart-wrapper {
  position: relative;
  width: 70px;
  height: 70px;
  flex-shrink: 0;
}
.chart-center {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
}
.chart-percentage {
  font-size: 12px;
  font-weight: 700;
}
</style>
