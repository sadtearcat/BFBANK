class TransactionHistory {
  final int id;
  final bool transactionStatus;
  final int transactionBankId;
  final int transactionBalance;
  final String transactionAccount;
  final int transactionAmount;
  final String transactionType; // 'WITHDRAWAL' or 'DEPOSIT'
  final DateTime transactionDate;
  final String transactionName;

  TransactionHistory({
    required this.id,
    required this.transactionStatus,
    required this.transactionBankId,
    required this.transactionBalance,
    required this.transactionAccount,
    required this.transactionAmount,
    required this.transactionType,
    required this.transactionDate,
    required this.transactionName,
  });

  factory TransactionHistory.fromJson(Map<String, dynamic> json) {
    return TransactionHistory(
      id: json['id'],
      transactionStatus: json['transactionStatus'],
      transactionBankId: json['transactionBankId'],
      transactionBalance: json['transactionBalance'],
      transactionAccount: json['transactionAccount'],
      transactionAmount: json['transactionAmount'],
      transactionType: json['transactionType'],
      transactionDate: DateTime.parse(json['transactionDate']),
      transactionName: json['transactionName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionStatus': transactionStatus,
      'transactionBankId': transactionBankId,
      'transactionBalance': transactionBalance,
      'transactionAccount': transactionAccount,
      'transactionAmount': transactionAmount,
      'transactionType': transactionType,
      'transactionDate': transactionDate.toIso8601String(),
      'transactionName': transactionName,
    };
  }

  bool get isWithdrawal => transactionType == 'WITHDRAWAL';
  bool get isDeposit => transactionType == 'DEPOSIT';
  
  String get typeLabel => isWithdrawal ? '출금' : '입금';
  
  String get formattedAmount => '${transactionAmount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match match) => '${match[1]},',
  )}원';
  
  String get formattedBalance => '${transactionBalance.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match match) => '${match[1]},',
  )}원';
} 