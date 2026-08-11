// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../ApiConfig/KnApiConfig.dart';
// KnAppBar は Dialog 化により不要（削除）
import '../CommonProcess/customUI/KnDialog.dart';
import '../CommonProcess/KnMsg.dart';
import '../Constants.dart';
import '../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-18 添加主题扩展
import 'Kn02F002FeeBean.dart';
import 'Kn02F004UnpaidBean.dart';
import '../01LessonMngmnt/1LessonSchedual/TrendyView/lesson_type_colors.dart';

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
  // 当前选中的未支付课费(lsnFeeId -> 是否勾选)。已支付(ownFlg==1)的记录不会出现在这个容器里，
  // 从数据结构上保证已支付的历史记录不会污染"这次要入账"的业务判断
  Map<String, bool> selectedSubjects = {};
  List<Map<String, dynamic>> bankList = [];
  String? selectedBankId;
  DateTime selectedDate = DateTime.now();
  double totalFee = 0;
  double paymentAmount = 0;

  // 课程明细：画面初期化时一次性批量取得（按monthData下标缓存），不再懒加载
  bool lessonDetailLoading = false;
  List<List<Kn02F002FeeBean>?> lessonDetailCache = [];

  @override
  void initState() {
    super.initState();
    widget.pagePath = '${widget.pagePath} >> $titleName';
    // 只把未支付的课费放进选中容器，已支付的记录不给它机会出现在这里
    selectedSubjects = {};
    for (final fee in widget.monthData) {
      if (fee.ownFlg == 0) {
        selectedSubjects[fee.lsnFeeId] = false;
      }
    }
    lessonDetailCache = List.filled(widget.monthData.length, null);
    calculateTotalFee();
    calculateHasPaidFee();
    fetchAllLessonDetails();
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

  // "实付"= 已支付历史金额 + 这次新选中(未支付)的金额
  void updatePaymentAmount() {
    paymentAmount = 0;
    for (final fee in widget.monthData) {
      final bool included =
          fee.ownFlg == 1 || (selectedSubjects[fee.lsnFeeId] ?? false);
      if (included) {
        paymentAmount +=
            fee.lessonType == 1 ? (fee.subjectPrice! * 4) : fee.lsnFee;
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

  // 画面初期化：一次性批量取得该月所有课费对应的课程明细，不再懒加载
  Future<void> fetchAllLessonDetails() async {
    setState(() => lessonDetailLoading = true);

    final List<String> lsnFeeIds =
        widget.monthData.map((fee) => fee.lsnFeeId).toList();
    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiLsnFeeLessonDetailBatch}';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(lsnFeeIds),
      );
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(decodedBody);
        final List<Kn02F002FeeBean> allDetails =
            data.map((item) => Kn02F002FeeBean.fromJson(item)).toList();
        for (int i = 0; i < widget.monthData.length; i++) {
          final String lsnFeeId = widget.monthData[i].lsnFeeId;
          lessonDetailCache[i] = allDetails
              .where((detail) => detail.lsnFeeId == lsnFeeId)
              .toList();
        }
      }
    } catch (e) {
      print('Failed to load lesson detail batch: $e');
    }

    setState(() => lessonDetailLoading = false);
  }

  // 汇总该课费对应的所有课程上课日期（"日/月（星期）"格式逗号拼接，不带类型/调课标签），单行显示用
  String buildLessonDatesText(int index) {
    final List<Kn02F002FeeBean>? list = lessonDetailCache[index];
    if (list == null || list.isEmpty) {
      return '';
    }
    final List<String> dates = [];
    for (final lsn in list) {
      if (lsn.scanqrDate == null || lsn.scanqrDate!.isEmpty) {
        continue;
      }
      try {
        final DateTime date =
            DateFormat('yyyy-MM-dd HH:mm').parse(lsn.scanqrDate!);
        final String weekday = DateFormat('EEE', 'en_US').format(date);
        dates.add('${date.day}/${date.month}（$weekday）');
      } catch (_) {}
    }
    return dates.join(', ');
  }

  // 取该课费的"代表日期"（第一条课程的签到日期，仅日期部分yyyy-MM-dd），用于多选日期一致性比较
  String? comparableDateString(int index) {
    final List<Kn02F002FeeBean>? list = lessonDetailCache[index];
    if (list == null || list.isEmpty) {
      return null;
    }
    final String? scanqrDate = list.first.scanqrDate;
    if (scanqrDate == null || scanqrDate.isEmpty) {
      return null;
    }
    try {
      final DateTime date = DateFormat('yyyy-MM-dd HH:mm').parse(scanqrDate);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (_) {
      return null;
    }
  }

  // checkbox可用性：已支付(ownFlg!=0)禁用；未支付时，若"别的"已勾选项目里有月计划课，本项也禁用
  // （月计划课与课结算/月加课互斥；月计划课自身的checkbox不受此限制，始终可点）
  // 注：selectedSubjects只装未支付记录，这里天然不会被已支付记录干扰，不需要再额外判断ownFlg
  bool isCheckboxDisabled(int index) {
    final fee = widget.monthData[index];
    if (fee.ownFlg != 0) {
      return true;
    }
    if (fee.lessonType != 1) {
      for (final other in widget.monthData) {
        if (other.lsnFeeId != fee.lsnFeeId &&
            other.lessonType == 1 &&
            (selectedSubjects[other.lsnFeeId] ?? false)) {
          return true;
        }
      }
    }
    return false;
  }

  // checkbox勾选/取消勾选处理
  void onCheckboxChanged(int index, bool? value) {
    final fee = widget.monthData[index];
    setState(() {
      selectedSubjects[fee.lsnFeeId] = value ?? false;
      if (value == true && fee.lessonType == 1) {
        // 月计划课优先：勾选后清空其他所有已勾选的未支付项目，入账日期设为今天
        // 只遍历selectedSubjects已有的键（即未支付记录），已支付记录不在这个容器里，不会被误清空
        for (final key in selectedSubjects.keys.toList()) {
          if (key != fee.lsnFeeId) {
            selectedSubjects[key] = false;
          }
        }
        selectedDate = DateTime.now();
      }
      updatePaymentAmount();
    });

    if (value == true && fee.lessonType != 1) {
      resolvePayDateForSelection(index);
    }
  }

  // 勾选课结算/月加课时：比较当前所有已勾选(同为课结算/月加课)记录的课程日期，
  // 全部相同则自动填入入账日期；不同则弹提示框要求手动输入
  // 注：selectedSubjects只装未支付记录，这里天然不会被已支付记录干扰
  void resolvePayDateForSelection(int index) {
    final String? newDateStr = comparableDateString(index);
    if (newDateStr == null) {
      return;
    }
    final String feeId = widget.monthData[index].lsnFeeId;
    for (int i = 0; i < widget.monthData.length; i++) {
      final otherFee = widget.monthData[i];
      if (otherFee.lsnFeeId == feeId) {
        continue;
      }
      if (!(selectedSubjects[otherFee.lsnFeeId] ?? false)) {
        continue;
      }
      if (otherFee.lessonType == 1) {
        continue;
      }
      final String? otherDateStr = comparableDateString(i);
      if (otherDateStr != null && otherDateStr != newDateStr) {
        showDateConflictDialog(index);
        return;
      }
    }
    try {
      setState(() => selectedDate = DateFormat('yyyy-MM-dd').parse(newDateStr));
    } catch (_) {}
  }

  // 8位纯数字（yyyyMMdd）转合法日期，非法（如9999/99/99、日期不存在）返回null
  DateTime? parseYyyymmdd(String digits) {
    if (digits.length != 8) {
      return null;
    }
    final int? year = int.tryParse(digits.substring(0, 4));
    final int? month = int.tryParse(digits.substring(4, 6));
    final int? day = int.tryParse(digits.substring(6, 8));
    if (year == null || month == null || day == null) {
      return null;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final DateTime date = DateTime(year, month, day);
    // DateTime构造函数对超出范围的日期会自动进位（如2月30日变3月X日），此处拦截
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  // 多选课程日期不一致时的手动输入提示框：纯数字输入(yyyyMMdd)，确定后格式化为yyyy-MM-dd；
  // 取消则把这次导致冲突的checkbox(conflictIndex)还原为未选中，保证已选中的记录始终以第一次选中的为参照标准
  void showDateConflictDialog(int conflictIndex) {
    final TextEditingController controller = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('入账日期不一致'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('不是同一个支付日期，请输入入账日期'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: InputDecoration(
                    hintText: 'yyyyMMdd',
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedSubjects[widget.monthData[conflictIndex].lsnFeeId] =
                        false;
                    updatePaymentAmount();
                  });
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final DateTime? parsed = parseYyyymmdd(controller.text);
                  if (parsed == null) {
                    setDialogState(() => errorText = '请输入合法的日期（yyyyMMdd）');
                    return;
                  }
                  setState(() => selectedDate = parsed);
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 科目名称文字颜色：已结算(ownFlg==1)维持灰色不变；未结算(ownFlg==0)时，
  // 勾选checkbox后按lessonType变色（月计划天蓝/月加课粉红/课结算浅绿），未勾选保持黑色
  Color subjectTextColor(Kn02F002FeeBean fee) {
    if (fee.ownFlg == 1) {
      return Colors.grey;
    }
    if (selectedSubjects[fee.lsnFeeId] ?? false) {
      switch (fee.lessonType) {
        case 1:
          return LessonTypeColors.scheduledColor;
        case 2:
          return LessonTypeColors.extraColor;
        default:
          return LessonTypeColors.payPerLessonColor;
      }
    }
    return Colors.black87;
  }

  Future<void> saveLsnPay() async {
    // A类：显示进度对话框
    final dismiss = KnDialog.showLoading(
      context, widget.knBgColor, widget.knFontColor,
      KnMsg.i.loadingLsnFeePay,
    );

    final String apiLsnSaveUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiStuPaySave}';
    List<Kn02F004UnpaidBean> selectedFees = [];

    // selectedSubjects只装未支付记录，这里不需要再判断ownFlg
    for (final fee in widget.monthData) {
      if (selectedSubjects[fee.lsnFeeId] ?? false) {
        selectedFees.add(Kn02F004UnpaidBean(
          lsnFeeId: fee.lsnFeeId,
          lsnPay: fee.lsnFee,
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

      // API 响应后先关闭 Loading 对话框，再处理结果
      dismiss();

      if (response.statusCode == 200) {
        if (mounted) {
          // ignore: use_build_context_synchronously
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          KnDialog.showInfo(
            context, widget.knBgColor, widget.knFontColor,
            KnMsg.i.titleError,
            '保存学费支付失败。错误码：${response.statusCode}',
          );
        }
      }
    } catch (e) {
      // 异常时也先关闭 Loading 对话框，再显示错误
      dismiss();
      if (mounted) {
        KnDialog.showInfo(
          context, widget.knBgColor, widget.knFontColor,
          KnMsg.i.titleError,
          '网络错误：$e',
        );
      }
    }
  }

  void validateAndSave() {
    if (!selectedSubjects.values.contains(true)) {
      // C类：未选择课程提示
      KnDialog.showInfo(
        context, widget.knBgColor, widget.knFontColor,
        KnMsg.i.titleError,
        '请选择要入账的课程',
      );
    } else if (selectedBankId == null) {
      // C类：未选择银行提示
      KnDialog.showInfo(
        context, widget.knBgColor, widget.knFontColor,
        KnMsg.i.titleError,
        '请选择银行名称',
      );
    } else {
      saveLsnPay();
    }
  }

  // B类：撤销支付确认对话框
  void showConfirmDialog(String lsnPayId, String lsnFeeId, String payMonth) {
    KnDialog.showConfirm(
      context, widget.knBgColor, widget.knFontColor,
      KnMsg.i.titleConfirm,
      KnMsg.i.confirmPaymentUndo,
      onConfirm: () async {
        restorePayment(lsnPayId, lsnFeeId, payMonth);
        widget.isAllPaid = false;
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
            // 撤销支付后该记录变为未支付，此时才让它进入选中容器（默认未勾选）
            selectedSubjects[lsnFeeId] = false;
          }
        });
        updatePaymentAmount();
      } else {
        if (mounted) {
          KnDialog.showInfo(
            context, widget.knBgColor, widget.knFontColor,
            KnMsg.i.titleError,
            '撤销支付失败。错误码：${response.statusCode}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        KnDialog.showInfo(
          context, widget.knBgColor, widget.knFontColor,
          KnMsg.i.titleError,
          '网络错误：$e',
        );
      }
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
              child: lessonDetailLoading
                  ? SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: widget.knBgColor),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children:
                            List.generate(widget.monthData.length, (index) {
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
                              isPaymentToday = DateFormat('yyyy-MM-dd')
                                      .format(paymentDate) ==
                                  DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now());
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
                                    value: fee.ownFlg == 1
                                        ? true
                                        : (selectedSubjects[fee.lsnFeeId] ??
                                            false),
                                    onChanged: isCheckboxDisabled(index)
                                        ? null
                                        : (bool? value) =>
                                            onCheckboxChanged(index, value),
                                  ),
                                ),
                                Text(
                                  '${fee.subjectName} ($lessonTypeText)',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 13,
                                    decoration: fee.ownFlg == 1
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: subjectTextColor(fee),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    buildLessonDatesText(index),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subjectTextColor(fee),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\$${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: subjectTextColor(fee),
                                  ),
                                ),
                                if (fee.ownFlg == 1 && isPaymentToday)
                                  SizedBox(
                                    width: 32,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.more_vert,
                                          size: 16),
                                      onPressed: () => showConfirmDialog(
                                          fee.lsnPayId,
                                          fee.lsnFeeId,
                                          fee.lsnMonth),
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
