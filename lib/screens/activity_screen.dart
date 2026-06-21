// activity_screen.dart: 사용자가 러닝 기록을 직접 입력하거나 실시간 GPS 기록을 시작하는 화면입니다.
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/run_activity.dart';
import '../services/realtime_run_service.dart';
import '../utils/pace_utils.dart';
import '../utils/recommendation.dart';
import '../widgets/page_header.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    super.key,
    required this.onSave,
    required this.runs,
    required this.onBack,
  });

  final Future<void> Function(RunActivity run) onSave;
  final List<RunActivity> runs;
  final VoidCallback onBack;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _dateController = TextEditingController(text: _todayText());
  final _distanceController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _noteController = TextEditingController();

  // 추가 확장 건강 지표 컨트롤러
  final _caloriesController = TextEditingController();
  final _elevationController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _cadenceController = TextEditingController();

  String _condition = '보통';
  bool _isRealtimeBusy = false;
  String _activeSource = 'manual';

  final _realtimeRunService = RealtimeRunService();
  StreamSubscription<RealtimeRunSnapshot>? _realtimeSubscription;
  RealtimeRunSnapshot _realtimeSnapshot = const RealtimeRunSnapshot(
    isRunning: false,
    startedAt: null,
    distanceKm: 0,
    elapsedSeconds: 0,
    paceSecondsPerKm: 0,
  );

  @override
  void initState() {
    super.initState();
    _realtimeSubscription = _realtimeRunService.snapshots.listen(
      (snapshot) {
        if (mounted) {
          setState(() => _realtimeSnapshot = snapshot);
        }
      },
      onError: (Object error) {
        if (mounted) {
          _showMessage('실시간 러닝 추적 중 오류가 발생했습니다.');
        }
      },
    );
  }

  @override
  void dispose() {
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_realtimeRunService.dispose());
    _dateController.dispose();
    _distanceController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _noteController.dispose();
    _caloriesController.dispose();
    _elevationController.dispose();
    _heartRateController.dispose();
    _cadenceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final dateStr = _dateController.text.trim();
    final distance = double.tryParse(_distanceController.text.trim()) ?? 0;
    final durationSeconds = durationToSeconds(
      _minutesController.text,
      _secondsController.text,
    );

    if (dateStr.isEmpty) {
      _showMessage('날짜를 입력해 주세요.');
      return;
    }
    final runDate = DateTime.tryParse(dateStr);
    if (runDate == null) {
      _showMessage('날짜는 2026-06-16 형식으로 입력해 주세요.');
      return;
    }
    if (distance <= 0) {
      _showMessage('거리 km를 0보다 크게 입력해 주세요.');
      return;
    }
    if (durationSeconds <= 0) {
      _showMessage('러닝 시간을 입력해 주세요.');
      return;
    }

    final calories = int.tryParse(_caloriesController.text.trim());
    final elevation = double.tryParse(_elevationController.text.trim());
    final heartRate = int.tryParse(_heartRateController.text.trim());
    final cadence = int.tryParse(_cadenceController.text.trim());

    final pace = calculatePaceSeconds(distance, durationSeconds);
    final run = RunActivity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      source: _activeSource,
      date: runDate,
      distanceKm: distance,
      durationSeconds: durationSeconds,
      paceSecondsPerKm: pace,
      condition: _condition,
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
      calories: calories,
      elevationGainM: elevation,
      averageHeartRate: heartRate,
      cadence: cadence,
    );

    await widget.onSave(run);
    if (!mounted) return;
    _showMessage('저장 완료: 평균 페이스는 ${formatPace(pace)}입니다.');

    // 저장 후 초기화
    _dateController.text = _todayText();
    _distanceController.clear();
    _minutesController.clear();
    _secondsController.clear();
    _noteController.clear();
    _caloriesController.clear();
    _elevationController.clear();
    _heartRateController.clear();
    _cadenceController.clear();
    setState(() {
      _condition = '보통';
      _activeSource = 'manual';
    });
  }

  Future<void> _toggleRealtimeRun() async {
    if (_isRealtimeBusy) {
      return;
    }

    setState(() => _isRealtimeBusy = true);
    try {
      if (_realtimeSnapshot.isRunning) {
        final snapshot = await _realtimeRunService.stop();
        if (!mounted) return;

        if (snapshot.distanceKm < 0.05 || snapshot.elapsedSeconds < 10) {
          _showMessage('러닝 시간이 너무 짧아 저장하지 않았습니다.');
          return;
        }

        final run = RunActivity(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          source: 'realtime_gps',
          date: snapshot.startedAt ?? DateTime.now(),
          distanceKm: snapshot.distanceKm,
          durationSeconds: snapshot.elapsedSeconds,
          paceSecondsPerKm: snapshot.paceSecondsPerKm,
          condition: 'GPS',
          note: '실시간 러닝 기록',
          createdAt: DateTime.now(),
        );

        await widget.onSave(run);
        if (!mounted) return;
        _showMessage(
          '실시간 러닝 저장 완료: 평균 페이스는 ${formatPace(run.paceSecondsPerKm)}입니다.',
        );
      } else {
        final recommendation = getRecommendation(widget.runs);
        await _realtimeRunService.start(targetPaceSeconds: recommendation.targetPaceSeconds);
        if (!mounted) return;
        _showMessage(
          '실시간 러닝을 시작했습니다. 오늘의 목표 페이스는 ${formatPace(recommendation.targetPaceSeconds)}입니다.',
        );
      }
    } on RealtimeRunException catch (e) {
      if (mounted) {
        _showMessage(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('실시간 러닝을 시작할 수 없습니다. 위치/알림 권한을 확인해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isRealtimeBusy = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 64, 22, 28),
      children: [
        PageHeader(
          title: '활동',
          description: '실시간 페이스를 확인하거나 오늘의 러닝을 직접 기록하세요.',
          icon: Icons.add_circle_outline,
          onBack: widget.onBack,
        ),
        const SizedBox(height: 24),
        _RealtimeRunCard(
          snapshot: _realtimeSnapshot,
          isBusy: _isRealtimeBusy,
          onToggle: _toggleRealtimeRun,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEF0F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '러닝 기록 추가 (수동)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              _LabeledField(
                label: '날짜',
                controller: _dateController,
                hint: '2026-06-16',
              ),
              _LabeledField(
                label: '거리 km',
                controller: _distanceController,
                hint: '5',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: '시간 분',
                      controller: _minutesController,
                      hint: '30',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: '시간 초',
                      controller: _secondsController,
                      hint: '20',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _FieldLabel(text: '컨디션'),
              Row(
                children: ['좋음', '보통', '힘듦'].map((condition) {
                  final active = _condition == condition;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: () => setState(() => _condition = condition),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: active
                              ? const Color(0xFF05E676)
                              : Colors.white,
                          foregroundColor: active
                              ? Colors.black
                              : const Color(0xFF777777),
                          side: BorderSide(
                            color: active
                                ? const Color(0xFF05E676)
                                : const Color(0xFFE1E4E8),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(
                          condition,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              _LabeledField(
                label: '메모',
                controller: _noteController,
                hint: '후반에 조금 힘들었음',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              const Text(
                '피트니스 & 건강 지표 (선택 사항)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: '칼로리 (kcal)',
                      controller: _caloriesController,
                      hint: '450',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: '고도 상승 (m)',
                      controller: _elevationController,
                      hint: '25',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: '평균 심박수 (bpm)',
                      controller: _heartRateController,
                      hint: '155',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: '케이던스 (spm)',
                      controller: _cadenceController,
                      hint: '172',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('러닝 기록 저장'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE1E4E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE1E4E8)),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RealtimeRunCard extends StatelessWidget {
  const _RealtimeRunCard({
    required this.snapshot,
    required this.isBusy,
    required this.onToggle,
  });

  final RealtimeRunSnapshot snapshot;
  final bool isBusy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isRunning = snapshot.isRunning;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isRunning ? const Color(0xFFEFFFF6) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRunning ? const Color(0xFF05E676) : const Color(0xFFEEF0F2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRunning ? Icons.sensors : Icons.location_searching,
                color: isRunning
                    ? const Color(0xFF008A45)
                    : const Color(0xFF555555),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '실시간 페이스 알림',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RealtimeMetric(
                  label: '거리',
                  value: '${snapshot.distanceKm.toStringAsFixed(2)} km',
                ),
              ),
              Expanded(
                child: _RealtimeMetric(
                  label: '시간',
                  value: formatDuration(snapshot.elapsedSeconds),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RealtimeMetric(
            label: '현재 평균 페이스',
            value: formatPace(snapshot.paceSecondsPerKm),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: isBusy ? null : onToggle,
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isRunning ? Icons.stop_circle_outlined : Icons.play_arrow,
                    ),
              label: Text(isRunning ? '러닝 중지 후 저장' : '실시간 러닝 시작'),
              style: FilledButton.styleFrom(
                backgroundColor: isRunning
                    ? const Color(0xFFFF3B30)
                    : const Color(0xFF05E676),
                foregroundColor: isRunning ? Colors.white : Colors.black,
                disabledBackgroundColor: const Color(0xFFD8DDE2),
                disabledForegroundColor: const Color(0xFF777777),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RealtimeMetric extends StatelessWidget {
  const _RealtimeMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

String _todayText() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
