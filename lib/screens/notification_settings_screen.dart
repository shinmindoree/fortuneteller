import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import '../services/firebase_config.dart';

/// 알림 설정 화면
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  
  // 알림 설정 상태
  bool _dailyFortuneEnabled = true;
  TimeOfDay _dailyFortuneTime = const TimeOfDay(hour: 8, minute: 0);
  bool _goodDayReminderEnabled = true;
  bool _weeklyFortuneEnabled = true;
  bool _monthlyFortuneEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 알림 설정 로드
  Future<void> _loadSettings() async {
    try {
      final settings = await FCMService.instance.loadNotificationSettings();
      
      setState(() {
        _dailyFortuneEnabled = settings['daily_fortune_enabled'] ?? true;
        _dailyFortuneTime = settings['daily_fortune_time'] ?? const TimeOfDay(hour: 8, minute: 0);
        _goodDayReminderEnabled = settings['good_day_reminder_enabled'] ?? true;
        _weeklyFortuneEnabled = settings['weekly_fortune_enabled'] ?? true;
        _monthlyFortuneEnabled = settings['monthly_fortune_enabled'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('설정 로드 실패: $e');
    }
  }

  /// 알림 설정 저장
  Future<void> _saveSettings() async {
    try {
      await FCMService.instance.saveNotificationSettings(
        dailyFortuneEnabled: _dailyFortuneEnabled,
        dailyFortuneTime: _dailyFortuneTime,
        goodDayReminderEnabled: _goodDayReminderEnabled,
        weeklyFortuneEnabled: _weeklyFortuneEnabled,
        monthlyFortuneEnabled: _monthlyFortuneEnabled,
      );

      // 일일 운세 알림 스케줄 업데이트
      if (_dailyFortuneEnabled) {
        await FCMService.instance.scheduleDailyFortuneNotification(
          time: _dailyFortuneTime,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 설정이 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 시간 선택기 표시
  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _dailyFortuneTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        _dailyFortuneTime = selectedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              '저장',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Firebase 상태 표시
                  _buildFirebaseStatusCard(),
                  const SizedBox(height: 24),
                  
                  // 운세 알림 설정
                  _buildFortuneNotificationsSection(),
                  const SizedBox(height: 24),
                  
                  // 일정 알림 설정
                  _buildScheduleNotificationsSection(),
                  const SizedBox(height: 24),
                  
                  // 알림 테스트 버튼
                  _buildTestNotificationSection(),
                  const SizedBox(height: 24),
                  
                  // 알림 관리
                  _buildNotificationManagementSection(),
                ],
              ),
            ),
    );
  }

  /// Firebase 상태 카드
  Widget _buildFirebaseStatusCard() {
    final isFirebaseAvailable = FirebaseConfig.isAvailable;
    final firebaseInfo = FirebaseConfig.info;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud,
                  color: isFirebaseAvailable ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Firebase 상태',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFirebaseAvailable 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isFirebaseAvailable ? Icons.check_circle : Icons.warning,
                    color: isFirebaseAvailable ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFirebaseAvailable 
                          ? 'Firebase 연결됨 (푸시 알림 사용 가능)'
                          : '로컬 알림 모드 (Firebase 미설정)',
                      style: TextStyle(
                        color: isFirebaseAvailable ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (isFirebaseAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'FCM 토큰: ${FCMService.instance.fcmToken?.substring(0, 20) ?? 'N/A'}...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 운세 알림 설정 섹션
  Widget _buildFortuneNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '운세 알림',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Column(
            children: [
              // 일일 운세 알림
              SwitchListTile(
                title: const Text('오늘의 운세'),
                subtitle: Text(
                  _dailyFortuneEnabled 
                      ? '매일 ${_dailyFortuneTime.format(context)}에 알림'
                      : '비활성화됨',
                ),
                value: _dailyFortuneEnabled,
                onChanged: (value) {
                  setState(() {
                    _dailyFortuneEnabled = value;
                  });
                },
                secondary: const Icon(Icons.wb_sunny),
              ),
              
              // 시간 설정 (일일 운세가 활성화된 경우에만)
              if (_dailyFortuneEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  title: const Text('알림 시간'),
                  subtitle: Text(_dailyFortuneTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectTime,
                ),
              ],
              
              const Divider(height: 1),
              
              // 주간 운세 알림
              SwitchListTile(
                title: const Text('이주의 운세'),
                subtitle: const Text('매주 월요일 오전 알림'),
                value: _weeklyFortuneEnabled,
                onChanged: (value) {
                  setState(() {
                    _weeklyFortuneEnabled = value;
                  });
                },
                secondary: const Icon(Icons.calendar_view_week),
              ),
              
              const Divider(height: 1),
              
              // 월간 운세 알림
              SwitchListTile(
                title: const Text('이달의 운세'),
                subtitle: const Text('매월 1일 오전 알림'),
                value: _monthlyFortuneEnabled,
                onChanged: (value) {
                  setState(() {
                    _monthlyFortuneEnabled = value;
                  });
                },
                secondary: const Icon(Icons.calendar_month),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 일정 알림 설정 섹션
  Widget _buildScheduleNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일정 알림',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Column(
            children: [
              // 길일 리마인더
              SwitchListTile(
                title: const Text('길일 리마인더'),
                subtitle: const Text('중요한 길일 하루 전 알림'),
                value: _goodDayReminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _goodDayReminderEnabled = value;
                  });
                },
                secondary: const Icon(Icons.event_available),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 알림 테스트 섹션
  Widget _buildTestNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림 테스트',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('알림이 제대로 작동하는지 테스트해보세요.'),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testDailyFortuneNotification,
                        icon: const Icon(Icons.wb_sunny),
                        label: const Text('운세 알림 테스트'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testGoodDayReminder,
                        icon: const Icon(Icons.event),
                        label: const Text('길일 알림 테스트'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 알림 관리 섹션
  Widget _buildNotificationManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림 관리',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('모든 알림 취소'),
                subtitle: const Text('스케줄된 모든 알림을 취소합니다'),
                leading: const Icon(Icons.notifications_off, color: Colors.red),
                trailing: const Icon(Icons.chevron_right),
                onTap: _cancelAllNotifications,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 일일 운세 알림 테스트
  void _testDailyFortuneNotification() async {
    try {
      await FCMService.instance.scheduleNotification(
        title: '🌅 오늘의 운세 (테스트)',
        body: '테스트 알림입니다. 실제로는 매일 설정된 시간에 발송됩니다.',
        type: FCMNotificationType.dailyFortune,
        scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('5초 후 테스트 알림이 발송됩니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테스트 알림 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 길일 리마인더 테스트
  void _testGoodDayReminder() async {
    try {
      await FCMService.instance.scheduleNotification(
        title: '📅 길일 알림 (테스트)',
        body: '내일은 중요한 길일입니다. 준비하세요!',
        type: FCMNotificationType.goodDayReminder,
        scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
        data: {
          'test': true,
          'good_day': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('5초 후 테스트 알림이 발송됩니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테스트 알림 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 모든 알림 취소
  void _cancelAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 취소'),
        content: const Text('스케줄된 모든 알림을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FCMService.instance.cancelAllScheduledNotifications();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('모든 알림이 취소되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('알림 취소 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 