import 'package:equatable/equatable.dart';

class ShutterStateModel extends Equatable {
  final String state; // OPEN, CLOSED, OPENING, CLOSING, STOPPED, FAULT
  final int position; // 0-100
  final bool isConnected;
  final bool isOnline;
  final DateTime lastUpdated;
  final String? error;

  const ShutterStateModel({
    required this.state,
    required this.position,
    required this.isConnected,
    required this.isOnline,
    required this.lastUpdated,
    this.error,
  });

  factory ShutterStateModel.initial() {
    return ShutterStateModel(
      state: 'UNKNOWN',
      position: -1,
      isConnected: false,
      isOnline: false,
      lastUpdated: DateTime.now(),
    );
  }

  ShutterStateModel copyWith({
    String? state,
    int? position,
    bool? isConnected,
    bool? isOnline,
    DateTime? lastUpdated,
    String? error,
  }) {
    return ShutterStateModel(
      state: state ?? this.state,
      position: position ?? this.position,
      isConnected: isConnected ?? this.isConnected,
      isOnline: isOnline ?? this.isOnline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error,
    );
  }

  bool get isOpen => state == 'OPEN' || position >= 95;
  bool get isClosed => state == 'CLOSED' || position <= 5;
  bool get isMoving => state == 'OPENING' || state == 'CLOSING';
  bool get canOpen => !isMoving && !isOpen && isOnline && isConnected;
  bool get canClose => !isMoving && !isClosed && isOnline && isConnected;
  bool get canStop => isMoving && isOnline && isConnected;

  @override
  List<Object?> get props => [state, position, isConnected, isOnline, lastUpdated, error];
}
