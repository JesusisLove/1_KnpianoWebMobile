// ignore_for_file: use_build_context_synchronously, use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart'; // 导入自定义加载指示器
import '../../Constants.dart';
import 'DurationBean.dart';

// ignore: must_be_immutable
class StudentDocumentEditPage extends StatefulWidget {
  final String stuId;
  final String subjectId;
  final String subjectSubId;
  final String adjustedDate;
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;

  StudentDocumentEditPage({
    Key? key,
    required this.stuId,
    required this.subjectId,
    required this.subjectSubId,
    required this.adjustedDate,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  }) : super(key: key);

  @override
  _StudentDocumentEditPageState createState() =>
      _StudentDocumentEditPageState();
}

class _StudentDocumentEditPageState extends State<StudentDocumentEditPage> {
  final String titleName = "学生档案编辑";
  bool _isLoading = false; // 添加加载状态变量
  bool _isDataLoaded = false; // 数据是否已加载完成

  String stuName = '';
  String subjectName = '';
  String subjectSubName = '';
  List<DurationBean> duration = []; // 初始化为空列表
  int? payStyle;
  int? selectedDuration;
  double standardPrice = 0.0;
  TextEditingController adjustedPriceController = TextEditingController();

  // 年度计划总课时相关变量
  TextEditingController yearLsnCntController = TextEditingController();
  bool _isYearLsnCntReadonly = true; // 年度计划总课时的只读状态

