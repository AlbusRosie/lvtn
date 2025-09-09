<template>
  <div class="branch-list">
    <div class="page-header">
      <div class="header-left">
        <h1>Quản lý chi nhánh</h1>
        <div class="search-container">
          <div class="search-box">
            <i class="fas fa-search"></i>
            <input
              v-model="searchTerm"
              type="text"
              placeholder="Tìm kiếm theo tên, địa chỉ, tỉnh, quận..."
              class="search-input"
            />
            <button 
              v-if="searchTerm" 
              @click="clearSearch" 
              class="clear-search"
              title="Xóa tìm kiếm"
            >
              <i class="fas fa-times"></i>
            </button>
          </div>
          <div v-if="searchTerm" class="search-results-info">
            <span class="results-count">
              {{ filteredBranches.length }} kết quả cho "{{ searchTerm }}"
            </span>
          </div>
        </div>
      </div>
      <button @click="showCreateForm = true" class="btn btn-primary">
        <i class="fas fa-plus"></i>
        Thêm chi nhánh mới
      </button>
    </div>

    <div class="filters-section">
      <div class="filter-group">
        <label for="province-filter">Tỉnh/Thành phố:</label>
        <select id="province-filter" v-model="selectedProvinceId" @change="onProvinceFilterChange">
          <option value="">Tất cả tỉnh/thành phố</option>
          <option v-for="province in provinces" :key="province.id" :value="province.id">
            {{ province.name }}
          </option>
        </select>
      </div>

      <div class="filter-group">
        <label for="district-filter">Quận/Huyện:</label>
        <select id="district-filter" v-model="selectedDistrictId" :disabled="!selectedProvinceId">
          <option value="">Tất cả quận/huyện</option>
          <option v-for="district in filteredDistricts" :key="district.id" :value="district.id">
            {{ district.name }}
          </option>
        </select>
      </div>

      <div class="filter-group">
        <label for="status-filter">Trạng thái:</label>
        <select id="status-filter" v-model="statusFilter">
          <option value="">Tất cả trạng thái</option>
          <option value="active">Hoạt động</option>
          <option value="inactive">Không hoạt động</option>
          <option value="maintenance">Bảo trì</option>
        </select>
      </div>

      <button @click="clearFilters" class="btn btn-secondary btn-sm">
        <i class="fas fa-times"></i>
        Xóa bộ lọc
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
          <h3>Xác nhận xóa chi nhánh</h3>
        </div>
        <p>Bạn có chắc chắn muốn xóa chi nhánh <strong>{{ branchToDelete?.name }}</strong>?</p>
        <div class="warning-box">
          <i class="fas fa-exclamation-triangle"></i>
          <div>
            <p><strong>Cảnh báo:</strong> Hành động này sẽ:</p>
            <ul>
              <li>Xóa tất cả tầng trong chi nhánh này</li>
              <li>Xóa tất cả bàn trong chi nhánh này</li>
              <li>Xóa tất cả đơn hàng và đặt bàn liên quan</li>
              <li>Xóa tất cả đánh giá và sản phẩm chi nhánh</li>
              <li>Không thể hoàn tác</li>
            </ul>
          </div>
        </div>
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
import ProvinceService from '@/services/ProvinceService';
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
      statusFilter: '',
      selectedProvinceId: '',
      selectedDistrictId: '',
      provinces: [],
      districts: [],
      filteredDistricts: []
    };
  },
  computed: {
    isAdmin() {
      return AuthService.isAdmin();
    },
    filteredBranches() {
      let filtered = [...this.branches];

      if (this.searchTerm) {
        const term = this.searchTerm.toLowerCase();
        filtered = filtered.filter(branch =>
          branch.name.toLowerCase().includes(term) ||
          (branch.address_detail && branch.address_detail.toLowerCase().includes(term)) ||
          branch.phone.toLowerCase().includes(term) ||
          branch.email.toLowerCase().includes(term) ||
          (branch.province_name && branch.province_name.toLowerCase().includes(term)) ||
          (branch.district_name && branch.district_name.toLowerCase().includes(term))
        );
      }

      if (this.statusFilter) {
        filtered = filtered.filter(branch => branch.status === this.statusFilter);
      }

      if (this.selectedProvinceId) {
        filtered = filtered.filter(branch => branch.province_id == this.selectedProvinceId);
      }

      if (this.selectedDistrictId) {
        filtered = filtered.filter(branch => branch.district_id == this.selectedDistrictId);
      }

      return filtered;
    }
  },
  async mounted() {
    await Promise.all([
      this.loadBranches(),
      this.loadProvinces()
    ]);
  },
  methods: {
    async loadBranches() {
      this.loading = true;
      this.error = null;

      try {
        console.log('Loading branches...');
        const branches = await BranchService.getAllBranches();
        console.log('Branches loaded:', branches);
        this.branches = branches;
      } catch (error) {
        const errorMessage = error.message || 'Có lỗi xảy ra khi tải danh sách chi nhánh';
        this.error = errorMessage;
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
        console.log('Form data:', formData);

        if (formData && formData.target && formData.target.tagName === 'FORM') {
          this.$toast.error('Lỗi: Dữ liệu form không hợp lệ');
          return;
        }
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

        console.log('Reloading branches after update...');
        await this.loadBranches();
        console.log('Branches reloaded:', this.branches);
        this.closeModal();
        this.editingBranch = null;
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

    handleDelete(branch) {
      this.branchToDelete = branch;
      this.showDeleteModal = true;
    },

    async confirmDelete() {
      this.deleteLoading = true;

      try {
        const token = AuthService.getToken();
        const result = await BranchService.deleteBranch(this.branchToDelete.id, token);

        if (this.toast) {
          this.toast.success(result.message || 'Xóa chi nhánh thành công!');
        } else {
          alert(result.message || 'Xóa chi nhánh thành công!');
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
      } finally {
        this.deleteLoading = false;
      }
    },

    async loadProvinces() {
      try {
        this.provinces = await ProvinceService.getAllProvinces();
      } catch (error) {
        console.error('Error loading provinces:', error);
        this.$toast?.error('Không thể tải danh sách tỉnh/thành phố');
      }
    },

    async onProvinceFilterChange() {
      this.selectedDistrictId = '';
      this.filteredDistricts = [];
      
      if (this.selectedProvinceId) {
        try {
          this.districts = await ProvinceService.getDistrictsByProvinceId(this.selectedProvinceId);
          this.filteredDistricts = this.districts;
        } catch (error) {
          console.error('Error loading districts:', error);
          this.$toast?.error('Không thể tải danh sách quận/huyện');
        }
      }
    },

    clearSearch() {
      this.searchTerm = '';
    },

    clearFilters() {
      this.searchTerm = '';
      this.statusFilter = '';
      this.selectedProvinceId = '';
      this.selectedDistrictId = '';
      this.filteredDistricts = [];
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

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
  gap: 20px;
}

.header-left {
  flex: 1;
}

.page-header h1 {
  margin: 0 0 16px 0;
  color: #1f2937;
  font-size: 2rem;
}

.search-container {
  max-width: 400px;
}

.search-box {
  position: relative;
  display: flex;
  align-items: center;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  padding: 8px 12px;
  transition: all 0.2s ease;
}

.search-box:focus-within {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.search-box i {
  color: #9ca3af;
  margin-right: 8px;
  font-size: 0.9rem;
}

.search-input {
  flex: 1;
  border: none;
  outline: none;
  font-size: 0.9rem;
  color: #374151;
  background: transparent;
}

.search-input::placeholder {
  color: #9ca3af;
}

.clear-search {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 4px;
  border-radius: 4px;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.clear-search:hover {
  background: #f3f4f6;
  color: #6b7280;
}

.search-results-info {
  margin-top: 8px;
  font-size: 0.85rem;
  color: #6b7280;
}

.results-count {
  font-weight: 500;
}

.filters-section {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 24px;
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  align-items: end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 200px;
}

.filter-group label {
  font-weight: 500;
  color: #374151;
  font-size: 0.85rem;
}

.filter-group select {
  padding: 8px 12px;
  border: 2px solid #e5e7eb;
  border-radius: 6px;
  font-size: 0.9rem;
  background: white;
  transition: border-color 0.2s ease;
}

.filter-group select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.filter-group select:disabled {
  background: #f3f4f6;
  color: #9ca3af;
  cursor: not-allowed;
}

.btn-sm {
  padding: 6px 12px;
  font-size: 0.8rem;
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

.warning-box {
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 6px;
  padding: 16px;
  margin: 16px 0;
  display: flex;
  gap: 12px;
}

.warning-box i {
  color: #ef4444;
  font-size: 1.2rem;
  margin-top: 2px;
}

.warning-box p {
  margin: 0 0 8px 0;
  color: #374151;
}

.warning-box ul {
  margin: 0;
  padding-left: 20px;
  color: #6b7280;
}

.warning-box li {
  margin: 4px 0;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
}
</style>