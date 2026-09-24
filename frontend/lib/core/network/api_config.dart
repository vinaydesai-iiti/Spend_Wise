/// Central place for every network-tunable constant. Nothing else in the
/// app should hardcode a base URL or a timeout.
class ApiConfig {
  const ApiConfig._();

  /// Points at the SpendWise Node.js/Express backend (see /backend).
  ///
  /// The right value depends on where the API server is actually running
  /// relative to the device/emulator running this app:
  ///  - Android emulator            -> http://10.0.2.2:5000/api
  ///  - iOS simulator / desktop     -> http://localhost:5000/api
  ///  - Physical device on same LAN -> http://<your-machine-LAN-IP>:5000/api
  ///  - Deployed backend            -> https://your-domain.example.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// Flip on locally to see full request/response bodies in the console.
  static const bool enableNetworkLogs = false;
}
