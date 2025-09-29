<template>
  <div class="branch-menu-management">
    <div class="header">
      <h1>Quản lý Menu Chi nhánh</h1>
      <div class="actions">
        <button @click="showAddProductModal = true" class="btn-add">+ Thêm sản phẩm</button>
        <button @click="refreshData" class="btn-refresh" :disabled="loading">Làm mới</button>
      </div>
    </div>

    <div class="search-section">
      <div class="search-row">
        <select v-model="selectedBranchId" @change="onBranchChange" class="filter-select">
          <option value="">Tất cả sản phẩm</option>
          <option v-for="branch in branches" :key="branch.id" :value="branch.id">
            {{ branch.name }}
          </option>
        </select>
        
        <input
          v-model="searchQuery"
          @input="onSearchInput"
          @keyup.enter="onSearchEnter"
          type="text"
          placeholder="Tìm kiếm sản phẩm..."
          class="search-input"
        />
        
        <select v-model="filters.category" class="filter-select">
          <option value="">Tất cả danh mục</option>
          <option v-for="category in categories" :key="category.id" :value="category.id">
            {{ category.name }}
          </option>
        </select>

        <select v-model="filters.status" class="filter-select">
          <option value="">Tất cả trạng thái</option>
          <option value="available">Có sẵn</option>
          <option value="out_of_stock">Hết hàng</option>
          <option value="temporarily_unavailable">Tạm ngừng</option>
          <option value="discontinued">Ngừng bán</option>
          <option value="not_added">Chưa thêm</option>
        </select>

        <button @click="applyFilters" class="filter-btn">Lọc</button>
        <button @click="clearFilters" class="filter-btn btn-secondary">Xóa bộ lọc</button>
      </div>
    </div>

    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Đang tải danh sách sản phẩm...</p>
      </div>

      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadProducts" class="btn btn-secondary">
          Thử lại
        </button>
      </div>

      <div v-else-if="products.length === 0" class="empty-state">
        <i class="fas fa-box"></i>
        <h3>Không có sản phẩm nào</h3>
        <p v-if="selectedBranchId">Chưa có sản phẩm nào được thêm vào chi nhánh này.</p>
        <p v-else>Chưa có sản phẩm nào trong hệ thống.</p>
        <button @click="showAddProductModal = true" class="btn btn-primary">
          Thêm sản phẩm đầu tiên
        </button>
      </div>

      <div v-else class="products-management">
        <div class="section-header">
          <div class="branch-info">
            <h3 v-if="selectedBranchId">{{ selectedBranch?.name }}</h3>
            <h3 v-else>Tất cả sản phẩm</h3>
            <div v-if="selectedBranchId" class="product-stats">
              <span class="stat-item added">{{ addedProductsCount }} đã thêm</span>
              <span class="stat-item not-added">{{ notAddedProductsCount }} chưa thêm</span>
            </div>
            <div v-else class="product-stats">
              <span class="stat-item total">{{ products.length }} sản phẩm</span>
            </div>
          </div>
          <div class="product-controls">
            <span class="product-count">{{ products.length }} sản phẩm</span>
            <label class="select-all-label">
              <input 
                type="checkbox" 
                v-model="selectAll"
                @change="toggleSelectAll"
              >
              Chọn tất cả
            </label>
          </div>
        </div>

        <!-- Chế độ quản lý theo chi nhánh -->
        <div v-if="selectedBranchId" class="products-layout">
          <div class="products-column not-added-column">
            <div class="column-header">
              <h4>Sản phẩm chưa thêm</h4>
              <span class="count">{{ notAddedProductsCount }} sản phẩm</span>
            </div>
            <div class="product-list">
              <div class="table-header">
                <div class="header-checkbox"></div>
                <div class="header-image">Hình ảnh</div>
                <div class="header-name">Tên sản phẩm</div>
                <div class="header-category">Danh mục</div>
                <div class="header-price">Giá gốc</div>
                <div class="header-actions">Thao tác</div>
              </div>
              
              <div 
                v-for="product in notAddedProducts" 
                :key="product.id"
                class="product-item not-added"
              >
                <div class="product-checkbox">
                  <input 
                    type="checkbox" 
                    :id="`product-${product.id}`"
                    :value="product.id"
                    v-model="selectedProducts"
                  >
                  <label :for="`product-${product.id}`"></label>
                </div>
                
                <div class="product-image">
                  <img 
                    :src="product.image || DEFAULT_PRODUCT_IMAGE" 
                    :alt="product.name"
                    @error="handleImageError"
                  >
                </div>
                
                <div class="product-name">{{ product.name }}</div>
                <div class="product-category">{{ product.category_name }}</div>
                <div class="product-price">{{ formatPrice(product.base_price) }}</div>
                
                <div class="product-actions">
                  <button 
                    v-if="product.final_status === 'not_added'"
                    @click="addProductToBranch(product)"
                    :disabled="loading"
                    class="btn btn-success btn-sm"
                  >
                    <i class="fas fa-plus"></i> Thêm
                  </button>
                  <span v-else class="text-success">Đã thêm</span>
                </div>
              </div>
            </div>
          </div>

          <div class="products-column added-column">
            <div class="column-header">
              <h4>Menu chi nhánh</h4>
              <span class="count">{{ addedProductsCount }} sản phẩm</span>
            </div>
            <div class="product-list">
              <div class="table-header">
                <div class="header-checkbox"></div>
                <div class="header-image">Hình ảnh</div>
                <div class="header-name">Tên sản phẩm</div>
                <div class="header-category">Danh mục</div>
                <div class="header-price">Giá gốc</div>
                <div class="header-branch-price">Giá chi nhánh</div>
                <div class="header-actions">Thao tác</div>
              </div>
              
              <div 
                v-for="product in addedProducts" 
                :key="product.id"
                class="product-item added"
              >
                <div class="product-checkbox">
                  <input 
                    type="checkbox" 
                    :id="`product-${product.id}`"
                    :value="product.id"
                    v-model="selectedProducts"
                  >
                  <label :for="`product-${product.id}`"></label>
                </div>
                
                <div class="product-image">
                  <img 
                    :src="product.image || DEFAULT_PRODUCT_IMAGE" 
                    :alt="product.name"
                    @error="handleImageError"
                  >
                </div>
                
                <div class="product-name">{{ product.name }}</div>
                <div class="product-category">{{ product.category_name }}</div>
                <div class="product-price">{{ formatPrice(product.base_price) }}</div>
                <div v-if="product.branch_price" class="branch-price">
                  {{ formatPrice(product.branch_price) }}
                </div>
                
                <div class="product-actions">
                  <button 
                    @click="editBranchProduct(product)"
                    class="btn btn-warning btn-sm"
                  >
                    <i class="fas fa-edit"></i> Sửa
                  </button>
                  <button 
                    v-if="product.final_status === 'available' || product.final_status === 'out_of_stock' || product.final_status === 'temporarily_unavailable'"
                    @click="removeProductFromBranch(product)"
                    :disabled="loading"
                    class="btn btn-danger btn-sm"
                  >
                    <i class="fas fa-trash"></i> Xóa
                  </button>
                  <span v-else-if="product.final_status === 'discontinued'" class="text-muted">Đã xóa</span>
                  <span v-else class="text-muted">Không thể xóa</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Chế độ quản lý tất cả sản phẩm -->
        <div v-else class="all-products-layout">
          <div class="product-list">
            <div class="table-header">
              <div class="header-checkbox"></div>
              <div class="header-image">Hình ảnh</div>
              <div class="header-name">Tên sản phẩm</div>
              <div class="header-category">Danh mục</div>
              <div class="header-price">Giá gốc</div>
              <div class="header-status">Trạng thái</div>
              <div class="header-actions">Thao tác</div>
            </div>
            
            <div 
              v-for="product in products" 
              :key="product.id"
              class="product-item all-products"
            >
              <div class="product-checkbox">
                <input 
                  type="checkbox" 
                  :id="`product-${product.id}`"
                  :value="product.id"
                  v-model="selectedProducts"
                >
                <label :for="`product-${product.id}`"></label>
              </div>
              
              <div class="product-image">
                <img 
                  :src="product.image || DEFAULT_PRODUCT_IMAGE" 
                  :alt="product.name"
                  @error="handleImageError"
                >
              </div>
              
              <div class="product-name">{{ product.name }}</div>
              <div class="product-category">{{ product.category_name }}</div>
              <div class="product-price">{{ formatPrice(product.base_price) }}</div>
              <div class="product-status">
                <span :class="getStatusBadgeClass(product.status)">
                  {{ getStatusText(product.status) }}
                </span>
              </div>
              
              <div class="product-actions">
                <button 
                  @click="editProduct(product)"
                  class="btn btn-warning btn-sm"
                >
                  <i class="fas fa-edit"></i> Sửa
                </button>
                <button 
                  @click="deleteProduct(product)"
                  :disabled="loading"
                  class="btn btn-danger btn-sm"
                >
                  <i class="fas fa-trash"></i> Xóa
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="selectedProducts.length > 0" class="bulk-actions">
      <div class="bulk-actions-content">
        <span class="selected-count">
          Đã chọn {{ selectedProducts.length }} sản phẩm
        </span>
        <div class="bulk-buttons">
          <button 
            class="btn btn-success btn-sm"
            @click="bulkAddToBranch"
            :disabled="loading"
          >
            <i class="fas fa-plus"></i> Thêm vào chi nhánh
          </button>
          <button 
            class="btn btn-warning btn-sm"
            @click="bulkUpdateStatus"
            :disabled="loading"
          >
            <i class="fas fa-edit"></i> Cập nhật trạng thái
          </button>
          <button 
            class="btn btn-danger btn-sm"
            @click="bulkRemoveFromBranch"
            :disabled="loading"
          >
            <i class="fas fa-trash"></i> Xóa khỏi chi nhánh
          </button>
        </div>
      </div>
    </div>

    <div 
      v-if="showAddProductModal" 
      class="modal-overlay" 
      @click="showAddProductModal = false"
    >
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h5 class="modal-title">
            <i class="fas fa-plus-circle"></i> Thêm sản phẩm vào menu
          </h5>
          <button 
            type="button" 
            class="btn-close" 
            @click="showAddProductModal = false"
          ></button>
        </div>
        <div class="modal-body">
          <AddProductToBranchForm 
            :branches="branches"
            :categories="categories"
            :selected-branch-id="selectedBranchId"
            @success="onProductAdded"
            @cancel="showAddProductModal = false"
          />
        </div>
      </div>
    </div>

    <div 
      v-if="showEditModal && editingProduct && selectedBranch"
      class="modal-overlay" 
      @click="showEditModal = false"
    >
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h5 class="modal-title">
            <i class="fas fa-edit"></i> Chỉnh sửa sản phẩm chi nhánh
          </h5>
          <button 
            type="button" 
            class="btn-close" 
            @click="showEditModal = false"
          ></button>
        </div>
        <div class="modal-body">
          <EditBranchProductForm 
            :product="editingProduct"
            :branch="selectedBranch"
            @success="onProductUpdated"
            @cancel="showEditModal = false"
          />
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useToast } from 'vue-toastification'
import ProductService from '@/services/ProductService'
import BranchService from '@/services/BranchService'
import { DEFAULT_AVATAR, DEFAULT_PRODUCT_IMAGE } from '@/constants'
import AddProductToBranchForm from '@/components/Admin/Product/AddProductToBranchForm.vue'
import EditBranchProductForm from '@/components/Admin/Product/EditBranchProductForm.vue'
import ProductCard from '@/components/Admin/Product/ProductCard.vue'
import LoadingSpinner from '@/components/LoadingSpinner.vue'

