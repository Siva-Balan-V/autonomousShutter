import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shutter_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final mqttService = ref.read(mqttServiceProvider);
    final voiceService = ref.read(voiceServiceProvider);
    
    await mqttService.connect();
    await voiceService.initialize();
    
    ref.read(shutterProvider.notifier).updateConnectionStatus();
    
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _toggleVoiceListening() async {
    final voiceService = ref.read(voiceServiceProvider);
    
    if (voiceService.isListening) {
      await voiceService.stopListening();
    } else {
      await voiceService.startListening();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final shutterState = ref.watch(shutterProvider);
    final voiceService = ref.read(voiceServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous Shutter Control'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          shutterState.isConnected && shutterState.isOnline
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: shutterState.isConnected && shutterState.isOnline
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          shutterState.isConnected && shutterState.isOnline
                              ? 'Connected'
                              : 'Disconnected',
                          style: TextStyle(
                            color: shutterState.isConnected && shutterState.isOnline
                                ? Colors.green
                                : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Last Updated: ${shutterState.lastUpdated.toLocal().toString().substring(0, 19)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Shutter State
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Shutter State',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      shutterState.state,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getStateColor(shutterState.state),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Position: ${shutterState.position >= 0 ? "${shutterState.position}%" : "Unknown"}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (shutterState.isMoving) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Voice Command Button
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isInitialized ? _toggleVoiceListening : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: voiceService.isListening ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      voiceService.isListening ? Icons.mic : Icons.mic_none,
                      size: 28,
                    ),
                    label: Text(
                      voiceService.isListening ? 'Listening...' : 'Tap to Speak',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    voiceService.isListening
                        ? 'Say "Open", "Close", or "Stop"'
                        : 'Give voice command',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Manual Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: shutterState.canOpen
                      ? () => ref.read(shutterProvider.notifier).sendManualCommand('open')
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('OPEN'),
                ),
                ElevatedButton(
                  onPressed: shutterState.canStop
                      ? () => ref.read(shutterProvider.notifier).sendManualCommand('stop')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('STOP'),
                ),
                ElevatedButton(
                  onPressed: shutterState.canClose
                      ? () => ref.read(shutterProvider.notifier).sendManualCommand('close')
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('CLOSE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStateColor(String state) {
    switch (state.toUpperCase()) {
      case 'OPEN':
        return Colors.green;
      case 'CLOSED':
        return Colors.blue;
      case 'OPENING':
      case 'CLOSING':
        return Colors.orange;
      case 'STOPPED':
        return Colors.grey;
      case 'FAULT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
