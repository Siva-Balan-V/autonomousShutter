import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/app_config.dart';

class MqttService {
  late MqttServerClient _client;
  bool _isConnected = false;
  
  final _stateController = StreamController<String>.broadcast();
  final _positionController = StreamController<int>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<String> get stateStream => _stateController.stream;
  Stream<int> get positionStream => _positionController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  
  bool get isConnected => _isConnected;
  
  Future<bool> connect() async {
    _client = MqttServerClient(
      AppConfig.mqttHost,
      'app_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    _client.port = AppConfig.mqttPort;
    _client.secure = true;
    _client.securityContext = SecurityContext.defaultContext;
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = onDisconnected;
    _client.onConnected = onConnected;
    _client.onSubscribed = onSubscribed;
    
    final connMessage = MqttConnectMessage()
        .authenticateAs(AppConfig.mqttUsername, AppConfig.mqttPassword)
        .withWillTopic(AppConfig.statusTopic)
        .withWillMessage('offline')
        .withWillQos(MqttQos.atLeastOnce)
        .startClean()
        .withClientIdentifier('shutter_app_client');
    
    _client.connectionMessage = connMessage;
    
    try {
      await _client.connect();
    } catch (e) {
      print('MQTT connection failed: $e');
      return false;
    }
    
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _isConnected = true;
      _subscribeToTopics();
      return true;
    }
    
    return false;
  }
  
  void _subscribeToTopics() {
    _client.subscribe(AppConfig.stateTopic, MqttQos.atLeastOnce);
    _client.subscribe(AppConfig.positionTopic, MqttQos.atLeastOnce);
    _client.subscribe(AppConfig.statusTopic, MqttQos.atLeastOnce);
    _client.subscribe(AppConfig.eventTopic, MqttQos.atLeastOnce);
    _client.subscribe(AppConfig.telemetryTopic, MqttQos.atLeastOnce);
    
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final topic = c[0].topic;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      if (topic == AppConfig.stateTopic) {
        _stateController.add(payload);
      } else if (topic == AppConfig.positionTopic) {
        final pos = int.tryParse(payload) ?? -1;
        _positionController.add(pos);
      } else if (topic == AppConfig.statusTopic) {
        _statusController.add(payload);
      } else if (topic == AppConfig.eventTopic) {
        // Parse JSON if needed
        _eventController.add({'raw': payload});
      }
    });
  }
  
  void publishCommand(String command) {
    if (!_isConnected) return;
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(command);
    
    _client.publishMessage(
      AppConfig.cmdTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }
  
  void onConnected() {
    _isConnected = true;
  }
  
  void onDisconnected() {
    _isConnected = false;
  }
  
  void onSubscribed(String topic) {
    print('Subscribed to: $topic');
  }
  
  void disconnect() {
    _client.disconnect();
    _isConnected = false;
  }
  
  void dispose() {
    _stateController.close();
    _positionController.close();
    _statusController.close();
    _eventController.close();
    disconnect();
  }
}
