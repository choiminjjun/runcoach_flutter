// record_screen.dart: 저장된 러닝 기록을 최신순으로 보여주고 삭제할 수 있습니다.
import 'package:flutter/material.dart';

import '../models/run_activity.dart';
import '../utils/pace_utils.dart';
import '../utils/run_analysis.dart';
import '../widgets/page_header.dart';
import '../widgets/run_card.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    required this.runs,
    required this.onDelete,
    required this.onBack,
  });

  final List<RunActivity> runs;
  final Future<void> Function(String id) onDelete;
  final VoidCallback onBack;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final sortedRuns = sortRuns(widget.runs);
    final initialDate = sortedRuns.isEmpty
        ? DateTime.now()
        : sortedRuns.first.date;
    _visibleMonth = DateTime(initialDate.year, initialDate.month);
    _selectedDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );
  }

  @override
  void didUpdateWidget(covariant RecordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.runs.isEmpty) {
      return;
    }

    final hasSelectedDate = widget.runs.any(
      (run) => _isSameDate(run.date, _selectedDate),
    );
    if (!hasSelectedDate && oldWidget.runs.length != widget.runs.length) {
      final latestRun = sortRuns(widget.runs).first;
      _visibleMonth = DateTime(latestRun.date.year, latestRun.date.month);
      _selectedDate = DateTime(
        latestRun.date.year,
        latestRun.date.month,
        latestRun.date.day,
      );
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    });
  }

  Future<void> _confirmDelete(BuildContext context, RunActivity run) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 러닝 기록을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onDelete(run.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final runsByDate = _groupRunsByDate(widget.runs);
    final selectedRuns = sortRuns(runsByDate[_dateKey(_selectedDate)] ?? []);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 64, 22, 28),
      children: [
        PageHeader(
          title: '기록',
          description: '날짜를 선택해 저장된 러닝 히스토리를 확인하세요.',
          icon: Icons.calendar_month_outlined,
          onBack: widget.onBack,
        ),
        const SizedBox(height: 24),
        _RunCalendar(
          visibleMonth: _visibleMonth,
          selectedDate: _selectedDate,
          runsByDate: runsByDate,
          onPreviousMonth: () => _changeMonth(-1),
          onNextMonth: () => _changeMonth(1),
          onDateSelected: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 18),
        _SelectedDateSection(
          selectedDate: _selectedDate,
          selectedRuns: selectedRuns,
          onDelete: (run) => _confirmDelete(context, run),
        ),
      ],
    );
  }
}

class _RunCalendar extends StatelessWidget {
  const _RunCalendar({
    required this.visibleMonth,
    required this.selectedDate,
    required this.runsByDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final Map<String, List<RunActivity>> runsByDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final weeks = _buildCalendarWeeks(visibleMonth);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF101B20),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF34444D), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left),
                color: const Color(0xFFE8EDF1),
                iconSize: 34,
                tooltip: '이전 달',
              ),
              Expanded(
                child: Text(
                  '${visibleMonth.year}년 ${visibleMonth.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE8EDF1),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right),
                color: const Color(0xFFE8EDF1),
                iconSize: 34,
                tooltip: '다음 달',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              _WeekdayLabel('Su'),
              _WeekdayLabel('Mo'),
              _WeekdayLabel('Tu'),
              _WeekdayLabel('We'),
              _WeekdayLabel('Th'),
              _WeekdayLabel('Fr'),
              _WeekdayLabel('Sa'),
            ],
          ),
          const SizedBox(height: 18),
          ...weeks.map(
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B321F),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  Row(
                    children: week.map((date) {
                      if (date == null) {
                        return const Expanded(child: SizedBox(height: 58));
                      }

                      final hasRuns = runsByDate.containsKey(_dateKey(date));
                      return Expanded(
                        child: _CalendarDayButton(
                          date: date,
                          hasRuns: hasRuns,
                          isSelected: _isSameDate(date, selectedDate),
                          onTap: () => onDateSelected(date),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF65737D),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CalendarDayButton extends StatelessWidget {
  const _CalendarDayButton({
    required this.date,
    required this.hasRuns,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool hasRuns;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${date.year}년 ${date.month}월 ${date.day}일',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 58,
          child: Center(
            child: hasRuns
                ? _RunDayMarker(day: date.day, isSelected: isSelected)
                : Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: isSelected
                        ? BoxDecoration(
                            color: const Color(0xFFFFAD3E),
                            borderRadius: BorderRadius.circular(21),
                          )
                        : null,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF101B20)
                            : const Color(0xFFFFAD3E),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RunDayMarker extends StatelessWidget {
  const _RunDayMarker({required this.day, required this.isSelected});

  final int day;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 58,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 31,
            child: Transform.rotate(
              angle: 0.78,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF5FCFFF),
                  border: Border.all(color: const Color(0xFF77DEFF), width: 3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF20AEEB),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : const Color(0xFF77DEFF),
                width: isSelected ? 4 : 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x5500A6E8),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              '$day',
              style: const TextStyle(
                color: Color(0xFF101B20),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDateSection extends StatelessWidget {
  const _SelectedDateSection({
    required this.selectedDate,
    required this.selectedRuns,
    required this.onDelete,
  });

  final DateTime selectedDate;
  final List<RunActivity> selectedRuns;
  final ValueChanged<RunActivity> onDelete;

  @override
  Widget build(BuildContext context) {
    final totalDistance = selectedRuns.fold<double>(
      0,
      (sum, run) => sum + run.distanceKm,
    );
    final totalDuration = selectedRuns.fold<int>(
      0,
      (sum, run) => sum + run.durationSeconds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF0F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatSelectedDate(selectedDate),
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (selectedRuns.isEmpty)
                const Text(
                  '선택한 날짜에 저장된 러닝 기록이 없습니다.',
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SummaryPill(label: '기록', value: '${selectedRuns.length}개'),
                    _SummaryPill(
                      label: '거리',
                      value: formatDistance(totalDistance),
                    ),
                    _SummaryPill(
                      label: '시간',
                      value: formatDuration(totalDuration),
                    ),
                    _SummaryPill(
                      label: '평균 페이스',
                      value: formatPace(
                        calculatePaceSeconds(totalDistance, totalDuration),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (selectedRuns.isEmpty)
          const SizedBox.shrink()
        else
          ...selectedRuns.map(
            (run) => RunCard(run: run, onDelete: () => onDelete(run)),
          ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EBEF)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF222222),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Map<String, List<RunActivity>> _groupRunsByDate(List<RunActivity> runs) {
  final grouped = <String, List<RunActivity>>{};
  for (final run in runs) {
    grouped.putIfAbsent(_dateKey(run.date), () => []).add(run);
  }
  return grouped;
}

List<List<DateTime?>> _buildCalendarWeeks(DateTime month) {
  final firstDay = DateTime(month.year, month.month);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final firstWeekdayIndex = firstDay.weekday % 7;
  final slots = <DateTime?>[
    for (var i = 0; i < firstWeekdayIndex; i++) null,
    for (var day = 1; day <= daysInMonth; day++)
      DateTime(month.year, month.month, day),
  ];

  while (slots.length % 7 != 0) {
    slots.add(null);
  }

  return [for (var i = 0; i < slots.length; i += 7) slots.sublist(i, i + 7)];
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _formatSelectedDate(DateTime date) {
  const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  return '${date.year}년 ${date.month}월 ${date.day}일 ${weekdays[date.weekday % 7]}요일';
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
