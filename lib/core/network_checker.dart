import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker {
  static Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static Stream<bool> get connectionStream {
    return Connectivity().onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}
