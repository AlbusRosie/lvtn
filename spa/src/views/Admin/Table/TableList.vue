<template>
  <div class="table-list">
    <!-- Statistics Section -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon" style="background: #ECFDF5; color: #10B981;">
          <i class="fas fa-table"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ tableStats.total }}</div>
          <div class="stat-label">Total Tables</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #D1FAE5; color: #059669;">
          <i class="fas fa-check-circle"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ tableStats.available }}</div>
          <div class="stat-label">Available</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #FEE2E2; color: #DC2626;">
          <i class="fas fa-users"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ tableStats.occupied }}</div>
          <div class="stat-label">Occupied</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #FEF3C7; color: #D97706;">
          <i class="fas fa-clock"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ tableStats.reserved }}</div>
          <div class="stat-label">Reserved</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #F3F4F6; color: #6B7280;">
          <i class="fas fa-tools"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ tableStats.maintenance }}</div>
          <div class="stat-label">Maintenance</div>
        </div>
      </div>
    </div>
    <!-- Filters Section -->
    <div class="filters-card">
      <div class="filters-header">
        <h3>Filters</h3>
        <button v-if="searchTerm || capacityFilter || branchFilter || floorFilter || timeFilterDate || timeFilterTime || timeFilterDuration || timeFilterGuestCount" 
                @click="handleReset" class="btn-clear-filters">
          <i class="fas fa-times"></i>
          Clear Filters
        </button>
      </div>
      <div class="filters-grid">
        <div v-if="!hideBranchFilter" class="filter-group">
          <label>Branch</label>
          <select v-model="branchFilter" class="filter-select">
            <option value="">All Branches</option>
            <option v-for="branch in branches" :key="branch.id" :value="branch.id">
              {{ branch.name }}
            </option>
          </select>
        </div>
        <div class="filter-group">
          <label>Search</label>
          <input
            v-model="searchTerm"
            type="text"
            placeholder="Search tables..."
            class="filter-input"
          />
        </div>
        <div class="filter-group">
          <label>Capacity</label>
          <select v-model="capacityFilter" class="filter-select">
            <option value="">All Capacity</option>
            <option value="1-2">1-2 people</option>
            <option value="3-4">3-4 people</option>
            <option value="5-6">5-6 people</option>
            <option value="7+">7+ people</option>
          </select>
        </div>
        <div class="filter-group">
          <label>Floor</label>
          <select v-model="floorFilter" class="filter-select">
            <option value="">All Floors</option>
            <option v-for="floor in floors" :key="floor.id" :value="floor.id">
              {{ floor.name }}
            </option>
          </select>
        </div>
      </div>
        </div>
    <!-- Time Filter Section -->
    <div class="filters-card time-filter-card">
      <div class="filters-header">
        <h3><i class="fas fa-calendar-alt"></i> Find Tables by Time</h3>
        <button v-if="timeFilterDate || timeFilterTime || timeFilterDuration || timeFilterGuestCount" 
                @click="handleResetTimeFilter" class="btn-clear-filters">
          <i class="fas fa-times"></i>
          Clear Time Filter
        </button>
      </div>
      <div class="time-filter-grid">
        <div class="filter-group">
          <label><i class="fas fa-calendar"></i> Date</label>
          <input
            v-model="timeFilterDate"
            type="date"
            class="filter-input"
            :min="getCurrentDate()"
          />
        </div>
        <div class="filter-group">
          <label><i class="fas fa-clock"></i> Start Time</label>
          <input
            v-model="timeFilterTime"
            type="time"
            class="filter-input"
          />
        </div>
        <div class="filter-group">
          <label><i class="fas fa-hourglass-half"></i> Duration</label>
          <select v-model="timeFilterDuration" class="filter-select">
            <option value="">Select Duration</option>
            <option :value="60">1 hour</option>
            <option :value="90">1.5 hours</option>
            <option :value="120">2 hours</option>
            <option :value="150">2.5 hours</option>
            <option :value="180">3 hours</option>
          </select>
        </div>
        <div class="filter-group">
          <label><i class="fas fa-users"></i> Guest Count</label>
          <input
            v-model.number="timeFilterGuestCount"
            type="number"
            min="1"
            class="filter-input"
            placeholder="Enter guest count"
          />
        </div>
        <div class="filter-group filter-group-action">
          <label>&nbsp;</label>
          <button 
            @click="checkAvailableTablesByTime" 
            class="btn-check-availability"
            :disabled="!canCheckAvailability || checkingAvailability"
          >
            <i v-if="checkingAvailability" class="fas fa-spinner fa-spin"></i>
            <i v-else class="fas fa-search"></i>
            {{ checkingAvailability ? 'Checking...' : 'Check Available Tables' }}
          </button>
        </div>
      </div>
      <div v-if="timeFilterDate && timeFilterTime && timeFilterDuration && timeFilterGuestCount" class="time-filter-info">
        <i class="fas fa-info-circle"></i>
        <span>Time: {{ formatTimeFilterInfo() }} | Guests: {{ timeFilterGuestCount }}</span>
      </div>
      <div v-if="hasCheckedAvailability && availableTablesCount > 0" class="time-filter-success">
        <i class="fas fa-check-circle"></i>
        <span>Found {{ availableTablesCount }} available table(s)</span>
      </div>
      <div v-else-if="hasCheckedAvailability && availableTablesCount === 0" class="time-filter-warning">
        <i class="fas fa-exclamation-triangle"></i>
        <span>No tables available at the selected time</span>
      </div>
    </div>
    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Loading tables...</p>
      </div>
      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadTables" class="btn btn-secondary">
          Retry
        </button>
      </div>
      <div v-else-if="filteredTables.length === 0" class="empty-state">
        <i class="fas fa-table"></i>
        <h3>No Tables Found</h3>
        <p v-if="searchTerm || capacityFilter || branchFilter || floorFilter || (hasCheckedAvailability && availableTablesCount === 0)">
          No tables match the current filters
        </p>
        <p v-else>
          No tables have been created yet. Add the first table!
        </p>
        <button @click="showCreateForm = true" class="btn btn-primary">
          Add First Table
        </button>
      </div>
      <!-- Table View -->
      <div v-else-if="viewMode === 'table'" class="tables-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>Table List</h3>
            <span class="table-count">{{ paginatedTables.length }}/{{ totalCount }} tables (Page {{ currentPage }}/{{ totalPages }})</span>
          </div>
          <div class="header-actions-wrapper">
            <div v-if="selectedTables.length > 0" class="bulk-actions">
              <span class="selected-count">{{ selectedTables.length }} selected</span>
              <button 
                @click="bulkDeleteTables" 
                class="bulk-btn bulk-btn-delete" 
                title="Delete tables"
              >
                <i class="fas fa-trash"></i>
              </button>
              <button @click="selectedTables = []" class="bulk-btn" title="Deselect">
                <i class="fas fa-times"></i>
              </button>
            </div>
            <div class="header-actions">
              <div class="view-toggle">
                <button 
                  @click="viewMode = 'table'" 
                  :class="['btn-view-toggle', { active: viewMode === 'table' }]"
                  title="View as table"
                >
                  <i class="fas fa-table"></i>
                </button>
                <button 
                  @click="viewMode = 'cards'" 
                  :class="['btn-view-toggle', { active: viewMode === 'cards' }]"
                  title="View as cards"
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
                Add Table
              </button>
              <button @click="loadTables(currentPage)" class="btn-refresh" :disabled="loading">
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
                    :checked="selectedTables.length === filteredTables.length && filteredTables.length > 0"
                    @change="selectAllTables"
                    class="checkbox-input"
                  />
                </th>
                <th class="number-col">Table Number</th>
                <th class="branch-col">Branch</th>
                <th class="floor-col">Floor</th>
                <th class="location-col">Location</th>
                <th class="capacity-col">Capacity</th>
                <th class="date-col">Created Date</th>
                <th class="actions-col">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="table in paginatedTables" 
                :key="table.id"
                :class="[`status-row-${table.status}`, { 'row-selected': selectedTables.includes(table.id) }]"
              >
                <td class="checkbox-col">
                  <input 
                    type="checkbox" 
                    :checked="selectedTables.includes(table.id)"
                    @change="toggleTableSelection(table.id)"
                    class="checkbox-input"
                  />
                </td>
                <td class="number-cell">
                  <div class="table-number-wrapper">
                    <i class="fas fa-table"></i>
                    <strong class="table-number-text">#{{ table.id }}</strong>
                  </div>
                </td>
                <td class="branch-cell">
                  <span class="branch-badge">{{ table.branch_name || 'N/A' }}</span>
                </td>
                <td class="floor-cell">
                  <span class="floor-badge">{{ table.floor_name || 'N/A' }}</span>
                </td>
                <td class="location-cell">
                  <span v-if="table.location" class="location-text" :title="table.location">
                    {{ table.location.length > 20 ? table.location.substring(0, 20) + '...' : table.location }}
                  </span>
                  <span v-else class="text-muted">-</span>
                </td>
                <td class="capacity-cell">
                  <div class="capacity-info">
                    <i class="fas fa-users"></i>
                    <span>{{ table.capacity }} people</span>
                  </div>
                </td>
                <td class="date-cell">
                  {{ formatDate(table.created_at) }}
                </td>
                <td class="actions-cell">
                  <div class="action-buttons">
                    <button 
                      @click="handleEdit(table)"
                      class="btn-action btn-edit"
                      title="Edit"
                    >
                      <i class="fas fa-edit"></i>
                    </button>
                    <button 
                      @click="handleDelete(table)"
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
            @click="loadTables(currentPage - 1)" 
            :disabled="currentPage === 1 || loading"
            class="pagination-btn"
            title="Previous page"
          >
            <i class="fas fa-chevron-left"></i>
          </button>
          <div class="pagination-info">
            <span>Page {{ currentPage }} / {{ totalPages }}</span>
          </div>
          <button 
            @click="loadTables(currentPage + 1)" 
            :disabled="currentPage === totalPages || loading"
            class="pagination-btn"
            title="Next page"
          >
            <i class="fas fa-chevron-right"></i>
          </button>
        </div>
      </div>
      <!-- Card View -->
      <div v-else class="tables-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>Table List</h3>
            <span class="table-count">{{ paginatedTables.length }}/{{ totalCount }} tables (Page {{ currentPage }}/{{ totalPages }})</span>
          </div>
          <div class="header-actions-wrapper">
            <div v-if="selectedTables.length > 0" class="bulk-actions">
              <span class="selected-count">{{ selectedTables.length }} selected</span>
              <button 
                @click="bulkDeleteTables" 
                class="bulk-btn bulk-btn-delete" 
                title="Delete tables"
              >
                <i class="fas fa-trash"></i>
              </button>
              <button @click="selectedTables = []" class="bulk-btn" title="Deselect">
                <i class="fas fa-times"></i>
              </button>
            </div>
            <div class="header-actions">
              <div class="view-toggle">
                <button 
                  @click="viewMode = 'table'" 
                  :class="['btn-view-toggle', { active: viewMode === 'table' }]"
                  title="View as table"
                >
                  <i class="fas fa-table"></i>
                </button>
                <button 
                  @click="viewMode = 'cards'" 
                  :class="['btn-view-toggle', { active: viewMode === 'cards' }]"
                  title="View as cards"
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
                Add Table
              </button>
              <button @click="loadTables(currentPage)" class="btn-refresh" :disabled="loading">
                <i class="fas fa-sync"></i>
                Refresh
              </button>
            </div>
          </div>
        </div>
        <div class="tables-grid">
          <TableCard
            v-for="table in paginatedTables"
            :key="table.id"
            :table="table"
            :is-admin="isAdmin"
            @edit="handleEdit"
            @delete="handleDelete"
            @updateStatus="handleUpdateStatus"
          />
        </div>
        <!-- Pagination for Card View -->
        <div v-if="totalPages > 1" class="pagination">
          <button 
            @click="loadTables(currentPage - 1)" 
            :disabled="currentPage === 1 || loading"
            class="pagination-btn"
            title="Previous page"
          >
            <i class="fas fa-chevron-left"></i>
          </button>
          <div class="pagination-info">
            <span>Page {{ currentPage }} / {{ totalPages }}</span>
          </div>
          <button 
            @click="loadTables(currentPage + 1)" 
            :disabled="currentPage === totalPages || loading"
            class="pagination-btn"
            title="Next page"
          >
            <i class="fas fa-chevron-right"></i>
          </button>
        </div>
      </div>
    </div>
    <div v-if="showCreateForm || editingTable" class="modal-overlay" @click.self="closeModal">
      <div class="modal-content form-modal">
        <div class="modal-header form-header">
          <div class="form-header-content">
            <div class="form-header-icon">
              <i class="fas" :class="editingTable ? 'fa-edit' : 'fa-plus'"></i>
            </div>
            <div>
              <h3>{{ editingTable ? 'Edit Table' : 'Add New Table' }}</h3>
              <p v-if="editingTable" class="form-subtitle">Table #{{ editingTable.id }}</p>
            </div>
          </div>
          <button @click="closeModal" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <TableForm
            ref="tableFormRef"
            :table="editingTable"
            :loading="formLoading"
            :manager-branch-id="isManagerView ? managerBranchId : null"
            :is-manager-view="isManagerView"
            @submit="handleFormSubmit"
            @cancel="closeModal"
          />
        </div>
        <div class="modal-actions">
          <button @click="closeModal" class="btn-close">
            <i class="fas fa-times"></i>
            Cancel
          </button>
          <button @click="handleFormSubmitFromModal" class="btn-confirm" :disabled="formLoading">
            <i v-if="!formLoading" class="fas" :class="editingTable ? 'fa-save' : 'fa-plus'"></i>
            <i v-else class="fas fa-spinner fa-spin"></i>
            <span v-if="formLoading">Processing...</span>
            <span v-else>{{ editingTable ? 'Update' : 'Create Table' }}</span>
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
            <h3>Confirm Delete</h3>
          </div>
          <button @click="showDeleteModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <p>Are you sure you want to delete table <strong>#{{ tableToDelete?.id }}</strong>?</p>
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
    <!-- Bulk Delete Table Modal -->
    <div v-if="showBulkDeleteModal" class="modal-overlay" @click.self="showBulkDeleteModal = false">
      <div class="modal-content delete-modal" @click.stop>
        <div class="modal-header">
          <div class="delete-header">
            <div class="delete-header-icon">
              <i class="fas fa-exclamation-triangle"></i>
            </div>
            <h3>Confirm Delete</h3>
          </div>
          <button @click="showBulkDeleteModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <p>Are you sure you want to delete <strong>{{ selectedTables.length }} table(s)</strong> selected?</p>
          <p class="warning">This action cannot be undone.</p>
        </div>
        <div class="modal-actions">
          <button @click="showBulkDeleteModal = false" class="btn btn-secondary">
            <i class="fas fa-times"></i>
            Cancel
          </button>
          <button @click="confirmBulkDelete" class="btn btn-danger" :disabled="bulkDeleteLoading">
            <i v-if="!bulkDeleteLoading" class="fas fa-trash"></i>
            <i v-else class="fas fa-spinner fa-spin"></i>
            <span v-if="bulkDeleteLoading">Deleting...</span>
            <span v-else>Delete</span>
          </button>
        </div>
      </div>
    </div>
    <!-- Export Modal -->
    <div v-if="showExportModal" class="modal-overlay" @click.self="showExportModal = false">
      <div class="modal-content export-modal" @click.stop>
        <div class="modal-header">
          <h3>Export Table List</h3>
          <button @click="showExportModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <!-- Filters Section -->
          <div class="export-section-card">
            <div class="export-section-header">
              <h4 class="section-title">
                Optional Filters
              </h4>
            </div>
            <div class="export-section-body">
              <div class="filter-grid">
              <div v-if="!isManagerView" class="form-group">
                <label>
                  <i class="fas fa-store label-icon"></i>
                  Branch
                </label>
                <select v-model="exportFilters.branch_id" class="form-select">
                  <option value="">All Branches</option>
                  <option v-for="branch in branches" :key="branch.id" :value="branch.id">
                    {{ branch.name }}
                  </option>
                </select>
              </div>
              <div v-else class="form-group">
                <label>
                  <i class="fas fa-store label-icon"></i>
                  Branch
                </label>
                <input 
                  type="text" 
                  :value="branches.find(b => b.id == managerBranchId)?.name || 'N/A'" 
                  class="form-select" 
                  disabled
                  readonly
                />
              </div>
              <div class="form-group">
                <label>
                  <i class="fas fa-layer-group label-icon"></i>
                  Floor
                </label>
                <select v-model="exportFilters.floor_id" class="form-select">
                  <option value="">All Floors</option>
                  <option v-for="floor in floors" :key="floor.id" :value="floor.id">
                    {{ floor.name }}
                  </option>
                </select>
              </div>
              <div class="form-group">
                <label>
                  <i class="fas fa-users label-icon"></i>
                  Capacity
                </label>
                <select v-model="exportFilters.capacity" class="form-select">
                  <option value="">All Capacity</option>
                  <option value="1-2">1-2 people</option>
                  <option value="3-4">3-4 people</option>
                  <option value="5-6">5-6 people</option>
                  <option value="7+">7+ people</option>
                </select>
              </div>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-actions">
            <button @click="showExportModal = false" class="btn-close">
              Cancel
            </button>
            <button @click="exportTables('csv')" class="btn-confirm" :disabled="isExporting">
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
  </div>
