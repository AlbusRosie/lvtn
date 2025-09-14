<template>
  <div class="menu-page">
    <div class="header">
      <h1>Quản lý Menu</h1>
      <div class="actions">
        <button @click="showAddProductModal = true" class="btn-add">+ Thêm sản phẩm</button>
        <button @click="refreshData" class="btn-refresh" :disabled="loading">Làm mới</button>
      </div>
    </div>

    <div class="controls">
      <div class="control-group">
        <label>Chi nhánh:</label>
        <select v-model="selectedBranchId" @change="onBranchChange" class="select">
          <option value="">-- Chọn chi nhánh --</option>
          <option v-for="branch in branches" :key="branch.id" :value="branch.id">
            {{ branch.name }}
          </option>
        </select>
      </div>
      
      <div class="control-group">
        <label>Danh mục:</label>
        <select v-model="filters.category" class="select">
          <option value="">Tất cả</option>
          <option v-for="category in categories" :key="category.id" :value="category.id">
            {{ category.name }}
          </option>
        </select>
      </div>
      
      <div class="control-group">
        <label>Trạng thái:</label>
        <select v-model="filters.status" class="select">
          <option value="">Tất cả</option>
          <option value="available">Có sẵn</option>
          <option value="out_of_stock">Hết hàng</option>
          <option value="temporarily_unavailable">Tạm ngừng</option>
          <option value="discontinued">Ngừng bán</option>
          <option value="not_added">Chưa thêm</option>
        </select>
      </div>
      
      <button @click="applyFilters" class="btn-filter">Lọc</button>
    </div>

    <div class="products-section" v-if="selectedBranchId">
      <div class="section-header">
        <h3>Danh sách sản phẩm</h3>
        <div class="search-box">
          <input 
            type="text" 
            v-model="searchQuery"
            placeholder="Tìm kiếm..."
            class="search-input"
          >
          <button @click="applyFilters" class="btn-search">Tìm</button>
        </div>
      </div>
      
      <div class="products-content">
        <div v-if="loading" class="loading">Đang tải...</div>
        <div v-else-if="products.length === 0" class="empty">Không có sản phẩm nào</div>
        <div class="d-flex justify-content-between align-items-center mb-3">
          <div class="btn-group" role="group">
            <button 
              type="button" 
              class="btn btn-outline-primary"
              :class="{ 'active': viewMode === 'cards' }"
              @click="viewMode = 'cards'"
            >
              <i class="bi bi-grid-3x3-gap"></i> Thẻ
            </button>
            <button 
              type="button" 
              class="btn btn-outline-primary"
              :class="{ 'active': viewMode === 'table' }"
              @click="viewMode = 'table'"
            >
              <i class="bi bi-table"></i> Bảng
            </button>
          </div>
          <div class="d-flex align-items-center gap-2">
            <span class="text-muted">Hiển thị {{ products.length }} sản phẩm</span>
            <div class="form-check">
              <input 
                type="checkbox" 
                v-model="selectAll"
                @change="toggleSelectAll"
                class="form-check-input"
                id="selectAll"
              >
              <label class="form-check-label" for="selectAll">
                Chọn tất cả
              </label>
            </div>
          </div>
        </div>

        <div v-if="viewMode === 'cards'" class="row">
          <div 
            v-for="product in products" 
            :key="product.id"
            class="col-lg-4 col-md-6 col-sm-12"
          >
            <ProductCard
              :product="product"
              :loading="loading"
              :selected="selectedProducts.includes(product.id)"
              @select="onProductSelect"
              @add-to-branch="addProductToBranch"
              @edit="editBranchProduct"
              @remove="removeProductFromBranch"
              @update-price="updateBranchPrice"
            />
          </div>
        </div>

        <div v-else class="table-responsive">
          <table class="table table-hover mb-0">
            <thead class="table-light">
              <tr>
                <th width="50">
                  <input 
                    type="checkbox" 
                    v-model="selectAll"
                    @change="toggleSelectAll"
                    class="form-check-input"
                  >
                </th>
                <th width="80">Hình ảnh</th>
                <th>Tên sản phẩm</th>
                <th>Danh mục</th>
                <th>Giá gốc</th>
                <th>Giá chi nhánh</th>
                <th>Trạng thái</th>
                <th width="120">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="product in products" :key="product.id">
                <td>
                  <input 
                    type="checkbox" 
                    v-model="selectedProducts"
                    :value="product.id"
                    class="form-check-input"
                  >
                </td>
                <td>
                  <img 
                    :src="product.image || DEFAULT_PRODUCT_IMAGE" 
                    :alt="product.name"
                    class="img-thumbnail"
                    style="width: 50px; height: 50px; object-fit: cover;"
                    @error="handleImageError"
                  >
                </td>
                <td>
                  <div>
                    <strong>{{ product.name }}</strong>
                    <br>
                    <small class="text-muted">{{ product.description }}</small>
                  </div>
                </td>
                <td>
                  <span class="badge bg-secondary">{{ product.category_name }}</span>
                </td>
                <td>
                  <span class="text-muted">{{ formatPrice(product.base_price) }}</span>
                </td>
                <td>
                  <div v-if="product.branch_product_id">
                    <input 
                      type="number" 
                      v-model="product.branch_price"
                      class="form-control form-control-sm"
                      style="width: 100px; display: inline-block;"
                      @blur="updateBranchPrice(product)"
                    >
                    <small class="text-muted d-block">{{ formatPrice(product.branch_price) }}</small>
                  </div>
                  <span v-else class="text-muted">Chưa thêm</span>
                </td>
                <td>
                  <span 
                    class="badge"
                    :class="getStatusBadgeClass(product.final_status)"
                  >
                    {{ getStatusText(product.final_status) }}
                  </span>
                </td>
                <td>
                  <div class="btn-group btn-group-sm">
                    <button 
                      v-if="!product.branch_product_id"
                      class="btn btn-success btn-sm"
                      @click="addProductToBranch(product)"
                      :disabled="loading"
                    >
                      <i class="bi bi-plus"></i>
                    </button>
                    <button 
                      v-else
                      class="btn btn-warning btn-sm"
                      @click="editBranchProduct(product)"
                    >
                      <i class="bi bi-pencil"></i>
                    </button>
                    <button 
                      v-if="product.branch_product_id"
                      class="btn btn-danger btn-sm"
                      @click="removeProductFromBranch(product)"
                      :disabled="loading"
                    >
                      <i class="bi bi-trash"></i>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div v-if="selectedProducts.length > 0" class="card mt-3">
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-center">
          <span class="text-muted">
            Đã chọn {{ selectedProducts.length }} sản phẩm
          </span>
          <div class="btn-group">
            <button 
              class="btn btn-success btn-sm"
              @click="bulkAddToBranch"
              :disabled="loading"
            >
              <i class="bi bi-plus"></i> Thêm vào chi nhánh
            </button>
            <button 
              class="btn btn-warning btn-sm"
              @click="bulkUpdateStatus"
              :disabled="loading"
            >
              <i class="bi bi-pencil"></i> Cập nhật trạng thái
            </button>
            <button 
              class="btn btn-danger btn-sm"
              @click="bulkRemoveFromBranch"
              :disabled="loading"
            >
              <i class="bi bi-trash"></i> Xóa khỏi chi nhánh
            </button>
          </div>
        </div>
      </div>
    </div>

    <div 
      class="modal fade" 
      :class="{ 'show': showAddProductModal }"
      :style="{ display: showAddProductModal ? 'block' : 'none' }"
      tabindex="-1"
    >
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              <i class="bi bi-plus-circle"></i> Thêm sản phẩm vào menu
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
    </div>

    <div 
      v-if="showEditModal && editingProduct && selectedBranch"
      class="modal fade show d-block"
      tabindex="-1"
      style="background-color: rgba(0,0,0,0.5);"
    >
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              <i class="bi bi-pencil"></i> Chỉnh sửa sản phẩm chi nhánh
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

    <div class="toast-container position-fixed bottom-0 end-0 p-3">
      <div
        v-for="toast in toasts"
        :key="toast.id"
        class="toast show"
        :class="toast.type"
      >
        <div class="toast-header">
          <strong class="me-auto">{{ toast.title }}</strong>
          <button
            @click="removeToast(toast.id)"
            type="button"
            class="btn-close"
          ></button>
        </div>
        <div class="toast-body">
          {{ toast.message }}
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

