<template>
  <div class="table-list">
    <div class="header">
      <h1>Quản lý bàn</h1>
      <div class="actions">
        <button @click="showCreateForm = true" class="btn-add">+ Thêm bàn</button>
        <button @click="loadTables" class="btn-refresh" :disabled="loading">Làm mới</button>
      </div>
    </div>

    <TableFilter
      :stats="tableStats"
      @search="handleSearch"
      @filter="handleFilter"
      @reset="handleReset"
    />

    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Đang tải danh sách bàn...</p>
      </div>

      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadTables" class="btn btn-secondary">
          Thử lại
        </button>
      </div>

      <div v-else-if="filteredTables.length === 0" class="empty-state">
        <i class="fas fa-table"></i>
        <h3>Không có bàn nào</h3>
        <p v-if="searchTerm || statusFilter || capacityFilter">
          Không tìm thấy bàn phù hợp với bộ lọc hiện tại
        </p>
        <p v-else>
          Chưa có bàn nào được tạo. Hãy thêm bàn đầu tiên!
        </p>
        <button @click="showCreateForm = true" class="btn btn-primary">
          Thêm bàn đầu tiên
        </button>
      </div>

      <div v-else class="tables-grid">
        <TableCard
          v-for="table in filteredTables"
          :key="table.id"
          :table="table"
          :is-admin="isAdmin"
          @edit="handleEdit"
          @delete="handleDelete"
          @update-status="handleUpdateStatus"
        />
      </div>
    </div>

    
    <div v-if="showCreateForm || editingTable" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <TableForm
          :table="editingTable"
          :loading="formLoading"
          @submit="handleFormSubmit"
          @cancel="closeModal"
        />
      </div>
    </div>

    
    <div v-if="showDeleteModal" class="modal-overlay" @click="showDeleteModal = false">
      <div class="modal-content delete-modal" @click.stop>
        <div class="delete-header">
          <i class="fas fa-exclamation-triangle"></i>
          <h3>Xác nhận xóa</h3>
        </div>
        <p>Bạn có chắc chắn muốn xóa bàn <strong>{{ tableToDelete?.table_number }}</strong>?</p>
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
import TableCard from '@/components/Admin/Table/TableCard.vue';
import TableForm from '@/components/Admin/Table/TableForm.vue';
import TableFilter from '@/components/Admin/Table/TableFilter.vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import TableService from '@/services/TableService';
import AuthService from '@/services/AuthService';

