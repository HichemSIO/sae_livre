// Modèle d'Interaction Utilisateur (stocké dans la DB)
class UserInteraction {
  final int? id;
  final int bookId;
  final String actionType; // 'like', 'dislike', 'favorite', 'read', 'view'
  final int? rating; // 1-5
  final DateTime timestamp;

  UserInteraction({
    this.id,
    required this.bookId,
    required this.actionType,
    this.rating,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'action_type': actionType,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory UserInteraction.fromMap(Map<String, dynamic> map) {
    return UserInteraction(
      id: map['id'] as int?,
      bookId: map['book_id'] as int,
      actionType: map['action_type'] as String,
      rating: map['rating'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

// Modèle de Métrique de Performance (stocké dans la DB)
class PerformanceMetric {
  final int? id;
  final String operationType; // 'list_load', 'recommendation', 'detail_view'
  final int durationMs;
  final double? cpuUsage;
  final double? memoryUsage;
  final DateTime timestamp;

  PerformanceMetric({
    this.id,
    required this.operationType,
    required this.durationMs,
    this.cpuUsage,
    this.memoryUsage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation_type': operationType,
      'duration_ms': durationMs,
      'cpu_usage': cpuUsage,
      'memory_usage': memoryUsage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PerformanceMetric.fromMap(Map<String, dynamic> map) {
    return PerformanceMetric(
      id: map['id'] as int?,
      operationType: map['operation_type'] as String,
      durationMs: map['duration_ms'] as int,
      cpuUsage: (map['cpu_usage'] as num?)?.toDouble(),
      memoryUsage: (map['memory_usage'] as num?)?.toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}