<template>
  <div class="category-form">
    <form class="form" @keydown.enter.prevent @submit.prevent="handleSubmit">
      <!-- Basic Info Card -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-info-circle"></i>
          <h3>Basic Information</h3>
        </div>
        <div class="card-content">
          <div class="form-group">
            <label>
              <i class="fas fa-tag"></i>
              Category Name <span class="required">*</span>
            </label>
            <input
              v-model="form.name"
              type="text"
              class="form-control"
              required
              placeholder="E.g: Main Course, Appetizer, Dessert..."
            />
          </div>
        </div>
      </div>
      <!-- Image Card -->
      <div class="info-card">
        <div class="card-header">
          <i class="fas fa-image"></i>
          <h3>Category Image</h3>
        </div>
        <div class="card-content">
          <div class="form-row">
            <div class="form-group">
              <label>
                <i class="fas fa-align-left"></i>
                Description
              </label>
              <textarea
                v-model="form.description"
                class="form-control"
                rows="2"
                placeholder="Detailed description of the category..."
              ></textarea>
            </div>
            <div class="form-group">
              <label>
                <i class="fas fa-image"></i>
                Image
              </label>
              <div class="image-upload-container">
                <input
                  ref="imageInput"
                  type="file"
                  accept="image
.info-card {
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  overflow: hidden;
  margin-bottom: 0;
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
  gap: 16px;
}
.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  align-items: stretch;
}
@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 0;
}
.form-row .form-group {
  height: 100%;
  display: flex;
  flex-direction: column;
}
.form-row .form-group .form-control {
  flex: 1;
}
.form-group label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
  color: #6B7280;
}
.form-group label i {
  color: #FF8C42;
  font-size: 12px;
}
.required {
  color: #EF4444;
  font-weight: 700;
}
.form-control {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  font-size: 14px;
  background: white;
  color: #1a1a1a;
  font-weight: 500;
  transition: all 0.2s ease;
}
.form-control:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
  background: white;
}
.form-control::placeholder {
  color: #9CA3AF;
  font-weight: 400;
}
.form-control textarea {
  resize: none;
  height: 100%;
  min-height: 120px;
}
.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 8px;
  padding-top: 24px;
  border-top: 2px solid #F0E6D9;
}
.btn {
  padding: 12px 24px;
  border: 2px solid;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-cancel {
  background: white;
  color: #6B7280;
  border-color: #E5E7EB;
}
.btn-cancel:hover:not(:disabled) {
  background: #F9FAFB;
  border-color: #D1D5DB;
  color: #4B5563;
}
.btn-submit {
  background: white;
  color: #F59E0B;
  border-color: #F59E0B;
}
.btn-submit:hover:not(:disabled) {
  background: #FFFBEB;
  border-color: #D97706;
  color: #D97706;
}
.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.image-upload-container {
  position: relative;
  border: 2px dashed #E5E5E5;
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  transition: all 0.2s ease;
  cursor: pointer;
  background: #FAFAFA;
  height: 100%;
  min-height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.image-upload-container:hover {
  border-color: #FF8C42;
  background: #FFF9F5;
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
  max-width: 100%;
  max-height: 180px;
  border-radius: 12px;
  border: 2px solid #F0E6D9;
  object-fit: cover;
}
.remove-image-btn {
  position: absolute;
  top: -8px;
  right: -8px;
  background: #EF4444;
  color: white;
  border: 2px solid white;
  border-radius: 50%;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.2s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}
.remove-image-btn:hover {
  background: #DC2626;
  transform: scale(1.1);
}
.image-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  color: #9CA3AF;
}
.image-placeholder i {
  font-size: 48px;
  color: #D1D5DB;
}
.image-placeholder span {
  font-size: 14px;
  font-weight: 500;
}
.image-info {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 12px;
  color: #6B7280;
  font-size: 12px;
  text-align: center;
  justify-content: center;
}
.image-info i {
  color: #9CA3AF;
  font-size: 12px;
}
</style>
