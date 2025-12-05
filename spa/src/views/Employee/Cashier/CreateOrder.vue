<template>
  <div class="create-order-page">
    <!-- Main Content Area -->
    <div class="create-order-main-content">
      <!-- Main Tabs: Tables and Menu -->
      <div class="main-tabs">
        <button 
          :class="['main-tab-btn', { active: activeMainTab === 'tables' }]"
          @click="activeMainTab = 'tables'"
        >
          <i class="fas fa-table"></i> Select Table
          <span v-if="availableTables.length > 0" class="tab-badge">{{ availableTables.length }}</span>
        </button>
        <button 
          :class="['main-tab-btn', { active: activeMainTab === 'menu' }]"
          @click="activeMainTab = 'menu'"
        >
          <i class="fas fa-utensils"></i> Menu
        </button>
      </div>
      <!-- Tab Content: Menu - Separate Box -->
      <div v-if="activeMainTab === 'menu'" class="menu-box">
        <!-- Search -->
        <div class="search-filter-section">
          <div class="search-bar">
            <i class="fas fa-search"></i>
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="Search dishes..."
              @input="filterProducts"
            />
          </div>
        </div>
        <!-- Category Tabs -->
        <div class="content-header">
          <div class="tabs">
            <button 
              :class="['tab-btn', { active: selectedCategoryTab === null }]"
              @click="selectCategoryTab(null)"
            >
              All
            </button>
            <button 
              v-for="category in categories"
              :key="category.id"
              :class="['tab-btn', { active: selectedCategoryTab === category.id }]"
              @click="selectCategoryTab(category.id)"
            >
              {{ category.name }}
            </button>
          </div>
        </div>
        <div v-if="productsLoading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i>
          <p>Loading products...</p>
        </div>
        <div v-else-if="filteredProducts.length === 0" class="empty-state">
          <i class="fas fa-inbox"></i>
          <p>No products</p>
        </div>
        <div v-else class="products-grid">
          <div
            v-for="product in filteredProducts"
            :key="product.id"
            class="product-card"
            @click="openProductOptions(product)"
          >
            <div class="product-image-wrapper">
              <img 
                :src="product.image || '/images/default-product.png'" 
                :alt="product.name"
                class="product-image"
                @error="handleImageError"
              />
              <div class="product-badge" v-if="product.discount">
                -{{ product.discount }}%
              </div>
            </div>
            <div class="product-info">
              <h3 class="product-name">{{ product.name }}</h3>
              <div class="product-stats">
                <div class="product-stat-item">
                  <span class="stat-label-text">Price</span>
                  <span class="stat-value-text">{{ formatCurrency(product.price) }}</span>
                </div>
              </div>
              <div class="product-footer">
                <div class="product-rating" v-if="product.rating">
                  <i v-for="i in 5" :key="i" class="fas fa-star" :class="{ 'star-filled': i <= (product.rating || 0), 'star-empty': i > (product.rating || 0) }"></i>
                </div>
                <button class="btn-add-product" @click.stop="openProductOptions(product)">
                  <i class="fas fa-plus"></i>
                  <span>Add</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Tab Content: Tables - Separate Box -->
      <div v-if="activeMainTab === 'tables'" class="tables-box">
        <div class="tables-section">
          <!-- Time Selection Form -->
          <div class="time-selection-form">
            <h4><i class="fas fa-calendar-alt"></i> Select reservation time</h4>
            <div class="time-form-row">
              <div class="time-form-group">
                <label class="time-form-label"><i class="fas fa-calendar"></i> Date</label>
                <input 
                  v-model="reservationDate" 
                  type="date" 
                  class="time-form-input"
                  :min="new Date().toISOString().split('T')[0]"
                />
              </div>
              <div class="time-form-group">
                <label class="time-form-label">
                  <i class="fas fa-clock"></i> Start time
                  <button 
                    class="btn-update-time" 
                    @click="reservationStartTime = getCurrentTime()"
                    title="Update current time"
                  >
                    <i class="fas fa-sync-alt"></i>
                  </button>
                </label>
                <input 
                  v-model="reservationStartTime" 
                  type="time" 
                  class="time-form-input"
                />
              </div>
              <div class="time-form-group">
                <label class="time-form-label"><i class="fas fa-hourglass-half"></i> Duration</label>
                <select v-model="reservationDuration" class="time-form-select">
                  <option v-for="duration in durationOptions" :key="duration.value" :value="duration.value">
                    {{ duration.label }}
                  </option>
                </select>
              </div>
              <div class="time-form-group">
                <label class="time-form-label"><i class="fas fa-users"></i> Number of guests</label>
                <input 
                  v-model.number="reservationGuestCount" 
                  type="number" 
                  min="1"
                  class="time-form-input"
                  placeholder="Enter number of guests"
                />
              </div>
              <div class="time-form-group">
                <label class="time-form-label"><i class="fas fa-layer-group"></i> Floor</label>
                <select v-model="selectedFloorFilter" class="time-form-select">
                  <option :value="null">All floors</option>
                  <option v-for="floor in allFloors" :key="floor.id" :value="floor.id">
                    {{ floor.name }}
                  </option>
                </select>
              </div>
            </div>
            <div v-if="reservationDate && reservationStartTime && reservationDuration && reservationGuestCount" class="time-display-info">
              <i class="fas fa-info-circle"></i>
              <span>Time: {{ formatReservationDateTime() }} | Guests: {{ reservationGuestCount }}</span>
            </div>
            <div v-if="checkingAvailability" class="time-display-info checking">
              <i class="fas fa-spinner fa-spin"></i>
              <span>Checking table availability...</span>
            </div>
          </div>
          <div v-if="!hasCheckedAvailability" class="tables-empty">
            <i class="fas fa-calendar-check"></i>
            <p>Please select reservation time</p>
            <span class="empty-message">Enter date, time and duration to view available tables</span>
          </div>
          <div v-else-if="checkingAvailability || tablesLoading" class="tables-loading">
            <i class="fas fa-spinner fa-spin"></i>
            <p>Checking table availability...</p>
          </div>
          <div v-else-if="availableTables.length === 0" class="tables-empty">
            <i class="fas fa-table"></i>
            <p>No tables</p>
            <span class="empty-message">This branch has no tables set up yet</span>
          </div>
          <div v-else-if="filteredTables.length === 0" class="tables-empty">
            <i class="fas fa-filter"></i>
            <p>No available tables</p>
            <span class="empty-message">No tables available at the selected time. Try changing the time or filters.</span>
          </div>
          <div v-else class="tables-grid">
            <div
              v-for="table in filteredTables"
              :key="table.id"
              :class="['table-card', { 'selected': selectedTable == table.id, 'available': table.isAvailable }]"
              @click="selectTable(table)"
            >
              <!-- Normal View -->
              <div v-if="selectedTable != table.id" class="table-card-normal">
                <div class="table-card-header">
                  <div class="table-number-large">#{{ table.id }}</div>
                  <!-- Status badge removed - status is now managed in table_schedules -->
                </div>
                <div class="table-card-body">
                  <div class="table-info-item">
                    <i class="fas fa-layer-group"></i>
                    <span>{{ table.floor_name || 'Floor ' + table.floor_id }}</span>
                  </div>
                  <div class="table-info-item">
                    <i class="fas fa-users"></i>
                    <span>{{ table.capacity }} guests</span>
                  </div>
                  <div v-if="table.location" class="table-info-item">
                    <i class="fas fa-map-marker-alt"></i>
                    <span>{{ table.location }}</span>
                  </div>
                </div>
              </div>
              <!-- Selected View -->
              <div v-else class="table-card-normal">
                <div class="table-card-header">
                  <div class="table-number-large">#{{ table.id }}</div>
                  <button class="btn-remove-table" @click.stop="clearTableSelection">
                    Deselect
                  </button>
                </div>
                <div class="table-card-body">
                  <div class="table-info-item">
                    <i class="fas fa-layer-group"></i>
                    <span>{{ table.floor_name || 'Floor ' + table.floor_id }}</span>
                  </div>
                  <div class="table-info-item">
                    <i class="fas fa-users"></i>
                    <span>{{ table.capacity }} guests</span>
                  </div>
                  <div v-if="table.location" class="table-info-item">
                    <i class="fas fa-map-marker-alt"></i>
                    <span>{{ table.location }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Right Sidebar - Redesigned -->
    <div class="sidebar-right">
      <!-- Order Info Section - Compact -->
      <div class="order-info-section">
        <div class="order-info-header">
          <h4><i class="fas fa-shopping-cart"></i> Order</h4>
          <span class="item-count-badge">{{ cartItems.length }}</span>
        </div>
        <!-- Customer & Table Info - Compact -->
        <div class="info-compact">
          <div class="info-row-inline">
            <div class="info-row-half">
              <label><i class="fas fa-phone"></i> Phone number</label>
              <div class="input-with-loader">
                <input 
                  v-model="customerPhone" 
                  type="tel" 
                  placeholder="Phone (optional)"
                  class="form-input-compact"
                  @blur="searchCustomerByPhone"
                />
                <i v-if="searchingCustomer" class="fas fa-spinner fa-spin search-loader"></i>
              </div>
            </div>
            <div class="info-row-half">
              <label><i class="fas fa-user"></i> Customer name</label>
              <input 
                v-model="customerName" 
                type="text" 
                placeholder="Customer name"
                class="form-input-compact"
              />
            </div>
          </div>
          <div v-if="selectedTableInfo" class="info-row table-row">
            <div class="table-badge">
              <i class="fas fa-table"></i>
              <span>Table #{{ selectedTableInfo.id }}</span>
              <span class="table-details">{{ selectedTableInfo.floor_name || 'Floor ' + selectedTableInfo.floor_id }} • {{ selectedTableInfo.capacity }} guests</span>
              <button 
                class="btn-remove-table-inline" 
                @click="clearTableSelection"
                title="Deselect"
              >
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>
          <!-- Delivery Info Form (for takeaway/delivery) -->
          <div class="delivery-info-section-sidebar">
            <div class="delivery-form-row-sidebar-full">
              <div class="delivery-form-group-sidebar-full">
                <label><i class="fas fa-map-marker-alt"></i> Delivery Address *</label>
                <input 
                  v-model="deliveryAddressDetail" 
                  type="text" 
                  class="delivery-form-input-sidebar"
                  placeholder="Nhập địa chỉ để tìm kiếm..."
                />
                <small class="mapbox-hint">
                  <i class="fas fa-map-marker-alt"></i> Sử dụng Mapbox Autofill để tìm địa chỉ
                </small>
              </div>
            </div>
            <div v-if="hasDeliveryInfo" class="delivery-info-badge-sidebar">
              <i class="fas fa-info-circle"></i>
              <span>Takeaway/delivery order</span>
            </div>
          </div>
        </div>
      </div>
      <!-- Cart Items Section - Scrollable -->
      <div class="cart-section">
        <div v-if="cartItems.length === 0" class="empty-cart">
          <i class="fas fa-shopping-cart"></i>
          <p>Empty cart</p>
        </div>
        <div v-else class="cart-items">
          <div
            v-for="(item, index) in cartItems"
            :key="`cart-item-${item.id}-${index}`"
            class="cart-item"
          >
            <div class="item-image">
              <img 
                :src="item.image || '/images/default-product.png'" 
                :alt="item.name"
                @error="handleImageError"
              />
            </div>
            <div class="item-details">
              <h6 class="item-name">{{ item.name }}</h6>
              <div v-if="getItemOptionsText(item)" class="item-options">
                {{ getItemOptionsText(item) }}
              </div>
              <div v-if="item.notes" class="item-notes">
                <i class="fas fa-sticky-note"></i> {{ item.notes }}
              </div>
              <div class="item-controls">
                <button 
                  class="btn-quantity" 
                  @click="decreaseQuantity(index)"
                >
                  <i class="fas fa-minus"></i>
                </button>
                <span class="quantity">{{ item.quantity }}</span>
                <button 
                  class="btn-quantity" 
                  @click="increaseQuantity(index)"
                >
                  <i class="fas fa-plus"></i>
                </button>
              </div>
            </div>
            <div class="item-price">
              <span>{{ formatCurrency(item.price * item.quantity) }}</span>
              <button class="btn-remove" @click="removeItem(index)">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
      <!-- Payment Section - Sticky Bottom -->
      <div class="payment-section-sticky">
        <!-- Summary -->
        <div class="payment-summary-compact">
          <div class="summary-row-compact">
            <span>Subtotal:</span>
            <span>{{ formatCurrency(subtotal) }}</span>
          </div>
          <div v-if="tax > 0" class="summary-row-compact">
            <span>Tax:</span>
            <span>{{ formatCurrency(tax) }}</span>
          </div>
          <div v-if="discount > 0" class="summary-row-compact discount">
            <span>Discount:</span>
            <span>-{{ formatCurrency(discount) }}</span>
          </div>
          <div class="summary-row-compact total-row">
            <span class="total-label">Total:</span>
            <span class="total-amount">{{ formatCurrency(total) }}</span>
          </div>
        </div>
        <!-- Payment Methods -->
        <div class="payment-methods-section">
          <div class="methods-grid">
            <button
              v-for="method in paymentMethods"
              :key="method.id"
              :class="['method-btn', { active: selectedPaymentMethod === method.id }]"
              @click="selectPaymentMethod(method.id)"
              :title="method.name"
            >
              <i :class="method.icon"></i>
            </button>
          </div>
        </div>
        <!-- Create Order Button -->
        <button 
          class="btn-place-order-main" 
          @click="placeOrder"
          :disabled="cartItems.length === 0 || placingOrder"
        >
          <div class="btn-order-content">
            <i class="fas fa-check-circle"></i>
            <span class="btn-order-text">{{ placingOrder ? 'Processing...' : 'Create order' }}</span>
          </div>
          <span class="order-total">{{ formatCurrency(total) }}</span>
        </button>
      </div>
    </div>
    <!-- Product Options Modal -->
    <div v-if="showProductOptions" class="modal-overlay" @click.self="closeProductOptions">
      <div class="modal-content product-options-modal">
        <div class="modal-header">
          <div class="modal-header-content">
            <div class="modal-header-image">
              <img 
                :src="selectedProduct?.image || '/images/default-product.png'" 
                :alt="selectedProduct?.name"
                @error="handleImageError"
              />
            </div>
            <h3>{{ selectedProduct?.name }}</h3>
          </div>
          <button class="modal-close" @click="closeProductOptions">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body" v-if="selectedProduct">
          <div class="product-options-form">
            <!-- Options grouped by type -->
            <template v-if="productOptions && productOptions.length > 0">
              <div 
                v-for="option in productOptions" 
                :key="option.id"
                class="option-card info-card"
              >
              <div class="card-header">
                <i :class="getOptionIcon(option.name, option.type)"></i>
                <h3>
                  {{ option.name }}
                  <span v-if="option.required" class="required-asterisk">*</span>
                </h3>
              </div>
              <div class="card-content">
                <!-- Select type (choose one) -->
                <div v-if="option.type === 'select'" class="options-grid">
                  <button
                    v-for="value in option.values"
                    :key="value.id"
                    :class="['option-btn', 'option-btn-select', { active: selectedOptions && selectedOptions[option.id] && selectedOptions[option.id][0] === value.id }]"
                    @click="selectOptionValue(option.id, value.id, 'select')"
                  >
                    <div class="option-btn-content">
                      <div class="option-name-wrapper">
                        <span class="option-name">{{ value.value || value.label || value.name }}</span>
                        <i v-if="selectedOptions && selectedOptions[option.id] && selectedOptions[option.id][0] === value.id" class="fas fa-check-circle option-check-icon"></i>
                      </div>
                      <span class="option-price" v-if="value.price_modifier !== 0">
                        {{ value.price_modifier > 0 ? '+' : '' }}{{ formatCurrency(value.price_modifier || 0) }}
                      </span>
                    </div>
                  </button>
                </div>
                <!-- Checkbox type (choose multiple) -->
                <div v-else-if="option.type === 'checkbox'" class="options-list">
                  <label
                    v-for="value in option.values"
                    :key="value.id"
                    :class="['option-checkbox', 'option-checkbox-custom', { checked: selectedOptions && selectedOptions[option.id] && selectedOptions[option.id].includes(value.id) }]"
                  >
                    <div class="custom-checkbox-wrapper">
                      <input
                        type="checkbox"
                        :value="value.id"
                        :checked="selectedOptions && selectedOptions[option.id] && selectedOptions[option.id].includes(value.id)"
                        @change="toggleOptionValue(option.id, value.id)"
                        class="custom-checkbox-input"
                      />
                      <span class="custom-checkbox">
                        <i class="fas fa-check"></i>
                      </span>
                    </div>
                    <span class="checkbox-label">
                      <span class="checkbox-name">{{ value.value || value.label || value.name }}</span>
                      <span class="option-price" v-if="value.price_modifier !== 0">
                        {{ value.price_modifier > 0 ? '+' : '' }}{{ formatCurrency(value.price_modifier || 0) }}
                      </span>
                    </span>
                  </label>
                </div>
              </div>
            </div>
            </template>
            <!-- Show message if no options -->
            <div v-else class="no-options-message">
              <i class="fas fa-info-circle"></i>
              <p>No options available for this product</p>
            </div>
            <!-- Quantity -->
            <div class="option-card info-card">
              <div class="card-header">
                <i class="fas fa-sort-numeric-up"></i>
                <h3>Quantity</h3>
              </div>
              <div class="card-content">
                <div class="quantity-selector">
                  <button class="qty-btn" @click="decreaseOptionQuantity">
                    <i class="fas fa-minus"></i>
                  </button>
                  <span class="qty-value">{{ optionQuantity }}</span>
                  <button class="qty-btn" @click="increaseOptionQuantity">
                    <i class="fas fa-plus"></i>
                  </button>
                </div>
              </div>
            </div>
            <!-- Notes -->
            <div class="option-card info-card">
              <div class="card-header">
                <i class="fas fa-sticky-note"></i>
                <h3>Notes</h3>
              </div>
              <div class="card-content">
                <textarea
                  v-model="productNotes"
                  class="notes-input"
                  placeholder="Notes for this item..."
                  rows="2"
                ></textarea>
              </div>
            </div>
            <!-- Price Summary -->
            <div class="option-price-summary">
              <div class="price-row">
                <span>Base price:</span>
                <span>{{ formatCurrency(selectedProduct.price || 0) }}</span>
              </div>
              <!-- Show price modifiers for each selected option -->
              <template v-for="option in productOptions" :key="option.id">
                <div 
                  v-if="selectedOptions[option.id] && selectedOptions[option.id].length > 0"
                  class="price-row"
                >
                  <span>{{ option.name }}:</span>
                  <span>
                    <template v-if="getOptionPrice(option.id) !== 0">
                      {{ getOptionPrice(option.id) > 0 ? '+' : '' }}{{ formatCurrency(getOptionPrice(option.id)) }}
                    </template>
                    <template v-else>
                      {{ formatCurrency(0) }}
                    </template>
                  </span>
                </div>
              </template>
              <!-- Fallback to old format if no new options selected -->
              <div class="price-row" v-if="selectedOptionsPrice === 0 && selectedSizePrice > 0">
                <span>Size:</span>
                <span>+{{ formatCurrency(selectedSizePrice) }}</span>
              </div>
              <div class="price-row" v-if="selectedOptionsPrice === 0 && selectedToppingsPrice > 0">
                <span>Topping:</span>
                <span>+{{ formatCurrency(selectedToppingsPrice) }}</span>
              </div>
              <div class="price-row total">
                <span>Total:</span>
                <span>{{ formatCurrency(optionTotalPrice) }}</span>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeProductOptions">
            Cancel
          </button>
          <button class="btn-add-to-cart" @click="confirmAddToCart">
            <i class="fas fa-shopping-cart"></i>
            Add to cart ({{ optionQuantity }})
          </button>
        </div>
      </div>
    </div>
    <!-- Table Schedule Modal -->
    <div v-if="showTableScheduleModal" class="modal-overlay" @click="closeTableScheduleModal">
      <div class="modal-content large" @click.stop>
        <div class="modal-header">
          <h3>
            <i class="fas fa-calendar-alt"></i> 
            Table schedule #{{ selectedTableForSchedule?.id }}
            <span v-if="selectedTableForSchedule?.floor_name" class="floor-info">
              ({{ selectedTableForSchedule.floor_name }})
            </span>
          </h3>
          <button class="modal-close" @click="closeTableScheduleModal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="schedule-controls">
            <div class="date-range-selector">
              <label>From date:</label>
              <input 
                v-model="scheduleDateRange.startDate" 
                type="date" 
                class="form-input"
                @change="loadTableSchedule(selectedTableForSchedule.id)"
              />
              <label>To date:</label>
              <input 
                v-model="scheduleDateRange.endDate" 
                type="date" 
                class="form-input"
                @change="loadTableSchedule(selectedTableForSchedule.id)"
              />
              <div v-if="branchInfo" class="operating-hours-info">
                <i class="fas fa-clock"></i>
                <span>Operating hours: {{ branchInfo.opening_hours || 7 }}:00 - {{ branchInfo.close_hours || 22 }}:00</span>
              </div>
            </div>
          </div>
          <div v-if="tableScheduleLoading || !branchInfo" class="schedule-loading">
            <i class="fas fa-spinner fa-spin"></i>
            <p v-if="!branchInfo">Loading branch information...</p>
            <p v-else>Loading schedule...</p>
          </div>
          <!-- Schedule Chart - Always show when branch info is loaded -->
          <div v-else class="schedule-chart-wrapper">
            <div class="schedule-chart" :style="{ '--dates-count': dateRange.length, '--hours-count': operatingHours.length }">
              <!-- Y-axis: Dates -->
              <div class="chart-y-axis">
                <div 
                  v-for="date in dateRange" 
                  :key="date"
                  class="y-axis-label"
                >
                  {{ formatChartDate(date) }}
                </div>
              </div>
              <!-- Chart Grid -->
              <div class="chart-grid">
                <!-- X-axis: Time (hours) -->
                <div class="chart-x-axis">
                  <div 
                    v-for="hour in operatingHours" 
                    :key="hour"
                    class="x-axis-label"
                  >
                    {{ hour.toString().padStart(2, '0') }}:00
                  </div>
                </div>
                <!-- Grid Cells -->
                <div class="chart-cells">
                  <div 
                    v-for="date in dateRange" 
                    :key="date"
                    class="chart-row"
                  >
                    <div 
                      v-for="hour in operatingHours" 
                      :key="`${date}-${hour}`"
                      class="chart-cell"
                      :class="getCellClass(date, hour)"
                      @click="selectCell(date, hour)"
                    >
                      <template v-if="getReservationsForCell(date, hour).length > 0">
                        <div 
                          v-for="reservation in getReservationsForCell(date, hour)" 
                          :key="reservation.id"
                          class="reservation-block"
                          :class="getReservationStatusClass(reservation.status)"
                          :title="getReservationTooltip(reservation)"
                          @click.stop
                        >
                          <div class="reservation-time">{{ formatScheduleTime(reservation.reservation_time) }}</div>
                          <div class="reservation-customer">{{ reservation.user_name || reservation.customer_name || 'Guest' }}</div>
                          <div class="reservation-guests">{{ reservation.guest_count }} guests</div>
                        </div>
                      </template>
                      <div v-else class="chart-cell-empty">
                        <span class="empty-indicator">Available</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <!-- Legend -->
            <div class="schedule-legend">
              <div class="legend-item">
                <span class="legend-color status-pending"></span>
                <span>Pending</span>
              </div>
              <div class="legend-item">
                <span class="legend-color status-confirmed"></span>
                <span>Confirmed</span>
              </div>
              <div class="legend-item">
                <span class="legend-color status-checked-in"></span>
                <span>Checked in</span>
              </div>
              <div class="legend-item">
                <span class="legend-color status-completed"></span>
                <span>Completed</span>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="closeTableScheduleModal">
            Close
          </button>
        </div>
      </div>
    </div>
    <!-- Error Modal -->
    <div v-if="showErrorModal" class="modal-overlay" @click.self="closeErrorModal">
      <div class="modal-content error-modal">
        <div class="modal-header">
          <h3>
            <i class="fas fa-exclamation-circle"></i>
            Error
          </h3>
          <button class="modal-close" @click="closeErrorModal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="error-content">
            <div class="error-icon">
              <i class="fas fa-exclamation-triangle"></i>
            </div>
            <p class="error-message">{{ formattedErrorMessage }}</p>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-primary" @click="closeErrorModal">
            OK
          </button>
        </div>
      </div>
    </div>
    <!-- Confirmation Modal -->
    <div v-if="showConfirmModal" class="modal-overlay" @click.self="closeConfirmModal">
      <div class="modal-content confirm-modal">
        <div class="modal-header">
          <h3>
            <i class="fas fa-question-circle"></i>
            Confirmation
          </h3>
          <button class="modal-close" @click="closeConfirmModal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="confirm-content">
            <div class="confirm-icon">
              <i class="fas fa-question-circle"></i>
            </div>
            <p class="confirm-message">{{ confirmMessage }}</p>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="closeConfirmModal">
            Cancel
          </button>
          <button class="btn btn-primary" @click="handleConfirm">
            Confirm
          </button>
        </div>
      </div>
    </div>
    <!-- Cell Info Modal -->
    <div v-if="showCellInfoModal" class="modal-overlay" @click="showCellInfoModal = false">
      <div class="modal-content small" @click.stop>
        <div class="modal-header">
          <h3>
            <i class="fas fa-info-circle"></i> 
            Table information #{{ selectedCellInfo?.table?.id }}
          </h3>
          <button class="modal-close" @click="showCellInfoModal = false">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div v-if="selectedCellInfo" class="cell-info">
            <div class="info-section">
              <div class="info-item">
                <label>Date:</label>
                <span>{{ formatChartDate(selectedCellInfo.date) }}</span>
              </div>
              <div class="info-item">
                <label>Table:</label>
                <span>#{{ selectedCellInfo.table?.id }} ({{ selectedCellInfo.table?.floor_name }})</span>
              </div>
            </div>
            <div class="time-edit-section">
              <h4><i class="fas fa-clock"></i> Edit time</h4>
              <div class="time-inputs-simple">
                <div class="time-input-wrapper">
                  <label><i class="fas fa-play-circle"></i> Start time</label>
                  <input 
                    type="time" 
                    v-model="startTimeString"
                    @change="updateTimeFromString"
                    class="time-input"
                  />
                </div>
                <div class="time-arrow">
                  <i class="fas fa-arrow-right"></i>
                </div>
                <div class="time-input-wrapper">
                  <label><i class="fas fa-stop-circle"></i> End time</label>
                  <input 
                    type="time" 
                    v-model="endTimeString"
                    @change="updateTimeFromString"
                    class="time-input"
                  />
                </div>
              </div>
              <div class="duration-quick-select">
                <label>Or select duration:</label>
                <div class="duration-buttons">
                  <button 
                    v-for="duration in durationOptions" 
                    :key="duration.value"
                    @click="setDuration(duration.value)"
                    class="duration-btn"
                    :class="{ active: selectedDuration === duration.value }"
                  >
                    {{ duration.label }}
                  </button>
                </div>
              </div>
              <div class="time-display-preview">
                <div class="preview-label">Time range:</div>
                <div class="preview-time">
                  <span class="time-badge start">{{ startTimeString || '--:--' }}</span>
                  <i class="fas fa-arrow-right"></i>
                  <span class="time-badge end">{{ endTimeString || '--:--' }}</span>
                </div>
              </div>
            </div>
            <div v-if="selectedCellInfo.reservations.length > 0" class="reservations-list">
              <h4>Reservation schedule:</h4>
              <div 
                v-for="reservation in selectedCellInfo.reservations" 
                :key="reservation.id"
                class="reservation-item"
                :class="getReservationStatusClass(reservation.status)"
              >
                <div class="reservation-header">
                  <span class="reservation-time">{{ formatScheduleTime(reservation.reservation_time) }}</span>
                  <span :class="['status-badge', getReservationStatusClass(reservation.status)]">
                    {{ getReservationStatusLabel(reservation.status) }}
                  </span>
                </div>
                <div class="reservation-details">
                  <div><strong>Customer:</strong> {{ reservation.user_name || reservation.customer_name || 'Walk-in customer' }}</div>
                  <div><strong>Guests:</strong> {{ reservation.guest_count }} guests</div>
                  <div v-if="reservation.special_requests"><strong>Notes:</strong> {{ reservation.special_requests }}</div>
                </div>
              </div>
            </div>
            <div v-else class="no-reservations">
              <i class="fas fa-calendar-times"></i>
              <p>No reservations in this time range</p>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="showCellInfoModal = false">
            Close
          </button>
          <button v-if="selectedCellInfo && selectedCellInfo.reservations.length === 0" class="btn btn-primary" @click="confirmReservation">
            <i class="fas fa-check"></i> Confirm reservation
          </button>
          <button v-if="selectedCellInfo" class="btn btn-success" @click="saveTimeChanges">
            <i class="fas fa-save"></i> Save time changes
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'vue-toastification';
const emit = defineEmits(['order-created']);
import ProductService from '@/services/ProductService';
import CategoryService from '@/services/CategoryService';
import BranchService from '@/services/BranchService';
import UserService from '@/services/UserService';
import OrderService from '@/services/OrderService';
import AuthService from '@/services/AuthService';
import TableService from '@/services/TableService';
import ReservationService from '@/services/ReservationService';
const router = useRouter();
const toast = useToast();
const categories = ref([]);
const products = ref([]);
const branches = ref([]);
const productsLoading = ref(false);
const searchQuery = ref('');
const selectedCategory = ref(null);
const selectedCategoryTab = ref(null);
const showFilters = ref(false);
const cartItems = ref([]);
const showProductOptions = ref(false);
const selectedProduct = ref(null);
const selectedSize = ref(null);
const selectedToppings = ref([]);
const optionQuantity = ref(1);
const productNotes = ref('');
const productSizes = ref([]);
const productToppings = ref([]);
const productOptions = ref([]); 
const selectedOptions = ref({}); 
const paymentMethods = [
  { id: 'cash', name: 'Cash', icon: 'fas fa-money-bill-wave' },
  { id: 'card', name: 'Card', icon: 'fas fa-credit-card' },
  { id: 'bank_transfer', name: 'Bank transfer', icon: 'fas fa-university' },
  { id: 'e_wallet', name: 'E-wallet', icon: 'fas fa-wallet' }
];
const selectedPaymentMethod = ref('cash');
const customerName = ref('');
const customerPhone = ref('');
const searchingCustomer = ref(false);
const deliveryAddressDetail = ref('');
const tables = ref([]);
const availableTables = ref([]);
const selectedTable = ref('');
const selectedTableInfo = ref(null);
const tablesLoading = ref(false);
const selectedTableForSchedule = ref(null);
const showTableScheduleModal = ref(false);
const tableSchedule = ref([]);
const tableScheduleLoading = ref(false);
const branchInfo = ref(null);
const scheduleDateRange = ref({
  startDate: new Date().toISOString().split('T')[0],
  endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0] 
});
const selectedCellInfo = ref(null);
const showCellInfoModal = ref(false);
const showErrorModal = ref(false);
const formattedErrorMessage = ref('');
const showConfirmModal = ref(false);
const confirmMessage = ref('');
const confirmCallback = ref(null);
const editedTime = ref({
  startHour: 0,
  startMinute: 0,
  endHour: 0,
  endMinute: 0
});
const startTimeString = ref('');
const endTimeString = ref('');
const selectedDuration = ref(null);
const reservationDate = ref(new Date().toISOString().split('T')[0]);
const getCurrentTime = () => {
  const now = new Date();
  const hours = now.getHours().toString().padStart(2, '0');
  const minutes = now.getMinutes().toString().padStart(2, '0');
  return `${hours}:${minutes}`;
};
const reservationStartTime = ref(getCurrentTime());
const reservationDuration = ref(120);
const reservationGuestCount = ref(1);
const hasCheckedAvailability = ref(false);
const checkingAvailability = ref(false);
const isCheckingInProgress = ref(false); 
const tableAvailabilityMap = ref(new Map()); 
const durationOptions = [
  { label: '1 hour', value: 60 },
  { label: '1.5 hours', value: 90 },
  { label: '2 hours', value: 120 },
  { label: '2.5 hours', value: 150 },
  { label: '3 hours', value: 180 }
];
const selectedFloorFilter = ref(null);
const placingOrder = ref(false);
const activeMainTab = ref('tables'); 
const filteredProducts = computed(() => {
  let result = products.value;
  if (selectedCategoryTab.value !== null) {
    result = result.filter(p => p.category_id === selectedCategoryTab.value);
  }
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(p => 
      p.name.toLowerCase().includes(query)
    );
  }
  return result;
});
const hasDeliveryInfo = computed(() => {
  return deliveryAddressDetail.value.trim();
});
const canAddToCart = computed(() => {
  return selectedTable.value || hasDeliveryInfo.value;
});
const filteredTables = computed(() => {
  let result = availableTables.value;
  if (hasCheckedAvailability.value) {
    result = result.filter(table => {
      const availability = tableAvailabilityMap.value.get(table.id);
      return availability === true;
    }).map(table => ({
      ...table,
      isAvailable: true
    }));
    if (reservationGuestCount.value && reservationGuestCount.value > 0) {
      result = result.filter(t => t.capacity >= reservationGuestCount.value);
    }
  } else {
    result = [];
  }
  return result;
});
const uniqueFloors = computed(() => {
  const floors = new Map();
  availableTables.value.forEach(table => {
    if (!floors.has(table.floor_id)) {
      floors.set(table.floor_id, {
        id: table.floor_id,
        name: table.floor_name || `Floor ${table.floor_id}`
      });
    }
  });
  return Array.from(floors.values());
});
const allFloors = computed(() => {
  const floors = new Map();
  tables.value.forEach(table => {
    if (table.floor_id && !floors.has(table.floor_id)) {
      floors.set(table.floor_id, {
        id: table.floor_id,
        name: table.floor_name || `Floor ${table.floor_id}`
      });
    }
  });
  return Array.from(floors.values()).sort((a, b) => a.id - b.id);
});
const subtotal = computed(() => {
  const sum = cartItems.value.reduce((acc, item) => {
    const price = Number(item.price) || 0;
    const quantity = Number(item.quantity) || 0;
    return acc + (price * quantity);
  }, 0);
  return isNaN(sum) ? 0 : sum;
});
const tax = computed(() => {
  const taxAmount = subtotal.value * 0.1; 
  return isNaN(taxAmount) ? 0 : taxAmount;
});
const discount = computed(() => {
  return 0;
});
const total = computed(() => {
  const totalAmount = Math.max(0, subtotal.value + tax.value - discount.value);
  return isNaN(totalAmount) ? 0 : totalAmount;
});
async function loadCategories() {
  try {
    const data = await CategoryService.getAllCategories();
    let cats = [];
    if (Array.isArray(data)) {
      cats = data;
    } else if (data && data.categories && Array.isArray(data.categories)) {
      cats = data.categories;
    } else if (data && data.items && Array.isArray(data.items)) {
      cats = data.items;
    } else if (data && data.data && Array.isArray(data.data)) {
      cats = data.data;
    }
    categories.value = cats.map(cat => ({
      id: cat.id,
      name: cat.name || cat.category_name || '',
      description: cat.description || '',
      image: cat.image || null,
      icon: getCategoryIcon(cat.name || cat.category_name || '')
    }));
  } catch (error) {
    showError(error);
  }
}
async function loadProducts() {
  productsLoading.value = true;
  try {
    const branchId = getCurrentBranchId();
    if (!branchId) {
      toast.error('Vui lòng chọn chi nhánh');
      productsLoading.value = false;
      return;
    }
    const data = await ProductService.getAvailableProducts({ 
      branch_id: branchId 
    });
    const prods = data.products || data.items || data.data || [];
    products.value = prods.map(product => ({
      ...product,
      price: Number(product.price || product.display_price || product.base_price) || 0,
      image: product.image || '/images/default-product.png',
      original_price: product.original_price ? Number(product.original_price) : null,
      discount: product.discount || null,
      rating: product.rating || null
    }));
  } catch (error) {
    showError(error);
  } finally {
    productsLoading.value = false;
  }
}
async function searchCustomerByPhone() {
  let phone = customerPhone.value?.trim().replace(/[\s\-\(\)\.]/g, '') || '';
  const digitCount = phone.replace(/\D/g, '').length;
  if (!phone || digitCount < 10) {
    return;
  }
  phone = phone.replace(/[^\d+]/g, '');
  const nameWasManuallyEntered = customerName.value?.trim() ? true : false;
  searchingCustomer.value = true;
  try {
    const data = await UserService.getAllUsers({ 
      role_id: 4,
      phone: phone
    });
    const customers = data.users || data.items || data.data || [];
    if (customers.length > 0) {
      const customer = customers[0]; 
      const customerPhoneNormalized = (customer.phone || '').replace(/[\s\-\(\)\.]/g, '').replace(/[^\d+]/g, '');
      if (!nameWasManuallyEntered || customerPhoneNormalized === phone) {
        customerName.value = customer.name || '';
        toast.success('Customer found in system');
      }
    } else {
      if (!nameWasManuallyEntered) {
        }
    }
  } catch (error) {
    if (error.message && !error.message.includes('404') && !error.message.includes('not found')) {
      showError(error);
    }
  } finally {
    searchingCustomer.value = false;
  }
}
let searchCustomerTimeout = null;
watch(customerPhone, () => {
  if (searchCustomerTimeout) {
    clearTimeout(searchCustomerTimeout);
  }
  const phone = customerPhone.value?.trim();
  if (phone && phone.length >= 10) {
    searchCustomerTimeout = setTimeout(() => {
      searchCustomerByPhone();
    }, 800);
  } else {
    if (!customerName.value?.trim()) {
      customerName.value = '';
    }
  }
});
async function loadTables() {
  if (activeMainTab.value === 'tables') {
    tablesLoading.value = true;
  }
  try {
    const branchId = getCurrentBranchId();
    if (!branchId) {
      availableTables.value = [];
      tables.value = [];
      return;
    }
    const branchIdNum = parseInt(branchId);
    if (isNaN(branchIdNum)) {
      showError(new Error('Invalid branch. Please log in again.'));
      availableTables.value = [];
      tables.value = [];
      return;
    }
    const data = await TableService.getAllTables({ branch_id: branchIdNum });
    let tablesList = [];
    if (data && Array.isArray(data)) {
      tablesList = data;
    } else if (data && data.tables && Array.isArray(data.tables)) {
      tablesList = data.tables;
    } else if (data && data.items && Array.isArray(data.items)) {
      tablesList = data.items;
    } else if (data && data.data && Array.isArray(data.data)) {
      tablesList = data.data;
    } else {
      tablesList = [];
    }
    tables.value = tablesList;
    availableTables.value = tablesList;
    if (selectedTable.value) {
      selectedTableInfo.value = tablesList.find(t => t.id === parseInt(selectedTable.value));
    }
    if (tablesList.length === 0 && activeMainTab.value === 'tables') {
      toast.warning('No tables in this branch');
    }
  } catch (error) {
    if (activeMainTab.value === 'tables') {
      toast.error('Failed to load tables: ' + (error.message || 'Unknown error'));
    }
    availableTables.value = [];
    tables.value = [];
  } finally {
    tablesLoading.value = false;
  }
}
function getCategoryIcon(categoryName) {
  const icons = {
    'Burger': 'fas fa-hamburger',
    'Pizza': 'fas fa-pizza-slice',
    'Chicken': 'fas fa-drumstick-bite',
    'Drink': 'fas fa-wine-glass',
    'Dessert': 'fas fa-ice-cream',
    'Salad': 'fas fa-leaf',
    'Soup': 'fas fa-bowl-food',
    'Rice': 'fas fa-bowl-rice',
    'Noodle': 'fas fa-utensils'
  };
  return icons[categoryName] || 'fas fa-utensils';
}
function getOptionIcon(optionName, optionType) {
  const name = (optionName || '').toLowerCase();
  if (name.includes('kích cỡ') || name.includes('size')) {
    return 'fas fa-arrows-alt-v';
  }
  if (name.includes('độ chín') || name.includes('doneness') || name.includes('cooking')) {
    return 'fas fa-fire';
  }
  if (name.includes('topping') || name.includes('thêm')) {
    return 'fas fa-plus-circle';
  }
  if (name.includes('spice') || name.includes('độ cay')) {
    return 'fas fa-pepper-hot';
  }
  if (name.includes('sauce') || name.includes('nước sốt')) {
    return 'fas fa-tint';
  }
  if (name.includes('ice') || name.includes('đá')) {
    return 'fas fa-snowflake';
  }
  if (optionType === 'select') {
    return 'fas fa-list';
  }
  if (optionType === 'checkbox') {
    return 'fas fa-check-square';
  }
  return 'fas fa-cog';
}
function getTableStatusLabel(status) {
  const labels = {
    'available': 'Available',
    'occupied': 'Occupied',
    'reserved': 'Reserved',
    'maintenance': 'Maintenance'
  };
  return labels[status] || status;
}
function onTableChange() {
  if (selectedTable.value) {
    selectedTableInfo.value = tables.value.find(t => t.id === parseInt(selectedTable.value));
  } else {
    selectedTableInfo.value = null;
  }
}
async function selectTable(table) {
  if (selectedTable.value == table.id) {
    selectedTable.value = '';
    selectedTableInfo.value = null;
  } else {
    selectedTable.value = table.id;
    selectedTableInfo.value = table;
  }
}
async function loadBranchInfo(branchId) {
  try {
    const data = await BranchService.getBranchById(branchId);
    branchInfo.value = data?.branch || data?.data || data || null;
  } catch (error) {
    branchInfo.value = { opening_hours: 7, close_hours: 22 };
  }
}
async function loadTableSchedule(tableId) {
  tableScheduleLoading.value = true;
  try {
    const data = await ReservationService.getTableSchedule(
      tableId,
      scheduleDateRange.value.startDate,
      scheduleDateRange.value.endDate
    );
    const reservations = data?.reservations || data?.data?.reservations || data?.data || data || [];
    tableSchedule.value = Array.isArray(reservations) ? reservations : [];
  } catch (error) {
    showError(error);
    tableSchedule.value = [];
  } finally {
    tableScheduleLoading.value = false;
  }
}
function formatScheduleDate(dateString) {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleDateString('vi-VN', { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' });
}
function formatScheduleTime(timeString) {
  if (!timeString) return '';
  return timeString.substring(0, 5); 
}
function getReservationStatusLabel(status) {
  const labels = {
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'checked_in': 'Checked in',
    'completed': 'Completed',
    'cancelled': 'Cancelled'
  };
  return labels[status] || status;
}
function getReservationStatusClass(status) {
  const classes = {
    'pending': 'status-pending',
    'confirmed': 'status-confirmed',
    'checked_in': 'status-checked-in',
    'completed': 'status-completed',
    'cancelled': 'status-cancelled'
  };
  return classes[status] || 'status-default';
}
function closeTableScheduleModal() {
  showTableScheduleModal.value = false;
  selectedTableForSchedule.value = null;
  tableSchedule.value = [];
  branchInfo.value = null;
}
const operatingHours = computed(() => {
  const startHour = branchInfo.value?.opening_hours || 7;
  const endHour = branchInfo.value?.close_hours || 22;
  const hours = [];
  for (let h = startHour; h <= endHour; h += 2) {
    hours.push(h);
  }
  const lastHour = hours[hours.length - 1];
  if (lastHour < endHour) {
    hours.push(endHour);
  }
  return hours;
});
const allOperatingHours = computed(() => {
  const startHour = branchInfo.value?.opening_hours || 7;
  const endHour = branchInfo.value?.close_hours || 22;
  const hours = [];
  for (let h = startHour; h <= endHour; h++) {
    hours.push(h);
  }
  return hours;
});
const dateRange = computed(() => {
  const dates = [];
  const start = new Date(scheduleDateRange.value.startDate);
  const end = new Date(scheduleDateRange.value.endDate);
  for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
    dates.push(new Date(d).toISOString().split('T')[0]);
  }
  return dates;
});
function formatChartDate(dateString) {
  const date = new Date(dateString);
  const day = date.getDate();
  const month = date.getMonth() + 1;
  return `${day}/${month}`;
}
function getReservationsForCell(date, hour) {
  return tableSchedule.value.filter(reservation => {
    const resDate = reservation.reservation_date.split('T')[0];
    const resHour = parseInt(reservation.reservation_time.split(':')[0]);
    return resDate === date && resHour >= hour && resHour < hour + 2;
  });
}
function selectCell(date, hour) {
  selectedCellInfo.value = {
    date: date,
    hour: hour,
    hourEnd: hour + 2,
    table: selectedTableForSchedule.value,
    reservations: getReservationsForCell(date, hour)
  };
  editedTime.value = {
    startHour: hour,
    startMinute: 0,
    endHour: hour + 2,
    endMinute: 0
  };
  startTimeString.value = `${hour.toString().padStart(2, '0')}:00`;
  endTimeString.value = `${(hour + 2).toString().padStart(2, '0')}:00`;
  selectedDuration.value = 120; 
  showCellInfoModal.value = true;
}
function updateTimeFromString() {
  if (startTimeString.value) {
    const [hour, minute] = startTimeString.value.split(':').map(Number);
    editedTime.value.startHour = hour;
    editedTime.value.startMinute = minute;
  }
  if (endTimeString.value) {
    const [hour, minute] = endTimeString.value.split(':').map(Number);
    editedTime.value.endHour = hour;
    editedTime.value.endMinute = minute;
  }
  selectedDuration.value = null; 
}
function setDuration(minutes) {
  if (!startTimeString.value) return;
  selectedDuration.value = minutes;
  const [startHour, startMinute] = startTimeString.value.split(':').map(Number);
  const startTotal = startHour * 60 + startMinute;
  const endTotal = startTotal + minutes;
  const endHour = Math.floor(endTotal / 60);
  const endMinute = endTotal % 60;
  endTimeString.value = `${endHour.toString().padStart(2, '0')}:${endMinute.toString().padStart(2, '0')}`;
  editedTime.value.endHour = endHour;
  editedTime.value.endMinute = endMinute;
}
function formatCellTime(hour) {
  return `${hour.toString().padStart(2, '0')}:00 - ${(hour + 2).toString().padStart(2, '0')}:00`;
}
function getCellClass(date, hour) {
  const reservations = getReservationsForCell(date, hour);
  if (reservations.length > 0) {
    return 'has-reservation';
  }
  return '';
}
function getReservationTooltip(reservation) {
  return `${reservation.user_name || reservation.customer_name || 'Walk-in customer'} - ${reservation.guest_count} guests - ${formatScheduleTime(reservation.reservation_time)}`;
}
function confirmReservation() {
  if (!selectedCellInfo.value) return;
  updateTimeFromString();
  if (!startTimeString.value || !endTimeString.value) {
    showError(new Error('Please select start time and end time'));
    return;
  }
  const startTotal = editedTime.value.startHour * 60 + editedTime.value.startMinute;
  const endTotal = editedTime.value.endHour * 60 + editedTime.value.endMinute;
  if (endTotal <= startTotal) {
    showError(new Error('End time must be after start time'));
    return;
  }
  const startTime = startTimeString.value;
  const endTime = endTimeString.value;
  toast.info(`Confirm reservation for table #${selectedCellInfo.value.table?.id} on ${formatChartDate(selectedCellInfo.value.date)} from ${startTime} to ${endTime}`);
  showCellInfoModal.value = false;
}
function getAvailableHours() {
  const startHour = branchInfo.value?.opening_hours || 7;
  const endHour = branchInfo.value?.close_hours || 22;
  const hours = [];
  for (let h = startHour; h <= endHour; h++) {
    hours.push(h);
  }
  return hours;
}
function formatEditedTime(hour, minute) {
  return `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
}
function saveTimeChanges() {
  if (!selectedCellInfo.value) return;
  updateTimeFromString();
  if (!startTimeString.value || !endTimeString.value) {
    showError(new Error('Please select start time and end time'));
    return;
  }
  const startTotal = editedTime.value.startHour * 60 + editedTime.value.startMinute;
  const endTotal = editedTime.value.endHour * 60 + editedTime.value.endMinute;
  if (endTotal <= startTotal) {
    showError(new Error('End time must be after start time'));
    return;
  }
  const startTime = startTimeString.value;
  const endTime = endTimeString.value;
  toast.success(`Time changes saved: ${startTime} - ${endTime}`);
  selectedCellInfo.value.hour = editedTime.value.startHour;
  selectedCellInfo.value.hourEnd = editedTime.value.endHour;
  if (selectedTableForSchedule.value) {
    loadTableSchedule(selectedTableForSchedule.value.id);
  }
}
function clearTableSelection() {
  selectedTable.value = '';
  selectedTableInfo.value = null;
  toast.info('Table deselected');
}
async function checkAvailableTables() {
  if (activeMainTab.value !== 'tables') {
    return;
  }
  if (!reservationDate.value || !reservationStartTime.value || !reservationDuration.value || !reservationGuestCount.value || reservationGuestCount.value <= 0) {
    return;
  }
  if (isCheckingInProgress.value) {
    return;
  }
  isCheckingInProgress.value = true;
  checkingAvailability.value = true;
  tableAvailabilityMap.value.clear();
  try {
    await loadTables();
    if (availableTables.value.length === 0) {
      toast.warning('No tables in this branch');
      checkingAvailability.value = false;
      hasCheckedAvailability.value = false;
      return;
    }
    const checkPromises = availableTables.value.map(async (table) => {
      try {
        let normalizedDate = reservationDate.value;
        if (normalizedDate.includes('/')) {
          const parts = normalizedDate.split('/');
          if (parts.length === 3) {
            normalizedDate = `${parts[2]}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`;
          }
        }
        let normalizedTime = reservationStartTime.value;
        if (normalizedTime.includes('AM') || normalizedTime.includes('PM')) {
          const [timePart, period] = normalizedTime.split(' ');
          const [hours, minutes] = timePart.split(':').map(Number);
          let hour24 = hours;
          if (period === 'PM' && hours !== 12) {
            hour24 = hours + 12;
          } else if (period === 'AM' && hours === 12) {
            hour24 = 0;
          }
          normalizedTime = `${hour24.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
        }
        if (normalizedTime.length === 5) {
          normalizedTime = normalizedTime + ':00';
        }
        const availabilityResult = await TableService.checkTableAvailability(
          table.id,
          normalizedDate,
          normalizedTime,
          reservationDuration.value
        );
        const isAvailable = availabilityResult.available === true;
        tableAvailabilityMap.value.set(table.id, isAvailable);
      } catch (error) {
        tableAvailabilityMap.value.set(table.id, false);
      }
    });
    await Promise.all(checkPromises);
    hasCheckedAvailability.value = true;
    const availableCount = Array.from(tableAvailabilityMap.value.values()).filter(v => v).length;
    if (availableCount === 0) {
      toast.warning('No tables available at the selected time');
    } else {
      toast.success(`Found ${availableCount} available tables`);
    }
  } catch (error) {
    showError(error);
    hasCheckedAvailability.value = false;
  } finally {
    checkingAvailability.value = false;
    isCheckingInProgress.value = false;
  }
}
function formatReservationDateTime() {
  if (!reservationDate.value || !reservationStartTime.value || !reservationDuration.value) {
    return '';
  }
  const date = new Date(reservationDate.value);
  const dateStr = date.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' });
  const [startHour, startMinute] = reservationStartTime.value.split(':').map(Number);
  const startTotalMinutes = startHour * 60 + startMinute;
  const endTotalMinutes = startTotalMinutes + reservationDuration.value;
  const endHour = Math.floor(endTotalMinutes / 60);
  const endMinute = endTotalMinutes % 60;
  const endTimeString = `${endHour.toString().padStart(2, '0')}:${endMinute.toString().padStart(2, '0')}`;
  return `${dateStr} from ${reservationStartTime.value} to ${endTimeString}`;
}
function getCurrentBranchId() {
  try {
    const user = AuthService.getUser();
    if (!user) {
      return null;
    }
    const branchId = user.branch_id || null;
    if (!branchId) {
      showError(new Error('You have not been assigned to a branch. Please contact administrator.'));
    }
    return branchId;
  } catch (error) {
    return null;
  }
}
function selectCategoryTab(categoryId) {
  selectedCategoryTab.value = categoryId;
}
async function openProductOptions(product) {
  selectedProduct.value = product;
  selectedSize.value = null;
  selectedToppings.value = [];
  selectedOptions.value = {}; 
  optionQuantity.value = 1;
  productNotes.value = '';
  productOptions.value = [];
  productSizes.value = [];
  productToppings.value = [];
  showProductOptions.value = true;
  try {
    const response = await ProductService.getProductOptions(product.id);
    let options = [];
    if (Array.isArray(response)) {
      options = response;
    } else if (response && Array.isArray(response.data)) {
      options = response.data;
    } else if (response && Array.isArray(response.options)) {
      options = response.options;
    } else {
      options = [];
    }
    if (!Array.isArray(options) || options.length === 0) {
      productOptions.value = [];
      return;
    }
    productOptions.value = options.map((option, index) => {
      let values = [];
      if (option.values && Array.isArray(option.values)) {
        values = option.values;
      } else if (option.value && Array.isArray(option.value)) {
        values = option.value;
      } else {
        }
      const mappedOption = {
        id: option.id,
        name: option.name || 'Tùy chọn',
        type: option.type || 'select', 
        required: option.required || false,
        values: values.map(val => ({
          id: val.id,
          value: val.value || val.label || val.name || '',
          label: val.label || val.value || val.name || '',
          name: val.value || val.label || val.name || '',
          price_modifier: Number(val.price_modifier) || 0
        }))
      };
      return mappedOption;
    }).filter(opt => opt.values && opt.values.length > 0); 
    productOptions.value.forEach(option => {
      if (option.type === 'select') {
        selectedOptions.value[option.id] = []; 
      } else {
        selectedOptions.value[option.id] = []; 
      }
    });
    productSizes.value = [];
    productToppings.value = [];
    productOptions.value.forEach(option => {
      const optionName = (option.name || '').toLowerCase();
      if (optionName.includes('size') || optionName.includes('kích thước')) {
        productSizes.value = option.values.map(val => ({
          id: val.id,
          name: val.value || val.name,
          price: val.price_modifier || 0
        }));
      } else if (option.type === 'checkbox' || optionName.includes('topping') || optionName.includes('thêm')) {
        option.values.forEach(val => {
          productToppings.value.push({
            id: val.id,
            name: val.value || val.name,
            price: val.price_modifier || 0
          });
        });
      }
    });
  } catch (error) {
    showError(error);
    productOptions.value = [];
    productSizes.value = [];
    productToppings.value = [];
  }
  }
