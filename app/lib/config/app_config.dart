import 'secrets.dart';

class AppConfig {
  // Credentials come from secrets.dart (git-ignored).
  // Copy secrets.dart.example -> secrets.dart and fill in values.
  static const String mqttHost = Secrets.mqttHost;
  static const int mqttPort = Secrets.mqttPort;
  static const String mqttUsername = Secrets.mqttUsername;
  static const String mqttPassword = Secrets.mqttPassword;
  static const String deviceId = Secrets.deviceId;

  // MQTT Topics
  static String get cmdTopic => 'shutter/$deviceId/cmd';
  static String get stateTopic => 'shutter/$deviceId/state';
  static String get positionTopic => 'shutter/$deviceId/position';
  static String get telemetryTopic => 'shutter/$deviceId/telemetry';
  static String get eventTopic => 'shutter/$deviceId/event';
  static String get statusTopic => 'shutter/$deviceId/status';

  // Voice command keywords
  static const List<String> openKeywords = ['open', 'open shutter', 'raise', 'up'];
  static const List<String> closeKeywords = ['close', 'close shutter', 'lower', 'down'];
  static const List<String> stopKeywords = ['stop', 'halt', 'pause'];
}
