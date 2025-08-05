# Hướng dẫn sử dụng tính năng quản lý Danh mục (Categories)

## Tổng quan

Tính năng quản lý danh mục cho phép admin phân loại và tổ chức sản phẩm một cách hiệu quả trong hệ thống nhà hàng LVTN.

## Cấu trúc dữ liệu

### Danh mục (Categories)
- **id**: ID duy nhất
- **name**: Tên danh mục (bắt buộc)
- **description**: Mô tả chi tiết (tùy chọn)
- **is_available**: Trạng thái hoạt động (true/false)
- **created_at**: Ngày tạo
- **updated_at**: Ngày cập nhật
- **product_count**: Số lượng sản phẩm trong danh mục (tính toán)

## Tính năng chính

### 1. Xem danh sách danh mục
- **Truy cập**: `/admin/categories`
- **Hiển thị**: Dạng card với thông tin cơ bản
- **Thông tin hiển thị**:
  - Tên danh mục
  - Trạng thái (Hoạt động/Không hoạt động)
  - Số lượng sản phẩm
  - Mô tả (nếu có)
  - Ngày tạo
- **Tìm kiếm**: Theo tên danh mục hoặc mô tả
- **Lọc**: Theo trạng thái hoạt động

### 2. Thêm danh mục mới
- **Cách thực hiện**: Click nút "Thêm danh mục mới"
- **Thông tin bắt buộc**:
  - Tên danh mục (không được trống)
- **Thông tin tùy chọn**:
  - Mô tả chi tiết
- **Trạng thái mặc định**: Hoạt động (true)

### 3. Chỉnh sửa danh mục
- **Cách thực hiện**: Click nút chỉnh sửa trên card danh mục
- **Có thể thay đổi**:
  - Tên danh mục
  - Mô tả
  - Trạng thái hoạt động
- **Lưu ý**: Thay đổi trạng thái sẽ ảnh hưởng đến hiển thị sản phẩm

### 4. Xóa danh mục
- **Cách thực hiện**: Click nút xóa trên card danh mục
- **Xác nhận**: Modal xác nhận trước khi xóa
- **Cảnh báo**: Xóa danh mục sẽ ảnh hưởng đến các sản phẩm thuộc danh mục

## API Endpoints

### Public Routes (Không cần authentication)
```
GET    /api/categories              - Lấy danh sách tất cả danh mục
GET    /api/categories/with-count   - Lấy danh mục với số lượng sản phẩm
GET    /api/categories/:id          - Lấy chi tiết danh mục theo ID
```

### Protected Routes (Cần authentication + admin role)
```
POST   /api/categories              - Tạo danh mục mới
PUT    /api/categories/:id          - Cập nhật danh mục
DELETE /api/categories/:id          - Xóa danh mục
```

## Quyền truy cập

- **Admin**: Có thể thực hiện tất cả thao tác (CRUD)
- **Staff**: Chỉ có thể xem danh sách
- **Customer**: Không có quyền truy cập

## Validation Rules

### Tạo danh mục mới
- **name**: Bắt buộc, không được trống, tối đa 255 ký tự
- **description**: Tùy chọn, tối đa 500 ký tự
- **is_available**: Mặc định là true

### Cập nhật danh mục
- **name**: Nếu cung cấp thì không được trống
- **description**: Tùy chọn
- **is_available**: Boolean (true/false)

## Lưu ý quan trọng

### Ràng buộc dữ liệu
1. **Tên danh mục**: Phải duy nhất trong hệ thống
2. **Sản phẩm liên quan**: Khi xóa danh mục, cần xử lý các sản phẩm thuộc danh mục
3. **Trạng thái**: Danh mục không hoạt động sẽ không hiển thị trong danh sách sản phẩm

### Best Practices
1. **Đặt tên rõ ràng**: Sử dụng tên ngắn gọn, dễ hiểu
2. **Mô tả chi tiết**: Cung cấp mô tả để dễ quản lý
3. **Kiểm tra trước khi xóa**: Đảm bảo không có sản phẩm quan trọng trong danh mục
4. **Sử dụng trạng thái**: Tạm thời ẩn danh mục thay vì xóa

## Hướng dẫn sử dụng

### Bước 1: Tạo danh mục cơ bản
1. Truy cập `/admin/categories`
2. Click "Thêm danh mục mới"
3. Nhập tên danh mục (VD: "Món chính", "Món khai vị")
4. Thêm mô tả nếu cần
5. Click "Tạo danh mục"

### Bước 2: Quản lý sản phẩm theo danh mục
1. Truy cập `/admin/products`
2. Tạo sản phẩm mới và chọn danh mục phù hợp
3. Hoặc chỉnh sửa sản phẩm hiện có để thay đổi danh mục

### Bước 3: Theo dõi và bảo trì
1. Kiểm tra số lượng sản phẩm trong mỗi danh mục
2. Cập nhật trạng thái danh mục khi cần
3. Xóa danh mục không sử dụng (cẩn thận)

## Troubleshooting

### Lỗi thường gặp
1. **"Tên danh mục đã tồn tại"**: Chọn tên khác hoặc chỉnh sửa danh mục hiện có
2. **"Không thể xóa danh mục"**: Kiểm tra xem có sản phẩm nào thuộc danh mục không
3. **"Danh mục không tìm thấy"**: Kiểm tra ID hoặc tên danh mục

### Debug
- Kiểm tra console browser để xem lỗi chi tiết
- Kiểm tra log server để xem lỗi backend
- Sử dụng Swagger UI để test API: `http://localhost:3000/api-docs`

## Ví dụ danh mục phổ biến

### Nhà hàng Việt Nam
- **Món chính**: Phở, Bún bò, Cơm tấm, Bánh mì
- **Món khai vị**: Gỏi cuốn, Chả giò, Bánh xèo
- **Món canh**: Canh chua, Canh cải, Canh bí
- **Tráng miệng**: Chè, Bánh flan, Kem
- **Đồ uống**: Nước mía, Trà đá, Cà phê

### Nhà hàng Quốc tế
- **Appetizers**: Salad, Soup, Bread
- **Main Course**: Pasta, Steak, Seafood
- **Desserts**: Cake, Ice cream, Pudding
- **Beverages**: Coffee, Tea, Juice, Wine

## Cập nhật tương lai

- [ ] Thêm icon cho danh mục
- [ ] Thêm màu sắc phân biệt
- [ ] Thêm thứ tự hiển thị
- [ ] Thêm danh mục con (subcategories)
- [ ] Thêm tính năng import/export
- [ ] Thêm biểu đồ thống kê theo danh mục 