  // 新增：月付费相关的控制器
  TextEditingController standardPriceMonthController = TextEditingController();
  TextEditingController adjustedPriceMonthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedDuration = null; // 确保初始化为 null
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true; // 开始加载前设置为true
    });

    try {
      await fetchStudentInfo();
      await fetchDurations();
      setState(() {
        _isDataLoaded = true; // 数据加载完成
      });
    } catch (e) {
      print('Error fetching initial data: $e');
      // 显示错误对话框
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('加载错误'),
              content: Text('加载数据时发生错误: $e'),
              actions: <Widget>[
                TextButton(
                  child: const Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // 返回上一页
                  },
                ),
              ],
            );
          },
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // 加载完成后设置为false
      });
    }
  }

  Future<void> fetchStudentInfo() async {
    final String apiStuDocUrl =
        '${KnConfig.apiBaseUrl}${Constants.stuDocInfoEdit}/${widget.stuId}/${widget.subjectId}/${widget.subjectSubId}/${widget.adjustedDate}';
    final response = await http.get(Uri.parse(apiStuDocUrl));

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      Map<String, dynamic> studentInfo = json.decode(decodedBody);
      setState(() {
        stuName = studentInfo['stuName'] ?? '';
        subjectName = studentInfo['subjectName'] ?? '';
        subjectSubName = studentInfo['subjectSubName'] ?? '';
        selectedDuration = studentInfo['minutesPerLsn'] ?? 0;
        standardPrice = studentInfo['lessonFee'] ?? 0.0;
        adjustedPriceController.text =
            (studentInfo['lessonFeeAdjusted'] ?? 0.0).toStringAsFixed(2);
        payStyle = studentInfo['payStyle'];

        // 设置年度计划总课时的值
        yearLsnCntController.text =
            (studentInfo['yearLsnCnt'] ?? '').toString();
        if (yearLsnCntController.text == '0' ||
            yearLsnCntController.text == 'null') {
          yearLsnCntController.text = '';
        }

        // 新增：初始化月付费相关数据
        _initializeMonthlyFields();
      });
    } else {
      throw Exception('Failed to load student info');
    }
  }

  // 新增：初始化月付费相关字段
  void _initializeMonthlyFields() {
    if (payStyle == 1) {
      // 标准价格（月）= 标准价格 × 4
      double monthlyStandardPrice = standardPrice * 4;
      standardPriceMonthController.text =
          monthlyStandardPrice.toStringAsFixed(2);

      // 调整价格（月）= 调整价格 × 4（如果调整价格不为空）
      double adjustedPrice =
          double.tryParse(adjustedPriceController.text) ?? 0.0;
      if (adjustedPrice > 0) {
        double monthlyAdjustedPrice = adjustedPrice * 4;
        adjustedPriceMonthController.text =
            monthlyAdjustedPrice.toStringAsFixed(2);
      }
    }
  }

  Future<void> fetchDurations() async {
    final String apiLsnDurationUrl =
        '${KnConfig.apiBaseUrl}${Constants.stuDocLsnDuration}';
    final responseDuration = await http.get(Uri.parse(apiLsnDurationUrl));

    if (responseDuration.statusCode == 200) {
      final decodedBody = utf8.decode(responseDuration.bodyBytes);
      List<dynamic> durationJson = json.decode(decodedBody);
      setState(() {
        duration = durationJson
            .map((durationString) =>
                DurationBean.fromString(durationString as String))
            .toList();
      });
    } else {
      throw Exception('Failed to load duration');
    }
  }

  // 切换年度计划总课时的只读状态
  void _toggleYearLsnCntReadonly() {
    setState(() {
      _isYearLsnCntReadonly = !_isYearLsnCntReadonly;
    });
  }

  // 判断是否应该显示年度计划总课时
  bool _shouldShowYearLsnCnt() {
    return payStyle == 1; // 按月付费时显示
  }

  // 新增：判断是否应该显示月付费相关字段
  bool _shouldShowMonthlyFields() {
    return payStyle == 1; // 按月付费时显示
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
              initialValue: standardPrice.toStringAsFixed(2),
              readOnly: true,
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
        initialValue: standardPrice.toStringAsFixed(2),
        readOnly: true,
        decoration: const InputDecoration(
          labelText: '标准价格',
          border: OutlineInputBorder(),
        ),
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
              enabled: !_isLoading,
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
              enabled: !_isLoading,
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
        enabled: !_isLoading, // 如果正在加载，禁用交互
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
            widget.knFontColor.alpha, // 自定义AppBar背景颜色
            widget.knFontColor.red - 20,
            widget.knFontColor.green - 20,
            widget.knFontColor.blue - 20),
        // [Flutter页面主题改造] 2026-01-26 副标题背景使用主题色的深色版本
        subtitleBackgroundColor: Color.fromARGB(
            widget.knBgColor.alpha,
            (widget.knBgColor.red * 0.6).round(),
            (widget.knBgColor.green * 0.6).round(),
            (widget.knBgColor.blue * 0.6).round()),
        subtitleTextColor: Colors.white, // 自定义底部文本颜色
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
        addInvisibleRightButton: false, // 显示Home按钮返回主菜单
        currentNavIndex: 2,
      ),
      body: Stack(
        children: [
          // 主要内容
          _isDataLoaded
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: stuName,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: '学生姓名',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: subjectName,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: '科目名称',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: subjectSubName,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: '科目级别名称',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: widget.adjustedDate,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: '调整日期',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 科目支付方式 - 在变更模式下禁用交互但保持提交值
                      const Text('科目支付方式'),
                      Container(
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: IgnorePointer(
                                // 禁用交互但保持视觉状态
                                child: RadioListTile<int>(
                                  title: Text('按月付费',
                                      style: TextStyle(
                                          color: Colors.grey[600])), // 灰色文字
                                  value: 1,
                                  groupValue: payStyle,
                                  onChanged: null, // 禁用交互
                                ),
                              ),
                            ),
                            Expanded(
                              child: IgnorePointer(
                                // 禁用交互但保持视觉状态
                                child: RadioListTile<int>(
                                  title: Text('课时付费',
                                      style: TextStyle(
                                          color: Colors.grey[600])), // 灰色文字
                                  value: 0,
                                  groupValue: payStyle,
                                  onChanged: null, // 禁用交互
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 年度计划总课时 - 新增字段
                      if (_shouldShowYearLsnCnt()) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: yearLsnCntController,
                                readOnly: _isYearLsnCntReadonly,
                                decoration: InputDecoration(
                                  labelText: '年度计划总课时',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isYearLsnCntReadonly
                                          ? Icons.lock
                                          : Icons.lock_open,
                                      color: _isYearLsnCntReadonly
                                          ? Colors.grey
                                          : widget.knBgColor,
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _toggleYearLsnCntReadonly,
                                    tooltip:
                                        _isYearLsnCntReadonly ? '开启编辑' : '关闭编辑',
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: _isYearLsnCntReadonly
                                      ? Colors.grey[600]
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: '课程时长',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedDuration,
                        items: duration.map((DurationBean durationBean) {
                          return DropdownMenuItem<int>(
                            value: durationBean.minutesPerLsn,
                            child: Text('${durationBean.minutesPerLsn} 分钟'),
                          );
                        }).toList(),
                        onChanged: _isLoading
                            ? null // 如果正在加载，禁用交互
                            : (int? newValue) {
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
                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _isLoading ? null : saveData, // 如果正在加载，禁用按钮
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                )
              : Container(), // 如果数据未加载完成，显示空容器

          // 加载指示器层
          if (_isLoading)
            Center(
              child:
                  KnLoadingIndicator(color: widget.knBgColor), // 使用自定义的加载器进度条
            ),
        ],
      ),
    );
  }

  Future<void> saveData() async {
    if (selectedDuration == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('输入错误'),
            content: const Text('请选择课程时长'),
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

    double? adjustedPriceValue = double.tryParse(adjustedPriceController.text);

    if (adjustedPriceValue == null || adjustedPriceValue < 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('输入错误'),
            content: const Text('请输入有效的调整价格'),
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

    Map<String, dynamic> data = {
      'stuId': widget.stuId,
      'subjectId': widget.subjectId,
      'subjectSubId': widget.subjectSubId,
      'adjustedDate': widget.adjustedDate,
      'payStyle': payStyle,
      'lessonFee': standardPrice,
      'lessonFeeAdjusted': adjustedPriceValue,
      'minutesPerLsn': selectedDuration,
      'yearLsnCnt': yearLsnCntValue, // 年度计划总课时
    };

    try {
      // 设置加载状态
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('${KnConfig.apiBaseUrl}${Constants.stuDocInfoSave}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      // 重置加载状态
      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        showDialog(
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
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('错误'),
              content: Text('保存失败: ${response.body}'),
              actions: <Widget>[
                TextButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // 重置加载状态
      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('错误'),
            content: Text('发生错误: $e'),
            actions: <Widget>[
              TextButton(
                child: const Text('确定'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
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
