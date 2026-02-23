// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart'; // 导入自定义加载指示器
import '../../Constants.dart';
import 'package:http/http.dart' as http;
import 'StudentLeaveBean.dart';
import 'StudentLeaveSettingPage.dart';
import 'dart:convert';
import 'dart:async'; // 新增导入
import '../../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-20 添加主题扩展

// ignore: must_be_immutable
class StudentLeaveListPage extends StatefulWidget {
  // AppBar背景颜色
  final Color knBgColor;
  // 字体颜色
  final Color knFontColor;
  // 画面迁移路径：例如，上课进度管理>>学生姓名一览>> xxx的课程进度状况
  late String pagePath;
  StudentLeaveListPage(
      {super.key,
      required this.knBgColor,
      required this.knFontColor,
      required this.pagePath});

  @override
  // ignore: library_private_types_in_public_api
  _StudentLeaveListPageState createState() => _StudentLeaveListPageState();
}

class _StudentLeaveListPageState extends State<StudentLeaveListPage> {
  final String titleName = '学生休学退学名单';
  final ValueNotifier<List<StudentLeaveBean>> stuOffLsnNotifier =
      ValueNotifier([]);
  int stuInfoCount = 0;
  List<StudentLeaveBean> students = [];
  bool _isLoading = false; // 修改加载状态标志
  bool _showDeleteButtons = false; // 控制删除按钮显示的状态
  bool _isDataLoaded = false; // 数据是否已加载完成
  String _searchQuery = ''; // 搜索关键词
  final TextEditingController _searchController = TextEditingController(); // 搜索输入控制器
  final Map<String, bool> _expandedYears = {}; // 年度ボックスの開閉状態

  @override
  void initState() {
    super.initState();
    fetchStuOffLsnInfo();
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

  // 过滤学生列表
  List<StudentLeaveBean> get filteredStudents {
    if (_searchQuery.isEmpty) {
      return students;
    }
    return students.where((student) {
      final name = student.nikName.isNotEmpty ? student.nikName : student.stuName;
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // 按退学年度分组（年度降序，同年度内按退学日升序，不明は末尾）
  Map<String, List<StudentLeaveBean>> get _groupedByYear {
    final map = <String, List<StudentLeaveBean>>{};
    for (final s in filteredStudents) {
      final year = s.quitDate.length >= 4 ? s.quitDate.substring(0, 4) : '不明';
      map.putIfAbsent(year, () => []).add(s);
    }
    // 同年度内：按退学日升序（早退学的在前）
    for (final list in map.values) {
      list.sort((a, b) => a.quitDate.compareTo(b.quitDate));
    }
    // 年度降序，不明末尾
    return Map.fromEntries(
      map.entries.toList()
        ..sort((a, b) {
          if (a.key == '不明') return 1;
          if (b.key == '不明') return -1;
          return b.key.compareTo(a.key);
        }),
    );
  }

  @override
  void dispose() {
    stuOffLsnNotifier.dispose(); // 释放资源
    _searchController.dispose(); // 释放搜索控制器
    super.dispose();
  }

  Future<void> fetchStuOffLsnInfo() async {
    if (!mounted) return; // 检查组件是否仍然挂载
    setState(() {
      _isLoading = true; // 开始加载数据
    });

    try {
      final String apiStuQuitLsnUrl =
          '${KnConfig.apiBaseUrl}${Constants.intergStuQuitLsn}';
      final responseFeeDetails = await http.get(Uri.parse(apiStuQuitLsnUrl));

      if (!mounted) return; // 再次检查，因为网络请求可能耗时

      if (responseFeeDetails.statusCode == 200) {
        final decodedBody = utf8.decode(responseFeeDetails.bodyBytes);
        List<dynamic> studentLeaveJson = json.decode(decodedBody);
        setState(() {
          stuOffLsnNotifier.value = studentLeaveJson
              .map((json) => StudentLeaveBean.fromJson(json))
              .toList();
          stuInfoCount = stuOffLsnNotifier.value.length;
          students = stuOffLsnNotifier.value;
          _isDataLoaded = true; // 数据加载完成
          _isLoading = false; // 加载状态结束
        });
      } else {
        throw Exception('Failed to load archived students');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; // 出错时也要设置加载完成
        });
        // 显示错误信息给用户
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // 切换删除按钮显示状态的方法
  void toggleDeleteButtons() {
    setState(() {
      _showDeleteButtons = !_showDeleteButtons;
    });
  }

  // 处理学生退学的方法
  Future<void> handleStudentReturn(String stuId) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true; // 开始处理操作
    });

    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.intergStuReturnExecute}/$stuId';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false; // 操作完成
      });

