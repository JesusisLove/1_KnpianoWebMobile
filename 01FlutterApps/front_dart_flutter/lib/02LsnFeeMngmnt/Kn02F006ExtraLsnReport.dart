// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../ApiConfig/KnApiConfig.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../CommonProcess/customUI/KnLoadingIndicator.dart';
import '../Constants.dart';
import '../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-18 添加主题扩展
import '../01LessonMngmnt/1LessonSchedual/Kn01L003LsnExtraBean.dart';
import '../01LessonMngmnt/1LessonSchedual/kn01L003ExtraToSche.dart';

/// 单科目加课统计数据
class ExtraLsnStats {
  int paidCount = 0; // 已支付课数
  int unpaidCount = 0; // 未支付课数
  int convertedCount = 0; // 已转换课数

  String get displayText => '$paidCount / $unpaidCount / $convertedCount';

  bool get hasData => paidCount > 0 || unpaidCount > 0 || convertedCount > 0;
}

/// 学生加课统计报告
class StudentExtraReport {
  final String stuId;
  final String stuName;
  final Map<String, ExtraLsnStats> subjectStats;

  StudentExtraReport({
    required this.stuId,
    required this.stuName,
    required this.subjectStats,
  });
}

// ignore: must_be_immutable
class Kn02F006ExtraLsnReport extends StatefulWidget {
  Kn02F006ExtraLsnReport({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;

  @override
  _Kn02F006ExtraLsnReportState createState() => _Kn02F006ExtraLsnReportState();
}

class _Kn02F006ExtraLsnReportState extends State<Kn02F006ExtraLsnReport> {
  final String titleName = '加课处理报告';

  // 年度选择
  int selectedYear = DateTime.now().year;
  List<int> years = Constants.generateYearList(); // 使用统一的年度列表生成方法

  // 数据存储
  List<Kn01L003LsnExtraBean> allExtraLessons = [];
  Map<String, StudentExtraReport> studentReports = {};

  // 搜索功能
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  // 加载状态
  bool isLoading = true;

  // 过滤条件
  bool filterPaid = false;      // 过滤已支付 > 0
  bool filterUnpaid = false;    // 过滤未支付 > 0
  bool filterConverted = false; // 过滤已转换 > 0

  // 颜色定义
  final Color paidColor = const Color(0xFF1E88E5); // 蓝色
  final Color paidBgColor = const Color(0xFFE3F2FD);
  final Color unpaidColor = const Color(0xFFE91E63); // 粉色
  final Color unpaidBgColor = const Color(0xFFFCE4EC);
  final Color convertedColor = const Color(0xFF4CAF50); // 绿色
  final Color convertedBgColor = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    widget.pagePath = '${widget.pagePath} >> $titleName';
    loadExtraLessonData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// 加载加课数据（优化版：一次性获取所有学生数据）
  Future<void> loadExtraLessonData() async {
    setState(() => isLoading = true);

    try {
      // 一次性获取所有学生的加课数据（stuId传特殊标识符"ALL"）
      const String stuId = 'ALL'; // 特殊标识符，后端检测到"ALL"时不添加学生过滤条件
      final String extraUrl =
          '${KnConfig.apiBaseUrl}${Constants.extraToScheView}/$stuId/$selectedYear';

      // print('🔍 请求URL: $extraUrl'); // 调试日志
      // print('🔍 stuId: "$stuId"');
      // print('🔍 selectedYear: $selectedYear');

      final extraResponse = await http.get(Uri.parse(extraUrl));

      if (extraResponse.statusCode != 200) {
        throw Exception('获取加课数据失败');
      }

      final decodedExtra = utf8.decode(extraResponse.bodyBytes);
      List<dynamic> extras = json.decode(decodedExtra);

      allExtraLessons =
          extras.map((e) => Kn01L003LsnExtraBean.fromJson(e)).toList();

      // 处理数据分组统计
      processExtraLessonData();

      setState(() => isLoading = false);
    } catch (e) {
      print('加载失败: $e');
      setState(() => isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('错误'),
              content: Text('数据加载失败: $e'),
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
  }

  /// 处理数据分组统计
  void processExtraLessonData() {
    studentReports = {};

    // 按学生ID分组
    Map<String, List<Kn01L003LsnExtraBean>> groupedByStudent = {};
    for (var lesson in allExtraLessons) {
      groupedByStudent.putIfAbsent(lesson.stuId, () => []).add(lesson);
      // ❌ 不再收集 allSubjects（只显示有数据的科目）
    }

    // 为每个学生统计各科目的数据
    groupedByStudent.forEach((stuId, lessons) {
      Map<String, ExtraLsnStats> subjectStats = {};

      // 按科目分组统计
      for (var lesson in lessons) {
        if (!subjectStats.containsKey(lesson.subjectName)) {
          subjectStats[lesson.subjectName] = ExtraLsnStats();
        }

        var stats = subjectStats[lesson.subjectName]!;

        // 判定逻辑（来自 kn01L003ExtraToSche.dart）
        if (lesson.extraToDurDate.isEmpty && lesson.payFlg == 1) {
          stats.paidCount++; // 已支付
        } else if (lesson.extraToDurDate.isEmpty && lesson.payFlg == 0) {
          stats.unpaidCount++; // 未支付
        } else if (lesson.extraToDurDate.isNotEmpty) {
          stats.convertedCount++; // 已转换
        }
      }

      studentReports[stuId] = StudentExtraReport(
        stuId: stuId,
        stuName: lessons.first.stuName,
        subjectStats: subjectStats,
      );
    });
  }

  /// 过滤后的学生列表
  List<StudentExtraReport> get filteredStudents {
    List<StudentExtraReport> students = studentReports.values.toList();

    // 1. 应用过滤条件（基于科目级别的统计）
    if (filterPaid || filterUnpaid || filterConverted) {
      students = students.map((student) {
        // 过滤每个学生的科目，只保留符合条件的科目
        Map<String, ExtraLsnStats> filteredSubjects = {};

        student.subjectStats.forEach((subjectName, stats) {
          bool matchPaid = !filterPaid || stats.paidCount > 0;
          bool matchUnpaid = !filterUnpaid || stats.unpaidCount > 0;
          bool matchConverted = !filterConverted || stats.convertedCount > 0;

          // AND逻辑：所有选中的条件都必须满足
          if (matchPaid && matchUnpaid && matchConverted) {
            filteredSubjects[subjectName] = stats;
          }
        });

        // 创建新的StudentExtraReport，只包含符合条件的科目
        return StudentExtraReport(
          stuId: student.stuId,
          stuName: student.stuName,
          subjectStats: filteredSubjects,
        );
      }).where((student) => student.subjectStats.isNotEmpty).toList();
      // 移除没有符合条件科目的学生
    }

    // 2. 应用搜索过滤
    if (searchQuery.isNotEmpty) {
      students = students
          .where((student) =>
              student.stuName.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // 3. 排序
    students.sort((a, b) => a.stuName.compareTo(b.stuName));

    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
        title: titleName,
        subtitle: widget.pagePath,
        context: context,
        appBarBackgroundColor: widget.knBgColor,
        titleColor: Color.fromARGB(
          widget.knFontColor.alpha,
          widget.knFontColor.red - 20,
          widget.knFontColor.green - 20,
          widget.knFontColor.blue - 20,
        ),
        // [Flutter页面主题改造] 2026-01-26 副标题背景使用主题色的深色版本
        subtitleBackgroundColor: Color.fromARGB(
          widget.knBgColor.alpha,
          (widget.knBgColor.red * 0.6).round(),
          (widget.knBgColor.green * 0.6).round(),
          (widget.knBgColor.blue * 0.6).round(),
        ),
        subtitleTextColor: Colors.white,
        addInvisibleRightButton: false,
        leftBalanceCount: 1, // [Flutter页面主题改造] 2026-01-19 添加左侧平衡使标题居中
        currentNavIndex: 1,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: widget.knFontColor),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildLegend(),
          Expanded(
            child: isLoading
                ? Center(child: KnLoadingIndicator(color: widget.knBgColor))
                : _buildStudentList(),
          ),
        ],
      ),
    );
  }

  /// 构建筛选区域（年度选择和统计信息）
  Widget _buildFilterSection() {
    // 计算统计信息
    final students = filteredStudents;
    final studentCount = students.length;
    final subjectCount = students.fold<int>(
      0,
      (sum, student) => sum + student.subjectStats.length,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：统计信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '学生人数: $studentCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '科目个数: $subjectCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // 右侧：年度选择器
          GestureDetector(
            onTap: () => _showYearPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: widget.knBgColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.knBgColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, color: widget.knBgColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$selectedYear年',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.knBgColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: widget.knBgColor, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建图例说明
  Widget _buildLegend() {
    // 判断是否有任何过滤条件
    final hasAnyFilter = filterPaid || filterUnpaid || filterConverted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(
            '已支付',
            paidColor,
            Icons.credit_card,
            isActive: !hasAnyFilter || filterPaid,
          ),
          _buildLegendItem(
            '未支付',
            unpaidColor,
            Icons.pending,
            isActive: !hasAnyFilter || filterUnpaid,
          ),
          _buildLegendItem(
            '已转换',
            convertedColor,
            Icons.swap_horiz,
            isActive: !hasAnyFilter || filterConverted,
          ),
          // 过滤按钮
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: hasAnyFilter ? widget.knBgColor : Colors.grey[600],
            ),
            onPressed: _showFilterDialog,
            tooltip: '过滤',
          ),
        ],
      ),
    );
  }

