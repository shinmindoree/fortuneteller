/// 천간 (天干) - 10개
enum Cheongan {
  gap('갑'),    // 갑 (甲)
  eul('을'),    // 을 (乙)
  byeong('병'), // 병 (丙)
  jeong('정'),  // 정 (丁)
  mu('무'),     // 무 (戊)
  gi('기'),     // 기 (己)
  gyeong('경'), // 경 (庚)
  sin('신'),    // 신 (辛)
  im('임'),     // 임 (壬)
  gye('계');    // 계 (癸)

  const Cheongan(this.name);
  
  final String name;
  
  /// 인덱스로 천간 가져오기 (0-9)
  static Cheongan fromIndex(int index) {
    return Cheongan.values[index % 10];
  }
}

/// 지지 (地支) - 12개
enum Jiji {
  ja('자'),     // 자 (子) - 쥐
  chuk('축'),   // 축 (丑) - 소
  in_('인'),    // 인 (寅) - 호랑이
  myo('묘'),    // 묘 (卯) - 토끼
  jin('진'),    // 진 (辰) - 용
  sa('사'),     // 사 (巳) - 뱀
  o('오'),      // 오 (午) - 말
  mi('미'),     // 미 (未) - 양
  sin('신'),    // 신 (申) - 원숭이
  yu('유'),     // 유 (酉) - 닭
  sul('술'),    // 술 (戌) - 개
  hae('해');    // 해 (亥) - 돼지

  const Jiji(this.name);
  
  final String name;
  
  /// 인덱스로 지지 가져오기 (0-11)
  static Jiji fromIndex(int index) {
    return Jiji.values[index % 12];
  }
}

/// 한 주(柱) - 천간과 지지의 조합
class Ju {
  final Cheongan cheongan;
  final Jiji jiji;
  
  const Ju({
    required this.cheongan,
    required this.jiji,
  });
  
  /// 육십갑자 순서 (0-59)
  int get sexagenary => (cheongan.index * 6 + jiji.index) % 60;
  
  /// 한글 표현
  String get display => '${cheongan.name}${jiji.name}';
  
  /// 육십갑자에서 순서로 Ju 생성
  static Ju fromSexagenary(int order) {
    final normalizedOrder = order % 60;
    final cheonganIndex = normalizedOrder % 10;
    final jijiIndex = normalizedOrder % 12;
    
    return Ju(
      cheongan: Cheongan.fromIndex(cheonganIndex),
      jiji: Jiji.fromIndex(jijiIndex),
    );
  }
  
  @override
  String toString() => display;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ju &&
          runtimeType == other.runtimeType &&
          cheongan == other.cheongan &&
          jiji == other.jiji;

  @override
  int get hashCode => cheongan.hashCode ^ jiji.hashCode;
}

/// 사주 8자 - 년월일시 4주(柱)
class SajuChars {
  final Ju year;   // 년주 (年柱)
  final Ju month;  // 월주 (月柱)
  final Ju day;    // 일주 (日柱)
  final Ju hour;   // 시주 (時柱)
  
  const SajuChars({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
  });
  
  /// 8자 문자열 표현
  String get display => '${year.display} ${month.display} ${day.display} ${hour.display}';
  
  /// 천간만 추출
  List<Cheongan> get cheongans => [year.cheongan, month.cheongan, day.cheongan, hour.cheongan];
  
  /// 지지만 추출
  List<Jiji> get jijis => [year.jiji, month.jiji, day.jiji, hour.jiji];
  
  @override
  String toString() => display;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SajuChars &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day &&
          hour == other.hour;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode ^ hour.hashCode;
} 