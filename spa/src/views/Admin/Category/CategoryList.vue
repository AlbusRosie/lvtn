<template>
  <div class="category-list">
    <!-- Filters Section -->
    <div class="filters-card">
      <div class="filters-header">
        <h3>Filters</h3>
        <button v-if="searchTerm" 
                @click="clearSearch" class="btn-clear-filters">
          <i class="fas fa-times"></i>
          Clear Filters
        </button>
      </div>
      <div class="filters-grid">
        <div class="filter-group">
          <label>Search</label>
          <input
            v-model="searchTerm"
            type="text"
            placeholder="Search categories..."
            class="filter-input"
          />
        </div>
      </div>
    </div>
    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Loading categories...</p>
      </div>
      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadCategories" class="btn btn-secondary">
          Retry
        </button>
      </div>
      <div v-else-if="filteredCategories.length === 0" class="empty-state">
        <i class="fas fa-tags"></i>
        <h3>No Categories Found</h3>
        <p v-if="searchTerm">
          No categories match the current filters
        </p>
        <p v-else>
          No categories have been created yet. Add the first category!
        </p>
        <button @click="showCreateForm = true" class="btn btn-primary">
          Add First Category
        </button>
      </div>
      <div v-else class="categories-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>Category List</h3>
            <span class="table-count">{{ filteredCategories.length }}/{{ categories.length }} categories</span>
          </div>
          <div class="header-actions-wrapper">
            <div v-if="selectedCategories.length > 0" class="bulk-actions">
              <span class="selected-count">{{ selectedCategories.length }} selected</span>
              <button 
                @click="bulkDeleteCategories" 
                class="bulk-btn bulk-btn-delete" 
                title="Delete categories"
              >
                <i class="fas fa-trash"></i>
              </button>
              <button @click="selectedCategories = []" class="bulk-btn" title="Deselect">
                <i class="fas fa-times"></i>
              </button>
            </div>
          <div class="header-actions">
            <button @click="exportCategories('csv')" class="btn-export" :disabled="loading || isExporting">
              <i v-if="isExporting" class="fas fa-spinner fa-spin"></i>
              <i v-else class="fas fa-file-excel"></i>
              {{ isExporting ? 'Exporting...' : 'Export Excel' }}
            </button>
            <button @click="showCreateForm = true" class="btn-add" :disabled="loading">
              <i class="fas fa-plus"></i>
              Add Category
            </button>
            <button @click="loadCategories" class="btn-refresh" :disabled="loading">
              <i class="fas fa-sync"></i>
              Refresh
            </button>
          </div>
          </div>
        </div>
        <div class="table-wrapper">
          <table class="modern-table">
            <thead>
              <tr>
                <th class="checkbox-col">
                  <input 
                    type="checkbox" 
                    :checked="selectedCategories.length === filteredCategories.length && filteredCategories.length > 0"
                    @change="selectAllCategories"
                    class="checkbox-input"
                  />
                </th>
                <th class="image-col">Image</th>
                <th class="name-col">Category Name</th>
                <th class="description-col">Description</th>
                <th class="products-col">Products</th>
                <th class="date-col">Created Date</th>
                <th class="actions-col">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="category in paginatedCategories" 
                :key="category.id"
                :class="{ 'row-selected': selectedCategories.includes(category.id) }"
              >
                <td class="checkbox-col">
                  <input 
                    type="checkbox" 
                    :checked="selectedCategories.includes(category.id)"
                    @change="toggleCategorySelection(category.id)"
                    class="checkbox-input"
                  />
                </td>
                <td class="image-cell">
                  <div class="category-image-cell">
                    <img 
                      :src="category.image || DEFAULT_CATEGORY_IMAGE" 
                      :alt="category.name"
                      @error="handleImageError"
                    />
                  </div>
                </td>
                <td class="name-cell">
                  <div class="category-name-wrapper">
                    <i class="fas fa-tag"></i>
                    <strong class="category-name-text">{{ category.name }}</strong>
                  </div>
                </td>
                <td class="description-cell">
                  <span class="description-text" :title="category.description || ''">
                    {{ category.description && category.description.length > 40 ? category.description.substring(0, 40) + '...' : (category.description || '-') }}
                  </span>
                </td>
                <td class="products-cell">
                  <span class="products-badge">{{ category.product_count || 0 }}</span>
                </td>
                <td class="date-cell">
                  {{ formatDate(category.created_at) }}
                </td>
                <td class="actions-cell">
                  <div class="action-buttons">
                    <button 
                      @click="handleEdit(category)"
                      class="btn-action btn-edit"
                      title="Edit"
                    >
                      <i class="fas fa-edit"></i>
                    </button>
                    <button 
                      @click="handleDelete(category)"
                      class="btn-action btn-delete"
                      title="Delete"
                      :disabled="loading"
                    >
                      <i class="fas fa-trash"></i>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <!-- Pagination -->
        <div v-if="totalPages > 1" class="pagination">
          <button 
            @click="currentPage = Math.max(1, currentPage - 1)" 
            :disabled="currentPage === 1 || loading"
            class="pagination-btn"
            title="Previous Page"
          >
            <i class="fas fa-chevron-left"></i>
          </button>
          <div class="pagination-info">
            <span>Page {{ currentPage }} / {{ totalPages }} ({{ filteredCategories.length }} categories)</span>
          </div>
          <button 
            @click="currentPage = Math.min(totalPages, currentPage + 1)" 
            :disabled="currentPage === totalPages || loading"
            class="pagination-btn"
            title="Next Page"
          >
            <i class="fas fa-chevron-right"></i>
          </button>
        </div>
      </div>
    </div>
    <div v-if="showCreateForm || editingCategory" class="modal-overlay" @click.self="closeModal">
      <div class="modal-content form-modal">
        <div class="modal-header">
          <div class="modal-header-left">
            <div class="modal-icon-wrapper" :class="editingCategory ? 'icon-edit' : 'icon-add'">
              <i class="fas" :class="editingCategory ? 'fa-edit' : 'fa-plus'"></i>
            </div>
            <div class="modal-title-section">
              <h3>{{ editingCategory ? 'Edit Category' : 'Add New Category' }}</h3>
              <p v-if="editingCategory && editingCategory.name" class="modal-subtitle">{{ editingCategory.name }}</p>
            </div>
          </div>
          <button @click="closeModal" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <CategoryForm
            :category="editingCategory"
            :loading="formLoading"
            @submit="handleFormSubmit"
            @cancel="closeModal"
          />
        </div>
      </div>
    </div>
    <div v-if="showDeleteModal" class="modal-overlay" @click.self="showDeleteModal = false">
      <div class="modal-content delete-modal">
        <div class="modal-header">
          <div class="delete-header">
            <div class="delete-header-icon">
              <i class="fas fa-exclamation-triangle"></i>
            </div>
            <h3>Confirm Delete Category</h3>
          </div>
          <button @click="showDeleteModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <p>Are you sure you want to delete category <strong>{{ categoryToDelete?.name }}</strong>?</p>
          <p class="warning">This action cannot be undone.</p>
        </div>
        <div class="modal-actions">
          <button @click="showDeleteModal = false" class="btn btn-secondary">
            <i class="fas fa-times"></i>
            Cancel
          </button>
          <button @click="confirmDelete" class="btn btn-danger" :disabled="deleteLoading">
            <i v-if="!deleteLoading" class="fas fa-trash"></i>
            <i v-else class="fas fa-spinner fa-spin"></i>
            <span v-if="deleteLoading">Deleting...</span>
            <span v-else>Delete</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { inject } from 'vue';
