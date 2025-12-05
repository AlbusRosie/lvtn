<script setup>
import { ref, watch, onMounted, computed } from 'vue';
import { Form, Field, ErrorMessage, useField } from 'vee-validate';
import { toTypedSchema } from '@vee-validate/zod';
import { z } from 'zod';
import { USER_ROLES, ROLE_NAMES, DEFAULT_AVATAR } from '@/constants';
import branchService from '@/services/BranchService';
import { useToast } from 'vue-toastification';
const props = defineProps({
  user: { type: Object, required: true },
  isManagerView: {
    type: Boolean,
    default: false
  },
  managerBranchId: {
    type: Number,
    default: null
  }
});
const avatarFileInput = ref(null);
const avatarFile = ref(props.user?.avatar || DEFAULT_AVATAR);
const branches = ref([]);
const $emit = defineEmits(['submit:user', 'delete:user']);
const toast = useToast();
const currentRoleId = ref(props.user?.role_id ?? null);
onMounted(async () => {
  try {
    const response = await branchService.getActiveBranches();
    branches.value = response.data || response || [];
  } catch (error) {
    branches.value = [];
  }
});
const validationSchema = toTypedSchema(
  z.object({
    username: z
      .string()
      .min(3, { message: 'Username must be at least 3 characters.' })
      .max(50, { message: 'Username must be at most 50 characters.' }),
    password: z
      .string()
      .optional()
      .refine(
        (val) => !val || val.length === 0 || (val.length >= 6 && val.length <= 50),
        { message: 'Password must be 6-50 characters if provided.' }
      ),
    role_id: z.coerce.number().min(1, { message: 'Please select a role.' }),
    name: z
      .string()
      .min(2, { message: 'Name must be at least 2 characters.' })
      .max(100, { message: 'Name must be at most 100 characters.' }),
    email: z
      .string()
      .email({ message: 'Invalid email address.' })
      .max(100, { message: 'Email must be at most 100 characters.' }),
    address: z.string().max(255, { message: 'Address must be at most 255 characters.' }).optional(),
    phone: z
      .string()
      .regex(/^[0-9]{10,11}$/, {
        message: 'Phone number must be 10-11 digits.'
      })
      .max(15, { message: 'Phone number must be at most 15 characters.' })
      .optional(),
    branch_id: z.coerce.number().optional().or(z.string().optional()),
    avatarFile: z.instanceof(File).optional()
  })
);
watch(
  () => props.user,
  (newUser) => {
    avatarFile.value = newUser?.avatar || DEFAULT_AVATAR;
  },
  { immediate: true }
);
function previewAvatarFile(event) {
  const file = event.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = (evt) => {
    avatarFile.value = evt.target.result;
  };
  reader.readAsDataURL(file);
}
const originalValues = ref({
  username: props.user?.username || '',
  role_id: props.user?.role_id ?? null,
  name: props.user?.name || '',
  email: props.user?.email || '',
  phone: props.user?.phone || null,
  branch_id: props.user?.branch_id ?? null,
  address: props.user?.address || null
});
const initialValues = ref({
  username: props.user?.username || '',
  password: '',
  role_id: props.user?.role_id ?? '',
  name: props.user?.name || '',
  email: props.user?.email || '',
  phone: props.user?.phone || '',
  branch_id: props.user?.branch_id ?? '',
  address: props.user?.address || ''
});
const shouldHideBranch = computed(() => {
  return currentRoleId.value === USER_ROLES.CUSTOMER || 
         currentRoleId.value === USER_ROLES.ADMIN;
});
watch(
  () => props.user,
  (newUser) => {
    if (newUser) {
      currentRoleId.value = newUser.role_id ?? null;
      originalValues.value = {
        username: newUser.username || '',
        role_id: newUser.role_id ?? null,
        name: newUser.name || '',
        email: newUser.email || '',
        phone: newUser.phone || null,
        branch_id: newUser.branch_id ?? null,
        address: newUser.address || null
      };
      initialValues.value = {
        username: newUser.username || '',
        password: '',
        role_id: newUser.role_id ?? '',
        name: newUser.name || '',
        email: newUser.email || '',
        phone: newUser.phone || '',
        branch_id: newUser.branch_id ?? '',
        address: newUser.address || ''
      };
    }
  },
  { immediate: true }
);
function normalizeValue(value) {
  if (value === null || value === undefined || value === '') return null;
  return String(value).trim();
}
function hasChanged(field, newValue, originalValue) {
  const normalizedNew = normalizeValue(newValue);
  const normalizedOriginal = normalizeValue(originalValue);
  return normalizedNew !== normalizedOriginal;
}
function submitUser(values) {
  const formData = new FormData();
  const original = originalValues.value;
  const isCustomerRole = values.role_id === USER_ROLES.CUSTOMER;
  const isAdminRole = values.role_id === USER_ROLES.ADMIN;
  currentRoleId.value = values.role_id ?? null;
  if (hasChanged('username', values.username, original.username)) {
    formData.append('username', values.username || '');
  }
  if (values.password && values.password.trim() !== '') {
    formData.append('password', values.password);
  }
  if (hasChanged('role_id', values.role_id, original.role_id)) {
    if (props.isManagerView && values.role_id === USER_ROLES.ADMIN) {
      toast.error('Manager cannot assign or update users to Admin role');
      return;
    }
    formData.append('role_id', values.role_id ?? '');
  }
  if (hasChanged('name', values.name, original.name)) {
    formData.append('name', values.name || '');
  }
  if (hasChanged('email', values.email, original.email)) {
    formData.append('email', values.email || '');
  }
  if (hasChanged('phone', values.phone, original.phone)) {
    if (values.phone && values.phone.trim() !== '') {
      formData.append('phone', values.phone);
    } else {
      formData.append('phone', '');
    }
  }
  if (hasChanged('address', values.address, original.address)) {
    if (values.address && values.address.trim() !== '') {
      formData.append('address', values.address);
    } else {
      formData.append('address', '');
    }
  }
  if (!isCustomerRole && !isAdminRole && !props.isManagerView && hasChanged('branch_id', values.branch_id, original.branch_id)) {
    if (values.branch_id !== undefined && values.branch_id !== '' && values.branch_id !== null) {
      formData.append('branch_id', values.branch_id);
    } else {
      formData.append('branch_id', '');
    }
  }
  if (props.isManagerView && props.managerBranchId && !props.user?.id) {
    formData.append('branch_id', props.managerBranchId);
  }
  if (values.avatarFile) {
    formData.append('avatarFile', values.avatarFile);
  }
  const hasData = formData.has('avatarFile') || 
                  formData.has('username') ||
                  formData.has('password') ||
                  formData.has('role_id') ||
                  formData.has('name') ||
                  formData.has('email') ||
                  formData.has('phone') ||
                  formData.has('address') ||
                  formData.has('branch_id');
  if (!hasData) {
    toast.info('No changes to update');
    return;
  }
  $emit('submit:user', formData);
}
function deleteUser() {
  $emit('delete:user', props.user.id);
}
</script>
<template>
  <div class="user-form">
    <Form :validation-schema="validationSchema" :initial-values="initialValues" @submit="submitUser" v-slot="{ values }">
      <!-- Avatar Section -->
      <div class="avatar-section">
        <div class="avatar-container" @click="avatarFileInput?.click()">
          <img
            class="avatar-preview"
            :src="avatarFile"
            alt="Avatar"
          />
          <div class="avatar-overlay">
            <i class="fas fa-camera"></i>
            <span>Change Image</span>
          </div>
        </div>
        <Field name="avatarFile" v-slot="{ handleChange }">
          <input
            type="file"
            class="d-none"
            ref="avatarFileInput"
            accept="image/*"
            @change="(e) => { previewAvatarFile(e); handleChange(e); }"
          />
        </Field>
      </div>

      <!-- Form Fields -->
      <div class="form-grid">
        <Field name="username" v-slot="{ field, errors }">
          <div class="form-group">
            <label>Username *</label>
            <input v-bind="field" type="text" class="form-control" />
            <ErrorMessage name="username" class="error-message" />
          </div>
        </Field>

        <Field name="password" v-slot="{ field, errors }">
          <div class="form-group">
            <label>Password {{ props.user?.id ? '(leave blank to keep current)' : '*' }}</label>
            <input v-bind="field" type="password" class="form-control" />
            <ErrorMessage name="password" class="error-message" />
          </div>
        </Field>

        <Field name="role_id" v-slot="{ field, errors }">
          <div class="form-group">
            <label>Role *</label>
            <select v-bind="field" class="form-control">
              <option value="">Select Role</option>
              <option v-for="(name, id) in ROLE_NAMES" :key="id" :value="id">{{ name }}</option>
            </select>
            <ErrorMessage name="role_id" class="error-message" />
          </div>
        </Field>

        <Field name="name" v-slot="{ field, errors }">
          <div class="form-group">
            <label>Name *</label>
            <input v-bind="field" type="text" class="form-control" />
            <ErrorMessage name="name" class="error-message" />
          </div>
        </Field>

        <Field name="email" v-slot="{ field, errors }">
          <div class="form-group">
            <label>Email *</label>
            <input v-bind="field" type="email" class="form-control" />
            <ErrorMessage name="email" class="error-message" />
          </div>
        </Field>

        <Field name="phone" v-slot="{ field, errors }">
          <div class="form-group">
            <label>Phone</label>
            <input v-bind="field" type="text" class="form-control" />
            <ErrorMessage name="phone" class="error-message" />
          </div>
        </Field>

        <Field name="address" v-slot="{ field, errors }">
          <div class="form-group">
            <label>Address</label>
            <textarea v-bind="field" class="form-control" rows="3"></textarea>
            <ErrorMessage name="address" class="error-message" />
          </div>
        </Field>

        <Field name="branch_id" v-slot="{ field, errors }" v-if="!shouldHideBranch && !props.isManagerView">
          <div class="form-group">
            <label>Branch</label>
            <select v-bind="field" class="form-control">
              <option value="">Select Branch</option>
              <option v-for="branch in branches" :key="branch.id" :value="branch.id">{{ branch.name }}</option>
            </select>
            <ErrorMessage name="branch_id" class="error-message" />
          </div>
        </Field>
      </div>

      <!-- Form Actions -->
      <div class="form-actions">
        <button type="submit" class="btn btn-primary">Save</button>
        <button v-if="props.user?.id" type="button" @click="deleteUser" class="btn btn-danger">Delete</button>
      </div>
    </Form>
  </div>