</template>
<script>
import { inject } from 'vue';
import TableCard from '@/components/Admin/Table/TableCard.vue';
import TableForm from '@/components/Admin/Table/TableForm.vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import TableService from '@/services/TableService';
import BranchService from '@/services/BranchService';
import ReservationService from '@/services/ReservationService';
import AuthService from '@/services/AuthService';
export default {
  name: 'TableList',
  components: {
    TableCard,
    TableForm,
    LoadingSpinner
  },
  props: {
    isManagerView: {
      type: Boolean,
      default: false
    },
    managerBranchId: {
      type: Number,
      default: null
    },
    hideBranchFilter: {
      type: Boolean,
      default: false
    }
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
      showBulkDeleteModal: false,
      bulkDeleteLoading: false,
      viewMode: 'table', 
      searchTerm: '',
      branchFilter: this.isManagerView && this.managerBranchId ? String(this.managerBranchId) : '',
      capacityFilter: '',
      floorFilter: '',
      timeFilterDate: '',
      timeFilterTime: '',
      timeFilterDuration: 120,
      timeFilterGuestCount: null,
      hasCheckedAvailability: false,
      checkingAvailability: false,
      tableAvailabilityMap: new Map(),
      availableTablesCount: 0,
      tableStats: {
        total: 0,
        available: 0,
        occupied: 0,
        reserved: 0,
        maintenance: 0
      },
      branches: [],
      floors: [],
      selectedTables: [], 
      currentPage: 1,
      totalPages: 1,
      totalCount: 0,
      itemsPerPage: 100, 
      showExportModal: false,
      isExporting: false,
      exportFilters: {
        branch_id: '',
        floor_id: '',
        capacity: ''
      }
    };
  },
  computed: {
    isAdmin() {
      return AuthService.isAdmin();
    },
    canCheckAvailability() {
      return this.timeFilterDate && 
             this.timeFilterTime && 
             this.timeFilterDuration && 
             this.timeFilterGuestCount && 
             this.timeFilterGuestCount > 0 &&
             !this.checkingAvailability;
    },
    filteredTables() {
      let filtered = [...this.tables];
      if (this.searchTerm) {
        const term = this.searchTerm.toLowerCase();
        filtered = filtered.filter(table =>
          (table.location && table.location.toLowerCase().includes(term)) ||
          (table.branch_name && table.branch_name.toLowerCase().includes(term)) ||
          (table.floor_name && table.floor_name.toLowerCase().includes(term))
        );
      }
      if (this.branchFilter) {
        filtered = filtered.filter(table => table.branch_id == this.branchFilter);
      }
      if (this.floorFilter) {
        filtered = filtered.filter(table => table.floor_id == this.floorFilter);
      }
      if (this.hasCheckedAvailability) {
        filtered = filtered.filter(table => {
          const availability = this.tableAvailabilityMap.get(table.id);
          return availability === true;
        });
        if (this.timeFilterGuestCount && this.timeFilterGuestCount > 0) {
          filtered = filtered.filter(table => table.capacity >= this.timeFilterGuestCount);
        }
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
    },
    paginatedTables() {
      const start = (this.currentPage - 1) * this.itemsPerPage;
      const end = start + this.itemsPerPage;
      return this.filteredTables.slice(start, end);
    }
  },
  watch: {
    filteredTables() {
      this.totalCount = this.filteredTables.length;
      this.totalPages = Math.ceil(this.totalCount / this.itemsPerPage);
      if (this.currentPage > this.totalPages && this.totalPages > 0) {
        this.currentPage = this.totalPages;
      }
    }
  },
  async mounted() {
    this.timeFilterTime = this.getCurrentTime();
    await Promise.all([
      this.loadTables(),
      this.loadBranches(),
      this.loadFloors()
    ]);
  },
  methods: {
    async loadTables(page = 1) {
      this.loading = true;
      this.error = null;
      try {
        const filters = {
          page,
          limit: this.itemsPerPage
        };
        if (this.isManagerView && this.managerBranchId) {
          filters.branch_id = this.managerBranchId;
        } else if (this.branchFilter) {
          filters.branch_id = this.branchFilter;
        }
        if (this.floorFilter) filters.floor_id = this.floorFilter;
        if (this.capacityFilter) {
          const [min, max] = this.capacityFilter.split('-');
          if (this.capacityFilter === '7+') {
            filters.min_capacity = 7;
          } else if (max) {
            filters.min_capacity = parseInt(min);
            filters.max_capacity = parseInt(max);
          }
        }
        const allTables = await TableService.getAllTables(filters);
        this.tables = allTables;
        this.calculateStats();
        let filtered = this.filteredTables;
        this.totalCount = filtered.length;
        this.totalPages = Math.ceil(this.totalCount / this.itemsPerPage);
        this.currentPage = page;
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while loading the table list';
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
    handleSearch() {
    },
    handleFilter() {
    },
    handleReset() {
      this.searchTerm = '';
      this.branchFilter = this.isManagerView && this.managerBranchId ? String(this.managerBranchId) : '';
      this.capacityFilter = '';
      this.floorFilter = '';
      this.handleResetTimeFilter();
    },
    handleResetTimeFilter() {
      this.timeFilterDate = '';
      this.timeFilterTime = this.getCurrentTime();
      this.timeFilterDuration = 120;
      this.timeFilterGuestCount = null;
      this.hasCheckedAvailability = false;
      this.tableAvailabilityMap.clear();
      this.availableTablesCount = 0;
    },
    getCurrentTime() {
      const now = new Date();
      const hours = now.getHours().toString().padStart(2, '0');
      const minutes = now.getMinutes().toString().padStart(2, '0');
      return `${hours}:${minutes}`;
    },
    getCurrentDate() {
      return new Date().toISOString().split('T')[0];
    },
    formatTimeFilterInfo() {
      if (!this.timeFilterDate || !this.timeFilterTime || !this.timeFilterDuration) return '';
      const date = new Date(this.timeFilterDate);
      const dateStr = date.toLocaleDateString('vi-VN');
      const durationHours = this.timeFilterDuration / 60;
      const durationStr = durationHours % 1 === 0 ? `${durationHours} hour${durationHours > 1 ? 's' : ''}` : `${durationHours} hours`;
      return `${dateStr} lúc ${this.timeFilterTime} (${durationStr})`;
    },
    async checkAvailableTablesByTime() {
      if (!this.canCheckAvailability) {
        return;
      }
      this.checkingAvailability = true;
      this.tableAvailabilityMap.clear();
      this.hasCheckedAvailability = false;
      try {
        await this.loadTables();
        if (this.tables.length === 0) {
          if (this.toast) {
            this.toast.warning('No tables in this branch');
          }
          this.checkingAvailability = false;
          return;
        }
        const checkPromises = this.tables.map(async (table) => {
          try {
            const scheduleData = await ReservationService.getTableSchedule(
              table.id,
              this.timeFilterDate,
              this.timeFilterDate
            );
            let reservationsList = [];
            if (Array.isArray(scheduleData)) {
              reservationsList = scheduleData;
            } else if (scheduleData?.reservations && Array.isArray(scheduleData.reservations)) {
              reservationsList = scheduleData.reservations;
            } else if (scheduleData?.data?.reservations && Array.isArray(scheduleData.data.reservations)) {
              reservationsList = scheduleData.data.reservations;
            } else if (scheduleData?.data && Array.isArray(scheduleData.data)) {
              reservationsList = scheduleData.data;
            }
            const [startHour, startMinute] = this.timeFilterTime.split(':').map(Number);
            const startTotalMinutes = startHour * 60 + startMinute;
            const endTotalMinutes = startTotalMinutes + this.timeFilterDuration;
            const endHour = Math.floor(endTotalMinutes / 60);
            const endMinute = endTotalMinutes % 60;
            const endTimeString = `${endHour.toString().padStart(2, '0')}:${endMinute.toString().padStart(2, '0')}:00`;
            const startTimeString = `${this.timeFilterTime}:00`;
            const hasConflict = reservationsList.some(schedule => {
              if (schedule.status === 'cancelled') {
                return false;
              }
              const resTime = schedule.reservation_time || schedule.start_time;
              if (!resTime) return false;
              let scheduleDate = schedule.reservation_date || schedule.schedule_date;
              if (!scheduleDate) return false;
              if (scheduleDate.includes('/')) {
                const parts = scheduleDate.split('/');
                if (parts.length === 3) {
                  scheduleDate = `${parts[2]}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`;
                }
              }
              if (scheduleDate instanceof Date) {
                scheduleDate = scheduleDate.toISOString().split('T')[0];
              }
              let normalizedFilterDate = this.timeFilterDate;
              if (normalizedFilterDate.includes('/')) {
                const parts = normalizedFilterDate.split('/');
                if (parts.length === 3) {
                  normalizedFilterDate = `${parts[2]}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`;
                }
              }
              if (normalizedFilterDate instanceof Date) {
                normalizedFilterDate = normalizedFilterDate.toISOString().split('T')[0];
              }
              if (scheduleDate !== normalizedFilterDate) {
                return false; 
              }
              let normalizedResTime = resTime;
              if (normalizedResTime instanceof Date) {
                normalizedResTime = normalizedResTime.toTimeString().split(' ')[0].substring(0, 8);
              } else if (normalizedResTime.length === 5) {
                normalizedResTime = normalizedResTime + ':00';
              } else if (normalizedResTime.length === 8) {
              } else {
                return false;
              }
              let resEndTime = schedule.end_time;
              if (!resEndTime) {
                const durationMinutes = schedule.duration_minutes || 120;
                const [rHour, rMinute] = normalizedResTime.split(':').map(Number);
                const rTotal = rHour * 60 + rMinute + durationMinutes;
                const rEndHour = Math.floor(rTotal / 60);
                const rEndMinute = rTotal % 60;
                resEndTime = `${rEndHour.toString().padStart(2, '0')}:${rEndMinute.toString().padStart(2, '0')}:00`;
              } else {
                if (resEndTime instanceof Date) {
                  resEndTime = resEndTime.toTimeString().split(' ')[0].substring(0, 8);
                } else if (resEndTime.length === 5) {
                  resEndTime = resEndTime + ':00';
                }
              }
              const hasOverlap = (startTimeString >= normalizedResTime && startTimeString < resEndTime) ||
                                 (endTimeString > normalizedResTime && endTimeString <= resEndTime) ||
                                 (startTimeString <= normalizedResTime && endTimeString >= resEndTime);
              return hasOverlap;
            });
            const isAvailable = !hasConflict;
            this.tableAvailabilityMap.set(table.id, isAvailable);
          } catch (error) {
            this.tableAvailabilityMap.set(table.id, false);
          }
        });
        await Promise.all(checkPromises);
        this.hasCheckedAvailability = true;
        this.availableTablesCount = Array.from(this.tableAvailabilityMap.values()).filter(v => v).length;
        if (this.availableTablesCount === 0) {
          if (this.toast) {
            this.toast.warning('No tables available at the selected time');
          }
        } else {
          if (this.toast) {
            this.toast.success(`Found ${this.availableTablesCount} available table(s)`);
          }
        }
      } catch (error) {
        if (this.toast) {
          this.toast.error('Unable to check available tables: ' + (error.message || 'Unknown error'));
        }
        this.hasCheckedAvailability = false;
      } finally {
        this.checkingAvailability = false;
      }
    },
    handleEdit(table) {
      this.editingTable = table;
    },
    handleFormSubmitFromModal() {
      if (this.$refs.tableFormRef) {
        this.$refs.tableFormRef.handleSubmit();
      }
    },
    async handleFormSubmit(formData) {
      this.formLoading = true;
      try {
        if (formData && formData.target && formData.target.tagName === 'FORM') {
          this.$toast.error('Error: Invalid form data');
          return;
        }
        if (this.isManagerView && this.managerBranchId) {
          if (!this.editingTable) {
            formData.branch_id = this.managerBranchId;
          } else {
          }
        }
        if (this.editingTable) {
          await TableService.updateTable(this.editingTable.id, formData);
          if (this.toast) {
            this.toast.success('Table updated successfully!');
          } else {
            alert('Table updated successfully!');
          }
        } else {
          await TableService.createTable(formData);
          if (this.toast) {
            this.toast.success('Table created successfully!');
          } else {
            alert('Table created successfully!');
          }
        }
        await this.loadTables();
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
        if (this.$toast) {
          this.$toast.error(errorMessage);
        } else {
          alert('Error: ' + errorMessage);
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
        await TableService.deleteTable(this.tableToDelete.id);
        if (this.toast) {
          this.toast.success('Table deleted successfully!');
        } else {
          alert('Table deleted successfully!');
        }
        await this.loadTables();
        this.showDeleteModal = false;
        this.tableToDelete = null;
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while deleting the table';
        if (this.$toast) {
          this.$toast.error(errorMessage);
        } else {
          alert('Error: ' + errorMessage);
        }
      } finally {
        this.deleteLoading = false;
      }
    },
    async handleUpdateStatus(tableId, status) {
      try {
        await TableService.updateTableStatus(tableId, status);
        if (this.$toast) {
          this.$toast.success('Status updated successfully!');
        } else {
          alert('Status updated successfully!');
        }
        await this.loadTables();
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while updating the status';
        if (this.$toast) {
          this.$toast.error(errorMessage);
        } else {
          alert('Error: ' + errorMessage);
        }
      }
    },
    closeModal() {
      this.showCreateForm = false;
      this.editingTable = null;
    },
    async loadBranches() {
      try {
        const branches = await BranchService.getAllBranches();
        this.branches = branches || [];
      } catch (error) {
        this.branches = [];
      }
    },
    async loadFloors() {
      try {
        const FloorService = await import('@/services/FloorService');
        const params = {};
        if (this.isManagerView && this.managerBranchId) {
          params.branch_id = this.managerBranchId;
        }
        const floors = await FloorService.default.getAllFloors(params);
        this.floors = floors || [];
      } catch (error) {
        this.floors = [];
      }
    },
    getStatusLabel(status) {
      return TableService.getStatusLabel(status);
    },
    formatDate(dateString) {
      if (!dateString) return '-';
      return new Date(dateString).toLocaleDateString('vi-VN');
    },
    toggleTableSelection(tableId) {
      const index = this.selectedTables.indexOf(tableId);
      if (index > -1) {
        this.selectedTables.splice(index, 1);
      } else {
        this.selectedTables.push(tableId);
      }
    },
    selectAllTables() {
      if (this.selectedTables.length === this.filteredTables.length) {
        this.selectedTables = [];
      } else {
        this.selectedTables = this.filteredTables.map(table => table.id);
      }
    },
    async bulkUpdateStatus(status) {
      if (this.selectedTables.length === 0) {
        if (this.toast) {
          this.toast.warning('Please select at least one table');
        } else {
          alert('Please select at least one table');
        }
        return;
      }
      const statusLabel = this.getStatusLabel(status);
      if (confirm(`Are you sure you want to update the status of ${this.selectedTables.length} table(s) to "${statusLabel}"?`)) {
        try {
          const promises = this.selectedTables.map(tableId => 
            TableService.updateTableStatus(tableId, status)
          );
          await Promise.all(promises);
          if (this.toast) {
            this.toast.success(`Successfully updated status of ${this.selectedTables.length} table(s)`);
          } else {
            alert(`Successfully updated status of ${this.selectedTables.length} table(s)`);
          }
          this.selectedTables = [];
          await this.loadTables(this.currentPage);
        } catch (error) {
          const errorMessage = error.message || 'An error occurred while updating the status';
          if (this.toast) {
            this.toast.error(errorMessage);
          } else {
            alert('Error: ' + errorMessage);
          }
        }
      }
    },
    bulkDeleteTables() {
      if (this.selectedTables.length === 0) {
        if (this.toast) {
          this.toast.warning('Please select at least one table');
        } else {
          alert('Please select at least one table');
        }
        return;
      }
      this.showBulkDeleteModal = true;
    },
    async confirmBulkDelete() {
      if (this.selectedTables.length === 0) return;
      this.bulkDeleteLoading = true;
      try {
        const promises = this.selectedTables.map(tableId => 
          TableService.deleteTable(tableId)
        );
        await Promise.all(promises);
        if (this.toast) {
          this.toast.success(`Successfully deleted ${this.selectedTables.length} table(s)`);
        } else {
          alert(`Successfully deleted ${this.selectedTables.length} table(s)`);
        }
        this.selectedTables = [];
        this.showBulkDeleteModal = false;
        await this.loadTables(this.currentPage);
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while deleting the table';
        if (this.toast) {
          this.toast.error(errorMessage);
        } else {
          alert('Error: ' + errorMessage);
        }
      } finally {
        this.bulkDeleteLoading = false;
      }
    },
    openExportModal() {
      this.exportFilters = {
        branch_id: this.isManagerView && this.managerBranchId ? String(this.managerBranchId) : (this.branchFilter || ''),
        floor_id: this.floorFilter || '',
        capacity: this.capacityFilter || ''
      };
      this.showExportModal = true;
    },
    async exportTables(format = 'csv') {
      this.isExporting = true;
      try {
        const filters = {};
        if (this.isManagerView && this.managerBranchId) {
          filters.branch_id = this.managerBranchId;
        } else if (this.exportFilters.branch_id) {
          filters.branch_id = this.exportFilters.branch_id;
        }
        if (this.exportFilters.floor_id) filters.floor_id = this.exportFilters.floor_id;
        if (this.exportFilters.capacity) {
          const [min, max] = this.exportFilters.capacity.split('-');
          if (this.exportFilters.capacity === '7+') {
            filters.min_capacity = 7;
          } else if (max) {
            filters.min_capacity = parseInt(min);
            filters.max_capacity = parseInt(max);
          }
        }
        const allTables = await TableService.getAllTables();
        let tablesToExport = [...allTables];
        if (filters.branch_id) {
          tablesToExport = tablesToExport.filter(t => t.branch_id == filters.branch_id);
        }
        if (filters.floor_id) {
          tablesToExport = tablesToExport.filter(t => t.floor_id == filters.floor_id);
        }
        if (filters.min_capacity) {
          if (filters.max_capacity) {
            tablesToExport = tablesToExport.filter(t => 
              t.capacity >= filters.min_capacity && t.capacity <= filters.max_capacity
            );
          } else {
            tablesToExport = tablesToExport.filter(t => t.capacity >= filters.min_capacity);
          }
        }
        if (tablesToExport.length === 0) {
          if (this.toast) {
            this.toast.warning('No tables match the selected filters');
          } else {
            alert('No tables match the selected filters');
          }
          return;
        }
        if (format === 'csv' || format === 'excel') {
          this.exportToCSV(tablesToExport, this.exportFilters);
        }
        this.showExportModal = false;
      } catch (error) {
        const errorMessage = error.message || 'Unable to export table list';
        if (this.toast) {
          this.toast.error(errorMessage);
        } else {
          alert('Error: ' + errorMessage);
        }
      } finally {
        this.isExporting = false;
      }
    },
    exportToCSV(tables, filters = {}) {
      const headers = [
        'ID', 'Table Number', 'Branch', 'Floor', 'Location', 'Capacity', 
        'Created Date'
      ];
      const rows = tables.map(table => [
        table.id,
        '#' + table.id,
        table.branch_name || 'N/A',
        table.floor_name || 'N/A',
        table.location || '-',
        table.capacity || 0,
        this.formatDate(table.created_at)
      ]);
      const csvContent = [
        headers.join(','),
        ...rows.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      ].join('\n');
      let filename = 'table_list';
      const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
      filename += `_${today}`;
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
        this.toast.success(`Successfully exported ${tables.length} table(s)`);
      } else {
        alert(`Successfully exported ${tables.length} table(s)`);
      }
    }
  }
};
</script>
<style scoped>
.table-list {
  padding: 20px;
  background: #F5F7FA;
  min-height: calc(100vh - 72px);
}
.header {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  margin-top: 16px;
  margin-bottom: 20px;
  padding: 16px 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
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
  background: #F59E0B;
  color: white;
  border: none;
}
.btn-add:hover:not(:disabled) {
  background: #D97706;
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
.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-primary {
  background: #3b82f6;
  color: white;
}
.delete-modal .modal-actions .btn {
  padding: 10px 20px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.delete-modal .modal-actions .btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.delete-modal .modal-actions .btn-secondary {
  background: #F3F4F6;
  color: #6B7280;
  border: 1px solid #E5E5E5;
}
.delete-modal .modal-actions .btn-secondary:hover:not(:disabled) {
  background: #E5E7EB;
}
.delete-modal .modal-actions .btn-danger {
  background: #EF4444;
  color: white;
  border: none;
}
.delete-modal .modal-actions .btn-danger:hover:not(:disabled) {
  background: #DC2626;
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
  font-size: 48px;
  margin-bottom: 16px;
  color: #9CA3AF;
}
.error i {
  color: #EF4444;
}
.empty-state i {
  color: #6B7280;
}
.loading p,
.error p,
.empty-state p {
  margin: 8px 0;
  color: #6B7280;
  font-size: 14px;
}
.empty-state h3 {
  margin: 0 0 8px 0;
  color: #1a1a1a;
  font-size: 18px;
  font-weight: 700;
}
.tables-card {
  background: #FAFBFC;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #E2E8F0;
  margin-bottom: 20px;
}
.tables-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
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
  padding: 14px 16px;
  text-align: left;
  font-size: 12px;
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
  transform: scale(1);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
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
  padding: 14px 16px;
  font-size: 13px;
  color: #1E293B;
  vertical-align: middle;
}
.number-col {
  width: 120px;
  max-width: 120px;
}
.table-number-wrapper {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  background: #FFF7ED;
  border: 1px solid #FED7AA;
  border-radius: 8px;
  width: fit-content;
}
.table-number-wrapper i {
  color: #F59E0B;
  font-size: 14px;
}
.table-number-text {
  font-size: 13px;
  font-weight: 700;
  color: #92400E;
}
.branch-col {
  width: 180px;
  max-width: 180px;
}
.branch-badge {
  padding: 6px 10px;
  background: #F1F5F9;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 500;
  color: #475569;
  display: inline-block;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.floor-col {
  width: 120px;
  max-width: 120px;
}
.floor-badge {
  padding: 6px 10px;
  background: #FEF3C7;
  border: 1px solid #FDE68A;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 500;
  color: #92400E;
  display: inline-block;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.location-col {
  width: 150px;
  max-width: 150px;
}
.location-text {
  font-size: 12px;
  color: #475569;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  padding: 4px 8px;
  background: #F8F9FA;
  border-radius: 6px;
  display: inline-block;
  max-width: 100%;
}
.text-muted {
  color: #9CA3AF;
  font-size: 12px;
}
.capacity-col {
  width: 130px;
  max-width: 130px;
}
.capacity-info {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #1E293B;
  padding: 4px 8px;
  background: #E0E7FF;
  border: 1px solid #C7D2FE;
  border-radius: 8px;
  width: fit-content;
}
.capacity-info i {
  color: #6366F1;
  font-size: 12px;
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
.status-badge.status-available {
  background: #D1FAE5;
  color: #065F46;
  border: 1px solid #A7F3D0;
}
.status-badge.status-occupied {
  background: #FEE2E2;
  color: #991B1B;
  border: 1px solid #FECACA;
}
.status-badge.status-reserved {
  background: #FEF3C7;
  color: #92400E;
  border: 1px solid #FDE68A;
}
.status-badge.status-maintenance {
  background: #F3F4F6;
  color: #374151;
  border: 1px solid #D1D5DB;
}
.date-col {
  width: 120px;
  max-width: 120px;
}
.date-cell {
  font-size: 12px;
  color: #64748B;
  font-weight: 500;
}
.actions-col {
  width: 120px;
  max-width: 120px;
  text-align: left;
}
.actions-cell {
  padding: 12px 16px !important;
  text-align: left;
}
.action-buttons {
  display: flex;
  gap: 6px;
  align-items: center;
  justify-content: flex-start;
  width: 100%;
}
.btn-action {
  width: 36px;
  height: 36px;
  border: 1px solid #E5E5E5;
  background: white;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748B;
  transition: all 0.2s ease;
  font-size: 14px;
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
  border-color: #FDE68A;
  background: #FFFBEB;
}
.btn-edit:hover:not(:disabled) {
  background: #FEF3C7;
  border-color: #F59E0B;
  color: #D97706;
}
.btn-delete {
  color: #EF4444;
  border-color: #FECACA;
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
  background: white;
  border-radius: 14px;
  max-width: 520px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
  padding: 0;
}
.delete-modal .modal-header {
  padding: 24px;
  background: white;
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
  border-radius: 12px;
  background: #FEE2E2;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #EF4444;
  font-size: 24px;
}
.delete-modal .modal-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: #1a1a1a;
}
.delete-modal .modal-body {
  padding: 24px;
  flex: 1;
  overflow-y: auto;
  background: white;
}
.delete-modal .modal-body p {
  margin: 0 0 12px 0;
  color: #333;
  font-size: 14px;
}
.delete-modal .modal-body p.warning {
  color: #EF4444;
  font-weight: 500;
}
.delete-modal .modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 20px 24px;
  border-top: 1px solid #F0E6D9;
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
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.form-header-content {
  display: flex;
  align-items: center;
  gap: 16px;
}
.form-header-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: #FED7AA;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #F59E0B;
  font-size: 18px;
}
.form-header h3 {
  margin: 0;
  color: #1E293B;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: -0.3px;
}
.form-subtitle {
  margin: 4px 0 0 0;
  color: #6B7280;
  font-size: 13px;
  font-weight: 500;
}
.form-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  max-height: calc(90vh - 200px);
  background: white;
}
.form-body {
  padding: 0;
}
.form-modal .modal-actions {
  padding: 16px 20px;
  background: #FFF7ED;
  border-top: 1px solid #FED7AA;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  flex-shrink: 0;
}
.form-modal .modal-actions .btn-close {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 20px;
  border: 2px solid #F0E6D9;
  background: white;
  color: #666;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  line-height: 1;
  white-space: nowrap;
}
.form-modal .modal-actions .btn-close:hover {
  background: #FFF9F5;
  border-color: #FF8C42;
  color: #D35400;
}
.form-modal .modal-actions .btn-confirm {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 20px;
  border: 2px solid #F59E0B;
  background: #F59E0B;
  color: white;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  line-height: 1;
  white-space: nowrap;
}
.form-modal .modal-actions .btn-confirm:hover:not(:disabled) {
  background: #D97706;
  border-color: #D97706;
  color: white;
}
.form-modal .modal-actions .btn-confirm:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  background: #F59E0B;
  border-color: #F59E0B;
  color: white;
}
.btn-close {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px 20px;
  border: 1px solid #E5E7EB;
  background: white;
  color: #6B7280;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  line-height: 1;
}
.btn-close:hover {
  background: #F3F4F6;
  border-color: #D1D5DB;
  color: #374151;
}
.btn-print {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px 20px;
  border: none;
  background: #F59E0B;
  color: white;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  line-height: 1;
}
.btn-print:hover:not(:disabled) {
  background: #D97706;
}
.btn-print:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.modal-actions-old {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
  padding-top: 24px;
  border-top: 1px solid #F3F4F6;
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
.btn-export {
  padding: 10px 18px;
  border: 2px solid #10B981;
  background: white;
  color: #10B981;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-export:hover {
  border-color: #059669;
  background: #ECFDF5;
  color: #059669;
}
.btn-export:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 24px;
}
.stat-card {
  background: white;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  transition: all 0.2s ease;
  border: 1px solid transparent;
}
.stat-card:hover {
  border-color: #FF8C42;
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);
}
.stat-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}
.stat-info {
  flex: 1;
}
.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: #1a1a1a;
  margin-bottom: 4px;
}
.stat-label {
  font-size: 13px;
  color: #6B7280;
  font-weight: 500;
}
.pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 20px 24px;
  background: white;
  border-top: 1px solid #E5E5E5;
}
.pagination-btn {
  width: 40px;
  height: 40px;
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
  justify-content: center;
  gap: 8px;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  white-space: nowrap;
  line-height: 1;
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
  border: 1px solid #E2E8F0;
  margin-bottom: 16px;
  overflow: hidden;
}
.export-section-card:last-child {
  margin-bottom: 0;
}
.export-section-header {
  padding: 12px 16px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.section-title {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  display: flex;
  align-items: center;
  gap: 8px;
  letter-spacing: -0.2px;
}
.export-section-body {
  padding: 14px 16px;
  background: white;
}
.filter-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}
.filter-grid .form-group {
  margin-bottom: 0;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.form-group label {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #64748B;
}
.label-icon {
  font-size: 14px;
  vertical-align: middle;
  margin-right: 6px;
}
.form-select {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 14px;
  color: #1E293B;
  background: white;
  cursor: pointer;
  transition: all 0.2s ease;
}
.form-select:hover {
  border-color: #CBD5E1;
}
.form-select:focus {
  outline: none;
  border-color: #F59E0B;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1);
}
.btn-confirm {
  padding: 10px 20px;
  border: none;
  background: #FF8C42;
  color: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s ease;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
}
.btn-confirm:hover:not(:disabled) {
  background: #E67E22;
}
.btn-confirm:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-close {
  padding: 12px 24px;
  border: 2px solid #F0E6D9;
  background: white;
  color: #666;
  cursor: pointer;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s ease;
}
.btn-close:hover {
  background: #FFF9F5;
  border-color: #FF8C42;
  color: #D35400;
}
@media (max-width: 1024px) {
  .tables-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 16px;
  }
}
.time-filter-card {
  background: linear-gradient(135deg, #FFF7ED 0%, #FFFBEB 100%);
  border: 2px solid #FED7AA;
}
.time-filter-card .filters-header h3 {
  color: #92400E;
  display: flex;
  align-items: center;
  gap: 8px;
}
.time-filter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 16px;
}
.filter-group-action {
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
}
.btn-check-availability {
  padding: 12px 20px;
  border: 2px solid #F59E0B;
  background: #F59E0B;
  color: white;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: 100%;
  height: 44px;
  box-sizing: border-box;
}
.btn-check-availability:hover:not(:disabled) {
  background: #D97706;
  border-color: #D97706;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
}
.btn-check-availability:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  background: #F59E0B;
  border-color: #F59E0B;
}
.time-filter-info {
  padding: 12px 16px;
  background: #E0F2FE;
  border: 1px solid #BAE6FD;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #0C4A6E;
  margin-top: 12px;
}
.time-filter-info i {
  color: #0284C7;
}
.time-filter-success {
  padding: 12px 16px;
  background: #D1FAE5;
  border: 1px solid #A7F3D0;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #065F46;
  margin-top: 12px;
  font-weight: 600;
}
.time-filter-success i {
  color: #10B981;
}
.time-filter-warning {
  padding: 12px 16px;
  background: #FEF3C7;
  border: 1px solid #FDE68A;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #92400E;
  margin-top: 12px;
  font-weight: 600;
}
.time-filter-warning i {
  color: #F59E0B;
}
@media (max-width: 768px) {
  .table-list {
    padding: 10px;
  }
  .page-header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }
  .tables-grid {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  .modal-overlay {
    padding: 10px;
  }
  .time-filter-grid {
    grid-template-columns: 1fr;
  }
}
</style>
