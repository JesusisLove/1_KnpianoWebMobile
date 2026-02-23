// [Flutter页面主题改造] 2026-01-17 新增主题状态管理Provider
// 使用ChangeNotifier进行主题状态管理，支持实时主题切换

import 'package:flutter/material.dart';
import '../models/theme_config.dart';
import '../services/theme_manager.dart';
import '../generated/theme_data_builder.dart';

/// 主题状态提供者
class ThemeProvider extends ChangeNotifier {
  final ThemeManager _themeManager = ThemeManager();

  bool _isInitialized = false;
  ThemeData? _themeData;

  bool get isInitialized => _isInitialized;
  ThemeConfig get currentConfig => _themeManager.currentTheme;
  String get currentThemeId => _themeManager.currentThemeId;
  ThemeData get themeData => _themeData ?? ThemeData.light();
  List<ThemeConfig> get availableThemes => _themeManager.allThemes;

  /// 初始化
  Future<void> initialize() async {
    await _themeManager.initialize();
    _themeData = ThemeDataBuilder.build(_themeManager.currentTheme);
    _isInitialized = true;
    notifyListeners();
  }

  /// 切换主题
  Future<void> switchTheme(String themeId) async {
    await _themeManager.switchTheme(themeId);
    _themeData = ThemeDataBuilder.build(_themeManager.currentTheme);
    notifyListeners();
  }

  /// 获取当前模块颜色
  ModuleColor getModuleColor(String moduleName) {
    final modules = currentConfig.colors.modules;
    switch (moduleName) {
      case 'lesson':
        return modules.lesson;
      case 'fee':
        return modules.fee;
      case 'archive':
        return modules.archive;
      case 'summary':
        return modules.summary;
      case 'setting':
        return modules.setting;
      default:
        return modules.lesson;
    }
  }

  /// 获取状态颜色
  StatusColors get statusColors => currentConfig.colors.status;

  /// 获取间距配置
  ThemeSpacing get spacing => currentConfig.spacing;

  /// 获取形状配置
  ThemeShapes get shapes => currentConfig.shapes;

  /// 获取阴影配置
  ThemeShadows get shadows => currentConfig.shadows;

  /// 获取动画配置
  ThemeAnimations get animations => currentConfig.animations;

  /// 获取图标配置
  ThemeIcons get icons => currentConfig.icons;
}
