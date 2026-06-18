// run_activity.dart: 수동 입력 기록, Mock Strava 가져오기 기록, OCR 인식 기록을 하나로 다루는 모델입니다.
import '../utils/pace_utils.dart';

class RunActivity {
  const RunActivity({
    required this.id,
    required this.stravaActivityId,
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
  final String? stravaActivityId;
  final String source; // 'manual', 'mock_strava', 'screenshot_ocr'
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

  bool get isStrava => source == 'mock_strava';
  bool get isOcr => source == 'screenshot_ocr';

  String get dateText {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  factory RunActivity.fromJson(Map<String, dynamic> json) {
    return RunActivity(
      id: json['id'] as String,
      stravaActivityId: json['stravaActivityId'] as String?,
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
      'stravaActivityId': stravaActivityId,
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

  factory RunActivity.fromMockStravaJson(Map<String, dynamic> json) {
    final stravaId = json['id']?.toString() ?? '';
    final meters = (json['distance'] as num? ?? 0).toDouble();
    final distanceKm = meters / 1000.0;
    final durationSeconds = json['moving_time'] as int? ?? json['elapsed_time'] as int? ?? 0;
    final dateStr = json['start_date_local'] as String? ?? json['start_date'] as String? ?? DateTime.now().toIso8601String();
    
    return RunActivity(
      id: 'strava-$stravaId',
      stravaActivityId: stravaId,
      source: 'mock_strava',
      date: DateTime.parse(dateStr),
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      paceSecondsPerKm: calculatePaceSeconds(distanceKm, durationSeconds),
      condition: 'Strava',
      note: json['name'] as String? ?? 'Strava Run',
      createdAt: DateTime.now(),
      calories: json['calories'] as int?,
      elevationGainM: (json['total_elevation_gain'] as num?)?.toDouble(),
      averageHeartRate: json['average_heartrate'] as int?,
      cadence: json['average_cadence'] as int?,
    );
  }

  factory RunActivity.fromOcrParsedData(Map<String, dynamic> data) {
    final distanceKm = (data['distanceKm'] as num? ?? 0).toDouble();
    final durationSeconds = data['durationSeconds'] as int? ?? 0;
    
    DateTime parsedDate;
    if (data['date'] is DateTime) {
      parsedDate = data['date'] as DateTime;
    } else if (data['date'] is String) {
      parsedDate = DateTime.tryParse(data['date'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return RunActivity(
      id: 'ocr-${DateTime.now().microsecondsSinceEpoch}',
      stravaActivityId: null,
      source: 'screenshot_ocr',
      date: parsedDate,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      paceSecondsPerKm: data['paceSecondsPerKm'] as int? ?? calculatePaceSeconds(distanceKm, durationSeconds),
      condition: data['condition']?.toString() ?? '보통',
      note: data['note']?.toString() ?? 'Screenshot OCR Run',
      createdAt: DateTime.now(),
      calories: data['calories'] as int?,
      elevationGainM: (data['elevationGainM'] as num?)?.toDouble(),
      averageHeartRate: data['averageHeartRate'] as int?,
      cadence: data['cadence'] as int?,
    );
  }

  RunActivity copyWith({
    String? id,
    String? stravaActivityId,
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
      stravaActivityId: stravaActivityId ?? this.stravaActivityId,
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
