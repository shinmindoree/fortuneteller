# 사주플래너 앱 설정 가이드

## 환경변수 설정

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=your_azure_openai_endpoint_here
AZURE_OPENAI_API_KEY=your_azure_openai_api_key_here
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# Firebase Configuration (if needed)
FIREBASE_PROJECT_ID=your_firebase_project_id_here
```

## 필요한 설정

### 1. Supabase 설정
1. [Supabase](https://supabase.com)에서 새 프로젝트 생성
2. Project Settings > API에서 URL과 anon key 복사
3. `.env` 파일에 추가

### 2. Azure OpenAI API 설정
1. [Azure Portal](https://portal.azure.com)에서 OpenAI 리소스 생성
2. OpenAI Studio에서 모델 배포 (예: gpt-4, gpt-35-turbo)
3. Keys and Endpoint에서 엔드포인트와 API 키 복사
4. 배포한 모델의 deployment name 확인
5. `.env` 파일에 추가

### 3. Firebase 설정 (FCM용)
1. [Firebase Console](https://console.firebase.google.com)에서 프로젝트 생성
2. Android 앱 추가
3. `google-services.json` 파일을 `android/app/` 폴더에 추가

## 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점
├── models/               # 데이터 모델들
├── services/             # API 서비스들
├── screens/              # 화면/페이지들
├── widgets/              # 재사용 가능한 위젯들
├── utils/                # 유틸리티 함수들
└── providers/            # 상태 관리 프로바이더들
```

## 실행 방법

```bash
flutter pub get
flutter run
``` 