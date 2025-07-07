import '../models/user_info.dart';
import '../models/account_info.dart';
import '../models/favorite_account.dart';
import '../models/transaction_history.dart';
import '../models/account_product.dart';
import 'dev_config.dart';
import 'user_state_service.dart';

class IntegratedDummyDataService {
  // 싱글톤 패턴
  static final IntegratedDummyDataService _instance = IntegratedDummyDataService._internal();
  factory IntegratedDummyDataService() => _instance;
  IntegratedDummyDataService._internal();

  final UserStateService _userStateService = UserStateService();

  // 현재 로그인된 사용자 정보
  static Future<UserInfo?> getCurrentUser() async {
    final userStateService = UserStateService();
    return await userStateService.getCurrentUser();
  }

  // 현재 사용자의 계좌 정보
  static Future<AccountInfo?> getCurrentUserAccount() async {
    final userStateService = UserStateService();
    return await userStateService.getCurrentAccount();
  }

  // 자주 사용하는 계좌 목록
  static Future<List<FavoriteAccount>> getFavoriteAccounts() async {
    final userStateService = UserStateService();
    final shouldUseDummy = await userStateService.shouldUseDummyData();
    
    if (!shouldUseDummy || !DevConfig.shouldUseDummyData('favorite')) {
      DevConfig.debugLog('더미 즐겨찾기 계좌 비활성화 - 빈 목록 반환');
      return [];
    }
    
    DevConfig.debugLog('더미 즐겨찾기 계좌 목록 반환');
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
  static Future<List<TransactionHistory>> getTransactionHistories() async {
    final userStateService = UserStateService();
    final shouldUseDummy = await userStateService.shouldUseDummyData();
    
    if (!shouldUseDummy || !DevConfig.shouldUseDummyData('transaction')) {
      DevConfig.debugLog('더미 거래 내역 비활성화 - 빈 목록 반환');
      return [];
    }
    
    DevConfig.debugLog('더미 거래 내역 목록 반환 (15개)');
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
    await DevConfig.simulateApiDelay();
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('사용자 정보를 찾을 수 없습니다');
    }
    return user;
  }

  static Future<AccountInfo> fetchAccountInfo() async {
    await DevConfig.simulateApiDelay();
    final account = await getCurrentUserAccount();
    if (account == null) {
      throw Exception('계좌 정보를 찾을 수 없습니다');
    }
    return account;
  }

  static Future<List<FavoriteAccount>> fetchFavoriteAccounts() async {
    await DevConfig.simulateApiDelay();
    return getFavoriteAccounts();
  }

  static Future<List<TransactionHistory>> fetchTransactionHistories() async {
    await DevConfig.simulateApiDelay();
    return getTransactionHistories();
  }

  // 계좌 번호로 사용자 검색 (송금 시 사용)
  static Future<String?> findUserByAccountNumber(String accountNumber) async {
    await DevConfig.simulateApiDelay();
    
    // 계좌번호 정규화 (하이픈 제거)
    final normalizedAccount = accountNumber.replaceAll('-', '');
    
    final favoriteAccounts = await getFavoriteAccounts();
    for (final account in favoriteAccounts) {
      if (account.receiverAccount.replaceAll('-', '') == normalizedAccount) {
        return account.receiverName;
      }
    }
    
    // 거래 내역에서도 찾아보기
    final histories = await getTransactionHistories();
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
    await DevConfig.simulateApiDelay();
    
    // 잔액 체크
    final currentAccount = await getCurrentUserAccount();
    if (currentAccount == null) {
      return false; // 계좌 정보 없음
    }
    
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
    if (!DevConfig.shouldUseDummyData('bank')) {
      DevConfig.debugLog('더미 은행 목록 비활성화 - 빈 목록 반환');
      return [];
    }
    
    await DevConfig.simulateApiDelay();
    DevConfig.debugLog('더미 은행 목록 반환');
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
    if (!DevConfig.shouldUseDummyData('settings')) {
      DevConfig.debugLog('더미 설정 비활성화 - 기본 설정 반환');
      return {};
    }
    
    await DevConfig.simulateApiDelay();
    DevConfig.debugLog('더미 사용자 설정 반환');
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
    await DevConfig.simulateApiDelay();
    DevConfig.debugLog('사용자 설정 업데이트 시뮬레이션');
    // 실제로는 설정을 저장해야 함
    return true;
  }

