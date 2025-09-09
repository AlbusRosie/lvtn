<template>
  <div class="table-card" :class="statusClass">
    <div class="table-header">
      <h3 class="table-number">{{ table.table_number }}</h3>
      <span class="status-badge" :class="`status-${table.status}`">
        {{ getStatusLabel(table.status) }}
      </span>
    </div>

    <div class="table-info">
      <div class="info-item">
        <i class="fas fa-building"></i>
        <span>{{ table.branch_name }}</span>
      </div>

      <div class="info-item">
        <i class="fas fa-layer-group"></i>
        <span>{{ table.floor_name }}</span>
      </div>

      <div class="info-item">
        <i class="fas fa-users"></i>
        <span>Sức chứa: {{ table.capacity }} người</span>
      </div>

      <div class="info-item" v-if="table.location">
        <i class="fas fa-map-marker-alt"></i>
        <span>{{ table.location }}</span>
      </div>

      <div class="info-item">
        <i class="fas fa-calendar"></i>
        <span>Tạo: {{ formatDate(table.created_at) }}</span>
      </div>
    </div>

    <div class="table-actions" v-if="isAdmin">
      <button
        @click="$emit('edit', table)"
        class="btn btn-edit"
        title="Chỉnh sửa"
      >
        <i class="fas fa-edit"></i>
      </button>

      <button
        @click="$emit('delete', table)"
        class="btn btn-delete"
        title="Xóa"
        :disabled="table.status === 'occupied' || table.status === 'reserved'"
      >
        <i class="fas fa-trash"></i>
      </button>

      <div class="status-actions">
        <button
          v-for="status in availableStatuses"
          :key="status.value"
          @click="$emit('updateStatus', table.id, status.value)"
          class="btn btn-status"
          :class="`btn-${status.value}`"
          :title="`Đặt trạng thái: ${status.label}`"
        >
          <i :class="status.icon"></i>
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import TableService from '@/services/TableService';

export default {
  name: 'TableCard',
  props: {
    table: {
      type: Object,
      required: true
    },
    isAdmin: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    statusClass() {
      return `status-${this.table.status}`;
    },
    availableStatuses() {
      const currentStatus = this.table.status;
      const allStatuses = [
        { value: 'available', label: 'Có sẵn', icon: 'fas fa-check' },
        { value: 'occupied', label: 'Đang sử dụng', icon: 'fas fa-users' },
        { value: 'reserved', label: 'Đã đặt trước', icon: 'fas fa-clock' },
        { value: 'maintenance', label: 'Bảo trì', icon: 'fas fa-tools' }
      ];

      return allStatuses.filter(status => status.value !== currentStatus);
    }
  },
  methods: {
    getStatusLabel(status) {
      return TableService.getStatusLabel(status);
    },
    formatDate(dateString) {
      return new Date(dateString).toLocaleDateString('vi-VN');
    }
  }
};
</script>

<style scoped>
.table-card {
  background: white;
  border-radius: 8px;
  padding: 16px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  border-left: 4px solid #ddd;
  transition: all 0.3s ease;
}

.table-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.table-number {
  font-size: 1.2rem;
  font-weight: bold;
  margin: 0;
  color: #333;
}

.status-badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
  text-transform: uppercase;
}

.status-available {
  border-left-color: #10b981;
}

.status-available .status-badge {
  background: #d1fae5;
  color: #065f46;
}

.status-occupied {
  border-left-color: #ef4444;
}

.status-occupied .status-badge {
  background: #fee2e2;
  color: #991b1b;
}

.status-reserved {
  border-left-color: #f59e0b;
}

.status-reserved .status-badge {
  background: #fef3c7;
  color: #92400e;
}

.status-maintenance {
  border-left-color: #6b7280;
}

.status-maintenance .status-badge {
  background: #f3f4f6;
  color: #374151;
}

.table-info {
  margin-bottom: 16px;
}

.info-item {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
  font-size: 0.9rem;
  color: #666;
}

.info-item i {
  width: 16px;
  margin-right: 8px;
  color: #999;
}

.table-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.btn {
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
  transition: all 0.2s ease;
}

.btn:hover {
  transform: translateY(-1px);
}

.btn-edit {
  background: #3b82f6;
  color: white;
}

.btn-edit:hover {
  background: #2563eb;
}

.btn-delete {
  background: #ef4444;
  color: white;
}

.btn-delete:hover:not(:disabled) {
  background: #dc2626;
}

.btn-delete:disabled {
  background: #9ca3af;
  cursor: not-allowed;
  transform: none;
}

.status-actions {
  display: flex;
  gap: 4px;
}

.btn-status {
  padding: 4px 8px;
  font-size: 0.7rem;
}

.btn-available {
  background: #10b981;
  color: white;
}

.btn-available:hover {
  background: #059669;
}

.btn-occupied {
  background: #ef4444;
  color: white;
}

.btn-occupied:hover {
  background: #dc2626;
}

.btn-reserved {
  background: #f59e0b;
  color: white;
}

.btn-reserved:hover {
  background: #d97706;
}

.btn-maintenance {
  background: #6b7280;
  color: white;
}

.btn-maintenance:hover {
  background: #4b5563;
}
</style>