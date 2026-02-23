// [应用锁定功能] 2026-02-17 PIN存储与验证服务
// 负责PIN的保存、验证、删除。从UI和状态管理中分离出来的纯服务类。
// PIN以SHA-256哈希值保存到SharedPreferences，不保存明文。

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinStorageService {
  static const String _keyPinHash = 'app_pin_hash';
  static const String _keyPinSet = 'app_pin_set';
  static const String _keyFailCount = 'app_pin_fail_count';
  static const String _keyLockoutUntil = 'app_pin_lockout_until';
  static const String _keyTimeoutSeconds = 'app_lock_timeout_seconds';

  /// 默认自动锁定时间（秒）
  static const int defaultTimeoutSeconds = 120;

  /// 将PIN字符串转为SHA-256哈希字符串
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 确认PIN是否已设置
  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPinSet) ?? false;
  }

  /// 将PIN哈希化后保存
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPinHash, _hashPin(pin));
    await prefs.setBool(_keyPinSet, true);
  }

  /// 验证输入PIN是否与保存的PIN一致
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString(_keyPinHash);
    if (savedHash == null) return false;
    return _hashPin(pin) == savedHash;
  }

  /// 删除PIN（供将来的重置功能使用）
  Future<void> deletePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPinHash);
    await prefs.setBool(_keyPinSet, false);
    await prefs.setInt(_keyFailCount, 0);
    await prefs.setInt(_keyLockoutUntil, 0);
  }

  /// 获取当前连续失败次数
  Future<int> getFailCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFailCount) ?? 0;
  }

  /// 失败次数+1；达到3次时自动写入锁定截止时间（当前时间+30分钟）
  Future<void> incrementFailCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyFailCount) ?? 0;
    final next = current + 1;
    await prefs.setInt(_keyFailCount, next);
    if (next >= 3) {
      final lockoutUntil =
          DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch;
      await prefs.setInt(_keyLockoutUntil, lockoutUntil);
    }
  }

  /// 将失败次数和锁定截止时间全部清零（验证成功时调用）
  Future<void> resetFailCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFailCount, 0);
    await prefs.setInt(_keyLockoutUntil, 0);
  }

  /// 获取锁定截止时间；未锁定时返回null
  Future<DateTime?> getLockoutUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_keyLockoutUntil) ?? 0;
    if (ts == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  /// 判断当前是否处于等待锁定状态
  Future<bool> isLockedOut() async {
    final lockoutUntil = await getLockoutUntil();
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil);
  }

  /// 获取自动锁定时间（秒）；未设置时返回默认值120秒
  Future<int> getTimeoutSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTimeoutSeconds) ?? defaultTimeoutSeconds;
  }

  /// 保存自动锁定时间（秒）
  Future<void> saveTimeoutSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimeoutSeconds, seconds);
  }
}
