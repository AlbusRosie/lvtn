<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import ProductService from '@/services/ProductService'
import { DEFAULT_AVATAR } from '@/constants'
import ProductOptionsManager from './ProductOptionsManager.vue'
const emit = defineEmits(['success', 'cancel'])
const props = defineProps({
  branches: {
    type: Array,
    default: () => []
  },
  categories: {
    type: Array,
    default: () => []
  },
  selectedBranchId: {
    type: [String, Number],
    default: null
  }
})
const loading = ref(false)
const imagePreview = ref(null)
const imageInput = ref(null)
const formData = ref({
  branchType: 'multiple',
  selectedMultipleBranches: [],
  newProduct: {
    name: '',
    category_id: '',
    base_price: 0,
    description: '',
    image: null,
    options: []
  },
  branchSettings: {
    price: '',
    status: 'available',
    is_available: true,
    notes: ''
  }
})
const availableBranches = computed(() => {
  return props.branches
})
const isFormValid = computed(() => {
  if (formData.value.branchType === 'multiple' && formData.value.selectedMultipleBranches.length === 0) {
    return false
  }
  return formData.value.newProduct.name && 
         formData.value.newProduct.category_id && 
         formData.value.newProduct.base_price > 0
})
const handleImageUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    if (file.size > 5 * 1024 * 1024) {
      alert('File size must not exceed 5MB')
      return
    }
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
    if (!allowedTypes.includes(file.type)) {
      alert('Only image files are accepted (JPG, PNG, GIF, WebP)')
      return
    }
    formData.value.newProduct.image = file
    const reader = new FileReader()
    reader.onload = (e) => {
      imagePreview.value = e.target.result
    }
    reader.readAsDataURL(file)
  }
}
const removeImage = () => {
  formData.value.newProduct.image = null
  imagePreview.value = null
  if (imageInput.value) {
    imageInput.value.value = ''
  }
}
const handleSubmit = async () => {
  loading.value = true
  try {
    await createNewProduct()
    emit('success')
  } catch (error) {
    alert('An error occurred: ' + error.message)
  } finally {
    loading.value = false
  }
}
const updateProductOptions = (options) => {
  formData.value.newProduct.options = options
}
const validateProductOption = ({ index, isValid, option }) => {
}
const createNewProduct = async () => {
  const productData = new FormData()
  productData.append('name', formData.value.newProduct.name)
  productData.append('category_id', formData.value.newProduct.category_id)
  productData.append('base_price', formData.value.newProduct.base_price)
  productData.append('description', formData.value.newProduct.description)
  productData.append('is_global_available', '0')
  if (formData.value.newProduct.image) {
    productData.append('imageFile', formData.value.newProduct.image)
  }
  if (formData.value.newProduct.options.length > 0) {
    productData.append('options', JSON.stringify(formData.value.newProduct.options))
  }
  let targetBranches = []
  if (formData.value.branchType === 'multiple') {
    targetBranches = formData.value.selectedMultipleBranches
  } else {
    targetBranches = availableBranches.value.map(branch => branch.id)
  }
  productData.append('selected_branches', JSON.stringify(targetBranches))
  const newProduct = await ProductService.createProduct(productData)
  const branchProductData = {
    price: formData.value.branchSettings.price || formData.value.newProduct.base_price,
    is_available: formData.value.branchSettings.is_available ? 1 : 0,
    status: formData.value.branchSettings.status,
    notes: formData.value.branchSettings.notes || null
  }
  const promises = targetBranches.map(branchId => 
    ProductService.addProductToBranch(branchId, newProduct.id, branchProductData)
  )
  await Promise.all(promises)
  if (formData.value.newProduct.options.length > 0) {
    const optionPromises = formData.value.newProduct.options.map(option => {
      const optionData = {
        name: option.name,
        type: option.type,
        required: option.required,
        display_order: option.display_order,
        values: option.values || []
      }
      return ProductService.createProductOption(newProduct.id, optionData)
    })
    await Promise.all(optionPromises)
  }
}
onMounted(() => {
  if (props.selectedBranchId) {
    formData.value.selectedMultipleBranches = [props.selectedBranchId]
  }
})
</script>
<template>
  <div class="add-product-form">
    <form @submit.prevent="handleSubmit" @keydown.enter.prevent>
      <!-- Branch Selection Card -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-store"></i>
          <h3>Select Branch <span class="required">*</span></h3>
        </div>
        <div class="card-content">
          <div class="branch-options">
            <label class="radio-option">
              <input 
                type="radio" 
                v-model="formData.branchType"
                value="multiple"
              >
              <span>Select Multiple Branches</span>
            </label>
            <label class="radio-option">
              <input 
                type="radio" 
                v-model="formData.branchType"
                value="all"
              >
              <span>Add to All Branches</span>
            </label>
          </div>
          <div v-if="formData.branchType === 'multiple'" class="multiple-branches">
            <div class="branches-list">
              <div 
                v-for="branch in availableBranches" 
                :key="branch.id"
                class="branch-item"
              >
                <label class="checkbox-label">
                  <input 
                    type="checkbox" 
                    :value="branch.id"
                    v-model="formData.selectedMultipleBranches"
                  >
                  <span>{{ branch.name }}</span>
                </label>
              </div>
            </div>
            <div v-if="formData.selectedMultipleBranches.length > 0" class="selected-info">
              <i class="fas fa-check-circle"></i>
              <span>Selected {{ formData.selectedMultipleBranches.length }} branch(es)</span>
            </div>
          </div>
          <div v-if="formData.branchType === 'all'" class="all-branches-info">
            <i class="fas fa-info-circle"></i>
            <span>Product will be added to {{ availableBranches.length }} branch(es)</span>
          </div>
        </div>
      </div>
      <!-- Product Basic Info Card -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-box"></i>
          <h3>Product Information</h3>
        </div>
        <div class="card-content">
          <div class="form-row">
            <div class="form-group">
              <label>
                <i class="fas fa-tag"></i>
                Product Name <span class="required">*</span>
              </label>
              <input 
                type="text" 
                v-model="formData.newProduct.name"
                class="form-control"
                placeholder="Enter product name"
                required
              >
            </div>
            <div class="form-group">
              <label>
                <i class="fas fa-folder"></i>
                Category <span class="required">*</span>
              </label>
              <select v-model="formData.newProduct.category_id" class="form-control" required>
                <option value="">Select Category</option>
                <option v-for="category in categories" :key="category.id" :value="category.id">
                  {{ category.name }}
                </option>
              </select>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>
                <i class="fas fa-dollar-sign"></i>
                Base Price <span class="required">*</span>
              </label>
              <input 
                type="number" 
                v-model="formData.newProduct.base_price"
                class="form-control"
                placeholder="0"
                min="0"
                step="1000"
                required
              >
            </div>
            <div class="form-group">
              <label for="productImage">
                <i class="fas fa-image"></i>
                Image
              </label>
              <div class="image-upload-container">
                <input
                  id="productImage"
                  ref="imageInput"
                  type="file"
                  accept="image/*"
                  @change="handleImageUpload"
                  class="image-input"
                />
                <div class="image-preview" v-if="imagePreview">
                  <img :src="imagePreview" alt="Preview" />
                  <button type="button" @click="removeImage" class="remove-image-btn">
                    <i class="fas fa-times"></i>
                  </button>
                </div>
                <div class="image-placeholder" v-else>
                  <i class="fas fa-image"></i>
                  <span>Chọn ảnh sản phẩm</span>
                </div>
              </div>
              <div class="image-info">
                <i class="fas fa-info-circle"></i>
                <small>Định dạng: JPG, PNG, GIF, WebP. Kích thước tối đa: 5MB</small>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Product Options Section -->
      <ProductOptionsManager 
        :options="formData.newProduct.options" 
        :loading="loading"
        @update:options="updateProductOptions"
      />
      <div class="form-actions">
        <button type="button" @click="$emit('cancel')" class="btn btn-cancel">
          Cancel
        </button>
        <button type="submit" class="btn btn-submit" :disabled="!isFormValid || loading">
          {{ loading ? 'Creating...' : 'Create Product' }}
        </button>
      </div>
    </form>
  </div>
