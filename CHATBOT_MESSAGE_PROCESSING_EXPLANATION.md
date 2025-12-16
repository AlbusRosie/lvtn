# Giải Thích: Hệ Thống Nhận, Hiểu và Phân Tích Tin Nhắn

## Tổng Quan

Hệ thống chatbot sử dụng kiến trúc **hybrid** kết hợp:
- **Rule-based pattern matching** (phát hiện intent và trích xuất entities)
- **AI Service** (Google Gemini) với Tool Calling
- **Intent Router** (điều hướng đến handler phù hợp)
- **Context Management** (duy trì ngữ cảnh cuộc hội thoại)

---

## 1. NHẬN TIN NHẮN TỪ NGƯỜI DÙNG

### 1.1. Entry Point - API Endpoint

**File:** `api/src/routes/ChatRouter.js` → `api/src/controllers/ChatController.js`

**Flow:**
```
User gửi HTTP POST request
  ↓
Endpoint: POST /chat/message
  ↓
ChatController.sendMessage()
  ↓
Validate & Sanitize input
  ↓
ChatService.processMessage()
```

**Request Body:**
```json
{
  "message": "Tôi muốn đặt bàn 2 người lúc 7h tối mai",
  "branch_id": 1,
  "conversation_id": "uuid-session-id"
}
```

**Validation:**
- Kiểm tra `message` là string và không rỗng
- Validate `conversation_id` (nếu có)
- Validate `branch_id` (nếu có)
- Sanitize message (loại bỏ ký tự nguy hiểm)

---

## 2. PHÂN TÍCH TIN NHẮN (MESSAGE ANALYSIS)

### 2.1. Intent Detection (Phát Hiện Ý Định)

**File:** `api/src/services/chat/IntentDetector.js`

Hệ thống sử dụng **pattern matching** với regex để phát hiện intent:

```javascript
// Ví dụ: Phát hiện intent "book_table"
const bookingPatterns = [
    /(đặt bàn|book|reservation|chỗ ngồi|đặt chỗ)/i,
    /(\d+)\s*(nguoi|người|people).*(đặt bàn|book)/i,
    /(đặt bàn|book).*(\d+)\s*(nguoi|người|people)/i
];
```

**Các Intent được hỗ trợ:**
- `book_table` - Đặt bàn
- `view_menu` - Xem menu
- `search_food` - Tìm món ăn
- `order_food` - Đặt món
- `view_branches` - Xem chi nhánh
- `ask_branch` - Hỏi về chi nhánh
- `order_delivery` - Đặt giao hàng
- `order_takeaway` - Đặt mang về
- `view_orders` - Xem đơn hàng
- `greeting` - Chào hỏi
- `ask_info` - Hỏi thông tin (default)

**Ví dụ:**
```
Input: "Tôi muốn đặt bàn 2 người"
→ Intent: "book_table"

Input: "Có món bò không?"
→ Intent: "search_food"

Input: "Xem menu chi nhánh Diamond Plaza"
→ Intent: "view_menu_specific_branch"
```

### 2.2. Entity Extraction (Trích Xuất Thông Tin)

**File:** `api/src/services/chat/EntityExtractor.js`

Hệ thống trích xuất các **entities** (thông tin cụ thể) từ tin nhắn:

**Các Entity được trích xuất:**
- `people` / `guest_count` - Số người
- `time` / `reservation_time` - Giờ đặt bàn
- `date` / `reservation_date` - Ngày đặt bàn
- `branch_id` - ID chi nhánh
- `branch_name` - Tên chi nhánh
- `district_search_term` - Từ khóa tìm kiếm quận/huyện

**Ví dụ Parsing:**

```javascript
// Input: "Đặt bàn 2 người lúc 7h tối mai"
parseNaturalLanguage(message)
→ {
    people: 2,
    time: "19:00",
    date: "2024-01-21"  // ngày mai
  }

// Input: "Chi nhánh ở quận 1"
→ {
    district_search_term: "quận 1"
  }
```

**Cách trích xuất:**

1. **Số người:**
   ```javascript
   /(\d+)\s*(nguoi|người|people|person|pax)/i
   // "2 người" → people: 2
   ```

2. **Thời gian:**
   ```javascript
   /(\d{1,2})[hH:]\s*(\d{0,2})?\s*(am|pm|sáng|chiều|tối)/i
   // "7h tối" → time: "19:00"
   // "9:30 sáng" → time: "09:30"
   ```

3. **Ngày:**
   ```javascript
   /(ngày mai|tomorrow)/i → date: tomorrow
   /(hôm nay|today)/i → date: today
   ```

