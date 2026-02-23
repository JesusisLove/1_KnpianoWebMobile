import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../ApiConfig/KnApiConfig.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../CommonProcess/customUI/KnLoadingIndicator.dart';
import '../Constants.dart';
import '../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-18 添加主题扩展
import 'Kn02f005FeeMonthlyReportBean.dart';
import 'Kn02F003LsnPay.dart';
import 'Kn02F002FeeBean.dart';

class UnpaidFeesPage extends StatefulWidget {
  final String initialYearMonth;
  final List<String> availableMonths;
  final Color knBgColor;
  final Color knFontColor;
  final String pagePath;

  const UnpaidFeesPage({
    super.key,
    required this.initialYearMonth,
    required this.availableMonths,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  @override
  // ignore: library_private_types_in_public_api
  _UnpaidFeesPageState createState() => _UnpaidFeesPageState();
}

class _UnpaidFeesPageState extends State<UnpaidFeesPage>
    with SingleTickerProviderStateMixin {
  late String selectedYearMonth;
  List<Kn02f005FeeMonthlyReportBean> feeList = [];
  // 分组后的数据
  List<Kn02f005FeeMonthlyReportBean> unpaidFeeList = [];
  List<Kn02f005FeeMonthlyReportBean> paidFeeList = [];
  double totalUnpaid = 0;
  final String titleName = '未缴纳学费明细';
  late String pagePath;
  // 添加加载状态变量
  bool _isLoading = false;
  // 当前显示的月份
  String currentDisplayMonth = '';
  // 临时选择的月份索引
  int tempSelectedMonthIndex = 0;
  // Tab控制器
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    selectedYearMonth = widget.initialYearMonth;
    currentDisplayMonth =
        widget.availableMonths.contains(selectedYearMonth.substring(5))
            ? selectedYearMonth.substring(5)
            : widget.availableMonths.isNotEmpty
                ? widget.availableMonths[0]
                : '';
    pagePath = '${widget.pagePath} >> $titleName';

    // 初始化TabController，默认显示第1个tab（学费支付未完）
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);

    fetchFeeDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchFeeDetails() async {
    // 开始加载时设置状态
    setState(() {
      _isLoading = true;
    });

    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.apiFeeUnpaidReport}/$selectedYearMonth';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> jsonList = json.decode(decodedBody);
        if (mounted) {
          setState(() {
            feeList = jsonList
                .map((json) => Kn02f005FeeMonthlyReportBean.fromJson(json))
                .toList();
            // 分组数据
            _groupFeeData();
            calculateTotalUnpaid();
            // 数据加载完成，结束加载状态
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        throw Exception('Failed to load fee details');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  // 分组费用数据
  void _groupFeeData() {
    unpaidFeeList = feeList.where((fee) => fee.unpaidLsnFee > 0).toList();
    paidFeeList = feeList.where((fee) => fee.unpaidLsnFee <= 0).toList();
  }

  void calculateTotalUnpaid() {
    totalUnpaid = feeList.fold(0, (sum, fee) => sum + fee.unpaidLsnFee);
  }

  // 跳转到学费支付页面
  Future<void> _navigateToPaymentPage(Kn02f005FeeMonthlyReportBean fee) async {
    // 显示加载指示器 - 参照body中的写法
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: KnLoadingIndicator(
            color: widget.knBgColor,
          ),
        );
      },
    );

    try {
      // 构造targetYearMonth（yyyy-MM格式）
      // 从selectedYearMonth中提取年份（yyyy-MM格式中的前4个字符）
      final yearPart = selectedYearMonth.substring(0, 4);
      // 确保月份为两位数格式（添加前导零）
      final formattedMonth = currentDisplayMonth.padLeft(2, '0');
      final targetYearMonth = '$yearPart-$formattedMonth';

      // 构造API URL
      final String apiMonthlyLsnPaidAndUnpaidDetailUrl =
          '${KnConfig.apiBaseUrl}${Constants.apiStuFeeDetailByYearMonth}/${fee.stuId}/$targetYearMonth';

      // 发送API请求
      final response =
          await http.get(Uri.parse(apiMonthlyLsnPaidAndUnpaidDetailUrl));

      // 关闭加载指示器
      if (mounted) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> jsonList = json.decode(decodedBody);

        // 转换为List<Kn02F002FeeBean>
        List<Kn02F002FeeBean> monthData =
            jsonList.map((json) => Kn02F002FeeBean.fromJson(json)).toList();

        // 构造pagePath
        final stuName = fee.nikName.isNotEmpty ? fee.nikName : fee.stuName;
        final pagePath = '未缴纳学费明细>>$stuName $currentDisplayMonth月份学费账单';

        // 跳转到支付页面
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Kn02F003LsnPay(
                monthData: monthData,
                isAllPaid: false,
                knBgColor: widget.knBgColor,
                knFontColor: widget.knFontColor,
                pagePath: pagePath,
              ),
            ),
          );

          // 如果支付页面返回true，表示数据有变化，需要刷新
          if (result == true) {
            fetchFeeDetails(); // 重新获取学费数据
          }
        }
      } else {
        // API请求失败
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('获取学费详情失败: HTTP ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      // 关闭加载指示器
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取学费详情失败: $e')),
        );
      }
    }
  }

  // [Flutter页面主题改造] 2026-01-18 月份选择器字体跟随主题风格
  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
  void _showMonthPicker() {
    // 默认选中当前显示的月份
    tempSelectedMonthIndex =
        widget.availableMonths.indexOf(currentDisplayMonth);
    if (tempSelectedMonthIndex < 0) {
      tempSelectedMonthIndex = 0;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setPickerState) => Container(
          height: 250,
          padding: const EdgeInsets.only(bottom: 34), // 为底部安全区域留出空间
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: widget.knBgColor, // 使用与AppBar相同的背景色
                  border: const Border(
                    bottom: BorderSide(color: CupertinoColors.separator),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.all(0),
                      child: Text(
                        '取消',
                        style: KnPickerTextStyle.pickerButton(context,
                            color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Text(
                      '选择月份',
                      style: KnPickerTextStyle.pickerTitle(context,
                          color: Colors.white),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(0),
                      child: Text(
                        '确定',
                        style: KnPickerTextStyle.pickerButton(context,
                            color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // 确认选择后更新月份并获取数据
                        if (tempSelectedMonthIndex >= 0 &&
                            tempSelectedMonthIndex <
                                widget.availableMonths.length) {
                          setState(() {
                            currentDisplayMonth =
                                widget.availableMonths[tempSelectedMonthIndex];
                            selectedYearMonth =
                                '${selectedYearMonth.substring(0, 5)}$currentDisplayMonth';
                          });
                          // 获取新选择月份的数据
                          fetchFeeDetails();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: tempSelectedMonthIndex,
                  ),
                  children: widget.availableMonths.asMap().entries
                      .map((entry) => Text('${entry.value}月份',
                          style: entry.key == tempSelectedMonthIndex
                              ? KnPickerTextStyle.pickerItemSelected(context,
                                  fontSize: 18)
                              : KnPickerTextStyle.pickerItem(context,
                                  fontSize: 18)))
                      .toList(),
                  onSelectedItemChanged: (index) {
                    // 只记录临时选择的索引，不立即执行数据获取
                    setPickerState(() {
                      tempSelectedMonthIndex = index;
                    });
                  },
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
    // 检查是否有未支付记录来决定是否显示Tab
    bool hasUnpaidRecords = unpaidFeeList.isNotEmpty;

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
        addInvisibleRightButton: false, // 显示Home按钮返回主菜单
        currentNavIndex: 1,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
      ),
      body: _isLoading
          ? // 加载期间显示白色背景和进度条
          Container(
              color: Colors.white, // 白色背景
              child: Center(
                child: KnLoadingIndicator(
                  color: widget.knBgColor,
                ),
              ),
            )
          : // 数据加载完成后显示内容
          Column(
              children: [
                // 只有当有未支付记录时才显示Tab栏
                if (hasUnpaidRecords) ...[
                  // Tab栏 - 改进的设计
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // 改为白色背景
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                      border: Border(
                        bottom: BorderSide(
                            color: widget.knBgColor, width: 1), // 底边线使用背景色
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Text(
                              '学费支付完了',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Text(
                              '学费支付未完',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                      labelColor: widget.knBgColor, // 选中的标签文字颜色使用背景色
                      unselectedLabelColor: Colors.grey[600], // 未选中的标签文字颜色
                      indicatorColor: widget.knBgColor, // 指示器颜色使用背景色
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
                // 内容区域
                Expanded(
                  child: hasUnpaidRecords
                      ? TabBarView(
                          controller: _tabController,
                          children: [
                            // 学费支付完了的Tab
                            _buildFeeTabContent(paidFeeList, '没有已支付完成的记录',
                                isUnpaidTab: false),
                            // 学费支付未完的Tab
                            _buildFeeTabContent(unpaidFeeList, '没有未支付的记录',
                                isUnpaidTab: true),
                          ],
                        )
                      : _buildSingleFeeContent(), // 没有未支付记录时显示所有数据
                ),
                // 底部显示合计和月份选择按钮
                Column(
                  children: [
                    _buildTotalUnpaid(),
                    _buildMonthSelectionButton(),
                    const SizedBox(height: 34), // 为底部安全区域留出空间
                  ],
                ),
              ],
            ),
    );
  }

  // 构建Tab内容
  Widget _buildFeeTabContent(
      List<Kn02f005FeeMonthlyReportBean> dataList, String emptyMessage,
      {bool isUnpaidTab = false}) {
    if (dataList.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: [
        // 固定的表格标题头
        _buildTableHeader(),
        // 可滚动的数据内容
        Expanded(
          child: ListView.builder(
            itemCount: dataList.length,
            itemBuilder: (context, index) {
              return _buildTableRow(dataList[index], isUnpaidTab);
            },
          ),
        ),
      ],
    );
  }

  // 构建固定的表格标题头
  Widget _buildTableHeader() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                '学生姓名',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Container(width: 1, height: 56, color: Colors.grey.shade300),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                '应支付额',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Container(width: 1, height: 56, color: Colors.grey.shade300),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                '实支付额',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Container(width: 1, height: 56, color: Colors.grey.shade300),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                '未支付额',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建单行数据
  Widget _buildTableRow(Kn02f005FeeMonthlyReportBean fee, bool isClickable) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 1),
          right: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: isClickable
                ? InkWell(
                    onTap: () => _navigateToPaymentPage(fee),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Text(
                        fee.nikName.isNotEmpty == true
                            ? fee.nikName
                            : fee.stuName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                : Container(
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      fee.nikName.isNotEmpty == true
                          ? fee.nikName
                          : fee.stuName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
          ),
          Container(width: 1, height: 56, color: Colors.grey.shade300),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                fee.shouldPayLsnFee.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          Container(width: 1, height: 56, color: Colors.grey.shade300),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                fee.hasPaidLsnFee.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          Container(width: 1, height: 56, color: Colors.grey.shade300),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                fee.unpaidLsnFee.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fee.unpaidLsnFee > 0 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 没有未支付记录时显示的单一内容（原来的显示方式）
  Widget _buildSingleFeeContent() {
    if (feeList.isEmpty && !_isLoading) {
      return const Center(
        child: Text(
          '没有学费记录',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: [
        // 固定的表格标题头
        _buildTableHeader(),
        // 可滚动的数据内容
        Expanded(
          child: ListView.builder(
            itemCount: feeList.length,
            itemBuilder: (context, index) {
              return _buildTableRow(feeList[index], false); // 单一内容时不可点击
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalUnpaid() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerRight,
      child: Text(
        '未支付额合计: ${totalUnpaid.toStringAsFixed(1)}',
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 新的月份选择按钮，一个按钮撑满屏幕宽度，留出4像素间距
  Widget _buildMonthSelectionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // 左右各留4像素间距
      child: SizedBox(
        width: double.infinity, // 让按钮宽度撑满父容器
        height: 50, // 设置按钮高度
        child: ElevatedButton(
          onPressed: _showMonthPicker,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 232, 232, 232), // 浅灰色背景
            foregroundColor: Colors.black, // 文字颜色
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // 圆角
            ),
          ),
          child: Text(
            '$currentDisplayMonth月份',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
