// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ApiConfig/KnApiConfig.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../CommonProcess/customUI/KnLoadingIndicator.dart';
import '../Constants.dart';
import '../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-18 添加主题扩展
import '../01LessonMngmnt/1LessonSchedual/kn01L002LsnStatistic.dart';
import '../01LessonMngmnt/1LessonSchedual/kn01L003ExtraToSche.dart';
import '../01LessonMngmnt/1LessonSchedual/kn01L003ExtraPiesesIntoOne.dart';

// Bean class for lesson counting data
class Kn04I003LsnCountingBean {
  final String stuId;
  final String stuName;
  final String subjectId;
  final String subjectName;
  final int payStyle;
  final double standartYearLsnCnt;
  final double totalLsnCnt0; // 按课时收费
  final double totalLsnCnt1; // 计划课
  final double totalLsnCnt2; // 加时课（整节加课课统计）
  final double totalLsnCnt3; // 加时课（零碎加课课统计

  Kn04I003LsnCountingBean({
    required this.stuId,
    required this.stuName,
    required this.subjectId,
    required this.subjectName,
    required this.payStyle,
    required this.standartYearLsnCnt,
    required this.totalLsnCnt0,
    required this.totalLsnCnt1,
    required this.totalLsnCnt2,
    required this.totalLsnCnt3,
  });

