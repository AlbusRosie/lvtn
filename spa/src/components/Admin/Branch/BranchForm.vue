<template>
  <div class="branch-form">
    <form class="form" @keydown.enter.prevent>
      <!-- Thông tin cơ bản -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-building"></i>
          <h3>Basic Information</h3>
        </div>
        <div class="card-content">
          <div class="form-group">
            <label for="name">Branch Name *</label>
            <input
              id="name"
              v-model="form.name"
              type="text"
              required
              placeholder="E.g: District 1 Branch"
            />
          </div>
          <div class="form-row">
            <div class="form-group">
              <label for="phone">Phone Number *</label>
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
          </div>
          <div class="form-group" v-if="isEditing">
            <label for="status">Status</label>
            <select id="status" v-model="form.status" required>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="maintenance">Maintenance</option>
            </select>
          </div>
        </div>
      </div>
      <!-- Thông tin địa chỉ -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-map-marker-alt"></i>
          <h3>Address Information</h3>
        </div>
        <div class="card-content">
          <div class="form-group" style="position: relative;">
            <label for="address_detail">Tìm kiếm địa chỉ *</label>
            <input
              id="address_detail"
              name="address_detail"
              ref="addressInput"
              v-model="form.address_detail"
              type="text"
              required
              autocomplete="address-line1"
              placeholder="Nhập địa chỉ để tìm kiếm..."
              @input="onAddressInput"
              @focus="onAddressFocus"
              @blur="onAddressBlur"
            />
            <!-- Autocomplete suggestions dropdown -->
            <div v-if="showSuggestions && autocompleteSuggestions.length > 0" class="autocomplete-suggestions">
              <div
                v-for="(suggestion, index) in autocompleteSuggestions"
                :key="index"
                class="suggestion-item"
                @mousedown="selectAddress(suggestion)"
              >
                <i class="fas fa-map-marker-alt"></i>
                <div class="suggestion-text">
                  <div class="suggestion-main">{{ suggestion.place_name || suggestion.text }}</div>
                  <div class="suggestion-context" v-if="suggestion.context">
                    {{ suggestion.context.map(c => c.text).join(', ') }}
                  </div>
                </div>
              </div>
            </div>
            <small v-if="mapboxInitialized" class="mapbox-hint">
              <i class="fas fa-map-marker-alt"></i> Mapbox Autofill đã sẵn sàng - Gõ để tìm địa chỉ
            </small>
            <small v-else-if="loadingMapbox" class="mapbox-loading">
              <i class="fas fa-spinner fa-spin"></i> Đang tải Mapbox Autofill...
            </small>
            <small v-else-if="!mapboxKey" class="mapbox-error" style="color: #ef4444;">
              <i class="fas fa-exclamation-triangle"></i> Mapbox API key chưa được cấu hình
            </small>
            <small v-else class="mapbox-error" style="color: #ef4444;">
              <i class="fas fa-exclamation-triangle"></i> Mapbox Autofill chưa sẵn sàng
            </small>
          </div>
          <!-- Hiển thị các phần địa chỉ sau khi chọn từ Autofill -->
          <div v-if="addressSelectedFromMapbox && (addressParts.street || addressParts.neighborhood || addressParts.district || addressParts.city)" class="address-parts">
            <div class="form-group">
              <label>Địa chỉ chi tiết</label>
              <input
                type="text"
                :value="addressParts.street || ''"
                readonly
                class="form-control readonly-field"
                placeholder="Số nhà, tên đường"
              />
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Phường/Xã</label>
                <input
                  type="text"
                  :value="addressParts.neighborhood || ''"
                  readonly
                  class="form-control readonly-field"
                  placeholder="Phường/Xã"
                />
              </div>
              <div class="form-group">
                <label>Quận/Huyện</label>
                <input
                  type="text"
                  :value="addressParts.district || ''"
                  readonly
                  class="form-control readonly-field"
                  placeholder="Quận/Huyện"
                />
              </div>
            </div>
            <div class="form-group">
              <label>Tỉnh/Thành phố</label>
              <input
                type="text"
                :value="addressParts.city || ''"
                readonly
                class="form-control readonly-field"
                placeholder="Tỉnh/Thành phố"
              />
            </div>
          </div>
          <!-- Hiển thị và chỉnh sửa tọa độ -->
          <div class="form-row" style="margin-top: 16px;">
            <div class="form-group">
              <label for="latitude">Latitude (Vĩ độ) *</label>
              <input
                id="latitude"
                v-model.number="form.latitude"
                type="number"
                step="0.00000001"
                placeholder="VD: 10.804992"
                @blur="validateCoordinates"
                :class="{ 'error': coordinateError }"
              />
              <small v-if="coordinateError" class="error-text">{{ coordinateError }}</small>
              <small v-else class="help-text">
                Tọa độ sẽ tự động cập nhật khi chọn địa chỉ từ Mapbox. 
                Bạn có thể chỉnh sửa thủ công nếu cần.
              </small>
            </div>
            <div class="form-group">
              <label for="longitude">Longitude (Kinh độ) *</label>
              <input
                id="longitude"
                v-model.number="form.longitude"
                type="number"
                step="0.00000001"
                placeholder="VD: 106.726408"
                @blur="validateCoordinates"
                :class="{ 'error': coordinateError }"
              />
              <small v-if="coordinateError" class="error-text">{{ coordinateError }}</small>
              <small v-else class="help-text">
                Phạm vi hợp lý cho HCM: Lat 10.3-11.0, Lng 106.3-107.0
              </small>
            </div>
          </div>
          <!-- Hiển thị cảnh báo nếu tọa độ có vẻ sai -->
          <div v-if="coordinateWarning" class="coordinate-warning">
            <i class="fas fa-exclamation-triangle"></i>
            <span>{{ coordinateWarning }}</span>
          </div>
        </div>
      </div>
      <!-- Thông tin hoạt động -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-clock"></i>
          <h3>Operating Information</h3>
        </div>
        <div class="card-content">
          <div class="form-row">
            <div class="form-group">
              <label for="opening_hours">Opening Hours</label>
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
              <label for="close_hours">Closing Hours</label>
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
            <label for="description">Description</label>
            <textarea
              id="description"
              v-model="form.description"
              rows="3"
              placeholder="Detailed description of the branch..."
            ></textarea>
          </div>
        </div>
      </div>
      <!-- Ảnh chi nhánh -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-image"></i>
          <h3>Branch Image</h3>
        </div>
        <div class="card-content">
          <div class="form-group">
            <label for="branchImage">Branch Image</label>
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
              </div>
              <div class="image-placeholder" v-else>
                <i class="fas fa-image"></i>
                <span>Chọn ảnh chi nhánh</span>
              </div>
            </div>
            <div class="image-info">
              <i class="fas fa-info-circle"></i>
              <small>Định dạng: JPG, PNG, GIF, WebP. Kích thước tối đa: 5MB</small>
            </div>
          </div>
        </div>
      </div>
      <div class="form-actions">
        <button type="button" @click="$emit('cancel')" class="btn btn-cancel">
          Cancel
        </button>
        <button type="submit" class="btn btn-submit" :disabled="isSubmitting">
          {{ isEditing ? 'Update Branch' : 'Create Branch' }}
        </button>
      </div>
    </form>
  </div>
