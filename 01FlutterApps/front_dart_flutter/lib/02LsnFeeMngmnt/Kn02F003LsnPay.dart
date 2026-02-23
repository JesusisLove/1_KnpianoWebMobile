// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../ApiConfig/KnApiConfig.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../Constants.dart';
import '../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-18 添加主题扩展
import 'Kn02F002FeeBean.dart';
import 'Kn02F004UnpaidBean.dart';

// ignore: must_be_immutable
class Kn02F003LsnPay extends StatefulWidget {
  final List<Kn02F002FeeBean> monthData;
  bool isAllPaid;
  // AppBar背景颜色
  final Color knBgColor;
  // 字体颜色
  final Color knFontColor;
  // 画面迁移路径：例如，上课进度管理>>学生姓名一览>> xxx的课程进度状况
  late String pagePath;

  Kn02F003LsnPay(
      {super.key,
      required this.monthData,
      required this.isAllPaid,
      required this.knBgColor,
      required this.knFontColor,
      required this.pagePath});

  @override
  _Kn02F003LsnPayState createState() => _Kn02F003LsnPayState();
}

class _Kn02F003LsnPayState extends State<Kn02F003LsnPay> {
  final String titleName = '学费账单';
  List<bool> selectedSubjects = [];
  List<Map<String, dynamic>> bankList = [];
  String? selectedBankId;
  DateTime selectedDate = DateTime.now();
  double totalFee = 0;
  double paymentAmount = 0;

  @override
  void initState() {
    super.initState();
    widget.pagePath = '${widget.pagePath} >> $titleName';
    selectedSubjects = List.generate(widget.monthData.length,
        (index) => widget.monthData[index].ownFlg == 1);
    calculateTotalFee();
    calculateHasPaidFee();
    fetchBankList().then((_) {
      // 检查是否有未支付的课费（至少有一个 ownFlg == 0）
      bool hasUnpaidFee = widget.monthData.any((item) => item.ownFlg == 0);

      // 只有存在未支付课费时才自动设置默认银行
      // 如果所有课费都已支付（所有 ownFlg == 1），则不自动设置，用户可手动选择
      if (hasUnpaidFee) {
        fetchDefaultBankId();
      }
    });
  }

  // 画面初期化，统计课费总额
  void calculateTotalFee() {
    totalFee = widget.monthData.fold(
        0,
        (sum, fee) =>
            sum + (fee.lessonType == 1 ? (fee.subjectPrice! * 4) : fee.lsnFee));
  }

  // 画面初期化，计算目前已支付课费总额
  void calculateHasPaidFee() {
    paymentAmount = widget.monthData.where((item) => item.ownFlg == 1).fold(
        0.0,
        (sum, item) =>
            sum +
            (item.lessonType == 1 ? (item.subjectPrice! * 4) : item.lsnPay));
  }

  void updatePaymentAmount() {
    paymentAmount = 0;
    for (int i = 0; i < widget.monthData.length; i++) {
      if (selectedSubjects[i]) {
        paymentAmount += widget.monthData[i].lessonType == 1
            ? (widget.monthData[i].subjectPrice! * 4)
            : widget.monthData[i].lsnFee;
      }
    }
    setState(() {});
  }