  factory Kn04I003LsnCountingBean.fromJson(Map<String, dynamic> json) {
    return Kn04I003LsnCountingBean(
      stuId: json['stuId'] as String? ?? '',
      stuName: json['stuName'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      payStyle: json['payStyle'] as int? ?? 0,
      standartYearLsnCnt: json['yearLsnCnt']?.toDouble() ?? 0.0,
      totalLsnCnt0: json['totalLsnCnt0']?.toDouble() ?? 0.0,
      totalLsnCnt1: json['totalLsnCnt1']?.toDouble() ?? 0.0,
      totalLsnCnt2: json['totalLsnCnt2']?.toDouble() ?? 0.0,
      totalLsnCnt3: json['totalLsnCnt3']?.toDouble() ?? 0.0,
    );
  }

  double get totalLessons => totalLsnCnt0 + totalLsnCnt1 + totalLsnCnt2;
}

class Kn04I003LsnCounting extends StatefulWidget {
  const Kn04I003LsnCounting({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  final Color knBgColor;
  final Color knFontColor;
  final String pagePath;

  @override
  // ignore: library_private_types_in_public_api
  _Kn04I003LsnCountingState createState() => _Kn04I003LsnCountingState();
}

class _Kn04I003LsnCountingState extends State<Kn04I003LsnCounting>
    with TickerProviderStateMixin {
  int selectedYear = DateTime.now().year;
  int selectedMonthFrom = 1;
  int selectedMonthTo = DateTime.now().month;

  List<int> years = Constants.generateYearList(); // 使用统一的年度列表生成方法
  List<int> months = List.generate(12, (index) => index + 1);

  List<Kn04I003LsnCountingBean> lessonCountingData = [];
  bool isLoading = true;
  final String titleName = '学生课程统计';
  late String pagePath;

  // 搜索功能相关
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Tab 控制器
  TabController? _tabController;

  // final double maxLessons = 43.0; // 满课时数

  @override
  void initState() {
    super.initState();
    pagePath = '${widget.pagePath} >> $titleName';
    // 页面初始加载 - 调用第一个API
    loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  // 判断学生是否满课时
  bool _isFullLesson(Kn04I003LsnCountingBean student) {
    return student.totalLsnCnt1 >= student.standartYearLsnCnt &&
        student.payStyle == 1;
  }

  // 判断是否需要显示 Tab（基于后台返回的 lessonCountingData）
  bool get _shouldShowTabs {
    return lessonCountingData.any((student) => _isFullLesson(student));
  }

  // 获取满课时学生列表
  List<Kn04I003LsnCountingBean> get _fullLessonStudents {
    return lessonCountingData
        .where((student) => _isFullLesson(student))
        .toList();
  }

  // 获取未满课时学生列表
  List<Kn04I003LsnCountingBean> get _notFullLessonStudents {
    return lessonCountingData
        .where((student) => !_isFullLesson(student))
        .toList();
  }

  // 过滤学生数据（无 Tab 时使用）
  List<Kn04I003LsnCountingBean> get filteredLessonData {
    if (_searchQuery.isEmpty) {
      return lessonCountingData;
    }
    return lessonCountingData.where((student) {
      return student.stuName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // 过滤满课时学生（在 Tab 内搜索）
  List<Kn04I003LsnCountingBean> get _filteredFullLessonStudents {
    final fullStudents = _fullLessonStudents;
    if (_searchQuery.isEmpty) {
      return fullStudents;
    }
    return fullStudents.where((student) {
      return student.stuName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // 过滤未满课时学生（在 Tab 内搜索）
  List<Kn04I003LsnCountingBean> get _filteredNotFullLessonStudents {
    final notFullStudents = _notFullLessonStudents;
    if (_searchQuery.isEmpty) {
      return notFullStudents;
    }
    return notFullStudents.where((student) {
      return student.stuName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // 管理 TabController 的创建和销毁
  void _manageTabController() {
    if (_shouldShowTabs) {
      // 需要显示 Tab
      if (_tabController == null) {
        // 创建新的 TabController
        _tabController = TabController(length: 2, vsync: this);
      }
    } else {
      // 不需要显示 Tab
      if (_tabController != null) {
        // 销毁现有的 TabController
        _tabController!.dispose();
        _tabController = null;
      }
    }
  }

  // 页面初始加载数据 - 使用 /mb_kn_lsn_counting
  Future<void> loadInitialData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.intergLsnCounting}';
      // print('Loading initial data from: $apiUrl');

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> jsonData = json.decode(decodedBody);

        setState(() {
          lessonCountingData = jsonData
              .map((json) => Kn04I003LsnCountingBean.fromJson(json))
              .toList();
          isLoading = false;

          // 根据后台返回的数据管理 TabController（在 setState 内部调用）
          _manageTabController();
        });

        // print('Initial data loaded: ${lessonCountingData.length} records');
      } else {
        throw Exception('Failed to load initial data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading initial data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 用户筛选查询 - 使用 /mb_kn_lsn_counting_search/{year}/{monthFrom}/{monthTo}
  Future<void> searchWithFilters() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.intergLsnCountingSearch}'
          '/$selectedYear'
          '/${selectedMonthFrom.toString().padLeft(2, '0')}'
          '/${selectedMonthTo.toString().padLeft(2, '0')}';

      print('Searching with filters: $apiUrl');

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> jsonData = json.decode(decodedBody);

        setState(() {
          lessonCountingData = jsonData
              .map((json) => Kn04I003LsnCountingBean.fromJson(json))
              .toList();
          isLoading = false;

          // 根据后台返回的数据管理 TabController（在 setState 内部调用）
          _manageTabController();
        });

        // print('Search completed: ${lessonCountingData.length} records');
      } else {
        throw Exception('Failed to search data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 显示搜索对话框
  /// [Flutter页面主题改造] 2026-01-20 对话框标题和按钮字体跟随主题风格
  /// [Flutter页面主题改造] 2026-01-21 文本框边框颜色跟随模块主题
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('搜索学生',
            style: KnElementTextStyle.dialogTitle(context,
                color: widget.knBgColor)),
        content: TextField(
          controller: _searchController,
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
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
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
        leftBalanceCount: 1, // [Flutter页面主题改造] 2026-01-19 添加左侧平衡使标题居中
        currentNavIndex: 3,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: widget.knFontColor),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildLegend(),
          Expanded(
            child: isLoading
                ? Center(
                    child: KnLoadingIndicator(color: widget.knBgColor),
                  )
                : _buildLessonChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Text(
            '$selectedYear年度课程统计报表',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFilterItem(
                  '统计年度',
                  '$selectedYear年',
                  () => _showYearPicker(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterItem(
                  '开始月份',
                  '${selectedMonthFrom.toString().padLeft(2, '0')}月',
                  () => _showMonthPicker(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterItem(
                  '结束月份',
                  '${selectedMonthTo.toString().padLeft(2, '0')}月',
                  () => _showMonthPicker(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: widget.knBgColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.knBgColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.knBgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('课时课', Colors.green),
          _buildLegendItem('计划课', widget.knBgColor),
          _buildLegendItem('加时课', Colors.pink),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonChart() {
    // 如果后台返回的数据为空
    if (lessonCountingData.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 根据后台返回的数据判断是否需要显示 Tab
    if (_shouldShowTabs && _tabController != null) {
      // 显示 Tab 分组
      return Column(
        children: [
          // TabBar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: widget.knBgColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: widget.knBgColor,
              indicatorWeight: 3,
              tabs: [
                Tab(text: '✅🏆满课时 (${_fullLessonStudents.length})'),
                const Tab(text: '未满课时'),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 满课时学生列表
                _buildStudentList(_filteredFullLessonStudents),
                // 未满课时学生列表
                _buildStudentList(_filteredNotFullLessonStudents),
              ],
            ),
          ),
        ],
      );
    }

    // 不显示 Tab，显示全部学生列表
    return _buildStudentList(filteredLessonData);
  }

  // 构建学生列表
  Widget _buildStudentList(List<Kn04I003LsnCountingBean> displayData) {
    // 如果搜索后无结果
    if (displayData.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到匹配的学生',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请尝试其他关键词',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 显示搜索结果计数
        if (_searchQuery.isNotEmpty)
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
                  '找到 ${displayData.length} 名学生',
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
            itemCount: displayData.length,
            itemBuilder: (context, index) {
              final item = displayData[index];
              return _buildStudentLessonCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentLessonCard(Kn04I003LsnCountingBean item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：学生姓名、科目、总计、完成度
            Row(
              children: [
                // 学生姓名（可点击跳转到课程进度统计页面）
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () {
                      // 跳转到课程进度统计页面
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Kn01L002LsnStatistic(
                            stuId: item.stuId,
                            stuName: item.stuName,
                            knBgColor: Constants.lessonThemeColor,
                            knFontColor: Colors.white,
                            pagePath: "综合管理 >> 学生课程统计",
                            selectedYear: selectedYear,
                          ),
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        children: [
                          // 如果计划总课时达到43节,显示🏆图标
                          if (item.totalLsnCnt1 >= item.standartYearLsnCnt &&
                              item.payStyle == 1)
                            const TextSpan(
                              text: '✅🏆',
                              style: TextStyle(fontSize: 16),
                            ),
                          // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                          TextSpan(
                            text: item.stuName,
                            style: KnElementTextStyle.cardTitle(
                              context,
                              fontSize: 16,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 科目标签
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.knBgColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.subjectName,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.knBgColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 总计
                Text(
                  '总计: ${item.totalLessons.toStringAsFixed(1)}节',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                // 计划总课时
                Text(
                  '计划: ${item.standartYearLsnCnt == 0 ? 43 : item.standartYearLsnCnt.toStringAsFixed(1)}节',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                // 完成度
                Text(
                  '完成度: ${((item.totalLsnCnt1 / (item.standartYearLsnCnt == 0 ? 43 : item.standartYearLsnCnt)) * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.totalLsnCnt1 >=
                            (item.standartYearLsnCnt == 0
                                ? 43
                                : item.standartYearLsnCnt)
                        ? Colors.green
                        : widget.knBgColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 课程进度条
            if (item.totalLsnCnt0 > 0)
              _buildLessonBar(
                  '时费课',
                  item.totalLsnCnt0,
                  (item.standartYearLsnCnt == 0 ? 43 : item.standartYearLsnCnt),
                  Colors.green),
            if (item.totalLsnCnt1 > 0)
              _buildLessonBar(
                  '计划课',
                  item.totalLsnCnt1,
                  (item.standartYearLsnCnt == 0 ? 43 : item.standartYearLsnCnt),
                  widget.knBgColor),
            if (item.totalLsnCnt2 > 0)
              _buildLessonBar(
                '加时课',
                item.totalLsnCnt2,
                (item.standartYearLsnCnt == 0 ? 43 : item.standartYearLsnCnt),
                Colors.pink,
                onTap: () {
                  // 跳转到加课消化管理页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExtraToSchePage(
                        stuId: item.stuId,
                        stuName: item.stuName,
                        knBgColor: widget.knBgColor,
                        knFontColor: widget.knFontColor,
                        pagePath: pagePath,
                        selectedYear: selectedYear,
                      ),
                    ),
                  );
                },
              ),
            if (item.totalLsnCnt3 > 0)
              _buildLessonBar(
                '零碎课',
                item.totalLsnCnt3,
                (item.standartYearLsnCnt == 0 ? 43 : item.standartYearLsnCnt),
                Colors.pink,
                onTap: () {
                  // 跳转到零碎加课拼整课页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Kn01L003ExtraPiesesIntoOne(
                        stuId: item.stuId,
                        stuName: item.stuName,
                        knBgColor: widget.knBgColor,
                        knFontColor: widget.knFontColor,
                        pagePath: pagePath,
                        selectedYear: selectedYear,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonBar(
      String label, double count, double maxLessons, Color color,
      {VoidCallback? onTap}) {
    double barWidth = (count / maxLessons).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧：课程标签（固定宽度）
          SizedBox(
            width: 40,
            child: onTap != null
                ? GestureDetector(
                    onTap: onTap,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
          ),
          const SizedBox(width: 2),
          // 中间：进度条（自动伸缩填充）
          Expanded(
            child: Container(
              height: 8,
              child: Stack(
                children: [
                  // 底层：白色进度条（固定长度，代表满额课时）
                  Container(
                    width: double.infinity,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 0.5,
                      ),
                    ),
                  ),
                  // 上层：彩色进度条
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: barWidth,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          // 右侧：课时标签（固定宽度）
          SizedBox(
            width: 42,
            child: Text(
              '${count.toStringAsFixed(1)}节',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [Flutter页面主题改造] 2026-01-18 年度选择器字体跟随主题风格
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
                decoration: BoxDecoration(
                  color: widget.knBgColor, // 添加背景颜色
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      child: Text(
                        '取消',
                        style: KnPickerTextStyle.pickerButton(context,
                            color: Colors.white),
                      ),
                    ),
                    Text(
                      '选择年度',
                      style: KnPickerTextStyle.pickerTitle(context,
                          color: Colors.white),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // 用户选择后进行筛选查询
                        searchWithFilters();
                      },
                      padding: EdgeInsets.zero,
                      child: Text(
                        '确定',
                        style: KnPickerTextStyle.pickerButton(context,
                            color: Colors.white),
                      ),
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
                  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
                  children: years.asMap().entries
                      .map((entry) => Center(
                          child: Text('${entry.value}年',
                              style: entry.key == tempSelectedIndex
                                  ? KnPickerTextStyle.pickerItemSelected(context,
                                      color: context.getModuleColor('summary').primary)
                                  : KnPickerTextStyle.pickerItem(context,
                                      color: context.getModuleColor('summary').primary))))
                      .toList(),
                  onSelectedItemChanged: (int index) {
                    setPickerState(() {
                      tempSelectedIndex = index;
                    });
                    setState(() {
                      selectedYear = years[index];

                      // 🔧 2026-01-09 新增：年度变化时自动调整结束月份
                      // 如果选择年 < 当前年，结束月自动切换为12月
                      // 如果选择年 = 当前年，结束月自动切换为当前月
                      int systemYear = DateTime.now().year;
                      int systemMonth = DateTime.now().month;

                      if (selectedYear < systemYear) {
                        selectedMonthTo = 12;
                      } else if (selectedYear == systemYear) {
                        selectedMonthTo = systemMonth;
                      }
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

  // [Flutter页面主题改造] 2026-01-18 月份选择器字体跟随主题风格
  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
  void _showMonthPicker(BuildContext context, bool isFromMonth) {
    int currentMonth = isFromMonth ? selectedMonthFrom : selectedMonthTo;
    int tempSelectedIndex = currentMonth - 1;

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
                decoration: BoxDecoration(
                  color: widget.knBgColor, // 添加背景颜色
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      child: Text(
                        '取消',
                        style: KnPickerTextStyle.pickerButton(context,
                            color: Colors.white),
                      ),
                    ),
                    Text(
                      isFromMonth ? '选择开始月份' : '选择结束月份',
                      style: KnPickerTextStyle.pickerTitle(context,
                          color: Colors.white),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // 用户选择后进行筛选查询
                        searchWithFilters();
                      },
                      padding: EdgeInsets.zero,
                      child: Text(
                        '确定',
                        style: KnPickerTextStyle.pickerButton(context,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  itemExtent: 40,
                  scrollController:
                      FixedExtentScrollController(initialItem: tempSelectedIndex),
                  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
                  children: months.asMap().entries
                      .map((entry) => Center(
                          child: Text('${entry.value.toString().padLeft(2, '0')}月',
                              style: entry.key == tempSelectedIndex
                                  ? KnPickerTextStyle.pickerItemSelected(context,
                                      color: context.getModuleColor('summary').primary)
                                  : KnPickerTextStyle.pickerItem(context,
                                      color: context.getModuleColor('summary').primary))))
                      .toList(),
                  onSelectedItemChanged: (int index) {
                    setPickerState(() {
                      tempSelectedIndex = index;
                    });
                    setState(() {
                      if (isFromMonth) {
                        selectedMonthFrom = months[index];
                      } else {
                        selectedMonthTo = months[index];
                      }
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
}
