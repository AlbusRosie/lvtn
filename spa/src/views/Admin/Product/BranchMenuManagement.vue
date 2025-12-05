<template>
  <div class="branch-menu-management">
    <!-- Top Products Section -->
    <div class="top-products-section">
      <div v-if="loadingTopProducts" class="top-products-loading">
        <i class="fas fa-spinner fa-spin"></i>
        <span>Loading...</span>
      </div>
      <div v-else-if="topProducts.length === 0" class="top-products-empty">
        <i class="fas fa-box-open"></i>
        <span>No sales data yet</span>
      </div>
      <div v-else class="top-products-grid">
        <div 
          v-for="(product, index) in topProducts.slice(0, 5)" 
          :key="product.id || product.product_id || index"
          class="top-product-card"
        >
          <div class="product-image-wrapper">
            <img 
              :src="product.image || product.image_url || '/images/placeholder-product.png'" 
              :alt="product.name || product.product_name"
              class="product-image"
              @error="handleTopProductImageError"
            />
          </div>
          <div class="product-info">
            <h3 class="product-name">{{ product.name || product.product_name || 'N/A' }}</h3>
            <div class="product-stats">
              <div class="product-stat-item">
                <span class="stat-label-text">Total Sales</span>
                <span class="stat-value-text">{{ product.total_quantity || 0 }}</span>
              </div>
            </div>
            <div class="product-footer">
              <div class="product-rating">
                <i v-for="i in 5" :key="i" class="fas fa-star" :class="{ 'star-filled': i <= (product.rating || 4), 'star-empty': i > (product.rating || 4) }"></i>
              </div>
              <div class="product-likes">
                <i class="fas fa-heart"></i>
                <span>{{ formatLikes(product.likes || product.total_quantity * 10) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Filters Section -->
    <div class="filters-card">
      <div class="filters-header">
        <h3>Filters</h3>
        <div class="filters-header-actions">
          <button v-if="selectedBranchId || filters.category || filters.status || filters.min_price || filters.max_price || searchQuery" 
                  @click="clearFilters" class="btn-clear-filters">
            <i class="fas fa-times"></i>
            Clear Filters
          </button>
          <button @click="showAdvancedFilters = !showAdvancedFilters" class="btn-toggle-filters">
            <i class="fas" :class="showAdvancedFilters ? 'fa-chevron-up' : 'fa-chevron-down'"></i>
            {{ showAdvancedFilters ? 'Collapse' : 'Expand' }}
          </button>
        </div>
      </div>
      <div class="filters-grid">
        <div class="filter-group">
          <label>Branch</label>
          <select v-model="selectedBranchId" @change="onBranchChange" class="filter-select">
            <option value="">All Branches</option>
            <option v-for="branch in branches" :key="branch.id" :value="branch.id">
              {{ branch.name }}
            </option>
          </select>
        </div>
        <div class="filter-group">
          <label>Search</label>
          <input
            v-model="searchQuery"
            @input="onSearchInput"
            @keyup.enter="onSearchEnter"
            type="text"
            placeholder="Search products..."
            class="filter-input"
          />
        </div>
        <div class="filter-group">
          <label>Category</label>
          <select v-model="filters.category" class="filter-select">
            <option value="">All Categories</option>
            <option v-for="category in categories" :key="category.id" :value="category.id">
              {{ category.name }}
            </option>
          </select>
        </div>
        <div class="filter-group">
          <label>Status</label>
          <select v-model="filters.status" class="filter-select">
            <option value="">All Status</option>
            <option value="available">Available</option>
            <option value="out_of_stock">Out of Stock</option>
            <option value="temporarily_unavailable">Temporarily Unavailable</option>
          </select>
        </div>
        <div v-show="showAdvancedFilters" class="filter-group">
          <label>Price From</label>
          <input v-model="filters.min_price" type="number" placeholder="0" class="filter-input" min="0">
        </div>
        <div v-show="showAdvancedFilters" class="filter-group">
          <label>Price To</label>
          <input v-model="filters.max_price" type="number" placeholder="999999999" class="filter-input" min="0">
        </div>
        <div class="filter-group">
          <label>Sort By</label>
          <div class="sort-controls">
            <select v-model="sortBy" class="filter-select">
              <option value="name">By Name</option>
              <option value="price">By Price</option>
              <option value="category">By Category</option>
              <option value="status">By Status</option>
              <option value="created_at">By Created Date</option>
            </select>
            <button 
              @click="sortOrder = sortOrder === 'asc' ? 'desc' : 'asc'" 
              class="btn-sort-toggle"
              :title="sortOrder === 'asc' ? 'Ascending' : 'Descending'"
            >
              <i class="fas" :class="sortOrder === 'asc' ? 'fa-sort-up' : 'fa-sort-down'"></i>
            </button>
          </div>
        </div>
      </div>
    </div>
    <div class="content-area">
      <div v-if="loading" class="loading">
        <LoadingSpinner />
        <p>Loading products...</p>
      </div>
      <div v-else-if="error" class="error">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="loadProducts" class="btn btn-secondary">
          Retry
        </button>
      </div>
      <div v-else-if="filteredProducts.length === 0 && !selectedBranchId" class="empty-state">
        <i class="fas fa-box"></i>
        <h3>No Products Found</h3>
        <p v-if="filters.category || filters.status || filters.min_price || filters.max_price || searchQuery">
          No products match the current filters
        </p>
        <p v-else>No products in the system yet.</p>
        <button @click="showAddProductModal = true" class="btn btn-primary">
          Add First Product
        </button>
      </div>
      <div v-else class="products-card">
        <div class="table-header-section">
          <div class="table-title">
            <h3 v-if="selectedBranchId">{{ selectedBranch?.name }}</h3>
            <h3 v-else>Product List</h3>
            <span class="table-count">
              <template v-if="selectedBranchId">
                {{ products.length }} products
              </template>
              <template v-else>
                {{ filteredProducts.length }}/{{ totalCount || products.length }} products
              </template>
            </span>
          </div>
          <div class="header-actions-wrapper">
            <div v-if="selectedProducts.length > 0" class="bulk-actions">
              <span class="selected-count">{{ selectedProducts.length }} selected</span>
              <button 
                v-if="selectedBranchId"
                class="bulk-btn" 
                @click="bulkAddToBranch"
                :disabled="loading"
                title="Add to Branch"
              >
                <i class="fas fa-plus"></i>
              </button>
              <button 
                v-if="selectedBranchId"
                class="bulk-btn" 
                @click="bulkRemoveFromBranch"
                :disabled="loading"
                title="Remove from Branch"
              >
                <i class="fas fa-trash"></i>
              </button>
              <button 
                class="bulk-btn" 
                @click="selectedProducts = []"
                title="Deselect"
              >
                <i class="fas fa-times"></i>
              </button>
            </div>
            <div class="header-actions">
              <button @click="openExportModal" class="btn-export" :disabled="loading">
                <i class="fas fa-file-excel"></i>
                Export Excel
              </button>
              <button @click="showAddProductModal = true" class="btn-add" :disabled="loading">
                <i class="fas fa-plus"></i>
                Add Product
              </button>
              <button @click="refreshData" class="btn-refresh" :disabled="loading">
                <i class="fas fa-sync"></i>
                Refresh
              </button>
            </div>
          </div>
        </div>
        <!-- Branch Management Mode -->
        <div v-if="selectedBranchId" class="products-layout">
          <!-- Column: Not Added Products -->
          <div class="products-column not-added-column">
            <div class="column-header">
              <h4><i class="fas fa-inbox"></i> Not Added Products</h4>
              <span class="count">{{ notAddedProductsCount }} products</span>
            </div>
            <div class="table-wrapper">
              <table class="modern-table">
                <thead>
                  <tr>
                    <th class="checkbox-col">
                      <input 
                        type="checkbox" 
                        :checked="selectedNotAddedProducts.length === filteredNotAddedProductsAll.length && filteredNotAddedProductsAll.length > 0"
                        @change="toggleSelectAllNotAdded"
                        class="checkbox-input"
                      />
                    </th>
                    <th class="image-col">Image</th>
                    <th class="name-col">Product Name</th>
                    <th class="category-col">Category</th>
                    <th class="price-col">Base Price</th>
                    <th class="actions-col">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="filteredNotAddedProducts.length === 0">
                    <td colspan="6" class="empty-table-cell">
                      <div class="empty-state-inline">
                        <i class="fas fa-inbox"></i>
                        <p>No products</p>
                      </div>
                    </td>
                  </tr>
                  <tr 
                    v-for="product in filteredNotAddedProducts" 
                    :key="product.id"
                    :class="{ 'row-selected': selectedProducts.includes(product.id) }"
                  >
                    <td class="checkbox-col">
                      <input 
                        type="checkbox" 
                        :id="`product-${product.id}`"
                        :value="product.id"
                        v-model="selectedProducts"
                        class="checkbox-input"
                      />
                    </td>
                    <td class="image-col">
                      <div class="product-image-cell">
                        <img 
                          :src="product.image || DEFAULT_PRODUCT_IMAGE" 
                          :alt="product.name"
                          @error="handleImageError"
                        />
                      </div>
                    </td>
                    <td class="name-col">
                      <div class="product-name-cell" :title="product.name">{{ product.name }}</div>
                    </td>
                    <td class="category-col">
                      <span class="category-badge">{{ product.category_name }}</span>
                    </td>
                    <td class="price-col">
                      <span class="price-value">{{ formatPrice(product.base_price) }}</span>
                    </td>
                    <td class="actions-col">
                      <div class="action-buttons">
                        <button 
                          @click="addProductToBranch(product)"
                          :disabled="loading"
                          class="btn-action btn-add-product"
                          title="Add to Branch"
                        >
                          <i class="fas fa-plus"></i>
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <!-- Pagination for Not Added Products -->
            <div v-if="notAddedTotalPages > 1" class="column-pagination">
              <button 
                class="pagination-btn-small" 
                @click="notAddedPage = Math.max(1, notAddedPage - 1)" 
                :disabled="notAddedPage === 1"
              >
                <i class="fas fa-chevron-left"></i>
              </button>
              <span class="pagination-info-small">
                {{ notAddedPage }} / {{ notAddedTotalPages }}
              </span>
              <button 
                class="pagination-btn-small" 
                @click="notAddedPage = Math.min(notAddedTotalPages, notAddedPage + 1)" 
                :disabled="notAddedPage === notAddedTotalPages"
              >
                <i class="fas fa-chevron-right"></i>
              </button>
            </div>
          </div>
          <!-- Column: Branch Menu -->
          <div class="products-column added-column">
            <div class="column-header">
              <h4><i class="fas fa-list"></i> Branch Menu</h4>
              <span class="count">{{ addedProductsCount }} products</span>
            </div>
            <div class="table-wrapper">
              <table class="modern-table">
                <thead>
                  <tr>
                    <th class="checkbox-col">
                      <input 
                        type="checkbox" 
                        :checked="selectedAddedProducts.length === filteredAddedProducts.length && filteredAddedProducts.length > 0"
                        @change="toggleSelectAllAdded"
                        class="checkbox-input"
                      />
                    </th>
                    <th class="image-col">Image</th>
                    <th class="name-col">Product Name</th>
                    <th class="category-col">Category</th>
                    <th class="price-col">Base Price</th>
                    <th class="branch-price-col">Branch Price</th>
                    <th class="actions-col">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="paginatedAddedProducts.length === 0">
                    <td colspan="7" class="empty-table-cell">
                      <div class="empty-state-inline">
                        <i class="fas fa-list"></i>
                        <p>No products in menu yet</p>
                      </div>
                    </td>
                  </tr>
                  <tr 
                    v-for="product in paginatedAddedProducts" 
                    :key="product.id"
                    :class="{ 'row-selected': selectedProducts.includes(product.id) }"
                  >
                    <td class="checkbox-col">
                      <input 
                        type="checkbox" 
                        :id="`product-${product.id}`"
                        :value="product.id"
                        v-model="selectedProducts"
                        class="checkbox-input"
                      />
                    </td>
                    <td class="image-col">
                      <div class="product-image-cell">
                        <img 
                          :src="product.image || DEFAULT_PRODUCT_IMAGE" 
                          :alt="product.name"
                          @error="handleImageError"
                        />
                      </div>
                    </td>
                    <td class="name-col">
                      <div class="product-name-cell" :title="product.name">{{ product.name }}</div>
                    </td>
                    <td class="category-col">
                      <span class="category-badge">{{ product.category_name }}</span>
                    </td>
                    <td class="price-col">
                      <span class="price-value">{{ formatPrice(product.base_price) }}</span>
                    </td>
                    <td class="branch-price-col">
                      <span class="branch-price-value">{{ formatPrice(product.branch_price || product.base_price) }}</span>
                    </td>
                    <td class="actions-col">
                      <div class="action-buttons">
                        <button 
                          v-if="product.final_status === 'available' || product.final_status === 'out_of_stock' || product.final_status === 'temporarily_unavailable'"
                          @click="editBranchProduct(product)"
                          class="btn-action btn-view"
                          title="View/Edit"
                        >
                          <i class="fas fa-eye"></i>
                        </button>
                        <button 
                          v-if="product.final_status === 'available' || product.final_status === 'out_of_stock' || product.final_status === 'temporarily_unavailable'"
                          @click="openDeleteBranchProductModal(product)"
                          :disabled="loading"
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
            <!-- Pagination for Added Products -->
            <div v-if="addedTotalPages > 1" class="column-pagination">
              <button 
                class="pagination-btn-small" 
                @click="addedPage = Math.max(1, addedPage - 1)" 
                :disabled="addedPage === 1"
              >
                <i class="fas fa-chevron-left"></i>
              </button>
              <span class="pagination-info-small">
                {{ addedPage }} / {{ addedTotalPages }}
              </span>
              <button 
                class="pagination-btn-small" 
                @click="addedPage = Math.min(addedTotalPages, addedPage + 1)" 
                :disabled="addedPage === addedTotalPages"
              >
                <i class="fas fa-chevron-right"></i>
              </button>
            </div>
          </div>
        </div>
        <!-- All Products Management Mode -->
        <div v-else class="all-products-layout">
          <div class="table-wrapper">
            <table class="modern-table">
              <thead>
                <tr>
                  <th class="checkbox-col">
                    <input 
                      type="checkbox" 
                      :checked="selectedProducts.length === filteredProducts.length && filteredProducts.length > 0"
                      @change="toggleSelectAll"
                      class="checkbox-input"
                      title="Select All"
                    />
                  </th>
                  <th class="image-col">Image</th>
                  <th class="name-col">Product Name</th>
                  <th class="category-col">Category</th>
                  <th class="price-col">Base Price</th>
                  <th class="status-col">Status</th>
                  <th class="actions-col">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="product in paginatedProducts" 
                  :key="product.id"
                  :class="{ 'row-selected': selectedProducts.includes(product.id) }"
                >
                  <td class="checkbox-col">
                    <input 
                      type="checkbox" 
                      :id="`product-${product.id}`"
                      :value="product.id"
                      v-model="selectedProducts"
                      class="checkbox-input"
                    >
                  </td>
                  <td class="image-col">
                    <div class="product-image-cell">
                      <img 
                        :src="product.image || DEFAULT_PRODUCT_IMAGE" 
                        :alt="product.name"
                        @error="handleImageError"
                      >
                    </div>
                  </td>
                  <td class="name-col">
                    <div class="product-name-cell">{{ product.name }}</div>
                  </td>
                  <td class="category-col">
                    <span class="category-badge">{{ product.category_name }}</span>
                  </td>
                  <td class="price-col">
                    <span class="price-value">{{ formatPrice(product.base_price) }}</span>
                  </td>
                  <td class="status-col">
                    <select 
                      v-if="selectedBranchId"
                      :value="product.final_status || product.status"
                      @change="quickUpdateStatus(product, $event.target.value)"
                      class="status-select"
                      :class="getStatusBadgeClass(product.final_status || product.status)"
                    >
                      <option value="available">Available</option>
                      <option value="out_of_stock">Out of Stock</option>
                      <option value="temporarily_unavailable">Temporarily Unavailable</option>
                    </select>
                    <span v-else class="status-badge" :class="getStatusBadgeClass(product.status)">
                      {{ getStatusText(product.status) }}
                    </span>
                  </td>
                  <td class="actions-col">
                    <div class="action-buttons">
                      <button 
                        @click="editProduct(product)"
                        class="btn-action btn-view"
                        title="View/Edit"
                      >
                        <i class="fas fa-eye"></i>
                      </button>
                      <button 
                        @click="openDeleteProductModal(product)"
                        :disabled="loading"
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
        </div>
        <!-- Pagination (only show when not viewing branch-specific menu) -->
        <div v-if="!selectedBranchId && totalPages > 1" class="pagination-section">
          <nav class="pagination-nav">
            <button 
              class="pagination-btn" 
              @click="loadProducts(currentPage - 1)" 
              :disabled="currentPage === 1 || loading"
            >
              <i class="fas fa-chevron-left"></i>
            </button>
            <span class="pagination-info">
              Page {{ currentPage }} / {{ totalPages }}
            </span>
            <button 
              class="pagination-btn" 
              @click="loadProducts(currentPage + 1)" 
              :disabled="currentPage === totalPages || loading"
            >
              <i class="fas fa-chevron-right"></i>
            </button>
          </nav>
        </div>
      </div>
    </div>
    <div 
      v-if="showAddProductModal" 
      class="modal-overlay" 
      @click.self="showAddProductModal = false"
    >
      <div class="modal-content add-product-modal" @click.stop>
        <div class="modal-header">
          <div class="modal-header-left">
            <div class="modal-icon-wrapper icon-add">
              <i class="fas fa-plus"></i>
            </div>
            <div class="modal-title-section">
              <h3>Add Product to Menu</h3>
            </div>
          </div>
          <button 
            type="button" 
            class="btn-close-modal" 
            @click="showAddProductModal = false"
          >
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <AddProductToBranchForm 
            :branches="branches"
            :categories="categories"
            :selected-branch-id="selectedBranchId"
            @success="onProductAdded"
            @cancel="showAddProductModal = false"
          />
        </div>
      </div>
    </div>
    <div 
      v-if="showEditModal && editingProduct && selectedBranch"
      class="modal-overlay" 
      @click="showEditModal = false"
    >
      <div class="modal-content edit-product-modal" @click.stop>
        <div class="modal-header">
          <div class="modal-header-left">
            <div class="modal-icon-wrapper icon-edit">
              <i class="fas fa-edit"></i>
            </div>
            <div class="modal-title-section">
              <h3>Edit Branch Product</h3>
              <p v-if="editingProduct?.name" class="modal-subtitle">{{ editingProduct.name }}</p>
            </div>
          </div>
          <button 
            type="button" 
            class="btn-close-modal" 
            @click="showEditModal = false"
          >
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <EditBranchProductForm 
            :product="editingProduct"
            :branch="selectedBranch"
            @success="onProductUpdated"
            @cancel="showEditModal = false"
          />
        </div>
      </div>
    </div>
    <!-- Modal Edit Product -->
    <div 
      v-if="showEditProductModal && editingProductForEdit" 
      class="modal-overlay" 
      @click="showEditProductModal = false"
    >
      <div class="modal-content edit-product-modal" @click.stop>
        <div class="modal-header">
          <div class="modal-header-left">
            <div class="modal-icon-wrapper icon-edit">
              <i class="fas fa-edit"></i>
            </div>
            <div class="modal-title-section">
              <h3>Edit Product</h3>
              <p v-if="editingProductForEdit?.name" class="modal-subtitle">{{ editingProductForEdit.name }}</p>
            </div>
          </div>
          <button 
            type="button" 
            class="btn-close-modal" 
            @click="showEditProductModal = false"
          >
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <EditProductForm 
            :product="editingProductForEdit"
            :categories="categories"
            :branches="branches"
            @success="onProductEdited"
            @cancel="showEditProductModal = false"
          />
        </div>
      </div>
    </div>
    <!-- Export Modal -->
    <div v-if="showExportModal" class="modal-overlay" @click.self="showExportModal = false">
      <div class="modal-content export-modal" @click.stop>
        <div class="modal-header">
          <h3>Export Product List</h3>
          <button @click="showExportModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <!-- Filters Section -->
          <div class="export-section-card">
            <div class="export-section-header">
              <h4 class="section-title">
                Filters
              </h4>
            </div>
            <div class="export-section-body">
              <div class="filter-grid">
                <div class="form-group">
                  <label>
                    <i class="fas fa-store label-icon"></i>
                    Branch
                  </label>
                  <select v-model="exportFilters.branch_id" class="form-select">
                    <option value="">All Branches</option>
                    <option v-for="branch in branches" :key="branch.id" :value="branch.id">
                      {{ branch.name }}
                    </option>
                  </select>
                </div>
                <div class="form-group">
                  <label>
                    <i class="fas fa-tags label-icon"></i>
                    Category
                  </label>
                  <select v-model="exportFilters.category" class="form-select">
                    <option value="">All Categories</option>
                    <option v-for="category in categories" :key="category.id" :value="category.id">
                      {{ category.name }}
                    </option>
                  </select>
                </div>
                <div class="form-group">
                  <label>
                    <i class="fas fa-info-circle label-icon"></i>
                    Status
                  </label>
                  <select v-model="exportFilters.status" class="form-select">
                    <option value="">All Status</option>
                    <option value="available">Available</option>
                    <option value="out_of_stock">Out of Stock</option>
                    <option value="temporarily_unavailable">Temporarily Unavailable</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>
                    <i class="fas fa-dollar-sign label-icon"></i>
                    Price From
                  </label>
                  <input v-model="exportFilters.min_price" type="number" class="form-input" placeholder="0" min="0">
                </div>
                <div class="form-group">
                  <label>
                    <i class="fas fa-dollar-sign label-icon"></i>
                    Price To
                  </label>
                  <input v-model="exportFilters.max_price" type="number" class="form-input" placeholder="999999999" min="0">
                </div>
                <div v-if="exportFilters.branch_id" class="form-group">
                  <label>
                    <i class="fas fa-list label-icon"></i>
                    Product Type
                  </label>
                  <select v-model="exportFilters.product_type" class="form-select">
                    <option value="all">Both (Not Added and Added)</option>
                    <option value="not-added">Not Added to Branch</option>
                    <option value="added">Added to Branch</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
          <div class="export-note">
            <i class="fas fa-info-circle note-icon"></i>
            <span>The file will be exported in CSV (Excel) format. All products matching the selected filters will be exported.</span>
          </div>
        </div>
        <div class="modal-actions">
          <button @click="showExportModal = false" class="btn-close">
            Cancel
          </button>
          <button @click="exportProducts('csv')" class="btn-confirm" :disabled="isExporting">
            <span v-if="isExporting">Exporting...</span>
            <span v-else>
              <i class="fas fa-download btn-icon"></i>
              Export Excel
            </span>
          </button>
        </div>
      </div>
    </div>
    <!-- Delete Branch Product Modal -->
    <div v-if="showDeleteBranchProductModal" class="modal-overlay" @click.self="showDeleteBranchProductModal = false">
      <div class="modal-content delete-modal">
        <div class="modal-header">
          <div class="delete-header">
            <div class="delete-header-icon">
              <i class="fas fa-exclamation-triangle"></i>
            </div>
            <h3>Confirm Remove Product from Branch</h3>
          </div>
          <button @click="showDeleteBranchProductModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <p>Are you sure you want to remove product <strong>{{ productToDelete?.name }}</strong> from branch <strong>{{ selectedBranch?.name }}</strong>?</p>
          <p class="warning">This action cannot be undone.</p>
        </div>
        <div class="modal-actions">
          <button @click="showDeleteBranchProductModal = false" class="btn btn-secondary">
            <i class="fas fa-times"></i>
            Cancel
          </button>
          <button @click="confirmDeleteBranchProduct" class="btn btn-danger" :disabled="deleteLoading">
            <i v-if="!deleteLoading" class="fas fa-trash"></i>
            <i v-else class="fas fa-spinner fa-spin"></i>
            <span v-if="deleteLoading">Deleting...</span>
            <span v-else>Delete</span>
          </button>
        </div>
      </div>
    </div>
    <!-- Delete Product Modal -->
    <div v-if="showDeleteProductModal" class="modal-overlay" @click.self="showDeleteProductModal = false">
      <div class="modal-content delete-modal">
        <div class="modal-header">
          <div class="delete-header">
            <div class="delete-header-icon">
              <i class="fas fa-exclamation-triangle"></i>
            </div>
            <h3>Confirm Delete Product</h3>
          </div>
          <button @click="showDeleteProductModal = false" class="btn-close-modal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <p>Are you sure you want to delete product <strong>{{ productToDelete?.name }}</strong>?</p>
          <p class="warning">This action cannot be undone.</p>
        </div>
        <div class="modal-actions">
          <button @click="showDeleteProductModal = false" class="btn btn-secondary">
            <i class="fas fa-times"></i>
            Cancel
          </button>
          <button @click="confirmDeleteProduct" class="btn btn-danger" :disabled="deleteLoading">
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
<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { useToast } from 'vue-toastification'
import ProductService from '@/services/ProductService'
import BranchService from '@/services/BranchService'
import { DEFAULT_AVATAR, DEFAULT_PRODUCT_IMAGE } from '@/constants'
import AddProductToBranchForm from '@/components/Admin/Product/AddProductToBranchForm.vue'
import EditBranchProductForm from '@/components/Admin/Product/EditBranchProductForm.vue'
import EditProductForm from '@/components/Admin/Product/EditProductForm.vue'
import ProductCard from '@/components/Admin/Product/ProductCard.vue'
import LoadingSpinner from '@/components/LoadingSpinner.vue'
import OrderService from '@/services/OrderService'
const toast = useToast()
const loading = ref(false)
const error = ref(null)
const branches = ref([])
const categories = ref([])
const products = ref([])
const selectedBranchId = ref('')
const selectedProducts = ref([])
const selectAll = ref(false)
const searchQuery = ref('')
let searchTimeout = null
const showAddProductModal = ref(false)
const showEditModal = ref(false)
const editingProduct = ref(null)
const showEditProductModal = ref(false)
const editingProductForEdit = ref(null)
const showDeleteBranchProductModal = ref(false)
const showDeleteProductModal = ref(false)
const productToDelete = ref(null)
const deleteLoading = ref(false)
const currentPage = ref(1)
const totalPages = ref(1)
const totalCount = ref(0)
const pageSize = ref(100) 
const notAddedPage = ref(1)
const notAddedPageSize = ref(20)
const addedPage = ref(1)
const addedPageSize = ref(20)
const sortBy = ref('name') 
const sortOrder = ref('asc') 
const showExportModal = ref(false)
const isExporting = ref(false)
const exportFilters = reactive({
  branch_id: '',
  category: '',
  status: '',
  min_price: '',
  max_price: '',
  product_type: 'all' 
})
const showAdvancedFilters = ref(false)
const topProducts = ref([])
const loadingTopProducts = ref(false)
const statistics = ref({
  total_products: 0,
  products_by_category: {},
  products_by_status: {},
  products_by_branch: {}
})
const filters = reactive({
  category: '',
  status: '',
  min_price: '',
  max_price: ''
})
const selectedBranch = computed(() => {
  return branches.value.find(b => b.id == selectedBranchId.value)
})
const productStats = computed(() => {
  const total = products.value.length
  const now = new Date()
  const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000)
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
  const new3Days = products.value.filter(product => {
    if (!product.created_at) return false
    return new Date(product.created_at) >= threeDaysAgo
  }).length
  const new7Days = products.value.filter(product => {
    if (!product.created_at) return false
    return new Date(product.created_at) >= sevenDaysAgo
  }).length
  const available = products.value.filter(product => {
    const status = product.final_status || product.status
    return status === 'available'
  }).length
  return {
    total,
    new3Days,
    new7Days,
    available
  }
})
const addedProductsCount = computed(() => {
  return products.value.filter(p => p.final_status === 'available' || p.final_status === 'out_of_stock' || p.final_status === 'temporarily_unavailable').length
})
const addedProducts = computed(() => {
  return products.value.filter(p => p.final_status === 'available' || p.final_status === 'out_of_stock' || p.final_status === 'temporarily_unavailable')
})
const filteredAddedProducts = computed(() => {
  let result = [...addedProducts.value]
  if (searchQuery.value) {
    const search = searchQuery.value.toLowerCase().trim()
    result = result.filter(p => {
      const name = (p.name || '').toLowerCase()
      const category = (p.category_name || '').toLowerCase()
      const description = (p.description || '').toLowerCase()
      return name.includes(search) || 
             category.includes(search) || 
             description.includes(search)
    })
  }
  if (filters.category) {
    result = result.filter(p => {
      return p.category_id == filters.category || 
             p.categoryId == filters.category
    })
  }
  if (filters.status) {
    result = result.filter(p => {
      const status = p.final_status || p.status || ''
      return status === filters.status
    })
  }
  if (filters.min_price) {
    const minPrice = parseFloat(filters.min_price)
    result = result.filter(p => {
      const price = p.branch_price || p.base_price || 0
      return price >= minPrice
    })
  }
  if (filters.max_price) {
    const maxPrice = parseFloat(filters.max_price)
    result = result.filter(p => {
      const price = p.branch_price || p.base_price || 0
      return price <= maxPrice
    })
  }
  return result
})
const selectedNotAddedProducts = computed(() => {
  return selectedProducts.value.filter(id => 
    filteredNotAddedProductsAll.value.some(p => p.id === id)
  )
})
const selectedAddedProducts = computed(() => {
  return selectedProducts.value.filter(id => 
    filteredAddedProducts.value.some(p => p.id === id)
  )
})
const notAddedProducts = computed(() => {
  if (!selectedBranchId.value) {
    return []
  }
  return products.value.filter(p => p.final_status === 'not_added')
})
const notAddedProductsCount = computed(() => {
  return notAddedProducts.value.length
})
const filteredProducts = computed(() => {
  let result = [...products.value]
  if (searchQuery.value) {
    const search = searchQuery.value.toLowerCase().trim()
    result = result.filter(p => {
      const name = (p.name || '').toLowerCase()
      const category = (p.category_name || '').toLowerCase()
      const description = (p.description || '').toLowerCase()
      return name.includes(search) || 
             category.includes(search) || 
             description.includes(search)
    })
  }
  if (filters.category) {
    result = result.filter(p => {
      return p.category_id == filters.category || 
             p.categoryId == filters.category
    })
  }
  if (filters.status) {
    result = result.filter(p => {
      const status = p.final_status || p.status || ''
      return status === filters.status
    })
  }
  if (filters.min_price) {
    const minPrice = parseFloat(filters.min_price)
    result = result.filter(p => {
      const price = p.branch_price || p.base_price || 0
      return price >= minPrice
    })
  }
  if (filters.max_price) {
    const maxPrice = parseFloat(filters.max_price)
    result = result.filter(p => {
      const price = p.branch_price || p.base_price || 0
      return price <= maxPrice
    })
  }
  result.sort((a, b) => {
    let aVal, bVal
    switch (sortBy.value) {
      case 'name':
        aVal = (a.name || '').toLowerCase()
        bVal = (b.name || '').toLowerCase()
        break
      case 'price':
        aVal = parseFloat(a.branch_price || a.base_price || 0)
        bVal = parseFloat(b.branch_price || b.base_price || 0)
        break
      case 'category':
        aVal = (a.category_name || '').toLowerCase()
        bVal = (b.category_name || '').toLowerCase()
        break
      case 'status':
        aVal = a.final_status || a.status || ''
        bVal = b.final_status || b.status || ''
        break
      case 'created_at':
        aVal = new Date(a.created_at || 0).getTime()
        bVal = new Date(b.created_at || 0).getTime()
        break
      default:
        aVal = (a.name || '').toLowerCase()
        bVal = (b.name || '').toLowerCase()
    }
    if (sortOrder.value === 'asc') {
      return aVal > bVal ? 1 : aVal < bVal ? -1 : 0
    } else {
      return aVal < bVal ? 1 : aVal > bVal ? -1 : 0
    }
  })
  return result
})
const paginatedProducts = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredProducts.value.slice(start, end)
})
const filteredNotAddedProductsAll = computed(() => {
  let result = [...notAddedProducts.value]
  if (searchQuery.value) {
    const search = searchQuery.value.toLowerCase().trim()
    result = result.filter(p => {
      const name = (p.name || '').toLowerCase()
      const category = (p.category_name || '').toLowerCase()
      const description = (p.description || '').toLowerCase()
      return name.includes(search) || 
             category.includes(search) || 
             description.includes(search)
    })
  }
  if (filters.category) {
    result = result.filter(p => {
      return p.category_id == filters.category || 
             p.categoryId == filters.category
    })
  }
  if (filters.min_price) {
    const minPrice = parseFloat(filters.min_price)
    result = result.filter(p => {
      const price = p.base_price || 0
      return price >= minPrice
    })
  }
  if (filters.max_price) {
    const maxPrice = parseFloat(filters.max_price)
    result = result.filter(p => {
      const price = p.base_price || 0
      return price <= maxPrice
    })
  }
  result.sort((a, b) => {
    let aVal, bVal
    switch (sortBy.value) {
      case 'name':
        aVal = (a.name || '').toLowerCase()
        bVal = (b.name || '').toLowerCase()
        break
      case 'price':
        aVal = parseFloat(a.base_price || 0)
        bVal = parseFloat(b.base_price || 0)
        break
      case 'category':
        aVal = (a.category_name || '').toLowerCase()
        bVal = (b.category_name || '').toLowerCase()
        break
      case 'status':
        aVal = a.status || ''
        bVal = b.status || ''
        break
      case 'created_at':
        aVal = new Date(a.created_at || 0).getTime()
        bVal = new Date(b.created_at || 0).getTime()
        break
      default:
        aVal = (a.name || '').toLowerCase()
        bVal = (b.name || '').toLowerCase()
    }
    if (sortOrder.value === 'asc') {
      return aVal > bVal ? 1 : aVal < bVal ? -1 : 0
    } else {
      return aVal < bVal ? 1 : aVal > bVal ? -1 : 0
    }
  })
  return result
})
const filteredNotAddedProducts = computed(() => {
  const start = (notAddedPage.value - 1) * notAddedPageSize.value
  const end = start + notAddedPageSize.value
  return filteredNotAddedProductsAll.value.slice(start, end)
})
const notAddedTotalPages = computed(() => {
  return Math.ceil(filteredNotAddedProductsAll.value.length / notAddedPageSize.value)
})
const paginatedAddedProducts = computed(() => {
  const start = (addedPage.value - 1) * addedPageSize.value
  const end = start + addedPageSize.value
  return filteredAddedProducts.value.slice(start, end)
})
const addedTotalPages = computed(() => {
  return Math.ceil(filteredAddedProducts.value.length / addedPageSize.value)
})
const loadBranches = async () => {
  try {
    const data = await BranchService.getActiveBranches()
    branches.value = data
  } catch (error) {
    showErrorToast('Unable to load branch list')
  }
}
const loadCategories = async () => {
  try {
    const CategoryService = await import('@/services/CategoryService')
    const data = await CategoryService.default.getAllCategories()
    categories.value = data.data || data
  } catch (error) {
    showErrorToast('Unable to load product categories')
  }
}
const loadProducts = async (page = 1) => {
  loading.value = true
  try {
    let params = { ...filters }
    if (params.category) {
      params.category_id = params.category
      delete params.category
    }
    if (searchQuery.value) {
      params.name = searchQuery.value
    }
    params.page = page
    params.limit = pageSize.value
    delete params.min_price
    delete params.max_price
    let data
    if (selectedBranchId.value) {
      const branchParams = { 
        ...params, 
        include_all: true,
        limit: 10000,  
        page: 1  
      }
      data = await ProductService.getProductsByBranch(selectedBranchId.value, branchParams)
    } else {
      const allParams = {
        ...params,
        limit: 10000,  
        page: 1
      }
      data = await ProductService.getProducts(allParams)
    }
    if (data.data && data.data.products) {
      products.value = data.data.products
      if (data.data.pagination) {
        currentPage.value = data.data.pagination.current_page || page
        totalPages.value = data.data.pagination.total_pages || 1
        totalCount.value = data.data.pagination.total_count || data.data.products.length
      }
    } else if (data.products) {
      products.value = data.products
      if (data.pagination) {
        currentPage.value = data.pagination.current_page || page
        totalPages.value = data.pagination.total_pages || 1
        totalCount.value = data.pagination.total_count || data.products.length
      }
    } else if (Array.isArray(data)) {
      products.value = data
      totalCount.value = data.length
      totalPages.value = Math.ceil(data.length / pageSize.value)
    } else {
      products.value = []
      totalCount.value = 0
      totalPages.value = 1
    }
    const productsByCategory = {}
    products.value.forEach(p => {
      const catId = p.category_id || p.category?.id || 'unknown'
      const catName = p.category_name || p.category?.name || 'Unknown'
      if (!productsByCategory[catId]) {
        productsByCategory[catId] = { name: catName, count: 0, products: [] }
      }
      productsByCategory[catId].count++
      productsByCategory[catId].products.push(p.name)
    })
    await loadStatistics()
    await loadTopProducts()
  } catch (error) {
    showErrorToast('Unable to load product list')
  } finally {
    loading.value = false
  }
}
async function loadStatistics() {
  try {
    const stats = {
      total_products: totalCount.value || products.value.length,
      products_by_category: {},
      products_by_status: {},
      products_by_branch: {}
    }
    products.value.forEach(product => {
      const catName = product.category_name || 'Khác'
      stats.products_by_category[catName] = (stats.products_by_category[catName] || 0) + 1
      const status = product.final_status || product.status || 'unknown'
      stats.products_by_status[status] = (stats.products_by_status[status] || 0) + 1
    })
    statistics.value = stats
  } catch (error) {
    }
}
const loadTopProducts = async () => {
  loadingTopProducts.value = true
  try {
    const filters = {}
    if (selectedBranchId.value) {
      filters.branch_id = selectedBranchId.value
    }
    const dateTo = new Date()
    const dateFrom = new Date()
    dateFrom.setDate(dateFrom.getDate() - 30)
    filters.date_from = dateFrom.toISOString().split('T')[0]
    filters.date_to = dateTo.toISOString().split('T')[0]
    const data = await OrderService.getTopProducts(filters, 5)
    let products = []
    if (Array.isArray(data)) {
      products = data
    } else if (data?.data && Array.isArray(data.data)) {
      products = data.data
    } else if (data?.items && Array.isArray(data.items)) {
      products = data.items
    }
    products.sort((a, b) => (b.total_quantity || 0) - (a.total_quantity || 0))
    topProducts.value = products.map(product => ({
      ...product,
      product_name: product.name || product.product_name || 'N/A',
      name: product.name || product.product_name || 'N/A'
    }))
  } catch (error) {
    topProducts.value = []
  } finally {
    loadingTopProducts.value = false
  }
}
const handleTopProductImageError = (event) => {
  event.target.src = DEFAULT_PRODUCT_IMAGE
}
const onBranchChange = () => {
  selectedProducts.value = []
  selectAll.value = false
  currentPage.value = 1
  notAddedPage.value = 1
  addedPage.value = 1
  loadProducts(1)
}
const selectAllBranches = () => {
  showInfoToast('Tính năng đang phát triển')
}
const onSearchInput = () => {
  if (searchTimeout) {
    clearTimeout(searchTimeout)
  }
  searchTimeout = setTimeout(() => {
    currentPage.value = 1
    loadProducts(1)
  }, 500)
}
const onSearchEnter = () => {
  if (searchTimeout) {
    clearTimeout(searchTimeout)
  }
  currentPage.value = 1
  loadProducts(1)
}
const applyFilters = () => {
  currentPage.value = 1
  loadProducts(1)
}
const clearFilters = () => {
  searchQuery.value = ''
  filters.category = ''
  filters.status = ''
  filters.min_price = ''
  filters.max_price = ''
  sortBy.value = 'name'
  sortOrder.value = 'asc'
  currentPage.value = 1
  notAddedPage.value = 1
  addedPage.value = 1
  loadProducts(1)
}
const refreshData = () => {
  loadProducts(currentPage.value)
}
function openExportModal() {
  exportFilters.branch_id = selectedBranchId.value || ''
  exportFilters.category = filters.category || ''
  exportFilters.status = filters.status || ''
  exportFilters.min_price = filters.min_price || ''
  exportFilters.max_price = filters.max_price || ''
  exportFilters.product_type = 'all'
  showExportModal.value = true
}
async function exportProducts(format = 'csv') {
  isExporting.value = true
  try {
    let params = {}
    if (exportFilters.branch_id) {
      params.branch_id = exportFilters.branch_id
    }
    if (exportFilters.category) {
      params.category_id = exportFilters.category
    }
    if (exportFilters.status) {
      params.status = exportFilters.status
    }
    if (exportFilters.min_price) {
      params.min_price = exportFilters.min_price
    }
    if (exportFilters.max_price) {
      params.max_price = exportFilters.max_price
    }
    let allProducts = []
    let page = 1
    let totalPages = 1
    params.limit = 100
    params.page = page
    let firstData
    if (params.branch_id) {
      if (exportFilters.product_type === 'not-added') {
        firstData = await ProductService.getNotAddedProductsByBranch(params.branch_id, params)
      } else if (exportFilters.product_type === 'added') {
        params.include_all = false
        firstData = await ProductService.getProductsByBranch(params.branch_id, params)
      } else {
        params.include_all = true
        firstData = await ProductService.getProductsByBranch(params.branch_id, params)
      }
    } else {
      firstData = await ProductService.getProducts(params)
    }
    const firstProducts = firstData.data?.products || firstData.products || (Array.isArray(firstData) ? firstData : [])
    let filteredFirstProducts = firstProducts
    if (params.branch_id && exportFilters.product_type === 'added') {
      filteredFirstProducts = firstProducts.filter(p => {
        return p.branch_product_id != null && p.branch_product_id !== undefined
      })
    } else if (params.branch_id && exportFilters.product_type === 'not-added') {
      filteredFirstProducts = firstProducts.filter(p => {
        return !p.branch_product_id || p.final_status === 'not_added'
      })
    }
    if (filteredFirstProducts.length > 0) {
      allProducts = allProducts.concat(filteredFirstProducts)
      totalPages = firstData.data?.metadata?.lastPage || firstData.metadata?.lastPage || 1
      if (totalPages > 1) {
        const remainingPages = []
        for (let p = 2; p <= totalPages; p++) {
          const pageParams = { ...params, page: p }
          if (params.branch_id) {
            if (exportFilters.product_type === 'not-added') {
              remainingPages.push(ProductService.getNotAddedProductsByBranch(params.branch_id, pageParams))
            } else if (exportFilters.product_type === 'added') {
              pageParams.include_all = false
              remainingPages.push(ProductService.getProductsByBranch(params.branch_id, pageParams))
            } else {
              pageParams.include_all = true
              remainingPages.push(ProductService.getProductsByBranch(params.branch_id, pageParams))
            }
          } else {
            remainingPages.push(ProductService.getProducts(pageParams))
          }
        }
        const remainingChunks = await Promise.all(remainingPages)
        remainingChunks.forEach(chunk => {
          const products = chunk.data?.products || chunk.products || (Array.isArray(chunk) ? chunk : [])
          if (exportFilters.product_type === 'added' && params.branch_id) {
            const addedProducts = products.filter(p => {
              return p.branch_product_id != null && p.branch_product_id !== undefined
            })
            if (addedProducts.length > 0) {
              allProducts = allProducts.concat(addedProducts)
            }
          } else if (exportFilters.product_type === 'not-added' && params.branch_id) {
            const notAddedProducts = products.filter(p => {
              return !p.branch_product_id || p.final_status === 'not_added'
            })
            if (notAddedProducts.length > 0) {
              allProducts = allProducts.concat(notAddedProducts)
            }
          } else {
            if (products.length > 0) {
              allProducts = allProducts.concat(products)
            }
          }
        })
      }
    }
    if (params.branch_id && exportFilters.product_type === 'all') {
      const notAddedParams = { ...params }
      delete notAddedParams.include_all
      let notAddedPage = 1
      let notAddedTotalPages = 1
      let notAddedFirstData = await ProductService.getNotAddedProductsByBranch(params.branch_id, { ...notAddedParams, page: notAddedPage, limit: 100 })
      const notAddedFirstProducts = notAddedFirstData.data?.products || notAddedFirstData.products || (Array.isArray(notAddedFirstData) ? notAddedFirstData : [])
      if (notAddedFirstProducts.length > 0) {
        notAddedFirstProducts.forEach(product => {
          if (!allProducts.find(p => p.id === product.id)) {
            allProducts.push(product)
          }
        })
        notAddedTotalPages = notAddedFirstData.data?.metadata?.lastPage || notAddedFirstData.metadata?.lastPage || 1
        if (notAddedTotalPages > 1) {
          const notAddedRemainingPages = []
          for (let p = 2; p <= notAddedTotalPages; p++) {
            notAddedRemainingPages.push(ProductService.getNotAddedProductsByBranch(params.branch_id, { ...notAddedParams, page: p, limit: 100 }))
          }
          const notAddedChunks = await Promise.all(notAddedRemainingPages)
          notAddedChunks.forEach(chunk => {
            const products = chunk.data?.products || chunk.products || (Array.isArray(chunk) ? chunk : [])
            products.forEach(product => {
              if (!allProducts.find(p => p.id === product.id)) {
                allProducts.push(product)
              }
            })
          })
        }
      }
    }
    if (allProducts.length === 0) {
      showErrorToast('No products match the selected filters')
      return
    }
    if (format === 'excel' || format === 'csv') {
      exportToCSV(allProducts)
    }
    showExportModal.value = false
  } catch (error) {
    showErrorToast('Unable to export product list: ' + (error.message || 'Unknown error'))
  } finally {
    isExporting.value = false
  }
}
function exportToCSV(products) {
  const headers = [
    'ID', 'Product Name', 'Category', 'Original Price', 'Branch Price', 
    'Status', 'Branch', 'Description', 'Image', 'Created Date'
  ]
  const rows = products.map(product => {
    let status = 'N/A'
    if (product.final_status) {
      status = getStatusText(product.final_status)
    } else if (product.status) {
      status = getStatusText(product.status)
    } else if (product.branch_product_id) {
      status = 'Available'
    } else {
      status = 'Not Added'
    }
    let branchName = 'All'
    if (exportFilters.branch_id) {
      const branch = branches.value.find(b => b.id == exportFilters.branch_id)
      branchName = branch?.name || 'N/A'
    }
    return [
      product.id,
      product.name || 'N/A',
      product.category_name || 'N/A',
      product.base_price || 0,
      product.branch_price || product.base_price || 0,
      status,
      branchName,
      product.description || '',
      product.image || '',
      product.created_at ? new Date(product.created_at).toLocaleString('vi-VN') : ''
    ]
  })
  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
  ].join('\n')
  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  link.setAttribute('href', url)
  link.setAttribute('download', `danh_sach_san_pham_${new Date().toISOString().split('T')[0]}.csv`)
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  showSuccessToast('File exported successfully!')
}
async function quickUpdateStatus(product, newStatus) {
  try {
    if (selectedBranchId.value) {
      await ProductService.updateBranchProduct(product.branch_product_id, {
        status: newStatus
      })
    } else {
      await ProductService.updateProduct(product.id, {
        status: newStatus
      })
    }
    showSuccessToast(`Status updated to "${getStatusText(newStatus)}"`)
    await loadProducts(currentPage.value)
  } catch (error) {
    showErrorToast(error.message || 'Unable to update status')
  }
}
const addProductToBranch = async (product) => {
  if (!selectedBranchId.value) {
    showErrorToast('Please select a branch before adding products')
    return
  }
  try {
    const branchProductData = {
      price: product.base_price
    }
    await ProductService.addProductToBranch(selectedBranchId.value, product.id, branchProductData)
    const message = `Added "${product.name}" to branch`
    showSuccessToast(message)
    await loadProducts()
  } catch (error) {
    showErrorToast(error.message)
  }
}
const editBranchProduct = (product) => {
  editingProduct.value = product
  showEditModal.value = true
}
const openDeleteBranchProductModal = (product) => {
  productToDelete.value = product
  showDeleteBranchProductModal.value = true
}
const confirmDeleteBranchProduct = async () => {
  if (!productToDelete.value) return
  deleteLoading.value = true
  try {
    await ProductService.removeProductFromBranch(selectedBranchId.value, productToDelete.value.id)
    showSuccessToast(`Removed "${productToDelete.value.name}" from branch`)
    showDeleteBranchProductModal.value = false
    productToDelete.value = null
    await new Promise(resolve => setTimeout(resolve, 500))
    await loadProducts()
  } catch (error) {
    showErrorToast(error.message)
  } finally {
    deleteLoading.value = false
  }
}
const updateBranchPrice = async (product) => {
  try {
    const updateData = {
      price: product.branch_price
    }
    await ProductService.updateBranchProduct(product.branch_product_id, updateData)
    showSuccessToast(`Updated price for "${product.name}"`)
  } catch (error) {
    showErrorToast(error.message)
    loadProducts()
  }
}
const toggleSelectAll = () => {
  const allFilteredIds = filteredProducts.value.map(p => p.id)
  const allSelected = allFilteredIds.length > 0 && allFilteredIds.every(id => selectedProducts.value.includes(id))
  if (allSelected) {
    selectedProducts.value = selectedProducts.value.filter(id => !allFilteredIds.includes(id))
  } else {
    allFilteredIds.forEach(id => {
      if (!selectedProducts.value.includes(id)) {
        selectedProducts.value.push(id)
      }
    })
  }
}
const toggleSelectAllNotAdded = () => {
  const notAddedIds = filteredNotAddedProductsAll.value.map(p => p.id)
  const allSelected = notAddedIds.every(id => selectedProducts.value.includes(id))
  if (allSelected) {
    selectedProducts.value = selectedProducts.value.filter(id => !notAddedIds.includes(id))
  } else {
    notAddedIds.forEach(id => {
      if (!selectedProducts.value.includes(id)) {
        selectedProducts.value.push(id)
      }
    })
  }
}
const toggleSelectAllAdded = () => {
  const addedIds = filteredAddedProducts.value.map(p => p.id)
  const allSelected = addedIds.every(id => selectedProducts.value.includes(id))
  if (allSelected) {
    selectedProducts.value = selectedProducts.value.filter(id => !addedIds.includes(id))
  } else {
    addedIds.forEach(id => {
      if (!selectedProducts.value.includes(id)) {
        selectedProducts.value.push(id)
      }
    })
  }
}
const onProductSelect = (productId, isSelected) => {
  if (isSelected) {
    if (!selectedProducts.value.includes(productId)) {
      selectedProducts.value.push(productId)
    }
  } else {
    const index = selectedProducts.value.indexOf(productId)
    if (index > -1) {
      selectedProducts.value.splice(index, 1)
    }
  }
}
const bulkAddToBranch = async () => {
  if (!selectedBranchId.value) {
    showErrorToast('Please select a branch')
    return
  }
  try {
    const promises = selectedProducts.value.map(productId => {
      const product = products.value.find(p => p.id === productId)
      return ProductService.addProductToBranch(selectedBranchId.value, productId, {
        price: product.base_price,
        is_available: 1,
        status: 'available'
      })
    })
    await Promise.all(promises)
    showSuccessToast(`Added ${selectedProducts.value.length} product(s) to branch`)
    selectedProducts.value = []
    selectAll.value = false
    loadProducts()
  } catch (error) {
    showErrorToast(error.message)
  }
}
const bulkUpdateStatus = () => {
  showInfoToast('Tính năng đang phát triển')
}
const bulkRemoveFromBranch = async () => {
  if (!confirm(`Are you sure you want to remove ${selectedProducts.value.length} product(s) from branch?`)) return
  try {
    const promises = selectedProducts.value.map(productId => {
      return ProductService.removeProductFromBranch(selectedBranchId.value, productId)
    })
    await Promise.all(promises)
    showSuccessToast(`Removed ${selectedProducts.value.length} product(s) from branch`)
    selectedProducts.value = []
    selectAll.value = false
    loadProducts()
  } catch (error) {
    showErrorToast(error.message)
  }
}
const onProductAdded = () => {
  showAddProductModal.value = false
  loadProducts()
}
const onProductUpdated = () => {
  showEditModal.value = false
  loadProducts()
}
const onProductEdited = () => {
  showEditProductModal.value = false
  loadProducts()
}
const editProduct = async (product) => {
  editingProductForEdit.value = product
  showEditProductModal.value = true
  try {
    const res = await ProductService.getProduct(product.id)
    const full = res && res.data
      ? (res.data.product ? { ...res.data.product, options: res.data.options || [] } : res.data)
      : product
    editingProductForEdit.value = full
  } catch (e) {
  }
}
const openDeleteProductModal = (product) => {
  productToDelete.value = product
  showDeleteProductModal.value = true
}
const confirmDeleteProduct = async () => {
  if (!productToDelete.value) return
  deleteLoading.value = true
  try {
    await ProductService.deleteProduct(productToDelete.value.id)
    showSuccessToast(`Deleted product "${productToDelete.value.name}"`)
    showDeleteProductModal.value = false
    productToDelete.value = null
    loadProducts()
  } catch (error) {
    showErrorToast(error.message)
  } finally {
    deleteLoading.value = false
  }
}
const formatPrice = (price) => {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(price)
}
const formatLikes = (likes) => {
  if (likes >= 1000) {
    return (likes / 1000).toFixed(1) + 'K'
  }
  return likes.toString()
}
const getStatusBadgeClass = (status) => {
  const classes = {
    'available': 'status-available',
    'out_of_stock': 'status-out-of-stock',
    'temporarily_unavailable': 'status-temporarily-unavailable',
    'not_added': 'status-not-added'
  }
  return classes[status] || ''
}
const getStatusText = (status) => {
  const texts = {
    'available': 'Available',
    'out_of_stock': 'Out of Stock',
    'temporarily_unavailable': 'Temporarily Unavailable',
    'not_added': 'Not Added'
  }
  return texts[status] || status
}
const handleImageError = (event) => {
  event.target.src = DEFAULT_PRODUCT_IMAGE
}
const showSuccessToast = (message) => {
  toast.success(message)
}
const showErrorToast = (message) => {
  toast.error(message)
}
const showInfoToast = (message) => {
  toast.info(message)
}
watch(selectedProducts, (newVal) => {
  selectAll.value = newVal.length === products.value.length && products.value.length > 0
})
watch([filters, sortBy, sortOrder], () => {
  currentPage.value = 1
  notAddedPage.value = 1
  addedPage.value = 1
  loadProducts(1)
}, { deep: true })
watch(searchQuery, () => {
  currentPage.value = 1
  notAddedPage.value = 1
  addedPage.value = 1
  loadProducts(1)
})
onMounted(() => {
  loadBranches()
  loadCategories()
  loadProducts(1)
  loadTopProducts()
})
watch(selectedBranchId, () => {
  loadTopProducts()
})
</script>
<style scoped>
.branch-menu-management {
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
  background: #FF8C42;
  color: white;
}
.btn-add:hover:not(:disabled) {
  background: #E67E22;
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
.btn-add:disabled, .btn-refresh:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-export {
  padding: 10px 18px;
  border: 2px solid #10B981;
  background: white;
  color: #10B981;
  cursor: pointer;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-export:hover:not(:disabled) {
  border-color: #059669;
  background: #ECFDF5;
  color: #059669;
}
.btn-export:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.filters-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 24px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
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
.filters-header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}
.btn-toggle-filters {
  padding: 8px 16px;
  border: 1px solid #E5E5E5;
  background: white;
  color: #6B7280;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-toggle-filters:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
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
.sort-controls {
  display: flex;
  gap: 8px;
  align-items: center;
}
.filter-select {
  flex: 1;
}
.btn-sort-toggle {
  width: 40px;
  height: 40px;
  border: 1px solid #E5E5E5;
  background: white;
  border-radius: 10px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  transition: all 0.2s ease;
}
.btn-sort-toggle:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
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
  background: white;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
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
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
  margin-bottom: 20px;
}
.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #FF8C42;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
.loading i,
.error i,
.empty-state i {
  font-size: 3rem;
  margin-bottom: 16px;
  color: #9ca3af;
}
.error i {
  color: #dc3545;
}
.empty-state i {
  color: #6c757d;
}
.loading p,
.error p,
.empty-state p {
  margin: 8px 0;
  color: #6c757d;
}
.empty-state h3 {
  margin: 0 0 8px 0;
  color: #495057;
}
.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}
.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}
.btn-primary {
  background: #FF8C42;
  color: white;
  border: 1px solid #FF8C42;
}
.btn-primary:hover:not(:disabled) {
  background: #FF7700;
  border-color: #FF7700;
}
.btn-secondary {
  background: #6b7280;
  color: white;
  border: 1px solid #6b7280;
}
.btn-secondary:hover:not(:disabled) {
  background: #4b5563;
  border-color: #4b5563;
}
.btn-success {
  background: #10b981;
  color: white;
  border: 1px solid #10b981;
}
.btn-success:hover:not(:disabled) {
  background: #059669;
  border-color: #059669;
}
.btn-warning {
  background: #f59e0b;
  color: white;
  border: 1px solid #f59e0b;
}
.btn-warning:hover:not(:disabled) {
  background: #d97706;
  border-color: #d97706;
}
.btn-danger {
  background: #ef4444;
  color: white;
  border: 1px solid #ef4444;
}
.btn-danger:hover:not(:disabled) {
  background: #dc2626;
  border-color: #dc2626;
}
.btn-sm {
  padding: 6px 12px;
  font-size: 12px;
}
.top-products-section {
  margin-bottom: 24px;
  overflow-x: auto;
  max-width: 100%;
  -webkit-overflow-scrolling: touch;
  scrollbar-width: none; 
  -ms-overflow-style: none; 
}
.top-products-section::-webkit-scrollbar {
  display: none; 
}
.top-products-grid {
  display: flex;
  flex-direction: row;
  gap: 20px;
  min-width: max-content;
}
.top-product-card {
  background: white;
  border-radius: 20px;
  padding: 20px;
  display: flex;
  align-items: flex-start;
  gap: 16px;
  flex-shrink: 0;
  min-width: 280px;
  max-width: 280px;
}
.top-products-loading,
.top-products-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 40px;
  color: #6B7280;
  font-size: 14px;
}
.top-products-loading i {
  color: #FF8C42;
}
.top-products-empty i {
  font-size: 24px;
  color: #D1D5DB;
}
.product-image-wrapper {
  width: 72px;
  height: 72px;
  border-radius: 16px;
  overflow: hidden;
  flex-shrink: 0;
  background: linear-gradient(135deg, #FFF9F5 0%, #FFE5D4 100%);
  border: 2px solid #FFF3E8;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}
.product-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center;
}
.product-info {
  flex: 1;
  min-width: 0;
}
.product-name {
  margin: 0 0 12px 0;
  font-size: 15px;
  font-weight: 600;
  color: #1F2937;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.product-stats {
  margin-bottom: 12px;
}
.product-stat-item {
  display: flex;
  align-items: baseline;
  gap: 8px;
}
.stat-label-text {
  font-size: 11px;
  color: #9CA3AF;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.stat-value-text {
  font-size: 20px;
  font-weight: 700;
  color: #1F2937;
  background: linear-gradient(135deg, #FF8C42 0%, #FFB800 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
.product-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 12px;
  border-top: 1px dashed #E5E7EB;
}
.product-rating {
  display: flex;
  gap: 2px;
}
.product-rating .fa-star {
  font-size: 12px;
  transition: transform 0.2s ease;
}
.product-rating .star-filled {
  color: #FBBF24;
}
.product-rating .star-empty {
  color: #E5E7EB;
}
.product-likes {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: #6B7280;
  font-weight: 500;
  background: #FFF9F5;
  padding: 4px 10px;
  border-radius: 20px;
  border: 1px solid #FFE5D4;
}
.product-likes i {
  color: #EF4444;
  font-size: 11px;
  animation: heartbeat 1.5s ease-in-out infinite;
}
@keyframes heartbeat {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}
.products-card {
  background: #FAFBFC;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #E2E8F0;
  margin-bottom: 20px;
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
.header-actions-wrapper {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}
.table-title {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
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
.product-stats {
  display: flex;
  gap: 8px;
  margin-left: 12px;
}
.stat-item {
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
}
.stat-item.added {
  background: #D1FAE5;
  color: #065F46;
  border: 1px solid #A7F3D0;
}
.stat-item.not-added {
  background: #FEE2E2;
  color: #991B1B;
  border: 1px solid #FECACA;
}
.select-all-controls {
  display: flex;
  align-items: center;
}
.select-all-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #6B7280;
  font-weight: 600;
  cursor: pointer;
}
.checkbox-input {
  width: 18px;
  height: 18px;
  cursor: pointer;
}
.bulk-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}
.selected-count {
  font-size: 13px;
  color: #6B7280;
  font-weight: 600;
  margin-right: 8px;
}
.bulk-btn {
  width: 36px;
  height: 36px;
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
.bulk-btn:hover:not(:disabled) {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.bulk-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
  backdrop-filter: blur(4px);
}
.modal-content {
  background: white;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15);
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.add-product-modal,
.edit-product-modal {
  background: white;
  border-radius: 14px;
  max-width: 700px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid #E2E8F0;
}
.add-product-modal .modal-header,
.edit-product-modal .modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
  flex-shrink: 0;
}
.add-product-modal .modal-header h3,
.edit-product-modal .modal-header h3 {
  font-size: 15px;
  font-weight: 600;
  color: #1E293B;
  letter-spacing: -0.2px;
  margin: 0;
}
.modal-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
  flex-wrap: wrap;
}
.product-header-badge {
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
.product-header-badge i {
  color: #F59E0B;
  font-size: 14px;
}
.product-name-badge {
  padding: 6px 14px;
  background: white;
  border: 1px solid #FED7AA;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #475569;
}
.edit-product-modal .modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.modal-icon-wrapper {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  flex-shrink: 0;
}
.modal-icon-wrapper.icon-add {
  background: white;
  border: 2px solid #10B981;
  color: #10B981;
}
.modal-icon-wrapper.icon-edit {
  background: white;
  border: 2px solid #F59E0B;
  color: #F59E0B;
}
.modal-icon-wrapper.icon-export {
  background: white;
  border: 2px solid #10B981;
  color: #10B981;
}
.modal-icon-wrapper.icon-view {
  background: white;
  border: 2px solid #3B82F6;
  color: #3B82F6;
}
.modal-title-section {
  flex: 1;
}
.modal-title-section h3 {
  margin: 0 0 4px 0;
  font-size: 20px;
  font-weight: 700;
  color: #1a1a1a;
  letter-spacing: -0.3px;
}
.modal-subtitle {
  margin: 0;
  font-size: 13px;
  color: #6B7280;
  font-weight: 500;
}
.modal-title {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: #1a1a1a;
  display: flex;
  align-items: center;
  gap: 10px;
}
.modal-title i {
  color: #FF8C42;
}
.modal-title {
  margin: 0;
  font-size: 18px;
  color: #333;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #666;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.btn-close:hover {
  color: #333;
}
.modal-body {
  padding: 24px;
  overflow-y: auto;
  flex: 1;
  background: white;
}
.product-stats {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}
.stat-item {
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
}
.stat-item.added {
  background: #d1fae5;
  color: #065f46;
  border: 1px solid #a7f3d0;
}
.stat-item.not-added {
  background: #fee2e2;
  color: #991b1b;
  border: 1px solid #fecaca;
}
.stat-item.total {
  background: #dbeafe;
  color: #1e40af;
  border: 1px solid #bfdbfe;
}
.products-layout {
  display: flex;
  margin-top: 20px;
  margin-left: 0;
  margin-right: 0;
  width: 100%;
  gap: 16px;
}
.products-column {
  flex: 1;
  background: white;
  border-radius: 12px;
  border: 1px solid #F0E6D9;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  max-width: 100%;
}
.not-added-column {
  flex: 0 0 45%;
}
.added-column {
  flex: 0 0 55%;
}
.column-header {
  background: #FFF9F5;
  padding: 16px 20px;
  border-bottom: 2px solid #F0E6D9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.column-header h4 {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: #1a1a1a;
  display: flex;
  align-items: center;
  gap: 8px;
  letter-spacing: -0.2px;
}
.column-header h4 i {
  color: #FF8C42;
  font-size: 16px;
}
.column-header .count {
  background: #FFF9F5;
  border: 1px solid #F0E6D9;
  color: #6B7280;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
}
.not-added-column .column-header {
  background: #FEF2F2;
  border-bottom-color: #FECACA;
}
.not-added-column .column-header h4 {
  color: #991B1B;
}
.not-added-column .column-header h4 i {
  color: #EF4444;
}
.not-added-column .column-header .count {
  background: #FEE2E2;
  border-color: #FECACA;
  color: #991B1B;
}
.added-column .column-header {
  background: #ECFDF5;
  border-bottom-color: #A7F3D0;
}
.added-column .column-header h4 {
  color: #065F46;
}
.added-column .column-header h4 i {
  color: #10B981;
}
.added-column .column-header .count {
  background: #D1FAE5;
  border-color: #A7F3D0;
  color: #065F46;
}
.products-column .table-wrapper {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  max-height: calc(100vh - 450px);
}
.column-pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 16px;
  background: #FAFAFA;
  border-top: 2px solid #F0E6D9;
}
.pagination-btn-small {
  width: 32px;
  height: 32px;
  border: 1px solid #E5E5E5;
  background: white;
  cursor: pointer;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  color: #666;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}
.pagination-btn-small:hover:not(:disabled) {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFF9F5;
}
.pagination-btn-small:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  background: #F8F8F8;
}
.pagination-info-small {
  font-size: 13px;
  font-weight: 600;
  color: #1a1a1a;
  min-width: 60px;
  text-align: center;
}
.products-column .modern-table {
  margin: 0;
  table-layout: fixed;
  width: 100%;
}
.empty-table-cell {
  padding: 40px 20px !important;
  text-align: center;
}
.empty-state-inline {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  color: #9CA3AF;
}
.empty-state-inline i {
  font-size: 48px;
  color: #D1D5DB;
}
.empty-state-inline p {
  margin: 0;
  font-size: 14px;
  font-weight: 500;
  color: #6B7280;
}
.branch-price-col {
  width: 110px;
  max-width: 110px;
}
.branch-price-value {
  font-weight: 700;
  color: #FF8C42;
  font-size: 14px;
}
.btn-add-product {
  color: #10B981;
  border-color: #A7F3D0;
  background: #ECFDF5;
}
.btn-add-product:hover:not(:disabled) {
  background: #D1FAE5;
  border-color: #10B981;
  color: #059669;
}
.table-wrapper {
  overflow-x: auto;
}
.modern-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  background: white;
  border-radius: 10px;
  overflow: hidden;
  border: 1px solid #E2E8F0;
  table-layout: fixed;
}
.modern-table thead {
  background: #F8F9FA;
}
.modern-table th {
  padding: 12px 14px;
  text-align: left;
  font-size: 11px;
  font-weight: 700;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 2px solid #E2E8F0;
  white-space: nowrap;
  vertical-align: middle;
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
  padding: 12px 14px;
  font-size: 12px;
  color: #1E293B;
  vertical-align: middle;
}
.checkbox-col {
  width: 40px;
  padding: 16px !important;
  text-align: center;
  vertical-align: middle;
  overflow: visible !important;
  text-overflow: clip !important;
  white-space: normal !important;
}
.checkbox-col input[type="checkbox"] {
  display: block;
  margin: 0 auto;
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
.image-col {
  width: 60px;
  max-width: 60px;
}
.product-image-cell {
  width: 45px;
  height: 45px;
  border-radius: 8px;
  overflow: hidden;
  border: 2px solid #F3F4F6;
  background: #FAFAFA;
}
.product-image-cell img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.2s ease;
}
.modern-table tbody tr:hover .product-image-cell img {
  transform: scale(1.05);
}
.name-col {
  max-width: 120px;
  width: 120px;
}
.product-name-cell {
  font-weight: 600;
  color: #1a1a1a;
  font-size: 13px;
  line-height: 1.4;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  cursor: help;
}
.category-col {
  width: 90px;
  max-width: 90px;
}
.category-badge {
  padding: 4px 8px;
  background: #F3F4F6;
  color: #6B7280;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 500;
  display: inline-block;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.price-col {
  width: 100px;
  max-width: 100px;
}
.price-value {
  font-weight: 700;
  color: #FF8C42;
  font-size: 13px;
  letter-spacing: -0.2px;
}
.status-col {
  width: 110px;
  max-width: 110px;
}
.status-badge {
  padding: 4px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  display: inline-block;
  letter-spacing: 0.2px;
}
.actions-col {
  width: 90px;
  max-width: 90px;
}
.action-buttons {
  display: flex;
  gap: 6px;
  align-items: center;
}
.btn-action {
  width: 32px;
  height: 32px;
  border: 1px solid #E5E5E5;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  transition: all 0.2s ease;
  font-size: 12px;
}
.btn-action:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}
.btn-action:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.btn-edit {
  color: #F59E0B;
  border-color: #FEF3C7;
  background: #FFFBEB;
}
.btn-edit:hover:not(:disabled) {
  background: #FEF3C7;
  border-color: #F59E0B;
  color: #D97706;
}
.btn-delete {
  color: #EF4444;
  border-color: #FEE2E2;
  background: #FEF2F2;
}
.btn-delete:hover:not(:disabled) {
  background: #FEE2E2;
  border-color: #EF4444;
  color: #DC2626;
}
.btn-view {
  color: #3B82F6;
  border-color: #DBEAFE;
  background: #EFF6FF;
}
.btn-view:hover:not(:disabled) {
  background: #DBEAFE;
  border-color: #3B82F6;
  color: #2563EB;
}
.btn-duplicate {
  color: #9333EA;
  border-color: #F3E8FF;
  background: #FAF5FF;
}
.btn-duplicate:hover:not(:disabled) {
  background: #F3E8FF;
  border-color: #9333EA;
  color: #7C3AED;
}
.status-select {
  padding: 4px 8px;
  border: 1px solid #E5E5E5;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 500;
  cursor: pointer;
  background: white;
  transition: all 0.2s ease;
  width: 100%;
  max-width: 100%;
}
.status-select.status-available {
  background: #D1FAE5;
  border-color: #A7F3D0;
  color: #065F46;
}
.status-select.status-out-of-stock {
  background: #FEE2E2;
  border-color: #FECACA;
  color: #991B1B;
}
.status-select.status-temporarily-unavailable {
  background: #FEF3C7;
  border-color: #FDE68A;
  color: #92400E;
}
.status-select:hover {
  opacity: 0.9;
}
.status-available {
  background: #D1FAE5;
  color: #065F46;
  border: 1px solid #A7F3D0;
}
.status-out-of-stock {
  background: #FEE2E2;
  color: #991B1B;
  border: 1px solid #FECACA;
}
.status-temporarily-unavailable {
  background: #FEF3C7;
  color: #92400E;
  border: 1px solid #FDE68A;
}
.status-not-added {
  background: #F3F4F6;
  color: #6B7280;
  border: 1px solid #E5E7EB;
}
.header-checkbox {
  flex: 0 0 20px;
}
.header-image {
  flex: 0 0 60px;
}
.header-name {
  flex: 0 0 120px;
}
.header-category {
  flex: 0 0 80px;
}
.header-price {
  flex: 0 0 80px;
}
.header-branch-price {
  flex: 0 0 150px;
}
.header-actions {
  display: flex;
  flex-direction: row;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
  flex: 0 0 auto;
  min-width: 100px;
}
.product-item {
  display: flex;
  align-items: center;
  background: white;
  padding: 12px 8px;
  border-bottom: 1px solid #eee;
  transition: all 0.2s ease;
  gap: 4px;
}
.product-item:last-child {
  border-bottom: none;
}
.product-item:hover {
  background: #f8f9fa;
}
.product-item.added {
  border-left: 4px solid #28a745;
}
.product-item.not-added {
  border-left: 4px solid #dc3545;
}
.product-item.all-products {
  border-left: 4px solid #007bff;
}
.all-products-layout {
  margin-top: 20px;
}
.header-status {
  flex: 0 0 100px;
}
.product-checkbox {
  flex: 0 0 20px;
}
.product-checkbox input[type="checkbox"] {
  margin: 0;
}
.product-image {
  flex: 0 0 auto;
  width: 60px;
  height: 60px;
  border-radius: 6px;
  overflow: hidden;
}
.product-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.product-name {
  flex: 0 0 120px;
  font-weight: 600;
  font-size: 14px;
  color: #333;
}
.product-category {
  flex: 0 0 80px;
  font-size: 12px;
  color: #666;
}
.product-price {
  flex: 0 0 80px;
  font-size: 13px;
  color: #007bff;
  font-weight: 500;
}
.branch-price {
  flex: 0 0 150px;
  font-size: 12px;
  color: #28a745;
  font-weight: 500;
}
.product-status {
  flex: 0 0 auto;
  min-width: 100px;
}
.status-added {
  background: #d4edda;
  color: #155724;
  padding: 6px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  border: 1px solid #c3e6cb;
}
.status-not-added {
  background: #f8d7da;
  color: #721c24;
  padding: 6px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  border: 1px solid #f5c6cb;
}
.product-actions {
  flex: 0 0 auto;
  min-width: 100px;
  display: flex;
  gap: 8px;
}
.product-actions button {
  padding: 6px 12px;
  border: 1px solid #ddd;
  background: white;
  color: #333;
  border-radius: 6px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 500;
  transition: all 0.2s ease;
  white-space: nowrap;
}
.product-actions button:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
.product-actions button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}
.product-actions .btn-success {
  background: #28a745 !important;
  color: white !important;
  border-color: #28a745 !important;
}
.product-actions .btn-success:hover:not(:disabled) {
  background: #218838 !important;
  border-color: #218838 !important;
}
.product-actions .btn-warning {
  background: #ffc107 !important;
  color: #212529 !important;
  border-color: #ffc107 !important;
}
.product-actions .btn-warning:hover:not(:disabled) {
  background: #e0a800 !important;
  border-color: #e0a800 !important;
}
.product-actions .btn-danger {
  background: #dc3545 !important;
  color: white !important;
  border-color: #dc3545 !important;
}
.product-actions .btn-danger:hover:not(:disabled) {
  background: #c82333 !important;
  border-color: #c82333 !important;
}
.product-actions .btn-info {
  background: #17a2b8 !important;
  color: white !important;
  border-color: #17a2b8 !important;
}
.product-actions .btn-info:hover:not(:disabled) {
  background: #138496 !important;
  border-color: #138496 !important;
}
@media (max-width: 768px) {
  .header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }
  .search-row {
    flex-direction: column;
    gap: 12px;
  }
  .search-input,
  .filter-select {
    width: 100%;
    min-width: auto;
  }
  .section-header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }
  .product-controls {
    justify-content: space-between;
  }
  .products-layout {
    flex-direction: column;
    gap: 20px;
  }
  .not-added-column,
  .added-column {
    flex: 1;
    min-width: auto;
  }
  .product-item {
    flex-direction: column;
    align-items: flex-start;
    padding: 16px;
    gap: 12px;
  }
  .product-checkbox {
    flex: none;
    margin-bottom: 8px;
  }
  .product-image {
    flex: none;
    width: 60px;
    height: 60px;
    margin-bottom: 8px;
  }
  .product-name,
  .product-category,
  .product-price,
  .branch-price {
    flex: none;
    width: 100%;
    margin-bottom: 4px;
  }
  .product-actions {
    flex: none;
    width: 100%;
    justify-content: flex-end;
  }
  .product-actions button {
    padding: 8px 12px;
    font-size: 13px;
  }
  .bulk-actions-content {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }
  .bulk-buttons {
    justify-content: center;
    flex-wrap: wrap;
  }
  .modal-overlay {
    padding: 10px;
  }
  .modal-content {
    max-width: none;
  }
  .quick-view-content {
    grid-template-columns: 1fr;
  }
  .export-modal, .quick-view-modal {
    max-width: 95%;
    max-height: 90vh;
  }
  .section-title {
    font-size: 14px;
  }
}
.pagination-section {
  display: flex;
  justify-content: center;
  margin-top: 24px;
  margin-bottom: 24px;
  padding: 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}
