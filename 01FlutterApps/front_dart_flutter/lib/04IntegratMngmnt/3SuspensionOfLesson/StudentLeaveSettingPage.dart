// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../03StuDocMngmnt/1studentBasic/KnStu001Bean.dart';
import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart'; // 导入自定义加载指示器
import '../../Constants.dart';

// ignore: must_be_immutable
class StudentLeaveSettingPage extends StatefulWidget {
  // AppBar背景颜色
  final Color knBgColor;
  // 字体颜色
  final Color knFontColor;
  // 画面迁移路径：例如，上课进度管理>>学生姓名一览>> xxx的课程进度状况
  late String pagePath;
  StudentLeaveSettingPage(
      {super.key,
      required this.knBgColor,
      required this.knFontColor,
      required this.pagePath});

  @override
  _StudentLeaveSettingPageState createState() =>
      _StudentLeaveSettingPageState();
}

class _StudentLeaveSettingPageState extends State<StudentLeaveSettingPage> {
  final String titleName = '他(她)要休学或退学';
  final ValueNotifier<List<KnStu001Bean>> stuOffLsnNotifier = ValueNotifier([]);
  int stuInfoCount = 0;
  List<KnStu001Bean> stuOffLsnList = [];
  bool _isLoading = false; // 修改加载状态标志
  bool _isDataLoaded = false; // 添加数据加载完成标志

  @override
  void initState() {
    super.initState();
    fetchStuOffLsnInfo();
  }

  @override
  void dispose() {
    stuOffLsnNotifier.dispose(); // 释放资源
    super.dispose();
  }

