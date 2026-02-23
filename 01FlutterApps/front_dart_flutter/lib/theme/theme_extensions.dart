// [Flutter页面主题改造] 2026-01-17 新增主题扩展辅助类
// 提供便捷的BuildContext扩展方法，方便页面访问主题配置
// [Flutter页面主题改造] 2026-01-18 添加选择器字体样式支持

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/theme_config.dart';
import 'providers/theme_provider.dart';

/// BuildContext扩展 - 便捷访问主题配置
extension ThemeContextExtension on BuildContext {
  /// 获取ThemeProvider
  ThemeProvider get themeProvider => Provider.of<ThemeProvider>(this);

  /// 获取ThemeProvider（不监听变化）
  ThemeProvider get themeProviderRead =>
      Provider.of<ThemeProvider>(this, listen: false);

  /// 获取当前主题配置
  ThemeConfig get themeConfig => themeProvider.currentConfig;

  /// 获取当前主题颜色
  ThemeColors get themeColors => themeConfig.colors;

  /// 获取模块颜色
  ModuleColors get moduleColors => themeColors.modules;

  /// 获取状态颜色
  StatusColors get statusColors => themeColors.status;

  /// [Flutter页面主题改造] 2026-01-20 获取课程卡片颜色
  LessonCardColors get lessonCardColors => themeColors.lessonCard;

  /// 获取间距配置
  ThemeSpacing get themeSpacing => themeConfig.spacing;

  /// 获取形状配置
  ThemeShapes get themeShapes => themeConfig.shapes;

  /// 获取阴影配置
  ThemeShadows get themeShadows => themeConfig.shadows;

  /// 获取动画配置
  ThemeAnimations get themeAnimations => themeConfig.animations;

  /// 获取图标配置
  ThemeIcons get themeIcons => themeConfig.icons;

  /// 根据模块名称获取颜色
  ModuleColor getModuleColor(String moduleName) {
    return themeProvider.getModuleColor(moduleName);
  }
}

/// 模块颜色枚举 - 用于类型安全的模块颜色获取
enum KnModule {
  lesson,
  fee,
  archive,
  summary,
  setting,
}

/// KnModule扩展
extension KnModuleExtension on KnModule {
  String get name {
    switch (this) {
      case KnModule.lesson:
        return 'lesson';
      case KnModule.fee:
        return 'fee';
      case KnModule.archive:
        return 'archive';
      case KnModule.summary:
        return 'summary';
      case KnModule.setting:
        return 'setting';
    }
  }

  /// 获取模块颜色
  ModuleColor getColor(BuildContext context) {
    return context.getModuleColor(name);
  }
}

// [Flutter页面主题改造] 2026-01-18 选择器字体样式辅助类
// [Flutter页面主题改造] 2026-01-19 改为使用JSON配置，移除硬编码判断
// [Flutter页面主题改造] 2026-01-20 添加pickerItemSelected方法，支持选中项粗体显示
/// 主题感知的选择器字体样式
class KnPickerTextStyle {
  /// 获取选择器项目的字体样式（未选中项 - 普通粗细）
  static TextStyle pickerItem(BuildContext context, {double fontSize = 20, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;
    final elementStyle = typography.elements.pickerItem;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color ?? Colors.black,
      fontWeight: elementStyle.fontWeight,
      fontStyle: elementStyle.fontStyle,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// [Flutter页面主题改造] 2026-01-20 获取选择器选中项目的字体样式（选中项 - 粗体）
  static TextStyle pickerItemSelected(BuildContext context, {double fontSize = 20, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;
    final elementStyle = typography.elements.pickerItem;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color ?? Colors.black,
      fontWeight: FontWeight.bold, // 选中项始终使用粗体
      fontStyle: elementStyle.fontStyle,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// 获取选择器按钮的字体样式（取消、确定等）
  static TextStyle pickerButton(BuildContext context, {double fontSize = 16, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;
    final elementStyle = typography.elements.buttonText;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color ?? Colors.blue,
      fontWeight: elementStyle.fontWeight,
      fontStyle: elementStyle.fontStyle,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// 获取选择器标题的字体样式
  static TextStyle pickerTitle(BuildContext context, {double fontSize = 16, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;
    final elementStyle = typography.elements.dialogTitle;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color ?? Colors.white,
      fontWeight: elementStyle.fontWeight,
      fontStyle: elementStyle.fontStyle,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }
}

// [Flutter页面主题改造] 2026-01-19 元素字体样式辅助类
/// 主题感知的元素字体样式
class KnElementTextStyle {
  /// 获取卡片标题的字体样式（如学生姓名）
  static TextStyle cardTitle(BuildContext context, {double fontSize = 18, Color? color, TextDecoration? decoration}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;
    final elementStyle = typography.elements.cardTitle;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: elementStyle.fontWeight,
      fontStyle: elementStyle.fontStyle,
      decoration: decoration,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// 获取列表项标题的字体样式
  static TextStyle listItemTitle(BuildContext context, {double fontSize = 16, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;
    final elementStyle = typography.elements.listItemTitle;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: elementStyle.fontWeight,
      fontStyle: elementStyle.fontStyle,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// 获取表头的字体样式
  static TextStyle tableHeader(BuildContext context, {double fontSize = 14, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;
    final elementStyle = typography.elements.tableHeader;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: elementStyle.fontWeight,
      fontStyle: elementStyle.fontStyle,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// 获取按钮文字的字体样式
  static TextStyle buttonText(BuildContext context, {double fontSize = 16, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;
    final elementStyle = typography.elements.buttonText;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: elementStyle.fontWeight,
      fontStyle: elementStyle.fontStyle,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// 获取对话框标题的字体样式
  static TextStyle dialogTitle(BuildContext context, {double fontSize = 16, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;
    final elementStyle = typography.elements.dialogTitle;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: elementStyle.fontWeight,
      fontStyle: elementStyle.fontStyle,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// 获取AppBar标题的字体样式
  static TextStyle appBarTitle(BuildContext context, {double fontSize = 20, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;
    final elementStyle = typography.elements.appBarTitle;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: elementStyle.fontWeight,
      fontStyle: elementStyle.fontStyle,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// [Flutter页面主题改造] 2026-01-21 获取弹出菜单项的字体样式
  /// 童话模式使用普通字重，其他模式也使用普通字重
  static TextStyle popupMenuItem(BuildContext context, {double fontSize = 17, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.normal, // 所有模式使用普通字重
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// [Flutter页面主题改造] 2026-01-21 获取对话框内容文字的字体样式
  static TextStyle dialogContent(BuildContext context, {double fontSize = 14, Color? color}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.normal,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }

  /// [Flutter页面主题改造] 2026-01-21 获取卡片内容文字的字体样式（副标题、描述等）
  static TextStyle cardBody(BuildContext context, {double fontSize = 12, Color? color, TextDecoration? decoration}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final typography = themeProvider.currentConfig.typography;

    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.normal,
      decoration: decoration,
    );

    if (typography.useGoogleFont) {
      return GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
    }
    return baseStyle;
  }
}
