// [固定排课新潮界面] 2026-02-12 时间网格视图（新潮界面）
// [手势操作改善] 2026-03-03 长按空白格新增 / 两步手势调整固定排课时间

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../ApiConfig/KnApiConfig.dart';
import '../../Constants.dart';
import '../../01LessonMngmnt/1LessonSchedual/ConflictInfo.dart';
import '../../01LessonMngmnt/1LessonSchedual/ConflictWarningDialog.dart';
import 'KnFixLsn001Bean.dart';
import 'schedule_grid_cell.dart';
import 'lesson_detail_sheet.dart';
import 'knfixlsn001_add.dart'; // [新潮界面] 2026-02-12 导入新增页面
import 'subject_colors.dart';

/// 时间网格视图（新潮界面）
/// [视觉优化] 2026-02-12 改为StatefulWidget以支持单元格选中效果
class ScheduleGridView extends StatefulWidget {
  final List<KnFixLsn001Bean> lessons;
  final Color themeColor;
  final Function(KnFixLsn001Bean) onEdit;
  final Function(KnFixLsn001Bean) onDelete;
  final VoidCallback onDataChanged; // 数据变更回调（用于刷新）
  // [新潮界面] 2026-02-12 导航到新增页面所需参数
  final Color knBgColor;
  final Color knFontColor;
  final String pagePath;

