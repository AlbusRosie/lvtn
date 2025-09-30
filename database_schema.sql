-- =====================================================
-- LVTN Restaurant Management System Database Schema
-- =====================================================

CREATE DATABASE IF NOT EXISTS `lvtn` 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `lvtn`;

-- =====================================================
-- 1. ROLES TABLE
-- =====================================================
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `description` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 2. PROVINCES TABLE
-- =====================================================
DROP TABLE IF EXISTS `provinces`;
CREATE TABLE `provinces` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `code` varchar(10) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 3. DISTRICTS TABLE
-- =====================================================
DROP TABLE IF EXISTS `districts`;
CREATE TABLE `districts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `code` varchar(10) NOT NULL,
  `province_id` int NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `idx_name` (`name`),
  KEY `idx_province_id` (`province_id`),
  CONSTRAINT `fk_districts_province` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 4. BRANCHES TABLE
-- =====================================================
DROP TABLE IF EXISTS `branches`;
CREATE TABLE `branches` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `province_id` int DEFAULT NULL,
  `district_id` int DEFAULT NULL,
  `address_detail` varchar(255) DEFAULT NULL,
  `phone` varchar(15) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `manager_id` int DEFAULT NULL,
  `status` enum('active','inactive','maintenance') DEFAULT 'active',
  `opening_hours` varchar(100) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_manager_id` (`manager_id`),
  KEY `idx_province_id` (`province_id`),
  KEY `idx_district_id` (`district_id`),
  KEY `idx_address_search` (`name`,`province_id`,`district_id`),
  CONSTRAINT `fk_branches_district` FOREIGN KEY (`district_id`) REFERENCES `districts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_branches_province` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 5. USERS TABLE
