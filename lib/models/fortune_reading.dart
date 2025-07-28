import 'dart:convert';

/// 운세 종류
enum FortuneType {
  daily,   // 일일 운세
  weekly,  // 주간 운세
  monthly, // 월간 운세
}

/// 운세 카테고리별 점수
class FortuneScores {
  final int wealth;    // 재물운 (0-100)
  final int health;    // 건강운 (0-100)
  final int love;      // 애정운 (0-100)
  final int career;    // 직업운 (0-100)
  final int general;   // 종합운 (0-100)

  const FortuneScores({
    required this.wealth,
    required this.health,
    required this.love,
    required this.career,
    required this.general,
  });

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'wealth': wealth,
      'health': health,
      'love': love,
      'career': career,
      'general': general,
    };
  }

  factory FortuneScores.fromJson(Map<String, dynamic> json) {
    return FortuneScores(
      wealth: json['wealth'] ?? 50,
      health: json['health'] ?? 50,
      love: json['love'] ?? 50,
      career: json['career'] ?? 50,
      general: json['general'] ?? 50,
    );
  }

  /// 평균 점수
  double get average => (wealth + health + love + career + general) / 5.0;

  /// 등급 (S/A/B/C/D)
  String get grade {
    if (general >= 90) return 'S';
    if (general >= 80) return 'A';
    if (general >= 70) return 'B';
    if (general >= 60) return 'C';
    return 'D';
  }

  /// 등급별 색상
  String get gradeColor {
    switch (grade) {
      case 'S': return '#FFD700'; // 금색
      case 'A': return '#FF6B6B'; // 빨간색
      case 'B': return '#4ECDC4'; // 청록색
      case 'C': return '#45B7D1'; // 파란색
      case 'D': return '#96CEB4'; // 연두색
      default: return '#95A5A6';  // 회색
    }
  }
}

/// 운세 읽기 결과
class FortuneReading {
  final String id;
  final FortuneType type;
  final DateTime date;        // 운세 날짜 (일일: 해당일, 주간: 월요일, 월간: 1일)
  final String title;         // 운세 제목
  final String summary;       // 한줄 요약
  final String description;   // 상세 설명
  final FortuneScores scores; // 운세 점수들
  final List<String> luckyItems;     // 행운의 아이템/색상
  final List<String> recommendations; // 추천 행동
  final List<String> warnings;       // 주의사항
  final DateTime createdAt;
  final bool isFavorite;      // 즐겨찾기 여부

  const FortuneReading({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    required this.summary,
    required this.description,
    required this.scores,
    required this.luckyItems,
    required this.recommendations,
    required this.warnings,
    required this.createdAt,
    this.isFavorite = false,
  });

  /// 운세 타입별 표시 이름
  String get typeName {
    switch (type) {
      case FortuneType.daily:
        return '오늘의 운세';
      case FortuneType.weekly:
        return '이주의 운세';
      case FortuneType.monthly:
        return '이달의 운세';
    }
  }

  /// 운세 타입별 아이콘
  String get typeIcon {
    switch (type) {
      case FortuneType.daily:
        return '🌅';
      case FortuneType.weekly:
        return '📅';
      case FortuneType.monthly:
        return '🗓️';
    }
  }

  /// 날짜 형식 표시
  String get dateFormatted {
    switch (type) {
      case FortuneType.daily:
        return '${date.month}월 ${date.day}일';
      case FortuneType.weekly:
        final endDate = date.add(const Duration(days: 6));
        return '${date.month}/${date.day} - ${endDate.month}/${endDate.day}';
      case FortuneType.monthly:
        return '${date.year}년 ${date.month}월';
    }
  }

  /// 진행률 계산 (0.0 - 1.0)
  double get progress {
    final now = DateTime.now();
    
    switch (type) {
      case FortuneType.daily:
        // 하루 진행률 (시간 기준)
        final dayStart = DateTime(now.year, now.month, now.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final elapsed = now.difference(dayStart).inMinutes;
        final total = dayEnd.difference(dayStart).inMinutes;
        return (elapsed / total).clamp(0.0, 1.0);
        
      case FortuneType.weekly:
        // 주간 진행률 (월요일 기준)
        final weekStart = date;
        final weekEnd = weekStart.add(const Duration(days: 7));
        final elapsed = now.difference(weekStart).inDays;
        final total = weekEnd.difference(weekStart).inDays;
        return (elapsed / total).clamp(0.0, 1.0);
        
      case FortuneType.monthly:
        // 월간 진행률
        final monthStart = DateTime(date.year, date.month, 1);
        final monthEnd = DateTime(date.year, date.month + 1, 1);
        final elapsed = now.difference(monthStart).inDays;
        final total = monthEnd.difference(monthStart).inDays;
        return (elapsed / total).clamp(0.0, 1.0);
    }
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'date': date.toIso8601String(),
      'title': title,
      'summary': summary,
      'description': description,
      'scores': scores.toJson(),
      'lucky_items': luckyItems,
      'recommendations': recommendations,
      'warnings': warnings,
      'created_at': createdAt.toIso8601String(),
      'is_favorite': isFavorite,
    };
  }

  factory FortuneReading.fromJson(Map<String, dynamic> json) {
    return FortuneReading(
      id: json['id'] ?? '',
      type: FortuneType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FortuneType.daily,
      ),
      date: DateTime.parse(json['date']),
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      description: json['description'] ?? '',
      scores: FortuneScores.fromJson(json['scores'] ?? {}),
      luckyItems: List<String>.from(json['lucky_items'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  /// 즐겨찾기 토글
  FortuneReading toggleFavorite() {
    return FortuneReading(
      id: id,
      type: type,
      date: date,
      title: title,
      summary: summary,
      description: description,
      scores: scores,
      luckyItems: luckyItems,
      recommendations: recommendations,
      warnings: warnings,
      createdAt: createdAt,
      isFavorite: !isFavorite,
    );
  }

  @override
  String toString() {
    return 'FortuneReading(id: $id, type: $type, date: $date, title: $title)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FortuneReading &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
} 