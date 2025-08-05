<template>
  <div class="product-detail">
    <!-- Loading -->
    <LoadingSpinner v-if="loading" />

    <!-- Product Details -->
    <div v-else-if="product" class="container-fluid">
      <!-- Header -->
      <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
          <nav aria-label="breadcrumb">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                <router-link to="/admin/products">Products</router-link>
              </li>
              <li class="breadcrumb-item active" aria-current="page">
                {{ product.name }}
              </li>
            </ol>
          </nav>
          <h2 class="mb-1">
            <i class="bi bi-box"></i> {{ product.name }}
          </h2>
        </div>
        <div class="d-flex gap-2">
          <button 
            @click="handleEdit" 
            class="btn btn-warning"
          >
            <i class="bi bi-pencil"></i> Edit
          </button>
          <button 
            @click="handleDelete" 
            class="btn btn-danger"
          >
            <i class="bi bi-trash"></i> Delete
          </button>
        </div>
      </div>

      <!-- Product Info -->
      <div class="row">
        <div class="col-lg-8">
          <div class="card">
            <div class="card-header">
              <h5 class="card-title mb-0">
                <i class="bi bi-info-circle"></i> Product Information
              </h5>
            </div>
            <div class="card-body">
              <div class="row">
                <div class="col-md-6">
                  <div class="mb-3">
                    <label class="form-label fw-bold">Product Name</label>
                    <p class="form-control-plaintext">{{ product.name }}</p>
                  </div>
                </div>
                <div class="col-md-6">
                  <div class="mb-3">
                    <label class="form-label fw-bold">Category</label>
                    <p class="form-control-plaintext">{{ product.category_name }}</p>
                  </div>
                </div>
              </div>
              
              <div class="row">
                <div class="col-md-6">
                  <div class="mb-3">
                    <label class="form-label fw-bold">Price</label>
                    <p class="form-control-plaintext text-primary fw-bold fs-5">
                      {{ formatPrice(product.price) }} VNĐ
                    </p>
                  </div>
                </div>
                <div class="col-md-6">
                  <div class="mb-3">
                    <label class="form-label fw-bold">Stock</label>
                    <p class="form-control-plaintext">
                      <span class="badge" :class="getStockBadgeClass()">
                        {{ product.stock }} in stock
                      </span>
                    </p>
                  </div>
                </div>
              </div>
              
              <div class="row">
                <div class="col-md-6">
                  <div class="mb-3">
                    <label class="form-label fw-bold">Seller</label>
                    <p class="form-control-plaintext">{{ product.seller_name }}</p>
                  </div>
                </div>
                <div class="col-md-6">
                  <div class="mb-3">
                    <label class="form-label fw-bold">Created Date</label>
                    <p class="form-control-plaintext">{{ formatDate(product.created_at) }}</p>
                  </div>
                </div>
              </div>
              
              <div class="mb-3">
                <label class="form-label fw-bold">Description</label>
                <p class="form-control-plaintext">
                  {{ product.description || 'No description available' }}
                </p>
              </div>
            </div>
          </div>
        </div>
        
        <div class="col-lg-4">
          <!-- Quick Stats -->
          <div class="card mb-3">
            <div class="card-header">
              <h6 class="card-title mb-0">
                <i class="bi bi-graph-up"></i> Quick Stats
              </h6>
            </div>
            <div class="card-body">
              <div class="d-flex justify-content-between mb-2">
                <span>Stock Status:</span>
                <span :class="getStockStatusClass()">{{ getStockStatus() }}</span>
              </div>
              <div class="d-flex justify-content-between mb-2">
                <span>Price Range:</span>
                <span>{{ getPriceRange() }}</span>
              </div>
              <div class="d-flex justify-content-between">
                <span>Category:</span>
                <span>{{ product.category_name }}</span>
              </div>
            </div>
          </div>
          
          <!-- Actions -->
          <div class="card">
            <div class="card-header">
              <h6 class="card-title mb-0">
                <i class="bi bi-gear"></i> Actions
              </h6>
            </div>
            <div class="card-body">
              <div class="d-grid gap-2">
                <button 
                  @click="handleEdit" 
                  class="btn btn-warning"
                >
                  <i class="bi bi-pencil"></i> Edit Product
                </button>
                <button 
                  @click="handleDuplicate" 
                  class="btn btn-info"
                >
                  <i class="bi bi-files"></i> Duplicate
                </button>
                <button 
                  @click="handleDelete" 
                  class="btn btn-danger"
                >
                  <i class="bi bi-trash"></i> Delete Product
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Not Found -->
    <div v-else class="text-center py-5">
      <i class="bi bi-exclamation-triangle display-1 text-warning"></i>
      <h4 class="mt-3 text-muted">Product not found</h4>
      <p class="text-muted">The product you're looking for doesn't exist or has been deleted.</p>
      <router-link to="/admin/products" class="btn btn-primary">
        <i class="bi bi-arrow-left"></i> Back to Products
      </router-link>
    </div>

    <!-- Edit Modal -->
    <div 
      v-if="showEditModal" 
      class="modal fade show d-block" 
      tabindex="-1"
      style="background-color: rgba(0,0,0,0.5);"
    >
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Edit Product</h5>
            <button 
              @click="showEditModal = false" 
              type="button" 
              class="btn-close"
            ></button>
          </div>
          <div class="modal-body">
            <ProductForm 
              :product="product"
              :categories="categories"
              :loading="formLoading"
              @submit="handleFormSubmit"
              @cancel="showEditModal = false"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div 
      v-if="showDeleteModal" 
      class="modal fade show d-block" 
      tabindex="-1"
      style="background-color: rgba(0,0,0,0.5);"
    >
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Confirm Delete</h5>
            <button 
              @click="showDeleteModal = false" 
              type="button" 
              class="btn-close"
            ></button>
          </div>
          <div class="modal-body">
            <p>Are you sure you want to delete "<strong>{{ product?.name }}</strong>"?</p>
            <p class="text-danger small">This action cannot be undone.</p>
          </div>
          <div class="modal-footer">
            <button 
              @click="showDeleteModal = false" 
              type="button" 
              class="btn btn-secondary"
            >
              Cancel
            </button>
            <button 
              @click="confirmDelete" 
              type="button" 
              class="btn btn-danger"
              :disabled="deleteLoading"
            >
              <span v-if="deleteLoading" class="spinner-border spinner-border-sm me-2"></span>
              Delete
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Toast Notifications -->
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
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import ProductService from '@/services/ProductService';
import ProductForm from '@/components/Admin/Product/ProductForm.vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';

