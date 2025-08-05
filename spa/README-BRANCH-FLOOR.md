# Hướng dẫn sử dụng tính năng quản lý Chi nhánh và Tầng

## Tổng quan

Hệ thống LVTN đã được mở rộng với tính năng quản lý đa chi nhánh và tầng, cho phép quản lý nhà hàng với nhiều địa điểm và tầng khác nhau.

## Cấu trúc dữ liệu

### Chi nhánh (Branches)
- **id**: ID duy nhất
- **name**: Tên chi nhánh
- **address**: Địa chỉ
- **phone**: Số điện thoại
- **email**: Email liên hệ
- **opening_hours**: Giờ mở cửa
- **description**: Mô tả
- **status**: Trạng thái (active/inactive/maintenance)
- **created_at**: Ngày tạo
- **updated_at**: Ngày cập nhật

### Tầng (Floors)
- **id**: ID duy nhất
- **branch_id**: ID chi nhánh
- **floor_number**: Số tầng (duy nhất trong chi nhánh)
- **name**: Tên tầng
- **capacity**: Sức chứa (số người)
- **description**: Mô tả
- **status**: Trạng thái (active/inactive/maintenance)
- **created_at**: Ngày tạo
- **updated_at**: Ngày cập nhật

## Tính năng chính

### 1. Quản lý Chi nhánh

#### Xem danh sách chi nhánh
- Truy cập: `/admin/branches`
- Hiển thị tất cả chi nhánh dạng card
- Thông tin: tên, địa chỉ, số điện thoại, email, trạng thái
- Tìm kiếm theo tên, địa chỉ, số điện thoại, email
- Lọc theo trạng thái

#### Thêm chi nhánh mới
- Click nút "Thêm chi nhánh mới"
- Điền thông tin bắt buộc: tên, địa chỉ, số điện thoại, email
- Thông tin tùy chọn: giờ mở cửa, mô tả
- Trạng thái mặc định: "Hoạt động"

#### Chỉnh sửa chi nhánh
- Click nút chỉnh sửa trên card chi nhánh
- Có thể thay đổi tất cả thông tin
- Có thể thay đổi trạng thái

#### Xóa chi nhánh
- Click nút xóa trên card chi nhánh
- Xác nhận trước khi xóa
- **Lưu ý**: Xóa chi nhánh sẽ ảnh hưởng đến tầng và bàn thuộc chi nhánh

### 2. Quản lý Tầng

#### Xem danh sách tầng
- Truy cập: `/admin/floors`
- Hiển thị tất cả tầng dạng card
- Thông tin: tên, chi nhánh, số tầng, sức chứa, trạng thái
- Tìm kiếm theo tên, mô tả, tên chi nhánh
- Lọc theo trạng thái và chi nhánh

#### Thêm tầng mới
- Click nút "Thêm tầng mới"
- Chọn chi nhánh từ dropdown
- Số tầng: có thể nhập thủ công hoặc tự động tạo
- **Tính năng tự động tạo số tầng**:
  - Click nút <i class="fas fa-magic"></i> để tự động tạo số tầng tiếp theo
  - Hệ thống sẽ tìm số tầng lớn nhất trong chi nhánh và +1
  - Hiển thị số lượng tầng hiện tại trong chi nhánh
- Điền thông tin bắt buộc: tên, sức chứa
- Thông tin tùy chọn: mô tả

#### Chỉnh sửa tầng
- Click nút chỉnh sửa trên card tầng
- Không thể thay đổi số tầng (để tránh xung đột)
- Có thể thay đổi các thông tin khác
- Có thể thay đổi trạng thái

#### Xóa tầng
- Click nút xóa trên card tầng
- Xác nhận trước khi xóa
- **Lưu ý**: Xóa tầng sẽ ảnh hưởng đến bàn thuộc tầng

## API Endpoints

### Chi nhánh (Branches)
```
GET    /api/branches              - Lấy danh sách chi nhánh
GET    /api/branches/:id          - Lấy chi tiết chi nhánh
POST   /api/branches              - Tạo chi nhánh mới
PUT    /api/branches/:id          - Cập nhật chi nhánh
DELETE /api/branches/:id          - Xóa chi nhánh
GET    /api/branches/active       - Lấy chi nhánh đang hoạt động
```

### Tầng (Floors)
```
GET    /api/floors                - Lấy danh sách tầng
GET    /api/floors/:id            - Lấy chi tiết tầng
POST   /api/floors                - Tạo tầng mới
PUT    /api/floors/:id            - Cập nhật tầng
DELETE /api/floors/:id            - Xóa tầng
GET    /api/floors/branch/:id     - Lấy tầng theo chi nhánh
GET    /api/floors/active         - Lấy tầng đang hoạt động
```

## Quyền truy cập

- **Admin**: Có thể thực hiện tất cả thao tác
- **Staff**: Chỉ có thể xem danh sách
- **Customer**: Không có quyền truy cập

## Lưu ý quan trọng

### Ràng buộc dữ liệu
1. **Số tầng**: Phải duy nhất trong mỗi chi nhánh
2. **Chi nhánh**: Khi xóa chi nhánh, cần xử lý các tầng và bàn liên quan
3. **Tầng**: Khi xóa tầng, cần xử lý các bàn liên quan

### Validation
- Tên chi nhánh: Bắt buộc, tối đa 255 ký tự
- Địa chỉ: Bắt buộc, tối đa 500 ký tự
- Số điện thoại: Bắt buộc, định dạng hợp lệ
- Email: Bắt buộc, định dạng email hợp lệ
- Số tầng: Bắt buộc, số nguyên dương, duy nhất trong chi nhánh
- Tên tầng: Bắt buộc, tối đa 255 ký tự
- Sức chứa: Bắt buộc, số nguyên từ 1-1000

### Trạng thái
- **active**: Hoạt động bình thường
- **inactive**: Không hoạt động (tạm thời)
- **maintenance**: Đang bảo trì

## Hướng dẫn sử dụng

### Bước 1: Tạo chi nhánh
1. Truy cập `/admin/branches`
2. Click "Thêm chi nhánh mới"
3. Điền thông tin chi nhánh
4. Click "Tạo chi nhánh"

### Bước 2: Tạo tầng
1. Truy cập `/admin/floors`
2. Click "Thêm tầng mới"
3. Chọn chi nhánh
4. Click nút <i class="fas fa-magic"></i> để tự động tạo số tầng
5. Điền thông tin tầng
6. Click "Tạo tầng"

### Bước 3: Quản lý bàn
1. Truy cập `/admin/tables`
2. Tạo bàn mới với chi nhánh và tầng đã chọn
3. Hệ thống sẽ tự động tạo số bàn

## Troubleshooting

### Lỗi thường gặp
1. **"Số tầng đã tồn tại"**: Chọn số tầng khác hoặc dùng tính năng tự động tạo
2. **"Chi nhánh không tồn tại"**: Kiểm tra lại danh sách chi nhánh
3. **"Không thể xóa chi nhánh"**: Kiểm tra xem có tầng hoặc bàn nào thuộc chi nhánh không

### Debug
- Kiểm tra console browser để xem lỗi chi tiết
- Kiểm tra log server để xem lỗi backend
- Sử dụng Swagger UI để test API: `http://localhost:3000/api-docs`

## Cập nhật tương lai

- [ ] Thêm tính năng import/export dữ liệu
- [ ] Thêm biểu đồ thống kê theo chi nhánh
- [ ] Thêm tính năng quản lý nhân viên theo chi nhánh
- [ ] Thêm tính năng đặt bàn theo chi nhánh và tầng 