  // 계좌 개설 관련 더미데이터
  static List<AccountProduct> getAccountProducts() {
    if (!DevConfig.shouldUseDummyData('accountProduct')) {
      DevConfig.debugLog('더미 계좌 상품 비활성화 - 빈 목록 반환');
      return [];
    }
    
    DevConfig.debugLog('더미 계좌 상품 목록 반환 (4개)');
    return [
      AccountProduct(
        id: 1,
        name: '주거래 우대통장',
        category: '입출금자유예금',
        description: '주거래 고객을 위한 특별우대 혜택이 가득한 통장',
        features: {
          '상품개요': '주거래 고객을 위한 특별우대 혜택이 가득한 통장',
          '상품특징': '높은 우대금리와 다양한 부가서비스를 제공하는 프리미엄 예금상품',
          '예금과목': '보통예금',
        },
        interestRate: 1.8,
        minimumAmount: 1000,
        maximumAmount: 100000000,
        benefits: [
          '우대금리 1.8% 적용',
          '타행 ATM 수수료 면제 (월 10회)',
          '인터넷뱅킹 수수료 면제',
          '카드 연회비 면제',
        ],
        depositType: '보통예금',
      ),
      AccountProduct(
        id: 2,
        name: '입출금통장',
        category: '입출금자유예금',
        description: '언제든지 자유롭게 입출금이 가능한 기본 예금상품',
        features: {
          '상품개요': '언제든지 자유롭게 입출금이 가능한 기본 예금상품',
          '상품특징': '예금보험공사 보호 대상 상품으로 안전하고 편리한 거래 가능',
          '예금과목': '보통예금',
        },
        interestRate: 0.8,
        minimumAmount: 1000,
        maximumAmount: 100000000,
        benefits: [
          '기본금리 0.8% 적용',
          '24시간 입출금 자유',
          '예금보험공사 보호',
          '체크카드 발급 가능',
        ],
        depositType: '보통예금',
      ),
      AccountProduct(
        id: 3,
        name: '주니어통장',
        category: '적립식예금',
        description: '청소년을 위한 특별한 혜택이 있는 성장형 예금상품',
        features: {
          '상품개요': '청소년을 위한 특별한 혜택이 있는 성장형 예금상품',
          '상품특징': '만 19세 미만 청소년 전용 상품으로 높은 우대금리와 교육비 지원 혜택',
          '예금과목': '적립식예금',
        },
        interestRate: 2.5,
        minimumAmount: 10000,
        maximumAmount: 50000000,
        benefits: [
          '우대금리 2.5% 적용',
          '교육비 할인 혜택',
          '용돈 자동입금 서비스',
          '청소년 전용 체크카드',
        ],
        depositType: '적립식예금',
      ),
      AccountProduct(
        id: 4,
        name: '모임통장',
        category: '입출금자유예금',
        description: '친구, 동료들과 함께 사용하는 공동 예금상품',
        features: {
          '상품개요': '친구, 동료들과 함께 사용하는 공동 예금상품',
          '상품특징': '여러 명이 함께 사용할 수 있는 공동계좌 서비스와 편리한 관리 기능',
          '예금과목': '보통예금',
        },
        interestRate: 1.2,
        minimumAmount: 10000,
        maximumAmount: 100000000,
        benefits: [
          '공동 관리 기능',
          '모임비 자동 정산',
          '회비 자동 납부',
          '투명한 거래 내역 공유',
        ],
        depositType: '보통예금',
      ),
    ];
  }

