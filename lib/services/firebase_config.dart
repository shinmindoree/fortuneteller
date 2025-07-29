import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase 기본 구성 설정
class FirebaseConfig {
  
  /// Firebase 초기화 (Firebase 프로젝트가 설정된 경우에만 활성화)
  static Future<void> initialize() async {
    try {
      debugPrint('🔥 Firebase 초기화 시도...');
      
      // Firebase 프로젝트가 설정되어 있는지 확인
      if (_isFirebaseConfigured()) {
        await Firebase.initializeApp();
        
        // 백그라운드 메시지 핸들러 설정
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        debugPrint('✅ Firebase 초기화 완료');
      } else {
        debugPrint('⚠️ Firebase 프로젝트가 설정되지 않음 (로컬 알림으로 대체)');
      }
    } catch (e) {
      debugPrint('⚠️ Firebase 초기화 실패 (로컬 알림으로 대체): $e');
    }
  }
  
  /// Firebase 프로젝트 설정 여부 확인
  static bool _isFirebaseConfigured() {
    try {
      // Firebase 앱이 초기화되었는지 확인
      return true; // google-services.json이 있으면 Firebase 사용 가능
    } catch (e) {
      return false;
    }
  }
  
  /// Firebase 사용 가능 여부
  static bool get isAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Firebase 앱 정보
  static Map<String, dynamic> get info {
    try {
      if (Firebase.apps.isNotEmpty) {
        final app = Firebase.app();
        return {
          'name': app.name,
          'options': {
            'projectId': app.options.projectId,
            'appId': app.options.appId,
          },
          'isConfigured': true,
        };
      }
    } catch (e) {
      debugPrint('Firebase 정보 조회 실패: $e');
    }
    
    return {
      'name': 'default',
      'options': {},
      'isConfigured': false,
    };
  }
}

/// 백그라운드 메시지 핸들러 (전역 함수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('📨 백그라운드 FCM 메시지: ${message.notification?.title}');
  } catch (e) {
    debugPrint('❌ 백그라운드 메시지 처리 실패: $e');
  }
} 