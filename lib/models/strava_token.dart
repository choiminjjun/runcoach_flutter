// strava_token.dart: Strava access token, refresh token, 만료 시간을 표현합니다.
class StravaToken {
  const StravaToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresAt;

  bool get isExpired {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt;
  }

  bool get willExpireSoon {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expiresAt - nowSeconds <= 60;
  }

  factory StravaToken.fromJson(Map<String, dynamic> json) {
    return StravaToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: json['expires_at'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt,
    };
  }
}
