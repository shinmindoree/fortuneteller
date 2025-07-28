import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/openai_service.dart';
import '../services/notification_service.dart';
import '../models/calendar_event.dart';

class CalendarScreen extends StatefulWidget {
  final List<CalendarEvent>? initialEvents;
  
  const CalendarScreen({
    super.key,
    this.initialEvents,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // 길일 데이터 저장
  final Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
    
    // 전달받은 이벤트가 있으면 로드, 없으면 샘플 데이터 로드
    if (widget.initialEvents != null && widget.initialEvents!.isNotEmpty) {
      _loadInitialEvents(widget.initialEvents!);
    } else {
      _loadSampleGoodDays(); // 임시로 샘플 데이터 로드
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _loadSampleGoodDays() {
    // 임시 샘플 데이터 (실제로는 Supabase에서 불러올 예정)
    final today = DateTime.now();
    final sampleEvents = [
      CalendarEvent(
        date: today.add(const Duration(days: 3)),
        title: '계약',
        description: '중요한 계약에 좋은 날입니다.',
        type: CalendarEventType.contract,
      ),
      CalendarEvent(
        date: today.add(const Duration(days: 7)),
        title: '이사',
        description: '새로운 시작에 적합한 길일입니다.',
        type: CalendarEventType.moving,
      ),
      CalendarEvent(
        date: today.add(const Duration(days: 12)),
        title: '시험',
        description: '학업 성취에 도움이 되는 날입니다.',
        type: CalendarEventType.exam,
      ),
      CalendarEvent(
        date: today.add(const Duration(days: 18)),
        title: '사업',
        description: '새로운 사업 시작에 좋은 날입니다.',
        type: CalendarEventType.business,
      ),
      CalendarEvent(
        date: today.add(const Duration(days: 25)),
        title: '결혼',
        description: '인연을 맺기에 좋은 길일입니다.',
        type: CalendarEventType.wedding,
      ),
    ];

    setState(() {
      _events.clear();
      for (final event in sampleEvents) {
        final day = DateTime(event.date.year, event.date.month, event.date.day);
        if (_events[day] != null) {
          _events[day]!.add(event);
        } else {
          _events[day] = [event];
        }
      }
    });

    // 선택된 날의 이벤트 업데이트
    _selectedEvents.value = _getEventsForDay(_selectedDay);
  }

  void _loadInitialEvents(List<CalendarEvent> events) {
    setState(() {
      _events.clear();
      for (final event in events) {
        final day = DateTime(event.date.year, event.date.month, event.date.day);
        if (_events[day] != null) {
          _events[day]!.add(event);
        } else {
          _events[day] = [event];
        }
      }
    });

    // 선택된 날의 이벤트 업데이트
    _selectedEvents.value = _getEventsForDay(_selectedDay);
    
    // 첫 번째 이벤트 날짜로 포커스 이동
    if (events.isNotEmpty) {
      final firstEventDate = events.first.date;
      setState(() {
        _selectedDay = firstEventDate;
        _focusedDay = firstEventDate;
      });
      _selectedEvents.value = _getEventsForDay(_selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('길일 캘린더'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSampleGoodDays,
            tooltip: '새로고침',
          ),
          PopupMenuButton<CalendarFormat>(
            icon: const Icon(Icons.view_module),
            onSelected: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarFormat.month,
                child: Text('월별 보기'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Text('2주 보기'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.week,
                child: Text('주별 보기'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 캘린더 위젯
          Card(
            margin: const EdgeInsets.all(8.0),
            child: TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              locale: 'ko_KR',
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ) ?? const TextStyle(),
                headerPadding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                holidayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                canMarkersOverflow: true,
              ),
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getEventColor(events.first.type),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 8.0),
          
          // 선택된 날짜의 이벤트 목록
          Expanded(
            child: ValueListenableBuilder<List<CalendarEvent>>(
              valueListenable: _selectedEvents,
              builder: (context, events, _) {
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDay),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: events.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '이 날에는 추천 길일이 없습니다',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                final event = events[index];
                                return _buildEventCard(event);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        icon: const Icon(Icons.add_alert),
        label: const Text('알림 추가'),
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getEventColor(event.type),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getEventIcon(event.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          event.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getEventColor(event.type).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getEventTypeName(event.type),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getEventColor(event.type),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showReminderDialog(event),
          tooltip: '알림 설정',
        ),
        onTap: () => _showEventDetails(event),
      ),
    );
  }

  Color _getEventColor(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.contract:
        return Colors.blue;
      case CalendarEventType.moving:
        return Colors.green;
      case CalendarEventType.exam:
        return Colors.orange;
      case CalendarEventType.business:
        return Colors.purple;
      case CalendarEventType.wedding:
        return Colors.pink;
      case CalendarEventType.health:
        return Colors.red;
      case CalendarEventType.general:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.contract:
        return Icons.description;
      case CalendarEventType.moving:
        return Icons.home;
      case CalendarEventType.exam:
        return Icons.school;
      case CalendarEventType.business:
        return Icons.business;
      case CalendarEventType.wedding:
        return Icons.favorite;
      case CalendarEventType.health:
        return Icons.local_hospital;
      case CalendarEventType.general:
        return Icons.event;
    }
  }

  String _getEventTypeName(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.contract:
        return '계약';
      case CalendarEventType.moving:
        return '이사';
      case CalendarEventType.exam:
        return '시험';
      case CalendarEventType.business:
        return '사업';
      case CalendarEventType.wedding:
        return '결혼';
      case CalendarEventType.health:
        return '건강';
      case CalendarEventType.general:
        return '일반';
    }
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('yyyy년 MM월 dd일').format(event.date),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(event.description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getEventColor(event.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getEventIcon(event.type),
                    color: _getEventColor(event.type),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getEventTypeName(event.type),
                    style: TextStyle(
                      color: _getEventColor(event.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showReminderDialog(event);
            },
            child: const Text('알림 설정'),
          ),
        ],
      ),
    );
  }

  void _showReminderDialog(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${event.title}에 대한 알림을 언제 받으시겠습니까?'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('당일 오전 9시'),
              onTap: () {
                Navigator.of(context).pop();
                _scheduleNotification(event, 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('1일 전 오후 6시'),
              onTap: () {
                Navigator.of(context).pop();
                _scheduleNotification(event, 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('1주일 전 오후 6시'),
              onTap: () {
                Navigator.of(context).pop();
                _scheduleNotification(event, 7);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog() {
    if (_selectedEvents.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선택한 날짜에 길일이 없습니다. 다른 날짜를 선택해주세요.'),
        ),
      );
      return;
    }

    final events = _selectedEvents.value;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${DateFormat('MM월 dd일').format(_selectedDay)}의 길일 중 알림을 설정할 항목을 선택하세요:'),
            const SizedBox(height: 16),
            ...events.map((event) => ListTile(
              leading: Icon(
                _getEventIcon(event.type),
                color: _getEventColor(event.type),
              ),
              title: Text(event.title),
              subtitle: Text(event.description),
              onTap: () {
                Navigator.of(context).pop();
                _showReminderDialog(event);
              },
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _scheduleNotification(CalendarEvent event, int daysBefore) async {
    try {
      final success = await NotificationService.instance.scheduleGoodDayNotification(
        event: event,
        daysBefore: daysBefore,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              daysBefore == 0 
                ? '${event.title} 당일 알림이 설정되었습니다'
                : '${event.title} ${daysBefore}일 전 알림이 설정되었습니다',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: '확인',
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {},
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('알림 설정에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: '확인',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('알림 설정 중 오류가 발생했습니다: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
} 