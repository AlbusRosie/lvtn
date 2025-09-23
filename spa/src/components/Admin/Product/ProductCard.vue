<template>
  <div class="product-card" :class="{ 'selected': isSelected }">
    <div class="card">
      
      <div class="card-header">
        <div class="header-top">
          <input 
            type="checkbox" 
            :id="`product-${product.id}`"
            v-model="isSelected"
            @change="onSelectionChange"
          >
          <label :for="`product-${product.id}`">
            {{ product.name }}
          </label>
          <div class="status-indicator" v-if="product.final_status === 'available'"></div>
        </div>
        <div class="product-actions">
          <button 
            v-if="!product.branch_product_id"
            @click="$emit('add-to-branch', product)"
            :disabled="loading"
            title="Thêm vào chi nhánh"
            class="btn-add"
          >
            Thêm
          </button>
          <button 
            v-else
            @click="$emit('edit', product)"
            title="Chỉnh sửa"
            class="btn-edit"
          >
            Sửa
          </button>
          <button 
            v-if="product.branch_product_id"
            @click="$emit('remove', product)"
            :disabled="loading"
            title="Xóa khỏi chi nhánh"
            class="btn-remove"
          >
            Xóa
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
          <div class="status-badge">
            {{ getStatusText(product.final_status) }}
          </div>
        </div>

        
        <div class="product-info">
          <p class="product-description">{{ product.description || 'Không có mô tả' }}</p>
          <div class="product-category">
            {{ product.category_name }}
          </div>
        </div>

        
        <div class="price-section">
          <div class="price-row">
            <span>Giá cơ bản: {{ formatPrice(product.base_price) }}</span>
          </div>
          
          <div v-if="product.branch_product_id" class="price-row">
            <input 
              type="number" 
              v-model="product.branch_price"
              @blur="updateBranchPrice"
              :disabled="loading"
              min="0"
              step="1000"
              placeholder="Giá chi nhánh"
            >
          </div>
          <div v-else class="price-row">
            <span>Chưa thêm vào chi nhánh</span>
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
  margin-bottom: 1rem;
}

.product-card.selected .card {
  border-color: #007bff;
}

.card {
  border-radius: 8px;
  border: 1px solid #ddd;
  height: 100%;
}

.card-header {
  background: #f8f9fa;
  border-bottom: 1px solid #ddd;
  padding: 12px;
}

.card-body {
  padding: 12px;
}

.product-image-container {
  position: relative;
  text-align: center;
  margin-bottom: 12px;
}

.product-image {
  width: 100%;
  height: 120px;
  object-fit: cover;
  border-radius: 4px;
  border: 1px solid #ddd;
}

.status-badge {
  position: absolute;
  top: 8px;
  right: 8px;
  background: white;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  border: 1px solid #ddd;
}

.product-info {
  margin-bottom: 12px;
}

.product-description {
  color: #666;
  font-size: 14px;
  margin-bottom: 8px;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.product-category {
  font-size: 12px;
  color: #999;
  margin-bottom: 8px;
}

.price-section {
  background-color: #f8f9fa;
  border-radius: 4px;
  padding: 8px;
  margin-bottom: 12px;
}

.price-row {
  margin-bottom: 4px;
  font-size: 14px;
}

.price-row:last-child {
  margin-bottom: 0;
}

.price-row input {
  width: 100%;
  padding: 4px 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.header-top {
  display: flex;
  align-items: center;
  gap: 8px;
}

.header-top input {
  margin: 0;
}

.header-top label {
  flex: 1;
  font-weight: bold;
  font-size: 14px;
  margin: 0;
  cursor: pointer;
}

.status-indicator {
  width: 8px;
  height: 8px;
  background: #28a745;
  border-radius: 50%;
}

.product-actions {
  display: flex;
  gap: 4px;
}

.product-actions button {
  padding: 4px 8px;
  border: 1px solid #ddd;
  background: white;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.2s ease;
}

.product-actions button:hover {
  background: #f5f5f5;
}

.btn-add {
  background: #28a745;
  color: white;
  border-color: #28a745;
}

.btn-add:hover {
  background: #218838;
}

.btn-edit {
  background: #ffc107;
  color: #212529;
  border-color: #ffc107;
}

.btn-edit:hover {
  background: #e0a800;
}

.btn-remove {
  background: #dc3545;
  color: white;
  border-color: #dc3545;
}

.btn-remove:hover {
  background: #c82333;
}

/* Responsive Design */
@media (max-width: 768px) {
  .product-image {
    height: 100px;
  }
  
  .card-header {
    padding: 8px;
  }
  
  .card-body {
    padding: 8px;
  }
}
</style>
