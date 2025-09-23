import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
    static final StorageService _instance = StorageService._internal();
    factory StorageService() => StorageService._internal();
    StorageService._internal();

    SharedPreferences? _prefs;

    Future<void> initialize() async {
        _prefs = await SharedPreferences.getInstance();
    }

    Future<String?> getAuthToken() async {
        return _prefs?.getString(AppConstants.authTokenKey);
    }

    Future<void> saveAuthToken(String token) async {
        await _prefs?.setString(AppConstants.authTokenKey, token);
    }

    Future<Map<String, dynamic>?> getUserData() async {
        final userDataString = _prefs?.getString(AppConstants.userDataKey);
        if (userDataString != null) {
        return json.decode(userDataString);
        }
        return null;
    }

    Future<void> saveUserData(Map<String, dynamic> userData) async {
        await _prefs?.setString(AppConstants.userDataKey, json.encode(userData));
    }

    Future<void> clearAuthData() async {
        await _prefs?.remove(AppConstants.authTokenKey);
        await _prefs?.remove(AppConstants.userDataKey);
    }

    Future<int?> getSelectedBranchId() async {
        return _prefs?.getInt(AppConstants.selectedBranchKey);
    }

    Future<void> saveSelectedBranchId(int branchId) async {
        await _prefs?.setInt(AppConstants.selectedBranchKey, branchId);
    }

    Future<void> clearSelectedBranch() async {
        await _prefs?.remove(AppConstants.selectedBranchKey);
    }
}