  static AccountTerms getAccountTerms() {
    if (!DevConfig.shouldUseDummyData('accountTerms')) {
      DevConfig.debugLog('더미 계좌 약관 비활성화 - 기본 약관 반환');
      return AccountTerms(
        title: '약관을 불러올 수 없습니다',
        content: '네트워크 연결을 확인해주세요.',
        sections: [],
      );
    }
    
    DevConfig.debugLog('더미 계좌 약관 반환');
    return AccountTerms(
      title: '예금거래기본약관',
      content: '이 예금거래기본약관(이하 "약관"이라 한다)은 은행과 거래처(또는 예금주)가 서로 믿음을 바탕으로 예금거래를 빠르고 틀림 없이 처리하는 한편, 서로의 이해관계를 합리적으로 조정하기 위하여 기본적이고 일반적인 사항을 정한 것이다. 은행은 이 약관을 영업점에 놓아두고, 거래처는 영업시간 중 언제든지 이 약관을 볼 수 있고 또한 그 교부를 청구할 수 있다.',
      sections: [
        TermsSection(
          title: '제1조 [적용범위]',
          content: ['이 약관은 입출금이 자유로운 예금, 거치식예금 및 적립식예금 거래에 적용한다.'],
        ),
        TermsSection(
          title: '제2조 [실명거래]',
          content: [
            '1. 거래처는 실명으로 거래하여야 한다.',
            '2. 은행은 거래처의 실명확인을 위하여 주민등록증·사업자등록증 등 실명확인증표 또는 그 밖에 필요한 서류의 제시나 제출을 요구할 수 있고, 거래처는 이에 따라야 한다.'
          ],
        ),
        TermsSection(
          title: '제3조 [거래장소]',
          content: ['거래처는 예금계좌를 개설한 영업점(이하 "개설점")에서 모든 예금거래를 한다. 다만, 은행이 정하는 바에 따라 다른 영업점이나 다른 금융기관, 또는 전산통신기기를 통하여 거래할 수 있다.'          ],
        ),
        TermsSection(
          title: '제4조 [거래방법]',
          content: ['거래처는 은행에서 내준 통장 또는 수표·어음용지로 거래하여야 한다. 다만, 자동이체약정·전산통신기기이용약정에 따라 거래하거나, 바이오정보 또는 실명확인증표로 본인확인된 경우에는 무통장으로 거래할 수 있다.'],
        ),
        TermsSection(
          title: '제5조 [인감, 비밀번호 등의 신고]',
          content: [
            '1. 거래를 시작할 때 인감, 서명, 비밀번호 등 필요한 사항을 신고하여야 한다.',
            '2. 비밀번호는 직접 입력하거나 전산통신기기를 통해 등록할 수 있다.',
            '3. 거치식·적립식 예금은 비밀번호 신고를 생략할 수 있다.',
            '4. 무통장 계좌는 인감 또는 서명 신고 절차를 생략할 수 있다.'
          ],
        ),
        TermsSection(
          title: '제6조 [입금]',
          content: [
            '1. 현금, 수표, 어음 등의 증권으로 입금할 수 있다.',
            '2. 계좌송금 또는 계좌이체도 가능하다.',
            '3. 증권 입금 시 필요한 절차를 따라야 하며, 은행은 그 책임을 지지 않는다.',
            '4. 수표나 어음은 금액란 기준으로 처리한다.'
          ],
        ),
        TermsSection(
          title: '제7조 [예금이 되는 시기]',
          content: [
            '1. 현금 입금: 은행이 확인한 때',
            '2. 계좌송금/이체: 입금 기록된 때',
            '3. 증권 입금: 부도 반환시한 이후 결제 확인 시',
            '4. 자기앞수표는 결제 확실 시 기록된 때로 본다'
          ],
        ),
        TermsSection(
          title: '제8조 [증권의 부도]',
          content: [
            '1. 지급거절 시 예금원장에서 금액을 뺀 후 통지한다.',
            '2. 거래처가 청구 시 해당 증권을 돌려준다.'
          ],
        ),
        TermsSection(
          title: '제9조 [이자]',
          content: [
            '1. 약정기간 또는 예금일로부터 지급 전날까지 계산',
            '2. 이율 변경 시 영업점 및 홈페이지에 공지',
            '3. 입출금 예금은 변경된 이율 적용, 고정금리 예금은 기존 이율 유지',
            '4. 변동이율 예금은 변경 시 통지함',
            '5. 실제 수령 이자는 세금 공제 후 금액'
          ],
        ),
        TermsSection(
          title: '제9조의2 [휴면예금 및 출연]',
          content: [
            '1. 최종 거래일로부터 5년 경과 시 휴면예금',
            '2. 휴면예금은 서민금융진흥원에 출연될 수 있음',
            '3. 해당 시점에 예금계약 종료 및 계좌 이용 불가'
          ],
        ),
      ],
    );
  }

