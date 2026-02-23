import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kn_piano/ApiConfig/KnApiConfig.dart';
import 'dart:convert';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart'; // 导入自定义加载指示器
import '../../Constants.dart';
import '../../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-21 添加主题扩展
import 'knfixlsn001_add.dart';
import 'knfixlsn001_edit.dart';
import 'KnFixLsn001Bean.dart';
// [固定排课新潮界面] 2026-02-12 导入新组件
import 'schedule_grid_view.dart';
import 'view_mode_toggle.dart';

// ignore: must_be_immutable
class ClassSchedulePage extends StatefulWidget {
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  ClassSchedulePage({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  @override
  ClassSchedulePageState createState() => ClassSchedulePageState();
}

class ClassSchedulePageState extends State<ClassSchedulePage>
    with TickerProviderStateMixin {
  final String titleName = '固定排课一览';
  late TabController _tabController;
  late Future<List<KnFixLsn001Bean>> futureFixLsnList;
  late String subtitle;
  bool _isLoading = false; // 添加加载状态变量
  String _filterSubject = ''; // 过滤科目
  String _filterStudentName = ''; // 过滤学生姓名
  final TextEditingController _filterStudentNameController =
      TextEditingController(); // 学生姓名输入控制器

  // 缓存过滤后的数据，确保TabBar和TabBarView使用相同的数据
  List<KnFixLsn001Bean> _cachedLessons = [];
  List<String> _cachedAvailableDays = [];

  // [固定排课新潮界面] 2026-02-12 视图模式
  ViewMode _viewMode = ViewMode.grid;
  bool _isViewModeLoading = true;

  final List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  @override
  void initState() {
    super.initState();
    // 获取当前日期并计算星期几的索引
    int currentDayIndex = _getCurrentDayIndex();
    _tabController =
        TabController(length: 7, vsync: this, initialIndex: currentDayIndex);

    // [固定排课新潮界面] 2026-02-12 加载用户视图偏好
    _loadViewModePreference();

    _fetchLessonData();
  }

  // [固定排课新潮界面] 2026-02-12 加载视图模式偏好
  Future<void> _loadViewModePreference() async {
    final mode = await ViewModePreference.getViewMode();
    if (mounted) {
      setState(() {
        _viewMode = mode;
        _isViewModeLoading = false;
      });
    }
  }

  // 新增方法：获取当前日期对应的星期几索引
  int _getCurrentDayIndex() {
    DateTime now = DateTime.now();
    // DateTime.weekday 返回 1-7，其中 1=Monday, 7=Sunday
    // 我们的weekDays数组是 [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
    // 所以需要将 weekday-1 来匹配数组索引
    int weekday = now.weekday; // 1=Monday, 2=Tuesday, ..., 7=Sunday
    return weekday - 1; // 转换为0-6的索引
  }

  // 新增方法：获取当前选中的星期
  String getCurrentSelectedDay() {
    // 直接使用缓存的数据
    if (_tabController.index < _cachedAvailableDays.length) {
      return _cachedAvailableDays[_tabController.index];
    }
    return _cachedAvailableDays.isNotEmpty ? _cachedAvailableDays[0] : 'Mon';
  }

  // 新的数据加载方法
  Future<void> _fetchLessonData() async {
    setState(() {
      _isLoading = true; // 开始加载前设置为true
    });

    try {
      final result = await fetchLessons();

      if (!mounted) return;

      // 在单个setState中同时更新数据、缓存和TabController，确保它们同步
      setState(() {
        futureFixLsnList = Future.value(result);
        _isLoading = false;

        // 更新缓存的过滤数据
        _cachedLessons = filterLessons(result);
        _cachedAvailableDays = getAvailableWeekDays(_cachedLessons);

        // 如果有过滤条件，需要重新创建 TabController
        if (_filterSubject.isNotEmpty || _filterStudentName.isNotEmpty) {
          _tabController.dispose();
          _tabController = TabController(
            length: _cachedAvailableDays.length,
            vsync: this,
            initialIndex: 0,
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // 出错时也要设置为false
      });
      rethrow; // 继续传递错误
    }
  }

  // 过滤lessons
  List<KnFixLsn001Bean> filterLessons(List<KnFixLsn001Bean> lessons) {
    return lessons.where((lesson) {
      // 科目过滤
      bool matchSubject =
          _filterSubject.isEmpty || lesson.subjectName == _filterSubject;

      // 学生姓名过滤（模糊匹配，不区分大小写）
      bool matchStudent = _filterStudentName.isEmpty ||
          lesson.studentName
              .toLowerCase()
              .contains(_filterStudentName.toLowerCase());

      // AND逻辑：所有条件都要满足
      return matchSubject && matchStudent;
    }).toList();
  }

  // 获取有数据的星期列表（过滤后）
  List<String> getAvailableWeekDays(List<KnFixLsn001Bean> filteredLessons) {
    if (_filterSubject.isEmpty && _filterStudentName.isEmpty) {
      // 没有过滤条件，显示所有星期
      return weekDays;
    }

    // 获取有数据的星期
    final availableDays =
        filteredLessons.map((lesson) => lesson.fixedWeek).toSet().toList();

    // 按照原始weekDays的顺序排序
    availableDays
        .sort((a, b) => weekDays.indexOf(a).compareTo(weekDays.indexOf(b)));

    return availableDays;
  }

  // 画面初期化：取得所有固定排课信息
  Future<List<KnFixLsn001Bean>> fetchLessons() async {
    final String apiUrl = '${KnConfig.apiBaseUrl}${Constants.fixedLsnInfoView}';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      return (json.decode(decodedBody) as List)
          .map((data) => KnFixLsn001Bean.fromJson(data))
          .toList();
    } else {
      throw Exception('Failed to load fixLsnList');
    }
  }

  @override
  Widget build(BuildContext context) {
    subtitle = "${widget.pagePath} >> $titleName";
    return Scaffold(
      appBar: KnAppBar(
        title: titleName,
        subtitle: subtitle,
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
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
        addInvisibleRightButton: true,
        leftBalanceCount:
            3, // [固定排课新潮界面] 2026-02-12 调整为3（新增了视图切换按钮）
        actions: [
          // [固定排课新潮界面] 2026-02-12 视图切换按钮
          if (!_isLoading && !_isViewModeLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ViewModeToggle(
                currentMode: _viewMode,
                onModeChanged: (mode) {
                  setState(() => _viewMode = mode);
                },
                activeColor: widget.knBgColor,
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color:
                  (_filterSubject.isNotEmpty || _filterStudentName.isNotEmpty)
                      ? Colors.yellow
                      : Colors.white,
            ),
            onPressed: _isLoading
                ? null // 如果正在加载，禁用按钮
                : () {
                    _showFilterDialog();
                  },
          ),
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            // 新規"➕"按钮的事件处理函数
            onPressed: _isLoading
                ? null // 如果正在加载，禁用按钮
                : () {
                    // 获取当前选中的星期并传递给子画面
                    String currentDay = getCurrentSelectedDay();
                    Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleForm(
                            knBgColor: Constants.settngThemeColor,
                            knFontColor: Colors.white,
                            pagePath: subtitle,
                            preSelectedDay: currentDay, // 传递当前选中的星期
                          ),
                        )).then((value) {
                      if (value == true) {
                        _fetchLessonData();
                      }
                    });
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // [固定排课新潮界面] 2026-02-12 仅在传统模式下显示 TabBar
          if (_viewMode == ViewMode.list && _cachedAvailableDays.isNotEmpty)
            TabBar(
              controller: _tabController,
              unselectedLabelColor: Colors.black,
              isScrollable: _cachedAvailableDays.length > 5, // 如果Tab太多，允许滚动
              tabs: _cachedAvailableDays.map((day) => Tab(text: day)).toList(),
            ),
          Expanded(
            child: Stack(
              children: [
                // [固定排课新潮界面] 2026-02-12 根据视图模式显示不同界面
                if (!_isLoading && !_isViewModeLoading)
                  _viewMode == ViewMode.grid
                      ? _buildGridView()
                      : _buildListView(),

                // 加载指示器层
                if (_isLoading || _isViewModeLoading)
                  Center(
                    child: KnLoadingIndicator(
                        color: widget.knBgColor), // 使用自定义的加载器进度条
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // [固定排课新潮界面] 2026-02-12 构建网格视图（新潮界面）
  Widget _buildGridView() {
    return ScheduleGridView(
      lessons: _cachedLessons,
      themeColor: widget.knBgColor,
      // [新潮界面] 2026-02-12 传入导航到新增页面所需参数
      knBgColor: Constants.settngThemeColor,
      knFontColor: Colors.white,
      pagePath: subtitle,
      onEdit: (lesson) {
        Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleFormEdit(
              lesson: lesson,
              knBgColor: Constants.settngThemeColor,
              knFontColor: Colors.white,
              pagePath: subtitle,
            ),
          ),
        ).then((value) {
          if (value == true) {
            _fetchLessonData();
          }
        });
      },
      onDelete: (lesson) {
        _showDeleteConfirmDialog(lesson);
      },
      onDataChanged: () {
        _fetchLessonData();
      },
    );
  }

  // [固定排课新潮界面] 2026-02-12 构建列表视图（传统界面）
  Widget _buildListView() {
    if (_cachedAvailableDays.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    return TabBarView(
      controller: _tabController,
      children: _cachedAvailableDays
          .map((day) => buildLessonList(_cachedLessons, day))
          .toList(),
    );
  }

  // [固定排课新潮界面] 2026-02-12 显示删除确认对话框
  void _showDeleteConfirmDialog(KnFixLsn001Bean lesson) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('删除确认',
              style: KnElementTextStyle.dialogTitle(context,
                  color: Constants.settngThemeColor)),
          content: Text('确定要删除${lesson.studentName}的固定排课吗？',
              style: KnElementTextStyle.dialogContent(context)),
          actions: <Widget>[
            TextButton(
              child: Text('取消',
                  style:
                      KnElementTextStyle.buttonText(context, color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('确定',
                  style: KnElementTextStyle.buttonText(context,
                      color: Constants.settngThemeColor)),
              onPressed: () {
                deleteLesson(lesson);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildLessonList(List<KnFixLsn001Bean> lessons, String dayIndex) {
    // 根据特定的日子过滤课程
    var dayLessons =
        lessons.where((lesson) => lesson.fixedWeek == dayIndex).toList();

    if (dayLessons.isEmpty) {
      return const Center(child: Text(""));
    }

    return ListView.builder(
      itemCount: dayLessons.length,
      itemBuilder: (context, index) {
        return buildLessonCard(dayLessons[index]);
      },
    );
  }

  Widget buildLessonCard(KnFixLsn001Bean lesson) {
    // 创建一个Card小部件，用于显示每个课程的详细信息
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
            backgroundImage: AssetImage('images/student-placeholder.png')),
        title: Text(lesson.studentName),
        subtitle: Row(
          children: <Widget>[
            // 为科目名称设置像素的左间距
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                lesson.subjectName,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            // const Spacer(), // 先不要删除，留着学习：这会填充所有可用空间
            Container(
              // 为固定时间设置像素的右间距
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                lesson.classTime,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // Row的宽度只足够包含子控件
          children: <Widget>[
            // 编辑按钮
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: _isLoading
                  ? null // 如果正在加载，禁用按钮
                  : () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleFormEdit(
                            lesson: lesson,
                            knBgColor: Constants.settngThemeColor,
                            knFontColor: Colors.white,
                            pagePath: subtitle,
                          ),
                        ),
                      ).then((value) {
                        // 检查返回值，如果为true，则重新加载数据
                        if (value == true) {
                          _fetchLessonData();
                        }
                      });
                    },
            ),
            // 删除按钮
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading
                  ? null // 如果正在加载，禁用按钮
                  : () {
                      // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('删除确认',
                                style: KnElementTextStyle.dialogTitle(context,
                                    color: Constants.settngThemeColor)),
                            content: Text('确定要删除${lesson.studentName}的固定排课吗？',
                                style:
                                    KnElementTextStyle.dialogContent(context)),
                            actions: <Widget>[
                              TextButton(
                                child: Text('取消',
                                    style: KnElementTextStyle.buttonText(
                                        context,
                                        color: Colors.red)),
                                onPressed: () {
                                  Navigator.of(context).pop(); // 关闭对话框
                                },
                              ),
                              TextButton(
                                child: Text('确定',
                                    style: KnElementTextStyle.buttonText(
                                        context,
                                        color: Constants.settngThemeColor)),
                                onPressed: () {
                                  // 执行删除操作
                                  deleteLesson(lesson);
                                  Navigator.of(context).pop(); // 关闭对话框
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  // 删除课程的函数
  void deleteLesson(KnFixLsn001Bean lesson) {
    setState(() {
      _isLoading = true; // 开始删除操作前设置为true
    });

    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.fixedLsnInfoDelete}/${lesson.studentId}/${lesson.subjectId}/${lesson.fixedWeek}';
    http.delete(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json', // 添加内容类型头
      },
    ).then((response) {
      setState(() {
        _isLoading = false; // 操作完成后设置为false
      });

      if (response.statusCode == 200) {
        // 调用重新加载数据的函数
        reloadData(lesson.fixedWeek);
      } else {
        // 错误处理
        if (kDebugMode) {
          print("删除失败: ${response.body}");
        }
      }
    }).catchError((error) {
      setState(() {
        _isLoading = false; // 出错时也要设置为false
      });

      // 错误处理
      if (kDebugMode) {
        print("出现错误: $error");
      }
    });
  }

  Future<void> reloadData(String fixedWeek) async {
    // 等待数据重新加载完成（_fetchLessonData会自动更新缓存）
    await _fetchLessonData();

    if (!mounted) return;

    // 使用缓存的数据来设置tab索引
    setState(() {
      // 尝试找到被删除数据的fixedWeek在过滤后的tabs中的索引
      final weekIndex = _cachedAvailableDays.indexOf(fixedWeek);
      if (weekIndex != -1 && weekIndex < _tabController.length) {
        _tabController.index = weekIndex;
      } else if (_tabController.length > 0) {
        // 如果找不到或者超出范围，设置为第一个tab
        _tabController.index = 0;
      }
    });
  }

  // 显示过滤对话框
  void _showFilterDialog() async {
    // 等待数据加载完成，获取所有科目
    final lessons = await futureFixLsnList;
    final subjects =
        lessons.map((lesson) => lesson.subjectName).toSet().toList();
    subjects.sort();

    // 临时变量
    String tempSubject = _filterSubject;
    String tempStudentName = _filterStudentName;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('过滤条件',
                style: KnElementTextStyle.dialogTitle(context,
                    color: widget.knBgColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 科目下拉框
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '科目',
                    prefixIcon: Icon(Icons.book),
                  ),
                  value: tempSubject.isEmpty ? null : tempSubject,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('全部科目'),
                    ),
                    ...subjects.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tempSubject = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                // 学生姓名输入框
                TextField(
                  controller: _filterStudentNameController,
                  decoration: const InputDecoration(
                    labelText: '学生姓名',
                    hintText: '请输入学生姓名',
                    prefixIcon: Icon(Icons.person),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      tempStudentName = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // 先保存context引用，避免async gap后使用
                  final navigator = Navigator.of(context);

                  // 获取原始数据（未过滤）
                  final lessons = await futureFixLsnList;

                  if (!mounted) return;

                  setState(() {
                    _filterSubject = '';
                    _filterStudentName = '';
                    _filterStudentNameController.clear();

                    // 清空过滤条件后，更新缓存为全部数据
                    _cachedLessons = lessons;
                    _cachedAvailableDays = weekDays;

                    // 重新创建TabController为全部7天
                    _tabController.dispose();
                    _tabController = TabController(
                      length: 7,
                      vsync: this,
                      initialIndex: _getCurrentDayIndex(),
                    );
                  });
                  navigator.pop();
                },
                child: Text('清空',
                    style: KnElementTextStyle.dialogTitle(context,
                        color: widget.knBgColor)),
              ),
              TextButton(
                onPressed: () async {
                  // 先保存context引用，避免async gap后使用
                  final navigator = Navigator.of(context);

                  // 获取当前数据
                  final lessons = await futureFixLsnList;

                  if (!mounted) return;

                  // 先临时更新过滤变量，以便使用filterLessons方法
                  final oldFilterSubject = _filterSubject;
                  final oldFilterStudentName = _filterStudentName;
                  _filterSubject = tempSubject;
                  _filterStudentName = tempStudentName;

                  // 使用统一的过滤方法
                  final filteredLessons = filterLessons(lessons);
                  final availableDays = getAvailableWeekDays(filteredLessons);

                  // 恢复旧值（如果mounted检查失败）
                  if (!mounted) {
                    _filterSubject = oldFilterSubject;
                    _filterStudentName = oldFilterStudentName;
                    return;
                  }

                  setState(() {
                    // 过滤变量已经在上面更新了
                    // 更新缓存数据
                    _cachedLessons = filteredLessons;
                    _cachedAvailableDays = availableDays;

                    // 重新创建TabController with new tab count
                    _tabController.dispose();
                    _tabController = TabController(
                      length: availableDays.length,
                      vsync: this,
                      initialIndex: 0,
                    );
                  });

                  navigator.pop();
                },
                child: Text('确定',
                    style: KnElementTextStyle.dialogTitle(context,
                        color: widget.knBgColor)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterStudentNameController.dispose();
    super.dispose();
  }
}
