<template>
  <div class="category-form">
    <h2>{{ isEditing ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới' }}</h2>

    <form class="form" @keydown.enter.prevent>
      <div class="form-group">
        <label for="name">Tên danh mục *</label>
        <input
          id="name"
          v-model="form.name"
          type="text"
          required
          placeholder="VD: Món chính, Món khai vị, Tráng miệng..."
        />
      </div>

      <div class="form-group">
        <label for="description">Mô tả</label>
        <textarea
          id="description"
          v-model="form.description"
          rows="3"
          placeholder="Mô tả chi tiết về danh mục..."
        ></textarea>
      </div>

      <div class="form-group">
        <label for="image">Hình ảnh danh mục</label>
        <div class="image-upload-section">
          <div class="current-image" v-if="currentImageUrl">
            <img :src="currentImageUrl" alt="Current image" class="preview-image" />
            <button type="button" @click="removeImage" class="remove-image-btn">
              <i class="fas fa-times"></i>
            </button>
          </div>
          <div class="image-upload" v-else>
            <input
              ref="imageInput"
              id="image"
              type="file"
              accept="image/*"
              @change="handleImageChange"
              style="display: none"
            />
            <button type="button" @click="$refs.imageInput.click()" class="upload-btn">
              <i class="fas fa-cloud-upload-alt"></i>
              <span>Chọn hình ảnh</span>
            </button>
          </div>
          <div class="image-info" v-if="selectedImage">
            <p class="image-name">{{ selectedImage.name }}</p>
            <p class="image-size">{{ formatFileSize(selectedImage.size) }}</p>
          </div>
        </div>
      </div>


      <div class="form-actions">
        <button type="button" @click="$emit('cancel')" class="btn btn-secondary">
          Hủy
        </button>
        <button type="button" @click="handleSubmit" class="btn btn-primary" :disabled="loading">
          <span v-if="loading">Đang xử lý...</span>
          <span v-else>{{ isEditing ? 'Cập nhật' : 'Tạo danh mục' }}</span>
        </button>
      </div>
    </form>
  </div>
</template>

<script>
export default {
  name: 'CategoryForm',
  props: {
    category: {
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
        description: ''
      },
      selectedImage: null,
      currentImageUrl: null
    };
  },
  computed: {
    isEditing() {
      return !!this.category;
    }
  },
  watch: {
    category: {
      handler(newCategory) {
        if (newCategory) {
          this.form = {
            name: newCategory.name,
            description: newCategory.description || ''
          };
          this.currentImageUrl = this.getImageUrl(newCategory.image);
        } else {
          this.resetForm();
        }
      },
      immediate: true
    }
  },
  methods: {
    resetForm() {
      this.form = {
        name: '',
        description: ''
      };
      this.selectedImage = null;
      this.currentImageUrl = null;
    },

    getImageUrl(imagePath) {
      if (!imagePath) return null;
      // Nếu đường dẫn đã có http, trả về nguyên
      if (imagePath.startsWith('http')) return imagePath;
      // Nếu đường dẫn bắt đầu bằng /public, thêm domain
      if (imagePath.startsWith('/public')) {
        return `${window.location.origin}${imagePath}`;
      }
      // Mặc định thêm /public/uploads/
      return `${window.location.origin}/public/uploads/${imagePath}`;
    },

    handleImageChange(event) {
      const file = event.target.files[0];
      if (file) {
        // Kiểm tra kích thước file (5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (this.$toast) {
            this.$toast.error('Kích thước file không được vượt quá 5MB');
          }
          return;
        }

        // Kiểm tra loại file
        if (!file.type.startsWith('image/')) {
          if (this.$toast) {
            this.$toast.error('Vui lòng chọn file hình ảnh');
          }
          return;
        }

        this.selectedImage = file;
        this.currentImageUrl = URL.createObjectURL(file);
      }
    },

    removeImage() {
      this.selectedImage = null;
      this.currentImageUrl = null;
      if (this.$refs.imageInput) {
        this.$refs.imageInput.value = '';
      }
    },

    formatFileSize(bytes) {
      if (bytes === 0) return '0 Bytes';
      const k = 1024;
      const sizes = ['Bytes', 'KB', 'MB', 'GB'];
      const i = Math.floor(Math.log(bytes) / Math.log(k));
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    },

    handleSubmit() {
      if (!this.form.name || !this.form.name.trim()) {
        if (this.$toast) {
          this.$toast.error('Vui lòng nhập tên danh mục');
        }
        return;
      }

      const formData = { 
        ...this.form,
        imageFile: this.selectedImage
      };
      this.$emit('submit', formData);
    }
  }
};
</script>

<style scoped>
.category-form {
  background: white;
  padding: 24px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.category-form h2 {
  margin: 0 0 24px 0;
  color: #333;
  font-size: 1.5rem;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
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
  border: 1px solid #d1d5db;
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

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 8px;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
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

.image-upload-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.current-image {
  position: relative;
  width: 120px;
  height: 120px;
  border-radius: 8px;
  overflow: hidden;
  border: 2px solid #e5e7eb;
}

.preview-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.remove-image-btn {
  position: absolute;
  top: 4px;
  right: 4px;
  background: rgba(239, 68, 68, 0.9);
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
  transition: background-color 0.2s ease;
}

.remove-image-btn:hover {
  background: rgba(220, 38, 38, 1);
}

.image-upload {
  display: flex;
  align-items: center;
  justify-content: center;
}

.upload-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 20px;
  border: 2px dashed #d1d5db;
  border-radius: 8px;
  background: #f9fafb;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 120px;
}

.upload-btn:hover {
  border-color: #3b82f6;
  background: #eff6ff;
  color: #3b82f6;
}

.upload-btn i {
  font-size: 1.5rem;
}

.upload-btn span {
  font-size: 0.9rem;
  font-weight: 500;
}

.image-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 8px 12px;
  background: #f3f4f6;
  border-radius: 6px;
  border: 1px solid #e5e7eb;
}

.image-name {
  margin: 0;
  font-size: 0.9rem;
  font-weight: 500;
  color: #374151;
  word-break: break-all;
}

.image-size {
  margin: 0;
  font-size: 0.8rem;
  color: #6b7280;
}
</style>
