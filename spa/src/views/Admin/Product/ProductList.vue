<template>
  <div class="product-list">
    <!-- Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h2 class="mb-1">
          <i class="bi bi-box"></i> Products Management
        </h2>
        <p class="text-muted mb-0">Manage your products inventory</p>
      </div>
      <button 
        @click="showCreateModal = true" 
        class="btn btn-primary"
      >
        <i class="bi bi-plus-circle"></i> Add Product
      </button>
    </div>

    <!-- Filter -->
    <ProductFilter 
      @filter="handleFilter"
      @clear="handleClearFilter"
    />

    <!-- Loading -->
    <LoadingSpinner v-if="loading" />

    <!-- Products Grid -->
    <div v-else-if="products.length > 0" class="row">
      <div 
        v-for="product in products" 
        :key="product.id" 
        class="col-lg-4 col-md-6 col-sm-12 mb-4"
      >
        <ProductCard 
          :product="product"
          @view="handleViewProduct"
          @edit="handleEditProduct"
          @delete="handleDeleteProduct"
        />
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="text-center py-5">
      <i class="bi bi-box display-1 text-muted"></i>
      <h4 class="mt-3 text-muted">No products found</h4>
      <p class="text-muted">Start by adding your first product</p>
      <button 
        @click="showCreateModal = true" 
        class="btn btn-primary"
      >
        <i class="bi bi-plus-circle"></i> Add Product
      </button>
    </div>

    <!-- Pagination -->
    <div v-if="metadata && metadata.totalPages > 1" class="d-flex justify-content-center mt-4">
      <nav>
        <ul class="pagination">
          <li class="page-item" :class="{ disabled: metadata.currentPage === 1 }">
            <button 
              @click="changePage(metadata.currentPage - 1)" 
              class="page-link"
              :disabled="metadata.currentPage === 1"
            >
              Previous
            </button>
          </li>
          
          <li 
            v-for="page in getPageNumbers()" 
            :key="page"
            class="page-item"
            :class="{ active: page === metadata.currentPage }"
          >
            <button @click="changePage(page)" class="page-link">
              {{ page }}
            </button>
          </li>
          
          <li class="page-item" :class="{ disabled: metadata.currentPage === metadata.totalPages }">
            <button 
              @click="changePage(metadata.currentPage + 1)" 
              class="page-link"
              :disabled="metadata.currentPage === metadata.totalPages"
            >
              Next
            </button>
          </li>
        </ul>
      </nav>
    </div>

    <!-- Create/Edit Modal -->
    <div 
      v-if="showCreateModal || showEditModal" 
      class="modal fade show d-block" 
      tabindex="-1"
      style="background-color: rgba(0,0,0,0.5);"
    >
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              {{ showEditModal ? 'Edit Product' : 'Add New Product' }}
            </h5>
            <button 
              @click="closeModal" 
              type="button" 
              class="btn-close"
            ></button>
          </div>
          <div class="modal-body">
            <ProductForm 
              :product="editingProduct"
              :loading="formLoading"
              @submit="handleFormSubmit"
              @cancel="closeModal"
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
            <p>Are you sure you want to delete "<strong>{{ deletingProduct?.name }}</strong>"?</p>
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
import { ref, reactive, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import ProductService from '@/services/ProductService';
import CategoryService from '@/services/CategoryService';
import ProductCard from '@/components/Admin/Product/ProductCard.vue';
import ProductForm from '@/components/Admin/Product/ProductForm.vue';
import ProductFilter from '@/components/Admin/Product/ProductFilter.vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';

const router = useRouter();

// Reactive data
const products = ref([]);
const categories = ref([]);
const metadata = ref(null);
const loading = ref(false);
const formLoading = ref(false);
const deleteLoading = ref(false);

// Modal states
const showCreateModal = ref(false);
const showEditModal = ref(false);
const showDeleteModal = ref(false);
const editingProduct = ref(null);
const deletingProduct = ref(null);

// Filters
const currentFilters = reactive({
  page: 1,
  limit: 10
});

// Toast notifications
const toasts = ref([]);
let toastId = 0;

// Load products
const loadProducts = async () => {
  loading.value = true;
  try {
    console.log('Loading products with filters:', currentFilters); // Debug log
    const response = await ProductService.getProducts(currentFilters);
    console.log('API response:', response); // Debug log
    products.value = response.data.products;
    metadata.value = response.data.metadata;
  } catch (error) {
    console.error('Error loading products:', error); // Debug log
    showToast('Error', error.message, 'danger');
  } finally {
    loading.value = false;
  }
};

// Load categories
const loadCategories = async () => {
  try {
    const response = await CategoryService.getAllCategories();
    categories.value = response.data || [];
  } catch (error) {
    console.error('Error loading categories:', error);
    categories.value = [];
  }
};

// Handle filter
const handleFilter = (filters) => {
  console.log('Received filters:', filters); // Debug log
  
  // Clear all existing filters first
  Object.keys(currentFilters).forEach(key => {
    if (key !== 'page' && key !== 'limit') {
      delete currentFilters[key];
    }
  });
  
  // Then apply new filters
  Object.assign(currentFilters, filters);
  currentFilters.page = 1; // Reset to first page
  
  console.log('Current filters after merge:', currentFilters); // Debug log
  loadProducts();
};

// Handle clear filter
const handleClearFilter = () => {
  // Reset to default values
  currentFilters.page = 1;
  currentFilters.limit = 10;
  
  // Remove all other filters
  Object.keys(currentFilters).forEach(key => {
    if (key !== 'page' && key !== 'limit') {
      delete currentFilters[key];
    }
  });
  
  console.log('Cleared filters:', currentFilters); // Debug log
  loadProducts();
};

// Change page
const changePage = (page) => {
  currentFilters.page = page;
  loadProducts();
};

// Get page numbers for pagination
const getPageNumbers = () => {
  if (!metadata.value) return [];
  
  const pages = [];
  const start = Math.max(1, metadata.value.currentPage - 2);
  const end = Math.min(metadata.value.totalPages, metadata.value.currentPage + 2);
  
  for (let i = start; i <= end; i++) {
    pages.push(i);
  }
  
  return pages;
};

// Handle view product
const handleViewProduct = (product) => {
  router.push(`/admin/products/${product.id}`);
};

// Handle edit product
const handleEditProduct = (product) => {
  editingProduct.value = product;
  showEditModal.value = true;
};

// Handle delete product
const handleDeleteProduct = (product) => {
  deletingProduct.value = product;
  showDeleteModal.value = true;
};

// Handle form submit
const handleFormSubmit = async (formData) => {
  formLoading.value = true;
  try {
    if (showEditModal.value) {
      await ProductService.updateProduct(editingProduct.value.id, formData);
      showToast('Success', 'Product updated successfully', 'success');
    } else {
      await ProductService.createProduct(formData);
      showToast('Success', 'Product created successfully', 'success');
    }
    
    closeModal();
    loadProducts();
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
    await ProductService.deleteProduct(deletingProduct.value.id);
    showToast('Success', 'Product deleted successfully', 'success');
    showDeleteModal.value = false;
    loadProducts();
  } catch (error) {
    showToast('Error', error.message, 'danger');
  } finally {
    deleteLoading.value = false;
  }
};

// Close modal
const closeModal = () => {
  showCreateModal.value = false;
  showEditModal.value = false;
  editingProduct.value = null;
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
onMounted(async () => {
  await loadCategories();
  loadProducts();
});
</script>

<style scoped>
.product-list {
  padding: 20px;
}

.modal {
  z-index: 1050;
}

.toast-container {
  z-index: 1060;
}

.pagination .page-link {
  color: #0d6efd;
}

.pagination .page-item.active .page-link {
  background-color: #0d6efd;
  border-color: #0d6efd;
}
</style> 