4. **Tên chi nhánh:**
   ```javascript
   /(?:xem menu|menu|chi nhánh)\s+(.+?)(?:\s|$)/i
   // "menu chi nhánh Diamond Plaza" → branch_name: "Diamond Plaza"
   ```

### 2.3. Context Building (Xây Dựng Ngữ Cảnh)

**File:** `api/src/services/chat/ContextService.js`

Hệ thống xây dựng **context** từ:
- Thông tin user (id, name, address, phone)
- Chi nhánh hiện tại (nếu có)
- Giỏ hàng của user
- Lịch sử đơn hàng (3 đơn gần nhất)
- Lịch sử hội thoại (50 tin nhắn gần nhất)
- Ngữ cảnh cuộc hội thoại (lastIntent, lastBranchId, lastEntities)

**Context Structure:**
```javascript
{
  user: { id, name, email, address, phone },
  branch: { id, name, address },
  cart: { items, total },
  recentOrders: [...],
  conversationHistory: [...],
  conversationContext: {
    lastIntent: "book_table",
    lastBranchId: 5,
    lastBranch: "Diamond Plaza",
    lastEntities: { people: 2, time: "19:00" }
  }
}
```

---

## 3. XỬ LÝ TIN NHẮN (MESSAGE PROCESSING)

### 3.1. Flow Chính trong ChatService

**File:** `api/src/services/ChatService.js` → `processMessage()`

**Flow xử lý:**

```
1. Get/Create Conversation
   ↓
2. Build Context
   ↓
3. Check if greeting (new conversation)
   ↓
4. Save user message
   ↓
5. Match suggestion from history (nếu user click button)
   ↓
6. Extract entities từ message
   ↓
7. Merge entities với context (lastEntities)
   ↓
8. Check special flows:
   - Booking flow (đã chọn chi nhánh + có đủ thông tin)
   - Nearest branch query
   ↓
9. Call AI Service (Gemini) hoặc Rule-based
   ↓
10. Route intent đến handler phù hợp
   ↓
11. Build & Save response
```

### 3.2. AI Service Processing

**File:** `api/src/services/chat/AIService.js`

**Hai chế độ:**

#### A. Gemini AI Mode (nếu có API key):
```javascript
1. Build system prompt với context
2. Gọi Gemini API với:
   - User message
   - Conversation history
   - Available tools (functions)
3. Gemini có thể gọi tools (function calling)
4. Xử lý kết quả từ tools
5. Generate response từ tool results
```

#### B. Rule-based Mode (fallback):
```javascript
1. Pattern matching với keywords
2. Gọi tools trực tiếp (không qua AI)
3. Format response từ tool results
```

**Tools Available:**
- `search_products` - Tìm món ăn
- `get_branch_menu` - Lấy menu chi nhánh
- `get_all_branches` - Lấy danh sách chi nhánh
- `check_table_availability` - Kiểm tra bàn trống
- `create_reservation` - Tạo đặt bàn
- `get_my_orders` - Lấy đơn hàng của user
- ... và nhiều tools khác

### 3.3. Intent Routing

**File:** `api/src/services/chat/IntentRouter.js`

Sau khi có intent và entities, hệ thống **route** đến handler phù hợp:

```javascript
const handlers = [
    new BookingIntentHandler(),    // Xử lý đặt bàn
    new TakeawayIntentHandler(),    // Xử lý takeaway
    new MenuIntentHandler(),        // Xử lý xem menu
    new BranchIntentHandler(),      // Xử lý chi nhánh
    new SearchIntentHandler(),      // Xử lý tìm kiếm
    new DefaultIntentHandler(),     // Handler mặc định
];

// Mỗi handler có method canHandle() và handle()
for (const handler of handlers) {
    if (handler.canHandle(intent, context, metadata)) {
        return await handler.handle(payload);
    }
}
```

**Ví dụ Handler:**

```javascript
// BookingIntentHandler.js
canHandle(intent, context, metadata) {
    return intent === 'book_table' || 
           intent === 'book_table_specific_branch';
}

async handle(payload) {
    const { entities, context } = payload;
    
    // Kiểm tra có đủ thông tin chưa
    if (!entities.branch_id) {
        // Hỏi user chọn chi nhánh
        return { suggestions: branchSuggestions };
    }
    
    if (!entities.people || !entities.time) {
        // Hỏi thêm thông tin
        return { message: "Bạn muốn đặt mấy người? Lúc mấy giờ?" };
    }
    
    // Đủ thông tin → Kiểm tra bàn trống
    const availability = await checkTableAvailability(...);
    
    if (availability.available) {
        // Tạo đặt bàn
        return { 
            message: "Có bàn trống! Bạn có muốn đặt không?",
            suggestions: [confirmButton]
        };
    }
}
```

---