const route = useRoute();
const router = useRouter();

// Reactive data
const product = ref(null);
const categories = ref([]);
const loading = ref(false);
const formLoading = ref(false);
const deleteLoading = ref(false);

// Modal states
const showEditModal = ref(false);
const showDeleteModal = ref(false);

// Toast notifications
const toasts = ref([]);
let toastId = 0;

// Load product
const loadProduct = async () => {
  loading.value = true;
  try {
    const response = await ProductService.getProduct(route.params.id);
    product.value = response.data;
  } catch (error) {
    showToast('Error', error.message, 'danger');
    product.value = null;
  } finally {
    loading.value = false;
  }
};

// Load categories
const loadCategories = () => {
  categories.value = [
    { id: 1, name: 'Điện thoại' },
    { id: 2, name: 'Laptop' }
  ];
};

// Format price
const formatPrice = (price) => {
  return new Intl.NumberFormat('vi-VN').format(price);
};

// Format date
const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('vi-VN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// Get stock badge class
const getStockBadgeClass = () => {
  const stock = product.value.stock;
  if (stock === 0) return 'bg-danger';
  if (stock <= 5) return 'bg-warning';
  return 'bg-success';
};

// Get stock status
const getStockStatus = () => {
  const stock = product.value.stock;
  if (stock === 0) return 'Out of Stock';
  if (stock <= 5) return 'Low Stock';
  return 'In Stock';
};

// Get stock status class
const getStockStatusClass = () => {
  const stock = product.value.stock;
  if (stock === 0) return 'text-danger';
  if (stock <= 5) return 'text-warning';
  return 'text-success';
};

// Get price range
const getPriceRange = () => {
  const price = product.value.price;
  if (price < 1000000) return 'Budget';
  if (price < 10000000) return 'Mid-range';
  return 'Premium';
};

// Handle edit
const handleEdit = () => {
  showEditModal.value = true;
};

// Handle delete
const handleDelete = () => {
  showDeleteModal.value = true;
};

// Handle duplicate
const handleDuplicate = () => {
  // Navigate to create page with pre-filled data
  router.push({
    path: '/admin/products/create',
    query: { 
      duplicate: product.value.id 
    }
  });
};

// Handle form submit
const handleFormSubmit = async (formData) => {
  formLoading.value = true;
  try {
    await ProductService.updateProduct(product.value.id, formData);
    showToast('Success', 'Product updated successfully', 'success');
    showEditModal.value = false;
    loadProduct(); // Reload product data
  } catch (error) {
    showToast('Error', error.message, 'danger');
  } finally {
    formLoading.value = false;
  }
};

// Confirm delete
const confirmDelete = async () => {
  deleteLoading.value = true;
  try {
    await ProductService.deleteProduct(product.value.id);
    showToast('Success', 'Product deleted successfully', 'success');
    showDeleteModal.value = false;
    router.push('/admin/products');
  } catch (error) {
    showToast('Error', error.message, 'danger');
  } finally {
    deleteLoading.value = false;
  }
};

// Show toast notification
const showToast = (title, message, type = 'info') => {
  const toast = {
    id: ++toastId,
    title,
    message,
    type: `bg-${type} text-white`
  };
  
  toasts.value.push(toast);
  
  // Auto remove after 5 seconds
  setTimeout(() => {
    removeToast(toast.id);
  }, 5000);
};

// Remove toast
const removeToast = (id) => {
  const index = toasts.value.findIndex(toast => toast.id === id);
  if (index > -1) {
    toasts.value.splice(index, 1);
  }
};

// Initialize
onMounted(() => {
  loadCategories();
  loadProduct();
});
</script>

<style scoped>
.product-detail {
  padding: 20px;
}

.modal {
  z-index: 1050;
}

.toast-container {
  z-index: 1060;
}

.breadcrumb a {
  text-decoration: none;
  color: #0d6efd;
}

.breadcrumb a:hover {
  text-decoration: underline;
}

.form-control-plaintext {
  padding: 0.375rem 0;
  margin-bottom: 0;
  color: #212529;
  background-color: transparent;
  border: solid transparent;
  border-width: 1px 0;
}
</style> 