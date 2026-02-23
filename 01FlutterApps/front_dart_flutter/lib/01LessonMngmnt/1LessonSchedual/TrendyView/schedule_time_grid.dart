// [课程表新潮版] 2026-02-13 时间网格组件
// 显示08:00-22:45的15分钟间隔网格，复用固定排课的网格逻辑

import 'dart:async';
import 'package:flutter/material.dart';
import '../Kn01L002LsnBean.dart';
import 'schedule_lesson_card.dart';

/// 时间网格组件
class ScheduleTimeGrid extends StatefulWidget {
  final DateTime weekStart;
  final List<Kn01L002LsnBean> lessons;
  final double timeColumnWidth;
  final Function(DateTime date, int hour, int minute)? onEmptyCellTap;
  final Function(List<Kn01L002LsnBean> lessons)? onLessonTap; // [集体排课] 2026-02-14 改为传递课程列表
  final String? highlightStuId;  // [闪烁动画] 2026-02-19 高亮显示的学生ID
  final String? highlightTime;   // [闪烁动画] 2026-02-19 高亮显示的时间（HH:mm）

  const ScheduleTimeGrid({
    super.key,
    required this.weekStart,
    required this.lessons,
    this.timeColumnWidth = 50.0,
    this.onEmptyCellTap,
    this.onLessonTap,
    this.highlightStuId,
    this.highlightTime,
  });

  // 时间配置（与固定排课一致）
  static const int startHour = 8;
  static const int endHour = 23; // [Bug修复] 2026-02-19 延伸到22:30（endHour=23生成到22:45）
  static const int intervalMinutes = 15;
  static const double cellHeight = 24.0;

  @override
  State<ScheduleTimeGrid> createState() => _ScheduleTimeGridState();
}

