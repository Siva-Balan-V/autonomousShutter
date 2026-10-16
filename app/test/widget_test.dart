import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autonomous_shutter_app/main.dart';
import 'package:autonomous_shutter_app/providers/shutter_provider.dart';
import 'package:autonomous_shutter_app/services/mqtt_service.dart';
import 'package:autonomous_shutter_app/services/voice_service.dart';

class FakeMqttService extends MqttService {
  @override
  Future<bool> connect() async => false;

  @override
  bool get isConnected => false;

  @override
  void publishCommand(String command) {}
}

class FakeVoiceService extends VoiceService {
  @override
  Future<bool> initialize() async => false;

  @override
  Future<void> startListening() async {}

  @override
  Future<void> stopListening() async {}
}

void main() {
  testWidgets('home screen shows shutter controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mqttServiceProvider.overrideWithValue(FakeMqttService()),
          voiceServiceProvider.overrideWithValue(FakeVoiceService()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Autonomous Shutter Control'), findsOneWidget);
    expect(find.text('Tap to Speak'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('CLOSE'), findsOneWidget);
  });
}
