import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/calendar_event.dart';

/// 알림 관리 서비스
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Android 초기화 설정
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS 초기화 설정
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // 권한 요청
      await _requestPermissions();
      
      _isInitialized = true;
      debugPrint('📱 알림 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ 알림 서비스 초기화 실패: $e');
    }
  }
  
  /// 알림 권한 요청
  Future<bool> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return true;
  }
  
  /// 알림 클릭 시 처리
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 알림 클릭됨: ${response.payload}');
    // TODO: 알림 클릭 시 해당 캘린더 화면으로 이동
  }
  
  /// 길일 알림 스케줄링
  Future<bool> scheduleGoodDayNotification({
    required CalendarEvent event,
    required int daysBefore,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final reminderDate = event.date.subtract(Duration(days: daysBefore));
      final now = DateTime.now();
      
      // 과거 날짜는 스케줄링하지 않음
      if (reminderDate.isBefore(now)) {
        debugPrint('⚠️ 과거 날짜는 알림 설정할 수 없습니다');
        return false;
      }
      
      // 알림 시간 설정 (오전 9시 또는 오후 6시)
      final notificationTime = daysBefore == 0 
          ? DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9, 0) // 당일 오전 9시
          : DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 18, 0); // 전날 오후 6시
      
      // 고유 ID 생성
      final id = _generateNotificationId(event, daysBefore);
      
      // 알림 내용 구성
      final title = daysBefore == 0 
          ? '오늘은 ${event.title} 길일입니다! 🎉'
          : '${daysBefore}일 후 ${event.title} 길일입니다';
      
      final body = event.description;
      
             // 알림 스케줄링 (임시로 즉시 알림으로 변경, 실제로는 스케줄링 구현 필요)
       // 실제 배포 시에는 timezone 패키지를 사용하여 정확한 시간 스케줄링 구현 필요
       await _flutterLocalNotificationsPlugin.show(
         id,
         title,
         body,
         const NotificationDetails(
           android: AndroidNotificationDetails(
             'goodday_channel',
             '길일 알림',
             channelDescription: '사주 분석으로 추천된 길일 알림',
             importance: Importance.high,
             priority: Priority.high,
             icon: '@mipmap/ic_launcher',
           ),
           iOS: DarwinNotificationDetails(
             presentAlert: true,
             presentBadge: true,
             presentSound: true,
           ),
         ),
         payload: '${event.id}_$daysBefore',
       );
      
      debugPrint('✅ 알림 스케줄링 완료: ${event.title} (${daysBefore}일 전)');
      return true;
    } catch (e) {
      debugPrint('❌ 알림 스케줄링 실패: $e');
      return false;
    }
  }
  
  /// 고유 알림 ID 생성
  int _generateNotificationId(CalendarEvent event, int daysBefore) {
    return '${event.id}_$daysBefore'.hashCode.abs() % 2147483647;
  }
  
  /// 예약된 알림 목록 조회
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ 예약된 알림 조회 실패: $e');
      return [];
    }
  }
  
  /// 특정 알림 취소
  Future<bool> cancelNotification(int id) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('🗑️ 알림 취소 완료: $id');
      return true;
    } catch (e) {
      debugPrint('❌ 알림 취소 실패: $e');
      return false;
    }
  }
  
  /// 모든 알림 취소
  Future<bool> cancelAllNotifications() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('🗑️ 모든 알림 취소 완료');
      return true;
    } catch (e) {
      debugPrint('❌ 모든 알림 취소 실패: $e');
      return false;
    }
  }
  
  /// 즉시 테스트 알림 표시
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _flutterLocalNotificationsPlugin.show(
        999,
        '사주플래너 알림 테스트',
        '알림이 정상적으로 작동합니다! 🎉',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            '테스트 알림',
            channelDescription: '알림 기능 테스트',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('🔔 테스트 알림 표시 완료');
    } catch (e) {
      debugPrint('❌ 테스트 알림 표시 실패: $e');
    }
  }
} 