## 4. XÁC ĐỊNH HÀNH ĐỘNG (ACTION DETERMINATION)

### 4.1. Cách Hệ Thống Biết Làm Gì

Hệ thống xác định hành động dựa trên:

1. **Intent** (ý định của user)
2. **Entities** (thông tin đã có)
3. **Context** (ngữ cảnh cuộc hội thoại)
4. **Metadata** (thông tin bổ sung)

**Ví dụ Flow:**

```
User: "Tôi muốn đặt bàn"

Step 1: Intent Detection
→ Intent: "book_table"

Step 2: Entity Extraction
→ Entities: {} (chưa có thông tin)

Step 3: Context Check
→ conversationContext.lastBranchId = null
→ conversationContext.lastIntent = null

Step 4: Handler Logic (BookingIntentHandler)
→ if (!entities.branch_id) {
     // Chưa có chi nhánh → Hỏi user chọn
     return {
       message: "Bạn muốn đặt bàn tại chi nhánh nào?",
       suggestions: [danh sách chi nhánh]
     };
   }

Step 5: Response
→ Action: "select_branch"
→ Action_data: { branches: [...] }
```

**Tiếp tục:**

```
User: "Chi nhánh Diamond Plaza" (hoặc click button)

Step 1: Entity Extraction
→ branch_name: "Diamond Plaza"
→ branch_id: 5 (tìm từ database)

Step 2: Update Context
→ conversationContext.lastBranchId = 5
→ conversationContext.lastBranch = "Diamond Plaza"
→ conversationContext.lastIntent = "book_table"

Step 3: Handler Logic
→ if (entities.branch_id && !entities.people) {
     // Có chi nhánh nhưng chưa có số người
     return {
       message: "Bạn muốn đặt mấy người?",
       suggestions: [1, 2, 3, 4, 5+]
     };
   }
```

**Tiếp tục:**

```
User: "2 người lúc 7h tối mai"

Step 1: Entity Extraction
→ people: 2
→ time: "19:00"
→ date: "2024-01-21"

Step 2: Merge với Context
→ entities = {
     branch_id: 5,  // từ context
     branch_name: "Diamond Plaza",
     people: 2,
     time: "19:00",
     date: "2024-01-21"
   }

Step 3: Handler Logic
→ if (entities.branch_id && entities.people && entities.time) {
     // Đủ thông tin → Kiểm tra bàn trống
     const result = await checkTableAvailability({
       branch_id: 5,
       date: "2024-01-21",
       time: "19:00",
       guest_count: 2
     });
     
     if (result.available) {
       return {
         message: "Có bàn trống! Bạn có muốn đặt không?",
         action: "confirm_booking",
         action_data: { ...entities }
       };
     }
   }
```

### 4.2. Action Types

**Các action được hỗ trợ:**

- `confirm_booking` - Xác nhận đặt bàn
- `order_food` - Đặt món
- `view_menu` - Xem menu
- `select_branch` - Chọn chi nhánh
- `select_branch_for_booking` - Chọn chi nhánh để đặt bàn
- `select_branch_for_delivery` - Chọn chi nhánh để giao hàng
- `select_branch_for_takeaway` - Chọn chi nhánh để takeaway
- `add_to_cart` - Thêm vào giỏ hàng
- `checkout_cart` - Thanh toán giỏ hàng
- `navigate_menu` - Điều hướng đến menu
- `enter_delivery_address` - Nhập địa chỉ giao hàng
- ... và nhiều action khác

**Action được xử lý ở:**
- `ChatController.executeAction()` - Xử lý action từ frontend
- Các Intent Handlers - Tạo action trong response

---

## 5. VÍ DỤ HOÀN CHỈNH

### Ví dụ 1: Đặt Bàn

```
User: "Tôi muốn đặt bàn 2 người lúc 7h tối mai tại chi nhánh Diamond Plaza"

Step 1: ChatController.sendMessage()
  → Validate message
  → ChatService.processMessage()

Step 2: Intent Detection
  → IntentDetector.detectIntent()
  → Intent: "book_table"

Step 3: Entity Extraction
  → EntityExtractor.extractEntities()
  → Entities: {
      people: 2,
      time: "19:00",
      date: "2024-01-21",
      branch_name: "Diamond Plaza"
    }

Step 4: Branch Lookup
  → EntityExtractor.extractBranchFromMessage()
  → branch_id: 5 (tìm từ database)

Step 5: Merge Entities
  → entities = {
      branch_id: 5,
      branch_name: "Diamond Plaza",
      people: 2,
      time: "19:00",
      date: "2024-01-21"
    }

Step 6: Intent Routing
  → IntentRouter.route()
  → BookingIntentHandler.canHandle() → true
  → BookingIntentHandler.handle()

Step 7: Check Table Availability
  → checkTableAvailability({
      branch_id: 5,
      date: "2024-01-21",
      time: "19:00",
      guest_count: 2
    })
  → Result: { available: true, tables: [...] }

Step 8: Build Response
  → ResponseComposer.buildAndSave()
  → {
      message: "Có bàn trống vào 7h tối mai! Bạn có muốn đặt không?",
      intent: "book_table",
      entities: { ... },
      action: "confirm_booking",
      action_data: { ...entities },
      suggestions: [
        { text: "Xác nhận đặt bàn", action: "confirm_booking", data: {...} }
      ]
    }

Step 9: Save to Database
  → MessageService.saveMessage() (user message)
  → MessageService.saveMessage() (bot response)

Step 10: Return Response
  → ChatController trả về JSON response
```

