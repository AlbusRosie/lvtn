<template>
  <div class="category-card">
    <div class="category-header">
      <div class="category-info">
        <h3 class="category-name">{{ category.name }}</h3>
      </div>
      <div class="category-actions" v-if="isAdmin">
        <button @click="$emit('edit', category)" class="btn-icon" title="Chỉnh sửa">
          <i class="fas fa-edit"></i>
        </button>
        <button @click="$emit('delete', category)" class="btn-icon btn-danger" title="Xóa">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>

    <div class="category-details">
      <div class="detail-item" v-if="category.description">
        <i class="fas fa-info-circle"></i>
        <span>{{ category.description }}</span>
      </div>

      <div class="detail-item">
        <i class="fas fa-box"></i>
        <span>{{ category.product_count || 0 }} sản phẩm</span>
      </div>

      <div class="detail-item" v-if="category.created_at">
        <i class="fas fa-calendar"></i>
        <span>Tạo ngày: {{ formatDate(category.created_at) }}</span>
      </div>
    </div>

    <div class="category-footer">
      <div class="category-meta">
        <span class="category-id">
          <i class="fas fa-hashtag"></i>
          ID: {{ category.id }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CategoryCard',
  props: {
    category: {
      type: Object,
      required: true
    },
    isAdmin: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleDateString('vi-VN');
    }
  }
};
</script>

<style scoped>
.category-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  padding: 20px;
  transition: all 0.2s ease;
  border: 1px solid #e5e7eb;
}

.category-card:hover {
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
  transform: translateY(-2px);
}

.category-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.category-info {
  flex: 1;
}

.category-name {
  margin: 0 0 8px 0;
  color: #1f2937;
  font-size: 1.25rem;
  font-weight: 600;
}


.category-actions {
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

.category-details {
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

.category-footer {
  border-top: 1px solid #e5e7eb;
  padding-top: 12px;
}

.category-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.8rem;
  color: #9ca3af;
}

.category-id {
  display: flex;
  align-items: center;
  gap: 4px;
}

.category-id i {
  font-size: 0.75rem;
}
</style>
