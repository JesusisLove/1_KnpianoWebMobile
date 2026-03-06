// [课程表新潮版] 2026-02-13 时间网格组件
// 显示08:00-22:45的15分钟间隔网格，复用固定排课的网格逻辑
// [两步调课] 2026-03-02 长按选中悬浮 → 长按目标格落地执行

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../ApiConfig/KnApiConfig.dart';
import '../../../Constants.dart';
import '../ConflictInfo.dart';
import '../ConflictWarningDialog.dart';
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
  final VoidCallback? onScheduleUpdated; // [两步调课] 2026-03-02 调课成功后通知父组件刷新

  const ScheduleTimeGrid({
    super.key,
    required this.weekStart,
    required this.lessons,
    this.timeColumnWidth = 50.0,
    this.onEmptyCellTap,
    this.onLessonTap,
    this.highlightStuId,
    this.highlightTime,
    this.onScheduleUpdated,
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

  // [两步调课] 2026-03-02 悬浮状态
  Kn01L002LsnBean? _floatingLesson;  // 第一步选中的待调课卡片（null=未选中）
  Timer? _floatingBlinkTimer;         // 悬浮卡片闪烁计时器
  bool _floatingVisible = true;       // 闪烁切换标志（true=完全可见/false=半透明）
  // [手势改善] 2026-03-04 长按中途手指滑出单元格的标志（true=已滑出，抬手不触发）
  bool _longPressLeftCell = false;

  // [课程表新潮版] 2026-02-14 Excel风格：按下时暂存待执行的动作
  // [集体排课] 2026-02-14 改为课程列表
  List<Kn01L002LsnBean>? _pendingLessonListTap;
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
    _floatingBlinkTimer?.cancel(); // [两步调课] 2026-03-02
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

        return Column(
          children: [
            // [手势改善] 2026-03-06 悬浮状态提示条：显示已选中的课程信息和操作提示
            if (_floatingLesson != null) _buildFloatingHintBar(),
            // 网格主体
            Expanded(
              child: SingleChildScrollView(
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
              ),
            ),
          ],
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
  /// [两步调课] 2026-03-02 长按进入/落地悬浮状态
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

        // [两步调课] 2026-03-02 判断是否是悬浮中的卡片
        final isFloating = _floatingLesson != null &&
            _floatingLesson!.lessonId == lesson.lessonId;

        // [手势改善] 2026-03-05 悬浮状态时卡片高度缩小为1格，露出被遮挡的网格
        final effectiveCellSpan = isFloating ? 1 : cellSpan;
        Widget cardWidget = ScheduleLessonCard(
          stuName: lesson.stuName,
          subjectName: lesson.subjectName,
          lessonType: lesson.lessonType,
          isAdjusted: isAdjusted,
          isSigned: isSigned,
          memo: lesson.memo,
          cellSpan: effectiveCellSpan,
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

        // [两步调课] 2026-03-02 悬浮状态：半透明 + 蓝色闪烁边框
        if (isFloating) {
          cardWidget = Opacity(
            opacity: _floatingVisible ? 1.0 : 0.35,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: cardWidget,
            ),
          );
        }

        blocks.add(
          Positioned(
            left: left,
            top: top,
            width: cardWidth,
            child: GestureDetector(
              // [课程表新潮版] 2026-02-14 Excel风格：按下显示光标，松开才执行动作
              // [两步调课] 悬浮中短按卡片不做任何操作（防止误触）
              onTapDown: (_) {
                if (_floatingLesson != null) return;
                _selectCell(dayIndex, slotIndex);
                _pendingLessonListTap = lessonList;
              },
              onTapUp: (_) {
                if (_floatingLesson != null) return;
                _releasePress();
                if (_pendingLessonListTap != null) {
                  widget.onLessonTap?.call(_pendingLessonListTap!);
                  _pendingLessonListTap = null;
                }
              },
              onTapCancel: () {
                if (_floatingLesson != null) return;
                _releasePress();
                _pendingLessonListTap = null;
              },
              // [两步调课] 2026-03-02 长按手势
              onLongPressStart: isSigned ? null : (details) {
                _pendingLessonListTap = null;
                if (_floatingLesson == null) {
                  // 第一步：进入悬浮
                  _releasePress();
                  _startFloating(lesson);
                } else if (_floatingLesson!.lessonId != lesson.lessonId) {
                  // 第二步：落地到此卡片所在时间格
                  _releasePress();
                  _placeLesson(context, dayIndex, slotIndex);
                }
                // 长按悬浮中的同一张卡片：不做任何操作
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
  /// [两步调课] 2026-03-02 悬浮中短按取消；长按落地
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
        // [手势改善] 2026-03-05 悬浮状态时，悬浮课程只占用第0格，其余格子变为可点击的空白格
        final isFloatingGroup = _floatingLesson != null &&
            lessonList.any((l) => l.lessonId == _floatingLesson!.lessonId);
        final effectiveSpan = isFloatingGroup ? 1 : cellSpan;
        for (int i = 0; i < effectiveSpan; i++) {
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
              },
              onTapUp: (_) {
                _releasePress();
                if (_floatingLesson != null) {
                  // [两步调课] 悬浮中短按空格 → 取消悬浮
                  _cancelFloating();
                }
              },
              onTapCancel: () {
                _releasePress();
              },
              // [手势改善] 2026-03-04 长按空格：仅显示视觉反馈，重置滑出标志
              onLongPressStart: (_) {
                _longPressLeftCell = false;
                _selectCell(currentDayIndex, currentSlotIndex);
              },
              // [手势改善] 2026-03-04 检测手指是否滑出单元格边界
              // 滑出 → 取消视觉反馈，抬手不触发任何操作
              onLongPressMoveUpdate: (details) {
                if (!_longPressLeftCell) {
                  final p = details.localPosition;
                  if (p.dx < 0 || p.dx > columnWidth ||
                      p.dy < 0 || p.dy > ScheduleTimeGrid.cellHeight) {
                    _longPressLeftCell = true;
                    _releasePress();
                  }
                }
              },
              // [手势改善] 2026-03-04 抬手：已滑出→不触发；悬浮→落地；非悬浮→弹出新增窗口
              onLongPressEnd: (_) {
                _releasePress();
                if (_longPressLeftCell) {
                  _longPressLeftCell = false;
                  return;
                }
                if (_floatingLesson != null) {
                  _placeLesson(context, currentDayIndex, currentSlotIndex);
                } else {
                  widget.onEmptyCellTap?.call(tapDate, tapHour, tapMinute);
                }
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

  // ─────────────────────────────────────────────
  // [两步调课] 2026-03-02 悬浮与落地方法
  // ─────────────────────────────────────────────

  /// 第一步：进入悬浮状态（卡片半透明 + 蓝色闪烁边框）
  void _startFloating(Kn01L002LsnBean lesson) {
    _floatingBlinkTimer?.cancel();
    setState(() {
      _floatingLesson = lesson;
      _floatingVisible = true;
    });
    // 持续闪烁，直到取消或落地
    _floatingBlinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _floatingVisible = !_floatingVisible;
        });
      }
    });
  }

  /// 取消悬浮状态（短按空白格触发）
  void _cancelFloating() {
    _floatingBlinkTimer?.cancel();
    setState(() {
      _floatingLesson = null;
      _floatingVisible = true;
    });
    _releasePress();
  }

  /// 第二步：落地到目标格（长按后手指松开时触发）
  void _placeLesson(BuildContext ctx, int targetDayIdx, int targetSlotIdx) {
    final lesson = _floatingLesson;
    _cancelFloating(); // 先清理悬浮状态

    if (lesson == null) return;

    // 计算目标日期时间
    final slots = timeSlots;
    if (targetSlotIdx < 0 || targetSlotIdx >= slots.length) return;
    final targetDate = widget.weekStart.add(Duration(days: targetDayIdx));
    final timeParts = slots[targetSlotIdx].split(':');
    final targetHour = int.parse(timeParts[0]);
    final targetMinute = int.parse(timeParts[1]);
    final targetDateTime = DateTime(
      targetDate.year, targetDate.month, targetDate.day,
      targetHour, targetMinute,
    );

    // 获取课程当前有效日期（用于「原地不动」判定）
    final effectiveDateStr = lesson.lsnAdjustedDate.isNotEmpty
        ? lesson.lsnAdjustedDate
        : lesson.schedualDate;
    final effectiveDt = _parseDateTime(effectiveDateStr);
    if (effectiveDt == null) return;

    // 目标与当前位置完全相同则不处理
    if (targetDateTime == effectiveDt) return;

    // 格式化目标日期时间字符串
    final formatted =
        '${targetDate.year.toString().padLeft(4, '0')}-'
        '${targetDate.month.toString().padLeft(2, '0')}-'
        '${targetDate.day.toString().padLeft(2, '0')} '
        '${targetHour.toString().padLeft(2, '0')}:'
        '${targetMinute.toString().padLeft(2, '0')}';

    // [调课逻辑改善] 2026-03-03 始终与原排课日期（schedualDate）比较，决定更新字段
    // 同一天 → 更新 schedualDate，清除 lsnAdjustedDate
    // 不同天 → 更新 lsnAdjustedDate（标记调课）
    final schedualDt = _parseDateTime(lesson.schedualDate);
    if (schedualDt == null) return;
    final schedualDateOnly =
        DateTime(schedualDt.year, schedualDt.month, schedualDt.day);
    final targetDateOnly =
        DateTime(targetDate.year, targetDate.month, targetDate.day);

    if (targetDateOnly == schedualDateOnly) {
      // 目标日期 == 原排课日期 → 只改时间，更新 schedualDate 并清除 lsnAdjustedDate
      _saveSameDayTimeChange(ctx, lesson.lessonId, formatted, lesson.classDuration);
    } else {
      // 目标日期 != 原排课日期 → 调课，更新 lsnAdjustedDate
      _saveReschedule(ctx, lesson.lessonId, formatted, lesson.classDuration);
    }
  }

  // ─────────────────────────────────────────────
  // [两步调课] 2026-03-02 API 调用方法
  // ─────────────────────────────────────────────

  /// 同一天时间调整：更新 schedualDate（不标记为调课，卡片不变橙色）
  Future<void> _saveSameDayTimeChange(
    BuildContext ctx,
    String lessonId,
    String newDateTimeStr,
    int classDuration, {
    bool forceOverlap = false,
  }) async {
    try {
      final url = '${KnConfig.apiBaseUrl}${Constants.apiUpdateSchedualDate}';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lessonId': lessonId,
          'schedualDate': newDateTimeStr,
          'forceOverlap': forceOverlap,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200 || response.statusCode == 409) {
        final responseData = json.decode(decodedBody);
        if (responseData is Map<String, dynamic>) {
          final result = ConflictCheckResult.fromJson(responseData);
          if (result.success) {
            widget.onScheduleUpdated?.call();
          } else if (result.hasConflict) {
            final timeParts = newDateTimeStr.split(' ').last;
            final endTime = _calcEndTime(timeParts, classDuration);
            final newSchedule = NewScheduleInfo(startTime: timeParts, endTime: endTime);
            if (result.isSameStudentConflict) {
              if (ctx.mounted) {
                await ConflictWarningDialog.showSameStudentConflict(
                    ctx, result.conflicts, newSchedule: newSchedule);
              }
            } else {
              if (ctx.mounted) {
                final confirmed = await ConflictWarningDialog.show(
                    ctx, result.conflicts, newSchedule: newSchedule);
                if (confirmed && ctx.mounted) {
                  await _saveSameDayTimeChange(
                      ctx, lessonId, newDateTimeStr, classDuration,
                      forceOverlap: true);
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  /// 调课（日期改变）：更新 lsnAdjustedDate
  Future<void> _saveReschedule(
    BuildContext ctx,
    String lessonId,
    String newDateTimeStr,
    int classDuration, {
    bool forceOverlap = false,
  }) async {
    try {
      final url = '${KnConfig.apiBaseUrl}${Constants.apiUpdateLessonTime}';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lessonId': lessonId,
          'lsnAdjustedDate': newDateTimeStr,
          'forceOverlap': forceOverlap,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200 || response.statusCode == 409) {
        final responseData = json.decode(decodedBody);
        if (responseData is Map<String, dynamic>) {
          final result = ConflictCheckResult.fromJson(responseData);
          if (result.success) {
            widget.onScheduleUpdated?.call();
          } else if (result.hasConflict) {
            final timeParts = newDateTimeStr.split(' ').last;
            final endTime = _calcEndTime(timeParts, classDuration);
            final newSchedule = NewScheduleInfo(startTime: timeParts, endTime: endTime);
            if (result.isSameStudentConflict) {
              if (ctx.mounted) {
                await ConflictWarningDialog.showSameStudentConflict(
                    ctx, result.conflicts, newSchedule: newSchedule);
              }
            } else {
              if (ctx.mounted) {
                final confirmed = await ConflictWarningDialog.show(
                    ctx, result.conflicts, newSchedule: newSchedule);
                if (confirmed && ctx.mounted) {
                  await _saveReschedule(
                      ctx, lessonId, newDateTimeStr, classDuration,
                      forceOverlap: true);
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  /// 计算结束时间（开始时间 + 课程时长）
  String _calcEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    if (parts.length != 2) return startTime;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final total = h * 60 + m + durationMinutes;
    return '${(total ~/ 60 % 24).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────

  /// [手势改善] 2026-03-06 构建悬浮状态提示条
  Widget _buildFloatingHintBar() {
    final lesson = _floatingLesson!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.open_with_rounded, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '已选中 ${lesson.stuName} (${lesson.subjectName})　长按目标时间槽落地',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '短按空白处取消',
            style: TextStyle(fontSize: 11, color: Colors.blue.shade400),
          ),
        ],
      ),
    );
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
