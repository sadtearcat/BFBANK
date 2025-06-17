class UserInfo {
  final int id;
  final String username;
  final String phoneNumber;
  final String birthDate;
  final String joinedDate;
  final bool enabled;
  final bool accountNonLocked;
  final bool accountNonExpired;
  final bool credentialsNonExpired;
  final String fcmToken;

  UserInfo({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.birthDate,
    required this.joinedDate,
    this.enabled = true,
    this.accountNonLocked = true,
    this.accountNonExpired = true,
    this.credentialsNonExpired = true,
    this.fcmToken = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate,
      'joinedDate': joinedDate,
      'enabled': enabled,
      'accountNonLocked': accountNonLocked,
      'accountNonExpired': accountNonExpired,
      'credentialsNonExpired': credentialsNonExpired,
      'fcmToken': fcmToken,
    };
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      username: json['username'],
      phoneNumber: json['phoneNumber'],
      birthDate: json['birthDate'],
      joinedDate: json['joinedDate'],
      enabled: json['enabled'] ?? true,
      accountNonLocked: json['accountNonLocked'] ?? true,
      accountNonExpired: json['accountNonExpired'] ?? true,
      credentialsNonExpired: json['credentialsNonExpired'] ?? true,
      fcmToken: json['fcmToken'] ?? '',
    );
  }
} 