  const ScheduleGridView({
    super.key,
    required this.lessons,
    required this.themeColor,
    required this.onEdit,
    required this.onDelete,
    required this.onDataChanged,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  @override
  State<ScheduleGridView> createState() => _ScheduleGridViewState();
}

class _ScheduleGridViewState extends State<ScheduleGridView> {
  // [视觉优化] 2026-02-12 选中单元格的位置（dayIndex, slotIndex）
  int? _selectedDayIndex;
  int? _selectedSlotIndex;

  // [时间轴高亮] 2026-02-15 按下时高亮时间轴线（红色加粗），松开恢复
  bool _isPressing = false;

  // [Excel风格] 2026-02-14 按下时暂存待执行的动作
  // 待执行的课程详情动作
  List<KnFixLsn001Bean>? _pendingLessonListTap;

  // [手势操作改善] 2026-03-03 两步手势调整时间 - 悬浮状态
  KnFixLsn001Bean? _floatingLesson;   // 第一步选中的待调整卡片（null=未选中）
  Timer? _floatingBlinkTimer;          // 悬浮卡片闪烁计时器
  bool _floatingVisible = true;        // 闪烁切换标志（true=完全可见/false=半透明）
  // [手势操作改善] 2026-03-03 长按中途手指滑出单元格的标志（true=已滑出，抬手不触发）
  bool _longPressLeftCell = false;

  // 时间配置
  static const int startHour = 8;
  static const int endHour = 23; // [Bug修复] 2026-02-19 延伸到22:30（endHour=23生成到22:45）
  static const int intervalMinutes = 15;
  static const double cellHeight = 24.0;
  static const double timeColumnWidth = 50.0;
  static const double headerHeight = 32.0;

  // 星期列表
  static const List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  static const List<String> weekDayNames = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日'
  ];

  /// 获取时间槽列表
  List<String> get timeSlots {
    final slots = <String>[];
    for (int h = startHour; h < endHour; h++) {
      for (int m = 0; m < 60; m += intervalMinutes) {
        slots.add(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }

  /// 按(星期, 开始时间, 时长, 科目)分组课程
  /// [集体上课] 2026-02-14 修改分组逻辑：只有同时间+同时长+同科目的课程才会并排显示
  Map<String, List<KnFixLsn001Bean>> _groupLessons() {
    final grouped = <String, List<KnFixLsn001Bean>>{};
    for (final lesson in widget.lessons) {
      // [集体上课] 按时间+时长+科目分组
      final key = '${lesson.fixedWeek}_${lesson.classTime}_${lesson.classDuration}_${lesson.subjectId}';
      grouped.putIfAbsent(key, () => []).add(lesson);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    // [Bug Fix] 2026-02-14 无论是否有课程，都显示时间网格，用户才能点击空白格子排课
    final groupedLessons = _groupLessons();
    final slots = timeSlots;

    return Column(
      children: [
        // 星期头部
        _buildHeader(context),
        // [手势改善] 2026-03-06 悬浮状态提示条：显示已选中的课程信息和操作提示
        if (_floatingLesson != null) _buildFloatingHintBar(),
        // 网格主体
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 时间列
                _buildTimeColumn(slots),
                // 课程网格
                Expanded(
                  child: _buildGrid(context, slots, groupedLessons),
                ),
              ],
            ),
          ),
        ),
        // 图例
        _buildLegend(context),
      ],
    );
  }

  /// 构建星期头部
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: headerHeight,
      color: Colors.grey.shade100,
      child: Row(
        children: [
          // 左上角空白
          const SizedBox(width: timeColumnWidth),
          // 星期标题
          ...List.generate(7, (index) {
            return Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                child: Text(
                  weekDayNames[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color:
                        _isToday(weekDays[index]) ? widget.themeColor : Colors.black87,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建时间列
  /// [视觉优化] 2026-02-12 显示所有时间刻度：整点显示完整时间，非整点只显示分钟
  /// 12:00和18:00字体加大加粗以区分中午和傍晚
  /// [时间轴高亮] 2026-02-15 按下时选中行的时间刻度变红加粗，松开恢复
  Widget _buildTimeColumn(List<String> slots) {
    return SizedBox(
      width: timeColumnWidth,
      child: Column(
        children: slots.asMap().entries.map((entry) {
          final index = entry.key;
          final slot = entry.value;
          final parts = slot.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          // 判断是否是重要时间点（12:00中午、18:00傍晚）
          final isImportantTime = (hour == 12 || hour == 18) && minute == 0;

          // [时间轴高亮] 2026-02-15 按下时当前行的时间刻度高亮红色
          final isHighlighted = _isPressing && _selectedSlotIndex == index;

          // 确定显示的文本：整点显示完整时间，非整点只显示分钟
          String displayText;
          if (minute == 0) {
            displayText = slot; // 整点：显示 "08:00"
          } else {
            displayText = minute.toString().padLeft(2, '0'); // 非整点：只显示 "15"、"30"、"45"
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
            height: cellHeight,
            // [视觉优化] 2026-02-12 时间刻度向上偏移，让网格线对准文字中间
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 4),
            child: Transform.translate(
              // 向上偏移约半个文字高度，让网格线（在单元格顶部）对准文字中间
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

  /// 构建课程网格
  Widget _buildGrid(
    BuildContext context,
    List<String> slots,
    Map<String, List<KnFixLsn001Bean>> groupedLessons,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth / 7;
        final gridHeight = slots.length * cellHeight;

        return SizedBox(
          height: gridHeight,
          child: Stack(
            children: [
              // 底层：空白网格线
              _buildGridLines(slots, columnWidth),
              // 上层：课程格子
              ..._buildLessonBlocks(context, groupedLessons, columnWidth),
              // [修复] 2026-02-12 空闲格子的点击区域（展开为列表）
              ..._buildEmptyCellTapAreas(
                  context, slots, groupedLessons, columnWidth),
              // [视觉优化] 2026-02-12 选中单元格的绿色边框（最上层）
              if (_selectedDayIndex != null && _selectedSlotIndex != null)
                _buildSelectionBorder(columnWidth),
            ],
          ),
        );
      },
    );
  }

  /// 构建网格线
  /// [视觉优化] 2026-02-12 整点的网格线调粗，12:00和18:00更粗
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

        // 判断线条粗细：12:00和18:00最粗(2.0)，其他整点次粗(1.0)，非整点细线(0.5)
        final isImportantHourLine = minute == 0 && (hour == 12 || hour == 18);
        final isHourLine = minute == 0;
        double lineWidth;
        Color lineColor;
        if (isHighlighted) {
          lineWidth = 2.5;  // 按下时高亮加粗
          lineColor = Colors.red;
        } else if (isImportantHourLine) {
          lineWidth = 2.0;  // 12:00和18:00加粗2倍
          lineColor = Colors.grey.shade500;
        } else if (isHourLine) {
          lineWidth = 1.0;  // 普通整点
          lineColor = Colors.grey.shade400;
        } else {
          lineWidth = 0.5;  // 非整点
          lineColor = Colors.grey.shade200;
        }

        return Container(
          height: cellHeight,
          decoration: BoxDecoration(
            border: Border(
              top: index == 0
                  ? BorderSide.none
                  : BorderSide(color: lineColor, width: lineWidth),
            ),
          ),
          child: Row(
            children: List.generate(7, (dayIndex) {
              return Container(
                width: columnWidth,
                decoration: BoxDecoration(
                  border: Border(
                    // 星期之间的垂直线粗细与整点水平线一致(1.0)
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
              '已选中 ${lesson.studentName} (${lesson.subjectName})　长按目标时间槽落地',
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

  /// [视觉优化] 2026-02-12 构建选中单元格的绿色边框（Excel风格）
  /// [时间显示] 2026-02-15 在选中单元格内显示对应时间（如 "13:30"）
  Widget _buildSelectionBorder(double columnWidth) {
    final slots = timeSlots;
    final timeText = (_selectedSlotIndex! >= 0 && _selectedSlotIndex! < slots.length)
        ? slots[_selectedSlotIndex!]
        : '';

    return Positioned(
      left: _selectedDayIndex! * columnWidth,
      top: _selectedSlotIndex! * cellHeight,
      width: columnWidth,
      height: cellHeight,
      child: IgnorePointer(
        child: Stack(
          children: [
            // 绿色边框
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  width: 2.0,
                ),
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

  /// [视觉优化] 2026-02-12 选中单元格
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

  /// 构建课程色块
  /// [集体排课] 2026-02-14 支持多学生并排显示
  /// [手势操作改善] 2026-03-03 长按进入悬浮状态
  List<Widget> _buildLessonBlocks(
    BuildContext context,
    Map<String, List<KnFixLsn001Bean>> groupedLessons,
    double columnWidth,
  ) {
    final blocks = <Widget>[];

    groupedLessons.forEach((key, lessonList) {
      final firstLesson = lessonList.first;
      final dayIndex = weekDays.indexOf(firstLesson.fixedWeek);
      if (dayIndex < 0) return;

      final slotIndex = firstLesson.timeSlotIndex;
      final cellSpan = firstLesson.cellSpan;

      // 防止越界
      if (slotIndex < 0) return;

      final top = slotIndex * cellHeight;
      final height = cellSpan * cellHeight - 1;
      final studentCount = lessonList.length;
      final totalWidth = columnWidth - 2;
      final cardWidth = totalWidth / studentCount;  // [集体排课] 平分宽度

      // [集体排课] 2026-02-14 遍历所有学生，并排显示
      for (int i = 0; i < lessonList.length; i++) {
        final lesson = lessonList[i];
        final left = dayIndex * columnWidth + 1 + i * cardWidth;

        // [手势操作改善] 2026-03-03 判断是否是悬浮中的卡片
        final isFloating = _floatingLesson != null &&
            _floatingLesson!.studentId == lesson.studentId &&
            _floatingLesson!.subjectId == lesson.subjectId &&
            _floatingLesson!.fixedWeek == lesson.fixedWeek;

        // [手势改善] 2026-03-05 悬浮状态时卡片高度缩小为1格，露出被遮挡的网格
        final effectiveHeight = isFloating ? cellHeight - 1 : height;

        Widget cardWidget = SingleLessonCell(
          lesson: lesson,
          isCompact: studentCount > 1,
        );

        // [手势操作改善] 2026-03-03 悬浮状态：半透明 + 蓝色闪烁边框
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
            height: effectiveHeight,
            child: GestureDetector(
              // [Excel风格] 2026-02-14 按下显示光标，松开打开详情
              // [手势操作改善] 悬浮中短按卡片不做任何操作（防止误触）
              onTapDown: (_) {
                if (_floatingLesson != null) return;
                _selectCell(dayIndex, slotIndex);
                _pendingLessonListTap = lessonList;
              },
              onTapUp: (_) {
                if (_floatingLesson != null) return;
                _releasePress();
                if (_pendingLessonListTap != null) {
                  _showLessonDetail(context, _pendingLessonListTap!);
                  _pendingLessonListTap = null;
                }
              },
              onTapCancel: () {
                if (_floatingLesson != null) return;
                _releasePress();
                _pendingLessonListTap = null;
              },
              // [手势操作改善] 2026-03-03 长按进入悬浮状态（第一步）
              onLongPressStart: (_) {
                _pendingLessonListTap = null;
                if (_floatingLesson == null) {
                  _releasePress();
                  _startFloating(lesson);
                }
                // 长按悬浮中的卡片：不做任何操作
              },
              child: cardWidget,
            ),
          ),
        );
      }
    });

    return blocks;
  }

  /// [修复] 2026-02-12 构建空闲格子的点击区域（返回List以便展开到父Stack）
  /// [手势操作改善] 2026-03-03 短按→无动作（或取消悬浮）；长按+抬手→新增/落地
  List<Widget> _buildEmptyCellTapAreas(
    BuildContext context,
    List<String> slots,
    Map<String, List<KnFixLsn001Bean>> groupedLessons,
    double columnWidth,
  ) {
    // 记录已被课程占用的格子
    final occupiedCells = <String>{};
    groupedLessons.forEach((key, lessonList) {
      final lesson = lessonList.first;
      final dayIndex = weekDays.indexOf(lesson.fixedWeek);
      final slotIndex = lesson.timeSlotIndex;
      final cellSpan = lesson.cellSpan;

      if (dayIndex >= 0 && slotIndex >= 0) {
        // [手势改善] 2026-03-05 悬浮状态时，悬浮课程只占用第0格，其余格子变为可点击的空白格
        final isFloatingGroup = _floatingLesson != null &&
            lessonList.any((l) =>
                l.studentId == _floatingLesson!.studentId &&
                l.subjectId == _floatingLesson!.subjectId &&
                l.fixedWeek == _floatingLesson!.fixedWeek);
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
        if (occupiedCells.contains(cellKey)) {
          continue; // 跳过已占用的格子
        }

        // 捕获当前循环变量的值
        final currentDayIndex = dayIndex;
        final currentSlotIndex = slotIndex;
        final tapWeekDay = weekDays[currentDayIndex];
        final tapHour = hour;
        final tapMinute = minute;

        tapAreas.add(
          Positioned(
            left: dayIndex * columnWidth,
            top: slotIndex * cellHeight,
            width: columnWidth,
            height: cellHeight,
            child: GestureDetector(
              // 按下：仅显示视觉反馈（绿色边框 + 红色时间轴）
              onTapDown: (_) {
                _selectCell(currentDayIndex, currentSlotIndex);
              },
              // 短按松开：悬浮中→取消悬浮；非悬浮→无动作
              onTapUp: (_) {
                _releasePress();
                if (_floatingLesson != null) {
                  _cancelFloating();
                }
              },
              onTapCancel: () {
                _releasePress();
              },
              // 长按开始：重置滑出标志 + 显示视觉反馈
              onLongPressStart: (_) {
                _longPressLeftCell = false;
                _selectCell(currentDayIndex, currentSlotIndex);
              },
              // [手势操作改善] 2026-03-03 手指在长按中移动：检测是否滑出单元格边界
              // 设计书要求：移出单元格 → 不触发，悬浮状态保持
              onLongPressMoveUpdate: (details) {
                if (!_longPressLeftCell) {
                  final p = details.localPosition;
                  if (p.dx < 0 || p.dx > columnWidth ||
                      p.dy < 0 || p.dy > cellHeight) {
                    _longPressLeftCell = true;
                    _releasePress(); // 取消视觉反馈（绿框/红轴）
                  }
                }
              },
              // 长按抬手：已滑出→不触发；悬浮中→落地执行；非悬浮→跳转新增页面
              onLongPressEnd: (_) {
                _releasePress();
                if (_longPressLeftCell) {
                  _longPressLeftCell = false;
                  return; // 手指已滑出单元格，取消操作
                }
                if (_floatingLesson != null) {
                  _placeLesson(context, currentDayIndex, currentSlotIndex);
                } else {
                  _navigateToAddForm(context, tapWeekDay, tapHour, tapMinute);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(), // 透明点击区域
            ),
          ),
        );
      }
    }
    return tapAreas;
  }

  /// 显示课程详情
  /// [集体排课] 2026-02-14 添加 onAddGroupMember 回调
  void _showLessonDetail(
      BuildContext context, List<KnFixLsn001Bean> lessonList) {
    final lesson = lessonList.first;
    LessonDetailSheet.show(
      context: context,
      weekDay: lesson.fixedWeek,
      timeSlot: lesson.classTime,
      lessons: lessonList,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      // [集体排课] 2026-02-14 追加学生排课
      onAddGroupMember: (weekDay, timeSlot) {
        // 解析时间 "HH:mm" 格式
        final parts = timeSlot.split(':');
        final hour = int.tryParse(parts[0]) ?? 9;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        _navigateToAddForm(context, weekDay, hour, minute);
      },
    );
  }

  /// [新潮界面] 2026-02-12 点击空单元格导航到新增页面（预填时间）
  void _navigateToAddForm(
      BuildContext context, String weekDay, int hour, int minute) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleForm(
          knBgColor: widget.knBgColor,
          knFontColor: widget.knFontColor,
          pagePath: widget.pagePath,
          preSelectedDay: weekDay,
          preSelectedHour: hour.toString().padLeft(2, '0'),
          preSelectedMinute: minute.toString().padLeft(2, '0'),
        ),
      ),
    );
    if (result == true) {
      widget.onDataChanged();
    }
  }

  /// 构建图例
  Widget _buildLegend(BuildContext context) {
    final subjectNames = widget.lessons.map((l) => l.subjectName).toSet().toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          ...subjectNames.map((name) => _buildLegendItem(
                SubjectColors.getColor(name),
                name,
              )),
          _buildLegendItem(Colors.white, '空闲', border: true),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool border = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: border ? Border.all(color: Colors.grey.shade300) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  /// 判断是否是今天
  bool _isToday(String weekDay) {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0=Mon, 6=Sun
    final dayIndex = weekDays.indexOf(weekDay);
    return dayIndex == todayIndex;
  }

  @override
  void dispose() {
    _floatingBlinkTimer?.cancel(); // [手势操作改善] 2026-03-03
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // [手势操作改善] 2026-03-03 悬浮与落地方法
  // ─────────────────────────────────────────────

  /// 第一步：进入悬浮状态（卡片半透明 + 蓝色闪烁边框）
  void _startFloating(KnFixLsn001Bean lesson) {
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

  /// 第二步：落地到目标格（长按后抬手时触发）
  void _placeLesson(BuildContext ctx, int targetDayIdx, int targetSlotIdx) {
    final lesson = _floatingLesson;
    _cancelFloating();

    if (lesson == null) return;

    final slots = timeSlots;
    if (targetSlotIdx < 0 || targetSlotIdx >= slots.length) return;

    final targetWeekDay = weekDays[targetDayIdx];
    final timeParts = slots[targetSlotIdx].split(':');
    final targetHour = int.parse(timeParts[0]);
    final targetMinute = int.parse(timeParts[1]);

    // 目标与当前位置完全相同则不处理
    if (targetWeekDay == lesson.fixedWeek &&
        targetHour == lesson.fixedHour &&
        targetMinute == lesson.fixedMinute) {
      return;
    }

    _saveTimeChange(ctx, lesson, targetWeekDay, targetHour, targetMinute);
  }

  /// 调用编辑API更新固定排课时间（含排他冲突检测）
  Future<void> _saveTimeChange(
    BuildContext ctx,
    KnFixLsn001Bean lesson,
    String newWeekDay,
    int newHour,
    int newMinute, {
    bool forceOverlap = false,
  }) async {
    try {
      final url = '${KnConfig.apiBaseUrl}${Constants.fixedLsnInfoEdit}';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'stuId': lesson.studentId,
          'subjectId': lesson.subjectId,
          'originalFixedWeek': lesson.fixedWeek,
          'fixedWeek': newWeekDay,
          'fixedHour': newHour.toString().padLeft(2, '0'),
          'fixedMinute': newMinute.toString().padLeft(2, '0'),
          'forceOverlap': forceOverlap,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200 || response.statusCode == 409) {
        dynamic responseData;
        try {
          responseData = json.decode(decodedBody);
        } catch (_) {
          if (response.statusCode == 200) {
            widget.onDataChanged();
            return;
          }
        }

        if (responseData is Map<String, dynamic>) {
          final result = ConflictCheckResult.fromJson(responseData);

          if (result.success) {
            widget.onDataChanged();
          } else if (result.hasConflict) {
            final startTime =
                '${newHour.toString().padLeft(2, '0')}:${newMinute.toString().padLeft(2, '0')}';
            final endTime = _calculateEndTime(startTime, lesson.classDuration);
            final newSchedule = NewScheduleInfo(
              startTime: startTime,
              endTime: endTime,
              stuName: lesson.studentName,
            );

            if (result.isSameStudentConflict) {
              if (ctx.mounted) {
                await ConflictWarningDialog.showSameStudentConflict(
                  ctx,
                  result.conflicts,
                  newSchedule: newSchedule,
                );
              }
            } else {
              if (ctx.mounted) {
                final confirmed = await ConflictWarningDialog.show(
                  ctx,
                  result.conflicts,
                  newSchedule: newSchedule,
                );
                if (confirmed && ctx.mounted) {
                  await _saveTimeChange(
                    ctx,
                    lesson,
                    newWeekDay,
                    newHour,
                    newMinute,
                    forceOverlap: true,
                  );
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  /// 计算结束时间（开始时间 + 课程时长）
  String _calculateEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    final startHour = int.parse(parts[0]);
    final startMinute = int.parse(parts[1]);
    final totalMinutes = startHour * 60 + startMinute + durationMinutes;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }
}
