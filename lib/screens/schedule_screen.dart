import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/wedding_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final weddingState = ref.watch(weddingProvider);

    // 일정 날짜 매핑 맵 구하기 (시기별 체크리스트 D-day는 결혼식 기준 백계산 처리 가능)
    final DateTime weddingDate = weddingState.coupleInfo?.weddingDate ?? DateTime.now().add(const Duration(days: 180));

    // 예시 일정 매핑 리스트 생성
    final Map<DateTime, List<String>> events = {};
    
    // D-6개월 전 항목 임의 가상 날짜 매핑 (오늘 혹은 예정일 근처)
    _addEvent(events, weddingDate.subtract(const Duration(days: 180)), '베뉴 투어 및 예산 조율');
    _addEvent(events, weddingDate.subtract(const Duration(days: 120)), '스튜디오 촬영 및 예복 맞춤');
    _addEvent(events, weddingDate.subtract(const Duration(days: 60)), '청첩장 및 모바일 영상 제작');
    _addEvent(events, weddingDate.subtract(const Duration(days: 30)), '식전영상 전달 및 드레스 피팅');
    _addEvent(events, weddingDate, '결혼식 본식 Day 💍');

    final selectedEvents = events[DateTime(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
        )] ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: const Text('결혼 일정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              eventLoader: (day) {
                return events[DateTime(day.year, day.month, day.day)] ?? [];
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Color(0xFFFF5271),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFFFFD1D8),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Color(0xFFFF5271),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${_selectedDay!.month}월 ${_selectedDay!.day}일의 일정',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E1E)),
                  ),
                ),
                if (selectedEvents.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('등록된 결혼 일정이 없습니다.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...selectedEvents.map(
                    (event) => Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.favorite, color: Color(0xFFFF5271)),
                        title: Text(
                          event,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _addEvent(Map<DateTime, List<String>> events, DateTime date, String event) {
    final key = DateTime(date.year, date.month, date.day);
    events.putIfAbsent(key, () => []).add(event);
  }
}
