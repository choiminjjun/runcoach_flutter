// activity_screen.dart: 사용자가 러닝 기록을 입력하거나 Mock Strava/Screenshot OCR에서 데이터를 가져오는 화면입니다.
import 'package:flutter/material.dart';

import '../models/run_activity.dart';
import '../models/import_result.dart';
import '../services/screenshot_ocr_service.dart';
import '../utils/pace_utils.dart';
import '../widgets/page_header.dart';
import '../widgets/mock_strava_card.dart';
import '../widgets/screenshot_ocr_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    super.key,
    required this.onSave,
    required this.onImportMockStrava,
    required this.runs,
    required this.onBack,
  });

  final Future<void> Function(RunActivity run) onSave;
  final Future<ImportResult> Function() onImportMockStrava;
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
  bool _isLoadingStrava = false;
  bool _isLoadingOcr = false;
  String _activeSource = 'manual';

  final _ocrService = ScreenshotOcrService();

  @override
  void dispose() {
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
      stravaActivityId: null,
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

  Future<void> _importStrava() async {
    setState(() => _isLoadingStrava = true);
    try {
      // 인공 딜레이로 실제 통신하는 느낌 제공
      await Future.delayed(const Duration(milliseconds: 800));
      final result = await widget.onImportMockStrava();
      if (!mounted) return;
      _showMessage(
        'Mock Strava 가져오기 성공: 신규 ${result.addedCount}건 추가, 중복 ${result.duplicateCount}건 제외.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Mock Strava 데이터 가져오기 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingStrava = false);
      }
    }
  }

  Future<void> _importOcr() async {
    setState(() => _isLoadingOcr = true);
    try {
      final data = await _ocrService.performOcr();
      if (!mounted) return;

      if (data != null) {
        // OCR 성공 시 입력 폼에 먼저 채워둠 (자동 저장 하지 않음)
        final DateTime dateVal = data['date'] is DateTime
            ? data['date']
            : DateTime.now();
        _dateController.text =
            '${dateVal.year.toString().padLeft(4, '0')}-'
            '${dateVal.month.toString().padLeft(2, '0')}-'
            '${dateVal.day.toString().padLeft(2, '0')}';

        //_distanceController.text = (data['distanceKm'] as double).toStringAsFixed(2);
        final rawDistance = data['distanceKm'];
        if (rawDistance != null) {
          // 어떤 타입이 들어와도 문자열로 만든 후 double로 안전하게 파싱합니다.
          final parsedDistance = double.tryParse(rawDistance.toString()) ?? 0.0;
          _distanceController.text = parsedDistance.toStringAsFixed(
            2,
          ); // 소수점 2자리(6.59) 유지
        } else {
          _distanceController.clear();
        }
        final durationSeconds = data['durationSeconds'] as int;
        final mins = durationSeconds ~/ 60;
        final secs = durationSeconds % 60;
        _minutesController.text = mins.toString();
        _secondsController.text = secs.toString();

        _noteController.text = data['note'] ?? '';

        if (data['calories'] != null) {
          _caloriesController.text = data['calories'].toString();
        } else {
          _caloriesController.clear();
        }

        if (data['elevationGainM'] != null) {
          _elevationController.text = data['elevationGainM'].toString();
        } else {
          _elevationController.clear();
        }

        if (data['averageHeartRate'] != null) {
          _heartRateController.text = data['averageHeartRate'].toString();
        } else {
          _heartRateController.clear();
        }

        if (data['cadence'] != null) {
          _cadenceController.text = data['cadence'].toString();
        } else {
          _cadenceController.clear();
        }

        setState(() {
          _condition = '보통';
          _activeSource = 'screenshot_ocr';
        });

        _showMessage('OCR 데이터 파싱 완료: 수동 입력 폼에 채워졌습니다. 내용을 확인한 뒤 저장해 주세요.');
      } else {
        _showMessage('이미지를 선택하지 않았거나 OCR 분석에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('OCR 연동 중 에러가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingOcr = false);
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
    final stravaCount = widget.runs
        .where((r) => r.source == 'mock_strava')
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 64, 22, 28),
      children: [
        PageHeader(
          title: '활동',
          description:
              '수동으로 오늘의 러닝을 기록하거나 Mock Strava, Screenshot OCR 연동을 시도하세요.',
          icon: Icons.add_circle_outline,
          onBack: widget.onBack,
        ),
        const SizedBox(height: 24),
        MockStravaCard(
          onImport: _importStrava,
          importedCount: stravaCount,
          isLoading: _isLoadingStrava,
        ),
        const SizedBox(height: 16),
        ScreenshotOcrCard(onPickAndParse: _importOcr, isLoading: _isLoadingOcr),
        const SizedBox(height: 24),
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
              Text(
                _activeSource == 'screenshot_ocr'
                    ? '러닝 기록 추가 (OCR 연동 확인)'
                    : '러닝 기록 추가 (수동)',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
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
                  label: Text(
                    _activeSource == 'screenshot_ocr'
                        ? '러닝 기록 확인 후 저장'
                        : '러닝 기록 저장',
                  ),
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

String _todayText() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
