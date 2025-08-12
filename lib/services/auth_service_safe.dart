import 'dart:async';
import 'package:flutter/foundation.dart';

/// 인증 결과 상태
enum AuthStatus { success, failed, cancelled, networkError }

/// 인증 결과
class AuthResult {
  final AuthStatus status;
  final String? message;

  const AuthResult({
    required this.status,
    this.message,
  });

  bool get isSuccess => status == AuthStatus.success;
}

/// 안전한 AuthService (Supabase 없이 동작)
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();

  // 인증 상태 스트림
  final _authStateController = StreamController<String?>.broadcast();
  Stream<String?> get authStateChanges => _authStateController.stream;

  /// 현재 사용자 (항상 null - 로컬 전용)
  String? get currentUser => null;

  /// 로그인 상태 확인
  bool get isLoggedIn => false;

  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      debugPrint('🔐 안전 모드 인증 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ 인증 서비스 초기화 실패: $e');
    }
  }

  /// 모든 인증 메서드는 로컬 전용 메시지 반환
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return const AuthResult(
      status: AuthStatus.failed,
      message: '이 앱은 로컬 전용으로 동작합니다.',
    );
  }

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return const AuthResult(
      status: AuthStatus.failed,
      message: '이 앱은 로컬 전용으로 동작합니다.',
    );
  }

  Future<AuthResult> signOut() async {
    return const AuthResult(
      status: AuthStatus.success,
      message: '로그아웃되었습니다.',
    );
  }

  Future<AuthResult> resetPassword(String email) async {
    return const AuthResult(
      status: AuthStatus.failed,
      message: '이 앱은 로컬 전용으로 동작합니다.',
    );
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    return null;
  }

  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    return false;
  }

  Future<AuthResult> deleteAccount() async {
    return const AuthResult(
      status: AuthStatus.failed,
      message: '이 앱은 로컬 전용으로 동작합니다.',
    );
  }
}
