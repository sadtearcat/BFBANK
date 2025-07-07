import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_info.dart';
import '../models/user_info.dart';
import 'dev_config.dart';

/// 사용자 상태 및 데이터 소스 관리 서비스
class UserStateService {
  // 싱글톤 패턴
  static final UserStateService _instance = UserStateService._internal();
  factory UserStateService() => _instance;
  UserStateService._internal();

  // SharedPreferences 키 상수
  static const String _keyHasAccount = 'has_account';
  static const String _keyUserInfo = 'user_info';
  static const String _keyAccountInfo = 'account_info';
  static const String _keyUseDummyData = 'use_dummy_data';

  // 메모리 캐시
  UserInfo? _currentUser;
  AccountInfo? _currentAccount;
  bool? _hasAccount;
  bool? _useDummyData;

  /// 앱 초기화 시 호출 - 사용자 상태 확인
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _hasAccount = prefs.getBool(_keyHasAccount) ?? false;
    _useDummyData = prefs.getBool(_keyUseDummyData) ?? true; // 기본값: 더미데이터 사용
    
    DevConfig.debugLog('사용자 상태 초기화 - 계좌 보유: $_hasAccount, 더미데이터 사용: $_useDummyData');
    
    // 저장된 사용자 정보가 있으면 로드
    if (_hasAccount == true) {
      await _loadUserData();
    }
  }

  /// 현재 사용자 정보 반환
  Future<UserInfo?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    
    if (_useDummyData == true && DevConfig.shouldUseDummyData('user')) {
      // 더미데이터 사용
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
    
    // 실제 사용자 데이터 반환
    return _currentUser;
  }

  /// 현재 계좌 정보 반환
  Future<AccountInfo?> getCurrentAccount() async {
    if (_currentAccount != null) return _currentAccount;
    
    if (_useDummyData == true && DevConfig.shouldUseDummyData('account')) {
      // 더미데이터 사용
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
    
    // 실제 계좌 데이터 반환
    return _currentAccount;
  }

  /// 계좌 보유 여부 확인
  Future<bool> hasAccount() async {
    if (_hasAccount != null) return _hasAccount!;
    
    final prefs = await SharedPreferences.getInstance();
    _hasAccount = prefs.getBool(_keyHasAccount) ?? false;
    return _hasAccount!;
  }

  /// 더미데이터 사용 여부 확인
  Future<bool> shouldUseDummyData() async {
    if (_useDummyData != null) return _useDummyData!;
    
    final prefs = await SharedPreferences.getInstance();
    _useDummyData = prefs.getBool(_keyUseDummyData) ?? true;
    return _useDummyData!;
  }

  /// 계좌 생성 완료 처리
  Future<void> completeAccountCreation({
    required UserInfo userInfo,
    required AccountInfo accountInfo,
  }) async {
    DevConfig.debugLog('계좌 생성 완료 - 더미데이터에서 실제 데이터로 전환');
    
    final prefs = await SharedPreferences.getInstance();
    
    // 사용자 상태 업데이트
    _hasAccount = true;
    _useDummyData = false;
    _currentUser = userInfo;
    _currentAccount = accountInfo;
    
    // SharedPreferences에 저장
    await prefs.setBool(_keyHasAccount, true);
    await prefs.setBool(_keyUseDummyData, false);
    await _saveUserData(userInfo, accountInfo);
    
    DevConfig.debugLog('계좌 생성 데이터 저장 완료');
  }

  /// 더미데이터 모드로 전환 (개발/테스트용)
  Future<void> enableDummyDataMode() async {
    DevConfig.debugLog('더미데이터 모드로 전환');
    
    final prefs = await SharedPreferences.getInstance();
    
    _useDummyData = true;
    _hasAccount = true;  // 더미데이터에는 계좌가 있다고 가정
    _currentUser = null;
    _currentAccount = null;
    
    await prefs.setBool(_keyUseDummyData, true);
    await prefs.setBool(_keyHasAccount, true);
  }

  /// 신규 사용자 모드로 전환 (계좌 없음)
  Future<void> enableNewUserMode() async {
    DevConfig.debugLog('신규 사용자 모드로 전환');
    
    final prefs = await SharedPreferences.getInstance();
    
    _useDummyData = false;
    _hasAccount = false;
    _currentUser = null;
    _currentAccount = null;
    
    await prefs.setBool(_keyUseDummyData, false);
    await prefs.setBool(_keyHasAccount, false);
    await prefs.remove(_keyUserInfo);
    await prefs.remove(_keyAccountInfo);
  }

  /// 사용자 데이터 저장
  Future<void> _saveUserData(UserInfo userInfo, AccountInfo accountInfo) async {
    final prefs = await SharedPreferences.getInstance();
    
    // JSON 형태로 저장 (실제 구현에서는 암호화 필요)
    await prefs.setString(_keyUserInfo, userInfo.toJson().toString());
    await prefs.setString(_keyAccountInfo, accountInfo.toJson().toString());
  }

  /// 저장된 사용자 데이터 로드
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final userInfoStr = prefs.getString(_keyUserInfo);
    final accountInfoStr = prefs.getString(_keyAccountInfo);
    
    // 실제 구현에서는 JSON 파싱과 암호화 해독 필요
    // 현재는 간단하게 null 처리
    if (userInfoStr != null && accountInfoStr != null) {
      DevConfig.debugLog('저장된 사용자 데이터 로드 완료');
      // TODO: JSON 파싱 구현
    }
  }

  /// 사용자 상태 완전 초기화 (개발/테스트용)
  Future<void> resetUserState() async {
    DevConfig.debugLog('사용자 상태 완전 초기화');
    
    final prefs = await SharedPreferences.getInstance();
    
    // 모든 상태 초기화
    _hasAccount = false;
    _useDummyData = true;
    _currentUser = null;
    _currentAccount = null;
    
    // SharedPreferences에서 모든 데이터 제거
    await prefs.remove(_keyHasAccount);
    await prefs.remove(_keyUseDummyData);
    await prefs.remove(_keyUserInfo);
    await prefs.remove(_keyAccountInfo);
    
    DevConfig.debugLog('사용자 상태 초기화 완료 - 신규 사용자 상태로 돌아감');
  }

  /// 현재 상태 정보 출력 (디버깅용)
  Future<void> printCurrentState() async {
    if (!DevConfig.enableDebugLogs) return;
    
    final hasAcc = await hasAccount();
    final useDummy = await shouldUseDummyData();
    final user = await getCurrentUser();
    final account = await getCurrentAccount();
    
    print('=== 사용자 상태 정보 ===');
    print('계좌 보유: $hasAcc');
    print('더미데이터 사용: $useDummy');
    print('사용자: ${user?.username ?? "없음"}');
    print('계좌번호: ${account?.accountNo ?? "없음"}');
    print('잔액: ${account?.accountBalance ?? 0}원');
    print('====================');
  }
} 