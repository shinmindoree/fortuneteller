import 'package:flutter/foundation.dart';

/// 동기화 결과
class SyncResult {
  final bool isSuccess;
  final String message;
  final int syncedItems;

  const SyncResult({
    required this.isSuccess,
    required this.message,
    this.syncedItems = 0,
  });
}

/// 안전한 SupabaseSyncService (로컬 전용)
class SupabaseSyncService {
  static SupabaseSyncService? _instance;
  static SupabaseSyncService get instance => _instance ??= SupabaseSyncService._();
  
  SupabaseSyncService._();

  bool _isSyncing = false;

  /// 현재 동기화 진행 중 여부
  bool get isSyncing => _isSyncing;

  /// 모든 데이터 동기화 (로컬 전용이므로 항상 성공)
  Future<SyncResult> syncAllData() async {
    debugPrint('🔄 로컬 전용 모드 - 동기화 건너뛰기');
    return const SyncResult(
      isSuccess: true,
      message: '로컬 전용 모드입니다.',
    );
  }

  /// 사주 분석 데이터 업로드
  Future<void> uploadAnalysis(Map<String, dynamic> analysis) async {
    debugPrint('📤 로컬 전용 모드 - 분석 업로드 건너뛰기');
  }

  /// 운세 데이터 업로드
  Future<void> uploadFortune(Map<String, dynamic> fortune) async {
    debugPrint('📤 로컬 전용 모드 - 운세 업로드 건너뛰기');
  }

  /// 일정 데이터 업로드
  Future<void> uploadEvent(Map<String, dynamic> event) async {
    debugPrint('📤 로컬 전용 모드 - 일정 업로드 건너뛰기');
  }
}