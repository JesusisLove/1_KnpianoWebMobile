// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, unnecessary_null_comparison

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kn_piano/ApiConfig/KnApiConfig.dart';
import 'package:kn_piano/Constants.dart';
import 'package:kn_piano/theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-19
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show HapticFeedback;
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart';
import 'AddCourseDialog.dart';
import 'Kn01L002LsnBean.dart';
import 'RescheduleLessonDialog.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [课程表新潮版] 2026-02-13 记忆功能
import 'TrendyView/schedule_trendy_view.dart'; // [课程表新潮版] 2026-02-13

// 调课对话框组件
class RescheduleLessonTimeDialog extends StatefulWidget {
  final DateTime initialDate;
  final String initialTime;
  final Function(String) onSave;

  const RescheduleLessonTimeDialog({
    super.key,
    required this.initialDate,
    required this.initialTime,
    required this.onSave,
  });

  @override
  _RescheduleLessonTimeDialogState createState() =>
      _RescheduleLessonTimeDialogState();
}

class _RescheduleLessonTimeDialogState
    extends State<RescheduleLessonTimeDialog> {
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    final timeParts = widget.initialTime.split(':');
    selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
  }

  bool _isValidTime(TimeOfDay time) {
    if (time.hour < 8 || time.hour > 22) return false;
    return [0, 15, 30, 45].contains(time.minute);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (picked != null && _isValidTime(picked)) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                Text(
                  '将该课调至',
                  style: KnElementTextStyle.dialogTitle(context, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('选择日期：'),
            const SizedBox(height: 8),
            AbsorbPointer(
              absorbing: true,
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: '选择日期',
                  suffixIcon:
                      const Icon(Icons.calendar_today, color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                controller: TextEditingController(
                  text: DateFormat('yyyy-MM-dd').format(widget.initialDate),
                ),
                enabled: false,
              ),
            ),
            const SizedBox(height: 24),
            const Text('选择时间：'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: '选择时间',
                    suffixIcon: const Icon(Icons.access_time),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  controller: TextEditingController(
                    text:
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE091A0),
                  minimumSize: const Size(120, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  final String newTime =
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                  try {
                    await widget.onSave(newTime); // 调用保存回调函数
                    if (mounted) {
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('保存失败: $e')),
                      );
                    }
                    rethrow;
                  }
                },
                child: const Text(
                  '保存',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

class CalendarPage extends StatefulWidget {
  final String focusedDay;
  final String? stuId;
  const CalendarPage({super.key, required this.focusedDay, this.stuId});
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  // [课题二] 2026-02-08 时间槽固定高度常量
  static const double _slotHeight = 40.0;

  String? highlightedStuId; // 新增
  final ScrollController _scrollController = ScrollController(); // 新增
  Timer? _highlightTimer; // 新增

  bool _isLoading = false; // 添加加载状态变量

  // [课题二] 2026-02-08 动画相关变量（从TimeTile移植）
  String? _pressedLessonId;
  Timer? _blinkTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isSaving = false;

  CalendarFormat _calendarFormat = CalendarFormat.week;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  String? currentHighlightedTime;

  List<Kn01L002LsnBean> studentLsns = [];

  // [BUG修复] 2026-02-08 跟踪当前前置显示的卡片（用于同一时间多卡片的点击切换）
  String? _frontCardLessonId;

  // [课程表新潮版] 2026-02-13 新潮版视图切换状态
  bool _isTrendyView = false;
  List<Kn01L002LsnBean> _weekLessons = []; // 一周的课程数据
  DateTime? _currentWeekStart; // 当前周的起始日期
  static const String _viewPreferenceKey = 'calendar_trendy_view'; // 记忆功能Key

  // [课程表新潮版] 2026-02-14 加载视图偏好设置
  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isTrendy = prefs.getBool(_viewPreferenceKey) ?? false;
    if (mounted && isTrendy != _isTrendyView) {
      setState(() {
        _isTrendyView = isTrendy;
      });
      if (isTrendy) {
        // 如果记忆的是新潮版，加载周数据
        final weekStart = _getWeekStart(_selectedDay);
        _fetchWeekLessons(weekStart);
      }
    }
  }

  // [课程表新潮版] 2026-02-14 保存视图偏好设置
  Future<void> _saveViewPreference(bool isTrendy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_viewPreferenceKey, isTrendy);
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = DateFormat('yyyy-MM-dd').parse(widget.focusedDay);
    _selectedDay = _focusedDay;

    // 设置初始状态
    if (widget.focusedDay.contains(' ')) {
      final time = widget.focusedDay.split(' ')[1].substring(0, 5);
      setState(() {
        currentHighlightedTime = time;
        highlightedStuId = widget.stuId;
      });

      // 设置10秒后清除高亮状态
      _highlightTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            currentHighlightedTime = null;
            highlightedStuId = null;
          });
        }
      });
    }

    // 获取指定日期的课程数据
    _fetchStudentLsn(widget.focusedDay.split(' ')[0].trim());

    // [课题二] 2026-02-08 动画初期化（从TimeTile移植）
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);

    // 等待布局完成后滚动到目标位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTargetTime();
    });

    // [课程表新潮版] 2026-02-14 加载记忆的视图偏好
    _loadViewPreference();
  }

  // 新增：滚动到目标时间位置
  void _scrollToTargetTime() {
    if (widget.focusedDay.contains(' ')) {
      final targetTime = widget.focusedDay.split(' ')[1].substring(0, 5);
      final targetHour = int.parse(targetTime.split(':')[0]);
      final targetMinute = int.parse(targetTime.split(':')[1]);

      // 计算目标位置
      final index = ((targetHour - 8) * 4) + (targetMinute ~/ 15);
      final targetPosition = index * 60.0; // 假设每个时间格的高度约为60

      // 计算滚动位置，使目标位置位于屏幕中间
      final screenHeight = MediaQuery.of(context).size.height;
      final offset =
          math.max(0, targetPosition - (screenHeight / 2)).toDouble();

      // 滚动到目标位置
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // 新增：清理定时器
  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.dispose();
    // [课题二] 2026-02-08 动画资源清理（从TimeTile移植）
    _blinkTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentLsn(String schedualDate) async {
    // 开始加载，设置加载状态为true
    setState(() {
      _isLoading = true;
    });

    try {
      final String apilsnInfoByDayUrl =
          '${KnConfig.apiBaseUrl}${Constants.lsnInfoByDay}/$schedualDate';
      final response = await http.get(Uri.parse(apilsnInfoByDayUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> responseStuLsnsJson = json.decode(decodedBody);
        if (mounted) {
          // 检查组件是否仍然挂载
          setState(() {
            studentLsns = responseStuLsnsJson
                .map((json) => Kn01L002LsnBean.fromJson(json))
                .toList();
            _isLoading = false; // 加载完成，设置加载状态为false
          });
          // [课题二] 2026-02-08 检查是否有需要高亮显示的课程，启动闪烁动画
          if (currentHighlightedTime != null && highlightedStuId != null) {
            for (var event in studentLsns) {
              // 获取课程显示时间
              String displayTime = event.schedualDate.length >= 16
                  ? event.schedualDate.substring(11, 16)
                  : '';
              if (_isHighlighted(event, displayTime)) {
                _startBlinking();
                break;
              }
            }
          }
        }
      } else {
        throw Exception('Failed to load archived lessons of the day');
      }
    } catch (e) {
      print('Error fetching current-day\'s lessons data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false; // 出错时也要结束加载状态
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据出错: $e')),
        );
      }
    }
  }

  // [课程表新潮版] 2026-02-13 加载一周的课程数据
  Future<void> _fetchWeekLessons(DateTime weekStart) async {
    setState(() {
      _isLoading = true;
      _currentWeekStart = weekStart;
    });

    try {
      final List<Kn01L002LsnBean> allLessons = [];

      // 并发加载7天的数据
      final futures = <Future<http.Response>>[];
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final url = '${KnConfig.apiBaseUrl}${Constants.lsnInfoByDay}/$dateStr';
        futures.add(http.get(Uri.parse(url)));
      }

      final responses = await Future.wait(futures);

      for (final response in responses) {
        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          List<dynamic> responseLsnsJson = json.decode(decodedBody);
          allLessons.addAll(
            responseLsnsJson.map((json) => Kn01L002LsnBean.fromJson(json)).toList()
          );
        }
      }

      if (mounted) {
        setState(() {
          _weekLessons = allLessons;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching week lessons: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载周数据出错: $e')),
        );
      }
    }
  }

  // [课程表新潮版] 2026-02-13 获取指定日期所在周的周一
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1=周一, 7=周日
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  // 长按课程卡片弹出的对话框画面，点击"保存"，执行时间更新
  Future<void> _updateLessonTime(
      String lessonId, String newTime, bool isRescheduledLesson) async {
    // 选中的课程表日期
    final String selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
    // 设置当天的调换时间
    // 方案B: 始终将新时间设置给lsnAdjustedDate，保留原始schedualDate记录
    // 这样即使是同一天的时间调整，也会生成调课From/To卡片
    final Map<String, dynamic> courseData = {
      'lessonId': lessonId,
      'lsnAdjustedDate': '$selectedDate $newTime',
    };

    try {
      final String updateUrl =
          '${KnConfig.apiBaseUrl}${Constants.apiUpdateLessonTime}';
      final response = await http.post(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(courseData),
      );

      if (response.statusCode == 200) {
        await _fetchStudentLsn(DateFormat('yyyy-MM-dd').format(_selectedDay));
      } else {
        throw Exception('Failed to update lesson time');
      }
    } catch (e) {
      print('Error updating lesson time: $e');
      rethrow;
    }
  }

  List<Kn01L002LsnBean> getSchedualLessonForTime(String time) {
    String selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    return studentLsns.where((event) {
      String eventScheduleDateStr = event.schedualDate.length >= 10
          ? event.schedualDate.substring(0, 10)
          : '';
      String eventTime1 = event.schedualDate.length >= 16
          ? event.schedualDate.substring(11, 16)
          : '';

      String eventAdjustedDateStr = event.lsnAdjustedDate.length >= 10
          ? event.lsnAdjustedDate.substring(0, 10)
          : '';
      String eventTime2 = event.lsnAdjustedDate.length >= 16
          ? event.lsnAdjustedDate.substring(11, 16)
          : '';

      return (eventScheduleDateStr == selectedDateStr && eventTime1 == time) ||
          (eventAdjustedDateStr == selectedDateStr && eventTime2 == time);
    }).toList();
  }

  // [课题二] 2026-02-08 动画辅助方法（从TimeTile移植）
  // 判断课程是否需要高亮显示
  bool _isHighlighted(Kn01L002LsnBean event, String displayTime) {
    final bool timeMatches = displayTime == currentHighlightedTime;
    final bool stuIdMatches = event.stuId == highlightedStuId;
    return timeMatches && stuIdMatches;
  }

  // 启动闪烁动画
  void _startBlinking() {
    _blinkTimer?.cancel();
    _fadeController.value = 1.0;

    int blinkCount = 0;
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
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

  // 判断是否为灰色背景的课程（不允许长按调时间）
  bool _isGrayBackground(Kn01L002LsnBean event) {
    String selectedDayStr = DateFormat('yyyy-MM-dd').format(_selectedDay);

    String eventScheduleDateStr = '';
    if (event.schedualDate.length >= 10) {
      eventScheduleDateStr = event.schedualDate.substring(0, 10);
    }

    String eventAdjustedDateStr = '';
    if (event.lsnAdjustedDate.length >= 10) {
      eventAdjustedDateStr = event.lsnAdjustedDate.substring(0, 10);
    }

    bool hasBeenRescheduled = event.lsnAdjustedDate.isNotEmpty;
    bool hasBeenSigned = event.scanQrDate.isNotEmpty;

    return ((selectedDayStr == eventScheduleDateStr) && hasBeenRescheduled) ||
        ((selectedDayStr == eventScheduleDateStr) && hasBeenSigned) ||
        ((selectedDayStr == eventAdjustedDateStr) && hasBeenSigned);
  }

  // 长按开始处理 - 弹出调时间对话框
  void _handleLongPressStart(Kn01L002LsnBean event, String displayTime) async {
    if (!_isGrayBackground(event)) {
      await HapticFeedback.heavyImpact();
      setState(() {
        _pressedLessonId = event.lessonId;
        _isSaving = false;
      });
      _fadeController.reset();

      final String currentTime = displayTime;
      final isRescheduledLesson = (event.lsnAdjustedDate.isNotEmpty == true);

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return RescheduleLessonTimeDialog(
            initialDate: _selectedDay,
            initialTime: currentTime,
            onSave: (String newTime) async {
              try {
                setState(() {
                  _isSaving = true;
                });
                await _updateLessonTime(
                    event.lessonId, newTime, isRescheduledLesson);
                return true;
              } catch (e) {
                setState(() {
                  _isSaving = false;
                });
                rethrow;
              }
            },
          );
        },
      );

      if (result == true && mounted) {
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _isSaving) {
            _fadeController.forward().then((_) {
              if (mounted) {
                setState(() {
                  _pressedLessonId = null;
                  _isSaving = false;
                });
              }
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _pressedLessonId = null;
            _isSaving = false;
          });
        }
      }
    }
  }

  void _handleLongPressEnd() {
    // 长按结束时不立即清除边框
  }

  // [BUG修复] 2026-02-08 获取排序后的课程卡片列表
  // 渲染顺序：调课From卡片先渲染（居后），被点击的卡片最后渲染（居前）
  List<Widget> _getSortedLessonCards() {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);

    // 辅助函数：判断课程是否是调课From卡片
    bool isRescheduleFromCard(Kn01L002LsnBean event) {
      final eventScheduleDateStr = event.schedualDate.length >= 10
          ? event.schedualDate.substring(0, 10)
          : '';
      final eventAdjustedDateStr = event.lsnAdjustedDate.length >= 10
          ? event.lsnAdjustedDate.substring(0, 10)
          : '';
      final hasBeenRescheduled = event.lsnAdjustedDate.isNotEmpty;

      return selectedDateStr == eventScheduleDateStr &&
          hasBeenRescheduled &&
          selectedDateStr != eventAdjustedDateStr;
    }

    // 复制列表并排序
    final sorted = List<Kn01L002LsnBean>.from(studentLsns);
    sorted.sort((a, b) {
      final aIsRescheduleFrom = isRescheduleFromCard(a);
      final bIsRescheduleFrom = isRescheduleFromCard(b);
      final aIsFront = a.lessonId == _frontCardLessonId;
      final bIsFront = b.lessonId == _frontCardLessonId;

      // 被点击的卡片最后渲染（居前）
      if (aIsFront) return 1;
      if (bIsFront) return -1;

      // 调课From卡片先渲染（居后），其他卡片后渲染（居前）
      if (aIsRescheduleFrom && !bIsRescheduleFrom) return -1;
      if (!aIsRescheduleFrom && bIsRescheduleFrom) return 1;

      return 0;
    });

    return sorted.map((event) => _buildPositionedCard(event)).toList();
  }

  // [课题二] 2026-02-08 构建绝对定位的课程卡片
  // 保留原有TimeTile._buildEventTile的所有业务逻辑，只改变定位方式
  Widget _buildPositionedCard(Kn01L002LsnBean event) {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);

    // === 原有业务逻辑：日期状态判断（完整保留自 TimeTile._buildEventTile）===
    final eventScheduleDateStr = event.schedualDate.length >= 10
        ? event.schedualDate.substring(0, 10)
        : '';
    final eventAdjustedDateStr = event.lsnAdjustedDate.length >= 10
        ? event.lsnAdjustedDate.substring(0, 10)
        : '';
    final hasBeenRescheduled = event.lsnAdjustedDate.isNotEmpty;
    final hasBeenSigned = event.scanQrDate.isNotEmpty;

    // 各种状态判断（完整保留）
    final isScheduledUnsignedLsn = selectedDateStr == eventScheduleDateStr &&
        !hasBeenRescheduled &&
        !hasBeenSigned;

    final isScheduledSignedLsn = selectedDateStr == eventScheduleDateStr &&
        !hasBeenRescheduled &&
        hasBeenSigned;

    final isAdjustedUnSignedLsnFrom = selectedDateStr == eventScheduleDateStr &&
        hasBeenRescheduled &&
        selectedDateStr != eventAdjustedDateStr &&
        !hasBeenSigned;

    final isAdjustedSignedLsnFrom = selectedDateStr == eventScheduleDateStr &&
        hasBeenRescheduled &&
        selectedDateStr != eventAdjustedDateStr &&
        hasBeenSigned;

    final isAdjustedUnSignedLsnTo = selectedDateStr != eventScheduleDateStr &&
        hasBeenRescheduled &&
        selectedDateStr == eventAdjustedDateStr &&
        !hasBeenSigned;

    final isAdjustedSignedLsnTo = selectedDateStr != eventScheduleDateStr &&
        hasBeenRescheduled &&
        selectedDateStr == eventAdjustedDateStr &&
        hasBeenSigned;

    // === 原有业务逻辑：背景颜色和附加信息（完整保留）===
    Color backgroundColor;
    Color textColor = Colors.black;
    String additionalInfo = '';

    if (isAdjustedUnSignedLsnFrom || isAdjustedSignedLsnFrom) {
      backgroundColor = Colors.grey.shade300;
      additionalInfo = '调课To：${event.lsnAdjustedDate}';
    } else if (isAdjustedUnSignedLsnTo) {
      backgroundColor = Colors.orange.shade100; // 调课目标日期：浅橙色
      additionalInfo = '调课From：${event.schedualDate}';
    } else if (isAdjustedSignedLsnTo) {
      backgroundColor = Colors.grey.shade500;
      additionalInfo = '调课From：${event.schedualDate}';
    } else if (isScheduledUnsignedLsn) {
      // 根据课程类型设置不同背景颜色
      final lessonCardColors = context.lessonCardColors;
      switch (event.lessonType) {
        case 0: // 课时课
          backgroundColor = lessonCardColors.hourly;
          break;
        case 2: // 加课
          backgroundColor = lessonCardColors.extra;
          break;
        case 1: // 计划课
        default:
          backgroundColor = lessonCardColors.planned;
          break;
      }
    } else if (isScheduledSignedLsn) {
      backgroundColor = Colors.grey.shade500;
    } else {
      backgroundColor = Colors.black12;
    }

    // 文字装饰（已签到显示删除线）
    TextDecoration textDecoration = TextDecoration.none;
    if (isScheduledSignedLsn ||
        isAdjustedSignedLsnFrom ||
        isAdjustedSignedLsnTo) {
      textDecoration = TextDecoration.lineThrough;
    }

    // === 时间线颜色（与主题JSON保持一致）===
    Color timelineColor;
    switch (event.lessonType) {
      case 0: // 课时课 - 绿色
        timelineColor = const Color(0xFF4CAF50);
        break;
      case 2: // 加课 - 粉色
        timelineColor = const Color(0xFFE91E63);
        break;
      case 1: // 计划课 - 蓝色
      default:
        timelineColor = const Color(0xFF2196F3);
        break;
    }

    // 判断是否显示时间线（只有调课From的课程不显示时间线）
    final bool showTimeline =
        !(isAdjustedUnSignedLsnFrom || isAdjustedSignedLsnFrom);

    // === 位置计算（课题二核心）===
    // 获取课程显示时间（优先调课时间）
    String displayTime;
    String displayDateStr;
    if (event.lsnAdjustedDate.isNotEmpty &&
        selectedDateStr == eventAdjustedDateStr) {
      // 调课To的情况：显示在调课目标日期
      displayDateStr = eventAdjustedDateStr;
      displayTime = event.lsnAdjustedDate.length >= 16
          ? event.lsnAdjustedDate.substring(11, 16)
          : '';
    } else {
      // 正常排课或调课From的情况
      displayDateStr = eventScheduleDateStr;
      displayTime = event.schedualDate.length >= 16
          ? event.schedualDate.substring(11, 16)
          : '';
    }

    // 只显示当天的课程
    if (displayDateStr != selectedDateStr) return const SizedBox.shrink();

    // 计算开始时间的Y坐标
    final timeParts = displayTime.split(':');
    if (timeParts.length != 2) return const SizedBox.shrink();
    final hour = int.tryParse(timeParts[0]) ?? 8;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final slotIndex = (hour - 8) * 4 + (minute ~/ 15);
    // 圆点紧贴开始时间分隔线下方
    // 分隔线在槽位的垂直中间（+_slotHeight/2），圆点从分隔线下方开始
    final topPosition = slotIndex * _slotHeight + _slotHeight / 2;

    // 计算课程时长对应的高度（结束时间槽位）
    final durationSlots = (event.classDuration / 15).ceil();
    // 时间线高度 = 从开始分隔线到结束分隔线的距离
    final timelineHeight = durationSlots * _slotHeight;

    // [BUG修复] 2026-02-08 调课From卡片位置调整
    final bool isRescheduleFromCard =
        isAdjustedUnSignedLsnFrom || isAdjustedSignedLsnFrom;

    // 检测同一时间是否有其他卡片（用于点击切换和位置调整）
    bool hasSameTimeOtherLesson = false;
    for (var otherEvent in studentLsns) {
      if (otherEvent.lessonId == event.lessonId) continue;

      // 获取其他课程的显示时间
      final otherEventScheduleDateStr = otherEvent.schedualDate.length >= 10
          ? otherEvent.schedualDate.substring(0, 10)
          : '';
      final otherEventAdjustedDateStr = otherEvent.lsnAdjustedDate.length >= 10
          ? otherEvent.lsnAdjustedDate.substring(0, 10)
          : '';
      final otherHasBeenRescheduled = otherEvent.lsnAdjustedDate.isNotEmpty;

      // 判断其他课程是否是调课From
      final otherIsRescheduleFrom =
          selectedDateStr == otherEventScheduleDateStr &&
              otherHasBeenRescheduled &&
              selectedDateStr != otherEventAdjustedDateStr;

      // 获取其他课程的显示时间
      String otherDisplayTime;
      if (otherEvent.lsnAdjustedDate.isNotEmpty &&
          selectedDateStr == otherEventAdjustedDateStr) {
        otherDisplayTime = otherEvent.lsnAdjustedDate.length >= 16
            ? otherEvent.lsnAdjustedDate.substring(11, 16)
            : '';
      } else {
        otherDisplayTime = otherEvent.schedualDate.length >= 16
            ? otherEvent.schedualDate.substring(11, 16)
            : '';
      }

      // 检测是否有同时间的其他卡片
      if (otherDisplayTime == displayTime) {
        // 对于调课From卡片：检测同时间是否有非调课From的课程（用于位置调整）
        // 对于普通卡片：检测同时间是否有调课From的课程（用于点击切换）
        if (isRescheduleFromCard && !otherIsRescheduleFrom) {
          hasSameTimeOtherLesson = true;
          break;
        } else if (!isRescheduleFromCard && otherIsRescheduleFrom) {
          hasSameTimeOtherLesson = true;
          break;
        }
      }
    }

    // 计算最终的top位置
    // 如果是调课From卡片且同一时间有其他课程 → 下方对齐（底边对齐结束时间）
    // 否则 → 上方对齐（顶边对齐开始时间）
    final bool needBottomAlign = isRescheduleFromCard && hasSameTimeOtherLesson;

    return Positioned(
      left: 54, // 时间轴右侧（与时间文字间距对称）
      right: 8,
      top: topPosition, // 紧贴开始时间分隔线下方
      child: SizedBox(
        // 调课From卡片且同一时间有其他课程时，设置固定高度使底边对齐
        height: needBottomAlign ? timelineHeight : null,
        child: Row(
          // 调课From卡片且同一时间有其他课程时，卡片下方对齐
          crossAxisAlignment: needBottomAlign
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // 时间线（只有非灰色卡片显示）
            if (showTimeline)
              SizedBox(
                width: 14,
                height: timelineHeight,
                child: Column(
                  children: [
                    // 起点圆点 ● - 紧贴开始时间分隔线下方
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: timelineColor)),
                    // 垂直线 │
                    Expanded(
                        child: Center(
                            child: Container(width: 3, color: timelineColor))),
                    // 末端三角形 ▼ - 紧贴结束时间分隔线上方
                    CustomPaint(
                        size: const Size(10, 8),
                        painter: _TrianglePainter(color: timelineColor)),
                  ],
                ),
              ),
            if (!showTimeline) const SizedBox(width: 14),
            // === 课程卡片（保留原有完整内容 + 动画效果）===
            Expanded(
              child: GestureDetector(
                onLongPressStart: (_) =>
                    _handleLongPressStart(event, displayTime),
                onLongPressEnd: (_) => _handleLongPressEnd(),
                // [BUG修复] 2026-02-08 点击卡片时将其置于前端显示
                onTap: () {
                  // 同时间有其他卡片时，点击可切换前后顺序
                  if (hasSameTimeOtherLesson) {
                    setState(() {
                      _frontCardLessonId = event.lessonId;
                    });
                  }
                },
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(left: 4),
                  // [课题二] 2026-02-08 高亮时显示红色背景
                  color: _isHighlighted(event, displayTime)
                      ? Colors.red[100]
                      : backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    // [课题二] 2026-02-08 动画边框效果
                    side: _isHighlighted(event, displayTime)
                        ? BorderSide(
                            color: Colors.red.withOpacity(_fadeAnimation.value),
                            width: 2.0,
                          )
                        : (_pressedLessonId == event.lessonId && _isSaving
                            ? BorderSide(
                                color: Colors.red
                                    .withOpacity(_fadeAnimation.value),
                                width: 2.0,
                              )
                            : BorderSide.none),
                  ),
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: child!,
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左侧内容区域
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 学生姓名
                              Text(
                                event.stuName,
                                style: KnElementTextStyle.cardTitle(
                                  context,
                                  fontSize: 18,
                                  color: textColor,
                                ).copyWith(decoration: textDecoration),
                              ),
                              const SizedBox(height: 4),
                              // 科目信息 + 调课信息
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${event.subjectName} - ${event.subjectSubName}',
                                      style: KnElementTextStyle.cardBody(
                                        context,
                                        fontSize: 12,
                                        color: textColor,
                                        decoration: textDecoration,
                                      ),
                                    ),
                                  ),
                                  if (additionalInfo.isNotEmpty)
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 0),
                                        child: Text(
                                          additionalInfo,
                                          style: KnElementTextStyle.cardBody(
                                            context,
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              // 课程时长 + 类型 + 备注
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${event.classDuration}分钟 | ${event.lessonType == 0 ? '课结算' : event.lessonType == 1 ? '月计划' : '月加课'}',
                                      style: KnElementTextStyle.cardBody(
                                        context,
                                        fontSize: 12,
                                        color: textColor,
                                        decoration: textDecoration,
                                      ),
                                    ),
                                  ),
                                  if (event.memo != null &&
                                      event.memo!.isNotEmpty &&
                                      (!isAdjustedUnSignedLsnTo &&
                                          !isAdjustedSignedLsnTo))
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 0),
                                        child: Text(
                                          '备注: ${event.memo}',
                                          style: KnElementTextStyle.cardBody(
                                            context,
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 右侧三个点菜单按钮（原有逻辑完整保留）
                        PopupMenuButton<String>(
                          icon:
                              const Icon(Icons.more_vert, color: Colors.black),
                          onSelected: (String result) {
                            switch (result) {
                              case '签到':
                                _handleSignCourse(event);
                                break;
                              case '撤销':
                                _handleRestoreCourse(event);
                                break;
                              case '调课':
                                _handleReschLsnCourse(event);
                                break;
                              case '取消':
                                _handleCancelRescheCourse(event);
                                break;
                              case '删除':
                                _handleDeleteCourse(event);
                                break;
                              case '备注':
                                _handleNoteCourse(event);
                                break;
                            }
                          },
                          itemBuilder: (BuildContext ctx) =>
                              _buildPositionedCardMenuItems(event),
                          constraints: const BoxConstraints(
                            minWidth: 50,
                            maxWidth: 60,
                          ),
                          position: PopupMenuPosition.under,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ), // closes GestureDetector
            ), // closes Expanded
          ],
        ),
      ), // closes SizedBox [BUG修复] 2026-02-08
    );
  }

  // [课题二] 2026-02-08 构建卡片右侧菜单项（保留原有 TimeTile._buildPopupMenuItems 逻辑）
  List<PopupMenuEntry<String>> _buildPositionedCardMenuItems(
      Kn01L002LsnBean event) {
    final menuStyle = KnElementTextStyle.popupMenuItem(context);

    // 已签到的课程
    if ((event.scanQrDate != null) && (event.scanQrDate.isNotEmpty)) {
      if (DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal()) ==
          event.scanQrDate) {
        return [
          PopupMenuItem<String>(
            value: '撤销',
            height: 36,
            child: Text('撤销', style: menuStyle),
          ),
          PopupMenuItem<String>(
            value: '备注',
            height: 36,
            child: Text('备注', style: menuStyle),
          ),
        ];
      } else {
        return [
          PopupMenuItem<String>(
            value: '备注',
            height: 36,
            child: Text('备注', style: menuStyle),
          ),
        ];
      }
    }

    // 检查是否为已调课但未签到的课程
    final selectedDayStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final eventScheduleDateStr = event.schedualDate.length >= 10
        ? event.schedualDate.substring(0, 10)
        : '';
    final eventAdjustedDateStr = event.lsnAdjustedDate.length >= 10
        ? event.lsnAdjustedDate.substring(0, 10)
        : '';

    final hasBeenRescheduled = event.lsnAdjustedDate.isNotEmpty;
    final hasBeenSigned = event.scanQrDate.isNotEmpty;

    final isAdjustedUnSignedLsnFrom = selectedDayStr == eventScheduleDateStr &&
        hasBeenRescheduled &&
        selectedDayStr != eventAdjustedDateStr &&
        !hasBeenSigned;

    if (isAdjustedUnSignedLsnFrom) {
      return <PopupMenuEntry<String>>[
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '调课',
          height: 36,
          child: Text('调课', style: menuStyle),
        ),
        PopupMenuItem<String>(
          value: '取消',
          height: 36,
          child: Text('取消', style: menuStyle),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '删除',
          height: 36,
          child: Text('删除', style: menuStyle),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '备注',
          height: 36,
          child: Text('备注', style: menuStyle),
        ),
      ];
    } else {
      return <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: '签到',
          enabled: !_selectedDay.isAfter(DateTime.now()),
          height: 36,
          child: Text(
            '签到',
            style: menuStyle.copyWith(
                color:
                    _selectedDay.isAfter(DateTime.now()) ? Colors.grey : null),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '调课',
          height: 36,
          child: Text('调课', style: menuStyle),
        ),
        PopupMenuItem<String>(
          value: '删除',
          height: 36,
          child: Text('删除', style: menuStyle),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '备注',
          height: 36,
          child: Text('备注', style: menuStyle),
        ),
      ];
    }
  }

  // [课程表新潮版] 2026-02-13 添加可选的overrideDate参数
  void _handleTimeSelection(BuildContext context, String time, {DateTime? overrideDate}) {
    final targetDate = overrideDate ?? _selectedDay;
    String formattedDate = DateFormat('yyyy-MM-dd').format(targetDate);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCourseDialog(scheduleDate: formattedDate, scheduleTime: time);
      },
    ).then((result) {
      if (result == true) {
        if (_isTrendyView) {
          // 新潮版：刷新整周数据
          _fetchWeekLessons(_currentWeekStart ?? _getWeekStart(_selectedDay));
        } else {
          // 传统版：刷新当天数据
          setState(() {
            _fetchStudentLsn(formattedDate);
          });
        }
      }
    });
  }

  // //课程的修改功能暂时不要了 2025/02/08 先暂时保留，不要删除
  // void _handleEditCourse(Kn01L002LsnBean event) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return EditCourseDialog(lessonId: event.lessonId);
  //     },
  //   ).then((result) {
  //     if (result == true) {
  //       setState(() {
  //         _fetchStudentLsn(DateFormat('yyyy-MM-dd').format(_selectedDay));
  //       });
  //     }
  //   });
  // }

  // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
  void _handleSignCourse(Kn01L002LsnBean event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('执行签到确认',
              style: KnElementTextStyle.dialogTitle(context, fontSize: 18)),
          content: Text(
              '签到【${event.subjectName}】这节课，\n当日之内可以撤销，过了今日撤销不可！\n您确定要签到吗？',
              style: KnElementTextStyle.dialogContent(context)),
          actions: <Widget>[
            TextButton(
              child: Text('取消',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.blue)),
              onPressed: () async {
                final String signUrl =
                    '${KnConfig.apiBaseUrl}${Constants.apiStuLsnSign}/${event.lessonId}';
                try {
                  final response = await http.get(
                    Uri.parse(signUrl),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );
                  if (response.statusCode == 200) {
                    setState(() {
                      _fetchStudentLsn(
                          DateFormat('yyyy-MM-dd').format(_selectedDay));
                    });
                    Navigator.of(context).pop(true);
                  } else {
                    throw Exception('Failed to delete lesson');
                  }
                } catch (e) {
                  print('Error deleting lesson: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
  void _handleRestoreCourse(Kn01L002LsnBean event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('撤销确认',
              style: KnElementTextStyle.dialogTitle(context, fontSize: 18)),
          content: Text('确实要撤销【${event.subjectName}】这节课吗？',
              style: KnElementTextStyle.dialogContent(context)),
          actions: <Widget>[
            TextButton(
              child: Text('取消',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.blue)),
              onPressed: () async {
                final String signUrl =
                    '${KnConfig.apiBaseUrl}${Constants.apiStuLsnRestore}/${event.lessonId}';
                try {
                  final response = await http.get(
                    Uri.parse(signUrl),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );
                  if (response.statusCode == 200) {
                    setState(() {
                      _fetchStudentLsn(
                          DateFormat('yyyy-MM-dd').format(_selectedDay));
                    });
                    Navigator.of(context).pop(true);
                  } else {
                    throw Exception('Failed to delete lesson');
                  }
                } catch (e) {
                  print('Error deleting lesson: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleReschLsnCourse(Kn01L002LsnBean event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: RescheduleLessonDialog(
                lessonId: event.lessonId,
                classDuration: event.classDuration, // [Bug修复] 2026-02-16 传递实际课时时长
              ),
            ),
          ),
        );
      },
    ).then((result) {
      if (result == true) {
        setState(() {
          _fetchStudentLsn(DateFormat('yyyy-MM-dd').format(_selectedDay));
        });
      }
    });
  }

  // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
  void _handleCancelRescheCourse(Kn01L002LsnBean event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('取消调课确认',
              style: KnElementTextStyle.dialogTitle(context, fontSize: 18)),
          content: Text('要取消【${event.subjectName}】这节课的调课吗？',
              style: KnElementTextStyle.dialogContent(context)),
          actions: <Widget>[
            TextButton(
              child: Text('取消',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.blue)),
              onPressed: () async {
                final String deleteUrl =
                    '${KnConfig.apiBaseUrl}${Constants.apiLsnRescheCancel}/${event.lessonId}';
                try {
                  final response = await http.post(
                    Uri.parse(deleteUrl),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );
                  if (response.statusCode == 200) {
                    setState(() {
                      _fetchStudentLsn(
                          DateFormat('yyyy-MM-dd').format(_selectedDay));
                    });
                    Navigator.of(context).pop(true);
                  } else {
                    throw Exception('Failed to delete lesson');
                  }
                } catch (e) {
                  print('Error deleting lesson: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
  void _handleDeleteCourse(Kn01L002LsnBean event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('删除确认',
              style: KnElementTextStyle.dialogTitle(context, fontSize: 18)),
          content: Text('确定要删除【${event.subjectName}】这节课吗？',
              style: KnElementTextStyle.dialogContent(context)),
          actions: <Widget>[
            TextButton(
              child: Text('取消',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.blue)),
              onPressed: () async {
                final String deleteUrl =
                    '${KnConfig.apiBaseUrl}${Constants.apiLsnDelete}/${event.lessonId}';
                try {
                  final response = await http.delete(
                    Uri.parse(deleteUrl),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );
                  if (response.statusCode == 200) {
                    setState(() {
                      _fetchStudentLsn(
                          DateFormat('yyyy-MM-dd').format(_selectedDay));
                    });
                    Navigator.of(context).pop(true);
                  } else {
                    throw Exception('Failed to delete lesson');
                  }
                } catch (e) {
                  print('Error deleting lesson: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // [课程表新潮版] 2026-02-13 调课（新潮版专用，刷新周数据）
  void _handleReschLsnCourseForTrendy(Kn01L002LsnBean event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: RescheduleLessonDialog(
                lessonId: event.lessonId,
                classDuration: event.classDuration, // [Bug修复] 2026-02-16 传递实际课时时长
              ),
            ),
          ),
        );
      },
    ).then((result) {
      if (result == true) {
        _fetchWeekLessons(_currentWeekStart ?? _getWeekStart(_selectedDay));
      }
    });
  }

  // [课程表新潮版] 2026-02-13 取消调课（新潮版专用，刷新周数据）
  void _handleCancelRescheCourseForTrendy(Kn01L002LsnBean event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('取消调课确认',
              style: KnElementTextStyle.dialogTitle(context, fontSize: 18)),
          content: Text('要取消【${event.subjectName}】这节课的调课吗？',
              style: KnElementTextStyle.dialogContent(context)),
          actions: <Widget>[
            TextButton(
              child: Text('取消',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.blue)),
              onPressed: () async {
                final String deleteUrl =
                    '${KnConfig.apiBaseUrl}${Constants.apiLsnRescheCancel}/${event.lessonId}';
                try {
                  final response = await http.post(
                    Uri.parse(deleteUrl),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );
                  if (response.statusCode == 200) {
                    Navigator.of(context).pop(true);
                    _fetchWeekLessons(_currentWeekStart ?? _getWeekStart(_selectedDay));
                  } else {
                    throw Exception('Failed to cancel reschedule');
                  }
                } catch (e) {
                  print('Error canceling reschedule: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // [课程表新潮版] 2026-02-13 删除课程（新潮版专用，刷新周数据）
  void _handleDeleteCourseForTrendy(Kn01L002LsnBean event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('删除确认',
              style: KnElementTextStyle.dialogTitle(context, fontSize: 18)),
          content: Text('确定要删除【${event.subjectName}】这节课吗？',
              style: KnElementTextStyle.dialogContent(context)),
          actions: <Widget>[
            TextButton(
              child: Text('取消',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.blue)),
              onPressed: () async {
                final String deleteUrl =
                    '${KnConfig.apiBaseUrl}${Constants.apiLsnDelete}/${event.lessonId}';
                try {
                  final response = await http.delete(
                    Uri.parse(deleteUrl),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );
                  if (response.statusCode == 200) {
                    Navigator.of(context).pop(true);
                    _fetchWeekLessons(_currentWeekStart ?? _getWeekStart(_selectedDay));
                  } else {
                    throw Exception('Failed to delete lesson');
                  }
                } catch (e) {
                  print('Error deleting lesson: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // [课程表新潮版] 2026-02-13 签到（新潮版专用，刷新周数据）
  void _handleSignCourseForTrendy(Kn01L002LsnBean event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('执行签到确认',
              style: KnElementTextStyle.dialogTitle(context, fontSize: 18)),
          content: Text(
              '签到【${event.subjectName}】这节课，\n当日之内可以撤销，过了今日撤销不可！\n您确定要签到吗？',
              style: KnElementTextStyle.dialogContent(context)),
          actions: <Widget>[
            TextButton(
              child: Text('取消',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.blue)),
              onPressed: () async {
                final String signUrl =
                    '${KnConfig.apiBaseUrl}${Constants.apiStuLsnSign}/${event.lessonId}';
                try {
                  final response = await http.get(
                    Uri.parse(signUrl),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );
                  if (response.statusCode == 200) {
                    Navigator.of(context).pop(true);
                    _fetchWeekLessons(_currentWeekStart ?? _getWeekStart(_selectedDay));
                  } else {
                    throw Exception('Failed to sign lesson');
                  }
                } catch (e) {
                  print('Error signing lesson: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // [课程表新潮版] 2026-02-13 撤销签到（新潮版专用，刷新周数据）
  void _handleRestoreCourseForTrendy(Kn01L002LsnBean event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('撤销确认',
              style: KnElementTextStyle.dialogTitle(context, fontSize: 18)),
          content: Text('确实要撤销【${event.subjectName}】这节课吗？',
              style: KnElementTextStyle.dialogContent(context)),
          actions: <Widget>[
            TextButton(
              child: Text('取消',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定',
                  style: KnElementTextStyle.buttonText(context,
                      color: Colors.blue)),
              onPressed: () async {
                final String restoreUrl =
                    '${KnConfig.apiBaseUrl}${Constants.apiStuLsnRestore}/${event.lessonId}';
                try {
                  final response = await http.get(
                    Uri.parse(restoreUrl),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );
                  if (response.statusCode == 200) {
                    Navigator.of(context).pop(true);
                    _fetchWeekLessons(_currentWeekStart ?? _getWeekStart(_selectedDay));
                  } else {
                    throw Exception('Failed to restore lesson');
                  }
                } catch (e) {
                  print('Error restoring lesson: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // [课程表新潮版] 2026-02-13 备注（TrendyView用）
  void _handleNoteCourseForTrendy(Kn01L002LsnBean event) {
    String noteContent = event.memo ?? '';
    bool hasContent = noteContent.isNotEmpty;

    final TextEditingController controller =
        TextEditingController(text: noteContent)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: noteContent.length),
          );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Text('备注',
                      style: KnElementTextStyle.dialogTitle(context,
                          fontSize: 18, color: Constants.lessonThemeColor)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              content: TextField(
                controller: controller,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Constants.lessonThemeColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Constants.lessonThemeColor, width: 2),
                  ),
                  hintText: '请输入备注内容',
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  noteContent = value;
                  setDialogState(() {
                    hasContent = value.trim().isNotEmpty;
                  });
                },
                style: KnElementTextStyle.dialogContent(context, fontSize: 14),
              ),
              actions: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasContent ? Colors.pink[100] : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: hasContent
                        ? () async {
                            try {
                              final String memoUrl =
                                  '${KnConfig.apiBaseUrl}${Constants.apiStuLsnMemo}/${event.lessonId}';
                              final response = await http.post(
                                Uri.parse(memoUrl),
                                headers: {
                                  'Content-Type':
                                      'application/json; charset=utf-8',
                                },
                                body: json.encode({
                                  'memo': noteContent,
                                  'lessonId': event.lessonId,
                                }),
                              );
                              final responseData =
                                  json.decode(utf8.decode(response.bodyBytes));
                              if (response.statusCode == 200 &&
                                  responseData['status'] == 'success') {
                                Navigator.of(dialogContext).pop();
                                // [课程表新潮版] 刷新周数据
                                _fetchWeekLessons(_currentWeekStart ?? _getWeekStart(_selectedDay));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('备注更新成功'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '备注更新失败: ${responseData['message'] ?? '未知错误'}'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('发生错误: $e'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        : null,
                    child: Text('确认',
                        style: KnElementTextStyle.buttonText(context,
                            fontSize: 16, color: Colors.black87)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
  void _handleNoteCourse(Kn01L002LsnBean event) {
    String noteContent = event.memo ?? '';
    bool hasContent = noteContent.isNotEmpty;

    // 创建一个TextEditingController并设置初始值和光标位置
    final TextEditingController _controller =
        TextEditingController(text: noteContent)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: noteContent.length),
          );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // [Flutter页面主题改造] 2026-01-21 标题和文本框边缘颜色跟模块主题一致
            return AlertDialog(
              title: Row(
                children: [
                  Text('备注',
                      style: KnElementTextStyle.dialogTitle(context,
                          fontSize: 18, color: Constants.lessonThemeColor)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              content: TextField(
                controller: _controller,
                maxLines: 3,
                // 添加以下属性以支持IME输入
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                // 确保支持多语言输入
                enableInteractiveSelection: true,
                // 设置输入装饰
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Constants.lessonThemeColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Constants.lessonThemeColor, width: 2),
                  ),
                  hintText: '请输入备注内容',
                  // 添加内边距使文本不会太靠边
                  contentPadding: const EdgeInsets.all(12),
                ),
                // 修改onChanged处理方式
                onChanged: (value) {
                  noteContent = value;
                  setDialogState(() {
                    hasContent = value.trim().isNotEmpty;
                  });
                },
                // 添加文本样式
                style: KnElementTextStyle.dialogContent(context, fontSize: 14),
              ),
              actions: <Widget>[
                // [Flutter页面主题改造] 2026-01-21 增加按钮高度确保文字完整显示
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasContent ? Colors.pink[100] : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: hasContent
                        ? () async {
                            try {
                              final String memoUrl =
                                  '${KnConfig.apiBaseUrl}${Constants.apiStuLsnMemo}/${event.lessonId}';
                              final response = await http.post(
                                Uri.parse(memoUrl),
                                headers: {
                                  'Content-Type':
                                      'application/json; charset=utf-8', // 确保指定正确的字符集
                                },
                                body: json.encode({
                                  'memo': noteContent,
                                  'lessonId': event.lessonId,
                                }),
                              );
                              final responseData =
                                  json.decode(utf8.decode(response.bodyBytes));
                              if (response.statusCode == 200 &&
                                  responseData['status'] == 'success') {
                                Navigator.of(dialogContext).pop();
                                _fetchStudentLsn(DateFormat('yyyy-MM-dd')
                                    .format(_selectedDay));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('备注更新成功'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '备注更新失败: ${responseData['message'] ?? '未知错误'}'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('发生错误: $e'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        : null,
                    child: Text('确认',
                        style: KnElementTextStyle.buttonText(context,
                            fontSize: 16, color: Colors.black87)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
        title: '课程表',
        subtitle: '学生课程管理 >> 课程表',
        context: context,
        appBarBackgroundColor: Constants.lessonThemeColor,
        titleColor: Colors.white,
        subtitleBackgroundColor: Colors.blue.shade700,
        subtitleTextColor: Colors.white,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
        addInvisibleRightButton: false,
        // [课程表新潮版] 2026-02-13 添加视图切换按钮
        actions: [
          _buildViewToggleButton(),
        ],
      ),
      body: _isTrendyView ? _buildTrendyView() : _buildTraditionalView(),
    );
  }

  // [课程表新潮版] 2026-02-13 视图切换按钮
  Widget _buildViewToggleButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (_isTrendyView) {
                setState(() {
                  _isTrendyView = false;
                });
                _saveViewPreference(false); // [课程表新潮版] 2026-02-14 记忆选择
                // [周同步] 2026-02-16 切换回传统版时，同步focusedDay并加载对应日期数据
                if (_currentWeekStart != null) {
                  _focusedDay = _currentWeekStart!;
                  _selectedDay = _currentWeekStart!;
                }
                _fetchStudentLsn(DateFormat('yyyy-MM-dd').format(_selectedDay));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: !_isTrendyView ? Colors.white : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.list,
                    size: 16,
                    color: !_isTrendyView ? Constants.lessonThemeColor : Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '列表',
                    style: TextStyle(
                      fontSize: 12,
                      color: !_isTrendyView ? Constants.lessonThemeColor : Colors.white,
                      fontWeight: !_isTrendyView ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (!_isTrendyView) {
                setState(() {
                  _isTrendyView = true;
                });
                _saveViewPreference(true); // [课程表新潮版] 2026-02-14 记忆选择
                // [周同步] 2026-02-16 切换到新潮版时，使用focusedDay确定周（用户可能翻页但未选日）
                final weekStart = _getWeekStart(_focusedDay);
                _fetchWeekLessons(weekStart);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isTrendyView ? Colors.white : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grid_view,
                    size: 16,
                    color: _isTrendyView ? Constants.lessonThemeColor : Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '网格',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isTrendyView ? Constants.lessonThemeColor : Colors.white,
                      fontWeight: _isTrendyView ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [课程表新潮版] 2026-02-13 新潮版视图
  Widget _buildTrendyView() {
    return Stack(
      children: [
        ScheduleTrendyView(
          lessons: _weekLessons,
          themeColor: Constants.lessonThemeColor,
          initialWeekStart: _currentWeekStart, // [周同步] 2026-02-16 传入当前周起始日期
          highlightStuId: highlightedStuId,    // [闪烁动画] 2026-02-19 传递高亮学生ID
          highlightTime: currentHighlightedTime, // [闪烁动画] 2026-02-19 传递高亮时间
          onAddLesson: (date, hour, minute) {
            // 复用现有的AddCourseDialog
            final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
            _handleTimeSelection(context, time, overrideDate: date);
          },
          onEditLesson: (lesson) {
            // 复用现有的调课对话框（编辑功能已废弃，使用调课代替）
            _handleReschLsnCourseForTrendy(lesson);
          },
          onRescheduleLesson: (lesson) {
            // 复用现有的调课对话框
            _handleReschLsnCourseForTrendy(lesson);
          },
          onCancelReschedule: (lesson) {
            // 复用现有的取消调课逻辑
            _handleCancelRescheCourseForTrendy(lesson);
          },
          onDeleteLesson: (lesson) {
            // 复用现有的删除逻辑
            _handleDeleteCourseForTrendy(lesson);
          },
          // [课程表新潮版] 2026-02-13 签到/撤销签到/备注
          onSignLesson: (lesson) {
            _handleSignCourseForTrendy(lesson);
          },
          onRestoreLesson: (lesson) {
            _handleRestoreCourseForTrendy(lesson);
          },
          onNoteLesson: (lesson) {
            _handleNoteCourseForTrendy(lesson);
          },
          onWeekChanged: (weekStart) {
            // [周同步] 2026-02-16 周切换时同步更新传统版的选中日期
            setState(() {
              _selectedDay = weekStart;
              _focusedDay = weekStart;
            });
            // 周切换时加载新一周的数据
            _fetchWeekLessons(weekStart);
          },
        ),
        // 加载指示器
        if (_isLoading)
          const Center(
            child: KnLoadingIndicator(color: Constants.lessonThemeColor),
          ),
      ],
    );
  }

  // [课程表新潮版] 2026-02-13 传统版视图
  Widget _buildTraditionalView() {
    return Column(
      children: [
        // 日历部分始终显示
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday, // 星期排列从Mon开始
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _fetchStudentLsn(DateFormat('yyyy-MM-dd').format(selectedDay));
            },
            // [周同步] 2026-02-16 翻页时同步focusedDay，确保切换到新潮版时周正确
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Constants.lessonThemeColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Constants.lessonThemeColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // 日期标题部分始终显示
        Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            DateFormat('yyyy年MM月dd日').format(_selectedDay),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // [课题二] 2026-02-08 课程时间轴部分，使用Stack+固定高度实现精确时间对齐
        Expanded(
          child: Stack(
            children: [
              // 底层：可滚动的时间轴 + 卡片叠加层
              SingleChildScrollView(
                controller: _scrollController,
                child: SizedBox(
                  // 总高度 = 56个时间槽 × _slotHeight
                  height: ((22 - 8) * 4) * _slotHeight,
                  child: Stack(
                    children: [
                      // 时间轴层（固定高度槽位）
                      Column(
                        children: List.generate((22 - 8) * 4, (index) {
                          int hour = 8 + (index ~/ 4);
                          int minute = (index % 4) * 15;
                          String time =
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                          return GestureDetector(
                            onTap: () => _handleTimeSelection(context, time),
                            child: SizedBox(
                              height: _slotHeight, // 固定槽高度
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: time.endsWith(':00')
                                          ? Text(time,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.black))
                                          : RichText(
                                              text: TextSpan(children: [
                                                TextSpan(
                                                    text:
                                                        time.substring(0, 3),
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w300,
                                                        color: Colors.white)),
                                                TextSpan(
                                                    text: time.substring(3),
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w300,
                                                        color: Colors.black)),
                                              ]),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                      child: Container(
                                          height: 0.5,
                                          color: Colors.grey.shade300)),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      // 卡片层（绝对定位）
                      // [BUG修复] 2026-02-08 调整渲染顺序：调课From卡片默认居后，被点击的卡片居前
                      if (!_isLoading) ..._getSortedLessonCards(),
                    ],
                  ),
                ),
              ),
              // 加载指示器
              if (_isLoading)
                const Center(
                    child: KnLoadingIndicator(
                        color: Constants.lessonThemeColor)),
            ],
          ),
        ),
      ],
    );
  }
}

// TimeTile Widget 的定义
class TimeTile extends StatefulWidget {
  final String time;
  final List<Kn01L002LsnBean> events;
  final VoidCallback onTap;
  final Function(Kn01L002LsnBean) onSign;
  final Function(Kn01L002LsnBean) onRestore;
  // final Function(Kn01L002LsnBean) onEdit; 废弃课程的修改处理
  final Function(Kn01L002LsnBean) onDelete;
  final Function(Kn01L002LsnBean) onReschLsn;
  final Function(Kn01L002LsnBean) onCancel;
  final Function(Kn01L002LsnBean) onAddmemo;
  final DateTime selectedDay;
  final Function(String, String, bool) onTimeChanged;
  final String? highlightedTime;
  final Function(String) onHighlightChanged;
  final String? highlightedStuId; // 新增

  const TimeTile({
    super.key,
    required this.time,
    this.events = const [],
    required this.onTap,
    required this.onSign,
    required this.onRestore,
    // required this.onEdit,
    required this.onDelete,
    required this.onReschLsn,
    required this.onCancel,
    required this.onAddmemo,
    required this.selectedDay,
    required this.onTimeChanged,
    required this.highlightedTime,
    required this.onHighlightChanged,
    this.highlightedStuId, // 新增
  });

  @override
  _TimeTileState createState() => _TimeTileState();
}

class _TimeTileState extends State<TimeTile>
    with SingleTickerProviderStateMixin {
  GlobalKey timeLineKey = GlobalKey();
  String? pressedLessonId;
  Timer? _blinkTimer;
  late AnimationController _fadeController; // 动画控制器，控制动画
  late Animation<double> _fadeAnimation; // 动画显示课程卡片外缘显示红色，然后颜色消失
  bool _isSaving = false; // 新增：保存状态标志

  // 修改高亮判断逻辑
  bool _isHighlighted(Kn01L002LsnBean event) {
    final bool timeMatches = widget.time == widget.highlightedTime;
    final bool stuIdMatches = event.stuId == widget.highlightedStuId;
    return timeMatches && stuIdMatches;
  }

  @override
  void initState() {
    super.initState();
    // 动画初期化
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);
    // 如果该课程卡片需要高亮显示，启动闪烁动画
    if (widget.events.isNotEmpty) {
      for (var event in widget.events) {
        if (_isHighlighted(event)) {
          _startBlinking();
          break;
        }
      }
    }
  }

// 添加闪烁控制方法
  void _startBlinking() {
    // 取消已存在的闪烁
    _blinkTimer?.cancel();

    // 重置控制器状态
    _fadeController.value = 1.0;

    // 每500毫秒闪烁一次，持续10秒（总共闪烁20次）
    int blinkCount = 0;
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && blinkCount < 20) {
        setState(() {
          _fadeController.value = _fadeController.value == 0 ? 1.0 : 0.0;
        });
        blinkCount++;
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _fadeController.value = 0.0; // 确保动画结束时边框消失
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel(); // 确保在销毁时取消计时器
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TimeTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 检查事件列表是否发生变化
    bool eventsChanged = widget.events.length != oldWidget.events.length;
    if (!eventsChanged && widget.events.isNotEmpty) {
      for (int i = 0; i < widget.events.length; i++) {
        if (widget.events[i].lessonId != oldWidget.events[i].lessonId) {
          eventsChanged = true;
          break;
        }
      }
    }

    // 当高亮状态发生改变或事件列表发生变化时，触发动画
    if (widget.events.isNotEmpty &&
        (widget.highlightedTime != oldWidget.highlightedTime ||
            widget.highlightedStuId != oldWidget.highlightedStuId ||
            eventsChanged)) {
      for (var event in widget.events) {
        if (_isHighlighted(event)) {
          _startBlinking();
          break;
        }
      }
    }
  }

  // 修改：调整长按处理逻辑
  void _handleLongPressStart(Kn01L002LsnBean event) async {
    if (!_isGrayBackground(event)) {
      await HapticFeedback.heavyImpact();
      setState(() {
        pressedLessonId = event.lessonId;
        _isSaving = false;
      });
      _fadeController.reset();

      // 获取当前卡片所在的时间位置
      final String currentTime = widget.time; // 直接使用时间轴上的时间
      // 判断是否有调课From
      final isRescheduledLesson = (event.lsnAdjustedDate.isNotEmpty == true);

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return RescheduleLessonTimeDialog(
            initialDate: widget.selectedDay,
            initialTime: currentTime, // 使用时间轴上的时间
            onSave: (String newTime) async {
              try {
                setState(() {
                  _isSaving = true;
                });
                await widget.onTimeChanged(
                    event.lessonId, newTime, isRescheduledLesson);
                return true;
              } catch (e) {
                setState(() {
                  _isSaving = false;
                });
                rethrow;
              }
            },
          );
        },
      );

      if (result == true && mounted) {
        // 保存成功，开始2秒计时后执行渐变动画
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _isSaving) {
            _fadeController.forward().then((_) {
              if (mounted) {
                setState(() {
                  pressedLessonId = null;
                  _isSaving = false;
                });
              }
            });
          }
        });
      } else {
        // 取消或关闭对话框，直接清除状态
        if (mounted) {
          setState(() {
            pressedLessonId = null;
            _isSaving = false;
          });
        }
      }
    }
  }

  void _handleLongPressEnd() {
    // 长按结束时不立即清除边框
  }

  bool _isGrayBackground(Kn01L002LsnBean event) {
    String selectedDayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDay);

    String eventScheduleDateStr = '';
    if (event.schedualDate.length >= 10) {
      eventScheduleDateStr = event.schedualDate.substring(0, 10);
    }

    String eventAdjustedDateStr = '';
    if (event.lsnAdjustedDate.length >= 10) {
      eventAdjustedDateStr = event.lsnAdjustedDate.substring(0, 10);
    }

    bool hasBeenRescheduled = event.lsnAdjustedDate.isNotEmpty;
    bool hasBeenSigned = event.scanQrDate.isNotEmpty;

    return ((selectedDayStr == eventScheduleDateStr) && hasBeenRescheduled) ||
        ((selectedDayStr == eventScheduleDateStr) && hasBeenSigned) ||
        ((selectedDayStr == eventAdjustedDateStr) && hasBeenSigned);
  }

  @override
  Widget build(BuildContext context) {
    // [Flutter页面主题改造] 2026-01-18 时间轴行间距调整为原来的2倍
    return GestureDetector(
      // 将GestureDetector移到最外层
      onTap: widget.onTap,
      child: Container(
        child: widget.events.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0), // 无事件时也添加间距
                child: _buildTimeLine(),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8.0), // 4.0 -> 8.0 (行间距调整为原来的2倍)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      key: timeLineKey,
                      child: _buildTimeLine(),
                    ),
                    ...widget.events
                        .map((event) => _buildEventTile(context, event)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTimeLine() {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Padding(
            padding: const EdgeInsets.only(left: 0, right: 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildTimeText(),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeText() {
    final isFullHour = widget.time.endsWith(':00');

    if (isFullHour) {
      return Text(
        widget.time,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w300,
          color: Colors.black,
        ),
      );
    } else {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: widget.time.substring(0, 3),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
            TextSpan(
              text: widget.time.substring(3),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEventTile(BuildContext context, Kn01L002LsnBean event) {
    final selectedDayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
    final eventScheduleDateStr = event.schedualDate.length >= 10
        ? event.schedualDate.substring(0, 10)
        : '';
    final eventAdjustedDateStr = event.lsnAdjustedDate.length >= 10
        ? event.lsnAdjustedDate.substring(0, 10)
        : '';
    final hasBeenRescheduled = event.lsnAdjustedDate.isNotEmpty;

    final hasBeenSigned = event.scanQrDate.isNotEmpty;

    final isScheduledUnsignedLsn = selectedDayStr == eventScheduleDateStr &&
        !hasBeenRescheduled &&
        !hasBeenSigned;

    final isScheduledSignedLsn = selectedDayStr == eventScheduleDateStr &&
        !hasBeenRescheduled &&
        hasBeenSigned;

    final isAdjustedUnSignedLsnFrom = selectedDayStr == eventScheduleDateStr &&
        hasBeenRescheduled &&
        selectedDayStr != eventAdjustedDateStr &&
        !hasBeenSigned;

    final isAdjustedSignedLsnFrom = selectedDayStr == eventScheduleDateStr &&
        hasBeenRescheduled &&
        selectedDayStr != eventAdjustedDateStr &&
        hasBeenSigned;

    final isAdjustedUnSignedLsnTo = selectedDayStr != eventScheduleDateStr &&
        hasBeenRescheduled &&
        selectedDayStr == eventAdjustedDateStr &&
        !hasBeenSigned;

    final isAdjustedSignedLsnTo = selectedDayStr != eventScheduleDateStr &&
        hasBeenRescheduled &&
        selectedDayStr == eventAdjustedDateStr &&
        hasBeenSigned;

    Color backgroundColor;
    Color textColor = Colors.black;
    String additionalInfo = '';

    if (isAdjustedUnSignedLsnFrom || isAdjustedSignedLsnFrom) {
      backgroundColor = Colors.grey.shade300;
      additionalInfo = '调课To：${event.lsnAdjustedDate}';
    } else if (isAdjustedUnSignedLsnTo) {
      backgroundColor = Colors.orange.shade100;
      additionalInfo = '调课From：${event.schedualDate}';
    } else if (isAdjustedSignedLsnTo) {
      backgroundColor = Colors.grey.shade500;
      additionalInfo = '调课From：${event.schedualDate}';
    } else if (isScheduledUnsignedLsn) {
      // [Flutter页面主题改造] 2026-01-20 根据课程类型设置不同背景颜色
      // lessonType: 0=课时课(绿色), 1=计划课(蓝色), 2=加课(粉色)
      final lessonCardColors = context.lessonCardColors;
      switch (event.lessonType) {
        case 0: // 课时课
          backgroundColor = lessonCardColors.hourly;
          break;
        case 2: // 加课
          backgroundColor = lessonCardColors.extra;
          break;
        case 1: // 计划课
        default:
          backgroundColor = lessonCardColors.planned;
          break;
      }
    } else if (isScheduledSignedLsn) {
      backgroundColor = Colors.grey.shade500;
    } else {
      backgroundColor = Colors.black12;
    }

    TextDecoration textDecoration = TextDecoration.none;
    if (isScheduledSignedLsn ||
        isAdjustedSignedLsnFrom ||
        isAdjustedSignedLsnTo) {
      textDecoration = TextDecoration.lineThrough;
    }
    return GestureDetector(
      onLongPressStart: (_) => _handleLongPressStart(event),
      onLongPressEnd: (_) => _handleLongPressEnd(),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(left: 56, top: 4, bottom: 4, right: 8),
        // 设置课程卡片的背景颜色
        color: _isHighlighted(event) ? Colors.red[100] : backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: _isHighlighted(event) // 修改这里的判断条件
              ? BorderSide(
                  color: Colors.red.withOpacity(_fadeAnimation.value),
                  width: 2.0,
                )
              : (pressedLessonId == event.lessonId && _isSaving
                  ? BorderSide(
                      color: Colors.red.withOpacity(_fadeAnimation.value),
                      width: 2.0,
                    )
                  : BorderSide.none),
        ),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: child!,
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [Flutter页面主题改造] 2026-01-19 使用JSON配置的字体样式
                    Text(
                      event.stuName,
                      style: KnElementTextStyle.cardTitle(
                        context,
                        fontSize: 18,
                        color: textColor,
                      ).copyWith(decoration: textDecoration),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${event.subjectName} - ${event.subjectSubName}',
                            style: KnElementTextStyle.cardBody(
                              context,
                              fontSize: 12,
                              color: textColor,
                              decoration: textDecoration,
                            ),
                          ),
                        ),
                        // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                        if (additionalInfo.isNotEmpty)
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: Text(
                                additionalInfo,
                                style: KnElementTextStyle.cardBody(
                                  context,
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${event.classDuration}分钟 | ${event.lessonType == 0 ? '课结算' : event.lessonType == 1 ? '月计划' : '月加课'}',
                            style: KnElementTextStyle.cardBody(
                              context,
                              fontSize: 12,
                              color: textColor,
                              decoration: textDecoration,
                            ),
                          ),
                        ),
                        // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                        if (event.memo != null &&
                            event.memo!.isNotEmpty &&
                            (!isAdjustedUnSignedLsnTo &&
                                !isAdjustedSignedLsnTo))
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: Text(
                                '备注: ${event.memo}',
                                style: KnElementTextStyle.cardBody(
                                  context,
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onSelected: (String result) {
                  switch (result) {
                    case '签到':
                      widget.onSign(event);
                      break;
                    case '撤销':
                      widget.onRestore(event);
                      break;
                    // case '修改':
                    //   widget.onEdit(event);
                    //   break;
                    case '调课':
                      widget.onReschLsn(event);
                      break;
                    case '取消':
                      widget.onCancel(event);
                      break;
                    case '删除':
                      widget.onDelete(event);
                      break;
                    case '备注':
                      widget.onAddmemo(event);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) =>
                    _buildPopupMenuItems(event),
                constraints: const BoxConstraints(
                  minWidth: 50,
                  maxWidth: 60,
                ),
                position: PopupMenuPosition.under,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
  List<PopupMenuEntry<String>> _buildPopupMenuItems(Kn01L002LsnBean event) {
    final menuStyle = KnElementTextStyle.popupMenuItem(context);

    if ((event.scanQrDate != null) && (event.scanQrDate.isNotEmpty)) {
      if (DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal()) ==
          event.scanQrDate) {
        return [
          PopupMenuItem<String>(
            value: '撤销',
            height: 36,
            child: Text('撤销', style: menuStyle),
          ),
          PopupMenuItem<String>(
            value: '备注',
            height: 36,
            child: Text('备注', style: menuStyle),
          ),
        ];
      } else {
        return [
          PopupMenuItem<String>(
            value: '备注',
            height: 36,
            child: Text('备注', style: menuStyle),
          ),
        ];
      }
    }

    // 检查是否为已调课但未签到的课程
    final selectedDayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
    final eventScheduleDateStr = event.schedualDate.length >= 10
        ? event.schedualDate.substring(0, 10)
        : '';
    final eventAdjustedDateStr = event.lsnAdjustedDate.length >= 10
        ? event.lsnAdjustedDate.substring(0, 10)
        : '';

    final hasBeenRescheduled = event.lsnAdjustedDate.isNotEmpty;
    final hasBeenSigned = event.scanQrDate.isNotEmpty;

    final isAdjustedUnSignedLsnFrom = selectedDayStr == eventScheduleDateStr &&
        hasBeenRescheduled &&
        selectedDayStr != eventAdjustedDateStr &&
        !hasBeenSigned;

    if (isAdjustedUnSignedLsnFrom) {
      return <PopupMenuEntry<String>>[
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '调课',
          height: 36,
          child: Text('调课', style: menuStyle),
        ),
        PopupMenuItem<String>(
          value: '取消',
          height: 36,
          child: Text('取消', style: menuStyle),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '删除',
          height: 36,
          child: Text('删除', style: menuStyle),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '备注',
          height: 36,
          child: Text('备注', style: menuStyle),
        ),
      ];
    } else {
      return <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: '签到',
          enabled: !widget.selectedDay.isAfter(DateTime.now()),
          height: 36,
          child: Text(
            '签到',
            style: menuStyle.copyWith(
                color: widget.selectedDay.isAfter(DateTime.now())
                    ? Colors.grey
                    : null),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '调课',
          height: 36,
          child: Text('调课', style: menuStyle),
        ),
        PopupMenuItem<String>(
          value: '删除',
          height: 36,
          child: Text('删除', style: menuStyle),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: '备注',
          height: 36,
          child: Text('备注', style: menuStyle),
        ),
      ];
    }
  }
}

// [课题二] 2026-02-08 时间线末端三角形绘制器
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // 底部中心（三角形尖端）
      ..lineTo(0, 0) // 左上角
      ..lineTo(size.width, 0) // 右上角
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
