import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shutter_state.dart';
import '../services/mqtt_service.dart';
import '../services/voice_service.dart';

class ShutterNotifier extends StateNotifier<ShutterStateModel> {
  final MqttService _mqttService;
  final VoiceService _voiceService;
  StreamSubscription<String>? _stateSub;
  StreamSubscription<int>? _positionSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<VoiceCommand>? _voiceSub;

  ShutterNotifier(this._mqttService, this._voiceService)
      : super(ShutterStateModel.initial()) {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _stateSub = _mqttService.stateStream.listen((state) {
      state = state.trim().toUpperCase();
      state = state.replaceAll('"', '');
      state = state.replaceAll("'", '');
      state = state.replaceAll(RegExp(r'[^A-Z]'), '');
      updateState(state: state);
    });

    _positionSub = _mqttService.positionStream.listen((position) {
      updateState(position: position);
    });

    _statusSub = _mqttService.statusStream.listen((status) {
      status = status.toLowerCase();
      updateState(isOnline: status == 'online');
    });

    _voiceSub = _voiceService.commandStream.listen((voiceCmd) {
      processVoiceCommand(voiceCmd.command);
    });
  }

  void updateState({
    String? state,
    int? position,
    bool? isConnected,
    bool? isOnline,
    String? error,
  }) {
    state = state ?? this.state.state;
    position = position ?? this.state.position;
    
    if (position < 0 || position > 100) {
      // Keep previous if invalid
      position = this.state.position;
    }
    
    this.state = this.state.copyWith(
      state: state,
      position: position,
      isConnected: isConnected ?? _mqttService.isConnected,
      isOnline: isOnline ?? this.state.isOnline,
      lastUpdated: DateTime.now(),
      error: error,
    );
  }

  void processVoiceCommand(String command) {
    final cmd = command.toLowerCase().trim();
    
    if (cmd == 'open' && state.canOpen) {
      _mqttService.publishCommand('open');
    } else if (cmd == 'close' && state.canClose) {
      _mqttService.publishCommand('close');
    } else if (cmd == 'stop' && state.canStop) {
      _mqttService.publishCommand('stop');
    } else {
      // Could not execute - already at state or moving
      print('Cannot execute $cmd: current state=${state.state}, pos=${state.position}');
    }
  }

  void sendManualCommand(String command) {
    final cmd = command.toLowerCase().trim();
    if (cmd == 'open' || cmd == 'close' || cmd == 'stop') {
      processVoiceCommand(cmd);
    } else {
      _mqttService.publishCommand(cmd);
    }
  }

  void updateConnectionStatus() {
    updateState(isConnected: _mqttService.isConnected);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _statusSub?.cancel();
    _voiceSub?.cancel();
    super.dispose();
  }
}

final mqttServiceProvider = Provider<MqttService>((ref) => MqttService());
final voiceServiceProvider = Provider<VoiceService>((ref) => VoiceService());

final shutterProvider = StateNotifierProvider<ShutterNotifier, ShutterStateModel>(
  (ref) => ShutterNotifier(
    ref.watch(mqttServiceProvider),
    ref.watch(voiceServiceProvider),
  ),
);