function closeProductOptions() {
  showProductOptions.value = false;
  selectedProduct.value = null;
  selectedSize.value = null;
  selectedToppings.value = [];
  selectedOptions.value = {};
  optionQuantity.value = 1;
  productNotes.value = '';
  productOptions.value = [];
}
function selectOptionValue(optionId, valueId, type) {
  if (type === 'select') {
    selectedOptions.value[optionId] = [valueId];
    const option = productOptions.value.find(opt => opt.id === optionId);
    if (option && (option.name.toLowerCase().includes('size') || option.name.toLowerCase().includes('kích thước'))) {
      selectedSize.value = valueId;
    }
  }
}
function toggleOptionValue(optionId, valueId) {
  if (!selectedOptions.value[optionId]) {
    selectedOptions.value[optionId] = [];
  }
  const index = selectedOptions.value[optionId].indexOf(valueId);
  if (index > -1) {
    selectedOptions.value[optionId].splice(index, 1);
    const toppingIndex = selectedToppings.value.indexOf(valueId);
    if (toppingIndex > -1) {
      selectedToppings.value.splice(toppingIndex, 1);
    }
  } else {
    selectedOptions.value[optionId].push(valueId);
    const option = productOptions.value.find(opt => opt.id === optionId);
    if (option && (option.type === 'checkbox' || option.name.toLowerCase().includes('topping') || option.name.toLowerCase().includes('thêm'))) {
      if (!selectedToppings.value.includes(valueId)) {
        selectedToppings.value.push(valueId);
      }
    }
  }
}
function increaseOptionQuantity() {
  optionQuantity.value++;
}
function decreaseOptionQuantity() {
  if (optionQuantity.value > 1) {
    optionQuantity.value--;
  }
}
const selectedSizePrice = computed(() => {
  if (!selectedSize.value) return 0;
  const size = productSizes.value.find(s => s.id === selectedSize.value);
  return Number(size?.price) || 0;
});
const selectedToppingsPrice = computed(() => {
  return selectedToppings.value.reduce((sum, toppingId) => {
    const topping = productToppings.value.find(t => t.id === toppingId);
    return sum + (Number(topping?.price) || 0);
  }, 0);
});
const selectedOptionsPrice = computed(() => {
  let total = 0;
  Object.keys(selectedOptions.value).forEach(optionId => {
    const option = productOptions.value.find(opt => opt.id === parseInt(optionId));
    if (option && selectedOptions.value[optionId]) {
      selectedOptions.value[optionId].forEach(valueId => {
        const value = option.values.find(v => v.id === valueId);
        if (value) {
          total += Number(value.price_modifier) || 0;
        }
      });
    }
  });
  return total;
});
function getOptionPrice(optionId) {
  if (!optionId || !productOptions.value || productOptions.value.length === 0) return 0;
  const option = productOptions.value.find(opt => opt.id === parseInt(optionId));
  if (!option || !selectedOptions.value || !selectedOptions.value[optionId]) return 0;
  if (!Array.isArray(selectedOptions.value[optionId]) || selectedOptions.value[optionId].length === 0) return 0;
  if (!option.values || !Array.isArray(option.values)) return 0;
  return selectedOptions.value[optionId].reduce((sum, valueId) => {
    const value = option.values.find(v => v.id === valueId);
    return sum + (Number(value?.price_modifier) || 0);
  }, 0);
}
const optionTotalPrice = computed(() => {
  if (!selectedProduct.value) return 0;
  const basePrice = Number(selectedProduct.value.price) || 0;
  const optionsPrice = selectedOptionsPrice.value > 0 ? selectedOptionsPrice.value : (selectedSizePrice.value + selectedToppingsPrice.value);
  const total = (basePrice + optionsPrice) * optionQuantity.value;
  return isNaN(total) ? 0 : total;
});
function confirmAddToCart() {
  if (!selectedProduct.value) return;
  if (!canAddToCart.value) {
    toast.warning('Please select a table or fill in delivery information before adding items');
    return;
  }
  const basePrice = Number(selectedProduct.value.price) || 0;
  const optionsPrice = selectedOptionsPrice.value > 0 ? selectedOptionsPrice.value : (selectedSizePrice.value + selectedToppingsPrice.value);
  const itemPrice = basePrice + optionsPrice;
  const optionsKey = JSON.stringify({
    options: selectedOptions.value, 
    size: selectedSize.value, 
    toppings: [...selectedToppings.value].sort(), 
    notes: productNotes.value
  });
  const cartItemKey = `${selectedProduct.value.id}-${optionsKey}`;
  const existingItem = cartItems.value.find(item => item.cartKey === cartItemKey);
  if (existingItem) {
    existingItem.quantity += optionQuantity.value;
  } else { 
    const sizeName = selectedSize.value 
      ? productSizes.value.find(s => s.id === selectedSize.value)?.name || null
      : null;
    const toppingNames = selectedToppings.value
      .map(toppingId => productToppings.value.find(t => t.id === toppingId)?.name)
      .filter(name => name);
    const newItem = {
      id: selectedProduct.value.id,
      cartKey: cartItemKey,
      name: selectedProduct.value.name,
      price: itemPrice,
      image: selectedProduct.value.image || '/images/default-product.png',
      quantity: optionQuantity.value,
      size: selectedSize.value,
      sizeName: sizeName,
      toppings: [...selectedToppings.value],
      toppingNames: toppingNames,
      notes: productNotes.value,
      basePrice: basePrice,
      sizePrice: selectedSizePrice.value,
      toppingsPrice: selectedToppingsPrice.value,
      optionsPrice: optionsPrice,
      selectedOptions: { ...selectedOptions.value } 
    };
    cartItems.value.push(newItem);
  }
  toast.success(`Added ${selectedProduct.value.name} (x${optionQuantity.value}) to cart`);
  closeProductOptions();
}
function addToCart(product) { 
  openProductOptions(product);
}
function increaseQuantity(index) {
  cartItems.value[index].quantity++;
}
function decreaseQuantity(index) {
  if (cartItems.value[index].quantity > 1) {
    cartItems.value[index].quantity--;
  } else {
    removeItem(index);
  }
}
function removeItem(index) {
  cartItems.value.splice(index, 1);
}
function getItemOptionsText(item) {
  const parts = [];
  if (item.sizeName) {
    parts.push(`Size: ${item.sizeName}`);
  }
  if (item.toppingNames && item.toppingNames.length > 0) {
    parts.push(`Topping: ${item.toppingNames.join(', ')}`);
  }
  return parts.length > 0 ? parts.join(' | ') : '';
}
function selectPaymentMethod(methodId) {
  selectedPaymentMethod.value = methodId;
}
async function placeOrder() {
  if (cartItems.value.length === 0) {
    showError(new Error('Please add products to cart'));
    return;
  }
  if (!canAddToCart.value) {
    toast.warning('Please select a table or fill in delivery information before creating order');
    return;
  }
  const branchId = getCurrentBranchId();
  if (!branchId) {
    showError(new Error('Branch not found. Please log in again.'));
    return;
  }
  placingOrder.value = true;
  try {
    const items = cartItems.value.map(item => {
      const specialInstructions = [];
      if (item.sizeName) {
        specialInstructions.push({
          option_name: 'Size',
          selected_values: [item.sizeName]
        });
      }
      if (item.toppingNames && item.toppingNames.length > 0) {
        specialInstructions.push({
          option_name: 'Topping',
          selected_values: item.toppingNames
        });
      }
      if (item.notes) {
        specialInstructions.push({
          option_name: 'Notes',
          selected_values: [item.notes]
        });
      }
      return {
        product_id: item.id,
        quantity: item.quantity,
        price: item.price,
        special_instructions: specialInstructions.length > 0 
          ? JSON.stringify(specialInstructions) 
          : null
      };
    });
    const orderType = hasDeliveryInfo.value ? 'delivery' : 'dine_in';
    let fullDeliveryAddress = null;
    if (hasDeliveryInfo.value) {
      fullDeliveryAddress = deliveryAddressDetail.value.trim();
    }
    const orderData = {
      user_id: null, 
      customer_name: customerName.value || null,
      customer_phone: customerPhone.value || null,
      branch_id: branchId,
      order_type: orderType,
      table_id: hasDeliveryInfo.value ? null : (selectedTable.value || null), 
      delivery_address: fullDeliveryAddress,
      total: total.value,
      subtotal: subtotal.value,
      tax: tax.value,
      discount: discount.value,
      payment_method: selectedPaymentMethod.value || 'cash',
      status: 'preparing', 
      payment_status: 'pending',
      items: items,
      reservation_date: !hasDeliveryInfo.value && selectedTable.value && reservationDate.value ? reservationDate.value : null,
      reservation_time: !hasDeliveryInfo.value && selectedTable.value && reservationStartTime.value ? reservationStartTime.value : null,
      reservation_duration: !hasDeliveryInfo.value && selectedTable.value && reservationDuration.value ? reservationDuration.value : null,
      guest_count: !hasDeliveryInfo.value && selectedTable.value && reservationGuestCount.value ? reservationGuestCount.value : null
    };
    const createdOrder = await OrderService.createOrder(orderData);
    toast.success('Order created successfully');
    emit('order-created', createdOrder);
    cartItems.value = [];
    customerName.value = '';
    customerPhone.value = '';
    selectedTable.value = '';
    selectedTableInfo.value = null;
    selectedPaymentMethod.value = 'cash';
    deliveryAddressDetail.value = '';
    if (activeMainTab.value === 'tables') {
      await loadTables();
      if (reservationDate.value && reservationStartTime.value && reservationDuration.value && reservationGuestCount.value) {
        hasCheckedAvailability.value = false;
        tableAvailabilityMap.value.clear();
        await checkAvailableTables();
      }
    }
  } catch (error) {
    showError(error);
  } finally {
    placingOrder.value = false;
  }
}
function showError(error) {
  let message = error.message || 'An error occurred';
  message = message.replace(/https?:\/\/localhost[^\s]*/gi, '');
  message = message.replace(/localhost[^\s]*/gi, '');
  message = message.replace(/http[^\s]*localhost[^\s]*/gi, '');
  message = message.replace(/Failed to fetch|Network error|fetch failed/gi, 'Connection error');
  message = message.replace(/\s+/g, ' ').trim();
  formattedErrorMessage.value = message || 'An unexpected error occurred';
  showErrorModal.value = true;
}
function closeErrorModal() {
  showErrorModal.value = false;
  formattedErrorMessage.value = '';
}
function showConfirm(message, callback) {
  confirmMessage.value = message;
  confirmCallback.value = callback;
  showConfirmModal.value = true;
}
function handleConfirm() {
  if (confirmCallback.value) {
    confirmCallback.value();
  }
  closeConfirmModal();
}
function closeConfirmModal() {
  showConfirmModal.value = false;
  confirmMessage.value = '';
  confirmCallback.value = null;
}
function formatCurrency(amount) {
  const num = Number(amount) || 0;
  if (isNaN(num)) return '0 ₫';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(num);
}
function formatRating(rating) {
  if (rating >= 1000) {
    return (rating / 1000).toFixed(1) + 'K+';
  }
  return rating.toFixed(1);
}
function handleImageError(event) {
  event.target.src = '/images/default-product.png';
}
function filterProducts() {
}
watch(reservationDate, (newDate) => {
  const today = new Date().toISOString().split('T')[0];
  if (newDate === today) {
    reservationStartTime.value = getCurrentTime();
  }
});
let checkAvailabilityTimeout = null;
watch([reservationDate, reservationStartTime, reservationDuration, reservationGuestCount], () => {
  if (activeMainTab.value !== 'tables') {
    return;
  }
  if (reservationDate.value && reservationStartTime.value && reservationDuration.value && reservationGuestCount.value && reservationGuestCount.value > 0) {
    if (checkAvailabilityTimeout) {
      clearTimeout(checkAvailabilityTimeout);
    }
    checkAvailabilityTimeout = setTimeout(() => {
      checkAvailableTables();
    }, 500);
  } else {
    hasCheckedAvailability.value = false;
    tableAvailabilityMap.value.clear();
  }
}, { immediate: false });
watch(activeMainTab, async (newTab, oldTab) => {
  if (oldTab === undefined) {
    return; 
  }
  if (oldTab === 'tables' && newTab !== 'tables') {
    tablesLoading.value = false;
    checkingAvailability.value = false;
    return; 
  }
  if (newTab === 'tables' && oldTab !== 'tables') {
    if (activeMainTab.value !== 'tables') {
      return; 
    }
    if (availableTables.value.length === 0) {
      if (activeMainTab.value === 'tables') {
        await loadTables();
      }
    }
    if (activeMainTab.value === 'tables' && reservationDate.value && reservationStartTime.value && reservationDuration.value && reservationGuestCount.value && reservationGuestCount.value > 0) {
      await checkAvailableTables();
    }
  }
}, { immediate: false });
onMounted(async () => {
  await loadCategories();
  await loadProducts();
  if (activeMainTab.value === 'tables') {
    await loadTables();
  }
  if (activeMainTab.value === 'tables' && reservationDate.value && reservationStartTime.value && reservationDuration.value && reservationGuestCount.value && reservationGuestCount.value > 0) {
    await checkAvailableTables();
  }
  if (products.value.length === 0) {
    try {
      const data = await ProductService.getProducts({ page: 1, limit: 100 });
      const prods = data.products || data.items || data.data || [];
      if (prods.length > 0) {
        products.value = prods.map(product => ({
          ...product,
          price: Number(product.price) || 0,
          image: product.image || '/images/default-product.png',
          original_price: product.original_price ? Number(product.original_price) : null,
          discount: product.discount || null,
          rating: product.rating || null
        }));
      }
    } catch (error) {
    }
  }
});
</script>
<style scoped>
.create-order-page {
  display: flex;
  background: #F5F7FA;
  position: relative;
  width: 100%;
  max-width: 100vw;
  overflow-x: hidden;
  flex-direction: row;
  box-sizing: border-box;
  max-height: none;
  border: none;
  border-radius: 0;
  margin: 0;
  overflow: visible;
  padding: 0;
}
.create-order-main-content {
  flex: 1;
  padding: 16px;
  margin-left: 0;
  margin-right: 440px;
  overflow-y: auto;
  overflow-x: hidden;
  background: #F5F7FA;
  order: 1;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  box-sizing: border-box;
  width: calc(100% - 440px);
  max-width: calc(100vw - 440px);
}
.main-tabs {
  display: flex;
  gap: 6px;
  margin: 0 0 16px 0;
  background: white;
  padding: 6px;
  border-radius: 10px;
  border: 1px solid #E2E8F0;
  width: 100%;
  max-width: 100%;
  box-sizing: border-box;
  flex-shrink: 0;
}
.main-tab-btn {
  flex: 1;
  padding: 10px 16px;
  background: transparent;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #64748B;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  position: relative;
}
.main-tab-btn:hover {
  background: #F8F9FA;
  color: #475569;
}
.main-tab-btn.active {
  background: #F59E0B;
  color: white;
}
.main-tab-btn i {
  font-size: 16px;
}
.tab-badge {
  background: #FF8C42;
  color: white;
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 700;
  margin-left: 4px;
}
.menu-box {
  background: #FAFBFC;
  border-radius: 10px;
  overflow-y: auto;
  overflow-x: hidden;
  display: flex;
  flex-direction: column;
  margin: 0;
  width: 100%;
  max-width: 100%;
  box-sizing: border-box;
  padding: 16px;
  flex: 1;
  border: 1px solid #E2E8F0;
}
.tables-box {
  background: white;
  border-radius: 10px;
  overflow-y: auto;
  overflow-x: hidden;
  display: flex;
  flex-direction: column;
  margin: 0;
  width: 100%;
  max-width: 100%;
  box-sizing: border-box;
  padding: 16px;
  border: 1px solid #E2E8F0;
  flex: 1;
}
.search-filter-section {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  align-items: center;
}
.search-bar {
  flex: 1;
  position: relative;
}
.search-bar i {
  position: absolute;
  left: 16px;
  top: 50%;
  transform: translateY(-50%);
  color: #9CA3AF;
  font-size: 14px;
  z-index: 1;
}
.search-bar input {
  width: 100%;
  padding: 12px 16px 12px 44px;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  font-size: 14px;
  background: white;
  color: #1F2937;
  transition: all 0.3s ease;
  box-shadow: 
    0 1px 2px rgba(0, 0, 0, 0.02),
    0 2px 4px rgba(0, 0, 0, 0.01);
}
.search-bar input:focus {
  outline: none;
  border-color: #F59E0B;
  box-shadow: 
    0 0 0 3px rgba(245, 158, 11, 0.1),
    0 2px 4px rgba(0, 0, 0, 0.02);
}
.search-bar input::placeholder {
  color: #9CA3AF;
}
.delivery-info-section {
  background: #F0F9FF;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
  border: 2px solid #3B82F6;
}
.delivery-info-section h4 {
  font-size: 16px;
  font-weight: 600;
  color: #1E293B;
  margin: 0 0 12px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}
