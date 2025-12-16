# Giải Thích Flow Logic Chatbot - Beast Bite

## Tổng Quan Kiến Trúc

Chatbot sử dụng kiến trúc **hybrid** kết hợp:
- **AI Service** (Google Gemini) với Tool Calling pattern
- **Rule-based handlers** cho các intent cụ thể
- **Intent Router** để điều hướng request đến handler phù hợp
- **Context Management** để duy trì ngữ cảnh cuộc hội thoại

---

## Flow Logic Chi Tiết

### 1. Entry Point - ChatController

**File:** `api/src/controllers/ChatController.js`

**Endpoint:** `POST /chat/message`

**Flow:**
```
User gửi message 
  ↓
ChatController.sendMessage()
  ↓
Validate input (message, conversation_id, branch_id)
  ↓
Sanitize message (Utils.validateChatInput)
  ↓
ChatService.processMessage()
  ↓
Trả về response với format chuẩn
```

**Response Format:**
```json
{
  "id": "uuid",
  "message": "Bot response",
  "intent": "detected_intent",
  "entities": {},
  "suggestions": [],
  "action": "action_name",
  "action_data": {},
  "type": "text",
  "conversation_id": "session_id",
  "timestamp": "ISO date"
}
```

---

### 2. Core Processing - ChatService

**File:** `api/src/services/ChatService.js`

**Method:** `processMessage({ message, userId, branchId, conversationId })`

#### 2.1. Khởi Tạo Conversation

```javascript
conversation = await ConversationService.getOrCreateConversation(userId, conversationId, branchId)
```

- Tìm conversation hiện có hoặc tạo mới
- Lưu `session_id`, `user_id`, `branch_id`
- Tạo `context_data` (JSON) để lưu ngữ cảnh

#### 2.2. Build Context

```javascript
context = await ContextService.buildContext(userId, branchId, conversation)
```

**Context bao gồm:**
- `user`: Thông tin user (id, name, email, address, phone)
- `branch`: Thông tin chi nhánh hiện tại
- `cart`: Giỏ hàng của user (nếu có)
- `recentOrders`: 3 đơn hàng gần nhất
- `conversationHistory`: Lịch sử tin nhắn (50 tin gần nhất)
- `conversationContext`: Ngữ cảnh từ context_data
  - `lastBranchId`: Chi nhánh vừa chọn
  - `lastIntent`: Intent vừa xử lý
  - `lastEntities`: Entities vừa extract
  - `lastDeliveryAddress`: Địa chỉ giao hàng
  - `userLatitude`, `userLongitude`: Vị trí user

#### 2.3. Xử Lý Greeting (Tin Nhắn Đầu Tiên)

```javascript
if (isNewConversation && isGreeting) {
    return GREETING_MESSAGE
}
```

- Nếu là conversation mới và message là greeting → trả về welcome message
- Lưu message vào database

#### 2.4. Match Suggestion Từ History

```javascript
suggestionMatch = this._matchSuggestionFromHistory(message, context)
```

**Logic:**
- Tìm trong lịch sử tin nhắn bot có suggestions
- So khớp message hiện tại với text của suggestions
- Nếu match → extract action và data từ suggestion

**Ví dụ:**
- User click suggestion "📍 Beast Bite - The Pearl District"
- System match với suggestion → extract `action: 'select_branch_for_booking'`, `data: { branch_id: 5 }`

#### 2.5. Extract Entities

```javascript
extractedEntities = await EntityExtractor.extractEntities(message)
mergedEntities = merge(lastEntities, extractedEntities)
```

**Entities được extract:**
- `date`: Ngày đặt bàn (từ "ngày mai", "20/01", etc.)
- `time`: Giờ đặt bàn (từ "7h tối", "19:00", etc.)
- `people`/`guest_count`: Số người (từ "2 người", "4 người", etc.)
- `branch_id`: ID chi nhánh
- `branch_name`: Tên chi nhánh
- `keyword`: Từ khóa tìm kiếm món ăn
- `location`: Địa điểm (quận, huyện, tỉnh)

#### 2.6. Xử Lý Booking Flow Đặc Biệt

```javascript
if (isBookingFlow && hasBookingInfo) {
    // User đã chọn branch, giờ cung cấp thông tin đặt bàn
    bookingResponse = await intentRouter.route(bookingPayload)
}
```

