# 📱 Flutter 앱 배포 시행착오 및 해결방법

> 실제 프로젝트에서 겪은 배포 과정의 문제점들과 해결책을 정리한 문서입니다.

## 🚨 주요 시행착오 목록

### 1. 빌드 에러 관련

#### ❌ 문제: 중복 메서드 선언 오류
```
Error: '_submitForm' is already declared in this scope.
Error: '_calculateAndShowSaju' is already declared in this scope.
```

**원인**: 코드 리팩토링 과정에서 메서드가 중복 생성됨

**해결**: 
```dart
// 기존 메서드 완전 삭제 후 새 메서드만 유지
void _submitForm() async { // 새 버전만 유지
  // 구현
}
```

#### ❌ 문제: InputDecoration 속성 오류
```
Error: No named parameter with the name 'color' in InputDecoration
```

**원인**: `InputDecoration`과 `BoxDecoration`의 속성 혼동

**해결**:
```dart
// ❌ 잘못된 사용
InputDecoration(
  color: Color(0x22FFFFFF), // InputDecoration에는 color 없음
)

// ✅ 올바른 사용
InputDecoration(
  fillColor: Color(0x22FFFFFF), // fillColor 사용
  filled: true,
)
```

#### ❌ 문제: StorageService 매개변수 타입 불일치
```
Error: Too many positional arguments: 0 allowed, but 1 found
```

**원인**: named parameter를 받는 메서드에 Map 전달

**해결**:
```dart
// 오버로드 메서드 추가
Future<bool> saveSajuProfileMap(Map<String, dynamic> profileData) async {
  // Map을 직접 받아서 처리
}
```

---

### 2. AdMob 통합 관련

#### ❌ 문제: google_mobile_ads 버전 호환성
```
Error: Couldn't find constructor 'RewardedAd'
```

**원인**: 
- google_mobile_ads 버전별 API 변화
- v4.0.0 → v6.0.0으로 업그레이드 시 API 완전 변경

**해결**:
```dart
// v6.0.0 API 사용
RewardedAd.load(
  adUnitId: adUnitId,
  request: AdRequest(),
  rewardedAdLoadCallback: RewardedAdLoadCallback(
    onAdLoaded: (ad) => _rewardedAd = ad,
    onAdFailedToLoad: (error) => debugPrint('Failed: $error'),
  ),
);
```

#### ❌ 문제: minSdkVersion 충돌
```
Error: minSdkVersion 21 cannot be smaller than version 23 declared in library [:google_mobile_ads]
```

**해결**:
```kotlin
// android/app/build.gradle.kts
defaultConfig {
    minSdk = 23  // 21에서 23으로 변경
}
```

#### ❌ 문제: 광고 로드 실패
```
LoadAdError(code: 3, domain: com.google.android.gms.ads, message: Ad unit doesn't match format)
```

**원인**: 잘못된 테스트 ID 사용

**해결**:
```dart
// 올바른 Google 공식 테스트 ID 사용
const String testRewardedId = "ca-app-pub-3940256099942544/5224354917";
```

#### ❌ 문제: 첫 번째 클릭에서 보상형 광고 로드 실패, 두 번째부터 성공
```
첫 번째: ✅ 광고 로드 완료 → 📊 광고 로드 상태: 로드되지 않음 → ❌ 광고 시청 실패
두 번째: ✅ 광고 로드 완료 → 📊 광고 로드 상태: 로드됨 → ✅ 광고 시청 성공
```

**원인**: 
- `RewardedAd.load()`는 비동기 콜백을 사용하는데, `await`가 콜백 완료를 기다리지 않음
- `loadRewardedAd()` 함수가 완료되어도 실제로는 `_rewardedAd` 변수가 아직 설정되지 않았을 수 있음

**해결**:
```dart
// AdService의 loadRewardedAd() 메서드 수정
Future<void> loadRewardedAd() async {
  // 기존 광고 정리
  _rewardedAd?.dispose();
  _rewardedAd = null;
  
  final completer = Completer<void>();
  
  await RewardedAd.load(
    adUnitId: _rewardedAdUnitId,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (RewardedAd ad) {
        _rewardedAd = ad;
        if (!completer.isCompleted) completer.complete(); // 완료 신호
      },
      onAdFailedToLoad: (LoadAdError error) {
        _rewardedAd = null;
        if (!completer.isCompleted) completer.complete(); // 실패해도 완료
      },
    ),
  );
  
  // 콜백이 실제로 완료될 때까지 대기
  await completer.future;
}
```