.delivery-info-section h4 i {
  color: #3B82F6;
  font-size: 18px;
}
.delivery-form-row {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  margin-bottom: 12px;
}
.delivery-form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
  min-width: 200px;
}
.delivery-form-group label {
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  display: flex;
  align-items: center;
  gap: 4px;
}
.delivery-form-group label i {
  font-size: 11px;
  color: #3B82F6;
}
.delivery-form-input,
.delivery-form-select {
  width: 100%;
  padding: 10px 12px;
  border: 2px solid #E2E8F0;
  border-radius: 6px;
  font-size: 13px;
  background: white;
  transition: all 0.3s;
  box-sizing: border-box;
}
.delivery-form-input:focus,
.delivery-form-select:focus {
  outline: none;
  border-color: #3B82F6;
}
.delivery-form-select:disabled {
  background: #F1F5F9;
  cursor: not-allowed;
  color: #94A3B8;
}
.delivery-form-group.full-width {
  flex: 1 1 100%;
  min-width: 100%;
}
.delivery-info-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  background: #DBEAFE;
  border-radius: 6px;
  font-size: 12px;
  color: #1E40AF;
  border-left: 3px solid #3B82F6;
}
.delivery-info-badge i {
  color: #3B82F6;
  font-size: 14px;
}
.delivery-info-section-sidebar {
  border-top: 1px dashed #E2E8F0;
}
.delivery-info-section-sidebar h5 {
  font-size: 13px;
  font-weight: 600;
  color: #1F2937;
  margin: 0 0 12px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}
