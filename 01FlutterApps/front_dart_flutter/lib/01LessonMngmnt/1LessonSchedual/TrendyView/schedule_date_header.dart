// [课程表新潮版] 2026-02-13 日期表头组件
// 显示一周七天的日期，今天用特殊样式标记

import 'package:flutter/material.dart';

/// 日期表头组件
class ScheduleDateHeader extends StatelessWidget {
  final DateTime weekStart;
  final double timeColumnWidth;

  // 星期名称
  static const List<String> weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

  const ScheduleDateHeader({
    super.key,
    required this.weekStart,
    this.timeColumnWidth = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Container(
      height: 50,
      color: Colors.grey.shade200,
      child: Row(
        children: [
          // [课程表新潮版] 2026-02-14 左侧显示周数（如W07）
          SizedBox(
            width: timeColumnWidth,
            child: Center(
              child: Text(
                'W${_getWeekNumber(weekStart).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),

          // 7天的日期表头
          ...List.generate(7, (index) {
            final date = weekStart.add(Duration(days: index));
            final isToday = _isSameDay(date, today);

            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue.shade100 : null,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '周${weekdayNames[index]}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.blue : Colors.black87,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.month}/${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.blue : Colors.black,
                          ),
                        ),
                        if (isToday)
                          const Text(
                            '★',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// [课程表新潮版] 2026-02-14 计算ISO周数
  int _getWeekNumber(DateTime date) {
    // ISO 8601: 一年中第一个星期四所在的周为第1周
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final firstThursday = firstDayOfYear.add(
      Duration(days: (DateTime.thursday - firstDayOfYear.weekday + 7) % 7),
    );
    final firstWeekStart = firstThursday.subtract(const Duration(days: 3));

    final diff = date.difference(firstWeekStart).inDays;
    if (diff < 0) {
      // 属于上一年的最后一周
      return _getWeekNumber(DateTime(date.year - 1, 12, 31));
    }
    return (diff ~/ 7) + 1;
  }
}
