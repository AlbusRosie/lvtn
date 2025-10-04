<template>
  <div class="branch-form">
    <h2>{{ getFormTitle() }}</h2>

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

      <div class="form-row">
        <div class="form-group">
          <label for="opening_hours">Giờ mở cửa</label>
          <input
            id="opening_hours"
            v-model.number="form.opening_hours"
            type="number"
            min="0"
            max="23"
            placeholder="VD: 7"
          />
        </div>

        <div class="form-group">
          <label for="close_hours">Giờ đóng cửa</label>
          <input
            id="close_hours"
            v-model.number="form.close_hours"
            type="number"
            min="0"
            max="23"
            placeholder="VD: 22"
          />
        </div>
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

      <div class="form-group">
        <label for="branchImage">Ảnh chi nhánh</label>
        <div class="image-upload-container">
          <input
            id="branchImage"
            ref="imageInput"
            type="file"
            accept="image/*"
            @change="handleImageChange"
            class="image-input"
          />
          <div class="image-preview" v-if="imagePreview">
            <img :src="imagePreview" alt="Preview" />
            <button type="button" @click="removeImage" class="remove-image-btn">
              <i class="fas fa-times"></i>
            </button>
            <div class="image-status" v-if="isEditing && !selectedImage">
              <small class="existing-image-label">Ảnh hiện tại sẽ được giữ nguyên</small>
            </div>
            <div class="image-status" v-if="selectedImage">
              <small class="new-image-label">Ảnh mới sẽ được cập nhật</small>
           </div>
          </div>
          <div class="image-placeholder" v-else>
            <i class="fas fa-image"></i>
            <span>Chọn ảnh chi nhánh</span>
          </div>
        </div>
        <div class="image-info">
          <small>Định dạng: JPG, PNG, GIF, WebP. Kích thước tối đa: 5MB</small>
        </div>
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
          <span v-else>{{ getSubmitButtonText() }}</span>
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
        opening_hours: 7,
        close_hours: 22,
        description: '',
        status: 'active',
        province_id: '',
        district_id: ''
      },
      provinces: [],
      districts: [],
      loadingProvinces: false,
      loadingDistricts: false,
      selectedImage: null,
      imagePreview: null
    };
  },
  computed: {
    isEditing() {
      return !!this.branch;
    },
    isCopying() {
      return this.branch && this.branch.name && this.branch.name.includes('(Copy)');
    }
  },
  async mounted() {
    await this.loadProvinces();
  },
  watch: {
    branch: {
      async handler(newBranch) {
        if (newBranch) {
          this.form = {
            name: newBranch.name,
            address_detail: newBranch.address_detail || '',
            phone: newBranch.phone,
            email: newBranch.email,
            opening_hours: newBranch.opening_hours || 7,
            close_hours: newBranch.close_hours || 22,
            description: newBranch.description || '',
            status: newBranch.status,
            province_id: newBranch.province_id || '',
            district_id: newBranch.district_id || ''
          };
          
          if (newBranch.image) {
            this.imagePreview = newBranch.image;
          } else {
            this.imagePreview = null;
          }
          
          if (newBranch.province_id) {
            await this.loadDistricts(newBranch.province_id);
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
    getFormTitle() {
      if (this.isCopying) {
        return 'Sao chép chi nhánh';
      } else if (this.isEditing) {
        return 'Chỉnh sửa chi nhánh';
      } else {
        return 'Thêm chi nhánh mới';
      }
    },

    getSubmitButtonText() {
      if (this.isCopying) {
        return 'Tạo bản sao';
      } else if (this.isEditing) {
        return 'Cập nhật';
      } else {
        return 'Tạo chi nhánh';
      }
    },

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
        this.districts = await ProvinceService.getDistrictsByProvinceId(provinceId);
      } catch (error) {
        console.error('Error loading districts:', error);
        this.$toast?.error('Không thể tải danh sách quận/huyện');
      } finally {
        this.loadingDistricts = false;
      }
    },

    async onProvinceChange() {
      this.form.district_id = '';
      this.districts = [];
      
      if (this.form.province_id) {
        await this.loadDistricts(this.form.province_id);
      }
    },

    resetForm() {
      this.form = {
        name: '',
        address_detail: '',
        phone: '',
        email: '',
        opening_hours: 7,
        close_hours: 22,
        description: '',
        status: 'active',
        province_id: '',
        district_id: ''
      };
      this.districts = [];
      this.selectedImage = null;
      this.imagePreview = null;
    },

    handleImageChange(event) {
      const file = event.target.files[0];
      if (file) {
        if (file.size > 5 * 1024 * 1024) {
          this.$toast?.error('Kích thước file không được vượt quá 5MB');
          return;
        }

        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
        if (!allowedTypes.includes(file.type)) {
          this.$toast?.error('Chỉ chấp nhận file ảnh (JPG, PNG, GIF, WebP)');
          return;
        }

        this.selectedImage = file;
        
        const reader = new FileReader();
        reader.onload = (e) => {
          this.imagePreview = e.target.result;
        };
        reader.readAsDataURL(file);
      }
    },

    removeImage() {
      this.selectedImage = null;
      this.$refs.imageInput.value = '';
      
      if (!this.isEditing || !this.branch?.image) {
        this.imagePreview = null;
      } else {
        this.imagePreview = this.branch.image;
      }
    },

    handleSubmit() {
      if (!this.form.name || !this.form.address_detail || !this.form.phone || !this.form.email || !this.form.province_id || !this.form.district_id) {
        this.$toast?.error('Vui lòng điền đầy đủ thông tin bắt buộc');
        return;
      }

      const formData = { ...this.form };
      
      let imageFile = this.selectedImage;
      if (this.isEditing && !imageFile) {
        imageFile = 'KEEP_EXISTING'; // Signal để backend biết giữ ảnh cũ
      }
      
      this.$emit('submit', { formData, imageFile });
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

.image-upload-container {
  position: relative;
  border: 2px dashed #d1d5db;
  border-radius: 8px;
  padding: 20px;
  text-align: center;
  transition: border-color 0.2s ease;
  cursor: pointer;
}

.image-upload-container:hover {
  border-color: #3b82f6;
}

.image-input {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}

.image-preview {
  position: relative;
  display: inline-block;
}

.image-preview img {
  max-width: 200px;
  max-height: 200px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.remove-image-btn {
  position: absolute;
  top: -8px;
  right: -8px;
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 12px;
}

.remove-image-btn:hover {
  background: #dc2626;
}

.image-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  color: #6b7280;
}

.image-placeholder i {
  font-size: 2rem;
}

.image-info {
  margin-top: 8px;
  color: #6b7280;
}

.image-status {
  margin-top: 8px;
  text-align: center;
}

.image-status small {
  display: inline-block;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 500;
}

.existing-image-label {
  color: #34d399;
  font-weight: 500;
}

.new-image-label {
  color: #3b82f6;
  font-weight: 500;
}

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
