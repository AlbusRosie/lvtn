class AppConstants {
  // User Roles
  static const int adminRole = 1;
  static const int managerRole = 2;
  static const int staffRole = 3;
  static const int customerRole = 4;
  
  // Order Types
  static const String dineIn = 'dine_in';
  static const String takeaway = 'takeaway';
  static const String delivery = 'delivery';
  
  // Order Status
  static const String pending = 'pending';
  static const String preparing = 'preparing';
  static const String ready = 'ready';
  static const String served = 'served';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
  
  // Table Status
  static const String available = 'available';
  static const String occupied = 'occupied';
  static const String reserved = 'reserved';
  static const String maintenance = 'maintenance';
  
  // Branch Status
  static const String active = 'active';
  static const String inactive = 'inactive';
  
  // Default Images
  static const String defaultAvatar = '/public/images/blank-profile-picture.png';
  static const String defaultProductImage = '/public/images/blank-profile-picture.png';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String selectedBranchKey = 'selected_branch';
}
