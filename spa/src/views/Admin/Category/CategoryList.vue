<template>
  <div class="category-list">
    <div class="page-header">
      <h1>Quản lý danh mục</h1>
      <button @click="showCreateForm = true" class="btn btn-primary">
        <i class="fas fa-plus"></i>
        Thêm danh mục mới
      </button>
    </div>

    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Đang tải danh sách danh mục...</p>
      </div>

      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadCategories" class="btn btn-secondary">
          Thử lại
        </button>
      </div>

      <div v-else-if="filteredCategories.length === 0" class="empty-state">
        <i class="fas fa-tags"></i>
        <h3>Không có danh mục nào</h3>
        <p v-if="searchTerm || statusFilter">
          Không tìm thấy danh mục phù hợp với bộ lọc hiện tại
        </p>
        <p v-else>
          Chưa có danh mục nào được tạo. Hãy thêm danh mục đầu tiên!
        </p>
        <button @click="showCreateForm = true" class="btn btn-primary">
          Thêm danh mục đầu tiên
        </button>
      </div>

      <div v-else class="categories-grid">
        <CategoryCard
          v-for="category in filteredCategories"
          :key="category.id"
          :category="category"
          :is-admin="isAdmin"
          @edit="handleEdit"
          @delete="handleDelete"
        />
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <div v-if="showCreateForm || editingCategory" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <CategoryForm
          :category="editingCategory"
          :loading="formLoading"
          @submit="handleFormSubmit"
          @cancel="closeModal"
        />
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteModal" class="modal-overlay" @click="showDeleteModal = false">
      <div class="modal-content delete-modal" @click.stop>
        <div class="delete-header">
          <i class="fas fa-exclamation-triangle"></i>
          <h3>Xác nhận xóa</h3>
        </div>
        <p>Bạn có chắc chắn muốn xóa danh mục <strong>{{ categoryToDelete?.name }}</strong>?</p>
        <p class="warning">Hành động này không thể hoàn tác và sẽ ảnh hưởng đến các sản phẩm thuộc danh mục này.</p>
        <div class="modal-actions">
          <button @click="showDeleteModal = false" class="btn btn-secondary">
            Hủy
          </button>
          <button @click="confirmDelete" class="btn btn-danger" :disabled="deleteLoading">
            <span v-if="deleteLoading">Đang xóa...</span>
            <span v-else>Xóa</span>
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
      statusFilter: ''
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
      if (this.statusFilter) {
        filtered = filtered.filter(category => category.status === this.statusFilter);
      }

      return filtered;
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
        const errorMessage = error.message || 'Có lỗi xảy ra khi tải danh sách danh mục';
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
          this.$toast.error('Lỗi: Dữ liệu form không hợp lệ');
          return;
        }
        const token = AuthService.getToken();

        if (this.editingCategory) {
          await CategoryService.updateCategory(this.editingCategory.id, formData, token);
          if (this.toast) {
            this.toast.success('Cập nhật danh mục thành công!');
          } else {
            alert('Cập nhật danh mục thành công!');
          }
        } else {
          await CategoryService.createCategory(formData, token);
          if (this.toast) {
            this.toast.success('Tạo danh mục mới thành công!');
          } else {
            alert('Tạo danh mục mới thành công!');
          }
        }

        await this.loadCategories();
        this.closeModal();
      } catch (error) {
        let errorMessage = 'Có lỗi xảy ra';
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
          alert('Lỗi: ' + errorMessage);
        }
      } finally {
        this.formLoading = false;
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
        await CategoryService.deleteCategory(this.categoryToDelete.id, token);

        if (this.toast) {
          this.toast.success('Xóa danh mục thành công!');
        } else {
          alert('Xóa danh mục thành công!');
        }
        await this.loadCategories();
        this.showDeleteModal = false;
        this.categoryToDelete = null;
      } catch (error) {
        const errorMessage = error.message || 'Có lỗi xảy ra khi xóa danh mục';
        if (this.toast) {
          this.toast.error(errorMessage);
        } else {
          alert('Lỗi: ' + errorMessage);
        }
      } finally {
        this.deleteLoading = false;
      }
    },

    closeModal() {
      this.showCreateForm = false;
      this.editingCategory = null;
    }
  }
};
</script>

<style scoped>
.category-list {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.page-header h1 {
  margin: 0;
  color: #1f2937;
  font-size: 2rem;
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

.btn-danger {
  background: #ef4444;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background: #dc2626;
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

.categories-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
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

.delete-modal {
  max-width: 400px;
}

.delete-header {
  text-align: center;
  margin-bottom: 20px;
}

.delete-header i {
  font-size: 3rem;
  color: #ef4444;
  margin-bottom: 16px;
}

.delete-header h3 {
  margin: 0;
  color: #374151;
}

.warning {
  color: #ef4444;
  font-weight: 500;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
}
</style>