// [课程表新潮版] 2026-02-13 课程类型颜色定义
// 根据lessonType字段值返回对应的背景颜色
// [Bug Fix] 2026-02-15 修正lessonType与数据库的映射关系
// 数据库中：pay_style=0(按课时支付)→lesson_type=0, pay_style=1(按月支付)→lesson_type=1

import 'package:flutter/material.dart';

/// 课程类型颜色配置
class LessonTypeColors {
  // lessonType常量定义
  // 注意：数据库中按课时缴费的lesson_type=0（来自pay_style=0的映射）
  static const int typePayPerLessonDB = 0;  // 按课时缴费（数据库值）
  static const int typeScheduled = 1;       // 计划课（按月付费）
  static const int typeExtra = 2;           // 加时课
  static const int typePayPerLesson = 3;    // 按课时缴费（兼容旧值）

  // 颜色定义
  static const Color scheduledColor = Color(0xFF81D4FA);     // 天蓝色 Colors.lightBlue.shade200
  static const Color extraColor = Color(0xFFF48FB1);         // 粉红色 Colors.pink.shade200
  static const Color payPerLessonColor = Color(0xFFC5E1A5);  // 浅绿色 Colors.lightGreen.shade200
  static const Color adjustedColor = Color(0xFFFFE0B2);      // 调课：浅橙色 Colors.orange.shade100
  static const Color signedColor = Color(0xFF9E9E9E);        // 已签到：深灰色 Colors.grey.shade500
  static const Color defaultColor = Color(0xFFE0E0E0);       // 默认灰色

  /// 根据lessonType和状态获取背景颜色
  /// 优先级：已签到 > 调课 > lessonType
  static Color getColor(int? lessonType, {bool isAdjusted = false, bool isSigned = false}) {
    // 已签到颜色优先级最高
    if (isSigned) {
      return signedColor;
    }
    // 调课颜色次之
    if (isAdjusted) {
      return adjustedColor;
    }

    switch (lessonType) {
      case typePayPerLessonDB: // 按课时缴费（数据库值=0）
        return payPerLessonColor;
      case typeScheduled:
        return scheduledColor;
      case typeExtra:
        return extraColor;
      case typePayPerLesson: // 按课时缴费（兼容旧值=3）
        return payPerLessonColor;
      default:
        return defaultColor;
    }
  }

  /// 根据lessonType获取课程类型名称
  static String getTypeName(int? lessonType) {
    switch (lessonType) {
      case typePayPerLessonDB: // 按课时缴费（数据库值=0）
        return '按课时缴费';
      case typeScheduled:
        return '计划课';
      case typeExtra:
        return '加时课';
      case typePayPerLesson: // 按课时缴费（兼容旧值=3）
        return '按课时缴费';
      default:
        return '未知类型';
    }
  }

  /// 图例数据
  static List<LegendItem> get legendItems => [
    LegendItem(color: scheduledColor, label: '计划课'),
    LegendItem(color: extraColor, label: '加时课'),
    LegendItem(color: payPerLessonColor, label: '按课时缴费'),
    LegendItem(color: adjustedColor, label: '调课'),
    LegendItem(color: signedColor, label: '已签到'),
  ];
}

/// 图例项
class LegendItem {
  final Color color;
  final String label;

  LegendItem({required this.color, required this.label});
}