const toast = useToast()

const loading = ref(false)
const branches = ref([])
const categories = ref([])
const products = ref([])
const selectedBranchId = ref('')
const selectedProducts = ref([])
const selectAll = ref(false)
const searchQuery = ref('')
const showAddProductModal = ref(false)
const showEditModal = ref(false)
const editingProduct = ref(null)
const viewMode = ref('cards')

const filters = ref({
  category: '',
  status: ''
})

const toasts = ref([])
let toastId = 0

const selectedBranch = computed(() => {
  return branches.value.find(b => b.id == selectedBranchId.value)
})

const loadBranches = async () => {
  try {
    const data = await BranchService.getActiveBranches()
    branches.value = data
  } catch (error) {
    showToast('Lỗi', 'Không thể tải danh sách chi nhánh', 'danger')
  }
}

const loadCategories = async () => {
  try {
    const data = await ProductService.getCategories()
    categories.value = data
  } catch (error) {
    showToast('Lỗi', 'Không thể tải danh mục sản phẩm', 'danger')
  }
}

const loadProducts = async () => {
  if (!selectedBranchId.value) return
  
  loading.value = true
  try {
    const params = {
      branch_id: selectedBranchId.value,
      ...filters.value
    }
    if (searchQuery.value) {
      params.name = searchQuery.value
    }
    
    const data = await ProductService.getProducts(params)
    products.value = data.data?.products || data.products || []
  } catch (error) {
    showToast('Lỗi', 'Không thể tải danh sách sản phẩm', 'danger')
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
  showToast('Thông báo', 'Tính năng đang phát triển', 'info')
}

const applyFilters = () => {
  loadProducts()
}

const refreshData = () => {
  loadProducts()
}

const addProductToBranch = async (product) => {
  try {
    const branchProductData = {
      price: product.base_price,
      is_available: 1,
      status: 'available'
    }
    
    await ProductService.addProductToBranch(selectedBranchId.value, product.id, branchProductData)
    showToast('Thành công', `Đã thêm "${product.name}" vào chi nhánh`, 'success')
    loadProducts()
  } catch (error) {
    showToast('Lỗi', error.message, 'danger')
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
    showToast('Thành công', `Đã xóa "${product.name}" khỏi chi nhánh`, 'success')
    loadProducts()
  } catch (error) {
    showToast('Lỗi', error.message, 'danger')
  }
}

const updateBranchPrice = async (product) => {
  try {
    const updateData = {
      price: product.branch_price
    }
    
    await ProductService.updateBranchProduct(product.branch_product_id, updateData)
    showToast('Thành công', `Đã cập nhật giá "${product.name}"`, 'success')
  } catch (error) {
    showToast('Lỗi', error.message, 'danger')
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
    showToast('Lỗi', 'Vui lòng chọn chi nhánh', 'danger')
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
    showToast('Thành công', `Đã thêm ${selectedProducts.value.length} sản phẩm vào chi nhánh`, 'success')
    selectedProducts.value = []
    selectAll.value = false
    loadProducts()
  } catch (error) {
    showToast('Lỗi', error.message, 'danger')
  }
}

const bulkUpdateStatus = () => {
  showToast('Thông báo', 'Tính năng đang phát triển', 'info')
}

const bulkRemoveFromBranch = async () => {
  if (!confirm(`Bạn có chắc muốn xóa ${selectedProducts.value.length} sản phẩm khỏi chi nhánh?`)) return
  
  try {
    const promises = selectedProducts.value.map(productId => {
      return ProductService.removeProductFromBranch(selectedBranchId.value, productId)
    })
    
    await Promise.all(promises)
    showToast('Thành công', `Đã xóa ${selectedProducts.value.length} sản phẩm khỏi chi nhánh`, 'success')
    selectedProducts.value = []
    selectAll.value = false
    loadProducts()
  } catch (error) {
    showToast('Lỗi', error.message, 'danger')
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
    'discontinued': 'bg-secondary',
    'not_added': 'bg-light text-dark'
  }
  return classes[status] || 'bg-secondary'
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

const showToast = (title, message, type = 'info') => {
  const toast = {
    id: ++toastId,
    title,
    message,
    type: `bg-${type} text-white`
  }
  
  toasts.value.push(toast)
  
  setTimeout(() => {
    removeToast(toast.id)
  }, 5000)
}

const removeToast = (id) => {
  const index = toasts.value.findIndex(toast => toast.id === id)
  if (index > -1) {
    toasts.value.splice(index, 1)
  }
}

watch(selectedProducts, (newVal) => {
  selectAll.value = newVal.length === products.value.length && products.value.length > 0
})

onMounted(() => {
  loadBranches()
  loadCategories()
})
</script>

<style scoped>
.menu-page {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
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

.btn-add, .btn-refresh, .btn-filter, .btn-search {
  padding: 8px 16px;
  border: 1px solid #ccc;
  background: white;
  cursor: pointer;
  border-radius: 4px;
}

.btn-add {
  background: #007bff;
  color: white;
  border-color: #007bff;
}

.btn-add:hover {
  background: #0056b3;
}

.controls {
  display: flex;
  gap: 20px;
  margin-bottom: 30px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 4px;
}

.control-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.control-group label {
  font-weight: bold;
  color: #555;
}

.select {
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
  background: white;
}

.products-section {
  background: white;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  border-bottom: 1px solid #ddd;
  background: #f8f9fa;
}

.section-header h3 {
  margin: 0;
  color: #333;
}

.search-box {
  display: flex;
  gap: 10px;
}

.search-input {
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
  width: 200px;
}

.products-content {
  padding: 15px;
}

.loading, .empty {
  text-align: center;
  padding: 40px;
  color: #666;
}

.table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 15px;
}

.table th, .table td {
  padding: 12px;
  text-align: left;
  border-bottom: 1px solid #ddd;
}

.table th {
  background: #f8f9fa;
  font-weight: bold;
}

.table tr:hover {
  background: #f5f5f5;
}

.btn {
  padding: 6px 12px;
  border: 1px solid #ccc;
  background: white;
  cursor: pointer;
  border-radius: 4px;
  margin: 2px;
}

.btn:hover {
  background: #f5f5f5;
}

.btn-success {
  background: #28a745;
  color: white;
  border-color: #28a745;
}

.btn-warning {
  background: #ffc107;
  color: #212529;
  border-color: #ffc107;
}

.btn-danger {
  background: #dc3545;
  color: white;
  border-color: #dc3545;
}

.img-thumbnail {
  width: 50px;
  height: 50px;
  object-fit: cover;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: bold;
}

.bg-success { background: #28a745; color: white; }
.bg-danger { background: #dc3545; color: white; }
.bg-warning { background: #ffc107; color: #212529; }
.bg-secondary { background: #6c757d; color: white; }
.bg-light { background: #f8f9fa; color: #212529; }

.modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  padding: 20px;
  border-radius: 4px;
  max-width: 500px;
  width: 90%;
}

.toast-container {
  position: fixed;
  bottom: 20px;
  right: 20px;
  z-index: 1060;
}

.toast {
  background: #333;
  color: white;
  padding: 10px 15px;
  margin: 5px 0;
  border-radius: 4px;
}
</style>

