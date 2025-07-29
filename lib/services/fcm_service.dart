import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

/// FCM 알림 종류
enum FCMNotificationType {
  dailyFortune,    // 일일 운세
  weeklyFortune,   // 주간 운세  
  monthlyFortune,  // 월간 운세
  goodDayReminder, // 길일 알림
  sajuAlert,       // 사주 관련 알림
  general,         // 일반 알림
}

/// FCM 알림 데이터
class FCMNotificationData {
  final String title;
  final String body;
  final FCMNotificationType type;
  final Map<String, dynamic>? data;
  final DateTime? scheduledTime;

  FCMNotificationData({
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.scheduledTime,
  });

  factory FCMNotificationData.fromMessage(RemoteMessage message) {
    final data = message.data;
    return FCMNotificationData(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: FCMNotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FCMNotificationType.general,
      ),
      data: data,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'type': type.name,
    'data': data,
    'scheduled_time': scheduledTime?.toIso8601String(),
  };
}

/// Firebase Cloud Messaging 서비스
class FCMService {
  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._();
  
  FCMService._();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  String? _fcmToken;
  bool _isInitialized = false;

  /// FCM 토큰
  String? get fcmToken => _fcmToken;

  /// 초기화 상태
  bool get isInitialized => _isInitialized;

  /// FCM 서비스 초기화
  Future<void> initialize() async {
    try {
      debugPrint('🔔 FCM 서비스 초기화 시작...');
      
      // Firebase 사용 가능 여부 확인
      final isFirebaseAvailable = Firebase.apps.isNotEmpty;
      debugPrint('🔥 Firebase 사용 가능: $isFirebaseAvailable');

      if (isFirebaseAvailable) {
        _messaging = FirebaseMessaging.instance;
        // FCM 토큰 생성 및 메시지 핸들러 설정
        await _generateFCMToken();
        _setupMessageHandlers();
      } else {
        debugPrint('⚠️ Firebase 미설정, 로컬 알림만 사용');
      }
      
      _localNotifications = FlutterLocalNotificationsPlugin();

      // 알림 권한 요청
      await _requestNotificationPermissions();

      // 로컬 알림 초기화
      await _initializeLocalNotifications();

      _isInitialized = true;
      debugPrint('✅ FCM 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ FCM 서비스 초기화 실패: $e');
    }
  }

  /// 알림 권한 요청
  Future<void> _requestNotificationPermissions() async {
    try {
      // FCM 알림 권한 요청
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 FCM 알림 권한: ${settings.authorizationStatus}');

      // 로컬 알림 권한 요청 (Android)
      if (Platform.isAndroid) {
        final permission = await Permission.notification.request();
        debugPrint('📱 로컬 알림 권한: $permission');
      }
    } catch (e) {
      debugPrint('❌ 알림 권한 요청 실패: $e');
    }
  }

