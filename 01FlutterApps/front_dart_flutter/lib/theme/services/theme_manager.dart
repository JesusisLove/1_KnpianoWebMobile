// [Flutter页面主题改造] 2026-01-17 新增主题管理器
// 负责加载、切换、持久化主题配置

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_config.dart';

/// 主题管理器 - 负责加载、切换、持久化主题
class ThemeManager {
  static const String _themePreferenceKey = 'selected_theme_id';
  static const String _defaultThemeId = 'fairytale';

  final Map<String, ThemeConfig> _loadedThemes = {};
  ThemeConfig? _currentTheme;

  /// 可用的主题ID列表（按assets/themes/目录中的文件定义）
  static const List<String> availableThemeIds = [
    'fairytale', // 童话风格
    'minimal', // 简约风格
    'business', // 商务风格
  ];

  /// 获取当前主题
  ThemeConfig get currentTheme {
    if (_currentTheme == null) {
      throw StateError('Theme not initialized. Call initialize() first.');
    }
    return _currentTheme!;
  }

  /// 获取当前主题ID
  String get currentThemeId => _currentTheme?.id ?? _defaultThemeId;

  /// 获取所有已加载的主题
  List<ThemeConfig> get allThemes => _loadedThemes.values.toList();

  /// 初始化主题管理器
  Future<void> initialize() async {
    // 1. 加载所有可用主题
    for (final themeId in availableThemeIds) {
      try {
        final config = await _loadThemeFromAssets(themeId);
        _loadedThemes[themeId] = config;
      } catch (e) {
        print('Warning: Failed to load theme "$themeId": $e');
      }
    }

    // 2. 读取用户上次选择的主题
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId =
        prefs.getString(_themePreferenceKey) ?? _defaultThemeId;

    // 3. 设置当前主题
    _currentTheme =
        _loadedThemes[savedThemeId] ?? _loadedThemes[_defaultThemeId];

    if (_currentTheme == null && _loadedThemes.isNotEmpty) {
      _currentTheme = _loadedThemes.values.first;
    }
  }

  /// 从assets加载主题配置
  Future<ThemeConfig> _loadThemeFromAssets(String themeId) async {
    final jsonString =
        await rootBundle.loadString('assets/themes/$themeId.json');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return ThemeConfig.fromJson(jsonMap);
  }

  /// 切换主题
  Future<void> switchTheme(String themeId) async {
    if (!_loadedThemes.containsKey(themeId)) {
      throw ArgumentError('Theme "$themeId" not found');
    }

    _currentTheme = _loadedThemes[themeId];

    // 持久化用户选择
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themeId);
  }

  /// 根据主题ID获取主题配置
  ThemeConfig? getTheme(String themeId) => _loadedThemes[themeId];

  /// 检查主题是否已加载
  bool isThemeLoaded(String themeId) => _loadedThemes.containsKey(themeId);
}
