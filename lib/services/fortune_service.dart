import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/fortune_reading.dart';
import '../models/saju_chars.dart';
import '../models/saved_analysis.dart';
import 'storage_service.dart';

/// 운세 생성 서비스
class FortuneService {
  static FortuneService? _instance;
  static FortuneService get instance => _instance ??= FortuneService._();
  
  FortuneService._();

  /// 오늘의 운세 생성
  Future<FortuneReading> getTodayFortune() async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    // 캐시된 오늘 운세가 있는지 확인
    final cached = await _getCachedFortune(FortuneType.daily, todayKey);
    if (cached != null) {
      debugPrint('📖 캐시된 오늘 운세 사용');
      return cached;
    }
    
    debugPrint('🤖 새로운 오늘 운세 생성 중...');
    
    // 저장된 사주 분석 정보 가져오기
    final currentAnalysis = await StorageService.instance.getCurrentAnalysis();
    
    if (currentAnalysis == null) {
      // 사주 정보가 없으면 기본 운세 생성
      return await _generateBasicFortune(FortuneType.daily, today);
    }
    
    // AI로 개인화된 운세 생성
    final fortune = await _generatePersonalizedFortune(
      type: FortuneType.daily,
      date: today,
      analysis: currentAnalysis,
    );
    
    // 캐시에 저장
    await _cacheFortune(fortune, todayKey);
    