const toast = useToast()

const loading = ref(false)
const error = ref(null)
const branches = ref([])
const categories = ref([])
const products = ref([])
const selectedBranchId = ref('')
const selectedProducts = ref([])
const selectAll = ref(false)
const searchQuery = ref('')
let searchTimeout = null
const showAddProductModal = ref(false)
const showEditModal = ref(false)
const editingProduct = ref(null)

const filters = ref({
  category: '',
  status: ''
})

const selectedBranch = computed(() => {
  return branches.value.find(b => b.id == selectedBranchId.value)
})

const addedProductsCount = computed(() => {
  return products.value.filter(p => p.final_status === 'available' || p.final_status === 'out_of_stock' || p.final_status === 'temporarily_unavailable').length
})

const notAddedProductsCount = computed(() => {
  return products.value.filter(p => p.final_status === 'not_added').length
})

const notAddedProducts = computed(() => {
  return products.value.filter(p => p.final_status === 'not_added')
})

const addedProducts = computed(() => {
  return products.value.filter(p => p.final_status === 'available' || p.final_status === 'out_of_stock' || p.final_status === 'temporarily_unavailable')
})

const loadBranches = async () => {
  try {
    const data = await BranchService.getActiveBranches()
    branches.value = data
  } catch (error) {
    showErrorToast('Không thể tải danh sách chi nhánh')
  }
}

