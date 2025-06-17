import '../models/user_info.dart';
import '../models/account_info.dart';
import '../models/favorite_account.dart';
import '../models/transaction_history.dart';

class IntegratedDummyDataService {
  // 싱글톤 패턴
  static final IntegratedDummyDataService _instance = IntegratedDummyDataService._internal();
  factory IntegratedDummyDataService() => _instance;
  IntegratedDummyDataService._internal();

  // 현재 로그인된 사용자 정보
  static UserInfo getCurrentUser() {
    return UserInfo(
      id: 1,
      username: '홍길동',
      phoneNumber: '010-1234-5678',
      birthDate: '1990-05-15',
      joinedDate: '2024-01-01',
      enabled: true,
      accountNonLocked: true,
      accountNonExpired: true,
      credentialsNonExpired: true,
      fcmToken: 'dummy_fcm_token_123',
    );
  }

  // 현재 사용자의 계좌 정보
  static AccountInfo getCurrentUserAccount() {
    return AccountInfo(
      id: 1,
      accountNo: '1102620007201',
      accountBalance: 1500000,
      accountState: 'ACTIVE',
      bankId: 1,
      bankName: '우리은행',
      dailyTransferLimit: 1000000,
      oneTimeTransferLimit: 500000,
      failedAttempts: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime.now(),
    );
  }

