import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/supabase_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/ad_service.dart';
import 'screens/splash_screen.dart';
import 'screens/saju_input_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize Supabase
    await SupabaseService.initialize();
    
    // Initialize Storage Service
    await StorageService.instance.initialize();
    
    // Initialize Auth Service
    await AuthService.instance.initialize();
    
    // Initialize Ad Service
    await AdService.instance.initialize();
    
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
      title: '율현 법사 - 오류',
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
      title: '율현 법사',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Noto Sans KR',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      home: const SplashScreen(),
      routes: {
        '/saju-input': (context) => const SajuInputScreen(),
      },
    );
  }
}
