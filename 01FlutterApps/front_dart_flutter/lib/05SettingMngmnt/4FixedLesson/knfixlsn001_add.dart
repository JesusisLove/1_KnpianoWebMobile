// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../Constants.dart';
// [固定排课排他功能] 2026-02-13 导入冲突检测相关组件
import '../../01LessonMngmnt/1LessonSchedual/ConflictInfo.dart';
import '../../01LessonMngmnt/1LessonSchedual/ConflictWarningDialog.dart';

// ignore: must_be_immutable
class ScheduleForm extends StatefulWidget {
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  final String? preSelectedDay; // 新增：接收预选中的星期
  final String? preSelectedHour; // [新潮界面] 2026-02-12 接收预选中的小时
  final String? preSelectedMinute; // [新潮界面] 2026-02-12 接收预选中的分钟

  ScheduleForm({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
    this.preSelectedDay, // 新增：可选参数
    this.preSelectedHour, // [新潮界面] 可选参数
    this.preSelectedMinute, // [新潮界面] 可选参数
  });

  @override
  ScheduleFormState createState() => ScheduleFormState();
}

class ScheduleFormState extends State<ScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  String titleName = "学生固定排课（新規）";

  String? selectedStuId;
  String? selectedSubId;
  String? selectedStudent;
  String? selectedSubject;
  String? selectedDay;
  String? selectedHour;
  String? selectedMinute;

  // WeekDays初期化
  List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // 只要从早08点到22点之间到时间
  List<String> hours =
      List.generate(15, (index) => (index + 8).toString().padLeft(2, '0'));
  List<String> minutes = ['00', '15', '30', '45'];

  // 存储从API获取的数据
  List<dynamic> rawData = [];

  // 存储处理后的学生列表和科目列表
  Map<String, String> stuNameList = {};
  Map<String, List<Map<String, String>>> subjectsByStudent = {};
  // [Bug修复] 2026-02-15 存储学生-科目的课时时长（分钟），用于冲突检测时正确计算结束时间
  // key: "${stuId}_${subjectId}", value: minutesPerLsn
  Map<String, int> classDurationByStudentSubject = {};

  // 画面初期化
  @override
  void initState() {
    super.initState();
    // 设置预选中的星期
    if (widget.preSelectedDay != null && days.contains(widget.preSelectedDay)) {
      selectedDay = widget.preSelectedDay;
    }
    // [新潮界面] 2026-02-12 设置预选中的小时
    if (widget.preSelectedHour != null && hours.contains(widget.preSelectedHour)) {
      selectedHour = widget.preSelectedHour;
    }
    // [新潮界面] 2026-02-12 设置预选中的分钟
    if (widget.preSelectedMinute != null && minutes.contains(widget.preSelectedMinute)) {
      selectedMinute = widget.preSelectedMinute;
    }
    fetchLessons(); // 在初始化时调用fetchLessons，并将结果存储在futureFixLsnList中
  }

  Future<void> fetchLessons() async {
    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.fixeDocStuSubInfoGet}';
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> rawData = json.decode(utf8.decode(response.bodyBytes));
        Map<String, List<Map<String, String>>> tempSubjects = {};
        for (var data in rawData) {
          String stuId = data['stuId'];
          String stuName = data['stuName'].trim();
          String subjectId = data['subjectId'];
          String subjectName = data['subjectName'].trim();
          if (!stuNameList.containsKey(stuId)) {
            stuNameList[stuId] = stuName;
          }
          if (!tempSubjects.containsKey(stuId)) {
            tempSubjects[stuId] = [];
          }
          tempSubjects[stuId]
              ?.add({'subjectId': subjectId, 'subjectName': subjectName});
          // [Bug修复] 2026-02-15 读取课时时长（minutesPerLsn），默认45分钟
          final minutesPerLsn = data['minutesPerLsn'] as int? ?? 45;
          classDurationByStudentSubject['${stuId}_$subjectId'] = minutesPerLsn;
        }
        setState(() {
          subjectsByStudent = tempSubjects;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
        title: titleName,
        subtitle: '${widget.pagePath} >> $titleName',
        context: context,
        appBarBackgroundColor: widget.knBgColor,
        titleColor: Color.fromARGB(
            widget.knFontColor.alpha,
            widget.knFontColor.red - 20,
            widget.knFontColor.green - 20,
            widget.knFontColor.blue - 20),
        // [Flutter页面主题改造] 2026-01-26 副标题背景使用主题色的深色版本
        subtitleBackgroundColor: Color.fromARGB(
            widget.knBgColor.alpha,
            (widget.knBgColor.red * 0.6).round(),
            (widget.knBgColor.green * 0.6).round(),
            (widget.knBgColor.blue * 0.6).round()),
        subtitleTextColor: Colors.white,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
        addInvisibleRightButton: false, // 显示Home按钮返回主菜单
        currentNavIndex: 4,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: selectedStuId,
                decoration: const InputDecoration(labelText: '学生姓名'),
                items: stuNameList.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedStuId = newValue;
                    selectedStudent = stuNameList[newValue];
                    selectedSubId = null;
                    selectedSubject = null;
                  });
                },
                validator: (value) => value == null ? '请选择学生' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedSubId,
                decoration: const InputDecoration(labelText: '科目名称'),
                items: selectedStuId != null
                    ? subjectsByStudent[selectedStuId]?.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject['subjectId'],
                          child: Text(subject['subjectName']!),
                        );
                      }).toList()
                    : [],
                onChanged: (newValue) {
                  setState(() {
                    selectedSubId = newValue;
                    selectedSubject = subjectsByStudent[selectedStuId]
                        ?.firstWhere((subject) =>
                            subject['subjectId'] == newValue)['subjectName'];
                  });
                },
                validator: (value) => value == null ? '请选择科目' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDay,
                decoration: const InputDecoration(labelText: '固定星期几'),
                items: days.map((String day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedDay = newValue;
                  });
                },
                validator: (value) => value == null ? '请选择星期' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedHour,
                      decoration: const InputDecoration(labelText: '固定在几点'),
                      items: hours.map((String hour) {
                        return DropdownMenuItem<String>(
                          value: hour,
                          child: Text(hour),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedHour = newValue;
                        });
                      },
                      validator: (value) => value == null ? '请选择小时' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedMinute,
                      decoration: const InputDecoration(labelText: '固定在几分'),
                      items: minutes.map((String minute) {
                        return DropdownMenuItem<String>(
                          value: minute,
                          child: Text(minute),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedMinute = newValue;
                        });
                      },
                      validator: (value) => value == null ? '请选择分钟' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: widget.knBgColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [固定排课排他功能] 2026-02-13 修改为支持冲突检测的两阶段提交
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _saveFixedLesson(forceOverlap: false);
    }
  }

  /// [固定排课排他功能] 2026-02-13 集成冲突检测的保存方法
  Future<void> _saveFixedLesson({bool forceOverlap = false}) async {
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在添加固定排课处理...'),
              ],
            ),
          ),
        );
      },
    );

    // 学生固定排课新规登录画面，点击"保存"按钮的url请求
    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.fixedLsnInfoAdd}';

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'stuId': selectedStuId,
          'subjectId': selectedSubId,
          'fixedWeek': selectedDay,
          'fixedHour': selectedHour,
          'fixedMinute': selectedMinute,
          'forceOverlap': forceOverlap, // [固定排课排他功能] 强制保存标记
        }),
      );

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      // [固定排课排他功能] 解析响应，处理冲突检测结果
      final responseBody = utf8.decode(response.bodyBytes);

      // 尝试解析为JSON
      dynamic responseData;
      try {
        responseData = json.decode(responseBody);
      } catch (_) {
        // 非JSON响应，按原有逻辑处理
        if (response.statusCode == 200) {
          _showSuccessDialog();
          return;
        } else {
          _showErrorDialog('保存失败: $responseBody');
          return;
        }
      }

      // 处理JSON响应
      if (responseData is Map<String, dynamic>) {
        final result = ConflictCheckResult.fromJson(responseData);

        if (result.success) {
          // 保存成功
          _showSuccessDialog();
        } else if (result.hasConflict) {
          // 检测到冲突，构建新排课时间信息用于时间轴可视化
          final startTime = '$selectedHour:$selectedMinute';
          // [Bug修复] 2026-02-15 使用学生实际的课时时长，而非硬编码45分钟
          final duration = classDurationByStudentSubject['${selectedStuId}_$selectedSubId'] ?? 45;
          final endTime = _calculateEndTime(startTime, duration);
          final newSchedule = NewScheduleInfo(
            startTime: startTime,
            endTime: endTime,
            stuName: selectedStudent,
          );

          if (result.isSameStudentConflict) {
            // 同一学生自我冲突，严格禁止
            await ConflictWarningDialog.showSameStudentConflict(
              context,
              result.conflicts,
              newSchedule: newSchedule,
            );
          } else {
            // 不同学生冲突，显示警告让用户确认
            final confirmed = await ConflictWarningDialog.show(
              context,
              result.conflicts,
              newSchedule: newSchedule,
            );

            if (confirmed) {
              // 用户确认继续，强制保存
              await _saveFixedLesson(forceOverlap: true);
            }
          }
        } else {
          // 其他错误
          _showErrorDialog(result.message);
        }
      } else {
        // 响应不是预期的Map格式，按成功处理（兼容旧版后端）
        if (response.statusCode == 200) {
          _showSuccessDialog();
        } else {
          _showErrorDialog('保存失败');
        }
      }
    } catch (e) {
      // 如果发生错误，确保关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
      }
      _showErrorDialog('发生错误: $e');
    }
  }

  /// 显示成功对话框
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提交成功'),
        content: const Text('固定排课时间已提交'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提交失败'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// [固定排课排他功能] 2026-02-13 计算课程结束时间
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
