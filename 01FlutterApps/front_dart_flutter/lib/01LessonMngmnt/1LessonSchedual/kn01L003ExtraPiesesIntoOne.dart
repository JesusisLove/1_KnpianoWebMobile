// ignore: file_names
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../../ApiConfig/KnApiConfig.dart';
import '../../../CommonProcess/customUI/KnAppBar.dart';
import '../../../CommonProcess/customUI/KnLoadingIndicator.dart';
import '../../Constants.dart';
import '../../../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-21 添加主题扩展

// 零碎课数据模型
class Kn01L003ExtraPicesesBean {
  final String lessonId;
  final String oldLessonId;
  final String subjectId;
  final String subjectSubId;
  final String subjectName;
  final String subjectSubName;
  final String stuId;
  final String stuName;
  String? nikName; //因为从后台返回的nikName有可能是NULL
  final int classDuration;
  final int minutesPerLsn;
  final DateTime scanQrDate;

  Kn01L003ExtraPicesesBean({
    required this.lessonId,
    required this.oldLessonId,
    required this.subjectId,
    required this.subjectSubId,
    required this.subjectName,
    required this.subjectSubName,
    required this.stuId,
    required this.stuName,
    this.nikName,
    required this.classDuration,
    required this.minutesPerLsn,
    required this.scanQrDate,
  });

  factory Kn01L003ExtraPicesesBean.fromJson(Map<String, dynamic> json) {
    DateTime parsedScanQrDate = DateTime.now();

    try {
      if (json['scanQrDate'] != null &&
          json['scanQrDate'].toString().isNotEmpty) {
        parsedScanQrDate = DateTime.parse(json['scanQrDate']);
      }
    } catch (e) {
      print('Error parsing scanQrDate: $e');
    }

    return Kn01L003ExtraPicesesBean(
      lessonId: json['lessonId'] ?? '',
      oldLessonId: json['oldLessonId'] ?? '',
      subjectId: json['subjectId'] ?? '',
      subjectSubId: json['subjectSubId'] ?? '',
      subjectName: json['subjectName'] ?? '',
      subjectSubName: json['subjectSubName'] ?? '',
      stuId: json['stuId'] ?? '',
      stuName: json['stuName'] ?? '',
      nikName: json['nikName'] ?? '',
      classDuration: json['classDuration'] ?? 0,
      minutesPerLsn: json['minutesPerLsn'] ?? 0,
      scanQrDate: parsedScanQrDate,
    );
  }

  String get formattedScanQrDate => DateFormat('yyyy-MM-dd').format(scanQrDate);
}

// 学生课程文档数据模型
class Kn03D004StuDocBean {
  final String stuId;
  final String stuName;
  final String? nikName;
  final String subjectId;
  final String subjectSubId;
  final int minutesPerLsn;

  Kn03D004StuDocBean({
    required this.stuId,
    required this.stuName,
    this.nikName,
    required this.subjectId,
    required this.subjectSubId,
    required this.minutesPerLsn,
  });

  factory Kn03D004StuDocBean.fromJson(Map<String, dynamic> json) {
    return Kn03D004StuDocBean(
      stuId: json['stuId'] ?? '',
      stuName: json['stuName'] ?? '',
      nikName: json['nikName'],
      subjectId: json['subjectId'] ?? '',
      subjectSubId: json['subjectSubId'] ?? '',
      minutesPerLsn: json['minutesPerLsn'] ?? 0,
    );
  }
}

// ignore: must_be_immutable
class Kn01L003ExtraPiesesIntoOne extends StatefulWidget {
  Kn01L003ExtraPiesesIntoOne({
    super.key,
    required this.stuId,
    required this.stuName,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
    required this.selectedYear,
  });

  final String stuId;
  final String stuName;
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  final int selectedYear;

  @override
  _Kn01L003ExtraPiesesIntoOneState createState() =>
      _Kn01L003ExtraPiesesIntoOneState();
}