**Điều kiện:**
- `isBookingFlow`: Có `lastBranchId` và `lastIntent === 'book_table'`
- `hasBookingInfo`: Có đủ thông tin (people + time, hoặc people + date, hoặc time + date)

**Ví dụ:**
- Context: User đã chọn branch_id = 5
- Message: "2 người chiều nay 5h"
- → Extract: people=2, time="17:00", date="hôm nay"
- → Route đến BookingIntentHandler

#### 2.7. Xử Lý Nearest Branch Query

```javascript
if (isNearestBranchQuery) {
    nearestBranchResponse = await intentRouter.route(nearestBranchPayload)
}
```

**Pattern:** "chi nhánh gần nhất", "gần tôi", "nearest", etc.

#### 2.8. LLM Pipeline (AI Processing)

```javascript
llmResult = await this._orchestrateLLMPipeline({
    message,
    context,
    metadata,
    mergedEntities
})
```

**Flow trong `_orchestrateLLMPipeline`:**

```
AIService.callAI(message, context, fallback)
  ↓
Nếu Gemini enabled:
  - Build system prompt với context
  - Gọi Gemini API với tools
  - Gemini có thể gọi tools (function calling)
  - Xử lý tool results
  ↓
Nếu Gemini disabled hoặc lỗi:
  - Rule-based tool calling (_ruleBasedToolCalling)
  - Fallback service
```

**System Prompt bao gồm:**
- Context hiện tại (user, branch, time)
- Available tools (dựa trên user role)
- Rules nghiêm ngặt:
  - BẮT BUỘC gọi tools để lấy dữ liệu thực
  - KHÔNG BAO GIỜ bịa đặt thông tin
  - KHÔNG sử dụng emoji
  - Xử lý đặc biệt cho booking flow, menu requests, delivery/takeaway

#### 2.9. Intent Routing

```javascript
routerPayload = this._buildRouterPayload({
    intent: llmResult.intent,
    message,
    context,
    entities: llmResult.entities,
    aiResponse: llmResult,
    metadata,
    branchId,
    userId
})

routedResponse = await intentRouter.route(routerPayload)
```

**IntentRouter** (`api/src/services/chat/IntentRouter.js`):

```javascript
for (const handler of this.handlers) {
    if (handler.canHandle(intent, context, metadata)) {
        result = await handler.handle(payload)
        if (result) return result
    }
}
```

**Handlers (theo thứ tự):**
1. **BookingIntentHandler**: Đặt bàn
2. **TakeawayIntentHandler**: Đặt món mang về
3. **MenuIntentHandler**: Xem menu
4. **BranchIntentHandler**: Thông tin chi nhánh
5. **SearchIntentHandler**: Tìm kiếm món ăn
6. **DefaultIntentHandler**: Fallback

#### 2.10. Build và Save Response

```javascript
result = await this._buildAndSaveResponse(conversation, context, finalPayload, userId, branchId)
```

**ResponseComposer.buildAndSave()** thực hiện:
- Format response message
- Tạo suggestions (nút hành động)
- Lưu message vào database (user message + bot response)
- Update conversation context nếu cần
- Trả về response object

---

### 3. AI Service - AIService

**File:** `api/src/services/chat/AIService.js`

#### 3.1. Call AI

```javascript
async callAI(message, context, fallback)
```

**Flow:**

**Nếu Gemini enabled:**
1. Lấy available tools dựa trên user role
2. Build system prompt với context và tools
3. Build conversation history (6 tin nhắn gần nhất)
4. Gọi Gemini API với function declarations
5. Gemini trả về:
   - Text response
   - Function calls (nếu có)

**Nếu Gemini disabled:**
- Sử dụng `_ruleBasedToolCalling()`:
  - Pattern matching cho các intent phổ biến
  - Gọi tools trực tiếp
  - Format response từ tool results

#### 3.2. Handle Function Calls

```javascript
async _handleGeminiFunctionCalls(functionCalls, originalMessage, context)
```

**Flow:**
```
For each function call:
  ↓
ToolOrchestrator.executeToolCall(toolName, args, userContext)
  ↓
Validate tool call (permissions, rate limit, parameters)
  ↓
Execute tool handler
  ↓
Collect tool results
  ↓
Generate response from tool results
```

