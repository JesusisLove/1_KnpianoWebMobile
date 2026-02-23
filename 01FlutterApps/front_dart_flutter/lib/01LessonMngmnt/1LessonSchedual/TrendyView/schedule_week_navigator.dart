// [课程表新潮版] 2026-02-13 周导航组件
// 显示当前周的日期范围，提供左右箭头切换周

import 'package:flutter/material.dart';

/// 周导航组件
class ScheduleWeekNavigator extends StatelessWidget {
  final DateTime currentWeekStart;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final Color? backgroundColor;
  final Color? arrowColor;

  const ScheduleWeekNavigator({
    super.key,
    required this.currentWeekStart,
    required this.onPreviousWeek,
    required this.onNextWeek,
    this.backgroundColor,
    this.arrowColor,
  });

  @override
  Widget build(BuildContext context) {
    final weekEnd = currentWeekStart.add(const Duration(days: 6));

    // 格式化日期范围
    final startStr = '${currentWeekStart.month}月${currentWeekStart.day}日';
    final endStr = '${weekEnd.month}月${weekEnd.day}日';
    final yearStr = '${currentWeekStart.year}年';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: backgroundColor ?? Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 左箭头 - 上一周
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: arrowColor ?? Colors.blue,
              size: 28,
            ),
            onPressed: onPreviousWeek,
            tooltip: '上一周',
          ),

          // 日期范围显示
          Expanded(
            child: Text(
              '$yearStr$startStr ～ $endStr',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 右箭头 - 下一周
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: arrowColor ?? Colors.blue,
              size: 28,
            ),
            onPressed: onNextWeek,
            tooltip: '下一周',
          ),
        ],
      ),
    );
  }
}
