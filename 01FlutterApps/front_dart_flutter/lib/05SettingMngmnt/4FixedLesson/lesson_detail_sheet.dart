// [固定排课新潮界面] 2026-02-12 课程详情面板（BottomSheet）
// [集体排课] 2026-02-14 添加"集体上课"复选框和"追加学生"按钮

import 'package:flutter/material.dart';
import 'KnFixLsn001Bean.dart';
import 'subject_colors.dart';

/// 课程详情面板（BottomSheet）
/// [集体排课] 2026-02-14 重构为 StatefulWidget
class LessonDetailSheet extends StatefulWidget {
  final String weekDay;
  final String timeSlot; // "09:00"
  final List<KnFixLsn001Bean> lessons;
  final Function(KnFixLsn001Bean) onEdit;
  final Function(KnFixLsn001Bean) onDelete;
  final Function(String weekDay, String timeSlot)? onAddGroupMember; // [集体排课] 追加学生

  const LessonDetailSheet({
    super.key,
    required this.weekDay,
    required this.timeSlot,
    required this.lessons,
    required this.onEdit,
    required this.onDelete,
    this.onAddGroupMember,
  });

  /// 显示详情面板
  static Future<void> show({
    required BuildContext context,
    required String weekDay,
    required String timeSlot,
    required List<KnFixLsn001Bean> lessons,
    required Function(KnFixLsn001Bean) onEdit,
    required Function(KnFixLsn001Bean) onDelete,
    Function(String weekDay, String timeSlot)? onAddGroupMember,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonDetailSheet(
        weekDay: weekDay,
        timeSlot: timeSlot,
        lessons: lessons,
        onEdit: onEdit,
        onDelete: onDelete,
        onAddGroupMember: onAddGroupMember,
      ),
    );
  }

  @override
  State<LessonDetailSheet> createState() => _LessonDetailSheetState();
}

class _LessonDetailSheetState extends State<LessonDetailSheet> {
  // [集体排课] 2026-02-14 集体上课复选框状态
  bool _isGroupLesson = false;

  @override
  Widget build(BuildContext context) {
    final weekDayName = _getWeekDayName(widget.weekDay);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$weekDayName ${widget.timeSlot}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // [集体排课] 多学生时显示人数徽章
                if (widget.lessons.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.lessons.length}人',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  )
                else
                  Text(
                    '${widget.lessons.length} 节课',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),
          // 课程列表
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.lessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final lesson = widget.lessons[index];
                return _buildLessonCard(context, lesson);
              },
            ),
          ),
          // [集体排课] 2026-02-14 集体上课区域
          // 注：复选框始终显示，让用户可以追加学生到任何时间段
          if (widget.onAddGroupMember != null) ...[
            const Divider(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // 集体上课复选框
                  CheckboxListTile(
                    title: const Text('集体上课'),
                    subtitle: const Text('勾选后可追加其他学生到此时间段', style: TextStyle(fontSize: 12)),
                    value: _isGroupLesson,
                    onChanged: (v) => setState(() => _isGroupLesson = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  // 追加学生按钮（仅勾选后显示）
                  if (_isGroupLesson)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onAddGroupMember?.call(widget.weekDay, widget.timeSlot);
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('追加其他学生排课'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          // 关闭按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ),
          ),
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, KnFixLsn001Bean lesson) {
    final bgColor = SubjectColors.getColor(lesson.subjectName);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // 科目颜色标识
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // 信息区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      lesson.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.music_note, size: 14, color: bgColor),
                    const SizedBox(width: 4),
                    Text(
                      lesson.subjectName,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.classDuration}分钟',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 操作按钮
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onEdit(lesson);
            },
            tooltip: '编辑',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete(lesson);
            },
            tooltip: '删除',
          ),
        ],
      ),
    );
  }

  String _getWeekDayName(String weekDay) {
    const names = {
      'Mon': '周一',
      'Tue': '周二',
      'Wed': '周三',
      'Thu': '周四',
      'Fri': '周五',
      'Sat': '周六',
      'Sun': '周日',
    };
    return names[weekDay] ?? weekDay;
  }
}
