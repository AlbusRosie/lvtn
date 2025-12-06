# Chỗ Nào Trong Source Code Lấy Cart Của User Với SessionId?

## Tóm Tắt

**Có 4 chỗ chính trong source code:**

1. **Client (Flutter):** `lib/services/CartService.dart` - Method `getUserCart()` - **Dòng 79-116**
2. **Server Controller:** `api/src/controllers/CartController.js` - Method `getUserCart()` - **Dòng 75-88**
3. **Server Service:** `api/src/services/CartService.js` - Method `getUserCart()` - **Dòng 441-447**
4. **Server Service:** `api/src/services/CartService.js` - Method `findPendingCart()` - **Dòng 4-13**

---

## 1. Client-Side: Gửi SessionId Lên Server

### File: `app/lvtn_mobile_app/lib/services/CartService.dart`

**Method:** `getUserCart()` - **Dòng 79-116**

```dart
static Future<Cart?> getUserCart({
  required String token,
  required int branchId,
  String? sessionId,
}) async {
  try {
    // BƯỚC 1: Lấy sessionId từ Local Storage
    final storedSessionId = await _getSessionId();  // ← Dòng 85
    String? currentSessionId = sessionId ?? storedSessionId;  // ← Dòng 86

    // BƯỚC 2: Nếu chưa có, tạo mới
    if (currentSessionId == null) {
      final newSessionId = _generateSessionId();
      await _setSessionId(newSessionId);
      currentSessionId = newSessionId;
    }

    // BƯỚC 3: Gửi sessionId trong query string
    final url = '${ApiConstants.baseUrl}${ApiConstants.getUserCart(branchId)}?session_id=$currentSessionId';  // ← Dòng 95

    // BƯỚC 4: Gửi request lên server
    final response = await http.get(
      Uri.parse(url),  // ← Dòng 98
      headers: ApiConstants.authHeaders(token),
    );

    // BƯỚC 5: Parse response
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'] == null) {
        return null;
      }
      return Cart.fromJson(data['data']);  // ← Dòng 108
    }
  } catch (e) {
    throw Exception('Error getting user cart: $e');
  }
}
```

**Điểm quan trọng:**
- **Dòng 85:** Lấy sessionId từ Local Storage
- **Dòng 95:** Gửi sessionId trong query string: `?session_id=1703123456789`
- **Dòng 98:** Gửi GET request lên server

---

## 2. Server Controller: Nhận SessionId Từ Request

### File: `api/src/controllers/CartController.js`

**Method:** `getUserCart()` - **Dòng 75-88**

```javascript
async function getUserCart(req, res, next) {
    try {
        // BƯỚC 1: Lấy branch_id từ URL params
        const { branch_id } = req.params;  // ← Dòng 77
        
        // BƯỚC 2: Lấy session_id từ query string
        const { session_id } = req.query;  // ← Dòng 78
        
        // BƯỚC 3: Lấy user_id từ auth token (middleware đã parse)
        const user_id = req.user.id;  // ← Dòng 79
        
        // BƯỚC 4: Gọi service với user_id và session_id
        const cart = await CartService.getUserCart(
            user_id,        // ← Từ auth token
            parseInt(branch_id),
            session_id      // ← Từ query string
        );  // ← Dòng 80
        
        // BƯỚC 5: Trả về cart
        if (!cart) {
            return res.json(success(null, 'No active cart found'));
        }
        res.json(success(cart, 'User cart retrieved successfully'));  // ← Dòng 84
    } catch (error) {
        next(new ApiError(500, error.message));
    }
}
```

**Điểm quan trọng:**
- **Dòng 78:** Nhận `session_id` từ query string: `req.query.session_id`
- **Dòng 79:** Nhận `user_id` từ auth token: `req.user.id`
- **Dòng 80:** Gọi service với cả `user_id` và `session_id`

---

## 3. Server Service: Tìm Cart Với UserId Và SessionId

### File: `api/src/services/CartService.js`

**Method:** `getUserCart()` - **Dòng 441-447**

```javascript
async getUserCart(userId, branchId, sessionId = null) {
    // BƯỚC 1: Tìm cart với userId và sessionId
    const cart = await this.findPendingCart(userId, branchId, sessionId);  // ← Dòng 442
    
    // BƯỚC 2: Nếu không tìm thấy, trả về null
    if (!cart) {
        return null;  // ← Dòng 444
    }
    
    // BƯỚC 3: Lấy đầy đủ thông tin cart (bao gồm items)
    return await this.getCartById(cart.id);  // ← Dòng 446
}
```

**Điểm quan trọng:**
- **Dòng 442:** Gọi `findPendingCart()` với `userId`, `branchId`, và `sessionId`
- **Dòng 446:** Nếu tìm thấy, lấy đầy đủ thông tin cart

---

## 4. Server Service: Query Database

### File: `api/src/services/CartService.js`

**Method:** `findPendingCart()` - **Dòng 4-13**

```javascript
async findPendingCart(userId, branchId, sessionId = null) {
    // BƯỚC 1: Bắt đầu query
    let query = knex('carts')
        .where('user_id', userId)      // ← Dòng 6: Filter theo user_id
        .where('branch_id', branchId); // ← Dòng 7: Filter theo branch_id
    
    // BƯỚC 2: Nếu có sessionId, thêm điều kiện
    if (sessionId) {
        query = query.where('session_id', sessionId);  // ← Dòng 9: Filter theo session_id
    }
    
    // BƯỚC 3: Thực thi query và trả về kết quả đầu tiên
    const cart = await query.first();  // ← Dòng 11
    return cart;  // ← Dòng 12
}
```

