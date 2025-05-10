import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestBatteryOptimization() async {
    // Doğrudan pil optimizasyonu iznini iste, açıklama dialogu gösterme
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  Future<bool> checkBatteryOptimization() async {
    if (await Permission.ignoreBatteryOptimizations.status.isGranted) {
      return true;
    }
    return false;
  }
}
