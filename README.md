# 📱 사주플래너 (가칭)
**내 사주에 맞는 길일을 추천받고, 중요한 날엔 자동으로 알림까지 받는 운세 기반 라이프 플래너**

## ✅ 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 플랫폼 | Flutter (Android/iOS) |
| 백엔드 | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| 분석 엔진 | Azure OpenAI API (gpt-4o 기반 사주 해석 및 길일 추천) |
| 핵심 기능 | 사주 입력 → AI 분석 → 길일 추천 → 알림 제공 |
| 주요 사용자 | 사주, 운세, 자기관리, 계획에 관심 있는 20~40대 일반 사용자 |

## ✅ 2. 핵심 기능 상세

### ① 사용자 정보 입력
- 이름 (선택)
- 생년월일 (양력/음력 선택)
- 태어난 시각 (24시간제)
- 성별

### ② 8자(四柱) 자동 계산
- 년주, 월주, 일주, 시주를 계산
- 간지 구성 예: 갑인 / 병진 / 무오 / 정축
- Flutter 앱 내 로컬 계산 (천간/지지 알고리즘 탑재)

### ③ Azure OpenAI 기반 사주 분석
- Azure OpenAI API(gpt-4o)에 프롬프트 전송
- 분석 항목:
  - 성격 요약
  - 재물운, 직업운, 건강운, 애정운
  - 조심할 시기
  - 향후 3개월 길일 추천 (이사, 계약, 시험 등 목적별)
- 결과는 analysis_result에 JSON/Text 형태로 저장

### ④ 캘린더 및 길일 알림
- AI가 추천한 길일을 앱 캘린더에 자동 저장
- 사용자 커스텀 일정도 추가 가능
- 알림 예약:
  - 당일, 하루 전, 일주일 전 선택 가능
  - Firebase Cloud Messaging(FCM) + Supabase Edge Function 사용

## ✅ 3. 기술 스택

| 영역 | 기술 |
|------|------|
| 프론트엔드 | Flutter |
| 백엔드 | Supabase (PostgreSQL, Edge Function, Auth) |
| 사주 엔진 | Azure OpenAI API (gpt-4o) |
| 알림 | Firebase Cloud Messaging (FCM) |
| 날짜 변환 | 천간지지, 음양력 변환 로직 직접 구현 or 오픈소스 활용 |
| 인증 | Supabase Auth (이메일, Google OAuth 등) |

## ✅ 4. 데이터베이스 구조 (Supabase)

### (1) users
| 필드 | 타입 | 설명 |
|------|------|------|
| id | uuid | 고유 사용자 ID |
| email | text | 이메일 |
| created_at | timestamp | 가입일 |

### (2) saju_profiles
| 필드 | 타입 | 설명 |
|------|------|------|
| id | uuid | 고유 ID |
| user_id | uuid | users FK |
| name | text | 이름 |
| birth_date | date | 생년월일 |
| birth_time | time | 태어난 시각 |
| lunar | boolean | 음력 여부 |
| gender | text | 성별 |
| saju_8chars | jsonb | 년주~시주 8자 |
| analysis_result | text/jsonb | GPT 분석 결과 저장 |
| created_at | timestamp | 생성일 |

### (3) good_days
| 필드 | 타입 | 설명 |
|------|------|------|
| id | uuid | 고유 ID |
| user_id | uuid | users FK |
| saju_profile_id | uuid | 분석 기반 참조 |
| title | text | 추천 목적 (ex. 시험, 이사) |
| date | date | 추천 길일 |
| type | enum | GOOD / BAD |
| reason | text | 추천 사유 |
| created_at | timestamp | 생성일 |

### (4) notifications
| 필드 | 타입 | 설명 |
|------|------|------|
| id | uuid | 고유 ID |
| user_id | uuid | users FK |
| good_day_id | uuid | 길일 참조 |
| notify_at | timestamp | 알림 예정 시간 |
| sent | boolean | 발송 여부 |

## ✅ 5. 사용자 흐름 (UX Flow)

```
[회원가입/Login]
      ↓
[사주 입력 (생년월일, 성별, 태어난 시)]
      ↓
[8자 자동 계산 + GPT 분석 요청]
      ↓
[사주 분석 결과 요약 화면 표시]
      ↓
[길일 추천 확인 + 캘린더 저장]
      ↓
[알림 설정]
      ↓
[캘린더 및 알림 수신]
```

## ✅ 6. UI 주요 구성 (기획 시안 기준)

| 화면 | 구성 |
|------|------|
| 홈 | 오늘의 길일 요약, 사주 요약 카드 |
| 사주 입력 | 생일, 시각, 성별, 음양력 입력 폼 |
| 분석 결과 | 성격/운세 요약, GPT 출력 정리 |
| 길일 캘린더 | 월별 보기, 목적별 필터링 |
| 알림 설정 | 길일 전날/당일 알림 선택 |
| 마이페이지 | 사주 수정, 재분석, 로그아웃 등 |

## ✅ 7. 개발 일정 예시

| 기간 | 단계 | 주요 작업 |
|------|------|----------|
| 1주차 | 설계 | 화면 흐름도, DB 설계, API 명세 |
| 2~3주차 | 기본 Flutter UI 개발 | 사주 입력, 결과 화면 구현 |
| 4주차 | Supabase 연동 | Auth + DB CRUD |
| 5주차 | Azure OpenAI 연동 로직 | 사주 분석 프롬프트 설계 및 결과 처리 |
| 6주차 | 캘린더 및 알림 기능 구현 | 길일 저장, FCM 연결, Edge Function |
| 7주차 | QA 및 Play Store 배포 준비 | 오류 수정, 알림 테스트 등 |

## ✅ 8. 확장 가능성 (향후 플랜)

- 프리미엄 상품: 상세 리포트, PDF 다운로드, 무제한 분석
- AI 챗봇 상담: ChatGPT 연동으로 1:1 사주 상담
- 친구 사주 보기/공유 기능
- 명리학 기반 심화분석 (대운, 세운 등) 