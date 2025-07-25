import '../models/saju_chars.dart';

/// 사주 8자 계산 서비스
class SajuCalculator {
  static const SajuCalculator _instance = SajuCalculator._();
  static SajuCalculator get instance => _instance;
  
  const SajuCalculator._();
  
  /// 메인 계산 함수 - 생년월일시를 사주 8자로 변환
  SajuChars calculateSaju({
    required DateTime birthDate,
    required int hour,
    required int minute,
    required bool isLunar,
    required String gender,
  }) {
    // 음력인 경우 양력으로 변환 (간단한 근사치 사용, 추후 정확한 변환 라이브러리 적용 가능)
    final adjustedDate = isLunar ? _approximateLunarToSolar(birthDate) : birthDate;
    
    final year = _calculateYearJu(adjustedDate.year);
    final month = _calculateMonthJu(adjustedDate.year, adjustedDate.month);
    final day = _calculateDayJu(adjustedDate);
    final hourJu = _calculateHourJu(day, hour);
    
    return SajuChars(
      year: year,
      month: month,
      day: day,
      hour: hourJu,
    );
  }
  
  /// 년주 계산 (입춘 기준)
  Ju _calculateYearJu(int year) {
    // 서기 4년이 갑자(甲子)년이므로, 이를 기준으로 계산
    // 입춘(2월 4일경) 기준으로 년도가 바뀜 (간단히 년도만 사용)
    final yearIndex = (year - 4) % 60;
    return Ju.fromSexagenary(yearIndex);
  }
  
  /// 월주 계산 (절기 기준)
  Ju _calculateMonthJu(int year, int month) {
    // 월주는 년간에 따라 결정됨
    final yearJu = _calculateYearJu(year);
    final yearCheonganIndex = yearJu.cheongan.index;
    
    // 월주 천간 계산 공식: (년간 × 2 + 월수) % 10
    // 1월은 인월(寅月)부터 시작 (월수 조정)
    final adjustedMonth = month + 1; // 1월=인월=2, 2월=묘월=3, ...
    final monthCheonganIndex = (yearCheonganIndex * 2 + adjustedMonth) % 10;
    
    // 월지는 고정: 1월=인(2), 2월=묘(3), ..., 12월=축(1)
    final monthJijiIndex = (month + 1) % 12;
    
    return Ju(
      cheongan: Cheongan.fromIndex(monthCheonganIndex),
      jiji: Jiji.fromIndex(monthJijiIndex),
    );
  }
  
  /// 일주 계산 (율리우스력 기준)
  Ju _calculateDayJu(DateTime date) {
    // 기준일: 서기 1년 1월 1일을 갑자일로 가정
    // 실제로는 더 정확한 기준일이 필요하지만, 간단한 계산을 위해 근사치 사용
    
    // 율리우스 일수 계산
    final julianDay = _calculateJulianDay(date);
    
    // 갑자일을 기준으로 일주 계산
    // 기준 율리우스 일수에서의 갑자일 조정
    final dayIndex = (julianDay - 1721426) % 60; // 조정된 기준일
    
    return Ju.fromSexagenary(dayIndex);
  }
  
  /// 시주 계산
  Ju _calculateHourJu(Ju dayJu, int hour) {
    // 시주 천간은 일간에 따라 결정됨
    final dayCheonganIndex = dayJu.cheongan.index;
    
    // 시간대별 지지 매핑 (자시=23-1시, 축시=1-3시, ...)
    final hourJijiIndex = _getHourJijiIndex(hour);
    
    // 시주 천간 계산 공식: (일간 × 2 + 시지) % 10
    final hourCheonganIndex = (dayCheonganIndex * 2 + hourJijiIndex) % 10;
    
    return Ju(
      cheongan: Cheongan.fromIndex(hourCheonganIndex),
      jiji: Jiji.fromIndex(hourJijiIndex),
    );
  }
  
  /// 시간을 지지 인덱스로 변환
  int _getHourJijiIndex(int hour) {
    // 자시: 23-1시 (0), 축시: 1-3시 (1), 인시: 3-5시 (2), ...
    if (hour >= 23 || hour < 1) return 0;  // 자시
    if (hour < 3) return 1;   // 축시
    if (hour < 5) return 2;   // 인시
    if (hour < 7) return 3;   // 묘시
    if (hour < 9) return 4;   // 진시
    if (hour < 11) return 5;  // 사시
    if (hour < 13) return 6;  // 오시
    if (hour < 15) return 7;  // 미시
    if (hour < 17) return 8;  // 신시
    if (hour < 19) return 9;  // 유시
    if (hour < 21) return 10; // 술시
    return 11; // 해시 (21-23시)
  }
  
  /// 율리우스 일수 계산 (그레고리력)
  int _calculateJulianDay(DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;
    
    int a = (14 - month) ~/ 12;
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;
    
    int julianDay = day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
    
    return julianDay;
  }
  
  /// 음력을 양력으로 근사 변환 (간단한 방법)
  /// 실제 프로덕션에서는 정확한 음력 변환 라이브러리 사용 권장
  DateTime _approximateLunarToSolar(DateTime lunarDate) {
    // 음력과 양력의 평균 차이는 약 20-50일 정도
    // 간단한 근사치로 30일을 더해줌 (정확하지 않음)
    return lunarDate.add(const Duration(days: 30));
  }
  
  /// 사주 해석을 위한 추가 정보
  SajuAnalysis analyzeSaju(SajuChars saju) {
    return SajuAnalysis(
      chars: saju,
      description: _generateBasicDescription(saju),
    );
  }
  
  /// 기본적인 사주 설명 생성
  String _generateBasicDescription(SajuChars saju) {
    final yearDesc = '년주: ${saju.year.display}';
    final monthDesc = '월주: ${saju.month.display}';
    final dayDesc = '일주: ${saju.day.display}';
    final hourDesc = '시주: ${saju.hour.display}';
    
    return '$yearDesc\n$monthDesc\n$dayDesc\n$hourDesc\n\n'
           '일간(日干): ${saju.day.cheongan.name}\n'
           '이 사주의 중심이 되는 천간입니다.';
  }
}

/// 사주 분석 결과
class SajuAnalysis {
  final SajuChars chars;
  final String description;
  
  const SajuAnalysis({
    required this.chars,
    required this.description,
  });
} 