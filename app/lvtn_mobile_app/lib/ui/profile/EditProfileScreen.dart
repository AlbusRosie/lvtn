import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/AuthProvider.dart';
import '../../services/UserService.dart';
import '../../services/AuthService.dart';
import '../../services/NotificationService.dart';
import '../../utils/image_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const String routeName = '/edit-profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  File? _selectedImage;
  String? _currentAvatarUrl;
  
  String _initialName = '';
  String _initialEmail = '';
  String? _initialPhone;
  String? _initialAvatarUrl;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _initialName = user?.name ?? '';
    _initialEmail = user?.email ?? '';
    _initialPhone = user?.phone;
    _initialAvatarUrl = user?.avatar;
    
    _nameController = TextEditingController(text: _initialName);
    _emailController = TextEditingController(text: _initialEmail);
    _phoneController = TextEditingController(text: _initialPhone ?? '');
    _currentAvatarUrl = _initialAvatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService().showError(
          context: context,
          message: 'Lỗi khi chọn ảnh: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nameChanged = _nameController.text.trim() != _initialName;
    final emailChanged = _emailController.text.trim() != _initialEmail;
    final phoneChanged = _phoneController.text.trim() != (_initialPhone ?? '');
    final avatarChanged = _selectedImage != null;
    
    if (!nameChanged && !emailChanged && !phoneChanged && !avatarChanged) {
      if (mounted) {
        NotificationService().showInfo(
          context: context,
          message: 'Không có thay đổi nào để cập nhật',
        );
      }
      return;
    }

    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final userService = UserService();
      final Map<String, dynamic> updateData = {};
      
      if (nameChanged) {
        updateData['name'] = _nameController.text.trim();
      }
      if (emailChanged) {
        updateData['email'] = _emailController.text.trim();
      }
      if (phoneChanged) {
        updateData['phone'] = _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim();
      }

      File? avatarFile = avatarChanged ? _selectedImage : null;
      
      final updatedUser = await userService.updateUserWithAvatar(
        user.id,
        updateData,
        avatarFile,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Yêu cầu quá thời gian chờ. Vui lòng thử lại.');
        },
      );
      
      if (updatedUser.id <= 0) {
        throw Exception('Dữ liệu người dùng không hợp lệ');
      }
      
      // Merge user mới với user hiện tại - chỉ cập nhật những trường đã thay đổi
      // Server có thể chỉ trả về những trường đã cập nhật, không phải tất cả
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        throw Exception('Không tìm thấy thông tin người dùng hiện tại');
      }
      
      // Tạo user mới bằng cách merge: giữ lại tất cả từ user cũ, chỉ cập nhật những trường đã thay đổi
      final finalUser = currentUser.copyWith(
        // Chỉ cập nhật những trường đã thay đổi
        name: nameChanged ? updatedUser.name : currentUser.name,
        email: emailChanged ? updatedUser.email : currentUser.email,
        phone: phoneChanged ? updatedUser.phone : currentUser.phone,
        avatar: avatarChanged ? updatedUser.avatar : currentUser.avatar,
        // Giữ nguyên các trường khác từ user hiện tại
        username: currentUser.username,
        address: currentUser.address,
        roleId: currentUser.roleId,
        status: currentUser.status,
        createdAt: currentUser.createdAt,
      );
      
      // Update initial values
      _initialName = _nameController.text.trim();
      _initialEmail = _emailController.text.trim();
      _initialPhone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      if (avatarChanged && finalUser.avatar != null) {
        _currentAvatarUrl = finalUser.avatar;
        _initialAvatarUrl = finalUser.avatar;
        _selectedImage = null;
      }
      
      // Cập nhật user trong AuthService (không notify listeners để tránh loading)
      final authService = AuthService();
      try {
        await authService.updateCurrentUser(finalUser).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Continue anyway - user data is already updated in memory
          },
        );
      } catch (e) {
        // Continue anyway - user data is already updated in memory
      }
      
      // Hiển thị thông báo thành công
      if (mounted) {
        NotificationService().showSuccess(
          context: context,
          message: 'Cập nhật thông tin thành công',
        );
      }
      
      // KHÔNG notify listeners để tránh trigger rebuild và loading
      // User đã được cập nhật trong AuthService, các màn hình khác sẽ tự động
      // cập nhật khi người dùng navigate đến hoặc khi cần thiết
      
    } catch (e) {
      String errorMessage = 'Lỗi khi cập nhật thông tin';
      if (e.toString().contains('timeout') || e.toString().contains('thời gian')) {
        errorMessage = 'Yêu cầu quá thời gian chờ. Vui lòng kiểm tra kết nối và thử lại.';
      } else if (e.toString().contains('Không nhận được phản hồi')) {
        errorMessage = 'Không thể kết nối đến server. Vui lòng thử lại.';
      } else if (e.toString().contains('không hợp lệ') || e.toString().contains('invalid')) {
        errorMessage = 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      if (mounted) {
        NotificationService().showError(
          context: context,
          message: errorMessage,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: SafeArea(
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.grey[800],
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Thông tin cá nhân',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A00),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          ImageUtils.getImageUrl(_currentAvatarUrl),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person_rounded,
                                              size: 60,
                                              color: Colors.white,
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 18,
                                color: Color(0xFFFF8A00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text(
                        'Thay đổi ảnh đại diện',
                        style: TextStyle(
                          color: Color(0xFFFF8A00),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF8A00),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Thông tin tài khoản',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _nameController,
                label: 'Họ và tên',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value.trim())) {
                      return 'Số điện thoại không hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF8A00).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        const Text(
                          'Lưu thông tin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[900],
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Color(0xFFFF8A00),
              size: 22,
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}

