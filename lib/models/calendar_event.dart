/// 캘린더 이벤트 타입
enum CalendarEventType {
  contract,   // 계약
  moving,     // 이사
  exam,       // 시험
  business,   // 사업
  wedding,    // 결혼
  health,     // 건강
  general,    // 일반
}

/// 캘린더 이벤트 모델
class CalendarEvent {
  final String id;
  final DateTime date;
  final String title;
  final String description;
  final CalendarEventType type;
  final bool isReminderSet;
  final DateTime? reminderDate;

  const CalendarEvent({
    String? id,
    required this.date,
    required this.title,
    required this.description,
    required this.type,
    this.isReminderSet = false,
    this.reminderDate,
  }) : id = id ?? '';

  /// OpenAI 분석 결과의 GoodDay에서 CalendarEvent로 변환
  factory CalendarEvent.fromGoodDay(
    String goodDayStr,
    String purpose,
    String reason,
  ) {
    // 날짜 파싱 (YYYY-MM-DD 형식 예상)
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(goodDayStr);
    } catch (e) {
      // 파싱 실패 시 오늘 날짜로 설정
      parsedDate = DateTime.now();
    }

    // 목적에 따른 이벤트 타입 결정
    CalendarEventType eventType = _getEventTypeFromPurpose(purpose);

    return CalendarEvent(
      id: '${parsedDate.millisecondsSinceEpoch}_${purpose.hashCode}',
      date: parsedDate,
      title: purpose,
      description: reason,
      type: eventType,
    );
  }

  /// 목적 문자열을 기반으로 이벤트 타입 결정
  static CalendarEventType _getEventTypeFromPurpose(String purpose) {
    final lowerPurpose = purpose.toLowerCase();
    
    if (lowerPurpose.contains('계약') || lowerPurpose.contains('contract')) {
      return CalendarEventType.contract;
    } else if (lowerPurpose.contains('이사') || lowerPurpose.contains('moving')) {
      return CalendarEventType.moving;
    } else if (lowerPurpose.contains('시험') || lowerPurpose.contains('exam') || lowerPurpose.contains('test')) {
      return CalendarEventType.exam;
    } else if (lowerPurpose.contains('사업') || lowerPurpose.contains('business') || lowerPurpose.contains('창업')) {
      return CalendarEventType.business;
    } else if (lowerPurpose.contains('결혼') || lowerPurpose.contains('wedding') || lowerPurpose.contains('혼인')) {
      return CalendarEventType.wedding;
    } else if (lowerPurpose.contains('건강') || lowerPurpose.contains('health') || lowerPurpose.contains('병원')) {
      return CalendarEventType.health;
    } else {
      return CalendarEventType.general;
    }
  }

  /// 알림 설정이 포함된 새로운 이벤트 생성
  CalendarEvent copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? description,
    CalendarEventType? type,
    bool? isReminderSet,
    DateTime? reminderDate,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isReminderSet: isReminderSet ?? this.isReminderSet,
      reminderDate: reminderDate ?? this.reminderDate,
    );
  }

  /// JSON으로 변환 (Supabase 저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'is_reminder_set': isReminderSet,
      'reminder_date': reminderDate?.toIso8601String(),
    };
  }

  /// JSON에서 생성 (Supabase 불러오기용)
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: CalendarEventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => CalendarEventType.general,
      ),
      isReminderSet: json['is_reminder_set'] ?? false,
      reminderDate: json['reminder_date'] != null 
          ? DateTime.parse(json['reminder_date'])
          : null,
    );
  }

  @override
  String toString() {
    return 'CalendarEvent(id: $id, date: $date, title: $title, type: $type)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ title.hashCode;
} 