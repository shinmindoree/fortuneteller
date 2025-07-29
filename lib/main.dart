import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/fortune_service.dart';
import 'services/supabase_sync_service.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/firebase_config.dart';
import 'models/saved_analysis.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/calendar_event.dart';
import 'models/fortune_reading.dart';
import 'screens/auth_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/saju_input_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/saju_analysis_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize Supabase
    await SupabaseService.initialize();
    
    // Initialize Notification Service
    await NotificationService.instance.initialize();
    
    // Initialize Storage Service
    await StorageService.instance.initialize();
    
    // Initialize Auth Service
    await AuthService.instance.initialize();
    
    // Initialize Firebase
    await FirebaseConfig.initialize();
    
    // Initialize FCM Service
    await FCMService.instance.initialize();
    
    runApp(const FortuneTellerApp());
  } catch (e) {
    print('앱 초기화 실패: $e');
    runApp(const ErrorApp(error: '앱 초기화에 실패했습니다. 환경 설정을 확인해주세요.'));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '사주플래너 - 오류',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '오류 발생',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FortuneTellerApp extends StatelessWidget {
  const FortuneTellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '사주플래너',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E4EC6), // 보라색 테마
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = '앱을 초기화하고 있습니다...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _statusMessage = 'Supabase 연결을 확인하고 있습니다...';
      });
      
      // Supabase 연결 상태 확인
      final isConnected = await SupabaseService.instance.checkConnection();
      
      if (isConnected) {
        setState(() {
          _statusMessage = '연결 완료! 앱을 시작합니다...';
        });
        await Future.delayed(const Duration(seconds: 1));
      } else {
        setState(() {
          _statusMessage = 'Supabase 연결 실패 - 오프라인 모드로 진행';
        });
        await Future.delayed(const Duration(seconds: 2));
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '초기화 중 오류 발생: $e';
      });
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 24),
            Text(
              '사주플래너',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '내 사주에 맞는 길일을 찾아보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// 분석 결과 자세히 보기
  void _showAnalysisDetails(BuildContext context, SavedAnalysis analysis) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SajuAnalysisScreen(
          sajuChars: analysis.sajuChars,
          name: analysis.name,
          birthDate: analysis.birthDate,
          gender: analysis.gender,
          isLunar: analysis.isLunar,
          // 저장된 결과를 표시하도록 설정
          preloadedResult: analysis.analysisResult,
        ),
      ),
    );
  }

  /// 길일과 함께 캘린더로 이동
  void _goToCalendarWithEvents(BuildContext context, List<CalendarEvent> events) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CalendarScreen(
          initialEvents: events,
        ),
      ),
    );
  }

  /// 상대적 시간 포맷팅
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.month}월 ${dateTime.day}일';
    }
  }

  /// 운세 상세 보기
  void _showFortuneDetail(BuildContext context, FortuneReading fortune) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  Row(
                    children: [
                      Text(
                        fortune.typeIcon,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fortune.typeName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              fortune.dateFormatted,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 운세 등급
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(int.parse(fortune.scores.gradeColor.substring(1), radix: 16) + 0xFF000000),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${fortune.scores.grade}급',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // 진행률
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '진행률',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(fortune.progress * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: fortune.progress,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // 운세 점수
                  Text(
                    '운세 점수',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _ScoreItem('재물', fortune.scores.wealth, Colors.amber)),
                      Expanded(child: _ScoreItem('건강', fortune.scores.health, Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _ScoreItem('애정', fortune.scores.love, Colors.pink)),
                      Expanded(child: _ScoreItem('직업', fortune.scores.career, Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // 설명
                  Text(
                    fortune.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fortune.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  
                  // 행운 아이템
                  if (fortune.luckyItems.isNotEmpty) ...[
                    Text(
                      '🍀 행운 아이템',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: fortune.luckyItems.map((item) => Chip(
                        label: Text(item),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 추천 사항
                  if (fortune.recommendations.isNotEmpty) ...[
                    Text(
                      '✨ 추천 행동',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...fortune.recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Text('• '),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  
                  // 주의 사항
                  if (fortune.warnings.isNotEmpty) ...[
                    Text(
                      '⚠️ 주의 사항',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...fortune.warnings.map((warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Text('• '),
                          Expanded(child: Text(warning)),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사주플래너'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          // 사용자 정보 및 로그아웃
          StreamBuilder<User?>(
            stream: AuthService.instance.authStateChanges,
            initialData: AuthService.instance.currentUser,
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null) {
                return PopupMenuButton<String>(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.email ?? '사용자',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '로그인됨',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'notifications',
                      child: Row(
                        children: [
                          Icon(Icons.notifications),
                          SizedBox(width: 8),
                          Text('알림 설정'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('로그아웃'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'notifications') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsScreen(),
                        ),
                      );
                    } else if (value == 'logout') {
                      final result = await AuthService.instance.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message ?? '로그아웃 완료'),
                            backgroundColor: result.isSuccess ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Supabase 연결 상태 표시
          FutureBuilder<bool>(
            future: SupabaseService.instance.checkConnection(),
            builder: (context, snapshot) {
              final isConnected = snapshot.data == true;
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? Colors.green : Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.waving_hand,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '안녕하세요!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '사주 분석으로 나만의 길일을 찾아보세요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              '빠른 시작',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.person_add,
                    title: '사주 입력',
                    subtitle: '내 정보를 입력하고\n사주를 분석해보세요',
                                          onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SajuInputScreen()),
                        );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.calendar_today,
                    title: '길일 보기',
                    subtitle: '이번 달 추천\n길일을 확인하세요',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const CalendarScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 운세 카드 섹션
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '나의 운세',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: PageView(
                    children: [
                      _FortuneCard(
                        title: '오늘의 운세',
                        icon: '🌅',
                        future: FortuneService.instance.getTodayFortune(),
                        onTap: (fortune) => _showFortuneDetail(context, fortune),
                      ),
                      _FortuneCard(
                        title: '이주의 운세',
                        icon: '📅',
                        future: FortuneService.instance.getWeeklyFortune(),
                        onTap: (fortune) => _showFortuneDetail(context, fortune),
                      ),
                      _FortuneCard(
                        title: '이달의 운세',
                        icon: '🗓️',
                        future: FortuneService.instance.getMonthlyFortune(),
                        onTap: (fortune) => _showFortuneDetail(context, fortune),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 최근 분석 결과
            FutureBuilder<SavedAnalysis?>(
              future: StorageService.instance.getCurrentAnalysis(),
              builder: (context, snapshot) {
                final currentAnalysis = snapshot.data;
                
                if (currentAnalysis == null) {
                  return const SizedBox.shrink(); // 저장된 분석이 없으면 숨김
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '최근 분석',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: InkWell(
                        onTap: () => _showAnalysisDetails(context, currentAnalysis),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      currentAnalysis.summary,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '사주: ${currentAnalysis.sajuChars.display}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '길일: ${currentAnalysis.goodDayEvents.length}개',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showAnalysisDetails(context, currentAnalysis),
                                    icon: const Icon(Icons.visibility, size: 16),
                                    label: const Text('자세히 보기'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _goToCalendarWithEvents(context, currentAnalysis.goodDayEvents),
                                    icon: const Icon(Icons.calendar_month, size: 16),
                                    label: const Text('캘린더 보기'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            
            // 클라우드 동기화 상태
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_sync,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '클라우드 동기화',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // 동기화 버튼 또는 로그인 버튼
                        _SyncOrLoginButton(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // 연결 상태
                    FutureBuilder<bool>(
                      future: SupabaseService.instance.checkConnection(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('연결 상태 확인 중...'),
                            ],
                          );
                        }
                        
                        final isConnected = snapshot.data == true;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isConnected ? Icons.cloud_done : Icons.cloud_off,
                                color: isConnected ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isConnected ? '클라우드 연결됨' : '오프라인 모드',
                                style: TextStyle(
                                  color: isConnected ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // 마지막 동기화 시간
                    FutureBuilder<DateTime?>(
                      future: SupabaseSyncService.instance.getLastSyncTime(),
                      builder: (context, snapshot) {
                        final lastSync = snapshot.data;
                        return Text(
                          lastSync != null 
                              ? '마지막 동기화: ${_formatRelativeTime(lastSync)}'
                              : '동기화 기록 없음',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Environment Status (for development)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '환경 설정 상태',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusRow('Azure OpenAI', dotenv.env['AZURE_OPENAI_ENDPOINT'] != null),
                    _StatusRow('Supabase', dotenv.env['SUPABASE_URL'] != null),
                    _StatusRow('Firebase', dotenv.env['FIREBASE_PROJECT_ID'] != null),
                    const SizedBox(height: 8),
                    FutureBuilder<String>(
                      future: StorageService.instance.getStorageInfo(),
                      builder: (context, snapshot) {
                        final info = snapshot.data ?? '정보 로딩 중...';
                        return Text(
                          info,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          await NotificationService.instance.showTestNotification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('테스트 알림을 전송했습니다!')),
                          );
                        },
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('알림 테스트'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String service;
  final bool isConfigured;

  const _StatusRow(this.service, this.isConfigured);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.error,
            size: 16,
            color: isConfigured ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text('$service: ${isConfigured ? '설정됨' : '미설정'}'),
        ],
      ),
    );
  }
}

/// 동기화 또는 로그인 버튼 위젯
class _SyncOrLoginButton extends StatefulWidget {
  @override
  State<_SyncOrLoginButton> createState() => _SyncOrLoginButtonState();
}

class _SyncOrLoginButtonState extends State<_SyncOrLoginButton> {
  bool _isSyncing = false;

  Future<void> _performSync() async {
    if (_isSyncing) return;

    // 로그인 상태 확인
    if (!AuthService.instance.isLoggedIn) {
      _goToAuthScreen();
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await SupabaseSyncService.instance.syncAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '동기화 완료'),
            backgroundColor: result.isSuccess 
                ? Colors.green 
                : result.status == SyncStatus.offline 
                    ? Colors.orange 
                    : Colors.red,
            action: SnackBarAction(
              label: '확인',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('동기화 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _goToAuthScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.data != null;
        
        if (!isLoggedIn) {
          // 로그인하지 않은 경우 로그인 버튼 표시
          return IconButton(
            onPressed: _goToAuthScreen,
            icon: Icon(
              Icons.login,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: '로그인',
          );
        }
        
        // 로그인한 경우 동기화 버튼 표시
        return IconButton(
          onPressed: _isSyncing ? null : _performSync,
          icon: _isSyncing 
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.sync,
                  color: Theme.of(context).colorScheme.primary,
                ),
          tooltip: _isSyncing ? '동기화 중...' : '수동 동기화',
        );
      },
    );
  }
}

/// 운세 카드 위젯
class _FortuneCard extends StatelessWidget {
  final String title;
  final String icon;
  final Future<FortuneReading> future;
  final Function(FortuneReading) onTap;

  const _FortuneCard({
    required this.title,
    required this.icon,
    required this.future,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FutureBuilder<FortuneReading>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '운세를 불러오는데\n실패했습니다',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final fortune = snapshot.data!;
          
          return Card(
            child: InkWell(
              onTap: () => onTap(fortune),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // 등급 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(int.parse(fortune.scores.gradeColor.substring(1), radix: 16) + 0xFF000000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            fortune.scores.grade,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 요약
                    Text(
                      fortune.summary,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    
                    // 진행률
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              fortune.dateFormatted,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${(fortune.progress * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: fortune.progress,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 점수 미리보기
                    Row(
                      children: [
                        _MiniScoreItem('재물', fortune.scores.wealth),
                        const SizedBox(width: 8),
                        _MiniScoreItem('건강', fortune.scores.health),
                        const SizedBox(width: 8),
                        _MiniScoreItem('애정', fortune.scores.love),
                        const SizedBox(width: 8),
                        _MiniScoreItem('직업', fortune.scores.career),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 점수 아이템 위젯 (상세 화면용)
class _ScoreItem extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreItem(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 미니 점수 아이템 위젯 (카드용)
class _MiniScoreItem extends StatelessWidget {
  final String label;
  final int score;

  const _MiniScoreItem(this.label, this.score);

  @override
  Widget build(BuildContext context) {
    Color getScoreColor(int score) {
      if (score >= 80) return Colors.green;
      if (score >= 60) return Colors.orange;
      return Colors.red;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: getScoreColor(score).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
              ),
            ),
            Text(
              '$score',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: getScoreColor(score),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