class _ScheduleTimeGridState extends State<ScheduleTimeGrid>
    with SingleTickerProviderStateMixin {
  // 选中单元格的位置
  int? _selectedDayIndex;
  int? _selectedSlotIndex;

  // [时间轴高亮] 2026-02-15 按下时高亮时间轴线（红色加粗），松开恢复
  bool _isPressing = false;

  // [闪烁动画] 2026-02-19 高亮学生卡片闪烁（与传统版CalendarPage一致）
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _blinkTimer;

  // [自动滚动] 2026-02-19 滚动到被查找学生卡片的位置
  final ScrollController _scrollController = ScrollController();

  // [课程表新潮版] 2026-02-14 Excel风格：按下时暂存待执行的动作
  // [集体排课] 2026-02-14 改为课程列表
  List<Kn01L002LsnBean>? _pendingLessonListTap;
  // 待执行的空单元格点击信息
  DateTime? _pendingEmptyDate;
  int? _pendingEmptyHour;
  int? _pendingEmptyMinute;

  @override
  void initState() {
    super.initState();
    // [闪烁动画] 2026-02-19 初始化动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);

    // 如果有高亮参数，启动闪烁 + 自动滚动
    if (widget.highlightStuId != null && widget.highlightTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startBlinking();
        _scrollToHighlightedLesson();
      });
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // [自动滚动] 2026-02-19 滚动到被查找学生卡片的位置，使其显示在屏幕中央
  void _scrollToHighlightedLesson() {
    if (widget.highlightTime == null) return;

    // 从 highlightTime（如 "14:30"）计算 slotIndex
    final parts = widget.highlightTime!.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    final slotIndex = _getSlotIndex(hour, minute);
    if (slotIndex < 0) return;

    // 目标位置 = slotIndex × cellHeight
    final targetPosition = slotIndex * ScheduleTimeGrid.cellHeight;

    // 获取可视区域高度，将目标卡片居中显示
    final viewportHeight = _scrollController.position.viewportDimension;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final offset = (targetPosition - viewportHeight / 2).clamp(0.0, maxScroll);

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // [闪烁动画] 2026-02-19 启动闪烁动画（与传统版CalendarPage一致：500ms间隔，20次闪烁=10秒）
  void _startBlinking() {
    _blinkTimer?.cancel();
    _fadeController.value = 1.0;

    int blinkCount = 0;
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && blinkCount < 20) {
        setState(() {
          _fadeController.value = _fadeController.value == 0 ? 1.0 : 0.0;
        });
        blinkCount++;
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _fadeController.value = 0.0;
          });
        }
      }
    });
  }

  // [闪烁动画] 2026-02-19 判断课程是否需要高亮
  bool _isHighlightedLesson(Kn01L002LsnBean lesson) {
    if (widget.highlightStuId == null || widget.highlightTime == null) return false;
    if (lesson.stuId != widget.highlightStuId) return false;

    // 获取有效时间
    final effectiveDateStr = lesson.lsnAdjustedDate.isNotEmpty
        ? lesson.lsnAdjustedDate
        : lesson.schedualDate;
    if (effectiveDateStr.length < 16) return false;
    final timeStr = effectiveDateStr.substring(11, 16);
    return timeStr == widget.highlightTime;
  }

  /// 获取时间槽列表
  List<String> get timeSlots {
    final slots = <String>[];
    for (int h = ScheduleTimeGrid.startHour; h < ScheduleTimeGrid.endHour; h++) {
      for (int m = 0; m < 60; m += ScheduleTimeGrid.intervalMinutes) {
        slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }

  /// 按(日期, 开始时间, 时长, 科目)分组课程
  /// [集体上课] 2026-02-14 修改分组逻辑：只有同时间+同时长+同科目的课程才会并排显示
  Map<String, List<Kn01L002LsnBean>> _groupLessons() {
    final grouped = <String, List<Kn01L002LsnBean>>{};

    for (final lesson in widget.lessons) {
      // 获取有效日期（调课日期优先）
      final effectiveDateStr = lesson.lsnAdjustedDate.isNotEmpty
          ? lesson.lsnAdjustedDate
          : lesson.schedualDate;

      if (effectiveDateStr.isEmpty) continue;

      // 解析日期和时间
      final effectiveDate = _parseDateTime(effectiveDateStr);
      if (effectiveDate == null) continue;

      // 检查是否在当前周
      final dayIndex = _getDayIndex(effectiveDate);
      if (dayIndex < 0 || dayIndex > 6) continue;

      // 获取时间槽
      final timeStr = '${effectiveDate.hour.toString().padLeft(2, '0')}:${effectiveDate.minute.toString().padLeft(2, '0')}';

      // [集体上课] 按时间+时长+科目分组
      final duration = lesson.classDuration > 0 ? lesson.classDuration : 45;
      final key = '${dayIndex}_${timeStr}_${duration}_${lesson.subjectId}';
      grouped.putIfAbsent(key, () => []).add(lesson);
    }

    return grouped;
  }

  /// 解析日期时间字符串
  DateTime? _parseDateTime(String dateStr) {
    try {
      // 尝试解析 "yyyy-MM-dd HH:mm" 格式
      return DateTime.parse(dateStr.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  /// 获取日期在当前周的索引（0=周一, 6=周日）
  int _getDayIndex(DateTime date) {
    final startOfWeek = DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day);
    final diff = date.difference(startOfWeek).inDays;
    if (diff >= 0 && diff <= 6) {
      return diff;
    }
    return -1;
  }

  /// 获取时间槽索引
  int _getSlotIndex(int hour, int minute) {
    final slotMinute = (minute ~/ ScheduleTimeGrid.intervalMinutes) * ScheduleTimeGrid.intervalMinutes;
    return ((hour - ScheduleTimeGrid.startHour) * 60 + slotMinute) ~/ ScheduleTimeGrid.intervalMinutes;
  }

  /// 计算课程占用的格子数
  int _getCellSpan(int classDuration) {
    return (classDuration / ScheduleTimeGrid.intervalMinutes).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final groupedLessons = _groupLessons();
    final slots = timeSlots;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - widget.timeColumnWidth) / 7;
        final gridHeight = slots.length * ScheduleTimeGrid.cellHeight;

        return SingleChildScrollView(
          controller: _scrollController, // [自动滚动] 2026-02-19
          child: SizedBox(
            height: gridHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 时间列
                _buildTimeColumn(slots),
                // 网格主体
                Expanded(
                  child: Stack(
                    children: [
                      // 底层：网格线
                      _buildGridLines(slots, columnWidth),
                      // 上层：课程色块
                      ..._buildLessonBlocks(groupedLessons, columnWidth),
                      // 空闲格子点击区域
                      ..._buildEmptyCellTapAreas(slots, groupedLessons, columnWidth),
                      // 选中边框
                      if (_selectedDayIndex != null && _selectedSlotIndex != null)
                        _buildSelectionBorder(columnWidth),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建时间列
  /// [时间轴高亮] 2026-02-15 按下时选中行的时间刻度变红加粗，松开恢复
  Widget _buildTimeColumn(List<String> slots) {
    return SizedBox(
      width: widget.timeColumnWidth,
      child: Column(
        children: slots.asMap().entries.map((entry) {
          final index = entry.key;
          final slot = entry.value;
          final parts = slot.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          // 重要时间点（12:00中午、18:00傍晚）
          final isImportantTime = (hour == 12 || hour == 18) && minute == 0;

          // [时间轴高亮] 2026-02-15 按下时当前行的时间刻度高亮红色
          final isHighlighted = _isPressing && _selectedSlotIndex == index;

          // 整点显示完整时间，非整点只显示分钟
          String displayText;
          if (minute == 0) {
            displayText = slot;
          } else {
            displayText = minute.toString().padLeft(2, '0');
          }

          // [时间轴高亮] 按下时高亮为红色加粗，否则保持原样式
          final textStyle = isHighlighted
              ? const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                )
              : TextStyle(
                  fontSize: isImportantTime ? 12 : 10,
                  fontWeight: isImportantTime ? FontWeight.bold : FontWeight.normal,
                  color: isImportantTime ? Colors.grey.shade800 : Colors.grey.shade600,
                );

          return Container(
            height: ScheduleTimeGrid.cellHeight,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 4),
            child: Transform.translate(
              offset: Offset(0, isImportantTime || isHighlighted ? -8 : -7),
              child: Text(
                // [时间轴高亮] 高亮时显示完整时间（如 "13:30"），方便用户确认
                isHighlighted ? slot : displayText,
                style: textStyle,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建网格线
  /// [时间轴高亮] 2026-02-15 按下时选中行的时间轴线变红加粗，松开恢复
  Widget _buildGridLines(List<String> slots, double columnWidth) {
    return Column(
      children: slots.asMap().entries.map((entry) {
        final index = entry.key;
        final slot = slots[index];
        final parts = slot.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        // [时间轴高亮] 2026-02-15 按下时当前行的时间轴线高亮红色
        final isHighlighted = _isPressing && _selectedSlotIndex == index;

        // 线条粗细
        final isImportantHourLine = minute == 0 && (hour == 12 || hour == 18);
        final isHourLine = minute == 0;
        double lineWidth;
        Color lineColor;
        if (isHighlighted) {
          lineWidth = 2.5;  // 按下时高亮加粗
          lineColor = Colors.red;
        } else if (isImportantHourLine) {
          lineWidth = 2.0;
          lineColor = Colors.grey.shade500;
        } else if (isHourLine) {
          lineWidth = 1.0;
          lineColor = Colors.grey.shade400;
        } else {
          lineWidth = 0.5;
          lineColor = Colors.grey.shade200;
        }

        return Container(
          height: ScheduleTimeGrid.cellHeight,
          decoration: BoxDecoration(
            border: Border(
              top: index == 0 ? BorderSide.none : BorderSide(color: lineColor, width: lineWidth),
            ),
          ),
          child: Row(
            children: List.generate(7, (dayIndex) {
              return Container(
                width: columnWidth,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade400, width: 1.0),
                  ),
                ),
              );
            }),
          ),
        );
      }).toList(),
    );
  }

  /// 构建课程色块
  /// [集体排课] 2026-02-14 支持多学生并排显示
  List<Widget> _buildLessonBlocks(
    Map<String, List<Kn01L002LsnBean>> groupedLessons,
    double columnWidth,
  ) {
    final blocks = <Widget>[];

    groupedLessons.forEach((key, lessonList) {
      // 解析key获取dayIndex和时间
      final parts = key.split('_');
      final dayIndex = int.parse(parts[0]);
      final timeParts = parts[1].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final slotIndex = _getSlotIndex(hour, minute);
      // 使用第一个课程的时长计算cellSpan（同时段课程时长应相同）
      final firstLesson = lessonList.first;
      final cellSpan = _getCellSpan(firstLesson.classDuration > 0 ? firstLesson.classDuration : 45);

      if (slotIndex < 0) return;

      final top = slotIndex * ScheduleTimeGrid.cellHeight;
      final studentCount = lessonList.length;
      final totalWidth = columnWidth - 2;
      final cardWidth = totalWidth / studentCount;  // 平分宽度

      // [集体排课] 2026-02-14 遍历所有学生，并排显示
      for (int i = 0; i < lessonList.length; i++) {
        final lesson = lessonList[i];
        final left = dayIndex * columnWidth + 1 + i * cardWidth;

        // 判断是否是调课
        final isAdjusted = lesson.lsnAdjustedDate.isNotEmpty;
        // [课程表新潮版] 2026-02-13 判断是否已签到
        final isSigned = lesson.scanQrDate.isNotEmpty;

        // [闪烁动画] 2026-02-19 判断是否需要高亮
        final isHighlighted = _isHighlightedLesson(lesson);

        Widget cardWidget = ScheduleLessonCard(
          stuName: lesson.stuName,
          subjectName: lesson.subjectName,
          lessonType: lesson.lessonType,
          isAdjusted: isAdjusted,
          isSigned: isSigned,
          memo: lesson.memo,
          cellSpan: cellSpan,
          isCompact: studentCount > 1,  // [集体排课] 多人时启用紧凑模式
        );

        // [闪烁动画] 2026-02-19 高亮卡片添加闪烁红色边框
        if (isHighlighted) {
          cardWidget = Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red.withOpacity(_fadeAnimation.value),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: cardWidget,
          );
        }

        blocks.add(
          Positioned(
            left: left,
            top: top,
            width: cardWidth,
            child: GestureDetector(
              // [课程表新潮版] 2026-02-14 Excel风格：按下显示光标，松开才执行动作
              onTapDown: (_) {
                _selectCell(dayIndex, slotIndex);
                _pendingLessonListTap = lessonList;  // [集体排课] 传递整个列表
              },
              onTapUp: (_) {
                _releasePress();
                if (_pendingLessonListTap != null) {
                  widget.onLessonTap?.call(_pendingLessonListTap!);
                  _pendingLessonListTap = null;
                }
              },
              onTapCancel: () {
                _releasePress();
                _pendingLessonListTap = null;
              },
              child: cardWidget,
            ),
          ),
        );
      }
    });

    return blocks;
  }

  /// 构建空闲格子点击区域
  List<Widget> _buildEmptyCellTapAreas(
    List<String> slots,
    Map<String, List<Kn01L002LsnBean>> groupedLessons,
    double columnWidth,
  ) {
    // 记录已被课程占用的格子
    final occupiedCells = <String>{};
    groupedLessons.forEach((key, lessonList) {
      final lesson = lessonList.first;
      final parts = key.split('_');
      final dayIndex = int.parse(parts[0]);
      final timeParts = parts[1].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final slotIndex = _getSlotIndex(hour, minute);
      final cellSpan = _getCellSpan(lesson.classDuration > 0 ? lesson.classDuration : 45);

      if (slotIndex >= 0) {
        for (int i = 0; i < cellSpan; i++) {
          occupiedCells.add('${dayIndex}_${slotIndex + i}');
        }
      }
    });

    final tapAreas = <Widget>[];
    for (int slotIndex = 0; slotIndex < slots.length; slotIndex++) {
      final slot = slots[slotIndex];
      final parts = slot.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final cellKey = '${dayIndex}_$slotIndex';
        if (occupiedCells.contains(cellKey)) continue;

        final currentDayIndex = dayIndex;
        final currentSlotIndex = slotIndex;

        // [课程表新潮版] 2026-02-14 Excel风格：按下显示光标，松开才执行动作
        final tapDate = widget.weekStart.add(Duration(days: currentDayIndex));
        final tapHour = hour;
        final tapMinute = minute;

        tapAreas.add(
          Positioned(
            left: dayIndex * columnWidth,
            top: slotIndex * ScheduleTimeGrid.cellHeight,
            width: columnWidth,
            height: ScheduleTimeGrid.cellHeight,
            child: GestureDetector(
              onTapDown: (_) {
                _selectCell(currentDayIndex, currentSlotIndex);
                _pendingEmptyDate = tapDate;
                _pendingEmptyHour = tapHour;
                _pendingEmptyMinute = tapMinute;
              },
              onTapUp: (_) {
                _releasePress();
                if (_pendingEmptyDate != null) {
                  widget.onEmptyCellTap?.call(
                    _pendingEmptyDate!,
                    _pendingEmptyHour!,
                    _pendingEmptyMinute!,
                  );
                  _pendingEmptyDate = null;
                  _pendingEmptyHour = null;
                  _pendingEmptyMinute = null;
                }
              },
              onTapCancel: () {
                _releasePress();
                _pendingEmptyDate = null;
                _pendingEmptyHour = null;
                _pendingEmptyMinute = null;
              },
              behavior: HitTestBehavior.opaque,
              child: Container(),
            ),
          ),
        );
      }
    }
    return tapAreas;
  }

  /// 选中单元格
  /// [时间轴高亮] 2026-02-15 同时标记按下状态
  void _selectCell(int dayIndex, int slotIndex) {
    setState(() {
      _selectedDayIndex = dayIndex;
      _selectedSlotIndex = slotIndex;
      _isPressing = true;
    });
  }

  /// [时间轴高亮] 2026-02-15 松开时恢复时间轴线
  void _releasePress() {
    if (_isPressing) {
      setState(() {
        _isPressing = false;
      });
    }
  }

  /// 构建选中边框
  /// [时间显示] 2026-02-15 在选中单元格内显示对应时间（如 "13:30"）
  Widget _buildSelectionBorder(double columnWidth) {
    final slots = timeSlots;
    final timeText = (_selectedSlotIndex! >= 0 && _selectedSlotIndex! < slots.length)
        ? slots[_selectedSlotIndex!]
        : '';

    return Positioned(
      left: _selectedDayIndex! * columnWidth,
      top: _selectedSlotIndex! * ScheduleTimeGrid.cellHeight,
      width: columnWidth,
      height: ScheduleTimeGrid.cellHeight,
      child: IgnorePointer(
        child: Stack(
          children: [
            // 绿色边框
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2.0),
              ),
            ),
            // 时间文字
            if (timeText.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