  // 자주 사용하는 계좌 목록
  static List<FavoriteAccount> getFavoriteAccounts() {
    return [
      FavoriteAccount(
        id: 1,
        receiverName: '김철수',
        receiverAccount: '1102620007210',
        receiverBankId: 1,
        receiverBankName: '우리은행',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 1)),
        frequency: 5,
      ),
      FavoriteAccount(
        id: 2,
        receiverName: '박영희',
        receiverAccount: '1102620007211',
        receiverBankId: 1,
        receiverBankName: '우리은행',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 3)),
        frequency: 3,
      ),
      FavoriteAccount(
        id: 3,
        receiverName: '이민호',
        receiverAccount: '1102620007212',
        receiverBankId: 1,
        receiverBankName: '우리은행',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 7)),
        frequency: 2,
      ),
      FavoriteAccount(
        id: 4,
        receiverName: '정수진',
        receiverAccount: '1102620007213',
        receiverBankId: 1,
        receiverBankName: '우리은행',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 10)),
        frequency: 1,
      ),
    ];
  }

  // 거래 내역 (더 풍부한 데이터로 확장)
  static List<TransactionHistory> getTransactionHistories() {
    return [
      // 최근 거래들
      TransactionHistory(
        id: 1,
        transactionStatus: true,
        transactionBankId: 1,
        transactionBalance: 1750000,
        transactionAccount: '110-262-000720',
        transactionAmount: 50000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(hours: 2)),
        transactionName: '김철수',
      ),
      TransactionHistory(
        id: 2,
        transactionStatus: true,
        transactionBankId: 2,
        transactionBalance: 1800000,
        transactionAccount: '356-890-012345',
        transactionAmount: 100000,
        transactionType: 'DEPOSIT',
        transactionDate: DateTime.now().subtract(const Duration(hours: 8)),
        transactionName: '박영희',
      ),
      TransactionHistory(
        id: 3,
        transactionStatus: true,
        transactionBankId: 3,
        transactionBalance: 1700000,
        transactionAccount: '302-456-789123',
        transactionAmount: 25000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        transactionName: '이민호',
      ),
      TransactionHistory(
        id: 4,
        transactionStatus: true,
        transactionBankId: 1,
        transactionBalance: 1725000,
        transactionAccount: '110-262-000723',
        transactionAmount: 80000,
        transactionType: 'DEPOSIT',
        transactionDate: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
        transactionName: '정수진',
      ),
      TransactionHistory(
        id: 5,
        transactionStatus: true,
        transactionBankId: 4,
        transactionBalance: 1645000,
        transactionAccount: '081-234-567890',
        transactionAmount: 200000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
        transactionName: '최동호',
      ),
      
      // 지난 주 거래들
      TransactionHistory(
        id: 6,
        transactionStatus: true,
        transactionBankId: 5,
        transactionBalance: 1845000,
        transactionAccount: '020-678-901234',
        transactionAmount: 150000,
        transactionType: 'DEPOSIT',
        transactionDate: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
        transactionName: '윤서연',
      ),
      TransactionHistory(
        id: 7,
        transactionStatus: true,
        transactionBankId: 2,
        transactionBalance: 1695000,
        transactionAccount: '356-234-567891',
        transactionAmount: 75000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 7, hours: 4)),
        transactionName: '장혜림',
      ),
      TransactionHistory(
        id: 8,
        transactionStatus: true,
        transactionBankId: 6,
        transactionBalance: 1770000,
        transactionAccount: '011-345-678912',
        transactionAmount: 120000,
        transactionType: 'DEPOSIT',
        transactionDate: DateTime.now().subtract(const Duration(days: 8, hours: 6)),
        transactionName: '송민수',
      ),
      
      // 지난달 거래들
      TransactionHistory(
        id: 9,
        transactionStatus: true,
        transactionBankId: 3,
        transactionBalance: 1650000,
        transactionAccount: '302-567-890123',
        transactionAmount: 90000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 12, hours: 3)),
        transactionName: '한지영',
      ),
      TransactionHistory(
        id: 10,
        transactionStatus: true,
        transactionBankId: 7,
        transactionBalance: 1740000,
        transactionAccount: '088-789-012345',
        transactionAmount: 60000,
        transactionType: 'DEPOSIT',
        transactionDate: DateTime.now().subtract(const Duration(days: 15, hours: 7)),
        transactionName: '구본석',
      ),
      TransactionHistory(
        id: 11,
        transactionStatus: true,
        transactionBankId: 1,
        transactionBalance: 1680000,
        transactionAccount: '110-262-000724',
        transactionAmount: 45000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 18, hours: 2)),
        transactionName: '신예린',
      ),
      TransactionHistory(
        id: 12,
        transactionStatus: true,
        transactionBankId: 8,
        transactionBalance: 1725000,
        transactionAccount: '079-901-234567',
        transactionAmount: 110000,
        transactionType: 'DEPOSIT',
        transactionDate: DateTime.now().subtract(const Duration(days: 22, hours: 8)),
        transactionName: '오태민',
      ),
      
      // 더 오래된 거래들
      TransactionHistory(
        id: 13,
        transactionStatus: true,
        transactionBankId: 4,
        transactionBalance: 1615000,
        transactionAccount: '081-456-789012',
        transactionAmount: 35000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 25, hours: 4)),
        transactionName: '배수현',
      ),
      TransactionHistory(
        id: 14,
        transactionStatus: true,
        transactionBankId: 2,
        transactionBalance: 1650000,
        transactionAmount: 85000,
        transactionAccount: '356-678-901234',
        transactionType: 'DEPOSIT',
        transactionDate: DateTime.now().subtract(const Duration(days: 28, hours: 1)),
        transactionName: '임채원',
      ),
      TransactionHistory(
        id: 15,
        transactionStatus: true,
        transactionBankId: 5,
        transactionBalance: 1565000,
        transactionAccount: '020-123-456789',
        transactionAmount: 65000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 30, hours: 6)),
        transactionName: '홍진우',
      ),
    ];
  }

  // API 호출 시뮬레이션 메서드들
  static Future<UserInfo> fetchUserInfo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return getCurrentUser();
  }

  static Future<AccountInfo> fetchAccountInfo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return getCurrentUserAccount();
  }

  static Future<List<FavoriteAccount>> fetchFavoriteAccounts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return getFavoriteAccounts();
  }

  static Future<List<TransactionHistory>> fetchTransactionHistories() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return getTransactionHistories();
  }

  // 계좌 번호로 사용자 검색 (송금 시 사용)
  static Future<String?> findUserByAccountNumber(String accountNumber) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // 계좌번호 정규화 (하이픈 제거)
    final normalizedAccount = accountNumber.replaceAll('-', '');
    
    final favoriteAccounts = getFavoriteAccounts();
    for (final account in favoriteAccounts) {
      if (account.receiverAccount.replaceAll('-', '') == normalizedAccount) {
        return account.receiverName;
      }
    }
    
    // 거래 내역에서도 찾아보기
    final histories = getTransactionHistories();
    for (final history in histories) {
      if (history.transactionAccount.replaceAll('-', '') == normalizedAccount) {
        return history.transactionName;
      }
    }
    
    return null; // 계좌 없음
  }

  // 송금 처리 (API 호출 시뮬레이션)
  static Future<bool> processTransfer({
    required String toAccount,
    required int amount,
    String? memo,
  }) async {
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // 잔액 체크
    final currentAccount = getCurrentUserAccount();
    if (currentAccount.accountBalance < amount) {
      return false; // 잔액 부족
    }
    
    // 이체 한도 체크
    if (amount > currentAccount.oneTimeTransferLimit) {
      return false; // 1회 이체 한도 초과
    }
    
    // 성공적으로 처리됨 (실제로는 거래 내역에 추가해야 함)
    return true;
  }

  // 확장성을 위한 메서드들
  static Future<List<String>> getBankList() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      '우리은행',
      '국민은행',
      '신한은행',
      '하나은행',
      'KB국민은행',
      '농협은행',
      '기업은행',
      '우체국',
    ];
  }

  static Future<Map<String, dynamic>> getUserSettings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'ttsEnabled': true,
      'hapticEnabled': true,
      'speechRate': 0.5,
      'volume': 1.0,
      'voiceGuidanceOnPageEnter': true,
      'autoLogin': false,
      'ttsQueueMode': true, // TTS 큐 모드
      'ttsMaxQueueSize': 10, // 최대 큐 크기
    };
  }

  static Future<bool> updateUserSettings(Map<String, dynamic> settings) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // 실제로는 설정을 저장해야 함
    return true;
  }
} 