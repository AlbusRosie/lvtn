# LVTN Restaurant Management API

API cho hệ thống quản lý nhà hàng LVTN với tính năng quản lý đa chi nhánh, tầng, bàn.

## Cài đặt

1. Cài đặt dependencies:
```bash
npm install
```

2. Cấu hình database trong file `.env`:
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASS=your_password
DB_NAME=lvtn
PORT=3000
JWT_SECRET=your-secret-key
```

3. Tạo database và chạy migration:
```bash
# Import database schema
mysql -u root -p < lvtn.sql

# Hoặc chạy seed data
node run-seeds.js
```

4. Khởi động server:
```bash
npm start
```

## API Documentation

Truy cập Swagger UI tại: `http://localhost:3000/api-docs`

## Table API Endpoints

### Public Endpoints (Không cần authentication)

#### 1. Lấy danh sách tất cả bàn
```
GET /api/tables
```
**Query Parameters:**
- `branch_id` (optional): Lọc theo ID chi nhánh

#### 2. Lấy danh sách bàn có sẵn
```
GET /api/tables/available
```
**Query Parameters:**
- `branch_id` (optional): Lọc theo ID chi nhánh

#### 3. Lấy danh sách bàn theo trạng thái
```
GET /api/tables/status/{status}
```
**Path Parameters:**
- `status`: Trạng thái bàn (available, occupied, reserved, maintenance)

**Query Parameters:**
- `branch_id` (optional): Lọc theo ID chi nhánh

#### 4. Lấy danh sách chi nhánh
```
GET /api/tables/branches
```

#### 5. Lấy danh sách tầng theo chi nhánh
```
GET /api/tables/branches/{branch_id}/floors
```

#### 6. Lấy danh sách bàn theo chi nhánh và tầng
```
GET /api/tables/branches/{branch_id}/floors/{floor_id}/tables
```

#### 7. Lấy thông tin bàn theo ID
```
GET /api/tables/{id}
```

#### 8. Lấy thông tin bàn theo số bàn và chi nhánh
```
GET /api/tables/branches/{branch_id}/tables/{table_number}
```

#### 9. Tạo số bàn tiếp theo
```
GET /api/tables/branches/{branch_id}/floors/{floor_id}/generate-number
```

#### 10. Lấy thống kê bàn
```
GET /api/tables/statistics
```
**Query Parameters:**
- `branch_id` (optional): Lọc theo ID chi nhánh

### Protected Endpoints (Cần authentication - Admin only)

#### 11. Tạo bàn mới
```
POST /api/tables
```
**Headers:**
- `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "branch_id": 1,
  "floor_id": 1,
  "table_number": "T01",
  "capacity": 4,
  "location": "Gần cửa sổ"
}
```

#### 12. Cập nhật thông tin bàn
```
PUT /api/tables/{id}
```
**Headers:**
- `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "branch_id": 1,
  "floor_id": 1,
  "table_number": "T02",
  "capacity": 6,
  "status": "available",
  "location": "Góc yên tĩnh"
}
```

#### 13. Cập nhật trạng thái bàn
```
PATCH /api/tables/{id}/status
```
**Headers:**
- `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "status": "occupied"
}
```

#### 14. Xóa bàn
```
DELETE /api/tables/{id}
```
**Headers:**
- `Authorization: Bearer {token}`

## Cấu trúc dữ liệu

### Table Schema
```json
{
  "id": 1,
  "branch_id": 1,
  "floor_id": 1,
  "table_number": "T01",
  "capacity": 4,
  "status": "available",
  "location": "Gần cửa sổ",
  "position_x": null,
  "position_y": null,
  "created_at": "2024-01-15T10:00:00.000Z",
  "branch_name": "Chi nhánh Quận 1",
  "floor_name": "Tầng 1",
  "floor_number": 1
}
```

### Branch Schema
```json
{
  "id": 1,
  "name": "Chi nhánh Quận 1",
  "address": "123 Nguyễn Huệ, Quận 1, TP.HCM",
  "phone": "028-1234-5678",
  "email": "q1@lvtn.com",
  "manager_id": 1,
  "status": "active",
  "opening_hours": "07:00-22:00",
  "description": "Chi nhánh chính tại trung tâm thành phố",
  "created_at": "2024-01-15T10:00:00.000Z"
}
```

### Floor Schema
```json
{
  "id": 1,
  "branch_id": 1,
  "floor_number": 1,
  "name": "Tầng 1",
  "description": "Tầng trệt - Khu vực chính",
  "capacity": 50,
  "status": "active",
  "created_at": "2024-01-15T10:00:00.000Z"
}
```

## Tính năng đặc biệt

### 1. Tự động tạo số bàn
API `/api/tables/branches/{branch_id}/floors/{floor_id}/generate-number` sẽ tự động tạo số bàn tiếp theo dựa trên số bàn hiện có trong tầng đó.

**Response:**
```json
{
  "status": "success",
  "data": {
    "nextTableNumber": "T03",
    "currentTableCount": 2,
    "maxNumber": 2
  }
}
```

### 2. Thống kê bàn
API `/api/tables/statistics` cung cấp thống kê số lượng bàn theo trạng thái.

**Response:**
```json
{
  "status": "success",
  "data": {
    "total": 18,
    "available": 15,
    "occupied": 2,
    "reserved": 0,
    "maintenance": 1
  }
}
```

### 3. Quản lý đa chi nhánh
- Mỗi bàn thuộc về một chi nhánh và một tầng cụ thể
- Số bàn phải duy nhất trong cùng một chi nhánh
- Có thể lọc bàn theo chi nhánh, tầng, trạng thái

## Lỗi thường gặp

### 400 Bad Request
- `Branch ID is required`: Thiếu ID chi nhánh
- `Floor ID is required`: Thiếu ID tầng
- `Table number is required`: Thiếu số bàn
- `Capacity must be at least 1`: Sức chứa phải ít nhất là 1
- `Table number already exists in this branch`: Số bàn đã tồn tại trong chi nhánh
- `Branch not found`: Không tìm thấy chi nhánh
- `Floor not found`: Không tìm thấy tầng
- `Floor does not belong to the specified branch`: Tầng không thuộc chi nhánh được chỉ định

### 401 Unauthorized
- `No token provided`: Không có token
- `Invalid token`: Token không hợp lệ
- `Access denied`: Không có quyền truy cập

### 404 Not Found
- `Table not found`: Không tìm thấy bàn

### 500 Internal Server Error
- `Database error`: Lỗi database

## Authentication

API sử dụng JWT Bearer token cho authentication. Token phải được gửi trong header:
```
Authorization: Bearer <your-jwt-token>
```

## Development

### Chạy trong development mode:
```bash
npm run dev
```

### Chạy tests:
```bash
npm test
```

### Linting:
```bash
npm run lint
``` 