  Future<void> fetchStuOffLsnInfo() async {
    if (!mounted) return; // 检查组件是否仍然挂载

    setState(() {
      _isLoading = true; // 开始加载数据
    });

    try {
      final String apiStuOnLsnUrl =
          '${KnConfig.apiBaseUrl}${Constants.intergStuOnLsn}';
      final responseFeeDetails = await http.get(Uri.parse(apiStuOnLsnUrl));

      if (!mounted) return; // 再次检查，因为网络请求可能耗时

      if (responseFeeDetails.statusCode == 200) {
        final decodedBody = utf8.decode(responseFeeDetails.bodyBytes);
        List<dynamic> stuDocJson = json.decode(decodedBody);
        setState(() {
          stuOffLsnNotifier.value =
              stuDocJson.map((json) => KnStu001Bean.fromJson(json)).toList();
          stuInfoCount = stuOffLsnNotifier.value.length;
          stuOffLsnList = stuOffLsnNotifier.value;
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

  // 注释: 修改为使用 KnStu001Bean 对象
  Set<KnStu001Bean> selectedStudents = <KnStu001Bean>{};

  // 注释: 新增保存功能
  Future<void> saveSelectedStudents() async {
    if (selectedStudents.isEmpty) {
      // 注释: 如果没有选中学生，显示提示对话框
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(
              '提示',
              style: Theme.of(dialogContext).textTheme.headlineSmall,
            ),
            content: Text(
              '没有退学的学生被选中，请选择要退学的学生。',
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  '确定',
                  style: Theme.of(dialogContext).textTheme.labelLarge,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    setState(() {
      _isLoading = true; // 开始保存操作
    });

    // 注释: 准备要发送的数据
    List<Map<String, dynamic>> studentsToSave = selectedStudents
        .map((student) => {'stuId': student.stuId, 'stuName': student.stuName})
        .toList();

    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.intergStuLeaveExecute}';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(studentsToSave),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false; // 操作结束
      });

      if (response.statusCode == 200) {
        // 注释: 保存成功
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('退学处理成功'),
            backgroundColor: widget.knBgColor,
            duration: const Duration(seconds: 5),
          ),
        );
        // 退出当前页面，返回上一句页面，并让上一级页面执行刷新操作
        Navigator.of(context).pop(true);
      } else {
        // 注释: 保存失败
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('退学处理失败，请重试')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false; // 操作出错时也要重置状态
      });

      // 注释: 发生错误
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        addInvisibleRightButton: false, // 显示Home按钮返回主菜单
        leftBalanceCount: 1, // [Flutter页面主题改造] 2026-01-19 添加左侧平衡使标题居中
        currentNavIndex: 3,
        subtitleTextColor: Colors.white, // 自定义底部文本颜色
        titleFontSize: 20.0, // 自定义标题字体大小
        subtitleFontSize: 12.0, // 自定义底部文本字体大小
        actions: [
          TextButton(
            onPressed: _isLoading ? null : saveSelectedStudents, // 加载中禁用保存按钮
            child: Text(
              '保存',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _isLoading ? Colors.grey : widget.knFontColor,
              ),
            ), // 注释: 使用主题字体风格
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主要内容
          _isDataLoaded
              ? AlphabetScrollView(
                  list: stuOffLsnList, // 注释: 使用 stuOffLsnList 代替 students
                  selectedStudents: selectedStudents,
                  isLoading: _isLoading, // 传递加载状态
                  onStudentSelected: (KnStu001Bean student, bool selected) {
                    if (_isLoading) return; // 加载中不允许选择
                    setState(() {
                      if (selected) {
                        selectedStudents.add(student);
                      } else {
                        selectedStudents.remove(student);
                      }
                    });
                  },
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

class AlphabetScrollView extends StatelessWidget {
  final List<KnStu001Bean> list; // 注释: 修改为 KnStu001Bean 类型的列表
  final Set<KnStu001Bean> selectedStudents; // 注释: 修改为 KnStu001Bean 类型的集合
  final Function(KnStu001Bean, bool) onStudentSelected; // 注释: 修改回调函数参数类型
  final bool isLoading; // 添加加载状态

  const AlphabetScrollView({
    super.key,
    required this.list,
    required this.selectedStudents,
    required this.onStudentSelected,
    required this.isLoading, // 接收加载状态
  });

  @override
  Widget build(BuildContext context) {
    // 注释: 根据 stuName 排序
    list.sort((a, b) => a.stuName.compareTo(b.stuName));
    final groupedStudents = groupStudents(list);

    return Row(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: groupedStudents.length,
            itemBuilder: (context, index) {
              final letter = groupedStudents.keys.elementAt(index);
              final students = groupedStudents[letter]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    // 紫色长条的两端边距
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color:
                            isLoading ? Colors.grey : Colors.purple, // 加载中改变颜色
                        borderRadius: BorderRadius.circular(10.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isLoading
                                  ? Colors.grey
                                  : Colors.purple, // 加载中改变颜色
                              borderRadius: BorderRadius.circular(10.5),
                            ),
                            child: Text(
                              letter,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                  ),
                  ...students.map((student) => buildStudentItem(student)),
                ],
              );
            },
          ),
        ),
        Container(
          width: 20,
          color: Colors.grey[200],
          child: ListView.builder(
            itemCount: 26,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        // 加载中禁用点击
                        // 处理字母索引点击
                      },
                child: Container(
                  height: 20,
                  alignment: Alignment.center,
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      fontSize: 12,
                      color: isLoading ? Colors.grey : Colors.black, // 加载中改变颜色
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 注释: 修改为使用 KnStu001Bean 对象
  Widget buildStudentItem(KnStu001Bean student) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 60, // 设置cell行的高度
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            // 添加一个 SizedBox 来设置左侧间距，每一行有checkBox的学生信息距离画面错边距60像素。
            const SizedBox(width: 24),
            Checkbox(
              value: selectedStudents.contains(student),
              onChanged: isLoading
                  ? null // 加载中禁用复选框
                  : (bool? value) {
                      onStudentSelected(student, value ?? false);
                    },
            ),
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        isLoading ? Colors.grey : Colors.orange, // 加载中改变颜色
                    child: Text(student.stuName[0],
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    student.stuName,
                    style: TextStyle(
                      color: isLoading ? Colors.grey : Colors.black, // 加载中改变颜色
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 注释: 修改为使用 KnStu001Bean 对象
  Map<String, List<KnStu001Bean>> groupStudents(List<KnStu001Bean> students) {
    final grouped = <String, List<KnStu001Bean>>{};
    for (final student in students) {
      final letter = student.stuName[0].toUpperCase();
      if (!grouped.containsKey(letter)) {
        grouped[letter] = [];
      }
      grouped[letter]!.add(student);
    }
    return grouped;
  }
}
