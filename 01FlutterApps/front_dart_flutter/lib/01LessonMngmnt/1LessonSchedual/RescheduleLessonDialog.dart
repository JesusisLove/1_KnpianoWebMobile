import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../ApiConfig/KnApiConfig.dart';
import '../../Constants.dart';
import '../../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-21
import 'dart:convert';
import 'ConflictInfo.dart'; // [课程排他状态功能] 2026-02-08
import 'ConflictWarningDialog.dart'; // [课程排他状态功能] 2026-02-08

class RescheduleLessonDialog extends StatefulWidget {
  final String lessonId;
  // [Bug修复] 2026-02-16 接收课时时长参数，避免硬编码45分钟
  final int classDuration;

  const RescheduleLessonDialog({
    super.key,
    required this.lessonId,
    this.classDuration = 45, // 默认45分钟，兼容旧调用
  });

  @override
  // ignore: library_private_types_in_public_api
  _RescheduleLessonDialogState createState() => _RescheduleLessonDialogState();
}

class _RescheduleLessonDialogState extends State<RescheduleLessonDialog> {
  DateTime? selectedDate;
  TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
        title: Text('将该课调至',
            style: KnElementTextStyle.appBarTitle(context, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择日期：'),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: '选择日期',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                        : '',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('选择时间：'),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: '选择时间',
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  controller:
                      TextEditingController(text: selectedTime.format(context)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveRescheduledLesson,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // 当前选择的日期
      firstDate: DateTime(2010), // 设置一个足够早的年份作为可选择的最早日期
      lastDate: DateTime(9999), // 设置一个足够晚的年份作为可选择的最晚日期

      // 关键部分: 不需要设置selectableDayPredicate，或者设置为始终返回true
      // selectableDayPredicate 默认允许选择所有日期
      // 如果之前有设置这个参数限制日期选择，需要移除或修改它
      selectableDayPredicate: (DateTime day) {
        // 返回true表示该日期可选
        return true;
      },

      // 可选: 自定义日期选择器主题
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // 主题颜色
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        // 处理日期选择后的逻辑...
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // 点击保存按钮
  void _saveRescheduledLesson() {
    // 直接使用 TimeOfDay 的 hour 和 minute 属性
    final selectedHour = selectedTime.hour;
    final selectedMinute = selectedTime.minute;

    // 验证小时在08-21点以内
    if (selectedHour < 8 || selectedHour > 21) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择有效的时间段从8点-21点')),
      );
      return;
    }

    // 验证分钟只有（00.15，30，45）有效
    if (![0, 15, 30, 45].contains(selectedMinute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('有效的分钟只有00，15，30，45')),
      );
      return;
    }

    // 格式化日期和时间
    final formattedTime =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
    final lsnAdjustedDate =
        '${DateFormat('yyyy-MM-dd').format(selectedDate!)} $formattedTime';

    final Map<String, dynamic> adjustedStuLsn = {
      'lessonId': widget.lessonId,
      'lsnAdjustedDate': lsnAdjustedDate,
    };

    _saveLesson(adjustedStuLsn);
  }

  // [课程排他状态功能] 2026-02-10 调课冲突检测（塞课场景）
  Future<void> _saveLesson(Map<String, dynamic> lessonData,
      {bool forceOverlap = false}) async {
    try {
      // 添加强制保存标记
      lessonData['forceOverlap'] = forceOverlap;

      // 使用调课专用API
      final String apiUpdateTimeUrl =
          '${KnConfig.apiBaseUrl}${Constants.apiUpdateLessonTime}';
      final response = await http.post(
        Uri.parse(apiUpdateTimeUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(lessonData),
      );

      // [课程排他状态功能] 解析响应（200成功/警告, 409冲突禁止）
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200 || response.statusCode == 409) {
        final responseData = json.decode(decodedBody);

        if (responseData is Map<String, dynamic>) {
          final result = ConflictCheckResult.fromJson(responseData);

          if (result.success) {
            // 调课成功
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop(true);
          } else if (result.hasConflict) {
            // 检测到冲突
            // [2026-02-12] 构建新排课时间信息，用于时间轴可视化
            final formattedTime =
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
            // [Bug修复] 2026-02-16 使用实际课时时长，而非硬编码45分钟
            final newSchedule = NewScheduleInfo(
              startTime: formattedTime,
              endTime: _calculateEndTime(formattedTime, widget.classDuration),
            );

            if (result.isSameStudentConflict) {
              // 同一学生自我冲突，严格禁止
              // ignore: use_build_context_synchronously
              await ConflictWarningDialog.showSameStudentConflict(
                context,
                result.conflicts,
                newSchedule: newSchedule,
              );
            } else {
              // 不同学生冲突，显示警告让用户确认
              // ignore: use_build_context_synchronously
              final confirmed = await ConflictWarningDialog.show(
                context,
                result.conflicts,
                newSchedule: newSchedule,
              );

              if (confirmed) {
                // 用户确认继续，强制调课
                await _saveLesson(lessonData, forceOverlap: true);
              }
            }
          } else {
            // 其他错误
            _showErrorDialog(result.message);
          }
        } else {
          // 兼容旧版本响应（直接返回成功字符串）
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('调课失败: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('调课失败: ${e.toString()}');
    }
  }

  /// [2026-02-12] 计算结束时间（开始时间 + 课程时长）
  String _calculateEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    if (parts.length != 2) return startTime;

    final startHour = int.tryParse(parts[0]) ?? 0;
    final startMinute = int.tryParse(parts[1]) ?? 0;

    final totalMinutes = startHour * 60 + startMinute + durationMinutes;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;

    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('错误'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
