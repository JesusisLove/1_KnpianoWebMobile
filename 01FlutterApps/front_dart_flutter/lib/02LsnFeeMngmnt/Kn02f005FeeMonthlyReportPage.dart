// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ApiConfig/KnApiConfig.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../CommonProcess/customUI/KnDialog.dart';
import '../CommonProcess/customUI/KnLoadingIndicator.dart';
import '../CommonProcess/KnMsg.dart';
import '../Constants.dart';
import '../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-18 添加主题扩展
import 'Kn02f005FeeMonthlyUnpaidPage.dart';
import 'Kn02f005FeeMonthlyReportBean.dart';
import 'Kn02F002FeeBean.dart';

class MonthlyIncomeReportPage extends StatefulWidget {
  const MonthlyIncomeReportPage({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  // AppBar背景颜色
  final Color knBgColor;
  // 字体颜色
  final Color knFontColor;
  // 画面迁移路径
  final String pagePath;

  @override
  _MonthlyIncomeReportPageState createState() =>
      _MonthlyIncomeReportPageState();
}

class _MonthlyIncomeReportPageState extends State<MonthlyIncomeReportPage>
    with SingleTickerProviderStateMixin {
  int selectedYear = DateTime.now().year;
  List<int> years = Constants.generateYearList();

  // 收入报告数据
  List<Kn02f005FeeMonthlyReportBean> monthlyReports = [];
  double totalShouldPay = 0;
  double totalHasPaid = 0;
  double totalBadDebt = 0;
  double totalUnpaid = 0;
  bool isLoading = true;

  // 坏账一览数据
  List<Kn02F002FeeBean> badDebtList = [];
  bool isBadDebtLoading = true;

  late TabController _tabController;
  final String titleName = '学费月度报告';
  late String pagePath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    pagePath = '${widget.pagePath} >> $titleName';
    fetchMonthlyReport();
    fetchBadDebtList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchMonthlyReport() async {
    setState(() {
      isLoading = true;
    });
    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.apiFeeMonthlyReport}/$selectedYear';
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> jsonData = json.decode(decodedBody);
        setState(() {
          monthlyReports = jsonData
              .map((json) => Kn02f005FeeMonthlyReportBean.fromJson(json))
              .toList();
          isLoading = false;
          calculateTotals();
        });
      } else {
        throw Exception('Failed to load monthly report');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchBadDebtList() async {
    setState(() {
      isBadDebtLoading = true;
    });
    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.apiBadDebtList}/$selectedYear';
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = json.decode(decodedBody);
        setState(() {
          badDebtList =
              jsonList.map((e) => Kn02F002FeeBean.fromJson(e)).toList();
          isBadDebtLoading = false;
          calculateTotals();
        });
      } else {
        setState(() {
          isBadDebtLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isBadDebtLoading = false;
      });
    }
  }

  void calculateTotals() {
    totalShouldPay =
        monthlyReports.fold(0, (sum, item) => sum + item.shouldPayLsnFee);
    totalHasPaid =
        monthlyReports.fold(0, (sum, item) => sum + item.hasPaidLsnFee);
    totalBadDebt =
        badDebtList.fold(0.0, (sum, item) => sum + item.lsnFee);
    totalUnpaid = totalShouldPay - totalHasPaid - totalBadDebt;
  }

  List<String> collectMonths() {
    return monthlyReports
        .map((report) => report.lsnMonth.substring(5, 7))
        .toSet()
        .toList()
      ..sort();
  }

  // 按学生姓名分组坏账列表
  Map<String, List<Kn02F002FeeBean>> _groupByStu() {
    final Map<String, List<Kn02F002FeeBean>> grouped = {};
    for (final item in badDebtList) {
      grouped.putIfAbsent(item.stuName, () => []).add(item);
    }
    return grouped;
  }

