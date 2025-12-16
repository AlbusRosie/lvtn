# Danh Sách Đầy Đủ Tất Cả Thành Phần Hệ Thống Chatbot - Beast Bite

## 📋 Mục Lục
1. [Controllers](#1-controllers)
2. [Services](#2-services)
3. [Intent Handlers](#3-intent-handlers)
4. [Tools (Tool Registry)](#4-tools-tool-registry)
5. [Tool Handlers](#5-tool-handlers)
6. [Validators](#6-validators)
7. [Helpers](#7-helpers)
8. [Constants](#8-constants)
9. [Utilities](#9-utilities)
10. [Intents](#10-intents)
11. [Entities](#11-entities)
12. [Actions](#12-actions)
13. [Database Tables](#13-database-tables)
14. [API Routes](#14-api-routes)
15. [User Roles](#15-user-roles)

---

## 1. Controllers

### 1.1. ChatController
**File:** `api/src/controllers/ChatController.js`

**Endpoints:**
- `POST /chat/message` - Gửi message và nhận response
- `GET /chat/history` - Lấy lịch sử tin nhắn
- `GET /chat/conversations` - Lấy tất cả conversations của user
- `GET /chat/suggestions` - Lấy suggestions mặc định
- `GET /chat/welcome` - Lấy welcome message
- `POST /chat/action` - Thực thi action (confirm_booking, add_to_cart, etc.)
- `POST /chat/reset` - Reset conversation

**Methods:**
- `sendMessage(req, res, next)` - Xử lý message từ user
- `getChatHistory(req, res, next)` - Lấy lịch sử chat
- `getAllConversations(req, res, next)` - Lấy tất cả conversations
- `getSuggestions(req, res, next)` - Lấy suggestions
- `getWelcomeMessage(req, res, next)` - Lấy welcome message
- `executeAction(req, res, next)` - Thực thi action
- `resetChat(req, res, next)` - Reset conversation

---

## 2. Services

### 2.1. Core Services

#### ChatService
**File:** `api/src/services/ChatService.js`

**Methods:**
- `processMessage({ message, userId, branchId, conversationId })` - Xử lý message chính
- `getAllUserConversations(userId)` - Lấy tất cả conversations
- `getConversationHistory(conversationId, limit, userId)` - Lấy lịch sử
- `getDefaultSuggestions(branchId)` - Lấy suggestions mặc định
- `getWelcomeMessage(userId, branchId, conversationId)` - Lấy welcome message
- `resetConversation(conversationId, userId, deleteMessages)` - Reset conversation

**Private Methods:**
- `_orchestrateLLMPipeline()` - Điều phối AI processing
- `_buildRouterPayload()` - Tạo payload cho router
- `_buildAndSaveResponse()` - Tạo và lưu response
- `_matchSuggestionFromHistory()` - Match suggestion từ history
- `_getIntentFromAction()` - Lấy intent từ action
- `_isSearchQuery()` - Kiểm tra có phải search query không

#### ConversationService
**File:** `api/src/services/chat/ConversationService.js`

**Methods:**
- `getOrCreateConversation(userId, conversationId, branchId)` - Tạo hoặc lấy conversation
- `getAllUserConversations(userId)` - Lấy tất cả conversations của user
- `getConversationHistory(conversationId, limit, userId)` - Lấy lịch sử tin nhắn
- `resetConversation(conversationId, userId, deleteMessages)` - Reset conversation
- `updateConversationContext(conversationId, contextData, userId)` - Update context
- `deepMerge(target, source)` - Merge objects
- `cleanMessage(message)` - Làm sạch message

#### ContextService
**File:** `api/src/services/chat/ContextService.js`

**Methods:**
- `buildContext(userId, branchId, conversation)` - Build context object

**Context Structure:**
```javascript
{
    user: { id, name, email, address, phone },
    branch: { id, name, address_detail, phone, opening_hours, close_hours },
    cart: { id, items, ... },
    recentOrders: [{ id, order_type, total, status, created_at }],
    conversationHistory: [{ message_type, message_content, ... }],
    conversationContext: {
        lastIntent,
        lastBranchId,
        lastBranch,
        lastEntities,
        lastDeliveryAddress,
        userLatitude,
        userLongitude,
        waitingForAddress
    },
    branchesCache: [{ id, name, address_detail, ... }],
    conversationId: "session_id"
}
```

#### MessageService
**File:** `api/src/services/chat/MessageService.js`

**Methods:**
- `saveMessage(conversationId, messageType, content, intent, entities, action, suggestions)` - Lưu message

#### AIService
**File:** `api/src/services/chat/AIService.js`

**Methods:**
- `callAI(message, context, fallback)` - Gọi AI (Gemini hoặc rule-based)

**Private Methods:**
- `_ruleBasedToolCalling()` - Rule-based processing khi Gemini disabled
- `_callGeminiWithRetry()` - Gọi Gemini với retry
- `_callGemini()` - Gọi Gemini API
- `_handleGeminiFunctionCalls()` - Xử lý function calls từ Gemini
- `_handleToolCalls()` - Xử lý tool calls
- `_generateResponseFromToolResults()` - Tạo response từ tool results
- `_buildFallbackResponseFromTools()` - Fallback response
- `_formatMenuResult()` - Format menu result
- `_formatSearchResult()` - Format search result
- `_formatAvailabilityResult()` - Format availability result
- `_formatReservationResult()` - Format reservation result
- `_formatBranchesResult()` - Format branches result
- `_formatBranchesResultForMenu()` - Format branches cho menu
- `_extractEntitiesFromToolResults()` - Extract entities từ tool results
- `_inferIntentFromToolCalls()` - Suy luận intent từ tool calls
- `_extractIntentFromMessage()` - Extract intent từ message
- `_buildSystemPrompt()` - Build system prompt cho Gemini
- `_buildConversationHistory()` - Build conversation history
- `_getUserRole()` - Lấy user role
- `_extractSearchKeyword()` - Extract keyword từ message
- `_extractLocationKeyword()` - Extract location từ message
- `_formatPrice()` - Format giá tiền

#### ToolOrchestrator
**File:** `api/src/services/chat/ToolOrchestrator.js`

**Methods:**
- `validateToolCall(toolName, parameters, userContext)` - Validate tool call
- `executeToolCall(toolName, parameters, userContext)` - Execute tool call
- `getAvailableToolsForLLM(userRole)` - Lấy available tools cho LLM
- `cleanupRateLimitCache()` - Cleanup rate limit cache

**Private Methods:**
- `_getUserRole()` - Lấy user role
- `_validateParameters()` - Validate parameters
- `_checkRateLimit()` - Kiểm tra rate limit
- `_logToolUsage()` - Log tool usage

#### ResponseComposer
**File:** `api/src/services/chat/ResponseComposer.js`

**Methods:**
- `buildAndSave(conversation, context, result, userId, branchId)` - Build và save response

#### ResponseHandler
**File:** `api/src/services/chat/ResponseHandler.js`

**Methods:**
- `getSuggestions(intent, branchId)` - Tạo suggestions dựa trên intent
- `determineAction(intent, entities)` - Xác định action
- `getMessageType(intent)` - Lấy message type
- `getDefaultSuggestions(branchId)` - Lấy suggestions mặc định
- `getCategoryEmoji(categoryName)` - Lấy emoji cho category
- `fallbackResponse()` - Fallback response

#### IntentRouter
**File:** `api/src/services/chat/IntentRouter.js`

**Methods:**
- `route(payload)` - Route intent đến handler phù hợp

**Handlers (theo thứ tự):**
1. BookingIntentHandler
2. TakeawayIntentHandler
3. MenuIntentHandler
4. BranchIntentHandler
5. SearchIntentHandler
6. DefaultIntentHandler

#### IntentDetector
**File:** `api/src/services/chat/IntentDetector.js`

**Methods:**
- `detectIntent(message)` - Detect intent từ message

#### EntityExtractor
**File:** `api/src/services/chat/EntityExtractor.js`

**Methods:**
- `extractEntities(message)` - Extract entities từ message
- `parseNaturalLanguage(message)` - Parse natural language
- `extractBranchFromMessage(userMessage, entities)` - Extract branch từ message

#### LegacyFallbackService
**File:** `api/src/services/chat/LegacyFallbackService.js`

**Methods:**
- `fallbackResponse(message, context)` - Fallback response khi AI lỗi

#### AnalyticsService
**File:** `api/src/services/chat/AnalyticsService.js`

**Methods:**
- `trackMessage(userId, conversationId, intent, responseTime, success)` - Track message
- `trackToolCall(userId, toolName, success, duration, error)` - Track tool call
- `trackBooking(event, userId, branchId, reservationId, metadata)` - Track booking
- `trackEvent(userId, eventType, metadata)` - Track event

### 2.2. Business Logic Handlers

#### BookingHandler
**File:** `api/src/services/chat/BookingHandler.js`

**Methods:**
- `handleSmartBooking(message, context)` - Xử lý đặt bàn thông minh
- `createActualReservation(userId, entities)` - Tạo reservation thực tế

#### BranchHandler
**File:** `api/src/services/chat/BranchHandler.js`

**Methods:**
- `getAllActiveBranches()` - Lấy tất cả chi nhánh active
- `getBranchByName(branchName)` - Tìm branch theo tên
- `createBranchSuggestions(branches, options)` - Tạo branch suggestions
- `getDistrict(districtId)` - Lấy thông tin quận/huyện

#### MenuHandler
**File:** `api/src/services/chat/MenuHandler.js`

**Methods:**
- (Các methods xử lý menu logic)

---

## 3. Intent Handlers

### 3.1. BaseIntentHandler
**File:** `api/src/services/chat/handlers/BaseIntentHandler.js`

**Methods:**
- `canHandle()` - Kiểm tra có thể xử lý không (base: return false)
- `buildResponse(payload)` - Build response object

### 3.2. BookingIntentHandler
**File:** `api/src/services/chat/handlers/BookingIntentHandler.js`

**Intents được xử lý:**
- `book_table`
- `book_table_partial`
- `book_table_specific_branch`
- `confirm_booking`
- `modify_booking`
- `show_booking_info`

**Methods:**
- `canHandle(intent, context)` - Kiểm tra có thể xử lý
- `handle({ intent, message, context, entities, userId })` - Xử lý intent

**Private Methods:**
- `_buildBranchSuggestionsIfNeeded(validation)` - Tạo branch suggestions nếu cần

### 3.3. MenuIntentHandler
**File:** `api/src/services/chat/handlers/MenuIntentHandler.js`

**Intents được xử lý:**
- `view_menu`
- `view_menu_specific_branch`

**Methods:**
- `canHandle(intent, context)` - Kiểm tra có thể xử lý
- `handle({ intent, message, context, entities, userId })` - Xử lý intent

### 3.4. BranchIntentHandler
**File:** `api/src/services/chat/handlers/BranchIntentHandler.js`

**Intents được xử lý:**
- `view_branches`
- `ask_branch`
- `find_nearest_branch`
- `find_first_branch`
- `search_branches_by_location`

**Methods:**
- `canHandle(intent, context)` - Kiểm tra có thể xử lý
- `handle({ intent, message, context, entities, userId })` - Xử lý intent

### 3.5. SearchIntentHandler
**File:** `api/src/services/chat/handlers/SearchIntentHandler.js`

**Intents được xử lý:**
- `search_food`
- `search_product`

**Methods:**
- `canHandle(intent, context)` - Kiểm tra có thể xử lý
- `handle({ intent, message, context, entities, userId })` - Xử lý intent

### 3.6. TakeawayIntentHandler
**File:** `api/src/services/chat/handlers/TakeawayIntentHandler.js`

**Intents được xử lý:**
- `order_takeaway`
- `order_delivery`

**Methods:**
- `canHandle(intent, context)` - Kiểm tra có thể xử lý
- `handle({ intent, message, context, entities, userId })` - Xử lý intent

### 3.7. DefaultIntentHandler
**File:** `api/src/services/chat/handlers/DefaultIntentHandler.js`

**Intents được xử lý:**
- Tất cả intents khác (fallback)

**Methods:**
- `canHandle(intent, context)` - Luôn return true (fallback)
- `handle({ intent, message, context, entities, userId })` - Xử lý intent

---

## 4. Tools (Tool Registry)

**File:** `api/src/services/chat/ToolRegistry.js`

### 4.1. Tool Definitions

#### 1. get_branch_menu
- **Description:** Lấy menu món ăn của một chi nhánh cụ thể
- **Allowed Roles:** customer, guest, staff, manager
- **Parameters:**
  - `branch_id` (integer, required)
  - `category_id` (integer, optional)
- **Handler:** `ToolHandlers.getBranchMenu`

#### 2. search_products
- **Description:** Tìm kiếm món ăn theo nhiều tiêu chí
- **Allowed Roles:** customer, guest, staff, manager
- **Parameters:**
  - `keyword` (string, optional)
  - `category_id` (integer, optional)
  - `min_price` (number, optional)
  - `max_price` (number, optional)
  - `branch_id` (integer, optional)
  - `sort_by` (enum: price_asc, price_desc, name, popularity, optional)
  - `dietary` (enum: vegetarian, vegan, halal, seafood, meat, chicken, beef, pork, optional)
  - `limit` (integer, default: 10, min: 1, max: 50)
- **Handler:** `ToolHandlers.searchProducts`

#### 3. check_table_availability
- **Description:** Kiểm tra bàn trống tại chi nhánh
- **Allowed Roles:** customer, guest, staff, manager
- **Parameters:**
  - `branch_id` (integer, required)
  - `reservation_date` (date, required, format: YYYY-MM-DD)
  - `reservation_time` (string, required, pattern: HH:MM)
  - `guest_count` (integer, required, min: 1, max: 50)
- **Handler:** `ToolHandlers.checkTableAvailability`

#### 4. create_reservation
- **Description:** Tạo đặt bàn mới
- **Allowed Roles:** customer, staff, manager
- **Parameters:**
  - `branch_id` (integer, required)
  - `reservation_date` (date, required, format: YYYY-MM-DD)
  - `reservation_time` (string, required, format: HH:MM)
  - `guest_count` (integer, required, min: 1)
  - `special_requests` (string, optional)
  - `customer_name` (string, optional)
  - `customer_phone` (string, optional)
- **Handler:** `ToolHandlers.createReservation`
- **Inject User Context:** true

#### 5. get_my_reservations
- **Description:** Lấy danh sách đặt bàn của user
- **Allowed Roles:** customer
- **Parameters:**
  - `status` (enum: pending, confirmed, completed, cancelled, optional)
  - `limit` (integer, default: 10)
- **Handler:** `ToolHandlers.getMyReservations`
- **Inject User Context:** true
- **Require Auth:** true

#### 6. get_my_orders
- **Description:** Lấy danh sách đơn hàng của user
- **Allowed Roles:** customer
- **Parameters:**
  - `status` (enum: pending, confirmed, preparing, ready, completed, cancelled, optional)
  - `limit` (integer, default: 10)
- **Handler:** `ToolHandlers.getMyOrders`
- **Inject User Context:** true
- **Require Auth:** true

#### 7. get_all_branches
- **Description:** Lấy danh sách tất cả chi nhánh đang hoạt động
- **Allowed Roles:** customer, guest, staff, manager
- **Parameters:**
  - `district_id` (integer, optional)
  - `province_id` (integer, optional)
- **Handler:** `ToolHandlers.getAllBranches`

#### 8. get_branch_details
- **Description:** Lấy thông tin chi tiết của một chi nhánh
- **Allowed Roles:** customer, guest, staff, manager
- **Parameters:**
  - `branch_id` (integer, required)
- **Handler:** `ToolHandlers.getBranchDetails`

#### 9. get_product_details
- **Description:** Lấy thông tin chi tiết của một món ăn
- **Allowed Roles:** customer, guest, staff, manager
- **Parameters:**
  - `product_id` (integer, required)
  - `branch_id` (integer, optional)
- **Handler:** `ToolHandlers.getProductDetails`

#### 10. get_categories
- **Description:** Lấy danh sách các danh mục món ăn
- **Allowed Roles:** customer, guest, staff, manager
- **Parameters:** (none)
- **Handler:** `ToolHandlers.getCategories`

#### 11. check_branch_operating_hours
- **Description:** Kiểm tra giờ mở cửa của chi nhánh
- **Allowed Roles:** customer, guest, staff, manager
- **Parameters:**
  - `branch_id` (integer, required)
  - `check_time` (string, optional, format: HH:MM)
- **Handler:** `ToolHandlers.checkBranchOperatingHours`

### 4.2. Tool Registry Functions

**File:** `api/src/services/chat/ToolRegistry.js`

**Functions:**
- `getToolDefinitionsForLLM(userRole)` - Lấy tool definitions cho LLM
- `getToolByName(toolName)` - Lấy tool definition theo tên

**Constants:**
- `USER_ROLES` - Định nghĩa các user roles

---

## 5. Tool Handlers

**File:** `api/src/services/chat/ToolHandlers.js`

### 5.1. Static Methods

#### getBranchMenu(params)
- Lấy menu của chi nhánh
- Parameters: `{ branch_id, category_id }`
- Returns: `{ branch_id, total_products, categories, menu }`

#### searchProducts(params)
- Tìm kiếm món ăn
- Parameters: `{ keyword, branch_id, category_id, min_price, max_price, sort_by, dietary, limit }`
- Returns: `{ keyword, filters, total_found, products }`

#### checkTableAvailability(params)
- Kiểm tra bàn trống
- Parameters: `{ branch_id, reservation_date, reservation_time, guest_count }`
- Returns: `{ available, message, suggestion, ... }`

#### createReservation(params)
- Tạo đặt bàn
- Parameters: `{ branch_id, reservation_date, reservation_time, guest_count, special_requests, customer_name, customer_phone, _user_id }`
- Returns: `{ success, reservation_id, details }`

#### getMyReservations(params)
- Lấy đặt bàn của user
- Parameters: `{ status, limit, _user_id }`
- Returns: `{ reservations: [...] }`

#### getMyOrders(params)
- Lấy đơn hàng của user
- Parameters: `{ status, limit, _user_id }`
- Returns: `{ orders: [...] }`

#### getAllBranches(params)
- Lấy tất cả chi nhánh
- Parameters: `{ district_id, province_id }`
- Returns: `{ branches: [...], total }`

#### getBranchDetails(params)
- Lấy chi tiết chi nhánh
- Parameters: `{ branch_id }`
- Returns: `{ id, name, address_detail, phone, ... }`

#### getProductDetails(params)
- Lấy chi tiết món ăn
- Parameters: `{ product_id, branch_id }`
- Returns: `{ id, name, description, price, ... }`

#### getCategories(params)
- Lấy danh sách categories
- Parameters: `{}`
- Returns: `{ categories: [...], total }`

#### checkBranchOperatingHours(params)
- Kiểm tra giờ mở cửa
- Parameters: `{ branch_id, check_time }`
- Returns: `{ is_open, opening_hours, closing_hours, message }`

---

## 6. Validators

### 6.1. BookingValidator
**File:** `api/src/services/chat/validators/BookingValidator.js`

**Methods:**
- `validate(rawEntities)` - Validate entities cho booking
- `buildMissingInfoPrompt(missing, entities)` - Tạo prompt hỏi thông tin thiếu

**Required Fields:**
- `people` (hoặc `number_of_people`, `guest_count`)
- `date` (hoặc `reservation_date`, `booking_date`)
- `time` (hoặc `reservation_time`, `time_slot`)
- `branch_name` (hoặc `branch_id`)

---

## 7. Helpers

### 7.1. BranchFormatter
**File:** `api/src/services/chat/helpers/BranchFormatter.js`

**Methods:**
- `formatBranchListWithDetails(branches)` - Format branch list với chi tiết
- `formatBranchListSimple(branches, includeDetails)` - Format branch list đơn giản

---

## 8. Constants

### 8.1. Messages
**File:** `api/src/services/chat/constants/Messages.js`

**Constants:**
- `GREETING_MESSAGE` - Welcome message mặc định

---

## 9. Utilities

### 9.1. Utils
**File:** `api/src/services/chat/Utils.js`

**Methods:**
- `validateChatInput(message)` - Validate và sanitize input
- `normalizeVietnamese(text)` - Normalize tiếng Việt
- `normalizeEntityFields(entities)` - Normalize entity fields
- `safeJsonParse(jsonString, context)` - Parse JSON an toàn
- `cleanMessage(message)` - Làm sạch message

---

## 10. Intents

### 10.1. Intent List

#### Greeting & General
- `greeting` - Chào hỏi
- `hello` - Chào hỏi
- `ask_info` - Hỏi thông tin chung

#### Booking
- `book_table` - Đặt bàn
- `book_table_partial` - Đặt bàn (thiếu thông tin)
- `book_table_specific_branch` - Đặt bàn tại chi nhánh cụ thể
- `confirm_booking` - Xác nhận đặt bàn
- `modify_booking` - Sửa đặt bàn
- `cancel_booking` - Hủy đặt bàn
- `show_booking_info` - Hiển thị thông tin đặt bàn
- `book_table_confirmed` - Đặt bàn đã xác nhận
- `book_table_cancelled` - Đặt bàn đã hủy
- `reservation_created` - Đặt bàn đã tạo thành công
- `reservation_failed` - Đặt bàn thất bại
- `check_availability` - Kiểm tra bàn trống

#### Menu
- `view_menu` - Xem menu
- `view_menu_specific_branch` - Xem menu chi nhánh cụ thể

#### Branch
- `view_branches` - Xem tất cả chi nhánh
- `ask_branch` - Hỏi về chi nhánh
- `find_nearest_branch` - Tìm chi nhánh gần nhất
- `find_first_branch` - Tìm chi nhánh đầu tiên
- `search_branches_by_location` - Tìm chi nhánh theo địa điểm
- `view_branch_info` - Xem thông tin chi nhánh

#### Search
- `search_food` - Tìm kiếm món ăn
- `search_product` - Tìm kiếm sản phẩm

#### Order
- `order_food` - Đặt món
- `order_food_specific_branch` - Đặt món tại chi nhánh cụ thể
- `order_takeaway` - Đặt món mang về
- `order_delivery` - Đặt món giao hàng
- `view_orders` - Xem đơn hàng
- `view_cart` - Xem giỏ hàng

#### Other
- `view_categories` - Xem danh mục
- `view_product` - Xem chi tiết sản phẩm
- `view_reservations` - Xem đặt bàn
- `tool_response` - Response từ tool
- `tool_error` - Lỗi tool
- `general` - Intent chung
- `unknown` - Intent không xác định

---

## 11. Entities

### 11.1. Entity Fields

#### Booking Entities
- `people` / `number_of_people` / `guest_count` - Số người
- `date` / `reservation_date` / `booking_date` - Ngày đặt bàn
- `time` / `reservation_time` / `time_slot` - Giờ đặt bàn
- `branch_id` - ID chi nhánh
- `branch_name` / `branch` - Tên chi nhánh
- `reservation_id` - ID đặt bàn
- `table_id` - ID bàn
- `floor_id` - ID tầng
- `special_requests` - Yêu cầu đặc biệt

#### Search Entities
- `keyword` - Từ khóa tìm kiếm
- `category_id` - ID danh mục
- `min_price` - Giá tối thiểu
- `max_price` - Giá tối đa
- `dietary` - Chế độ ăn (vegetarian, vegan, etc.)
- `sort_by` - Sắp xếp

#### Location Entities
- `district_id` - ID quận/huyện
- `province_id` - ID tỉnh/thành phố
- `district_search_term` - Từ khóa tìm quận/huyện
- `location` - Địa điểm
- `userLatitude` - Vĩ độ user
- `userLongitude` - Kinh độ user
- `delivery_address` / `lastDeliveryAddress` - Địa chỉ giao hàng

#### Product Entities
- `product_id` - ID sản phẩm
- `quantity` - Số lượng

#### Time Entities
- `time_hour` - Giờ (số)
- `time_ambiguous` - Giờ không rõ ràng (AM/PM)

---

## 12. Actions

### 12.1. Action List

#### Booking Actions
- `book_table` - Đặt bàn
- `confirm_booking` - Xác nhận đặt bàn
- `modify_booking` - Sửa đặt bàn
- `cancel_booking` - Hủy đặt bàn
- `select_branch_for_booking` - Chọn chi nhánh để đặt bàn
- `select_time` - Chọn giờ
- `confirm_reservation_only` - Chỉ xác nhận đặt bàn (không đặt món)

#### Menu Actions
- `view_menu` - Xem menu
- `navigate_menu` - Điều hướng đến menu
- `view_category` - Xem danh mục

#### Branch Actions
- `view_branches` - Xem chi nhánh
- `view_branch_info` - Xem thông tin chi nhánh
- `select_branch` - Chọn chi nhánh
- `find_branch` - Tìm chi nhánh
- `find_nearest_branch` - Tìm chi nhánh gần nhất

#### Order Actions
- `order_food` - Đặt món
- `add_to_cart` - Thêm vào giỏ hàng
- `view_cart` - Xem giỏ hàng
- `checkout_cart` - Thanh toán giỏ hàng
- `view_orders` - Xem đơn hàng
- `navigate_orders` - Điều hướng đến đơn hàng
- `check_order_status` - Kiểm tra trạng thái đơn hàng

#### Takeaway/Delivery Actions
- `select_branch_for_takeaway` - Chọn chi nhánh cho takeaway
- `select_branch_for_delivery` - Chọn chi nhánh cho delivery
- `confirm_delivery_address` - Xác nhận địa chỉ giao hàng
- `change_delivery_address` - Thay đổi địa chỉ giao hàng
- `use_saved_address` - Dùng địa chỉ đã lưu
- `enter_delivery_address` - Nhập địa chỉ giao hàng

#### Other Actions
- `search_food` - Tìm kiếm món
- `call_confirmation` - Gọi xác nhận
- `call_booking` - Gọi đặt bàn
- `show_reservation_details` - Hiển thị chi tiết đặt bàn
- `use_existing_cart` - Dùng giỏ hàng hiện có
- `add_note` - Thêm ghi chú

---

## 13. Database Tables

### 13.1. Chat Tables

#### chat_conversations
**Columns:**
- `id` (PK, integer)
- `user_id` (FK to users, integer, nullable)
- `session_id` (string, unique)
- `branch_id` (FK to branches, integer, nullable)
- `context_data` (JSON/text)
- `status` (enum: active, inactive)
- `expires_at` (datetime)
- `created_at` (datetime)
- `updated_at` (datetime)

#### chat_messages
**Columns:**
- `id` (PK, integer)
- `conversation_id` (FK to chat_conversations, integer)
- `message_type` (enum: user, bot)
- `message_content` (text)
- `intent` (string, nullable)
- `entities` (JSON/text, nullable)
- `suggestions` (JSON/text, nullable)
- `action` (string, nullable)
- `created_at` (datetime)

### 13.2. Related Tables

#### users
- Thông tin user

#### branches
- Thông tin chi nhánh

#### products
- Thông tin sản phẩm

#### branch_products
- Sản phẩm theo chi nhánh

#### categories
- Danh mục món ăn

#### reservations
- Đặt bàn

#### orders
- Đơn hàng

#### carts
- Giỏ hàng

#### cart_items
- Items trong giỏ hàng

#### tables
- Bàn

#### floors
- Tầng

#### districts
- Quận/huyện

#### provinces
- Tỉnh/thành phố

#### audit_logs
- Log audit (cho tool usage)

---

## 14. API Routes

### 14.1. Chat Routes

**Base Path:** `/api/chat` hoặc `/chat`

#### POST /chat/message
- **Controller:** `ChatController.sendMessage`
- **Auth:** Optional (Bearer token)
- **Body:**
  ```json
  {
    "message": "string",
    "branch_id": "integer (optional)",
    "conversation_id": "string (optional)"
  }
  ```
- **Response:**
  ```json
  {
    "status": "success",
    "data": {
      "id": "uuid",
      "message": "string",
      "intent": "string",
      "entities": {},
      "suggestions": [],
      "action": "string",
      "action_data": {},
      "type": "text",
      "conversation_id": "string",
      "timestamp": "ISO date"
    }
  }
  ```

#### GET /chat/history
- **Controller:** `ChatController.getChatHistory`
- **Auth:** Required
- **Query:**
  - `conversation_id` (required)
- **Response:**
  ```json
  {
    "status": "success",
    "data": [
      {
        "id": "integer",
        "message_type": "user|bot",
        "message_content": "string",
        "intent": "string",
        "entities": {},
        "suggestions": [],
        "created_at": "ISO date"
      }
    ]
  }
  ```

#### GET /chat/conversations
- **Controller:** `ChatController.getAllConversations`
- **Auth:** Required
- **Response:**
  ```json
  {
    "status": "success",
    "data": [
      {
        "id": "integer",
        "session_id": "string",
        "branch_id": "integer",
        "created_at": "ISO date",
        "last_message": {
          "content": "string",
          "is_user": "boolean",
          "created_at": "ISO date"
        }
      }
    ]
  }
  ```

#### GET /chat/suggestions
- **Controller:** `ChatController.getSuggestions`
- **Auth:** Optional
- **Query:**
  - `branch_id` (optional)
- **Response:**
  ```json
  {
    "status": "success",
    "data": [
      {
        "text": "string",
        "action": "string",
        "data": {}
      }
    ]
  }
  ```

#### GET /chat/welcome
- **Controller:** `ChatController.getWelcomeMessage`
- **Auth:** Required
- **Query:**
  - `branch_id` (optional)
  - `conversation_id` (optional)
- **Response:**
  ```json
  {
    "status": "success",
    "data": {
      "id": "uuid",
      "message": "string",
      "intent": "greeting",
      "entities": {},
      "suggestions": [],
      "action": null,
      "action_data": null,
      "type": "text",
      "conversation_id": "string",
      "timestamp": "ISO date"
    }
  }
  ```

#### POST /chat/action
- **Controller:** `ChatController.executeAction`
- **Auth:** Optional (một số actions cần auth)
- **Body:**
  ```json
  {
    "action": "string",
    "data": {},
    "conversation_id": "string (optional)"
  }
  ```
- **Response:**
  ```json
  {
    "status": "success",
    "data": {
      "action": "string",
      "success": "boolean",
      "message": "string",
      "data": {}
    }
  }
  ```

#### POST /chat/reset
- **Controller:** `ChatController.resetChat`
- **Auth:** Required
- **Body:**
  ```json
  {
    "conversation_id": "string (required)",
    "delete_messages": "boolean (optional, default: true)"
  }
  ```
- **Response:**
  ```json
  {
    "status": "success",
    "data": {
      "success": true,
      "conversationId": "string",
      "messagesDeleted": true
    }
  }
  ```

---

## 15. User Roles

### 15.1. Role Definitions

**File:** `api/src/services/chat/ToolRegistry.js`

```javascript
USER_ROLES = {
    CUSTOMER: 'customer',    // Khách hàng đã đăng ký
    GUEST: 'guest',          // Khách vãng lai (chưa đăng nhập)
    STAFF: 'staff',          // Nhân viên
    MANAGER: 'manager',      // Quản lý
    ADMIN: 'admin'           // Quản trị viên
}
```

### 15.2. Rate Limits

**File:** `api/src/services/chat/ToolOrchestrator.js`

- **Guest:** 5 calls/phút
- **Customer:** 20 calls/phút
- **Staff:** 50 calls/phút
- **Manager:** 100 calls/phút
- **Admin:** Unlimited

### 15.3. Tool Access by Role

#### Tools Available for All (customer, guest, staff, manager):
- `get_branch_menu`
- `search_products`
- `check_table_availability`
- `get_all_branches`
- `get_branch_details`
- `get_product_details`
- `get_categories`
- `check_branch_operating_hours`

#### Tools Available for Customer Only:
- `get_my_reservations`
- `get_my_orders`

#### Tools Available for Customer, Staff, Manager:
- `create_reservation`

#### Tools Requiring Auth:
- `get_my_reservations` (require_auth: true)
- `get_my_orders` (require_auth: true)

---

## 📊 Tổng Kết

### Số Lượng Thành Phần

- **Controllers:** 1 (ChatController)
- **Core Services:** 12
- **Intent Handlers:** 6
- **Tools:** 11
- **Tool Handlers:** 11 methods
- **Validators:** 1
- **Helpers:** 1
- **Constants:** 1 file
- **Utilities:** 1 file
- **Intents:** ~30+
- **Entities:** ~20+ fields
- **Actions:** ~25+
- **Database Tables:** 2 chat tables + ~10 related tables
- **API Routes:** 7 endpoints
- **User Roles:** 5 roles

### File Structure

```
api/src/
├── controllers/
│   └── ChatController.js
├── services/
│   ├── ChatService.js
│   └── chat/
│       ├── AIService.js
│       ├── AnalyticsService.js
│       ├── BookingHandler.js
│       ├── BranchHandler.js
│       ├── ContextService.js
│       ├── ConversationService.js
│       ├── EntityExtractor.js
│       ├── IntentDetector.js
│       ├── IntentRouter.js
│       ├── LegacyFallbackService.js
│       ├── MenuHandler.js
│       ├── MessageService.js
│       ├── ResponseComposer.js
│       ├── ResponseHandler.js
│       ├── ToolHandlers.js
│       ├── ToolOrchestrator.js
│       ├── ToolRegistry.js
│       ├── Utils.js
│       ├── constants/
│       │   └── Messages.js
│       ├── handlers/
│       │   ├── BaseIntentHandler.js
│       │   ├── BookingIntentHandler.js
│       │   ├── BranchIntentHandler.js
│       │   ├── DefaultIntentHandler.js
│       │   ├── MenuIntentHandler.js
│       │   ├── SearchIntentHandler.js
│       │   └── TakeawayIntentHandler.js
│       ├── helpers/
│       │   └── BranchFormatter.js
│       └── validators/
│           └── BookingValidator.js
└── routes/
    └── (chat routes trong main router)
```

---

**Tài liệu này liệt kê đầy đủ tất cả các thành phần trong hệ thống chatbot Beast Bite.**



