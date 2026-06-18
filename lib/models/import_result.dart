// import_result.dart: Strava 기록 가져오기 결과를 표현합니다.
class ImportResult {
  const ImportResult({
    required this.addedCount,
    required this.duplicateCount,
  });

  final int addedCount;
  final int duplicateCount;
}
