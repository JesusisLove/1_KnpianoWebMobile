// ignore: file_names
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/CommonMethod.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart';
import '../../Constants.dart';
import '../../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-18 添加主题扩展
import 'Kn01L003LsnExtraBean.dart';

// 定义过滤类型
enum FilterType { paid, unpaid, converted }

// ignore: must_be_immutable
class ExtraToSchePage extends StatefulWidget {
  ExtraToSchePage({
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
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  final int selectedYear;

  @override
  _ExtraToSchePageState createState() => _ExtraToSchePageState();
}

class _ExtraToSchePageState extends State<ExtraToSchePage> {
  final String titleName = '加课消化管理';
  late int selectedYear;
  late List<int> years;
  late Future<List<Kn01L003LsnExtraBean>> futureLessons = Future.value([]);
  FilterType selectedFilter = FilterType.unpaid; // 默认选中未支付
  List<Kn01L003LsnExtraBean> allLessons = [];
  int paidCount = 0;
  int unpaidCount = 0;
  int convertedCount = 0;
  // 添加加载状态变量
  bool _isLoading = false;

  // 定义颜色常量
  final Map<FilterType, Color> tagColors = {
    FilterType.paid: const Color(0xFF1E88E5), // 蓝色
    FilterType.unpaid: const Color(0xFFE91E63), // 粉色
    FilterType.converted: const Color(0xFF4CAF50), // 绿色
  };

  final Map<FilterType, Color> tagBgColors = {
    FilterType.paid: const Color(0xFFE3F2FD), // 浅蓝色
    FilterType.unpaid: const Color(0xFFFCE4EC), // 浅粉色
    FilterType.converted: const Color(0xFFE8F5E9), // 浅绿色
  };

  final Map<FilterType, IconData> tagIcons = {
    FilterType.paid: Icons.credit_card,
    FilterType.unpaid: Icons.more_horiz,
    FilterType.converted: Icons.swap_horiz,
  };

  final Map<FilterType, String> tagTitles = {
    FilterType.paid: '已支付',
    FilterType.unpaid: '未支付',
    FilterType.converted: '已转换',
  };

  @override
  void initState() {
    super.initState();
    years = Constants.generateYearList(); // 使用统一的年度列表生成方法
    selectedYear = widget.selectedYear; // 使用传递过来的年度参数
    widget.pagePath = '${widget.pagePath} >> 加课消化管理';
    futureLessons = fetchLessons();
    // 启动初始数据加载
    _fetchLessonsData();
  }

  List<Kn01L003LsnExtraBean> getFilteredLessons() {
    switch (selectedFilter) {
      case FilterType.paid:
        return allLessons
            .where((lesson) =>
                    lesson.extraToDurDate.isEmpty && // 是月加课
                    lesson.payFlg == 1 // 已结算
                )
            .toList();
      case FilterType.unpaid:
        return allLessons
            .where((lesson) =>
                    lesson.extraToDurDate.isEmpty && // 是月加课
                    lesson.payFlg == 0 // 未结算
                )
            .toList();
      case FilterType.converted:
        return allLessons
            .where((lesson) => lesson.extraToDurDate.isNotEmpty // 是加转正
                )
            .toList();
    }
  }

  void updateCounts() {
    setState(() {
      paidCount = allLessons
          .where(
              (lesson) => lesson.extraToDurDate.isEmpty && lesson.payFlg == 1)
          .length;
      unpaidCount = allLessons
          .where(
              (lesson) => lesson.extraToDurDate.isEmpty && lesson.payFlg == 0)
          .length;
      convertedCount =
          allLessons.where((lesson) => lesson.extraToDurDate.isNotEmpty).length;
    });
  }

  Widget _buildFilterTag({
    required FilterType type,
    required int count,
  }) {
    final bool isSelected = selectedFilter == type;
    final Color tagColor = tagColors[type]!;
    final Color tagBgColor = tagBgColors[type]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tagBgColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? tagColor : tagBgColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tagTitles[type]!,
              style: TextStyle(
                color: tagColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTagIcon(type, tagColor),
                const SizedBox(width: 4),
                Text(
                  '$count节',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagIcon(FilterType type, Color color) {
    switch (type) {
      case FilterType.paid:
        return Icon(
          Icons.credit_card,
          color: color,
          size: 16,
        );
      case FilterType.unpaid:
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.more_horiz,
            color: Colors.white,
            size: 12,
          ),
        );
      case FilterType.converted:
        return Icon(
          Icons.swap_horiz,
          color: color,
          size: 16,
        );
    }
  }

  void _showDigestDatePicker(Kn01L003LsnExtraBean lesson) {
    String selectedDate = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '换正课日期',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 28),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('选择日期：'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        // 获取当前日期
                        DateTime now = DateTime.now();
                        // 计算本年年底
                        DateTime yearEnd = DateTime(now.year, 12, 31);
                        // 计算合适的初始日期
                        DateTime initialDate =
                            now.isAfter(yearEnd) ? yearEnd : now;

                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: DateTime(2020, 1, 1),
                          lastDate: DateTime(2025, 12, 31), // 延长到2025年底
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: widget.knBgColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate =
                                DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            hintText: '选择日期',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: selectedDate.isEmpty ? '' : selectedDate,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.knBgColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: selectedDate.isEmpty
                            ? null
                            : () async {
                                try {
                                  // 显示进度对话框
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return WillPopScope(
                                        onWillPop: () async => false,
                                        child: const AlertDialog(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 16),
                                              Text('正在执行加课换正课处理...'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                  final requestData =
                                      lesson.toRequestMap(selectedDate);
                                  final String apiUrl =
                                      '${KnConfig.apiBaseUrl}${Constants.executeExtraToSche}';
                                  final response = await http.post(
                                    Uri.parse(apiUrl),
                                    headers: {
                                      'Content-Type':
                                          'application/json; charset=UTF-8',
                                    },
                                    body: utf8.encode(json.encode(requestData)),
                                  );
                                  // 关闭进度对话框'正在执行加课换正课处理...'
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                  if (response.statusCode == 200) {
                                    final decodedBody =
                                        utf8.decode(response.bodyBytes);
                                    if (decodedBody == 'success') {
                                      Navigator.of(context).pop();
                                      _fetchLessonsData();
                                    } else {
                                      throw Exception(decodedBody);
                                    }
                                  } else {
                                    final decodedBody =
                                        utf8.decode(response.bodyBytes);
                                    throw Exception(decodedBody);
                                  }
                                } catch (e) {
                                  // 如果发生错误，确保关闭进度对话框'正在执行加课换正课处理...'
                                  if (mounted) {
                                    Navigator.of(context).pop(); // 关闭进度对话框
                                  }
                                  showDialog(
                                    // ignore: use_build_context_synchronously
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('错误'),
                                        content: Text('更新失败: $e'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('确定'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchLessonsData() async {
    setState(() {
      _isLoading = true; // 开始加载，设置状态
    });
    try {
      final lessons = await fetchLessons();
      setState(() {
        allLessons = lessons;
        updateCounts();
        _isLoading = false; // 加载完成，更新状态
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // 出错时也要更新状态
      });
      // 处理错误
    }
  }

  Future<void> _cancelLesson(Kn01L003LsnExtraBean lesson) async {
    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.undoExtraToSche}/${lesson.lessonId}';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && decodedBody['status'] == 'success') {
        _fetchLessonsData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decodedBody['message'] ?? '撤销成功')),
        );
      } else {
        throw Exception(decodedBody['message'] ?? '操作失败');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('错误'),
          content: Text('撤销失败: ${e.toString().replaceAll('Exception: ', '')}'),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<List<Kn01L003LsnExtraBean>> fetchLessons() async {
    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.extraToScheView}/${widget.stuId}/$selectedYear';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> lessonsJson = json.decode(decodedBody);
        return lessonsJson
            .map((json) => Kn01L003LsnExtraBean.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load lessons');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // [Flutter页面主题改造] 2026-01-18 年份选择器字体跟随主题风格
  // [Flutter页面主题改造] 2026-01-20 选中项粗体显示
  // [Flutter页面主题改造] 2026-01-21 使用模块主题颜色（绿色）
  void _showYearPicker() {
    int tempSelectedIndex = years.indexOf(selectedYear);
    final themeColor = widget.knBgColor; // 使用模块主题颜色
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
                color: themeColor,
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
                        _fetchLessonsData();
                        Navigator.of(context).pop();
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
                          child: Text(entry.value.toString(),
                              style: entry.key == tempSelectedIndex
                                  ? KnPickerTextStyle.pickerItemSelected(context,
                                      color: themeColor, fontSize: 18)
                                  : KnPickerTextStyle.pickerItem(context,
                                      color: themeColor, fontSize: 18))))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildFilterTag(
                  type: FilterType.paid,
                  count: paidCount,
                ),
                const SizedBox(width: 8),
                _buildFilterTag(
                  type: FilterType.unpaid,
                  count: unpaidCount,
                ),
                const SizedBox(width: 8),
                _buildFilterTag(
                  type: FilterType.converted,
                  count: convertedCount,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // [Flutter页面主题改造] 2026-01-21 增加按钮宽度，确保年度文字完整显示
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text('$selectedYear年'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.knBgColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              minimumSize: const Size(100, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: _showYearPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(Kn01L003LsnExtraBean lesson, bool isPaidExtraLesson) {
    Color textColor = lesson.payFlg == 1
        ? Colors.grey
        : (lesson.extraToDurDate.isNotEmpty
            ? const Color.fromARGB(255, 167, 47, 4)
            : Colors.pink);

    if (lesson.extraToDurDate.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '原加课日: ${CommonMethod.getWeekday(lesson.originalSchedualDate)} ${lesson.originalSchedualDate}',
            style: TextStyle(
              color: isPaidExtraLesson ? Colors.grey : Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '现正课日: ${CommonMethod.getWeekday(lesson.extraToDurDate)} ${lesson.extraToDurDate}',
            style: TextStyle(color: textColor),
          ),
        ],
      );
    } else if (lesson.lsnAdjustedDate.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '上课日期: ${CommonMethod.getWeekday(lesson.schedualDate)} ${lesson.schedualDate}',
            style: TextStyle(color: textColor),
          ),
          Text(
            '调课日期: ${CommonMethod.getWeekday(lesson.lsnAdjustedDate)} ${lesson.lsnAdjustedDate}',
            style: TextStyle(
              color: isPaidExtraLesson
                  ? Colors.grey
                  : (lesson.extraToDurDate.isEmpty
                      ? Colors.pink
                      : Colors.orange),
            ),
          ),
        ],
      );
    } else {
      return Text(
        '上课日期: ${CommonMethod.getWeekday(lesson.schedualDate)} ${lesson.schedualDate}',
        style: TextStyle(color: textColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
        title: '${widget.stuName}的$titleName',
        subtitle: widget.pagePath,
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
        addInvisibleRightButton: false,
        currentNavIndex: 0,
      ),
      body: _isLoading
          ? KnLoadingIndicator(color: widget.knBgColor) // 使用统一的加载指示器
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    color: tagBgColors[selectedFilter]!.withOpacity(0.1),
                    child: FutureBuilder<List<Kn01L003LsnExtraBean>>(
                      future: futureLessons,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('No data available'));
                        }

                        final filteredLessons = getFilteredLessons();
                        return ListView.builder(
                          itemCount: filteredLessons.length,
                          itemBuilder: (context, index) =>
                              _buildLessonCard(filteredLessons[index]),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLessonCard(Kn01L003LsnExtraBean lesson) {
    final bool isPaidExtraLesson = lesson.payFlg == 1;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPaidExtraLesson
              ? Colors.grey.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: isPaidExtraLesson ? Colors.grey : Colors.green,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              '${lesson.classDuration}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${lesson.subjectName}: ${lesson.subjectSubName}',
                style: TextStyle(
                  color: isPaidExtraLesson ? Colors.grey : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: lesson.extraToDurDate.isNotEmpty
                    ? const Color.fromARGB(255, 167, 47, 4).withOpacity(0.1)
                    : Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                lesson.extraToDurDate.isNotEmpty ? "加转正" : "月加课",
                style: TextStyle(
                  color: lesson.extraToDurDate.isNotEmpty
                      ? const Color.fromARGB(255, 167, 47, 4)
                      : Colors.pink,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _buildDateInfo(lesson, isPaidExtraLesson),
        ),
        trailing: isPaidExtraLesson
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '结算完了',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              )
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (BuildContext context) {
                  if (lesson.extraToDurDate.isNotEmpty && lesson.payFlg == 0) {
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'cancel',
                        child: Text('撤销'),
                      ),
                    ];
                  } else if (lesson.extraToDurDate.isEmpty &&
                      lesson.payFlg == 0) {
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'digest',
                        child: Text('消化'),
                      ),
                    ];
                  }
                  return <PopupMenuEntry<String>>[];
                },
                onSelected: (String result) async {
                  if (result == 'digest') {
                    _showDigestDatePicker(lesson);
                  } else if (result == 'cancel') {
                    await _cancelLesson(lesson);
                  }
                },
              ),
      ),
    );
  }
}
