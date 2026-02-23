// [Flutter页面主题改造] 2026-01-17 新增主题配置模型类
// 从JSON配置文件映射主题设置，支持多主题切换

import 'package:flutter/material.dart';

/// 主题配置模型 - 从JSON映射
class ThemeConfig {
  final String id;
  final String name;
  final String nameEn;
  final String description;
  final String version;
  final String author;

  final ThemeColors colors;
  final ThemeTypography typography;
  final ThemeShapes shapes;
  final ThemeSpacing spacing;
  final ThemeShadows shadows;
  final ThemeAnimations animations;
  final ThemeIcons icons;

  ThemeConfig({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.version,
    required this.author,
    required this.colors,
    required this.typography,
    required this.shapes,
    required this.spacing,
    required this.shadows,
    required this.animations,
    required this.icons,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      id: json['id'],
      name: json['name'],
      nameEn: json['nameEn'],
      description: json['description'],
      version: json['version'],
      author: json['author'],
      colors: ThemeColors.fromJson(json['colors']),
      typography: ThemeTypography.fromJson(json['typography']),
      shapes: ThemeShapes.fromJson(json['shapes']),
      spacing: ThemeSpacing.fromJson(json['spacing']),
      shadows: ThemeShadows.fromJson(json['shadows']),
      animations: ThemeAnimations.fromJson(json['animations']),
      icons: ThemeIcons.fromJson(json['icons']),
    );
  }
}

/// 颜色配置
class ThemeColors {
  final Color background;
  final Color cardBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color hintText;
  final Color divider;
  final Color border;
  final ModuleColors modules;
  final StatusColors status;
  // [Flutter页面主题改造] 2026-01-20 添加课程卡片颜色配置
  final LessonCardColors lessonCard;

  ThemeColors({
    required this.background,
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.hintText,
    required this.divider,
    required this.border,
    required this.modules,
    required this.status,
    required this.lessonCard,
  });

  factory ThemeColors.fromJson(Map<String, dynamic> json) {
    return ThemeColors(
      background: _parseColor(json['background']),
      cardBackground: _parseColor(json['cardBackground']),
      primaryText: _parseColor(json['primaryText']),
      secondaryText: _parseColor(json['secondaryText']),
      hintText: _parseColor(json['hintText']),
      divider: _parseColor(json['divider']),
      border: _parseColor(json['border']),
      modules: ModuleColors.fromJson(json['modules']),
      status: StatusColors.fromJson(json['status']),
      lessonCard: LessonCardColors.fromJson(json['lessonCard'] ?? {}),
    );
  }

  static Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

/// 模块颜色
class ModuleColors {
  final ModuleColor lesson;
  final ModuleColor fee;
  final ModuleColor archive;
  final ModuleColor summary;
  final ModuleColor setting;

  ModuleColors({
    required this.lesson,
    required this.fee,
    required this.archive,
    required this.summary,
    required this.setting,
  });

  factory ModuleColors.fromJson(Map<String, dynamic> json) {
    return ModuleColors(
      lesson: ModuleColor.fromJson(json['lesson']),
      fee: ModuleColor.fromJson(json['fee']),
      archive: ModuleColor.fromJson(json['archive']),
      summary: ModuleColor.fromJson(json['summary']),
      setting: ModuleColor.fromJson(json['setting']),
    );
  }
}

class ModuleColor {
  final Color primary;
  final Color light;

  ModuleColor({required this.primary, required this.light});

  factory ModuleColor.fromJson(Map<String, dynamic> json) {
    return ModuleColor(
      primary: ThemeColors._parseColor(json['primary']),
      light: ThemeColors._parseColor(json['light']),
    );
  }
}

/// 状态颜色
class StatusColors {
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color disabled;

  StatusColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.disabled,
  });

  factory StatusColors.fromJson(Map<String, dynamic> json) {
    return StatusColors(
      success: ThemeColors._parseColor(json['success']),
      warning: ThemeColors._parseColor(json['warning']),
      error: ThemeColors._parseColor(json['error']),
      info: ThemeColors._parseColor(json['info']),
      disabled: ThemeColors._parseColor(json['disabled']),
    );
  }
}

/// [Flutter页面主题改造] 2026-01-20 课程卡片颜色配置
/// 用于区分不同类型课程的背景颜色
class LessonCardColors {
  final Color planned;  // 计划课背景色
  final Color extra;    // 加课背景色
  final Color hourly;   // 课时课背景色

  LessonCardColors({
    required this.planned,
    required this.extra,
    required this.hourly,
  });