**Tool Results Format:**
```javascript
{
    tool: "search_products",
    success: true,
    result: { products: [...], total_found: 10 }
}
```

#### 3.3. Generate Response From Tool Results

```javascript
async _generateResponseFromToolResults(toolResults, originalMessage)
```

**Nếu Gemini enabled:**
- Gọi Gemini lần 2 với tool results
- Gemini tạo response tự nhiên từ kết quả

**Nếu Gemini disabled:**
- Sử dụng `_buildFallbackResponseFromTools()`:
  - Format kết quả theo từng tool type
  - Tạo response text từ formatted results

---

### 4. Tool Orchestrator

**File:** `api/src/services/chat/ToolOrchestrator.js`

#### 4.1. Validate Tool Call

```javascript
async validateToolCall(toolName, parameters, userContext)
```

**Validation:**
1. Tool tồn tại trong ToolRegistry
2. User có quyền (role-based access)
3. Parameters hợp lệ (type, required, format)
4. Rate limit (dựa trên user role)

**Rate Limits:**
- Guest: 5 calls/phút
- Customer: 20 calls/phút
- Staff: 50 calls/phút
- Manager: 100 calls/phút
- Admin: Unlimited

#### 4.2. Execute Tool Call

```javascript
async executeToolCall(toolName, parameters, userContext)
```

**Flow:**
```
Validate tool call
  ↓
Get tool definition từ ToolRegistry
  ↓
Load ToolHandlers module
  ↓
Get handler method (toolDef.handler = "ToolHandlers.methodName")
  ↓
Inject user context nếu cần
  ↓
Execute handler method
  ↓
Return result
```

**Tool Handlers** (`api/src/services/chat/ToolHandlers.js`):
- `getBranchMenu(branch_id)`
- `searchProducts(keyword, branch_id, ...)`
- `checkTableAvailability(branch_id, date, time, guest_count)`
- `createReservation(user_id, branch_id, date, time, guest_count)`
- `getAllBranches()`
- `getBranchDetails(branch_id)`
- `getMyOrders(user_id)`
- `getMyReservations(user_id)`
- ... và nhiều tools khác

---

### 5. Intent Handlers

#### 5.1. BookingIntentHandler

**File:** `api/src/services/chat/handlers/BookingIntentHandler.js`

**Intents:** `book_table`, `book_table_partial`, `confirm_booking`, `modify_booking`

**Flow:**
```
Validate entities (BookingValidator)
  ↓
Nếu thiếu thông tin:
  - Build prompt hỏi thông tin thiếu
  - Tạo suggestions cho branch nếu cần
  ↓
Nếu đủ thông tin:
  - BookingHandler.handleSmartBooking()
  - Check table availability
  - Tạo reservation nếu có thể
  ↓
Return response với reservation details
```

**BookingValidator** kiểm tra:
- `people`/`guest_count`: Số người (required)
- `date`/`reservation_date`: Ngày (required)
- `time`/`reservation_time`: Giờ (required)
- `branch_id` hoặc `branch_name`: Chi nhánh (required)

#### 5.2. MenuIntentHandler

**File:** `api/src/services/chat/handlers/MenuIntentHandler.js`

**Intents:** `view_menu`, `view_menu_specific_branch`

**Flow:**
```
Extract branch từ message hoặc context
  ↓
Nếu có branch_id:
  - Tool: get_branch_menu(branch_id)
  - Format menu theo categories
  - Tạo suggestions để navigate
  ↓
Nếu không có branch:
  - Tool: get_all_branches()
  - Tạo suggestions cho mỗi branch
```

#### 5.3. BranchIntentHandler

**File:** `api/src/services/chat/handlers/BranchIntentHandler.js`

**Intents:** `view_branches`, `ask_branch`, `find_nearest_branch`

**Flow:**
```
Nếu find_nearest_branch:
  - Lấy user location từ context
  - Tool: get_all_branches()
  - Calculate distance (nếu có location)
  - Sort by distance
  ↓
Nếu ask_branch:
  - Extract branch name/location từ message
  - Tool: get_all_branches() hoặc search
  - Filter branches
  ↓
Format branch list với địa chỉ, phone, giờ làm việc
```

#### 5.4. SearchIntentHandler

**File:** `api/src/services/chat/handlers/SearchIntentHandler.js`

**Intents:** `search_food`, `search_product`

