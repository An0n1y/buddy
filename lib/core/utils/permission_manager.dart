import 'package:permission_handler/permission_handler.dart';

/// Centralized permission handling logic.
class PermissionManager {
  Future<bool> ensureCamera() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final result = await Permission.camera.request();
    return result.isGranted;
  }
}
