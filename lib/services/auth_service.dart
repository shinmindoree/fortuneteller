import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'storage_service.dart';
import 'supabase_sync_service.dart';

/// 인증 결과 상태
enum AuthStatus { success, failed, cancelled, networkError }

/// 인증 결과
class AuthResult {
  final AuthStatus status;
  final String? message;
  final User? user;

  const AuthResult({
    required this.status,
    this.message,
    this.user,
  });

  bool get isSuccess => status == AuthStatus.success;
}

/// 사용자 인증 서비스
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  
  // 인증 상태 스트림
  final _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  /// 현재 사용자
  User? get currentUser => _client.auth.currentUser;

  /// 로그인 상태 확인
  bool get isLoggedIn => currentUser != null;

  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      // Supabase Auth 상태 변경 리스너 등록
      _client.auth.onAuthStateChange.listen((data) {
        final user = data.session?.user;
        _authStateController.add(user);
        debugPrint('🔐 인증 상태 변경: ${user?.email ?? '로그아웃'}');
        
        // 로그인 시 자동 동기화
        if (user != null) {
          _performAutoSync();
        }
      });
      
      debugPrint('🔐 인증 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ 인증 서비스 초기화 실패: $e');
    }
  }

  /// 이메일/비밀번호로 회원가입
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      debugPrint('📝 회원가입 시도: $email');
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      if (response.user != null) {
        debugPrint('✅ 회원가입 성공: ${response.user!.email}');
        
        // 사용자 프로필 생성
        await _createUserProfile(response.user!, displayName);
        
        return AuthResult(
          status: AuthStatus.success,
          message: '회원가입이 완료되었습니다.',
          user: response.user,
        );
      } else {
        return const AuthResult(
          status: AuthStatus.failed,
          message: '회원가입에 실패했습니다.',
        );
      }
    } on AuthException catch (e) {
      debugPrint('❌ 회원가입 실패: ${e.message}');
      return AuthResult(
        status: AuthStatus.failed,
        message: _getAuthErrorMessage(e),
      );
    } catch (e) {
      debugPrint('❌ 회원가입 오류: $e');
      return AuthResult(
        status: AuthStatus.networkError,
        message: '네트워크 오류가 발생했습니다.',
      );
    }
  }

  /// 이메일/비밀번호로 로그인
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔑 로그인 시도: $email');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('✅ 로그인 성공: ${response.user!.email}');
        
        return AuthResult(
          status: AuthStatus.success,
          message: '로그인되었습니다.',
          user: response.user,
        );
      } else {
        return const AuthResult(
          status: AuthStatus.failed,
          message: '로그인에 실패했습니다.',
        );
      }
    } on AuthException catch (e) {
      debugPrint('❌ 로그인 실패: ${e.message}');
      return AuthResult(
        status: AuthStatus.failed,
        message: _getAuthErrorMessage(e),
      );
    } catch (e) {
      debugPrint('❌ 로그인 오류: $e');
      return AuthResult(
        status: AuthStatus.networkError,
        message: '네트워크 오류가 발생했습니다.',
      );
    }
  }

  /// 구글 소셜 로그인
  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('🌐 구글 로그인 시도');
      
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.fortuneteller://callback',
      );

      if (response) {
        return const AuthResult(
          status: AuthStatus.success,
          message: '구글 로그인 진행 중...',
        );
      } else {
        return const AuthResult(
          status: AuthStatus.failed,
          message: '구글 로그인에 실패했습니다.',
        );
      }
    } catch (e) {
      debugPrint('❌ 구글 로그인 오류: $e');
      return const AuthResult(
        status: AuthStatus.failed,
        message: '구글 로그인 중 오류가 발생했습니다.',
      );
    }
  }

  /// 로그아웃
  Future<AuthResult> signOut() async {
    try {
      debugPrint('🚪 로그아웃 시도');
      
      await _client.auth.signOut();
      
      // 로컬 데이터 정리 (선택사항)
      // await StorageService.instance.clearAllData();
      
      debugPrint('✅ 로그아웃 완료');
      
      return const AuthResult(
        status: AuthStatus.success,
        message: '로그아웃되었습니다.',
      );
    } catch (e) {
      debugPrint('❌ 로그아웃 오류: $e');
      return AuthResult(
        status: AuthStatus.failed,
        message: '로그아웃 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 비밀번호 재설정 이메일 발송
  Future<AuthResult> resetPassword(String email) async {
    try {
      debugPrint('📧 비밀번호 재설정 이메일 발송: $email');
      
      await _client.auth.resetPasswordForEmail(email);
      
      return const AuthResult(
        status: AuthStatus.success,
        message: '비밀번호 재설정 이메일을 발송했습니다.',
      );
    } on AuthException catch (e) {
      debugPrint('❌ 비밀번호 재설정 실패: ${e.message}');
      return AuthResult(
        status: AuthStatus.failed,
        message: _getAuthErrorMessage(e),
      );
    } catch (e) {
      debugPrint('❌ 비밀번호 재설정 오류: $e');
      return AuthResult(
        status: AuthStatus.networkError,
        message: '네트워크 오류가 발생했습니다.',
      );
    }
  }

  /// 사용자 프로필 정보 가져오기
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ 사용자 프로필 조회 실패: $e');
      return null;
    }
  }

  /// 사용자 프로필 업데이트
  Future<bool> updateUserProfile({
    String? displayName,
    DateTime? birthDate,
    String? gender,
    bool? isLunarCalendar,
    bool? notificationEnabled,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final updateData = <String, dynamic>{};
      
      if (displayName != null) updateData['display_name'] = displayName;
      if (birthDate != null) updateData['birth_date'] = birthDate.toIso8601String().split('T')[0];
      if (gender != null) updateData['gender'] = gender;
      if (isLunarCalendar != null) updateData['is_lunar_calendar'] = isLunarCalendar;
      if (notificationEnabled != null) updateData['notification_enabled'] = notificationEnabled;
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('user_profiles')
          .upsert({
            'id': user.id,
            ...updateData,
          });

      debugPrint('✅ 사용자 프로필 업데이트 완료');
      return true;
    } catch (e) {
      debugPrint('❌ 사용자 프로필 업데이트 실패: $e');
      return false;
    }
  }

  /// 계정 삭제
  Future<AuthResult> deleteAccount() async {
    try {
      debugPrint('🗑️ 계정 삭제 시도');
      
      final user = currentUser;
      if (user == null) {
        return const AuthResult(
          status: AuthStatus.failed,
          message: '로그인이 필요합니다.',
        );
      }

      // 사용자 데이터 삭제 (Supabase RLS 정책에 의해 자동 삭제됨)
      await _client.rpc('delete_user_data', params: {'user_id': user.id});
      
      // 계정 삭제 (관리자 권한 필요, 일반적으로 서버에서 처리)
      // 여기서는 로그아웃만 수행
      await signOut();
      
      return const AuthResult(
        status: AuthStatus.success,
        message: '계정 삭제 요청이 처리되었습니다.',
      );
    } catch (e) {
      debugPrint('❌ 계정 삭제 오류: $e');
      return AuthResult(
        status: AuthStatus.failed,
        message: '계정 삭제 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 사용자 프로필 생성
  Future<void> _createUserProfile(User user, String? displayName) async {
    try {
      await _client.from('user_profiles').insert({
        'id': user.id,
        'display_name': displayName ?? user.email?.split('@')[0],
        'notification_enabled': true,
        'timezone': 'Asia/Seoul',
      });
      
      debugPrint('✅ 사용자 프로필 생성 완료');
    } catch (e) {
      debugPrint('⚠️ 사용자 프로필 생성 실패: $e');
    }
  }

  /// 로그인 후 자동 동기화
  void _performAutoSync() {
    Future.microtask(() async {
      try {
        await Future.delayed(const Duration(seconds: 2)); // 로그인 완료 대기
        
        final result = await SupabaseSyncService.instance.syncAllData();
        if (result.isSuccess) {
          debugPrint('🔄 로그인 후 자동 동기화 완료');
        }
      } catch (e) {
        debugPrint('⚠️ 로그인 후 자동 동기화 실패: $e');
      }
    });
  }

  /// 인증 오류 메시지 변환
  String _getAuthErrorMessage(AuthException e) {
    switch (e.message.toLowerCase()) {
      case 'invalid login credentials':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'user already registered':
        return '이미 가입된 이메일입니다.';
      case 'weak password':
        return '비밀번호가 너무 약합니다. 6자 이상 입력해주세요.';
      case 'invalid email':
        return '올바른 이메일 주소를 입력해주세요.';
      case 'signup disabled':
        return '현재 회원가입이 비활성화되어 있습니다.';
      case 'email rate limit exceeded':
        return '이메일 전송 한도를 초과했습니다. 잠시 후 다시 시도해주세요.';
      default:
        return e.message;
    }
  }

  /// 리소스 정리
  void dispose() {
    _authStateController.close();
  }
} 