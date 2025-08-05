<template>
  <div class="product-form">
    <form @submit.prevent="handleSubmit" class="needs-validation" novalidate>
      <div class="row">
        <div class="col-md-6">
          <div class="mb-3">
            <label for="name" class="form-label">Tên món ăn *</label>
            <input
              v-model="form.name"
              type="text"
              class="form-control"
              :class="{ 'is-invalid': errors.name }"
              id="name"
              placeholder="Nhập tên món ăn"
              required
            />
            <div class="invalid-feedback" v-if="errors.name">
              {{ errors.name }}
            </div>
          </div>
        </div>
        
        <div class="col-md-6">
          <div class="mb-3">
            <label for="category" class="form-label">Danh mục *</label>
            <select
              v-model="form.category_id"
              class="form-select"
              :class="{ 'is-invalid': errors.category_id }"
              id="category"
              required
              :disabled="loadingCategories"
            >
              <option value="">
                {{ loadingCategories ? 'Đang tải danh mục...' : 'Chọn danh mục' }}
              </option>
              <option v-for="category in categories" :key="category.id" :value="category.id">
                {{ category.name }}
              </option>
            </select>
            <div class="invalid-feedback" v-if="errors.category_id">
              {{ errors.category_id }}
            </div>
          </div>
        </div>
      </div>
      
      <div class="row">
        <div class="col-md-6">
          <div class="mb-3">
            <label for="price" class="form-label">Giá (VNĐ) *</label>
            <input
              v-model.number="form.price"
              type="number"
              class="form-control"
              :class="{ 'is-invalid': errors.price }"
              id="price"
              placeholder="Nhập giá"
              min="0"
              step="1000"
              required
            />
            <div class="invalid-feedback" v-if="errors.price">
              {{ errors.price }}
            </div>
          </div>
        </div>
        
        <div class="col-md-6">
          <div class="mb-3">
            <label for="stock" class="form-label">Số lượng *</label>
            <input
              v-model.number="form.stock"
              type="number"
              class="form-control"
              :class="{ 'is-invalid': errors.stock }"
              id="stock"
              placeholder="Nhập số lượng"
              min="0"
              required
            />
            <div class="invalid-feedback" v-if="errors.stock">
              {{ errors.stock }}
            </div>
          </div>
        </div>
      </div>
      
      <div class="mb-3">
        <label for="description" class="form-label">Mô tả</label>
        <textarea
          v-model="form.description"
          class="form-control"
          :class="{ 'is-invalid': errors.description }"
          id="description"
          rows="4"
          placeholder="Nhập mô tả món ăn"
        ></textarea>
        <div class="invalid-feedback" v-if="errors.description">
          {{ errors.description }}
        </div>
      </div>

      <div class="row">
        <div class="col-md-6">
          <div class="mb-3">
            <label for="image" class="form-label">Hình ảnh</label>
            <input
              type="file"
              class="form-control"
              :class="{ 'is-invalid': errors.imageFile }"
              id="image"
              accept="image/*"
              @change="handleImageChange"
            />
            <div class="invalid-feedback" v-if="errors.imageFile">
              {{ errors.imageFile }}
            </div>
            <div v-if="imagePreview" class="mt-2">
              <img :src="imagePreview" alt="Preview" class="img-thumbnail" style="max-width: 200px; max-height: 200px;" />
            </div>
          </div>
        </div>
        
        <div class="col-md-6">
          <div class="mb-3">
            <div class="form-check">
              <input
                v-model="form.is_available"
                type="checkbox"
                class="form-check-input"
                id="is_available"
              />
              <label class="form-check-label" for="is_available">
                Có sẵn để đặt hàng
              </label>
            </div>
          </div>
        </div>
      </div>
      
      <div class="d-flex justify-content-end gap-2">
        <button 
          type="button" 
          @click="$emit('cancel')" 
          class="btn btn-secondary"
        >
          Hủy
        </button>
        <button 
          type="submit" 
          class="btn btn-primary"
          :disabled="loading"
        >
          <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
          {{ isEdit ? 'Cập nhật món ăn' : 'Tạo món ăn' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue';
import CategoryService from '@/services/CategoryService';

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

const isEdit = computed(() => !!props.product);
const imagePreview = ref('');
const categories = ref([]);
const loadingCategories = ref(false);

const form = reactive({
  name: '',
  category_id: '',
  price: '',
  stock: '',
  description: '',
  is_available: true,
  imageFile: null
});

const errors = reactive({
  name: '',
  category_id: '',
  price: '',
  stock: '',
  description: '',
  imageFile: ''
});

// Watch for product changes (edit mode)
watch(() => props.product, (newProduct) => {
  if (newProduct) {
    form.name = newProduct.name || '';
    form.category_id = newProduct.category_id || '';
    form.price = newProduct.price || '';
    form.stock = newProduct.stock || '';
    form.description = newProduct.description || '';
    form.is_available = newProduct.is_available !== undefined ? newProduct.is_available : true;
    imagePreview.value = newProduct.image || '';
  }
}, { immediate: true });

// Load categories on mount
onMounted(async () => {
  await loadCategories();
});

const loadCategories = async () => {
  try {
    loadingCategories.value = true;
    const response = await CategoryService.getAllCategories();
    categories.value = response.data || [];
  } catch (error) {
    console.error('Error loading categories:', error);
    categories.value = [];
  } finally {
    loadingCategories.value = false;
  }
};

const handleImageChange = (event) => {
  const file = event.target.files[0];
  if (file) {
    // Validate file type
    if (!file.type.startsWith('image/')) {
      errors.imageFile = 'Vui lòng chọn file hình ảnh';
      return;
    }
    
    // Validate file size (5MB)
    if (file.size > 5 * 1024 * 1024) {
      errors.imageFile = 'Kích thước file không được vượt quá 5MB';
      return;
    }
    
    form.imageFile = file;
    errors.imageFile = '';
    
    // Create preview
    const reader = new FileReader();
    reader.onload = (e) => {
      imagePreview.value = e.target.result;
    };
    reader.readAsDataURL(file);
  }
};

const validateForm = () => {
  let isValid = true;
  
  // Reset errors
  Object.keys(errors).forEach(key => {
    errors[key] = '';
  });
  
  // Validate name
  if (!form.name.trim()) {
    errors.name = 'Tên món ăn là bắt buộc';
    isValid = false;
  }
  
  // Validate category
  if (!form.category_id) {
    errors.category_id = 'Vui lòng chọn danh mục';
    isValid = false;
  }
  
  // Validate price
  if (!form.price || form.price <= 0) {
    errors.price = 'Giá phải lớn hơn 0';
    isValid = false;
  }
  
  // Validate stock
  if (form.stock === '' || form.stock < 0) {
    errors.stock = 'Số lượng phải từ 0 trở lên';
    isValid = false;
  }
  
  return isValid;
};

const handleSubmit = () => {
  if (validateForm()) {
    const formData = new FormData();
    formData.append('name', form.name);
    formData.append('category_id', form.category_id);
    formData.append('price', form.price);
    formData.append('stock', form.stock);
    formData.append('description', form.description);
    formData.append('is_available', form.is_available);
    
    if (form.imageFile) {
      formData.append('imageFile', form.imageFile);
    }
    
    emit('submit', formData);
  }
};
</script>

<style scoped>
.product-form {
  max-width: 800px;
}

.form-label {
  font-weight: 500;
}

.form-control:focus,
.form-select:focus {
  border-color: #0d6efd;
  box-shadow: 0 0 0 0.2rem rgba(13, 110, 253, 0.25);
}

.invalid-feedback {
  display: block;
}
</style> 