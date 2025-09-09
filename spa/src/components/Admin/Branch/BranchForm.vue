<template>
  <div class="branch-form">
    <h2>{{ isEditing ? 'Chỉnh sửa chi nhánh' : 'Thêm chi nhánh mới' }}</h2>

    <form class="form" @keydown.enter.prevent>
      <div class="form-group">
        <label for="name">Tên chi nhánh *</label>
        <input
          id="name"
          v-model="form.name"
          type="text"
          required
          placeholder="VD: Chi nhánh Quận 1"
        />
      </div>

      <div class="form-row">
        <div class="form-group">
          <label for="province_id">Tỉnh/Thành phố *</label>
          <select 
            id="province_id" 
            v-model="form.province_id" 
            @change="onProvinceChange"
            required
            :disabled="loadingProvinces"
          >
            <option value="">Chọn tỉnh/thành phố</option>
            <option 
              v-for="province in provinces" 
              :key="province.id" 
              :value="province.id"
            >
              {{ province.name }}
            </option>
          </select>
          <div v-if="loadingProvinces" class="loading-text">Đang tải...</div>
        </div>

        <div class="form-group">
          <label for="district_id">Quận/Huyện *</label>
          <select 
            id="district_id" 
            v-model="form.district_id" 
            required
            :disabled="!form.province_id || loadingDistricts"
          >
            <option value="">Chọn quận/huyện</option>
            <option 
              v-for="district in districts" 
              :key="district.id" 
              :value="district.id"
            >
              {{ district.name }}
            </option>
          </select>
          <div v-if="loadingDistricts" class="loading-text">Đang tải...</div>
        </div>
      </div>

      <div class="form-group">
        <label for="address_detail">Địa chỉ chi tiết *</label>
        <input
          id="address_detail"
          v-model="form.address_detail"
          type="text"
          required
          placeholder="VD: 123 Nguyễn Huệ, Tầng 1"
        />
      </div>

      <div class="form-group">
        <label for="phone">Số điện thoại *</label>
        <input
          id="phone"
          v-model="form.phone"
          type="tel"
          required
          placeholder="VD: 028-1234-5678"
        />
      </div>

      <div class="form-group">
        <label for="email">Email *</label>
        <input
          id="email"
          v-model="form.email"
          type="email"
          required
          placeholder="VD: q1@lvtn.com"
        />
      </div>

      <div class="form-group">
        <label for="opening_hours">Giờ mở cửa</label>
        <input
          id="opening_hours"
          v-model="form.opening_hours"
          type="text"
          placeholder="VD: 07:00-22:00"
        />
      </div>

      <div class="form-group">
        <label for="description">Mô tả</label>
        <textarea
          id="description"
          v-model="form.description"
          rows="3"
          placeholder="Mô tả chi tiết về chi nhánh..."
        ></textarea>
      </div>

      <div class="form-group" v-if="isEditing">
        <label for="status">Trạng thái</label>
        <select id="status" v-model="form.status" required>
          <option value="active">Hoạt động</option>
          <option value="inactive">Không hoạt động</option>
          <option value="maintenance">Bảo trì</option>
        </select>
      </div>

      <div class="form-actions">
        <button type="button" @click="$emit('cancel')" class="btn btn-secondary">
          Hủy
        </button>
        <button type="button" @click="handleSubmit" class="btn btn-primary" :disabled="loading">
          <span v-if="loading">Đang xử lý...</span>
          <span v-else>{{ isEditing ? 'Cập nhật' : 'Tạo chi nhánh' }}</span>
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import ProvinceService from '@/services/ProvinceService';

export default {
  name: 'BranchForm',
  props: {
    branch: {
      type: Object,
      default: null
    },
    loading: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      form: {
        name: '',
        address_detail: '',
        phone: '',
        email: '',
        opening_hours: '',
        description: '',
        status: 'active',
        province_id: '',
        district_id: ''
      },
      provinces: [],
      districts: [],
      loadingProvinces: false,
      loadingDistricts: false
    };
  },
  computed: {
    isEditing() {
      return !!this.branch;
    }
  },
  async mounted() {
    await this.loadProvinces();
  },
  watch: {
    branch: {
      async handler(newBranch) {
        console.log('Branch data received:', newBranch);
        if (newBranch) {
          this.form = {
            name: newBranch.name,
            address_detail: newBranch.address_detail || '',
            phone: newBranch.phone,
            email: newBranch.email,
            opening_hours: newBranch.opening_hours || '',
            description: newBranch.description || '',
            status: newBranch.status,
            province_id: newBranch.province_id || '',
            district_id: newBranch.district_id || ''
          };
          console.log('Form data set:', this.form);
          if (newBranch.province_id) {
            await this.loadDistricts(newBranch.province_id);
            console.log('Districts loaded:', this.districts);
          } else {
            this.districts = [];
          }
        } else {
          this.resetForm();
        }
      },
      immediate: true
    }
  },
  methods: {
    async loadProvinces() {
      try {
        this.loadingProvinces = true;
        this.provinces = await ProvinceService.getAllProvinces();
      } catch (error) {
        console.error('Error loading provinces:', error);
        this.$toast?.error('Không thể tải danh sách tỉnh/thành phố');
      } finally {
        this.loadingProvinces = false;
      }
    },

    async loadDistricts(provinceId) {
      try {
        this.loadingDistricts = true;
        console.log('Loading districts for province:', provinceId);
        this.districts = await ProvinceService.getDistrictsByProvinceId(provinceId);
        console.log('Districts loaded:', this.districts);
      } catch (error) {
        console.error('Error loading districts:', error);
        this.$toast?.error('Không thể tải danh sách quận/huyện');
      } finally {
        this.loadingDistricts = false;
      }
    },

    async onProvinceChange() {
      console.log('Province changed to:', this.form.province_id);
      this.form.district_id = '';
      this.districts = [];
      
      if (this.form.province_id) {
        await this.loadDistricts(this.form.province_id);
        console.log('Districts loaded after province change:', this.districts);
      }
    },

    resetForm() {
      this.form = {
        name: '',
        address_detail: '',
        phone: '',
        email: '',
        opening_hours: '',
        description: '',
        status: 'active',
        province_id: '',
        district_id: ''
      };
      this.districts = [];
    },

    handleSubmit() {
      if (!this.form.name || !this.form.address_detail || !this.form.phone || !this.form.email || !this.form.province_id || !this.form.district_id) {
        this.$toast?.error('Vui lòng điền đầy đủ thông tin bắt buộc');
        return;
      }

      const formData = { ...this.form };
      console.log('Submitting form data:', formData);
      console.log('Current form state:', this.form);
      console.log('Available districts:', this.districts);
      this.$emit('submit', formData);
    }
  }
};
</script>

<style scoped>
.branch-form {
  background: white;
  padding: 24px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.branch-form h2 {
  margin: 0 0 24px 0;
  color: #1f2937;
  font-size: 1.5rem;
  font-weight: 600;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group label {
  font-weight: 500;
  color: #374151;
  font-size: 0.9rem;
}

.form-group input,
.form-group select,
.form-group textarea {
  padding: 10px 12px;
  border: 2px solid #e5e7eb;
  border-radius: 6px;
  font-size: 0.9rem;
  transition: border-color 0.2s ease;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
}

.loading-text {
  font-size: 0.8rem;
  color: #6b7280;
  font-style: italic;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
  padding-top: 24px;
  border-top: 1px solid #e5e7eb;
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

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>