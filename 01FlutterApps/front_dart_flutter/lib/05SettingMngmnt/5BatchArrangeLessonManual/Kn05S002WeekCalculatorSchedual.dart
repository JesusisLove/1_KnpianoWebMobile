// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart'; // Import the custom loading indicator
import '../../Constants.dart';
import 'Kn05S002FixedLsnStatusBean.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class Kn05S002WeekCalculatorSchedual extends StatefulWidget {
  // AppBar背景颜色
  final Color knBgColor;
  // 字体颜色
  final Color knFontColor;
  // 画面迁移路径：例如，上课进度管理>>学生姓名一览>> xxx的课程进度状况
  late String pagePath;

  Kn05S002WeekCalculatorSchedual({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  @override
  _Kn05S002WeekCalculatorSchedualState createState() =>
      _Kn05S002WeekCalculatorSchedualState();
}

class _Kn05S002WeekCalculatorSchedualState
    extends State<Kn05S002WeekCalculatorSchedual> {
  final String titleName = '周次排课设置';
  List<Kn05S002FixedLsnStatusBean> staticLsnList = [];
  bool _isLoading = false; // Changed variable name to match student list page

  @override
  void initState() {
    super.initState();
    _fetchWeeklySchedual(); // Changed to use the new fetch method
  }

  // New method to handle loading state consistently
  void _fetchWeeklySchedual() {
    setState(() {
      _isLoading = true; // Set loading to true before fetching
    });

    fetchWeeklySchedual().then((_) {
      // Data loading is complete
      setState(() {
        _isLoading = false; // Set loading to false after fetching
      });
    }).catchError((error) {
      // Error occurred during fetching
      setState(() {
        _isLoading = false; // Ensure loading is set to false on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载数据失败：$error')),
      );
    });
  }

  // Modified to return Future<void> and not handle loading state directly
  Future<void> fetchWeeklySchedual() async {
    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.weeklySchedualDateForOneYear}';

    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      List<dynamic> jsonList = json.decode(decodedBody);
      setState(() {
        staticLsnList = jsonList
            .map((json) => Kn05S002FixedLsnStatusBean.fromJson(json))
            .toList();
      });
    } else {
      throw Exception('Failed to load weekly schedual');
    }
  }

  // 显示进度对话框
  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('正在执行排课，请稍候...'),
              ],
            ),
          ),
        );
      },
    );
  }

  // 执行排课
  Future<void> executeWeeklySchedual(
      int weekNumber, String startDate, String endDate) async {
    _showProgressDialog(); // 显示进度对话框

    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.weeklySchedualExcute}/$startDate/$endDate';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      Navigator.pop(context); // 关闭进度对话框

      if (response.statusCode == 200) {
        // Use the new fetch method
        _fetchWeeklySchedual(); // Modified to use new method
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('排课成功！')),
        );
      } else {
        throw Exception('Failed to execute weekly schedual');
      }
    } catch (e) {
      Navigator.pop(context); // 确保错误时也关闭进度对话框
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('排课失败：$e')),
      );
    }
  }

  // 撤销排课
  Future<void> cancelWeeklySchedual(
      int weekNumber, String startDate, String endDate) async {
    _showProgressDialog(); // 显示进度对话框

    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.weeklySchedualCancel}/$startDate/$endDate/$weekNumber';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      Navigator.pop(context); // 关闭进度对话框

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        if (responseBody == "ok") {
          _fetchWeeklySchedual(); // 刷新页面
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('撤销成功！')),
          );
        } else {
          // 显示错误消息
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('撤销失败'),
                content: Text(responseBody),
                actions: <Widget>[
                  TextButton(
                    child: const Text('确定'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        throw Exception('Failed to cancel weekly schedual');
      }
    } catch (e) {
      Navigator.pop(context); // 确保错误时也关闭进度对话框
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('撤销失败：$e')),
      );
    }
  }

  String formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    return DateFormat('MM-dd').format(dateTime);
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed, // Disable button when loading
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          minimumSize: const Size(60, 30),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      ),
    );
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
        subtitleTextColor: Colors.white, // 自定义底部文本颜色
        titleFontSize: 20.0, // 自定义标题字体大小
        subtitleFontSize: 12.0, // 自定义底部文本字体大小
        addInvisibleRightButton: true,
        leftBalanceCount: 1, // [Flutter页面主题改造] 2026-01-19 添加左侧平衡使标题居中
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: widget.knFontColor),
            // Disable popup menu button when loading
            onSelected: _isLoading
                ? null
                : (String result) {
                    if (result == 'prepay') {
                      print('预支付学费被选中');
                    }
                  },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'prepay',
                child: Text('年度周次生成'),
              ),
            ],
          ),
        ],
      ),
      // Modified body to use Stack for overlay loading indicator
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(child: Text('周次', textAlign: TextAlign.center)),
                    Expanded(child: Text('开始日', textAlign: TextAlign.center)),
                    Expanded(child: Text('结束日', textAlign: TextAlign.center)),
                    Expanded(child: Text('操作', textAlign: TextAlign.center)),
                  ],
                ),
              ),
              Expanded(
                child: staticLsnList.isEmpty && !_isLoading
                    ? const Center(child: Text("暂无数据"))
                    : ListView.separated(
                        itemCount: staticLsnList.length,
                        separatorBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Divider(
                            color: Colors.grey[300],
                            height: 1,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final item = staticLsnList[index];
                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                    child: Text(
                                        '第${item.weekNumber.toString().padLeft(2, '0')}周',
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    child: Text(formatDate(item.startWeekDate),
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    child: Text(formatDate(item.endWeekDate),
                                        textAlign: TextAlign.center)),
                                Expanded(
                                  child: Center(
                                    child: item.fixedStatus == 0
                                        ? _buildButton(
                                            '排课',
                                            Colors.blue,
                                            () => executeWeeklySchedual(
                                                item.weekNumber,
                                                item.startWeekDate,
                                                item.endWeekDate))
                                        : _buildButton(
                                            '撤销',
                                            Colors.red,
                                            () => cancelWeeklySchedual(
                                                item.weekNumber,
                                                item.startWeekDate,
                                                item.endWeekDate)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // Loading indicator overlay
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
