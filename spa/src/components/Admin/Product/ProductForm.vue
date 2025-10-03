<template>
  <div class="product-form">
    <form @submit.prevent="handleSubmit">
      <div class="form-group">
        <label>Tên sản phẩm *</label>
        <input
          v-model="formData.name"
          type="text"
          class="form-control"
          placeholder="Nhập tên sản phẩm"
          required
        />
      </div>

      <div class="form-group">
        <label>Danh mục *</label>
        <select
          v-model="formData.category_id"
          class="form-control"
          required
        >
          <option value="">Chọn danh mục</option>
          <option v-for="category in categories" :key="category.id" :value="category.id">
            {{ category.name }}
          </option>
        </select>
      </div>

      <div class="form-row">
        <div class="form-col">
          <label>Giá cơ bản *</label>
          <input
            v-model.number="formData.base_price"
            type="number"
            class="form-control"
            placeholder="Nhập giá cơ bản"
            min="0"
            step="1000"
            required
          />
        </div>

        <div class="form-col">
          <label>Trạng thái</label>
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
        <label>Mô tả</label>
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
          />
          <span>Có sẵn toàn hệ thống</span>
        </label>
      </div>

      <div v-if="formData.is_global_available" class="form-group">
        <label>Chọn chi nhánh áp dụng</label>
        <div class="branch-selection">
          <div class="branch-actions">
            <button
              type="button"
              class="btn btn-small"
              @click="selectAllBranches"
            >
              Chọn tất cả
            </button>
            <button
              type="button"
              class="btn btn-small"
              @click="deselectAllBranches"
            >
              Bỏ chọn tất cả
            </button>
          </div>
          
          <div v-if="loadingBranches" class="loading">
            Đang tải danh sách chi nhánh...
          </div>
          
          <div v-else-if="branches.length === 0" class="empty">
            Không có chi nhánh nào đang hoạt động
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
              />
              <label :for="`branch_${branch.id}`" class="branch-label">
                <div class="branch-name">{{ branch.name }}</div>
                <div class="branch-address">{{ branch.address_detail }}</div>
              </label>
            </div>
          </div>
          
          <div v-if="branches.length > 0" class="branch-count">
            Đã chọn: {{ formData.selected_branches.length }} / {{ branches.length }} chi nhánh
          </div>
        </div>
      </div>

      <div class="form-group">
        <label for="productImage">Hình ảnh sản phẩm</label>
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
          <small>Định dạng: JPG, PNG, GIF, WebP. Kích thước tối đa: 5MB</small>
        </div>
      </div>

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
  image: null
});

onMounted(async () => {
  try {
    const [categoriesResponse, branchesResponse] = await Promise.all([
      CategoryService.getAllCategories(),
      loadBranches()
    ]);
    categories.value = categoriesResponse || [];
  } catch (error) {
    console.error('Error loading data:', error);
  }
});

const loadBranches = async () => {
  loadingBranches.value = true;
  try {
    const response = await BranchService.getActiveBranchesForProduct();
    branches.value = response || [];
  } catch (error) {
    console.error('Error loading branches:', error);
    branches.value = [];
  } finally {
    loadingBranches.value = false;
  }
};

watch(() => props.product, (newProduct) => {
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
  }
}, { immediate: true });

const getImageUrl = (imagePath) => {
  if (!imagePath) return null;
  // Nếu đường dẫn đã có http, trả về nguyên
  if (imagePath.startsWith('http')) return imagePath;
  // Nếu đường dẫn bắt đầu bằng /public, thêm domain
  if (imagePath.startsWith('/public')) {
    return `${window.location.origin}${imagePath}`;
  }
  // Mặc định thêm /public/uploads/
  return `${window.location.origin}/public/uploads/${imagePath}`;
};

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

const handleSubmit = () => {
  if (!formData.name || !formData.category_id || !formData.base_price) {
    alert('Vui lòng điền đầy đủ thông tin bắt buộc');
    return;
  }

  const submitData = new FormData();
  
  Object.keys(formData).forEach(key => {
    if (key === 'image' && formData[key]) {
      submitData.append('imageFile', formData[key]);
    } else if (key === 'selected_branches' && formData[key].length > 0) {
      submitData.append(key, JSON.stringify(formData[key]));
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

.branch-selection {
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 15px;
}

.branch-actions {
  display: flex;
  gap: 10px;
  margin-bottom: 15px;
}

.btn-small {
  padding: 5px 10px;
  font-size: 12px;
  border: 1px solid #ddd;
  background: white;
  border-radius: 3px;
  cursor: pointer;
}

.btn-small:hover {
  background: #f5f5f5;
}

.loading, .empty {
  text-align: center;
  padding: 20px;
  color: #666;
}

.branch-list {
  max-height: 200px;
  overflow-y: auto;
}

.branch-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 0;
  border-bottom: 1px solid #eee;
}

.branch-item:last-child {
  border-bottom: none;
}

.branch-item input[type="checkbox"] {
  margin: 0;
}

.branch-label {
  cursor: pointer;
  flex: 1;
}

.branch-name {
  font-weight: 500;
  margin-bottom: 2px;
}

.branch-address {
  font-size: 12px;
  color: #666;
}

.branch-count {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid #eee;
  font-size: 12px;
  color: #666;
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

.btn-cancel:hover:not(:disabled) {
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

.btn:disabled {
  background: #ccc;
  border-color: #ccc;
  cursor: not-allowed;
}
</style>