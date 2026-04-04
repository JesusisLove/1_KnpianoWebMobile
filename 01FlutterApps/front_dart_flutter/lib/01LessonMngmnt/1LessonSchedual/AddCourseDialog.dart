// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../03StuDocMngmnt/4stuDoc/DurationBean.dart';
import '../../03StuDocMngmnt/4stuDoc/Kn03D004StuDocBean.dart';
import '../../ApiConfig/KnApiConfig.dart';
import '../../Constants.dart';
import 'ConflictInfo.dart'; // [课程排他状态功能] 2026-02-08
import 'ConflictWarningDialog.dart'; // [课程排他状态功能] 2026-02-08
import '../../CommonProcess/customUI/KnDialog.dart';
import '../../CommonProcess/KnMsg.dart';

class AddCourseDialog extends StatefulWidget {
  const AddCourseDialog({
    super.key,
    required this.scheduleDate,
    required this.scheduleTime,
    // [集体课条件判断] 2026-02-26 新增
    // 来自课程详细对话框「集体上课checkbox」的选中状态
    this.isGroupLessonScheduling = false,
  });
  final String scheduleDate;
  final String scheduleTime;
  // [集体课条件判断] 2026-02-26 新增
  final bool isGroupLessonScheduling;
  @override
  _AddCourseDialogState createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  String? selectedStudent;
  String? selectedSubject;
  String? subjectLevel;
  String? courseType;
  int? lessonType;
  int? selectedDuration;
  List<Kn03D004StuDocBean> stuDocList = [];
  List<dynamic> stuSubjectsList = [];
  List<DurationBean> durationList = [];
  bool isRadioEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
    fetchDurations();
    // 初始化时设置courseType为null，表示所有radio按钮处于为选中状态
    courseType = null;
  }

  // 从档案表里取出入档案的学生初期化学生下拉列表框
  Future<void> _fetchStudentData() async {
    try {
      final String apiStuDocUrl =
          '${KnConfig.apiBaseUrl}${Constants.stuDocInfoView}';
      final response = await http.get(Uri.parse(apiStuDocUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> stuDocJson = json.decode(decodedBody);
        setState(() {
          stuDocList = stuDocJson
              .map((json) => Kn03D004StuDocBean.fromJson(json))
              .toList();
        });
      } else {
        throw Exception('Failed to load archived students');
      }
    } catch (e) {
      _showErrorDialog('加载学生数据失败: ${e.toString()}');
    }
  }

  // 从档案表里取入档案的学生最新的科目初期化科目下拉列表框
  Future<void> _fetchStudentSubjects(String stuId) async {
    try {
      final String apiLatestSubjectsnUrl =
          '${KnConfig.apiBaseUrl}${Constants.apiLatestSubjectsnUrl}/$stuId';
      final responseStuSubjects =
          await http.get(Uri.parse(apiLatestSubjectsnUrl));

      if (responseStuSubjects.statusCode == 200) {
        final decodedBody = utf8.decode(responseStuSubjects.bodyBytes);
        List<dynamic> responseStuSubjectsJson = json.decode(decodedBody);
        setState(() {
          stuSubjectsList = responseStuSubjectsJson;
          selectedSubject = null;
          subjectLevel = null;
          courseType = null;
          selectedDuration = null;
          isRadioEnabled = false;
        });
      } else {
        throw Exception('Failed to load archived subjects of the student');
      }
    } catch (e) {
      _showErrorDialog('加载学生科目失败: ${e.toString()}');
    }
  }

  // 从后端取出上课时长初期化上课时长下拉列表框
  Future<void> fetchDurations() async {
    try {
      final String apiLsnDruationUrl =
          '${KnConfig.apiBaseUrl}${Constants.apiLsnDruationUrl}';
      final response = await http.get(Uri.parse(apiLsnDruationUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> durationJson = json.decode(decodedBody);
        setState(() {
          durationList = durationJson
              .map((durationString) =>
                  DurationBean.fromString(durationString as String))
              .toList();
        });
      } else {
        throw Exception('Failed to load duration');
      }
    } catch (e) {
      _showErrorDialog('加载上课时长失败: ${e.toString()}');
    }
  }

  void _updateSubjectInfo(dynamic selectedSubjectInfo) {
    setState(() {
      subjectLevel = selectedSubjectInfo['subjectSubName'];
      if (selectedSubjectInfo['payStyle'] == 0) {
        courseType = '课结算';
        isRadioEnabled = false;
        lessonType = 0;
      } else {
        courseType = '月计划';
        isRadioEnabled = true;
        lessonType = 1;
      }
      selectedDuration = selectedSubjectInfo['minutesPerLsn'];
    });
  }

  bool _validateForm() {
    if (selectedStudent == null) {
      _showErrorDialog('请选择学生姓名');
      return false;
    }
    if (selectedSubject == null) {
      _showErrorDialog('请选择科目名称');
      return false;
    }
    if (selectedDuration == null) {
      _showErrorDialog('请选择上课时长');
      return false;
    }
    return true;
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
    String title;
    if (message.contains('请选择') ||
        message.contains('必须') ||
        message.contains('输入')) {
      title = KnMsg.i.titleInputError;
    } else if (message.contains('排课操作被禁止') || message.contains('以后执行排课')) {
      title = KnMsg.i.titleSchedulingBanned;
    } else if (message.contains('网络') || message.contains('连接')) {
      title = KnMsg.i.titleError;
    } else {
      title = KnMsg.i.titleOperationError;
    }
    KnDialog.showInfo(context, Constants.lessonThemeColor, Colors.white, title, message);
  }

  void _showBusinessErrorDialog(String message) {
    KnDialog.showInfo(context, Constants.lessonThemeColor, Colors.white,
        KnMsg.i.titleSchedulingBanned, message);
  }

  // [集体课条件判断] 2026-02-26 新増
  // 集体课条件不匹配时的禁止对话框（不可强制跳过）
  // [集体课条件判断] 2026-02-27 新增existingValue/newValue，显示差异对比
  Future<void> _showGroupClassConditionErrorDialog(
    String message, {
    String existingValue = '',
    String newValue = '',
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('排课禁止'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (existingValue.isNotEmpty || newValue.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 72,
                            child: Text('既存课程：', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ),
                          Text(existingValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const SizedBox(
                            width: 72,
                            child: Text('新排课者：', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ),
                          Text(newValue, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
        );
      },
    );
  }

// [课程排他状态功能] 2026-02-08 集成冲突检测的两阶段提交

  Future<void> _saveCourse({bool forceOverlap = false}) async {
    if (!_validateForm()) return;

    final selectedStudentDoc =
        stuDocList.firstWhere((student) => student.stuName == selectedStudent);
    final selectedSubjectInfo = stuSubjectsList
        .firstWhere((subject) => subject['subjectName'] == selectedSubject);

    final Map<String, dynamic> courseData = {
      'stuId': selectedStudentDoc.stuId,
      'subjectId': selectedSubjectInfo['subjectId'],
      'subjectSubId': selectedSubjectInfo['subjectSubId'],
      // [集体课条件判断] 2026-02-27 新增：供Java端构建差异对比信息
      'subjectName': selectedSubjectInfo['subjectName'],
      'subjectSubName': selectedSubjectInfo['subjectSubName'],
      'lessonType': lessonType,
      'classDuration': selectedDuration,
      'schedualDate': '${widget.scheduleDate} ${widget.scheduleTime}',
      'forceOverlap': forceOverlap, // [课程排他状态功能] 强制保存标记
      // [集体课条件判断] 2026-02-26 新增
      'isGroupLessonScheduling': widget.isGroupLessonScheduling,
    };

    final dismiss = KnDialog.showLoading(context, Constants.lessonThemeColor,
        Colors.white, KnMsg.i.loadingCourseAdd);
    try {
      final String apiLsnSaveUrl =
          '${KnConfig.apiBaseUrl}${Constants.apiLsnSave}';
      final response = await http.post(
        Uri.parse(apiLsnSaveUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(courseData),
      );

      dismiss();

      // [课程排他状态功能] 处理响应（200 和 409 都可能包含冲突信息）
      if (response.statusCode == 200 || response.statusCode == 409) {
        final decodedBody = utf8.decode(response.bodyBytes);

        // 尝试解析JSON响应
        dynamic responseData;
        try {
          responseData = json.decode(decodedBody);
        } catch (e) {
          // 如果不是有效JSON，检查是否是旧版本返回的纯文本"success"
          if (decodedBody.toLowerCase().contains('success')) {
            Navigator.of(context).pop(true);
            return;
          } else {
            _showErrorDialog('保存失败: $decodedBody');
            return;
          }
        }

        if (responseData is Map<String, dynamic>) {
          final result = ConflictCheckResult.fromJson(responseData);

          if (result.success) {
            // 保存成功
            Navigator.of(context).pop(true);
          } else if (result.isGroupClassConditionError) {
            // [集体课条件判断] 2026-02-26 新増
            // 集体课条件不匹配（科目/子科目/课时不同），严格禁止，不可强制跳过
            await _showGroupClassConditionErrorDialog(
              result.message,
              existingValue: result.existingValue,
              newValue: result.newValue,
            );
            // 用户点确定后，关闭排课对话框，返回课程表页面
            Navigator.of(context).pop(false);
          } else if (result.hasConflict) {
            // 检测到冲突
            // [2026-02-12] 构建新排课时间信息，用于时间轴可视化
            final newSchedule = NewScheduleInfo(
              startTime: widget.scheduleTime,
              endTime: _calculateEndTime(widget.scheduleTime, selectedDuration ?? 45),
              stuName: selectedStudent,
            );

            if (result.isSameStudentConflict) {
              // 同一学生自我冲突，严格禁止
              await ConflictWarningDialog.showSameStudentConflict(
                context,
                result.conflicts,
                newSchedule: newSchedule,
              );
              // 用户确认后，关闭排课对话框，返回课程表页面
              Navigator.of(context).pop(false);
            } else {
              // 不同学生冲突，显示警告让用户确认
              final confirmed = await ConflictWarningDialog.show(
                context,
                result.conflicts,
                newSchedule: newSchedule,
              );

              if (confirmed) {
                // 用户确认继续，强制保存
                await _saveCourse(forceOverlap: true);
              } else {
                // 用户取消，关闭排课对话框，返回课程表页面
                Navigator.of(context).pop(false);
              }
            }
          } else {
            // 其他错误
            _showErrorDialog(result.message);
          }
        } else {
          // 兼容旧版本响应（直接返回成功）
          Navigator.of(context).pop(true);
        }
      } else {
        // 其他HTTP错误状态码（如500等）
        final errorMessage = utf8.decode(response.bodyBytes);
        // 尝试解析JSON错误响应
        try {
          final errorJson = json.decode(errorMessage);
          if (errorJson is Map<String, dynamic> && errorJson['message'] != null) {
            final message = errorJson['message'] as String;
            if (message.contains('排课操作被禁止')) {
              _showBusinessErrorDialog(message);
            } else {
              _showErrorDialog(message);
            }
          } else {
            _showErrorDialog(errorMessage);
          }
        } catch (e) {
          // JSON解析失败，直接显示原始错误信息
          if (errorMessage.contains('排课操作被禁止')) {
            _showBusinessErrorDialog(errorMessage);
          } else {
            _showErrorDialog(errorMessage);
          }
        }
      }
    } catch (e) {
      dismiss();
      _showErrorDialog('保存失败: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏（绿色背景）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: primaryColor,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '添加课程:${widget.scheduleDate} ${widget.scheduleTime}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            // 内容区
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdown(
                      label: '学生姓名',
                      value: selectedStudent,
                      items: stuDocList
                          .map((student) => DropdownMenuItem(
                                value: student.stuName,
                                child: Text(student.stuName),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStudent = value as String?;
                          selectedSubject = null;
                          subjectLevel = null;
                          courseType = null;
                          isRadioEnabled = false;
                        });
                        if (value != null) {
                          final selectedStudentDoc = stuDocList
                              .firstWhere((student) => student.stuName == value);
                          _fetchStudentSubjects(selectedStudentDoc.stuId);
                        }
                      },
                    ),
                    _buildDropdown(
                      label: '科目名称',
                      value: selectedSubject,
                      items: stuSubjectsList
                          .map((subject) => DropdownMenuItem(
                                value: subject['subjectName'] as String,
                                child: Text(subject['subjectName'] as String),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedSubject = value as String?);
                        if (value != null) {
                          final selectedSubjectInfo = stuSubjectsList.firstWhere(
                            (subject) => subject['subjectName'] == value,
                            orElse: () => null,
                          );
                          if (selectedSubjectInfo != null) {
                            _updateSubjectInfo(selectedSubjectInfo);
                          }
                        }
                      },
                    ),
                    _buildTextField(
                      label: '科目级别名称',
                      controller: TextEditingController(text: subjectLevel),
                      readOnly: true,
                    ),
                    Text('上课种别',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['课结算', '月计划', '月加课'].map((type) {
                        return _buildRadioButton(type, primaryColor);
                      }).toList(),
                    ),
                    _buildDropdown(
                      label: '上课时长',
                      value: selectedDuration,
                      items: durationList
                          .map((DurationBean durationBean) => DropdownMenuItem(
                                value: durationBean.minutesPerLsn,
                                child: Text('${durationBean.minutesPerLsn} 分钟'),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedDuration = value as int?),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _saveCourse,
                            child: const Text('保存', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required Function(dynamic) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              icon: Icon(Icons.arrow_drop_down, color: Colors.green.shade700),
              dropdownColor: Colors.green.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.green.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.green.shade600),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRadioButton(String type, Color primaryColor) {
    return InkWell(
      onTap: () {
        if ((isRadioEnabled && type != '课结算') ||
            (courseType == '课结算' && type == '课结算')) {
          setState(() {
            courseType = type;
            if (type == '课结算') {
              lessonType = 0;
            } else if (type == '月计划') {
              lessonType = 1;
            } else if (type == '月加课') {
              lessonType = 2;
            }
          });
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: type,
            groupValue: courseType,
            onChanged: (isRadioEnabled && type != '课结算') ||
                    (courseType == '课结算' && type == '课结算')
                ? (String? value) {
                    setState(() {
                      courseType = value!;
                      if (type == '课结算') {
                        lessonType = 0;
                      } else if (type == '月计划') {
                        lessonType = 1;
                      } else if (type == '月加课') {
                        lessonType = 2;
                      }
                    });
                  }
                : null,
            activeColor: primaryColor,
          ),
          Text(type, style: TextStyle(color: Colors.green.shade700)),
        ],
      ),
    );
  }
}
