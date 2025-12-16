<template>
  <div class="branch-list">
    <!-- Filters Section -->
    <div class="filters-card">
      <div class="filters-header">
        <h3>Filters</h3>
        <button v-if="searchTerm || statusFilter" 
                @click="clearFilters" class="btn-clear-filters">
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
            placeholder="Search branches..."
            class="filter-input"
          />
        </div>
        <div class="filter-group">
          <label>Status</label>
          <select v-model="statusFilter" class="filter-select">
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
            <option value="maintenance">Maintenance</option>
          </select>
        </div>
      </div>
    </div>
    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Loading branches...</p>
      </div>
      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadBranches" class="btn btn-secondary">
          Retry
        </button>
      </div>
      <div v-else-if="filteredBranches.length === 0" class="empty-state">
        <i class="fas fa-building"></i>
        <h3>No Branches Found</h3>
        <p v-if="searchTerm || statusFilter">
          No branches match the current filters
        </p>
        <p v-else>
          No branches have been created yet. Add the first branch!
        </p>
        <button @click="showCreateForm = true" class="btn btn-primary">
          <i class="fas fa-plus"></i>
          Add First Branch
        </button>
      </div>
      <!-- Table View -->
      <div v-else-if="viewMode === 'table'" class="branches-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>Branch List</h3>
            <span class="table-count">{{ filteredBranches.length }}/{{ branches.length }} branches</span>
          </div>
          <div class="header-actions-wrapper">
            <div v-if="selectedBranches.length > 0" class="bulk-actions">
              <span class="selected-count">{{ selectedBranches.length }} selected</span>
              <button 
                @click="bulkDeleteBranches" 
                class="bulk-btn bulk-btn-delete" 
                title="Delete branches"
              >
                <i class="fas fa-trash"></i>
              </button>
              <button @click="selectedBranches = []" class="bulk-btn" title="Deselect">
                <i class="fas fa-times"></i>
              </button>
            </div>
          <div class="header-actions">
            <div class="view-toggle">
              <button 
                @click="viewMode = 'table'" 
                :class="['btn-view-toggle', { active: viewMode === 'table' }]"
                title="Table View"
              >
                <i class="fas fa-table"></i>
              </button>
              <button 
                @click="viewMode = 'cards'" 
                :class="['btn-view-toggle', { active: viewMode === 'cards' }]"
                title="Card View"
              >
                <i class="fas fa-th"></i>
              </button>
            </div>
            <button @click="openExportModal" class="btn-export" :disabled="loading">
              <i class="fas fa-file-excel"></i>
              Export Excel
            </button>
            <button @click="showCreateForm = true" class="btn-add" :disabled="loading">
              <i class="fas fa-plus"></i>
              Add Branch
            </button>
            <button @click="loadBranches" class="btn-refresh" :disabled="loading">
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
                    :checked="selectedBranches.length === filteredBranches.length && filteredBranches.length > 0"
                    @change="selectAllBranches"
                    class="checkbox-input"
                  />
                </th>
                <th class="name-col">Branch Name</th>
                <th class="address-col">Address</th>
                <th class="phone-col">Phone</th>
                <th class="email-col">Email</th>
                <th class="status-col">Status</th>
                <th class="actions-col">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="branch in paginatedBranches" 
                :key="branch.id"
                :class="{ 'row-selected': selectedBranches.includes(branch.id) }"
              >
                <td class="checkbox-col">
                  <input 
                    type="checkbox" 
                    :checked="selectedBranches.includes(branch.id)"
                    @change="toggleBranchSelection(branch.id)"
                    class="checkbox-input"
                  />
                </td>
                <td class="name-cell">
                  <div class="branch-name-wrapper">
                    <strong class="branch-name-text">{{ branch.name }}</strong>
                  </div>
                </td>
                <td class="address-cell">
                  <span class="address-text" :title="branch.address_detail || ''">
                    {{ branch.address_detail && branch.address_detail.length > 30 ? branch.address_detail.substring(0, 30) + '...' : (branch.address_detail || '-') }}
                  </span>
                </td>
                <td class="phone-cell">
                  <span class="phone-text">{{ branch.phone || '-' }}</span>
                </td>
                <td class="email-cell">
                  <span class="email-text" :title="branch.email || ''">
                    {{ branch.email && branch.email.length > 25 ? branch.email.substring(0, 25) + '...' : (branch.email || '-') }}
                  </span>
                </td>
                <td class="status-cell">
                  <span class="status-badge" :class="`status-${branch.status}`">
                    {{ getStatusLabel(branch.status) }}
                  </span>
                </td>
                <td class="actions-cell">
                  <div class="action-buttons">
                    <button 
                      @click="handleEdit(branch)"
                      class="btn-action btn-edit"
                      title="Edit"
                    >
                      <i class="fas fa-edit"></i>
                    </button>
                    <button 
                      @click="handleDelete(branch)"
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
      </div>
      <!-- Card View -->
      <div v-else class="branches-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>Branch List</h3>
            <span class="table-count">{{ filteredBranches.length }}/{{ branches.length }} branches</span>
          </div>
          <div class="header-actions-wrapper">
            <div class="header-actions">
              <div class="view-toggle">
                <button 
                  @click="viewMode = 'table'" 
                  :class="['btn-view-toggle', { active: viewMode === 'table' }]"
                  title="Table View"
                >
                  <i class="fas fa-table"></i>
                </button>
                <button 
                  @click="viewMode = 'cards'" 
                  :class="['btn-view-toggle', { active: viewMode === 'cards' }]"
                  title="Card View"
                >
                  <i class="fas fa-th"></i>
                </button>
              </div>
              <button @click="openExportModal" class="btn-export" :disabled="loading">
                <i class="fas fa-file-excel"></i>
                Export Excel
              </button>
              <button @click="showCreateForm = true" class="btn-add" :disabled="loading">
                <i class="fas fa-plus"></i>
                Add Branch
              </button>
              <button @click="loadBranches" class="btn-refresh" :disabled="loading">
                <i class="fas fa-sync"></i>
                Refresh
              </button>
            </div>
          </div>
        </div>
        <div class="branches-grid">
          <BranchCard
            v-for="branch in paginatedBranches"
            :key="branch.id"
            :branch="branch"
            :is-admin="isAdmin"
            @edit="handleEdit"
            @delete="handleDelete"
          />
        </div>
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
          <span>Page {{ currentPage }} / {{ totalPages }} ({{ filteredBranches.length }} branches)</span>
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
    <div v-if="showCreateForm || editingBranch" class="modal-overlay" @click.self="closeModal">
      <div class="modal-content form-modal" @click.stop>
        <div class="modal-header">
          <div class="modal-header-left">
            <div class="branch-header-badge">
              <i class="fas" :class="editingBranch ? 'fa-edit' : 'fa-plus'"></i>
              <span>{{ editingBranch ? 'Edit Branch' : 'Add New Branch' }}</span>
            </div>
            <span v-if="editingBranch && editingBranch.name" class="branch-name-badge">
              {{ editingBranch.name }}
            </span>
          </div>
          <button @click="closeModal" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <BranchForm
            :branch="editingBranch"
            :loading="formLoading"
            @submit="handleFormSubmit"
            @cancel="closeModal"
          />
        </div>
      </div>
    </div>
    <!-- Export Modal -->
    <div v-if="showExportModal" class="modal-overlay" @click.self="showExportModal = false">
      <div class="modal-content export-modal" @click.stop>
        <div class="modal-header">
          <h3>Export Branch List</h3>
          <button @click="showExportModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <!-- Filters Section -->
          <div class="export-section-card">
            <div class="export-section-header">
              <h4 class="section-title">
                <i class="fas fa-filter"></i>
                Optional Filters
              </h4>
            </div>
            <div class="export-filters-grid">
              <div class="form-group">
                <label>
                  <i class="fas fa-search label-icon"></i>
                  Search
                </label>
                <input
                  v-model="exportFilters.searchTerm"
                  type="text"
                  placeholder="Search branches..."
                  class="form-select"
                />
              </div>
              <div class="form-group">
                <label>
                  <i class="fas fa-toggle-on label-icon"></i>
                  Status
                </label>
                <select v-model="exportFilters.status" class="form-select">
                  <option value="">All Status</option>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                  <option value="maintenance">Maintenance</option>
                </select>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-actions">
          <button @click="showExportModal = false" class="btn-close">
            Cancel
          </button>
          <button @click="exportToExcel" class="btn-confirm" :disabled="isExporting">
            <span v-if="isExporting">
              <i class="fas fa-spinner fa-spin"></i> Exporting...
            </span>
            <span v-else>
              <i class="fas fa-file-excel"></i> Export Excel
            </span>
          </button>
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
            <h3>Confirm Delete Branch</h3>
          </div>
          <button @click="showDeleteModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <p>Are you sure you want to delete branch <strong>{{ branchToDelete?.name }}</strong>?</p>
          <p class="warning">This action cannot be undone.</p>
          <div class="warning-box">
            <div class="warning-box-icon">
              <i class="fas fa-exclamation-triangle"></i>
            </div>
            <div class="warning-box-content">
              <p><strong>Warning:</strong> This action will:</p>
              <ul>
                <li>Delete all floors in this branch</li>
                <li>Delete all tables in this branch</li>
                <li>Delete all related orders and reservations</li>
                <li>Delete all reviews and branch products</li>
              </ul>
            </div>
          </div>
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
import BranchCard from '@/components/Admin/Branch/BranchCard.vue';
import BranchForm from '@/components/Admin/Branch/BranchForm.vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import BranchService from '@/services/BranchService';
import AuthService from '@/services/AuthService';
import SocketService from '@/services/SocketService';
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
      viewMode: 'table', 
      selectedBranches: [], 
      currentPage: 1,
      totalPages: 1,
      itemsPerPage: 100, 
      showExportModal: false,
      isExporting: false,
      exportFilters: {
        searchTerm: '',
        status: ''
      },
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
          branch.email.toLowerCase().includes(term)
        );
      }
      if (this.statusFilter) {
        filtered = filtered.filter(branch => branch.status === this.statusFilter);
      }
      return filtered;
    },
    paginatedBranches() {
      const start = (this.currentPage - 1) * this.itemsPerPage;
      const end = start + this.itemsPerPage;
      return this.filteredBranches.slice(start, end);
    }
  },
  watch: {
    filteredBranches() {
      this.currentPage = 1;
      this.totalPages = Math.ceil(this.filteredBranches.length / this.itemsPerPage);
      if (this.currentPage > this.totalPages && this.totalPages > 0) {
        this.currentPage = this.totalPages;
      }
    }
  },
  async mounted() {
    await this.loadBranches();
    this.totalPages = Math.ceil(this.filteredBranches.length / this.itemsPerPage);
    
    // Setup real-time listeners
    SocketService.on('branch-created', this.handleBranchCreated);
    SocketService.on('branch-updated', this.handleBranchUpdated);
    SocketService.on('branch-deleted', this.handleBranchDeleted);
    SocketService.on('branch-status-updated', this.handleBranchStatusUpdated);
  },
  beforeUnmount() {
    // Cleanup listeners
    SocketService.off('branch-created', this.handleBranchCreated);
    SocketService.off('branch-updated', this.handleBranchUpdated);
    SocketService.off('branch-deleted', this.handleBranchDeleted);
    SocketService.off('branch-status-updated', this.handleBranchStatusUpdated);
  },
  methods: {
    handleBranchCreated(data) {
      this.toast.success(`Chi nhánh "${data.branch.name}" đã được tạo`);
      this.loadBranches();
    },
    handleBranchUpdated(data) {
      const index = this.branches.findIndex(b => b.id === data.branchId);
      if (index !== -1) {
        this.branches[index] = { ...this.branches[index], ...data.branch };
        this.branches = [...this.branches];
        this.toast.info(`Chi nhánh "${data.branch.name}" đã được cập nhật`);
      } else {
        this.loadBranches();
      }
    },
    handleBranchDeleted(data) {
      this.branches = this.branches.filter(b => b.id !== data.branchId);
      this.toast.warning(`Chi nhánh "${data.branch.name}" đã bị xóa`);
    },
    handleBranchStatusUpdated(data) {
      const index = this.branches.findIndex(b => b.id === data.branchId);
      if (index !== -1) {
        this.branches[index].status = data.newStatus;
        this.branches = [...this.branches];
        this.toast.info(`Trạng thái chi nhánh đã thay đổi: ${data.newStatus}`);
      }
    },
    async loadBranches() {
      this.loading = true;
      this.error = null;
      try {
        const branches = await BranchService.getAllBranches();
        this.branches = branches;
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while loading branches';
        this.error = errorMessage;
      } finally {
        this.loading = false;
      }
    },
    handleCopy(branch) {
      const copiedBranch = {
        ...branch,
        name: `${branch.name} (Copy)`,
        email: `copy_${branch.email}`,
        phone: branch.phone + '_copy'
      };
      delete copiedBranch.id;
      delete copiedBranch.created_at;
      delete copiedBranch.image; 
      this.editingBranch = copiedBranch;
    },
    handleEdit(branch) {
      this.editingBranch = branch;
    },
    async handleFormSubmit(data) {
      this.formLoading = true;
      try {
        if (data && data.target && data.target.tagName === 'FORM') {
          this.$toast.error('Error: Invalid form data');
          return;
        }
        const { formData, imageFile } = data;
        if (this.editingBranch) {
          if (this.editingBranch.name && this.editingBranch.name.includes('(Copy)')) {
            await BranchService.createBranch(formData, imageFile);
            if (this.toast) {
              this.toast.success('Branch copied successfully!');
            } else {
              alert('Branch copied successfully!');
            }
          } else {
            await BranchService.updateBranch(this.editingBranch.id, formData, imageFile);
            if (this.toast) {
              this.toast.success('Branch updated successfully!');
            } else {
              alert('Branch updated successfully!');
            }
          }
        } else {
          await BranchService.createBranch(formData, imageFile);
          if (this.toast) {
            this.toast.success('Branch created successfully!');
          } else {
            alert('Branch created successfully!');
          }
        }
        await this.loadBranches();
        this.closeModal();
        this.editingBranch = null;
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
          alert('Lỗi: ' + errorMessage);
        }
      } finally {
        this.formLoading = false;
      }
    },
    async bulkDeleteBranches() {
      if (this.selectedBranches.length === 0) {
        if (this.toast) {
          this.toast.warning('Please select at least one branch');
        } else {
          alert('Please select at least one branch');
        }
        return;
      }
      if (confirm(`Are you sure you want to delete ${this.selectedBranches.length} selected branch(es)? This action cannot be undone.`)) {
        try {
          const token = AuthService.getToken();
          const promises = this.selectedBranches.map(branchId => 
            BranchService.deleteBranch(branchId, token)
          );
          await Promise.all(promises);
          if (this.toast) {
            this.toast.success(`Deleted ${this.selectedBranches.length} branch(es) successfully`);
          } else {
            alert(`Deleted ${this.selectedBranches.length} branch(es) successfully`);
          }
          this.selectedBranches = [];
          await this.loadBranches();
        } catch (error) {
          const errorMessage = error.message || 'An error occurred while deleting branches';
          if (this.toast) {
            this.toast.error(errorMessage);
          } else {
            alert('Lỗi: ' + errorMessage);
          }
        }
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
          this.toast.success(result.message || 'Branch deleted successfully!');
        } else {
          alert(result.message || 'Branch deleted successfully!');
        }
        await this.loadBranches();
        this.showDeleteModal = false;
        this.branchToDelete = null;
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while deleting branch';
        if (this.toast) {
          this.toast.error(errorMessage);
        } else {
          alert('Lỗi: ' + errorMessage);
        }
      } finally {
        this.deleteLoading = false;
      }
    },
    clearFilters() {
      this.searchTerm = '';
      this.statusFilter = '';
    },
    closeModal() {
      this.showCreateForm = false;
      this.editingBranch = null;
    },
    getStatusLabel(status) {
      switch (status) {
        case 'active': return 'Active';
        case 'inactive': return 'Inactive';
        case 'maintenance': return 'Maintenance';
        default: return 'Không xác định';
      }
    },
    formatDate(dateString) {
      if (!dateString) return '-';
      return new Date(dateString).toLocaleDateString('vi-VN');
    },
    toggleBranchSelection(branchId) {
      const index = this.selectedBranches.indexOf(branchId);
      if (index > -1) {
        this.selectedBranches.splice(index, 1);
      } else {
        this.selectedBranches.push(branchId);
      }
    },
    selectAllBranches() {
      if (this.selectedBranches.length === this.filteredBranches.length) {
        this.selectedBranches = [];
      } else {
        this.selectedBranches = this.filteredBranches.map(branch => branch.id);
      }
    },
    async openExportModal() {
      this.exportFilters = {
        searchTerm: this.searchTerm || '',
        status: this.statusFilter || ''
      };
      this.showExportModal = true;
    },
    async exportToExcel() {
      this.isExporting = true;
      try {
        const allBranches = await BranchService.getAllBranches(
          this.exportFilters.searchTerm || null,
          this.exportFilters.status || null
        );
        if (!allBranches || allBranches.length === 0) {
          if (this.toast) {
            this.toast.warning('No branches match the selected filters');
          } else {
            alert('No branches match the selected filters');
          }
          return;
        }
        const sortedBranches = [...allBranches].sort((a, b) => (a.name || '').localeCompare(b.name || ''));
        const headers = ['ID', 'Branch Name', 'Address', 'Phone', 'Email', 'Status'];
        const rows = sortedBranches.map(branch => [
          branch.id,
          branch.name || 'N/A',
          branch.address_detail || 'N/A',
          branch.phone || 'N/A',
          branch.email || 'N/A',
          this.getStatusLabel(branch.status)
        ]);
        const csvContent = [
          headers.join(','),
          ...rows.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
        ].join('\n');
        const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
        const filename = `branch_list_${today}`;
        const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', `${filename}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        if (this.toast) {
          this.toast.success(`Exported ${sortedBranches.length} branch(es) successfully`);
        } else {
          alert(`Exported ${sortedBranches.length} branch(es) successfully`);
        }
        this.showExportModal = false;
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while exporting file';
        if (this.toast) {
          this.toast.error(errorMessage);
        } else {
          alert('Lỗi: ' + errorMessage);
        }
        } finally {
        this.isExporting = false;
      }
    }
  }
};
</script>
<style scoped>
.branch-list {
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
.view-toggle {
  display: flex;
  gap: 6px;
  margin-right: 12px;
  background: #F8F8F8;
  padding: 4px;
  border-radius: 12px;
}
.btn-view-toggle {
  padding: 10px 14px;
  border: none;
  background: transparent;
  cursor: pointer;
  border-radius: 10px;
  color: #666;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
}
.btn-view-toggle:hover {
  background: rgba(255, 140, 66, 0.1);
  color: #FF8C42;
}
.btn-view-toggle.active {
  background: linear-gradient(135deg, #FF8C42, #E67E22);
  color: white;
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
.filter-select,
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
.filter-select:focus,
.filter-input:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
  background: white;
}
.filter-select::placeholder,
.filter-input::placeholder {
  color: #9CA3AF;
  font-weight: 400;
}
.filter-select:disabled {
  background: #F5F5F5;
  color: #9CA3AF;
  cursor: not-allowed;
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
.branches-card {
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
.header-actions {
  display: flex;
  flex-direction: row;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
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
.name-col {
  width: 150px;
  max-width: 150px;
}
.branch-name-wrapper {
  display: flex;
  align-items: center;
  gap: 6px;
}
.branch-name-wrapper i {
  color: #6B7280;
  font-size: 12px;
}
.branch-name-text {
  font-size: 13px;
  font-weight: 600;
  color: #1a1a1a;
}
.address-col {
  width: 180px;
  max-width: 180px;
}
.address-text {
  font-size: 12px;
  color: #6B7280;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.phone-col {
  width: 110px;
  max-width: 110px;
}
.phone-text {
  font-size: 12px;
  color: #6B7280;
  font-weight: 500;
}
.email-col {
  width: 150px;
  max-width: 150px;
}
.email-text {
  font-size: 12px;
  color: #6B7280;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.status-col {
  width: 110px;
  max-width: 110px;
}
.status-badge {
  padding: 4px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.2px;
  display: inline-block;
}
.status-badge.status-active {
  background: #D1FAE5;
  color: #065F46;
  border: 1px solid #A7F3D0;
}
.status-badge.status-inactive {
  background: #FEE2E2;
  color: #991B1B;
  border: 1px solid #FECACA;
}
.status-badge.status-maintenance {
  background: #FEF3C7;
  color: #92400E;
  border: 1px solid #FDE68A;
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
  width: 100px;
  max-width: 100px;
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
.btn-copy {
  color: #8B5CF6;
  border-color: #EDE9FE;
  background: #F5F3FF;
}
.btn-copy:hover:not(:disabled) {
  background: #EDE9FE;
  border-color: #8B5CF6;
  color: #7C3AED;
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
.branches-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
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
  font-size: 14px;
}
.warning-box {
  background: #FEF2F2;
  border: 1px solid #FECACA;
  border-radius: 10px;
  padding: 20px;
  margin: 20px 0;
  display: flex;
  gap: 16px;
}
.warning-box-icon {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  background: #F59E0B;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 20px;
  flex-shrink: 0;
}
.warning-box-content {
  flex: 1;
}
.warning-box-content p {
  margin: 0 0 12px 0;
  color: #1a1a1a;
  font-size: 14px;
  font-weight: 600;
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
  border: 2px solid #F0E6D9;
  background: white;
  color: #666;
}
.export-modal .modal-actions .btn-close:hover {
  background: #FFF9F5;
  border-color: #FF8C42;
  color: #D35400;
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
  padding: 20px;
  margin-bottom: 16px;
  border: 1px solid #E2E8F0;
}
.export-section-header {
  margin-bottom: 16px;
}
.section-title {
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
  margin: 0;
  display: flex;
  align-items: center;
  gap: 8px;
}
.export-filters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}
.export-filters-grid .form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.export-filters-grid .form-group label {
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
  display: flex;
  align-items: center;
  gap: 6px;
}
.export-filters-grid .form-group .label-icon {
  font-size: 12px;
  color: #9CA3AF;
}
.export-filters-grid .form-select {
  padding: 10px 14px;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  font-size: 14px;
  background: white;
  color: #1a1a1a;
  font-weight: 500;
  transition: all 0.2s ease;
  cursor: pointer;
}
.export-filters-grid .form-select:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.btn-export {
  padding: 10px 18px;
  border: 2px solid #10B981;
  background: white;
  color: #10B981;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-export:hover:not(:disabled) {
  background: #10B981;
  color: white;
}
.btn-export:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.warning-box-content ul {
  margin: 0;
  padding-left: 20px;
  color: #6B7280;
  font-size: 13px;
  line-height: 1.8;
}
.warning-box-content li {
  margin: 6px 0;
}
.delete-modal .modal-actions {
  padding: 20px 24px;
  background: #FAFAFA;
  border-top: 1px solid #F0E6D9;
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}
.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
  padding-top: 24px;
  border-top: 1px solid #F3F4F6;
}
.delete-modal .modal-actions .btn {
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  border: none;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s ease;
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
.delete-modal .modal-actions .btn-secondary {
  background: white;
  color: #6B7280;
  border: 1px solid #E2E8F0;
}
.delete-modal .modal-actions .btn-secondary:hover {
  background: #F9FAFB;
  border-color: #CBD5E1;
}
.delete-modal .modal-actions .btn-danger {
  background: #EF4444;
  color: white;
}
.delete-modal .modal-actions .btn-danger:hover:not(:disabled) {
  background: #DC2626;
}
.delete-modal .modal-actions .btn-danger:disabled {
  opacity: 0.6;
  cursor: not-allowed;
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
  background: white;
  border-radius: 14px;
  max-width: 700px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
}
.form-modal .modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
  flex-shrink: 0;
}
.modal-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
  flex-wrap: wrap;
}
.branch-header-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  background: #FFF7ED;
  border: 1px solid #FED7AA;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
}
.branch-header-badge i {
  color: #F59E0B;
  font-size: 14px;
}
.branch-name-badge {
  padding: 6px 14px;
  background: white;
  border: 1px solid #FED7AA;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #475569;
}
.form-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.modal-actions .btn {
  padding: 12px 24px;
  border: 2px solid #F0E6D9;
  background: white;
  color: #666;
  border-radius: 10px;
  font-weight: 600;
  transition: all 0.2s ease;
}
.modal-actions .btn-primary {
  background: linear-gradient(135deg, #FF8C42, #E67E22);
  color: white;
  border-color: #FF8C42;
}
.modal-actions .btn-primary:hover {
  background: linear-gradient(135deg, #E67E22, #D35400);
  border-color: #E67E22;
}
.modal-actions .btn-secondary {
  border-color: #E5E5E5;
  color: #6B7280;
}
.modal-actions .btn-secondary:hover {
  background: #F3F4F6;
  border-color: #D1D5DB;
  color: #374151;
}
.modal-actions .btn-danger {
  background: #EF4444;
  border-color: #EF4444;
  color: white;
}
.modal-actions .btn-danger:hover:not(:disabled) {
  background: #DC2626;
  border-color: #DC2626;
}
@media (max-width: 768px) {
  .branch-list {
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
</style>
