class AppConfig {
  /// Base API URL (change when switching environments)
  static const String apiBaseUrl = "http://192.168.1.105:8080";

  /// REST API base
  static String get apiUrl => "$apiBaseUrl/api";

  /// Websocket URL
  static String get wsUrl {
    if (apiBaseUrl.startsWith('https://')) {
      return 'wss://${apiBaseUrl.substring(8)}/ws';
    }
    if (apiBaseUrl.startsWith('http://')) {
      return 'ws://${apiBaseUrl.substring(7)}/ws';
    }
    return '$apiBaseUrl/ws';
  }

  /// Google Maps API
  static const String googleMapsApiKey =
      'AIzaSyDuZC6kFobB0pnp-k3VcxQIjvb0EhgfnVI';
}
