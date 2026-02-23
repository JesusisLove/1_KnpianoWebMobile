// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../Constants.dart';
import '../../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-21 添加主题扩展
import '../2subjectBasic/kn05S003SubEda_list.dart';
import 'KnSub001Bean.dart';
import 'knsub001_add_edit.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart'; // 导入自定义加载指示器

// ignore: must_be_immutable
class SubjectViewPage extends StatefulWidget {
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  late String subtitle;
  final String titleName = "科目基本信息";
  SubjectViewPage({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  }) {
    subtitle = "$pagePath >> $titleName";
  }

  @override
  _SubjectViewPageState createState() => _SubjectViewPageState();
}

class _SubjectViewPageState extends State<SubjectViewPage> {
  late Future<List<KnSub001Bean>> futureSubjects;
  bool _isLoading = false; // 添加加载状态变量

  @override
  void initState() {
    super.initState();
    _fetchSubjectData();
  }

  void _fetchSubjectData() {
    setState(() {
      _isLoading = true; // 开始加载前设置为true
    });

    // 确保在这里为futureSubjects赋值
    futureSubjects = _fetchSubjects().then((result) {
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

  // 画面初期化：取得所有科目信息
  Future<List<KnSub001Bean>> _fetchSubjects() async {
    // 上课管理菜单画面，点击“学生科目管理”按钮的url请求
    final String apiUrl = '${KnConfig.apiBaseUrl}${Constants.subjectView}';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      List<dynamic> subjectsJson = json.decode(decodedBody);
      return subjectsJson.map((json) => KnSub001Bean.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subjects');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: KnAppBar(
          title: widget.titleName,
          subtitle: widget.subtitle,
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
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              // 新規”➕”按钮的事件处理函数
              onPressed: _isLoading
                  ? null // 如果正在加载，禁用按钮
                  : () {
                      // Navigate to add subject page or handle add operation
                      Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SubjectAddEdit(
                                    showMode: '新規',
                                    knBgColor: widget.knBgColor,
                                    knFontColor: widget.knFontColor,
                                    pagePath: widget.subtitle,
                                  ))).then((value) => {
                            setState(() {
                              _fetchSubjectData(); // 使用统一的加载方法
                            })
                          });
                    },
            ),
          ],
        ),
        body: Stack(
          children: [
            FutureBuilder<List<KnSub001Bean>>(
              future: futureSubjects,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_isLoading) {
                  // 当连接状态是等待中，但_isLoading为false时不显示任何内容
                  return Container();
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return _buildSubjectItem(snapshot.data![index]);
                    },
                  );
                } else {
                  /* 当页面首次加载时，snapshot.hasData 条件还没有满足，但也不是 ConnectionState.waiting 状态或有错误，所以代码执行到了最后的 else 分支，显示了 "No data available" 信息。 */
                  // return const Center(child: Text('No data available'));
                  // 在非加载状态下，如果没有数据且没有错误，才显示无数据提示
                  return Container(); // 或者你可以选择显示一个更友好的提示
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
        ));
  }

  Widget _buildSubjectItem(KnSub001Bean subject) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          // backgroundImage: NetworkImage(student.imageUrl), // 假设每个学生对象有一个imageUrl字段
          // 如果没有图像URL，可以使用一个本地的占位符图像
          backgroundImage: AssetImage('images/student-placeholder.png'),
        ),
        title: Text(subject.subjectName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 编辑按钮
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              // 编辑按钮的事件处理函数
              onPressed: _isLoading
                  ? null // 如果正在加载，禁用按钮
                  : () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectAddEdit(
                            subject: subject,
                            showMode: '編集',
                            knBgColor: widget.knBgColor,
                            knFontColor: widget.knFontColor,
                            pagePath: widget.subtitle,
                          ),
                        ),
                      ).then((value) {
                        // 检查返回值，如果为true，则重新加载数据
                        if (value == true) {
                          setState(() {
                            // futureSubjects = fetchSubjects();
                            _fetchSubjectData();
                          });
                        }
                      });
                    },
            ),

            // 删除按钮
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading
                  ? null // 如果正在加载，禁用按钮
                  : () async {
                      // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('删除确认',
                                style: KnElementTextStyle.dialogTitle(context,
                                    color: Constants.stuDocThemeColor)),
                            content: Text('确定要删除【${subject.subjectName}】这门科目吗？',
                                style: KnElementTextStyle.dialogContent(context)),
                            actions: <Widget>[
                              TextButton(
                                child: Text('取消',
                                    style: KnElementTextStyle.buttonText(context,
                                        color: Colors.red)),
                                onPressed: () {
                                  Navigator.of(context).pop(); // 关闭对话框
                                },
                              ),
                              TextButton(
                                child: Text('确定',
                                    style: KnElementTextStyle.buttonText(context,
                                        color: Constants.stuDocThemeColor)),
                                onPressed: () {
                                  deleteSubject(subject);
                                  Navigator.of(context).pop(); // 关闭对话框
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
            ),

            // 科目级别按钮
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.blue),
              // 科目级别按钮的事件处理函数
              onPressed: _isLoading
                  ? null // 如果正在加载，禁用按钮
                  : () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Kn05S003SubEdaView(
                            subjectName: subject.subjectName,
                            subjectId: subject.subjectId,
                            knBgColor: widget.knBgColor,
                            knFontColor: widget.knFontColor,
                            pagePath: widget.subtitle,
                          ),
                        ),
                      ).then((value) {
                        // 检查返回值，如果为true，则重新加载数据
                        if (value == true) {
                          setState(() {
                            // futureSubjects = fetchSubjects();
                            _fetchSubjectData();
                          });
                        }
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  deleteSubject(KnSub001Bean subject) {
    setState(() {
      _isLoading = true; // 开始删除操作前设置为true
    });

    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.subjectInfoDelete}/${subject.subjectId}';
    try {
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
          _fetchSubjectData(); // 使用统一的加载方法，不再使用reloadData
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('删除失败'),
                content: Text(response.body),
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
      }).catchError((error) {
        setState(() {
          _isLoading = false; // 出错时也要设置为false
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('操作异常'),
              content: Text('发生错误: $error'),
              actions: <Widget>[
                TextButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // 出错时也要设置为false
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('网络异常'),
            content: const Text('无法连接到服务器'),
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
