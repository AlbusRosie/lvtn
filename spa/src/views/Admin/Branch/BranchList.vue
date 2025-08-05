<template>
  <div class="branch-list">
    <div class="page-header">
      <h1>Quản lý chi nhánh</h1>
      <button @click="showCreateForm = true" class="btn btn-primary">
        <i class="fas fa-plus"></i>
        Thêm chi nhánh mới
      </button>
    </div>

    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Đang tải danh sách chi nhánh...</p>
      </div>

      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadBranches" class="btn btn-secondary">
          Thử lại
        </button>
      </div>

      <div v-else-if="filteredBranches.length === 0" class="empty-state">
        <i class="fas fa-building"></i>
        <h3>Không có chi nhánh nào</h3>
        <p v-if="searchTerm || statusFilter">
          Không tìm thấy chi nhánh phù hợp với bộ lọc hiện tại
        </p>
        <p v-else>
          Chưa có chi nhánh nào được tạo. Hãy thêm chi nhánh đầu tiên!
        </p>
        <button @click="showCreateForm = true" class="btn btn-primary">
          Thêm chi nhánh đầu tiên
        </button>
      </div>

      <div v-else class="branches-grid">
        <BranchCard
          v-for="branch in filteredBranches"
          :key="branch.id"
          :branch="branch"
          :is-admin="isAdmin"
          @edit="handleEdit"
          @delete="handleDelete"
        />
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <div v-if="showCreateForm || editingBranch" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <BranchForm
          :branch="editingBranch"
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
        <p>Bạn có chắc chắn muốn xóa chi nhánh <strong>{{ branchToDelete?.name }}</strong>?</p>
        <p class="warning">Hành động này không thể hoàn tác.</p>
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
import BranchCard from '@/components/Admin/Branch/BranchCard.vue';
import BranchForm from '@/components/Admin/Branch/BranchForm.vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import BranchService from '@/services/BranchService';
import AuthService from '@/services/AuthService';

export default {
  name: 'BranchList',
  components: {
    BranchCard,
    BranchForm,
    LoadingSpinner
  },
  setup() {
    const toast = inject('toast');
    return { toast };
  },
  data() {
    return {
      branches: [],
      loading: false,
      error: null,
      showCreateForm: false,
      editingBranch: null,
      formLoading: false,
      showDeleteModal: false,
      branchToDelete: null,
      deleteLoading: false,
      searchTerm: '',
      statusFilter: ''
    };
  },
  computed: {
    isAdmin() {
      return AuthService.isAdmin();
    },
    filteredBranches() {
      let filtered = [...this.branches];

      // Search filter
      if (this.searchTerm) {
        const term = this.searchTerm.toLowerCase();
        filtered = filtered.filter(branch => 
          branch.name.toLowerCase().includes(term) ||
          branch.address.toLowerCase().includes(term) ||
          branch.phone.toLowerCase().includes(term) ||
          branch.email.toLowerCase().includes(term)
        );
      }

      // Status filter
      if (this.statusFilter) {
        filtered = filtered.filter(branch => branch.status === this.statusFilter);
      }

      return filtered;
    }
  },
  async mounted() {
    await this.loadBranches();
  },
  methods: {
    async loadBranches() {
      this.loading = true;
      this.error = null;
      
      try {
        const branches = await BranchService.getAllBranches();
        this.branches = branches;
      } catch (error) {
        const errorMessage = error.message || 'Có lỗi xảy ra khi tải danh sách chi nhánh';
        this.error = errorMessage;
        console.error('Error loading branches:', error);
      } finally {
        this.loading = false;
      }
    },

    handleEdit(branch) {
      this.editingBranch = branch;
    },

    async handleFormSubmit(formData) {
      this.formLoading = true;
      
      try {
        // Kiểm tra xem formData có phải là SubmitEvent không
        if (formData && formData.target && formData.target.tagName === 'FORM') {
          console.error('Received SubmitEvent instead of form data');
          this.$toast.error('Lỗi: Dữ liệu form không hợp lệ');
          return;
        }
        
        console.log('BranchList.handleFormSubmit called with:', formData);
        const token = AuthService.getToken();
        
        if (this.editingBranch) {
          await BranchService.updateBranch(this.editingBranch.id, formData, token);
          if (this.toast) {
            this.toast.success('Cập nhật chi nhánh thành công!');
          } else {
            alert('Cập nhật chi nhánh thành công!');
          }
        } else {
          await BranchService.createBranch(formData, token);
          if (this.toast) {
            this.toast.success('Tạo chi nhánh mới thành công!');
          } else {
            alert('Tạo chi nhánh mới thành công!');
          }
        }
        
        await this.loadBranches();
        this.closeModal();
      } catch (error) {
        console.error('Error submitting form:', error);
        
        // Xử lý lỗi từ API response hoặc Error object
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

    handleDelete(branch) {
      this.branchToDelete = branch;
      this.showDeleteModal = true;
    },

    async confirmDelete() {
      this.deleteLoading = true;
      
      try {
        const token = AuthService.getToken();
        await BranchService.deleteBranch(this.branchToDelete.id, token);
        
        if (this.toast) {
          this.toast.success('Xóa chi nhánh thành công!');
        } else {
          alert('Xóa chi nhánh thành công!');
        }
        await this.loadBranches();
        this.showDeleteModal = false;
        this.branchToDelete = null;
      } catch (error) {
        const errorMessage = error.message || 'Có lỗi xảy ra khi xóa chi nhánh';
        if (this.toast) {
          this.toast.error(errorMessage);
        } else {
          alert('Lỗi: ' + errorMessage);
        }
        console.error('Error deleting branch:', error);
      } finally {
        this.deleteLoading = false;
      }
    },

    closeModal() {
      this.showCreateForm = false;
      this.editingBranch = null;
    }
  }
};
</script>

<style scoped>
.branch-list {
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

.branches-grid {
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