---

### 3. Android 빌드 설정 관련

#### ❌ 문제: 키스토어 파일 경로 오류
```
Error: Keystore file 'upload-keystore.jks ' not found
```

**원인**: key.properties 파일에 공백 문자 포함

**해결**:
```properties
# key.properties - 공백 제거
storeFile=upload-keystore.jks
# storeFile=upload-keystore.jks  (끝에 공백 있으면 안됨)
```

#### ❌ 문제: 패키지명 제한 오류
```
Error: 'com.example'은(는) 제한되어 있으므로 다른 패키지 이름을 사용해야 합니다.
```

**원인**: Google Play에서 example 패키지명 금지

**해결**:
```kotlin
// android/app/build.gradle.kts
android {
    namespace = "kr.fortuneteller"
    defaultConfig {
        applicationId = "kr.fortuneteller"
    }
}
```

**주의**: 패키지명 변경 시 모든 관련 파일 수정 필요
- MainActivity.kt 파일 위치 및 패키지 선언
- google-services.json의 package_name
- 폴더 구조 변경

#### ❌ 문제: MainActivity 클래스 찾을 수 없음
```
ClassNotFoundException: Didn't find class "kr.fortuneteller.MainActivity"
```

**원인**: 패키지명 변경 후 파일 위치 불일치

**해결**:
```bash
# 올바른 폴더 구조
android/app/src/main/kotlin/kr/fortuneteller/MainActivity.kt

# MainActivity.kt 내용
package kr.fortuneteller
import io.flutter.embedding.android.FlutterActivity
class MainActivity: FlutterActivity() {}
```

---

### 4. Firebase/Google Services 관련

#### ❌ 문제: google-services.json 패키지명 불일치
```
Error: No matching client found for package name 'kr.fortuneteller'
```

**원인**: Firebase 프로젝트에 새 패키지명이 등록되지 않음

**해결**:
1. Firebase Console에서 Android 앱 추가
2. 새 패키지명 등록: `kr.fortuneteller`
3. 새 google-services.json 다운로드 및 교체

#### ❌ 문제: 환경변수 파일 누락으로 인한 크래시
```
Exception: .env 파일을 찾을 수 없습니다
```

**원인**: 릴리즈 빌드에는 .env 파일이 포함되지 않음

**해결**:
```dart
// 안전한 환경변수 로딩
try {
  await dotenv.load(fileName: ".env");
} catch (e) {
  debugPrint('Environment file not found: $e');
  // 로컬 모드로 fallback
}

// 서비스별 안전장치
if (!OpenAIService.instance.isConfigured) {
  return '일시적으로 서비스를 이용할 수 없습니다.';
}
```

---

### 5. Play Console 업로드 관련

#### ❌ 문제: 서명 키 불일치
```
Error: 업로드한 AAB가 "Play Console에 등록된 업로드 키"와 다른 키로 서명되어 있습니다.
```

**원인**: 
- 키스토어 파일 변경
- SHA1 지문 불일치

**해결**:
```bash
# 현재 키스토어의 SHA1 확인
keytool -list -v -keystore upload-keystore.jks -alias upload

# Play Console에서 SHA1 지문 업데이트 또는
# 동일한 키스토어 계속 사용
```

#### ❌ 문제: 버전 코드 중복
```
Error: 3 버전 코드는 이미 사용되었습니다.
```

**해결**:
```yaml
# pubspec.yaml - 버전 코드 증가
version: 1.0.0+4  # +뒤 숫자를 계속 증가
```

#### ❌ 문제: 앱 크래시로 인한 정책 위반
```
Play Console: 손상된 기능 정책 위반
```

**원인**: 
- 릴리즈 환경에서 환경변수 누락
- Supabase/Auth 서비스 초기화 실패