-- =====================================================
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `role_id` int NOT NULL,
  `branch_id` int DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `name` varchar(100) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `favorite` tinyint(1) NOT NULL DEFAULT '0',
  `avatar` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive','suspended') DEFAULT 'active',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `role_id` (`role_id`),
  KEY `idx_username` (`username`),
  KEY `idx_email` (`email`),
  KEY `idx_branch_id` (`branch_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `users_ibfk_2` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 6. FLOORS TABLE
-- =====================================================
DROP TABLE IF EXISTS `floors`;
CREATE TABLE `floors` (
  `id` int NOT NULL AUTO_INCREMENT,
  `branch_id` int NOT NULL,
  `floor_number` int NOT NULL,
  `name` varchar(50) NOT NULL,
  `description` text,
  `capacity` int DEFAULT '0',
  `status` enum('active','inactive','maintenance') DEFAULT 'active',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `design_data` json DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_floor_number` (`floor_number`),
  KEY `idx_branch_floor_active` (`branch_id`,`floor_number`,`status`),
  CONSTRAINT `floors_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 7. TABLES TABLE
-- =====================================================
DROP TABLE IF EXISTS `tables`;
CREATE TABLE `tables` (
  `id` int NOT NULL AUTO_INCREMENT,
  `branch_id` int NOT NULL,
  `floor_id` int NOT NULL,
  `table_number` varchar(10) NOT NULL,
  `capacity` int NOT NULL,
  `status` enum('available','occupied','reserved','maintenance') DEFAULT 'available',
  `location` varchar(100) DEFAULT NULL,
  `position_x` int DEFAULT NULL,
  `position_y` int DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_branch_floor_table` (`branch_id`,`floor_id`,`table_number`),
  KEY `idx_branch_id` (`branch_id`),
  KEY `idx_floor_id` (`floor_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `tables_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tables_ibfk_2` FOREIGN KEY (`floor_id`) REFERENCES `floors` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 8. CATEGORIES TABLE
-- =====================================================
DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 9. PRODUCTS TABLE
-- =====================================================
DROP TABLE IF EXISTS `products`;
CREATE TABLE `products` (
  `id` int NOT NULL AUTO_INCREMENT,
  `category_id` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `base_price` decimal(10,2) NOT NULL COMMENT 'Giá cơ bản, có thể điều chỉnh theo chi nhánh',
  `description` text,
  `image` varchar(255) DEFAULT NULL,
  `is_global_available` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Có sẵn toàn hệ thống hay không',
  `status` enum('active','inactive') DEFAULT 'active' COMMENT 'Trạng thái chung của sản phẩm',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_is_global_available` (`is_global_available`),
  KEY `idx_status` (`status`),
  CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 10. BRANCH_PRODUCTS TABLE
-- =====================================================
DROP TABLE IF EXISTS `branch_products`;
CREATE TABLE `branch_products` (
  `id` int NOT NULL AUTO_INCREMENT,
  `branch_id` int NOT NULL,
  `product_id` int NOT NULL,
  `price` decimal(10,2) NOT NULL COMMENT 'Giá tại chi nhánh này (có thể khác giá cơ bản)',
  `is_available` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Có sẵn tại chi nhánh này không',
  `status` enum('available','out_of_stock','temporarily_unavailable','discontinued') DEFAULT 'available' COMMENT 'Trạng thái sản phẩm tại chi nhánh',
  `notes` text COMMENT 'Ghi chú đặc biệt cho chi nhánh này',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_branch_product` (`branch_id`,`product_id`),
  KEY `idx_branch_id` (`branch_id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_is_available` (`is_available`),
  KEY `idx_status` (`status`),
  KEY `idx_branch_products_branch_status` (`branch_id`,`status`),
  KEY `idx_branch_products_price` (`price`),
  KEY `idx_branch_products_available` (`is_available`,`status`),
  CONSTRAINT `branch_products_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `branch_products_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 11. ORDERS TABLE
-- =====================================================
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `branch_id` int NOT NULL,
  `table_id` int DEFAULT NULL,
  `order_type` enum('dine_in','takeaway','delivery') NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `status` enum('pending','preparing','ready','served','cancelled','completed') DEFAULT 'pending',
  `payment_status` enum('pending','paid','failed') DEFAULT 'pending',
  `payment_method` enum('cash','card','online') DEFAULT NULL,
  `delivery_address` varchar(255) DEFAULT NULL,
  `delivery_phone` varchar(15) DEFAULT NULL,
  `notes` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_branch_id` (`branch_id`),
  KEY `idx_table_id` (`table_id`),
  KEY `idx_status` (`status`),
  KEY `idx_order_type` (`order_type`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 12. ORDER_DETAILS TABLE
-- =====================================================
DROP TABLE IF EXISTS `order_details`;
CREATE TABLE `order_details` (
  `id` int NOT NULL AUTO_INCREMENT,
  `order_id` int NOT NULL,
  `product_id` int NOT NULL,
  `quantity` int NOT NULL,
  `price` decimal(10,2) NOT NULL COMMENT 'Giá tại thời điểm đặt hàng',
  `special_instructions` text,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_product_id` (`product_id`),
  CONSTRAINT `order_details_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `order_details_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 13. RESERVATIONS TABLE
-- =====================================================
DROP TABLE IF EXISTS `reservations`;
CREATE TABLE `reservations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `branch_id` int NOT NULL,
  `table_id` int NOT NULL,
  `reservation_date` date NOT NULL,
  `reservation_time` time NOT NULL,
  `guest_count` int NOT NULL,
  `status` enum('pending','confirmed','cancelled','completed') DEFAULT 'pending',
  `special_requests` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_branch_id` (`branch_id`),
  KEY `idx_table_id` (`table_id`),
  KEY `idx_reservation_date` (`reservation_date`),
  KEY `idx_status` (`status`),
  CONSTRAINT `reservations_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reservations_ibfk_2` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reservations_ibfk_3` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 14. REVIEWS TABLE
-- =====================================================
DROP TABLE IF EXISTS `reviews`;
CREATE TABLE `reviews` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `branch_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `order_id` int DEFAULT NULL,
  `rating` int NOT NULL,
  `comment` text,
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_branch_id` (`branch_id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_ibfk_3` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_ibfk_4` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_chk_1` CHECK (((`rating` >= 1) and (`rating` <= 5)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- INSERT INITIAL DATA
-- =====================================================

-- Insert roles
INSERT INTO `roles` (`id`, `name`, `description`) VALUES
(1, 'admin', 'Quản trị viên hệ thống, có toàn quyền quản lý'),
(2, 'manager', 'Quản lý chi nhánh, quản lý nhân viên và hoạt động'),
(3, 'staff', 'Nhân viên nhà hàng, quản lý bàn và đơn hàng'),
(4, 'customer', 'Khách hàng, có thể đặt bàn và đặt hàng');

-- Insert provinces (major cities)
INSERT INTO `provinces` (`id`, `name`, `code`) VALUES
(1, 'Thành phố Hồ Chí Minh', 'SG'),
(2, 'Hà Nội', 'HN'),
(3, 'Đà Nẵng', 'DN'),
(4, 'Cần Thơ', 'CT'),
(5, 'An Giang', 'AG'),
(6, 'Bà Rịa - Vũng Tàu', 'BV'),
(7, 'Bạc Liêu', 'BL'),
(8, 'Bắc Giang', 'BG'),
(9, 'Bắc Kạn', 'BK'),
(10, 'Bắc Ninh', 'BN'),
(11, 'Bến Tre', 'BTR'),
(12, 'Bình Dương', 'BD'),
(13, 'Bình Phước', 'BP'),
(14, 'Bình Thuận', 'BTH'),
(15, 'Cà Mau', 'CM'),
(16, 'Cao Bằng', 'CB'),
(17, 'Đắk Lắk', 'DLK'),
(18, 'Đắk Nông', 'DNO'),
(19, 'Điện Biên', 'DB'),
(20, 'Đồng Nai', 'DNA'),
(21, 'Đồng Tháp', 'DT'),
(22, 'Gia Lai', 'GL'),
(23, 'Hà Giang', 'HG'),
(24, 'Hà Nam', 'HNA'),
(25, 'Hà Tĩnh', 'HT'),
(26, 'Hải Dương', 'HD'),
(27, 'Hải Phòng', 'HP'),
(28, 'Hậu Giang', 'HGI'),
(29, 'Hòa Bình', 'HB'),
(30, 'Hưng Yên', 'HY'),
(31, 'Khánh Hòa', 'KH'),
(32, 'Kiên Giang', 'KG'),
(33, 'Kon Tum', 'KT'),
(34, 'Lai Châu', 'LC'),
(35, 'Lâm Đồng', 'LD'),
(36, 'Lạng Sơn', 'LS'),
(37, 'Lào Cai', 'LCA'),
(38, 'Long An', 'LA'),
(39, 'Nam Định', 'ND'),
(40, 'Nghệ An', 'NA'),
(41, 'Ninh Bình', 'NB'),
(42, 'Ninh Thuận', 'NT'),
(43, 'Phú Thọ', 'PT'),
(44, 'Phú Yên', 'PY'),
(45, 'Quảng Bình', 'QB'),
(46, 'Quảng Nam', 'QNA'),
(47, 'Quảng Ngãi', 'QNG'),
(48, 'Quảng Ninh', 'QNI'),
(49, 'Quảng Trị', 'QT'),
(50, 'Sóc Trăng', 'ST'),
(51, 'Sơn La', 'SL'),
(52, 'Tây Ninh', 'TN'),
(53, 'Thái Bình', 'TB'),
(54, 'Thái Nguyên', 'TNG'),
(55, 'Thanh Hóa', 'TH'),
(56, 'Thừa Thiên Huế', 'TT'),
(57, 'Tiền Giang', 'TG'),
(58, 'Trà Vinh', 'TV'),
(59, 'Tuyên Quang', 'TQ'),
(60, 'Vĩnh Long', 'VL'),
(61, 'Vĩnh Phúc', 'VP'),
(62, 'Yên Bái', 'YB');

-- Insert districts for Ho Chi Minh City
INSERT INTO `districts` (`id`, `name`, `code`, `province_id`) VALUES
(1, 'Quận 1', 'Q1', 1),
(2, 'Quận 2', 'Q2', 1),
(3, 'Quận 3', 'Q3', 1),
(4, 'Quận 4', 'Q4', 1),
(5, 'Quận 5', 'Q5', 1),
(6, 'Quận 6', 'Q6', 1),
(7, 'Quận 7', 'Q7', 1),
(8, 'Quận 8', 'Q8', 1),
(9, 'Quận 9', 'Q9', 1),
(10, 'Quận 10', 'Q10', 1),
(11, 'Quận 11', 'Q11', 1),
(12, 'Quận 12', 'Q12', 1),
(13, 'Quận Thủ Đức', 'TĐ', 1),
(14, 'Quận Gò Vấp', 'GV', 1),
(15, 'Quận Bình Thạnh', 'BT', 1),
(16, 'Quận Tân Bình', 'TB', 1),
(17, 'Quận Tân Phú', 'TP', 1),
(18, 'Quận Phú Nhuận', 'PN', 1),
(19, 'Huyện Hóc Môn', 'HM', 1),
(20, 'Huyện Củ Chi', 'CC', 1),
(21, 'Huyện Bình Chánh', 'BC', 1),
(22, 'Huyện Nhà Bè', 'NB', 1),
(23, 'Huyện Cần Giờ', 'CG', 1);

-- Insert districts for Hanoi
INSERT INTO `districts` (`id`, `name`, `code`, `province_id`) VALUES
(70, 'Quận Ba Đình', 'QBD', 2),
(71, 'Quận Hoàn Kiếm', 'QHK', 2),
(72, 'Quận Tây Hồ', 'QTH', 2),
(73, 'Quận Long Biên', 'QLB', 2),
(74, 'Quận Cầu Giấy', 'QCG', 2),
(75, 'Quận Đống Đa', 'QDD', 2),
(76, 'Quận Hai Bà Trưng', 'QHBT', 2),
(77, 'Quận Hoàng Mai', 'QHM', 2),
(78, 'Quận Thanh Xuân', 'QTX', 2),
(79, 'Quận Hà Đông', 'QHD', 2),
(80, 'Quận Nam Từ Liêm', 'QNTL', 2),
(81, 'Quận Bắc Từ Liêm', 'QBTL', 2),
(82, 'Huyện Sóc Sơn', 'HSS', 2),
(83, 'Huyện Đông Anh', 'HDA', 2),
(84, 'Huyện Gia Lâm', 'HGL', 2),
(85, 'Huyện Quốc Oai', 'HQO', 2),
(86, 'Huyện Thạch Thất', 'HTT', 2),
(87, 'Huyện Chương Mỹ', 'HCM', 2),
(88, 'Huyện Thanh Oai', 'HTO', 2),
(89, 'Huyện Thường Tín', 'HTT2', 2),
(90, 'Huyện Phú Xuyên', 'HPX', 2),
(91, 'Huyện Ứng Hòa', 'HUH', 2),
(92, 'Huyện Mỹ Đức', 'HMD', 2),
(93, 'Huyện Sơn Tây', 'HST', 2),
(94, 'Huyện Ba Vì', 'HBV', 2),
(95, 'Huyện Phúc Thọ', 'HPT', 2),
(96, 'Huyện Đan Phượng', 'HDP', 2),
(97, 'Huyện Hoài Đức', 'HHD', 2);

-- Insert sample branches
INSERT INTO `branches` (`id`, `name`, `province_id`, `district_id`, `address_detail`, `phone`, `email`, `status`, `opening_hours`, `description`) VALUES
(1, 'Chi nhánh Quận 1', 1, 1, '123 Nguyễn Huệ, Tầng 1', '028-1234-5678', 'q1@lvtn.com', 'active', '07:00-22:00', 'Chi nhánh chính tại trung tâm thành phố'),
(2, 'Chi nhánh Quận 7', 1, 7, '456 Nguyễn Thị Thập, Tầng 1', '028-8765-4321', 'q7@lvtn.com', 'active', '07:00-22:00', 'Chi nhánh tại khu vực Nam Sài Gòn'),
(3, 'Chi nhánh Quận 3', 1, 3, '789 Lê Văn Sỹ, Tầng 1', '028-9999-8888', 'q3@lvtn.com', 'active', '07:00-22:00', 'Chi nhánh tại khu vực trung tâm');

-- Insert admin user
INSERT INTO `users` (`id`, `role_id`, `username`, `password`, `email`, `name`, `status`) VALUES
(1, 1, 'admin', '$2b$10$S7bscswgSzw615X1yfGl0eXbnsCeLH2ZWleqLfZPh4RsFpMVFjqya', 'admin@lvtn.com', 'Administrator', 'active');

-- Insert sample floors
INSERT INTO `floors` (`id`, `branch_id`, `floor_number`, `name`, `description`, `capacity`, `status`) VALUES
(1, 1, 1, 'Tầng 1', 'Tầng trệt - Khu vực chính', 50, 'active'),
(2, 1, 2, 'Tầng 2', 'Tầng lầu - Khu vực yên tĩnh', 30, 'active'),
(3, 2, 1, 'Tầng 1', 'Tầng trệt - Khu vực chính', 40, 'active'),
(4, 2, 2, 'Tầng 2', 'Tầng lầu - Khu vực yên tĩnh', 25, 'active'),
(5, 3, 1, 'Tầng 1', 'Tầng trệt - Khu vực chính', 35, 'active');

-- Insert sample tables
INSERT INTO `tables` (`id`, `branch_id`, `floor_id`, `table_number`, `capacity`, `status`, `location`) VALUES
(1, 1, 1, 'T01', 2, 'available', 'Gần cửa sổ'),
(2, 1, 1, 'T02', 4, 'available', 'Góc yên tĩnh'),
(3, 1, 1, 'T03', 6, 'available', 'Khu vực chính'),
(4, 1, 1, 'T04', 2, 'available', 'Gần cửa sổ'),
(5, 1, 2, 'T05', 4, 'available', 'Khu yên tĩnh'),
(6, 2, 3, 'T01', 2, 'available', 'Gần cửa sổ'),
(7, 2, 3, 'T02', 4, 'available', 'Góc yên tĩnh'),
(8, 2, 4, 'T03', 6, 'available', 'Khu vực chính'),
(9, 3, 5, 'T01', 4, 'available', 'Khu yên tĩnh'),
(10, 3, 5, 'T02', 6, 'available', 'Góc riêng tư');

-- Insert categories
INSERT INTO `categories` (`id`, `name`, `description`) VALUES
(1, 'Khai vị', 'Các món khai vị ngon miệng, kích thích vị giác'),
(2, 'Món chính', 'Các món ăn chính đặc trưng của nhà hàng'),
(3, 'Tráng miệng', 'Các món tráng miệng hấp dẫn và ngọt ngào'),
(4, 'Đồ uống', 'Các loại đồ uống đa dạng, từ nước ngọt đến cocktail'),
(5, 'Combo', 'Các combo tiết kiệm cho gia đình và nhóm');

-- Insert sample products
INSERT INTO `products` (`id`, `category_id`, `name`, `base_price`, `description`, `is_global_available`, `status`) VALUES
(1, 1, 'Gỏi cuốn tôm thịt', 45000.00, 'Gỏi cuốn tươi ngon với tôm và thịt luộc, rau sống tươi', 1, 'active'),
(2, 1, 'Chả giò', 35000.00, 'Chả giò giòn rụm với nhân thịt băm và tôm', 1, 'active'),
(3, 1, 'Nem nướng Nha Trang', 55000.00, 'Nem nướng đặc sản Nha Trang với nước chấm đặc biệt', 1, 'active'),
(4, 1, 'Bánh xèo', 42000.00, 'Bánh xèo giòn tan với tôm, thịt và giá đỗ', 1, 'active'),
(5, 2, 'Phở bò', 65000.00, 'Phở bò truyền thống với nước dùng đậm đà', 1, 'active'),
(6, 2, 'Cơm tấm sườn nướng', 55000.00, 'Cơm tấm với sườn nướng thơm ngon, bì, chả', 1, 'active'),
(7, 2, 'Bún chả Hà Nội', 60000.00, 'Bún chả đặc trưng Hà Nội với thịt nướng', 1, 'active'),
(8, 2, 'Bún bò Huế', 70000.00, 'Bún bò Huế cay nồng với thịt bò và chả cua', 1, 'active'),
(9, 3, 'Chè ba màu', 25000.00, 'Chè ba màu truyền thống với đậu xanh, đậu đỏ', 1, 'active'),
(10, 3, 'Bánh flan', 30000.00, 'Bánh flan mềm mịn với caramel ngọt ngào', 1, 'active'),
(11, 4, 'Nước mía', 20000.00, 'Nước mía tươi mát, giải khát', 1, 'active'),
(12, 4, 'Trà đá', 15000.00, 'Trà đá giải khát truyền thống', 1, 'active'),
(13, 4, 'Cà phê sữa đá', 25000.00, 'Cà phê sữa đá đậm đà kiểu Sài Gòn', 1, 'active'),
(14, 5, 'Combo gia đình 4 người', 350000.00, 'Combo gồm: Phở bò, Cơm tấm, Bún chả, Bánh mì + 4 đồ uống', 1, 'active');

-- Insert branch products for all branches
INSERT INTO `branch_products` (`branch_id`, `product_id`, `price`, `is_available`, `status`) VALUES
-- Branch 1 products
(1, 1, 45000.00, 1, 'available'),
(1, 2, 35000.00, 1, 'available'),
(1, 3, 55000.00, 1, 'available'),
(1, 4, 42000.00, 1, 'available'),
(1, 5, 65000.00, 1, 'available'),
(1, 6, 55000.00, 1, 'available'),
(1, 7, 60000.00, 1, 'available'),
(1, 8, 70000.00, 1, 'available'),
(1, 9, 25000.00, 1, 'available'),
(1, 10, 30000.00, 1, 'available'),
(1, 11, 20000.00, 1, 'available'),
(1, 12, 15000.00, 1, 'available'),
(1, 13, 25000.00, 1, 'available'),
(1, 14, 350000.00, 1, 'available'),

-- Branch 2 products (some different prices and status)
(2, 1, 47000.00, 0, 'out_of_stock'),
(2, 2, 36000.00, 1, 'available'),
(2, 3, 55000.00, 1, 'available'),
(2, 4, 42000.00, 0, 'temporarily_unavailable'),
(2, 5, 68000.00, 1, 'available'),
(2, 6, 55000.00, 1, 'available'),
(2, 7, 60000.00, 1, 'available'),
(2, 8, 70000.00, 0, 'out_of_stock'),
(2, 9, 25000.00, 1, 'available'),
(2, 10, 30000.00, 1, 'available'),
(2, 11, 20000.00, 1, 'available'),
(2, 12, 15000.00, 1, 'available'),
(2, 13, 25000.00, 1, 'available'),
(2, 14, 360000.00, 1, 'available'),

-- Branch 3 products
(3, 1, 45000.00, 1, 'available'),
(3, 2, 35000.00, 1, 'available'),
(3, 3, 55000.00, 1, 'available'),
(3, 4, 42000.00, 1, 'available'),
(3, 5, 65000.00, 1, 'available'),
(3, 6, 55000.00, 1, 'available'),
(3, 7, 60000.00, 1, 'available'),
(3, 8, 70000.00, 1, 'available'),
(3, 9, 25000.00, 1, 'available'),
(3, 10, 30000.00, 1, 'available'),
(3, 11, 20000.00, 1, 'available'),
(3, 12, 15000.00, 1, 'available'),
(3, 13, 25000.00, 1, 'available'),
(3, 14, 350000.00, 1, 'available');

-- =====================================================
-- END OF SCHEMA
-- =====================================================