</template>
<script>
export default {
  name: 'BranchForm',
  props: {
    branch: {
      type: Object,
      default: null
    },
    isEditing: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      form: {
        name: '',
        phone: '',
        email: '',
        address_detail: '',
        latitude: null,
        longitude: null,
        opening_hours: null,
        close_hours: null,
        description: '',
        status: 'active'
      },
      addressParts: {
        street: '',
        neighborhood: '',
        district: '',
        city: ''
      },
      selectedImage: null,
      imagePreview: null,
      coordinateError: null,
      coordinateWarning: null,
      mapboxKey: import.meta.env.VITE_MAPBOX_KEY || '',
      geocodeTimer: null,
      originalBranchData: null,
      isSubmitting: false,
      mapboxInitialized: false,
      loadingMapbox: false,
      addressSelectedFromMapbox: false,
      autocompleteSuggestions: [],
      showSuggestions: false,
      mapboxAutofill: null
    };
  },
  mounted() {
    this.initMapboxAutofill();
    if (this.branch) {
      this.originalBranchData = { ...this.branch };
      this.form = {
        name: this.branch.name || '',
        phone: this.branch.phone || '',
        email: this.branch.email || '',
        address_detail: this.branch.address_detail || '',
        latitude: this.branch.latitude ?? null,
        longitude: this.branch.longitude ?? null,
        opening_hours: this.branch.opening_hours ?? null,
        close_hours: this.branch.close_hours ?? null,
        description: this.branch.description || '',
        status: this.branch.status || 'active'
      };
      if (this.branch.image) {
        this.imagePreview = this.getImageUrl(this.branch.image);
      }
    }
  },
  methods: {
    async initMapboxAutofill() {
      this.loadingMapbox = true;
      try {
        let apiKey = '';
        
        // Priority 1: Try to get from MapService (backend API)
        try {
          const MapService = (await import('@/services/MapService')).default;
          apiKey = await MapService.getMapboxApiKey();
        } catch (error) {
          console.warn('Could not fetch Mapbox API key from service:', error);
        }
        
        // Priority 2: Fallback to environment variable
        if (!apiKey) {
          apiKey = import.meta.env.VITE_MAPBOX_KEY || '';
        }
        
        if (!apiKey) {
          console.warn('Mapbox API key not found. Please configure MAPBOX_KEY_PUBLIC or MAPBOX_KEY in backend .env file');
          this.loadingMapbox = false;
          return;
        }
        
        this.mapboxKey = apiKey;
        
        // Validate the API key by making a simple request
        const testUrl = `https://api.mapbox.com/geocoding/v5/mapbox.places/test.json?access_token=${this.mapboxKey}&limit=1`;
        const response = await fetch(testUrl);
        if (response.ok || response.status === 200) {
          this.mapboxInitialized = true;
          console.log('Mapbox Autofill initialized successfully');
        } else {
          const errorData = await response.json().catch(() => ({}));
          console.error('Mapbox API key validation failed:', errorData);
        }
      } catch (error) {
        console.error('Error initializing Mapbox:', error);
      } finally {
        this.loadingMapbox = false;
      }
    },
    onAddressFocus() {
      this.showSuggestions = this.autocompleteSuggestions.length > 0;
    },
    onAddressBlur() {
      // Use setTimeout to allow click on suggestion before closing
      setTimeout(() => {
        this.showSuggestions = false;
      }, 200);
    },
    async onAddressInput(event) {
      const query = event.target.value.trim();
      if (query.length < 3) {
        this.autocompleteSuggestions = [];
        this.showSuggestions = false;
        return;
      }
      if (!this.mapboxKey) {
        return;
      }
      try {
        const encodedQuery = encodeURIComponent(query);
        const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodedQuery}.json?access_token=${this.mapboxKey}&country=VN&limit=5`;
        const response = await fetch(url);
        if (response.ok) {
          const data = await response.json();
          this.autocompleteSuggestions = data.features || [];
          this.showSuggestions = this.autocompleteSuggestions.length > 0;
        }
      } catch (error) {
        console.error('Error fetching suggestions:', error);
      }
      // Also try to get coordinates for the current input
      await this.tryGetCoordinatesFromAutofill(event.target);
    },
    async selectAddress(feature) {
      if (!feature) return;
      this.form.address_detail = feature.place_name || feature.text || '';
      this.addressSelectedFromMapbox = true;
      this.parseAddressParts(feature);
      const coordinates = feature.geometry.coordinates;
      this.form.longitude = coordinates[0];
      this.form.latitude = coordinates[1];
      this.autocompleteSuggestions = [];
      this.showSuggestions = false;
      await this.$nextTick();
      this.validateCoordinates();
    },
    getImageUrl(imagePath) {
      if (!imagePath) return null;
      if (imagePath.startsWith('http')) return imagePath;
      if (imagePath.startsWith('/public')) {
        return `${window.location.origin}${imagePath}`;
      }
      return `${window.location.origin}/public/uploads/${imagePath}`;
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
      this.imagePreview = null;
      if (this.$refs.imageInput) {
        this.$refs.imageInput.value = '';
      }
    },
    parseAddressParts(feature) {
      if (!feature) {
        this.addressParts = { street: '', neighborhood: '', district: '', city: '' };
        return;
      }
      const props = feature.properties || {};
      const context = feature.context || [];
      this.addressParts = {
        street: '',
        neighborhood: '',
        district: '',
        city: ''
      };
      let addressNumber = '';
      let street = '';
      let neighborhood = '';
      let district = '';
      let city = '';
      let region = '';
      context.forEach(ctx => {
        const id = ctx.id || '';
        if (id.startsWith('address')) {
          addressNumber = ctx.text || '';
        } else if (id.startsWith('street')) {
          street = ctx.text || '';
        } else if (id.startsWith('neighborhood') || id.startsWith('locality')) {
          neighborhood = ctx.text || '';
        } else if (id.startsWith('district')) {
          district = ctx.text || '';
        } else if (id.startsWith('place')) {
          city = ctx.text || '';
        } else if (id.startsWith('region')) {
          region = ctx.text || '';
        }
      });
      if (!street && props.address) {
        street = props.address;
      }
      if (!neighborhood && props.neighborhood) {
        neighborhood = props.neighborhood;
      }
      if (!district && props.district) {
        district = props.district;
      }
      if (!city && props.place) {
        city = props.place;
      }
      if (addressNumber && street) {
        this.addressParts.street = `${addressNumber} ${street}`;
      } else if (street) {
        this.addressParts.street = street;
      } else if (addressNumber) {
        this.addressParts.street = addressNumber;
      }
      this.addressParts.neighborhood = neighborhood || '';
      this.addressParts.district = district || '';
      this.addressParts.city = city || region || '';
    },
    formatFullAddress(feature) {
      if (!feature) return '';
      const parts = [];
      const props = feature.properties || {};
      const context = feature.context || [];
      let addressNumber = ''; 
      let street = ''; 
      let neighborhood = ''; 
      let district = ''; 
      let city = ''; 
      let region = ''; 
      context.forEach(ctx => {
        const id = ctx.id || '';
        if (id.startsWith('address')) {
          addressNumber = ctx.text || '';
        } else if (id.startsWith('street')) {
          street = ctx.text || '';
        } else if (id.startsWith('neighborhood') || id.startsWith('locality')) {
          neighborhood = ctx.text || '';
        } else if (id.startsWith('district')) {
          district = ctx.text || '';
        } else if (id.startsWith('place')) {
          city = ctx.text || '';
        } else if (id.startsWith('region')) {
          region = ctx.text || '';
        }
      });
      if (!street && props.address) {
        street = props.address;
      }
      if (!neighborhood && props.neighborhood) {
        neighborhood = props.neighborhood;
      }
      if (!district && props.district) {
        district = props.district;
      }
      if (!city && props.place) {
        city = props.place;
      }
      if (addressNumber && street) {
        parts.push(`${addressNumber} ${street}`);
      } else if (street) {
        parts.push(street);
      } else if (addressNumber) {
        parts.push(addressNumber);
      }
      if (neighborhood) {
        parts.push(neighborhood);
      }
      if (district) {
        parts.push(district);
      }
      if (city) {
        parts.push(city);
      } else if (region) {
        parts.push(region);
      }
      if (parts.length === 0) {
        return feature.place_name || props.full_address || '';
      }
      return parts.join(', ');
    },
    async tryGetCoordinatesFromAutofill(input) {
      const address = input.value.trim();
      if (!address || address.length < 5) {
        return; 
      }
      if (!this.mapboxKey) {
        return; 
      }
      try {
        if (this.geocodeTimer) {
          clearTimeout(this.geocodeTimer);
        }
        this.geocodeTimer = setTimeout(async () => {
          try {
            const encodedAddress = encodeURIComponent(address);
            const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodedAddress}.json?access_token=${this.mapboxKey}`;
            const response = await fetch(url);
            if (response.ok) {
              const data = await response.json();
              if (data.features && data.features.length > 0) {
                const feature = data.features[0];
                const coordinates = feature.geometry.coordinates; 
                this.form.longitude = coordinates[0];
                this.form.latitude = coordinates[1];
                this.$nextTick(() => {
                  this.validateCoordinates();
                });
                } else {
                }
            } else {
              }
          } catch (error) {
            }
        }, 1000); 
      } catch (error) {
        }
    },
    validateCoordinates() {
      this.coordinateError = null;
      this.coordinateWarning = null;
      if (this.form.latitude === null || this.form.longitude === null) {
        return; 
      }
      const lat = parseFloat(this.form.latitude);
      const lng = parseFloat(this.form.longitude);
      if (isNaN(lat) || isNaN(lng)) {
        this.coordinateError = 'Tọa độ phải là số hợp lệ';
        return;
      }
      const HCM_LAT_MIN = 10.3;
      const HCM_LAT_MAX = 11.0;
      const HCM_LNG_MIN = 106.3;
      const HCM_LNG_MAX = 107.0;
      if (lat < HCM_LAT_MIN || lat > HCM_LAT_MAX || 
          lng < HCM_LNG_MIN || lng > HCM_LNG_MAX) {
        this.coordinateWarning = 'Cảnh báo: Tọa độ (' + lat.toFixed(6) + ', ' + lng.toFixed(6) + ') có vẻ nằm ngoài phạm vi Hồ Chí Minh. Vui lòng kiểm tra lại!';
        if (lat < 8 || lat > 12 || lng < 104 || lng > 110) {
          this.coordinateError = 'Tọa độ quá xa so với Hồ Chí Minh. Vui lòng kiểm tra lại địa chỉ!';
        }
      } else {
        this.coordinateWarning = null;
      }
    },
    handleSubmit() {
      if (!this.form.name || !this.form.address_detail || !this.form.phone || !this.form.email) {
        this.$toast?.error('Please fill in all required information');
        return;
      }
      this.validateCoordinates();
      if (this.coordinateError) {
        this.$toast?.error(this.coordinateError);
        return;
      }
      if (this.coordinateWarning) {
        const confirmed = confirm(this.coordinateWarning + '\n\nBạn có chắc chắn muốn tiếp tục?');
        if (!confirmed) {
          return;
        }
      }
      if (this.isEditing && this.originalBranchData) {
        const changedFields = {};
        let hasChanges = false;
        if (this.form.name !== this.originalBranchData.name) {
          changedFields.name = this.form.name;
          hasChanges = true;
        }
        if (this.form.address_detail !== this.originalBranchData.address_detail) {
          changedFields.address_detail = this.form.address_detail;
          hasChanges = true;
        }
        if (this.form.phone !== this.originalBranchData.phone) {
          changedFields.phone = this.form.phone;
          hasChanges = true;
        }
        if (this.form.email !== this.originalBranchData.email) {
          changedFields.email = this.form.email;
          hasChanges = true;
        }
        if (this.form.opening_hours !== this.originalBranchData.opening_hours) {
          changedFields.opening_hours = this.form.opening_hours;
          hasChanges = true;
        }
        if (this.form.close_hours !== this.originalBranchData.close_hours) {
          changedFields.close_hours = this.form.close_hours;
          hasChanges = true;
        }
        if ((this.form.description || '') !== (this.originalBranchData.description || '')) {
          changedFields.description = this.form.description;
          hasChanges = true;
        }
        if (this.form.status !== this.originalBranchData.status) {
          changedFields.status = this.form.status;
          hasChanges = true;
        }
        const currentLat = this.form.latitude ?? null;
        const originalLat = this.originalBranchData.latitude ?? null;
        const currentLng = this.form.longitude ?? null;
        const originalLng = this.originalBranchData.longitude ?? null;
        if (currentLat !== originalLat) {
          changedFields.latitude = this.form.latitude;
          hasChanges = true;
        }
        if (currentLng !== originalLng) {
          changedFields.longitude = this.form.longitude;
          hasChanges = true;
        }
        const hasImageChange = this.selectedImage !== null;
        if (!hasChanges && !hasImageChange) {
          this.$toast?.info('Không có thay đổi nào để cập nhật');
          return;
        }
        let formData;
        if (hasChanges) {
          formData = changedFields;
        } else {
          formData = {
            name: this.form.name,
            address_detail: this.form.address_detail,
            phone: this.form.phone,
            email: this.form.email,
            opening_hours: this.form.opening_hours,
            close_hours: this.form.close_hours,
            description: this.form.description,
            status: this.form.status,
            latitude: this.form.latitude,
            longitude: this.form.longitude
          };
        }
        let imageFile = this.selectedImage;
        if (!imageFile) {
          imageFile = 'KEEP_EXISTING'; 
        }
        this.$emit('submit', { formData, imageFile });
      } else {
        const formData = { ...this.form };
        let imageFile = this.selectedImage;
        if (this.isEditing && !imageFile) {
          imageFile = 'KEEP_EXISTING'; 
        }
        this.$emit('submit', { formData, imageFile });
      }
    }
  }
};
</script>
<style scoped>
.branch-form {
  background: white;
  padding: 0;
}
.form {
  display: flex;
  flex-direction: column;
  gap: 16px;
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
  font-size: 14px;
}
.card-header h3 {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  letter-spacing: -0.2px;
}
.card-content {
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.form-row {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.form-group label {
  font-size: 12px;
  font-weight: 500;
  color: #64748B;
  letter-spacing: 0;
}
.form-group input,
.form-group select,
.form-group textarea {
  padding: 10px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  color: #1E293B;
  font-weight: 500;
  transition: all 0.2s ease;
}
.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #F59E0B;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1);
}
.form-group textarea {
  resize: vertical;
  min-height: 80px;
}
.loading-text {
  font-size: 11px;
  color: #94A3B8;
  font-style: italic;
  margin-top: 4px;
}
.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #E2E8F0;
}
.btn {
  padding: 12px 24px;
  border: 2px solid #F0E6D9;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
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
  background: #F59E0B;
  color: white;
  border-color: #F59E0B;
}
.btn-primary:hover:not(:disabled) {
  background: #D97706;
  border-color: #D97706;
}
.btn-secondary {
  background: white;
  color: #666;
  border-color: #E5E7EB;
}
.btn-secondary:hover:not(:disabled) {
  background: #FFF9F5;
  border-color: #FF8C42;
  color: #D35400;
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
  border-color: #F59E0B;
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
.mapbox-hint {
  display: block;
  margin-top: 6px;
  color: #3b82f6;
  font-size: 11px;
  font-style: italic;
}
.mapbox-hint i {
  margin-right: 4px;
}
.mapbox-loading {
  display: block;
  margin-top: 6px;
  color: #6b7280;
  font-size: 11px;
}
.mapbox-loading i {
  margin-right: 4px;
}
.autocomplete-suggestions {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 1px solid #E5E7EB;
  border-radius: 8px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  max-height: 300px;
  overflow-y: auto;
  z-index: 1000;
  margin-top: 4px;
}
.suggestion-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 12px 16px;
  cursor: pointer;
  border-bottom: 1px solid #F3F4F6;
  transition: background-color 0.2s ease;
}
.suggestion-item:last-child {
  border-bottom: none;
}
.suggestion-item:hover {
  background-color: #F9FAFB;
}
.suggestion-item i {
  color: #3B82F6;
  margin-top: 2px;
  flex-shrink: 0;
}
.suggestion-text {
  flex: 1;
  min-width: 0;
}
.suggestion-main {
  font-size: 14px;
  font-weight: 500;
  color: #1F2937;
  margin-bottom: 4px;
}
.suggestion-context {
  font-size: 12px;
  color: #6B7280;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
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
.address-parts {
  margin-top: 16px;
  padding: 16px;
  background: #F8FAFC;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  border-left: 3px solid #3b82f6;
}
.address-parts .form-group {
  margin-bottom: 12px;
}
.address-parts .form-group:last-child {
  margin-bottom: 0;
}
.address-parts label {
  font-size: 12px;
  font-weight: 600;
  color: #64748B;
  margin-bottom: 6px;
  display: block;
}
.readonly-field {
  background-color: #F1F5F9 !important;
  color: #1E293B !important;
  cursor: not-allowed !important;
  border: 1px solid #CBD5E1 !important;
  font-weight: 500;
}
.readonly-field:focus {
  outline: none;
  border-color: #94A3B8 !important;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1) !important;
}
.readonly-field::placeholder {
  color: #94A3B8;
  font-style: italic;
}
.error-text {
  display: block;
  margin-top: 4px;
  color: #ef4444;
  font-size: 12px;
  font-weight: 500;
}
.help-text {
  display: block;
  margin-top: 4px;
  color: #6b7280;
  font-size: 11px;
}
.form-group input.error {
  border-color: #ef4444 !important;
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1) !important;
}
.coordinate-warning {
  margin-top: 12px;
  padding: 12px;
  background: #fef3c7;
  border: 1px solid #fbbf24;
  border-radius: 6px;
  color: #92400e;
  font-size: 13px;
  display: flex;
  align-items: center;
  gap: 8px;
}
.coordinate-warning i {
  color: #f59e0b;
  font-size: 16px;
}
@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
