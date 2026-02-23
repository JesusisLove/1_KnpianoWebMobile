// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kn_piano/ApiConfig/KnApiConfig.dart';
import 'package:kn_piano/Constants.dart';

import '../../CommonProcess/customUI/KnAppBar.dart';

// ignore: must_be_immutable
class BankStuAddEdit extends StatefulWidget {
  BankStuAddEdit({
    super.key,
    this.bankId,
    this.showMode,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  }) {
    // 在构造体内将 titleName 初期化
    titleName = "科目級別情報（$showMode）";
    subtitle = '$pagePath >> $titleName';
  }

  final String? bankId;
  final String? showMode;
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  // titleName を追加
  late final String titleName;
  late final String subtitle;

  @override
  _BankStuAddEditState createState() => _BankStuAddEditState();
}

class _BankStuAddEditState extends State<BankStuAddEdit> {
  String? bankId;
  String? stuId;
  String? stuName;
  int? delFlg;

  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedStudent;

  @override
  void initState() {
    super.initState();
    bankId = widget.bankId;
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final String apiUrl = '${KnConfig.apiBaseUrl}${Constants.studentInfoView}';
    var response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      setState(() {
        _students = List<Map<String, dynamic>>.from(
            json.decode(utf8.decode(response.bodyBytes)));
      });
    } else {
      // Handle error
      print("Error fetching students: ${response.body}");
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
        addInvisibleRightButton: false, // 显示Home按钮返回主菜单
        currentNavIndex: 2,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedStudent,
                items: _students.map((student) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: student,
                    child: Text(student['stuName']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStudent = value;
                    stuId = value?['stuId']; // Set the selected student ID
                    stuName =
                        value?['stuName']; // Set the selected student name
                  });
                },
                decoration: const InputDecoration(
                  labelText: '学生姓名',
                  labelStyle: TextStyle(color: Constants.stuDocThemeColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Constants.stuDocThemeColor,
                      width: Constants.enabledBorderSideWidth,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Constants.stuDocThemeColor,
                      width: Constants.focusedBorderSideWidth,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请选择学生姓名';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
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
                  Text('正在登录学生银行信息...'),
                ],
              ),
            ),
          );
        },
      );

      _formKey.currentState!.save();

      // 科目新规编辑画面，点击“保存”按钮的url请求
      final String apiUrl = '${KnConfig.apiBaseUrl}${Constants.stuBankAdd}';
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'bankId': bankId,
          'stuId': stuId,
          'stuName': stuName,
          'delFlg': delFlg,
        }),
      );

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('提交成功'),
            content: const Text('科目信息已保存'),
            actions: <Widget>[
              TextButton(
                onPressed: () => {
                  // 直接退回到一览画面
                  Navigator.of(context).pop(),
                  Navigator.of(context).pop(true) // 关闭当前页面并返回成功标识
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('提交失败'),
            content: Text('错误: ${response.body}'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }
}
