<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import UserForm from '@/components/Admin/User/UserForm.vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import usersService from '@/services/UserService';
import OrderService from '@/services/OrderService';
import SocketService from '@/services/SocketService';
import { ROLE_NAMES, USER_ROLES, DEFAULT_AVATAR } from '@/constants';
import { useMutation, useQueryClient } from '@tanstack/vue-query';
import { useToast } from 'vue-toastification';
const router = useRouter();
const route = useRoute();
const queryClient = useQueryClient();
const toast = useToast();
const totalPages = ref(1);
const currentPage = computed(() => {
  const page = Number(route.query?.page);
  if (Number.isNaN(page) || page < 1) return 1;
  return page;
});
const users = ref([]);
const searchText = ref('');
const searchType = ref('name'); 
const selectedRole = ref(String(USER_ROLES.CUSTOMER));
const selectedRecent = ref(''); 
const isLoading = ref(true);
const error = ref(null);
const showModal = ref(false);
const modalUser = ref(null);
const showCreateModal = ref(false);
const showDeleteModal = ref(false);
const userToDelete = ref(null);
const deleteLoading = ref(false);
const selectedUsers = ref([]);
const isExporting = ref(false);
const customersWithOrders = ref(0);
const totalCustomers = ref(0);
const userStats = computed(() => {
  const total = totalCustomers.value || users.value.length;
  const now = new Date();
  const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const new3Days = users.value.filter(user => {
    if (!user.created_at) return false;
    return new Date(user.created_at) >= threeDaysAgo;
  }).length;
  const new7Days = users.value.filter(user => {
    if (!user.created_at) return false;
    return new Date(user.created_at) >= sevenDaysAgo;
  }).length;
  const orderPercentage = total > 0 
    ? Math.min(100, Math.round((customersWithOrders.value / total) * 100))
    : 0;
  return {
    total,
    new3Days,
    new7Days,
    orderPercentage
  };
});
const filteredUsers = computed(() => {
  let filtered = users.value;
  if (searchText.value) {
    filtered = filtered.filter((user) => {
      const searchValue = searchText.value.toLowerCase();
      switch (searchType.value) {
        case 'name':
          return user.name?.toLowerCase().includes(searchValue);
        case 'phone':
          return user.phone?.includes(searchValue);
        case 'email':
          return user.email?.toLowerCase().includes(searchValue);
        case 'username':
          return user.username?.toLowerCase().includes(searchValue);
        default:
          return [user.name, user.email, user.address, user.phone, user.username]
            .join('')
            .toLowerCase()
            .includes(searchValue);
      }
    });
  }
  if (selectedRole.value) {
    filtered = filtered.filter(user => user.role_id == selectedRole.value);
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
    if (searchText.value) {
      filters[searchType.value] = searchText.value;
    }
    if (selectedRole.value) {
      filters.role_id = selectedRole.value;
    }
    if (selectedRecent.value) {
      filters.recent = selectedRecent.value; 
    }
    const chunk = await usersService.fetchUsers(page, 6, filters);
    totalPages.value = chunk.metadata.lastPage ?? 1;
    totalCustomers.value = chunk.metadata.total || chunk.metadata.totalCount || 0;
    users.value = chunk.users.sort((current, next) => current.name.localeCompare(next.name));
    await loadCustomersWithOrders();
  } catch (err) {
    error.value = 'An error occurred while loading user list.';
  } finally {
    isLoading.value = false;
  }
}
async function loadCustomersWithOrders() {
  try {
    const stats = await OrderService.getOrderStatistics({});
    customersWithOrders.value = stats.unique_customers || 0;
  } catch (error) {
    customersWithOrders.value = 0;
  }
}
const deleteUserMutation = useMutation({
  mutationFn: usersService.deleteUser,
  onSuccess: () => {
    toast.success('User deleted successfully!');
    queryClient.invalidateQueries(['users']);
    retrieveUsers(currentPage.value);
    showDeleteModal.value = false;
    userToDelete.value = null;
  },
  onError: () => {
    toast.error('An error occurred while deleting user!');
    error.value = 'Error deleting user!';
  }
});
const updateUserMutation = useMutation({
  mutationFn: ({ userId, formData }) => usersService.updateUser(userId, formData),
  onSuccess: () => {
    toast.success('User updated successfully!');
    queryClient.invalidateQueries(['users']);
    queryClient.invalidateQueries(['user', modalUser.value?.id]);
    retrieveUsers(currentPage.value);
    showModal.value = false;
  },
  onError: (error) => {
    toast.error('An error occurred while updating user!');
    }
});
function handleDelete(user) {
  userToDelete.value = user;
  showDeleteModal.value = true;
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
function showUserDetails(user) {
  modalUser.value = user;
  showModal.value = true;
}
function confirmDelete() {
  if (userToDelete.value) {
    deleteUserMutation.mutate(userToDelete.value.id);
  }
}
function handleUpdateUser(formData) {
  if (modalUser.value?.id) {
    updateUserMutation.mutate({ userId: modalUser.value.id, formData });
  }
}
function handleDeleteFromModal() {
  if (modalUser.value) {
    userToDelete.value = modalUser.value;
    showModal.value = false;
    showDeleteModal.value = true;
  }
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
function clearFilters() {
  searchText.value = '';
  selectedRole.value = '';
  selectedRecent.value = '';
  retrieveUsers(1);
}
const createUserMutation = useMutation({
  mutationFn: usersService.createUser,
  onSuccess: () => {
    toast.success('User created successfully!');
    queryClient.invalidateQueries(['users']);
    retrieveUsers(currentPage.value);
    showCreateModal.value = false;
  },
  onError: (error) => {
    const errorMessage = error.response?.data?.message || error.message || 'An error occurred while creating user.';
    toast.error(errorMessage);
  }
});
async function onCreateUser(userData) {
  if (!userData.get('username') || !userData.get('password') || !userData.get('role_id') || !userData.get('name') || !userData.get('email')) {
    toast.warning('Please fill in all required information.');
    return;
  }
  await createUserMutation.mutateAsync(userData);
}
function goToRegisterUser() {
  showCreateModal.value = true;
}
async function exportToExcel() {
  isExporting.value = true;
  try {
    const filters = {};
    if (searchText.value) {
      filters[searchType.value] = searchText.value;
    }
    if (selectedRole.value) {
      filters.role_id = selectedRole.value;
    }
    if (selectedRecent.value) {
      filters.recent = selectedRecent.value;
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
    if (allUsers.length === 0) {
      toast.warning('No customers match the selected filters');
      return;
    }
    allUsers.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    const headers = ['ID', 'Customer Name', 'Username', 'Email', 'Phone', 'Address', 'Created Date'];
    const rows = allUsers.map(user => [
      user.id,
      user.name || 'N/A',
      user.username || 'N/A',
      user.email || 'N/A',
      user.phone || 'N/A',
      user.address || 'N/A',
      formatDate(user.created_at)
    ]);
    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
    ].join('\n');
    const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
    const filename = `danh_sach_khach_hang_${today}`;
    const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `${filename}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success(`Exported ${allUsers.length} customer(s) successfully`);
  } catch (error) {
    toast.error('An error occurred while exporting file');
    } finally {
    isExporting.value = false;
  }
}
function handleRecentFilter() {
  retrieveUsers(1);
}
watch(searchText, () => {
  retrieveUsers(1);
});
watch(currentPage, () => retrieveUsers(currentPage.value), { immediate: true });

// Real-time user updates
function handleUserCreated(data) {
  if (data.user && data.user.role_id === USER_ROLES.CUSTOMER) {
    users.value.unshift(data.user);
    users.value = [...users.value];
    totalCustomers.value = users.value.length;
    toast.info(`Khách hàng mới: ${data.user.name}`);
  }
}

function handleUserUpdated(data) {
  if (data.user) {
    const index = users.value.findIndex(u => u.id === data.userId);
    if (index !== -1) {
      users.value[index] = { ...users.value[index], ...data.user };
      users.value = [...users.value];
    } else if (data.user.role_id === USER_ROLES.CUSTOMER) {
      // User might not be in current view, reload
      retrieveUsers(currentPage.value);
    }
  }
}

function handleUserDeleted(data) {
  const index = users.value.findIndex(u => u.id === data.userId);
  if (index !== -1) {
    users.value.splice(index, 1);
    users.value = [...users.value];
    totalCustomers.value = users.value.length;
  }
}

onMounted(() => {
  // Setup real-time listeners
  SocketService.on('user-created', handleUserCreated);
  SocketService.on('user-updated', handleUserUpdated);
  SocketService.on('user-deleted', handleUserDeleted);
});

onUnmounted(() => {
  // Cleanup listeners
  SocketService.off('user-created', handleUserCreated);
  SocketService.off('user-updated', handleUserUpdated);
  SocketService.off('user-deleted', handleUserDeleted);
});
</script>
<template>
  <div class="user-list">
    <!-- Statistics and Filters Section -->
    <div class="stats-filters-container">
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon" style="background: #ECFDF5; color: #10B981;">
            <i class="fas fa-users"></i>
          </div>
          <div class="stat-info">
            <div class="stat-value">{{ userStats.total }}</div>
            <div class="stat-label">Total Customers</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon" style="background: #D1FAE5; color: #059669;">
            <i class="fas fa-user-plus"></i>
          </div>
          <div class="stat-info">
            <div class="stat-value">{{ userStats.new3Days }}</div>
            <div class="stat-label">New 3 Days</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon" style="background: #FEF3C7; color: #D97706;">
            <i class="fas fa-calendar-week"></i>
          </div>
          <div class="stat-info">
            <div class="stat-value">{{ userStats.new7Days }}</div>
            <div class="stat-label">New 7 Days</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon" style="background: #E0E7FF; color: #6366F1;">
            <i class="fas fa-shopping-cart"></i>
          </div>
          <div class="stat-info">
            <div class="stat-value">{{ userStats.orderPercentage }}%</div>
            <div class="stat-label">With Orders</div>
          </div>
        </div>
      </div>
      <!-- Compact Filters -->
      <div class="compact-filters">
        <div class="filter-row">
          <input
            v-model="searchText"
            type="text"
            placeholder="Search customers..."
            class="filter-input-compact"
            @keyup.enter="handleSearch"
          />
          <select v-model="selectedRecent" @change="handleRecentFilter" class="filter-select-compact">
            <option value="">All Time</option>
            <option value="3d">New 3 Days</option>
            <option value="7d">New 7 Days</option>
          </select>
          <button v-if="searchText || selectedRole || selectedRecent" 
                  @click="clearFilters" class="btn-clear-compact">
            <i class="fas fa-times"></i>
            Clear
          </button>
        </div>
      </div>
    </div>
    <div class="content-area">
      <div v-if="isLoading" class="loading">
        <LoadingSpinner />
        <p>Loading customer list...</p>
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
        <h3>No Customers Found</h3>
        <p v-if="searchText || selectedRole">
          No customers match the current filters
        </p>
        <p v-else>
          No customers have been created yet. Add the first customer!
        </p>
        <button @click="goToRegisterUser" class="btn btn-primary">
          Add First Customer
        </button>
      </div>
      <!-- Table View -->
      <div v-else class="tables-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3>Customer List</h3>
            <span class="table-count">{{ filteredUsers.length }} customers</span>
          </div>
          <div class="header-actions">
            <button @click="exportToExcel" class="btn-export" :disabled="isExporting || isLoading">
              <i class="fas fa-file-excel"></i>
              <span v-if="isExporting">Exporting...</span>
              <span v-else>Export Excel</span>
            </button>
            <button @click="goToRegisterUser" class="btn-add" :disabled="isLoading">
              <i class="fas fa-plus"></i>
              Add Customer
            </button>
            <button @click="retrieveUsers(currentPage)" class="btn-refresh" :disabled="isLoading">
              <i class="fas fa-sync"></i>
              Refresh
            </button>
          </div>
        </div>
        <div class="table-wrapper">
          <table class="modern-table">
            <thead>
              <tr>
                <th class="checkbox-col">
                  <input 
                    type="checkbox" 
                    :checked="selectedUsers.length === filteredUsers.length && filteredUsers.length > 0"
                    @change="toggleSelectAll"
                    class="checkbox-input"
                  />
                </th>
                <th class="id-col">ID</th>
                <th class="name-col">Customer Name</th>
                <th class="email-col">Email</th>
                <th class="phone-col">Phone</th>
                <th class="address-col">Address</th>
                <th class="date-col">Created Date</th>
                <th class="actions-col">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="user in filteredUsers" 
                :key="user.id"
                :class="{ 'row-selected': selectedUsers.includes(user.id) }"
              >
                <td class="checkbox-col">
                  <input 
                    type="checkbox" 
                    :checked="selectedUsers.includes(user.id)"
                    @change="toggleUserSelection(user.id)"
                    class="checkbox-input"
                  />
                </td>
                <td class="id-cell">#{{ user.id }}</td>
                <td class="name-cell">
                  <div class="user-name">{{ user.name || 'N/A' }}</div>
                  <div class="user-username" v-if="user.username">{{ user.username }}</div>
                </td>
                <td class="email-cell">{{ user.email || 'N/A' }}</td>
                <td class="phone-cell">{{ user.phone || 'N/A' }}</td>
                <td class="address-cell">{{ user.address || 'N/A' }}</td>
                <td class="date-cell">{{ formatDate(user.created_at) }}</td>
                <td class="actions-col">
                  <div class="action-buttons">
                    <button 
                      @click="showUserDetails(user)"
                      class="btn-action btn-edit"
                      title="View Details"
                    >
                      <i class="fas fa-eye"></i>
                    </button>
                    <button 
                      @click="handleDelete(user)"
                      class="btn-action btn-delete"
                      title="Delete"
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
    <!-- User Details/Edit Modal -->
    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal-content modal-content-large">
        <div class="modal-header">
          <button @click="showModal = false" class="close-btn">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body" v-if="modalUser">
          <UserForm 
            :user="modalUser" 
            @submit:user="handleUpdateUser"
            @delete:user="handleDeleteFromModal"
          />
        </div>
      </div>
    </div>
    <!-- Create User Modal -->
    <div v-if="showCreateModal" class="modal-overlay" @click.self="showCreateModal = false">
      <div class="modal-content modal-content-large">
        <div class="modal-header">
          <h2>Add New Customer</h2>
          <button @click="showCreateModal = false" class="close-btn">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <UserForm 
            :user="{
              avatar: DEFAULT_AVATAR,
              username: '',
              password: '',
              role_id: USER_ROLES.CUSTOMER,
              name: '',
              email: '',
              address: '',
              phone: '',
              branch_id: null
            }" 
            @submit:user="onCreateUser"
          />
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
          <p>Are you sure you want to delete user <strong>{{ userToDelete?.name }}</strong>?</p>
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
.user-list {
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
.stats-filters-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 24px;
}
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
}
.compact-filters {
  background: white;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  border: 1px solid #E2E8F0;
}
.filter-row {
  display: flex;
  gap: 12px;
  align-items: center;
  flex-wrap: wrap;
}
.filter-input-compact {
  flex: 1;
  min-width: 200px;
  padding: 10px 14px;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  font-size: 14px;
  background: #FAFAFA;
  color: #1a1a1a;
  font-weight: 500;
  transition: all 0.2s ease;
}
.filter-input-compact:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
  background: white;
}
.filter-input-compact::placeholder {
  color: #9CA3AF;
  font-weight: 400;
}
.filter-select-compact {
  padding: 10px 14px;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  font-size: 14px;
  background: #FAFAFA;
  color: #1a1a1a;
  font-weight: 500;
  transition: all 0.2s ease;
  cursor: pointer;
  min-width: 150px;
}
.filter-select-compact:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
  background: white;
}
.btn-clear-compact {
  padding: 10px 16px;
  border: 1px solid #E5E5E5;
  background: white;
  color: #666;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s ease;
  white-space: nowrap;
}
.btn-clear-compact:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
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
.search-section {
  margin-bottom: 20px;
  background: white;
  padding: 16px 20px;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  border: 1px solid #F0E6D9;
}
.search-row {
  display: flex;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
}
.search-input {
  flex: 1;
  min-width: 200px;
  padding: 10px 14px;
  border: 2px solid #F0E6D9;
  border-radius: 10px;
  font-size: 13px;
  background: #FDFBF8;
  color: #333;
  font-weight: 500;
  transition: border-color 0.2s ease;
}
.search-input:focus {
  outline: none;
  border-color: #FF8C42;
  background: white;
}
.search-input::placeholder {
  color: #999;
}
.filter-select {
  padding: 10px 14px;
  border: 2px solid #F0E6D9;
  border-radius: 10px;
  font-size: 13px;
  background: white;
  min-width: 160px;
  color: #333;
  font-weight: 500;
  transition: border-color 0.2s ease;
  cursor: pointer;
}
.filter-select:focus {
  outline: none;
  border-color: #FF8C42;
}
.clear-btn {
  padding: 10px 18px;
  background: white;
  color: #666;
  border: 2px solid #F0E6D9;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
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
  flex-shrink: 0;
}
.tables-card {
  background: #FAFBFC;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #E2E8F0;
  margin-bottom: 20px;
}
.table-wrapper {
  overflow-x: auto;
}
.modern-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  background: white;
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
  overflow: hidden;
  text-overflow: ellipsis;
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
.modern-table td {
  padding: 14px 16px;
  font-size: 13px;
  color: #1E293B;
  vertical-align: middle;
  overflow: hidden;
  text-overflow: ellipsis;
  word-wrap: break-word;
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
.id-col { width: 60px; }
.name-col { width: 180px; }
.email-col { width: 200px; }
.phone-col { width: 120px; }
.address-col { width: 200px; }
.date-col { width: 150px; }
.actions-col { width: 120px; }
.id-cell {
  font-size: 13px;
  font-weight: 700;
  color: #0F172A;
}
.user-name {
  font-weight: 600;
  color: #0F172A;
  font-size: 13px;
}
.user-username {
  font-size: 12px;
  color: #475569;
  margin-top: 2px;
}
.email-cell {
  font-size: 13px;
  color: #1E293B;
}
.phone-cell {
  font-size: 13px;
  color: #475569;
}
.address-cell {
  font-size: 13px;
  color: #6B7280;
}
.date-cell {
  font-size: 12px;
  color: #475569;
  font-weight: 500;
}
.action-buttons {
  display: flex;
  gap: 8px;
  align-items: center;
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
  font-size: 14px;
  transition: all 0.2s ease;
}
.btn-action:hover {
  background: #F8F9FA;
  border-color: #D1D5DB;
  color: #334155;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
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
}
.btn-delete:hover {
  background: #FEF2F2;
  border-color: #EF4444;
  color: #DC2626;
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
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  border: 1px solid #F0E6D9;
}
.modal-content-large {
  max-width: 500px;
}
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 28px;
  border-bottom: 1px solid #F0E6D9;
}
.modal-header h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
  color: #1a1a1a;
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
@media (max-width: 768px) {
  .user-list {
    padding: 10px;
  }
  .header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }
  .search-row {
    flex-direction: column;
    align-items: stretch;
  }
  .search-input,
  .filter-select {
    min-width: auto;
  }
  .modal-overlay {
    padding: 10px;
  }
}
</style>
