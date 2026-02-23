/// 学生入学管理

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // 引入 intl 包来格式化日期
import 'package:kn_piano/ApiConfig/KnApiConfig.dart'; // API配置文件
import 'package:kn_piano/CommonProcess/customUI/FormFields.dart'; // 共通控件作成（所有窗体控件统一标准）
import 'package:kn_piano/Constants.dart';

import '../../CommonProcess/customUI/KnAppBar.dart'; // 引入包含全局常量的文件

// ignore: must_be_immutable
class StudentAdd extends StatefulWidget {
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  StudentAdd(
      {super.key,
      required this.knBgColor,
      required this.knFontColor,
      required this.pagePath});

  @override
  StudentAddState createState() => StudentAddState();
}

class StudentAddState extends State<StudentAdd> {
  final titleName = "学生信息登录";
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _stuNameController = TextEditingController();
  final TextEditingController _nikNameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _birthdayController =
      TextEditingController(); // 控制器用于管理日期输入
  final List<TextEditingController> _telsController =
      List.generate(4, (_) => TextEditingController());
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postCodeController = TextEditingController();
  final TextEditingController _introducerController = TextEditingController();

  String? stuName;
  String? nikName;
  String? gender;
  String? birthday;
  List<String?> telephones = List.filled(4, null);
  String? address;
  String? postCode;
  String? introducer;

  final FocusNode _stuNameFocusNode = FocusNode();
  final FocusNode _nikNameFocusNode = FocusNode();
  final FocusNode _genderFocusNode = FocusNode();
  final FocusNode _birthdayFocusNode = FocusNode();
  final List<FocusNode?> _telephonesNode = List.filled(4, null);
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _postCodeFocusNode = FocusNode();
  final FocusNode _introducerFocusNode = FocusNode();

  Color _stuNameColor = Colors.black;
  Color _nikNameColor = Colors.black;
  Color _genderColor = Colors.black;
  Color _birthdayColor = Colors.black;
  final List<Color> _telephonesColor = List.generate(4, (_) => Colors.black);
  Color _addressColor = Colors.black;
  Color _postCodeColor = Colors.black;
  Color _introducerColor = Colors.black;

  @override
  void initState() {
    super.initState();

    // 获得焦点时的标签字体颜色
    _stuNameFocusNode.addListener(() {
      setState(() => _stuNameColor = _stuNameFocusNode.hasFocus
          ? Constants.stuDocThemeColor
          : Colors.black);
    });

    _nikNameFocusNode.addListener(() {
      setState(() => _nikNameColor = _nikNameFocusNode.hasFocus
          ? Constants.stuDocThemeColor
          : Colors.black);
    });

    _genderFocusNode.addListener(() {
      setState(() => _genderColor = _genderFocusNode.hasFocus
          ? Constants.stuDocThemeColor
          : Colors.black);
    });

    _birthdayFocusNode.addListener(() {
      setState(() => _birthdayColor = _birthdayFocusNode.hasFocus
          ? Constants.stuDocThemeColor
          : Colors.black);
    });
    // 初始化电话号码的 FocusNode
    for (int i = 0; i < _telephonesNode.length; i++) {
      _telephonesNode[i] = FocusNode();
      _telephonesNode[i]!.addListener(() {
        setState(() => _telephonesColor[i] = _telephonesNode[i]!.hasFocus
            ? Constants.stuDocThemeColor
            : Colors.black);
      });
    }
    _addressFocusNode.addListener(() {
      setState(() => _addressColor = _addressFocusNode.hasFocus
          ? Constants.stuDocThemeColor
          : Colors.black);
    });

    _postCodeFocusNode.addListener(() {
      setState(() => _postCodeColor = _postCodeFocusNode.hasFocus
          ? Constants.stuDocThemeColor
          : Colors.black);
    });

    _introducerFocusNode.addListener(() {
      setState(() => _introducerColor = _introducerFocusNode.hasFocus
          ? Constants.stuDocThemeColor
          : Colors.black);
    });
  }

  @override
  void dispose() {
    // 释放控制器资源
    _stuNameController.dispose();
    _nikNameController.dispose();
    _genderController.dispose();
    _birthdayController.dispose();
    for (final controller in _telsController) {
      controller.dispose();
    }
    _addressController.dispose();
    _postCodeController.dispose();
    _introducerController.dispose();

    // 释放FocusNode资源
    _stuNameFocusNode.dispose();
    _nikNameFocusNode.dispose();
    _genderFocusNode.dispose();
    _birthdayFocusNode.dispose();

    for (var node in _telephonesNode) {
      node!.removeListener(() {});
      node.dispose();
    }
    _addressFocusNode.dispose();
    _postCodeFocusNode.dispose();
    _introducerFocusNode.dispose();
    super.dispose();
  }

