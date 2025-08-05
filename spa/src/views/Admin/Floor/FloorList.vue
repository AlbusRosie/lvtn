<template>
  <div class="floor-list">
    <div class="page-header">
      <h1>Quản lý tầng</h1>
      <button @click="showCreateForm = true" class="btn btn-primary">
        <i class="fas fa-plus"></i>
        Thêm tầng mới
      </button>
    </div>

    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Đang tải danh sách tầng...</p>
      </div>

      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadFloors" class="btn btn-secondary">
          Thử lại
        </button>
      </div>

      <div v-else-if="filteredFloors.length === 0" class="empty-state">
        <i class="fas fa-layer-group"></i>
        <h3>Không có tầng nào</h3>
        <p v-if="searchTerm || statusFilter || branchFilter">
          Không tìm thấy tầng phù hợp với bộ lọc hiện tại
        </p>
        <p v-else>
          Chưa có tầng nào được tạo. Hãy thêm tầng đầu tiên!
        </p>
        <button @click="showCreateForm = true" class="btn btn-primary">
          Thêm tầng đầu tiên
        </button>
      </div>

      <div v-else class="floors-grid">
        <FloorCard
          v-for="floor in filteredFloors"
          :key="floor.id"
          :floor="floor"
          :is-admin="isAdmin"
          @edit="handleEdit"
          @delete="handleDelete"
        />
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <div v-if="showCreateForm || editingFloor" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <FloorForm
          :floor="editingFloor"
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
        <p>Bạn có chắc chắn muốn xóa tầng <strong>{{ floorToDelete?.name }}</strong>?</p>
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
import FloorCard from '@/components/Admin/Floor/FloorCard.vue';
import FloorForm from '@/components/Admin/Floor/FloorForm.vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import FloorService from '@/services/FloorService';
import AuthService from '@/services/AuthService';

export default {
  name: 'FloorList',
  components: {
    FloorCard,
    FloorForm,
    LoadingSpinner
  },
  setup() {
    const toast = inject('toast');
    return { toast };
  },
  data() {
    return {
      floors: [],
      loading: false,
      error: null,
      showCreateForm: false,
      editingFloor: null,
      formLoading: false,
      showDeleteModal: false,
      floorToDelete: null,
      deleteLoading: false,
      searchTerm: '',
      statusFilter: '',
      branchFilter: ''
    };
  },
  computed: {
    isAdmin() {
      return AuthService.isAdmin();
    },
    filteredFloors() {
      let filtered = [...this.floors];

      // Search filter
      if (this.searchTerm) {
        const term = this.searchTerm.toLowerCase();
        filtered = filtered.filter(floor => 
          floor.name.toLowerCase().includes(term) ||
          floor.description?.toLowerCase().includes(term) ||
          floor.branch_name?.toLowerCase().includes(term)
        );
      }

      // Status filter
      if (this.statusFilter) {
        filtered = filtered.filter(floor => floor.status === this.statusFilter);
      }

      // Branch filter
      if (this.branchFilter) {
        filtered = filtered.filter(floor => floor.branch_id == this.branchFilter);
      }

      return filtered;
    }
  },
  async mounted() {
    await this.loadFloors();
  },
  methods: {
    async loadFloors() {
      this.loading = true;
      this.error = null;
      
      try {
        const floors = await FloorService.getAllFloors();
        this.floors = floors;
      } catch (error) {
        const errorMessage = error.message || 'Có lỗi xảy ra khi tải danh sách tầng';
        this.error = errorMessage;
        console.error('Error loading floors:', error);
      } finally {
        this.loading = false;
      }
    },

    handleEdit(floor) {
      this.editingFloor = floor;
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
        
        console.log('FloorList.handleFormSubmit called with:', formData);
        const token = AuthService.getToken();
        
        if (this.editingFloor) {
          await FloorService.updateFloor(this.editingFloor.id, formData, token);
          if (this.toast) {
            this.toast.success('Cập nhật tầng thành công!');
          } else {
            alert('Cập nhật tầng thành công!');
          }
        } else {
          await FloorService.createFloor(formData, token);
          if (this.toast) {
            this.toast.success('Tạo tầng mới thành công!');
          } else {
            alert('Tạo tầng mới thành công!');
          }
        }
        
        await this.loadFloors();
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

    handleDelete(floor) {
      this.floorToDelete = floor;
      this.showDeleteModal = true;
    },

    async confirmDelete() {
      this.deleteLoading = true;
      
      try {
        const token = AuthService.getToken();
        await FloorService.deleteFloor(this.floorToDelete.id, token);
        
        if (this.toast) {
          this.toast.success('Xóa tầng thành công!');
        } else {
          alert('Xóa tầng thành công!');
        }
        await this.loadFloors();
        this.showDeleteModal = false;
        this.floorToDelete = null;
      } catch (error) {
        const errorMessage = error.message || 'Có lỗi xảy ra khi xóa tầng';
        if (this.toast) {
          this.toast.error(errorMessage);
        } else {
          alert('Lỗi: ' + errorMessage);
        }
        console.error('Error deleting floor:', error);
      } finally {
        this.deleteLoading = false;
      }
    },

    closeModal() {
      this.showCreateForm = false;
      this.editingFloor = null;
    }
  }
};
</script>

<style scoped>
.floor-list {
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

.floors-grid {
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