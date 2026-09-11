import 'package:permission_handler/permission_handler.dart';

enum PermissionOutcome { granted, denied, permanentlyDenied }

/// Wraps permission_handler so call screens never touch the plugin
/// directly — they just get one of three clear outcomes and react to it.
class PermissionService {
  PermissionService._();

  static Future<PermissionOutcome> requestMicrophone() =>
      _request(Permission.microphone);

  static Future<PermissionOutcome> requestCamera() =>
      _request(Permission.camera);

  /// Both mic + camera, used before starting a video call.
  static Future<PermissionOutcome> requestAudioAndVideo() async {
    final statuses = await [Permission.microphone, Permission.camera].request();
    if (statuses.values.every((s) => s.isGranted)) {
      return PermissionOutcome.granted;
    }
    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      return PermissionOutcome.permanentlyDenied;
    }
    return PermissionOutcome.denied;
  }

  static Future<PermissionOutcome> _request(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;
    return PermissionOutcome.denied;
  }

  static Future<void> openSettings() => openAppSettings();
}
