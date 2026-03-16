// [课程表新潮版] 2026-02-13 新潮版主视图
// 组合周导航、日期表头、时间网格和图例

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Kn01L002LsnBean.dart';
import 'schedule_week_navigator.dart';
import 'schedule_date_header.dart';
import 'schedule_time_grid.dart';
import 'lesson_type_colors.dart';
import 'lesson_detail_sheet.dart';
import 'cell_height_notifier.dart';

/// 课程表新潮版主视图
class ScheduleTrendyView extends StatefulWidget {
  final List<Kn01L002LsnBean> lessons;
  final Color? themeColor;
  final Function(DateTime date, int hour, int minute)? onAddLesson;
  // [集体课条件判断] 2026-02-27 集体追加学生排课专用回调（与onAddLesson区分，以传递isGroupLessonScheduling=true）
  final Function(DateTime date, int hour, int minute)? onAddGroupLesson;
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
  final VoidCallback? onScheduleUpdated; // [两步调课] 2026-03-02 调课成功后通知父组件刷新

  const ScheduleTrendyView({
    super.key,
    required this.lessons,
    this.themeColor,
    this.onAddLesson,
    this.onAddGroupLesson,
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
    this.onScheduleUpdated,
  });

  @override
  State<ScheduleTrendyView> createState() => _ScheduleTrendyViewState();
}

class _ScheduleTrendyViewState extends State<ScheduleTrendyView> {
  late DateTime _currentWeekStart;

  // 时间列宽度
  static const double timeColumnWidth = 50.0;

  // [捏合缩放手势] 2026-03-16 单元格高度 Provider（课程表新潮版独立实例）
  final CellHeightNotifier _cellHeightNotifier = CellHeightNotifier();
  // [捏合模式隔离] 2026-03-16 捏合开始时的基准：两指距离和单元格高度
  double _pinchStartDistance = 0.0;
  double _pinchStartCellHeight = CellHeightNotifier.defaultHeight;
  // [捏合缩放手势] 2026-03-16 动态最小高度 + 双指圆圈位置追踪
  double _minCellHeight = CellHeightNotifier.minHeight;
  final Map<int, Offset> _pointerPositions = {};
  // [捏合模式隔离] 2026-03-16 捏合锁定标志：第2根手指按下→true，全部手指离开→false
  bool _isPinchMode = false;

  @override
  void initState() {
    super.initState();
    // [周同步] 2026-02-16 优先使用外部传入的初始周，否则使用当前日期
    _currentWeekStart = widget.initialWeekStart ?? _getWeekStart(DateTime.now());
  }

  @override
  void dispose() {
    _cellHeightNotifier.dispose();
    super.dispose();
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

    // [捏合缩放手势] 2026-03-16 以 ChangeNotifierProvider 包装整个视图，
    // ScheduleTimeGrid 可从 Provider 读取动态 cellHeight
    return ChangeNotifierProvider.value(
      value: _cellHeightNotifier,
      child: Column(
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
          // [捏合缩放手势] 2026-03-16 LayoutBuilder 计算动态最小高度
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                // 动态最小高度：8:00-23:00共60格恰好填满可用区域
                const int totalSlots =
                    (ScheduleTimeGrid.endHour - ScheduleTimeGrid.startHour) *
                        (60 ~/ ScheduleTimeGrid.intervalMinutes);
                _minCellHeight = constraints.maxHeight / totalSlots;
                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    setState(() {
                      _pointerPositions[event.pointer] = event.localPosition;
                      // [捏合模式隔离] 第2根手指按下 → 进入捏合锁定，记录基准
                      if (_pointerPositions.length >= 2) {
                        _isPinchMode = true;
                        _pinchStartDistance = _calcPinchDistance();
                        _pinchStartCellHeight = _cellHeightNotifier.cellHeight;
                      }
                    });
                  },
                  onPointerMove: (event) {
                    if (!_pointerPositions.containsKey(event.pointer)) return;
                    if (_isPinchMode || _pointerPositions.length >= 2) {
                      setState(() {
                        _pointerPositions[event.pointer] = event.localPosition;
                        // [捏合模式隔离] Listener 直接计算缩放，完全绕开手势竞技场
                        if (_isPinchMode &&
                            _pointerPositions.length >= 2 &&
                            _pinchStartDistance > 0) {
                          final newH = (_pinchStartCellHeight *
                                  _calcPinchDistance() /
                                  _pinchStartDistance)
                              .clamp(_minCellHeight,
                                  CellHeightNotifier.maxHeight);
                          _cellHeightNotifier.update(newH);
                        }
                      });
                    } else {
                      _pointerPositions[event.pointer] = event.localPosition;
                    }
                  },
                  onPointerUp: (event) {
                    setState(() {
                      _pointerPositions.remove(event.pointer);
                      // [捏合模式隔离] 全部手指离开 → 解除捏合锁定
                      if (_pointerPositions.isEmpty) {
                        _isPinchMode = false;
                      }
                    });
                  },
                  onPointerCancel: (event) {
                    setState(() {
                      _pointerPositions.remove(event.pointer);
                      if (_pointerPositions.isEmpty) {
                        _isPinchMode = false;
                      }
                    });
                  },
                  child: Stack(
                      children: [
                        ScheduleTimeGrid(
                          weekStart: _currentWeekStart,
                          lessons: weekLessons,
                          timeColumnWidth: timeColumnWidth,
                          onEmptyCellTap: widget.onAddLesson,
                          onLessonTap: _showLessonDetail,
                          highlightStuId: widget.highlightStuId,   // [闪烁动画] 2026-02-19
                          highlightTime: widget.highlightTime,     // [闪烁动画] 2026-02-19
                          onScheduleUpdated: widget.onScheduleUpdated, // [两步调课] 2026-03-02
                          // [捏合模式隔离] 2026-03-16 捏合锁定时禁止内部滚动
                          scrollPhysics: _isPinchMode ? const NeverScrollableScrollPhysics() : null,
                        ),
                        // [捏合缩放手势] 2026-03-16 双指触碰时显示两个对称圆圈
                        if (_pointerPositions.length >= 2)
                          IgnorePointer(
                            child: ClipRect(
                              child: Stack(
                                children: _pointerPositions.values
                                    .map((pos) => Positioned(
                                          left: pos.dx - 50,
                                          top: pos.dy - 50,
                                          child: Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.blue.withOpacity(0.25),
                                              border: Border.all(
                                                color: Colors.blue.shade400,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                );
              },
            ),
          ),

          // 图例
          _buildLegend(),
        ],
      ),
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

  /// [捏合模式隔离] 2026-03-16 计算两指间的欧氏距离
  double _calcPinchDistance() {
    final positions = _pointerPositions.values.toList();
    if (positions.length < 2) return 0.0;
    return (positions[0] - positions[1]).distance;
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
      // [集体课条件判断] 2026-02-27 追加学生排课使用专用回调，以传递isGroupLessonScheduling=true
      onAddGroupMember: widget.onAddGroupLesson ?? widget.onAddLesson,
    );
  }
}
