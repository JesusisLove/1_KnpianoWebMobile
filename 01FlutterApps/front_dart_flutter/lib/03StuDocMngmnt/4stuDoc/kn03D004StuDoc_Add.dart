// ignore: file_names
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../Constants.dart';
import '../2subjectBasic/Kn05S003SubjectEdabnBean.dart';
import '../2subjectBasic/KnSub001Bean.dart';
import 'DurationBean.dart';

// ignore: must_be_immutable
class StudentDocumentPage extends StatefulWidget {
  final String? stuId;
  final String? stuName;
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  StudentDocumentPage({
    super.key,
    required this.stuId,
    required this.stuName,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  @override
  // ignore: library_private_types_in_public_api
  _StudentDocumentPageState createState() => _StudentDocumentPageState();
}

class _StudentDocumentPageState extends State<StudentDocumentPage> {
  final String titleName = "学生档案新增";
  List<KnSub001Bean> subjects = [];
  List<Kn05S003SubjectEdabnBean> subjectSubs = [];
  List<DurationBean>? duration = [];
  KnSub001Bean? selectedSubject;
  Kn05S003SubjectEdabnBean? selectedSubjectSub;
  DateTime? adjustmentDate = DateTime.now();
  bool isMonthlyPayment = true;
  int? payStyle = 1;
  int? selectedDuration;
  double standardPrice = 0.0;
  TextEditingController adjustedPriceController = TextEditingController();

  // 新增：年度计划总课时
  TextEditingController yearLsnCntController = TextEditingController();

  // 新增：月付费相关的控制器
  TextEditingController standardPriceMonthController = TextEditingController();
  TextEditingController adjustedPriceMonthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 获取当前日期并设置为当月1号
    final now = DateTime.now();
    adjustmentDate = DateTime(now.year, now.month, 1);
    fetchSubjects();
    fetchDurations();
  }

  // 获取科目信息，初始化下拉列表框
  Future<void> fetchSubjects() async {
    final String apiStuDocUrl =
        '${KnConfig.apiBaseUrl}${Constants.subjectView}';
    final responseSubject = await http.get(Uri.parse(apiStuDocUrl));

    if (responseSubject.statusCode == 200) {
      final decodedBody = utf8.decode(responseSubject.bodyBytes);
      List<dynamic> subjectJson = json.decode(decodedBody);
      setState(() {
        subjects =
            subjectJson.map((json) => KnSub001Bean.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load subjects');
    }
  }

  // 获取科目下的科目级别信息，初始化下拉列表框
  Future<void> fetchSubjectSubs(String subjectId) async {
    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.subjectEdaView}/$subjectId';
    final responseSubject = await http.get(Uri.parse(apiUrl));

    if (responseSubject.statusCode == 200) {
      final decodedBody = utf8.decode(responseSubject.bodyBytes);
      final List<dynamic> subjectSubsJson = json.decode(decodedBody);

      setState(() {
        subjectSubs = subjectSubsJson
            .map((json) => Kn05S003SubjectEdabnBean.fromJson(json))
            .toList();
        selectedSubjectSub = null;
      });
    } else {
      throw Exception('Failed to load subject subs');
    }
  }

  // 取得学生上1节课的分钟时长，初始化下拉列表框
  Future<void> fetchDurations() async {
    final String apiLsnDruationUrl =
        '${KnConfig.apiBaseUrl}${Constants.stuDocLsnDuration}';
    final responseDuration = await http.get(Uri.parse(apiLsnDruationUrl));

    if (responseDuration.statusCode == 200) {
      final decodedBody = utf8.decode(responseDuration.bodyBytes);
      List<dynamic> durationJson = json.decode(decodedBody);
      setState(() {
        /* 后端Java层的duration的数据类型时List<Stirng>,而此处的前端的duration的数据类型时List<DurationBean>,
           为了保持前端与后端实体Bean对象的一致性做了特殊处理
        */
        duration = durationJson
            .map((durationString) =>
                DurationBean.fromString(durationString as String))
            .toList();
      });
    } else {
      throw Exception('Failed to load duration');
    }
  }

  // 新增：判断是否应该显示年度计划总课时
  bool _shouldShowYearLsnCnt() {
    return payStyle == 1; // 按月付费时显示
  }

  // 新增：判断是否应该显示月付费相关字段
  bool _shouldShowMonthlyFields() {
    return payStyle == 1; // 按月付费时显示
  }

  // 新增：更新标准价格（月）
  void _updateStandardPriceMonth() {
    if (payStyle == 1) {
      double monthlyPrice = standardPrice * 4;
      standardPriceMonthController.text = monthlyPrice.toStringAsFixed(2);
    }
  }

  // 新增：处理调整价格（月）的变化
  void _onAdjustedPriceMonthChanged(String value) {
    if (value.isNotEmpty) {
      double? monthlyPrice = double.tryParse(value);
      if (monthlyPrice != null) {
        double lessonPrice = monthlyPrice / 4;
        adjustedPriceController.text = lessonPrice.toStringAsFixed(2);
      }
    } else {
      adjustedPriceController.clear();
    }
  }

  // 新增：处理调整价格的变化
  void _onAdjustedPriceChanged(String value) {
    if (payStyle == 1) {
      if (value.isNotEmpty) {
        double? lessonPrice = double.tryParse(value);
        if (lessonPrice != null) {
          double monthlyPrice = lessonPrice * 4;
          adjustedPriceMonthController.text = monthlyPrice.toStringAsFixed(2);
        }
      } else {
        adjustedPriceMonthController.clear();
      }
    }
  }

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<KnSub001Bean>(
      decoration: const InputDecoration(
        labelText: '科目名称',
        border: OutlineInputBorder(),
      ),
      value: selectedSubject,
      items: subjects.map((KnSub001Bean subject) {
        return DropdownMenuItem<KnSub001Bean>(
          value: subject,
          child: Text(subject.subjectName),
        );
      }).toList(),
      onChanged: (KnSub001Bean? newValue) {
        setState(() {
          selectedSubject = newValue;
          if (newValue != null) {
            fetchSubjectSubs(newValue.subjectId);
          }
        });
      },
    );
  }

  Widget _buildSubjectSubDropdown() {
    return DropdownButtonFormField<Kn05S003SubjectEdabnBean>(
      decoration: const InputDecoration(
        labelText: '科目级别名称',
        border: OutlineInputBorder(),
      ),
      value: selectedSubjectSub,
      items: subjectSubs.map((Kn05S003SubjectEdabnBean subjectSub) {
        return DropdownMenuItem<Kn05S003SubjectEdabnBean>(
          value: subjectSub,
          child: Text(subjectSub.subjectSubName),
        );
      }).toList(),
      onChanged: (Kn05S003SubjectEdabnBean? newValue) {
        setState(() {
          selectedSubjectSub = newValue;
          standardPrice = newValue?.subjectPrice ?? 0.0;
          // 更新标准价格（月）
          _updateStandardPriceMonth();
        });
      },
    );
  }

  // 新增：构建标准价格行（包含标准价格（月）和标准价格）
  Widget _buildStandardPriceRow() {
    if (_shouldShowMonthlyFields()) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              readOnly: true,
              controller: standardPriceMonthController,
              decoration: const InputDecoration(
                labelText: '标准价格（月）',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              readOnly: true,
              controller:
                  TextEditingController(text: standardPrice.toStringAsFixed(2)),
              decoration: const InputDecoration(
                labelText: '标准价格',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              minLines: 1,
            ),
          ),
        ],
      );
    } else {
      return TextFormField(
        readOnly: true,
        controller:
            TextEditingController(text: standardPrice.toStringAsFixed(2)),
        decoration: const InputDecoration(
          labelText: '标准价格',
          border: OutlineInputBorder(),
        ),
        maxLines: 1,
        minLines: 1,
      );
    }
  }

  // 新增：构建调整价格行（包含调整价格（月）和调整价格）
  Widget _buildAdjustedPriceRow() {
    if (_shouldShowMonthlyFields()) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: adjustedPriceMonthController,
              decoration: const InputDecoration(
                labelText: '调整价格（月）',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLines: 1,
              minLines: 1,
              onChanged: _onAdjustedPriceMonthChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: adjustedPriceController,
              decoration: const InputDecoration(
                labelText: '调整价格',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLines: 1,
              minLines: 1,
              onChanged: _onAdjustedPriceChanged,
            ),
          ),
        ],
      );
    } else {
      return TextFormField(
        controller: adjustedPriceController,
        decoration: const InputDecoration(
          labelText: '调整价格',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        maxLines: 1,
        minLines: 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
        title: titleName,
        subtitle: "${widget.pagePath} >> $titleName",
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
        currentNavIndex: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: widget.stuName,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '学生姓名',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              minLines: 1,
            ),
            const SizedBox(height: 8),
            _buildSubjectDropdown(),
            const SizedBox(height: 8),
            _buildSubjectSubDropdown(),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(
                  text: adjustmentDate.toString().split(' ')[0]),
              decoration: const InputDecoration(
                labelText: '调整日付',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              maxLines: 1,
              minLines: 1,
              onTap: () async {
                // 获取当前选择的日期，如果没有则使用当前日期
                DateTime currentDate = adjustmentDate ?? DateTime.now();
                // 确保初始日期总是月初1号
                DateTime initialDate =
                    DateTime(currentDate.year, currentDate.month, 1);

                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(2025, 1, 1),
                  lastDate: DateTime(2025, 12, 31),
                  selectableDayPredicate: (DateTime date) {
                    // 只允许选择每月1号
                    return date.day == 1;
                  },
                  initialEntryMode:
                      DatePickerEntryMode.calendarOnly, // 直接显示日历视图
                  helpText: '选择月份', // 修改标题文字为中文
                );
                if (picked != null) {
                  setState(() {
                    adjustmentDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            const Text('科目支付区分'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text('按月付费'),
                    value: 1,
                    groupValue: payStyle,
                    onChanged: (int? value) {
                      setState(() {
                        payStyle = value;
                        isMonthlyPayment = (value == 1);
                        // 当切换到按月付费时，更新标准价格（月）
                        if (value == 1) {
                          _updateStandardPriceMonth();
                        } else {
                          // 当切换到课时付费时，清空月付费相关字段
                          standardPriceMonthController.clear();
                          adjustedPriceMonthController.clear();
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text('课时付费'),
                    value: 0,
                    groupValue: payStyle,
                    onChanged: (int? value) {
                      setState(() {
                        payStyle = value;
                        isMonthlyPayment = (value == 1);
                        // 当切换到课时付费时，清空月付费相关字段
                        if (value == 0) {
                          standardPriceMonthController.clear();
                          adjustedPriceMonthController.clear();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 年度计划总课时 - 只在按月付费时显示
            if (_shouldShowYearLsnCnt()) ...[
              TextFormField(
                controller: yearLsnCntController,
                decoration: const InputDecoration(
                  labelText: '年度计划总课时',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLines: 1,
                minLines: 1,
              ),
              const SizedBox(height: 8),
            ],

            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: '课程时长',
                border: OutlineInputBorder(),
              ),
              value: selectedDuration,
              items: duration?.map((DurationBean durationBean) {
                return DropdownMenuItem<int>(
                  value: durationBean.minutesPerLsn,
                  child: Text('${durationBean.minutesPerLsn} 分钟'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedDuration = newValue;
                });
              },
            ),
            const SizedBox(height: 8),

            // 使用新的标准价格行构建方法
            _buildStandardPriceRow(),
            const SizedBox(height: 8),

            // 使用新的调整价格行构建方法
            _buildAdjustedPriceRow(),
            const SizedBox(height: 8),

            ElevatedButton(
              child: const Text('保存'),
              onPressed: () {
                List<String> missingFields = [];

                if (selectedSubject == null) {
                  missingFields.add('科目名称');
                }
                if (selectedSubjectSub == null) {
                  missingFields.add('科目级别名称');
                }
                if (adjustmentDate == null) {
                  missingFields.add('调整日期');
                }
                if (selectedDuration == null) {
                  missingFields.add('课程时长');
                }

                if (missingFields.isNotEmpty) {
                  // 显示错误消息，列出具体缺少的字段
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('输入错误'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('请填写以下必填项:'),
                            const SizedBox(height: 10),
                            ...missingFields
                                .map((field) => Text('• $field'))
                                .toList(),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('确定'),
                            onPressed: () => {
                              Navigator.of(context).pop(),
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // 所有必填项都已填写，继续保存操作
                  saveData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveData() async {
    // 解析年度计划总课时
    int? yearLsnCntValue;
    if (payStyle == 1 && yearLsnCntController.text.isNotEmpty) {
      // 按月付费且有值
      yearLsnCntValue = int.tryParse(yearLsnCntController.text);
      if (yearLsnCntValue == null || yearLsnCntValue < 0) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('输入错误'),
              content: const Text('请输入有效的年度计划总课时'),
              actions: <Widget>[
                TextButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    // 准备要发送的数据
    Map<String, dynamic> data = {
      'stuId': widget.stuId,
      'subjectId': selectedSubject?.subjectId,
      'subjectSubId': selectedSubjectSub?.subjectSubId,
      'adjustedDate':
          adjustmentDate?.toIso8601String().split('T')[0], // 格式化为 YYYY-MM-DD
      'payStyle': payStyle,
      'minutesPerLsn': selectedDuration,
      'lessonFee': standardPrice,
      'lessonFeeAdjusted': double.tryParse(adjustedPriceController.text) ?? 0.0,
      'yearLsnCnt': yearLsnCntValue, // 年度计划总课时
    };

    try {
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
                  Text('正在登记学生档案信息...'),
                ],
              ),
            ),
          );
        },
      );

      final response = await http.post(
        Uri.parse('${KnConfig.apiBaseUrl}${Constants.stuDocInfoSave}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response.statusCode == 200) {
        // 保存成功
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('成功'),
              content: const Text('学生档案已成功保存。'),
              actions: <Widget>[
                TextButton(
                  child: const Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 可以选择返回上一页或清空表单
                    Navigator.of(context).pop(true); // 关闭当前页面并返回成功标识
                    // 或者清空表单
                    resetForm();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // 保存失败
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('错误'),
              content: Text('保存失败: ${response.body}'),
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
    } catch (e) {
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      // 捕获网络错误等异常
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('错误'),
            content: Text('发生错误: $e'),
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

// 重置表单的辅助方法
  void resetForm() {
    setState(() {
      selectedSubject = null;
      selectedSubjectSub = null;
      subjectSubs.clear();
      adjustmentDate = DateTime.now();
      isMonthlyPayment = true;
      payStyle = 1; // 重置为按月付费
      selectedDuration = null;
      standardPrice = 0.0;
      adjustedPriceController.clear();
      yearLsnCntController.clear(); // 清空年度计划总课时
      // 新增：清空月付费相关字段
      standardPriceMonthController.clear();
      adjustedPriceMonthController.clear();
    });
  }

  @override
  void dispose() {
    adjustedPriceController.dispose();
    yearLsnCntController.dispose(); // 释放年度计划总课时控制器
    // 新增：释放月付费相关控制器
    standardPriceMonthController.dispose();
    adjustedPriceMonthController.dispose();
    super.dispose();
  }
}
