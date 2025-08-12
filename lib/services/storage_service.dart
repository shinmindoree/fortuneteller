import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_analysis.dart';
import '../models/calendar_event.dart';

/// 로컬 데이터 저장 서비스
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();
  
  static const String _keyAnalysisList = 'saved_analysis_list';
  static const String _keyCurrentAnalysis = 'current_analysis';
  static const String _keyGoodDayEvents = 'good_day_events';
  static const String _keySajuProfile = 'user_saju_profile';
  
  SharedPreferences? _prefs;
  
  /// 초기화
  Future<void> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      debugPrint('📁 로컬 저장소 초기화 완료');
    } catch (e) {
      debugPrint('❌ 로컬 저장소 초기화 실패: $e');
    }
  }
  
  /// SharedPreferences 인스턴스 확인
  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }
  
  /// 외부에서 SharedPreferences 접근용 (FortuneService에서 사용)
  Future<SharedPreferences> get preferences => _preferences;

  // --------------------
  // 사주 프로필 저장/로드/삭제
  // --------------------
  Future<bool> saveSajuProfile({
    required String name,
    required DateTime birthDate,
    required int hour,
    required int minute,
    required String gender,
    required bool isLunar,
  }) async {
    try {
      final prefs = await _preferences;
      final profile = {
        'name': name,
        'birthDate': birthDate.toIso8601String(),
        'hour': hour,
        'minute': minute,
        'gender': gender,
        'isLunar': isLunar,
      };
      final success = await prefs.setString(_keySajuProfile, jsonEncode(profile));
      debugPrint(success ? '💾 사주 프로필 저장 완료' : '❌ 사주 프로필 저장 실패');
      return success;
    } catch (e) {
      debugPrint('❌ 사주 프로필 저장 중 오류: $e');
      return false;
    }
  }

  // Map을 받는 오버로드 메서드
  Future<bool> saveSajuProfileMap(Map<String, dynamic> profileData) async {
    try {
      final prefs = await _preferences;
      final success = await prefs.setString(_keySajuProfile, jsonEncode(profileData));
      debugPrint(success ? '💾 사주 프로필 저장 완료' : '❌ 사주 프로필 저장 실패');
      return success;
    } catch (e) {
      debugPrint('❌ 사주 프로필 저장 중 오류: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSajuProfile() async {
    try {
      final prefs = await _preferences;
      final jsonStr = prefs.getString(_keySajuProfile);
      if (jsonStr == null) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map;
    } catch (e) {
      debugPrint('❌ 사주 프로필 로드 실패: $e');
      return null;
    }
  }

  Future<bool> deleteSajuProfile() async {
    try {
      final prefs = await _preferences;
      final success = await prefs.remove(_keySajuProfile);
      debugPrint(success ? '🗑️ 사주 프로필 삭제 완료' : '❌ 사주 프로필 삭제 실패');
      return success;
    } catch (e) {
      debugPrint('❌ 사주 프로필 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// 사주 분석 결과 저장
  Future<bool> saveAnalysis(SavedAnalysis analysis) async {
    try {
      final prefs = await _preferences;
      
      // 기존 분석 목록 가져오기
      final existingList = await getSavedAnalysisList();
      
      // 같은 ID가 있으면 업데이트, 없으면 추가
      final index = existingList.indexWhere((item) => item.id == analysis.id);
      if (index >= 0) {
        existingList[index] = analysis;
        debugPrint('📝 기존 분석 결과 업데이트: ${analysis.id}');
      } else {
        existingList.insert(0, analysis); // 최신 것을 맨 앞에
        debugPrint('💾 새로운 분석 결과 저장: ${analysis.id}');
      }
      
      // 최대 10개까지만 보관 (용량 관리)
      if (existingList.length > 10) {
        existingList.removeRange(10, existingList.length);
      }
      
      // JSON 문자열 목록으로 변환
      final jsonList = existingList.map((item) => jsonEncode(item.toJson())).toList();
      
      // 저장
      final success = await prefs.setStringList(_keyAnalysisList, jsonList);
      
      // 현재 분석으로도 설정
      if (success) {
        await _setCurrentAnalysis(analysis);
      }
      
      debugPrint(success ? '✅ 분석 결과 저장 완료' : '❌ 분석 결과 저장 실패');
      return success;
    } catch (e) {
      debugPrint('❌ 분석 결과 저장 중 오류: $e');
      return false;
    }
  }
  
  /// 저장된 분석 목록 가져오기
  Future<List<SavedAnalysis>> getSavedAnalysisList() async {
    try {
      final prefs = await _preferences;
      final jsonList = prefs.getStringList(_keyAnalysisList) ?? [];
      
      final analysisList = jsonList
          .map((jsonStr) {
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              return SavedAnalysis.fromJson(json);
            } catch (e) {
              debugPrint('⚠️ 저장된 분석 데이터 파싱 실패: $e');
              return null;
            }
          })
          .where((analysis) => analysis != null)
          .cast<SavedAnalysis>()
          .toList();
      
      // 최근 순으로 정렬
      analysisList.sort((a, b) => a.compareTo(b));
      
      debugPrint('📂 저장된 분석 ${analysisList.length}개 로드 완료');
      return analysisList;
    } catch (e) {
      debugPrint('❌ 저장된 분석 목록 로드 실패: $e');
      return [];
    }
  }
  
  /// 현재 활성 분석 설정
  Future<bool> _setCurrentAnalysis(SavedAnalysis analysis) async {
    try {
      final prefs = await _preferences;
      final jsonStr = jsonEncode(analysis.toJson());
      return await prefs.setString(_keyCurrentAnalysis, jsonStr);
    } catch (e) {
      debugPrint('❌ 현재 분석 설정 실패: $e');
      return false;
    }
  }
  
  /// 현재 활성 분석 가져오기
  Future<SavedAnalysis?> getCurrentAnalysis() async {
    try {
      final prefs = await _preferences;
      final jsonStr = prefs.getString(_keyCurrentAnalysis);
      
      if (jsonStr == null) return null;
      
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final analysis = SavedAnalysis.fromJson(json);
      
      debugPrint('📖 현재 활성 분석 로드: ${analysis.summary}');
      return analysis;
    } catch (e) {
      debugPrint('❌ 현재 활성 분석 로드 실패: $e');
      return null;
    }
  }
  
  /// 분석 결과 삭제
  Future<bool> deleteAnalysis(String analysisId) async {
    try {
      final existingList = await getSavedAnalysisList();
      final updatedList = existingList.where((item) => item.id != analysisId).toList();
      
      final prefs = await _preferences;
      final jsonList = updatedList.map((item) => jsonEncode(item.toJson())).toList();
      
      final success = await prefs.setStringList(_keyAnalysisList, jsonList);
      
      // 삭제된 것이 현재 활성 분석이었다면 해제
      final currentAnalysis = await getCurrentAnalysis();
      if (currentAnalysis?.id == analysisId) {
        await prefs.remove(_keyCurrentAnalysis);
      }
      
      debugPrint(success ? '🗑️ 분석 결과 삭제 완료: $analysisId' : '❌ 분석 결과 삭제 실패');
      return success;
    } catch (e) {
      debugPrint('❌ 분석 결과 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// 길일 이벤트 저장
  Future<bool> saveGoodDayEvents(List<CalendarEvent> events) async {
    try {
      final prefs = await _preferences;
      final jsonList = events.map((event) => jsonEncode(event.toJson())).toList();
      
      final success = await prefs.setStringList(_keyGoodDayEvents, jsonList);
      debugPrint(success ? '📅 길일 이벤트 저장 완료: ${events.length}개' : '❌ 길일 이벤트 저장 실패');
      return success;
    } catch (e) {
      debugPrint('❌ 길일 이벤트 저장 중 오류: $e');
      return false;
    }
  }
  
  /// 저장된 길일 이벤트 가져오기
  Future<List<CalendarEvent>> getSavedGoodDayEvents() async {
    try {
      final prefs = await _preferences;
      final jsonList = prefs.getStringList(_keyGoodDayEvents) ?? [];
      
      final events = jsonList
          .map((jsonStr) {
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              return CalendarEvent.fromJson(json);
            } catch (e) {
              debugPrint('⚠️ 길일 이벤트 데이터 파싱 실패: $e');
              return null;
            }
          })
          .where((event) => event != null)
          .cast<CalendarEvent>()
          .toList();
      
      debugPrint('📅 저장된 길일 이벤트 ${events.length}개 로드 완료');
      return events;
    } catch (e) {
      debugPrint('❌ 저장된 길일 이벤트 로드 실패: $e');
      return [];
    }
  }
  
  /// 모든 데이터 삭제 (초기화)
  Future<bool> clearAllData() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_keyAnalysisList);
      await prefs.remove(_keyCurrentAnalysis);
      await prefs.remove(_keyGoodDayEvents);
      await prefs.remove(_keySajuProfile);
      
      debugPrint('🧹 모든 로컬 데이터 삭제 완료');
      return true;
    } catch (e) {
      debugPrint('❌ 데이터 삭제 중 오류: $e');
      return false;
    }
  }
  
  /// 저장 공간 사용량 확인 (대략적)
  Future<String> getStorageInfo() async {
    try {
      final analysisList = await getSavedAnalysisList();
      final events = await getSavedGoodDayEvents();
      
      return '저장된 분석: ${analysisList.length}개\n길일 이벤트: ${events.length}개';
    } catch (e) {
      return '저장 정보 확인 실패';
    }
  }
} 