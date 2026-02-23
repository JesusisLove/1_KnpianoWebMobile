// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kn_piano/03StuDocMngmnt/4stuDoc/Kn03D004StuDocBean.dart';
import 'dart:convert';

import 'package:kn_piano/Constants.dart';

import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-21 添加主题扩展
import '../../CommonProcess/customUI/KnLoadingIndicator.dart'; // 导入自定义加载指示器
import 'kn03D004StuDoc_Add.dart';
import 'kn03D004StuDoc_Edit.dart';

// ignore: must_be_immutable
class StudentDocDetailPage extends StatefulWidget {
  StudentDocDetailPage({
    super.key,
    this.stuId,
    required this.stuName,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });
  final String? stuId;
  final String? stuName;
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;

  @override
  _StudentDocDetailPageState createState() => _StudentDocDetailPageState();
}

class _StudentDocDetailPageState extends State<StudentDocDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false; // 添加加载状态变量

  // 使用 ValueNotifier 来管理状态
  final ValueNotifier<List<Kn03D004StuDocBean>> stuDocNotifier =
      ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 1, vsync: this); // 只有一个选项卡，修改为length: 1
    _fetchStudentData();
  }

  // 统一的数据加载方法
  Future<void> _fetchStudentData() async {
    setState(() {
      _isLoading = true; // 开始加载前设置为true
    });

    try {
      // 获取已入档案学生
      final String apiStuDocUrl =
          '${KnConfig.apiBaseUrl}${Constants.stuDocDetailView}/${widget.stuId}';
      final responseStuDoc = await http.get(Uri.parse(apiStuDocUrl));

      if (responseStuDoc.statusCode == 200) {
        final decodedBody = utf8.decode(responseStuDoc.bodyBytes);
        List<dynamic> stuDocJson = json.decode(decodedBody);
        stuDocNotifier.value = stuDocJson
            .map((json) => Kn03D004StuDocBean.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load archived students');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching student data: $e');
    } finally {
      setState(() {
        _isLoading = false; // 加载完成后设置为false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
        // 设置本页面的标题：例如 邱彦涛 的科目明细，要求邱彦涛的名字底下有下划线。
        title: '${widget.stuName}\u{0332} 的科目级别明细', // \u{0332} 是下划线 Unicode 字符,
        subtitle: '${widget.pagePath} >> ${widget.stuName}\u{0332} 的科目级别明细',
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
        leftBalanceCount: 1, // [Flutter页面主题改造] 2026-01-19 添加左侧平衡使标题居中
        actions: [
          IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              // 新規"➕"按钮的事件处理函数
              onPressed: _isLoading
                  ? null // 如果正在加载，禁用按钮
                  : () {
                      Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (context) => StudentDocumentPage(
                                    stuId: widget.stuId,
                                    stuName: widget.stuName,
                                    knBgColor: widget.knBgColor,
                                    knFontColor: widget.knFontColor,
                                    pagePath: widget.pagePath,
                                  ))).then((value) => {
                            if (value == true) {_fetchStudentData()}
                          });
                    }),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildStudentList(stuDocNotifier),
            ],
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

  // 新增：格式化年度计划总课时显示文本
  String _formatYearLsnCnt(Kn03D004StuDocBean student) {
    // 如果是按月付费且有年度计划总课时数据
    if (student.payStyle == 1 && student.yearLsnCnt > 0) {
      return '年计划: ${student.yearLsnCnt}课时';
    }
    return ''; // 课时付费或没有数据时返回空字符串
  }

  // 新增：根据payStyle获取价格标签文本
  String _getPriceLabelText(int payStyle) {
    return payStyle == 1 ? '课费（元/月）' : '单价（元/时）';
  }

  // 新增：根据payStyle计算显示价格
  double _getDisplayPrice(Kn03D004StuDocBean student) {
    double basePrice = student.lessonFeeAdjusted > 0
        ? student.lessonFeeAdjusted
        : student.lessonFee;

    // 如果是按月付费，价格乘以4
    return student.payStyle == 1 ? basePrice * 4 : basePrice;
  }

  // 风格二：編集、削除
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
            final yearLsnCntText = _formatYearLsnCnt(student);
            final priceLabelText = _getPriceLabelText(student.payStyle);
            final displayPrice = _getDisplayPrice(student);

            return ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage('images/student-placeholder.png'),
              ),
              title: Text(
                '${student.subjectName} ${student.subjectSubName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行：课程单价和级别调整日期
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$priceLabelText: ＄${displayPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '级别调整日期: ${student.adjustedDate.substring(0, 10)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  // 第二行：年度计划总课时（只在有数据时显示）
                  if (yearLsnCntText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          yearLsnCntText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          student.payStyle == 1 ? '按月付费' : '课时付费',
                          style: TextStyle(
                            fontSize: 14,
                            color: student.payStyle == 1
                                ? Colors.blue[600]
                                : Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // 如果没有年度计划总课时，也显示支付方式
                  if (yearLsnCntText.isEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Spacer(),
                        Text(
                          student.payStyle == 1 ? '按月付费' : '课时付费',
                          style: TextStyle(
                            fontSize: 14,
                            color: student.payStyle == 1
                                ? Colors.blue[600]
                                : Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: PopupMenuButton<String>(
                enabled: !_isLoading, // 如果正在加载，禁用按钮
                onSelected: (String result) {
                  switch (result) {
                    case 'edit':
                      // 编辑
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentDocumentEditPage(
                            stuId: student.stuId,
                            subjectId: student.subjectId,
                            subjectSubId: student.subjectSubId,
                            adjustedDate: student.adjustedDate,
                            knBgColor: widget.knBgColor,
                            knFontColor: widget.knFontColor,
                            pagePath: widget.pagePath,
                          ),
                        ),
                      ).then((value) {
                        if (value == true) {
                          // 如果编辑成功，刷新学生列表
                          _fetchStudentData();
                        }
                      });
                      break;
                    case 'delete':
                      // 删除
                      // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('删除确认',
                                style: KnElementTextStyle.dialogTitle(context,
                                    color: Constants.stuDocThemeColor)),
                            content: Text('确定要删除【${student.subjectName}】这门科目吗？',
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
                                  _deleteSubjectEdaBan(
                                      student.stuId,
                                      student.subjectId,
                                      student.subjectSubId,
                                      student.adjustedDate);
                                  Navigator.of(context).pop(true);
                                },
                              ),
                            ],
                          );
                        },
                      );
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('编辑'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('删除'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 科目级别一览里的删除按钮按下事件
  void _deleteSubjectEdaBan(String stuId, String subjectId, String subjectSubId,
      String adjustedDate) async {
    setState(() {
      _isLoading = true; // 开始删除操作前设置为true
    });

    final String deleteUrl =
        '${KnConfig.apiBaseUrl}${Constants.stuDocInfoDelete}/$stuId/$subjectId/$subjectSubId/$adjustedDate';
    try {
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      setState(() {
        _isLoading = false; // 操作完成后设置为false
      });

      if (response.statusCode == 200) {
        // 删除成功后重新获取数据
        await _fetchStudentData();

        // 检查 stuDocNotifier 中的数据量
        if (stuDocNotifier.value.isEmpty) {
          // 如果数据为空，关闭当前页面
          Navigator.of(context).pop(true);
        }
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

  @override
  void dispose() {
    _tabController.dispose();
    stuDocNotifier.dispose();
    super.dispose();
  }
}
