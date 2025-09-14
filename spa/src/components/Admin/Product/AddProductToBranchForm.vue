<template>
  <div class="add-product-form">
    <form @submit.prevent="handleSubmit">
      <div class="mb-3">
        <label class="form-label">
          <i class="bi bi-building"></i> Chi nhánh <span class="text-danger">*</span>
        </label>
        <div class="row">
          <div class="col-md-6">
            <div class="form-check">
              <input 
                class="form-check-input" 
                type="radio" 
                id="allBranches"
                v-model="formData.branchType"
                value="all"
              >
              <label class="form-check-label" for="allBranches">
                <strong>Tất cả chi nhánh</strong>
                <small class="text-muted d-block">Thêm sản phẩm vào tất cả chi nhánh đang hoạt động</small>
              </label>
            </div>
          </div>
          <div class="col-md-6">
            <div class="form-check">
              <input 
                class="form-check-input" 
                type="radio" 
                id="specificBranch"
                v-model="formData.branchType"
                value="specific"
              >
              <label class="form-check-label" for="specificBranch">
                <strong>Chi nhánh cụ thể</strong>
                <small class="text-muted d-block">Chọn chi nhánh để thêm sản phẩm</small>
              </label>
            </div>
          </div>
        </div>
      </div>

      <div v-if="formData.branchType === 'specific'" class="mb-3">
        <label class="form-label">Chọn chi nhánh</label>
        <select 
          v-model="formData.selectedBranches" 
          class="form-select"
          multiple
          size="4"
        >
          <option 
            v-for="branch in availableBranches" 
            :key="branch.id" 
            :value="branch.id"
          >
            {{ branch.name }} - {{ branch.address_detail }}
          </option>
        </select>
        <small class="text-muted">Giữ Ctrl để chọn nhiều chi nhánh</small>
      </div>

      <div class="mb-3">
        <label class="form-label">
          <i class="bi bi-box"></i> Sản phẩm <span class="text-danger">*</span>
        </label>
        <div class="row">
          <div class="col-md-6">
            <div class="form-check">
              <input 
                class="form-check-input" 
                type="radio" 
                id="existingProduct"
                v-model="formData.productType"
                value="existing"
              >
              <label class="form-check-label" for="existingProduct">
                <strong>Sản phẩm có sẵn</strong>
                <small class="text-muted d-block">Chọn từ danh sách sản phẩm hiện có</small>
              </label>
            </div>
          </div>
          <div class="col-md-6">
            <div class="form-check">
              <input 
                class="form-check-input" 
                type="radio" 
                id="newProduct"
                v-model="formData.productType"
                value="new"
              >
              <label class="form-check-label" for="newProduct">
                <strong>Tạo sản phẩm mới</strong>
                <small class="text-muted d-block">Tạo sản phẩm mới và thêm vào chi nhánh</small>
              </label>
            </div>
          </div>
        </div>
      </div>

      <div v-if="formData.productType === 'existing'" class="mb-3">
        <label class="form-label">Chọn sản phẩm</label>
        <div class="row">
          <div class="col-md-6">
            <select v-model="filters.category" class="form-select form-select-sm mb-2">
              <option value="">Tất cả danh mục</option>
              <option v-for="category in categories" :key="category.id" :value="category.id">
                {{ category.name }}
              </option>
            </select>
          </div>
          <div class="col-md-6">
            <input 
              type="text" 
              v-model="filters.search"
              class="form-control form-control-sm mb-2"
              placeholder="Tìm kiếm sản phẩm..."
            >
          </div>
        </div>
        
        <div class="border rounded p-2" style="max-height: 200px; overflow-y: auto;">
          <div v-if="loadingProducts" class="text-center p-3">
            <div class="spinner-border spinner-border-sm text-primary" role="status">
              <span class="visually-hidden">Loading...</span>
            </div>
          </div>
          <div v-else-if="filteredProducts.length === 0" class="text-center p-3 text-muted">
            <i class="bi bi-inbox"></i>
            <p class="mb-0">Không có sản phẩm nào</p>
          </div>
          <div v-else>
            <div 
              v-for="product in filteredProducts" 
              :key="product.id"
              class="form-check mb-2"
            >
              <input 
                class="form-check-input" 
                type="checkbox" 
                :id="`product-${product.id}`"
                :value="product.id"
                v-model="formData.selectedProducts"
              >
              <label class="form-check-label d-flex align-items-center" :for="`product-${product.id}`">
                <img 
                  :src="product.image || DEFAULT_AVATAR" 
                  :alt="product.name"
                  class="img-thumbnail me-2"
                  style="width: 40px; height: 40px; object-fit: cover;"
                >
                <div>
                  <div class="fw-bold">{{ product.name }}</div>
                  <small class="text-muted">{{ product.category_name }} - {{ formatPrice(product.base_price) }}</small>
                </div>
              </label>
            </div>
          </div>
        </div>
      </div>

      <div v-if="formData.productType === 'new'" class="mb-3">
        <div class="row">
          <div class="col-md-6">
            <label class="form-label">Tên sản phẩm <span class="text-danger">*</span></label>
            <input 
              type="text" 
              v-model="formData.newProduct.name"
              class="form-control"
              placeholder="Nhập tên sản phẩm"
              required
            >
          </div>
          <div class="col-md-6">
            <label class="form-label">Danh mục <span class="text-danger">*</span></label>
            <select v-model="formData.newProduct.category_id" class="form-select" required>
              <option value="">Chọn danh mục</option>
              <option v-for="category in categories" :key="category.id" :value="category.id">
                {{ category.name }}
              </option>
            </select>
          </div>
        </div>
        <div class="row mt-2">
          <div class="col-md-6">
            <label class="form-label">Giá cơ bản <span class="text-danger">*</span></label>
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
          <div class="col-md-6">
            <label class="form-label">Hình ảnh</label>
            <input 
              type="file" 
              @change="handleImageUpload"
              class="form-control"
              accept="image/*"
            >
          </div>
        </div>
        <div class="mt-2">
          <label class="form-label">Mô tả</label>
          <textarea 
            v-model="formData.newProduct.description"
            class="form-control"
            rows="3"
            placeholder="Mô tả sản phẩm"
          ></textarea>
        </div>
      </div>

      <div class="mb-3">
        <h6 class="mb-3">
          <i class="bi bi-gear"></i> Cài đặt sản phẩm cho chi nhánh
        </h6>
        <div class="row">
          <div class="col-md-4">
            <label class="form-label">Giá tại chi nhánh</label>
            <input 
              type="number" 
              v-model="formData.branchSettings.price"
              class="form-control"
              placeholder="Tự động lấy giá cơ bản"
              min="0"
              step="1000"
            >
            <small class="text-muted">Để trống để sử dụng giá cơ bản</small>
          </div>
          <div class="col-md-4">
            <label class="form-label">Trạng thái</label>
            <select v-model="formData.branchSettings.status" class="form-select">
              <option value="available">Có sẵn</option>
              <option value="temporarily_unavailable">Tạm ngừng</option>
              <option value="out_of_stock">Hết hàng</option>
            </select>
          </div>
          <div class="col-md-4">
            <label class="form-label">Có sẵn</label>
            <div class="form-check form-switch">
              <input 
                class="form-check-input" 
                type="checkbox" 
                v-model="formData.branchSettings.is_available"
              >
              <label class="form-check-label">
                {{ formData.branchSettings.is_available ? 'Có sẵn' : 'Không có sẵn' }}
              </label>
            </div>
          </div>
        </div>
        <div class="mt-2">
          <label class="form-label">Ghi chú</label>
          <textarea 
            v-model="formData.branchSettings.notes"
            class="form-control"
            rows="2"
            placeholder="Ghi chú đặc biệt cho chi nhánh này"
          ></textarea>
        </div>
      </div>

      <div class="d-flex justify-content-end gap-2">
        <button 
          type="button" 
          class="btn btn-secondary"
          @click="$emit('cancel')"
        >
          <i class="bi bi-x-circle"></i> Hủy
        </button>
        <button 
          type="submit" 
          class="btn btn-primary"
          :disabled="loading || !isFormValid"
        >
          <i class="bi bi-plus-circle"></i> 
          {{ loading ? 'Đang xử lý...' : 'Thêm sản phẩm' }}
        </button>
      </div>
    </form>
  </div>