      if (response.statusCode == 200) {
        // 请求成功，刷新页面
        await fetchStuOffLsnInfo();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('学生已成功复学'),
            backgroundColor: widget.knBgColor,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        // 请求失败，显示错误信息
        throw Exception('Failed to process student return');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; // 确保出错时也重置加载状态
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 格式化日期字符串，只保留yyyy-mm-dd部分
  String formatDate(String dateString) {
    if (dateString.isEmpty) return '暂无日期'; // 如果为空，显示提示文字
    // 如果日期字符串包含时间部分，只取日期部分
    if (dateString.contains(' ')) {
      return dateString.split(' ')[0];
    }
    // 如果日期字符串长度超过10个字符，只取前10个字符（yyyy-mm-dd）
    if (dateString.length > 10) {
      return dateString.substring(0, 10);
    }
    return dateString;
  }

  // 构建添加按钮
  Widget _buildAddButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.maxWidth;
        return GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StudentLeaveSettingPage(
                              knBgColor: Constants.ingergThemeColor,
                              knFontColor: Colors.white,
                              pagePath: '${widget.pagePath} >> $titleName',
                            )),
                  ).then((value) {
                    if (value == true) {
                      fetchStuOffLsnInfo();
                    }
                  });
                },
          child: Container(
            width: size,
            height: size, // 和学生卡片一样的正方形
            decoration: BoxDecoration(
              color: Colors.grey[300], // 添加按钮用浅灰色背景
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.knBgColor,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add,
                color: _isLoading ? Colors.grey : widget.knBgColor,
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentCard(StudentLeaveBean student) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用LayoutBuilder确保正方形
        double size = constraints.maxWidth;
        return Container(
          width: size,
          height: size, // 强制高度等于宽度，确保正方形
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white, // 背景改为白色
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.knBgColor, // 边框保持紫色
              width: 0.4,
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 学生姓名 - 第一行，加大加粗，强制居中
                  Center(
                    child: Text(
                      student.nikName.isNotEmpty
                          ? student.nikName
                          : student.stuName,
                      style: TextStyle(
                        color: widget.knBgColor, // 文字改为紫色
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 入学日期 - 第二行，强制居中
                  Center(
                    child: Text(
                      formatDate(student.enterDate),
                      style: TextStyle(
                        color: widget.knBgColor, // 文字改为紫色
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 退学日期 - 第三行，强制居中
                  Center(
                    child: Text(
                      formatDate(student.quitDate),
                      style: TextStyle(
                        color: widget.knBgColor, // 文字改为紫色
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // 删除按钮
              if (_showDeleteButtons && !_isLoading)
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      handleStudentReturn(student.stuId);
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 构建年度折叠盒子
  Widget _buildYearBox(String year, List<StudentLeaveBean> yearStudents) {
    final isExpanded = _searchQuery.isNotEmpty || (_expandedYears[year] ?? false);
    final yearLabel = year == '不明' ? '不明' : '$year年';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // 年度ヘッダー（タップで開閉）
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedYears[year] = !(_expandedYears[year] ?? false);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.knBgColor,
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      )
                    : BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '$yearLabel  (${yearStudents.length}名)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          // 年度コンテンツ（展開時のみ表示）
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(color: widget.knBgColor, width: 0.5),
                  right: BorderSide(color: widget.knBgColor, width: 0.5),
                  bottom: BorderSide(color: widget.knBgColor, width: 0.5),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  for (int rowIndex = 0;
                      rowIndex < (yearStudents.length / 4).ceil();
                      rowIndex++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          for (int colIndex = 0; colIndex < 4; colIndex++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: () {
                                  final idx = rowIndex * 4 + colIndex;
                                  return idx < yearStudents.length
                                      ? _buildStudentCard(yearStudents[idx])
                                      : const SizedBox.shrink();
                                }(),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: KnAppBar(
        title: titleName,
        subtitle: '${widget.pagePath} >> $titleName',
        context: context,
        appBarBackgroundColor: widget.knBgColor, // 自定义AppBar背景颜色
        titleColor: Color.fromARGB(
            widget.knFontColor.alpha, // 自定义标题颜色
            widget.knFontColor.red - 20,
            widget.knFontColor.green - 20,
            widget.knFontColor.blue - 20),
        // [Flutter页面主题改造] 2026-01-26 副标题背景使用主题色的深色版本
        subtitleBackgroundColor: Color.fromARGB(
            widget.knBgColor.alpha,
            (widget.knBgColor.red * 0.6).round(),
            (widget.knBgColor.green * 0.6).round(),
            (widget.knBgColor.blue * 0.6).round()),
        addInvisibleRightButton: true,
        leftBalanceCount: 1, // [Flutter页面主题改造] 2026-01-26 修正：无Home按钮时，leftBalanceCount = actions数 - 1
        subtitleTextColor: Colors.white, // 自定义底部文本颜色
        titleFontSize: 20.0, // 自定义标题字体大小
        subtitleFontSize: 12.0, // 自定义底部文本字体大小
        actions: [
          // 搜索按钮
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: _isLoading ? null : _showSearchDialog,
          ),
          // 当加载中时禁用按钮
          IconButton(
            icon: Icon(
              _showDeleteButtons ? Icons.close : Icons.add,
              color: Colors.white,
            ),
            onPressed: _isLoading ? null : toggleDeleteButtons,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主要内容
          _isDataLoaded
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        // 年度別グループ表示（降順）
                        for (final entry in _groupedByYear.entries)
                          _buildYearBox(entry.key, entry.value),
                        // 「+」追加ボタン（全年度の下に配置）
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _buildAddButton(),
                                ),
                              ),
                              const Expanded(child: SizedBox()),
                              const Expanded(child: SizedBox()),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(), // 如果数据未加载完成，显示空容器

          // 加载指示器层
          if (_isLoading)
            Center(
              child:
                  KnLoadingIndicator(color: widget.knBgColor), // 使用自定义的加载器进度条
            ),
        ],
      ),
    );
  }
}