.delivery-info-section-sidebar h5 i {
  color: #F59E0B;
  font-size: 14px;
}
.delivery-form-group-sidebar {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 10px;
}
.delivery-form-group-sidebar label {
  font-size: 11px;
  font-weight: 600;
  color: #475569;
  display: flex;
  align-items: center;
  gap: 4px;
}
.delivery-form-group-sidebar label i {
  font-size: 10px;
  color: #3B82F6;
}
.delivery-form-row-sidebar-full {
  display: flex;
  gap: 8px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}
.delivery-form-group-sidebar-third {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}
.delivery-form-group-sidebar-third label {
  font-size: 11px;
  font-weight: 600;
  color: #1F2937;
  display: flex;
  align-items: center;
  gap: 5px;
  margin-bottom: 2px;
}
.delivery-form-group-sidebar-third label i {
  font-size: 11px;
  color: #F59E0B;
}
.delivery-form-row-sidebar {
  display: flex;
  gap: 6px; 
  margin-bottom: 8px; 
}
.delivery-form-group-sidebar-half {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 3px; 
  min-width: 0;
}
.delivery-form-group-sidebar-half label {
  font-size: 10px; 
  font-weight: 600;
  color: #475569;
  display: flex;
  align-items: center;
  gap: 4px;
  margin-bottom: 2px;
}
.delivery-form-group-sidebar-half label i {
  font-size: 9px; 
  color: #3B82F6;
}
.delivery-form-input-sidebar,
.delivery-form-select-sidebar {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 6px;
  font-size: 12px;
  background: white;
  color: #1F2937;
  transition: all 0.2s ease;
  box-sizing: border-box;
}
.delivery-form-input-sidebar:focus,
.delivery-form-select-sidebar:focus {
  outline: none;
  border-color: #F59E0B;
}
.delivery-form-select-sidebar:disabled {
  background: #F1F5F9;
  cursor: not-allowed;
  color: #94A3B8;
}
.delivery-info-badge-sidebar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  background: linear-gradient(135deg, #DBEAFE 0%, #BFDBFE 100%);
  border-radius: 10px;
  font-size: 12px;
  font-weight: 600;
  color: #1E40AF;
  border: 1px solid #93C5FD;
  margin-top: 8px;
  box-shadow: 
    0 2px 4px rgba(59, 130, 246, 0.1);
}
.delivery-info-badge-sidebar i {
  color: #3B82F6;
  font-size: 12px;
}
.btn-filter-main {
  padding: 8px 16px;
  background: #FF8C42;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.3s;
  white-space: nowrap;
}
.btn-filter-main:hover {
  background: #E55A2B;
}
.tables-section {
  display: flex;
  flex-direction: column;
  width: 100%;
}
.time-selection-form {
  background: white;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
  border: 1px solid #E2E8F0;
}
.time-selection-form h4 {
  font-size: 16px;
  font-weight: 600;
  color: #1E293B;
  margin: 0 0 16px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}
