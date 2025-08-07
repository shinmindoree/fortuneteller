import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/saju_chars.dart';

/// Azure OpenAI를 활용한 사주 분석 서비스
class OpenAIService {
  static const OpenAIService _instance = OpenAIService._();
  static OpenAIService get instance => _instance;
  
  const OpenAIService._();
  
  /// Azure OpenAI 설정 정보
  String? get _endpoint => dotenv.env['AZURE_OPENAI_ENDPOINT'];
  String? get _apiKey => dotenv.env['AZURE_OPENAI_API_KEY'];
  String? get _deploymentName => dotenv.env['AZURE_OPENAI_DEPLOYMENT_NAME'];
  String? get _apiVersion => dotenv.env['AZURE_OPENAI_API_VERSION'];
  
  /// 설정 확인
  bool get isConfigured => 
      _endpoint != null && 
      _apiKey != null && 
      _deploymentName != null && 
      _apiVersion != null;
  
  /// 일반적인 AI 응답 생성
  Future<String> generateResponse(String prompt) async {
    if (!isConfigured) {
      throw Exception('Azure OpenAI 설정이 완료되지 않았습니다.');
    }
    
    try {
      final response = await _callOpenAI(prompt);
      return response;
    } catch (e) {
      throw Exception('AI 응답 생성 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 사주 분석 요청
  Future<SajuAnalysisResult> analyzeSaju({
    required SajuChars sajuChars,
    required String name,
    required DateTime birthDate,
    required String gender,
    required bool isLunar,
  }) async {
    if (!isConfigured) {
      throw Exception('Azure OpenAI 설정이 완료되지 않았습니다.');
    }
    
    try {
      final prompt = _buildSajuPrompt(
        sajuChars: sajuChars,
        name: name,
        birthDate: birthDate,
        gender: gender,
        isLunar: isLunar,
      );
      
      final response = await _callOpenAI(prompt);
      return SajuAnalysisResult.fromOpenAIResponse(response);
      
    } catch (e) {
      throw Exception('사주 분석 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 사주 분석을 위한 프롬프트 생성
  String _buildSajuPrompt({
    required SajuChars sajuChars,
    required String name,
    required DateTime birthDate,
    required String gender,
    required bool isLunar,
  }) {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: 90)); // 3개월 후
    
    return '''
당신은 전문적인 사주명리학 전문가입니다. 다음 사주 정보를 바탕으로 상세하고 정확한 분석을 해주세요.

**현재 날짜 정보:**
- 오늘 날짜: ${now.year}년 ${now.month}월 ${now.day}일
- 분석 기간: ${now.year}년 ${now.month}월 ${now.day}일부터 ${futureDate.year}년 ${futureDate.month}월 ${futureDate.day}일까지 (향후 3개월)

**기본 정보:**
- 이름: $name
- 생년월일: ${birthDate.year}년 ${birthDate.month}월 ${birthDate.day}일 (${isLunar ? '음력' : '양력'})
- 성별: $gender

**사주 8자:**
- 년주: ${sajuChars.year.display} (${sajuChars.year.cheongan.name}${sajuChars.year.jiji.name})
- 월주: ${sajuChars.month.display} (${sajuChars.month.cheongan.name}${sajuChars.month.jiji.name})
- 일주: ${sajuChars.day.display} (${sajuChars.day.cheongan.name}${sajuChars.day.jiji.name})
- 시주: ${sajuChars.hour.display} (${sajuChars.hour.cheongan.name}${sajuChars.hour.jiji.name})

**일간(日干): ${sajuChars.day.cheongan.name}**

다음 형식으로 분석 결과를 JSON 형태로 제공해주세요:

{
  "personality": "성격 및 기질 분석 (200자 내외)",
  "fortune": {
    "wealth": "재물운 분석 및 조언 (150자 내외)",
    "career": "직업운 및 진로 조언 (150자 내외)",
    "health": "건강운 및 주의사항 (150자 내외)",
    "love": "애정운 및 인간관계 (150자 내외)"
  },
  "caution_period": "주의해야 할 시기 및 이유 (100자 내외)",
  "good_days": [
    {
      "date": "${now.year}-XX-XX",
      "purpose": "이사/계약/시험/결혼 등",
      "reason": "추천 이유 (50자 내외)"
    }
  ],
  "summary": "전체적인 운세 요약 (300자 내외)"
}

**요청사항:**
1. 전통 사주명리학 원리에 따라 정확하게 분석해주세요
2. 구체적이고 실용적인 조언을 포함해주세요
3. **중요**: ${now.year}년 ${now.month}월 ${now.day}일부터 ${futureDate.year}년 ${futureDate.month}월 ${futureDate.day}일까지의 길일을 5개 이상 추천해주세요
4. 추천 날짜는 반드시 ${now.year}년 이후의 미래 날짜여야 합니다
5. 부정적인 내용도 건설적으로 표현해주세요
6. 응답은 반드시 유효한 JSON 형식으로 작성해주세요
''';
  }
  
  /// Azure OpenAI API 호출
  Future<String> _callOpenAI(String prompt) async {
    final url = Uri.parse(
      '$_endpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion'
    );
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'api-key': _apiKey!,
      },
      body: jsonEncode({
        'messages': [
          {
            'role': 'system',
            'content': '당신은 수십 년의 경험을 가진 전문 사주명리학자입니다. 정확하고 상세한 사주 분석을 제공합니다.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'max_tokens': 2000,
        'temperature': 0.7,
        'top_p': 0.95,
        'frequency_penalty': 0.2,
        'presence_penalty': 0.1,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return content;
    } else {
      throw Exception('OpenAI API 호출 실패: ${response.statusCode} - ${response.body}');
    }
  }
}

/// 사주 분석 결과 모델
class SajuAnalysisResult {
  final String personality;
  final Fortune fortune;
  final String cautionPeriod;
  final List<GoodDay> goodDays;
  final String summary;
  
  const SajuAnalysisResult({
    required this.personality,
    required this.fortune,
    required this.cautionPeriod,
    required this.goodDays,
    required this.summary,
  });
  
  factory SajuAnalysisResult.fromOpenAIResponse(String response) {
    try {
      // JSON 추출 (```json 태그가 있을 수 있음)
      String jsonStr = response;
      if (response.contains('```json')) {
        final start = response.indexOf('```json') + 7;
        final end = response.lastIndexOf('```');
        if (end > start) {
          jsonStr = response.substring(start, end);
        }
      }
      
      final data = jsonDecode(jsonStr);
      
      return SajuAnalysisResult(
        personality: data['personality'] ?? '분석 결과를 가져올 수 없습니다.',
        fortune: Fortune.fromJson(data['fortune'] ?? {}),
        cautionPeriod: data['caution_period'] ?? '특별한 주의사항이 없습니다.',
        goodDays: (data['good_days'] as List?)
            ?.map((item) => GoodDay.fromJson(item))
            .toList() ?? [],
        summary: data['summary'] ?? '분석을 완료했습니다.',
      );
    } catch (e) {
      // JSON 파싱 실패 시 기본값 반환
      return SajuAnalysisResult(
        personality: '분석 중 오류가 발생했습니다: $e',
        fortune: const Fortune(
          wealth: '분석 결과를 가져올 수 없습니다.',
          career: '분석 결과를 가져올 수 없습니다.',
          health: '분석 결과를 가져올 수 없습니다.',
          love: '분석 결과를 가져올 수 없습니다.',
        ),
        cautionPeriod: '분석 중 오류가 발생했습니다.',
        goodDays: [],
        summary: '응답: $response',
      );
    }
  }
}

/// 운세 정보
class Fortune {
  final String wealth;   // 재물운
  final String career;   // 직업운
  final String health;   // 건강운
  final String love;     // 애정운
  
  const Fortune({
    required this.wealth,
    required this.career,
    required this.health,
    required this.love,
  });
  
  factory Fortune.fromJson(Map<String, dynamic> json) {
    return Fortune(
      wealth: json['wealth'] ?? '정보 없음',
      career: json['career'] ?? '정보 없음',
      health: json['health'] ?? '정보 없음',
      love: json['love'] ?? '정보 없음',
    );
  }
}

/// 길일 정보
class GoodDay {
  final String date;     // 날짜
  final String purpose;  // 목적
  final String reason;   // 이유
  
  const GoodDay({
    required this.date,
    required this.purpose,
    required this.reason,
  });
  
  factory GoodDay.fromJson(Map<String, dynamic> json) {
    return GoodDay(
      date: json['date'] ?? '',
      purpose: json['purpose'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
} 