### Ví dụ 2: Tìm Món Ăn

```
User: "Có món bò không?"

Step 1: Intent Detection
  → Intent: "search_food"

Step 2: Entity Extraction
  → keyword: "bò"

Step 3: AI Service (hoặc Rule-based)
  → AIService.callAI()
  → Gemini gọi tool: search_products({ keyword: "bò" })
  → ToolOrchestrator.executeToolCall()
  → Database query: SELECT * FROM products WHERE name LIKE '%bò%'
  → Results: [product1, product2, ...]

Step 4: Generate Response
  → Response: "Tôi tìm thấy 5 món bò:
      • Bò nướng - 150,000đ
      • Bò kho - 120,000đ
      ..."

Step 5: Intent Routing
  → SearchIntentHandler.handle()
  → Return formatted response với suggestions
```

---

## 6. TÓM TẮT QUY TRÌNH

```
┌─────────────────────────────────────────┐
│  1. NHẬN TIN NHẮN                        │
│     - HTTP POST /chat/message            │
│     - Validate & Sanitize                │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  2. PHÂN TÍCH TIN NHẮN                   │
│     - Intent Detection (pattern match)  │
│     - Entity Extraction (regex parsing)  │
│     - Context Building                  │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  3. XỬ LÝ AI/Tools                      │
│     - AI Service (Gemini) hoặc          │
│     - Rule-based tool calling           │
│     - Execute tools (database queries)  │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  4. INTENT ROUTING                      │
│     - Route đến handler phù hợp         │
│     - Handler xử lý logic cụ thể        │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  5. XÁC ĐỊNH HÀNH ĐỘNG                  │
│     - Dựa trên intent + entities        │
│     - Dựa trên context                  │
│     - Tạo action & suggestions          │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  6. BUILD & SAVE RESPONSE               │
│     - Format response message           │
│     - Add suggestions/buttons           │
│     - Save to database                  │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  7. TRẢ VỀ KẾT QUẢ                      │
│     - JSON response với:                │
│       - message (text)                  │
│       - intent                          │
│       - entities                        │
│       - action                          │
│       - suggestions                     │
└─────────────────────────────────────────┘
```

---

## 7. CÁC FILE QUAN TRỌNG

### Core Processing:
- `api/src/controllers/ChatController.js` - Entry point
- `api/src/services/ChatService.js` - Core processing logic
- `api/src/services/chat/IntentDetector.js` - Intent detection
- `api/src/services/chat/EntityExtractor.js` - Entity extraction
- `api/src/services/chat/ContextService.js` - Context building

### AI & Routing:
- `api/src/services/chat/AIService.js` - AI processing (Gemini)
- `api/src/services/chat/IntentRouter.js` - Intent routing
- `api/src/services/chat/handlers/*.js` - Intent handlers

### Support Services:
- `api/src/services/chat/ConversationService.js` - Conversation management
- `api/src/services/chat/MessageService.js` - Message storage
- `api/src/services/chat/ResponseComposer.js` - Response building
- `api/src/services/chat/ToolOrchestrator.js` - Tool execution

---

## 8. KẾT LUẬN

Hệ thống chatbot sử dụng **multi-layer approach**:

1. **Pattern Matching** (nhanh, chính xác cho các case phổ biến)
2. **AI Processing** (linh hoạt, hiểu ngữ cảnh phức tạp)
3. **Rule-based Handlers** (xử lý logic nghiệp vụ cụ thể)
4. **Context Management** (duy trì ngữ cảnh cuộc hội thoại)

Kết hợp các phương pháp này giúp hệ thống:
- ✅ Hiểu được ý định của user
- ✅ Trích xuất thông tin chính xác
- ✅ Xác định hành động phù hợp
- ✅ Duy trì ngữ cảnh cuộc hội thoại
- ✅ Xử lý các trường hợp phức tạp

