import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'dart:async';

/// 실제 AdMob SDK를 사용하는 광고 서비스 클래스
class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();
  
  bool _isInitialized = false;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;
  AppOpenAd? _appOpenAd;
  
  // 실제 AdMob 광고 단위 ID
  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3786451504514591/7213959158'; // Android 보상형 광고 실제 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS 보상형 광고 테스트 ID (iOS 실제 ID로 교체 필요)
    } else {
      return 'ca-app-pub-3786451504514591/7213959158'; // 기본값
    }
  }

  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3786451504514591/3270280064'; // Android 배너 광고 실제 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS 배너 광고 테스트 ID (iOS 실제 ID로 교체 필요)
    } else {
      return 'ca-app-pub-3786451504514591/3270280064'; // 기본값
    }
  }

  String get _appOpenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3786451504514591/2304714577'; // Android App Open 광고 실제 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5575463023'; // iOS App Open 광고 테스트 ID (iOS 실제 ID로 교체 필요)
    } else {
      return 'ca-app-pub-3786451504514591/2304714577';
    }
  }
  
  /// 광고 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔄 광고 서비스 초기화 시작...');
      
      // 테스트 기기 설정 (모든 기기에서 테스트 광고가 표시되도록)
      final RequestConfiguration configuration = RequestConfiguration(
        testDeviceIds: <String>[], // 빈 리스트는 모든 기기를 테스트 기기로 처리
      );
      MobileAds.instance.updateRequestConfiguration(configuration);
      
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ 광고 서비스 초기화 완료 (테스트 모드)');
    } catch (e) {
      debugPrint('❌ 광고 서비스 초기화 실패: $e');
    }
  }
  
  // 배너 광고 로드
  Future<BannerAd?> loadBannerAd() async {
    if (!_isInitialized) {
      debugPrint('🔄 광고 초기화 필요, 초기화 중...');
      await initialize();
    }
    try {
      debugPrint('🔄 배너 광고 로드 시작...');
      debugPrint('📱 플랫폼: ${Platform.operatingSystem}');
      debugPrint('🆔 배너 광고 단위 ID: $_bannerAdUnitId');
      
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('✅ 배너 광고 로드 완료');
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ 배너 광고 로드 실패: $error');
            debugPrint('🔍 에러 코드: ${error.code}');
            debugPrint('🔍 에러 메시지: ${error.message}');
            debugPrint('🔍 에러 도메인: ${error.domain}');
            ad.dispose();
            _bannerAd = null;
          },
          onAdOpened: (ad) {
            debugPrint('🖱️ 배너 광고 클릭됨');
          },
          onAdClosed: (ad) {
            debugPrint('🔚 배너 광고 닫힘');
          },
        ),
      );
      
      await _bannerAd!.load();
      debugPrint('✅ 배너 광고 로드 완료');
      return _bannerAd;
    } catch (e) {
      debugPrint('❌ 배너 광고 로드 중 오류: $e');
      _bannerAd = null;
      return null;
    }
  }

  // 배너 광고 위젯 생성
  Widget? getBannerAdWidget() {
    if (_bannerAd == null) {
      debugPrint('⚠️ 배너 광고가 로드되지 않았습니다.');
      return null;
    }
    debugPrint('🎨 배너 광고 위젯 생성');
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// 보상형 광고 로드
  Future<void> loadRewardedAd() async {
    if (!_isInitialized) {
      debugPrint('🔄 광고 초기화 필요, 초기화 중...');
      await initialize();
    }
    
    // 기존 광고가 있다면 dispose
    _rewardedAd?.dispose();
    _rewardedAd = null;
    
    final completer = Completer<void>();
    
    try {
      debugPrint('🔄 보상형 광고 로드 시작...');
      debugPrint('📱 플랫폼: ${Platform.operatingSystem}');
      debugPrint('🆔 광고 단위 ID: $_rewardedAdUnitId');
      
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(
          keywords: ['games', 'entertainment'],
          nonPersonalizedAds: false,
        ),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            debugPrint('✅ 보상형 광고 로드 완료');
            _rewardedAd = ad;
            
            // 광고 이벤트 콜백 설정
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (RewardedAd ad) {
                debugPrint('🎬 광고가 전체 화면으로 표시됨');
              },
              onAdImpression: (RewardedAd ad) {
                debugPrint('👁️ 광고 인상 발생');
              },
              onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
                debugPrint('❌ 광고 표시 실패: $error');
                ad.dispose();
                _rewardedAd = null;
              },
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                debugPrint('🔚 광고가 닫힘');
                ad.dispose();
                _rewardedAd = null;
              },
              onAdClicked: (RewardedAd ad) {
                debugPrint('🖱️ 광고 클릭됨');
              },
            );
            
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('❌ 보상형 광고 로드 실패: $error');
            debugPrint('🔍 에러 코드: ${error.code}');
            debugPrint('🔍 에러 메시지: ${error.message}');
            debugPrint('🔍 에러 도메인: ${error.domain}');
            _rewardedAd = null;
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
      
      // 로드 완료까지 대기
      await completer.future;
      
    } catch (e) {
      debugPrint('❌ 보상형 광고 로드 중 오류: $e');
      _rewardedAd = null;
      if (!completer.isCompleted) completer.complete();
    }
  }
  
  /// 보상형 광고 표시
  Future<bool> showRewardedAd() async {
    debugPrint('🔄 광고 표시 시작...');
    debugPrint('📊 광고 로드 상태: ${_rewardedAd != null ? "로드됨" : "로드되지 않음"}');
    if (_rewardedAd == null) {
      debugPrint('⚠️ 광고가 로드되지 않았습니다. 다시 로드합니다.');
      await loadRewardedAd();
      if (_rewardedAd == null) {
        debugPrint('❌ 광고 로드에 실패했습니다.');
        return false;
      }
    }

    try {
      bool rewardEarned = false;
      final completer = Completer<bool>();

      // 화면 표시 콜백을 이 시점에 재설정해 결과를 보장
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedAd ad) {
          debugPrint('🎬 광고 전체 화면 표시');
        },
        onAdImpression: (RewardedAd ad) {
          debugPrint('👁️ 광고 인상 발생');
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          debugPrint('❌ 광고 표시 실패: $error');
          ad.dispose();
          if (!completer.isCompleted) completer.complete(false);
        },
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          debugPrint('🔚 광고가 닫힘');
          ad.dispose();
          if (!completer.isCompleted) completer.complete(rewardEarned);
        },
        onAdClicked: (RewardedAd ad) {
          debugPrint('🖱️ 광고 클릭됨');
        },
      );

      debugPrint('🎬 광고 표시 시도...');
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
          debugPrint('🎁 보상 획득: ${rewardItem.amount} ${rewardItem.type}');
          rewardEarned = true;
        },
      );

      final result = await completer.future;
      debugPrint('✅ 광고 표시 종료, 보상 여부: $result');
      return result;
    } catch (e) {
      debugPrint('❌ 보상형 광고 표시 실패: $e');
      return false;
    }
  }

  // App Open Ad 로드
  Future<bool> loadAppOpenAd() async {
    if (!_isInitialized) {
      await initialize();
    }
    final completer = Completer<bool>();
    debugPrint('🔄 AppOpen 광고 로드 시작... ($_appOpenAdUnitId)');
    try {
      await AppOpenAd.load(
        adUnitId: _appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ AppOpen 광고 로드 완료');
            _appOpenAd = ad;
            completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ AppOpen 광고 로드 실패: $error');
            _appOpenAd = null;
            completer.complete(false);
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ AppOpen 광고 로드 중 오류: $e');
      _appOpenAd = null;
      completer.complete(false);
    }
    return completer.future;
  }

  // App Open Ad 표시
  Future<bool> showAppOpenAd() async {
    if (_appOpenAd == null) {
      final loaded = await loadAppOpenAd();
      if (!loaded || _appOpenAd == null) return false;
    }
    final completer = Completer<bool>();
    try {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) => debugPrint('🎬 AppOpen 표시'),
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('❌ AppOpen 표시 실패: $error');
          ad.dispose();
          _appOpenAd = null;
          if (!completer.isCompleted) completer.complete(false);
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('🔚 AppOpen 닫힘');
          ad.dispose();
          _appOpenAd = null;
          if (!completer.isCompleted) completer.complete(true);
        },
      );
      _appOpenAd!.show();
    } catch (e) {
      debugPrint('❌ AppOpen 표시 중 오류: $e');
      _appOpenAd = null;
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }
  
  /// 광고 로드 상태 확인
  bool get isAdLoaded => _rewardedAd != null;
  bool get isBannerAdLoaded => _bannerAd != null;
  
  /// 광고 정리
  void dispose() {
    debugPrint('🗑️ 광고 정리 중...');
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _bannerAd?.dispose();
    _bannerAd = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
} 
