# Giải Thích Đơn Giản: Làm Sao Tìm Được Giỏ Hàng?

## Câu Hỏi

1. **Khi user thêm vào giỏ hàng, làm sao biết có giỏ hàng hay chưa?**
2. **Nếu chưa có → tạo mới → tạo sessionId đúng không?**
3. **Nếu đã có → bằng cách nào tìm được giỏ hàng đó khi chưa biết sessionId?**

## Câu Trả Lời Đơn Giản

**SessionId được LƯU TRONG LOCAL STORAGE của app và được GỬI LÊN SERVER trong mỗi request.**

**Flow đơn giản:**
```
1. User thêm sản phẩm lần đầu
   → App: Chưa có sessionId → Tạo mới "1703123456789"
   → App: Lưu vào Local Storage
   → App: Gửi lên server với sessionId "1703123456789"
   → Server: Tìm cart với sessionId "1703123456789" → KHÔNG TÌM THẤY
   → Server: Tạo cart mới với sessionId "1703123456789"

2. User thêm sản phẩm lần 2
   → App: Lấy sessionId từ Local Storage → "1703123456789"
   → App: Gửi lên server với sessionId "1703123456789"
   → Server: Tìm cart với sessionId "1703123456789" → TÌM THẤY
   → Server: Dùng cart cũ
```

---

## 1. Lần Đầu Tiên: Chưa Có Giỏ Hàng

### 1.1. User Thêm Sản Phẩm Lần Đầu

**Bước 1: App kiểm tra Local Storage**
```dart
// App kiểm tra: Có sessionId trong Local Storage không?
final sessionId = await StorageService().getString('cart_session_id');
// → null (chưa có)
```

**Bước 2: App tạo sessionId mới**
```dart
// App tạo sessionId mới
final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
// → "1703123456789"

// App lưu vào Local Storage
await StorageService().setString('cart_session_id', newSessionId);
```

**Bước 3: App gửi lên server**
```dart
// App gửi request lên server
POST /api/branches/7/cart/add
Body: {
  "product_id": 1,
  "session_id": "1703123456789"  // ← App gửi sessionId lên
}
```

**Bước 4: Server tìm cart**
```javascript
// Server nhận sessionId từ request
const sessionId = req.body.session_id;  // "1703123456789"
const userId = req.user.id;            // 123

// Server tìm cart với sessionId này
const cart = await knex('carts')
  .where('user_id', userId)
  .where('session_id', sessionId)
  .first();
// → null (KHÔNG TÌM THẤY - chưa có cart)
```

**Bước 5: Server tạo cart mới**
```javascript
// Server tạo cart mới với sessionId
await knex('carts').insert({
  user_id: 123,
  session_id: "1703123456789",  // ← Dùng sessionId từ client
  branch_id: 7,
  // ...
});
```

**Kết quả:**
- ✅ Cart mới được tạo với sessionId "1703123456789"
- ✅ SessionId được lưu trong Local Storage của app

---

## 2. Lần Thứ 2: Đã Có Giỏ Hàng

### 2.1. User Thêm Sản Phẩm Lần 2

**Bước 1: App lấy sessionId từ Local Storage**
```dart
// App lấy sessionId từ Local Storage
final sessionId = await StorageService().getString('cart_session_id');
// → "1703123456789" (ĐÃ CÓ - từ lần trước)
```

**Bước 2: App gửi lên server**
```dart
// App gửi request lên server
POST /api/branches/7/cart/add
Body: {
  "product_id": 2,
  "session_id": "1703123456789"  // ← App gửi sessionId cũ lên
}
```

**Bước 3: Server tìm cart**
```javascript
// Server nhận sessionId từ request
const sessionId = req.body.session_id;  // "1703123456789"
const userId = req.user.id;            // 123

// Server tìm cart với sessionId này
const cart = await knex('carts')
  .where('user_id', userId)
  .where('session_id', sessionId)
  .first();
// → { id: 456, user_id: 123, session_id: "1703123456789", ... }
// → TÌM THẤY!
```