class _Kn01L003ExtraPiesesIntoOneState
    extends State<Kn01L003ExtraPiesesIntoOne> {
  final String titleName = '零碎加课拼整课';

  // 数据相关
  List<Kn01L003ExtraPicesesBean> allPieces = [];
  List<Kn01L003ExtraPicesesBean> availablePieces = [];
  List<Kn01L003ExtraPicesesBean> selectedPieces = [];
  List<Kn03D004StuDocBean> latestPrices = [];

  // 业务逻辑相关
  String sourceIds = '';
  String baseSubjectId = '';
  String baseSubjectName = '';
  int totalClassDuration = 0;
  int targetMinutesPerLsn = 0;
  String targetSubjectSubId = '';
  String targetSubjectSubName = '';
  bool _isLoading = false;

  // 新增：日期时间相关
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    widget.pagePath = '${widget.pagePath} >> $titleName';
    _fetchData();
  }

  // 获取所有数据
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _fetchPiecesData(),
        _fetchLatestPrices(),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 获取零碎课数据
  Future<void> _fetchPiecesData() async {
    try {
      final String currentYear = widget.selectedYear.toString(); // 使用传递过来的年度参数
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.piceseLsnIntoOne}/$currentYear/${widget.stuId}';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> piecesJson = json.decode(decodedBody);

        allPieces = piecesJson
            .map((json) => Kn01L003ExtraPicesesBean.fromJson(json))
            .toList();
        availablePieces = List.from(allPieces);
      } else {
        throw Exception('Failed to load pieces');
      }
    } catch (e) {
      print('Error fetching pieces: $e');
      throw e;
    }
  }

  // 获取学生最新课程价格
  Future<void> _fetchLatestPrices() async {
    try {
      final String currentYear = widget.selectedYear.toString(); // 使用传递过来的年度参数
      // 在URL路径中包含年度和学生ID
      final String apiUrl =
          '${KnConfig.apiBaseUrl}${Constants.latestLsnPrice}/$currentYear/${widget.stuId}';

      // 使用GET请求
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> pricesJson = json.decode(decodedBody);

        latestPrices = pricesJson
            .map((json) => Kn03D004StuDocBean.fromJson(json))
            .toList();
      } else {
        throw Exception('API调用失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching latest prices: $e');
      throw e;
    }
  }

  // 计算进度百分比
  double get progressPercentage {
    if (targetMinutesPerLsn == 0) return 0.0;
    return (totalClassDuration / targetMinutesPerLsn).clamp(0.0, 1.0);
  }

  // 检查是否达到100%进度
  bool get isCompleted => progressPercentage >= 1.0 && targetMinutesPerLsn > 0;

  // 取消拼凑功能 - 新增的方法
  void _cancelAssembly() {
    setState(() {
      // 将所有已选择的零碎课放回可用列表
      availablePieces.addAll(selectedPieces);

      // 清空选中列表
      selectedPieces.clear();

      // 重置所有状态
      sourceIds = '';
      baseSubjectId = '';
      baseSubjectName = '';
      totalClassDuration = 0;
      targetMinutesPerLsn = 0;
      targetSubjectSubId = '';
      targetSubjectSubName = '';
      selectedDateTime = null; // 重置选择的日期时间
    });
  }

  // 新增：选择日期时间的方法 - 修复本地化问题
  Future<void> _selectDateTime() async {
    try {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDateTime ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        // 移除 locale 参数，让它使用系统默认的本地化设置
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: widget.knBgColor, // 使用页面主题色
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: widget.knBgColor, // 按钮颜色
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        final TimeOfDay? pickedTime = await showTimePicker(
          // ignore: use_build_context_synchronously
          context: context,
          initialTime:
              TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: widget.knBgColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: widget.knBgColor,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          setState(() {
            selectedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          });
        }
      }
    } catch (e) {
      // 如果日期选择器出现错误，显示错误消息
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('提示'),
            content: const Text('日期选择器出现问题，请稍后重试'),
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

  // 新增：格式化选择的日期时间
  String get formattedSelectedDateTime {
    if (selectedDateTime == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!);
  }

  // 处理拖拽逻辑
  void _onPieceDragged(Kn01L003ExtraPicesesBean piece) {
    // 如果已经达到100%，禁止继续拖拽
    if (isCompleted) return;

    print('拖拽课程: ${piece.subjectId}/${piece.subjectSubId}');
    print('当前价格信息数量: ${latestPrices.length}');

    // 检查科目一致性
    if (selectedPieces.isEmpty) {
      // 第一次拖拽，设置基准值
      baseSubjectId = piece.subjectId;
      baseSubjectName = piece.subjectName;

      // 从最新价格列表中查找对应的课程信息
      try {
        final targetPrice = latestPrices.firstWhere(
          (price) {
            print(
                '比较: ${price.subjectId}/${price.subjectSubId} vs ${piece.subjectId}/${piece.subjectSubId}');
            return price.subjectId == piece.subjectId &&
                price.subjectSubId == piece.subjectSubId;
          },
        );

        targetMinutesPerLsn = targetPrice.minutesPerLsn;
        targetSubjectSubId = targetPrice.subjectSubId;
        targetSubjectSubName = piece.subjectSubName;

        print(
            '找到匹配的价格信息: ${targetPrice.subjectId}/${targetPrice.subjectSubId} - ${targetPrice.minutesPerLsn}分钟');
      } catch (e) {
        print('未找到匹配的价格信息，可用的价格信息:');
        for (var price in latestPrices) {
          print('  - ${price.subjectId}/${price.subjectSubId}');
        }

        // 如果找不到精确匹配，尝试只匹配 subjectId
        try {
          final fallbackPrice = latestPrices.firstWhere(
            (price) => price.subjectId == piece.subjectId,
          );

          targetMinutesPerLsn = fallbackPrice.minutesPerLsn;
          targetSubjectSubId = fallbackPrice.subjectSubId;
          targetSubjectSubName =
              fallbackPrice.subjectSubId; // 使用价格信息中的subjectSubId

          print(
              '使用fallback价格信息: ${fallbackPrice.subjectId}/${fallbackPrice.subjectSubId} - ${fallbackPrice.minutesPerLsn}分钟');
        } catch (e2) {
          _showErrorDialog(
              '未找到课程 ${piece.subjectName}(${piece.subjectId}) 的价格信息，无法进行拼凑。');
          return;
        }
      }
    } else {
      // 后续拖拽，检查科目是否一致
      if (piece.subjectId != baseSubjectId) {
        _showSubjectMismatchDialog();
        return;
      }
    }

    // *** 新增：检查累加后是否会超过目标时长 ***
    int newTotalDuration = totalClassDuration + piece.classDuration;
    if (newTotalDuration > targetMinutesPerLsn) {
      _showErrorDialog('累加时长超出限制！\n'
          '当前累计：$totalClassDuration 分钟\n'
          '添加课程：${piece.classDuration} 分钟\n'
          '累加后总计：$newTotalDuration 分钟\n'
          '目标时长：$targetMinutesPerLsn 分钟\n\n'
          '零碎课的累计时长必须严格等于目标课程时长！');
      return;
    }

    setState(() {
      // 从可用列表移除，添加到已选列表
      availablePieces.remove(piece);
      selectedPieces.add(piece);

      // 更新sourceIds
      if (sourceIds.isEmpty) {
        sourceIds = piece.lessonId;
      } else {
        sourceIds += ',${piece.lessonId}';
      }

      // 更新累计时长
      totalClassDuration = newTotalDuration; // 使用计算后的值
    });
  }

  // 从选中区域移除零碎课
  void _removePieceFromSelected(Kn01L003ExtraPicesesBean piece) {
    setState(() {
      selectedPieces.remove(piece);
      availablePieces.add(piece);

      // 更新sourceIds
      List<String> ids = sourceIds.split(',');
      ids.remove(piece.lessonId);
      sourceIds = ids.join(',');

      // 更新累计时长
      totalClassDuration -= piece.classDuration;

      // 如果没有选中的课程了，重置所有状态
      if (selectedPieces.isEmpty) {
        baseSubjectId = '';
        baseSubjectName = '';
        targetMinutesPerLsn = 0;
        targetSubjectSubId = '';
        targetSubjectSubName = '';
        selectedDateTime = null; // 重置选择的日期时间
      }
    });
  }

  // 显示错误对话框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('错误'),
          content: Text(message),
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

  // 显示科目不匹配对话框
  void _showSubjectMismatchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('不同科目的课程不能拼凑，请重新确认。'),
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

  // 保存并执行加课换正课
  Future<void> _saveAndExecute() async {
    if (selectedPieces.isEmpty || !isCompleted) return;

    // 新增：校验日期时间是否已选择
    if (selectedDateTime == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('提示'),
            content: const Text('请选择换成整课的日期时间'),
            actions: <Widget>[
              TextButton(
                child: const Text('确定'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    // 仿照参照代码的加载处理风格
    setState(() {
      _isLoading = true;
    });

    try {
      // 准备请求数据
      final firstPiece = selectedPieces.first;

      // 从最新价格列表中获取目标课程信息
      latestPrices.firstWhere(
        (price) =>
            price.subjectId == baseSubjectId &&
            price.subjectSubId == targetSubjectSubId,
      );

      final String apiUrl =
          '${KnConfig.apiBaseUrl}/liu/mb_kn_piceses_into_onelsn_sche';

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['sourceIds'] = sourceIds;
      request.fields['subjectId'] = baseSubjectId;
      request.fields['subjectSubId'] = targetSubjectSubId;
      request.fields['stuId'] = firstPiece.stuId;
      request.fields['subjectName'] = baseSubjectName;
      request.fields['subjectSubName'] = targetSubjectSubName;
      request.fields['standardDuration'] = targetMinutesPerLsn.toString();
      // 修改：使用用户选择的日期时间
      request.fields['scanQRDate'] = formattedSelectedDateTime;

      // 生成备注内容：来自零碎课 + 扫码日期列表
      String memoContent = '来自零碎课：' +
          selectedPieces.map((piece) => piece.formattedScanQrDate).join(',');
      request.fields['memo'] = memoContent;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // 成功后重置状态并重新加载数据
        setState(() {
          selectedPieces.clear();
          sourceIds = '';
          baseSubjectId = '';
          baseSubjectName = '';
          targetMinutesPerLsn = 0;
          targetSubjectSubId = '';
          targetSubjectSubName = '';
          totalClassDuration = 0;
          selectedDateTime = null; // 重置选择的日期时间
        });

        await _fetchData();

        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '加课换正课执行成功！',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: widget.knBgColor, // 使用页面主题色作为背景
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        throw Exception(responseBody);
      }
    } catch (e) {
      print('Error in _saveAndExecute: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('错误'),
              content: Text('操作失败: $e'),
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
    } finally {
      // 仿照参照代码的风格，无论成功还是失败，都将加载状态设置为false
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 构建1区 - 可用零碎课列表
  Widget _buildAvailablePiecesArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.knBgColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: widget.knBgColor),
                const SizedBox(width: 8),
                Text(
                  '可用零碎课 (${availablePieces.length}节)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.knBgColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: availablePieces.isEmpty
                ? const Center(
                    child: Text(
                      '暂无可用零碎课',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: availablePieces.length,
                    itemBuilder: (context, index) {
                      final piece = availablePieces[index];
                      return _buildDraggablePieceCard(piece);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 构建可拖拽的零碎课卡片
  Widget _buildDraggablePieceCard(Kn01L003ExtraPicesesBean piece) {
    // 只有在未完成100%且未加载时才允许拖拽
    bool isDraggingEnabled = !isCompleted && !_isLoading;

    return Draggable<Kn01L003ExtraPicesesBean>(
      data: piece,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 300,
          child: _buildPieceCard(piece, isDragging: true),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: _buildPieceCard(piece, isDisabled: true),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: _buildPieceCard(piece, isEnabled: isDraggingEnabled),
      ),
    );
  }

  // 构建零碎课卡片
  Widget _buildPieceCard(
    Kn01L003ExtraPicesesBean piece, {
    bool isDragging = false,
    bool isDisabled = false,
    bool isEnabled = true,
    bool showRemoveButton = false,
  }) {
    final isActiveCard = isEnabled && !isDisabled;

    return Card(
      elevation: isDragging ? 8 : 2,
      margin: EdgeInsets.zero,
      color: isDisabled ? Colors.grey[200] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isActiveCard
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActiveCard ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              '${piece.classDuration}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          '${piece.subjectName}: ${piece.subjectSubName}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActiveCard ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          '扫码日期: ${piece.formattedScanQrDate}',
          style: TextStyle(
            fontSize: 12,
            color: isActiveCard ? Colors.grey[600] : Colors.grey,
          ),
        ),
        trailing: showRemoveButton
            ? IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _removePieceFromSelected(piece),
              )
            : isActiveCard
                ? const Icon(Icons.drag_handle, color: Colors.grey)
                : null,
      ),
    );
  }

  // 构建新整课信息卡片 - 优化布局，解决溢出问题
  Widget _buildNewLessonCard() {
    return Container(
      padding: const EdgeInsets.all(8), // 减少外层padding
      child: Card(
        elevation: 4,
        color: Colors.green[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.green, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12), // 减少内层padding
          child: Column(
            mainAxisSize: MainAxisSize.min, // 重要：让Column使用最小空间
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部信息行 - 优化布局
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, // 缩小图标
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24, // 缩小图标
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '新整课: $baseSubjectName',
                          style: const TextStyle(
                            fontSize: 14, // 缩小字体
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '课程级别: $targetSubjectSubName',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '总时长: $totalClassDuration 分钟',
                          style: const TextStyle(fontSize: 12),
                        ),
                        // 将课程ID移到可展开的区域
                        if (sourceIds.length > 20) // 如果ID太长，简化显示
                          Text(
                            '拼凑课程: ${sourceIds.split(',').length}节课',
                            style: const TextStyle(fontSize: 12),
                          )
                        else
                          Text(
                            '拼凑课程ID: $sourceIds',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // 取消按钮 - 缩小尺寸
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextButton(
                      onPressed: _cancelAssembly,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                      child: Text(
                        '取消',
                        style: KnElementTextStyle.buttonText(context,
                            fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 日期时间选择区域 - 调整为紧凑布局，与取消按钮相似宽度
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    '换成整课的日期时间:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 日期时间选择按钮 - 紧凑设计，在加载时禁用
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            _isLoading ? Colors.grey[300]! : Colors.grey[400]!,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: _isLoading ? Colors.grey[200] : Colors.grey[50],
                    ),
                    child: InkWell(
                      onTap: _isLoading ? null : _selectDateTime,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 120, // 设置最小宽度，与取消按钮相似
                          maxWidth: 180, // 设置最大宽度，避免过宽
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: _isLoading
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                selectedDateTime == null
                                    ? '选择时间'
                                    : formattedSelectedDateTime,
                                style: TextStyle(
                                  color: _isLoading
                                      ? Colors.grey[400]
                                      : selectedDateTime == null
                                          ? Colors.grey[600]
                                          : Colors.black,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              color: _isLoading
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 留出底部空间
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // 构建2区 - 拖拽目标区域
  Widget _buildTargetArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '拼凑区域 (${selectedPieces.length}节)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // 进度条区域 - 只有选中了课程才显示
          if (selectedPieces.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '加课拼凑状况: $totalClassDuration/$targetMinutesPerLsn 分钟',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(progressPercentage * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercentage >= 1.0 ? Colors.green : Colors.blue,
                    ),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ],

          // 主内容区域 - 优化为可滚动的内容
          Expanded(
            child: DragTarget<Kn01L003ExtraPicesesBean>(
              onAccept: _onPieceDragged,
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? Colors.blue[200]
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: candidateData.isNotEmpty
                          ? Colors.blue
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? // 进度达到100%时，显示新生成的整课信息 - 使用SingleChildScrollView防止溢出
                      SingleChildScrollView(
                          child: _buildNewLessonCard(),
                        )
                      : selectedPieces.isEmpty
                          ? // 没有选中课程时，显示拖拽提示
                          const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.move_to_inbox,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '将零碎课拖拽到这里',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : // 有选中课程但未达到100%时，显示简洁的拖拽提示 - 使用SingleChildScrollView
                          SingleChildScrollView(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty,
                                      size: 48,
                                      color: Colors.blue[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '已拼凑 ${selectedPieces.length} 节课',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '继续拖拽零碎课到这里',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // 显示已拖拽课程的简要信息
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: selectedPieces
                                          .map((piece) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[100],
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${piece.classDuration}',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      piece.subjectSubName,
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _removePieceFromSelected(
                                                              piece),
                                                      child: const Icon(
                                                        Icons.close,
                                                        size: 16,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                );
              },
            ),
          ),

          // 保存按钮 - 只有进度达到100%时才显示，并在加载时禁用
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // 仿照参照代码的风格，在加载时禁用按钮
                onPressed: _isLoading ? null : _saveAndExecute,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('正在执行加课换正课处理...'),
                        ],
                      )
                    : const Text(
                        '保存并且执行加课换正课',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
        title: '${widget.stuName}的$titleName',
        subtitle: widget.pagePath,
        context: context,
        appBarBackgroundColor: widget.knBgColor,
        titleColor: Color.fromARGB(
          widget.knFontColor.alpha,
          widget.knFontColor.red - 20,
          widget.knFontColor.green - 20,
          widget.knFontColor.blue - 20,
        ),
        // [Flutter页面主题改造] 2026-01-26 副标题背景使用主题色的深色版本
        subtitleBackgroundColor: Color.fromARGB(
          widget.knBgColor.alpha,
          (widget.knBgColor.red * 0.6).round(),
          (widget.knBgColor.green * 0.6).round(),
          (widget.knBgColor.blue * 0.6).round(),
        ),
        subtitleTextColor: Colors.white,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
        addInvisibleRightButton: false,
        currentNavIndex: 0,
      ),
      body: Stack(
        children: [
          // 主要内容
          LayoutBuilder(
            builder: (context, constraints) {
              // 根据屏幕大小调整布局比例
              final isSmallScreen = constraints.maxHeight < 600;
              final isTablet = constraints.maxWidth > 600;

              return Padding(
                padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
                child: Column(
                  children: [
                    // 1区 - 可用零碎课列表
                    Expanded(
                      flex: isSmallScreen ? 2 : 3, // 小屏幕时减少比例
                      child: _buildAvailablePiecesArea(),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    // 2区 - 拖拽目标区域
                    Expanded(
                      flex: isSmallScreen ? 3 : 2, // 小屏幕时增加比例给拖拽区域
                      child: _buildTargetArea(),
                    ),
                  ],
                ),
              );
            },
          ),

          // 加载指示器 - 仿照参照代码的风格
          if (_isLoading)
            Center(
              child: KnLoadingIndicator(color: widget.knBgColor),
            ),
        ],
      ),
    );
  }
}
