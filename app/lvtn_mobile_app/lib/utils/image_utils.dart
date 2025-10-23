import '../config/env.dart';
import '../constants/app_constants.dart';

class ImageUtils {
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _getDefaultImageUrl();
    }
    
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    if (imagePath.startsWith('/public')) {
      return '${Environment.baseUrl.replaceAll('/api', '')}$imagePath';
    }
    
    return '${Environment.baseUrl.replaceAll('/api', '')}/public/uploads/$imagePath';
  }
  
  static String _getDefaultImageUrl() {
    return '${Environment.baseUrl.replaceAll('/api', '')}${AppConstants.defaultProductImage}';
  }
  
  static String getBranchImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _getDefaultBranchImageUrl();
    }
    
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    if (imagePath.startsWith('/public')) {
      return '${Environment.baseUrl.replaceAll('/api', '')}$imagePath';
    }
    
    return '${Environment.baseUrl.replaceAll('/api', '')}/public/uploads/$imagePath';
  }
  
  static String _getDefaultBranchImageUrl() {
    return '${Environment.baseUrl.replaceAll('/api', '')}${AppConstants.defaultBranchImage}';
  }
}
