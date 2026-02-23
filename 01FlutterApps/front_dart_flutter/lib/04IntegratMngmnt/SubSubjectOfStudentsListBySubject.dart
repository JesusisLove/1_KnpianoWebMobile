import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../ApiConfig/KnApiConfig.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../CommonProcess/customUI/KnLoadingIndicator.dart'; // 添加自定义加载指示器
import '../Constants.dart';
import '../03StuDocMngmnt/4stuDoc/Kn03D004StuDocBean.dart';
import '../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-18 添加主题扩展

class SubSubjectOfStudentsListBySubject extends StatefulWidget {
  final Color knBgColor;
  final Color knFontColor;
  final String pagePath;

  const SubSubjectOfStudentsListBySubject({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SubSubjectOfStudentsListBySubjectState createState() =>
      _SubSubjectOfStudentsListBySubjectState();
}

class _SubSubjectOfStudentsListBySubjectState
    extends State<SubSubjectOfStudentsListBySubject>
    with TickerProviderStateMixin {
  final String titleName = '正在学习该科目的学生';
  late String pagePath;

  // 科目列表相关
  List<Map<String, String>> subjectList = [];
  String? selectedSubjectId;
  String? selectedSubjectName;
  int tempSelectedIndex = 0;

  // Tab相关
  TabController? _tabController;
  List<String> subjectSubNames = [];
  int selectedTabIndex = 0;

  // 学生列表相关
  List<Kn03D004StuDocBean> studentList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    pagePath = '${widget.pagePath} >> $titleName';
    fetchSubjectList();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // 获取科目列表
  Future<void> fetchSubjectList() async {
    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.subjectEdaStuAll}';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> jsonList = json.decode(decodedBody);

        setState(() {
          subjectList = jsonList
              .map((json) => {
                    'subjectId': json['subjectId'].toString(),
                    'subjectName': json['subjectName'].toString(),
                  })
              .toList();

          if (subjectList.isNotEmpty) {
            selectedSubjectId = subjectList[0]['subjectId'];
            selectedSubjectName = subjectList[0]['subjectName'];
            fetchStudentsBySubject(selectedSubjectId!);
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching subject list: $e');
    }
  }

  // 获取指定科目的学生列表
  Future<void> fetchStudentsBySubject(String subjectId) async {
    if (isLoading) return;

    // 首先销毁现有的TabController
    _tabController?.dispose();
    _tabController = null;

    setState(() {
      isLoading = true;
      studentList = [];
      subjectSubNames = [];
      selectedTabIndex = 0;
    });

    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.subjectEdaStuBysub}/$subjectId';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> jsonList = json.decode(decodedBody);

        // 处理新数据
        final newStudentList =
            jsonList.map((json) => Kn03D004StuDocBean.fromJson(json)).toList();

        // 获取新的子科目名称列表（去重）
        final newSubjectSubNames = newStudentList
            .map((student) => student.subjectSubName)
            .toSet()
            .toList();

        if (mounted) {
          setState(() {
            studentList = newStudentList;
            subjectSubNames = newSubjectSubNames;
            selectedTabIndex = 0;

            // 创建新的TabController
            if (subjectSubNames.isNotEmpty) {
              _tabController = TabController(
                length: subjectSubNames.length,
                vsync: this,
              );
              _tabController!.addListener(() {
                if (mounted && !_tabController!.indexIsChanging) {
                  setState(() {
                    selectedTabIndex = _tabController!.index;
                  });
                }
              });
            }

            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 显示科目选择器
  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
  void _showSubjectPicker() {
    int localTempSelectedIndex = subjectList.indexWhere(
        (subject) => subject['subjectId'] == selectedSubjectId);
    if (localTempSelectedIndex < 0) localTempSelectedIndex = 0;
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
                  color: widget.knBgColor,
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
                        style: KnPickerTextStyle.pickerButton(context, color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Text(
                      '选择科目',
                      style: KnPickerTextStyle.pickerTitle(context, color: Colors.white),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(0),
                      child: Text(
                        '确定',
                        style: KnPickerTextStyle.pickerButton(context, color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          tempSelectedIndex = localTempSelectedIndex;
                          selectedSubjectId =
                              subjectList[tempSelectedIndex]['subjectId'];
                          selectedSubjectName =
                              subjectList[tempSelectedIndex]['subjectName'];
                        });
                        fetchStudentsBySubject(selectedSubjectId!);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: localTempSelectedIndex,
                  ),
                  children: subjectList.asMap().entries
                      .map((entry) => Center(
                          child: Text(entry.value['subjectName']!,
                              style: entry.key == localTempSelectedIndex
                                  ? KnPickerTextStyle.pickerItemSelected(context)
                                  : KnPickerTextStyle.pickerItem(context))))
                      .toList(),
                  onSelectedItemChanged: (index) {
                    setPickerState(() {
                      localTempSelectedIndex = index;
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

// 构建Tab栏 - 可滑动的两行显示版本
  Widget _buildTabs() {
    if (subjectSubNames.isEmpty) return Container();

    // 获取每个子科目的学生数量
    Map<String, int> subjectStudentCounts = {};
    for (var subName in subjectSubNames) {
      final studentsInSubject = studentList
          .where((student) => student.subjectSubName == subName)
          .toList();
      subjectStudentCounts[subName] = studentsInSubject.length;
    }

    return DefaultTabController(
      length: subjectSubNames.length,
      child: Container(
        height: 60, // 适当调整高度
        child: TabBar(
          controller: _tabController,
          isScrollable: true, // 确保可以滚动
          labelPadding: const EdgeInsets.symmetric(horizontal: 4), // 减小水平间距
          indicatorPadding: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          indicatorColor: Colors.transparent, // 移除下划线指示器
          tabAlignment: TabAlignment.start, // Tab从左侧开始对齐
          onTap: (index) {
            setState(() {
              selectedTabIndex = index;
            });
          },
          tabs: List.generate(subjectSubNames.length, (index) {
            final subName = subjectSubNames[index];
            // 提取年级信息
            String shortName = _getShortGradeName(subName);
            // 获取该子科目的学生数量
            int studentCount = subjectStudentCounts[subName] ?? 0;

            return Container(
              width: 80, // 固定宽度
              height: 40, // 控制高度，避免溢出
              decoration: BoxDecoration(
                color: index == selectedTabIndex ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 使Column尺寸最小化
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 第一行：年级简称
                    Text(
                      shortName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // 微小的间距
                    // 第二行：学生人数
                    Text(
                      '$studentCount人',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

// 改进的辅助方法：从"Grade0-Grade1"格式中提取"Grade0-1"
  String _getShortGradeName(String fullName) {
    // 处理特殊情况：如果是"DipAB-LR"这样的格式，直接返回
    if (!fullName.contains('Grade')) {
      return fullName;
    }

    // 处理"Grade0-Grade1"格式
    if (fullName.contains('-')) {
      List<String> parts = fullName.split('-');
      if (parts.length == 2) {
        String firstPart = parts[0].trim(); // 如"Grade0"
        String secondPart = parts[1].trim(); // 如"Grade1"

        // 从第一部分提取数字
        String firstNumber = "";
        if (firstPart.startsWith('Grade')) {
          firstNumber = firstPart.substring('Grade'.length);
        }

        // 从第二部分提取数字
        String secondNumber = "";
        if (secondPart.startsWith('Grade')) {
          secondNumber = secondPart.substring('Grade'.length);
        } else {
          secondNumber = secondPart;
        }

        // 返回简化的格式
        return 'Grade$firstNumber-$secondNumber';
      }
    }

    // 如果无法解析或格式不匹配，则返回原始名称
    return fullName;
  }

// 构建学生列表 - 对齐优化版本
  Widget _buildStudentList() {
    // 加载状态下不显示任何内容，由外层的Stack处理加载指示器
    if (isLoading) {
      return Container(); // 返回空容器，不显示任何提示信息
    }

    // 只有在非加载状态下，才检查是否有数据
    if (subjectSubNames.isEmpty || selectedTabIndex >= subjectSubNames.length) {
      return const Center(
        child: Text(
          '目前没有该科目下的学生列表信息！',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    final currentSubName = subjectSubNames[selectedTabIndex];
    final filteredStudents = studentList
        .where((student) => student.subjectSubName == currentSubName)
        .toList();

    if (filteredStudents.isEmpty) {
      return const Center(
        child: Text(
          '该子科目下暂无学生',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredStudents.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (context, index) {
        final student = filteredStudents[index];

        // 学费计算
        final monthlyFee = (student.lessonFeeAdjusted > 0
                ? student.lessonFeeAdjusted * 4
                : student.lessonFee * 4)
            .toStringAsFixed(1);

        return Container(
          color: index % 2 == 0 ? const Color(0xFFF5F5F5) : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              // 左侧：学生姓名
              Expanded(
                flex: 4,
                child: Text(
                  student.nikName.isNotEmpty
                      ? student.nikName
                      : student.stuName,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),

              // 右侧：收费类型和金额布局
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    // 收费类型（计/时）- 固定宽度的容器
                    Container(
                      width: 40, // 固定宽度
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: student.payStyle == 1
                              ? const Color(0xFFE3F2FD) // "计"使用蓝色背景
                              : const Color(0xFFE8F5E9), // "时"使用绿色背景
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          student.payStyle == 1 ? '计' : '时',
                          style: TextStyle(
                            color: student.payStyle == 1
                                ? Colors.blue.shade800
                                : Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    // 学费金额 - 固定宽度对齐
                    Container(
                      width: 100, // 固定宽度，确保所有金额对齐
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$monthlyFee/月',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 基准日
              Expanded(
                flex: 5,
                child: Text(
                  '基准日: ${student.adjustedDate}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建科目选择器按钮 - 修改后的版本
  Widget _buildSubjectPickerButton() {
    // 使用Padding包装，在左右两侧各添加4像素的间距
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // 左右各4像素的间距
      child: SizedBox(
        width: double.infinity, // 让按钮宽度撑满父容器
        height: 50, // 设置按钮高度
        child: ElevatedButton(
          onPressed: _showSubjectPicker,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 232, 232, 232), // 浅灰色背景
            foregroundColor: Colors.purple, // 紫色文字
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // 圆角
            ),
          ),
          child: Text(
            selectedSubjectName ?? '选择科目',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
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
        addInvisibleRightButton: true,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
      ),
      // 使用Stack布局显示加载遮罩
      body: Stack(
        children: [
          // 主内容
          Column(
            children: [
              Expanded(
                child: _buildStudentList(),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabs(),
                  _buildSubjectPickerButton(),
                  const SizedBox(height: 34), // 为底部安全区域留出空间
                ],
              ),
            ],
          ),
          // 加载指示器 - 仅在加载状态下显示
          if (isLoading)
            // 使用轻微的半透明背景，不会完全遮挡内容
            Opacity(
              opacity: 0.7,
              child: Container(
                color: Colors.grey[50], // 非常浅的背景
                child: Center(
                  child:
                      KnLoadingIndicator(color: widget.knBgColor), // 使用自定义加载指示器
                ),
              ),
            ),
        ],
      ),
    );
  }
}
