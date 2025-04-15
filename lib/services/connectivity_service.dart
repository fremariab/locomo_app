import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  factory ConnectivityService() => _instance;
  
  ConnectivityService._internal();
  
  // Check if the device is connected to the internet
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // Stream of connectivity changes
  Stream<bool> get connectivityStream => 
    Connectivity().onConnectivityChanged.map((result) => result != ConnectivityResult.none);
  
  // Get the current connectivity status
  Future<ConnectivityResult> getConnectivityStatus() async {
    // Use a different approach to avoid type issues
    final result = await Connectivity().checkConnectivity();
    
    // Convert the result to a string and then back to ConnectivityResult
    final resultString = result.toString();
    
    // Map the string to the appropriate ConnectivityResult
    if (resultString.contains('wifi')) {
      return ConnectivityResult.wifi;
    } else if (resultString.contains('mobile')) {
      return ConnectivityResult.mobile;
    } else if (resultString.contains('ethernet')) {
      return ConnectivityResult.ethernet;
    } else if (resultString.contains('vpn')) {
      return ConnectivityResult.vpn;
    } else if (resultString.contains('other')) {
      return ConnectivityResult.other;
    } else {
      return ConnectivityResult.none;
    }
  }
} 