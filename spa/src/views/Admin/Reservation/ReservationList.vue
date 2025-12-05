<template>
  <div class="reservation-list">
    <!-- Statistics Section -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon" style="background: #ECFDF5; color: #10B981;">
          <i class="fas fa-calendar-check"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ reservationStats.total }}</div>
          <div class="stat-label">Total Reservations</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #FEF3C7; color: #D97706;">
          <i class="fas fa-clock"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ reservationStats.pending }}</div>
          <div class="stat-label">Pending</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #D1FAE5; color: #059669;">
          <i class="fas fa-check-circle"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ reservationStats.confirmed }}</div>
          <div class="stat-label">Confirmed</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #DBEAFE; color: #2563EB;">
          <i class="fas fa-check-double"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ reservationStats.completed }}</div>
          <div class="stat-label">Completed</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #FEE2E2; color: #DC2626;">
          <i class="fas fa-times-circle"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ reservationStats.cancelled }}</div>
          <div class="stat-label">Cancelled</div>
        </div>
      </div>
    </div>
    <!-- Filters Section -->
    <div class="filters-card">
      <div class="filters-header">
        <h3>Filters</h3>
        <button v-if="searchTerm || statusFilter || branchFilter || dateFrom || dateTo" 
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
            placeholder="Search by customer name, email, table number, date..."
            class="filter-input"
          />
        </div>
        <div class="filter-group">
          <label>Status</label>
          <select v-model="statusFilter" class="filter-select">
            <option value="">All Status</option>
            <option value="pending">Pending</option>
            <option value="confirmed">Confirmed</option>
            <option value="completed">Completed</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </div>
        <div class="filter-group">
          <label>From Date</label>
          <input
            v-model="dateFrom"
            type="date"
            class="filter-input"
          />
        </div>
        <div class="filter-group">
          <label>To Date</label>
          <input
            v-model="dateTo"
            type="date"
            class="filter-input"
          />
        </div>
      </div>
    </div>
    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Loading reservations...</p>
      </div>
      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadReservations" class="btn btn-secondary">
          Retry
        </button>
      </div>
      <div v-else-if="filteredReservations.length === 0" class="empty-state">
        <i class="fas fa-calendar-times"></i>
        <h3>No Reservations Found</h3>
        <p v-if="searchTerm || statusFilter || branchFilter || dateFrom || dateTo">
          No reservations match the current filters
        </p>
        <p v-else>
          No reservations yet.
        </p>
      </div>
      <!-- Table View -->
      <div v-else class="reservations-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>Reservation List</h3>
            <span class="table-count">{{ filteredReservations.length }}/{{ reservations.length }} reservations</span>
          </div>
          <div class="header-actions-wrapper">
            <div v-if="selectedReservations.length > 0" class="bulk-actions">
              <span class="selected-count">{{ selectedReservations.length }} selected</span>
              <!-- Only show update button when a specific status is selected -->
              <template v-if="statusFilter">
                <button 
                  @click="bulkUpdateStatus('confirmed')" 
                  class="bulk-btn" 
                  title="Confirm"
                  :disabled="!canBulkUpdateToStatus('confirmed')"
                >
                  <i class="fas fa-check"></i>
                </button>
                <button 
                  @click="bulkUpdateStatus('cancelled')" 
                  class="bulk-btn" 
                  title="Cancel"
                  :disabled="!canBulkUpdateToStatus('cancelled')"
                >
                  <i class="fas fa-times"></i>
                </button>
              </template>
              <!-- Show delete button when "All Status" is selected -->
              <template v-if="!statusFilter">
                <button 
                  @click="bulkDeleteReservations" 
                  class="bulk-btn bulk-btn-delete" 
                  title="Delete reservations"
                >
                  <i class="fas fa-trash"></i>
                </button>
              </template>
              <button @click="selectedReservations = []" class="bulk-btn" title="Deselect">
                <i class="fas fa-times"></i>
              </button>
          </div>
          <div class="header-actions">
            <button @click="openExportModal" class="btn-export" :disabled="loading">
              <i class="fas fa-file-excel"></i>
              Export Excel
            </button>
            <button @click="loadReservations(currentPage)" class="btn-refresh" :disabled="loading">
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
                    :checked="selectedReservations.length === filteredReservations.length && filteredReservations.length > 0"
                    @change="selectAllReservations"
                    class="checkbox-input"
                  />
                </th>
                <th class="id-col">ID</th>
                <th class="customer-col">Customer</th>
                <th class="branch-col">Branch</th>
                <th class="table-col">Table</th>
                <th class="date-col">Reservation Date</th>
                <th class="time-col">Reservation Time</th>
                <th class="guests-col">Guests</th>
                <th class="status-col">Status</th>
                <th class="date-col">Created Date</th>
                <th class="actions-col">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="reservation in paginatedReservations" 
                :key="reservation.id"
                :class="[`status-row-${reservation.status}`, { 'row-selected': selectedReservations.includes(reservation.id) }]"
              >
                <td class="checkbox-col">
                  <input 
                    type="checkbox" 
                    :checked="selectedReservations.includes(reservation.id)"
                    @change="toggleReservationSelection(reservation.id)"
                    class="checkbox-input"
                  />
                </td>
                <td class="id-cell">#{{ reservation.id }}</td>
                <td class="customer-cell">
                  <div class="customer-info">
                    <div class="customer-name">{{ reservation.user_name || 'N/A' }}</div>
                    <div class="customer-email">{{ reservation.user_email || '' }}</div>
                  </div>
                </td>
                <td class="branch-cell">
                  <span class="branch-badge">{{ reservation.branch_name || 'N/A' }}</span>
                </td>
                <td class="table-cell">
                  <span class="table-badge" v-if="reservation.table_id">#{{ reservation.table_id }}</span>
                  <span class="table-badge" v-else>N/A</span>
                </td>
                <td class="date-cell">
                  {{ formatDate(reservation.reservation_date) }}
                </td>
                <td class="time-cell">
                  {{ formatTime(reservation.reservation_time) }}
                </td>
                <td class="guests-cell">
                  <div class="guests-info">
                    <i class="fas fa-users"></i>
                    <span>{{ reservation.guest_count }} people</span>
                  </div>
                </td>
                <td class="status-cell">
                  <span class="status-badge" :class="`status-${reservation.status}`">
                    {{ getStatusLabel(reservation.status) }}
                  </span>
                </td>
                <td class="date-cell">
                  {{ formatDate(reservation.created_at) }}
                </td>
                <td class="actions-cell">
                  <div class="action-buttons">
                    <button 
                      @click="handleView(reservation)"
                      class="btn-action btn-view"
                      title="View Details"
                    >
                      <i class="fas fa-eye"></i>
                    </button>
                    <button 
                      @click="handleDelete(reservation)"
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
        <div v-if="!loading && filteredReservations.length > 0" class="pagination">
          <div class="pagination-controls">
            <label class="pagination-label">Show:</label>
            <select v-model="itemsPerPage" @change="currentPage = 1" class="pagination-select">
              <option :value="20">20</option>
              <option :value="50">50</option>
              <option :value="100">100</option>
              <option :value="200">200</option>
            </select>
            <span class="pagination-label">per page</span>
          </div>
          <div class="pagination-buttons">
            <button 
              @click="currentPage = Math.max(1, currentPage - 1)" 
              :disabled="currentPage === 1 || loading"
              class="pagination-btn"
              title="Previous Page"
            >
              <i class="fas fa-chevron-left"></i>
            </button>
            <div class="pagination-info">
              <span>Page {{ currentPage }} / {{ totalPages }} ({{ totalCount }} reservations)</span>
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
    </div>
    <!-- Delete Modal -->
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
          <p>Are you sure you want to delete reservation <strong>#{{ reservationToDelete?.id }}</strong>?</p>
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
    <!-- Bulk Delete Reservation Modal -->
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
          <p>Are you sure you want to delete <strong>{{ selectedReservations.length }} reservation(s)</strong> selected?</p>
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
    <!-- View Reservation Modal -->
    <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
      <div class="modal-content quick-modal" @click.stop>
        <div class="modal-header">
          <div class="modal-header-left">
            <div class="order-id-badge">
              <i class="fas fa-calendar-check"></i>
              <span>Reservation #{{ reservationToView?.id }}</span>
            </div>
            <span class="badge modal-status-badge" :class="`status-${reservationToView?.status}`">
              {{ getStatusLabel(reservationToView?.status) }}
            </span>
          </div>
          <button @click="showViewModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div v-if="reservationToView" class="modal-body">
          <!-- Reservation Info Cards -->
          <div class="order-info-grid">
            <!-- Customer Info Card -->
            <div class="info-card">
              <div class="card-header">
                <i class="fas fa-user"></i>
                <h3>Customer Information</h3>
              </div>
              <div class="card-content customer-info-grid">
                <div class="info-item">
                  <span class="info-label">Customer Name</span>
                  <span class="info-value">{{ reservationToView.user_name || 'N/A' }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Email</span>
                  <span class="info-value">{{ reservationToView.user_email || 'N/A' }}</span>
                </div>
              </div>
            </div>
            <!-- Reservation Info Card -->
            <div class="info-card">
              <div class="card-header">
                <i class="fas fa-store"></i>
                <h3>Reservation Information</h3>
              </div>
              <div class="card-content reservation-info-grid">
                <div class="info-item">
                  <span class="info-label">Branch</span>
                  <span class="info-value">{{ reservationToView.branch_name || 'N/A' }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Table</span>
                  <span class="info-value" v-if="reservationToView.table_id">#{{ reservationToView.table_id }}</span>
                  <span class="info-value" v-else>N/A</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Reservation Date</span>
                  <span class="info-value">{{ formatDate(reservationToView.reservation_date) }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Reservation Time</span>
                  <span class="info-value">{{ formatTime(reservationToView.reservation_time) }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Guest Count</span>
                  <span class="info-value">{{ reservationToView.guest_count }} people</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Created Date</span>
                  <span class="info-value">{{ formatDate(reservationToView.created_at) }}</span>
                </div>
              </div>
            </div>
          </div>
          <!-- Reservation Actions Cards -->
          <div class="order-info-grid">
            <!-- Status Update Card -->
            <div class="info-card">
              <div class="card-header">
                <i class="fas fa-info-circle"></i>
                <h3>Change Reservation Status</h3>
              </div>
              <div class="card-content">
                <div class="quick-status-buttons">
                  <button 
                    v-for="statusOption in statusOptions.filter(s => s.value)" 
                    :key="statusOption.value"
                    @click="updateReservationStatus(statusOption.value)"
                    class="btn-quick-status"
                    :class="{ 
                      'btn-danger': statusOption.value === 'cancelled',
                      'active': reservationToView.status === statusOption.value
                    }"
                    :disabled="isUpdatingReservation || !canUpdateToStatus(statusOption.value, reservationToView.status)"
                    :title="!canUpdateToStatus(statusOption.value, reservationToView.status) ? (reservationToView.status === 'completed' || reservationToView.status === 'cancelled' ? 'Cannot update status of completed or cancelled reservations' : 'Cannot revert to previous status') : ''"
                  >
                    {{ statusOption.label }}
                  </button>
                </div>
              </div>
            </div>
          </div>
          <!-- Modal Actions -->
          <div class="modal-actions">
            <button @click="showViewModal = false" class="btn-close">
              <i class="fas fa-times"></i>
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
    <!-- Export Modal -->
    <div v-if="showExportModal" class="modal-overlay" @click.self="showExportModal = false">
      <div class="modal-content export-modal" @click.stop>
        <div class="modal-header">
          <div class="export-header">
            <div class="export-header-icon">
              <i class="fas fa-file-excel"></i>
            </div>
          <h3>Export Reservation List</h3>
          </div>
          <button @click="showExportModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="export-section-card">
            <div class="export-section-header">
            <h4 class="section-title">
              <i class="fas fa-filter"></i>
              Optional Filters
            </h4>
            </div>
            <div class="export-section-body">
            <div class="filter-grid">
                <div class="form-group" v-if="!hideBranchFilter">
                  <label class="label-icon">
                    <i class="fas fa-store"></i>
                    Branch
                  </label>
                  <select v-model="exportFilters.branch_id" class="form-select">
                  <option value="">All Branches</option>
                  <option v-for="branch in branches" :key="branch.id" :value="branch.id">
                    {{ branch.name }}
                  </option>
                </select>
              </div>
              <div class="form-group">
                  <label class="label-icon">
                    <i class="fas fa-tag"></i>
                    Status
                  </label>
                <select v-model="exportFilters.status" class="form-select">
                  <option value="">All Status</option>
                  <option value="pending">Pending</option>
                  <option value="confirmed">Confirmed</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
              <div class="form-group">
                  <label class="label-icon">
                    <i class="fas fa-calendar"></i>
                    From Date
                  </label>
                <input v-model="exportFilters.date_from" type="date" class="form-select" />
              </div>
              <div class="form-group">
                  <label class="label-icon">
                    <i class="fas fa-calendar"></i>
                    To Date
                  </label>
                <input v-model="exportFilters.date_to" type="date" class="form-select" />
              </div>
              <div class="form-group" style="grid-column: 1 / -1;">
                  <label class="label-icon">
                    <i class="fas fa-filter"></i>
                    Filter By
                  </label>
                  <div class="radio-group">
                    <label class="radio-label">
                      <input 
                        type="radio" 
                        v-model="exportFilters.date_type" 
                        value="reservation_date"
                      />
                      <span>Reservation Date</span>
                    </label>
                    <label class="radio-label">
                      <input 
                        type="radio" 
                        v-model="exportFilters.date_type" 
                        value="created_at"
                      />
                      <span>Created Date</span>
                    </label>
                  </div>
                </div>
            </div>
              </div>
            </div>
          </div>
          <div class="modal-actions">
            <button @click="showExportModal = false" class="btn-close">
            <i class="fas fa-times"></i>
              Cancel
            </button>
            <button @click="exportReservations('csv')" class="btn-confirm" :disabled="isExporting">
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
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import ReservationService from '@/services/ReservationService';
import BranchService from '@/services/BranchService';
import AuthService from '@/services/AuthService';
export default {
  name: 'ReservationList',
  components: {
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
      reservations: [],
      loading: false,
      error: null,
      showDeleteModal: false,
      reservationToDelete: null,
      deleteLoading: false,
      showBulkDeleteModal: false,
      bulkDeleteLoading: false,
      showViewModal: false,
      reservationToView: null,
      isUpdatingReservation: false,
      statusOptions: [
        { value: 'pending', label: 'Pending' },
        { value: 'confirmed', label: 'Confirmed' },
        { value: 'completed', label: 'Completed' },
        { value: 'cancelled', label: 'Cancelled' }
      ],
      searchTerm: '',
      branchFilter: this.isManagerView && this.managerBranchId ? String(this.managerBranchId) : '',
      statusFilter: '',
      dateFrom: '',
      dateTo: '',
      reservationStats: {
        total: 0,
        pending: 0,
        confirmed: 0,
        completed: 0,
        cancelled: 0
      },
      branches: [],
      selectedReservations: [],
      currentPage: 1,
      totalPages: 1,
      totalCount: 0,
      itemsPerPage: 50,
      showExportModal: false,
      isExporting: false,
      exportFilters: {
        branch_id: '',
        status: '',
        date_from: '',
        date_to: '',
        date_type: 'reservation_date' 
      }
    };
  },
  computed: {
    isAdmin() {
      return AuthService.isAdmin();
    },
    filteredReservations() {
      let filtered = [...this.reservations];
      if (this.searchTerm) {
        const term = this.searchTerm.toLowerCase().trim();
        filtered = filtered.filter(reservation => {
          const matchesName = reservation.user_name && reservation.user_name.toLowerCase().includes(term);
          const matchesEmail = reservation.user_email && reservation.user_email.toLowerCase().includes(term);
          const matchesId = String(reservation.id).includes(term);
          const matchesTable = reservation.table_id && String(reservation.table_id).includes(term);
          let matchesDate = false;
          if (reservation.reservation_date) {
            try {
              const dateFormatted = this.formatDate(reservation.reservation_date).toLowerCase();
              const dateISO = reservation.reservation_date.toLowerCase();
              const dateObj = new Date(reservation.reservation_date);
              const day = String(dateObj.getDate()).padStart(2, '0');
              const month = String(dateObj.getMonth() + 1).padStart(2, '0');
              const year = String(dateObj.getFullYear());
              matchesDate = 
                dateFormatted.includes(term) || 
                dateISO.includes(term) ||
                day.includes(term) ||
                month.includes(term) ||
                year.includes(term) ||
                `${day}/${month}`.includes(term) ||
                `${day}/${month}/${year}`.includes(term);
            } catch (e) {
              matchesDate = false;
            }
          }
          return matchesName || matchesEmail || matchesId || matchesTable || matchesDate;
        });
      }
      if (this.branchFilter) {
        filtered = filtered.filter(r => r.branch_id == this.branchFilter);
      }
      if (this.statusFilter) {
        filtered = filtered.filter(r => r.status === this.statusFilter);
      }
      if (this.dateFrom) {
        filtered = filtered.filter(r => {
          if (!r.reservation_date) return false;
          const reservationDate = new Date(r.reservation_date);
          reservationDate.setHours(0, 0, 0, 0);
          const fromDate = new Date(this.dateFrom);
          fromDate.setHours(0, 0, 0, 0);
          return reservationDate >= fromDate;
        });
      }
      if (this.dateTo) {
        filtered = filtered.filter(r => {
          if (!r.reservation_date) return false;
          const reservationDate = new Date(r.reservation_date);
          reservationDate.setHours(0, 0, 0, 0);
          const toDate = new Date(this.dateTo);
          toDate.setHours(23, 59, 59, 999);
          return reservationDate <= toDate;
        });
      }
      return filtered;
    },
    paginatedReservations() {
      const start = (this.currentPage - 1) * this.itemsPerPage;
      const end = start + this.itemsPerPage;
      return this.filteredReservations.slice(start, end);
    }
  },
  watch: {
    filteredReservations() {
      this.totalCount = this.filteredReservations.length;
      this.totalPages = Math.max(1, Math.ceil(this.totalCount / this.itemsPerPage));
      if (this.currentPage > this.totalPages && this.totalPages > 0) {
        this.currentPage = this.totalPages;
      }
    },
    itemsPerPage() {
      this.totalPages = Math.max(1, Math.ceil(this.totalCount / this.itemsPerPage));
      if (this.currentPage > this.totalPages && this.totalPages > 0) {
        this.currentPage = this.totalPages;
      }
    }
  },
  async mounted() {
    await Promise.all([
      this.loadReservations(),
      this.loadBranches()
    ]);
  },
  methods: {
    async loadReservations(page = 1) {
      this.loading = true;
      this.error = null;
      try {
        const filters = {};
        if (this.isManagerView && this.managerBranchId) {
          filters.branch_id = this.managerBranchId;
        } else if (this.branchFilter) {
          filters.branch_id = this.branchFilter;
        }
        if (this.statusFilter) filters.status = this.statusFilter;
        if (this.dateFrom) filters.start_date = this.dateFrom;
        if (this.dateTo) filters.end_date = this.dateTo;
        const result = await ReservationService.getAllReservations(filters);
        this.reservations = result.reservations || result || [];
        this.calculateStats();
        this.currentPage = page;
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while loading the reservation list';
        this.error = errorMessage;
        if (this.toast) {
          this.toast.error(errorMessage);
        }
      } finally {
        this.loading = false;
      }
    },
    calculateStats() {
      const stats = {
        total: this.reservations.length,
        pending: 0,
        confirmed: 0,
        completed: 0,
        cancelled: 0
      };
      this.reservations.forEach(reservation => {
        if (stats.hasOwnProperty(reservation.status)) {
          stats[reservation.status]++;
        }
      });
      this.reservationStats = stats;
    },
    handleReset() {
      this.searchTerm = '';
      this.branchFilter = '';
      this.statusFilter = '';
      this.dateFrom = '';
      this.dateTo = '';
    },
    async handleUpdateStatus(id, status) {
      try {
        await ReservationService.updateReservation(id, { status });
        if (this.toast) {
          this.toast.success('Status updated successfully!');
        }
        await this.loadReservations(this.currentPage);
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while updating the status';
        if (this.toast) {
          this.toast.error(errorMessage);
        }
      }
    },
    async handleView(reservation) {
      this.reservationToView = { ...reservation };
      this.showViewModal = true;
    },
    async updateReservationStatus(newStatus) {
      if (!this.reservationToView || this.isUpdatingReservation) return;
      if (!this.canUpdateToStatus(newStatus, this.reservationToView.status)) {
      if (this.toast) {
          if (this.reservationToView.status === 'completed' || this.reservationToView.status === 'cancelled') {
            this.toast.warning('Cannot update status of completed or cancelled reservations');
          } else {
            this.toast.warning('Cannot revert to previous status');
          }
        }
        return;
      }
      this.isUpdatingReservation = true;
      try {
        await ReservationService.updateReservation(this.reservationToView.id, { status: newStatus });
        this.reservationToView.status = newStatus;
      if (this.toast) {
          this.toast.success(`Reservation status updated to "${this.getStatusLabel(newStatus)}" successfully`);
        }
        await this.loadReservations(this.currentPage);
        await this.calculateStats();
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while updating the status';
        if (this.toast) {
          this.toast.error(errorMessage);
        }
      } finally {
        this.isUpdatingReservation = false;
      }
    },
    handleDelete(reservation) {
      this.reservationToDelete = reservation;
      this.showDeleteModal = true;
    },
    async confirmDelete() {
      this.deleteLoading = true;
      try {
        await ReservationService.deleteReservation(this.reservationToDelete.id);
        if (this.toast) {
          this.toast.success('Reservation deleted successfully!');
        }
        await this.loadReservations(this.currentPage);
        this.showDeleteModal = false;
        this.reservationToDelete = null;
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while deleting the reservation';
        if (this.toast) {
          this.toast.error(errorMessage);
        }
      } finally {
        this.deleteLoading = false;
      }
    },
    async loadBranches() {
      try {
        const branches = await BranchService.getAllBranches();
        this.branches = branches || [];
      } catch (error) {
        this.branches = [];
      }
    },
    getStatusLabel(status) {
      const labels = {
        pending: 'Pending',
        confirmed: 'Confirmed',
        completed: 'Completed',
        cancelled: 'Cancelled'
      };
      return labels[status] || status;
    },
    getStatusOrderValue(status) {
      const statusOrder = {
        'pending': 1,
        'confirmed': 2,
        'completed': 3,
        'cancelled': 4
      };
      return statusOrder[status] || 0;
    },
    canUpdateToStatus(targetStatus, currentStatus) {
      if (currentStatus === 'completed' || currentStatus === 'cancelled') {
        return false;
      }
      if (targetStatus === currentStatus) {
        return false;
      }
      if (targetStatus === 'cancelled') {
        return currentStatus === 'pending' || currentStatus === 'confirmed';
      }
      const currentOrder = this.getStatusOrderValue(currentStatus);
      const targetOrder = this.getStatusOrderValue(targetStatus);
      return targetOrder > currentOrder;
    },
    canBulkUpdateToStatus(status) {
      if (this.selectedReservations.length === 0) return false;
      const selectedReservationObjects = this.filteredReservations.filter(reservation => 
        this.selectedReservations.includes(reservation.id)
      );
      const canUpdate = selectedReservationObjects.every(reservation => 
        this.canUpdateToStatus(status, reservation.status)
      );
      return canUpdate;
    },
    formatDate(dateString) {
      if (!dateString) return '-';
      return new Date(dateString).toLocaleDateString('vi-VN');
    },
    formatTime(timeString) {
      if (!timeString) return '-';
      return timeString.substring(0, 5);
    },
    toggleReservationSelection(id) {
      const index = this.selectedReservations.indexOf(id);
      if (index > -1) {
        this.selectedReservations.splice(index, 1);
      } else {
        this.selectedReservations.push(id);
      }
    },
    selectAllReservations() {
      if (this.selectedReservations.length === this.filteredReservations.length) {
        this.selectedReservations = [];
      } else {
        this.selectedReservations = this.filteredReservations.map(r => r.id);
      }
    },
    async bulkUpdateStatus(status) {
      if (this.selectedReservations.length === 0) {
        if (this.toast) {
          this.toast.warning('Please select at least one reservation');
        }
        return;
      }
      if (!this.canBulkUpdateToStatus(status)) {
        if (this.toast) {
          this.toast.warning('Cannot update status backwards. Please select reservations that can be updated to this status.');
        }
        return;
      }
      const statusLabel = this.getStatusLabel(status);
      if (confirm(`Are you sure you want to update ${this.selectedReservations.length} reservation(s) status to "${statusLabel}"?`)) {
        try {
          const promises = this.selectedReservations.map(id => 
            ReservationService.updateReservation(id, { status })
          );
          await Promise.all(promises);
          if (this.toast) {
            this.toast.success(`Updated ${this.selectedReservations.length} reservation(s) status successfully`);
          }
          this.selectedReservations = [];
          await this.loadReservations(this.currentPage);
        } catch (error) {
          const errorMessage = error.message || 'An error occurred while updating status';
          if (this.toast) {
            this.toast.error(errorMessage);
          }
        }
      }
    },
    bulkDeleteReservations() {
      if (this.selectedReservations.length === 0) {
        if (this.toast) {
          this.toast.warning('Please select at least one reservation');
        }
        return;
      }
      this.showBulkDeleteModal = true;
    },
    async confirmBulkDelete() {
      if (this.selectedReservations.length === 0) return;
      this.bulkDeleteLoading = true;
      try {
        const promises = this.selectedReservations.map(id => 
          ReservationService.deleteReservation(id)
        );
        await Promise.all(promises);
        if (this.toast) {
          this.toast.success(`Deleted ${this.selectedReservations.length} reservation(s) successfully`);
        }
        this.selectedReservations = [];
        this.showBulkDeleteModal = false;
        await this.loadReservations(this.currentPage);
      } catch (error) {
        const errorMessage = error.message || 'An error occurred while deleting the reservation';
        if (this.toast) {
          this.toast.error(errorMessage);
        }
      } finally {
        this.bulkDeleteLoading = false;
      }
    },
    openExportModal() {
      const branchId = this.isManagerView && this.managerBranchId 
        ? String(this.managerBranchId) 
        : (this.branchFilter || '');
      this.exportFilters = {
        branch_id: branchId,
        status: this.statusFilter || '',
        date_from: this.dateFrom || '',
        date_to: this.dateTo || '',
        date_type: 'reservation_date' 
      };
      this.showExportModal = true;
    },
    async exportReservations(format = 'csv') {
      this.isExporting = true;
      try {
        const filters = {};
        if (this.isManagerView && this.managerBranchId) {
          filters.branch_id = this.managerBranchId;
        } else if (this.exportFilters.branch_id) {
          filters.branch_id = this.exportFilters.branch_id;
        }
        if (this.exportFilters.status) filters.status = this.exportFilters.status;
        if (this.exportFilters.date_from) filters.start_date = this.exportFilters.date_from;
        if (this.exportFilters.date_to) filters.end_date = this.exportFilters.date_to;
        if (this.exportFilters.date_type === 'created_at') {
          delete filters.start_date;
          delete filters.end_date;
        }
        const result = await ReservationService.getAllReservations(filters);
        let reservationsToExport = result.reservations || result || [];
        if (this.exportFilters.date_from || this.exportFilters.date_to) {
          const dateField = this.exportFilters.date_type || 'reservation_date'; 
          reservationsToExport = reservationsToExport.filter(r => {
            const dateValue = r[dateField];
            if (!dateValue) return false;
            const date = new Date(dateValue);
            date.setHours(0, 0, 0, 0);
            if (this.exportFilters.date_from) {
              const fromDate = new Date(this.exportFilters.date_from);
              fromDate.setHours(0, 0, 0, 0);
              if (date < fromDate) return false;
            }
            if (this.exportFilters.date_to) {
              const toDate = new Date(this.exportFilters.date_to);
              toDate.setHours(23, 59, 59, 999);
              if (date > toDate) return false;
            }
            return true;
          });
        }
        if (reservationsToExport.length === 0) {
          if (this.toast) {
            this.toast.warning('No reservations match the selected filters');
          }
          return;
        }
        if (format === 'csv' || format === 'excel') {
          this.exportToCSV(reservationsToExport);
        }
        this.showExportModal = false;
      } catch (error) {
        const errorMessage = error.message || 'Unable to export reservation list';
        if (this.toast) {
          this.toast.error(errorMessage);
        }
      } finally {
        this.isExporting = false;
      }
    },
    exportToCSV(reservations) {
      const headers = [
        'ID', 'Customer', 'Email', 'Branch', 'Table', 'Reservation Date', 'Reservation Time', 
        'Guest Count', 'Special Requests'
      ];
      const rows = reservations.map(r => [
        r.id,
        r.user_name || 'N/A',
        r.user_email || 'N/A',
        r.branch_name || 'N/A',
        (r.table_id ? '#' + r.table_id : 'N/A'),
        this.formatDate(r.reservation_date),
        this.formatTime(r.reservation_time),
        r.guest_count || 0,
        r.special_requests || '-'
      ]);
      const csvContent = [
        headers.join(','),
        ...rows.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      ].join('\n');
      const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
      const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      const url = URL.createObjectURL(blob);
      link.setAttribute('href', url);
      link.setAttribute('download', `reservation_list_${today}.csv`);
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      if (this.toast) {
        this.toast.success(`Exported ${reservations.length} reservation(s) successfully`);
      }
    }
  }
};
</script>
<style scoped>
.reservation-list {
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
.header-title-section h1 {
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
.btn-export, .btn-refresh {
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
  border: 2px solid #10B981;
  background: white;
  color: #10B981;
}
.btn-export i {
  color: #10B981;
}
.btn-export:hover:not(:disabled) {
  border-color: #059669;
  background: #ECFDF5;
  color: #059669;
}
.btn-export:hover:not(:disabled) i {
  color: #059669;
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
.btn-export:disabled, .btn-refresh:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}
.stat-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  border: 1px solid #E2E8F0;
}
.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
}
.stat-info {
  flex: 1;
}
.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: #1a1a1a;
  line-height: 1.2;
}
.stat-label {
  font-size: 13px;
  color: #6B7280;
  font-weight: 500;
  margin-top: 4px;
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
.reservations-card {
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
  padding: 0;
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
  padding: 10px 8px;
  text-align: left;
  font-size: 10px;
  font-weight: 700;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: 0.3px;
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
.modern-table tbody tr:last-child {
  border-bottom: none;
}
.modern-table tbody tr:last-child td {
  border-bottom: none;
}
.checkbox-col {
  width: 40px;
  padding: 16px !important;
  overflow: visible !important;
  text-overflow: clip !important;
  white-space: normal !important;
}
.checkbox-input {
  width: 18px;
  height: 18px;
  min-width: 18px;
  min-height: 18px;
  cursor: pointer;
  accent-color: #FF8C42;
  flex-shrink: 0;
}
.modern-table td {
  padding: 12px 10px;
  font-size: 12px;
  color: #1E293B;
  vertical-align: middle;
  overflow: visible;
  word-wrap: break-word;
}
.id-col { width: 45px; }
.customer-col { width: 140px; }
.branch-col { width: 170px; }
.table-col { width: 65px; }
.date-col { width: 110px; }
.time-col { width: 100px; }
.guests-col { width: 120px; }
.status-col { width: 105px; }
.status-cell {
  overflow: visible !important;
  text-overflow: clip !important;
}
.actions-col { width: 95px; }
.id-cell {
  font-size: 12px;
  font-weight: 700;
  color: #0F172A;
  overflow: visible !important;
  text-overflow: clip !important;
  white-space: nowrap;
}
.customer-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}
.customer-name {
  font-size: 12px;
  font-weight: 600;
  color: #0F172A;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.customer-email {
  font-size: 11px;
  color: #475569;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.branch-cell {
  overflow: hidden;
  text-overflow: ellipsis;
}
.branch-badge {
  padding: 6px 10px;
  background: #F1F5F9;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 500;
  color: #475569;
  display: inline-block;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 100%;
}
.table-cell {
  overflow: visible !important;
  text-overflow: clip !important;
  white-space: nowrap;
}
.table-badge {
  padding: 6px 10px;
  background: #FFF7ED;
  border: 1px solid #FED7AA;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  color: #92400E;
  display: inline-block;
  white-space: nowrap;
}
.time-cell {
  font-size: 12px;
  font-weight: 600;
  color: #334155;
  overflow: visible !important;
  text-overflow: clip !important;
  white-space: nowrap;
}
.guests-cell {
  overflow: visible !important;
  text-overflow: clip !important;
}
.guests-info {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  font-weight: 600;
  color: #1E293B;
  padding: 6px 10px;
  background: #E0E7FF;
  border: 1px solid #C7D2FE;
  border-radius: 8px;
  width: fit-content;
  white-space: nowrap;
}
.guests-info i {
  color: #6366F1;
  font-size: 13px;
}
.status-badge {
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  display: inline-block;
  letter-spacing: 0.2px;
  border: 1px solid;
}
.status-badge.status-pending {
  background: #FEF3C7;
  color: #92400E;
  border-color: #FDE68A;
}
.status-badge.status-confirmed {
  background: #D1FAE5;
  color: #065F46;
  border-color: #A7F3D0;
}
.status-badge.status-completed {
  background: #DBEAFE;
  color: #1E40AF;
  border-color: #93C5FD;
}
.status-badge.status-cancelled {
  background: #FEE2E2;
  color: #991B1B;
  border-color: #FECACA;
}
.date-cell {
  font-size: 12px;
  color: #475569;
  font-weight: 500;
  overflow: visible !important;
  text-overflow: clip !important;
  white-space: nowrap;
}
.actions-cell {
  overflow: visible !important;
  text-overflow: clip !important;
}
.action-buttons {
  display: flex;
  gap: 6px;
  align-items: center;
}
.btn-action {
  width: 36px;
  height: 36px;
  min-width: 36px;
  flex-shrink: 0;
  border: 1px solid #E5E5E5;
  background: white;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748B;
  transition: all 0.2s ease;
}
.btn-action:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}
.btn-action:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-action.btn-view {
  color: #3B82F6;
  border-color: #DBEAFE;
  background: #EFF6FF;
}
.btn-action.btn-view:hover:not(:disabled) {
  background: #DBEAFE;
  border-color: #3B82F6;
  color: #2563EB;
}
.btn-action.btn-edit {
  color: #10B981;
  border-color: #D1FAE5;
  background: #ECFDF5;
}
.btn-action.btn-edit:hover:not(:disabled) {
  background: #D1FAE5;
  border-color: #10B981;
  color: #059669;
}
.btn-action.btn-delete {
  color: #EF4444;
  border-color: #FEE2E2;
  background: #FEF2F2;
}
.btn-action.btn-delete:hover:not(:disabled) {
  background: #FEE2E2;
  border-color: #EF4444;
  color: #DC2626;
}
.pagination {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  padding: 20px;
  margin-top: 20px;
}
.pagination-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}
.pagination-label {
  font-size: 13px;
  color: #6B7280;
  font-weight: 500;
}
.pagination-select {
  padding: 6px 10px;
  border: 1px solid #E5E5E5;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  color: #1a1a1a;
  cursor: pointer;
  transition: all 0.2s ease;
}
.pagination-select:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.pagination-buttons {
  display: flex;
  align-items: center;
  gap: 16px;
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
  from { opacity: 0; }
  to { opacity: 1; }
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
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
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
  border-radius: 12px;
  background: #FEE2E2;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #EF4444;
  font-size: 24px;
}
.modal-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: #1a1a1a;
}
.btn-close-modal {
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  cursor: pointer;
  border-radius: 8px;
  color: #666;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}
.btn-close-modal:hover {
  background: #F3F4F6;
  color: #1a1a1a;
}
.modal-body {
  padding: 24px;
  flex: 1;
  overflow-y: auto;
}
.modal-body p {
  margin: 0 0 12px 0;
  color: #333;
  font-size: 14px;
}
.modal-body p.warning {
  color: #EF4444;
  font-weight: 500;
}
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 20px 24px;
  border-top: 1px solid #F0E6D9;
}
.btn {
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
.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-secondary {
  background: #F3F4F6;
  color: #6B7280;
  border: 1px solid #E5E5E5;
}
.btn-secondary:hover:not(:disabled) {
  background: #E5E7EB;
}
.btn-danger {
  background: #EF4444;
  color: white;
  border: none;
}
.btn-danger:hover:not(:disabled) {
  background: #DC2626;
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
.export-header {
  display: flex;
  align-items: center;
  gap: 12px;
}
.export-header-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: #FED7AA;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #D97706;
  font-size: 18px;
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
.form-group {
  display: flex;
  flex-direction: column;
  margin-bottom: 0;
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
}
.form-select {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  color: #1E293B;
  font-weight: 500;
  transition: all 0.2s ease;
}
.form-select:focus {
  outline: none;
  border-color: #CBD5E1;
  box-shadow: 0 0 0 3px rgba(226, 232, 240, 0.3);
}
.radio-group {
  display: flex;
  gap: 20px;
  align-items: center;
  margin-top: 4px;
  flex-wrap: wrap;
}
.radio-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  color: #1E293B;
  white-space: nowrap;
}
.radio-label input[type="radio"] {
  width: 18px;
  height: 18px;
  min-width: 18px;
  min-height: 18px;
  cursor: pointer;
  accent-color: #F59E0B;
  flex-shrink: 0;
  margin: 0;
  padding: 0;
}
.radio-label span {
  user-select: none;
  white-space: nowrap;
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
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
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
.quick-modal {
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
.quick-modal .modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.modal-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}
.order-id-badge {
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
.order-id-badge i {
  color: #F59E0B;
  font-size: 14px;
}
.modal-status-badge {
  padding: 8px 14px;
  font-size: 12px;
  font-weight: 600;
  border-radius: 8px;
}
.modal-status-badge.status-pending {
  background: #FEF3C7;
  color: #92400E;
  border: 1px solid #FDE68A;
}
.modal-status-badge.status-confirmed {
  background: #D1FAE5;
  color: #065F46;
  border: 1px solid #A7F3D0;
}
.modal-status-badge.status-completed {
  background: #DBEAFE;
  color: #1E40AF;
  border: 1px solid #93C5FD;
}
.modal-status-badge.status-cancelled {
  background: #FEE2E2;
  color: #991B1B;
  border: 1px solid #FECACA;
}
.quick-modal .btn-close-modal {
  padding: 0;
  border: none;
  background: transparent;
  cursor: pointer;
  color: #64748B;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  line-height: 1;
  font-size: 20px;
  border-radius: 8px;
  transition: all 0.2s ease;
}
.quick-modal .btn-close-modal:hover {
  background: #F3F4F6;
  color: #1E293B;
}
.quick-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.order-info-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
  margin-bottom: 24px;
}
.info-card {
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  overflow: hidden;
}
.card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
}
.card-header i {
  color: #F59E0B;
  font-size: 16px;
  width: 20px;
  text-align: center;
}
.card-header h3 {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
  letter-spacing: -0.2px;
}
.card-content {
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 0;
}
.customer-info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.reservation-info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.info-card {
  display: flex;
  flex-direction: column;
  height: 100%;
}
.card-content .info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 8px 0;
  border-bottom: 1px solid #F1F5F9;
}
.card-content .info-item:last-child {
  border-bottom: none;
  padding-bottom: 0;
}
.customer-info-grid .info-item {
  border-bottom: none;
  padding: 8px 0;
}
.reservation-info-grid .info-item {
  border-bottom: 1px solid #F1F5F9;
  padding: 8px 0;
}
.reservation-info-grid .info-item:nth-last-child(-n+2) {
  border-bottom: none;
  padding-bottom: 0;
}
.card-content .info-label {
  font-size: 12px;
  font-weight: 500;
  color: #64748B;
  letter-spacing: 0;
  text-transform: none;
  margin-bottom: 2px;
}
.card-content .info-value {
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  word-break: break-word;
}
.quick-status-buttons {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  align-items: stretch;
  margin-top: 4px;
}
.btn-quick-status {
  padding: 10px 16px;
  border: 1px solid #86EFAC;
  background: white;
  color: #16A34A;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
  min-width: 120px;
  text-align: center;
  flex: 1;
  box-sizing: border-box;
}
.btn-quick-status:hover:not(:disabled) {
  background: #F0FDF4;
  border-color: #4ADE80;
  color: #15803D;
}
.btn-quick-status:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-quick-status.active {
  background: #16A34A;
  border-color: #16A34A;
  color: white;
  font-weight: 600;
}
.btn-quick-status.btn-danger {
  color: #DC2626;
  border-color: #FCA5A5;
  background: white;
}
.btn-quick-status.btn-danger:hover:not(:disabled) {
  background: #FEF2F2;
  border-color: #F87171;
  color: #B91C1C;
}
.btn-quick-status.btn-danger.active {
  background: #DC2626;
  border-color: #DC2626;
  color: white;
}
.quick-modal .modal-actions {
  padding: 16px 20px;
  background: #FFF7ED;
  border-top: 1px solid #FED7AA;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  flex-shrink: 0;
}
.quick-modal .modal-actions .btn-close {
  padding: 12px 20px;
  border: 2px solid #F0E6D9;
  background: white;
  color: #666;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
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
.quick-modal .modal-actions .btn-close:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.btn-close {
  padding: 10px 20px;
  border: 2px solid #EF4444;
  background: white;
  color: #EF4444;
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
.btn-close:hover {
  background: #EF4444;
  color: white;
}
</style>
