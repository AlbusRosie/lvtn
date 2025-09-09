<template>
  <div class="product-filter">
    <div class="card">
      <div class="card-body">
        <h6 class="card-title mb-3">
          <i class="bi bi-funnel"></i> Lọc món ăn
        </h6>

        <form @submit.prevent="handleFilter">
          <div class="row">
            <div class="col-md-3">
              <div class="mb-3">
                <label for="searchName" class="form-label">Tìm kiếm tên</label>
                <input
                  v-model="filters.name"
                  type="text"
                  class="form-control form-control-sm"
                  id="searchName"
                  placeholder="Tên món ăn..."
                />
              </div>
            </div>

            <div class="col-md-2">
              <div class="mb-3">
                <label for="categoryFilter" class="form-label">Danh mục</label>
                <select
                  v-model="filters.category_id"
                  class="form-select form-select-sm"
                  id="categoryFilter"
                  :disabled="loadingCategories"
                >
                  <option value="">
                    {{ loadingCategories ? 'Đang tải...' : 'Tất cả danh mục' }}
                  </option>
                  <option v-for="category in categories" :key="category.id" :value="category.id">
                    {{ category.name }}
                  </option>
                </select>
              </div>
            </div>

            <div class="col-md-2">
              <div class="mb-3">
                <label for="minPrice" class="form-label">Giá tối thiểu</label>
                <input
                  v-model.number="filters.min_price"
                  type="number"
                  class="form-control form-control-sm"
                  id="minPrice"
                  placeholder="Giá min"
                  min="0"
                />
              </div>
            </div>

            <div class="col-md-2">
              <div class="mb-3">
                <label for="maxPrice" class="form-label">Giá tối đa</label>
                <input
                  v-model.number="filters.max_price"
                  type="number"
                  class="form-control form-control-sm"
                  id="maxPrice"
                  placeholder="Giá max"
                  min="0"
                />
              </div>
            </div>

            <div class="col-md-2">
              <div class="mb-3">
                <label for="statusFilter" class="form-label">Trạng thái</label>
                <select
                  v-model="filters.status"
                  class="form-select form-select-sm"
                  id="statusFilter"
                >
                  <option value="">Tất cả trạng thái</option>
                  <option value="active">Hoạt động</option>
                  <option value="inactive">Không hoạt động</option>
                  <option value="out_of_stock">Hết hàng</option>
                </select>
              </div>
            </div>

            <div class="col-md-1">
              <div class="mb-3">
                <label for="availabilityFilter" class="form-label">Có sẵn</label>
                <select
                  v-model="filters.is_available"
                  class="form-select form-select-sm"
                  id="availabilityFilter"
                >
                  <option value="">Tất cả</option>
                  <option :value="true">Có sẵn</option>
                  <option :value="false">Không có sẵn</option>
                </select>
              </div>
            </div>

            <div class="col-md-1">
              <div class="mb-3">
                <label for="stockFilter" class="form-label">Số lượng</label>
                <select
                  v-model="filters.stock_status"
                  class="form-select form-select-sm"
                  id="stockFilter"
                >
                  <option value="">Tất cả</option>
                  <option value="in_stock">Còn hàng</option>
                  <option value="low_stock">Ít hàng (≤5)</option>
                  <option value="out_of_stock">Hết hàng</option>
                </select>
              </div>
            </div>
          </div>

          <div class="d-flex justify-content-between align-items-center">
            <div class="d-flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">
                <i class="bi bi-search"></i> Lọc
              </button>
              <button type="button" @click="handleClear" class="btn btn-outline-secondary btn-sm">
                <i class="bi bi-x-circle"></i> Xóa bộ lọc
              </button>
            </div>

            <div class="d-flex align-items-center gap-2">
              <label class="form-label mb-0">Hiển thị:</label>
              <select v-model="filters.limit" class="form-select form-select-sm" style="width: auto;">
                <option value="10">10</option>
                <option value="20">20</option>
                <option value="50">50</option>
                <option value="100">100</option>
              </select>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, watch, onMounted } from 'vue';
import CategoryService from '@/services/CategoryService';

const categories = ref([]);
const loadingCategories = ref(false);

const emit = defineEmits(['filter', 'clear']);

const filters = reactive({
  name: '',
  category_id: '',
  min_price: '',
  max_price: '',
  status: '',
  is_available: '',
  stock_status: '',
  limit: 10
});
onMounted(async () => {
  await loadCategories();
});

const loadCategories = async () => {
  try {
    loadingCategories.value = true;
    const response = await CategoryService.getAllCategories();
    categories.value = response || [];
  } catch (error) {
    categories.value = [];
  } finally {
    loadingCategories.value = false;
  }
};

const handleFilter = () => {
  const filterData = { ...filters };
  Object.keys(filterData).forEach(key => {
    if (key === 'limit') return; // Keep limit

    if (filterData[key] === '' || filterData[key] === null || filterData[key] === undefined) {
      delete filterData[key];
    }
  });

  emit('filter', filterData);
};

const handleClear = () => {
  Object.keys(filters).forEach(key => {
    if (key === 'limit') {
      filters[key] = 10;
    } else {
      filters[key] = '';
    }
  });

  emit('clear');
};
watch(() => filters.limit, () => {
  handleFilter();
});
</script>

<style scoped>
.product-filter {
  margin-bottom: 1.5rem;
}

.card-title {
  color: #6c757d;
  font-size: 0.9rem;
  font-weight: 600;
}

.form-label {
  font-size: 0.8rem;
  font-weight: 500;
  margin-bottom: 0.25rem;
}

.form-control-sm,
.form-select-sm {
  font-size: 0.875rem;
}
</style>