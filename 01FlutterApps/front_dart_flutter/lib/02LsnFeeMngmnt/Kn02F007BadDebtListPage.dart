import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../ApiConfig/KnApiConfig.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../CommonProcess/customUI/KnLoadingIndicator.dart';
import '../Constants.dart';
import '../theme/theme_extensions.dart';
import 'Kn02F002FeeBean.dart';
import '../CommonProcess/customUI/KnDialog.dart';
import '../CommonProcess/KnMsg.dart';

class Kn02F007BadDebtListPage extends StatefulWidget {
  const Kn02F007BadDebtListPage({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  final Color knBgColor;
  final Color knFontColor;
  final String pagePath;

  @override
  State<Kn02F007BadDebtListPage> createState() =>
      _Kn02F007BadDebtListPageState();
}

class _Kn02F007BadDebtListPageState extends State<Kn02F007BadDebtListPage> {
  int selectedYear = DateTime.now().year;
  final List<int> years = Constants.generateYearList();
  List<Kn02F002FeeBean> badDebtList = [];
  bool isLoading = true;
  final String titleName = '坏账一览';
  late String pagePath;

  @override
  void initState() {
    super.initState();
    pagePath = '${widget.pagePath} >> $titleName';
    fetchBadDebtList();
  }

  Future<void> fetchBadDebtList() async {
    setState(() {
      isLoading = true;
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
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _undoBadDebt(Kn02F002FeeBean item) {
    KnDialog.showConfirm(
      context,
      widget.knBgColor,
      widget.knFontColor,
      KnMsg.i.titleBadDebtUndoConfirm,
      KnMsg.i.confirmBadDebtUndo
          .replaceFirst('%s', item.stuName)
          .replaceFirst('%s', item.subjectName)
          .replaceFirst('%s', item.lsnMonth),
      onConfirm: () async {
        final url =
            '${KnConfig.apiBaseUrl}${Constants.apiBadDebtUndo}'
            '/${item.lsnFeeId}';
        final res = await http.put(Uri.parse(url));
        if (res.statusCode == 200 && mounted) {
          KnDialog.showSnackBar(context, KnMsg.i.snackBadDebtUndo,
              type: KnSnackType.success);
          fetchBadDebtList();
        }
      },
    );
  }

  // 按学生姓名分组
  Map<String, List<Kn02F002FeeBean>> _groupByStu() {
    final Map<String, List<Kn02F002FeeBean>> grouped = {};
    for (final item in badDebtList) {
      grouped.putIfAbsent(item.stuName, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    // 统计
    final int totalCount = badDebtList.length;
    final double totalAmount =
        badDebtList.fold(0.0, (sum, item) => sum + item.lsnFee);

    final grouped = _groupByStu();

    return Scaffold(
      appBar: KnAppBar(
        title: titleName,
        subtitle: pagePath,
        context: context,
        moduleName: 'fee',
        currentNavIndex: 1,
      ),
      body: isLoading
          ? KnLoadingIndicator(color: widget.knBgColor)
          : Column(
              children: [
                // 顶部信息栏（年度选择器 + 坏账统计）
                _buildTopBar(totalCount, totalAmount),
                // 列表
                Expanded(
                  child: badDebtList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 64, color: Colors.green.shade300),
                              const SizedBox(height: 16),
                              Text(
                                '$selectedYear年 暂无坏账记录',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: grouped.keys.length,
                          itemBuilder: (context, index) {
                            final stuName = grouped.keys.elementAt(index);
                            final items = grouped[stuName]!;
                            return _buildStudentSection(stuName, items);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTopBar(int totalCount, double totalAmount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: widget.knBgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.knBgColor.withOpacity(0.2)),
      ),
      child: SizedBox(
        height: 30,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: widget.knBgColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '坏账合计：$totalCount 笔  /  ¥${totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: widget.knBgColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
            // 年度选择按钮
            GestureDetector(
              onTap: () => _showYearPicker(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: widget.knBgColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: widget.knBgColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today,
                        color: widget.knBgColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$selectedYear年',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.knBgColor,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down,
                        color: widget.knBgColor, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildStudentSection(
      String stuName, List<Kn02F002FeeBean> items) {
    final double stuTotal =
        items.fold(0.0, (sum, item) => sum + item.lsnFee);
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
                    Icon(Icons.person,
                        size: 18, color: Colors.orange.shade800),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade800,
                  ),
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
                // 坏账理由
                if (item.memo != null && item.memo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '理由：${item.memo}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.deepOrange),
                  ),
                ],
              ],
            ),
          ),
          // 课程详情按钮
          TextButton.icon(
            onPressed: () => _showDetailDialog(item),
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('详情', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blueGrey,
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
    );
  }

  // 课程详情对话框：点击月份后弹出
  void _showDetailDialog(Kn02F002FeeBean item) {
    final bool isExtra2Sche = item.extra2ScheFlg == 1;
    final String dateLabel = isExtra2Sche ? '换正课日期' : '签到日期';
    final String dateValue = isExtra2Sche
        ? (item.newScanqrDate ?? '-')
        : (item.payDate != null && item.payDate!.isNotEmpty ? item.payDate! : '-');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.knBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: widget.knFontColor, size: 18),
              const SizedBox(width: 8),
              Text(
                '课程详情',
                style: TextStyle(
                  color: widget.knFontColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow('科目名称', item.subjectName),
            if (item.subjectSubName != null && item.subjectSubName!.isNotEmpty)
              _detailRow('子科目', item.subjectSubName!),
            _detailRow('课费', '¥${item.lsnFee.toStringAsFixed(0)}'),
            _detailRow(dateLabel, dateValue),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭', style: TextStyle(color: widget.knBgColor)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