</template>
<style scoped>
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
.card-header .required {
  color: #EF4444;
  font-weight: 700;
  margin-left: 4px;
}
.card-content {
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
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
.branch-options {
  display: flex;
  gap: 16px;
  padding: 12px;
  background: #FFF9F5;
  border: 2px solid #F0E6D9;
  border-radius: 10px;
}
.radio-option {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: #1a1a1a;
}
.radio-option input[type='radio'] {
  margin: 0;
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #FF8C42;
}
.all-branches-info {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 16px;
  background: #ECFDF5;
  border: 2px solid #D1FAE5;
  border-radius: 10px;
  color: #065F46;
  font-size: 13px;
  font-weight: 500;
}
.all-branches-info i {
  font-size: 16px;
  color: #10B981;
}
.multiple-branches {
  border: 2px solid #F0E6D9;
  border-radius: 12px;
  padding: 16px;
  background: #FFF9F5;
}
.branches-list {
  max-height: 240px;
  overflow-y: auto;
  margin-bottom: 12px;
  padding: 4px;
}
.branches-list::-webkit-scrollbar {
  width: 6px;
}
.branches-list::-webkit-scrollbar-track {
  background: #F5F5F5;
  border-radius: 3px;
}
.branches-list::-webkit-scrollbar-thumb {
  background: #D1D5DB;
  border-radius: 3px;
}
.branches-list::-webkit-scrollbar-thumb:hover {
  background: #9CA3AF;
}
.branch-item {
  padding: 12px;
  border-bottom: 1px solid #F0E6D9;
  background: white;
  border-radius: 8px;
  margin-bottom: 8px;
}
.branch-item:last-child {
  margin-bottom: 0;
}
.branch-item .checkbox-label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-weight: 500;
  font-size: 14px;
  color: #1a1a1a;
}
.branch-item .checkbox-label input[type='checkbox'] {
  margin: 0;
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #FF8C42;
}
.selected-info {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  background: #D1FAE5;
  border: 2px solid #A7F3D0;
  border-radius: 10px;
  color: #065F46;
  font-size: 13px;
  font-weight: 600;
}
.selected-info i {
  font-size: 16px;
  color: #10B981;
}
.form-row {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
.checkbox-label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: #1a1a1a;
}
.checkbox-label input[type='checkbox'] {
  margin: 0;
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #FF8C42;
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
.btn-cancel:hover {
  background: #F9FAFB;
  border-color: #D1D5DB;
  color: #4B5563;
}
.btn-submit {
  background: white;
  color: #10B981;
  border-color: #10B981;
}
.btn-submit:hover:not(:disabled) {
  background: #ECFDF5;
  border-color: #059669;
  color: #059669;
}
.btn-submit:disabled {
  background: #F3F4F6;
  border-color: #D1D5DB;
  color: #9CA3AF;
  cursor: not-allowed;
  opacity: 0.6;
}
.image-upload-container {
  position: relative;
  border: 2px dashed #E5E5E5;
  border-radius: 12px;
  padding: 24px;
  text-align: center;
  transition: all 0.2s ease;
  cursor: pointer;
  background: #FAFAFA;
}
.image-upload-container:hover {
  border-color: #FF8C42;
  background: #FFF9F5;
}
.image-input {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}
.image-preview {
  position: relative;
  display: inline-block;
}
.image-preview img {
  max-width: 240px;
  max-height: 240px;
  border-radius: 12px;
  border: 2px solid #F0E6D9;
}
.remove-image-btn {
  position: absolute;
  top: -8px;
  right: -8px;
  background: #EF4444;
  color: white;
  border: 2px solid white;
  border-radius: 50%;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}
.remove-image-btn:hover {
  background: #DC2626;
  transform: scale(1.1);
}
.image-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  color: #9CA3AF;
}
.image-placeholder i {
  font-size: 48px;
  color: #D1D5DB;
}
.image-placeholder span {
  font-size: 14px;
  font-weight: 500;
}
.image-info {
  margin-top: 12px;
  color: #6B7280;
  font-size: 12px;
  text-align: center;
}
</style>