class Environment {
  static const String emulator = 'emulator';
  static const String device = 'device';
  
  static const String current = emulator;
  
  static String get baseUrl {
    switch (current) {
      case emulator:
        return 'http://10.0.2.2:3000/api';
      case device:
        return 'http://192.168.1.20:3000/api';
      default:
        return 'http://10.0.2.2:3000/api';
    }
  }
  
  static bool get isEmulator => current == emulator;
  static bool get isDevice => current == device;
}