    return fortune;
  }

  /// 이주의 운세 생성
  Future<FortuneReading> getWeeklyFortune() async {
    final now = DateTime.now();
    // 이번 주 월요일 찾기
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = '${monday.year}-${monday.month}-${monday.day}-weekly';
    
    final cached = await _getCachedFortune(FortuneType.weekly, weekKey);
    if (cached != null) {
      debugPrint('📖 캐시된 주간 운세 사용');
      return cached;
    }
    
    debugPrint('🤖 새로운 주간 운세 생성 중...');
    
    final currentAnalysis = await StorageService.instance.getCurrentAnalysis();
    
    if (currentAnalysis == null) {
      return await _generateBasicFortune(FortuneType.weekly, monday);
    }
    
    final fortune = await _generatePersonalizedFortune(
      type: FortuneType.weekly,
      date: monday,
      analysis: currentAnalysis,
    );
    
    await _cacheFortune(fortune, weekKey);
    return fortune;
  }

  /// 이달의 운세 생성
  Future<FortuneReading> getMonthlyFortune() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final monthKey = '${now.year}-${now.month}-monthly';
    
    final cached = await _getCachedFortune(FortuneType.monthly, monthKey);
    if (cached != null) {
      debugPrint('📖 캐시된 월간 운세 사용');
      return cached;
    }
    
    debugPrint('🤖 새로운 월간 운세 생성 중...');
    
    final currentAnalysis = await StorageService.instance.getCurrentAnalysis();
    
    if (currentAnalysis == null) {
      return await _generateBasicFortune(FortuneType.monthly, firstDay);
    }
    
    final fortune = await _generatePersonalizedFortune(
      type: FortuneType.monthly,
      date: firstDay,
      analysis: currentAnalysis,
    );
    
    await _cacheFortune(fortune, monthKey);
    return fortune;
  }

  /// AI를 사용한 개인화된 운세 생성
  Future<FortuneReading> _generatePersonalizedFortune({
    required FortuneType type,
    required DateTime date,
    required SavedAnalysis analysis,
  }) async {
    try {
      final prompt = _buildFortunePrompt(type, date, analysis);
      final response = await _callOpenAI(prompt);
      
      if (response == null) {
        throw Exception('AI 응답이 없습니다');
      }
      
      return _parseFortuneResponse(response, type, date);
    } catch (e) {
      debugPrint('❌ 개인화된 운세 생성 실패: $e');
      return await _generateBasicFortune(type, date);
    }
  }

  /// 기본 운세 생성 (사주 정보 없을 때)
  Future<FortuneReading> _generateBasicFortune(FortuneType type, DateTime date) async {
    final random = Random();
    
    // 기본적인 랜덤 운세 데이터
    final scores = FortuneScores(
      wealth: 40 + random.nextInt(40),    // 40-79
      health: 40 + random.nextInt(40),
      love: 40 + random.nextInt(40),
      career: 40 + random.nextInt(40),
      general: 40 + random.nextInt(40),
    );
    
    final titles = {
      FortuneType.daily: ['새로운 하루의 시작', '기회의 날', '조심스러운 하루', '평온한 일상'],
      FortuneType.weekly: ['변화의 주간', '안정된 한 주', '도전의 시기', '성장의 기회'],
      FortuneType.monthly: ['새로운 출발', '발전의 달', '신중한 계획', '풍요로운 시간'],
    };
    
    final luckyItems = ['빨간색', '파란색', '금색', '백색', '꽃', '책', '음악', '따뜻한 차'];
    final recommendations = ['일찍 일어나기', '운동하기', '독서하기', '가족과 시간 보내기', '새로운 것 배우기'];
    final warnings = ['성급한 결정 피하기', '건강 관리 주의', '말조심하기', '과소비 주의'];
    
    return FortuneReading(
      id: '${type.name}_${date.millisecondsSinceEpoch}',
      type: type,
      date: date,
      title: titles[type]![random.nextInt(titles[type]!.length)],
      summary: '오늘은 ${scores.grade}등급의 운세입니다. 차분하게 하루를 보내세요.',
      description: '${type.name == 'daily' ? '오늘' : type.name == 'weekly' ? '이번 주' : '이번 달'}은 전반적으로 안정된 시기입니다. 작은 변화들이 긍정적인 결과를 가져올 수 있으니 새로운 시도를 두려워하지 마세요.',
      scores: scores,
      luckyItems: (luckyItems..shuffle()).take(3).toList(),
      recommendations: (recommendations..shuffle()).take(2).toList(),
      warnings: (warnings..shuffle()).take(1).toList(),
      createdAt: DateTime.now(),
    );
  }

  /// 운세 프롬프트 생성
  String _buildFortunePrompt(FortuneType type, DateTime date, SavedAnalysis analysis) {
    final typeKorean = {
      FortuneType.daily: '일일',
      FortuneType.weekly: '주간', 
      FortuneType.monthly: '월간',
    };
    
    final period = {
      FortuneType.daily: '오늘 (${date.year}년 ${date.month}월 ${date.day}일)',
      FortuneType.weekly: '이번 주 (${date.month}월 ${date.day}일주)',
      FortuneType.monthly: '이번 달 (${date.year}년 ${date.month}월)',
    };

    return '''
당신은 전문적인 사주명리학 운세 전문가입니다. 다음 정보를 바탕으로 ${typeKorean[type]} 운세를 분석해주세요.

**기본 정보:**
- 이름: ${analysis.name}
- 생년월일: ${analysis.birthDate.year}년 ${analysis.birthDate.month}월 ${analysis.birthDate.day}일
- 성별: ${analysis.gender}
- 사주 8자: ${analysis.sajuChars.display}

**운세 기간:** ${period[type]}

**기존 분석 요약:**
${analysis.analysisResult.summary.length > 100 ? analysis.analysisResult.summary.substring(0, 100) + '...' : analysis.analysisResult.summary}

다음 JSON 형식으로 ${typeKorean[type]} 운세를 제공해주세요:

{
  "title": "운세 제목 (15자 이내)",
  "summary": "한줄 요약 (30자 이내)", 
  "description": "상세 운세 설명 (200-300자)",
  "scores": {
    "wealth": 재물운_점수(0-100),
    "health": 건강운_점수(0-100),
    "love": 애정운_점수(0-100),
    "career": 직업운_점수(0-100),
    "general": 종합운_점수(0-100)
  },
  "lucky_items": ["행운의_아이템1", "행운의_아이템2", "행운의_아이템3"],
  "recommendations": ["추천_행동1", "추천_행동2"],
  "warnings": ["주의사항1", "주의사항2"]
}

**요청사항:**
1. 사주 8자와 일간을 기반으로 정확한 분석을 해주세요
2. 점수는 현실적으로 40-95점 사이로 설정해주세요
3. 행운의 아이템은 색상, 방향, 숫자, 소재 등을 포함해주세요
4. 추천 행동은 구체적이고 실천 가능한 것으로 해주세요
5. 주의사항은 건설적이고 도움이 되는 조언으로 해주세요
6. 응답은 반드시 유효한 JSON 형식으로 작성해주세요
''';
  }

  /// OpenAI API 호출
  Future<Map<String, dynamic>?> _callOpenAI(String prompt) async {
    try {
      final endpoint = dotenv.env['AZURE_OPENAI_ENDPOINT'];
      final apiKey = dotenv.env['AZURE_OPENAI_API_KEY'];
      final deploymentName = dotenv.env['AZURE_OPENAI_DEPLOYMENT_NAME'];
      final apiVersion = dotenv.env['AZURE_OPENAI_API_VERSION'];

      if (endpoint == null || apiKey == null || deploymentName == null) {
        debugPrint('❌ OpenAI 환경 변수가 설정되지 않았습니다');
        return null;
      }

      final url = '$endpoint/openai/deployments/$deploymentName/chat/completions?api-version=$apiVersion';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
        },
        body: jsonEncode({
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // JSON 응답 파싱
        try {
          return jsonDecode(content);
        } catch (e) {
          debugPrint('❌ JSON 파싱 실패: $content');
          return null;
        }
      } else {
        debugPrint('❌ OpenAI API 오류: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ OpenAI API 호출 실패: $e');
      return null;
    }
  }

  /// AI 응답을 FortuneReading으로 변환
  FortuneReading _parseFortuneResponse(Map<String, dynamic> response, FortuneType type, DateTime date) {
    try {
      final scores = FortuneScores.fromJson(response['scores'] ?? {});
      
      return FortuneReading(
        id: '${type.name}_${date.millisecondsSinceEpoch}',
        type: type,
        date: date,
        title: response['title'] ?? '운세',
        summary: response['summary'] ?? '',
        description: response['description'] ?? '',
        scores: scores,
        luckyItems: List<String>.from(response['lucky_items'] ?? []),
        recommendations: List<String>.from(response['recommendations'] ?? []),
        warnings: List<String>.from(response['warnings'] ?? []),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ 운세 응답 파싱 실패: $e');
      throw Exception('운세 데이터 파싱 실패');
    }
  }

  /// 캐시된 운세 가져오기
  Future<FortuneReading?> _getCachedFortune(FortuneType type, String key) async {
    try {
      final prefs = await StorageService.instance.preferences;
      final jsonStr = prefs.getString('fortune_cache_$key');
      
      if (jsonStr == null) return null;
      
      final json = jsonDecode(jsonStr);
      return FortuneReading.fromJson(json);
    } catch (e) {
      debugPrint('❌ 캐시된 운세 로드 실패: $e');
      return null;
    }
  }

  /// 운세 캐시에 저장
  Future<void> _cacheFortune(FortuneReading fortune, String key) async {
    try {
      final prefs = await StorageService.instance.preferences;
      final jsonStr = jsonEncode(fortune.toJson());
      await prefs.setString('fortune_cache_$key', jsonStr);
      debugPrint('💾 운세 캐시 저장 완료: $key');
    } catch (e) {
      debugPrint('❌ 운세 캐시 저장 실패: $e');
    }
  }

  /// 운세 히스토리 저장
  Future<bool> saveFortune(FortuneReading fortune) async {
    try {
      final prefs = await StorageService.instance.preferences;
      final existing = prefs.getStringList('fortune_history') ?? [];
      
      // 중복 제거 (같은 타입, 같은 날짜)
      existing.removeWhere((jsonStr) {
        try {
          final json = jsonDecode(jsonStr);
          final existingFortune = FortuneReading.fromJson(json);
          return existingFortune.type == fortune.type && 
                 existingFortune.date.day == fortune.date.day &&
                 existingFortune.date.month == fortune.date.month &&
                 existingFortune.date.year == fortune.date.year;
        } catch (e) {
          return false;
        }
      });
      
      // 새 운세 추가 (최신 순)
      existing.insert(0, jsonEncode(fortune.toJson()));
      
      // 최대 30개 유지
      if (existing.length > 30) {
        existing.removeRange(30, existing.length);
      }
      
      return await prefs.setStringList('fortune_history', existing);
    } catch (e) {
      debugPrint('❌ 운세 히스토리 저장 실패: $e');
      return false;
    }
  }

  /// 운세 히스토리 가져오기
  Future<List<FortuneReading>> getFortuneHistory() async {
    try {
      final prefs = await StorageService.instance.preferences;
      final jsonList = prefs.getStringList('fortune_history') ?? [];
      
      return jsonList
          .map((jsonStr) {
            try {
              final json = jsonDecode(jsonStr);
              return FortuneReading.fromJson(json);
            } catch (e) {
              return null;
            }
          })
          .where((fortune) => fortune != null)
          .cast<FortuneReading>()
          .toList();
    } catch (e) {
      debugPrint('❌ 운세 히스토리 로드 실패: $e');
      return [];
    }
  }
} 