const loadCategories = async () => {
  try {
    const CategoryService = await import('@/services/CategoryService')
    const data = await CategoryService.default.getAllCategories()
    categories.value = data
  } catch (error) {
    showErrorToast('Không thể tải danh mục sản phẩm')
  }
}

const loadProducts = async () => {
  loading.value = true
  try {
    let params = { ...filters.value }
    
    if (params.category) {
      params.category_id = params.category
      delete params.category
    }
    
    if (selectedBranchId.value) {
      params.branch_id = selectedBranchId.value
    }
    
    if (searchQuery.value) {
      params.name = searchQuery.value
    }
    
    const data = await ProductService.getProducts(params)
    
    if (data.data && data.data.products) {
      products.value = data.data.products
    } else if (data.products) {
      products.value = data.products
    } else if (Array.isArray(data)) {
      products.value = data
    } else {
      products.value = []
    }
    } catch (error) {
    showErrorToast('Không thể tải danh sách sản phẩm')
  } finally {
    loading.value = false
  }
}

const onBranchChange = () => {
  selectedProducts.value = []
  selectAll.value = false
  loadProducts()
}


const selectAllBranches = () => {
  showInfoToast('Tính năng đang phát triển')
}

const onSearchInput = () => {
  if (searchTimeout) {
    clearTimeout(searchTimeout)
  }
  
  searchTimeout = setTimeout(() => {
    loadProducts()
  }, 500)
}

