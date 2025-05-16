
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  bool isConnected = true;

  ConnectivityService() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      isConnected = result != ConnectivityResult.none;
    });
  }
}