**Flow:**
```
Extract keyword từ message
  ↓
Extract branch_id từ context (nếu có)
  ↓
Tool: search_products({ keyword, branch_id, ... })
  ↓
Format results:
  - List products với giá
  - Limit 5-10 items
  - Tạo suggestions để xem chi tiết
```

#### 5.5. TakeawayIntentHandler

**File:** `api/src/services/chat/handlers/TakeawayIntentHandler.js`

**Intents:** `order_takeaway`, `order_delivery`

**Flow:**
```
Nếu order_delivery:
  - Kiểm tra delivery address trong context
  - Nếu chưa có: Hỏi địa chỉ
  - Nếu có: Tool: get_all_branches()
  - Tạo suggestions cho mỗi branch
  ↓
Nếu order_takeaway:
  - Tool: get_all_branches()
  - Tạo suggestions cho mỗi branch
```

---

### 6. Context Management

#### 6.1. ConversationService

**File:** `api/src/services/chat/ConversationService.js`

**Chức năng:**
- `getOrCreateConversation()`: Tạo hoặc lấy conversation
- `updateConversationContext()`: Update context_data
- `getConversationHistory()`: Lấy lịch sử tin nhắn
- `resetConversation()`: Reset conversation

**Context Data Structure:**
```json
{
  "lastBranchId": 5,
  "lastBranch": "Beast Bite - The Pearl District",
  "lastIntent": "book_table",
  "lastEntities": {
    "people": 2,
    "date": "2025-01-20",
    "time": "17:00"
  },
  "lastDeliveryAddress": "123 Đường ABC",
  "userLatitude": 10.123,
  "userLongitude": 106.456,
  "waitingForAddress": false
}
```

#### 6.2. ContextService

**File:** `api/src/services/chat/ContextService.js`

**Method:** `buildContext(userId, branchId, conversation)`

**Flow:**
```
1. Load user info (nếu có userId)
2. Load branch info (nếu có branchId)
3. Load cart (nếu có userId + branchId)
4. Load recent orders (3 đơn gần nhất)
5. Load conversation history (50 tin gần nhất)
6. Parse conversationContext từ context_data
7. Merge entities từ history vào context
8. Return complete context object
```

---

### 7. Response Generation

#### 7.1. ResponseComposer

**File:** `api/src/services/chat/ResponseComposer.js`

**Method:** `buildAndSave(conversation, context, result, userId, branchId)`

**Flow:**
```
1. Extract message từ result
2. Tạo suggestions từ ResponseHandler
3. Format response object:
   - message
   - intent
   - entities
   - suggestions
   - action
   - action_data
   - type
4. Save bot message vào database
5. Update conversation context nếu cần
6. Return formatted response
```

#### 7.2. ResponseHandler

**File:** `api/src/services/chat/ResponseHandler.js`

**Chức năng:**
- `getSuggestions(intent, branchId)`: Tạo suggestions dựa trên intent
- `getDefaultSuggestions(branchId)`: Suggestions mặc định

**Suggestions Format:**
```javascript
[
  {
    text: "📍 Beast Bite - The Pearl District",
    action: "select_branch_for_booking",
    data: {
      branch_id: 5,
      branch_name: "Beast Bite - The Pearl District"
    }
  },
  {
    text: "🕐 17:00",
    action: "select_time",
    data: { time: "17:00" }
  }
]
```

---

### 8. Action Execution

**File:** `api/src/controllers/ChatController.js`

**Endpoint:** `POST /chat/action`

**Actions được hỗ trợ:**
- `confirm_booking`: Xác nhận đặt bàn
- `select_branch_for_booking`: Chọn chi nhánh để đặt bàn
- `select_branch_for_takeaway`: Chọn chi nhánh cho takeaway
- `select_branch_for_delivery`: Chọn chi nhánh cho delivery
- `confirm_delivery_address`: Xác nhận địa chỉ giao hàng
- `add_to_cart`: Thêm món vào giỏ hàng
- `checkout_cart`: Thanh toán giỏ hàng
- `view_menu`: Xem menu
- `order_food`: Đặt món
- ... và nhiều actions khác

**Flow:**
```
User click suggestion/button
  ↓
Frontend gọi /chat/action với action + data
  ↓
ChatController.executeAction()
  ↓
Switch case theo action
  ↓
Execute logic tương ứng
  ↓
Return result
```