</template>

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
const loadingProducts = ref(false)
const products = ref([])

const formData = ref({
  branchType: 'specific',
  selectedBranches: [],
  productType: 'existing',
  selectedProducts: [],
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

const filters = ref({
  category: '',
  search: ''
})

const availableBranches = computed(() => {
  if (props.selectedBranchId) {
    return props.branches.filter(b => b.id == props.selectedBranchId)
  }
  return props.branches
})

const filteredProducts = computed(() => {
  let filtered = products.value

  if (filters.value.category) {
    filtered = filtered.filter(p => p.category_id == filters.value.category)
  }

  if (filters.value.search) {
    const search = filters.value.search.toLowerCase()
    filtered = filtered.filter(p => 
      p.name.toLowerCase().includes(search) ||
      p.description?.toLowerCase().includes(search)
    )
  }

  return filtered
})

const isFormValid = computed(() => {
  if (formData.value.branchType === 'specific' && formData.value.selectedBranches.length === 0) {
    return false
  }

  if (formData.value.productType === 'existing' && formData.value.selectedProducts.length === 0) {
    return false
  }

  if (formData.value.productType === 'new') {
    return formData.value.newProduct.name && 
           formData.value.newProduct.category_id && 
           formData.value.newProduct.base_price > 0
  }

  return true
})

const loadProducts = async () => {
  loadingProducts.value = true
  try {
    const data = await ProductService.getProducts()
    products.value = data.data?.products || data.products || []
  } catch (error) {
    console.error('Error loading products:', error)
  } finally {
    loadingProducts.value = false
  }
}

const handleImageUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    formData.value.newProduct.image = file
  }
}

