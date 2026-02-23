// [固定排课新潮界面] 2026-02-12 科目颜色映射工具类

import 'package:flutter/material.dart';

/// 科目颜色映射工具类
/// 为不同科目提供一致的颜色标识
class SubjectColors {
  /// 预定义的科目颜色
  static const Map<String, Color> _colorMap = {
    '钢琴': Color(0xFF2196F3), // 蓝色
    '小提琴': Color(0xFFFF9800), // 橙色
    '吉他': Color(0xFF4CAF50), // 绿色
    '声乐': Color(0xFF9C27B0), // 紫色
    '乐理': Color(0xFF00BCD4), // 青色
    '大提琴': Color(0xFFE91E63), // 粉色
    '古筝': Color(0xFF795548), // 棕色
    '架子鼓': Color(0xFF607D8B), // 灰蓝色
    '长笛': Color(0xFF8BC34A), // 浅绿
    '萨克斯': Color(0xFFFF5722), // 深橙
  };

  /// 备用颜色列表（用于未预定义的科目）
  static const List<Color> _fallbackColors = [
    Color(0xFF3F51B5), // 靛蓝
    Color(0xFF009688), // 蓝绿
    Color(0xFFCDDC39), // 黄绿
    Color(0xFFFF5722), // 深橙
    Color(0xFF673AB7), // 深紫
    Color(0xFF03A9F4), // 浅蓝
    Color(0xFFFFC107), // 琥珀
    Color(0xFF8D6E63), // 棕灰
  ];

  /// 获取科目颜色
  /// - 如果科目在预定义列表中，返回预定义颜色
  /// - 否则根据科目名称哈希值选择备用颜色
  static Color getColor(String subjectName) {
    if (_colorMap.containsKey(subjectName)) {
      return _colorMap[subjectName]!;
    }
    // 使用哈希值选择备用颜色，确保同一科目总是返回相同颜色
    final index = subjectName.hashCode.abs() % _fallbackColors.length;
    return _fallbackColors[index];
  }

  /// 获取科目文字颜色（在深色背景上使用白色，浅色背景上使用黑色）
  static Color getTextColor(String subjectName) {
    final bgColor = getColor(subjectName);
    // 计算亮度，决定文字颜色
    final luminance = bgColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// 获取所有预定义的科目和颜色（用于图例显示）
  static Map<String, Color> get allColors => Map.unmodifiable(_colorMap);
}
