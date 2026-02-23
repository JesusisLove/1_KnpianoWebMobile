// [Flutter页面主题改造] 2026-01-17 新增ThemeData构建器
// 将ThemeConfig转换为Flutter原生ThemeData
// [Flutter页面主题改造] 2026-01-18 添加Google Fonts支持(童话风格字体)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/theme_config.dart';

/// 将 ThemeConfig 转换为 Flutter ThemeData
class ThemeDataBuilder {
  static ThemeData build(ThemeConfig config) {
    final colors = config.colors;
    final typography = config.typography;
    final shapes = config.shapes;

    // [Flutter页面主题改造] 2026-01-18 获取字体名称，支持Google Fonts
    final String? googleFontFamily = typography.useGoogleFont
        ? typography.fontFamily['web'] ?? typography.fontFamily['android']
        : null;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // 色彩方案
      colorScheme: ColorScheme.light(
        primary: colors.modules.lesson.primary,
        secondary: colors.modules.fee.primary,
        surface: colors.cardBackground,
        error: colors.status.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: colors.primaryText,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: colors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colors.modules.lesson.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: typography.h3.size,
          fontWeight: typography.h3.fontWeight,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(shapes.appBarRadius),
          ),
        ),
      ),

      // 卡片
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.cardRadius),
          side: BorderSide(color: colors.border, width: 1),
        ),
      ),

      // 按钮
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.modules.lesson.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shapes.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryText,
          side: BorderSide(color: colors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shapes.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.modules.lesson.primary,
          textStyle: TextStyle(
            fontSize: typography.body2.size,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 输入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.cardBackground,
        hintStyle: TextStyle(color: colors.hintText),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapes.inputRadius),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapes.inputRadius),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapes.inputRadius),
          borderSide:
              BorderSide(color: colors.modules.lesson.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapes.inputRadius),
          borderSide: BorderSide(color: colors.status.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapes.inputRadius),
          borderSide: BorderSide(color: colors.status.error, width: 2),
        ),
      ),

      // 底部导航
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.cardBackground,
        selectedItemColor: colors.modules.lesson.primary,
        unselectedItemColor: colors.hintText,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // 对话框
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.dialogRadius),
        ),
        titleTextStyle: TextStyle(
          fontSize: typography.h2.size,
          fontWeight: typography.h2.fontWeight,
          color: colors.primaryText,
        ),
        contentTextStyle: TextStyle(
          fontSize: typography.body1.size,
          fontWeight: typography.body1.fontWeight,
          color: colors.primaryText,
        ),
      ),

      // 分割线
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),

      // 浮动按钮
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.modules.lesson.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.buttonRadius),
        ),
      ),

      // 列表项
      listTileTheme: ListTileThemeData(
        tileColor: colors.cardBackground,
        textColor: colors.primaryText,
        iconColor: colors.secondaryText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.cardRadius / 2),
        ),
      ),

      // [Flutter页面主题改造] 2026-01-18 文字主题，支持Google Fonts
      textTheme: _buildTextTheme(colors, typography, googleFontFamily),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: colors.modules.lesson.light,
        labelStyle: TextStyle(
          fontSize: typography.caption.size,
          color: colors.primaryText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.buttonRadius / 2),
        ),
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: colors.modules.lesson.primary,
        unselectedLabelColor: colors.hintText,
        labelStyle: TextStyle(
          fontSize: typography.body2.size,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: typography.body2.size,
          fontWeight: FontWeight.normal,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: colors.modules.lesson.primary,
            width: 3,
          ),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.primaryText,
        contentTextStyle: TextStyle(
          fontSize: typography.body2.size,
          color: colors.cardBackground,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.inputRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // [Flutter页面主题改造] 2026-01-18 构建文字主题，支持Google Fonts (ZCOOL KuaiLe for 童话风格)
  static TextTheme _buildTextTheme(
    ThemeColors colors,
    ThemeTypography typography,
    String? googleFontFamily,
  ) {
    // 基础文字主题
    TextTheme baseTextTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: typography.h1.size,
        fontWeight: typography.h1.fontWeight,
        color: colors.primaryText,
        height: typography.h1.height,
      ),
      headlineMedium: TextStyle(
        fontSize: typography.h2.size,
        fontWeight: typography.h2.fontWeight,
        color: colors.primaryText,
        height: typography.h2.height,
      ),
      headlineSmall: TextStyle(
        fontSize: typography.h3.size,
        fontWeight: typography.h3.fontWeight,
        color: colors.primaryText,
        height: typography.h3.height,
      ),
      bodyLarge: TextStyle(
        fontSize: typography.body1.size,
        fontWeight: typography.body1.fontWeight,
        color: colors.primaryText,
        height: typography.body1.height,
      ),
      bodyMedium: TextStyle(
        fontSize: typography.body2.size,
        fontWeight: typography.body2.fontWeight,
        color: colors.secondaryText,
        height: typography.body2.height,
      ),
      bodySmall: TextStyle(
        fontSize: typography.caption.size,
        fontWeight: typography.caption.fontWeight,
        color: colors.hintText,
        height: typography.caption.height,
      ),
      labelLarge: TextStyle(
        fontSize: typography.body1.size,
        fontWeight: FontWeight.w600,
        color: colors.primaryText,
      ),
      labelMedium: TextStyle(
        fontSize: typography.body2.size,
        fontWeight: FontWeight.w500,
        color: colors.secondaryText,
      ),
      labelSmall: TextStyle(
        fontSize: typography.caption.size,
        fontWeight: FontWeight.w500,
        color: colors.hintText,
      ),
    );

    // 如果使用Google Fonts，应用字体
    if (googleFontFamily != null) {
      // 使用ZCOOL KuaiLe字体（童话风格手写体）
      if (googleFontFamily == 'ZCOOL KuaiLe') {
        return GoogleFonts.zcoolKuaiLeTextTheme(baseTextTheme);
      }
      // 可以在这里添加其他Google Fonts支持
    }

    return baseTextTheme;
  }
}