  Future<void> fetchBankList() async {
    final String apiGetBnkUrl =
        '${KnConfig.apiBaseUrl}${Constants.stuBankList}/${widget.monthData.first.stuId}';
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
      // Handle error
    }
  }

  // 获取默认银行ID（上一个月支付时使用的银行）
  Future<void> fetchDefaultBankId() async {
    final String stuId = widget.monthData.first.stuId;
    final String currentMonth = widget.monthData.first.lsnMonth; // 格式：2025-12

    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiDefaultBankId}/$stuId/$currentMonth';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final String bankId = utf8.decode(response.bodyBytes);

        // 如果返回了有效的银行ID，设置为默认选中
        if (bankId.isNotEmpty) {
          setState(() {
            selectedBankId = bankId;
          });
        }
      }
    } catch (e) {
      print('Failed to load default bank ID: $e');
      // 不影响正常流程，用户可以手动选择银行
    }
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
                Text('正在处理学费入账......'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> saveLsnPay() async {
    // 显示“正在处理学费入账....”进度条
    _showProcessingDialog();

    final String apiLsnSaveUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiStuPaySave}';
    List<Kn02F004UnpaidBean> selectedFees = [];

    for (int i = 0; i < widget.monthData.length; i++) {
      if (selectedSubjects[i] && widget.monthData[i].ownFlg == 0) {
        selectedFees.add(Kn02F004UnpaidBean(
          lsnFeeId: widget.monthData[i].lsnFeeId,
          lsnPay: widget.monthData[i].lsnFee,
          payMonth: widget.monthData.first.lsnMonth,
          payDate: selectedDate.toString(),
          bankId: selectedBankId!,
        ));
      }
    }

    try {
      final response = await http.post(
        Uri.parse(apiLsnSaveUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(selectedFees),
      );

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
      }

      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true);
      } else {
        showErrorDialog('保存学费支付失败。错误码：${response.statusCode}');
      }
    } catch (e) {
      // 确保发生错误时也关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
      }
      showErrorDialog('网络错误：$e');
    }
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

  void validateAndSave() {
    if (!selectedSubjects.contains(true)) {
      showErrorDialog('请选择要入账的课程');
    } else if (selectedBankId == null) {
      showErrorDialog('请选择银行名称');
    } else {
      saveLsnPay();
    }
  }

  // 修改：添加确认对话框
  Future<void> showConfirmDialog(String lsnPayId, String lsnFeeId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('确认',
              style: KnElementTextStyle.dialogTitle(context,
                  color: Constants.lsnfeeThemeColor)),
          content: Text('您确定要撤销这笔支付吗？',
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
              child: Text('确认',
                  style: KnElementTextStyle.buttonText(context,
                      color: Constants.lsnfeeThemeColor)),
              onPressed: () {
                Navigator.of(context).pop();
                restorePayment(lsnPayId, lsnFeeId);
                widget.isAllPaid = false;
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> restorePayment(String lsnPayId, String lsnFeeId) async {
    final String apiStuPayRestoreUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiStuPayRestore}/$lsnPayId/$lsnFeeId';
    try {
      final response = await http.delete(Uri.parse(apiStuPayRestoreUrl));
      if (response.statusCode == 200) {
        setState(() {
          int index = widget.monthData
              .indexWhere((element) => element.lsnFeeId == lsnFeeId);
          if (index != -1) {
            widget.monthData[index].ownFlg = 0;
            selectedSubjects[index] = false;
          }
        });
        updatePaymentAmount();
      } else {
        showErrorDialog('撤销支付失败。错误码：${response.statusCode}');
      }
    } catch (e) {
      showErrorDialog('网络错误：$e');
    }
  }

// 修改: 添加显示银行选择器的方法
  // [Flutter页面主题改造] 2026-01-18 银行选择器字体跟随主题风格
  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
  void _showBankPicker() {
    // 找到当前选中银行的索引，如果没有选中则默认为0
    int initialIndex = 0;
    if (selectedBankId != null) {
      initialIndex =
          bankList.indexWhere((bank) => bank['bankId'] == selectedBankId);
      if (initialIndex == -1) initialIndex = 0;
    }

    // 临时存储选择的索引
    int tempSelectedIndex = initialIndex;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setPickerState) => Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                color: widget.knBgColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text('取消',
                          style: KnPickerTextStyle.pickerButton(context,
                              color: widget.knFontColor)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text('选择银行',
                        style: KnPickerTextStyle.pickerTitle(context,
                            color: widget.knFontColor)),
                    CupertinoButton(
                      child: Text('确定',
                          style: KnPickerTextStyle.pickerButton(context,
                              color: widget.knFontColor)),
                      onPressed: () {
                        // 点击确定时更新selectedBankId
                        setState(() {
                          selectedBankId = bankList[tempSelectedIndex]['bankId'];
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  // 设置初始选中的项目
                  scrollController:
                      FixedExtentScrollController(initialItem: tempSelectedIndex),
                  onSelectedItemChanged: (int index) {
                    // 更新临时选择的索引
                    setPickerState(() {
                      tempSelectedIndex = index;
                    });
                  },
                  children: bankList.asMap().entries
                      .map((entry) => Text(entry.value['bankName'],
                          style: entry.key == tempSelectedIndex
                              ? KnPickerTextStyle.pickerItemSelected(context,
                                  fontSize: 18)
                              : KnPickerTextStyle.pickerItem(context,
                                  fontSize: 18)))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
          title:
              '${widget.monthData.first.stuName} ${widget.monthData.first.month}月份的学费账单',
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
          addInvisibleRightButton: false,
          currentNavIndex: 1,
          subtitleTextColor: Colors.white,
          titleFontSize: 20.0,
          subtitleFontSize: 12.0,
          refreshPreviousPage: true), //刷新上一页面
      // 修改: 更新body部分的布局和样式
      body: Column(
        children: [
          // 修改: 调整课程列表的样式
          Expanded(
            child: ListView.builder(
              itemCount: widget.monthData.length,
              itemBuilder: (context, index) {
                final fee = widget.monthData[index];
                final lessonTypeText = fee.lessonType == 0
                    ? '结算课'
                    : fee.lessonType == 1
                        ? '月计划'
                        : '月加课';
                bool isPaymentToday = false;
                if (fee.payDate != null && fee.payDate!.isNotEmpty) {
                  try {
                    final paymentDate = DateTime.parse(fee.payDate!);
                    isPaymentToday =
                        DateFormat('yyyy-MM-dd').format(paymentDate) ==
                            DateFormat('yyyy-MM-dd').format(DateTime.now());
                  } catch (e) {
                    print('Invalid date format: ${fee.payDate}');
                  }
                }
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: Checkbox(
                      value: selectedSubjects[index],
                      onChanged: fee.ownFlg == 0
                          ? (bool? value) {
                              setState(() {
                                selectedSubjects[index] = value!;
                                updatePaymentAmount();
                              });
                            }
                          : null,
                    ),
                    title: Text('${fee.subjectName} ($lessonTypeText)'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('课费: \$${fee.lsnFee.toStringAsFixed(2)}'),
                        Text('单价: \$${fee.subjectPrice}/节'),
                        Text('上课节数: ${fee.lsnCount}'),
                      ],
                    ),
                    trailing: fee.ownFlg == 1 && isPaymentToday
                        ? IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              showConfirmDialog(fee.lsnPayId, fee.lsnFeeId);
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          // 修改: 调整底部结算区域的样式
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('合计: \$${totalFee.toStringAsFixed(2)}'),
                    Text('支付: \$${paymentAmount.toStringAsFixed(2)}'),
                    Text(
                        '剩余: \$${(totalFee - paymentAmount).toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 16),
                // 修改: 使用GestureDetector来触发银行选择器
                GestureDetector(
                  onTap: _showBankPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedBankId != null
                            ? bankList.firstWhere((bank) =>
                                bank['bankId'] == selectedBankId)['bankName']
                            : '选择银行'),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 修改: 调整日期选择器的样式
                GestureDetector(
                  onTap: () async {
                    // 获取当前时间
                    DateTime now = DateTime.now();
                    // 设置可选时间范围为当前年份的全年
                    DateTime firstDate = DateTime(now.year, 1, 1);
                    DateTime lastDate = DateTime(now.year, 12, 31);

                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      selectableDayPredicate: (DateTime date) {
                        // 判断这个日期在这个月的第几天
                        int dayOfMonth = date.day;
                        // 只要是这个月的日期就返回true
                        return dayOfMonth >= 1 && dayOfMonth <= 31;
                      },
                      initialEntryMode:
                          DatePickerEntryMode.calendarOnly, // 直接显示日历视图
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '入账日期: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 修改: 调整学费入账按钮的样式
                ElevatedButton(
                  onPressed: !widget.isAllPaid ? validateAndSave : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: widget.knFontColor,
                    backgroundColor: widget.knBgColor,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('学费入账'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