const handleSubmit = async () => {
  loading.value = true
  try {
    if (formData.value.productType === 'existing') {
      await addExistingProducts()
    } else {
      await createNewProduct()
    }
    
    emit('success')
  } catch (error) {
    console.error('Error adding products:', error)
    alert('Có lỗi xảy ra: ' + error.message)
  } finally {
    loading.value = false
  }
}

const addExistingProducts = async () => {
  const branches = formData.value.branchType === 'all' 
    ? props.branches.map(b => b.id)
    : formData.value.selectedBranches

  const branchProductData = {
    price: formData.value.branchSettings.price || null,
    is_available: formData.value.branchSettings.is_available ? 1 : 0,
    status: formData.value.branchSettings.status,
    notes: formData.value.branchSettings.notes || null
  }

  const promises = []
  
  for (const branchId of branches) {
    for (const productId of formData.value.selectedProducts) {
      promises.push(
        ProductService.addProductToBranch(branchId, productId, branchProductData)
      )
    }
  }

  await Promise.all(promises)
}

const createNewProduct = async () => {
  const productData = new FormData()
  productData.append('name', formData.value.newProduct.name)
  productData.append('category_id', formData.value.newProduct.category_id)
  productData.append('base_price', formData.value.newProduct.base_price)
  productData.append('description', formData.value.newProduct.description)
  productData.append('is_global_available', formData.value.branchType === 'all' ? '1' : '0')
  
  if (formData.value.newProduct.image) {
    productData.append('imageFile', formData.value.newProduct.image)
  }

  if (formData.value.branchType === 'specific') {
    productData.append('selected_branches', JSON.stringify(formData.value.selectedBranches))
  }

  const newProduct = await ProductService.createProduct(productData)
  
  if (formData.value.branchType === 'specific' && formData.value.selectedBranches.length > 0) {
    const branchProductData = {
      price: formData.value.branchSettings.price || formData.value.newProduct.base_price,
      is_available: formData.value.branchSettings.is_available ? 1 : 0,
      status: formData.value.branchSettings.status,
      notes: formData.value.branchSettings.notes || null
    }

    const promises = formData.value.selectedBranches.map(branchId => 
      ProductService.addProductToBranch(branchId, newProduct.data.id, branchProductData)
    )

    await Promise.all(promises)
  }
}

const formatPrice = (price) => {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(price)
}

watch(() => props.selectedBranchId, (newVal) => {
  if (newVal) {
    formData.value.selectedBranches = [newVal]
  }
})

onMounted(() => {
  if (props.selectedBranchId) {
    formData.value.selectedBranches = [props.selectedBranchId]
  }
  loadProducts()
})
</script>

<style scoped>
.add-product-form {
  padding: 0;
}

.form-check-label {
  cursor: pointer;
}

.img-thumbnail {
  border: 1px solid #dee2e6;
}

.border {
  border: 1px solid #dee2e6 !important;
}

.spinner-border-sm {
  width: 1rem;
  height: 1rem;
}

.form-control-sm {
  font-size: 0.875rem;
}

.text-muted {
  font-size: 0.875rem;
}

.form-switch .form-check-input {
  width: 2.5em;
  height: 1.25em;
}
</style>
