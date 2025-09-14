<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import UserCard from '@/components/Admin/User/UserCard.vue';
import InputSearch from '@/components/Admin/User/InputSearch.vue';
import UserList from '@/components/Admin/User/UserList.vue';
import MainPagination from '@/components/Admin/User/MainPagination.vue';
import usersService from '@/services/UserService';
import { ROLE_NAMES } from '@/constants';

const router = useRouter();
const route = useRoute();
const totalPages = ref(1);
const currentPage = computed(() => {
  const page = Number(route.query?.page);
  if (Number.isNaN(page) || page < 1) return 1;
  return page;
});

const users = ref([]);
const selectedIndex = ref(-1);
const searchText = ref('');
const searchType = ref('name');
const selectedRole = ref('');
const selectedFavorite = ref('');
const isLoading = ref(true);
const error = ref(null);

const searchableUsers = computed(() =>
  users.value.map((user) => {
    const { name, email, address, phone } = user;
    return [name, email, address, phone].join('');
  })
);

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
        default:
          return [user.name, user.email, user.address, user.phone]
            .join('')
            .toLowerCase()
            .includes(searchValue);
      }
    });
  }

  if (selectedRole.value) {
    filtered = filtered.filter(user => user.role_id == selectedRole.value);
  }

  if (selectedFavorite.value !== '') {
    filtered = filtered.filter(user => user.favorite == selectedFavorite.value);
  }

  return filtered;
});

const selectedUser = computed(() => {
  if (selectedIndex.value < 0) return null;
  return filteredUsers.value[selectedIndex.value];
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
    if (selectedFavorite.value !== '') {
      filters.favorite = selectedFavorite.value;
    }

    const chunk = await usersService.fetchUsers(page, 10, filters);
    totalPages.value = chunk.metadata.lastPage ?? 1;
    users.value = chunk.users.sort((current, next) => current.name.localeCompare(next.name));
    selectedIndex.value = -1;
  } catch (err) {
    error.value = 'Đã có lỗi xảy ra khi tải danh sách người dùng.';
  } finally {
    isLoading.value = false;
  }
}

async function onDeleteUsers() {
  if (confirm('Bạn muốn xóa tất cả tài khoản?')) {
    try {
      await usersService.deleteAllUsers();
      totalPages.value = 1;
      users.value = [];
      selectedIndex.value = -1;
      changeCurrentPage(1);
    } catch (error) {
    }
  }
}

function goToRegisterUser() {
  router.push({ name: 'user.register' });
}

function changeCurrentPage(page) {
  router.push({ name: 'home', query: { page } });
}

function handleSearch(searchTypeValue) {
  searchType.value = searchTypeValue;
  retrieveUsers(1);
}

function handleRoleFilter() {
  retrieveUsers(1);
}

function handleFavoriteFilter() {
  retrieveUsers(1);
}

watch(searchText, () => (selectedIndex.value = -1));

watch(currentPage, () => retrieveUsers(currentPage.value), { immediate: true });
</script>

<template>
  <div class="page row mb-5">
    <div class="mt-3 col-md-6">
      <h4>
        Quản lý người dùng
        <i class="fas fa-users"></i>
      </h4>

      
      <div class="my-3">
        <InputSearch
          v-model="searchText"
          :search-type="searchType"
          @submit="handleSearch"
        />
      </div>

      
      <div class="row mb-3">
        <div class="col-md-6">
          <label class="form-label">Lọc theo vai trò:</label>
          <select v-model="selectedRole" @change="handleRoleFilter" class="form-select form-select-sm">
            <option value="">Tất cả vai trò</option>
            <option value="1">{{ ROLE_NAMES[1] }}</option>
            <option value="2">{{ ROLE_NAMES[2] }}</option>
            <option value="3">{{ ROLE_NAMES[3] }}</option>
          </select>
        </div>
        <div class="col-md-6">
          <label class="form-label">Lọc theo yêu thích:</label>
          <select v-model="selectedFavorite" @change="handleFavoriteFilter" class="form-select form-select-sm">
            <option value="">Tất cả</option>
            <option value="1">Yêu thích</option>
            <option value="0">Không yêu thích</option>
          </select>
        </div>
      </div>

      <p v-if="isLoading">Đang tải danh sách người dùng...</p> 
      <p v-if="error" class="text-danger">{{ error }}</p> 
      <UserList
        v-if="filteredUsers.length > 0 && !isLoading"
        :users="filteredUsers"
        v-model:selected-index="selectedIndex"
      />
      <p v-else-if="!isLoading">Không có người dùng nào.</p> 
      <div class="mt-3 d-flex flex-wrap justify-content-round align-items-center">
        <MainPagination
          :total-pages="totalPages"
          :current-page="currentPage"
          @update:current-page="changeCurrentPage"
        />
        <div class="w-100"></div>
        <button class="btn btn-sm btn-primary" @click="retrieveUsers(currentPage)">
          <i class="fas fa-redo"></i> Làm mới
        </button>
        <button class="btn btn-sm btn-success" @click="goToRegisterUser">
          <i class="fas fa-plus"></i> Thêm mới
        </button>
        <button class="btn btn-sm btn-danger" @click="onDeleteUsers">
          <i class="fas fa-trash"></i> Xóa tất cả
        </button>
      </div>
    </div>
    <div class="mt-3 col-md-6">
      <div v-if="selectedUser">
        <h4>
          Chi tiết người dùng
          <i class="fas fa-address-card"></i>
        </h4>
        <UserCard v-if="selectedUser" :user="selectedUser" />
        <router-link
          v-if="selectedUser?.id"
          :to="{
            name: 'user.edit',
            params: { id: selectedUser.id }
          }"
        >
          <span class="mt-2 badge text-bg-warning"> <i class="fas fa-edit"></i> Hiệu chỉnh</span>
        </router-link>
      </div>
      <div v-else class="text-center text-muted mt-5">
        <i class="fas fa-user fa-3x mb-3"></i>
        <p>Chọn một người dùng để xem chi tiết</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page {
  text-align: left;
  max-width: 750px;
}
</style>
