import '../models/transaction_history.dart';

class DummyDataService {
  static List<TransactionHistory> getDummyTransactionHistories() {
    return [
      TransactionHistory(
        id: 1,
        transactionStatus: true,
        transactionBankId: 1,
        transactionBalance: 1500000,
        transactionAccount: '110-262-000720',
        transactionAmount: 50000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 1)),
        transactionName: '김철수',
      ),
      TransactionHistory(
        id: 2,
        transactionStatus: true,
        transactionBankId: 1,
        transactionBalance: 1550000,
        transactionAccount: '110-262-000721',
        transactionAmount: 100000,
        transactionType: 'DEPOSIT',
        transactionDate: DateTime.now().subtract(const Duration(days: 2)),
        transactionName: '박영희',
      ),
      TransactionHistory(
        id: 3,
        transactionStatus: true,
        transactionBankId: 1,
        transactionBalance: 1450000,
        transactionAccount: '110-262-000722',
        transactionAmount: 30000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 3)),
        transactionName: '이민호',
      ),
      TransactionHistory(
        id: 4,
        transactionStatus: true,
        transactionBankId: 1,
        transactionBalance: 1480000,
        transactionAccount: '110-262-000723',
        transactionAmount: 80000,
        transactionType: 'DEPOSIT',
        transactionDate: DateTime.now().subtract(const Duration(days: 4)),
        transactionName: '정수진',
      ),
      TransactionHistory(
        id: 5,
        transactionStatus: true,
        transactionBankId: 1,
        transactionBalance: 1400000,
        transactionAmount: 200000,
        transactionAccount: '110-262-000724',
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 5)),
        transactionName: '최동호',
      ),
      TransactionHistory(
        id: 6,
        transactionStatus: true,
        transactionBankId: 1,
        transactionBalance: 1600000,
        transactionAccount: '110-262-000725',
        transactionAmount: 150000,
        transactionType: 'DEPOSIT',
        transactionDate: DateTime.now().subtract(const Duration(days: 6)),
        transactionName: '윤서연',
      ),
      TransactionHistory(
        id: 7,
        transactionStatus: true,
        transactionBankId: 1,
        transactionBalance: 1450000,
        transactionAccount: '110-262-000726',
        transactionAmount: 75000,
        transactionType: 'WITHDRAWAL',
        transactionDate: DateTime.now().subtract(const Duration(days: 7)),
        transactionName: '장혜림',
      ),
    ];
  }

  /// 계좌 ID로 거래 내역 조회 (API 호출 시뮬레이션)
  static Future<List<TransactionHistory>> getHistoriesForAccount(int accountId) async {
    // API 호출 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));
    return getDummyTransactionHistories();
  }

  /// 거래 내역이 있는지 확인
  static bool hasTransactionHistories() {
    return getDummyTransactionHistories().isNotEmpty;
  }
} 