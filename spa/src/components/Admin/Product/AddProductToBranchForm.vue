<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import ProductService from '@/services/ProductService'
import { DEFAULT_AVATAR } from '@/constants'

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
    image: null
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
      alert('Kích thước file không được vượt quá 5MB')
      return
    }

    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
    if (!allowedTypes.includes(file.type)) {
      alert('Chỉ chấp nhận file ảnh (JPG, PNG, GIF, WebP)')
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
    console.error('Error adding product:', error)
    alert('Có lỗi xảy ra: ' + error.message)
  } finally {
    loading.value = false
  }
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
      <div class="form-group">
        <label>Chi nhánh *</label>
        <div class="branch-options">
          <label class="radio-option">
            <input 
              type="radio" 
              v-model="formData.branchType"
              value="multiple"
            >
            <span>Chọn nhiều chi nhánh</span>
          </label>
          <label class="radio-option">
            <input 
              type="radio" 
              v-model="formData.branchType"
              value="all"
            >
            <span>Thêm vào tất cả chi nhánh</span>
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
            <i class="bi bi-check-circle"></i>
            <span>Đã chọn {{ formData.selectedMultipleBranches.length }} chi nhánh</span>
          </div>
        </div>
        
        <div v-if="formData.branchType === 'all'" class="all-branches-info">
          <i class="bi bi-info-circle"></i>
          <span>Sản phẩm sẽ được thêm vào {{ availableBranches.length }} chi nhánh</span>
        </div>
      </div>

      <div class="form-group">
        <div class="form-row">
          <div class="form-col">
            <label>Tên sản phẩm *</label>
            <input 
              type="text" 
              v-model="formData.newProduct.name"
              class="form-control"
              placeholder="Nhập tên sản phẩm"
              required
            >
          </div>
          <div class="form-col">
            <label>Danh mục *</label>
            <select v-model="formData.newProduct.category_id" class="form-control" required>
              <option value="">Chọn danh mục</option>
              <option v-for="category in categories" :key="category.id" :value="category.id">
                {{ category.name }}
              </option>
            </select>
          </div>
        </div>
        
        <div class="form-row">
          <div class="form-col">
            <label>Giá cơ bản *</label>
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
          <div class="form-col">
            <label for="productImage">Hình ảnh</label>
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
              <small>Định dạng: JPG, PNG, GIF, WebP. Kích thước tối đa: 5MB</small>
            </div>
          </div>
        </div>
        
        <div class="form-group">
          <label>Mô tả</label>
          <textarea 
            v-model="formData.newProduct.description"
            class="form-control"
            rows="3"
            placeholder="Mô tả sản phẩm"
          ></textarea>
        </div>
      </div>

      <div class="form-group">
        <label>Cài đặt cho chi nhánh</label>
        <div class="form-row">
          <div class="form-col">
            <label>Giá tại chi nhánh</label>
            <input 
              type="number" 
              v-model="formData.branchSettings.price"
              class="form-control"
              placeholder="Tự động lấy giá cơ bản"
              min="0"
              step="1000"
            >
          </div>
          <div class="form-col">
            <label>Trạng thái</label>
            <select v-model="formData.branchSettings.status" class="form-control">
              <option value="available">Có sẵn</option>
              <option value="temporarily_unavailable">Tạm ngừng</option>
              <option value="out_of_stock">Hết hàng</option>
            </select>
          </div>
        </div>
        
        <div class="form-group">
          <label class="checkbox-label">
            <input 
              type="checkbox" 
              v-model="formData.branchSettings.is_available"
            >
            <span>Có sẵn tại chi nhánh</span>
          </label>
        </div>
        
        <div class="form-group">
          <label>Ghi chú</label>
          <textarea 
            v-model="formData.branchSettings.notes"
            class="form-control"
            rows="2"
            placeholder="Ghi chú đặc biệt cho chi nhánh này"
          ></textarea>
        </div>
      </div>

      <div class="form-actions">
        <button 
          type="button" 
          class="btn btn-cancel"
          @click="$emit('cancel')"
        >
          Hủy
        </button>
        <button 
          type="submit" 
          class="btn btn-submit"
          :disabled="loading || !isFormValid"
        >
          {{ loading ? 'Đang xử lý...' : 'Thêm sản phẩm' }}
        </button>
      </div>
    </form>
  </div>
</template>
<style scoped>
.add-product-form {
  padding: 0;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: 500;
  color: #333;
}

.form-control {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.form-control:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.branch-options {
  display: flex;
  gap: 20px;
  margin-bottom: 15px;
}

.radio-option {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.radio-option input[type="radio"] {
  margin: 0;
}

.all-branches-info {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px;
  background: #e3f2fd;
  border: 1px solid #bbdefb;
  border-radius: 4px;
  color: #1976d2;
  font-size: 14px;
}

.all-branches-info i {
  font-size: 16px;
}

.multiple-branches {
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 15px;
  background: #f9f9f9;
}

.branches-list {
  max-height: 200px;
  overflow-y: auto;
  margin-bottom: 15px;
}

.branch-item {
  padding: 8px 0;
  border-bottom: 1px solid #eee;
}

.branch-item:last-child {
  border-bottom: none;
}

.branch-item .checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-weight: normal;
}

.branch-item .checkbox-label input[type="checkbox"] {
  margin: 0;
}

.selected-info {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background: #d4edda;
  border: 1px solid #c3e6cb;
  border-radius: 4px;
  color: #155724;
  font-size: 14px;
  font-weight: 500;
}

.selected-info i {
  font-size: 16px;
}


.form-row {
  display: flex;
  gap: 15px;
}

.form-col {
  flex: 1;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.checkbox-label input[type="checkbox"] {
  margin: 0;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 30px;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

.btn {
  padding: 10px 20px;
  border: 1px solid #ddd;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.btn-cancel {
  background: white;
  color: #666;
}

.btn-cancel:hover {
  background: #f5f5f5;
}

.btn-submit {
  background: #007bff;
  color: white;
  border-color: #007bff;
}

.btn-submit:hover:not(:disabled) {
  background: #0056b3;
}

.btn-submit:disabled {
  background: #ccc;
  border-color: #ccc;
  cursor: not-allowed;
}

.image-upload-container {
  position: relative;
  border: 2px dashed #d1d5db;
  border-radius: 8px;
  padding: 20px;
  text-align: center;
  transition: border-color 0.2s ease;
  cursor: pointer;
}

.image-upload-container:hover {
  border-color: #3b82f6;
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
  max-width: 200px;
  max-height: 200px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.remove-image-btn {
  position: absolute;
  top: -8px;
  right: -8px;
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 12px;
}

.remove-image-btn:hover {
  background: #dc2626;
}

.image-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  color: #6b7280;
}

.image-placeholder i {
  font-size: 2rem;
}

.image-info {
  margin-top: 8px;
  color: #6b7280;
}
</style>