**Bước 4: Server dùng cart cũ**
```javascript
// Server dùng cart cũ (không tạo mới)
// Thêm sản phẩm vào cart hiện có
await knex('cart_items').insert({
  cart_id: 456,  // ← Cart cũ
  product_id: 2,
  // ...
});
```

**Kết quả:**
- ✅ Tìm thấy cart cũ với sessionId "1703123456789"
- ✅ Thêm sản phẩm vào cart cũ

---

## 3. Tóm Tắt Flow

### 3.1. Flow Đơn Giản

```
┌─────────────────────────────────────┐
│  LẦN ĐẦU TIÊN                        │
├─────────────────────────────────────┤
│  1. App: Local Storage → null       │
│  2. App: Tạo sessionId mới         │
│     → "1703123456789"                │
│  3. App: Lưu vào Local Storage      │
│  4. App: Gửi lên server             │
│     Body: { "session_id": "1703123456789" }
│  5. Server: Tìm cart                │
│     → KHÔNG TÌM THẤY                 │
│  6. Server: Tạo cart mới            │
│     session_id: "1703123456789"     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  LẦN THỨ 2                          │
├─────────────────────────────────────┤
│  1. App: Local Storage → "1703123456789"
│  2. App: Gửi lên server             │
│     Body: { "session_id": "1703123456789" }
│  3. Server: Tìm cart                │
│     WHERE session_id = "1703123456789"
│     → TÌM THẤY!                     │
│  4. Server: Dùng cart cũ            │
└─────────────────────────────────────┘
```

### 3.2. Điểm Quan Trọng

**Câu hỏi: Làm sao tìm được giỏ hàng khi chưa biết sessionId?**

**Trả lời:**
- **App ĐÃ BIẾT sessionId** vì đã lưu trong Local Storage từ lần trước
- **App GỬI sessionId lên server** trong mỗi request
- **Server DÙNG sessionId đó** để tìm cart

**Ví dụ:**
```
Lần 1:
  App tạo: "1703123456789"
  App lưu: Local Storage = "1703123456789"
  App gửi: session_id = "1703123456789"
  Server tạo cart với sessionId "1703123456789"

Lần 2:
  App lấy: Local Storage = "1703123456789"  ← ĐÃ CÓ!
  App gửi: session_id = "1703123456789"     ← GỬI LÊN!
  Server tìm: WHERE session_id = "1703123456789"  ← TÌM THẤY!
```

---

## 4. Code Thực Tế

### 4.1. Client: Thêm Sản Phẩm

```dart
// lib/services/CartService.dart
static Future<Cart> addToCart({
  required int branchId,
  required int productId,
  // ...
}) async {
  // BƯỚC 1: Lấy sessionId từ Local Storage
  final storedSessionId = await _getSessionId();
  // → "1703123456789" (nếu đã có)
  // → null (nếu chưa có)
  
  // BƯỚC 2: Nếu chưa có, tạo mới
  final currentSessionId = storedSessionId ?? _generateSessionId();
  // → "1703123456789" (dùng lại) hoặc tạo mới
  
  // BƯỚC 3: Lưu vào Local Storage nếu chưa có
  if (storedSessionId == null) {
    await _setSessionId(currentSessionId);
  }
  
  // BƯỚC 4: Gửi sessionId lên server
  final response = await http.post(
    Uri.parse('${ApiConstants.baseUrl}${ApiConstants.addToCart(branchId)}'),
    body: jsonEncode({
      'product_id': productId,
      'session_id': currentSessionId,  // ← GỬI SESSIONID LÊN
      // ...
    }),
  );
}
```

### 4.2. Server: Tìm Hoặc Tạo Cart

