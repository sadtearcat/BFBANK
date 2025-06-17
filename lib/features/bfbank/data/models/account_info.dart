class AccountInfo {
  final int id;
  final String accountNo;
  final int accountBalance;
  final String accountState;
  final int bankId;
  final String bankName;
  final int dailyTransferLimit;
  final int oneTimeTransferLimit;
  final int failedAttempts;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountInfo({
    required this.id,
    required this.accountNo,
    required this.accountBalance,
    required this.accountState,
    required this.bankId,
    this.bankName = '우리은행',
    required this.dailyTransferLimit,
    required this.oneTimeTransferLimit,
    this.failedAttempts = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedBalance {
    return '${accountBalance.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }

  String get formattedAccountNo {
    // 계좌번호 형식: 000-00-000000
    if (accountNo.length >= 10) {
      return '${accountNo.substring(0, 3)}-${accountNo.substring(3, 5)}-${accountNo.substring(5)}';
    }
    return accountNo;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountNo': accountNo,
      'accountBalance': accountBalance,
      'accountState': accountState,
      'bankId': bankId,
      'bankName': bankName,
      'dailyTransferLimit': dailyTransferLimit,
      'oneTimeTransferLimit': oneTimeTransferLimit,
      'failedAttempts': failedAttempts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      id: json['id'],
      accountNo: json['accountNo'],
      accountBalance: json['accountBalance'],
      accountState: json['accountState'],
      bankId: json['bankId'],
      bankName: json['bankName'] ?? '우리은행',
      dailyTransferLimit: json['dailyTransferLimit'],
      oneTimeTransferLimit: json['oneTimeTransferLimit'],
      failedAttempts: json['failedAttempts'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
} 