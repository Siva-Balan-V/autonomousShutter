# Mobile App Build Plan - Autonomous Shutter Voice Control

## Overview
This plan outlines the development of a mobile application for voice-based control of the autonomous shutter system. The app will transcribe voice commands, communicate with the shutter's communication module, check shutter position, and execute appropriate motor actions (open/close).

## Key Requirements
1. **Voice-based commanding** - Transcribe voice input and convert to actionable commands
2. **Data communication** - Communicate with the communication module on the shutter
3. **Position checking** - Check current shutter position before acting
4. **Command execution** - Act accordingly to voice commands (open, close) based on current state
5. **Remote operation** - Work from remote location (as per existing architecture)

## Architecture Summary
- **Platform**: Flutter (recommended, cross-platform)
- **Voice Recognition**: Android SpeechRecognizer / iOS Speech framework
- **Communication**: MQTT over TLS (HiveMQ Cloud) matching existing remote architecture
- **State Sync**: Real-time position and state updates via MQTT topics
- **Auth**: User authentication (Firebase Auth recommended)

## Core Components

### 1. Voice Recognition Service
- Implement speech-to-text using platform native APIs
- Handle microphone permissions
- Process recognized text to extract commands
- Support keywords: "open", "close", "stop", "shutter open", "shutter close"
- Implement error handling for noisy environments

### 2. Command Parser
- Extract intent from transcribed text
- Map to actions: OPEN, CLOSE, STOP
- Handle variations and edge cases
- Return parsed command with confidence

### 3. Shutter State Manager
- Subscribe to MQTT topics for real-time state
- Track: current state, position (0-100%), online/offline status
- Validate commands against current state
- Prevent conflicting operations

### 4. Communication Layer (MQTT)
- Connect to broker with TLS
- Publish commands to `shutter/<deviceId>/cmd`
- Subscribe to: `state`, `position`, `telemetry`, `event`, `status`
- Handle reconnection and offline states
- Implement LWT monitoring

### 5. UI/UX Components
- Voice command button (tap to speak / continuous)
- Current state display (Open/Closed/Opening/Closing/Stopped/Offline)
- Position indicator (percentage)
- Status indicators (connected, listening, processing)
- Command feedback (visual + optional haptic)
- Error messages

## Implementation Phases

### Phase 1: Project Setup (Day 1)
- [ ] Create Flutter app in `app/` directory
- [ ] Configure pubspec.yaml with dependencies
- [ ] Set up basic project structure (lib/, assets/, etc.)
- [ ] Configure MQTT, speech recognition, auth packages
- [ ] Set up app theming and constants

### Phase 2: Voice Recognition (Day 1-2)
- [ ] Implement speech-to-text service
- [ ] Add microphone permission handling
- [ ] Create voice input UI (floating mic button)
- [ ] Build command parser for shutter commands
- [ ] Test voice recognition accuracy
- [ ] Handle platform-specific differences (Android/iOS)

### Phase 3: MQTT Communication (Day 2)
- [ ] Implement MQTT client wrapper
- [ ] Configure TLS connection to broker
- [ ] Subscribe to state/position topics
- [ ] Publish commands
- [ ] Implement connection state management
- [ ] Add reconnection logic

### Phase 4: State Management & Logic (Day 2-3)
- [ ] Create ShutterState model
- [ ] Implement state provider/riverpod/bloc pattern
- [ ] Build position checking logic
- [ ] Implement command validation (e.g., don't close if already closed)
- [ ] Add safety checks
- [ ] Handle edge cases and errors

### Phase 5: UI Integration (Day 3)
- [ ] Build main screen with state display
- [ ] Add voice command UI
- [ ] Create status indicators
- [ ] Implement command confirmation feedback
- [ ] Add settings screen for device config
- [ ] Polish UX

### Phase 6: Testing & Integration (Day 3-4)
- [ ] Test with actual shutter hardware
- [ ] Verify voice commands work correctly
- [ ] Test position-based logic
- [ ] Validate remote operation
- [ ] Test error scenarios (offline, connection loss)
- [ ] Build release APK

## Key Logic: Position-Based Command Handling

```dart
// Example logic
if (command == "open") {
  if (currentState == "CLOSED" || currentPosition < 100) {
    publishCommand("open");
  } else if (currentState == "OPEN" || currentPosition == 100) {
    showFeedback("Shutter already open");
  }
} else if (command == "close") {
  if (currentState == "OPEN" || currentPosition > 0) {
    publishCommand("close");
  } else if (currentState == "CLOSED" || currentPosition == 0) {
    showFeedback("Shutter already closed");
  }
}
```

## Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  mqtt_client: ^10.3.0
  speech_to_text: ^7.0.0
  permission_handler: ^11.3.1
  flutter_riverpod: ^2.5.1
  shared_preferences: ^2.3.2
  firebase_auth: ^5.3.1
  firebase_core: ^3.6.0
  equatable: ^2.0.5
  flutter_tts: ^4.0.2  # optional for audio feedback
```

## Configuration Files
- `lib/config/app_config.dart` - Broker settings, device ID, topics
- `lib/config/secrets.dart` - (git-ignored) credentials
- `.env` approach or secure storage for sensitive data

## Security Considerations
- TLS encryption for all MQTT traffic
- Secure storage for credentials
- User authentication required
- Input validation on voice commands
- No hardcoded secrets

## Testing Checklist
- [ ] Voice recognition in quiet and noisy environments
- [ ] Command accuracy > 90%
- [ ] Correct response to "open" when closed
- [ ] Correct response to "close" when open
- [ ] No action when already at target position
- [ ] Works from remote network (mobile data)
- [ ] Handles broker disconnection gracefully
- [ ] Shows correct position in real-time

## Deliverables
1. Complete Flutter app in `app/` directory
2. Updated `docs/mobile_app.md` with implementation details
3. Working APK for demonstration
4. Test results documented


---

## Implementation Notes

- Flutter SDK is **not installed** on the dev machine used to scaffold this; the Dart
  source was written manually. Run `flutter create .` inside `app/` to generate the
  `android/` and `ios/` platform folders, then `flutter pub get`.
- Files implemented so far are listed in `docs/mobile_app.md`.
- Copy `app/lib/config/secrets.dart.example` → `secrets.dart` (git-ignored) before running.
