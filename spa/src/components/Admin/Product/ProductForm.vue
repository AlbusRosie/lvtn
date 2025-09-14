<template>
  <div class="product-form">
    <form @submit.prevent="handleSubmit">
      <div class="row">
        <div class="col-md-6">
          <div class="mb-3">
            <label for="name" class="form-label">Tên sản phẩm <span class="text-danger">*</span></label>
            <input
              v-model="formData.name"
              type="text"
              class="form-control"
              id="name"
              placeholder="Nhập tên sản phẩm"
              required
            />
          </div>
        </div>

        <div class="col-md-6">
          <div class="mb-3">
            <label for="category_id" class="form-label">Danh mục <span class="text-danger">*</span></label>
            <select
              v-model="formData.category_id"
              class="form-select"
              id="category_id"
              required
            >
              <option value="">Chọn danh mục</option>
              <option v-for="category in categories" :key="category.id" :value="category.id">
                {{ category.name }}
              </option>
            </select>
          </div>
        </div>

        <div class="col-md-6">
          <div class="mb-3">
            <label for="base_price" class="form-label">Giá cơ bản <span class="text-danger">*</span></label>
            <input
              v-model.number="formData.base_price"
              type="number"
              class="form-control"
              id="base_price"
              placeholder="Nhập giá cơ bản"
              min="0"
              step="1000"
              required
            />
          </div>
        </div>

        <div class="col-md-6">
          <div class="mb-3">
            <label for="status" class="form-label">Trạng thái</label>
            <select
              v-model="formData.status"
              class="form-select"
              id="status"
            >
              <option value="active">Hoạt động</option>
              <option value="inactive">Không hoạt động</option>
            </select>
          </div>
        </div>

        <div class="col-12">
          <div class="mb-3">
            <label for="description" class="form-label">Mô tả</label>
            <textarea
              v-model="formData.description"
              class="form-control"
              id="description"
              rows="3"
              placeholder="Nhập mô tả sản phẩm"
            ></textarea>
          </div>
        </div>

        <div class="col-12">
          <div class="mb-3">
            <div class="form-check">
              <input
                v-model="formData.is_global_available"
                class="form-check-input"
                type="checkbox"
                id="is_global_available"
                @change="onGlobalAvailableChange"
              />
              <label class="form-check-label" for="is_global_available">
                Có sẵn toàn hệ thống
              </label>
            </div>
          </div>
        </div>

        <div v-if="formData.is_global_available" class="col-12">
          <div class="mb-3">
            <label class="form-label">Chọn chi nhánh áp dụng</label>
            <div class="border rounded p-3" style="max-height: 200px; overflow-y: auto;">
              <div class="mb-2">
                <button
                  type="button"
                  class="btn btn-sm btn-outline-primary me-2"
                  @click="selectAllBranches"
                >
                  <i class="bi bi-check-all"></i> Chọn tất cả
                </button>
                <button
                  type="button"
                  class="btn btn-sm btn-outline-secondary"
                  @click="deselectAllBranches"
                >
                  <i class="bi bi-x-square"></i> Bỏ chọn tất cả
                </button>
              </div>
              
              <div v-if="loadingBranches" class="text-center py-3">
                <div class="spinner-border spinner-border-sm" role="status">
                  <span class="visually-hidden">Loading...</span>
                </div>
                <span class="ms-2">Đang tải danh sách chi nhánh...</span>
              </div>
              
              <div v-else-if="branches.length === 0" class="text-muted text-center py-3">
                Không có chi nhánh nào đang hoạt động
              </div>
              
              <div v-else class="row">
                <div
                  v-for="branch in branches"
                  :key="branch.id"
                  class="col-md-6 col-lg-4 mb-2"
                >
                  <div class="form-check">
                    <input
                      v-model="formData.selected_branches"
                      class="form-check-input"
                      type="checkbox"
                      :value="branch.id"
                      :id="`branch_${branch.id}`"
                    />
                    <label class="form-check-label" :for="`branch_${branch.id}`">
                      <strong>{{ branch.name }}</strong>
                      <br>
                      <small class="text-muted">{{ branch.address_detail }}</small>
                    </label>
                  </div>
                </div>
              </div>
              
              <div v-if="branches.length > 0" class="mt-2 pt-2 border-top">
                <small class="text-muted">
                  Đã chọn: <strong>{{ formData.selected_branches.length }}</strong> / {{ branches.length }} chi nhánh
                </small>
              </div>
            </div>
          </div>
        </div>

        <div class="col-12">
          <div class="mb-3">
            <label for="image" class="form-label">Hình ảnh</label>
            <input
              @change="handleImageChange"
              type="file"
              class="form-control"
              id="image"
              accept="image/*"
            />
            <div v-if="imagePreview" class="mt-2">
              <img :src="imagePreview" alt="Preview" class="img-thumbnail" style="max-width: 200px; max-height: 200px;">
            </div>
          </div>
        </div>
      </div>

      <div class="d-flex justify-content-end gap-2">
        <button
          @click="$emit('cancel')"
          type="button"
          class="btn btn-secondary"
          :disabled="loading"
        >
          Hủy
        </button>
        <button
          type="submit"
          class="btn btn-primary"
          :disabled="loading"
        >
          <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
          {{ isEditing ? 'Cập nhật' : 'Tạo mới' }}
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
const imagePreview = ref('');

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
      imagePreview.value = newProduct.image;
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
    imagePreview.value = '';
  }
}, { immediate: true });

const handleImageChange = (event) => {
  const file = event.target.files[0];
  if (file) {
    formData.image = file;
    
    const reader = new FileReader();
    reader.onload = (e) => {
      imagePreview.value = e.target.result;
    };
    reader.readAsDataURL(file);
  }
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

.form-label {
  font-weight: 500;
}

.text-danger {
  color: #dc3545 !important;
}

.img-thumbnail {
  border: 1px solid #dee2e6;
  border-radius: 0.375rem;
}

.spinner-border-sm {
  width: 1rem;
  height: 1rem;
}
</style>