  // API 호출 시뮬레이션 메서드들
  static Future<List<AccountProduct>> fetchAccountProducts() async {
    await DevConfig.simulateApiDelay();
    return getAccountProducts();
  }

  static Future<AccountTerms> fetchAccountTerms() async {
    await DevConfig.simulateApiDelay();
    return getAccountTerms();
  }

  // 신분증 인증 처리 (OCR 결과 시뮬레이션)
  static Future<Map<String, String>> processIdCardOcr(String imagePath) async {
    await DevConfig.simulateApiDelay(); // OCR은 시간이 좀 걸림
    await Future.delayed(Duration(milliseconds: 1500)); // 추가 딜레이
    
    if (!DevConfig.shouldUseDummyData('idCardOcr')) {
      throw Exception('OCR 서비스가 비활성화되어 있습니다.');
    }
    
    DevConfig.debugLog('더미 신분증 OCR 결과 반환');
    return {
      'name': '홍길동',
      'birthDate': '1990-05-15',
      'idNumber': '900515-1234567',
      'address': '서울특별시 강남구 테헤란로 123',
      'issueDate': '2019-01-01',
      'confidence': '0.92',
      'status': 'success',
    };
  }

  // 계좌 개설 처리
  static Future<Map<String, dynamic>> createAccount({
    required AccountProduct product,
    required Map<String, String> personalInfo,
    required String password,
  }) async {
    await DevConfig.simulateApiDelay(); // 계좌 개설은 시간이 걸림
    await Future.delayed(Duration(milliseconds: 2500)); // 추가 딜레이
    
    DevConfig.debugLog('더미 계좌 개설 처리');
    
    // 실제로는 서버에서 계좌번호를 생성해야 함
    final now = DateTime.now();
    final accountNumber = '110262000${now.millisecondsSinceEpoch.toString().substring(7)}';
    
    // 새로운 사용자 및 계좌 정보 생성
    final newUser = UserInfo(
      id: 2,
      username: personalInfo['name'] ?? '홍길동',
      phoneNumber: personalInfo['phoneNumber'] ?? '010-1234-5678',
      birthDate: personalInfo['birthDate'] ?? '1990-05-15',
      joinedDate: now.toIso8601String().split('T')[0],
      enabled: true,
      accountNonLocked: true,
      accountNonExpired: true,
      credentialsNonExpired: true,
      fcmToken: 'real_fcm_token_${now.millisecondsSinceEpoch}',
    );
    
    final newAccount = AccountInfo(
      id: 2,
      accountNo: accountNumber,
      accountBalance: 0, // 새 계좌는 잔액 0
      accountState: 'ACTIVE',
      bankId: 1,
      bankName: '우리은행',
      dailyTransferLimit: 1000000,
      oneTimeTransferLimit: 500000,
      failedAttempts: 0,
      createdAt: now,
      updatedAt: now,
    );
    
    // UserStateService를 통해 상태 전환 (더미데이터에서 실제 데이터로)
    final userStateService = UserStateService();
    await userStateService.completeAccountCreation(
      userInfo: newUser,
      accountInfo: newAccount,
    );
    
    return {
      'success': true,
      'accountNumber': accountNumber,
      'accountName': product.name,
      'interestRate': product.interestRate,
      'createdAt': now.toIso8601String(),
      'message': '계좌가 성공적으로 개설되었습니다.',
    };
  }
} 