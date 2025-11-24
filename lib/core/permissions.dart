import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestStorage() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