```javascript
// api/src/services/CartService.js
async addToCart(userId, branchId, productId, sessionId = null, ...) {
  // BƯỚC 1: Tìm cart với sessionId (từ client gửi lên)
  let cart = await this.findPendingCart(userId, branchId, sessionId);
  // → cart object (nếu tìm thấy)
  // → null (nếu không tìm thấy)
  
  // BƯỚC 2: Nếu không tìm thấy, tạo mới
  if (!cart) {
    cart = await this.createCart(userId, branchId, orderType, sessionId);
    // → Tạo cart mới với sessionId từ client
  }
  
  // BƯỚC 3: Thêm sản phẩm vào cart
  // ...
}
```

### 4.3. Server: Tìm Cart

```javascript
// api/src/services/CartService.js
async findPendingCart(userId, branchId, sessionId = null) {
  // Tìm cart với sessionId (từ client gửi lên)
  const cart = await knex('carts')
    .where('user_id', userId)
    .where('branch_id', branchId)
    .where('session_id', sessionId)  // ← Dùng sessionId từ client
    .first();
  
  return cart;  // cart object hoặc null
}
```

---

## 5. Ví Dụ Cụ Thể

### 5.1. Scenario 1: Lần Đầu Tiên

```
User mở app lần đầu
  ↓
User thêm sản phẩm
  ↓
App kiểm tra Local Storage
  → null (chưa có sessionId)
  ↓
App tạo sessionId mới
  → "1703123456789"
  ↓
App lưu vào Local Storage
  → Local Storage: "1703123456789"
  ↓
App gửi lên server
  → Body: { "session_id": "1703123456789" }
  ↓
Server tìm cart
  → WHERE session_id = "1703123456789"
  → null (KHÔNG TÌM THẤY)
  ↓
Server tạo cart mới
  → session_id: "1703123456789"
```

### 5.2. Scenario 2: Lần Thứ 2

```
User thêm sản phẩm lần 2
  ↓
App lấy từ Local Storage
  → "1703123456789" (ĐÃ CÓ!)
  ↓
App gửi lên server
  → Body: { "session_id": "1703123456789" }
  ↓
Server tìm cart
  → WHERE session_id = "1703123456789"
  → { id: 456, session_id: "1703123456789", ... } (TÌM THẤY!)
  ↓
Server dùng cart cũ
  → Thêm sản phẩm vào cart id: 456
```

### 5.3. Scenario 3: User Đóng App Và Mở Lại

```
User đóng app
  → Local Storage vẫn còn: "1703123456789"
  → Cart vẫn còn trên server
  ↓
User mở app lại
  ↓
App lấy từ Local Storage
  → "1703123456789" (VẪN CÒN!)
  ↓
App gọi getUserCart()
  → GET /api/branches/7/cart?session_id=1703123456789
  ↓
Server tìm cart
  → WHERE session_id = "1703123456789"
  → TÌM THẤY cart cũ!
  ↓
App hiển thị cart cũ
```

---

## 6. Trả Lời Câu Hỏi

### 6.1. Làm Sao Biết Có Giỏ Hàng Hay Chưa?

**Trả lời:**
- Server query database với sessionId (từ client gửi lên)
- Nếu tìm thấy → Đã có giỏ hàng
- Nếu không tìm thấy → Chưa có giỏ hàng

### 6.2. Chưa Có → Tạo Mới → Tạo SessionId Đúng Không?

**Trả lời:** **ĐÚNG!**
- App tạo sessionId mới
- App lưu vào Local Storage
- App gửi lên server
- Server tạo cart mới với sessionId đó

### 6.3. Đã Có → Bằng Cách Nào Tìm Được?

**Trả lời:**
- **App ĐÃ BIẾT sessionId** (đã lưu trong Local Storage từ lần trước)
- **App GỬI sessionId lên server** trong request
- **Server DÙNG sessionId đó** để tìm cart

**Ví dụ:**
```
Lần 1: App tạo "1703123456789" → Lưu vào Local Storage
Lần 2: App lấy "1703123456789" từ Local Storage → Gửi lên server
       Server tìm với "1703123456789" → TÌM THẤY!
```

