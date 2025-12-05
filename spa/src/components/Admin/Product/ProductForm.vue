<template>
  <div class="product-form">
    <form @submit.prevent="handleSubmit" novalidate>
      <div class="form-group">
        <label>
          <i class="fas fa-tag"></i>
          Tên sản phẩm <span class="required">*</span>
        </label>
        <input
          v-model="formData.name"
          type="text"
          class="form-control"
          :class="{ 'error': errors.name }"
          placeholder="Nhập tên sản phẩm"
          required
          @blur="validateField('name')"
          @input="errors.name && validateField('name')"
        />
        <span v-if="errors.name" class="error-message">
          <i class="fas fa-exclamation-circle"></i>
          {{ errors.name }}
        </span>
      </div>
      <div class="form-group">
        <label>
          <i class="fas fa-folder"></i>
          Danh mục <span class="required">*</span>
        </label>
        <select
          v-model="formData.category_id"
          class="form-control"
          :class="{ 'error': errors.category_id }"
          required
          @blur="validateField('category_id')"
          @change="errors.category_id && validateField('category_id')"
        >
          <option value="">Chọn danh mục</option>
          <option v-for="category in categories" :key="category.id" :value="category.id">
            {{ category.name }}
          </option>
        </select>
        <span v-if="errors.category_id" class="error-message">
          <i class="fas fa-exclamation-circle"></i>
          {{ errors.category_id }}
        </span>
      </div>
      <div class="form-row">
        <div class="form-col">
          <label>
            <i class="fas fa-dollar-sign"></i>
            Giá cơ bản <span class="required">*</span>
          </label>
          <input
            v-model.number="formData.base_price"
            type="number"
            class="form-control"
            :class="{ 'error': errors.base_price }"
            placeholder="Nhập giá cơ bản"
            min="0"
            step="1000"
            required
            @blur="validateField('base_price')"
            @input="errors.base_price && validateField('base_price')"
          />
          <span v-if="errors.base_price" class="error-message">
            <i class="fas fa-exclamation-circle"></i>
            {{ errors.base_price }}
          </span>
        </div>
        <div class="form-col">
          <label>
            <i class="fas fa-info-circle"></i>
            Trạng thái
          </label>
          <select
            v-model="formData.status"
            class="form-control"
          >
            <option value="active">Hoạt động</option>
            <option value="inactive">Không hoạt động</option>
          </select>
        </div>
      </div>
      <div class="form-group">
        <label>
          <i class="fas fa-align-left"></i>
          Mô tả
        </label>
        <textarea
          v-model="formData.description"
          class="form-control"
          rows="3"
          placeholder="Nhập mô tả sản phẩm"
        ></textarea>
      </div>
      <div class="form-group">
        <label class="checkbox-label">
          <input
            v-model="formData.is_global_available"
            type="checkbox"
            @change="onGlobalAvailableChange"
            class="checkbox-input"
          />
          <span>
            <i class="fas fa-globe"></i>
            Có sẵn toàn hệ thống
          </span>
        </label>
      </div>
      <div v-if="formData.is_global_available" class="form-group">
        <label>
          <i class="fas fa-store"></i>
          Chọn chi nhánh áp dụng
        </label>
        <div class="branch-selection">
          <div class="branch-actions">
            <button
              type="button"
              class="btn btn-small"
              @click="selectAllBranches"
            >
              <i class="fas fa-check-double"></i>
              Chọn tất cả
            </button>
            <button
              type="button"
              class="btn btn-small"
              @click="deselectAllBranches"
            >
              <i class="fas fa-times"></i>
              Bỏ chọn tất cả
            </button>
          </div>
          <div v-if="loadingBranches" class="loading-state">
            <i class="fas fa-spinner fa-spin"></i>
            <span>Đang tải danh sách chi nhánh...</span>
          </div>
          <div v-else-if="branches.length === 0" class="empty-state">
            <i class="fas fa-exclamation-circle"></i>
            <span>Không có chi nhánh nào đang hoạt động</span>
          </div>
          <div v-else class="branch-list">
            <div
              v-for="branch in branches"
              :key="branch.id"
              class="branch-item"
            >
              <input
                v-model="formData.selected_branches"
                type="checkbox"
                :value="branch.id"
                :id="`branch_${branch.id}`"
                class="branch-checkbox"
              />
              <label :for="`branch_${branch.id}`" class="branch-label">
                <div class="branch-name">{{ branch.name }}</div>
                <div class="branch-address">{{ branch.address_detail }}</div>
              </label>
            </div>
          </div>
          <div v-if="branches.length > 0" class="branch-count">
            <i class="fas fa-check-circle"></i>
            <span>Đã chọn: {{ formData.selected_branches.length }} / {{ branches.length }} chi nhánh</span>
          </div>
        </div>
      </div>
      <div class="form-group">
        <label>
          <i class="fas fa-image"></i>
          Hình ảnh sản phẩm
        </label>
        <div class="image-upload-container">
          <input
            id="productImage"
            ref="imageInput"
            type="file"
            accept="image/*"
            @change="handleImageChange"
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
      <!-- Product Options Section -->
      <ProductOptionsManager 
        :options="formData.options" 
        :loading="loading"
        @update:options="updateProductOptions"
        @validate-option="validateProductOption"
      />
      <div class="form-actions">
        <button
          @click="$emit('cancel')"
          type="button"
          class="btn btn-cancel"
          :disabled="loading"
        >
          Hủy
        </button>
        <button
          type="submit"
          class="btn btn-submit"
          :disabled="loading"
        >
          <i v-if="loading" class="fas fa-spinner fa-spin"></i>
          <i v-else-if="isEditing" class="fas fa-save"></i>
          <i v-else class="fas fa-plus"></i>
          {{ loading ? 'Đang xử lý...' : (isEditing ? 'Cập nhật' : 'Tạo mới') }}
        </button>
      </div>
    </form>
  </div>
