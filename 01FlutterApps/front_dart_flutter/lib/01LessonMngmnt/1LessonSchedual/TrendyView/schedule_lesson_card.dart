// [课程表新潮版] 2026-02-13 课程卡片组件
// 显示单个课程的信息，背景色由lessonType和是否调课决定

import 'package:flutter/material.dart';
import 'lesson_type_colors.dart';

/// 课程卡片组件
/// 课程卡片高度根据课程时长动态计算：(时长/15) × 24px
class ScheduleLessonCard extends StatelessWidget {
  final String stuName;
  final String subjectName;
  final int? lessonType;
  final bool isAdjusted; // 是否是调课
  final bool isSigned; // [课程表新潮版] 2026-02-13 是否已签到
  final String? memo; // [课程表新潮版] 2026-02-13 备注
  final int cellSpan; // 占用的格子数（时长/15）
  final VoidCallback? onTap;
  final bool isCompact; // [集体排课] 2026-02-14 紧凑模式（多学生并排时使用）

  // 单元格高度配置（与固定排课一致）
  static const double cellHeight = 24.0;

  const ScheduleLessonCard({
    super.key,
    required this.stuName,
    required this.subjectName,
    this.lessonType,
    this.isAdjusted = false,
    this.isSigned = false,
    this.memo,
    this.cellSpan = 3, // 默认45分钟 = 3格
    this.onTap,
    this.isCompact = false, // [集体排课] 2026-02-14 默认非紧凑模式
  });

  @override
  Widget build(BuildContext context) {
    // 获取背景色（签到 > 调课 > lessonType）
    final bgColor = LessonTypeColors.getColor(lessonType,
        isAdjusted: isAdjusted, isSigned: isSigned);

    // 计算卡片高度
    final cardHeight = cellSpan * cellHeight - 1;

    // [集体排课] 2026-02-14 紧凑模式：只显示姓名，减小内边距
    if (isCompact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: cardHeight,
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 1,
                offset: const Offset(0, 0.5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              stuName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // 正常模式
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 学生姓名
            Text(
              stuName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // 科目名称（如果空间足够）
            if (cellSpan >= 2)
              Text(
                subjectName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // 备注（如果有且空间足够）
            if (memo != null && memo!.isNotEmpty && cellSpan >= 3)
              Text(
                '备注: $memo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // 调课标识（如果是调课）
            if (isAdjusted && cellSpan >= 3)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  '调',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
