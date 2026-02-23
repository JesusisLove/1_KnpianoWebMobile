// [Flutter页面主题改造] 2026-01-17 新增主题颜色桥接工具类
// 提供从旧Constants颜色系统到新ThemeProvider的平滑迁移
// 在迁移过渡期内，此类提供向后兼容的颜色访问方法

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/theme_config.dart';
import 'providers/theme_provider.dart';

/// KN主题颜色工具类
/// 提供模块颜色和渐变色的统一访问接口
class KnThemeColors {
  /// 获取模块主色调
  /// [context] BuildContext
  /// [moduleName] 模块名称: lesson, fee, archive, summary, setting
  static Color getModulePrimary(BuildContext context, String moduleName) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.getModuleColor(moduleName).primary;
  }

  /// 获取模块浅色调
  static Color getModuleLight(BuildContext context, String moduleName) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.getModuleColor(moduleName).light;
  }

  /// 获取模块渐变色（用于按钮、卡片背景）
  static List<Color> getModuleGradient(BuildContext context, String moduleName) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final moduleColor = themeProvider.getModuleColor(moduleName);
    return [moduleColor.primary, moduleColor.light];
  }

  /// 获取上课管理模块颜色
  static ModuleColor getLessonColors(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .getModuleColor('lesson');
  }

  /// 获取学费管理模块颜色
  static ModuleColor getFeeColors(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .getModuleColor('fee');
  }

  /// 获取档案管理模块颜色
  static ModuleColor getArchiveColors(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .getModuleColor('archive');
  }

  /// 获取综合管理模块颜色
  static ModuleColor getSummaryColors(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .getModuleColor('summary');
  }

  /// 获取设置管理模块颜色
  static ModuleColor getSettingColors(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .getModuleColor('setting');
  }

  /// 获取背景色
  static Color getBackgroundColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .currentConfig
        .colors
        .background;
  }

  /// 获取卡片背景色
  static Color getCardBackgroundColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .currentConfig
        .colors
        .cardBackground;
  }

  /// 获取主文字颜色
  static Color getPrimaryTextColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .currentConfig
        .colors
        .primaryText;
  }

  /// 获取次要文字颜色
  static Color getSecondaryTextColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .currentConfig
        .colors
        .secondaryText;
  }

  /// 获取提示文字颜色
  static Color getHintTextColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .currentConfig
        .colors
        .hintText;
  }

  /// 获取分割线颜色
  static Color getDividerColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .currentConfig
        .colors
        .divider;
  }

  /// 获取边框颜色
  static Color getBorderColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .currentConfig
        .colors
        .border;
  }

  /// 获取状态颜色
  static StatusColors getStatusColors(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .currentConfig
        .colors
        .status;
  }

  /// 获取圆角配置
  static ThemeShapes getShapes(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .currentConfig
        .shapes;
  }

  /// 获取间距配置
  static ThemeSpacing getSpacing(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false)
        .currentConfig
        .spacing;
  }
}

/// 模块索引与名称映射（用于底部导航栏索引转换）
class KnModuleMapper {
  static const Map<int, String> indexToModule = {
    0: 'lesson',
    1: 'fee',
    2: 'archive',
    3: 'summary',
    4: 'setting',
  };

  /// 根据导航索引获取模块名称
  static String getModuleName(int index) {
    return indexToModule[index] ?? 'lesson';
  }

  /// 根据导航索引获取模块颜色
  static ModuleColor getModuleColorByIndex(BuildContext context, int index) {
    final moduleName = getModuleName(index);
    return Provider.of<ThemeProvider>(context, listen: false)
        .getModuleColor(moduleName);
  }

  /// 根据导航索引获取模块渐变色
  static List<Color> getModuleGradientByIndex(BuildContext context, int index) {
    final moduleColor = getModuleColorByIndex(context, index);
    return [moduleColor.primary, moduleColor.light];
  }
}
