import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'dart:async'; // Added for Completer

/// 실제 AdMob SDK를 사용하는 광고 서비스 클래스
class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();
  
  bool _isInitialized = false;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;
  
  // 테스트 광고 단위 ID
  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android 테스트 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS 테스트 ID
    } else {
      return 'ca-app-pub-3940256099942544/5224354917'; // 기본값
    }
  }

  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android 배너 테스트 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS 배너 테스트 ID
    } else {
      return 'ca-app-pub-3940256099942544/6300978111'; // 기본값
    }
  }
  
  /// 광고 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔄 광고 서비스 초기화 시작...');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ 광고 서비스 초기화 완료');
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
    return Container(
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
    
    try {
      debugPrint('🔄 보상형 광고 로드 시작...');
      debugPrint('📱 플랫폼: ${Platform.operatingSystem}');
      debugPrint('🆔 광고 단위 ID: $_rewardedAdUnitId');
      
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
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
              },
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                debugPrint('🔚 광고가 닫힘');
                ad.dispose();
              },
              onAdClicked: (RewardedAd ad) {
                debugPrint('🖱️ 광고 클릭됨');
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('❌ 보상형 광고 로드 실패: $error');
            debugPrint('🔍 에러 코드: ${error.code}');
            debugPrint('🔍 에러 메시지: ${error.message}');
            debugPrint('🔍 에러 도메인: ${error.domain}');
            _rewardedAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ 보상형 광고 로드 중 오류: $e');
      _rewardedAd = null;
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
  }
} 