.pagination-nav {
  display: flex;
  align-items: center;
  gap: 16px;
}
.pagination-btn {
  width: 40px;
  height: 40px;
  border: 1px solid #E5E5E5;
  background: white;
  cursor: pointer;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
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
  opacity: 0.4;
  cursor: not-allowed;
  background: #F8F8F8;
}
.pagination-info {
  font-size: 14px;
  font-weight: 600;
  color: #1a1a1a;
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
  display: flex;
  align-items: center;
  gap: 8px;
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
  justify-content: center;
  gap: 8px;
  min-width: 120px;
  height: 44px;
  box-sizing: border-box;
  white-space: nowrap;
  line-height: 1;
}
.export-modal .modal-actions .btn-close {
  background: white;
  color: #6B7280;
  border-color: #E5E7EB;
}
.export-modal .modal-actions .btn-close:hover {
  background: #F9FAFB;
  border-color: #D1D5DB;
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
  padding: 16px;
  margin-bottom: 16px;
  border: 1px solid #E2E8F0;
}
.export-section-header {
  margin-bottom: 16px;
}
.export-section-header .section-title {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
  letter-spacing: -0.1px;
  padding-bottom: 12px;
  border-bottom: 1px solid #E2E8F0;
}
.export-section-body {
  padding-top: 4px;
}
.quick-view-modal {
  max-width: 700px;
}
.btn-close-modal {
  width: 40px;
  height: 40px;
  border: none;
  background: transparent;
  cursor: pointer;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  transition: all 0.2s ease;
  font-size: 18px;
  flex-shrink: 0;
}
.btn-close-modal:hover {
  background: #FFF9F5;
  color: #FF8C42;
  transform: rotate(90deg);
}
.export-note {
  margin-top: 16px;
  padding: 12px 16px;
  background: #FFF7ED;
  border-radius: 8px;
  display: flex;
  align-items: flex-start;
  gap: 10px;
  font-size: 12px;
  color: #92400E;
  line-height: 1.5;
  border: 1px solid #FED7AA;
}
.export-note .note-icon {
  color: #F59E0B;
  font-size: 14px;
  margin-top: 2px;
  flex-shrink: 0;
}
.filter-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
.filter-row {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
.form-group {
  display: flex;
  flex-direction: column;
}
.form-group label {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #374151;
}
.form-group label .label-icon {
  color: #9CA3AF;
  font-size: 12px;
}
.form-select, .form-input {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #E5E5E5;
  border-radius: 10px;
  font-size: 14px;
  background: white;
  color: #1a1a1a;
  font-weight: 500;
  transition: all 0.2s ease;
}
.form-select:focus, .form-input:focus {
  outline: none;
  border-color: #FF8C42;
  box-shadow: 0 0 0 3px rgba(255, 140, 66, 0.1);
}
.quick-view-content {
  display: grid;
  grid-template-columns: 300px 1fr;
  gap: 24px;
}
.product-image-large {
  width: 100%;
  height: 320px;
  border-radius: 12px;
  overflow: hidden;
  background: #F5F5F5;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #F0F0F0;
}
.product-image-large img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.product-details {
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.product-name-large {
  margin: 0 0 8px 0;
  font-size: 26px;
  font-weight: 700;
  color: #1a1a1a;
  letter-spacing: -0.4px;
  line-height: 1.3;
}
.detail-section {
  background: #FFF9F5;
  border-radius: 12px;
  padding: 20px;
  border: 2px solid #F0E6D9;
}
.detail-row {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 16px 0;
  border-bottom: 1px solid #F5F5F5;
}
.detail-row:last-child {
  border-bottom: none;
}
.detail-row.description-row {
  align-items: flex-start;
}
.detail-label {
  font-size: 14px;
  font-weight: 600;
  color: #6B7280;
  min-width: 140px;
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}
.detail-label i {
  color: #FF8C42;
  font-size: 14px;
  width: 16px;
}
.detail-value {
  font-size: 15px;
  color: #1a1a1a;
  font-weight: 500;
  flex: 1;
}
.detail-value.price {
  font-weight: 700;
  color: #FF8C42;
  font-size: 20px;
  letter-spacing: -0.3px;
}
.description-text {
  line-height: 1.6;
  color: #4B5563;
}
.btn-edit-confirm {
  padding: 12px 24px;
  border: 2px solid #F59E0B;
  background: white;
  color: #F59E0B;
  cursor: pointer;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-edit-confirm:hover {
  background: #FFFBEB;
  border-color: #D97706;
  color: #D97706;
}
.delete-modal {
  max-width: 520px;
  padding: 0;
  overflow: hidden;
}
.delete-modal .modal-header {
  background: white;
  padding: 24px;
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
  border-radius: 10px;
  background: #EF4444;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 24px;
}
.delete-header h3 {
  margin: 0;
  color: #1a1a1a;
  font-size: 20px;
  font-weight: 700;
  letter-spacing: -0.3px;
}
.delete-modal .modal-body {
  padding: 24px;
}
.delete-modal .modal-body p {
  margin: 0 0 20px 0;
  color: #6B7280;
  font-size: 15px;
  line-height: 1.6;
}
.delete-modal .modal-body strong {
  color: #1a1a1a;
  font-weight: 600;
}
.delete-modal .modal-body .warning {
  color: #EF4444;
  font-weight: 600;
  margin-top: 12px;
}
.delete-modal .modal-actions {
  padding: 20px 24px;
  background: #FAFAFA;
  border-top: 1px solid #F0E6D9;
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}
.delete-modal .btn {
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  border: none;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s ease;
}
.delete-modal .btn-secondary {
  background: white;
  color: #6B7280;
  border: 1px solid #E2E8F0;
}
.delete-modal .btn-secondary:hover {
  background: #F9FAFB;
  border-color: #CBD5E1;
}
.delete-modal .btn-danger {
  background: #EF4444;
  color: white;
}
.delete-modal .btn-danger:hover:not(:disabled) {
  background: #DC2626;
}
.delete-modal .btn-danger:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
