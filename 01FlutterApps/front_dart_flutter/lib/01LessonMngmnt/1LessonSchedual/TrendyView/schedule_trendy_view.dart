// [课程表新潮版] 2026-02-13 新潮版主视图
// 组合周导航、日期表头、时间网格和图例

import 'package:flutter/material.dart';
import '../Kn01L002LsnBean.dart';
import 'schedule_week_navigator.dart';
import 'schedule_date_header.dart';
import 'schedule_time_grid.dart';
import 'lesson_type_colors.dart';
import 'lesson_detail_sheet.dart';

/// 课程表新潮版主视图
class ScheduleTrendyView extends StatefulWidget {
  final List<Kn01L002LsnBean> lessons;
  final Color? themeColor;
  final Function(DateTime date, int hour, int minute)? onAddLesson;
  final Function(Kn01L002LsnBean lesson)? onEditLesson;
  final Function(Kn01L002LsnBean lesson)? onRescheduleLesson;
  final Function(Kn01L002LsnBean lesson)? onCancelReschedule;
  final Function(Kn01L002LsnBean lesson)? onDeleteLesson;
  final Function(Kn01L002LsnBean lesson)? onSignLesson;     // [课程表新潮版] 2026-02-13 签到
  final Function(Kn01L002LsnBean lesson)? onRestoreLesson;  // [课程表新潮版] 2026-02-13 撤销签到
  final Function(Kn01L002LsnBean lesson)? onNoteLesson;     // [课程表新潮版] 2026-02-13 备注
  final Function(DateTime weekStart)? onWeekChanged;
  final DateTime? initialWeekStart; // [周同步] 2026-02-16 支持从外部传入初始周
  final String? highlightStuId;  // [闪烁动画] 2026-02-19 高亮显示的学生ID
  final String? highlightTime;   // [闪烁动画] 2026-02-19 高亮显示的时间（HH:mm）

  const ScheduleTrendyView({
    super.key,
    required this.lessons,
    this.themeColor,
    this.onAddLesson,
    this.onEditLesson,
    this.onRescheduleLesson,
    this.onCancelReschedule,
    this.onDeleteLesson,
    this.onSignLesson,
    this.onRestoreLesson,
    this.onNoteLesson,
    this.onWeekChanged,
    this.initialWeekStart,
    this.highlightStuId,
    this.highlightTime,
  });

  @override
  State<ScheduleTrendyView> createState() => _ScheduleTrendyViewState();
}

class _ScheduleTrendyViewState extends State<ScheduleTrendyView> {
  late DateTime _currentWeekStart;

  // 时间列宽度
  static const double timeColumnWidth = 50.0;

  @override
  void initState() {
    super.initState();
    // [周同步] 2026-02-16 优先使用外部传入的初始周，否则使用当前日期
    _currentWeekStart = widget.initialWeekStart ?? _getWeekStart(DateTime.now());
  }

  // [周同步] 2026-02-16 当外部传入的initialWeekStart变化时，同步更新
  @override
  void didUpdateWidget(covariant ScheduleTrendyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialWeekStart != null &&
        oldWidget.initialWeekStart != widget.initialWeekStart) {
      setState(() {
        _currentWeekStart = widget.initialWeekStart!;
      });
    }
  }

  /// 获取指定日期所在周的周一
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1=周一, 7=周日
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  void _goToPreviousWeek() {
    final newWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    setState(() {
      _currentWeekStart = newWeekStart;
    });
    widget.onWeekChanged?.call(newWeekStart);
  }

  void _goToNextWeek() {
    final newWeekStart = _currentWeekStart.add(const Duration(days: 7));
    setState(() {
      _currentWeekStart = newWeekStart;
    });
    widget.onWeekChanged?.call(newWeekStart);
  }

  /// 筛选当前周的课程
  List<Kn01L002LsnBean> _filterLessonsForCurrentWeek() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 7));

    return widget.lessons.where((lesson) {
      // 获取有效日期（调课日期优先）
      final effectiveDateStr = lesson.lsnAdjustedDate.isNotEmpty
          ? lesson.lsnAdjustedDate
          : lesson.schedualDate;

      if (effectiveDateStr.isEmpty) return false;

      try {
        final effectiveDate = DateTime.parse(effectiveDateStr.replaceFirst(' ', 'T'));
        return effectiveDate.isAfter(_currentWeekStart.subtract(const Duration(days: 1))) &&
            effectiveDate.isBefore(weekEnd);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weekLessons = _filterLessonsForCurrentWeek();

    return Column(
      children: [
        // 周导航
        ScheduleWeekNavigator(
          currentWeekStart: _currentWeekStart,
          onPreviousWeek: _goToPreviousWeek,
          onNextWeek: _goToNextWeek,
          arrowColor: widget.themeColor,
        ),

        // 日期表头
        ScheduleDateHeader(
          weekStart: _currentWeekStart,
          timeColumnWidth: timeColumnWidth,
        ),

        // [Bug Fix] 2026-02-14 无论是否有课程，都显示时间网格，用户才能点击空白格子排课
        Expanded(
          child: ScheduleTimeGrid(
            weekStart: _currentWeekStart,
            lessons: weekLessons,
            timeColumnWidth: timeColumnWidth,
            onEmptyCellTap: widget.onAddLesson,
            onLessonTap: _showLessonDetail,
            highlightStuId: widget.highlightStuId,   // [闪烁动画] 2026-02-19
            highlightTime: widget.highlightTime,     // [闪烁动画] 2026-02-19
          ),
        ),

        // 图例
        _buildLegend(),
      ],
    );
  }

  /// 构建图例
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('图例: ', style: TextStyle(fontSize: 12)),
          ...LessonTypeColors.legendItems.map((item) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(item.label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// 显示课程详情
  /// [集体排课] 2026-02-14 改为接收课程列表
  void _showLessonDetail(List<Kn01L002LsnBean> lessons) {
    if (lessons.isEmpty) return;

    // 判断是否有调课课程（用于显示取消调课选项）
    final hasAdjustedLesson = lessons.any((l) => l.lsnAdjustedDate.isNotEmpty);

    LessonDetailSheet.show(
      context: context,
      lessons: lessons, // [集体排课] 传递课程列表
      onEdit: (l) {
        widget.onEditLesson?.call(l);
      },
      onReschedule: (l) {
        widget.onRescheduleLesson?.call(l);
      },
      onCancelReschedule: hasAdjustedLesson
          ? (l) {
              widget.onCancelReschedule?.call(l);
            }
          : null,
      onDelete: (l) {
        widget.onDeleteLesson?.call(l);
      },
      // [课程表新潮版] 2026-02-13 签到/撤销签到/备注
      onSign: widget.onSignLesson != null
          ? (l) {
              widget.onSignLesson?.call(l);
            }
          : null,
      onRestore: widget.onRestoreLesson != null
          ? (l) {
              widget.onRestoreLesson?.call(l);
            }
          : null,
      onNote: widget.onNoteLesson != null
          ? (l) {
              widget.onNoteLesson?.call(l);
            }
          : null,
      // [集体排课] 2026-02-14 追加学生排课，复用onAddLesson回调
      onAddGroupMember: widget.onAddLesson,
    );
  }
}
