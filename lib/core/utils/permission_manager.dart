import 'package:permission_handler/permission_handler.dart';

/// Centralized permission handling logic.
class PermissionManager {
  Future<bool> ensureCamera() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    // If the status is undetermined, this should trigger the iOS system dialog once.
    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) return true;
    }

    // On iOS, once denied, the system dialog will not show again.
    // Direct the user to Settings so they can enable the permission manually.
    if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
      await openSettings();
      return false;
    }

    return false;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
