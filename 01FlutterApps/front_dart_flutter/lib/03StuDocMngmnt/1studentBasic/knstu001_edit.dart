/// 学生入学管理

import 'dart:convert';
// import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // 引入 intl 包来格式化日期
import 'package:kn_piano/ApiConfig/KnApiConfig.dart'; // API配置文件
import 'package:kn_piano/CommonProcess/customUI/FormFields.dart'; // 共通控件作成（所有窗体控件统一标准）
import 'package:kn_piano/Constants.dart';

import '../../CommonProcess/customUI/KnAppBar.dart';
import 'KnStu001Bean.dart'; // 引入包含全局常量的文件

// ignore: must_be_immutable
class StudentEdit extends StatefulWidget {
  final KnStu001Bean? student;
  // AppBar背景颜色
  final Color knBgColor;
  // 字体颜色
  final Color knFontColor;
  // 画面迁移路径：例如，上课进度管理>>学生姓名一览>> xxx的课程进度状况
  late String pagePath;

  StudentEdit(
      {super.key,
      this.student,
      required this.knBgColor,
      required this.knFontColor,
      required this.pagePath});

  @override
  StudentEditState createState() => StudentEditState();
}

class StudentEditState extends State<StudentEdit> {
  final String titleName = "学生信息登录";
  final _formKey = GlobalKey<FormState>();
  // 往后端提交新数据的退避变量
  String? stuId;
  String? stuName;
  String? nikName;
  int? gender;
  String? birthday;
  List<String?> telephones = List.filled(4, null);
  String? address;
  String? postCode;
  String? introducer;
  int? delFlg;

// 用上一级传过来的List对象，初期化画面的项目数据
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

// 为画面控件定义它对应的焦点对象
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
    if (widget.student != null) {
      // 单纯地把变量映射给后端javaBean对应的项目
      stuId = widget.student!.stuId;
      delFlg = widget.student!.delFlg;

      // 把上一级画面传过来的student，赋值给TextFormField
      _stuNameController.text = widget.student!.stuName;
      _nikNameController.text = widget.student!.nikName;
      _birthdayController.text = widget.student!.birthday;
      _telsController[0].text = widget.student!.tel1;
      _telsController[1].text = widget.student!.tel2;
      _telsController[2].text = widget.student!.tel3;
      _telsController[3].text = widget.student!.tel4;
      _addressController.text = widget.student!.address;
      _postCodeController.text = widget.student!.postCode;
      _introducerController.text = widget.student!.introducer;
    }

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

  // 释放控制器资源
  @override
  void dispose() {
    // 释放TextFormField资源
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

    // 释放TextFormField资源
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
      initialDate: (widget.student?.birthday != null &&
              widget.student!.birthday.isNotEmpty)
          ? DateFormat('yyyy/MM/dd').parse(widget.student!.birthday)
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
    return Scaffold(
      appBar: KnAppBar(
        title: titleName,
        subtitle: "${widget.pagePath} >> $titleName",
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
        actions: [
          // 如果需要，可以在这里添加额外的操作按钮
        ],
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
                inputController: _stuNameController, // 让控件在公共方法里定义
                inputLabelColor: _stuNameColor,
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
                onSave: (value) =>
                    {print("nikName onSave被触发，值为: $value"), nikName = value},
                validator: (value) {
                  // if (value == null || value.isEmpty) {
                  //   return '请输入学生姓名';
                  // }
                  return null;
                },
              ),
              DropdownButtonFormField<int>(
                focusNode: _genderFocusNode,
                value: widget.student!.gender,
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
                  DropdownMenuItem<int>(
                    value: 1, // 用于提交的值为1
                    child: Text('男'), // 显示为“男”
                  ),
                  DropdownMenuItem<int>(
                    value: 2, // 用于提交的值为2
                    child: Text('女'), // 显示为“女”
                  )
                ],
                onChanged: (int? newValue) {
                  setState(() {
                    gender = newValue;
                  });
                },
                validator: (int? value) => value == null ? '请选择性别' : null,
              ),
              FormFields.createTextFormField(
                inputFocusNode: _birthdayFocusNode,
                inputLabelText: '出生日',
                initialValue: birthday,
                inputLabelColor: _birthdayColor,
                inputController: _birthdayController,
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
                  Text('正在更新学生信息...'),
                ],
              ),
            ),
          );
        },
      );
      _formKey.currentState!.save();

      // 学生档案菜单画面，点击“保存”按钮的url请求
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.studentInfoEdit}';

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'stuId': stuId,
          'stuName': stuName ?? widget.student!.stuName,
          'nikName': nikName ?? widget.student!.nikName,
          'gender': gender ?? widget.student!.gender,
          'birthday': birthday ?? widget.student!.birthday,
          'tel1': telephones.isNotEmpty ? telephones[0] : null,
          'tel2': telephones.isNotEmpty ? telephones[1] : null,
          'tel3': telephones.isNotEmpty ? telephones[2] : null,
          'tel4': telephones.isNotEmpty ? telephones[3] : null,
          'address': address ?? widget.student!.address,
          'postCode': postCode ?? widget.student!.postCode,
          'introducer': introducer ?? widget.student!.introducer,
          'delFlg': delFlg ?? 0,
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
            title: const Text('更新成功'),
            content: const Text('学生信息已更新'),
            actions: <Widget>[
              TextButton(
                onPressed: () => {
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