  /// FCM 토큰 생성 및 저장
  Future<void> _generateFCMToken() async {
    if (_messaging == null) return;
    
    try {
      final token = await _messaging!.getToken();
      if (token != null) {
        _fcmToken = token;
        await _saveFCMToken(token);
        debugPrint('🔑 FCM 토큰 생성: ${token.substring(0, 20)}...');
        
        // 사용자가 로그인한 경우 서버에 토큰 전송
        if (AuthService.instance.isLoggedIn) {
          await _sendTokenToServer(token);
        }
      }

      // 토큰 갱신 리스너
      _messaging!.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await _saveFCMToken(newToken);
        if (AuthService.instance.isLoggedIn) {
          await _sendTokenToServer(newToken);
        }
        debugPrint('🔄 FCM 토큰 갱신: ${newToken.substring(0, 20)}...');
      });
    } catch (e) {
      debugPrint('❌ FCM 토큰 생성 실패: $e');
    }
  }

  /// 메시지 핸들러 설정
  void _setupMessageHandlers() {
    if (_messaging == null) return;
    
    try {
      // 앱이 포그라운드에 있을 때 메시지 수신
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 앱이 백그라운드에서 알림을 터치했을 때
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // 앱이 종료된 상태에서 알림을 터치했을 때 (초기 메시지)
      _checkInitialMessage();

      debugPrint('📨 FCM 메시지 핸들러 설정 완료');
    } catch (e) {
      debugPrint('❌ FCM 메시지 핸들러 설정 실패: $e');
    }
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      );

      debugPrint('📱 로컬 알림 초기화 완료');
    } catch (e) {
      debugPrint('❌ 로컬 알림 초기화 실패: $e');
    }
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 포그라운드 메시지 수신: ${message.notification?.title}');
    
    final notificationData = FCMNotificationData.fromMessage(message);
    
    // 로컬 알림으로 표시
    _showLocalNotification(notificationData);
    
    // 메시지 처리
    _processNotificationAction(notificationData);
  }

  /// 백그라운드 메시지 처리
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('📨 백그라운드 메시지 터치: ${message.notification?.title}');
    
    final notificationData = FCMNotificationData.fromMessage(message);
    _processNotificationAction(notificationData);
  }

  /// 초기 메시지 확인 (앱이 종료된 상태에서 알림 터치)
  Future<void> _checkInitialMessage() async {
    try {
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📨 초기 메시지 수신: ${initialMessage.notification?.title}');
        
        final notificationData = FCMNotificationData.fromMessage(initialMessage);
        _processNotificationAction(notificationData);
      }
    } catch (e) {
      debugPrint('❌ 초기 메시지 확인 실패: $e');
    }
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification(FCMNotificationData data) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'fcm_default_channel',
        'FCM Notifications',
        channelDescription: 'Firebase Cloud Messaging notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications!.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        data.title,
        data.body,
        details,
        payload: jsonEncode(data.toJson()),
      );
    } catch (e) {
      debugPrint('❌ 로컬 알림 표시 실패: $e');
    }
  }

  /// 로컬 알림 터치 처리
  void _handleLocalNotificationTap(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        final notificationData = FCMNotificationData(
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          type: FCMNotificationType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => FCMNotificationType.general,
          ),
          data: data['data'],
        );
        
        _processNotificationAction(notificationData);
      }
    } catch (e) {
      debugPrint('❌ 로컬 알림 터치 처리 실패: $e');
    }
  }

  /// 알림 액션 처리
  void _processNotificationAction(FCMNotificationData data) {
    debugPrint('🎯 알림 액션 처리: ${data.type.name}');
    
    // 알림 종류별 액션 처리
    switch (data.type) {
      case FCMNotificationType.dailyFortune:
      case FCMNotificationType.weeklyFortune:
      case FCMNotificationType.monthlyFortune:
        // 운세 화면으로 이동 (구현 예정)
        debugPrint('📊 운세 화면으로 이동');
        break;
        
      case FCMNotificationType.goodDayReminder:
        // 캘린더 화면으로 이동 (구현 예정)
        debugPrint('📅 캘린더 화면으로 이동');
        break;
        
      case FCMNotificationType.sajuAlert:
        // 사주 분석 화면으로 이동 (구현 예정)
        debugPrint('🔮 사주 분석 화면으로 이동');
        break;
        
      case FCMNotificationType.general:
      default:
        // 홈 화면으로 이동
        debugPrint('🏠 홈 화면으로 이동');
        break;
    }
  }

  /// FCM 토큰을 서버에 전송
  Future<void> _sendTokenToServer(String token) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      await SupabaseService.instance.client
          .from('user_profiles')
          .update({
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      debugPrint('📤 FCM 토큰 서버 전송 완료');
    } catch (e) {
      debugPrint('❌ FCM 토큰 서버 전송 실패: $e');
    }
  }

  /// FCM 토큰 로컬 저장
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      debugPrint('❌ FCM 토큰 로컬 저장 실패: $e');
    }
  }

  /// 저장된 FCM 토큰 로드
  Future<String?> _loadFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      debugPrint('❌ FCM 토큰 로드 실패: $e');
      return null;
    }
  }

  /// 스케줄된 알림 설정
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required FCMNotificationType type,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = FCMNotificationData(
        title: title,
        body: body,
        type: type,
        data: data,
        scheduledTime: scheduledTime,
      );

      // 로컬 알림으로 스케줄링 (FCM은 서버에서 스케줄링)
      await NotificationService.instance.scheduleNotification(
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: jsonEncode(notificationData.toJson()),
      );

      debugPrint('⏰ 알림 스케줄 설정: $title at $scheduledTime');
    } catch (e) {
      debugPrint('❌ 알림 스케줄 설정 실패: $e');
    }
  }

  /// 일일 운세 알림 스케줄링
  Future<void> scheduleDailyFortuneNotification({
    required TimeOfDay time,
  }) async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day + 1, // 다음 날
        time.hour,
        time.minute,
      );

      // 설정된 시간이 현재 시간보다 이르면 다음 날로 설정
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await scheduleNotification(
        title: '🌅 오늘의 운세',
        body: '새로운 하루가 시작되었습니다. 오늘의 운세를 확인해보세요!',
        type: FCMNotificationType.dailyFortune,
        scheduledTime: scheduledDate,
      );

      debugPrint('📅 일일 운세 알림 설정: ${time.hour}:${time.minute.toString().padLeft(2, '0')} 매일');
    } catch (e) {
      debugPrint('❌ 일일 운세 알림 설정 실패: $e');
    }
  }

  /// 길일 리마인더 알림 스케줄링
  Future<void> scheduleGoodDayReminder({
    required DateTime goodDay,
    required String title,
    required String description,
    int daysBefore = 1,
  }) async {
    try {
      final reminderDate = goodDay.subtract(Duration(days: daysBefore));
      
      if (reminderDate.isAfter(DateTime.now())) {
        await scheduleNotification(
          title: '📅 길일 알림',
          body: '$title이 ${daysBefore}일 후입니다. $description',
          type: FCMNotificationType.goodDayReminder,
          scheduledTime: reminderDate,
          data: {
            'good_day': goodDay.toIso8601String(),
            'title': title,
            'description': description,
          },
        );

        debugPrint('📅 길일 리마인더 설정: $title, $reminderDate');
      }
    } catch (e) {
      debugPrint('❌ 길일 리마인더 설정 실패: $e');
    }
  }

  /// 알림 설정 저장
  Future<void> saveNotificationSettings({
    required bool dailyFortuneEnabled,
    required TimeOfDay dailyFortuneTime,
    required bool goodDayReminderEnabled,
    required bool weeklyFortuneEnabled,
    required bool monthlyFortuneEnabled,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('daily_fortune_enabled', dailyFortuneEnabled);
      await prefs.setInt('daily_fortune_hour', dailyFortuneTime.hour);
      await prefs.setInt('daily_fortune_minute', dailyFortuneTime.minute);
      await prefs.setBool('good_day_reminder_enabled', goodDayReminderEnabled);
      await prefs.setBool('weekly_fortune_enabled', weeklyFortuneEnabled);
      await prefs.setBool('monthly_fortune_enabled', monthlyFortuneEnabled);

      debugPrint('💾 알림 설정 저장 완료');
    } catch (e) {
      debugPrint('❌ 알림 설정 저장 실패: $e');
    }
  }

  /// 알림 설정 로드
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'daily_fortune_enabled': prefs.getBool('daily_fortune_enabled') ?? true,
        'daily_fortune_time': TimeOfDay(
          hour: prefs.getInt('daily_fortune_hour') ?? 8,
          minute: prefs.getInt('daily_fortune_minute') ?? 0,
        ),
        'good_day_reminder_enabled': prefs.getBool('good_day_reminder_enabled') ?? true,
        'weekly_fortune_enabled': prefs.getBool('weekly_fortune_enabled') ?? true,
        'monthly_fortune_enabled': prefs.getBool('monthly_fortune_enabled') ?? true,
      };
    } catch (e) {
      debugPrint('❌ 알림 설정 로드 실패: $e');
      return {
        'daily_fortune_enabled': true,
        'daily_fortune_time': const TimeOfDay(hour: 8, minute: 0),
        'good_day_reminder_enabled': true,
        'weekly_fortune_enabled': true,
        'monthly_fortune_enabled': true,
      };
    }
  }

  /// 모든 스케줄된 알림 취소
  Future<void> cancelAllScheduledNotifications() async {
    try {
      await _localNotifications?.cancelAll();
      debugPrint('🗑️ 모든 스케줄된 알림 취소 완료');
    } catch (e) {
      debugPrint('❌ 스케줄된 알림 취소 실패: $e');
    }
  }

  /// 특정 타입의 알림 취소
  Future<void> cancelNotificationsByType(FCMNotificationType type) async {
    try {
      // 구현 예정: 특정 타입의 알림만 취소
      debugPrint('🗑️ ${type.name} 알림 취소 요청');
    } catch (e) {
      debugPrint('❌ 알림 취소 실패: $e');
    }
  }

  /// FCM 서비스 종료
  void dispose() {
    debugPrint('🔔 FCM 서비스 종료');
  }
}

 