---

## 7. Câu Hỏi: Nhiều SessionId Trong Local Storage?

### 7.1. Local Storage Chỉ Có 1 SessionId

**Quan trọng:**
- Local Storage chỉ lưu **1 sessionId** (key: `'cart_session_id'`)
- **KHÔNG** có nhiều sessionId trong Local Storage
- Mỗi thiết bị chỉ có **1 sessionId**

**Code:**
```dart
// Local Storage chỉ có 1 key
static const String _storageKey = 'cart_session_id';

// Lấy sessionId
final sessionId = await storage.getString('cart_session_id');
// → "1703123456789" (chỉ có 1 giá trị)
// → null (nếu chưa có)
```

### 7.2. Server Query Với CẢ UserId VÀ SessionId

**Quan trọng:**
- Server query với **CẢ user_id VÀ session_id**
- Mỗi user chỉ thấy cart của chính họ
- Không bị conflict dù có nhiều user

**Code:**
```javascript
// Server query
const cart = await knex('carts')
  .where('user_id', userId)      // ← Từ auth token (user hiện tại)
  .where('session_id', sessionId) // ← Từ Local Storage
  .first();
```

### 7.3. Scenario: User A Logout, User B Login

**Flow:**
```
1. User A đăng nhập
   → Local Storage: sessionId = "1703123456789"
   → Server: Cart { user_id: 123, session_id: "1703123456789" }
   
2. User A logout
   → Local Storage: sessionId = "1703123456789" (VẪN CÒN!)
   → Server: Cart vẫn còn (user_id: 123)
   
3. User B đăng nhập (cùng thiết bị)
   → Local Storage: sessionId = "1703123456789" (VẪN CÒN từ User A!)
   → Server: Query với user_id = 456 (User B) + session_id = "1703123456789"
   → KHÔNG TÌM THẤY (vì cart của User A có user_id = 123)
   → Server: Tạo cart MỚI cho User B
   → Cart { user_id: 456, session_id: "1703123456789" }
```

**Kết quả:**
- ✅ User A có cart riêng (user_id: 123, session_id: "1703123456789")
- ✅ User B có cart riêng (user_id: 456, session_id: "1703123456789")
- ✅ Cùng sessionId nhưng user_id khác → Không conflict

### 7.4. Tại Sao Không Bị Conflict?

**Lý do:**
- Server query với **CẢ user_id VÀ session_id**
- `user_id` từ **auth token** (user hiện tại)
- `session_id` từ **Local Storage** (có thể từ user trước)
- Mỗi user chỉ thấy cart của chính họ

**Ví dụ:**
```sql
-- User A (user_id = 123)
SELECT * FROM carts
WHERE user_id = 123              -- ← User A
  AND session_id = '1703123456789'
→ Cart của User A

-- User B (user_id = 456)
SELECT * FROM carts
WHERE user_id = 456              -- ← User B
  AND session_id = '1703123456789'
→ Cart của User B (hoặc null nếu chưa có)
```

---

## 8. Kết Luận

**Tóm tắt:**
1. **Lần đầu:** App tạo sessionId → Lưu vào Local Storage → Gửi lên server → Server tạo cart
2. **Lần sau:** App lấy sessionId từ Local Storage → Gửi lên server → Server tìm cart → Tìm thấy!

**Điểm quan trọng:**
- Local Storage chỉ có **1 sessionId** (không phải nhiều)
- Server query với **CẢ user_id VÀ session_id**
- Mỗi user chỉ thấy cart của chính họ (vì có user_id)
- SessionId có thể "chia sẻ" giữa các user nhưng không conflict (vì có user_id)

**Không cần "biết trước" sessionId vì:**
- App đã lưu trong Local Storage từ lần trước
- App tự động gửi lên server trong mỗi request
- Server chỉ cần nhận và dùng kết hợp với user_id

