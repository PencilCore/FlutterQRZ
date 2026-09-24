import 'package:shared_preferences/shared_preferences.dart';

/// 凭据存储服务 - 保存/读取 QRZ.com 登录信息
class CredentialStorage {
  static const String _keyUsername = 'qrz_username';
  static const String _keyPassword = 'qrz_password';
  static const String _keyAutoLogin = 'qrz_auto_login';
  static const String _keyLoggedIn = 'qrz_logged_in';

  /// 保存登录凭据
  Future<void> saveCredentials({
    required String username,
    required String password,
    bool autoLogin = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
    await prefs.setBool(_keyAutoLogin, autoLogin);
    await prefs.setBool(_keyLoggedIn, true);
  }

  /// 读取保存的用户名
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  /// 读取保存的密码
  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPassword);
  }

  /// 是否开启自动登录
  Future<bool> isAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoLogin) ?? true;
  }

  /// 是否之前登录过
  Future<bool> wasLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  /// 清除所有凭据
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyAutoLogin);
    await prefs.setBool(_keyLoggedIn, false);
  }

  /// 仅标记为未登录（保留密码以便下次自动登录）
  Future<void> markLoggedOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
  }

  /// 仅标记为已登录
  Future<void> markLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
  }
}