const onSearchEnter = () => {
  if (searchTimeout) {
    clearTimeout(searchTimeout)
  }
  loadProducts()
}

const applyFilters = () => {
  loadProducts()
}

const clearFilters = () => {
  searchQuery.value = ''
  filters.value = {
    category: '',
    status: '',
    min_price: '',
    max_price: ''
  }
  loadProducts()
}

const refreshData = () => {
  loadProducts()
}

const addProductToBranch = async (product) => {
  try {
    const branchProductData = {
      price: product.base_price
    }
    
    await ProductService.addProductToBranch(selectedBranchId.value, product.id, branchProductData)
    
    const message = `Đã thêm "${product.name}" vào chi nhánh`
    
    showSuccessToast(message)
    
    await loadProducts()
  } catch (error) {
    showErrorToast(error.message)
  }
}

const editBranchProduct = (product) => {
  editingProduct.value = product
  showEditModal.value = true
}

const removeProductFromBranch = async (product) => {
  if (!confirm(`Bạn có chắc muốn xóa "${product.name}" khỏi chi nhánh?`)) return
  
  try {
    await ProductService.removeProductFromBranch(selectedBranchId.value, product.id)
    showSuccessToast(`Đã xóa "${product.name}" khỏi chi nhánh`)
    
    await new Promise(resolve => setTimeout(resolve, 500))
    
    await loadProducts()
  } catch (error) {
    showErrorToast(error.message)
  }
}

const updateBranchPrice = async (product) => {
  try {
    const updateData = {
      price: product.branch_price
    }
    
    await ProductService.updateBranchProduct(product.branch_product_id, updateData)
    showSuccessToast(`Đã cập nhật giá "${product.name}"`)
  } catch (error) {
    showErrorToast(error.message)
    loadProducts()
  }
}

const toggleSelectAll = () => {
  if (selectAll.value) {
    selectedProducts.value = products.value.map(p => p.id)
  } else {
    selectedProducts.value = []
  }
}

const onProductSelect = (productId, isSelected) => {
  if (isSelected) {
    if (!selectedProducts.value.includes(productId)) {
      selectedProducts.value.push(productId)
    }
  } else {
    const index = selectedProducts.value.indexOf(productId)
    if (index > -1) {
      selectedProducts.value.splice(index, 1)
    }
  }
}

const bulkAddToBranch = async () => {
  if (!selectedBranchId.value) {
    showErrorToast('Vui lòng chọn chi nhánh')
    return
  }
  
  try {
    const promises = selectedProducts.value.map(productId => {
      const product = products.value.find(p => p.id === productId)
      return ProductService.addProductToBranch(selectedBranchId.value, productId, {
        price: product.base_price,
        is_available: 1,
        status: 'available'
      })
    })
    
    await Promise.all(promises)
    showSuccessToast(`Đã thêm ${selectedProducts.value.length} sản phẩm vào chi nhánh`)
    selectedProducts.value = []
    selectAll.value = false
    loadProducts()
  } catch (error) {
    showErrorToast(error.message)
  }
}

