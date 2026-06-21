// run_activity.dart: 수동 입력 기록과 실시간 GPS 기록을 하나로 다루는 모델입니다.

class RunActivity {
  const RunActivity({
    required this.id,
    required this.source,
    required this.date,
    required this.distanceKm,
    required this.durationSeconds,
    required this.paceSecondsPerKm,
    required this.condition,
    required this.note,
    required this.createdAt,
    this.calories,
    this.elevationGainM,
    this.averageHeartRate,
    this.cadence,
  });

  final String id;
  final String source; // 'manual', 'realtime_gps'
  final DateTime date;
  final double distanceKm;
  final int durationSeconds;
  final int paceSecondsPerKm;
  final String condition;
  final String note;
  final DateTime createdAt;

  // 추가 확장 피트니스 지표 (Optional)
  final int? calories;
  final double? elevationGainM;
  final int? averageHeartRate;
  final int? cadence;

  String get dateText {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  factory RunActivity.fromJson(Map<String, dynamic> json) {
    return RunActivity(
      id: json['id'] as String,
      source: json['source'] as String? ?? 'manual',
      date: DateTime.parse(json['date'] as String),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationSeconds: json['durationSeconds'] as int,
      paceSecondsPerKm: json['paceSecondsPerKm'] as int,
      condition: json['condition'] as String? ?? '보통',
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      calories: json['calories'] as int?,
      elevationGainM: (json['elevationGainM'] as num?)?.toDouble(),
      averageHeartRate: json['averageHeartRate'] as int?,
      cadence: json['cadence'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'date': date.toIso8601String(),
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      'paceSecondsPerKm': paceSecondsPerKm,
      'condition': condition,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      if (calories != null) 'calories': calories,
      if (elevationGainM != null) 'elevationGainM': elevationGainM,
      if (averageHeartRate != null) 'averageHeartRate': averageHeartRate,
      if (cadence != null) 'cadence': cadence,
    };
  }

  RunActivity copyWith({
    String? id,
    String? source,
    DateTime? date,
    double? distanceKm,
    int? durationSeconds,
    int? paceSecondsPerKm,
    String? condition,
    String? note,
    DateTime? createdAt,
    int? calories,
    double? elevationGainM,
    int? averageHeartRate,
    int? cadence,
  }) {
    return RunActivity(
      id: id ?? this.id,
      source: source ?? this.source,
      date: date ?? this.date,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      paceSecondsPerKm: paceSecondsPerKm ?? this.paceSecondsPerKm,
      condition: condition ?? this.condition,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      calories: calories ?? this.calories,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      cadence: cadence ?? this.cadence,
    );
  }
}