  factory LessonCardColors.fromJson(Map<String, dynamic> json) {
    return LessonCardColors(
      planned: ThemeColors._parseColor(json['planned'] ?? '#BBDEFB'),
      extra: ThemeColors._parseColor(json['extra'] ?? '#FFCDD2'),
      hourly: ThemeColors._parseColor(json['hourly'] ?? '#C8E6C9'),
    );
  }
}

/// 字体配置
class ThemeTypography {
  final Map<String, String> fontFamily;
  // [Flutter页面主题改造] 2026-01-18 添加Google字体支持标志
  final bool useGoogleFont;
  final TextStyleConfig h1;
  final TextStyleConfig h2;
  final TextStyleConfig h3;
  final TextStyleConfig body1;
  final TextStyleConfig body2;
  final TextStyleConfig caption;
  // [Flutter页面主题改造] 2026-01-19 添加元素样式配置
  final ElementStyles elements;

  ThemeTypography({
    required this.fontFamily,
    this.useGoogleFont = false,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.body1,
    required this.body2,
    required this.caption,
    required this.elements,
  });

  factory ThemeTypography.fromJson(Map<String, dynamic> json) {
    return ThemeTypography(
      fontFamily: Map<String, String>.from(json['fontFamily']),
      useGoogleFont: json['useGoogleFont'] ?? false,
      h1: TextStyleConfig.fromJson(json['h1']),
      h2: TextStyleConfig.fromJson(json['h2']),
      h3: TextStyleConfig.fromJson(json['h3']),
      body1: TextStyleConfig.fromJson(json['body1']),
      body2: TextStyleConfig.fromJson(json['body2']),
      caption: TextStyleConfig.fromJson(json['caption']),
      elements: ElementStyles.fromJson(json['elements'] ?? {}),
    );
  }
}

/// [Flutter页面主题改造] 2026-01-19 元素样式配置
/// [Flutter页面主题改造] 2026-01-20 新增moduleTitle和moduleSubtitle
class ElementStyles {
  final ElementStyleConfig cardTitle;
  final ElementStyleConfig listItemTitle;
  final ElementStyleConfig tableHeader;
  final ElementStyleConfig buttonText;
  final ElementStyleConfig dialogTitle;
  final ElementStyleConfig pickerItem;
  final ElementStyleConfig appBarTitle;
  final ElementStyleConfig moduleTitle;     // 模块主页标题（如"上课管理"）
  final ElementStyleConfig moduleSubtitle;  // 模块主页副标题（如"课程安排与进度跟踪"）

  ElementStyles({
    required this.cardTitle,
    required this.listItemTitle,
    required this.tableHeader,
    required this.buttonText,
    required this.dialogTitle,
    required this.pickerItem,
    required this.appBarTitle,
    required this.moduleTitle,
    required this.moduleSubtitle,
  });

  factory ElementStyles.fromJson(Map<String, dynamic> json) {
    return ElementStyles(
      cardTitle: ElementStyleConfig.fromJson(json['cardTitle'] ?? {'weight': 'bold', 'style': 'normal'}),
      listItemTitle: ElementStyleConfig.fromJson(json['listItemTitle'] ?? {'weight': 'bold', 'style': 'normal'}),
      tableHeader: ElementStyleConfig.fromJson(json['tableHeader'] ?? {'weight': 'bold', 'style': 'normal'}),
      buttonText: ElementStyleConfig.fromJson(json['buttonText'] ?? {'weight': 'bold', 'style': 'normal'}),
      dialogTitle: ElementStyleConfig.fromJson(json['dialogTitle'] ?? {'weight': 'bold', 'style': 'normal'}),
      pickerItem: ElementStyleConfig.fromJson(json['pickerItem'] ?? {'weight': 'regular', 'style': 'normal'}),
      appBarTitle: ElementStyleConfig.fromJson(json['appBarTitle'] ?? {'weight': 'bold', 'style': 'normal'}),
      moduleTitle: ElementStyleConfig.fromJson(json['moduleTitle'] ?? {'weight': 'bold', 'style': 'normal'}),
      moduleSubtitle: ElementStyleConfig.fromJson(json['moduleSubtitle'] ?? {'weight': 'regular', 'style': 'normal'}),
    );
  }
}

/// 元素样式配置项
class ElementStyleConfig {
  final String weight;
  final String style;

  ElementStyleConfig({
    required this.weight,
    required this.style,
  });

  factory ElementStyleConfig.fromJson(Map<String, dynamic> json) {
    return ElementStyleConfig(
      weight: json['weight'] ?? 'regular',
      style: json['style'] ?? 'normal',
    );
  }