export default {
  name: 'TableList',
  components: {
    TableCard,
    TableForm,
    TableFilter,
    LoadingSpinner
  },
  setup() {
    const toast = inject('toast');
    return { toast };
  },
  data() {
    return {
      tables: [],
      loading: false,
      error: null,
      showCreateForm: false,
      editingTable: null,
      formLoading: false,
      showDeleteModal: false,
      tableToDelete: null,
      deleteLoading: false,
      searchTerm: '',
      branchFilter: '',
      statusFilter: '',
      capacityFilter: '',
      tableStats: {
        total: 0,
        available: 0,
        occupied: 0,
        reserved: 0,
        maintenance: 0
      }
    };
  },
  computed: {
    isAdmin() {
      return AuthService.isAdmin();
    },
    filteredTables() {
      let filtered = [...this.tables];

      if (this.searchTerm) {
        const term = this.searchTerm.toLowerCase();
        filtered = filtered.filter(table =>
          table.table_number.toLowerCase().includes(term) ||
          (table.location && table.location.toLowerCase().includes(term)) ||
          (table.branch_name && table.branch_name.toLowerCase().includes(term)) ||
          (table.floor_name && table.floor_name.toLowerCase().includes(term))
        );
      }

      if (this.branchFilter) {
        filtered = filtered.filter(table => table.branch_id == this.branchFilter);
      }

      if (this.statusFilter) {
        filtered = filtered.filter(table => table.status === this.statusFilter);
      }

      if (this.capacityFilter) {
        filtered = filtered.filter(table => {
          const capacity = table.capacity;
          switch (this.capacityFilter) {
            case '1-2': return capacity >= 1 && capacity <= 2;
            case '3-4': return capacity >= 3 && capacity <= 4;
            case '5-6': return capacity >= 5 && capacity <= 6;
            case '7+': return capacity >= 7;
            default: return true;
          }
        });
      }

      return filtered;
    }
  },
  async mounted() {
    await this.loadTables();
  },
  methods: {
    async loadTables() {
      this.loading = true;
      this.error = null;

      try {
        const tables = await TableService.getAllTables();
        this.tables = tables;
        this.calculateStats();
      } catch (error) {
        const errorMessage = error.message || 'Có lỗi xảy ra khi tải danh sách bàn';
        this.error = errorMessage;
      } finally {
        this.loading = false;
      }
    },

    calculateStats() {
      const stats = {
        total: this.tables.length,
        available: 0,
        occupied: 0,
        reserved: 0,
        maintenance: 0
      };

      this.tables.forEach(table => {
        stats[table.status]++;
      });

      this.tableStats = stats;
    },

    handleSearch(term) {
      this.searchTerm = term;
    },

    handleFilter(filters) {
      this.branchFilter = filters.branch;
      this.statusFilter = filters.status;
      this.capacityFilter = filters.capacity;
    },

    handleReset() {
      this.searchTerm = '';
      this.branchFilter = '';
      this.statusFilter = '';
      this.capacityFilter = '';
    },

    handleEdit(table) {
      this.editingTable = table;
    },

    async handleFormSubmit(formData) {
      this.formLoading = true;

      try {

        if (formData && formData.target && formData.target.tagName === 'FORM') {
          this.$toast.error('Lỗi: Dữ liệu form không hợp lệ');
          return;
        }
        const token = AuthService.getToken();

        if (this.editingTable) {
          await TableService.updateTable(this.editingTable.id, formData, token);
          if (this.toast) {
            this.toast.success('Cập nhật bàn thành công!');
          } else {
            alert('Cập nhật bàn thành công!');
          }
        } else {
          await TableService.createTable(formData, token);
          if (this.toast) {
            this.toast.success('Tạo bàn mới thành công!');
          } else {
            alert('Tạo bàn mới thành công!');
          }
        }

        await this.loadTables();
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

        if (this.$toast) {
          this.$toast.error(errorMessage);
        } else {
          alert('Lỗi: ' + errorMessage);
        }
      } finally {
        this.formLoading = false;
      }
    },

    handleDelete(table) {
      this.tableToDelete = table;
      this.showDeleteModal = true;
    },

    async confirmDelete() {
      this.deleteLoading = true;

      try {
        const token = AuthService.getToken();
        await TableService.deleteTable(this.tableToDelete.id, token);

        if (this.toast) {
          this.toast.success('Xóa bàn thành công!');
        } else {
          alert('Xóa bàn thành công!');
        }
        await this.loadTables();
        this.showDeleteModal = false;
        this.tableToDelete = null;
      } catch (error) {
        const errorMessage = error.message || 'Có lỗi xảy ra khi xóa bàn';
        if (this.$toast) {
          this.$toast.error(errorMessage);
        } else {
          alert('Lỗi: ' + errorMessage);
        }
      } finally {
        this.deleteLoading = false;
      }
    },

    async handleUpdateStatus(tableId, status) {
      try {
        const token = AuthService.getToken();
        await TableService.updateTableStatus(tableId, status, token);

        if (this.$toast) {
          this.$toast.success('Cập nhật trạng thái thành công!');
        } else {
          alert('Cập nhật trạng thái thành công!');
        }
        await this.loadTables();
      } catch (error) {
        const errorMessage = error.message || 'Có lỗi xảy ra khi cập nhật trạng thái';
        if (this.$toast) {
          this.$toast.error(errorMessage);
        } else {
          alert('Lỗi: ' + errorMessage);
        }
      }
    },

    closeModal() {
      this.showCreateForm = false;
      this.editingTable = null;
    }
  }
};
</script>

<style scoped>
.table-list {
  padding: 20px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding-bottom: 15px;
  border-bottom: 1px solid #ddd;
}

.header h1 {
  margin: 0;
  font-size: 24px;
  color: #333;
}

.actions {
  display: flex;
  gap: 10px;
}

.btn-add, .btn-refresh {
  padding: 8px 16px;
  border: 1px solid #ccc;
  background: white;
  cursor: pointer;
  border-radius: 4px;
}

.btn-add {
  background: #007bff;
  color: white;
  border-color: #007bff;
}

.btn-add:hover {
  background: #0056b3;
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

.tables-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
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
  max-width: 500px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
}

.delete-modal {
  max-width: 400px;
  padding: 24px;
}

.delete-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.delete-header i {
  font-size: 1.5rem;
  color: #f59e0b;
}

.delete-header h3 {
  margin: 0;
  color: #1f2937;
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

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }

  .tables-grid {
    grid-template-columns: 1fr;
  }

  .modal-overlay {
    padding: 10px;
  }
}
</style>
