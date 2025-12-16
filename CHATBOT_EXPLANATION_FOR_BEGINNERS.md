# Giải Thích Chatbot Cho Người Mới Bắt Đầu - Beast Bite

## 📚 Mục Lục
1. [Chatbot là gì?](#chatbot-là-gì)
2. [Các thành phần cơ bản](#các-thành-phần-cơ-bản)
3. [Flow hoạt động từng bước](#flow-hoạt-động-từng-bước)
4. [Ví dụ cụ thể](#ví-dụ-cụ-thể)
5. [Giải thích từng component](#giải-thích-từng-component)

--- 

## 🤖 Chatbot là gì?

**Chatbot** là một chương trình máy tính có thể **trò chuyện với người dùng** như một người thật.

### Ví dụ đơn giản:
```
User: "Xin chào"
Bot: "Xin chào! Tôi có thể giúp gì cho bạn?"

User: "Tôi muốn đặt bàn"
Bot: "Bạn muốn đặt bàn cho bao nhiêu người?"

User: "2 người"
Bot: "Bạn muốn đặt vào ngày nào?"
```

### Chatbot của Beast Bite có thể:
- ✅ Đặt bàn nhà hàng
- ✅ Xem menu
- ✅ Tìm kiếm món ăn
- ✅ Tìm chi nhánh gần nhất
- ✅ Đặt món giao hàng/takeaway
- ✅ Xem đơn hàng

---

## 🧩 Các Thành Phần Cơ Bản

### 1. **Intent (Ý định)**
**Intent** là **mục đích** của câu nói người dùng.

**Ví dụ:**
- User nói: "Tôi muốn đặt bàn" → Intent: `book_table`
- User nói: "Xem menu" → Intent: `view_menu`
- User nói: "Có món bò không?" → Intent: `search_food`

**Các Intent phổ biến:**
- `greeting`: Chào hỏi
- `book_table`: Đặt bàn
- `view_menu`: Xem menu
- `search_food`: Tìm món ăn
- `view_branches`: Xem chi nhánh
- `order_delivery`: Đặt giao hàng
- `order_takeaway`: Đặt mang về

### 2. **Entity (Thực thể)**
**Entity** là **thông tin cụ thể** được trích xuất từ câu nói.

**Ví dụ:**
- User: "Đặt bàn 2 người ngày mai 7h tối"
  - Entity: `people = 2`
  - Entity: `date = "2025-01-21"` (ngày mai)
  - Entity: `time = "19:00"` (7h tối)

- User: "Xem menu chi nhánh Diamond Plaza"
  - Entity: `branch_name = "Diamond Plaza"`

**Các Entity phổ biến:**
- `people`/`guest_count`: Số người
- `date`/`reservation_date`: Ngày
- `time`/`reservation_time`: Giờ
- `branch_id`: ID chi nhánh
- `branch_name`: Tên chi nhánh
- `keyword`: Từ khóa tìm kiếm

### 3. **Context (Ngữ cảnh)**
**Context** là **thông tin từ các câu nói trước** để hiểu cuộc hội thoại.

**Ví dụ:**
```
Lần 1:
User: "Tôi muốn đặt bàn"
Bot: "Bạn muốn đặt tại chi nhánh nào?"
→ Context: lastIntent = "book_table"

Lần 2:
User: "Diamond Plaza"
Bot: "Bạn muốn đặt cho bao nhiêu người?"
→ Context: lastIntent = "book_table", lastBranchId = 5

Lần 3:
User: "2 người"
Bot: "Bạn muốn đặt vào ngày nào?"
→ Context: lastIntent = "book_table", lastBranchId = 5, people = 2
```

**Context lưu:**
- `lastIntent`: Intent vừa xử lý
- `lastBranchId`: Chi nhánh vừa chọn
- `lastEntities`: Entities từ các tin nhắn trước
- `lastDeliveryAddress`: Địa chỉ giao hàng (nếu có)

### 4. **Handler (Xử lý)**
**Handler** là **chương trình xử lý** một loại intent cụ thể.

**Ví dụ:**
- `BookingIntentHandler`: Xử lý đặt bàn
- `MenuIntentHandler`: Xử lý xem menu
- `SearchIntentHandler`: Xử lý tìm kiếm món ăn

### 5. **Tool (Công cụ)**
**Tool** là **function** để lấy dữ liệu từ database.

**Ví dụ:**
- `get_branch_menu(branch_id)`: Lấy menu của chi nhánh
- `search_products(keyword)`: Tìm món ăn
- `check_table_availability(branch_id, date, time, guest_count)`: Kiểm tra bàn trống
- `create_reservation(...)`: Tạo đặt bàn

---

## 🔄 Flow Hoạt Động Từng Bước

### Bước 1: User gửi message

```
User gửi: "Tôi muốn đặt bàn 2 người ngày mai 7h tối"
```

### Bước 2: Controller nhận request

**File:** `api/src/controllers/ChatController.js`

```javascript
// Endpoint: POST /chat/message
async function sendMessage(req, res) {
    const { message, branch_id, conversation_id } = req.body;
    const user_id = req.user?.id;
    
    // Validate input
    if (!message) {
        return error("Message is required");
    }
    
    // Sanitize (làm sạch) message
    const sanitizedMessage = Utils.validateChatInput(message);
    
    // Gọi ChatService để xử lý
    const result = await ChatService.processMessage({
        message: sanitizedMessage,
        userId: user_id,
        branchId: branch_id,
        conversationId: conversation_id
    });
    
    // Trả về response
    return success(result);
}
```

**Chức năng:**
- ✅ Nhận message từ user
- ✅ Validate (kiểm tra) input
- ✅ Sanitize (làm sạch) để tránh hack
- ✅ Gọi ChatService để xử lý
- ✅ Trả về kết quả

### Bước 3: Get/Create Conversation

**File:** `api/src/services/chat/ConversationService.js`

```javascript
conversation = await ConversationService.getOrCreateConversation(
    userId, 
    conversationId, 
    branchId
);
```

**Chức năng:**
- Tìm conversation hiện có (nếu có `conversation_id`)
- Nếu không có → Tạo mới
- Lưu vào database với `session_id` duy nhất

**Ví dụ:**
```
Conversation mới:
{
    id: 123,
    session_id: "user_5_1705123456",
    user_id: 5,
    branch_id: null,
    context_data: "{}",
    created_at: "2025-01-20 10:00:00"
}
```

### Bước 4: Build Context

**File:** `api/src/services/chat/ContextService.js`

```javascript
context = await ContextService.buildContext(userId, branchId, conversation);
```

**Context bao gồm:**

```javascript
{
    // Thông tin user
    user: {
        id: 5,
        name: "Nguyễn Văn A",
        email: "a@example.com",
        phone: "0123456789"
    },
    
    // Thông tin chi nhánh (nếu có)
    branch: {
        id: 3,
        name: "Beast Bite - Diamond Plaza",
        address: "123 Đường ABC"
    },
    
    // Giỏ hàng (nếu có)
    cart: {
        id: 10,
        items: [...]
    },
    
    // 3 đơn hàng gần nhất
    recentOrders: [
        { id: 1, total: 500000, status: "completed" },
        { id: 2, total: 300000, status: "pending" }
    ],
    
    // Lịch sử tin nhắn (50 tin gần nhất)
    conversationHistory: [
        { message_type: "user", message_content: "Xin chào" },
        { message_type: "bot", message_content: "Xin chào!..." }
    ],
    
    // Ngữ cảnh từ context_data
    conversationContext: {
        lastIntent: "book_table",
        lastBranchId: 3,
        lastEntities: { people: 2 }
    }
}
```

**Chức năng:**
- ✅ Load thông tin user từ database
- ✅ Load thông tin branch (nếu có)
- ✅ Load giỏ hàng (nếu có)
- ✅ Load lịch sử đơn hàng
- ✅ Load lịch sử tin nhắn
- ✅ Parse context từ `context_data`

### Bước 5: Extract Entities

**File:** `api/src/services/chat/EntityExtractor.js`

```javascript
extractedEntities = await EntityExtractor.extractEntities(message);
```

**Ví dụ với message: "Tôi muốn đặt bàn 2 người ngày mai 7h tối"**

```javascript
// EntityExtractor sẽ:
1. Tìm số người: "2 người" → people = 2
2. Tìm ngày: "ngày mai" → date = "2025-01-21"
3. Tìm giờ: "7h tối" → time = "19:00"

// Kết quả:
{
    people: 2,
    guest_count: 2,
    number_of_people: 2,
    date: "2025-01-21",
    reservation_date: "2025-01-21",
    time: "19:00",
    reservation_time: "19:00"
}
```

**Cách hoạt động:**
- Sử dụng **Regular Expression (Regex)** để tìm pattern
- Ví dụ: `/(\d+)\s*(nguoi|người|people)/i` để tìm số người
- Ví dụ: `/(ngay+y?\s+mai|tomorrow)/i` để tìm "ngày mai"
- Ví dụ: `/(\d{1,2})[hH]\s*(tối|toi|pm)/i` để tìm giờ

**Merge với entities cũ:**
```javascript
// Entities từ tin nhắn trước
lastEntities = { branch_id: 3, branch_name: "Diamond Plaza" }

// Entities mới extract
newEntities = { people: 2, date: "2025-01-21", time: "19:00" }

// Merge (gộp lại)
mergedEntities = {
    ...lastEntities,  // branch_id: 3, branch_name: "Diamond Plaza"
    ...newEntities    // people: 2, date: "2025-01-21", time: "19:00"
}
```

### Bước 6: Detect Intent

**File:** `api/src/services/chat/IntentDetector.js`

```javascript
intent = IntentDetector.detectIntent(message);
```

**Cách hoạt động:**
- Sử dụng **pattern matching** để nhận diện intent
- So khớp message với các pattern đã định nghĩa

**Ví dụ:**
```javascript
// Pattern cho book_table
/(đặt bàn|book|reservation)/i

// Pattern cho view_menu
/(xem menu|menu|thực đơn)/i

// Pattern cho search_food
/(có món|có gì|tìm món)/i
```

**Kết quả:**
- Message: "Tôi muốn đặt bàn" → Intent: `book_table`
- Message: "Xem menu" → Intent: `view_menu`
- Message: "Có món bò không?" → Intent: `search_food`

### Bước 7: AI Processing (LLM Pipeline)

**File:** `api/src/services/chat/AIService.js`

```javascript
llmResult = await AIService.callAI(message, context, fallback);
```

**Có 2 cách xử lý:**

#### Cách 1: Gemini AI (nếu enabled)

```javascript
// 1. Build system prompt với context
systemPrompt = `
Bạn là trợ lý ảo của nhà hàng Beast Bite.
Context: User đã chọn branch_id=3
Available tools: get_branch_menu, search_products, ...
Rules: BẮT BUỘC gọi tools để lấy dữ liệu thực
`;

// 2. Gọi Gemini API
geminiResponse = await geminiModel.generateContent({
    prompt: systemPrompt + message,
    tools: availableTools
});

// 3. Gemini có thể trả về:
// - Text response: "Tôi sẽ kiểm tra menu cho bạn..."
// - Function calls: [{ name: "get_branch_menu", args: { branch_id: 3 } }]
```

**Nếu Gemini gọi function:**
```javascript
// Gemini trả về function call
functionCalls = [
    {
        name: "get_branch_menu",
        args: { branch_id: 3 }
    }
];

// Execute function
toolResult = await ToolOrchestrator.executeToolCall(
    "get_branch_menu",
    { branch_id: 3 },
    userContext
);

// Kết quả
toolResult = {
    success: true,
    data: {
        menu: {
            "Món chính": [
                { name: "Bò bít tết", price: 250000 },
                { name: "Gà nướng", price: 180000 }
            ],
            "Đồ uống": [...]
        }
    }
};

// Gemini tạo response từ kết quả
finalResponse = await geminiModel.generateContent({
    prompt: `Tool results: ${JSON.stringify(toolResult.data)}. 
             Tạo response tự nhiên cho user.`
});
```

#### Cách 2: Rule-based (nếu Gemini disabled)

```javascript
// Pattern matching đơn giản
if (/(có món|co mon|tìm món)/i.test(message)) {
    // Gọi tool trực tiếp
    result = await ToolOrchestrator.executeToolCall(
        "search_products",
        { keyword: extractedKeyword },
        userContext
    );
    
    // Format response thủ công
    response = `Tìm thấy ${result.data.products.length} món: ...`;
}
```

### Bước 8: Intent Routing

**File:** `api/src/services/chat/IntentRouter.js`

```javascript
routedResponse = await intentRouter.route(routerPayload);
```

**Cách hoạt động:**

```javascript
// IntentRouter có danh sách handlers
handlers = [
    new BookingIntentHandler(),    // Xử lý đặt bàn
    new TakeawayIntentHandler(),   // Xử lý takeaway
    new MenuIntentHandler(),       // Xử lý menu
    new BranchIntentHandler(),    // Xử lý chi nhánh
    new SearchIntentHandler(),     // Xử lý tìm kiếm
    new DefaultIntentHandler()    // Fallback
];

// Duyệt qua từng handler
for (const handler of handlers) {
    // Kiểm tra handler có thể xử lý intent này không?
    if (handler.canHandle(intent, context, metadata)) {
        // Gọi handler xử lý
        result = await handler.handle(payload);
        if (result) {
            return result;  // Trả về kết quả
        }
    }
}
```

**Ví dụ với intent `book_table`:**

```javascript
// BookingIntentHandler.canHandle()
canHandle(intent, context) {
    return intent === 'book_table' || 
           intent === 'book_table_partial' ||
           intent === 'confirm_booking';
}

// BookingIntentHandler.handle()
async handle({ intent, message, context, entities, userId }) {
    // 1. Validate entities
    validation = BookingValidator.validate(entities);
    
    // 2. Nếu thiếu thông tin → hỏi lại
    if (validation.status === 'ask_missing') {
        return {
            intent: 'ask_info',
            response: 'Bạn muốn đặt cho bao nhiêu người?',
            entities: validation.entities,
            suggestions: [...]
        };
    }
    
    // 3. Nếu đủ thông tin → xử lý đặt bàn
    result = await BookingHandler.handleSmartBooking(message, context);
    
    // 4. Return response
    return result;
}
```

### Bước 9: Build và Save Response

**File:** `api/src/services/chat/ResponseComposer.js`

```javascript
response = await ResponseComposer.buildAndSave(
    conversation, 
    context, 
    result, 
    userId, 
    branchId
);
```

**Cách hoạt động:**

```javascript
// 1. Extract message từ result
message = result.response || result.message;

// 2. Tạo suggestions (nút hành động)
suggestions = await ResponseHandler.getSuggestions(intent, branchId);

// Ví dụ suggestions:
suggestions = [
    {
        text: "📍 Beast Bite - Diamond Plaza",
        action: "select_branch_for_booking",
        data: { branch_id: 3, branch_name: "Diamond Plaza" }
    },
    {
        text: "🕐 19:00",
        action: "select_time",
        data: { time: "19:00" }
    }
];

// 3. Format response object
response = {
    message: "Bạn muốn đặt bàn tại chi nhánh nào?",
    intent: "book_table",
    entities: { people: 2, date: "2025-01-21", time: "19:00" },
    suggestions: suggestions,
    action: "select_branch_for_booking",
    action_data: null,
    type: "text",
    conversation_id: "user_5_1705123456"
};

// 4. Save bot message vào database
await MessageService.saveMessage(
    conversation.id,
    'bot',
    response.message,
    response.intent,
    response.entities,
    response.action,
    response.suggestions
);

// 5. Update conversation context
await ConversationService.updateConversationContext(
    conversation.id,
    {
        lastIntent: "book_table",
        lastBranchId: 3,
        lastEntities: { people: 2, date: "2025-01-21", time: "19:00" }
    },
    userId
);

// 6. Return response
return response;
```

### Bước 10: Return Response to User

```json
{
    "status": "success",
    "data": {
        "id": "uuid-123",
        "message": "Bạn muốn đặt bàn tại chi nhánh nào?",
        "intent": "book_table",
        "entities": {
            "people": 2,
            "date": "2025-01-21",
            "time": "19:00"
        },
        "suggestions": [
            {
                "text": "📍 Beast Bite - Diamond Plaza",
                "action": "select_branch_for_booking",
                "data": {
                    "branch_id": 3,
                    "branch_name": "Diamond Plaza"
                }
            }
        ],
        "action": "select_branch_for_booking",
        "action_data": null,
        "type": "text",
        "conversation_id": "user_5_1705123456",
        "timestamp": "2025-01-20T10:00:00.000Z"
    }
}
```

---

## 📝 Ví Dụ Cụ Thể

### Ví Dụ 1: Đặt Bàn (Multi-turn)

#### Turn 1: User bắt đầu
```
User: "Tôi muốn đặt bàn"
```

**Flow:**
1. Extract entities: `{}` (chưa có gì)
2. Detect intent: `book_table`
3. AI/Router → `BookingIntentHandler`
4. Validate: Thiếu branch, people, date, time
5. Response: "Bạn muốn đặt tại chi nhánh nào?"

**Context sau turn 1:**
```json
{
    "lastIntent": "book_table",
    "lastEntities": {}
}
```

#### Turn 2: User chọn chi nhánh
```
User: "📍 Beast Bite - Diamond Plaza" (click suggestion)
```

**Flow:**
1. Match suggestion → `action: "select_branch_for_booking"`, `data: { branch_id: 3 }`
2. Update context: `lastBranchId = 3`
3. Response: "Bạn muốn đặt cho bao nhiêu người?"

**Context sau turn 2:**
```json
{
    "lastIntent": "book_table",
    "lastBranchId": 3,
    "lastBranch": "Beast Bite - Diamond Plaza",
    "lastEntities": { "branch_id": 3 }
}
```

#### Turn 3: User cung cấp thông tin
```
User: "2 người ngày mai 7h tối"
```

**Flow:**
1. Extract entities:
   - `people = 2`
   - `date = "2025-01-21"` (ngày mai)
   - `time = "19:00"` (7h tối)
2. Merge với context: `branch_id = 3` (từ turn 2)
3. Detect intent: `book_table`
4. Check: `isBookingFlow = true` (có lastBranchId), `hasBookingInfo = true` (có people + date + time)
5. Route → `BookingIntentHandler`
6. Validate: Đủ thông tin ✅
7. Call tool: `check_table_availability(branch_id=3, date="2025-01-21", time="19:00", guest_count=2)`
8. Tool result: `{ available: true, tables: [...] }`
9. Response: "Còn bàn trống! Bạn có muốn xác nhận đặt bàn không?"

**Context sau turn 3:**
```json
{
    "lastIntent": "book_table",
    "lastBranchId": 3,
    "lastBranch": "Beast Bite - Diamond Plaza",
    "lastEntities": {
        "branch_id": 3,
        "people": 2,
        "date": "2025-01-21",
        "time": "19:00"
    }
}
```

#### Turn 4: User xác nhận
```
User: "OK" (hoặc click "Xác nhận đặt bàn")
```

**Flow:**
1. Detect intent: `confirm_booking` (từ "OK")
2. Route → `BookingIntentHandler`
3. Call tool: `create_reservation(user_id=5, branch_id=3, date="2025-01-21", time="19:00", guest_count=2)`
4. Tool result: `{ success: true, reservation_id: 123 }`
5. Response: "🎉 Đặt bàn thành công! Mã đặt bàn: #123"

**Context sau turn 4:**
```json
{
    "lastIntent": "reservation_created",
    "lastBranchId": 3,
    "lastReservationId": 123,
    "lastEntities": {
        "branch_id": 3,
        "people": 2,
        "date": "2025-01-21",
        "time": "19:00",
        "reservation_id": 123
    }
}
```

### Ví Dụ 2: Tìm Món Ăn

```
User: "Có món bò không?"
```

**Flow:**
1. Extract entities:
   - `keyword = "bò"` (từ "món bò")
2. Detect intent: `search_food`
3. AI Processing:
   - Gemini gọi tool: `search_products({ keyword: "bò" })`
   - Tool result: `{ products: [{ name: "Bò bít tết", price: 250000 }, ...] }`
   - Gemini tạo response: "Chúng tôi có các món bò: Bò bít tết (250,000đ), ..."
4. Route → `SearchIntentHandler` (nếu cần format thêm)
5. Response: "Chúng tôi có các món bò:\n• Bò bít tết - 250,000đ\n• Bò kho - 180,000đ\n..."

### Ví Dụ 3: Xem Menu Chi Nhánh

```
User: "Xem menu chi nhánh Diamond Plaza"
```

**Flow:**
1. Extract entities:
   - `branch_name = "Diamond Plaza"`
   - Tìm branch_id từ tên → `branch_id = 3`
2. Detect intent: `view_menu_specific_branch`
3. AI Processing:
   - Gemini gọi tool: `get_branch_menu({ branch_id: 3 })`
   - Tool result: `{ menu: { "Món chính": [...], "Đồ uống": [...] } }`
   - Gemini tạo response: "Menu chi nhánh Diamond Plaza: ..."
4. Route → `MenuIntentHandler`
5. Response: "Menu chi nhánh Diamond Plaza:\n\nMón chính:\n• Bò bít tết - 250,000đ\n..."

---

## 🔧 Giải Thích Từng Component

### 1. ChatController

**Vị trí:** `api/src/controllers/ChatController.js`

**Chức năng:**
- Nhận HTTP request từ frontend
- Validate input
- Gọi ChatService
- Trả về HTTP response

**Code mẫu:**
```javascript
async function sendMessage(req, res) {
    // 1. Lấy data từ request
    const { message, branch_id, conversation_id } = req.body;
    const user_id = req.user?.id;
    
    // 2. Validate
    if (!message) {
        return res.status(400).json({ error: "Message is required" });
    }
    
    // 3. Sanitize (làm sạch)
    const sanitizedMessage = Utils.validateChatInput(message);
    
    // 4. Gọi ChatService
    const result = await ChatService.processMessage({
        message: sanitizedMessage,
        userId: user_id,
        branchId: branch_id,
        conversationId: conversation_id
    });
    
    // 5. Trả về response
    return res.json({ status: "success", data: result });
}
```

### 2. ChatService

**Vị trí:** `api/src/services/ChatService.js`

**Chức năng:**
- Orchestrator (điều phối) toàn bộ flow
- Gọi các service khác theo thứ tự
- Xử lý các trường hợp đặc biệt

**Flow chính:**
```javascript
async processMessage({ message, userId, branchId, conversationId }) {
    // 1. Get/Create conversation
    conversation = await ConversationService.getOrCreateConversation(...);
    
    // 2. Build context
    context = await ContextService.buildContext(...);
    
    // 3. Check greeting
    if (isNewConversation && isGreeting) {
        return GREETING_MESSAGE;
    }
    
    // 4. Match suggestion
    suggestionMatch = this._matchSuggestionFromHistory(message, context);
    if (suggestionMatch) {
        // Xử lý suggestion match
    }
    
    // 5. Extract entities
    extractedEntities = await EntityExtractor.extractEntities(message);
    mergedEntities = merge(lastEntities, extractedEntities);
    
    // 6. Check special cases
    if (isBookingFlow && hasBookingInfo) {
        // Route to BookingHandler
    }
    
    // 7. LLM Pipeline
    llmResult = await this._orchestrateLLMPipeline(...);
    
    // 8. Intent Routing
    routedResponse = await intentRouter.route(...);
    
    // 9. Build & Save Response
    result = await this._buildAndSaveResponse(...);
    
    return result;
}
```

### 3. EntityExtractor

**Vị trí:** `api/src/services/chat/EntityExtractor.js`

**Chức năng:**
- Trích xuất thông tin từ câu nói tự nhiên
- Sử dụng Regex pattern matching

**Ví dụ code:**
```javascript
// Tìm số người
const peopleMatch = message.match(/(\d+)\s*(nguoi|người|people)/i);
if (peopleMatch) {
    entities.people = parseInt(peopleMatch[1]);
}

// Tìm giờ
const timeMatch = message.match(/(\d{1,2})[hH]\s*(tối|toi|pm)/i);
if (timeMatch) {
    let hour = parseInt(timeMatch[1]);
    if (timeMatch[2] === 'tối' || timeMatch[2] === 'pm') {
        hour += 12;  // 7h tối = 19:00
    }
    entities.time = `${hour}:00`;
}

// Tìm ngày
if (message.match(/(ngày mai|tomorrow)/i)) {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    entities.date = tomorrow.toISOString().split('T')[0];
}
```

### 4. IntentDetector

**Vị trí:** `api/src/services/chat/IntentDetector.js`

**Chức năng:**
- Nhận diện intent từ message
- Sử dụng pattern matching

**Ví dụ code:**
```javascript
detectIntent(message) {
    const lower = message.toLowerCase();
    
    // Pattern cho book_table
    if (lower.match(/(đặt bàn|book|reservation)/i)) {
        return 'book_table';
    }
    
    // Pattern cho view_menu
    if (lower.match(/(xem menu|menu|thực đơn)/i)) {
        return 'view_menu';
    }
    
    // Pattern cho search_food
    if (lower.match(/(có món|có gì|tìm món)/i)) {
        return 'search_food';
    }
    
    // Default
    return 'ask_info';
}
```

### 5. AIService

**Vị trí:** `api/src/services/chat/AIService.js`

**Chức năng:**
- Gọi Google Gemini API
- Xử lý function calling
- Fallback nếu Gemini lỗi

**Flow:**
```javascript
async callAI(message, context, fallback) {
    // 1. Check Gemini enabled
    if (!this.geminiEnabled) {
        return await this._ruleBasedToolCalling(message, context, fallback);
    }
    
    // 2. Get available tools
    const availableTools = ToolOrchestrator.getAvailableToolsForLLM(userRole);
    
    // 3. Build system prompt
    const systemPrompt = this._buildSystemPrompt(context, availableTools);
    
    // 4. Build conversation history
    const history = this._buildConversationHistory(context);
    
    // 5. Call Gemini
    const response = await this._callGemini(message, context, availableTools);
    
    // 6. Handle function calls (nếu có)
    if (response.functionCalls && response.functionCalls.length > 0) {
        return await this._handleGeminiFunctionCalls(
            response.functionCalls, 
            message, 
            context
        );
    }
    
    // 7. Return text response
    return {
        intent: this._extractIntentFromMessage(response.text, message),
        entities: await EntityExtractor.extractEntities(message),
        response: response.text
    };
}
```

### 6. ToolOrchestrator

**Vị trí:** `api/src/services/chat/ToolOrchestrator.js`

**Chức năng:**
- Validate tool calls
- Execute tool handlers
- Rate limiting

**Flow:**
```javascript
async executeToolCall(toolName, parameters, userContext) {
    // 1. Validate
    await this.validateToolCall(toolName, parameters, userContext);
    
    // 2. Get tool definition
    const toolDef = getToolByName(toolName);
    
    // 3. Load handler
    const handlerMethod = ToolHandlers[toolDef.handler];
    
    // 4. Execute
    const result = await handlerMethod(parameters, userContext);
    
    // 5. Return
    return {
        success: true,
        data: result,
        tool: toolName
    };
}
```

### 7. Intent Handlers

**Vị trí:** `api/src/services/chat/handlers/`

**Chức năng:**
- Xử lý một loại intent cụ thể
- Mỗi handler có `canHandle()` và `handle()`

**Ví dụ: BookingIntentHandler**
```javascript
class BookingIntentHandler extends BaseIntentHandler {
    canHandle(intent, context) {
        return intent === 'book_table' || 
               intent === 'book_table_partial' ||
               intent === 'confirm_booking';
    }
    
    async handle({ intent, message, context, entities, userId }) {
        // 1. Validate entities
        const validation = BookingValidator.validate(entities);
        
        // 2. Nếu thiếu → hỏi lại
        if (validation.status === 'ask_missing') {
            return this.buildResponse({
                intent: 'ask_info',
                response: BookingValidator.buildMissingInfoPrompt(validation.missing),
                entities: validation.entities,
                suggestions: [...]
            });
        }
        
        // 3. Nếu đủ → xử lý
        const result = await BookingHandler.handleSmartBooking(message, context);
        return result;
    }
}
```

### 8. ResponseComposer

**Vị trí:** `api/src/services/chat/ResponseComposer.js`

**Chức năng:**
- Format response
- Tạo suggestions
- Save vào database
- Update context

**Flow:**
```javascript
async buildAndSave(conversation, context, result, userId, branchId) {
    // 1. Extract message
    const message = result.response || result.message;
    
    // 2. Create suggestions
    const suggestions = await ResponseHandler.getSuggestions(intent, branchId);
    
    // 3. Format response
    const response = {
        message,
        intent,
        entities,
        suggestions,
        action,
        action_data,
        type: 'text',
        conversation_id: conversation.session_id
    };
    
    // 4. Save to database
    await MessageService.saveMessage(...);
    
    // 5. Update context
    await ConversationService.updateConversationContext(...);
    
    return response;
}
```

---

## 🎯 Tóm Tắt

### Flow Tổng Quan:

```
User Message
    ↓
ChatController (nhận request)
    ↓
ChatService (orchestrator)
    ↓
[1] Get/Create Conversation
    ↓
[2] Build Context (user, branch, history, cart)
    ↓
[3] Extract Entities (date, time, people, branch)
    ↓
[4] Detect Intent (book_table, view_menu, ...)
    ↓
[5] AI Processing (Gemini hoặc Rule-based)
    ↓
[6] Intent Routing (gửi đến handler phù hợp)
    ↓
[7] Handler xử lý (gọi tools nếu cần)
    ↓
[8] Build & Save Response
    ↓
[9] Return Response to User
```

### Các Khái Niệm Quan Trọng:

1. **Intent**: Mục đích của user
2. **Entity**: Thông tin cụ thể (số người, ngày, giờ, ...)
3. **Context**: Ngữ cảnh từ các tin nhắn trước
4. **Handler**: Chương trình xử lý một loại intent
5. **Tool**: Function để lấy dữ liệu từ database
6. **Suggestion**: Nút hành động để user click

### Database Tables:

1. **chat_conversations**: Lưu conversation sessions
2. **chat_messages**: Lưu lịch sử tin nhắn
3. **branches**: Thông tin chi nhánh
4. **products**: Thông tin món ăn
5. **reservations**: Đặt bàn
6. **orders**: Đơn hàng

---

## ❓ Câu Hỏi Thường Gặp

### Q1: Tại sao cần Context?
**A:** Context giúp chatbot nhớ thông tin từ các tin nhắn trước, cho phép hội thoại nhiều lượt tự nhiên hơn.

### Q2: Tại sao cần AI (Gemini)?
**A:** AI giúp hiểu ngôn ngữ tự nhiên tốt hơn, xử lý được nhiều cách diễn đạt khác nhau.

### Q3: Tại sao cần Tools?
**A:** Tools giúp chatbot lấy dữ liệu thực từ database thay vì bịa đặt thông tin.

### Q4: Tại sao cần Handlers?
**A:** Handlers giúp tổ chức code rõ ràng, mỗi handler xử lý một loại intent cụ thể.

### Q5: Flow có thể bỏ qua bước nào không?
**A:** Có, một số bước có thể bỏ qua tùy trường hợp:
- Nếu là greeting → bỏ qua AI processing
- Nếu match suggestion → bỏ qua entity extraction
- Nếu Gemini disabled → dùng rule-based thay vì AI

---

## 📚 Tài Liệu Tham Khảo

- `CHATBOT_ARCHITECTURE.md`: Kiến trúc tổng quan
- `CHATBOT_FLOW_EXPLANATION.md`: Flow logic chi tiết
- Code files trong `api/src/services/chat/`

---

**Chúc bạn hiểu rõ về chatbot! 🎉**



