// pace_utils.dart: 시간, 거리, 페이스 계산과 표시 형식을 담당합니다.
int durationToSeconds(String minutesText, String secondsText) {
  final minutes = int.tryParse(minutesText.trim()) ?? 0;
  final seconds = int.tryParse(secondsText.trim()) ?? 0;
  return (minutes * 60 + seconds).clamp(0, 24 * 60 * 60);
}

int calculatePaceSeconds(double distanceKm, int durationSeconds) {
  if (distanceKm <= 0 || durationSeconds <= 0) {
    return 0;
  }
  return (durationSeconds / distanceKm).round();
}

String formatPace(int paceSecondsPerKm) {
  if (paceSecondsPerKm <= 0) {
    return '-\'--"/km';
  }
  final minutes = paceSecondsPerKm ~/ 60;
  final seconds = paceSecondsPerKm % 60;
  return '$minutes\'${seconds.toString().padLeft(2, '0')}"/km';
}

String formatDuration(int totalSeconds) {
  if (totalSeconds <= 0) {
    return '0분 00초';
  }
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours시간 $minutes분 ${seconds.toString().padLeft(2, '0')}초';
  }
  return '$minutes분 ${seconds.toString().padLeft(2, '0')}초';
}

String formatDistance(double distanceKm) {
  return '${distanceKm.toStringAsFixed(1)}km';
}