const bulkUpdateStatus = () => {
  showInfoToast('Tính năng đang phát triển')
}

const bulkRemoveFromBranch = async () => {
  if (!confirm(`Bạn có chắc muốn xóa ${selectedProducts.value.length} sản phẩm khỏi chi nhánh?`)) return
  
  try {
    const promises = selectedProducts.value.map(productId => {
      return ProductService.removeProductFromBranch(selectedBranchId.value, productId)
    })
    
    await Promise.all(promises)
    showSuccessToast(`Đã xóa ${selectedProducts.value.length} sản phẩm khỏi chi nhánh`)
    selectedProducts.value = []
    selectAll.value = false
    loadProducts()
  } catch (error) {
    showErrorToast(error.message)
  }
}

const onProductAdded = () => {
  showAddProductModal.value = false
  loadProducts()
}

const onProductUpdated = () => {
  showEditModal.value = false
  loadProducts()
}

const editProduct = (product) => {
  window.location.href = `/admin/products/${product.id}`
}

const deleteProduct = async (product) => {
  if (!confirm(`Bạn có chắc muốn xóa sản phẩm "${product.name}"?`)) return
  
  try {
    await ProductService.deleteProduct(product.id)
    showSuccessToast(`Đã xóa sản phẩm "${product.name}"`)
    loadProducts()
  } catch (error) {
    showErrorToast(error.message)
  }
}

const formatPrice = (price) => {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(price)
}

const getStatusBadgeClass = (status) => {
  const classes = {
    'available': 'bg-success',
    'out_of_stock': 'bg-danger',
    'temporarily_unavailable': 'bg-warning',
    'discontinued': 'bg-transparent text-dark',
    'not_added': 'bg-light text-dark'
  }
  return classes[status] || 'bg-transparent text-dark'
}

const getStatusText = (status) => {
  const texts = {
    'available': 'Có sẵn',
    'out_of_stock': 'Hết hàng',
    'temporarily_unavailable': 'Tạm ngừng',
    'discontinued': 'Ngừng bán',
    'not_added': 'Chưa thêm'
  }
  return texts[status] || status
}

const handleImageError = (event) => {
  event.target.src = DEFAULT_PRODUCT_IMAGE
}

const showSuccessToast = (message) => {
  toast.success(message)
}

const showErrorToast = (message) => {
  toast.error(message)
}

const showInfoToast = (message) => {
  toast.info(message)
}

watch(selectedProducts, (newVal) => {
  selectAll.value = newVal.length === products.value.length && products.value.length > 0
})

onMounted(() => {
  loadBranches()
  loadCategories()
  loadProducts()
})
</script>

<style scoped>
.branch-menu-management {
  padding: 20px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding-bottom: 15px;
  border-bottom: 1px solid #ddd;
}

.header h1 {
  margin: 0;
  font-size: 24px;
  color: #333;
}

.actions {
  display: flex;
  gap: 10px;
}

.btn-add, .btn-refresh {
  padding: 8px 16px;
  border: 1px solid #ccc;
  background: white;
  color: #333;
  cursor: pointer;
  border-radius: 4px;
  font-size: 14px;
}

.btn-add {
  background: #007bff;
  color: white;
  border-color: #007bff;
}

.btn-add:hover {
  background: #0056b3;
}

.btn-refresh {
  background: white;
  color: #333;
  border-color: #ccc;
}

.btn-refresh:hover {
  background: #f8f9fa;
  border-color: #007bff;
}

.search-section {
  margin-bottom: 20px;
}

.search-row {
  display: flex;
  gap: 12px;
  align-items: center;
  flex-wrap: wrap;
}

