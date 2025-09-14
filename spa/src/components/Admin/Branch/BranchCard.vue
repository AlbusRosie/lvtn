<template>
  <div class="branch-card">
    <div class="branch-header">
      <div class="branch-info">
        <h3 class="branch-name">{{ branch.name }}</h3>
        <span class="branch-status" :class="`status-${branch.status}`">
          {{ getStatusLabel(branch.status) }}
        </span>
      </div>
      <div class="branch-actions" v-if="isAdmin">
        <button @click="$emit('edit', branch)" class="btn-icon" title="Chỉnh sửa">
          <i class="fas fa-edit"></i>
        </button>
        <button @click="$emit('delete', branch)" class="btn-icon btn-danger" title="Xóa">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>

    <div class="branch-details">
      <div class="detail-item">
        <i class="fas fa-map-marker-alt"></i>
        <div class="address-info">
          <div v-if="branch.address_detail">{{ branch.address_detail }}</div>
          <div v-if="branch.district_name || branch.province_name" class="location">
            {{ [branch.district_name, branch.province_name].filter(Boolean).join(', ') }}
          </div>
        </div>
      </div>

      <div class="detail-item">
        <i class="fas fa-phone"></i>
        <span>{{ branch.phone }}</span>
      </div>

      <div class="detail-item">
        <i class="fas fa-envelope"></i>
        <span>{{ branch.email }}</span>
      </div>

      <div class="detail-item" v-if="branch.opening_hours">
        <i class="fas fa-clock"></i>
        <span>{{ branch.opening_hours }}</span>
      </div>

      <div class="detail-item" v-if="branch.description">
        <i class="fas fa-info-circle"></i>
        <span>{{ branch.description }}</span>
      </div>
    </div>

    <div class="branch-footer">
      <div class="branch-meta">
        <span class="created-date">
          <i class="fas fa-calendar"></i>
          Tạo ngày: {{ formatDate(branch.created_at) }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
import { BRANCH_STATUS } from '@/constants';

export default {
  name: 'BranchCard',
  props: {
    branch: {
      type: Object,
      required: true
    },
    isAdmin: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    getStatusLabel(status) {
      const statusMap = {
        [BRANCH_STATUS.ACTIVE]: 'Hoạt động',
        [BRANCH_STATUS.INACTIVE]: 'Không hoạt động',
        [BRANCH_STATUS.MAINTENANCE]: 'Bảo trì'
      };
      return statusMap[status] || status;
    },

    formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleDateString('vi-VN');
    }
  }
};
</script>

<style scoped>
.branch-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  padding: 20px;
  transition: all 0.2s ease;
  border: 1px solid #e5e7eb;
}

.branch-card:hover {
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
  transform: translateY(-2px);
}

.branch-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.branch-info {
  flex: 1;
}

.branch-name {
  margin: 0 0 8px 0;
  color: #1f2937;
  font-size: 1.25rem;
  font-weight: 600;
}

.branch-status {
  display: inline-block;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
}

.status-active {
  background: #dcfce7;
  color: #166534;
}

.status-inactive {
  background: #fef2f2;
  color: #dc2626;
}

.status-maintenance {
  background: #fef3c7;
  color: #d97706;
}

.branch-actions {
  display: flex;
  gap: 8px;
}

.btn-icon {
  background: none;
  border: none;
  padding: 8px;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s ease;
  color: #6b7280;
}

.btn-icon:hover {
  background: #f3f4f6;
  color: #374151;
}

.btn-icon.btn-danger:hover {
  background: #fef2f2;
  color: #dc2626;
}

.branch-details {
  margin-bottom: 16px;
}

.detail-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  color: #6b7280;
  font-size: 0.9rem;
}

.detail-item i {
  width: 16px;
  color: #9ca3af;
}

.detail-item span {
  flex: 1;
  word-break: break-word;
}

.address-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.address-info .location {
  font-size: 0.8rem;
  color: #9ca3af;
  font-style: italic;
}

.branch-footer {
  border-top: 1px solid #e5e7eb;
  padding-top: 12px;
}

.branch-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.8rem;
  color: #9ca3af;
}

.created-date {
  display: flex;
  align-items: center;
  gap: 4px;
}

.created-date i {
  font-size: 0.75rem;
}
</style>
