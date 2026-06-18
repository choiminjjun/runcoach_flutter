// strava_config.dart: Strava OAuth와 API 호출에 필요한 설정값을 관리합니다.
class StravaConfig {
  // 주의:
  // 실제 배포 앱에서는 clientSecret을 모바일 앱 내부에 직접 저장하면 안 된다.
  // 실제 서비스에서는 백엔드 서버에서 authorization code를 token으로 교환하는 구조가 권장된다.
  // 이 프로젝트에서는 과제용 MVP 구현을 위해 config 파일에 임시로 작성한다.
  static const String clientId = 'YOUR_STRAVA_CLIENT_ID';
  static const String clientSecret = 'YOUR_STRAVA_CLIENT_SECRET';
  static const String redirectUri = 'runcoach://strava-callback';

  static const String authorizeUrl =
      'https://www.strava.com/oauth/mobile/authorize';
  static const String tokenUrl = 'https://www.strava.com/oauth/token';
  static const String activitiesUrl =
      'https://www.strava.com/api/v3/athlete/activities';

  static const String scope = 'read,activity:read';
}
