// ignore: file_names
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kn_piano/03StuDocMngmnt/4stuDoc/Kn03D004StuDocBean.dart';
import 'dart:convert';

import 'package:kn_piano/Constants.dart';

import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import 'kn03D004StuDoc_Add.dart';
import 'kn03D004StuDoc_Detial_list.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart'; // 导入自定义加载指示器

// ignore: must_be_immutable
class StudentDocPage extends StatefulWidget {
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  late String subtitle;

  StudentDocPage({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  }) {
    subtitle = '$pagePath >> 档案管理';
  }

  @override
  // ignore: library_private_types_in_public_api
  _StudentDocPageState createState() => _StudentDocPageState();
}

class _StudentDocPageState extends State<StudentDocPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int archivedCount = 0;
  int unarchivedCount = 0;
  bool _isLoading = false; // 添加加载状态变量

  // 使用 ValueNotifier 来管理状态
  final ValueNotifier<List<Kn03D004StuDocBean>> stuDocNotifier =
      ValueNotifier([]);
  final ValueNotifier<List<Kn03D004StuDocBean>> stuUnDocNotifier =
      ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStudent(); // 使用统一的数据加载方法
    // 从DB取得该科目的科目级别信息，做画面初期化
    _fetchStudentData();
  }

  // 统一的数据加载方法
  void _fetchStudentData() {
    setState(() {
      _isLoading = true; // 开始加载前设置为true
    });

    _fetchStudent().then((_) {
      // 数据加载完成后
      setState(() {
        _isLoading = false; // 加载完成后设置为false
      });
    }).catchError((error) {
      // 发生错误时
      setState(() {
        _isLoading = false; // 出错时也要设置为false
      });
      // ignore: avoid_print
      print('Error in _fetchStudentData: $error');
    });
  }

  Future<void> _fetchStudent() async {
    try {
      // 获取已入档案学生
      final String apiStuDocUrl =
          '${KnConfig.apiBaseUrl}${Constants.stuDocInfoView}';
      final responseStuDoc = await http.get(Uri.parse(apiStuDocUrl));

      if (responseStuDoc.statusCode == 200) {
        final decodedBody = utf8.decode(responseStuDoc.bodyBytes);
        List<dynamic> stuDocJson = json.decode(decodedBody);
        stuDocNotifier.value = stuDocJson
            .map((json) => Kn03D004StuDocBean.fromJson(json))
            .toList();
        archivedCount = stuDocNotifier.value.length; // 更新已入档案人数
      } else {
        throw Exception('Failed to load archived students');
      }

      // 获取未入档案学生
      final String apiStuUnDocUrl =
          '${KnConfig.apiBaseUrl}${Constants.stuUnDocInfoView}';
      final responseStuUnDoc = await http.get(Uri.parse(apiStuUnDocUrl));

      if (responseStuUnDoc.statusCode == 200) {
        final decodedBody = utf8.decode(responseStuUnDoc.bodyBytes);
        List<dynamic> stuUnDocJson = json.decode(decodedBody);
        stuUnDocNotifier.value = stuUnDocJson
            .map((json) => Kn03D004StuDocBean.fromJson(json))
            .toList();
        unarchivedCount = stuUnDocNotifier.value.length; // 更新未入档案人数
      } else {
        throw Exception('Failed to load unarchived students');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching student data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Kn03D004StuDocBean>>(
      valueListenable: stuUnDocNotifier,
      builder: (context, unDocStudents, child) {
        return Scaffold(
          appBar: KnAppBar(
            title: unarchivedCount == 0 ? '档案管理（$archivedCount人）' : '档案管理',
            subtitle: widget.subtitle,
            context: context,
            appBarBackgroundColor: widget.knBgColor,
            titleColor: Color.fromARGB(
                widget.knFontColor.alpha, // 自定义AppBar背景颜色
                widget.knFontColor.red - 20,
                widget.knFontColor.green - 20,
                widget.knFontColor.blue - 20),
            // [Flutter页面主题改造] 2026-01-26 副标题背景使用主题色的深色版本
            subtitleBackgroundColor: Color.fromARGB(
                widget.knBgColor.alpha,
                (widget.knBgColor.red * 0.6).round(),
                (widget.knBgColor.green * 0.6).round(),
                (widget.knBgColor.blue * 0.6).round()),
            subtitleTextColor: Colors.white, // 自定义底部文本颜色
            titleFontSize: 20.0,
            subtitleFontSize: 12.0,
            addInvisibleRightButton: true,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  if (unDocStudents.isNotEmpty)
                    TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: '已入档案 （$archivedCount人）'),
                        Tab(text: '未入档案 （$unarchivedCount人）'),
                      ],
                    ),
                  Expanded(
                    child: unDocStudents.isNotEmpty
                        ? TabBarView(
                            controller: _tabController,
                            children: [
                              _buildStudentList(stuDocNotifier),
                              _buildStudentUnDocList(stuUnDocNotifier),
                            ],
                          )
                        : _buildStudentList(stuDocNotifier),
                  ),
                ],
              ),

              // 加载指示器层
              if (_isLoading)
                Center(
                  child: KnLoadingIndicator(
                      color: widget.knBgColor), // 使用自定义的加载器进度条
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentList(ValueNotifier<List<Kn03D004StuDocBean>> notifier) {
    return ValueListenableBuilder<List<Kn03D004StuDocBean>>(
      valueListenable: notifier,
      builder: (context, students, child) {
        if (students.isEmpty && !_isLoading) {
          return const Center(child: Text('没有数据'));
        }
        if (students.isEmpty && _isLoading) {
          return Container(); // 正在加载中，返回空容器
        }
        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage('images/student-placeholder.png'),
              ),
              title: Text(student.stuName),
              trailing: SizedBox(
                width: 100, // 固定宽度，保证对齐
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${student.subjectCount} 科',
                        style: const TextStyle(fontSize: 16.0)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 24.0),
                      onPressed: _isLoading
                          ? null
                          : () {
                              // 直接跳转到详细页面
                              Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDocDetailPage(
                                    stuId: student.stuId,
                                    stuName: student.stuName,
                                    knBgColor: widget.knBgColor,
                                    knFontColor: widget.knFontColor,
                                    pagePath: widget.subtitle,
                                  ),
                                ),
                              ).then((value) {
                                _fetchStudentData();
                              });
                            },
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

  Widget _buildStudentUnDocList(
      ValueNotifier<List<Kn03D004StuDocBean>> notifier) {
    return ValueListenableBuilder<List<Kn03D004StuDocBean>>(
      valueListenable: notifier,
      builder: (context, students, child) {
        if (students.isEmpty && !_isLoading) {
          return const Center(child: Text('没有数据'));
        }
        if (students.isEmpty && _isLoading) {
          return Container(); // 正在加载中，返回空容器
        }
        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage('images/student-placeholder.png'),
              ),
              title: Text(student.stuName),
              trailing: SizedBox(
                width: 80, // 固定宽度，保证对齐
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 24.0),
                      onPressed: _isLoading
                          ? null
                          : () {
                              // 直接跳转到新增页面
                              Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDocumentPage(
                                    stuId: student.stuId,
                                    stuName: student.stuName,
                                    knBgColor: widget.knBgColor,
                                    knFontColor: widget.knFontColor,
                                    pagePath: widget.subtitle,
                                  ),
                                ),
                              ).then((value) {
                                _fetchStudentData();
                              });
                            },
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

  @override
  void dispose() {
    _tabController.dispose();
    stuDocNotifier.dispose();
    stuUnDocNotifier.dispose();
    super.dispose();
  }
}