</template>
<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue';
import CategoryService from '@/services/CategoryService';
import BranchService from '@/services/BranchService';
import ProductService from '@/services/ProductService';
import ProductOptionsManager from './ProductOptionsManager.vue';
const props = defineProps({
  product: {
    type: Object,
    default: null
  },
  loading: {
    type: Boolean,
    default: false
  }
});
const emit = defineEmits(['submit', 'cancel']);
const categories = ref([]);
const branches = ref([]);
const loadingBranches = ref(false);
const selectedImage = ref(null);
const imagePreview = ref(null);
const imageInput = ref(null);
const isEditing = computed(() => !!props.product);
const formData = reactive({
  name: '',
  category_id: '',
  base_price: '',
  description: '',
  status: 'active',
  is_global_available: true,
  selected_branches: [],
  image: null,
  options: []
});
const errors = reactive({
  name: '',
  category_id: '',
  base_price: ''
});
onMounted(async () => {
  try {
    const [categoriesResponse, branchesResponse] = await Promise.all([
      CategoryService.getAllCategories(),
      loadBranches()
    ]);
    categories.value = categoriesResponse || [];
  } catch (error) {
    }
});
const loadBranches = async () => {
  loadingBranches.value = true;
  try {
    const response = await BranchService.getActiveBranchesForProduct();
    branches.value = response || [];
  } catch (error) {
    branches.value = [];
  } finally {
    loadingBranches.value = false;
  }
};
const loadProductOptions = async (productId) => {
  try {
    const response = await ProductService.getProductOptions(productId);
    const options = response?.options || response?.data?.options || (Array.isArray(response) ? response : []);
    if (options && Array.isArray(options) && options.length > 0) {
      formData.options = options.map(option => {
        let requiredValue = false;
        if (option.required !== undefined && option.required !== null) {
          if (typeof option.required === 'boolean') {
            requiredValue = option.required;
          } else if (typeof option.required === 'string') {
            requiredValue = option.required === 'true' || option.required === '1';
          } else if (typeof option.required === 'number') {
            requiredValue = option.required === 1;
          }
        }
        return {
          id: option.id || null,
          name: option.name || '',
          type: option.type || 'select',
          required: requiredValue,
          display_order: option.display_order ?? 0,
          expanded: false, 
          values: (option.values && Array.isArray(option.values) && option.values.length > 0)
            ? option.values.map((value, idx) => ({
                id: value.id || null,
                value: value.value || value.label || '',
                label: value.label || value.value || '',
                price_modifier: value.price_modifier ?? 0,
                display_order: value.display_order ?? idx
              }))
            : []
        };
      });
      } else {
      formData.options = [];
    }
  } catch (error) {
    formData.options = [];
  }
};
const currentProductId = ref(null);
watch(() => props.product?.id, (newProductId) => {
  if (newProductId !== currentProductId.value) {
    currentProductId.value = newProductId;
    errors.name = '';
    errors.category_id = '';
    errors.base_price = '';
    const newProduct = props.product;
  if (newProduct) {
    formData.name = newProduct.name || '';
    formData.category_id = newProduct.category_id || '';
    formData.base_price = newProduct.base_price || '';
    formData.description = newProduct.description || '';
    formData.status = newProduct.status || 'active';
    formData.is_global_available = newProduct.is_global_available !== undefined ? newProduct.is_global_available : true;
    if (newProduct.image) {
      imagePreview.value = getImageUrl(newProduct.image);
    }
    if (newProduct.options && Array.isArray(newProduct.options) && newProduct.options.length > 0) {
      formData.options = newProduct.options.map(option => {
        let requiredValue = false;
        if (option.required !== undefined && option.required !== null) {
          if (typeof option.required === 'boolean') {
            requiredValue = option.required;
          } else if (typeof option.required === 'string') {
            requiredValue = option.required === 'true' || option.required === '1';
          } else if (typeof option.required === 'number') {
            requiredValue = option.required === 1;
          }
        }
        return {
          id: option.id || null,
          name: option.name || '',
          type: option.type || 'select',
          required: requiredValue,
          display_order: option.display_order ?? 0,
          expanded: false, 
          values: (option.values && Array.isArray(option.values) && option.values.length > 0)
            ? option.values.map((value, idx) => ({
                id: value.id || null,
                value: value.value || value.label || '',
                label: value.label || value.value || '',
                price_modifier: value.price_modifier ?? 0,
                display_order: value.display_order ?? idx
              }))
            : []
        };
      });
      } else {
      if (isEditing.value && newProduct.id) {
        loadProductOptions(newProduct.id);
      } else {
        formData.options = [];
      }
    }
  } else {
    Object.keys(formData).forEach(key => {
      if (key === 'status') {
        formData[key] = 'active';
      } else if (key === 'is_global_available') {
        formData[key] = true;
      } else {
        formData[key] = '';
      }
    });
    selectedImage.value = null;
    imagePreview.value = null;
      currentProductId.value = null;
  }
  }
}, { immediate: true });
function getImageUrl(imagePath) {
  if (!imagePath) return null;
  if (imagePath.startsWith('http')) return imagePath;
  if (imagePath.startsWith('/public')) {
    return `${window.location.origin}${imagePath}`;
  }
  return `${window.location.origin}/public/uploads/${imagePath}`;
}
const handleImageChange = (event) => {
  const file = event.target.files[0];
  if (file) {
    if (file.size > 5 * 1024 * 1024) {
      alert('Kích thước file không được vượt quá 5MB');
      return;
    }
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      alert('Chỉ chấp nhận file ảnh (JPG, PNG, GIF, WebP)');
      return;
    }
    selectedImage.value = file;
    const reader = new FileReader();
    reader.onload = (e) => {
      imagePreview.value = e.target.result;
    };
    reader.readAsDataURL(file);
    formData.image = file;
  }
};
const removeImage = () => {
  selectedImage.value = null;
  imagePreview.value = null;
  formData.image = null;
  if (imageInput.value) {
    imageInput.value.value = '';
  }
};
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};
const onGlobalAvailableChange = () => {
  if (!formData.is_global_available) {
    formData.selected_branches = [];
  } else if (formData.selected_branches.length === 0 && branches.value.length > 0) {
    selectAllBranches();
  }
};
const selectAllBranches = () => {
  formData.selected_branches = branches.value.map(branch => branch.id);
};
const deselectAllBranches = () => {
  formData.selected_branches = [];
};
const updateProductOptions = (options) => {
  formData.options = options;
};
const validateProductOption = ({ index, isValid, option }) => {
};
const validateField = (fieldName) => {
  switch (fieldName) {
    case 'name':
      if (!formData.name || formData.name.trim() === '') {
        errors.name = 'Tên sản phẩm là bắt buộc';
        return false;
      }
      errors.name = '';
      return true;
    case 'category_id':
      if (!formData.category_id || formData.category_id === '') {
        errors.category_id = 'Vui lòng chọn danh mục';
        return false;
      }
      errors.category_id = '';
      return true;
    case 'base_price':
      const priceValue = formData.base_price;
      if (priceValue === '' || priceValue === null || priceValue === undefined) {
        errors.base_price = 'Giá cơ bản là bắt buộc';
        return false;
      }
      const numPrice = Number(priceValue);
      if (isNaN(numPrice) || String(priceValue).trim() === '') {
        errors.base_price = 'Giá phải là số hợp lệ';
        return false;
      }
      if (numPrice < 0) {
        errors.base_price = 'Giá không được nhỏ hơn 0';
        return false;
      }
      errors.base_price = '';
      return true;
    default:
      return true;
  }
};
const validateAllFields = () => {
  const nameValid = validateField('name');
  const categoryValid = validateField('category_id');
  const priceValid = validateField('base_price');
  return nameValid && categoryValid && priceValid;
};
const handleSubmit = () => {
  const isValid = validateAllFields();
  if (!isValid) {
    const firstErrorField = document.querySelector('.form-control.error');
    if (firstErrorField) {
      firstErrorField.scrollIntoView({ behavior: 'smooth', block: 'center' });
      firstErrorField.focus();
    }
    return;
  }
  const submitData = new FormData();
  Object.keys(formData).forEach(key => {
    if (key === 'image' && formData[key]) {
      submitData.append('imageFile', formData[key]);
    } else if (key === 'selected_branches' && formData[key].length > 0) {
      submitData.append(key, JSON.stringify(formData[key]));
    } else if (key === 'options') {
      submitData.append(key, JSON.stringify(formData[key] || []));
    } else if (formData[key] !== null && formData[key] !== '') {
      submitData.append(key, formData[key]);
    }
  });
  emit('submit', submitData);
};
</script>
<style scoped>
.product-form {
  max-width: 100%;
}
.form-group {
  margin-bottom: 24px;
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
.form-control.error {
  border-color: #EF4444;
  background: #FEF2F2;
}
.form-control.error:focus {
  border-color: #EF4444;
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1);
  background: #FEF2F2;
}
.form-control::placeholder {
  color: #9CA3AF;
  font-weight: 400;
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
.form-group.has-error .form-control {
  border-color: #EF4444;
  background: #FEF2F2;
}
.form-row {
  display: flex;
  gap: 16px;
}
.form-col {
  flex: 1;
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
.branch-selection {
  border: 2px solid #F0E6D9;
  border-radius: 12px;
  padding: 16px;
  background: #FFF9F5;
}
.branch-actions {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
}
.btn-small {
  padding: 8px 16px;
  font-size: 13px;
  font-weight: 600;
  border: 2px solid #E5E7EB;
  background: white;
  border-radius: 8px;
  cursor: pointer;
  color: #6B7280;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-small:hover {
  background: #F9FAFB;
  border-color: #D1D5DB;
  color: #4B5563;
}
.btn-small i {
  font-size: 12px;
}
.loading-state,
.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 24px;
  color: #6B7280;
  font-size: 14px;
  font-weight: 500;
  background: white;
  border-radius: 10px;
  border: 2px dashed #E5E5E5;
}
.loading-state i {
  color: #FF8C42;
  font-size: 16px;
}
.empty-state i {
  color: #9CA3AF;
  font-size: 16px;
}
.branch-list {
  max-height: 240px;
  overflow-y: auto;
  margin-bottom: 12px;
  padding: 4px;
}
.branch-list::-webkit-scrollbar {
  width: 6px;
}
.branch-list::-webkit-scrollbar-track {
  background: #F5F5F5;
  border-radius: 3px;
}
.branch-list::-webkit-scrollbar-thumb {
  background: #D1D5DB;
  border-radius: 3px;
}
.branch-list::-webkit-scrollbar-thumb:hover {
  background: #9CA3AF;
}
.branch-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  border-bottom: 1px solid #F0E6D9;
  background: white;
  border-radius: 8px;
  margin-bottom: 8px;
}
.branch-item:last-child {
  margin-bottom: 0;
}
.branch-checkbox {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #FF8C42;
  flex-shrink: 0;
}
.branch-label {
  cursor: pointer;
  flex: 1;
}
.branch-name {
  font-weight: 600;
  font-size: 14px;
  color: #1a1a1a;
  margin-bottom: 4px;
}
.branch-address {
  font-size: 12px;
  color: #6B7280;
  font-weight: 400;
}
.branch-count {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 12px;
  padding: 12px 16px;
  background: #D1FAE5;
  border: 2px solid #A7F3D0;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  color: #065F46;
}
.branch-count i {
  color: #10B981;
  font-size: 14px;
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
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 12px;
  color: #6B7280;
  font-size: 12px;
  text-align: center;
  justify-content: center;
}
.image-info i {
  color: #9CA3AF;
  font-size: 12px;
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
  color: #10B981;
  border-color: #10B981;
}
.btn-submit:hover:not(:disabled) {
  background: #ECFDF5;
  border-color: #059669;
  color: #059669;
}
.btn:disabled {
  background: #F3F4F6;
  border-color: #D1D5DB;
  color: #9CA3AF;
  cursor: not-allowed;
  opacity: 0.6;
}
</style>