.search-input {
  flex: 1;
  min-width: 200px;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.search-input:focus {
  outline: none;
  border-color: #007bff;
}

.filter-select {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  background: white;
  min-width: 150px;
}

.filter-select:focus {
  outline: none;
  border-color: #007bff;
}

.filter-btn {
  padding: 8px 16px;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.filter-btn:hover {
  background: #0056b3;
}

.filter-btn.btn-secondary {
  background: #6c757d;
  margin-left: 8px;
}

.filter-btn.btn-secondary:hover {
  background: #545b62;
}

.content-area {
  min-height: 400px;
}

.loading,
.error,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
}

.loading i,
.error i,
.empty-state i {
  font-size: 3rem;
  margin-bottom: 16px;
  color: #9ca3af;
}

.error i {
  color: #ef4444;
}

.empty-state i {
  color: #6b7280;
}

.loading p,
.error p,
.empty-state p {
  margin: 8px 0;
  color: #6b7280;
}

.empty-state h3 {
  margin: 0 0 8px 0;
  color: #374151;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn:hover:not(:disabled) {
  transform: translateY(-1px);
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.btn-primary {
  background: #3b82f6;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #2563eb;
}

.btn-secondary {
  background: #6b7280;
  color: white;
}

.btn-secondary:hover:not(:disabled) {
  background: #4b5563;
}

.btn-success {
  background: #10b981;
  color: white;
}

.btn-success:hover:not(:disabled) {
  background: #059669;
}

.btn-warning {
  background: #f59e0b;
  color: white;
}

.btn-warning:hover:not(:disabled) {
  background: #d97706;
}

.btn-danger {
  background: #ef4444;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background: #dc2626;
}

.btn-sm {
  padding: 6px 12px;
  font-size: 0.8rem;
}

.products-management {
  background: white;
  border: 1px solid #ddd;
  border-radius: 8px;
  overflow: hidden;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #ddd;
  background: #f8f9fa;
}

.branch-info h3 {
  margin: 0 0 8px 0;
  color: #333;
  font-size: 18px;
}

.product-controls {
  display: flex;
  align-items: center;
  gap: 20px;
}

.product-count {
  font-size: 14px;
  color: #666;
}

.select-all-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #666;
  cursor: pointer;
}

.bulk-actions {
  background: white;
  border: 1px solid #ddd;
  border-radius: 8px;
  margin-top: 20px;
  padding: 16px 20px;
}

.bulk-actions-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.selected-count {
  font-size: 14px;
  color: #666;
  font-weight: 500;
}

.bulk-buttons {
  display: flex;
  gap: 12px;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.modal-content {
  background: white;
  border-radius: 8px;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  padding: 20px 20px 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-title {
  margin: 0;
  font-size: 18px;
  color: #333;
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #666;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-close:hover {
  color: #333;
}

.modal-body {
  padding: 20px;
}


.product-stats {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}

.stat-item {
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
}

.stat-item.added {
  background: #d1fae5;
  color: #065f46;
  border: 1px solid #a7f3d0;
}

.stat-item.not-added {
  background: #fee2e2;
  color: #991b1b;
  border: 1px solid #fecaca;
}

.stat-item.total {
  background: #dbeafe;
  color: #1e40af;
  border: 1px solid #bfdbfe;
}

.products-layout {
  display: flex;
  margin-top: 20px;
  width: 100%;
  overflow-x: auto;
}

.products-column {
  flex: 1;
  background: white;
  border-radius: 8px;
  border: 1px solid #ddd;
  overflow: hidden;
  min-width: 400px;
}

.not-added-column {
  flex: 0 0 40%;
  min-width: 350px;
}

.added-column {
  flex: 0 0 60%;
  min-width: 450px;
}

.column-header {
  background: #f8f9fa;
  padding: 15px 20px;
  border-bottom: 1px solid #ddd;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.column-header h4 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #333;
}

.column-header .count {
  background: #007bff;
  color: white;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
}

.not-added-column .column-header {
  background: #f8d7da;
  border-bottom-color: #f5c6cb;
}

.not-added-column .column-header h4 {
  color: #721c24;
}

.not-added-column .column-header .count {
  background: #dc3545;
}

.added-column .column-header {
  background: #d4edda;
  border-bottom-color: #c3e6cb;
}

.added-column .column-header h4 {
  color: #155724;
}

.added-column .column-header .count {
  background: #28a745;
}

.product-list {
  display: flex;
  flex-direction: column;
  gap: 1px;
  background: #f5f5f5;
  border-radius: 4px;
  overflow: hidden;
}

.table-header {
  display: flex;
  align-items: center;
  background: #e9ecef;
  padding: 12px 8px;
  border-bottom: 2px solid #dee2e6;
  font-weight: 600;
  font-size: 13px;
  color: #495057;
  gap: 4px;
}

.header-checkbox {
  flex: 0 0 20px;
}

.header-image {
  flex: 0 0 60px;
}

.header-name {
  flex: 0 0 120px;
}

.header-category {
  flex: 0 0 80px;
}

.header-price {
  flex: 0 0 80px;
}

.header-branch-price {
  flex: 0 0 150px;
}

.header-actions {
  flex: 0 0 auto;
  min-width: 100px;
}

.product-item {
  display: flex;
  align-items: center;
  background: white;
  padding: 12px 8px;
  border-bottom: 1px solid #eee;
  transition: all 0.2s ease;
  gap: 4px;
}

.product-item:last-child {
  border-bottom: none;
}

.product-item:hover {
  background: #f8f9fa;
}

.product-item.added {
  border-left: 4px solid #28a745;
}

.product-item.not-added {
  border-left: 4px solid #dc3545;
}

.product-item.all-products {
  border-left: 4px solid #007bff;
}

.all-products-layout {
  margin-top: 20px;
}

.header-status {
  flex: 0 0 100px;
}

.product-checkbox {
  flex: 0 0 20px;
}

.product-checkbox input[type="checkbox"] {
  margin: 0;
}

.product-image {
  flex: 0 0 auto;
  width: 60px;
  height: 60px;
  border-radius: 6px;
  overflow: hidden;
  border: 1px solid #ddd;
}

.product-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.product-name {
  flex: 0 0 120px;
  font-weight: 600;
  font-size: 14px;
  color: #333;
}

.product-category {
  flex: 0 0 80px;
  font-size: 12px;
  color: #666;
}

.product-price {
  flex: 0 0 80px;
  font-size: 13px;
  color: #007bff;
  font-weight: 500;
}

.branch-price {
  flex: 0 0 150px;
  font-size: 12px;
  color: #28a745;
  font-weight: 500;
}

.product-status {
  flex: 0 0 auto;
  min-width: 100px;
}

.status-added {
  background: #d4edda;
  color: #155724;
  padding: 6px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  border: 1px solid #c3e6cb;
}

.status-not-added {
  background: #f8d7da;
  color: #721c24;
  padding: 6px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  border: 1px solid #f5c6cb;
}

.product-actions {
  flex: 0 0 auto;
  min-width: 100px;
  display: flex;
  gap: 8px;
}

.product-actions button {
  padding: 6px 12px;
  border: 1px solid #ddd;
  background: white;
  color: #333;
  border-radius: 6px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 500;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.product-actions button:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.product-actions button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.product-actions .btn-success {
  background: #28a745 !important;
  color: white !important;
  border-color: #28a745 !important;
}

.product-actions .btn-success:hover:not(:disabled) {
  background: #218838 !important;
  border-color: #218838 !important;
}

.product-actions .btn-warning {
  background: #ffc107 !important;
  color: #212529 !important;
  border-color: #ffc107 !important;
}

.product-actions .btn-warning:hover:not(:disabled) {
  background: #e0a800 !important;
  border-color: #e0a800 !important;
}

.product-actions .btn-danger {
  background: #dc3545 !important;
  color: white !important;
  border-color: #dc3545 !important;
}

.product-actions .btn-danger:hover:not(:disabled) {
  background: #c82333 !important;
  border-color: #c82333 !important;
}

@media (max-width: 768px) {
  .header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }

  .search-row {
    flex-direction: column;
    gap: 12px;
  }

  .search-input,
  .filter-select {
    width: 100%;
    min-width: auto;
  }

  .section-header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }

  .product-controls {
    justify-content: space-between;
  }

  .products-layout {
    flex-direction: column;
    gap: 20px;
  }
  
  .not-added-column,
  .added-column {
    flex: 1;
    min-width: auto;
  }
  
  .product-item {
    flex-direction: column;
    align-items: flex-start;
    padding: 16px;
    gap: 12px;
  }
  
  .product-checkbox {
    flex: none;
    margin-bottom: 8px;
  }
  
  .product-image {
    flex: none;
    width: 60px;
    height: 60px;
    margin-bottom: 8px;
  }
  
  .product-name,
  .product-category,
  .product-price,
  .branch-price {
    flex: none;
    width: 100%;
    margin-bottom: 4px;
  }
  
  .product-actions {
    flex: none;
    width: 100%;
    justify-content: flex-end;
  }
  
  .product-actions button {
    padding: 8px 12px;
    font-size: 13px;
  }

  .bulk-actions-content {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }

  .bulk-buttons {
    justify-content: center;
    flex-wrap: wrap;
  }

  .modal-overlay {
    padding: 10px;
  }

  .modal-content {
    max-width: none;
  }
}
</style>

