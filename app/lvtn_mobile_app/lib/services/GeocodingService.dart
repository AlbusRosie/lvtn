import 'package:geocoding/geocoding.dart';

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Geocode địa chỉ thành tọa độ (lat, lng)
  /// Trả về null nếu địa chỉ không hợp lệ
  /// Chỉ kiểm tra cơ bản: không rỗng, có thể geocode được, và tọa độ trong phạm vi Việt Nam
  Future<LocationCoordinates?> geocodeAddress(String address) async {
    try {
      final trimmedAddress = address.trim();
      if (trimmedAddress.isEmpty || trimmedAddress.length < 3) {
        return null;
      }

      List<Location> locations = await locationFromAddress(trimmedAddress);
      
      if (locations.isEmpty) {
        print('GeocodingService: Không tìm thấy địa chỉ: $trimmedAddress');
        return null;
      }

      final location = locations.first;
      
      if (!_isValidVietnamCoordinates(location.latitude, location.longitude)) {
        print('GeocodingService: Tọa độ không nằm trong phạm vi Việt Nam: ${location.latitude}, ${location.longitude}');
        return null;
      }

      return LocationCoordinates(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (e) {
      print('GeocodingService: Lỗi khi geocode địa chỉ "$address": $e');
      return null;
    }
  }

  /// Kiểm tra tọa độ có nằm trong phạm vi Việt Nam không
  bool _isValidVietnamCoordinates(double latitude, double longitude) {
    return latitude >= 8.5 && latitude <= 23.5 && 
           longitude >= 102.0 && longitude <= 110.0;
  }

  /// Reverse geocode: chuyển tọa độ thành địa chỉ
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;
      final address = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
      
      return address;
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Lấy thông tin chi tiết từ reverse geocode (Placemark)
  Future<Placemark?> getPlacemark(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return null;
      }
      return placemarks.first;
    } catch (e) {
      print('Get placemark error: $e');
      return null;
    }
  }

  /// Tạo danh sách các biến thể tên province có thể xuất hiện trong reverse geocode
  /// Dựa trên dữ liệu từ DB (provinces table)
  List<String> _getProvinceNameVariants(String provinceName) {
    final variants = <String>[provinceName];
    final lower = provinceName.toLowerCase().trim();

    if (lower.contains('ho chi minh') || lower.contains('hồ chí minh') || lower == 'ho chi minh city') {
      variants.addAll([
        'ho chi minh',
        'hồ chí minh', 
        'ho chi minh city',
        'thành phố hồ chí minh',
        'tp hcm',
        'hcm',
        'ho chi minh',
        'saigon',
        'sài gòn'
      ]);
    } else if (lower.contains('hanoi') || lower.contains('hà nội') || lower == 'hanoi') {
      variants.addAll([
        'hanoi',
        'hà nội',
        'hanoi city',
        'thành phố hà nội',
        'tp hà nội',
        'ha noi'
      ]);
    } else if (lower.contains('da nang') || lower.contains('đà nẵng') || lower == 'da nang') {
      variants.addAll([
        'da nang',
        'đà nẵng',
        'da nang city',
        'thành phố đà nẵng'
      ]);
    } else if (lower.contains('can tho') || lower.contains('cần thơ') || lower == 'can tho') {
      variants.addAll([
        'can tho',
        'cần thơ',
        'can tho city',
        'thành phố cần thơ'
      ]);
    } else if (lower.contains('ba ria') || lower.contains('vung tau')) {
      variants.addAll([
        'ba ria - vung tau',
        'ba ria vung tau',
        'vũng tàu',
        'vung tau'
      ]);
    } else if (lower.contains('thua thien') || lower.contains('hue')) {
      variants.addAll([
        'thua thien - hue',
        'thua thien hue',
        'huế',
        'hue'
      ]);
    } else {
      final cleaned = provinceName
          .replaceAll(' Province', '')
          .replaceAll(' province', '')
          .replaceAll(' City', '')
          .replaceAll(' city', '')
          .trim();
      if (cleaned != provinceName) {
        variants.add(cleaned);
      }
    }

    return variants;
  }

  /// Tạo danh sách các biến thể tên district có thể xuất hiện trong reverse geocode
  /// Dựa trên dữ liệu từ DB (districts table)
  List<String> _getDistrictNameVariants(String districtName) {
    final variants = <String>[districtName];
    final lower = districtName.toLowerCase().trim();

    if (lower.startsWith('district ')) {
      final number = districtName.replaceAll('District ', '').replaceAll('district ', '').trim();
      variants.addAll([
        'district $number',
        'district $number',
        'quận $number',
        'quan $number',
        'q$number',
        'q $number',
        'q.$number',
        number,
      ]);
    } else if (lower.endsWith(' district')) {
      final name = districtName.replaceAll(' District', '').replaceAll(' district', '').trim();
      variants.addAll([
        '$name district',
        'quận $name',
        'quan $name',
        name,
        name.toLowerCase(),
      ]);
    } else {
      variants.addAll([
        '$districtName district',
        'quận $districtName',
        'quan $districtName',
      ]);
    }

    return variants;
  }

  /// Validate địa chỉ chi tiết (detail address) với province và district đã chọn
  /// Đây là method chính để validate địa chỉ khi user đã chọn province/district từ DB
  /// address: Địa chỉ chi tiết (số nhà, tên đường, phường/xã)
  /// fullAddress: Địa chỉ đầy đủ bao gồm cả district và province
  Future<ValidationResult> validateDetailAddress({
    required String detailAddress,
    required String provinceName,
    String? districtName,
  }) async {
    final trimmedDetail = detailAddress.trim();
    
    final formatValidation = _validateDetailAddressFormat(trimmedDetail);
    if (!formatValidation.isValid) {
      return ValidationResult(
        isValid: false,
        errorMessage: formatValidation.errorMessage ?? 'Địa chỉ không hợp lệ',
        coordinates: null,
      );
    }

    String fullAddress = trimmedDetail;
    if (districtName != null && districtName.isNotEmpty) {
      fullAddress = '$fullAddress, $districtName';
    }
    fullAddress = '$fullAddress, $provinceName, Vietnam';

    print('GeocodingService: Đang validate địa chỉ: $fullAddress');

    final coordinates = await geocodeAddress(fullAddress);
    if (coordinates == null) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Địa chỉ không hợp lệ hoặc không tìm thấy trên bản đồ',
        coordinates: null,
      );
    }

    final placemark = await getPlacemark(
      coordinates.latitude,
      coordinates.longitude,
    );

    if (placemark == null) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Không thể xác minh địa chỉ',
        coordinates: coordinates,
      );
    }

    final hasStreetInfo = (placemark.street != null && placemark.street!.isNotEmpty) ||
                         (placemark.subLocality != null && placemark.subLocality!.isNotEmpty);
    
    if (!hasStreetInfo) {
      print('GeocodingService: Cảnh báo - Reverse geocode không trả về thông tin đường/phố chi tiết');
    }

    final placemarkTexts = [
      placemark.administrativeArea ?? '',
      placemark.locality ?? '',
      placemark.subAdministrativeArea ?? '',
    ].where((e) => e.isNotEmpty).map((e) => e.toLowerCase()).toList();
    
    final combinedText = placemarkTexts.join(' ');
    final provinceVariants = _getProvinceNameVariants(provinceName);
    final normalizedProvinceVariants = provinceVariants.map((v) => v.toLowerCase().trim()).toList();
    
    final hasProvinceMatch = normalizedProvinceVariants.any((variant) {
      return placemarkTexts.any((text) => 
        text == variant || 
        text.contains(variant) || 
        variant.contains(text)
      ) || combinedText.contains(variant);
    });

    if (!hasProvinceMatch) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Địa chỉ không khớp với tỉnh/thành phố đã chọn',
        coordinates: coordinates,
        placemark: placemark,
      );
    }

    final reverseGeocodeAddress = await reverseGeocode(
      coordinates.latitude,
      coordinates.longitude,
    );
    
    if (reverseGeocodeAddress != null) {
      final reverseLower = reverseGeocodeAddress.toLowerCase();
      final provinceLower = provinceName.toLowerCase();
      
      if (reverseLower == provinceLower || 
          (reverseLower.contains(provinceLower) && reverseLower.length < provinceLower.length + 10)) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Địa chỉ không đủ chi tiết. Vui lòng nhập số nhà và tên đường cụ thể',
          coordinates: coordinates,
          placemark: placemark,
        );
      }
    }

    if (districtName != null && districtName.isNotEmpty) {
      final districtVariants = _getDistrictNameVariants(districtName);
      final normalizedDistrictVariants = districtVariants.map((v) => v.toLowerCase().trim()).toList();
      
      final hasDistrictMatch = normalizedDistrictVariants.any((variant) {
        return placemarkTexts.any((text) => 
          text == variant || 
          text.contains(variant) || 
          variant.contains(text)
        ) || combinedText.contains(variant);
      });

      if (!hasDistrictMatch) {
        print('GeocodingService: Cảnh báo - District có thể không khớp: $districtName');
      }
    }

    return ValidationResult(
      isValid: true,
      errorMessage: null,
      coordinates: coordinates,
      placemark: placemark,
    );
  }

  /// Validate format địa chỉ chi tiết
  /// Kiểm tra địa chỉ có chứa từ khóa hợp lệ, số nhà, tên đường, v.v.
  _FormatValidationResult _validateDetailAddressFormat(String detailAddress) {
    if (detailAddress.isEmpty) {
      return _FormatValidationResult(
        isValid: false,
        errorMessage: 'Vui lòng nhập địa chỉ chi tiết',
      );
    }

    if (detailAddress.length < 5) {
      return _FormatValidationResult(
        isValid: false,
        errorMessage: 'Địa chỉ quá ngắn. Vui lòng nhập địa chỉ chi tiết hơn',
      );
    }

    final lowerAddress = detailAddress.toLowerCase();

    final addressKeywords = [
      'đường', 'duong', 'street', 'phố', 'pho', 'road',
      'ngõ', 'ngo', 'hẻm', 'hem', 'lane', 'alley',
      'số', 'so', 'number', 'no', 'no.',
      'phường', 'phuong', 'ward', 'xã', 'xa', 'commune',
      'tổ', 'to', 'khu', 'ap', 'ấp',
    ];

    final hasAddressKeyword = addressKeywords.any((keyword) => lowerAddress.contains(keyword));

    final hasNumber = RegExp(r'\d').hasMatch(detailAddress);

    final isOnlyLetters = RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(detailAddress);
    final isRandomString = detailAddress.length > 10 && 
                          !hasNumber && 
                          !hasAddressKeyword && 
                          isOnlyLetters &&
                          !_containsValidVietnameseWords(lowerAddress);

    if (isRandomString) {
      return _FormatValidationResult(
        isValid: false,
        errorMessage: 'Địa chỉ không hợp lệ. Vui lòng nhập số nhà và tên đường cụ thể',
      );
    }

    if (detailAddress.length > 8 && !hasNumber && !hasAddressKeyword) {
      return _FormatValidationResult(
        isValid: false,
        errorMessage: 'Địa chỉ không hợp lệ. Vui lòng nhập số nhà hoặc tên đường',
      );
    }

    if (detailAddress.length < 10 && !hasNumber && !hasAddressKeyword) {
      return _FormatValidationResult(
        isValid: false,
        errorMessage: 'Địa chỉ không đủ chi tiết. Vui lòng nhập số nhà và tên đường',
      );
    }

    return _FormatValidationResult(isValid: true);
  }

  /// Kiểm tra địa chỉ có chứa từ tiếng Việt hợp lệ không
  /// Để phân biệt với chuỗi ngẫu nhiên
  bool _containsValidVietnameseWords(String address) {
    final validWords = [
      'phường', 'phuong', 'xã', 'xa', 'quận', 'quan', 'huyện', 'huyen',
      'tỉnh', 'tinh', 'thành phố', 'thanh pho', 'tp',
      'đường', 'duong', 'phố', 'pho', 'ngõ', 'ngo', 'hẻm', 'hem',
      'số', 'so', 'tổ', 'to', 'khu', 'ấp', 'ap',
      'trung tâm', 'trung tam', 'khu vực', 'khu vuc',
      'chung cư', 'chung cu', 'tòa nhà', 'toa nha',
    ];

    return validWords.any((word) => address.contains(word));
  }
}

class LocationCoordinates {
  final double latitude;
  final double longitude;

  LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });
}

/// Kết quả validation địa chỉ
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final LocationCoordinates? coordinates;
  final Placemark? placemark;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.coordinates,
    this.placemark,
  });
}

/// Kết quả validation format địa chỉ
class _FormatValidationResult {
  final bool isValid;
  final String? errorMessage;

  _FormatValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