  FontWeight get fontWeight {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case 'medium':
        return FontWeight.w500;
      case 'w700':
        return FontWeight.w700;
      case 'regular':
        return FontWeight.normal;
      case 'light':
        return FontWeight.w300;
      default:
        return FontWeight.normal;
    }
  }

  FontStyle get fontStyle {
    return style == 'italic' ? FontStyle.italic : FontStyle.normal;
  }
}

class TextStyleConfig {
  final double size;
  final String weight;
  final double height;

  TextStyleConfig({
    required this.size,
    required this.weight,
    required this.height,
  });

  factory TextStyleConfig.fromJson(Map<String, dynamic> json) {
    return TextStyleConfig(
      size: json['size'].toDouble(),
      weight: json['weight'],
      height: json['height'].toDouble(),
    );
  }

  FontWeight get fontWeight {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case 'medium':
        return FontWeight.w500;
      case 'regular':
        return FontWeight.normal;
      case 'light':
        return FontWeight.w300;
      default:
        return FontWeight.normal;
    }
  }
}

/// 形状配置
class ThemeShapes {
  final double cardRadius;
  final double buttonRadius;
  final double inputRadius;
  final double dialogRadius;
  final double appBarRadius;

  ThemeShapes({
    required this.cardRadius,
    required this.buttonRadius,
    required this.inputRadius,
    required this.dialogRadius,
    required this.appBarRadius,
  });

  factory ThemeShapes.fromJson(Map<String, dynamic> json) {
    return ThemeShapes(
      cardRadius: json['cardRadius'].toDouble(),
      buttonRadius: json['buttonRadius'].toDouble(),
      inputRadius: json['inputRadius'].toDouble(),
      dialogRadius: json['dialogRadius'].toDouble(),
      appBarRadius: json['appBarRadius'].toDouble(),
    );
  }
}

/// 间距配置
class ThemeSpacing {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  ThemeSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
  });

  factory ThemeSpacing.fromJson(Map<String, dynamic> json) {
    return ThemeSpacing(
      xs: json['xs'].toDouble(),
      sm: json['sm'].toDouble(),
      md: json['md'].toDouble(),
      lg: json['lg'].toDouble(),
      xl: json['xl'].toDouble(),
      xxl: json['xxl'].toDouble(),
      xxxl: json['xxxl'].toDouble(),
    );
  }
}

/// 阴影配置
class ThemeShadows {
  final ShadowConfig card;
  final ShadowConfig button;

  ThemeShadows({required this.card, required this.button});

  factory ThemeShadows.fromJson(Map<String, dynamic> json) {
    return ThemeShadows(
      card: ShadowConfig.fromJson(json['card']),
      button: ShadowConfig.fromJson(json['button']),
    );
  }
}

class ShadowConfig {
  final Color color;
  final double blur;
  final double offsetY;

  ShadowConfig({
    required this.color,
    required this.blur,
    required this.offsetY,
  });

  factory ShadowConfig.fromJson(Map<String, dynamic> json) {
    return ShadowConfig(
      color: ThemeColors._parseColor(json['color']),
      blur: json['blur'].toDouble(),
      offsetY: json['offsetY'].toDouble(),
    );
  }

  BoxShadow toBoxShadow() {
    return BoxShadow(
      color: color,
      blurRadius: blur,
      offset: Offset(0, offsetY),
    );
  }
}

/// 动画配置
class ThemeAnimations {
  final int pageTransition;
  final int cardExpand;
  final int buttonPress;
  final int listItemAppear;

  ThemeAnimations({
    required this.pageTransition,
    required this.cardExpand,
    required this.buttonPress,
    required this.listItemAppear,
  });

  factory ThemeAnimations.fromJson(Map<String, dynamic> json) {
    return ThemeAnimations(
      pageTransition: json['pageTransition'],
      cardExpand: json['cardExpand'],
      buttonPress: json['buttonPress'],
      listItemAppear: json['listItemAppear'],
    );
  }
}

/// 图标配置
class ThemeIcons {
  final String style;
  final IconSizes sizes;

  ThemeIcons({required this.style, required this.sizes});

  factory ThemeIcons.fromJson(Map<String, dynamic> json) {
    return ThemeIcons(
      style: json['style'],
      sizes: IconSizes.fromJson(json['sizes']),
    );
  }
}

class IconSizes {
  final double navigation;
  final double listItem;
  final double card;
  final double button;

  IconSizes({
    required this.navigation,
    required this.listItem,
    required this.card,
    required this.button,
  });

  factory IconSizes.fromJson(Map<String, dynamic> json) {
    return IconSizes(
      navigation: json['navigation'].toDouble(),
      listItem: json['listItem'].toDouble(),
      card: json['card'].toDouble(),
      button: json['button'].toDouble(),
    );
  }
}
