// realtime_run_service.dart: GPS 기반 실시간 러닝 추적과 페이스 알림을 담당합니다.
import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/pace_utils.dart';

class RealtimeRunSnapshot {
  const RealtimeRunSnapshot({
    required this.isRunning,
    required this.startedAt,
    required this.distanceKm,
    required this.elapsedSeconds,
    required this.paceSecondsPerKm,
  });

  final bool isRunning;
  final DateTime? startedAt;
  final double distanceKm;
  final int elapsedSeconds;
  final int paceSecondsPerKm;
}

class RealtimeRunService {
  RealtimeRunService({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const _notificationId = 4201;
  static const _channelId = 'runcoach_realtime_pace';
  static const _channelName = 'RunCoach 실시간 페이스';

  final FlutterLocalNotificationsPlugin _notifications;
  final _snapshotController = StreamController<RealtimeRunSnapshot>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  DateTime? _startedAt;
  Position? _lastPosition;
  double _distanceMeters = 0;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _notificationsReady = false;
  DateTime? _lastNotificationAt;
  int? _targetPaceSeconds;

  Stream<RealtimeRunSnapshot> get snapshots => _snapshotController.stream;

  RealtimeRunSnapshot get currentSnapshot => _snapshot();

  Future<void> start({int? targetPaceSeconds}) async {
    if (_isRunning) {
      return;
    }

    await _ensureNotificationsReady();
    await _ensureLocationPermission();

    _targetPaceSeconds = targetPaceSeconds;
    _startedAt = DateTime.now();
    _lastPosition = null;
    _distanceMeters = 0;
    _elapsedSeconds = 0;
    _isRunning = true;
    _lastNotificationAt = null;

    _emit();
    await _showPaceNotification(force: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _startedAt;
      if (startedAt == null) {
        return;
      }
      _elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
      _emit();
      _showPaceNotification();
    });

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _locationSettings(),
        ).listen(
          _handlePosition,
          onError: (Object error) {
            _stopTrackingOnly();
            _snapshotController.addError(error);
          },
        );
  }

  Future<RealtimeRunSnapshot> stop() async {
    final snapshot = _snapshot();
    await _stopTrackingOnly();
    await _notifications.cancel(id: _notificationId);
    return snapshot;
  }

  Future<void> dispose() async {
    await _stopTrackingOnly();
    await _notifications.cancel(id: _notificationId);
    await _snapshotController.close();
  }

  Future<void> _ensureNotificationsReady() async {
    if (_notificationsReady) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
      ),
    );

    await _notifications.initialize(settings: initializationSettings);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);

    _notificationsReady = true;
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const RealtimeRunException('기기 위치 서비스가 꺼져 있습니다.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const RealtimeRunException('위치 권한이 필요합니다.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const RealtimeRunException('설정에서 위치 권한을 허용해 주세요.');
    }
  }

  LocationSettings _locationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
      );
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        activityType: ActivityType.fitness,
        allowBackgroundLocationUpdates: false,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );
  }

  void _handlePosition(Position position) {
    if (!_isRunning) {
      return;
    }

    if (position.accuracy > 50) {
      return;
    }

    final previous = _lastPosition;
    if (previous == null) {
      _lastPosition = position;
      _emit();
      return;
    }

    final movedMeters = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      position.latitude,
      position.longitude,
    );

    if (movedMeters >= 0.1 && movedMeters <= 100) {
      _distanceMeters += movedMeters;
      _lastPosition = position;
      _emit();
      _showPaceNotification();
    }
  }

  Future<void> _showPaceNotification({bool force = false}) async {
    if (!_isRunning) {
      return;
    }

    final now = DateTime.now();
    if (!force &&
        _lastNotificationAt != null &&
        now.difference(_lastNotificationAt!) < const Duration(seconds: 30)) {
      return;
    }
    _lastNotificationAt = now;

    final snapshot = _snapshot();
    final paceText = formatPace(snapshot.paceSecondsPerKm);
    final distanceText = snapshot.distanceKm.toStringAsFixed(2);

    // 평균 페이스가 목표 페이스보다 빠르거나 느린지 비교 (10초 오차 범위 제공)
    var isDeviating = false;
    final target = _targetPaceSeconds;
    final current = snapshot.paceSecondsPerKm;
    if (target != null && current > 0) {
      // 10초 넘게 페이스 차이가 날 때 소리/진동 알림 트리거
      isDeviating = (current - target).abs() > 10;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: '러닝 중 현재 평균 페이스를 알려줍니다.',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        onlyAlertOnce: !isDeviating, // 페이스가 이탈한 경우에만 소리/진동으로 주의 유도
        playSound: true, // 채널 기본 알림 소리 사용 허용
        autoCancel: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true, // 소리 재생 허용
      ),
    );

    await _notifications.show(
      id: _notificationId,
      title: isDeviating
          ? '⚠️ 페이스 조정 필요! ($paceText)'
          : '현재 페이스 $paceText',
      body: '$distanceText km / ${formatDuration(snapshot.elapsedSeconds)}'
          '${target != null ? ' (목표: ${formatPace(target)})' : ''}',
      notificationDetails: details,
    );
  }

  Future<void> _stopTrackingOnly() async {
    _timer?.cancel();
    _timer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isRunning = false;
    _emit();
  }

  RealtimeRunSnapshot _snapshot() {
    final distanceKm = _distanceMeters / 1000;
    return RealtimeRunSnapshot(
      isRunning: _isRunning,
      startedAt: _startedAt,
      distanceKm: distanceKm,
      elapsedSeconds: _elapsedSeconds,
      paceSecondsPerKm: calculatePaceSeconds(distanceKm, _elapsedSeconds),
    );
  }

  void _emit() {
    if (!_snapshotController.isClosed) {
      _snapshotController.add(_snapshot());
    }
  }
}

class RealtimeRunException implements Exception {
  const RealtimeRunException(this.message);

  final String message;

  @override
  String toString() => message;
}
