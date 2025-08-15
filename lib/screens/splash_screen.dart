import 'package:flutter/material.dart';
import 'dart:async';
import 'saju_input_screen.dart';
import '../services/storage_service.dart';
import '../services/saju_calculator.dart';
import '../models/saju_chars.dart';
import 'yulhyun_chatbot_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/ad_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _startOptimizedFlow();
  }

  void _startOptimizedFlow() async {
    // 애니메이션 시작
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _scaleController.forward();
    
    // 병렬 처리: 애니메이션과 함께 데이터 로딩 시작
    final futures = await Future.wait([
      _preloadAppOpenAd(),
      _loadUserProfile(),
      Future.delayed(const Duration(milliseconds: 1800)), // 최소 애니메이션 시간 보장
    ]);
    
    final adPreloaded = futures[0] as bool;
    final profile = futures[1] as Map<String, dynamic>?;
    
    if (!mounted) return;
    
    // 광고가 준비되었으면 표시 (비차단)
    if (adPreloaded) {
      _showAppOpenAdAsync();
    }
    
    // 프로필 확인 후 적절한 화면으로 이동
    _navigateToNextScreen(profile);
  }

  Future<bool> _preloadAppOpenAd() async {
    try {
      // 백그라운드에서 광고 미리 로딩
      await AdService.instance.loadAppOpenAd();
      return true;
    } catch (e) {
      debugPrint('광고 프리로딩 실패: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _loadUserProfile() async {
    try {
      return await StorageService.instance.getSajuProfile();
    } catch (e) {
      debugPrint('프로필 로딩 실패: $e');
      return null;
    }
  }

  void _showAppOpenAdAsync() {
    // 비동기로 광고 표시 (다음 화면 전환을 차단하지 않음)
    AdService.instance.showAppOpenAd().then((shown) {
      debugPrint('AppOpen 광고 표시 결과: $shown');
    }).catchError((error) {
      debugPrint('AppOpen 광고 표시 실패: $error');
    });
  }

  void _navigateToNextScreen(Map<String, dynamic>? profile) {
    if (profile != null) {
      try {
        final name = profile['name'] as String? ?? '';
        final birthDate = DateTime.parse(profile['birthDate'] as String);
        final hour = (profile['hour'] as num).toInt();
        final minute = (profile['minute'] as num).toInt();
        final gender = profile['gender'] as String? ?? '남성';
        final isLunar = profile['isLunar'] as bool? ?? false;

        final sajuChars = SajuCalculator.instance.calculateSaju(
          birthDate: birthDate,
          hour: hour,
          minute: minute,
          isLunar: isLunar,
          gender: gender,
        );

        // 선택 항목들도 불러오기
        final maritalStatus = profile['maritalStatus'] as String?;
        final city = profile['city'] as String?;
        final bloodType = profile['bloodType'] as String?;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => YulhyunChatbotScreen(
              name: name,
              birthDate: birthDate,
              birthTime: TimeOfDay(hour: hour, minute: minute),
              gender: gender,
              isLunar: isLunar,
              sajuChars: sajuChars,
              maritalStatus: maritalStatus,
              city: city,
              bloodType: bloodType,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
        return;
      } catch (e) {
        debugPrint('프로필 파싱 실패: $e');
      }
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SajuInputScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0E1A),
              Color(0xFF101426),
              Color(0xFF12162A),
              Color(0xFF0D1021),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 상징 아이콘 (글로우)
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0x33D4AF37), Color(0x11000000)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x66D4AF37),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: FaIcon(FontAwesomeIcons.yinYang, size: 64, color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '율현 법사',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '신내림 받은 율현법사와\n당신의 운명에 대해서 얘기해보세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
