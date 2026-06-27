import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../models/wedding_category.dart';

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
    _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final schedules = ref.watch(scheduleProvider);

    final DateTime weddingDate = authState.coupleInfo?.weddingDate ?? DateTime.now().add(const Duration(days: 180));

    // Convert List<CategorySchedule> into Map<DateTime, List<CategorySchedule>>
    final Map<DateTime, List<CategorySchedule>> events = {};
    
    // Add wedding day as a default system event
    final normalizedWeddingDate = DateTime(weddingDate.year, weddingDate.month, weddingDate.day);
    events.putIfAbsent(normalizedWeddingDate, () => []).add(
          CategorySchedule(id: 'system_wedding_day', date: normalizedWeddingDate, title: '결혼식 본식 Day 💍', reminderDays: 0),
        );

    // Map user schedules
    for (var schedule in schedules) {
      final key = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
      events.putIfAbsent(key, () => []).add(schedule);
    }

    final selectedKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final selectedEvents = events[selectedKey] ?? [];

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
                  _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return events[key] ?? [];
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDay!.month}월 ${_selectedDay!.day}일의 일정',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E1E)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFFFF5271), size: 28),
                      onPressed: () => _showAddEventDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                          event.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        trailing: event.id == 'system_wedding_day'
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () {
                                  ref.read(scheduleProvider.notifier).deleteSchedule(event.id);
                                },
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

  void _showAddEventDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('새 일정 추가', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: '일정 제목을 입력하세요 (예: 한복 피팅)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  ref.read(scheduleProvider.notifier).addSchedule(
                        textController.text,
                        _selectedDay!,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('새 일정이 등록되었습니다! 📅')),
                  );
                }
              },
              child: const Text('등록', style: TextStyle(color: Color(0xFFFF5271), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