</template>

<style scoped>
.user-form {
  padding: 20px;
}

.avatar-section {
  display: flex;
  justify-content: center;
  margin-bottom: 30px;
}

.avatar-container {
  position: relative;
  width: 120px;
  height: 120px;
  border-radius: 50%;
  overflow: hidden;
  cursor: pointer;
  border: 3px solid #e0e0e0;
  transition: all 0.3s;
}

.avatar-container:hover {
  border-color: #007bff;
}

.avatar-container:hover .avatar-overlay {
  opacity: 1;
}

.avatar-preview {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: white;
  opacity: 0;
  transition: opacity 0.3s;
}

.avatar-overlay i {
  font-size: 24px;
  margin-bottom: 5px;
}

.avatar-overlay span {
  font-size: 12px;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
  margin-bottom: 30px;
}

.form-group {
  display: flex;
  flex-direction: column;
}

.form-group label {
  margin-bottom: 8px;
  font-weight: 500;
  color: #333;
}

.form-control {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.form-control:focus {
  outline: none;
  border-color: #007bff;
}

.error-message {
  color: #dc3545;
  font-size: 12px;
  margin-top: 5px;
}

.form-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.3s;
}

.btn-primary {
  background: #007bff;
  color: white;
}

.btn-primary:hover {
  background: #0056b3;
}

.btn-danger {
  background: #dc3545;
  color: white;
}

.btn-danger:hover {
  background: #c82333;
}

@media (max-width: 768px) {
  .avatar-preview {
    width: 80px;
    height: 80px;
  }
  .form-grid {
    grid-template-columns: 1fr;
  }
  .form-actions {
    flex-direction: column-reverse;
  }
  .btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
