<template>
  <div class="edit-branch-product-form">
    <form @submit.prevent="handleSubmit">
      <!-- Product Info Grid -->
      <div class="product-info-grid">
        <!-- Product Info Card -->
        <div class="info-card">
          <div class="card-header">
            <i class="fas fa-box"></i>
            <h3>Product Information</h3>
          </div>
          <div class="card-content">
            <div class="product-info-header">
              <img 
                :src="product?.image || DEFAULT_AVATAR" 
                :alt="product?.name || 'Product'"
                class="product-image"
                @error="handleImageError"
              >
              <div class="product-info">
                <div class="info-item">
                  <span class="info-label">Product Name</span>
                  <span class="info-value">{{ product?.name || 'N/A' }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Category</span>
                  <span class="info-value">{{ product?.category_name || 'N/A' }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Base Price</span>
                  <span class="info-value price">{{ formatPrice(product?.base_price || 0) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
        <!-- Branch Info Card -->
        <div class="info-card">
          <div class="card-header">
            <i class="fas fa-store"></i>
            <h3>Branch Information</h3>
          </div>
          <div class="card-content">
            <div class="info-item">
              <span class="info-label">Branch</span>
              <span class="info-value">{{ branch?.name || 'N/A' }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">Current Status</span>
              <span class="info-value">
                <span class="status-badge" :class="getStatusBadgeClass(product?.branch_status || product?.final_status || 'available')">
                  {{ getStatusText(product?.branch_status || product?.final_status || 'available') }}
                </span>
              </span>
            </div>
          </div>
        </div>
      </div>
      <!-- Price and Status Card -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-edit"></i>
          <h3>Edit Information</h3>
        </div>
        <div class="card-content">
          <div class="form-row">
            <div class="form-group">
              <label>
                <i class="fas fa-dollar-sign"></i>
                Branch Price <span class="required">*</span>
              </label>
              <div class="input-with-prefix">
                <span class="input-prefix">₫</span>
                <input 
                  type="number" 
                  v-model="formData.price"
                  class="form-control"
                  :class="{ 'is-invalid': errors.price }"
                  placeholder="Enter price"
                  min="0"
                  step="1000"
                  required
                >
              </div>
              <div v-if="errors.price" class="error-message">
                <i class="fas fa-exclamation-circle"></i>
                {{ errors.price }}
              </div>
            </div>
            <div class="form-group">
              <label>
                <i class="fas fa-info-circle"></i>
                Status
              </label>
              <select 
                v-model="formData.status" 
                class="form-control"
                :class="{ 'is-invalid': errors.status }"
              >
                <option value="available">Available</option>
                <option value="out_of_stock">Out of Stock</option>
                <option value="temporarily_unavailable">Temporarily Unavailable</option>
              </select>
              <div v-if="errors.status" class="error-message">
                <i class="fas fa-exclamation-circle"></i>
                {{ errors.status }}
              </div>
            </div>
          </div>
          <div class="form-group">
            <label class="checkbox-label">
              <input 
                type="checkbox" 
                v-model="formData.is_available"
                class="checkbox-input"
              >
              <span>
                <i class="fas fa-check-circle"></i>
                Available at Branch
              </span>
            </label>
          </div>
        </div>
      </div>
      <!-- Notes Card -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-sticky-note"></i>
          <h3>Notes</h3>
        </div>
        <div class="card-content">
          <div class="form-group">
            <textarea 
              v-model="formData.notes"
              class="form-control"
              :class="{ 'is-invalid': errors.notes }"
              rows="3"
              placeholder="Special notes for this branch..."
            ></textarea>
            <div v-if="errors.notes" class="error-message">
              <i class="fas fa-exclamation-circle"></i>
              {{ errors.notes }}
            </div>
          </div>
        </div>
      </div>
      <!-- Form Actions -->
      <div class="form-actions">
        <button 
          type="button" 
          class="btn btn-cancel"
          @click="$emit('cancel')"
          :disabled="loading"
        >
          Cancel
        </button>
        <button 
          type="submit" 
          class="btn btn-submit"
          :disabled="loading || !isFormValid"
        >
          <i v-if="loading" class="fas fa-spinner fa-spin"></i>
          <i v-else class="fas fa-save"></i>
          {{ loading ? 'Saving...' : 'Save' }}
        </button>
      </div>
    </form>
  </div>
</template>
<script setup>
import { ref, computed, onMounted } from 'vue'
import ProductService from '@/services/ProductService'
import { DEFAULT_AVATAR } from '@/constants'
const emit = defineEmits(['success', 'cancel'])
const props = defineProps({
  product: {
    type: Object,
    required: true
  },
  branch: {
    type: Object,
    required: true
  }
})
const loading = ref(false)
const errors = ref({})
const formData = ref({
  price: 0,
  status: 'available',
  is_available: true,
  notes: ''
})
const isFormValid = computed(() => {
  return formData.value.price > 0 && 
         formData.value.status && 
         Object.keys(errors.value).length === 0
})
const initializeForm = () => {
  if (props.product?.branch_price) {
    formData.value.price = props.product.branch_price
  } else {
    formData.value.price = props.product?.base_price || 0
  }
  formData.value.status = props.product?.branch_status || 'available'
  formData.value.is_available = props.product?.branch_available !== 0
  formData.value.notes = props.product?.branch_notes || ''
}
const validateForm = () => {
  errors.value = {}
  if (!formData.value.price || formData.value.price <= 0) {
    errors.value.price = 'Price must be greater than 0'
  }
  if (!formData.value.status) {
    errors.value.status = 'Please select status'
  }
  return Object.keys(errors.value).length === 0
}
const handleSubmit = async () => {
  if (!validateForm()) {
    return
  }
  loading.value = true
  try {
    const updateData = {
      price: formData.value.price,
      status: formData.value.status,
      is_available: formData.value.is_available ? 1 : 0,
      notes: formData.value.notes || null
    }
    await ProductService.updateBranchProduct(props.product?.branch_product_id, updateData)
    emit('success')
  } catch (error) {
    alert('An error occurred: ' + error.message)
  } finally {
    loading.value = false
  }
}
const handleImageError = (event) => {
  event.target.src = DEFAULT_AVATAR
}
const formatPrice = (price) => {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(price)
}
const getStatusText = (status) => {
  const statusMap = {
    'available': 'Available',
    'out_of_stock': 'Out of Stock',
    'temporarily_unavailable': 'Temporarily Unavailable',
    'not_added': 'Not Added'
  }
  return statusMap[status] || status
}
const getStatusBadgeClass = (status) => {
  const classMap = {
    'available': 'status-available',
    'out_of_stock': 'status-out-of-stock',
    'temporarily_unavailable': 'status-unavailable',
    'not_added': 'status-not-added'
  }
  return classMap[status] || ''
}
onMounted(() => {
  initializeForm()
})
</script>
<style scoped>
.edit-branch-product-form {
  padding: 0;
}
.product-info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 16px;
  margin-bottom: 16px;
}
.info-card {
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  overflow: hidden;
  margin-bottom: 16px;
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
.product-info-header {
  display: flex;
  align-items: flex-start;
  gap: 16px;
}
.product-image {
  width: 64px;
  height: 64px;
  border-radius: 10px;
  object-fit: cover;
  border: 2px solid #E2E8F0;
  flex-shrink: 0;
}
.product-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
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
.info-item .info-value.price {
  color: #F59E0B;
  font-size: 14px;
}
.status-badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}
.status-available {
  background: #D1FAE5;
  color: #059669;
}
.status-out-of-stock {
  background: #FEE2E2;
  color: #DC2626;
}
.status-unavailable {
  background: #FEF3C7;
  color: #D97706;
}
.status-not-added {
  background: #E5E7EB;
  color: #6B7280;
}
.form-row {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
.form-group {
  margin-bottom: 0;
}
.card-content .form-group:not(:last-child) {
  margin-bottom: 16px;
}
.form-group label {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
}
.form-group label i {
  color: #FF8C42;
  font-size: 12px;
}
.required {
  color: #EF4444;
  font-weight: 700;
}
.form-control {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  font-size: 14px;
  background: white;
  color: #1a1a1a;
  font-weight: 500;
  transition: all 0.2s ease;
}
.form-control:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
  background: white;
}
.form-control::placeholder {
  color: #9CA3AF;
  font-weight: 400;
}
.form-control.is-invalid {
  border-color: #EF4444;
}
.form-control.is-invalid:focus {
  border-color: #EF4444;
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1);
}
.input-with-prefix {
  position: relative;
  display: flex;
  align-items: center;
}
.input-prefix {
  position: absolute;
  left: 16px;
  font-size: 14px;
  font-weight: 600;
  color: #6B7280;
  z-index: 1;
}
.input-with-prefix .form-control {
  padding-left: 40px;
}
.error-message {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 6px;
  font-size: 12px;
  color: #EF4444;
  font-weight: 500;
}
.error-message i {
  font-size: 12px;
}
.checkbox-label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: #1a1a1a;
  margin-bottom: 0;
}
.checkbox-input {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #FF8C42;
}
.checkbox-label span {
  display: flex;
  align-items: center;
  gap: 8px;
}
.checkbox-label span i {
  color: #10B981;
  font-size: 14px;
}
.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 32px;
  padding-top: 24px;
  border-top: 2px solid #F0E6D9;
}
.btn {
  padding: 12px 24px;
  border: 2px solid;
  border-radius: 10px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-cancel {
  background: white;
  color: #6B7280;
  border-color: #E5E7EB;
}
.btn-cancel:hover:not(:disabled) {
  background: #F9FAFB;
  border-color: #D1D5DB;
  color: #4B5563;
}
.btn-submit {
  background: white;
  color: #F59E0B;
  border-color: #F59E0B;
}
.btn-submit:hover:not(:disabled) {
  background: #FFFBEB;
  border-color: #D97706;
  color: #D97706;
}
.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>