  /// 构建单个图例项
  Widget _buildLegendItem(
    String label,
    Color color,
    IconData icon, {
    required bool isActive,
  }) {
    // 如果不活跃，使用灰色；否则使用原色
    final displayColor = isActive ? color : Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: displayColor, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: displayColor)),
      ],
    );
  }

  /// 构建学生列表
  Widget _buildStudentList() {
    final students = filteredStudents;

    if (students.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '没有找到匹配的学生',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '$selectedYear年度暂无加课数据',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 搜索结果计数
        if (searchQuery.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.knBgColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.knBgColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.knBgColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '找到 ${students.length} 名学生',
                  style: TextStyle(
                    color: widget.knBgColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return _buildStudentCard(students[index]);
            },
          ),
        ),
      ],
    );
  }

  /// 构建学生卡片
  Widget _buildStudentCard(StudentExtraReport student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToExtraToSchePage(student),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 学生姓名行
              Row(
                children: [
                  Icon(Icons.person, color: widget.knBgColor),
                  const SizedBox(width: 8),
                  Text(
                    student.stuName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
              const Divider(height: 20),

              // 科目统计行（只显示有加课记录的科目）
              ...student.subjectStats.entries.map((entry) {
                return _buildSubjectRow(entry.key, entry.value);
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建科目统计行
  Widget _buildSubjectRow(String subjectName, ExtraLsnStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // 科目名称
          SizedBox(
            width: 80,
            child: Text(
              subjectName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),

          // 已支付（蓝色）
          Expanded(
            child: _buildStatChip(
              label: '已支付',
              count: stats.paidCount,
              color: paidColor,
              bgColor: paidBgColor,
            ),
          ),
          const SizedBox(width: 8),

          // 未支付（粉色）
          Expanded(
            child: _buildStatChip(
              label: '未支付',
              count: stats.unpaidCount,
              color: unpaidColor,
              bgColor: unpaidBgColor,
            ),
          ),
          const SizedBox(width: 8),

          // 已转换（绿色）
          Expanded(
            child: _buildStatChip(
              label: '已转换',
              count: stats.convertedCount,
              color: convertedColor,
              bgColor: convertedBgColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计数字卡片
  Widget _buildStatChip({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
          Text(
            '$count节',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// [Flutter页面主题改造] 2026-01-18 年度选择器字体跟随主题风格
  /// [Flutter页面主题改造] 2026-01-20 选中项粗体显示
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
                        loadExtraLessonData(); // 重新加载数据
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
                  children: years.asMap().entries
                      .map((entry) => Center(
                            child: Text(
                              '${entry.value}年',
                              style: entry.key == tempSelectedIndex
                                  ? KnPickerTextStyle.pickerItemSelected(context,
                                      color: widget.knBgColor)
                                  : KnPickerTextStyle.pickerItem(context,
                                      color: widget.knBgColor),
                            ),
                          ))
                      .toList(),
                  onSelectedItemChanged: (index) {
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

  /// 显示搜索对话框
  /// [Flutter页面主题改造] 2026-01-20 对话框标题和按钮字体跟随主题风格
  // [Flutter页面主题改造] 2026-01-21 文本框边框颜色跟随模块主题
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('搜索学生',
            style: KnElementTextStyle.dialogTitle(context,
                color: widget.knBgColor)),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: '请输入学生姓名',
            prefixIcon: Icon(Icons.search, color: widget.knBgColor),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.knBgColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.knBgColor, width: 2),
            ),
          ),
          autofocus: true,
          onChanged: (value) {
            setState(() => searchQuery = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = '';
                searchController.clear();
              });
              Navigator.pop(context);
            },
            child: Text('清除',
                style: KnElementTextStyle.buttonText(context,
                    color: widget.knBgColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定',
                style: KnElementTextStyle.buttonText(context,
                    color: widget.knBgColor)),
          ),
        ],
      ),
    );
  }

  /// 显示过滤对话框
  /// [Flutter页面主题改造] 2026-01-20 对话框标题和按钮字体跟随主题风格
  void _showFilterDialog() {
    // 临时变量存储对话框内的选择状态
    bool tempPaid = filterPaid;
    bool tempUnpaid = filterUnpaid;
    bool tempConverted = filterConverted;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('选择过滤条件',
                style: KnElementTextStyle.dialogTitle(context,
                    color: widget.knBgColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(Icons.credit_card, color: paidColor, size: 20),
                      const SizedBox(width: 8),
                      const Text('已支付 > 0'),
                    ],
                  ),
                  value: tempPaid,
                  onChanged: (value) {
                    setDialogState(() => tempPaid = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(Icons.pending, color: unpaidColor, size: 20),
                      const SizedBox(width: 8),
                      const Text('未支付 > 0'),
                    ],
                  ),
                  value: tempUnpaid,
                  onChanged: (value) {
                    setDialogState(() => tempUnpaid = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: convertedColor, size: 20),
                      const SizedBox(width: 8),
                      const Text('已转换 > 0'),
                    ],
                  ),
                  value: tempConverted,
                  onChanged: (value) {
                    setDialogState(() => tempConverted = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('取消',
                    style: KnElementTextStyle.buttonText(context,
                        color: widget.knBgColor)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    filterPaid = tempPaid;
                    filterUnpaid = tempUnpaid;
                    filterConverted = tempConverted;
                  });
                  Navigator.pop(context);
                },
                child: Text('确定',
                    style: KnElementTextStyle.buttonText(context,
                        color: widget.knBgColor)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 跳转到加课消化管理页面
  void _navigateToExtraToSchePage(StudentExtraReport student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExtraToSchePage(
          stuId: student.stuId,
          stuName: student.stuName,
          knBgColor: widget.knBgColor,
          knFontColor: widget.knFontColor,
          pagePath: widget.pagePath,
          selectedYear: selectedYear,
        ),
      ),
    );
  }
}
