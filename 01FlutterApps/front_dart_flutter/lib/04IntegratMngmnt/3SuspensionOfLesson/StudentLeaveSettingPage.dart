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

  // 新增保存功能（含退学前学费查账）
  Future<void> saveSelectedStudents() async {
    if (selectedStudents.isEmpty) {
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
      _isLoading = true;
    });

    // 对每位学生进行学费查账
    List<KnStu001Bean> feeOkList = [];
    List<Map<String, dynamic>> feePendingList = []; // {student, unpaidFees}

    for (final student in selectedStudents) {
      try {
        final String feeCheckUrl =
            '${KnConfig.apiBaseUrl}${Constants.intergStuFeeCheck}/${student.stuId}';
        final response = await http.get(Uri.parse(feeCheckUrl));
        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          final List<dynamic> unpaidJson = json.decode(decodedBody);
          if (unpaidJson.isEmpty) {
            feeOkList.add(student);
          } else {
            feePendingList.add({'student': student, 'unpaidFees': unpaidJson});
          }
        } else {
          // 查账失败时，保守处理：不退学，视为有欠费
          feePendingList.add({'student': student, 'unpaidFees': []});
        }
      } catch (_) {
        feePendingList.add({'student': student, 'unpaidFees': []});
      }
    }

    // 学费已交齐的学生：统一执行退学
    int withdrawnCount = 0;
    if (feeOkList.isNotEmpty) {
      final ok = await _executeWithdraw(feeOkList);
      if (ok) withdrawnCount += feeOkList.length;
    }

    setState(() {
      _isLoading = false;
    });

    // 有欠费的学生：逐个弹出欠费明细对话框
    for (final item in feePendingList) {
      if (!mounted) break;
      final student = item['student'] as KnStu001Bean;
      final unpaidFees = item['unpaidFees'] as List<dynamic>;

      // 计算合计（传给对话框和二次确认框）
      double total = 0;
      for (final fee in unpaidFees) {
        total += (fee['lsnFee'] as num?)?.toDouble() ?? 0;
      }

      // 欠费明细对话框：返回 true = 用户点了"强行退学"
      final wantsForceLeave =
          await _showUnpaidFeeDialog(student, unpaidFees, total);

      if (wantsForceLeave && mounted) {
        // 二次确认对话框（含坏账理由输入）
        final memo =
            await _showForceLeaveConfirmDialog(student.stuName, total);
        if (memo != null && mounted) {
          setState(() => _isLoading = true);
          final ok = await _executeForceLeave(student.stuId, memo);
          if (mounted) setState(() => _isLoading = false);
          if (ok) withdrawnCount++;
        }
      }
    }

    if (!mounted) return;

    if (withdrawnCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('退学处理成功（$withdrawnCount 名）'),
          backgroundColor: widget.knBgColor,
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  // 批量退学（学费已交齐）
  Future<bool> _executeWithdraw(List<KnStu001Bean> students) async {
    try {
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.intergStuLeaveExecute}';
      final List<Map<String, dynamic>> body = students
          .map((s) => {'stuId': s.stuId, 'stuName': s.stuName})
          .toList();
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 强行退学（批量坏账 + 退学）
  Future<bool> _executeForceLeave(String stuId, String memo) async {
    try {
      final uri = Uri.parse(
        '${KnConfig.apiBaseUrl}${Constants.intergStuForceLeave}/$stuId',
      ).replace(queryParameters: {'memo': memo});
      final response = await http.post(uri);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 欠费明细对话框（账单风格，返回 true = 用户点击了"强行退学"）
  Future<bool> _showUnpaidFeeDialog(
      KnStu001Bean student, List<dynamic> unpaidFees, double total) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 标题栏 ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.knBgColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long,
                          color: widget.knFontColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '未结算账单',
                        style: TextStyle(
                          color: widget.knFontColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── 账单信息头 ───────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.stuName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '出单日期：$dateStr',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                      // 未结算状态标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              '未结算',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // ── 列标题 ───────────────────────────────────
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 7),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text('科目',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                                fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('月份',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                                fontWeight: FontWeight.bold)),
                      ),
                      Text('金额',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                // ── 欠费明细列表 ─────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    child: unpaidFees.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('（查账失败，无法确认欠费详情）',
                                style:
                                    TextStyle(color: Colors.black45)),
                          )
                        : Column(
                            children: unpaidFees
                                .asMap()
                                .entries
                                .map((entry) {
                              final i = entry.key;
                              final fee = entry.value;
                              final subject =
                                  fee['subjectName'] ?? '';
                              final sub =
                                  fee['subjectSubName'] ?? '';
                              final month = fee['lsnMonth'] ?? '';
                              final amount =
                                  (fee['lsnFee'] as num?)
                                      ?.toDouble() ??
                                  0;
                              final subjectLabel =
                                  sub.isNotEmpty ? '$subject($sub)' : subject;

                              return Container(
                                color: i.isOdd
                                    ? Colors.grey.shade50
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 9),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        subjectLabel,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        month,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    Text(
                                      '¥${amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                // ── 合计行 ───────────────────────────────────
                if (unpaidFees.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('合计  ',
                            style: TextStyle(
                                fontSize: 13, color: Colors.black45)),
                        Text(
                          '¥ ${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                ],
                // ── 按钮区 ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        child: const Text('知道了',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        child: const Text('强行退学'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  // 强行退学二次确认对话框（返回 memo 字符串 = 用户确认执行，null = 取消）
  Future<String?> _showForceLeaveConfirmDialog(
      String stuName, double totalFee) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ForceLeaveConfirmDialog(
        stuName: stuName,
        totalFee: totalFee,
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

class _ForceLeaveConfirmDialog extends StatefulWidget {
  final String stuName;
  final double totalFee;

  const _ForceLeaveConfirmDialog({
    required this.stuName,
    required this.totalFee,
  });

  @override
  State<_ForceLeaveConfirmDialog> createState() =>
      _ForceLeaveConfirmDialogState();
}

class _ForceLeaveConfirmDialogState extends State<_ForceLeaveConfirmDialog> {
  final TextEditingController _memoController = TextEditingController();
  bool _showTextField = true;
  bool _showError = false;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_memoController.text.trim().isEmpty) {
      setState(() {
        _showTextField = false;
        _showError = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showTextField = true;
            _showError = false;
          });
        }
      });
      return;
    }
    Navigator.pop(context, _memoController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 红色标题栏
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: Colors.red,
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '强行退学确认',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.stuName} 的未付款课费（合计 ¥${widget.totalFee.toStringAsFixed(0)}）将全部标记为坏账，此操作不可撤销。',
                  ),
                  const SizedBox(height: 12),
                  if (_showTextField)
                    TextField(
                      controller: _memoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '坏账理由（必填）',
                        border: OutlineInputBorder(),
                        hintText: '请输入坏账处理理由',
                      ),
                    ),
                  if (_showError)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '请务必填写理由才可以执行坏账操作！',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            // 按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('取消',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _onConfirm,
                    child: const Text('确认'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