  // 日期选择处理
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthday != null
          ? DateFormat('yyyy/MM/dd').parse(birthday!)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthday = DateFormat('yyyy/MM/dd').format(picked);
        _birthdayController.text = birthday!; // 更新文本字段内容
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String subtitle = "${widget.pagePath} >> $titleName";
    return Scaffold(
      appBar: KnAppBar(
        title: titleName,
        subtitle: subtitle,
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
        currentNavIndex: 2,
        subtitleTextColor: Colors.white, // 自定义底部文本颜色
        titleFontSize: 20.0, // 自定义标题字体大小
        subtitleFontSize: 12.0, // 自定义底部文本字体大小
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FormFields.createTextFormField(
                inputFocusNode: _stuNameFocusNode,
                inputLabelText: '学生姓名',
                inputLabelColor: _stuNameColor,
                // initialValue: stuName, //编辑模式下的一个坑：👈手动输入一个新数据后，一回车就还原成了旧数据
                inputController: _stuNameController,
                themeColor: Constants.stuDocThemeColor,
                enabledBorderSideWidth: Constants.enabledBorderSideWidth,
                focusedBorderSideWidth: Constants.focusedBorderSideWidth,
                onSave: (value) => stuName = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入学生姓名';
                  }
                  return null;
                },
              ),
              FormFields.createTextFormField(
                inputFocusNode: _nikNameFocusNode,
                inputLabelText: '姓名略称',
                inputLabelColor: _nikNameColor,
                inputController: _nikNameController,
                themeColor: Constants.stuDocThemeColor,
                enabledBorderSideWidth: Constants.enabledBorderSideWidth,
                focusedBorderSideWidth: Constants.focusedBorderSideWidth,
                onSave: (value) => nikName = value,
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return '请输入学生姓名';
                //   }
                //   return null;
                // },
              ),
              DropdownButtonFormField<String>(
                focusNode: _genderFocusNode,
                value: gender,
                decoration: InputDecoration(
                  labelText: '学生性别',
                  labelStyle: TextStyle(color: _genderColor),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Constants.stuDocThemeColor,
                        width: Constants.enabledBorderSideWidth), // 未聚焦时的边框颜色
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Constants.stuDocThemeColor,
                        width: Constants.focusedBorderSideWidth), // 聚焦时的边框颜色
                  ),
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: '1', // 用于提交的值为1
                    child: Text('男'), // 显示为“男”
                  ),
                  DropdownMenuItem<String>(
                    value: '2', // 用于提交的值为2
                    child: Text('女'), // 显示为“女”
                  )
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    gender = newValue;
                  });
                },
                validator: (String? value) => value == null ? '请选择性别' : null,
              ),
              FormFields.createTextFormField(
                inputFocusNode: _birthdayFocusNode,
                inputController: _birthdayController, // 使用控制器
                inputLabelText: '出生日',
                inputLabelColor: _birthdayColor,
                themeColor: Constants.stuDocThemeColor,
                enabledBorderSideWidth: Constants.enabledBorderSideWidth,
                focusedBorderSideWidth: Constants.focusedBorderSideWidth,
                blnReadOnly: true, // 设置为只读
                onTap: () => _selectDate(context), // 点击时调用日期选择器
                onSave: (value) => birthday = value,
              ),
              ...List.generate(
                  4,
                  (index) => FormFields.createTextFormField(
                        inputFocusNode: _telephonesNode[index]!,
                        inputLabelText: '联系电话${index + 1}',
                        inputController: _telsController[index],
                        inputLabelColor: _telephonesColor[index],
                        themeColor: Constants.stuDocThemeColor,
                        enabledBorderSideWidth:
                            Constants.enabledBorderSideWidth,
                        focusedBorderSideWidth:
                            Constants.focusedBorderSideWidth,
                        onSave: (value) => telephones[index] = value,
                      )),
              FormFields.createTextFormField(
                inputFocusNode: _postCodeFocusNode,
                inputLabelText: '邮政编号',
                inputController: _postCodeController,
                inputLabelColor: _postCodeColor,
                themeColor: Constants.stuDocThemeColor,
                enabledBorderSideWidth: Constants.enabledBorderSideWidth,
                focusedBorderSideWidth: Constants.focusedBorderSideWidth,
                onSave: (value) => postCode = value,
              ),
              FormFields.createTextFormField(
                inputFocusNode: _addressFocusNode,
                inputLabelText: '家庭住址',
                inputController: _addressController,
                inputLabelColor: _addressColor,
                themeColor: Constants.stuDocThemeColor,
                enabledBorderSideWidth: Constants.enabledBorderSideWidth,
                focusedBorderSideWidth: Constants.focusedBorderSideWidth,
                onSave: (value) => address = value,
              ),
              FormFields.createTextFormField(
                inputFocusNode: _introducerFocusNode,
                inputLabelText: '介绍人',
                inputController: _introducerController,
                inputLabelColor: _introducerColor,
                themeColor: Constants.stuDocThemeColor,
                enabledBorderSideWidth: Constants.enabledBorderSideWidth,
                focusedBorderSideWidth: Constants.focusedBorderSideWidth,
                onSave: (value) => introducer = value,
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

  // 点击保存按钮
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
                  Text('正在登记学生信息...'),
                ],
              ),
            ),
          );
        },
      );
      _formKey.currentState!.save();

      // 学生档案菜单画面，点击“保存”按钮的url请求
      final String apiUrl = '${KnConfig.apiBaseUrl}${Constants.studentInfoAdd}';

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'stuName': stuName,
          'nikName': nikName,
          'gender': gender,
          'birthday': birthday,
          'tel1': telephones.isNotEmpty ? telephones[0] : null,
          'tel2': telephones.isNotEmpty ? telephones[1] : null,
          'tel3': telephones.isNotEmpty ? telephones[2] : null,
          'tel4': telephones.isNotEmpty ? telephones[3] : null,
          'address': address,
          'postCode': postCode,
          'introducer': introducer,
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
            content: const Text('学生信息已保存'),
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
