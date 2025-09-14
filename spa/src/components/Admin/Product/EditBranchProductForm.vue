<template>
  <div class="edit-branch-product-form">
    <form @submit.prevent="handleSubmit">
      <div class="mb-3">
        <div class="d-flex align-items-center">
          <img 
            :src="product?.image || DEFAULT_AVATAR" 
            :alt="product?.name || 'Product'"
            class="img-thumbnail me-3"
            style="width: 50px; height: 50px; object-fit: cover;"
            @error="handleImageError"
          >
          <div>
            <h6 class="mb-1">{{ product?.name || 'Unknown Product' }}</h6>
            <small class="text-muted">{{ product?.category_name || 'Unknown Category' }}</small>
          </div>
        </div>
      </div>

      <div class="mb-3">
        <label class="form-label">Giá tại chi nhánh <span class="text-danger">*</span></label>
        <div class="input-group">
          <span class="input-group-text">₫</span>
          <input 
            type="number" 
            v-model="formData.price"
            class="form-control"
            :class="{ 'is-invalid': errors.price }"
            placeholder="Nhập giá"
            min="0"
            step="1000"
            required
          >
        </div>
        <div v-if="errors.price" class="invalid-feedback">
          {{ errors.price }}
        </div>
      </div>

      <div class="mb-3">
        <label class="form-label">Trạng thái</label>
        <select 
          v-model="formData.status" 
          class="form-select"
          :class="{ 'is-invalid': errors.status }"
        >
          <option value="available">Có sẵn</option>
          <option value="out_of_stock">Hết hàng</option>
          <option value="temporarily_unavailable">Tạm ngừng</option>
          <option value="discontinued">Ngừng bán</option>
        </select>
        <div v-if="errors.status" class="invalid-feedback">
          {{ errors.status }}
        </div>
      </div>

      <div class="mb-3">
        <div class="form-check form-switch">
          <input 
            class="form-check-input" 
            type="checkbox" 
            v-model="formData.is_available"
            :disabled="formData.status === 'discontinued'"
          >
          <label class="form-check-label">
            Có sẵn tại chi nhánh
          </label>
        </div>
      </div>

      <div class="mb-4">
        <label class="form-label">Ghi chú</label>
        <textarea 
          v-model="formData.notes"
          class="form-control"
          :class="{ 'is-invalid': errors.notes }"
          rows="2"
          placeholder="Ghi chú đặc biệt..."
        ></textarea>
        <div v-if="errors.notes" class="invalid-feedback">
          {{ errors.notes }}
        </div>
      </div>

      <div class="d-flex justify-content-end gap-2">
        <button 
          type="button" 
          class="btn btn-outline-secondary"
          @click="$emit('cancel')"
          :disabled="loading"
        >
          Hủy
        </button>
        <button 
          type="submit" 
          class="btn btn-primary"
          :disabled="loading || !isFormValid"
        >
          <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
          {{ loading ? 'Đang lưu...' : 'Lưu' }}
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
    errors.value.price = 'Giá phải lớn hơn 0'
  }

  if (!formData.value.status) {
    errors.value.status = 'Vui lòng chọn trạng thái'
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
    console.error('Error updating branch product:', error)
    alert('Có lỗi xảy ra: ' + error.message)
  } finally {
    loading.value = false
  }
}

const handleImageError = (event) => {
  event.target.src = DEFAULT_AVATAR
}

onMounted(() => {
  initializeForm()
})
</script>

<style scoped>
.edit-branch-product-form {
  padding: 0;
}

.img-thumbnail {
  border: 1px solid #dee2e6;
}

.form-switch .form-check-input {
  width: 2.5em;
  height: 1.25em;
}

.invalid-feedback {
  display: block;
  font-size: 0.875rem;
}

.is-invalid {
  border-color: #dc3545;
}

.input-group-text {
  background-color: #f8f9fa;
  border-color: #ced4da;
  color: #6c757d;
  font-weight: 500;
}
</style>