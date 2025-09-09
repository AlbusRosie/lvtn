<template>
  <div class="product-card">
    <div class="card h-100 shadow-sm">
      <div class="card-img-top-container">
        <img
          :src="product.image || '/public/images/blank-profile-picture.png'"
          class="card-img-top"
          :alt="product.name"
          style="height: 200px; object-fit: cover;"
        />
        <div class="availability-badge">
          <span class="badge" :class="getStatusBadgeClass()">
            {{ getStatusLabel() }}
          </span>
        </div>
      </div>
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-start mb-2">
          <h5 class="card-title mb-0 text-truncate" :title="product.name">
            {{ product.name }}
          </h5>
          <span class="badge" :class="getStockBadgeClass()">
            {{ product.stock }} món
          </span>
        </div>

        <div class="product-info mb-3">
          <div class="row">
            <div class="col-6">
              <small class="text-muted">Giá:</small>
              <div class="fw-bold text-primary">
                {{ formatPrice(product.price) }} VNĐ
              </div>
            </div>
            <div class="col-6">
              <small class="text-muted">Danh mục:</small>
              <div class="fw-bold">{{ product.category_name }}</div>
            </div>
          </div>

          <div class="row mt-2">
            <div class="col-6">
              <small class="text-muted">Trạng thái:</small>
              <div class="fw-bold">
                <span class="badge" :class="getStatusBadgeClass()">
                  {{ getStatusLabel() }}
                </span>
              </div>
            </div>
            <div class="col-6">
              <small class="text-muted">Ngày tạo:</small>
              <div class="fw-bold">{{ formatDate(product.created_at) }}</div>
            </div>
          </div>
        </div>

        <div class="product-description mb-3">
          <small class="text-muted">Mô tả:</small>
          <p class="card-text small mb-0" :title="product.description">
            {{ truncateDescription(product.description) }}
          </p>
        </div>

        <div class="product-actions">
          <div class="btn-group w-100" role="group">
            <button
              @click="$emit('view', product)"
              class="btn btn-outline-primary btn-sm"
              title="Xem chi tiết"
            >
              <i class="bi bi-eye"></i> Xem
            </button>
            <button
              @click="$emit('edit', product)"
              class="btn btn-outline-warning btn-sm"
              title="Chỉnh sửa"
            >
              <i class="bi bi-pencil"></i> Sửa
            </button>
            <button
              @click="$emit('delete', product)"
              class="btn btn-outline-danger btn-sm"
              title="Xóa món ăn"
            >
              <i class="bi bi-trash"></i> Xóa
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  product: {
    type: Object,
    required: true
  }
});

const emit = defineEmits(['view', 'edit', 'delete']);

const formatPrice = (price) => {
  return new Intl.NumberFormat('vi-VN').format(price);
};

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('vi-VN');
};

const truncateDescription = (description) => {
  if (!description) return 'Chưa có mô tả';
  return description.length > 100
    ? description.substring(0, 100) + '...'
    : description;
};

const getStockBadgeClass = () => {
  const stock = props.product.stock;
  if (stock === 0) return 'bg-danger';
  if (stock <= 5) return 'bg-warning';
  return 'bg-success';
};

const getStatusLabel = () => {
  switch (props.product.status) {
    case 'inactive':
      return 'Không hoạt động';
    case 'out_of_stock':
      return 'Hết hàng';
    case 'active':
      return props.product.is_available ? 'Có sẵn' : 'Không có sẵn';
    default:
      return 'Không xác định';
  }
};

const getStatusBadgeClass = () => {
  switch (props.product.status) {
    case 'inactive':
      return 'bg-secondary';
    case 'out_of_stock':
      return 'bg-danger';
    case 'active':
      return props.product.is_available ? 'bg-success' : 'bg-warning';
    default:
      return 'bg-secondary';
  }
};
</script>

<style scoped>
.product-card {
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.product-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.1) !important;
}

.card-img-top-container {
  position: relative;
}

.availability-badge {
  position: absolute;
  top: 10px;
  right: 10px;
}

.card-title {
  font-size: 1.1rem;
  line-height: 1.3;
}

.product-info {
  font-size: 0.9rem;
}

.product-description {
  max-height: 60px;
  overflow: hidden;
}

.btn-group .btn {
  font-size: 0.8rem;
}

.badge {
  font-size: 0.7rem;
}
</style>