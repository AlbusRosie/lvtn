<template>
  <div class="product-create">
    <div class="header">
      <div class="breadcrumb">
        <router-link to="/admin/products/branch-menu">Menu Chi nhánh</router-link>
        <span> / </span>
        <span>Tạo sản phẩm mới</span>
      </div>
      <h1>Tạo sản phẩm mới</h1>
      <p class="subtitle">Thêm sản phẩm mới vào hệ thống</p>
    </div>

    <div class="form-container">
      <ProductForm
        :product="duplicateProduct"
        :categories="categories"
        :loading="loading"
        @submit="handleSubmit"
        @cancel="handleCancel"
      />
    </div>

  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useToast } from 'vue-toastification';
import ProductService from '@/services/ProductService';
import ProductForm from '@/components/Admin/Product/ProductForm.vue';

const route = useRoute();
const router = useRouter();
const toast = useToast();

const categories = ref([]);
const duplicateProduct = ref(null);
const loading = ref(false);

const loadCategories = () => {
  categories.value = [
    { id: 1, name: 'Điện thoại' },
    { id: 2, name: 'Laptop' }
  ];
};

const loadDuplicateProduct = async () => {
  const duplicateId = route.query.duplicate;
  if (duplicateId) {
    try {
      const response = await ProductService.getProduct(duplicateId);
      const product = response.data;

      duplicateProduct.value = {
        name: `${product.name} (Copy)`,
        category_id: product.category_id,
        price: product.price,
        stock: product.stock,
        description: product.description
      };
    } catch (error) {
      toast.error('Không thể tải sản phẩm để sao chép');
    }
  }
};

const handleSubmit = async (formData) => {
  loading.value = true;
  try {
    await ProductService.createProduct(formData);
    toast.success('Tạo sản phẩm thành công!');

    setTimeout(() => {
      router.push('/admin/products/branch-menu');
    }, 1500);
  } catch (error) {
    toast.error(error.message);
  } finally {
    loading.value = false;
  }
};

const handleCancel = () => {
  router.push('/admin/products/branch-menu');
};


onMounted(() => {
  loadCategories();
  loadDuplicateProduct();
});
</script>

<style scoped>
.product-create {
  padding: 20px;
}

.header {
  margin-bottom: 30px;
}

.breadcrumb {
  margin-bottom: 10px;
  font-size: 14px;
  color: #666;
}

.breadcrumb a {
  color: #007bff;
  text-decoration: none;
}

.breadcrumb a:hover {
  text-decoration: underline;
}

.header h1 {
  margin: 0 0 5px 0;
  font-size: 24px;
  color: #333;
}

.subtitle {
  margin: 0;
  color: #666;
  font-size: 14px;
}

.form-container {
  max-width: 800px;
  margin: 0 auto;
}

</style>