**Điểm quan trọng:**
- **Dòng 6:** Filter theo `user_id` (từ auth token)
- **Dòng 7:** Filter theo `branch_id` (từ URL params)
- **Dòng 9:** Filter theo `session_id` (từ query string)
- **Dòng 11:** Thực thi query: `SELECT * FROM carts WHERE user_id = ? AND branch_id = ? AND session_id = ? LIMIT 1`

**SQL Query được tạo:**
```sql
SELECT * FROM carts
WHERE user_id = 123              -- ← Từ auth token
  AND branch_id = 7              -- ← Từ URL params
  AND session_id = '1703123456789'  -- ← Từ query string
LIMIT 1;
```

---

## 5. Flow Hoàn Chỉnh

### 5.1. Client → Server

```
┌─────────────────────────────────────┐
│  CLIENT (Flutter)                    │
│  File: lib/services/CartService.dart │
│  Method: getUserCart() - Dòng 79    │
├─────────────────────────────────────┤
│  1. Lấy sessionId từ Local Storage │
│     → storedSessionId = "1703123456789"
│                                      │
│  2. Gửi GET request                 │
│     GET /api/cart/branches/7/user-cart?session_id=1703123456789
│                                      │
│  3. Nhận response                   │
│     → Cart object hoặc null         │
└─────────────────────────────────────┘
              ↓ HTTP Request
┌─────────────────────────────────────┐
│  SERVER CONTROLLER                  │
│  File: api/src/controllers/CartController.js
│  Method: getUserCart() - Dòng 75   │
├─────────────────────────────────────┤
│  1. Nhận session_id từ query       │
│     → req.query.session_id = "1703123456789"
│                                      │
│  2. Nhận user_id từ auth token     │
│     → req.user.id = 123            │
│                                      │
│  3. Gọi service                    │
│     → CartService.getUserCart(123, 7, "1703123456789")
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  SERVER SERVICE                     │
│  File: api/src/services/CartService.js
│  Method: getUserCart() - Dòng 441  │
├─────────────────────────────────────┤
│  1. Gọi findPendingCart()           │
│     → findPendingCart(123, 7, "1703123456789")
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  SERVER SERVICE                     │
│  File: api/src/services/CartService.js
│  Method: findPendingCart() - Dòng 4 │
├─────────────────────────────────────┤
│  1. Query database                  │
│     SELECT * FROM carts             │
│     WHERE user_id = 123             │
│       AND branch_id = 7             │
│       AND session_id = '1703123456789'
│                                      │
│  2. Trả về cart hoặc null           │
└─────────────────────────────────────┘
```

---

## 6. Các File Và Dòng Code Cụ Thể

### 6.1. Client-Side

| File | Method | Dòng | Mô Tả |
|------|--------|------|-------|
| `lib/services/CartService.dart` | `getUserCart()` | 85 | Lấy sessionId từ Local Storage |
| `lib/services/CartService.dart` | `getUserCart()` | 95 | Tạo URL với sessionId trong query string |
| `lib/services/CartService.dart` | `getUserCart()` | 98 | Gửi GET request lên server |
| `lib/services/CartService.dart` | `getUserCart()` | 108 | Parse và trả về Cart object |

### 6.2. Server-Side

| File | Method | Dòng | Mô Tả |
|------|--------|------|-------|
| `api/src/controllers/CartController.js` | `getUserCart()` | 78 | Nhận session_id từ query string |
| `api/src/controllers/CartController.js` | `getUserCart()` | 79 | Nhận user_id từ auth token |
| `api/src/controllers/CartController.js` | `getUserCart()` | 80 | Gọi service với user_id và session_id |
| `api/src/services/CartService.js` | `getUserCart()` | 442 | Gọi findPendingCart() |
| `api/src/services/CartService.js` | `findPendingCart()` | 6 | Filter theo user_id |
| `api/src/services/CartService.js` | `findPendingCart()` | 9 | Filter theo session_id |
| `api/src/services/CartService.js` | `findPendingCart()` | 11 | Thực thi query database |

---

## 7. Ví Dụ Thực Tế

### 7.1. Request Từ Client

```dart
// Client gọi
final cart = await CartService.getUserCart(
  token: "abc123",
  branchId: 7,
  sessionId: null,  // Sẽ lấy từ Local Storage
);

// Request được gửi:
GET /api/cart/branches/7/user-cart?session_id=1703123456789
Headers: {
  "Authorization": "Bearer abc123"
}
```

### 7.2. Server Nhận Và Xử Lý

```javascript
// Controller nhận
req.query.session_id = "1703123456789"  // Từ query string
req.user.id = 123                        // Từ auth token

// Service query
SELECT * FROM carts
WHERE user_id = 123
  AND branch_id = 7
  AND session_id = '1703123456789'
LIMIT 1;

// Kết quả
→ { id: 456, user_id: 123, session_id: "1703123456789", ... }
```

---

## 8. Tóm Tắt

**Các chỗ chính trong source code:**

1. **Client:** `lib/services/CartService.dart:79-116` - Gửi sessionId lên server
2. **Controller:** `api/src/controllers/CartController.js:75-88` - Nhận sessionId từ request
3. **Service:** `api/src/services/CartService.js:441-447` - Gọi findPendingCart()
4. **Service:** `api/src/services/CartService.js:4-13` - Query database với user_id và session_id

**Flow:**
```
Client (dòng 95) 
  → Gửi sessionId trong query string
  ↓
Controller (dòng 78) 
  → Nhận sessionId từ req.query
  ↓
Service (dòng 442) 
  → Gọi findPendingCart()
  ↓
Service (dòng 6-9) 
  → Query database với user_id + session_id
```

