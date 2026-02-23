// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../ApiConfig/KnApiConfig.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../Constants.dart';
import '../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-18 添加主题扩展
import 'Kn02F002FeeBean.dart';
import 'Kn02F003AdvcLsnFeePayPage.dart';
import 'Kn02F004AdvcLsnFeePayPerLsnPage.dart';
import 'Kn02F003LsnPay.dart';
import '../CommonProcess/customUI/KnLoadingIndicator.dart';

// ignore: must_be_immutable
class LsnFeeDetail extends StatefulWidget {
  LsnFeeDetail({
    super.key,
    required this.stuId,
    required this.stuName,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
    required this.selectedYear,
  });
  final String stuId;
  final String stuName;
  // AppBar背景颜色
  final Color knBgColor;
  // 字体颜色
  final Color knFontColor;
  // 画面迁移路径：例如，上课进度管理>>学生姓名一览>> xxx的课程进度状况
  late String pagePath;
  final int selectedYear;

  @override
  _LsnFeeDetailState createState() => _LsnFeeDetailState();
}

class _LsnFeeDetailState extends State<LsnFeeDetail> {
  final String titleName = '课程费用详细';
  late int selectedYear;
  late List<int> years;
  late TextEditingController _stuNameController;
  int stuFeeDetailCount = 0;
  final ValueNotifier<List<Kn02F002FeeBean>> stuFeeDetailNotifier =
      ValueNotifier([]);
  // 添加一个加载状态变量
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    years = Constants.generateYearList(); // 使用统一的年度列表生成方法
    selectedYear = widget.selectedYear; // 使用传递过来的年度参数
    _stuNameController = TextEditingController(text: widget.stuName);
    widget.pagePath = '${widget.pagePath} >> $titleName';
    fetchFeeDetails();
  }

  @override
  void dispose() {
    _stuNameController.dispose();
    super.dispose();
  }

  // 该学生已支付和未支付的账单信息
  Future<void> fetchFeeDetails() async {
    // 开始加载时设置加载状态为true
    setState(() {
      _isLoading = true;
    });
    try {
      final String apiLsnPaidAndUnpaidDetailUrl =
          '${KnConfig.apiBaseUrl}${Constants.apiStuFeeDetailByYear}/${widget.stuId}/$selectedYear';
      final responseFeeDetails =
          await http.get(Uri.parse(apiLsnPaidAndUnpaidDetailUrl));
      if (responseFeeDetails.statusCode == 200) {
        final decodedBody = utf8.decode(responseFeeDetails.bodyBytes);
        List<dynamic> stuDocJson = json.decode(decodedBody);
        setState(() {
          stuFeeDetailNotifier.value =
              stuDocJson.map((json) => Kn02F002FeeBean.fromJson(json)).toList();
          stuFeeDetailCount = stuFeeDetailNotifier.value.length;
          // 数据加载完成，设置加载状态为false
          _isLoading = false;
        });
      } else {
        // 错误处理
        setState(() {
          _isLoading = false; // 即使发生错误也要结束加载状态
        });
        throw Exception('Failed to load archived students');
      }
    } catch (e) {
      // 错误处理
      setState(() {
        _isLoading = false; // 确保任何异常情况下都会结束加载状态
      });
      // 可以在这里添加错误提示逻辑
    }
  }

  // [Flutter页面主题改造] 2026-01-18 年份选择器字体跟随主题风格
  // [Flutter页面主题改造] 2026-01-19 修复取消/确定按钮字体颜色不一致问题
  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
  void _showYearPicker() {
    int tempSelectedIndex = years.indexOf(selectedYear);
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
                              color: Colors.white)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text('选择年份',
                        style: KnPickerTextStyle.pickerTitle(context,
                            color: Colors.white, fontSize: 14)),
                    CupertinoButton(
                      child: Text('确定',
                          style: KnPickerTextStyle.pickerButton(context,
                              color: Colors.white)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        // 确定按钮点击后立即调用获取数据方法
                        fetchFeeDetails();
                      },
                    ),
                  ],
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
                          child: Text('${entry.value}年',
                              style: entry.key == tempSelectedIndex
                                  ? KnPickerTextStyle.pickerItemSelected(context,
                                      color: widget.knBgColor, fontSize: 18)
                                  : KnPickerTextStyle.pickerItem(context,
                                      color: widget.knBgColor, fontSize: 18))))
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
        addInvisibleRightButton: false,
        leftBalanceCount: 1, // [Flutter页面主题改造] 2026-01-19 添加左侧平衡使标题居中
        currentNavIndex: 1,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: widget.knFontColor),
            onSelected: (String result) async {
              if (result == 'prepay') {
                final bool? success = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Kn02F003AdvcLsnFeePayPage(
                              stuId: widget.stuId,
                              stuName: widget.stuName,
                              knBgColor: widget.knBgColor,
                              knFontColor: widget.knFontColor,
                              pagePath: widget.pagePath,
                              selectedYear: selectedYear,
                            )));
                if (success == true) {
                  fetchFeeDetails();
                }
              } else if (result == 'prepay_per_lsn') {
                final bool? success = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Kn02F004AdvcLsnFeePayPerLsnPage(
                              stuId: widget.stuId,
                              stuName: widget.stuName,
                              knBgColor: widget.knBgColor,
                              knFontColor: widget.knFontColor,
                              pagePath: widget.pagePath,
                              selectedYear: selectedYear,
                            )));
                if (success == true) {
                  fetchFeeDetails();
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'prepay',
                child: Text('预支付学费（按月）'),
              ),
              const PopupMenuItem<String>(
                value: 'prepay_per_lsn',
                child: Text('预支付学费（按课时）'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _stuNameController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: '学生姓名',
                        labelStyle: TextStyle(color: widget.knBgColor),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: widget.knBgColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: widget.knBgColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: widget.knBgColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // [Flutter页面主题改造] 2026-01-21 增加按钮宽度，确保年度文字完整显示
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _showYearPicker,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: widget.knFontColor,
                        backgroundColor: widget.knBgColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text('$selectedYear年'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? KnLoadingIndicator(color: widget.knBgColor)
                : ValueListenableBuilder<List<Kn02F002FeeBean>>(
                    valueListenable: stuFeeDetailNotifier,
                    builder: (context, feeDetailList, child) {
                      // if (feeDetailList.isEmpty) {
                      //   return const Center(child: Text('No fee details available'));
                      // }
                      final months = feeDetailList
                          .map((detail) => detail.month)
                          .where((month) => month > 0)
                          .toSet()
                          .toList()
                        ..sort();

                      return ListView.builder(
                        itemCount: months.length,
                        itemBuilder: (context, index) {
                          final month = months[index];
                          final monthData = feeDetailList
                              .where((detail) => detail.month == month)
                              .toList();
                          monthData.first.stuId = widget.stuId;
                          monthData.first.stuName = widget.stuName;
                          // 修改：传递fetchFeeDetails函数给MonthLineItem
                          return MonthLineItem(
                            month: month,
                            monthData: monthData,
                            fetchFeeDetails: fetchFeeDetails,
                            pagePath: widget.pagePath,
                            knBgColor: widget.knBgColor,
                            knFontColor: widget.knFontColor,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// 修改：MonthLineItem类的定义，添加fetchFeeDetails参数
class MonthLineItem extends StatelessWidget {
  final int month;
  final List<Kn02F002FeeBean> monthData;
  final Future<void> Function() fetchFeeDetails;
  final String pagePath;
  final Color knBgColor;
  final Color knFontColor;

  const MonthLineItem({
    super.key,
    required this.month,
    required this.monthData,
    required this.fetchFeeDetails,
    required this.pagePath,
    required this.knBgColor,
    required this.knFontColor,
  });

  @override
  Widget build(BuildContext context) {
    double totalFee = monthData.fold(0, (sum, item) => sum + item.lsnFee);
    final currentMonth = DateTime.now().month;
    final bool isAdvancePay = monthData.any((item) => item.advcFlg == 0);
    bool isAllPaid = monthData.every((item) => item.ownFlg == 1);

    Color monthColor = month < currentMonth
        ? Colors.grey
        : (month == currentMonth ? Colors.green : knBgColor);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: knBgColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$month月',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: monthColor,
                  ),
                ),
                Text(
                  '课费总计: \$${totalFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: knBgColor,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (String result) {
                    if (result == 'record' || result == 'view') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Kn02F003LsnPay(
                            monthData: monthData,
                            isAllPaid: isAllPaid,
                            knBgColor: knBgColor,
                            knFontColor: knFontColor,
                            pagePath: pagePath,
                          ),
                        ),
                      ).then((value) {
                        fetchFeeDetails();
                      });
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    if (!isAllPaid)
                      const PopupMenuItem<String>(
                        value: 'record',
                        child: Text('学费记账'),
                      ),
                    if (isAllPaid)
                      const PopupMenuItem<String>(
                        value: 'view',
                        child: Text('学费查看'),
                      ),
                  ],
                  icon: Icon(Icons.more_vert, color: knBgColor),
                ),
              ],
            ),
          ),
          ...monthData.map((item) => _buildLessonItem(item, isAdvancePay)),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: knBgColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已支付: \$${monthData.where((item) => item.ownFlg == 1).fold(0.0, (sum, item) => sum + item.lsnPay).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  '未支付: \$${(monthData.fold(0.0, (sum, item) => sum + item.lsnFee) - monthData.fold(0.0, (sum, item) => sum + item.lsnPay)).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(Kn02F002FeeBean item, bool isAdvancePay) {
    String lessonTypeText = '';
    String lsnFeeText = '时课费';
    switch (item.lessonType) {
      case 0:
        lessonTypeText = '课结算';
        break;
      case 1:
        lessonTypeText = '月计划';
        lsnFeeText = '月课费';
        break;
      case 2:
        lessonTypeText = '月加课';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.subjectName} - $lessonTypeText',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.ownFlg == 1 ? Colors.grey : knBgColor,
                          decoration: item.ownFlg == 1
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    // 如果有支付日期且不为空，显示支付日期和银行名称
                    if (item.payDate != null && item.payDate!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 10), // 设置10像素的间距
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '支付日期: ${item.payDate}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (item.bankName.isNotEmpty)
                              Text(
                                '银行名称: ${item.bankName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(
                  '课时: ${item.lsnCount}节  $lsnFeeText：\$${item.lessonType == 1 ? (item.subjectPrice! * 4).toStringAsFixed(2) : item.lsnFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: item.ownFlg == 1 ? Colors.grey : Colors.black87,
                    decoration: item.ownFlg == 1
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          if (item.advcFlg == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: knBgColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '预付费',
                style: TextStyle(
                  fontSize: 12,
                  color: knBgColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LessonCount {
  final double monthRegular;
  final double monthPlan;
  final double monthExtra;

  LessonCount({
    required this.monthRegular,
    required this.monthPlan,
    required this.monthExtra,
  });
}
