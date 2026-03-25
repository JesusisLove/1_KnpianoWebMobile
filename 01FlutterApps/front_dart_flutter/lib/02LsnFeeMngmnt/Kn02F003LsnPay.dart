// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../ApiConfig/KnApiConfig.dart';
// KnAppBar は Dialog 化により不要（削除）
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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  color: widget.knBgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: widget.knFontColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '错误',
                        style: TextStyle(
                          color: widget.knFontColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
  Future<void> showConfirmDialog(String lsnPayId, String lsnFeeId, String payMonth) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  color: widget.knBgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.help_outline, color: widget.knFontColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '确认',
                        style: TextStyle(
                          color: widget.knFontColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('您确定要撤销这笔支付吗？'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              restorePayment(lsnPayId, lsnFeeId, payMonth);
                              widget.isAllPaid = false;
                            },
                            child: Text('确认', style: TextStyle(color: widget.knBgColor)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> restorePayment(String lsnPayId, String lsnFeeId, String payMonth) async {
    final String apiStuPayRestoreUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiStuPayRestore}/$lsnPayId/$lsnFeeId/$payMonth';
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

  // [UI改善] 2026-03-06 改为 Dialog 弹窗形式，消除空旷感
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 标题栏 ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.knBgColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Text(
                '${widget.monthData.first.stuName} ${widget.monthData.first.month}月份的学费账单',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.knFontColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // ── 课程列表（紧凑行，最大高度可滚动）──
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(widget.monthData.length, (index) {
                    final fee = widget.monthData[index];
                    final lessonTypeText = fee.lessonType == 0
                        ? '结算课'
                        : fee.lessonType == 1
                            ? '月计划'
                            : '月加课';
                    final amount = fee.lessonType == 1
                        ? (fee.subjectPrice! * 4)
                        : fee.lsnFee;
                    bool isPaymentToday = false;
                    if (fee.payDate != null && fee.payDate!.isNotEmpty) {
                      try {
                        final paymentDate = DateTime.parse(fee.payDate!);
                        isPaymentToday =
                            DateFormat('yyyy-MM-dd').format(paymentDate) ==
                                DateFormat('yyyy-MM-dd').format(DateTime.now());
                      } catch (_) {}
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Checkbox(
                              visualDensity: VisualDensity.compact,
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
                          ),
                          Expanded(
                            child: Text(
                              '${fee.subjectName} ($lessonTypeText)',
                              style: TextStyle(
                                fontSize: 13,
                                decoration: fee.ownFlg == 1
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: fee.ownFlg == 1
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '\$${fee.subjectPrice}/节×${fee.lsnCount}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: fee.ownFlg == 1
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                          if (fee.ownFlg == 1 && isPaymentToday)
                            SizedBox(
                              width: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon:
                                    const Icon(Icons.more_vert, size: 16),
                                onPressed: () => showConfirmDialog(
                                    fee.lsnPayId, fee.lsnFeeId, fee.lsnMonth),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            const Divider(height: 1),
            // ── 汇总行 ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('合计: \$${totalFee.toStringAsFixed(2)}',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  Text('实付: \$${paymentAmount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.green)),
                  Text(
                      '剩余: \$${(totalFee - paymentAmount).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── 银行选择 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: GestureDetector(
                onTap: _showBankPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
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
            ),
            // ── 入账日期 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: GestureDetector(
                onTap: () async {
                  final DateTime now = DateTime.now();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(now.year, 1, 1),
                    lastDate: DateTime(now.year, 12, 31),
                    selectableDayPredicate: (DateTime date) =>
                        date.day >= 1 && date.day <= 31,
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
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
            ),
            // ── 操作按钮 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !widget.isAllPaid ? validateAndSave : null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: widget.knFontColor,
                        backgroundColor: widget.knBgColor,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      child: const Text('学费入账'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
