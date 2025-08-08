import 'package:flutter/material.dart';
import 'dart:async';
import 'saju_input_screen.dart';
import '../services/storage_service.dart';
import '../services/saju_calculator.dart';
import '../models/saju_chars.dart';
import 'yulhyun_chatbot_screen.dart';

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
    
    _startAnimations();
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _scaleController.forward();
    
    Timer(const Duration(seconds: 3), () async {
      final profile = await StorageService.instance.getSajuProfile();
      if (!mounted) return;
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

          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => YulhyunChatbotScreen(
                name: name,
                birthDate: birthDate,
                birthTime: TimeOfDay(hour: hour, minute: minute),
                gender: gender,
                isLunar: isLunar,
                sajuChars: sajuChars,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
          return;
        } catch (_) {}
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
    });
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
      backgroundColor: const Color(0xFF1A237E), // 진한 인디고 색상
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 아이콘
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    size: 60,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 32),
                
                // 앱 제목
                const Text(
                  '율현 법사',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                
                // 부제목
                const Text(
                  'AI 기반 사주 상담',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 48),
                
                // 로딩 인디케이터
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
