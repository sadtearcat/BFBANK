class FavoriteAccount {
  final int id;
  final String receiverName;
  final String receiverAccount;
  final int receiverBankId;
  final String receiverBankName;
  final DateTime lastTransactionDate;
  final int frequency; // 거래 빈도수

  FavoriteAccount({
    required this.id,
    required this.receiverName,
    required this.receiverAccount,
    required this.receiverBankId,
    this.receiverBankName = '우리은행',
    required this.lastTransactionDate,
    this.frequency = 1,
  });

  String get formattedAccount {
    // 계좌번호 형식: 000-00-000000
    if (receiverAccount.length >= 10) {
      return '${receiverAccount.substring(0, 3)}-${receiverAccount.substring(3, 5)}-${receiverAccount.substring(5)}';
    }
    return receiverAccount;
  }

  String get shortDescription {
    return '$receiverName ($receiverBankName)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiverName': receiverName,
      'receiverAccount': receiverAccount,
      'receiverBankId': receiverBankId,
      'receiverBankName': receiverBankName,
      'lastTransactionDate': lastTransactionDate.toIso8601String(),
      'frequency': frequency,
    };
  }

  factory FavoriteAccount.fromJson(Map<String, dynamic> json) {
    return FavoriteAccount(
      id: json['id'],
      receiverName: json['receiverName'],
      receiverAccount: json['receiverAccount'],
      receiverBankId: json['receiverBankId'],
      receiverBankName: json['receiverBankName'] ?? '우리은행',
      lastTransactionDate: DateTime.parse(json['lastTransactionDate']),
      frequency: json['frequency'] ?? 1,
    );
  }
} 