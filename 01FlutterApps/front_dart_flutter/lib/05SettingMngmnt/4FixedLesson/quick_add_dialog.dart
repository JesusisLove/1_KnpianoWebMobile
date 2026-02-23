// [固定排课新潮界面] 2026-02-12 快速新增对话框

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../ApiConfig/KnApiConfig.dart';
import '../../Constants.dart';

/// 快速新增对话框
class QuickAddDialog extends StatefulWidget {
  final String weekDay; // Mon, Tue, ...
  final int hour; // 8-20
  final int minute; // 0, 15, 30, 45
  final Color themeColor;

  const QuickAddDialog({
    super.key,
    required this.weekDay,
    required this.hour,
    required this.minute,
    required this.themeColor,
  });

  /// 显示快速新增对话框
  /// 返回 true 表示新增成功，需要刷新数据
  static Future<bool> show({
    required BuildContext context,
    required String weekDay,
    required int hour,
    required int minute,
    required Color themeColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuickAddDialog(
        weekDay: weekDay,
        hour: hour,
        minute: minute,
        themeColor: themeColor,
      ),
    );
    return result ?? false;
  }

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedStuId;
  String? _selectedSubId;
  bool _isLoading = true;
  bool _isSaving = false;

  // 学生和科目数据
  Map<String, String> _stuNameList = {};
  Map<String, List<Map<String, String>>> _subjectsByStudent = {};

  @override
  void initState() {
    super.initState();
    _fetchStudentsAndSubjects();
  }

  /// 获取学生和科目列表
  Future<void> _fetchStudentsAndSubjects() async {
    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.fixeDocStuSubInfoGet}';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> rawData = json.decode(utf8.decode(response.bodyBytes));
        Map<String, String> stuNames = {};
        Map<String, List<Map<String, String>>> subjects = {};

        for (var data in rawData) {
          String stuId = data['stuId'];
          String stuName = data['stuName'].toString().trim();
          String subjectId = data['subjectId'];
          String subjectName = data['subjectName'].toString().trim();

          stuNames[stuId] = stuName;
          subjects.putIfAbsent(stuId, () => []);
          subjects[stuId]!.add({
            'subjectId': subjectId,
            'subjectName': subjectName,
          });
        }

        if (mounted) {
          setState(() {
            _stuNameList = stuNames;
            _subjectsByStudent = subjects;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 保存新增排课
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.fixedLsnInfoAdd}';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'stuId': _selectedStuId,
          'subjectId': _selectedSubId,
          'fixedWeek': widget.weekDay,
          'fixedHour': widget.hour.toString().padLeft(2, '0'),
          'fixedMinute': widget.minute.toString().padLeft(2, '0'),
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          Navigator.of(context).pop(true); // 返回成功
        } else {
          _showError('保存失败');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('网络错误: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${widget.hour.toString().padLeft(2, '0')}:${widget.minute.toString().padLeft(2, '0')}';
    final weekDayName = _getWeekDayName(widget.weekDay);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.add_circle, color: widget.themeColor),
          const SizedBox(width: 8),
          const Text('新增固定排课'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间显示（只读）
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            color: widget.themeColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$weekDayName $timeStr',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 学生选择
                  DropdownButtonFormField<String>(
                    value: _selectedStuId,
                    decoration: const InputDecoration(
                      labelText: '选择学生',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    items: _stuNameList.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStuId = value;
                        _selectedSubId = null; // 重置科目选择
                      });
                    },
                    validator: (value) => value == null ? '请选择学生' : null,
                  ),
                  const SizedBox(height: 16),
                  // 科目选择
                  DropdownButtonFormField<String>(
                    value: _selectedSubId,
                    decoration: const InputDecoration(
                      labelText: '选择科目',
                      prefixIcon: Icon(Icons.music_note),
                      border: OutlineInputBorder(),
                    ),
                    items: _selectedStuId != null
                        ? _subjectsByStudent[_selectedStuId]?.map((subject) {
                            return DropdownMenuItem<String>(
                              value: subject['subjectId'],
                              child: Text(subject['subjectName']!),
                            );
                          }).toList()
                        : [],
                    onChanged: (value) {
                      setState(() => _selectedSubId = value);
                    },
                    validator: (value) => value == null ? '请选择科目' : null,
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.themeColor,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('确定'),
        ),
      ],
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
