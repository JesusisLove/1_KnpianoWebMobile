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
import 'Kn02F003AdvcLsnFeePayBean.dart';

// ignore: must_be_immutable
class Kn02F003AdvcLsnFeePayPage extends StatefulWidget {
  final String stuId;
  final String stuName;
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  final int selectedYear;

  Kn02F003AdvcLsnFeePayPage({
    super.key,
    required this.stuId,
    required this.stuName,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
    required this.selectedYear,
  });

  @override
  _Kn02F003AdvcLsnFeePayPageState createState() =>
      _Kn02F003AdvcLsnFeePayPageState();
}

class _Kn02F003AdvcLsnFeePayPageState extends State<Kn02F003AdvcLsnFeePayPage> {
  late int selectedYear;
  int selectedMonth = DateTime.now().month;
  List<Kn02F003AdvcLsnFeePayBean> stuFeeDetailList = [];
  int stuFeeDetailCount = 0;
  List<Map<String, dynamic>> bankList = [];
  late List<int> years;
  String? selectedBank;
  String titleName = "的课费预支付";
  bool _isLoading = false; // 用于页面整体加载状态

  List<int> months = List.generate(12, (index) => index + 1);
  static const double controlHeight = 40.0;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.selectedYear; // 使用传递过来的年度参数
    years = Constants.generateYearList(); // 使用统一的年度列表生成方法
    // 设置加载状态并获取数据
    setState(() {
      _isLoading = true;
    });
    fetchBankList().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
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

  // 获取费用详情
  Future<void> fetchAdvcLsnInfoDetails() async {
    final String yearMonth =
        '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
    final String apiAdvcLsnFeePayInfo =
        '${KnConfig.apiBaseUrl}${Constants.apiAdvcLsnFeePayInfo}/${widget.stuId}/$yearMonth';
    final responseFeeDetails = await http.get(Uri.parse(apiAdvcLsnFeePayInfo));
    if (responseFeeDetails.statusCode == 200) {
      final decodedBody = utf8.decode(responseFeeDetails.bodyBytes);
      List<dynamic> stuDocJson = json.decode(decodedBody);
      setState(() {
        stuFeeDetailList = stuDocJson
            .map((json) => Kn02F003AdvcLsnFeePayBean.fromJson(json))
            .toList();
        stuFeeDetailCount = stuFeeDetailList.length;
      });
    } else {
      throw Exception('Failed to load fee details');
    }
  }

  // 显示年份选择器
  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
  void _showYearPicker() {
    int tempSelectedIndex = years.indexOf(selectedYear);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setPickerState) => Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Container(
                  height: controlHeight,
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: const Center(
                    child: Text(
                      '选择年份',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
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
                                    color: Colors.red,
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
  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
  void _showMonthPicker() {
    int tempSelectedIndex = months.indexOf(selectedMonth);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setPickerState) => Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: const Center(
                    child: Text(
                      '选择月份',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
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
                                    color: Colors.red,
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

  // 新增：显示错误消息的方法
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
      barrierDismissible: false, // 用户不能通过点击对话框外部来关闭
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // 禁止返回键关闭
          child: const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在处理学费预支付......'),
              ],
            ),
          ),
        );
      },
    );
  }

  // 新增：执行课费预支付的方法
  Future<void> executeAdvcLsnPay() async {
    // 检查是否有选中的科目
    List<Kn02F003AdvcLsnFeePayBean> selectedItems =
        stuFeeDetailList.where((item) => item.isChecked).toList();
    if (selectedItems.isEmpty) {
      showErrorDialog('执行预支付，至少选择一个科目。');
      return;
    }

    // 检查选中的科目是否都有排课日期
    if (selectedItems.any((item) => item.schedualDate.isEmpty)) {
      showErrorDialog('请输入您要排课的日期：yyyy-MM-dd hh:mm');
      return;
    }

    // 检查是否选择了银行
    if (selectedBank == null) {
      showErrorDialog('请选择要存入的银行。');
      return;
    }

    // 更新选中项目的银行ID
    for (var item in selectedItems) {
      item.bankId = selectedBank!;
    }

    final String yearMonth =
        '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';

    // 显示“正在处理学费预支付....”进度条
    _showProcessingDialog();

    // 发送数据到后端
    final String apiExecuteAdvcLsnPayUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiExecuteAdvcLsnPay}/${widget.stuId}/$yearMonth';
    try {
      final response = await http.post(
        Uri.parse(apiExecuteAdvcLsnPayUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(selectedItems),
      );

      if (response.statusCode == 200) {
        // 支付成功
        if (mounted) {
          // 显示绿底白字的成功消息
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
              // behavior: SnackBarBehavior.floating, // 使 SnackBar 浮动 // 此代码保留不要删除，这是设置showSnackBar的显示风格
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          );

          // 延迟一小段时间后关闭当前页面
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop(true); // 关闭当前页面，返回上一级
          });
        }
      } else {
        // 显示错误信息
        showErrorDialog(utf8.decode(response.bodyBytes));
      }
      // 关闭进度对话框
      Navigator.of(context).pop(); // 关闭进度对话框
    } catch (e) {
      // 确保发生错误时也关闭进度对话框
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
          subtitle: "${widget.pagePath} >> 课费预支付",
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
          addInvisibleRightButton: false,
          currentNavIndex: 1,
        ),
        body: Stack(children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // 添加操作指导小贴士
                Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    border: Border.all(color: Colors.amber),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '预支付操作小贴士:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.amber,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text('①指定年月后，点击【推算排课日期】按钮。'),
                      Text('②看到日期字体红色，表示过去的日期，依然可以预支付。'),
                      Text('③点击排课日期，可以另择日期进行预排课。'),
                      Text('④选择银行名称，点击【课费预支付】完成预支付操作。'),
                      Text('※一旦预支付完成，再预支付程序也不会重复执行预支付。'),
                    ],
                  ),
                ),
                // 年月选择和推算排课日期按钮
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _showYearPicker,
                        child: Container(
                          height: controlHeight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.pink[50],
                          ),
                          child: Row(
                            children: [
                              Text('$selectedYear年',
                                  style: const TextStyle(color: Colors.red)),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showMonthPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.pink[50],
                          ),
                          child: Row(
                            children: [
                              Text(
                                  '${selectedMonth.toString().padLeft(2, '0')}月',
                                  style: const TextStyle(color: Colors.red)),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: fetchAdvcLsnInfoDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[500],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(80, controlHeight),
                        ),
                        child: const Text(
                          '推算排课日期',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                // 费用详情列表
                Container(
                  color: Colors.grey[200],
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: stuFeeDetailCount,
                    separatorBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(color: Colors.grey),
                    ),
                    itemBuilder: (context, index) {
                      final kn02F003AdvcLsnFeePayBean = stuFeeDetailList[index];
                      return AdvcLsnDetails(
                        item: kn02F003AdvcLsnFeePayBean,
                        onChanged: (bool? value) {
                          setState(() {
                            kn02F003AdvcLsnFeePayBean.isChecked = value!;
                          });
                        },
                      );
                    },
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
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.pink[50],
                          ),
                          child: DropdownButton<String>(
                            value: selectedBank,
                            items: bankList
                                .map((bank) => DropdownMenuItem<String>(
                                      value: bank['bankId'],
                                      child: Text(bank['bankName'],
                                          style: const TextStyle(
                                              color: Colors.red)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedBank = value;
                              });
                            },
                            hint: const Text('请选择银行名称',
                                style: TextStyle(color: Colors.red)),
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      ElevatedButton(
                        onPressed: executeAdvcLsnPay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(120, controlHeight),
                        ),
                        child: const Text(
                          '课费预支付',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 仅在页面初始化加载时显示的进度指示器
          if (_isLoading)
            Center(
              // 使用自定的加载器进度条
              child: KnLoadingIndicator(color: widget.knBgColor), // 使用自定的加载器进度条
            ),
        ]));
  }
}

