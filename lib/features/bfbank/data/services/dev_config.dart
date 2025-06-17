/// 개발용 더미데이터 설정 관리
/// 각 기능별로 더미데이터 사용 여부를 간편하게 제어할 수 있습니다.
class DevConfig {
  // =============================================================================
  // 🛠️ 개발용 더미데이터 활성화/비활성화 설정
  // =============================================================================
  
  /// 전체 더미데이터 활성화 (마스터 스위치)
  static const bool enableDummyData = true;
  
  /// 사용자 정보 더미데이터
  static const bool enableDummyUser = true;
  
  /// 계좌 정보 더미데이터  
  static const bool enableDummyAccount = true;
  
  /// 거래 내역 더미데이터
  static const bool enableDummyTransactionHistory = true;
  
  /// 즐겨찾기 계좌 더미데이터
  static const bool enableDummyFavoriteAccounts = true;
  
  /// 설정 더미데이터
  static const bool enableDummySettings = true;
  
  /// 은행 목록 더미데이터
  static const bool enableDummyBankList = true;
  
  // =============================================================================
  // 🎯 개발용 기능 설정
  // =============================================================================
  
  /// 자동 로그인 (로그인 화면 건너뛰기)
  static const bool enableAutoLogin = true;
  
  /// 더미 계좌 자동 부여
  static const bool enableAutoAccountAssignment = true;
  
  /// 개발용 디버그 로그 출력
  static const bool enableDebugLogs = true;
  
  /// API 호출 시뮬레이션 딜레이 (밀리초)
  static const int apiSimulationDelay = 500;
  
  // =============================================================================
  // 🔧 헬퍼 메서드
  // =============================================================================
  
  /// 더미데이터 사용 여부 확인
  static bool shouldUseDummyData(String dataType) {
    if (!enableDummyData) return false;
    
    switch (dataType) {
      case 'user':
        return enableDummyUser;
      case 'account':
        return enableDummyAccount;
      case 'transaction':
        return enableDummyTransactionHistory;
      case 'favorite':
        return enableDummyFavoriteAccounts;
      case 'settings':
        return enableDummySettings;
      case 'bank':
        return enableDummyBankList;
      default:
        return enableDummyData;
    }
  }
  
  /// 개발용 로그 출력
  static void debugLog(String message) {
    if (enableDebugLogs) {
      print('[DEV] $message');
    }
  }
  
  /// API 시뮬레이션 딜레이
  static Future<void> simulateApiDelay() async {
    if (enableDummyData) {
      await Future.delayed(Duration(milliseconds: apiSimulationDelay));
    }
  }
  
  /// 개발 환경 정보 출력
  static void printDevInfo() {
    if (!enableDebugLogs) return;
    
    print('=== BFBANK 개발 환경 설정 ===');
    print('전체 더미데이터: ${enableDummyData ? "활성화" : "비활성화"}');
    print('사용자 정보: ${enableDummyUser ? "활성화" : "비활성화"}');
    print('계좌 정보: ${enableDummyAccount ? "활성화" : "비활성화"}');
    print('거래 내역: ${enableDummyTransactionHistory ? "활성화" : "비활성화"}');
    print('즐겨찾기: ${enableDummyFavoriteAccounts ? "활성화" : "비활성화"}');
    print('설정: ${enableDummySettings ? "활성화" : "비활성화"}');
    print('은행 목록: ${enableDummyBankList ? "활성화" : "비활성화"}');
    print('자동 로그인: ${enableAutoLogin ? "활성화" : "비활성화"}');
    print('자동 계좌 부여: ${enableAutoAccountAssignment ? "활성화" : "비활성화"}');
    print('API 딜레이: ${apiSimulationDelay}ms');
    print('==============================');
  }
} 