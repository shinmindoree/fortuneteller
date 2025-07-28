import 'dart:convert';
import 'saju_chars.dart';
import '../services/openai_service.dart';
import 'calendar_event.dart';

/// 저장된 사주 분석 결과
class SavedAnalysis {
  final String id; // 고유 ID
  final String name;
  final DateTime birthDate;
  final String gender;
  final bool isLunar;
  final SajuChars sajuChars;
  final SajuAnalysisResult analysisResult;
  final List<CalendarEvent> goodDayEvents;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedAnalysis({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.isLunar,
    required this.sajuChars,
    required this.analysisResult,
    required this.goodDayEvents,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 사주 분석 정보로부터 저장용 객체 생성
  factory SavedAnalysis.fromAnalysis({
    required String name,
    required DateTime birthDate,
    required String gender,
    required bool isLunar,
    required SajuChars sajuChars,
    required SajuAnalysisResult analysisResult,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_${name.hashCode}';
    
    // GoodDay를 CalendarEvent로 변환
    final goodDayEvents = analysisResult.goodDays.map((goodDay) {
      return CalendarEvent.fromGoodDay(
        goodDay.date,
        goodDay.purpose,
        goodDay.reason,
      );
    }).toList();

    return SavedAnalysis(
      id: id,
      name: name,
      birthDate: birthDate,
      gender: gender,
      isLunar: isLunar,
      sajuChars: sajuChars,
      analysisResult: analysisResult,
      goodDayEvents: goodDayEvents,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// JSON으로 변환 (저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate.toIso8601String(),
      'gender': gender,
      'is_lunar': isLunar,
      'saju_chars': {
        'year': {
          'cheongan': sajuChars.year.cheongan.index,
          'jiji': sajuChars.year.jiji.index,
        },
        'month': {
          'cheongan': sajuChars.month.cheongan.index,
          'jiji': sajuChars.month.jiji.index,
        },
        'day': {
          'cheongan': sajuChars.day.cheongan.index,
          'jiji': sajuChars.day.jiji.index,
        },
        'hour': {
          'cheongan': sajuChars.hour.cheongan.index,
          'jiji': sajuChars.hour.jiji.index,
        },
      },
      'analysis_result': {
        'personality': analysisResult.personality,
        'fortune': {
          'wealth': analysisResult.fortune.wealth,
          'career': analysisResult.fortune.career,
          'health': analysisResult.fortune.health,
          'love': analysisResult.fortune.love,
        },
        'caution_period': analysisResult.cautionPeriod,
        'good_days': analysisResult.goodDays.map((goodDay) => {
          'date': goodDay.date,
          'purpose': goodDay.purpose,
          'reason': goodDay.reason,
        }).toList(),
        'summary': analysisResult.summary,
      },
      'good_day_events': goodDayEvents.map((event) => event.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// JSON에서 생성 (불러오기용)
  factory SavedAnalysis.fromJson(Map<String, dynamic> json) {
    // 사주 8자 복원
    final sajuData = json['saju_chars'];
    final sajuChars = SajuChars(
      year: Ju(
        cheongan: Cheongan.fromIndex(sajuData['year']['cheongan']),
        jiji: Jiji.fromIndex(sajuData['year']['jiji']),
      ),
      month: Ju(
        cheongan: Cheongan.fromIndex(sajuData['month']['cheongan']),
        jiji: Jiji.fromIndex(sajuData['month']['jiji']),
      ),
      day: Ju(
        cheongan: Cheongan.fromIndex(sajuData['day']['cheongan']),
        jiji: Jiji.fromIndex(sajuData['day']['jiji']),
      ),
      hour: Ju(
        cheongan: Cheongan.fromIndex(sajuData['hour']['cheongan']),
        jiji: Jiji.fromIndex(sajuData['hour']['jiji']),
      ),
    );

    // 분석 결과 복원
    final analysisData = json['analysis_result'];
    final analysisResult = SajuAnalysisResult(
      personality: analysisData['personality'] ?? '',
      fortune: Fortune(
        wealth: analysisData['fortune']['wealth'] ?? '',
        career: analysisData['fortune']['career'] ?? '',
        health: analysisData['fortune']['health'] ?? '',
        love: analysisData['fortune']['love'] ?? '',
      ),
      cautionPeriod: analysisData['caution_period'] ?? '',
      goodDays: (analysisData['good_days'] as List)
          .map((item) => GoodDay(
                date: item['date'] ?? '',
                purpose: item['purpose'] ?? '',
                reason: item['reason'] ?? '',
              ))
          .toList(),
      summary: analysisData['summary'] ?? '',
    );

    // 캘린더 이벤트 복원
    final goodDayEvents = (json['good_day_events'] as List)
        .map((item) => CalendarEvent.fromJson(item))
        .toList();

    return SavedAnalysis(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      birthDate: DateTime.parse(json['birth_date']),
      gender: json['gender'] ?? '',
      isLunar: json['is_lunar'] ?? false,
      sajuChars: sajuChars,
      analysisResult: analysisResult,
      goodDayEvents: goodDayEvents,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// 요약 정보
  String get summary => '${name.isEmpty ? '익명' : name} • ${birthDate.year}년생 ${gender}';
  
  /// 최근 순으로 정렬을 위한 비교
  int compareTo(SavedAnalysis other) {
    return other.updatedAt.compareTo(updatedAt); // 최근 것이 먼저
  }

  @override
  String toString() {
    return 'SavedAnalysis(id: $id, name: $name, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedAnalysis &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
} 