// AdvcLsnDetails 类修改
class AdvcLsnDetails extends StatefulWidget {
  final Kn02F003AdvcLsnFeePayBean item;
  final Function(bool?) onChanged; // 新增：回调函数

  const AdvcLsnDetails(
      {super.key, required this.item, required this.onChanged});

  @override
  _AdvcLsnDetailsState createState() => _AdvcLsnDetailsState();
}

class _AdvcLsnDetailsState extends State<AdvcLsnDetails> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // 检查日期是否小于当前日期
  bool isDatePassed() {
    if (widget.item.schedualDate.isEmpty) {
      return false;
    }
    try {
      DateTime scheduleDate =
          DateFormat('yyyy-MM-dd HH:mm').parse(widget.item.schedualDate);
      return scheduleDate.isBefore(DateTime.now());
    } catch (e) {
      print('日期解析错误: ${widget.item.schedualDate}');
      return false;
    }
  }

  // 选择日期
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _selectTime(context); // 在选择日期后立即选择时间
    }
  }

  // 选择时间
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
      // 更新schedualDate
      if (selectedDate != null) {
        widget.item.schedualDate =
            "${DateFormat('yyyy-MM-dd').format(selectedDate!)} ${picked.format(context)}";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool datePassed = isDatePassed();
    String displayDate = widget.item.schedualDate.isNotEmpty
        ? widget.item.schedualDate
        : (selectedDate != null && selectedTime != null
            ? "${DateFormat('yyyy-MM-dd').format(selectedDate!)} ${selectedTime!.format(context)}"
            : "");

    return CheckboxListTile(
      value: widget.item.isChecked,
      onChanged: (value) {
        setState(() {
          widget.item.isChecked = value!;
          if (widget.item.isChecked && displayDate.isEmpty) {
            _selectDate(context);
          } else if (!widget.item.isChecked) {
            selectedDate = null;
            selectedTime = null;
            widget.item.schedualDate = "";
          }
        });
        widget.onChanged(value); // 调用回调函数
      },
      title: Text(
          '${widget.item.subjectName} ${widget.item.subjectSubName} ${widget.item.lessonType == 1 ? '「月计划」' : ''}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                    text:
                        '¥${widget.item.subjectPrice}   ${widget.item.minutesPerLsn}分钟   '),
                if (displayDate.isNotEmpty)
                  TextSpan(
                    text:
                        '${CommonMethod.getWeekday(displayDate)} $displayDate',
                    style: TextStyle(
                      color: widget.item.schedualDate.isEmpty
                          ? Colors.blue
                          : (datePassed ? Colors.red : null),
                    ),
                  ),
              ],
            ),
          ),
          if (displayDate.isEmpty && widget.item.isChecked)
            Row(
              children: [
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('选择日期和时间',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
