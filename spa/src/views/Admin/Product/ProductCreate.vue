<template>
  <div class="product-create">
    <!-- Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <nav aria-label="breadcrumb">
          <ol class="breadcrumb">
            <li class="breadcrumb-item">
              <router-link to="/admin/products">Products</router-link>
            </li>
            <li class="breadcrumb-item active" aria-current="page">
              Create Product
            </li>
          </ol>
        </nav>
        <h2 class="mb-1">
          <i class="bi bi-plus-circle"></i> Create New Product
        </h2>
        <p class="text-muted mb-0">Add a new product to your inventory</p>
      </div>
      <router-link to="/admin/products" class="btn btn-secondary">
        <i class="bi bi-arrow-left"></i> Back to Products
      </router-link>
    </div>

    <!-- Create Form -->
    <div class="row justify-content-center">
      <div class="col-lg-8">
        <div class="card">
          <div class="card-header">
            <h5 class="card-title mb-0">
              <i class="bi bi-box"></i> Product Information
            </h5>
          </div>
          <div class="card-body">
            <ProductForm 
              :product="duplicateProduct"
              :categories="categories"
              :loading="loading"
              @submit="handleSubmit"
              @cancel="handleCancel"
            />
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

const route = useRoute();
const router = useRouter();

// Reactive data
const categories = ref([]);
const duplicateProduct = ref(null);
const loading = ref(false);

// Toast notifications
const toasts = ref([]);
let toastId = 0;

// Load categories
const loadCategories = () => {
  categories.value = [
    { id: 1, name: 'Điện thoại' },
    { id: 2, name: 'Laptop' }
  ];
};

// Load duplicate product if needed
const loadDuplicateProduct = async () => {
  const duplicateId = route.query.duplicate;
  if (duplicateId) {
    try {
      const response = await ProductService.getProduct(duplicateId);
      const product = response.data;
      
      // Create duplicate data without ID
      duplicateProduct.value = {
        name: `${product.name} (Copy)`,
        category_id: product.category_id,
        price: product.price,
        stock: product.stock,
        description: product.description
      };
    } catch (error) {
      showToast('Error', 'Failed to load product for duplication', 'danger');
    }
  }
};

// Handle form submit
const handleSubmit = async (formData) => {
  loading.value = true;
  try {
    await ProductService.createProduct(formData);
    showToast('Success', 'Product created successfully', 'success');
    
    // Redirect to products list after a short delay
    setTimeout(() => {
      router.push('/admin/products');
    }, 1500);
  } catch (error) {
    showToast('Error', error.message, 'danger');
  } finally {
    loading.value = false;
  }
};

// Handle cancel
const handleCancel = () => {
  router.push('/admin/products');
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
  loadDuplicateProduct();
});
</script>

<style scoped>
.product-create {
  padding: 20px;
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
</style> 