import CategoryCard from '@/components/Admin/Category/CategoryCard.vue';
import CategoryForm from '@/components/Admin/Category/CategoryForm.vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import CategoryService from '@/services/CategoryService';
import AuthService from '@/services/AuthService';
import { DEFAULT_PRODUCT_IMAGE } from '@/constants';
const DEFAULT_CATEGORY_IMAGE = DEFAULT_PRODUCT_IMAGE;
export default {
  name: 'CategoryList',
  components: {
    CategoryCard,
    CategoryForm,
    LoadingSpinner
  },
  setup() {
    const toast = inject('toast');
    return { toast };
  },
  data() {
    return {
      categories: [],
      loading: false,
      error: null,
      showCreateForm: false,
      editingCategory: null,
      formLoading: false,
      showDeleteModal: false,
      categoryToDelete: null,
      deleteLoading: false,
      searchTerm: '',
      DEFAULT_CATEGORY_IMAGE,
      selectedCategories: [], 
      currentPage: 1,
      totalPages: 1,
      itemsPerPage: 100, 
      isExporting: false
    };
  },
  computed: {
    isAdmin() {
      return AuthService.isAdmin();
    },
    filteredCategories() {
      let filtered = [...this.categories];
      if (this.searchTerm) {
        const term = this.searchTerm.toLowerCase();
        filtered = filtered.filter(category =>
          category.name.toLowerCase().includes(term) ||
          category.description?.toLowerCase().includes(term)
        );
      }
      return filtered;
    },
    paginatedCategories() {
      const start = (this.currentPage - 1) * this.itemsPerPage;
      const end = start + this.itemsPerPage;
      return this.filteredCategories.slice(start, end);
    }
  },
  watch: {
    filteredCategories() {
      this.currentPage = 1;
      this.totalPages = Math.ceil(this.filteredCategories.length / this.itemsPerPage);
    }
  },
  async mounted() {
    await this.loadCategories();
  },
  methods: {
    async loadCategories() {
      this.loading = true;
      this.error = null;
      try {
        const categories = await CategoryService.getCategoriesWithProductCount();
        this.categories = categories;
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while loading categories';
        this.error = errorMessage;
      } finally {
        this.loading = false;
      }
    },
    handleEdit(category) {
      this.editingCategory = category;
    },
    async handleFormSubmit(formData) {
      this.formLoading = true;
      try {
        if (formData && formData.target && formData.target.tagName === 'FORM') {
          this.$toast.error('Error: Invalid form data');
          return;
        }
        const token = AuthService.getToken();
        if (this.editingCategory) {
          await CategoryService.updateCategory(this.editingCategory.id, formData, formData.imageFile);
          if (this.toast) {
            this.toast.success('Category updated successfully!');
          } else {
            alert('Category updated successfully!');
          }
        } else {
          await CategoryService.createCategory(formData, formData.imageFile);
          if (this.toast) {
            this.toast.success('Category created successfully!');
          } else {
            alert('Category created successfully!');
          }
        }
        await this.loadCategories();
        this.closeModal();
      } catch (error) {
        let errorMessage = 'An error occurred';
        if (error.response && error.response.data) {
          errorMessage = error.response.data.message || error.response.data.error || errorMessage;
        } else if (error.message) {
          errorMessage = error.message;
        } else if (typeof error === 'string') {
          errorMessage = error;
        }
        if (this.toast) {
          this.toast.error(errorMessage);
        } else {
          alert('Error: ' + errorMessage);
        }
      } finally {
        this.formLoading = false;
      }
    },
    async bulkDeleteCategories() {
      if (this.selectedCategories.length === 0) {
        if (this.toast) {
          this.toast.warning('Please select at least one category');
        } else {
          alert('Please select at least one category');
        }
        return;
      }
      if (confirm(`Are you sure you want to delete ${this.selectedCategories.length} selected category(ies)? This action cannot be undone.`)) {
        try {
          const token = AuthService.getToken();
          const promises = this.selectedCategories.map(categoryId => 
            CategoryService.deleteCategory(categoryId, token)
          );
          await Promise.all(promises);
          if (this.toast) {
            this.toast.success(`Deleted ${this.selectedCategories.length} category(ies) successfully`);
          } else {
            alert(`Deleted ${this.selectedCategories.length} category(ies) successfully`);
          }
          this.selectedCategories = [];
          await this.loadCategories();
        } catch (error) {
          const errorMessage = error.message || 'An error occurred while deleting categories';
          if (this.toast) {
            this.toast.error(errorMessage);
          } else {
            alert('Error: ' + errorMessage);
          }
        }
      }
    },
    handleDelete(category) {
      this.categoryToDelete = category;
      this.showDeleteModal = true;
    },
    async confirmDelete() {
      this.deleteLoading = true;
      try {
        const token = AuthService.getToken();
        const result = await CategoryService.deleteCategory(this.categoryToDelete.id, token);
        let successMessage = 'Category deleted successfully!';
        if (result.deletedProductsCount > 0) {
          successMessage = `Category deleted successfully! Deleted ${result.deletedProductsCount} related product(s).`;
        }
        if (this.toast) {
          this.toast.success(successMessage);
        } else {
          alert(successMessage);
        }
        await this.loadCategories();
        this.showDeleteModal = false;
        this.categoryToDelete = null;
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while deleting the category';
        if (this.toast) {
          this.toast.error(errorMessage);
        } else {
          alert('Error: ' + errorMessage);
        }
      } finally {
        this.deleteLoading = false;
      }
    },
    closeModal() {
      this.showCreateForm = false;
      this.editingCategory = null;
    },
    clearSearch() {
      this.searchTerm = '';
    },
    handleImageError(event) {
      event.target.src = DEFAULT_CATEGORY_IMAGE;
    },
    formatDate(dateString) {
      if (!dateString) return '-';
      return new Date(dateString).toLocaleDateString('vi-VN');
    },
    toggleCategorySelection(categoryId) {
      const index = this.selectedCategories.indexOf(categoryId);
      if (index > -1) {
        this.selectedCategories.splice(index, 1);
      } else {
        this.selectedCategories.push(categoryId);
      }
    },
    selectAllCategories() {
      if (this.selectedCategories.length === this.filteredCategories.length) {
        this.selectedCategories = [];
      } else {
        this.selectedCategories = this.filteredCategories.map(category => category.id);
      }
    },
    async exportCategories(format = 'csv') {
      this.isExporting = true
      try {
        let allCategories = []
        const categories = await CategoryService.getAllCategories()
        const categoriesList = categories.data?.categories || categories.categories || (Array.isArray(categories) ? categories : [])
        if (this.searchTerm) {
          const term = this.searchTerm.toLowerCase()
          allCategories = categoriesList.filter(category =>
            category.name?.toLowerCase().includes(term) ||
            category.description?.toLowerCase().includes(term)
          )
        } else {
          allCategories = categoriesList
        }
        if (allCategories.length === 0) {
          if (this.toast) {
            this.toast.warning('No categories match the selected filters')
          } else {
            alert('No categories match the selected filters')
          }
          return
        }
        if (format === 'excel' || format === 'csv') {
          this.exportToCSV(allCategories)
          if (this.toast) {
            this.toast.success(`Successfully exported ${allCategories.length} category(ies)`)
          }
        }
      } catch (error) {
        const errorMessage = error.message || 'Lỗi không xác định'
        if (this.toast) {
          this.toast.error('Unable to export category list: ' + errorMessage)
        } else {
          alert('Unable to export category list: ' + errorMessage)
        }
      } finally {
        this.isExporting = false
      }
    },
    exportToCSV(categories) {
      const headers = [
        'ID', 'Category Name', 'Description', 'Products', 'Created Date'
      ]
      const rows = categories.map(category => [
        category.id,
        category.name || 'N/A',
        category.description || '',
        category.product_count || 0,
        category.created_at ? new Date(category.created_at).toLocaleString('vi-VN') : ''
      ])
      const csvContent = [
        headers.join(','),
        ...rows.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      ].join('\n')
      const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      const url = URL.createObjectURL(blob)
      link.setAttribute('href', url)
      link.setAttribute('download', `danh_sach_danh_muc_${new Date().toISOString().split('T')[0]}.csv`)
      link.style.visibility = 'hidden'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    }
  }
};
</script>
<style scoped>
.category-list {
  padding: 20px;
  background: #F5F7FA;
  min-height: calc(100vh - 72px);
}
.header {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  margin-bottom: 24px;
  background: white;
  padding: 16px 24px;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
  border: 1px solid #F0E6D9;
}
.header-title-section {
  display: flex;
  align-items: center;
  gap: 12px;
}
.header h1 {
  margin: 0;
  font-size: 22px;
  color: #333;
  font-weight: 700;
  letter-spacing: -0.3px;
}
.actions {
  display: flex;
  gap: 10px;
  align-items: center;
}
.btn-add, .btn-refresh {
  padding: 10px 18px;
  border: none;
  background: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-export {
  padding: 10px 18px;
  border: none;
  background: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
  border: 2px solid #10B981;
  background: white;
  color: #10B981;
}
.btn-export:hover:not(:disabled) {
  background: #ECFDF5;
  border-color: #059669;
  color: #059669;
}
.btn-add {
  background: #FF8C42;
  color: white;
}
.btn-add:hover:not(:disabled) {
  background: #E67E22;
}
.btn-refresh {
  border: 2px solid #F0E6D9;
  background: white;
  color: #666;
}
.btn-refresh:hover:not(:disabled) {
  border-color: #FF8C42;
  background: #FFF3E0;
  color: #FF8C42;
}
.btn-add:disabled, .btn-refresh:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.filters-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  border: 1px solid #E2E8F0;
}
.filters-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}
.filters-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: #1a1a1a;
}
.btn-clear-filters {
  padding: 8px 16px;
  border: 1px solid #E5E5E5;
  background: white;
  color: #666;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s ease;
}
.btn-clear-filters:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.filters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}
.filter-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.filter-group label {
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
}
.filter-input {
  padding: 10px 14px;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  font-size: 14px;
  background: #FAFAFA;
  color: #1a1a1a;
  font-weight: 500;
  transition: all 0.2s ease;
}
.filter-input:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
  background: white;
}
.filter-input::placeholder {
  color: #9CA3AF;
  font-weight: 400;
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
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
  border: 1px solid #F0E6D9;
}
.loading i,
.error i,
.empty-state i {
  font-size: 3rem;
  margin-bottom: 16px;
}
.error i {
  color: #EF4444;
}
.empty-state i {
  color: #6B7280;
  opacity: 0.5;
}
.empty-state h3 {
  margin: 0 0 8px 0;
  color: #1a1a1a;
  font-size: 18px;
  font-weight: 700;
}
.empty-state p {
  margin: 0 0 16px 0;
  color: #6B7280;
  font-size: 14px;
}
.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-primary {
  background: linear-gradient(135deg, #FF8C42, #E67E22);
  color: white;
}
.btn-primary:hover:not(:disabled) {
  background: linear-gradient(135deg, #E67E22, #D35400);
}
.btn-secondary {
  background: #6b7280;
  color: white;
}
.btn-secondary:hover:not(:disabled) {
  background: #4b5563;
}
.btn-danger {
  background: #ef4444;
  color: white;
}
.btn-danger:hover:not(:disabled) {
  background: #dc2626;
}
.categories-card {
  background: #FAFBFC;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #E2E8F0;
  margin-bottom: 20px;
}
.table-header-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0;
  background: transparent;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 2px solid #E2E8F0;
}
.header-actions-wrapper {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}
.header-actions {
  display: flex;
  flex-direction: row;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
  flex-shrink: 0;
}
.table-title {
  display: flex;
  align-items: center;
  gap: 12px;
}
.table-title h3 {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
  color: #1E293B;
  letter-spacing: -0.2px;
  flex-shrink: 0;
}
.table-count {
  padding: 4px 12px;
  background: #F3F4F6;
  border: 1px solid #E5E7EB;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
}
.bulk-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}
.selected-count {
  font-size: 13px;
  color: #6B7280;
  font-weight: 600;
  margin-right: 8px;
}
.bulk-btn {
  width: 36px;
  height: 36px;
  border: 1px solid #E5E5E5;
  background: white;
  cursor: pointer;
  border-radius: 8px;
  font-size: 14px;
  color: #666;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}
.bulk-btn:hover:not(:disabled) {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.bulk-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background: #F3F4F6;
  border-color: #E5E7EB;
  color: #9CA3AF;
}
.bulk-btn-delete {
  color: #EF4444;
  border-color: #FEE2E2;
  background: #FEF2F2;
}
.bulk-btn-delete:hover:not(:disabled) {
  background: #FEE2E2;
  border-color: #EF4444;
  color: #DC2626;
}
.table-wrapper {
  overflow-x: auto;
}
.modern-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  background: white;
  border-radius: 10px;
  overflow: hidden;
  border: 1px solid #E2E8F0;
  table-layout: fixed;
}
.modern-table thead {
  background: #F8F9FA;
}
.modern-table th {
  padding: 12px 14px;
  text-align: left;
  font-size: 11px;
  font-weight: 700;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 2px solid #E2E8F0;
  white-space: nowrap;
}
.modern-table tbody tr {
  transition: all 0.2s ease;
  border-bottom: 1px solid #F1F5F9;
}
.modern-table tbody tr:hover {
  background: #F8F9FA;
}
.modern-table tbody tr.row-selected {
  background: #FFF9F5 !important;
}
.modern-table tbody tr:last-child td {
  border-bottom: none;
}
.checkbox-col {
  width: 40px;
  padding: 16px !important;
}
.checkbox-input {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #FF8C42;
}
.modern-table td {
  padding: 12px 14px;
  font-size: 12px;
  color: #1E293B;
  vertical-align: middle;
}
.image-col {
  width: 60px;
  max-width: 60px;
}
.category-image-cell {
  width: 45px;
  height: 45px;
  border-radius: 8px;
  overflow: hidden;
  border: 2px solid #F3F4F6;
  background: #FAFAFA;
}
.category-image-cell img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.2s ease;
}
.modern-table tbody tr:hover .category-image-cell img {
  transform: scale(1.05);
}
.name-col {
  width: 180px;
  max-width: 180px;
}
.category-name-wrapper {
  display: flex;
  align-items: center;
  gap: 6px;
}
.category-name-wrapper i {
  color: #6B7280;
  font-size: 12px;
}
.category-name-text {
  font-size: 13px;
  font-weight: 600;
  color: #1a1a1a;
}
.description-col {
  width: 250px;
  max-width: 250px;
}
.description-text {
  font-size: 12px;
  color: #6B7280;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.products-col {
  width: 100px;
  max-width: 100px;
}
.products-badge {
  padding: 4px 10px;
  background: #F3F4F6;
  border: 1px solid #E5E7EB;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #6B7280;
  display: inline-block;
}
.date-col {
  width: 100px;
  max-width: 100px;
}
.date-cell {
  font-size: 11px;
  color: #6B7280;
  font-weight: 500;
}
.actions-col {
  width: 80px;
  max-width: 80px;
}
.action-buttons {
  display: flex;
  gap: 6px;
  align-items: center;
  justify-content: flex-end;
}
.btn-action {
  width: 32px;
  height: 32px;
  border: 1px solid #E5E5E5;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  transition: all 0.2s ease;
  font-size: 12px;
}
.btn-action:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}
.btn-action:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-edit {
  color: #F59E0B;
  border-color: #FEF3C7;
  background: #FFFBEB;
}
.btn-edit:hover:not(:disabled) {
  background: #FEF3C7;
  border-color: #F59E0B;
  color: #D97706;
}
.btn-delete {
  color: #EF4444;
  border-color: #FEE2E2;
  background: #FEF2F2;
}
.btn-delete:hover:not(:disabled) {
  background: #FEE2E2;
  border-color: #EF4444;
  color: #DC2626;
}
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  backdrop-filter: blur(4px);
  animation: fadeIn 0.2s ease;
}
@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}
.modal-content {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
  border: 1px solid #F0E6D9;
  width: 90%;
  max-width: 600px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: slideUp 0.3s ease;
}
@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
.delete-modal {
  max-width: 520px;
  padding: 0;
  overflow: hidden;
}
.delete-modal .modal-header {
  background: white;
  padding: 24px;
  border-bottom: 1px solid #F0E6D9;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.delete-header {
  display: flex;
  align-items: center;
  gap: 16px;
}
.delete-header-icon {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  background: #EF4444;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 24px;
}
.delete-header h3 {
  margin: 0;
  color: #1a1a1a;
  font-size: 20px;
  font-weight: 700;
  letter-spacing: -0.3px;
}
.delete-modal .modal-body {
  padding: 24px;
}
.delete-modal .modal-body p {
  margin: 0 0 20px 0;
  color: #6B7280;
  font-size: 15px;
  line-height: 1.6;
}
.delete-modal .modal-body strong {
  color: #1a1a1a;
  font-weight: 600;
}
.delete-modal .modal-body .warning {
  color: #EF4444;
  font-weight: 600;
  margin-top: 12px;
}
.delete-modal .modal-actions {
  padding: 20px 24px;
  background: #FAFAFA;
  border-top: 1px solid #F0E6D9;
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}
.modal-actions .btn {
  padding: 12px 24px;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.modal-actions .btn-secondary {
  background: white;
  color: #6B7280;
  border: 2px solid #E5E7EB;
}
.modal-actions .btn-secondary:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.modal-actions .btn-danger {
  background: #EF4444;
  color: white;
  border: none;
}
.modal-actions .btn-danger:hover:not(:disabled) {
  background: #DC2626;
}
.modal-actions .btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-close-modal {
  width: 36px;
  height: 36px;
  border: none;
  background: rgba(255, 255, 255, 0.8);
  color: #6B7280;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  font-size: 16px;
}
.btn-close-modal:hover {
  background: white;
  color: #EF4444;
  transform: rotate(90deg);
}
.form-modal {
  max-width: 700px;
  padding: 0;
  overflow: hidden;
}
.form-modal .modal-header {
  padding: 20px 24px;
  background: #FFF7ED;
  border-bottom: 2px solid #FED7AA;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-shrink: 0;
}
.modal-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}
.modal-icon-wrapper {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  flex-shrink: 0;
}
.modal-icon-wrapper.icon-add {
  background: white;
  border: 2px solid #10B981;
  color: #10B981;
}
.modal-icon-wrapper.icon-edit {
  background: white;
  border: 2px solid #F59E0B;
  color: #F59E0B;
}
.modal-title-section {
  flex: 1;
}
.modal-title-section h3 {
  margin: 0 0 4px 0;
  font-size: 18px;
  font-weight: 700;
  color: #1E293B;
  letter-spacing: -0.3px;
}
.modal-subtitle {
  margin: 0;
  font-size: 13px;
  color: #6B7280;
  font-weight: 500;
}
.form-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
@media (max-width: 768px) {
  .category-list {
    padding: 16px;
  }
  .header {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
    padding: 12px 16px;
  }
  .filters-grid {
    grid-template-columns: 1fr;
  }
  .modal-content {
    width: 95%;
  }
}
.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 16px;
  padding: 20px;
  margin-top: 20px;
}
.pagination-btn {
  width: 36px;
  height: 36px;
  border: 1px solid #E5E5E5;
  background: white;
  cursor: pointer;
  border-radius: 8px;
  font-size: 14px;
  color: #666;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}
.pagination-btn:hover:not(:disabled) {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.pagination-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.pagination-info {
  font-size: 14px;
  color: #6B7280;
  font-weight: 500;
}
.export-modal {
  background: white;
  border-radius: 14px;
  max-width: 750px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
}
.export-modal .modal-header {
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-shrink: 0;
}
.export-modal .modal-header h3 {
  font-size: 15px;
  font-weight: 600;
  margin: 0;
  color: #1E293B;
  letter-spacing: -0.2px;
}
.export-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.export-modal .modal-actions {
  padding: 16px 20px;
  gap: 10px;
  background: #FFF7ED;
  border-top: 1px solid #FED7AA;
  display: flex;
  justify-content: flex-end;
  flex-shrink: 0;
}
.export-modal .modal-actions .btn-close,
.export-modal .modal-actions .btn-confirm {
  padding: 12px 20px;
  border: 2px solid #F59E0B;
  background: #F59E0B;
  color: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.export-modal .modal-actions .btn-close {
  background: white;
  color: #6B7280;
  border-color: #E5E7EB;
}
.export-modal .modal-actions .btn-close:hover {
  background: #F9FAFB;
  border-color: #D1D5DB;
}
.export-modal .modal-actions .btn-confirm:hover:not(:disabled) {
  background: #D97706;
  border-color: #D97706;
  color: white;
}
.export-modal .modal-actions .btn-confirm:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  background: #F59E0B;
  border-color: #F59E0B;
  color: white;
}
.export-section-card {
  background: #FAFBFC;
  border-radius: 10px;
  padding: 16px;
  margin-bottom: 16px;
  border: 1px solid #E2E8F0;
}
.export-section-header {
  margin-bottom: 16px;
}
.export-section-header .section-title {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  display: flex;
  align-items: center;
  gap: 8px;
}
.export-section-header .section-title i {
  color: #F59E0B;
  font-size: 14px;
}
.export-section-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.filter-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
.export-section-body .form-group {
  margin-bottom: 0;
}
.export-section-body .form-group label {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
}
.export-section-body .form-group label .label-icon {
  color: #FF8C42;
  font-size: 12px;
}
.export-section-body .form-select {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  font-size: 14px;
  background: white;
  color: #1a1a1a;
  font-weight: 500;
  transition: all 0.2s ease;
}
.export-section-body .form-select:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.export-note {
  margin-top: 16px;
  padding: 12px 16px;
  background: #FFF7ED;
  border-radius: 8px;
  display: flex;
  align-items: flex-start;
  gap: 10px;
  font-size: 12px;
  color: #92400E;
  line-height: 1.5;
}
.export-note .note-icon {
  color: #F59E0B;
  font-size: 14px;
  margin-top: 2px;
  flex-shrink: 0;
}
</style>
