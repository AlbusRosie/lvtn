class AppConstants {
  static const int adminRole = 1;
  static const int managerRole = 2;
  static const int staffRole = 3;
  static const int customerRole = 4;
  
  // Order types: Only 2 types
  static const String dineIn = 'dine_in';      // With table reservation
  static const String delivery = 'delivery';    // Without table (delivery/takeaway)
  
  // Order statuses
  static const String pending = 'pending';
  static const String preparing = 'preparing';
  static const String ready = 'ready';
  static const String outForDelivery = 'out_for_delivery';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  
  static const String available = 'available';
  static const String occupied = 'occupied';
  static const String reserved = 'reserved';
  static const String maintenance = 'maintenance';
  
  static const String active = 'active';
  static const String inactive = 'inactive';
  
  static const String defaultAvatar = '/public/images/blank-profile-picture.jpg';
  static const String defaultProductImage = '/public/images/blank-profile-picture.jpg';
  static const String defaultBranchImage = '/public/images/blank-profile-picture.jpg';
  
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String selectedBranchKey = 'selected_branch';
  
  static const int primaryColor = 0xFFFF9800;
}
