import 'package:flutter_test/flutter_test.dart';

import 'package:autonomous_shutter_app/models/shutter_state.dart';

void main() {
  group('ShutterStateModel', () {
    test('initial state is unknown', () {
      final state = ShutterStateModel.initial();
      expect(state.state, 'UNKNOWN');
      expect(state.position, -1);
    });

    test('canOpen is false when already open', () {
      final state = ShutterStateModel(
        state: 'OPEN',
        position: 100,
        isConnected: true,
        isOnline: true,
        lastUpdated: DateTime.now(),
      );
      expect(state.canOpen, false);
      expect(state.canClose, true);
    });

    test('cannot command while moving', () {
      final state = ShutterStateModel(
        state: 'OPENING',
        position: 50,
        isConnected: true,
        isOnline: true,
        lastUpdated: DateTime.now(),
      );
      expect(state.canOpen, false);
      expect(state.canClose, false);
      expect(state.canStop, true);
    });
  });
}
