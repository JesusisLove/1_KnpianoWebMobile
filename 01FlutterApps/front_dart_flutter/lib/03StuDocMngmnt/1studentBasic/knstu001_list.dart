// 学生档案编辑
import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart';
import '../../Constants.dart';
import 'knstu001_add.dart';
import 'knstu001_edit.dart';
import 'KnStu001Bean.dart'; // 导入Student模型
import 'package:http/http.dart' as http;
import 'dart:convert';
// 确保Student模型已经导入
import 'package:kn_piano/ApiConfig/KnApiConfig.dart';

// ignore: must_be_immutable
class StuEditList extends StatefulWidget {
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;

  StuEditList(
      {super.key,
      required this.knBgColor,
      required this.knFontColor,
      required this.pagePath});
  @override
  StuEditListState createState() => StuEditListState();
}

class StuEditListState extends State<StuEditList> {
  late Future<List<KnStu001Bean>> futureStudents;
  final String titleName = "学生基本信息一覧";
  late String subtitle;
  bool _isLoading = false; // 添加加载状态变量

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  // 新的数据加载方法
  void _fetchStudentData() {
    setState(() {
      _isLoading = true; // 开始加载前设置为true
    });

    futureStudents = fetchStudents().then((result) {
      // 数据加载完成后
      setState(() {
        _isLoading = false; // 加载完成后设置为false
      });
      return result;
    }).catchError((error) {
      // 发生错误时
      setState(() {
        _isLoading = false; // 出错时也要设置为false
      });
      throw error; // 继续传递错误
    });
  }

  // 画面初期化：取得所有学生信息
  Future<List<KnStu001Bean>> fetchStudents() async {
    // 学生档案菜单画面，点击“学生档案编辑”按钮的url请求
    final String apiUrl = '${KnConfig.apiBaseUrl}${Constants.studentInfoView}';
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      List<dynamic> jsonList = jsonDecode(decodedBody);
      jsonList.map((json) => KnStu001Bean.fromJson(json)).toList();
      List<KnStu001Bean> stuLst = jsonList
          .map((json) => KnStu001Bean.fromJson(json))
          .cast<KnStu001Bean>()
          .toList();
      return stuLst;
    } else {
      throw Exception('Failed to load students');
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
        leftBalanceCount: 1, // [Flutter页面主题改造] 2026-01-19 添加左侧平衡使标题居中
        actions: [
          // 如果需要，可以在这里添加额外的操作按钮
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            // 新規”➕”按钮的事件处理函数
            onPressed: _isLoading
                ? null // 如果正在加载，禁用按钮
                : () {
                    Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentAdd(
                            knBgColor: Constants.stuDocThemeColor,
                            knFontColor: Colors.white,
                            pagePath: subtitle,
                          ),
                        )).then((value) {
                      // 检查返回值，如果为true，则重新加载数据
                      if (value == true) {
                        setState(() {
                          // futureStudents = fetchStudents();
                          _fetchStudentData();
                        });
                      }
                    });
                  },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 原有的FutureBuilder
          FutureBuilder<List<KnStu001Bean>>(
            future: futureStudents,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !_isLoading) {
                // 当连接状态是等待中，但_isLoading为false时不显示任何内容
                // 因为我们将使用全屏的加载指示器
                return Container();
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _buildStudentItem(snapshot.data![index]);
                  },
                );
              } else {
                // return const Center(child: Text("No data available"));
                return const Center(child: Text(""));
              }
            },
          ),

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

  Widget _buildStudentItem(KnStu001Bean student) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          // backgroundImage: NetworkImage(student.imageUrl), // 假设每个学生对象有一个imageUrl字段
          // 如果没有图像URL，可以使用一个本地的占位符图像
          backgroundImage: AssetImage('images/student-placeholder.png'),
        ),
        // 第一种风格
        title: Text(
          student.stuName,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue, // 下划线颜色
            decorationStyle: TextDecorationStyle.solid, // 下划线样式（实线）
            /*还有其他形式的属性
              TextDecorationStyle.double（双线）
              TextDecorationStyle.dotted（点线）
              TextDecorationStyle.dashed（虚线）
              TextDecorationStyle.wavy（波浪线）
            */
            decorationThickness: 0.5, // 下划线粗细
            fontSize: 20,
            height: 2.5,
          ),
        ),

        // 第二种风格
        // title: Container(
        //   padding: const EdgeInsets.only(bottom: 1), // 文字和下划线之间的间距
        //   decoration: const BoxDecoration(
        //     border: Border(
        //       bottom: BorderSide(
        //         color: Colors.black,
        //         width: 0.09, // 线的粗细为1像素
        //       ),
        //     ),
        //   ),
        //   child: Text(
        //     student.stuName,
        //     style: const TextStyle(
        //       fontSize: 20,
        //     ),
        //   ),
        // ),
        subtitle: Row(
          // 能在不同设备的屏幕大小保持相同的布局比例
          children: <Widget>[
            // 昵称部分 - 使用Expanded占据剩余空间
            Expanded(
              flex: 5, // 给昵称更多的空间比例
              child: Text(
                student.nikName,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis, // 处理长昵称
              ),
            ),

            // 性别部分 - 固定宽度，但足够显示"男"或"女"
            Container(
              width: 35, // 略微调小宽度，确保紧凑布局
              alignment: Alignment.center, // 内容居中对齐
              child: Text(
                student.gender == 1 ? '男' : '女',
                style: const TextStyle(fontSize: 14),
              ),
            ),

            // 生日部分 - 使用Expanded但给予较小的比例
            Expanded(
              flex: 6, // 生日部分也需要较多空间，尤其是带"Birth:"前缀
              child: Text(
                'Birth:${student.birthday}',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis, // 以防日期太长
              ),
            ),
          ],
        ),

        trailing: Row(
            mainAxisSize: MainAxisSize.min, // Row的宽度只足够包含子控件
            children: <Widget>[
              // 编辑按钮的事件处理函数
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentEdit(
                        student: student,
                        knBgColor: Constants.stuDocThemeColor,
                        knFontColor: Colors.white,
                        pagePath: subtitle,
                      ),
                    ),
                  ).then((value) {
                    // 检查返回值，如果为true，则重新加载数据
                    if (value == true) {
                      setState(() {
                        futureStudents = fetchStudents();
                      });
                    }
                  });
                },
              ),
            ]),
      ),
    );
  }
}
