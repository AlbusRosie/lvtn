<template>
  <div class="product-card" :class="{ 'selected': isSelected }">
    <div class="card">
      
      <div class="card-header d-flex justify-content-between align-items-center">
        <div class="form-check">
          <input 
            type="checkbox" 
            :id="`product-${product.id}`"
            v-model="isSelected"
            @change="onSelectionChange"
            class="form-check-input"
          >
          <label :for="`product-${product.id}`" class="form-check-label">
            <strong>{{ product.name }}</strong>
          </label>
        </div>
        <div class="product-actions">
          <button 
            v-if="!product.branch_product_id"
            class="btn btn-success btn-sm"
            @click="$emit('add-to-branch', product)"
            :disabled="loading"
            title="Thêm vào chi nhánh"
          >
            <i class="bi bi-plus"></i>
          </button>
          <button 
            v-else
            class="btn btn-warning btn-sm me-1"
            @click="$emit('edit', product)"
            title="Chỉnh sửa"
          >
            <i class="bi bi-pencil"></i>
          </button>
          <button 
            v-if="product.branch_product_id"
            class="btn btn-danger btn-sm"
            @click="$emit('remove', product)"
            :disabled="loading"
            title="Xóa khỏi chi nhánh"
          >
            <i class="bi bi-trash"></i>
          </button>
        </div>
      </div>

      <div class="card-body">
        
        <div class="product-image-container">
          <img 
            :src="product.image || DEFAULT_PRODUCT_IMAGE" 
            :alt="product.name"
            class="product-image"
            @error="handleImageError"
          >
          <div class="product-status-badge">
            <span 
              class="badge"
              :class="getStatusBadgeClass(product.final_status)"
            >
              {{ getStatusText(product.final_status) }}
            </span>
          </div>
        </div>

        
        <div class="product-info">
          <h6 class="product-name">{{ product.name }}</h6>
          <p class="product-description">{{ product.description || 'Không có mô tả' }}</p>
          
          <div class="product-category">
            <span class="badge bg-secondary">{{ product.category_name }}</span>
          </div>
        </div>

        
        <div class="price-section">
          <div class="price-row">
            <label class="price-label">Giá cơ bản:</label>
            <span class="base-price">{{ formatPrice(product.base_price) }}</span>
          </div>
          
          <div v-if="product.branch_product_id" class="price-row">
            <label class="price-label">Giá chi nhánh:</label>
            <div class="branch-price-input">
              <input 
                type="number" 
                v-model="product.branch_price"
                class="form-control form-control-sm"
                @blur="updateBranchPrice"
                :disabled="loading"
                min="0"
                step="1000"
              >
              <small class="price-display">{{ formatPrice(product.branch_price) }}</small>
            </div>
          </div>
          <div v-else class="price-row">
            <span class="text-muted">Chưa thêm vào chi nhánh</span>
          </div>
        </div>

        
        <div v-if="product.branch_product_id" class="branch-details">
          <div class="detail-row">
            <i class="bi bi-calendar"></i>
            <span>Thêm ngày: {{ formatDate(product.added_to_branch_at) }}</span>
          </div>
          <div v-if="product.branch_notes" class="detail-row">
            <i class="bi bi-chat-text"></i>
            <span>{{ product.branch_notes }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { DEFAULT_AVATAR, DEFAULT_PRODUCT_IMAGE } from '@/constants'

const props = defineProps({
  product: {
    type: Object,
    required: true
  },
  loading: {
    type: Boolean,
    default: false
  },
  selected: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['select', 'add-to-branch', 'edit', 'remove', 'update-price'])

const isSelected = ref(props.selected)

const onSelectionChange = () => {
  emit('select', props.product.id, isSelected.value)
}

const updateBranchPrice = async () => {
  emit('update-price', props.product)
}

const formatPrice = (price) => {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(price)
}

const formatDate = (date) => {
  return new Intl.DateTimeFormat('vi-VN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).format(new Date(date))
}

const getStatusBadgeClass = (status) => {
  const classes = {
    'available': 'bg-success',
    'out_of_stock': 'bg-danger',
    'temporarily_unavailable': 'bg-warning',
    'discontinued': 'bg-secondary',
    'not_added': 'bg-light text-dark'
  }
  return classes[status] || 'bg-secondary'
}

const getStatusText = (status) => {
  const texts = {
    'available': 'Có sẵn',
    'out_of_stock': 'Hết hàng',
    'temporarily_unavailable': 'Tạm ngừng',
    'discontinued': 'Ngừng bán',
    'not_added': 'Chưa thêm'
  }
  return texts[status] || status
}

const handleImageError = (event) => {
  event.target.src = DEFAULT_PRODUCT_IMAGE
}
</script>

<style scoped>
.product-card {
  transition: all 0.3s ease;
  margin-bottom: 1rem;
}

.product-card:hover {
  transform: translateY(-2px);
}

.product-card.selected .card {
  border-color: #007bff;
  box-shadow: 0 4px 15px rgba(0, 123, 255, 0.3);
}

.card {
  border-radius: 12px;
  border: 2px solid #e9ecef;
  transition: all 0.3s ease;
  height: 100%;
}

.card-header {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-bottom: 1px solid #dee2e6;
  padding: 0.75rem 1rem;
}

.card-body {
  padding: 1rem;
}

.product-image-container {
  position: relative;
  text-align: center;
  margin-bottom: 1rem;
}

.product-image {
  width: 100%;
  height: 150px;
  object-fit: cover;
  border-radius: 8px;
  border: 2px solid #e9ecef;
  transition: all 0.3s ease;
}

.product-image:hover {
  border-color: #007bff;
  transform: scale(1.02);
}

.product-status-badge {
  position: absolute;
  top: 8px;
  right: 8px;
}

.product-info {
  margin-bottom: 1rem;
}

.product-name {
  font-weight: 600;
  color: #212529;
  margin-bottom: 0.5rem;
  line-height: 1.3;
}

.product-description {
  color: #6c757d;
  font-size: 0.875rem;
  margin-bottom: 0.75rem;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.product-category {
  margin-bottom: 0.5rem;
}

.price-section {
  background-color: #f8f9fa;
  border-radius: 8px;
  padding: 0.75rem;
  margin-bottom: 1rem;
}

.price-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.price-row:last-child {
  margin-bottom: 0;
}

.price-label {
  font-weight: 500;
  color: #495057;
  font-size: 0.875rem;
  margin: 0;
}

.base-price {
  font-weight: 600;
  color: #6c757d;
  font-size: 0.875rem;
}

.branch-price-input {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.25rem;
}

.branch-price-input .form-control {
  width: 120px;
  text-align: right;
}

.price-display {
  color: #28a745;
  font-weight: 600;
  font-size: 0.75rem;
}

.branch-details {
  border-top: 1px solid #e9ecef;
  padding-top: 0.75rem;
}

.detail-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.75rem;
  color: #6c757d;
  margin-bottom: 0.25rem;
}

.detail-row:last-child {
  margin-bottom: 0;
}

.detail-row i {
  width: 12px;
  text-align: center;
}

.product-actions {
  display: flex;
  gap: 0.25rem;
}

.btn-sm {
  padding: 0.25rem 0.5rem;
  font-size: 0.75rem;
  border-radius: 6px;
}

.badge {
  font-size: 0.65rem;
  padding: 0.35em 0.65em;
  border-radius: 6px;
  font-weight: 500;
}

.form-check-input {
  margin-top: 0.125rem;
}

.form-check-label {
  cursor: pointer;
  font-size: 0.875rem;
  margin-bottom: 0;
}

/* Responsive Design */
@media (max-width: 768px) {
  .product-image {
    height: 120px;
  }
  
  .price-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.25rem;
  }
  
  .branch-price-input {
    align-items: flex-start;
  }
  
  .branch-price-input .form-control {
    width: 100px;
  }
}

/* Animation */
.product-card {
  animation: fadeInUp 0.3s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