**해결**:
```dart
// 모든 외부 서비스에 fallback 로직 추가
class AuthService {
  static AuthService? _instance;
  
  static AuthService get instance {
    try {
      return _instance ??= AuthService._();
    } catch (e) {
      return LocalAuthService(); // 로컬 전용 대체 서비스
    }
  }
}
```

---

### 6. 의존성 및 버전 관리

#### ❌ 문제: Flutter 버전 호환성
```
Error: The argument type 'CardTheme' can't be assigned to 'CardThemeData?'
```

**원인**: Flutter 3.32에서 API 변경

**해결**:
```dart
// 변경 전
theme: ThemeData(
  cardTheme: CardTheme(...),
  dialogTheme: DialogTheme(...),
)

// 변경 후
theme: ThemeData(
  cardTheme: CardThemeData(...),
  dialogTheme: DialogThemeData(...),
)
```

#### ❌ 문제: 의존성 충돌
```
Error: intl 버전 충돌
```

**해결**:
```yaml
dependencies:
  intl: ^0.20.2  # 명시적 버전 지정

dependency_overrides:
  intl: ^0.20.2  # 강제 버전 고정
```

---

## 🛠️ 예방을 위한 Best Practices

### 1. 개발 단계
```dart
// 환경별 설정 분리
class Config {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const String apiUrl = isProduction 
    ? 'https://api.production.com'
    : 'https://api.dev.com';
}
```

### 2. 빌드 전 체크리스트
```bash
# 빌드 전 검증 스크립트
flutter analyze              # 정적 분석
flutter test                # 단위 테스트
flutter build apk --debug   # 디버그 빌드 테스트
flutter build appbundle --release  # 릴리즈 빌드
```

### 3. 버전 관리
```yaml
# 체계적인 버전 관리
version: 1.0.0+4
# major.minor.patch+buildNumber
# 기능 추가시: minor 증가
# 버그 수정시: patch 증가
# 매 업로드시: buildNumber 증가
```

### 4. 키스토어 관리
```bash
# 키스토어 백업 (중요!)
cp upload-keystore.jks ~/secure-backup/
cp key.properties ~/secure-backup/

# SHA1 지문 기록
keytool -list -v -keystore upload-keystore.jks -alias upload > keystore-info.txt
```

### 5. AdMob 설정 검증
```dart
class AdService {
  bool get isTestMode => kDebugMode;
  
  String get rewardedAdUnitId {
    return isTestMode 
      ? 'ca-app-pub-3940256099942544/5224354917'  // Google 공식 테스트 ID
      : 'ca-app-pub-실제ID/실제단위ID';
  }
}
```

---

## 📝 릴리즈 전 최종 점검 사항

### 필수 확인 리스트
- [ ] 모든 테스트 ID를 실제 ID로 변경
- [ ] .env 파일 의존성 제거 또는 fallback 로직 추가
- [ ] 패키지명 일치성 확인 (5개 위치)
- [ ] 키스토어 파일 백업 완료
- [ ] 버전 코드 증가
- [ ] 릴리즈 빌드 성공 확인
- [ ] 크래시 없음 확인

### 패키지명 확인 위치
1. `android/app/build.gradle.kts` (applicationId, namespace)
2. `android/app/src/main/kotlin/패키지경로/MainActivity.kt`
3. `android/app/google-services.json` (package_name)
4. Firebase Console 설정
5. Play Console 앱 등록

---

## 🔍 디버깅 팁

### 로그 확인 방법
```bash
# Android 로그 실시간 확인
adb logcat | grep -i flutter

# 크래시 로그 확인
adb logcat | grep -i "crash\|exception\|error"
```

### 빌드 문제 해결
```bash
# 캐시 정리
flutter clean
flutter pub get

# Gradle 캐시 정리
cd android
./gradlew clean

# 최종 빌드
flutter build appbundle --release --verbose
```

---

**💡 핵심 교훈**: 
1. **테스트 환경과 프로덕션 환경의 차이**를 항상 고려
2. **백업**은 선택이 아닌 필수 (특히 키스토어)
3. **버전 관리**를 체계적으로 수행
4. **외부 서비스 의존성**에 대한 fallback 로직 필수
5. **패키지명 일치성**을 여러 위치에서 확인

이 문서를 참조하여 향후 앱 배포 시 동일한 실수를 반복하지 않도록 주의하세요! 🚀

