import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  /// Supabase 클라이언트 초기화
  static Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Supabase URL과 ANON KEY가 .env 파일에 설정되어 있지 않습니다.');
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // 개발 중에는 디버그 모드 활성화
    );
  }
  
  /// Supabase 클라이언트 인스턴스
  SupabaseClient get client => Supabase.instance.client;
  
  /// 현재 사용자 정보
  User? get currentUser => client.auth.currentUser;
  
  /// 인증 상태 스트림
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  /// 연결 상태 확인
  Future<bool> checkConnection() async {
    try {
      // 간단한 쿼리로 연결 상태 확인
      await client.from('users').select('id').limit(1);
      return true;
    } catch (e) {
      print('Supabase 연결 확인 실패: $e');
      return false;
    }
  }
  
  /// 익명 로그인 (테스트용)
  Future<AuthResponse> signInAnonymously() async {
    return await client.auth.signInAnonymously();
  }
  
  /// 이메일로 회원가입
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  /// 이메일로 로그인
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// 로그아웃
  Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  /// 사용자 프로필 가져오기
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('사용자 프로필 가져오기 실패: $e');
      return null;
    }
  }
} 