  Future<void> _undoBadDebt(Kn02F002FeeBean item) async {
    // B类：撤销坏账确认对话框（B-18）
    KnDialog.showConfirm(
      context, widget.knBgColor, widget.knFontColor,
      KnMsg.i.titleBadDebtUndoConfirm,
      KnMsg.i.confirmBadDebtUndo
          .replaceFirst('%s', item.stuName)
          .replaceFirst('%s', item.subjectName)
          .replaceFirst('%s', item.lsnMonth),
      onConfirm: () async {
        final url =
            '${KnConfig.apiBaseUrl}${Constants.apiBadDebtUndo}/${item.lsnFeeId}';
        final res = await http.put(Uri.parse(url));
        if (res.statusCode == 200 && mounted) {
          // D类：撤销坏账成功 SnackBar（D-17）
          KnDialog.showSnackBar(
            context,
            KnMsg.i.snackBadDebtUndo,
            type: KnSnackType.success,
          );
          fetchBadDebtList();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
        title: titleName,
        subtitle: pagePath,
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
        currentNavIndex: 1,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
      ),
      body: Column(
        children: [
          // 标题（Tab外，两个Tab共用）
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '$selectedYear年度月收入报告',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // Tab切换栏
          TabBar(
            controller: _tabController,
            labelColor: widget.knBgColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: widget.knBgColor,
            tabs: [
              const Tab(text: '收入报告'),
              Tab(text: '坏账一览(${badDebtList.length})'),
            ],
          ),
          // 内容区（随Tab切换）
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab① 收入报告
                Column(
                  children: [
                    _buildTableHeader(),
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: KnLoadingIndicator(
                                color: widget.knBgColor,
                              ),
                            )
                          : _buildIncomeList(),
                    ),
                  ],
                ),
                // Tab② 坏账一览
                _buildBadDebtContent(),
              ],
            ),
          ),
          // 底部固定区域（四项汇总 + 年度选择器，Tab外共用）
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: const Row(
        children: [
          Expanded(
              flex: 1,
              child:
                  Text('月份', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child:
                  Text('应收入', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child:
                  Text('实收入', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('平账结果',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildIncomeList() {
    return ListView.builder(
      itemCount: monthlyReports.length,
      itemBuilder: (context, index) {
        var item = monthlyReports[index];
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            title: Row(
              children: [
                Expanded(flex: 1, child: Text(item.lsnMonth.substring(5, 7))),
                Expanded(
                    flex: 2,
                    child:
                        Text(item.shouldPayLsnFee.toStringAsFixed(1))),
                Expanded(
                    flex: 2,
                    child: Text(item.hasPaidLsnFee.toStringAsFixed(1))),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.unpaidLsnFee.toStringAsFixed(1)}欠',
                          style: const TextStyle(color: Colors.red)),
                      IconButton(
                        icon: const Icon(Icons.info_outline,
                            color: Colors.blue),
                        onPressed: () =>
                            _navigateToUnpaidFeesPage(context, item.lsnMonth),
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

  void _navigateToUnpaidFeesPage(BuildContext context, String month) {
    String yearMonth = '$selectedYear-${month.substring(5, 7)}';
    List<String> availableMonths = collectMonths();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnpaidFeesPage(
          initialYearMonth: yearMonth,
          availableMonths: availableMonths,
          knBgColor: Constants.lsnfeeThemeColor,
          knFontColor: Colors.white,
          pagePath: "学费月度报告",
        ),
      ),
    );
  }

  // Tab② 坏账一览内容
  Widget _buildBadDebtContent() {
    if (isBadDebtLoading) {
      return Center(child: KnLoadingIndicator(color: widget.knBgColor));
    }

    final grouped = _groupByStu();

    if (badDebtList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text(
              '$selectedYear年 暂无坏账记录',
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final stuName = grouped.keys.elementAt(index);
        final items = grouped[stuName]!;
        return _buildStudentSection(stuName, items);
      },
    );
  }

  Widget _buildStudentSection(String stuName, List<Kn02F002FeeBean> items) {
    final double stuTotal = items.fold(0.0, (sum, item) => sum + item.lsnFee);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 学生姓名标题栏
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    Text(
                      stuName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                Text(
                  '小计：¥${stuTotal.toStringAsFixed(0)}',
                  style:
                      TextStyle(fontSize: 13, color: Colors.orange.shade800),
                ),
              ],
            ),
          ),
          // 各条坏账记录
          ...items.map((item) => _buildBadDebtItem(item)),
        ],
      ),
    );
  }

  Widget _buildBadDebtItem(Kn02F002FeeBean item) {
    String lessonTypeText;
    switch (item.lessonType) {
      case 0:
        lessonTypeText = '课结算';
        break;
      case 1:
        lessonTypeText = '月计划';
        break;
      case 2:
        lessonTypeText = '月加课';
        break;
      default:
        lessonTypeText = '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.subjectName}  ·  $lessonTypeText',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '月份: ${item.lsnMonth}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  '¥${item.lsnFee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (item.memo != null && item.memo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '理由：${item.memo}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.deepOrange),
                  ),
                ],
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 课程详情按钮
              TextButton.icon(
                onPressed: () => _showDetailDialog(item),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('详情', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              // 撤销坏账按钮
              TextButton.icon(
                onPressed: () => _undoBadDebt(item),
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('撤销坏账', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 课程详情对话框：调用API获取该课费对应的所有课程记录
  Future<void> _showDetailDialog(Kn02F002FeeBean item) async {
    // 先弹出加载中对话框，返回关闭函数
    final dismiss = KnDialog.showLoading(
        context, widget.knBgColor, widget.knFontColor, '正在加载课程详情...');

    List<Kn02F002FeeBean> details = [];
    try {
      final url =
          '${KnConfig.apiBaseUrl}${Constants.apiBadDebtDetail}/${item.lsnFeeId}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final decoded = utf8.decode(res.bodyBytes);
        final List<dynamic> jsonList = json.decode(decoded);
        details = jsonList.map((e) => Kn02F002FeeBean.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore
    }

    if (!mounted) return;
    dismiss(); // 关闭加载中对话框

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 标题栏 ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.knBgColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long,
                        color: widget.knFontColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '坏账对应课程记录（${details.length}件）',
                      style: TextStyle(
                        color: widget.knFontColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // ── 内容区 ──
              Flexible(
                child: details.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('暂无课程记录'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shrinkWrap: true,
                        itemCount: details.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        itemBuilder: (context, index) {
                          final d = details[index];
                          final bool isExtra = d.extra2ScheFlg == 1;
                          // 原始签到日期（计划课的签到日期，或换正课前的加课签到日期）
                          final String originalDate =
                              d.payDate != null && d.payDate!.isNotEmpty
                                  ? d.payDate!
                                  : '-';
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 科目名 + 子科目名 + 换正课标签
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        d.subjectSubName != null &&
                                                d.subjectSubName!.isNotEmpty
                                            ? '${d.subjectName}  ·  ${d.subjectSubName}'
                                            : d.subjectName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                    ),
                                    if (isExtra) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '换正课',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange.shade800),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 签到日期（普通课）或 原签到日期 + 换正课日期（换正课）
                                if (!isExtra)
                                  Text(
                                    '签到日期：$originalDate',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  )
                                else ...[
                                  Text(
                                    '原签到日期：$originalDate',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                  Text(
                                    '换正课日期：${d.newScanqrDate != null ? d.newScanqrDate!.substring(0, 10) : '-'}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                // 课费单价
                                Text(
                                  '单价：¥${(d.subjectPrice ?? 0).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              // ── 关闭按钮 ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child:
                        Text('关闭', style: TextStyle(color: widget.knBgColor)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTotalAmounts(),
          const SizedBox(height: 10),
          _buildYearPicker(),
        ],
      ),
    );
  }

  Widget _buildTotalAmounts() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('应支付总额：'),
            Text(totalShouldPay.toStringAsFixed(2)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('已支付总额：'),
            Text(totalHasPaid.toStringAsFixed(2)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('坏账总额：'),
            Text(
              totalBadDebt.toStringAsFixed(2),
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('未支付总额：'),
            Text(
              totalUnpaid.toStringAsFixed(2),
              style: TextStyle(
                color: totalUnpaid > 0 ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearPicker() {
    return GestureDetector(
      onTap: () => _showYearPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.lightBlue[100],
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
            child: Text('$selectedYear年',
                style: const TextStyle(fontSize: 18))),
      ),
    );
  }

  // [Flutter页面主题改造] 2026-01-18 年度选择器字体跟随主题风格
  // [Flutter页面主题改造] 2026-01-19 修复标题区域主题颜色丢失问题
  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
  void _showYearPicker(BuildContext context) {
    int tempSelectedIndex = years.indexOf(selectedYear);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setPickerState) => Container(
          height: 350,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: widget.knBgColor),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      child: Text('取消',
                          style: KnPickerTextStyle.pickerButton(context,
                              color: Colors.white)),
                    ),
                    Text(
                      '选择年度',
                      style: KnPickerTextStyle.pickerTitle(context,
                          color: Colors.white),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // 年度变更时同时刷新两个Tab的数据
                        fetchMonthlyReport();
                        fetchBadDebtList();
                      },
                      padding: EdgeInsets.zero,
                      child: Text('确定',
                          style: KnPickerTextStyle.pickerButton(context,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                      initialItem: tempSelectedIndex),
                  children: years
                      .asMap()
                      .entries
                      .map((entry) => Center(
                          child: Text('${entry.value}年',
                              style: entry.key == tempSelectedIndex
                                  ? KnPickerTextStyle.pickerItemSelected(
                                      context,
                                      color: widget.knBgColor)
                                  : KnPickerTextStyle.pickerItem(context,
                                      color: widget.knBgColor))))
                      .toList(),
                  onSelectedItemChanged: (int index) {
                    setPickerState(() {
                      tempSelectedIndex = index;
                    });
                    setState(() => selectedYear = years[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
