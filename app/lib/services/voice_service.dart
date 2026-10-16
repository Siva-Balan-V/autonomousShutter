import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceCommand {
  final String command; // open, close, stop
  final String rawText;
  final double confidence;
  
  const VoiceCommand({
    required this.command,
    required this.rawText,
    required this.confidence,
  });
}

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  
  final _commandController = StreamController<VoiceCommand>.broadcast();
  Stream<VoiceCommand> get commandStream => _commandController.stream;
  
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  
  Future<bool> initialize() async {
    // Request microphone permission
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      return false;
    }
    
    _isInitialized = await _speechToText.initialize();
    return _isInitialized;
  }
  
  Future<void> startListening() async {
    if (!_isInitialized || _isListening) return;
    
    _isListening = true;
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );
  }
  
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speechToText.stop();
    _isListening = false;
  }
  
  void _onSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.toLowerCase();
    
    if (result.finalResult && text.isNotEmpty) {
      final command = _parseCommand(text);
      if (command != null) {
        _commandController.add(command);
      }
      _isListening = false;
    }
  }
  
  VoiceCommand? _parseCommand(String text) {
    // Check for open keywords
    if (text.contains('open') || text.contains('raise') || text.contains('up')) {
      return VoiceCommand(
        command: 'open',
        rawText: text,
        confidence: 0.9,
      );
    }
    
    // Check for close keywords
    if (text.contains('close') || text.contains('lower') || text.contains('down')) {
      return VoiceCommand(
        command: 'close',
        rawText: text,
        confidence: 0.9,
      );
    }
    
    // Check for stop keywords
    if (text.contains('stop') || text.contains('halt') || text.contains('pause')) {
      return VoiceCommand(
        command: 'stop',
        rawText: text,
        confidence: 0.9,
      );
    }
    
    return null;
  }
  
  void dispose() {
    _commandController.close();
    _speechToText.cancel();
  }
}
