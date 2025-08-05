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

      <div class="form-group" v-if="isEditing">
        <label for="status">Trạng thái</label>
        <select id="status" v-model="form.status" required>
          <option value="active">Hoạt động</option>
          <option value="inactive">Không hoạt động</option>
        </select>
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
        description: '',
        status: 'active'
      }
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
            description: newCategory.description || '',
            status: newCategory.status || 'active'
          };
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
        description: '',
        status: 'active'
      };
    },
    
    handleSubmit() {
      console.log('CategoryForm.handleSubmit called');
      
      // Kiểm tra xem form có hợp lệ không
      if (!this.form.name || !this.form.name.trim()) {
        console.error('Form validation failed:', this.form);
        if (this.$toast) {
          this.$toast.error('Vui lòng nhập tên danh mục');
        }
        return;
      }
      
      const formData = { ...this.form };
      
      console.log('CategoryForm submitting data:', formData);
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
</style> 