.time-selection-form h4 i {
  color: #FF8C42;
  font-size: 18px;
}
.time-form-row {
  display: flex;
  gap: 16px;
  align-items: flex-end;
  flex-wrap: wrap;
  margin-bottom: 16px;
}
.time-form-group {
  display: flex;
  flex-direction: column;
  gap: 0;
  flex: 1;
  min-width: 150px;
}
.time-form-label {
  font-size: 13px;
  font-weight: 600;
  color: #1F2937;
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
}
.time-form-label i {
  font-size: 12px;
  color: #F59E0B;
}
.btn-update-time {
  background: none;
  border: none;
  padding: 2px 6px;
  margin-left: 4px;
  cursor: pointer;
  color: #FF8C42;
  font-size: 12px;
  transition: all 0.2s ease;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
}
.btn-update-time:hover {
  background: #FFF9F5;
  color: #E55A2B;
  transform: rotate(180deg);
}
.btn-update-time i {
  font-size: 11px;
}
.time-form-input,
.time-form-select {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  font-size: 14px;
  background: white;
  color: #1F2937;
  transition: all 0.3s ease;
  box-sizing: border-box;
  box-shadow: 
    0 1px 2px rgba(0, 0, 0, 0.02),
    0 2px 4px rgba(0, 0, 0, 0.01);
}
.time-form-input:focus,
.time-form-select:focus {
  outline: none;
  border-color: #F59E0B;
  box-shadow: 
    0 0 0 3px rgba(245, 158, 11, 0.1),
    0 2px 4px rgba(0, 0, 0, 0.02);
}
.btn-check-availability {
  padding: 10px 20px;
  background: #F59E0B;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 8px;
  white-space: nowrap;
  height: fit-content;
}
.btn-check-availability:hover:not(:disabled) {
  background: #D97706;
}
.btn-check-availability:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.time-display-info {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  background: #EFF6FF;
  border-radius: 8px;
  font-size: 13px;
  color: #1E40AF;
  margin-top: 12px;
  border: 1px solid #DBEAFE;
}
.time-display-info i {
  color: #3B82F6;
  font-size: 14px;
}
.time-display-info.checking {
  background: #FFF7ED;
  color: #92400E;
  border-color: #FED7AA;
}
.time-display-info.checking i {
  color: #F59E0B;
}
.tables-filters {
  background: #F8F9FA;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
  border: 1px solid #E2E8F0;
}
.filter-row {
  display: flex;
  gap: 12px;
  align-items: flex-end;
  flex-wrap: wrap;
}
.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
  min-width: 150px;
}
.filter-label {
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  display: flex;
  align-items: center;
  gap: 4px;
}
.filter-label i {
  font-size: 11px;
  color: #FF8C42;
}
.filter-input,
.filter-select {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 6px;
  font-size: 13px;
  background: white;
  transition: all 0.2s ease;
  box-sizing: border-box;
}
.filter-input:focus,
.filter-select:focus {
  outline: none;
  border-color: #F59E0B;
}
.filter-input::placeholder {
  color: #94A3B8;
}
.btn-clear-filters {
  padding: 8px 16px;
  background: #FEE2E2;
  color: #DC2626;
  border: 1px solid #FCA5A5;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
  white-space: nowrap;
  height: fit-content;
}
.btn-clear-filters:hover {
  background: #FEE2E2;
  border-color: #DC2626;
  transform: translateY(-1px);
}
.btn-clear-filters i {
  font-size: 11px;
}
.tables-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding: 16px 16px 12px 16px;
  border-bottom: 2px solid #FF8C42;
  width: 100%;
  box-sizing: border-box;
}
.tables-header h3 {
  font-size: 18px;
  font-weight: 700;
  color: #1E293B;
  margin: 0;
  display: flex;
  align-items: center;
  gap: 8px;
}
.tables-header h3 i {
  color: #F59E0B;
  font-size: 20px;
}
.table-count-badge {
  background: #F59E0B;
  color: white;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
}
.tables-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  color: #64748B;
  width: 100%;
}
.tables-loading i {
  font-size: 32px;
  margin-bottom: 12px;
  color: #FF8C42;
}
.tables-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  text-align: center;
  color: #94A3B8;
  width: 100%;
}
.tables-empty i {
  font-size: 48px;
  margin-bottom: 12px;
  color: #CBD5E1;
}
.tables-empty p {
  font-size: 16px;
  font-weight: 600;
  color: #64748B;
  margin: 0 0 8px 0;
}
.empty-message {
  font-size: 12px;
  color: #94A3B8;
}
.tables-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 20px;
  width: 100%;
  box-sizing: border-box;
  align-items: start;
}
.table-card {
  background: white;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s ease;
  width: 100%;
  box-sizing: border-box;
  min-width: 0;
}
.table-card:hover {
  border-color: #F59E0B;
}
.table-card.selected {
  border-color: #F59E0B;
  background: #FFF7ED;
  border-width: 2px;
}
.table-card.available {
  border-color: rgba(16, 185, 129, 0.3);
}
.table-card.available:hover {
  border-color: #10B981;
}
.table-card.selected.available {
  border-color: #F59E0B;
  background: #FFF7ED;
}
.table-card.status-available {
  border-color: rgba(16, 185, 129, 0.3);
}
.table-card.selected.status-available {
  border-color: #F59E0B;
  background: #FFF7ED;
}
.table-card.status-occupied {
  border-color: rgba(239, 68, 68, 0.3);
}
.table-card.selected.status-occupied {
  border-color: #F59E0B;
  background: #FFF7ED;
}
.table-card.status-reserved {
  border-color: rgba(245, 158, 11, 0.3);
}
.table-card.selected.status-reserved {
  border-color: #F59E0B;
  background: #FFF7ED;
}
.table-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  padding-bottom: 12px;
  border-bottom: 1px solid #F1F5F9;
}
.table-number-large {
  font-size: 22px;
  font-weight: 700;
  color: #1E293B;
  letter-spacing: -0.3px;
}
.table-card.selected .table-number-large {
  color: #D97706;
}
.table-status-badge {
  font-size: 10px;
  font-weight: 600;
  padding: 4px 8px;
  border-radius: 4px;
  text-transform: uppercase;
}
.table-status-badge.status-available {
  background: #D1FAE5;
  color: #059669;
}
.table-status-badge.status-occupied {
  background: #FEE2E2;
  color: #DC2626;
}
.table-status-badge.status-reserved {
  background: #FEF3C7;
  color: #D97706;
}
.table-card-body {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.table-info-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #64748B;
}
.table-info-item i {
  width: 14px;
  color: #94A3B8;
  font-size: 12px;
}
.btn-remove-table {
  padding: 6px 12px;
  background: white;
  color: #DC2626;
  border: 1px solid #FECACA;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  text-transform: uppercase;
  line-height: 1;
  display: inline-block;
}
.btn-remove-table:hover {
  background: #FEE2E2;
  border-color: #FCA5A5;
}
.btn-remove-table-small {
  padding: 4px 6px;
  background: #FEE2E2;
  color: #DC2626;
  border: none;
  border-radius: 4px;
  font-size: 11px;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  flex-shrink: 0;
}
.btn-remove-table-small:hover {
  background: #FECACA;
}
.btn-remove-table-small i {
  font-size: 11px;
}
.categories-horizontal {
  margin-bottom: 24px;
}
.section-title {
  font-size: 18px;
  font-weight: 600;
  color: #333;
  margin: 0 0 16px 0;
}
.categories-scroll {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding-bottom: 8px;
  scrollbar-width: thin;
  scrollbar-color: #FF8C42 #F5F7FA;
}
.categories-scroll::-webkit-scrollbar {
  height: 6px;
}
.categories-scroll::-webkit-scrollbar-track {
  background: #F5F7FA;
  border-radius: 3px;
}
.categories-scroll::-webkit-scrollbar-thumb {
  background: #FF8C42;
  border-radius: 3px;
}
.category-btn-horizontal {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 16px 24px;
  border: 2px solid #E2E8F0;
  background: white;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s;
  min-width: 100px;
  white-space: nowrap;
}
.category-btn-horizontal:hover {
  border-color: #FF8C42;
  background: #FFF5F2;
}
.category-btn-horizontal.active {
  border-color: #FF8C42;
  background: #FF8C42;
  color: white;
}
.category-btn-horizontal i {
  font-size: 24px;
  color: #FF8C42;
}
.category-btn-horizontal.active i {
  color: white;
}
.category-btn-horizontal span {
  font-size: 14px;
  font-weight: 500;
}
.content-header {
  margin-bottom: 20px;
}
.tabs {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  scrollbar-width: none; 
  -ms-overflow-style: none; 
  padding: 4px;
  background: #F8F9FA;
  border-radius: 12px;
}
.tabs::-webkit-scrollbar {
  display: none; 
}
.tab-btn {
  padding: 10px 20px;
  border: none;
  background: white;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  color: #64748B;
  border-radius: 8px;
  transition: all 0.3s ease;
  white-space: nowrap;
  flex-shrink: 0;
  box-shadow: 
    0 1px 2px rgba(0, 0, 0, 0.02);
  position: relative;
}
.tab-btn:hover {
  color: #F59E0B;
  background: #FFF7ED;
  transform: translateY(-1px);
  box-shadow: 
    0 2px 4px rgba(0, 0, 0, 0.04);
}
.tab-btn.active {
  color: white;
  background: #F59E0B;
  font-weight: 600;
  box-shadow: 
    0 2px 8px rgba(245, 158, 11, 0.3),
    0 4px 12px rgba(245, 158, 11, 0.15);
}
.tab-btn.active:hover {
  background: #D97706;
  transform: translateY(-1px);
}
.products-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}
.product-card {
  background: white;
  border-radius: 20px;
  padding: 20px;
  display: flex;
  align-items: flex-start;
  gap: 16px;
  box-shadow: 
    0 2px 4px rgba(0, 0, 0, 0.02),
    0 8px 16px rgba(0, 0, 0, 0.03);
  border: 1px solid rgba(0, 0, 0, 0.04);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
  cursor: pointer;
}
.product-card::after {
  content: '';
  position: absolute;
  top: -50%;
  right: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, rgba(245, 158, 11, 0.05) 0%, transparent 70%);
  opacity: 0;
  transition: opacity 0.3s ease;
}
.product-card:hover {
  border-color: #F59E0B;
  box-shadow: 
    0 4px 8px rgba(0, 0, 0, 0.04),
    0 12px 24px rgba(0, 0, 0, 0.06);
  transform: translateY(-2px);
}
.product-card:hover::after {
  opacity: 1;
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
}
.product-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}
.product-card:hover .product-image {
  transform: scale(1.05);
}
.product-badge {
  position: absolute;
  top: 4px;
  right: 4px;
  background: #F59E0B;
  color: white;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 700;
  z-index: 1;
  box-shadow: 0 2px 4px rgba(245, 158, 11, 0.3);
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
  background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%);
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
.btn-add-product {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 8px 20px;
  min-width: 100px;
  background: #F59E0B;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}
.btn-add-product:hover {
  background: #D97706;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(245, 158, 11, 0.3);
}
.btn-add-product:active {
  transform: translateY(0);
}
.btn-add-product i {
  font-size: 12px;
}
.product-actions {
  display: flex;
  gap: 6px;
  padding: 0 10px 10px;
}
.btn-order {
  width: 100%;
  padding: 6px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 11px;
  transition: all 0.3s;
  background: #FF8C42;
  color: white;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}
.btn-order:hover {
  background: #E55A2B;
}
.sidebar-right {
  background: white;
  border-left: 1px solid #E2E8F0;
  display: flex;
  flex-direction: column;
  height: 100vh;
  position: fixed;
  right: 0;
  top: 0;
  overflow-y: auto;
  overflow-x: hidden;
  width: 420px;
  flex-shrink: 0;
  z-index: 1001;
  order: 2;
  box-shadow: -2px 0 8px rgba(0, 0, 0, 0.04);
}
.order-info-section {
  padding: 16px;
  background: white;
  border-bottom: 1px solid #E2E8F0;
  flex-shrink: 0;
}
.order-info-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding: 10px 14px;
  background: #FFF7ED;
  border: 1px solid #FED7AA;
  border-radius: 8px;
}
.order-info-header h4 {
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
  margin: 0;
  display: flex;
  align-items: center;
  gap: 8px;
  letter-spacing: -0.1px;
}
.order-info-header h4 i {
  color: #F59E0B;
  font-size: 15px;
}
.item-count-badge {
  background: #F59E0B;
  color: white;
  padding: 4px 10px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 700;
}
.info-compact {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.info-row {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.info-row label {
  font-size: 11px;
  font-weight: 600;
  color: #1F2937;
  display: flex;
  align-items: center;
  gap: 5px;
}
.info-row label i {
  color: #F59E0B;
  font-size: 11px;
}
.info-row-inline {
  display: flex;
  gap: 8px;
  margin-bottom: 8px;
}
.info-row-half {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}
.info-row-half label {
  font-size: 11px;
  font-weight: 600;
  color: #1F2937;
  display: flex;
  align-items: center;
  gap: 5px;
  margin-bottom: 2px;
}
.info-row-half label i {
  color: #F59E0B;
  font-size: 11px;
}
.form-select-compact,
.form-input-compact {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 6px;
  font-size: 12px;
  background: white;
  color: #1F2937;
  transition: all 0.2s ease;
}
.form-select-compact:focus,
.form-input-compact:focus {
  outline: none;
  border-color: #F59E0B;
}
.input-with-loader {
  position: relative;
  width: 100%;
}
.search-loader {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #F59E0B;
  font-size: 12px;
}
.table-row {
  margin-top: 6px;
}
.table-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background: #FFF7ED;
  border: 1px solid #FED7AA;
  border-radius: 8px;
}
.table-badge i {
  color: #F59E0B;
  font-size: 16px;
}
.table-badge > span:first-of-type {
  font-weight: 700;
  color: #D97706;
  font-size: 13px;
}
.table-details {
  font-size: 11px;
  color: #64748B;
  margin-left: auto;
  font-weight: 500;
}
.btn-remove-table-inline {
  background: white;
  color: #DC2626;
  border: 1px solid #FECACA;
  border-radius: 6px;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
  flex-shrink: 0;
  margin-left: 8px;
}
.btn-remove-table-inline:hover {
  background: #FEE2E2;
  border-color: #FCA5A5;
}
.btn-remove-table-inline i {
  font-size: 10px;
}
.table-section-top {
  padding: 12px;
  border-bottom: 1px solid #E2E8F0;
  background: #FFF7ED;
  flex-shrink: 0;
  min-height: fit-content;
  border-left: 3px solid #F59E0B;
}
.table-section-top h5 {
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  margin: 0 0 10px 0;
  display: flex;
  align-items: center;
  gap: 6px;
}
.table-section-top h5 i {
  color: #FF8C42;
  font-size: 14px;
}
.table-count {
  font-size: 11px;
  font-weight: normal;
  color: #64748B;
}
.table-section-top .form-select {
  width: 100%;
  margin-bottom: 8px;
  border: 1px solid #FF8C42;
  background: white;
}
.table-section-top .form-select:focus {
  border-color: #FF8C42;
}
.table-section-top .form-select:disabled {
  background: #F3F4F6;
  border-color: #E2E8F0;
  color: #94A3B8;
  cursor: not-allowed;
}
.no-tables-message {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px;
  background: #FEF3C7;
  border: 1px solid #FCD34D;
  border-radius: 6px;
  font-size: 12px;
  color: #D97706;
  margin-top: 8px;
}
.no-tables-message i {
  font-size: 14px;
  color: #D97706;
}
.table-section-top .loading-text {
  font-size: 11px;
  color: #64748B;
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 4px;
}
.table-section-top .loading-text i {
  font-size: 11px;
}
.selected-table-info {
  margin-top: 8px;
}
.table-info-card {
  background: white;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  padding: 10px;
  margin-top: 8px;
}
.table-info-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  padding-bottom: 8px;
  border-bottom: 1px solid #E2E8F0;
}
.table-info-header i {
  color: #FF8C42;
  font-size: 16px;
}
.table-info-header .table-number {
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
}
.table-info-body {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 8px;
}
.table-info-details {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.table-info-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #64748B;
}
.table-info-row i {
  width: 14px;
  color: #94A3B8;
  font-size: 12px;
}
.table-status {
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
}
.table-status.status-available {
  background: #D1FAE5;
  color: #059669;
}
.table-status.status-occupied {
  background: #FEE2E2;
  color: #DC2626;
}
.table-status.status-reserved {
  background: #FEF3C7;
  color: #D97706;
}
.table-status.status-maintenance {
  background: #F3F4F6;
  color: #6B7280;
}
.cart-section {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  min-height: 0;
  padding: 0;
  background: white;
}
.cart-section::-webkit-scrollbar {
  width: 6px;
}
.cart-section::-webkit-scrollbar-track {
  background: transparent;
}
.cart-section::-webkit-scrollbar-thumb {
  background: #E2E8F0;
  border-radius: 3px;
}
.cart-section::-webkit-scrollbar-thumb:hover {
  background: #CBD5E1;
}
.empty-cart {
  text-align: center;
  padding: 60px 20px;
  color: #94A3B8;
}
.empty-cart i {
  font-size: 48px;
  margin-bottom: 16px;
  opacity: 0.4;
  color: #CBD5E1;
}
.empty-cart p {
  font-size: 14px;
  font-weight: 500;
  color: #64748B;
  margin: 0;
}
.cart-items {
  display: flex;
  flex-direction: column;
  gap: 12px;
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  min-height: 0;
  max-height: 100%;
  padding: 20px;
  padding-right: 12px;
}
.cart-items::-webkit-scrollbar {
  width: 6px;
}
.cart-items::-webkit-scrollbar-track {
  background: transparent;
}
.cart-items::-webkit-scrollbar-thumb {
  background: #E2E8F0;
  border-radius: 3px;
}
.cart-items::-webkit-scrollbar-thumb:hover {
  background: #CBD5E1;
}
.cart-item {
  display: flex;
  gap: 12px;
  padding: 12px;
  background: white;
  border-radius: 8px;
  border: 1px solid #E2E8F0;
  min-height: 80px;
  flex-shrink: 0;
  transition: all 0.2s ease;
}
.cart-item:hover {
  border-color: #F59E0B;
}
.item-image {
  width: 56px;
  height: 56px;
  border-radius: 8px;
  overflow: hidden;
  flex-shrink: 0;
  background: #FFF7ED;
  border: 1px solid #FED7AA;
}
.item-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.item-details {
  flex: 1;
  min-width: 0;
}
.item-name {
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
  margin: 0 0 6px 0;
  line-height: 1.4;
  word-wrap: break-word;
  overflow-wrap: break-word;
}
.item-options {
  font-size: 11px;
  color: #64748B;
  margin: 0 0 4px 0;
  line-height: 1.3;
  word-wrap: break-word;
  overflow-wrap: break-word;
  white-space: normal;
  padding: 4px 8px;
  background: #F1F5F9;
  border-radius: 6px;
  display: inline-block;
}
.item-notes {
  font-size: 11px;
  color: #64748B;
  margin: 4px 0 8px 0;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
  background: #FEF3C7;
  border-radius: 6px;
  border: 1px solid #FDE68A;
}
.item-notes i {
  font-size: 10px;
  color: #F59E0B;
}
.item-controls {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
  padding: 6px;
  background: #FAFBFC;
  border-radius: 8px;
  border: 1px solid #E2E8F0;
  width: fit-content;
}
.btn-quantity {
  width: 24px;
  height: 24px;
  border: 1px solid #E2E8F0;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748B;
  font-size: 11px;
  transition: all 0.2s ease;
}
.btn-quantity:hover {
  background: #FFF7ED;
  border-color: #F59E0B;
  color: #F59E0B;
}
.quantity {
  min-width: 24px;
  text-align: center;
  font-weight: 700;
  font-size: 13px;
  color: #1E293B;
}
.item-price {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
  justify-content: space-between;
}
.item-price span {
  font-weight: 700;
  color: #F59E0B;
  font-size: 14px;
}
.btn-remove {
  background: #FEE2E2;
  border: 1px solid #FECACA;
  color: #DC2626;
  cursor: pointer;
  padding: 6px;
  font-size: 11px;
  border-radius: 6px;
  transition: all 0.2s ease;
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.btn-remove:hover {
  background: #FECACA;
}
.payment-section-sticky {
  padding: 16px;
  background: white;
  border-top: 1px solid #E2E8F0;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.payment-summary-compact {
  padding: 12px;
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  margin-bottom: 0;
}
.summary-row-compact {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
  font-size: 12px;
  color: #64748B;
}
.summary-row-compact:last-child {
  margin-bottom: 0;
}
.summary-row-compact.total-row {
  margin-top: 6px;
  padding-top: 6px;
  border-top: 2px solid #E2E8F0;
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
}
.summary-row-compact.discount {
  color: #059669;
  font-weight: 500;
}
.total-label {
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
}
.total-amount {
  font-size: 18px;
  font-weight: 700;
  color: #F59E0B;
}
.payment-methods-section {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.methods-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
}
.method-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 6px;
  border: 2px solid #E2E8F0;
  background: white;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  min-height: 36px;
  min-width: 0;
  width: 100%;
}
.method-btn:hover {
  border-color: #F59E0B;
  background: #FFF7ED;
}
.method-btn.active {
  border-color: #F59E0B;
  background: #FFF7ED;
}
.method-btn i {
  font-size: 15px;
  color: #64748B;
}
.method-btn.active i {
  color: #F59E0B;
}
.customer-section {
  margin-bottom: 10px;
}
.customer-section h5 {
  font-size: 12px;
  color: #666;
  margin: 0 0 8px 0;
}
.form-select,
.form-input {
  width: 100%;
  padding: 6px 10px;
  border: 1px solid #E2E8F0;
  border-radius: 6px;
  font-size: 12px;
  margin-bottom: 6px;
}
.btn-place-order-main {
  width: 100%;
  padding: 14px 20px;
  background: #F59E0B;
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-top: 0;
  box-shadow: 
    0 4px 12px rgba(245, 158, 11, 0.3),
    0 2px 4px rgba(245, 158, 11, 0.2);
}
.btn-place-order-main:hover:not(:disabled) {
  background: #D97706;
  transform: translateY(-2px);
  box-shadow: 
    0 6px 16px rgba(245, 158, 11, 0.4),
    0 4px 8px rgba(245, 158, 11, 0.3);
}
.btn-place-order-main:active:not(:disabled) {
  background: #B45309;
  transform: translateY(0);
}
.btn-place-order-main:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
  background: #F59E0B;
}
.btn-order-content {
  display: flex;
  align-items: center;
  gap: 10px;
  flex: 1;
}
.btn-place-order-main i {
  font-size: 18px;
}
.btn-order-text {
  font-size: 15px;
  font-weight: 700;
  letter-spacing: 0.2px;
}
.order-total {
  font-size: 16px;
  font-weight: 700;
  background: rgba(255, 255, 255, 0.2);
  padding: 6px 12px;
  border-radius: 6px;
}
.loading-state,
.empty-state {
  text-align: center;
  padding: 40px 12px;
  color: #999;
}
.loading-state i {
  font-size: 36px;
  margin-bottom: 12px;
  color: #F59E0B;
}
.empty-state i {
  font-size: 36px;
  margin-bottom: 12px;
  opacity: 0.5;
}
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10000;
  padding: 20px;
  overflow-y: auto;
}
.product-options-modal {
  background: white;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15);
  max-width: 550px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.product-options-modal .modal-body {
  padding: 24px;
}
.error-modal {
  max-width: 480px;
  width: 100%;
}
.error-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  text-align: center;
}
.error-icon {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: #FEE2E2;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #DC2626;
  font-size: 32px;
}
.error-message {
  font-size: 14px;
  color: #1E293B;
  line-height: 1.6;
  margin: 0;
}
.confirm-modal {
  max-width: 480px;
  width: 100%;
}
.confirm-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  text-align: center;
}
.confirm-icon {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: #DBEAFE;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #2563EB;
  font-size: 32px;
}
.confirm-message {
  font-size: 14px;
  color: #1E293B;
  line-height: 1.6;
  margin: 0;
}
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  background: #FFF7ED;
  border-bottom: 1px solid #FED7AA;
  flex-shrink: 0;
}
.modal-header-content {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}
.modal-header-image {
  width: 48px;
  height: 48px;
  border-radius: 6px;
  overflow: hidden;
  flex-shrink: 0;
  background: #F8F9FA;
}
.modal-header-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.modal-header h3 {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
  color: #1a1a1a;
  letter-spacing: -0.2px;
}
.modal-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #64748B;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}
.modal-close:hover {
  color: #1E293B;
}
.modal-content {
  background: white;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15);
  display: flex;
  flex-direction: column;
  max-height: 90vh;
  overflow: hidden;
}
.modal-content.large {
  max-width: 700px;
  width: 100%;
  max-height: 90vh;
}
.modal-content.small {
  max-width: 400px;
  width: 100%;
  max-height: 85vh;
}
.modal-content.small .modal-header {
  padding: 10px 12px;
}
.modal-content.small .modal-header h3 {
  font-size: 14px;
}
.modal-content.small .modal-body {
  padding: 8px 10px;
  max-height: calc(85vh - 120px);
  overflow-y: auto;
}
.modal-content.small .modal-footer {
  padding: 8px 12px;
  gap: 6px;
}
.modal-content.small .modal-footer .btn {
  padding: 6px 12px;
  font-size: 12px;
}
.modal-body {
  padding: 24px;
  overflow-y: auto;
  overflow-x: visible;
  flex: 1;
  min-height: 0;
  max-height: calc(90vh - 150px);
  background: white;
}
.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 16px 20px;
  background: #FAFAFA;
  border-top: 1px solid #FED7AA;
}
.schedule-controls {
  margin-bottom: 8px;
  padding: 10px;
  background: #F8F9FA;
  border-radius: 6px;
}
.date-range-selector {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}
.date-range-selector label {
  font-size: 11px;
  font-weight: 500;
  color: #333;
  white-space: nowrap;
}
.date-range-selector .form-input {
  width: auto;
  min-width: 110px;
  margin-bottom: 0;
  padding: 4px 6px;
  font-size: 11px;
}
.operating-hours-info {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 10px;
  color: #666;
  margin-left: auto;
  white-space: nowrap;
}
.operating-hours-info i {
  color: #FF8C42;
}
.schedule-loading,
.schedule-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
}
.schedule-loading i,
.schedule-empty i {
  font-size: 48px;
  color: #999;
  margin-bottom: 16px;
}
.schedule-loading p,
.schedule-empty p {
  font-size: 18px;
  font-weight: 600;
  color: #333;
  margin: 0 0 8px 0;
}
.schedule-empty .empty-message {
  font-size: 14px;
  color: #666;
}
.schedule-table-wrapper {
  overflow-x: auto;
  max-height: 500px;
  overflow-y: auto;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
}
.schedule-table {
  width: 100%;
  border-collapse: collapse;
  background: white;
}
.schedule-table thead {
  background: #F8F9FA;
  position: sticky;
  top: 0;
  z-index: 10;
}
.schedule-table th {
  padding: 12px;
  text-align: left;
  font-weight: 600;
  font-size: 13px;
  color: #333;
  border-bottom: 2px solid #E2E8F0;
  white-space: nowrap;
}
.schedule-table td {
  padding: 12px;
  font-size: 13px;
  color: #666;
  border-bottom: 1px solid #F0F0F0;
}
.schedule-table tbody tr:hover {
  background: #F8F9FA;
}
.schedule-table .status-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  display: inline-block;
}
.schedule-table .status-pending {
  background: #FEF3C7;
  color: #D97706;
}
.schedule-table .status-confirmed {
  background: #D1ECF1;
  color: #0C5460;
}
.schedule-table .status-checked-in {
  background: #D4EDDA;
  color: #155724;
}
.schedule-table .status-completed {
  background: #D1FAE5;
  color: #059669;
}
.schedule-table .status-cancelled {
  background: #FEE2E2;
  color: #DC2626;
}
.modal-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #64748B;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}
.modal-close:hover {
  color: #1E293B;
}
.product-options-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.no-options-message {
  padding: 20px;
  text-align: center;
  color: #64748B;
  background: #F8F9FA;
  border-radius: 10px;
  border: 1px solid #E2E8F0;
}
.no-options-message i {
  font-size: 24px;
  color: #94A3B8;
  margin-bottom: 8px;
  display: block;
}
.no-options-message p {
  margin: 0;
  font-size: 13px;
}
.option-card {
  margin-bottom: 16px;
}
.option-card:last-child {
  margin-bottom: 0;
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
  display: flex;
  align-items: center;
  gap: 4px;
}
.card-content {
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.required-asterisk {
  color: #DC2626;
  font-weight: 700;
  margin-left: 4px;
}
.options-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
  gap: 10px;
}
.option-btn-select {
  padding: 12px 14px;
  border: 2px solid #E2E8F0;
  background: white;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
  min-height: 70px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.option-btn-select:hover {
  border-color: #F59E0B;
  background: #FFF7ED;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(245, 158, 11, 0.1);
}
.option-btn-select.active {
  border-color: #F59E0B;
  background: linear-gradient(135deg, #FFF7ED 0%, #FEF3C7 100%);
  border-width: 2px;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1), 0 2px 8px rgba(245, 158, 11, 0.15);
}
.option-btn-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  width: 100%;
}
.option-name-wrapper {
  display: flex;
  align-items: center;
  gap: 6px;
  justify-content: center;
}
.option-name {
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  text-align: center;
  line-height: 1.4;
}
.option-btn-select.active .option-name {
  color: #D97706;
  font-weight: 700;
}
.option-check-icon {
  color: #F59E0B;
  font-size: 16px;
  animation: checkIn 0.3s ease;
}
@keyframes checkIn {
  0% {
    transform: scale(0);
    opacity: 0;
  }
  50% {
    transform: scale(1.2);
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}
.option-price {
  font-size: 11px;
  color: #64748B;
  font-weight: 600;
  padding: 2px 6px;
  background: #F1F5F9;
  border-radius: 4px;
  white-space: nowrap;
}
.option-btn-select.active .option-price {
  color: #D97706;
  background: rgba(245, 158, 11, 0.15);
}
.options-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.option-checkbox-custom {
  display: flex;
  align-items: center;
  padding: 12px 14px;
  border: 2px solid #E2E8F0;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: white;
  gap: 12px;
}
.option-checkbox-custom:hover {
  border-color: #F59E0B;
  background: #FFF7ED;
  transform: translateX(2px);
}
.option-checkbox-custom.checked {
  border-color: #F59E0B;
  background: linear-gradient(135deg, #FFF7ED 0%, #FEF3C7 100%);
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1);
}
.custom-checkbox-wrapper {
  position: relative;
  flex-shrink: 0;
}
.custom-checkbox-input {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
  margin: 0;
  cursor: pointer;
}
.custom-checkbox {
  width: 22px;
  height: 22px;
  border: 2px solid #CBD5E1;
  border-radius: 6px;
  background: white;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  position: relative;
}
.custom-checkbox i {
  font-size: 12px;
  color: white;
  opacity: 0;
  transform: scale(0);
  transition: all 0.2s ease;
}
.option-checkbox-custom.checked .custom-checkbox {
  background: #F59E0B;
  border-color: #F59E0B;
  box-shadow: 0 2px 4px rgba(245, 158, 11, 0.3);
}
.option-checkbox-custom.checked .custom-checkbox i {
  opacity: 1;
  transform: scale(1);
  animation: checkIn 0.2s ease;
}
.checkbox-label {
  flex: 1;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}
.checkbox-name {
  font-size: 13px;
  font-weight: 600;
  color: #1E293B;
  flex: 1;
}
.option-checkbox-custom.checked .checkbox-name {
  color: #D97706;
  font-weight: 700;
}
.option-checkbox-custom .option-price {
  font-size: 11px;
  color: #64748B;
  font-weight: 600;
  padding: 2px 6px;
  background: #F1F5F9;
  border-radius: 4px;
  white-space: nowrap;
}
.option-checkbox-custom.checked .option-price {
  color: #D97706;
  background: rgba(245, 158, 11, 0.15);
}
.quantity-selector {
  display: flex;
  align-items: center;
  gap: 12px;
  justify-content: center;
  background: #FAFBFC;
  padding: 8px;
  border-radius: 10px;
  border: 1px solid #E2E8F0;
}
.qty-btn {
  width: 32px;
  height: 32px;
  border: 1px solid #E2E8F0;
  background: white;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748B;
  transition: all 0.2s ease;
  font-size: 14px;
}
.qty-btn:hover {
  border-color: #F59E0B;
  background: #FFF7ED;
  color: #F59E0B;
}
.qty-btn:active {
  transform: scale(0.95);
}
.qty-value {
  font-size: 15px;
  font-weight: 700;
  min-width: 30px;
  text-align: center;
  color: #1E293B;
}
.notes-input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 13px;
  font-family: inherit;
  resize: vertical;
  background: white;
  color: #1E293B;
  transition: all 0.2s ease;
}
.notes-input:focus {
  outline: none;
  border-color: #F59E0B;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1);
}
.option-price-summary {
  background: #FAFBFC;
  padding: 14px 16px;
  border-radius: 10px;
  border: 1px solid #E2E8F0;
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 8px;
}
.price-row {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  color: #64748B;
  padding: 4px 0;
}
.price-row.total {
  font-size: 16px;
  font-weight: 700;
  color: #1E293B;
  border-top: 1px solid #E2E8F0;
  padding-top: 10px;
  margin-top: 6px;
}
.product-options-modal .modal-footer {
  display: flex;
  gap: 10px;
  padding: 16px 20px;
  background: #FAFAFA;
  border-top: 1px solid #FED7AA;
  flex-shrink: 0;
}
.btn-cancel,
.btn-add-to-cart {
  flex: 1;
  padding: 12px 20px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition: all 0.2s ease;
}
.btn-cancel {
  background: white;
  color: #64748B;
  border: 1px solid #E2E8F0;
}
.btn-cancel:hover {
  background: #F8F9FA;
  border-color: #CBD5E1;
  color: #475569;
}
.btn-add-to-cart {
  background: #F59E0B;
  color: white;
}
.btn-add-to-cart:hover {
  background: #D97706;
}
.schedule-chart-wrapper {
  margin-top: 10px;
  width: fit-content;
  max-width: 100%;
}
.schedule-chart {
  display: grid;
  grid-template-columns: 70px 1fr;
  grid-template-rows: 25px 1fr;
  gap: 0;
  border: 1px solid #E2E8F0;
  border-radius: 6px;
  overflow: hidden;
  background: white;
  max-height: calc(90vh - 280px);
  height: fit-content;
  width: fit-content;
  min-width: fit-content;
}
.chart-y-axis {
  grid-column: 1;
  grid-row: 2;
  display: grid;
  grid-template-rows: repeat(var(--dates-count, 7), 1fr);
  background: #F8F9FA;
  border-right: 2px solid #E2E8F0;
  padding: 2px 6px;
  overflow: visible;
}
.y-axis-label {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  font-size: 9px;
  color: #666;
  font-weight: 500;
  padding: 2px 4px;
  border-bottom: 1px solid #F0F0F0;
  min-height: 40px;
  flex-shrink: 0;
}
.chart-grid {
  grid-column: 2;
  grid-row: 2;
  display: flex;
  flex-direction: column;
  overflow-x: auto;
  overflow-y: visible;
  max-height: none;
  width: fit-content;
  min-width: fit-content;
}
.chart-x-axis {
  display: flex;
  background: #F8F9FA;
  border-bottom: 2px solid #E2E8F0;
  position: sticky;
  top: 0;
  z-index: 5;
}
.x-axis-label {
  min-width: 70px;
  padding: 4px 6px;
  text-align: center;
  font-size: 8px;
  font-weight: 600;
  color: #333;
  border-right: 1px solid #E2E8F0;
  flex-shrink: 0;
}
.chart-cells {
  display: grid;
  grid-template-rows: repeat(var(--dates-count, 7), 1fr);
  flex: 1;
}
.chart-row {
  display: flex;
  border-bottom: 1px solid #F0F0F0;
  flex-shrink: 0;
}
.chart-cell {
  min-width: 70px;
  height: 100%;
  border-right: 1px solid #F0F0F0;
  position: relative;
  padding: 1px;
  background: white;
  transition: background 0.2s;
  cursor: pointer;
  flex-shrink: 0;
}
.chart-cell:hover {
  background: #F0F7FF;
  border: 1px solid #B3D9FF;
}
.chart-cell.has-reservation {
  background: #FFF5F5;
}
.chart-cell-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  opacity: 0.3;
}
.empty-indicator {
  font-size: 8px;
  color: #999;
  font-style: italic;
}
.reservation-block {
  position: absolute;
  top: 1px;
  left: 1px;
  right: 1px;
  min-height: 24px;
  padding: 2px 4px;
  border-radius: 3px;
  font-size: 8px;
  cursor: pointer;
  z-index: 10;
  display: flex;
  flex-direction: column;
  gap: 1px;
  overflow: hidden;
}
.reservation-block.status-pending {
  background: #FEF3C7;
  border-left: 3px solid #D97706;
  color: #92400E;
}
.reservation-block.status-confirmed {
  background: #D1ECF1;
  border-left: 3px solid #0C5460;
  color: #0C5460;
}
.reservation-block.status-checked-in {
  background: #D4EDDA;
  border-left: 3px solid #155724;
  color: #155724;
}
.reservation-block.status-completed {
  background: #D1FAE5;
  border-left: 3px solid #059669;
  color: #059669;
}
.reservation-block.status-cancelled {
  background: #FEE2E2;
  border-left: 3px solid #DC2626;
  color: #DC2626;
  opacity: 0.6;
}
.reservation-time {
  font-weight: 600;
  font-size: 9px;
  line-height: 1.2;
}
.reservation-customer {
  font-size: 8px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.1;
}
.reservation-guests {
  font-size: 7px;
  opacity: 0.8;
  line-height: 1;
}
.schedule-legend {
  display: flex;
  gap: 10px;
  margin-top: 8px;
  padding: 6px;
  background: #F8F9FA;
  border-radius: 4px;
  flex-wrap: wrap;
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 9px;
  color: #333;
}
.legend-color {
  width: 10px;
  height: 10px;
  border-radius: 2px;
  border-left: 2px solid;
}
.legend-color.status-pending {
  background: #FEF3C7;
  border-color: #D97706;
}
.legend-color.status-confirmed {
  background: #D1ECF1;
  border-color: #0C5460;
}
.legend-color.status-checked-in {
  background: #D4EDDA;
  border-color: #155724;
}
.legend-color.status-completed {
  background: #D1FAE5;
  border-color: #059669;
}
.cell-info {
  padding: 5px 0;
}
.info-section {
  margin-bottom: 12px;
  padding: 8px 10px;
  background: #F8F9FA;
  border-radius: 6px;
}
.info-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 6px;
  font-size: 12px;
}
.info-item:last-child {
  margin-bottom: 0;
}
.info-item label {
  font-weight: 600;
  color: #333;
}
.info-item span {
  color: #666;
}
.reservations-list {
  margin-top: 12px;
}
.reservations-list h4 {
  font-size: 13px;
  font-weight: 600;
  color: #333;
  margin-bottom: 8px;
}
.reservation-item {
  padding: 8px 10px;
  margin-bottom: 8px;
  border-radius: 6px;
  border-left: 3px solid;
  background: #F8F9FA;
}
.reservation-item.status-pending {
  border-color: #D97706;
  background: #FEF3C7;
}
.reservation-item.status-confirmed {
  border-color: #0C5460;
  background: #D1ECF1;
}
.reservation-item.status-checked-in {
  border-color: #155724;
  background: #D4EDDA;
}
.reservation-item.status-completed {
  border-color: #059669;
  background: #D1FAE5;
}
.reservation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}
.reservation-header .reservation-time {
  font-weight: 600;
  font-size: 12px;
  color: #333;
}
.reservation-details {
  font-size: 11px;
  color: #666;
}
.reservation-details div {
  margin-bottom: 3px;
}
.reservation-details strong {
  color: #333;
}
.no-reservations {
  text-align: center;
  padding: 20px 15px;
  color: #999;
}
.no-reservations i {
  font-size: 36px;
  margin-bottom: 8px;
  opacity: 0.5;
}
.no-reservations p {
  font-size: 12px;
  margin: 0;
}
.time-edit-section {
  margin-top: 12px;
  padding: 12px;
  background: #F8F9FA;
  border-radius: 8px;
  border: 1px solid #E2E8F0;
}
.time-edit-section h4 {
  font-size: 14px;
  font-weight: 600;
  color: #333;
  margin: 0 0 12px 0;
  display: flex;
  align-items: center;
  gap: 6px;
}
.time-edit-section h4 i {
  color: #FF8C42;
}
.time-inputs-simple {
  display: flex;
  align-items: flex-end;
  gap: 10px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}
