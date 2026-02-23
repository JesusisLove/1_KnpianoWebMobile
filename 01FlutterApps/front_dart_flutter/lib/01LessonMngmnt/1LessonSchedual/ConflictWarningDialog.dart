// [课程排他状态功能] 2026-02-08 冲突警告对话框
// 在排课或调课检测到时间冲突时显示警告，让老师确认是否继续

import 'package:flutter/material.dart';
import 'ConflictInfo.dart';

class ConflictWarningDialog extends StatelessWidget {
  final List<ConflictInfo> conflicts;
  final NewScheduleInfo? newSchedule; // [2026-02-12] 新排课时间，用于绘制时间轴
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConflictWarningDialog({
    super.key,
    required this.conflicts,
    this.newSchedule,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 8),
          const Text('时间冲突提醒'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('您的排课时间与以下课程重叠：'),
            const SizedBox(height: 12),
            // [2026-02-12] 时间轴可视化示意图
            if (newSchedule != null)
              _TimelineConflictWidget(
                conflicts: conflicts,
                newSchedule: newSchedule!,
              ),
            const SizedBox(height: 12),
            ...conflicts.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final conflict = entry.value;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.orange,
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '学生：${conflict.stuName}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '时间：${conflict.startTime} - ${conflict.endTime}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '集体课可以继续排课，一对一教学建议取消',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '是否继续排课？',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('确认排课'),
        ),
      ],
    );
  }

  /// 显示冲突警告对话框
  /// 返回 true 表示用户确认继续，false 表示取消
  /// [newSchedule] 新排课时间信息，用于绘制时间轴示意图
  static Future<bool> show(
    BuildContext context,
    List<ConflictInfo> conflicts, {
    NewScheduleInfo? newSchedule,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConflictWarningDialog(
        conflicts: conflicts,
        newSchedule: newSchedule,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  /// 显示同一学生冲突禁止对话框（不可继续）
  /// [newSchedule] 新排课时间信息，用于绘制时间轴示意图
  static Future<void> showSameStudentConflict(
    BuildContext context,
    List<ConflictInfo> conflicts, {
    NewScheduleInfo? newSchedule,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('排课禁止'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('同一学生在该时间段已有课程安排：'),
              const SizedBox(height: 12),
              // [2026-02-12] 时间轴可视化示意图
              if (newSchedule != null)
                _TimelineConflictWidget(
                  conflicts: conflicts,
                  newSchedule: newSchedule,
                ),
              const SizedBox(height: 12),
              ...conflicts.map((conflict) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      '${conflict.stuName}：${conflict.startTime} - ${conflict.endTime}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '同一学生不能同时上两节课，请选择其他时间',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示取消调课冲突禁止对话框
  static Future<void> showCancelRescheduleConflict(
    BuildContext context,
    String originalTime,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text('无法取消调课'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('原时间段（$originalTime）已安排其他学生的课程，无法恢复。'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '请保持当前调课状态，或选择其他时间进行调课',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// [课程排他状态功能] 2026-02-12 时间轴可视化组件
/// 显示新排课与已有课程的时间重叠情况
class _TimelineConflictWidget extends StatelessWidget {
  final List<ConflictInfo> conflicts;
  final NewScheduleInfo newSchedule;

  const _TimelineConflictWidget({
    required this.conflicts,
    required this.newSchedule,
  });

  @override
  Widget build(BuildContext context) {
    // 解析所有时间，计算时间轴范围
    final allTimes = <int>[];
    allTimes.add(_parseTimeToMinutes(newSchedule.startTime));
    allTimes.add(_parseTimeToMinutes(newSchedule.endTime));
    for (final conflict in conflicts) {
      allTimes.add(_parseTimeToMinutes(conflict.startTime));
      allTimes.add(_parseTimeToMinutes(conflict.endTime));
    }

    final minTime = allTimes.reduce((a, b) => a < b ? a : b);
    final maxTime = allTimes.reduce((a, b) => a > b ? a : b);
    final totalRange = maxTime - minTime;

    if (totalRange <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间刻度
          _buildTimeAxis(minTime, maxTime),
          const SizedBox(height: 8),
          // 已有课程（橙色）
          ...conflicts.map((conflict) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildTimeBlock(
              label: '${conflict.stuName}',
              startMinutes: _parseTimeToMinutes(conflict.startTime),
              endMinutes: _parseTimeToMinutes(conflict.endTime),
              minTime: minTime,
              totalRange: totalRange,
              color: Colors.orange.shade400,
              timeText: '${conflict.startTime}-${conflict.endTime}',
            ),
          )),
          // 新排课（蓝色斜线）
          _buildTimeBlock(
            label: newSchedule.stuName ?? '新排课',
            startMinutes: _parseTimeToMinutes(newSchedule.startTime),
            endMinutes: _parseTimeToMinutes(newSchedule.endTime),
            minTime: minTime,
            totalRange: totalRange,
            color: Colors.blue.shade400,
            isNew: true,
            timeText: '${newSchedule.startTime}-${newSchedule.endTime}',
          ),
          const SizedBox(height: 8),
          // 重叠区域标识
          _buildOverlapIndicator(minTime, totalRange),
        ],
      ),
    );
  }

  /// 解析时间字符串为分钟数（从0:00开始）
  int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  /// 格式化分钟数为时间字符串
  String _formatMinutesToTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 构建时间刻度轴（使用Row避免Stack+Positioned在AlertDialog中的问题）
  Widget _buildTimeAxis(int minTime, int maxTime) {
    // 生成时间刻度（简化为起止时间）
    final startTimeStr = _formatMinutesToTime(minTime);
    final endTimeStr = _formatMinutesToTime(maxTime);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 时间刻度行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              startTimeStr,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            Text(
              endTimeStr,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // 底部横线
        Container(height: 1, color: Colors.grey.shade400),
      ],
    );
  }

  /// 构建时间块（使用Row+Flexible避免LayoutBuilder在AlertDialog中的问题）
  Widget _buildTimeBlock({
    required String label,
    required int startMinutes,
    required int endMinutes,
    required int minTime,
    required int totalRange,
    required Color color,
    bool isNew = false,
    String? timeText,
  }) {
    // 计算左侧空白和色块的flex比例（放大100倍取整避免浮点误差）
    final leftFlex = ((startMinutes - minTime) * 100 / totalRange).round();
    final blockFlex = ((endMinutes - startMinutes) * 100 / totalRange).round();
    final rightFlex = 100 - leftFlex - blockFlex;

    return SizedBox(
      height: 28,
      child: Row(
        children: [
          // 左侧空白
          if (leftFlex > 0) Spacer(flex: leftFlex),
          // 色块
          Flexible(
            flex: blockFlex > 0 ? blockFlex : 1,
            child: Container(
              decoration: BoxDecoration(
                color: isNew ? null : color,
                gradient: isNew
                    ? LinearGradient(
                        colors: [color.withOpacity(0.7), color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(4),
                border: isNew ? Border.all(color: color, width: 2) : null,
              ),
              // 斜线效果（新排课）
              child: isNew
                  ? CustomPaint(
                      painter: _DiagonalStripePainter(color: color),
                      child: Center(
                        child: Text(
                          '$label $timeText',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 2),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        '$label $timeText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ),
          // 右侧空白
          if (rightFlex > 0) Spacer(flex: rightFlex),
        ],
      ),
    );
  }

  /// 构建重叠区域指示器（使用Row+Flexible避免LayoutBuilder在AlertDialog中的问题）
  Widget _buildOverlapIndicator(int minTime, int totalRange) {
    // 计算新排课与所有冲突课程的重叠区域
    final newStart = _parseTimeToMinutes(newSchedule.startTime);
    final newEnd = _parseTimeToMinutes(newSchedule.endTime);

    final overlaps = <Map<String, int>>[];
    for (final conflict in conflicts) {
      final conflictStart = _parseTimeToMinutes(conflict.startTime);
      final conflictEnd = _parseTimeToMinutes(conflict.endTime);

      // 计算重叠区域
      final overlapStart = newStart > conflictStart ? newStart : conflictStart;
      final overlapEnd = newEnd < conflictEnd ? newEnd : conflictEnd;

      if (overlapStart < overlapEnd) {
        overlaps.add({'start': overlapStart, 'end': overlapEnd});
      }
    }

    if (overlaps.isEmpty) return const SizedBox.shrink();

    // 取第一个重叠区域显示（多个重叠通常是连续的）
    final overlap = overlaps.first;
    final overlapMinutes = overlap['end']! - overlap['start']!;

    // 计算flex比例
    final leftFlex = ((overlap['start']! - minTime) * 100 / totalRange).round();
    final blockFlex = ((overlap['end']! - overlap['start']!) * 100 / totalRange).round();
    final rightFlex = 100 - leftFlex - blockFlex;

    return SizedBox(
      height: 20,
      child: Row(
        children: [
          // 左侧空白
          if (leftFlex > 0) Spacer(flex: leftFlex),
          // 重叠区域色块
          Flexible(
            flex: blockFlex > 0 ? blockFlex : 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '重叠${overlapMinutes}分钟',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // 右侧空白
          if (rightFlex > 0) Spacer(flex: rightFlex),
        ],
      ),
    );
  }
}

/// 斜线填充绘制器（用于新排课色块）
class _DiagonalStripePainter extends CustomPainter {
  final Color color;

  _DiagonalStripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const spacing = 6.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
