// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../ApiConfig/KnApiConfig.dart';
import '../CommonProcess/CommonMethod.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../CommonProcess/customUI/KnLoadingIndicator.dart';
import '../Constants.dart';
import 'Kn02F004AdvcLsnFeePayPerLsnBean.dart';

// ignore: must_be_immutable
class Kn02F004AdvcLsnFeePayPerLsnPage extends StatefulWidget {
  final String stuId;
  final String stuName;
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  final int selectedYear;

  Kn02F004AdvcLsnFeePayPerLsnPage({
    super.key,
    required this.stuId,
    required this.stuName,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
    required this.selectedYear,
  });

  @override
  _Kn02F004AdvcLsnFeePayPerLsnPageState createState() =>
      _Kn02F004AdvcLsnFeePayPerLsnPageState();
}

class _Kn02F004AdvcLsnFeePayPerLsnPageState
    extends State<Kn02F004AdvcLsnFeePayPerLsnPage> {
  late int selectedYear;
  int selectedMonth = DateTime.now().month;
  // 科目列表（该生所有按课时交费的科目）
  List<Kn02F004AdvcLsnFeePayPerLsnBean> subjectList = [];
  // 选中的科目
  Kn02F004AdvcLsnFeePayPerLsnBean? selectedSubject;
  // SP返回的排课预览Bean列表（服务器端遍历候选日期后返回的N条记录）
  List<Kn02F004AdvcLsnFeePayPerLsnBean> serverScheduleBeans = [];
  // 排课日期预览列表
  List<Map<String, dynamic>> schedulePreviewList = [];
  // 银行列表
  List<Map<String, dynamic>> bankList = [];
  late List<int> years;
  String? selectedBank;
  String titleName = "的按课时预支付";
  bool _isLoading = false;
  bool _hasSchedule = false;
  String? _subjectLoadError; // 科目列表加载失败时的错误信息

  // 双向联动：课时数和金额
  int lessonCount = 4;
  double amount = 0;
  final TextEditingController _lessonCountController =
      TextEditingController(text: '4');
  final TextEditingController _amountController = TextEditingController();
  String? amountError;

  List<int> months = List.generate(12, (index) => index + 1);
  static const double controlHeight = 40.0;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.selectedYear;
    years = Constants.generateYearList();
    setState(() {
      _isLoading = true;
    });
    Future.wait([fetchBankList(), fetchSubjectList()]).then((_) {
      setState(() {
        _isLoading = false;
      });
    }).catchError((e) {
      setState(() {
        _isLoading = false;
      });
      print('初期化加载错误: $e');
    });
  }

  @override
  void dispose() {
    _lessonCountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // 获取银行列表
  Future<void> fetchBankList() async {
    final String apiGetBnkUrl =
        '${KnConfig.apiBaseUrl}${Constants.stuBankList}/${widget.stuId}';
    final response = await http.get(Uri.parse(apiGetBnkUrl));
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = json.decode(decodedBody);
      setState(() {
        bankList = data
            .map((item) => {
                  'bankId': item['bankId'],
                  'bankName': item['bankName'],
                })
            .toList();
      });
    } else {
      print('Failed to load bank list');
    }
  }

  // 获取该生的按课时交费科目列表
  Future<void> fetchSubjectList() async {
    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiAdvcLsnFeePayPerLsnSubjects}/${widget.stuId}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(decodedBody);
        setState(() {
          subjectList = data
              .map((json) => Kn02F004AdvcLsnFeePayPerLsnBean.fromJson(json))
              .toList();
          _subjectLoadError = null;
        });
      } else {
        setState(() {
          _subjectLoadError = '科目列表加载失败(HTTP ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _subjectLoadError = '科目列表加载失败: $e';
      });
    }
  }

  // 获取按课时交费科目的排课日期推算信息（服务器端遍历候选日期，返回N条记录）
  Future<void> fetchScheduleInfo() async {
    if (selectedSubject == null) return;

    final String yearMonth =
        '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiAdvcLsnFeePayPerLsnInfo}/${widget.stuId}/$yearMonth'
        '?lessonCount=$lessonCount'
        '&subjectId=${selectedSubject!.subjectId}'
        '&subjectSubId=${selectedSubject!.subjectSubId}';
    final responseFeeDetails = await http.get(Uri.parse(apiUrl));
    if (responseFeeDetails.statusCode == 200) {
      final decodedBody = utf8.decode(responseFeeDetails.bodyBytes);
      List<dynamic> jsonList = json.decode(decodedBody);
      setState(() {
        serverScheduleBeans = jsonList
            .map((json) => Kn02F004AdvcLsnFeePayPerLsnBean.fromJson(json))
            .toList();
        // 直接使用服务器返回的N条记录构建预览列表
        if (serverScheduleBeans.isNotEmpty) {
          _hasSchedule = true;
          schedulePreviewList = [];
          for (var bean in serverScheduleBeans) {
            try {
              DateTime date =
                  DateFormat('yyyy-MM-dd HH:mm').parse(bean.schedualDate);
              schedulePreviewList.add({
                'no': bean.sequenceNo ?? (schedulePreviewList.length + 1),
                'subjectName': bean.subjectName,
                'subjectSubName': bean.subjectSubName,
                'subjectPrice': bean.subjectPrice,
                'schedualDate': bean.schedualDate,
                'isPast': date.isBefore(DateTime.now()),
                'processingMode': bean.processingMode ?? 'A',
                'existingLessonId': bean.existingLessonId,  // B/C模式需要
                'existingFeeId': bean.existingFeeId,        // C模式需要
              });
            } catch (e) {
              print('日期解析错误: ${bean.schedualDate}');
            }
          }
          if (schedulePreviewList.isEmpty) {
            _hasSchedule = false;
          }
        } else {
          _hasSchedule = false;
          schedulePreviewList = [];
        }
      });
    } else {
      throw Exception('Failed to load schedule info');
    }
  }

  // 科目选择变更
  void _onSubjectChanged(Kn02F004AdvcLsnFeePayPerLsnBean? subject) {
    setState(() {
      selectedSubject = subject;
      schedulePreviewList = [];
      _hasSchedule = false;
      if (subject != null) {
        // 更新金额联动
        _updateAmountFromLessonCount();
      } else {
        _amountController.text = '';
        amount = 0;
      }
    });
  }

  // 课时数变更 → 自动计算金额
  void _onLessonCountChanged(String value) {
    int count = int.tryParse(value) ?? 0;
    if (count < 1) count = 1;
    if (count > 52) count = 52;
    setState(() {
      lessonCount = count;
      amountError = null;
      _updateAmountFromLessonCount();
    });
  }

  // 金额变更 → 自动计算课时数
  void _onAmountChanged(String value) {
    double amt = double.tryParse(value) ?? 0;
    if (selectedSubject == null || selectedSubject!.subjectPrice <= 0) return;
    double unitPrice = selectedSubject!.subjectPrice;
    setState(() {
      amount = amt;
      if (amt > 0) {
        if (amt % unitPrice != 0) {
          amountError = '金额必须是单价(¥${unitPrice.toStringAsFixed(0)})的整数倍';
        } else {
          amountError = null;
          lessonCount = (amt / unitPrice).round();
          _lessonCountController.text = lessonCount.toString();
        }
      } else {
        amountError = null;
      }
    });
  }

  void _updateAmountFromLessonCount() {
    if (selectedSubject != null && selectedSubject!.subjectPrice > 0) {
      amount = lessonCount * selectedSubject!.subjectPrice;
      _amountController.text = amount.toStringAsFixed(0);
      amountError = null;
    }
  }

  // 点击「推算排课日期」
  Future<void> _onSearchPressed() async {
    if (selectedSubject == null) {
      showErrorDialog('请选择科目。');
      return;
    }
    if (lessonCount < 1) {
      showErrorDialog('预支付课时数必须大于0。');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await fetchScheduleInfo();
    } catch (e) {
      showErrorDialog('获取排课信息失败：$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 显示年份选择器
  void _showYearPicker() {
    int tempSelectedIndex = years.indexOf(selectedYear);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setPickerState) => Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Container(
                  height: controlHeight,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: const Center(
                    child: Text(
                      '选择年份',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32.0,
                    scrollController: FixedExtentScrollController(
                        initialItem: tempSelectedIndex),
                    onSelectedItemChanged: (int index) {
                      setPickerState(() {
                        tempSelectedIndex = index;
                      });
                      setState(() {
                        selectedYear = years[index];
                      });
                    },
                    children: years.asMap().entries
                        .map((entry) => Center(
                            child: Text(entry.value.toString(),
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: entry.key == tempSelectedIndex
                                        ? FontWeight.bold
                                        : FontWeight.normal))))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 显示月份选择器
  void _showMonthPicker() {
    int tempSelectedIndex = months.indexOf(selectedMonth);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setPickerState) => Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: const Center(
                    child: Text(
                      '选择月份',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32.0,
                    scrollController: FixedExtentScrollController(
                        initialItem: tempSelectedIndex),
                    onSelectedItemChanged: (int index) {
                      setPickerState(() {
                        tempSelectedIndex = index;
                      });
                      setState(() {
                        selectedMonth = months[index];
                      });
                    },
                    children: months.asMap().entries
                        .map((entry) => Center(
                            child: Text(entry.value.toString().padLeft(2, '0'),
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: entry.key == tempSelectedIndex
                                        ? FontWeight.bold
                                        : FontWeight.normal))))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showErrorDialog(String message) {
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

  Future<void> _showProcessingDialog() {
    return showDialog(
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
                Text('正在处理按课时预支付......'),
              ],
            ),
          ),
        );
      },
    );
  }

  // 执行按课时预支付
  Future<void> executeAdvcLsnPayPerLesson() async {
    if (selectedSubject == null) {
      showErrorDialog('请选择科目。');
      return;
    }
    if (schedulePreviewList.isEmpty) {
      showErrorDialog('请先点击「推算排课日期」按钮。');
      return;
    }
    if (lessonCount < 1) {
      showErrorDialog('预支付课时数必须大于0。');
      return;
    }
    if (selectedBank == null) {
      showErrorDialog('请选择要存入的银行。');
      return;
    }

    // 构建请求数据：发送完整的 Preview 结果列表给 Execution SP
    // SP 直接按列表执行，不再重新计算
    var dataToSend = <Map<String, dynamic>>[];

    // 第一条记录包含基本信息（学生、科目、银行等）
    // 后续记录只包含排课信息（日期、模式、既存ID）
    for (int i = 0; i < schedulePreviewList.length; i++) {
      var item = schedulePreviewList[i];
      var record = <String, dynamic>{
        'schedualDate': item['schedualDate'],
        'processingMode': item['processingMode'],
        'existingLessonId': item['existingLessonId'],
        'existingFeeId': item['existingFeeId'],
      };

      // 第一条记录添加基本信息
      if (i == 0) {
        record['stuId'] = widget.stuId;
        record['stuName'] = widget.stuName;
        record['subjectId'] = selectedSubject!.subjectId;
        record['subjectSubId'] = selectedSubject!.subjectSubId;
        record['subjectName'] = selectedSubject!.subjectName;
        record['subjectSubName'] = selectedSubject!.subjectSubName;
        record['classDuration'] = selectedSubject!.minutesPerLsn;
        record['lessonType'] = 0;
        record['subjectPrice'] = selectedSubject!.subjectPrice;
        record['minutesPerLsn'] = selectedSubject!.minutesPerLsn;
        record['bankId'] = selectedBank!;
        record['lessonCount'] = lessonCount;
      }

      dataToSend.add(record);
    }

    final String yearMonth =
        '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';

    _showProcessingDialog();

    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiExecuteAdvcLsnPayPerLsn}/${widget.stuId}/$yearMonth';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dataToSend),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                utf8.decode(response.bodyBytes),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop(true);
          });
        }
      } else {
        showErrorDialog(utf8.decode(response.bodyBytes));
      }
      Navigator.of(context).pop(); // 关闭进度对话框
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
      }
      print('Error details: $e');
      showErrorDialog('网络错误：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: KnAppBar(
          title: widget.stuName + titleName,
          subtitle: "${widget.pagePath} >> 按课时预支付",
          context: context,
          appBarBackgroundColor: widget.knBgColor,
          titleColor: Color.fromARGB(
              widget.knFontColor.alpha,
              widget.knFontColor.red - 20,
              widget.knFontColor.green - 20,
              widget.knFontColor.blue - 20),
          subtitleBackgroundColor: Color.fromARGB(
              widget.knBgColor.alpha,
              (widget.knBgColor.red * 0.6).round(),
              (widget.knBgColor.green * 0.6).round(),
              (widget.knBgColor.blue * 0.6).round()),
          subtitleTextColor: Colors.white,
          titleFontSize: 20.0,
          subtitleFontSize: 12.0,
          addInvisibleRightButton: false,
          currentNavIndex: 1,
        ),
        body: Stack(children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // 操作指导小贴士
                Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '按课时预支付操作说明:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text('①选择科目，系统自动显示课时单价。'),
                      Text('②输入预支付金额或课时数（两者自动联动）。'),
                      Text('③指定开始年月，点击【推算排课日期】。'),
                      Text('④确认排课预览后，选择银行，点击【按课时预支付】。'),
                      Text('※每节课单独创建课程和费用记录，费用=课时单价。'),
                    ],
                  ),
                ),

                // 年月选择器（在科目上方）
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Text('年月 ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue)),
                      GestureDetector(
                        onTap: _showYearPicker,
                        child: Container(
                          height: controlHeight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blue[50],
                          ),
                          child: Row(
                            children: [
                              Text('$selectedYear年',
                                  style: const TextStyle(color: Colors.blue)),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showMonthPicker,
                        child: Container(
                          height: controlHeight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blue[50],
                          ),
                          child: Row(
                            children: [
                              Text(
                                  '${selectedMonth.toString().padLeft(2, '0')}月',
                                  style: const TextStyle(color: Colors.blue)),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 科目选择器
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('科目',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue)),
                      const SizedBox(height: 4),
                      if (_subjectLoadError != null)
                        Container(
                          height: controlHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.red[50],
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(_subjectLoadError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        )
                      else if (subjectList.isEmpty && !_isLoading)
                        Container(
                          height: controlHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.orange[50],
                          ),
                          alignment: Alignment.centerLeft,
                          child: const Text('该生没有按课时交费的科目',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 13)),
                        )
                      else
                        Container(
                          height: controlHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blue[50],
                          ),
                          child: DropdownButton<String>(
                            value: selectedSubject != null
                                ? '${selectedSubject!.subjectId}_${selectedSubject!.subjectSubId}'
                                : null,
                            items: subjectList
                                .map((subj) => DropdownMenuItem<String>(
                                      value: '${subj.subjectId}_${subj.subjectSubId}',
                                      child: Text(
                                          '${subj.subjectName} - ${subj.subjectSubName}',
                                          style: const TextStyle(
                                              color: Colors.blue)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                var parts = value.split('_');
                                var subj = subjectList.firstWhere(
                                    (s) => s.subjectId == parts[0] && s.subjectSubId == parts[1]);
                                _onSubjectChanged(subj);
                              } else {
                                _onSubjectChanged(null);
                              }
                            },
                            hint: const Text('请选择科目',
                                style: TextStyle(color: Colors.blue)),
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                ),

                // 课时单价显示
                if (selectedSubject != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      children: [
                        const Text('课时单价: ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '¥${selectedSubject!.subjectPrice.toStringAsFixed(0)}/节',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedSubject!.minutesPerLsn}分钟/节',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                // 双向联动输入（金额 ↔ 课时数）
                if (selectedSubject != null)
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 预支付金额
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('预支付金额',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        height: 36,
                                        child: TextField(
                                          controller: _amountController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 2),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          onChanged: _onAmountChanged,
                                        ),
                                      ),
                                      const Text(' 元',
                                          style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // ↔ 箭头
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('↔',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                            ),
                            // 预支付课时
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('预支付课时',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        height: 36,
                                        child: TextField(
                                          controller: _lessonCountController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 2),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          onChanged: _onLessonCountChanged,
                                        ),
                                      ),
                                      const Text(' 节',
                                          style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (amountError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(amountError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12)),
                          ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('输入任一项，另一项自动计算',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),

                // 推算排课日期按钮
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: controlHeight,
                    child: ElevatedButton(
                      onPressed: selectedSubject != null && lessonCount > 0
                          ? _onSearchPressed
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[500],
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '推算排课日期',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),

                // 排课日期预览列表
                if (schedulePreviewList.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                          ),
                          child: const Text('排课日期预览',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: schedulePreviewList.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            var item = schedulePreviewList[index];
                            bool isPast = item['isPast'] as bool;
                            String mode = item['processingMode'] ?? 'A';
                            // 处理模式标签：A=新建, B=既存未签, C=既存已签未付
                            String modeLabel;
                            Color modeColor;
                            switch (mode) {
                              case 'A':
                                modeLabel = '新建';
                                modeColor = Colors.green;
                                break;
                              case 'B':
                                modeLabel = '既存未签';
                                modeColor = Colors.orange;
                                break;
                              case 'C':
                                modeLabel = '已签未付';
                                modeColor = Colors.purple;
                                break;
                              default:
                                modeLabel = '新建';
                                modeColor = Colors.green;
                            }
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.blue,
                                child: Text('${item['no']}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    '${item['subjectName']} ${item['subjectSubName']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: modeColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: modeColor, width: 1),
                                    ),
                                    child: Text(
                                      modeLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: modeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '¥${(item['subjectPrice'] as double).toStringAsFixed(0)}  ${CommonMethod.getWeekday(item['schedualDate'])} ${item['schedualDate']}',
                                style: TextStyle(
                                  color: isPast ? Colors.red : Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            );
                          },
                        ),
                        // 合计行
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(8)),
                          ),
                          child: Text(
                            '合计: ¥${(selectedSubject!.subjectPrice * lessonCount).toStringAsFixed(0)}  共 $lessonCount 节课',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.blue),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 无固定排课提示
                if (selectedSubject != null &&
                    serverScheduleBeans.isEmpty &&
                    !_hasSchedule &&
                    schedulePreviewList.isEmpty)
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '该生该科目无固定排课信息，暂不支持手动输入排课日期（功能开发中）。',
                      style: TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),

                const SizedBox(height: 10),
                // 银行选择和支付按钮
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: controlHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blue[50],
                          ),
                          child: DropdownButton<String>(
                            value: selectedBank,
                            items: bankList
                                .map((bank) => DropdownMenuItem<String>(
                                      value: bank['bankId'],
                                      child: Text(bank['bankName'],
                                          style: const TextStyle(
                                              color: Colors.blue)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedBank = value;
                              });
                            },
                            hint: const Text('请选择银行名称',
                                style: TextStyle(color: Colors.blue)),
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      ElevatedButton(
                        onPressed: executeAdvcLsnPayPerLesson,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(120, controlHeight),
                        ),
                        child: const Text(
                          '按课时预支付',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Center(
              child: KnLoadingIndicator(color: widget.knBgColor),
            ),
        ]));
  }
}
