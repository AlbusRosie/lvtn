<script setup>
import { ref, computed, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import UserForm from '@/components/Admin/User/UserForm.vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import usersService from '@/services/UserService';
import branchService from '@/services/BranchService';
import { ROLE_NAMES, USER_ROLES, DEFAULT_AVATAR } from '@/constants';
import { useMutation, useQueryClient } from '@tanstack/vue-query';
import { useToast } from 'vue-toastification';
const props = defineProps({
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
});
const toast = useToast();
const router = useRouter();
const route = useRoute();
const queryClient = useQueryClient();
const totalPages = ref(1);
const currentPage = computed(() => {
  const page = Number(route.query?.page);
  if (Number.isNaN(page) || page < 1) return 1;
  return page;
});
const users = ref([]);
const searchText = ref('');
const selectedRole = ref('');
const selectedRecent = ref(''); 
const selectedBranch = ref(props.isManagerView && props.managerBranchId ? String(props.managerBranchId) : '');
const branches = ref([]);
const isLoading = ref(true);
const error = ref(null);
const showModal = ref(false);
const modalUser = ref(null);
const showDeleteModal = ref(false);
const userToDelete = ref(null);
const deleteLoading = ref(false);
const selectedUsers = ref([]);
const bulkBranchId = ref('');
const isBulkAssigning = ref(false);
const updatingUsers = ref(new Set()); 
const isExporting = ref(false);
const showExportModal = ref(false);
const exportFilters = ref({
  role_id: '',
  branch_id: '',
  recent: ''
});
const staffStats = computed(() => {
  const allStaff = users.value.filter(user => user.role_id !== USER_ROLES.CUSTOMER);
  const total = allStaff.length;
  const now = new Date();
  const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const new3Days = allStaff.filter(user => {
    if (!user.created_at) return false;
    return new Date(user.created_at) >= threeDaysAgo;
  }).length;
  const new7Days = allStaff.filter(user => {
    if (!user.created_at) return false;
    return new Date(user.created_at) >= sevenDaysAgo;
  }).length;
  const byRole = {
    admin: allStaff.filter(u => u.role_id === USER_ROLES.ADMIN).length,
    manager: allStaff.filter(u => u.role_id === USER_ROLES.MANAGER).length,
    staff: allStaff.filter(u => u.role_id === USER_ROLES.STAFF).length,
    kitchen: allStaff.filter(u => u.role_id === USER_ROLES.KITCHEN_STAFF).length,
    cashier: allStaff.filter(u => u.role_id === USER_ROLES.CASHIER).length,
    delivery: allStaff.filter(u => u.role_id === USER_ROLES.DELIVERY_STAFF).length
  };
  return {
    total,
    new3Days,
    new7Days,
    byRole
  };
});
const filteredUsers = computed(() => {
  let filtered = users.value.filter(user => user.role_id !== USER_ROLES.CUSTOMER);
  if (searchText.value) {
    filtered = filtered.filter((user) => {
      const searchValue = searchText.value.toLowerCase();
      return [user.name, user.email, user.address, user.phone, user.username]
        .join('')
        .toLowerCase()
        .includes(searchValue);
    });
  }
  if (selectedRole.value) {
    filtered = filtered.filter(user => user.role_id == selectedRole.value);
  }
  if (selectedBranch.value) {
    if (selectedBranch.value === 'none') {
      filtered = filtered.filter(user => !user.branch_id || user.branch_id === null);
    } else {
      filtered = filtered.filter(user => user.branch_id == selectedBranch.value);
    }
  }
  if (selectedRecent.value) {
    const now = new Date();
    const daysAgo = selectedRecent.value === '3d' ? 3 : 7;
    const cutoffDate = new Date(now.getTime() - daysAgo * 24 * 60 * 60 * 1000);
    filtered = filtered.filter(user => {
      if (!user.created_at) return false;
      return new Date(user.created_at) >= cutoffDate;
    });
  }
  return filtered;
});
async function retrieveUsers(page) {
  isLoading.value = true;
  error.value = null;
  try {
    const filters = {};
    filters.not_role_id = USER_ROLES.CUSTOMER;
    if (searchText.value) {
      filters.search = searchText.value;
    }
    if (selectedRole.value) {
      filters.role_id = selectedRole.value;
    }
    if (props.isManagerView && props.managerBranchId) {
      filters.branch_id = props.managerBranchId;
    } else if (selectedBranch.value) {
      filters.branch_id = selectedBranch.value; 
    }
    if (selectedRecent.value) {
      filters.recent = selectedRecent.value; 
    }
    const chunk = await usersService.fetchUsers(page, 6, filters);
    totalPages.value = chunk.metadata.lastPage ?? 1;
    users.value = chunk.users.sort((current, next) => current.name.localeCompare(next.name));
    } catch (err) {
    error.value = 'An error occurred while loading staff list.';
  } finally {
    isLoading.value = false;
  }
}
const deleteUserMutation = useMutation({
  mutationFn: usersService.deleteUser,
  onSuccess: () => {
    toast.success('Staff deleted successfully!');
    queryClient.invalidateQueries(['users']);
    retrieveUsers(currentPage.value);
    showDeleteModal.value = false;
  },
  onError: (error) => {
    toast.error('An error occurred while deleting staff!');
    }
});
const updateBranchMutation = useMutation({
  mutationFn: ({ userId, branchId }) => {
    const formData = new FormData();
    if (branchId) formData.append('branch_id', branchId);
    else formData.append('branch_id', '');
    return usersService.updateUser(userId, formData);
  },
  onSuccess: () => {
    toast.success('Branch updated successfully!');
    queryClient.invalidateQueries(['users']);
    retrieveUsers(currentPage.value);
  },
  onError: (error) => {
    toast.error('An error occurred while updating branch!');
    }
});
const createUserMutation = useMutation({
  mutationFn: (formData) => usersService.createUser(formData),
  onSuccess: () => {
    toast.success('Staff created successfully!');
    queryClient.invalidateQueries(['users']);
    retrieveUsers(currentPage.value);
    showModal.value = false;
    modalUser.value = null;
  },
  onError: (error) => {
    toast.error('An error occurred while creating staff!');
    }
});
const updateUserMutation = useMutation({
  mutationFn: ({ userId, formData }) => usersService.updateUser(userId, formData),
  onSuccess: () => {
    toast.success('Staff updated successfully!');
    queryClient.invalidateQueries(['users']);
    queryClient.invalidateQueries(['user', modalUser.value?.id]);
    retrieveUsers(currentPage.value);
    showModal.value = false;
    modalUser.value = null;
  },
  onError: (error) => {
    toast.error('An error occurred while updating staff!');
    }
});
function handleDelete(user) {
  userToDelete.value = user;
  showDeleteModal.value = true;
}
function confirmDelete() {
  if (userToDelete.value) {
    deleteLoading.value = true;
    deleteUserMutation.mutate(userToDelete.value.id);
  }
}
function showUserDetails(user) {
  modalUser.value = user;
  showModal.value = true;
}
function showCreateModal() {
  modalUser.value = null;
  showModal.value = true;
}
function handleUpdateUser(formData) {
  if (modalUser.value?.id) {
    updateUserMutation.mutate({ userId: modalUser.value.id, formData });
  } else {
    createUserMutation.mutate(formData);
  }
}
function handleDeleteFromModal() {
  if (modalUser.value) {
    userToDelete.value = modalUser.value;
    showModal.value = false;
    showDeleteModal.value = true;
  }
}
function formatDate(dateString) {
  if (!dateString) return 'N/A';
  const date = new Date(dateString);
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = date.getFullYear();
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  return `${hours}:${minutes}:${seconds} ${day}/${month}/${year}`;
}
function changeCurrentPage(page) {
  if (page < 1) page = 1;
  if (page > totalPages.value) page = totalPages.value;
  router.push({ 
    path: route.path,
    query: { ...route.query, page }
  });
}
function handleSearch() {
  retrieveUsers(1);
}
function handleRoleFilter() {
  retrieveUsers(1);
}
function handleRecentFilter() {
  retrieveUsers(1);
}
function handleBranchFilter() {
  retrieveUsers(1);
}
function clearFilters() {
  searchText.value = '';
  selectedRole.value = '';
  selectedBranch.value = '';
  selectedRecent.value = '';
  retrieveUsers(1);
}
async function loadBranches() {
  try {
    const response = await branchService.getActiveBranches();
    branches.value = response.data || response || [];
  } catch (error) {
    branches.value = [];
  }
}
function openExportModal() {
  exportFilters.value = {
    role_id: selectedRole.value || '',
    branch_id: props.isManagerView && props.managerBranchId 
      ? String(props.managerBranchId) 
      : (selectedBranch.value || ''),
    recent: selectedRecent.value || ''
  };
  showExportModal.value = true;
}
async function exportToExcel() {
  isExporting.value = true;
  try {
    const filters = {};
    filters.not_role_id = USER_ROLES.CUSTOMER;
    if (exportFilters.value.role_id) {
      filters.role_id = exportFilters.value.role_id;
    }
    if (props.isManagerView && props.managerBranchId) {
      filters.branch_id = props.managerBranchId;
    } else if (exportFilters.value.branch_id) {
      filters.branch_id = exportFilters.value.branch_id; 
    }
    if (exportFilters.value.recent) {
      filters.recent = exportFilters.value.recent;
    }
    let allUsers = [];
    let page = 1;
    let totalPages = 1;
    const firstChunk = await usersService.fetchUsers(page, 100, filters);
    if (firstChunk.users && firstChunk.users.length > 0) {
      allUsers = allUsers.concat(firstChunk.users);
      totalPages = firstChunk.metadata?.lastPage || 1;
      if (totalPages > 1) {
        const remainingPages = [];
        for (let p = 2; p <= totalPages; p++) {
          remainingPages.push(usersService.fetchUsers(p, 100, filters));
        }
        const remainingChunks = await Promise.all(remainingPages);
        remainingChunks.forEach(chunk => {
          if (chunk.users && chunk.users.length > 0) {
            allUsers = allUsers.concat(chunk.users);
          }
        });
      }
    }
    allUsers = allUsers.filter(user => user.role_id !== USER_ROLES.CUSTOMER);
    if (allUsers.length === 0) {
      toast.warning('No staff match the selected filters');
      return;
    }
    allUsers.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    const headers = ['ID', 'Staff Name', 'Username', 'Email', 'Phone', 'Role', 'Branch', 'Address', 'Created Date'];
    const rows = allUsers.map(user => [
      user.id,
      user.name || 'N/A',
      user.username || 'N/A',
      user.email || 'N/A',
      user.phone || 'N/A',
      ROLE_NAMES[user.role_id] || 'N/A',
      user.branch_name || 'Not assigned',
      user.address || 'N/A',
      formatDate(user.created_at)
    ]);
    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
    ].join('\n');
    const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
    const filename = `staff_list_${today}`;
    const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `${filename}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success(`Exported ${allUsers.length} staff member(s) successfully`);
    showExportModal.value = false;
  } catch (error) {
    toast.error('An error occurred while exporting file');
    } finally {
    isExporting.value = false;
  }
}
watch(currentPage, (newPage) => {
  retrieveUsers(newPage);
});
async function updateUserBranch(userId, branchId) {
  updatingUsers.value.add(userId);
  try {
    await updateBranchMutation.mutateAsync({ userId, branchId });
  } finally {
    updatingUsers.value.delete(userId);
  }
}
async function bulkAssignBranch() {
  if (!bulkBranchId.value) {
    toast.warning('Please select a branch');
    return;
  }
  if (selectedUsers.value.length === 0) {
    toast.warning('Please select at least one staff member');
    return;
  }
  isBulkAssigning.value = true;
  try {
    const promises = selectedUsers.value.map(userId => 
      updateBranchMutation.mutateAsync({ userId, branchId: bulkBranchId.value })
    );
    await Promise.all(promises);
    toast.success(`Assigned ${selectedUsers.value.length} staff member(s)!`);
    selectedUsers.value = [];
    bulkBranchId.value = '';
  } catch (error) {
    } finally {
    isBulkAssigning.value = false;
  }
}
function toggleUserSelection(userId) {
  const index = selectedUsers.value.indexOf(userId);
  if (index > -1) {
    selectedUsers.value.splice(index, 1);
  } else {
    selectedUsers.value.push(userId);
  }
}
function toggleSelectAll() {
  if (selectedUsers.value.length === filteredUsers.value.length) {
    selectedUsers.value = [];
  } else {
    selectedUsers.value = filteredUsers.value.map(u => u.id);
  }
}
loadBranches();
retrieveUsers(currentPage.value);
</script>
<template>
  <div class="staff-list">
    <!-- Bulk Assignment Bar -->
    <div v-if="selectedUsers.length > 0 && !isManagerView" class="bulk-assign-bar">
      <div class="bulk-info">
        <i class="fas fa-users"></i>
        <span>Selected <strong>{{ selectedUsers.length }}</strong> staff member(s)</span>
      </div>
      <div class="bulk-actions">
        <select v-model="bulkBranchId" class="bulk-branch-select">
          <option value="">Select Branch</option>
          <option v-for="branch in branches" :key="branch.id" :value="branch.id">
            {{ branch.name }}
          </option>
        </select>
        <button 
          @click="bulkAssignBranch" 
          class="btn-bulk-assign"
          :disabled="!bulkBranchId || isBulkAssigning"
        >
          <i class="fas fa-check"></i>
          <span v-if="isBulkAssigning">Assigning...</span>
          <span v-else>Bulk Assign</span>
        </button>
        <button @click="selectedUsers = []" class="btn-clear-selection">
          <i class="fas fa-times"></i>
          Deselect
        </button>
      </div>
    </div>
    <!-- Statistics Section -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon" style="background: #ECFDF5; color: #10B981;">
          <i class="fas fa-users"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ staffStats.total }}</div>
          <div class="stat-label">Total Staff</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #D1FAE5; color: #059669;">
          <i class="fas fa-user-plus"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ staffStats.new3Days }}</div>
          <div class="stat-label">New 3 Days</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #FEF3C7; color: #D97706;">
          <i class="fas fa-calendar-week"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ staffStats.new7Days }}</div>
          <div class="stat-label">New 7 Days</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #E0E7FF; color: #6366F1;">
          <i class="fas fa-filter"></i>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ filteredUsers.length }}</div>
          <div class="stat-label">Displaying</div>
        </div>
      </div>
    </div>
    <!-- Filters Section -->
    <div class="filters-card">
      <div class="filters-header">
        <h3>Filters</h3>
        <button v-if="searchText || selectedRole || selectedBranch || selectedRecent" 
                @click="clearFilters" class="btn-clear-filters">
          <i class="fas fa-times"></i>
          Clear Filters
        </button>
      </div>
      <div class="filters-grid">
        <div class="filter-group">
          <label>Search</label>
        <input
          v-model="searchText"
          @keyup.enter="handleSearch"
            class="filter-input"
          placeholder="Search staff..."
        />
        </div>
        <div class="filter-group">
          <label>Role</label>
        <select v-model="selectedRole" @change="handleRoleFilter" class="filter-select">
          <option value="">All Roles</option>
          <option :value="USER_ROLES.ADMIN">Admin</option>
          <option :value="USER_ROLES.MANAGER">Manager</option>
          <option :value="USER_ROLES.STAFF">Staff</option>
          <option :value="USER_ROLES.KITCHEN_STAFF">Kitchen Staff</option>
          <option :value="USER_ROLES.CASHIER">Cashier & Receptionist</option>
          <option :value="USER_ROLES.DELIVERY_STAFF">Delivery Staff</option>
        </select>
        </div>
        <div v-if="!hideBranchFilter" class="filter-group">
          <label>Branch</label>
        <select v-model="selectedBranch" @change="handleBranchFilter" class="filter-select">
          <option value="">All Branches</option>
          <option value="none">Not Assigned</option>
          <option v-for="branch in branches" :key="branch.id" :value="branch.id">
            {{ branch.name }}
          </option>
        </select>
        </div>
        <div class="filter-group">
          <label>Time</label>
        <select v-model="selectedRecent" @change="handleRecentFilter" class="filter-select">
          <option value="">All Time</option>
          <option value="3d">New 3 Days</option>
          <option value="7d">New 7 Days</option>
        </select>
      </div>
    </div>
      </div>
    <div class="content-area">
        <div v-if="isLoading" class="loading">
          <LoadingSpinner />
          <p>Loading staff list...</p>
        </div>
        <div v-else-if="error" class="error">
          <i class="fas fa-exclamation-triangle"></i>
          <p>{{ error }}</p>
          <button @click="retrieveUsers(currentPage)" class="btn btn-secondary">
            Retry
          </button>
        </div>
        <div v-else-if="filteredUsers.length === 0" class="empty-state">
          <i class="fas fa-users"></i>
          <h3>No Staff Found</h3>
          <p v-if="searchText || selectedRole || selectedRecent">
            No staff match the current filters
          </p>
          <p v-else>
            No staff have been created yet. Add the first staff member!
          </p>
        <button @click="showCreateModal" class="btn btn-primary">
          Add First Staff Member
        </button>
        </div>
        <!-- Table View -->
      <div v-else class="tables-card">
          <div class="table-header-section">
            <div class="table-title">
              <h3>Staff List</h3>
              <span class="table-count">{{ filteredUsers.length }} staff members</span>
            </div>
            <div class="header-actions">
            <button @click="openExportModal" class="btn-export" :disabled="isLoading">
              <i class="fas fa-file-excel"></i>
              Export Excel
            </button>
            <button @click="showCreateModal" class="btn-add" :disabled="isLoading">
                <i class="fas fa-plus"></i>
                Add Staff
              </button>
            <button @click="retrieveUsers(currentPage)" class="btn-refresh" :disabled="isLoading">
                <i class="fas fa-sync"></i>
                Refresh
              </button>
            </div>
          </div>
          <div class="users-table-wrapper">
        <table class="users-table">
          <thead>
            <tr>
              <th class="col-checkbox">
                <input 
                  type="checkbox" 
                  :checked="selectedUsers.length === filteredUsers.length && filteredUsers.length > 0"
                  @change="toggleSelectAll"
                    class="checkbox-input"
                />
              </th>
              <th class="col-avatar">Avatar</th>
              <th class="col-name">Staff Name</th>
              <th class="col-email">Email</th>
              <th class="col-phone">Phone</th>
              <th class="col-role">Role</th>
              <th class="col-branch">Branch</th>
              <th class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="user in filteredUsers" :key="user.id" class="user-row">
              <td class="col-checkbox">
                <input 
                  type="checkbox" 
                  :checked="selectedUsers.includes(user.id)"
                  @change="toggleUserSelection(user.id)"
                    class="checkbox-input"
                />
              </td>
              <td class="col-avatar">
                <img 
                  :src="user.avatar || DEFAULT_AVATAR" 
                  :alt="user.name"
                  class="user-avatar-img"
                />
              </td>
              <td class="col-name">
                <strong>{{ user.name }}</strong>
                <div class="username">{{ user.username }}</div>
              </td>
              <td class="col-email">{{ user.email }}</td>
              <td class="col-phone">{{ user.phone || '-' }}</td>
              <td class="col-role">
                <span class="role-badge-small" :class="{
                  'role-admin': user.role_id === USER_ROLES.ADMIN,
                  'role-manager': user.role_id === USER_ROLES.MANAGER,
                  'role-staff': user.role_id === USER_ROLES.STAFF,
                  'role-kitchen': user.role_id === USER_ROLES.KITCHEN_STAFF,
                  'role-cashier': user.role_id === USER_ROLES.CASHIER,
                  'role-delivery': user.role_id === USER_ROLES.DELIVERY_STAFF
                }">
                  {{ ROLE_NAMES[user.role_id] || 'N/A' }}
                </span>
              </td>
              <td class="col-branch">
                <select 
                  v-if="!isManagerView"
                  :value="user.branch_id || ''" 
                  @change="updateUserBranch(user.id, $event.target.value)"
                  :disabled="updatingUsers.has(user.id)"
                  class="branch-select-inline"
                >
                  <option value="">Not Assigned</option>
                  <option v-for="branch in branches" :key="branch.id" :value="branch.id">
                    {{ branch.name }}
                  </option>
                </select>
                <span v-else class="branch-readonly">
                  {{ branches.find(b => b.id == user.branch_id)?.name || 'Not Assigned' }}
                </span>
                <i v-if="updatingUsers.has(user.id)" class="fas fa-spinner fa-spin updating-icon"></i>
              </td>
              <td class="col-actions">
                <div class="table-actions">
                  <button @click="showUserDetails(user)" class="btn-icon" title="View and Edit">
                    <i class="fas fa-eye"></i>
                  </button>
                  <button @click="handleDelete(user)" class="btn-icon btn-icon-danger" title="Delete">
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
            @click="changeCurrentPage(currentPage - 1)" 
            :disabled="currentPage === 1 || isLoading"
            class="pagination-btn"
            title="Previous Page"
          >
            <i class="fas fa-chevron-left"></i>
          </button>
          <div class="pagination-info">
            <span>Page {{ currentPage }} / {{ totalPages }}</span>
          </div>
          <button 
          @click="changeCurrentPage(currentPage + 1)"
            :disabled="currentPage === totalPages || isLoading"
            class="pagination-btn"
          title="Next Page"
        >
          <i class="fas fa-chevron-right"></i>
        </button>
      </div>
    </div>
    </div>
    <!-- User Details/Edit/Create Modal -->
    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal-content user-form-modal" @click.stop>
        <div class="modal-header">
          <div class="modal-header-left">
            <div class="user-action-badge">
              <i :class="modalUser ? 'fas fa-user-edit' : 'fas fa-user-plus'"></i>
              <span>{{ modalUser ? 'Edit Staff' : 'Add New Staff' }}</span>
            </div>
            <span v-if="modalUser" class="badge role-badge-in-modal" :class="{
              'role-admin': modalUser.role_id === USER_ROLES.ADMIN,
              'role-manager': modalUser.role_id === USER_ROLES.MANAGER,
              'role-staff': modalUser.role_id === USER_ROLES.STAFF,
              'role-kitchen': modalUser.role_id === USER_ROLES.KITCHEN_STAFF,
              'role-cashier': modalUser.role_id === USER_ROLES.CASHIER,
              'role-delivery': modalUser.role_id === USER_ROLES.DELIVERY_STAFF
            }">
              {{ ROLE_NAMES[modalUser.role_id] || 'N/A' }}
            </span>
          </div>
          <button @click="showModal = false; modalUser = null" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <UserForm 
            :user="modalUser || { role_id: USER_ROLES.STAFF }" 
            :is-manager-view="props.isManagerView"
            :manager-branch-id="props.managerBranchId"
            @submit:user="handleUpdateUser"
            @delete:user="handleDeleteFromModal"
          />
        </div>
      </div>
    </div>
    <!-- Export Modal -->
    <div v-if="showExportModal" class="modal-overlay" @click.self="showExportModal = false">
      <div class="modal-content export-modal" @click.stop>
        <div class="modal-header">
          <h3>Export Staff List</h3>
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
                  <i class="fas fa-user-tag label-icon"></i>
                  Role
                </label>
                <select v-model="exportFilters.role_id" class="form-select">
                  <option value="">All Roles</option>
                  <option :value="USER_ROLES.ADMIN">Admin</option>
                  <option :value="USER_ROLES.MANAGER">Manager</option>
                  <option :value="USER_ROLES.STAFF">Staff</option>
                  <option :value="USER_ROLES.KITCHEN_STAFF">Kitchen Staff</option>
                  <option :value="USER_ROLES.CASHIER">Cashier & Receptionist</option>
                  <option :value="USER_ROLES.DELIVERY_STAFF">Delivery Staff</option>
                </select>
              </div>
              <div v-if="!hideBranchFilter && !(props.isManagerView && props.managerBranchId)" class="form-group">
                <label>
                  <i class="fas fa-building label-icon"></i>
                  Branch
                </label>
                <select v-model="exportFilters.branch_id" class="form-select">
                  <option value="">All Branches</option>
                  <option value="none">Not Assigned</option>
                  <option v-for="branch in branches" :key="branch.id" :value="branch.id">
                    {{ branch.name }}
                  </option>
                </select>
              </div>
              <div class="form-group">
                <label>
                  <i class="fas fa-calendar label-icon"></i>
                  Time
                </label>
                <select v-model="exportFilters.recent" class="form-select">
                  <option value="">All Time</option>
                  <option value="3d">New 3 Days</option>
                  <option value="7d">New 7 Days</option>
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
    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteModal" class="modal-overlay" @click.self="showDeleteModal = false">
      <div class="modal-content delete-modal" @click.stop>
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
          <p>Are you sure you want to delete staff member <strong>{{ userToDelete?.name }}</strong>?</p>
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
<style scoped>
.staff-list {
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
.btn-add:disabled, .btn-refresh:disabled, .btn-export:disabled {
  opacity: 0.6;
  cursor: not-allowed;
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
.tables-card {
  background: #FAFBFC;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #E2E8F0;
  margin-bottom: 20px;
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
  margin-bottom: 20px;
}
.error i {
  color: #ef4444;
}
.empty-state i {
  color: #6b7280;
  opacity: 0.5;
}
.bulk-assign-bar {
  background: linear-gradient(135deg, #FFF3E0, #FFE8CC);
  border: 2px solid #FF8C42;
  border-radius: 20px;
  padding: 20px 28px;
  margin-bottom: 28px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 15px;
}
.bulk-info {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 15px;
  color: #D35400;
  font-weight: 600;
}
.bulk-info i {
  font-size: 20px;
  color: #FF8C42;
}
.bulk-actions {
  display: flex;
  gap: 12px;
  align-items: center;
  flex-wrap: wrap;
}
.bulk-branch-select {
  padding: 12px 18px;
  border: 2px solid #FF8C42;
  border-radius: 16px;
  font-size: 14px;
  min-width: 220px;
  background: white;
  color: #333;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}
.bulk-branch-select:focus {
  outline: none;
}
.btn-bulk-assign {
  padding: 12px 24px;
  background: linear-gradient(135deg, #FF8C42, #E67E22);
  color: white;
  border: none;
  border-radius: 16px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: background 0.2s ease;
}
.btn-bulk-assign:hover:not(:disabled) {
  background: linear-gradient(135deg, #E67E22, #D35400);
}
.btn-bulk-assign:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}
.btn-clear-selection {
  padding: 12px 20px;
  background: white;
  color: #666;
  border: 2px solid #F0E6D9;
  border-radius: 16px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s ease;
}
.btn-clear-selection:hover {
  background: #FFF3E0;
  border-color: #FF8C42;
  color: #FF8C42;
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
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
}
.header-actions {
  display: flex;
  flex-direction: row;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
}
.users-table-wrapper {
  background: white;
  border-radius: 10px;
  overflow: hidden;
  border: 1px solid #E2E8F0;
}
.users-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  background: white;
  table-layout: fixed;
}
.users-table thead {
  background: #F8F9FA;
}
.users-table th {
  padding: 14px 16px;
  text-align: left;
  font-size: 12px;
  font-weight: 700;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 2px solid #E2E8F0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.users-table tbody tr {
  transition: all 0.2s ease;
  border-bottom: 1px solid #F1F5F9;
}
.users-table tbody tr:hover {
  background: #F8F9FA;
}
.users-table tbody tr.row-selected {
  background: #FFF9F5 !important;
}
.users-table tbody tr:last-child td {
  border-bottom: none;
}
.users-table td {
  padding: 14px 16px;
  font-size: 13px;
  color: #1E293B;
  vertical-align: middle;
  overflow: hidden;
  text-overflow: ellipsis;
  word-wrap: break-word;
}
.col-checkbox {
  width: 40px;
  padding: 16px !important;
  overflow: visible !important;
  text-overflow: clip !important;
  white-space: normal !important;
}
.checkbox-input {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #FF8C42;
}
.col-avatar {
  width: 60px;
}
.user-avatar-img {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #e9ecef;
}
.col-name {
  min-width: 180px;
}
.col-name {
  font-size: 13px;
  color: #0F172A;
}
.col-name strong {
  font-weight: 700;
  color: #0F172A;
  font-size: 13px;
}
.col-name .username {
  font-size: 12px;
  color: #475569;
  margin-top: 2px;
}
.col-email {
  font-size: 13px;
  color: #1E293B;
}
.col-phone {
  font-size: 13px;
  color: #475569;
}
.col-role {
  min-width: 120px;
}
.role-badge-small {
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  display: inline-block;
}
.role-admin {
  background: #fee2e2;
  color: #dc2626;
}
.role-manager {
  background: #f3e8ff;
  color: #7c3aed;
}
.role-staff {
  background: #fef3c7;
  color: #d97706;
}
.role-kitchen {
  background: #fef2f2;
  color: #ef4444;
}
.role-cashier {
  background: #ecfdf5;
  color: #059669;
}
.role-delivery {
  background: #f0f9ff;
  color: #0284c7;
}
.col-branch {
  min-width: 200px;
}
.branch-select-inline {
  width: 100%;
  padding: 10px 14px;
  border: 2px solid #F0E6D9;
  border-radius: 12px;
  font-size: 13px;
  background: white;
  color: #333;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}
.branch-select-inline:focus {
  outline: none;
  border-color: #FF8C42;
}
.branch-select-inline:disabled {
  background: #F8F8F8;
  cursor: not-allowed;
  opacity: 0.6;
}
.branch-readonly {
  display: inline-block;
  padding: 6px 12px;
  color: #374151;
  font-size: 14px;
  font-weight: 500;
}
.col-branch {
  position: relative;
}
.updating-icon {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  color: #007bff;
  font-size: 12px;
}
.col-actions {
  width: 120px;
}
.table-actions {
  display: flex;
  gap: 8px;
  align-items: center;
}
.btn-icon {
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
  font-size: 14px;
  transition: all 0.2s ease;
}
.btn-icon:hover {
  background: #F8F9FA;
  border-color: #D1D5DB;
  color: #334155;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}
.btn-icon-danger {
  color: #EF4444;
}
.btn-icon-danger:hover {
  background: #FEF2F2;
  border-color: #EF4444;
  color: #DC2626;
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
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
  backdrop-filter: blur(2px);
}
.modal-content {
  background: white;
  border-radius: 20px;
  padding: 0;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12);
  border: 1px solid #F0E6D9;
}
.modal-content-large {
  max-width: 500px;
}
.user-form-modal {
  background: white;
  border-radius: 14px;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
}
.user-form-modal .modal-header {
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-shrink: 0;
}
.user-form-modal .modal-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}
.user-action-badge {
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
.user-action-badge i {
  color: #F59E0B;
  font-size: 14px;
}
.role-badge-in-modal {
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 600;
  border-radius: 6px;
}
.role-badge-in-modal.role-admin {
  background: #FEE2E2;
  color: #DC2626;
}
.role-badge-in-modal.role-manager {
  background: #DBEAFE;
  color: #2563EB;
}
.role-badge-in-modal.role-staff {
  background: #D1FAE5;
  color: #059669;
}
.role-badge-in-modal.role-kitchen {
  background: #FEF3C7;
  color: #D97706;
}
.role-badge-in-modal.role-cashier {
  background: #E0E7FF;
  color: #6366F1;
}
.role-badge-in-modal.role-delivery {
  background: #FCE7F3;
  color: #DB2777;
}
.user-form-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
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
.export-options {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.export-option-checkbox {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  padding: 12px;
  border-radius: 8px;
  transition: background 0.2s ease;
}
.export-option-checkbox:hover {
  background: #F3F4F6;
}
.export-option-checkbox input[type="checkbox"] {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #F59E0B;
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
.modal-header {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding: 20px 28px;
  border-bottom: 1px solid #F0E6D9;
}
.close-btn {
  background: white;
  border: 2px solid #F0E6D9;
  font-size: 16px;
  cursor: pointer;
  color: #666;
  padding: 0;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  transition: all 0.2s ease;
}
.close-btn:hover {
  background: #FFEBEE;
  border-color: #ef4444;
  color: #ef4444;
}
.modal-body {
  padding: 28px;
  overflow-y: auto;
  flex: 1;
}
.modal-body :deep(.user-form) {
  border: none;
  padding: 0;
  background: transparent;
}
.delete-modal {
  background: white;
  border-radius: 14px;
  max-width: 500px;
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
@media (max-width: 768px) {
  .staff-list {
    padding: 15px;
  }
  .header {
    flex-direction: column;
    gap: 15px;
    align-items: flex-start;
  }
  .search-row {
    flex-direction: column;
    align-items: stretch;
  }
  .search-input,
  .filter-select {
    min-width: auto;
  }
  .users-grid {
    grid-template-columns: 1fr;
  }
  .user-detail {
    flex-direction: column;
    text-align: center;
  }
  .bulk-assign-bar {
    flex-direction: column;
    align-items: stretch;
  }
  .bulk-actions {
    width: 100%;
  }
  .bulk-branch-select {
    width: 100%;
    min-width: auto;
  }
  .users-table-wrapper {
    overflow-x: auto;
  }
  .users-table {
    min-width: 800px;
  }
}
</style>
