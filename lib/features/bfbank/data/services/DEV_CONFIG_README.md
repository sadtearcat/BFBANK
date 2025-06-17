# 🛠️ BFBANK 개발용 더미데이터 설정 가이드

## 📋 개요
`DevConfig` 클래스를 통해 앱의 모든 더미데이터와 개발용 기능을 간편하게 활성화/비활성화할 수 있습니다.

## 🎯 주요 설정

### 1. 더미데이터 제어
```dart
// 전체 더미데이터 마스터 스위치 (false시 모든 더미데이터 비활성화)
static const bool enableDummyData = true;

// 개별 더미데이터 제어
static const bool enableDummyUser = true;              // 사용자 정보
static const bool enableDummyAccount = true;           // 계좌 정보
static const bool enableDummyTransactionHistory = true; // 거래 내역
static const bool enableDummyFavoriteAccounts = true;  // 즐겨찾기 계좌
static const bool enableDummySettings = true;          // 설정
static const bool enableDummyBankList = true;          // 은행 목록
```

### 2. 개발용 기능 제어
```dart
static const bool enableAutoLogin = true;              // 자동 로그인
static const bool enableAutoAccountAssignment = true;  // 자동 계좌 부여
static const bool enableDebugLogs = true;              // 디버그 로그
static const int apiSimulationDelay = 500;             // API 딜레이 (밀리초)
```

## 🚀 사용 시나리오

### 시나리오 1: 실제 API 테스트
```dart
// dev_config.dart에서 다음과 같이 설정
static const bool enableDummyData = false;  // 모든 더미데이터 비활성화
```

### 시나리오 2: 특정 기능만 테스트
```dart
// 거래 내역만 더미데이터 사용, 나머지는 실제 API
static const bool enableDummyData = true;
static const bool enableDummyUser = false;
static const bool enableDummyAccount = false;
static const bool enableDummyTransactionHistory = true;  // 이것만 활성화
static const bool enableDummyFavoriteAccounts = false;
```

### 시나리오 3: 빠른 개발/테스트
```dart
// 모든 더미데이터 활성화 + 빠른 API 응답
static const bool enableDummyData = true;
static const bool enableAutoLogin = true;
static const bool enableAutoAccountAssignment = true;
static const int apiSimulationDelay = 100;  // 빠른 응답
```

### 시나리오 4: 실제 환경 시뮬레이션
```dart
// 모든 더미데이터 활성화 + 실제와 같은 API 딜레이
static const bool enableDummyData = true;
static const int apiSimulationDelay = 2000;  // 실제와 같은 느린 응답
```

## 📊 더미데이터 현황

### 사용자 정보
- 홍길동 (010-1234-5678)
- 생년월일: 1990-05-15
- 가입일: 2024-01-01

### 계좌 정보
- 계좌번호: 1102620007201 (우리은행)
- 잔액: 1,500,000원
- 일일이체한도: 1,000,000원
- 1회이체한도: 500,000원

### 거래 내역
- **15개의 풍부한 거래 내역**
- 8개 은행 (우리, 국민, 신한, 하나, KB, 농협, 기업, 우체국)
- 시간대별 분류: 최근/지난주/지난달
- 입금/출금 다양한 패턴

### 즐겨찾기 계좌
- 4개의 자주 사용하는 계좌
- 사용 빈도별 정렬
- 최근 거래일 포함

## 🔧 개발 팁

### 1. 로그 확인
앱 시작 시 콘솔에서 현재 설정 상태를 확인할 수 있습니다:
```
=== BFBANK 개발 환경 설정 ===
전체 더미데이터: 활성화
사용자 정보: 활성화
계좌 정보: 활성화
...
==============================
```

### 2. 런타임 확인
```dart
// 코드에서 현재 설정 확인
if (DevConfig.shouldUseDummyData('user')) {
  // 더미 사용자 데이터 사용
}

// 디버그 로그 출력
DevConfig.debugLog('사용자 정보 로드 완료');
```

### 3. API 딜레이 시뮬레이션
```dart
// 모든 API 호출에서 설정된 딜레이 적용
await DevConfig.simulateApiDelay();
```

## ⚠️ 주의사항

1. **프로덕션 빌드 전 확인**: 배포 전에는 반드시 `enableDummyData = false`로 설정
2. **계좌 자동 부여**: `enableAutoAccountAssignment = false`시 계좌 생성 과정 필요
3. **API 딜레이**: 실제 서버 응답 시간과 유사하게 설정하여 UX 테스트
4. **로그 비활성화**: 성능 테스트 시 `enableDebugLogs = false` 권장

## 🔄 설정 변경 후 적용

설정 변경 후 **Hot Restart** (Ctrl+Shift+F5)를 수행하여 변경사항을 적용하세요.
Hot Reload로는 const 값 변경이 적용되지 않습니다.

---

💡 **빠른 설정 변경**: `dev_config.dart` 파일의 상단 설정 값들만 수정하면 됩니다! 