**Ví dụ: `confirm_booking`:**
```javascript
case 'confirm_booking':
    reservation = await BookingHandler.createActualReservation(userId, data)
    // Check existing cart
    // Return success message với suggestions
```

---

## Flow Diagram Tổng Quan

```
User Message
    ↓
ChatController.sendMessage()
    ↓
ChatService.processMessage()
    ↓
[1] Get/Create Conversation
    ↓
[2] Build Context (user, branch, history, cart, orders)
    ↓
[3] Extract Entities (date, time, people, branch, keyword)
    ↓
[4] Check Special Cases:
    - Greeting → Return welcome
    - Suggestion match → Route to handler
    - Booking flow → Route to BookingHandler
    - Nearest branch → Route to BranchHandler
    ↓
[5] LLM Pipeline:
    - AIService.callAI()
    - Gemini API (nếu enabled) hoặc Rule-based
    - Tool calling (get_branch_menu, search_products, etc.)
    - Generate response
    ↓
[6] Intent Routing:
    - IntentRouter.route()
    - Try handlers theo thứ tự
    - Handler xử lý và return response
    ↓
[7] Build & Save Response:
    - ResponseComposer.buildAndSave()
    - Format message
    - Create suggestions
    - Save to database
    - Update context
    ↓
[8] Return Response to User
```

---

## Key Features

### 1. Context-Aware Conversations
- Lưu ngữ cảnh trong `conversationContext`
- Merge entities từ các tin nhắn trước
- Nhớ branch đã chọn, địa chỉ giao hàng, etc.

### 2. Multi-Turn Dialogue
- Hỗ trợ hội thoại nhiều lượt
- Ví dụ: Đặt bàn qua nhiều bước (chọn branch → chọn ngày → chọn giờ → xác nhận)

### 3. Tool Calling Pattern
- AI có thể gọi functions để lấy dữ liệu thực
- Tools được validate (permissions, rate limit, parameters)
- Results được format và trả về user

### 4. Role-Based Access
- Different tools cho different roles
- Rate limits dựa trên role
- Admin/Manager có tools đặc biệt (revenue report, all users, etc.)

### 5. Fallback Handling
- Nếu Gemini API lỗi → Rule-based processing
- Nếu không match intent → DefaultIntentHandler
- Graceful degradation

### 6. Analytics Tracking
- Track messages (intent, response time, success)
- Track tool calls
- Track booking events
- Track errors

---

## Database Schema

### chat_conversations
- `id`: Primary key
- `user_id`: User ID
- `session_id`: Conversation session ID
- `branch_id`: Branch ID
- `context_data`: JSON context
- `status`: active/inactive
- `expires_at`: Expiration time
- `created_at`: Created time

### chat_messages
- `id`: Primary key
- `conversation_id`: Foreign key to chat_conversations
- `message_type`: user/bot
- `message_content`: Message text
- `intent`: Detected intent
- `entities`: JSON entities
- `suggestions`: JSON suggestions
- `action`: Action name
- `created_at`: Created time

---

## Error Handling

1. **Validation Errors**: Trả về 400 với message rõ ràng
2. **Authentication Errors**: Trả về 401
3. **Permission Errors**: Trả về 403
4. **Rate Limit Errors**: Trả về 429
5. **AI Service Errors**: Fallback to rule-based
6. **Database Errors**: Log và trả về error message
7. **Tool Execution Errors**: Log và trả về error trong tool result

---

## Best Practices

1. **Luôn validate input** trước khi xử lý
2. **Luôn sanitize user input** để tránh injection
3. **Luôn check permissions** trước khi gọi tools
4. **Luôn update context** sau khi có thay đổi quan trọng
5. **Luôn save messages** vào database để có history
6. **Luôn tạo suggestions** để guide user
7. **Luôn handle errors** gracefully với fallback

---

## Kết Luận

Chatbot sử dụng kiến trúc hybrid mạnh mẽ với:
- **AI-powered** cho xử lý ngôn ngữ tự nhiên
- **Rule-based** cho các case cụ thể và fallback
- **Tool calling** để lấy dữ liệu thực từ database
- **Context management** để duy trì ngữ cảnh
- **Intent routing** để điều hướng đến handler phù hợp

Flow được thiết kế để xử lý nhiều loại request khác nhau một cách linh hoạt và hiệu quả.