.time-input-wrapper {
  flex: 1;
  min-width: 130px;
}
.time-input-wrapper label {
  display: block;
  font-size: 11px;
  font-weight: 600;
  color: #666;
  margin-bottom: 6px;
  display: flex;
  align-items: center;
  gap: 4px;
}
.time-input-wrapper label i {
  color: #FF8C42;
  font-size: 14px;
}
.time-input {
  width: 100%;
  padding: 8px 10px;
  border: 2px solid #E2E8F0;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  background: white;
  color: #333;
  transition: all 0.2s;
}
.time-input:focus {
  outline: none;
  border-color: #FF8C42;
  background: #FFFBF9;
}
.time-arrow {
  padding-bottom: 8px;
  color: #999;
  font-size: 18px;
}
.duration-quick-select {
  margin-bottom: 12px;
  padding-top: 12px;
  border-top: 1px solid #E2E8F0;
}
.duration-quick-select label {
  display: block;
  font-size: 11px;
  font-weight: 600;
  color: #666;
  margin-bottom: 8px;
}
.duration-buttons {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}
.duration-btn {
  padding: 6px 12px;
  border: 2px solid #E2E8F0;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  background: white;
  color: #666;
  cursor: pointer;
  transition: all 0.2s;
}
.duration-btn:hover {
  border-color: #FF8C42;
  color: #FF8C42;
  background: #FFFBF9;
}
.duration-btn.active {
  border-color: #FF8C42;
  background: #FF8C42;
  color: white;
}
.time-display-preview {
  margin-top: 12px;
  padding: 10px;
  background: white;
  border-radius: 6px;
  border: 2px solid #FF8C42;
  text-align: center;
}
.preview-label {
  font-size: 10px;
  font-weight: 600;
  color: #999;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 6px;
}
.preview-time {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}
.preview-time i {
  color: #FF8C42;
  font-size: 12px;
}
.time-badge {
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  font-family: 'Courier New', monospace;
}
.time-badge.start {
  background: #E3F2FD;
  color: #1976D2;
}
.time-badge.end {
  background: #F3E5F5;
  color: #7B1FA2;
}
.btn-success {
  background: #10B981;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: background 0.2s;
}
.btn-success:hover {
  background: #059669;
}
.create-order-page .create-order-main-content {
  padding: 12px;
  margin-left: 20px !important; 
  margin-right: 440px !important; 
  overflow-y: auto;
  overflow-x: hidden !important; 
  flex: 1;
  order: 1 !important;
  width: calc(100% - 460px) !important; 
  max-width: calc(100vw - 460px) !important; 
  box-sizing: border-box;
  align-items: flex-start !important; 
}
.create-order-page .sidebar-right {
  position: fixed !important;
  right: 0 !important;
  top: 0 !important;
  height: 100vh !important;
  display: flex !important;
  flex-direction: column !important;
  z-index: 1001 !important;
  order: 2 !important;
  width: 420px !important;
}
</style>
