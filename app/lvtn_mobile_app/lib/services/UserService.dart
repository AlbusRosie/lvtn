import 'dart:io';
import '../constants/api_constants.dart';
import '../models/user.dart';
import 'APIService.dart';
import 'StorageService.dart';
import '../constants/app_constants.dart';
import 'dart:convert';
import 'AuthService.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  Future<User> updateUser(int userId, Map<String, dynamic> updateData) async {
    try {
      print('UserService.updateUser: userId=$userId, updateData=$updateData');
      
      final response = await ApiService().put('${ApiConstants.users}/$userId', updateData);
      
      print('UserService.updateUser: Response=$response');
      
      if (response == null) {
        throw Exception('Không nhận được phản hồi từ server');
      }

      dynamic userData;
      if (response is Map) {
        if (response['user'] != null) {
          userData = response['user'];
        } else {
          userData = response;
        }
      } else {
        throw Exception('Response không đúng định dạng: ${response.runtimeType}');
      }
      
      print('UserService.updateUser: userData=$userData');
      
      final updatedUser = User.fromJson(userData as Map<String, dynamic>);
      
      print('UserService.updateUser: Updated user - id=${updatedUser.id}, name=${updatedUser.name}');
      
      final authService = AuthService();
      if (authService.currentUser?.id == userId) {
        await StorageService().setString(
          AppConstants.userDataKey,
          jsonEncode(updatedUser.toJson()),
        );
        print('UserService.updateUser: Updated user in storage');
      }
      
      return updatedUser;
    } catch (error, stackTrace) {
      print('UserService.updateUser error: $error');
      print('UserService.updateUser stackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<User> updateUserAddress(int userId, String address) async {
    return await updateUser(userId, {'address': address});
  }

  Future<User> updateUserWithAvatar(int userId, Map<String, dynamic> updateData, File? avatarFile) async {
    try {
      print('UserService.updateUserWithAvatar: userId=$userId, updateData=$updateData, hasFile=${avatarFile != null}');
      
      User updatedUser;
      
      final cleanUpdateData = Map<String, dynamic>.from(updateData);
      if (avatarFile == null) {
        cleanUpdateData.removeWhere((key, value) => value == null);
      }
      
      if (cleanUpdateData.isEmpty && avatarFile == null) {
        print('UserService.updateUserWithAvatar: No data to update');
        throw Exception('Không có dữ liệu nào để cập nhật');
      }
      
      print('UserService.updateUserWithAvatar: cleanUpdateData=$cleanUpdateData');
      
      if (avatarFile != null) {
        print('UserService.updateUserWithAvatar: Using multipart upload');
        final response = await ApiService().putMultipart(
          '${ApiConstants.users}/$userId',
          updateData,
          file: avatarFile,
          fileFieldName: 'avatarFile',
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Yêu cầu upload ảnh quá thời gian chờ');
          },
        );
        
        print('UserService.updateUserWithAvatar: Multipart response=$response');
        print('UserService.updateUserWithAvatar: Response type=${response.runtimeType}');
        
        if (response == null) {
          throw Exception('Không nhận được phản hồi từ server');
        }

        dynamic userData;
        if (response is Map) {
          if (response['user'] != null) {
            userData = response['user'];
          } else if (response['data'] != null && response['data'] is Map) {
            userData = response['data'];
          } else {
            userData = response;
          }
        } else {
          throw Exception('Response không đúng định dạng: ${response.runtimeType}');
        }
        
        print('UserService.updateUserWithAvatar: userData=$userData');
        if (userData is! Map) {
          throw Exception('User data không phải là object: ${userData.runtimeType}');
        }
        
        updatedUser = User.fromJson(userData as Map<String, dynamic>);
      } else {
        print('UserService.updateUserWithAvatar: Using regular PUT');
        updatedUser = await updateUser(userId, cleanUpdateData).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Yêu cầu cập nhật quá thời gian chờ');
          },
        );
      }
      
      print('UserService.updateUserWithAvatar: Updated user - id=${updatedUser.id}, name=${updatedUser.name}');
      
      // Update storage in background, don't wait for it
      final authService = AuthService();
      if (authService.currentUser?.id == userId) {
        try {
          await StorageService().setString(
            AppConstants.userDataKey,
            jsonEncode(updatedUser.toJson()),
          ).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              print('UserService: Storage update timeout, continuing anyway');
            },
          );
          print('UserService.updateUserWithAvatar: Updated user in storage');
        } catch (e) {
          print('UserService: Error updating storage: $e, continuing anyway');
        }
      }
      
      return updatedUser;
    } catch (error, stackTrace) {
      print('UserService.updateUserWithAvatar error: $error');
      print('UserService.updateUserWithAvatar stackTrace: $stackTrace');
      rethrow;
    }
  }
}

