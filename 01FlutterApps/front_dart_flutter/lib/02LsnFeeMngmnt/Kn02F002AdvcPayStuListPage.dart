// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../ApiConfig/KnApiConfig.dart';
import '../Constants.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../CommonProcess/customUI/KnLoadingIndicator.dart';
import '../theme/theme_extensions.dart';
import 'Kn02F002AdvcPayStuBean.dart';
import 'Kn02F003AdvcLsnFeePayPage.dart';
import 'Kn02F004AdvcLsnFeePayPerLsnPage.dart';

class Kn02F002AdvcPayStuListPage extends StatefulWidget {
  final Color knBgColor;
  final Color knFontColor;
  final String pagePath;

  const Kn02F002AdvcPayStuListPage({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  @override
  _Kn02F002AdvcPayStuListPageState createState() =>
      _Kn02F002AdvcPayStuListPageState();
}

class _Kn02F002AdvcPayStuListPageState
    extends State<Kn02F002AdvcPayStuListPage> with TickerProviderStateMixin {
  List<Kn02F002AdvcPayStuBean> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  final int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fetchStudents();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          '${KnConfig.apiBaseUrl}${Constants.apiAdvcAllStu}/$selectedYear'));
      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _students = data
              .map((item) => Kn02F002AdvcPayStuBean.fromJson(item))
              .toList();
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Kn02F002AdvcPayStuBean> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.displayName.toLowerCase().contains(q) ||
          s.stuId.toLowerCase().contains(q);
    }).toList();
  }

  void _onStudentTap(Kn02F002AdvcPayStuBean stu) {
    if (stu.hasMonthly && !stu.hasPerLsn) {
      _openF003(stu);
    } else if (!stu.hasMonthly && stu.hasPerLsn) {
      _openF004(stu);
    } else {
      _showPayTypeBottomSheet(stu);
    }
  }

  void _openF003(Kn02F002AdvcPayStuBean stu) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Kn02F003AdvcLsnFeePayPage(
        stuId: stu.stuId,
        stuName: stu.displayName,
        knBgColor: widget.knBgColor,
        knFontColor: widget.knFontColor,
        pagePath: widget.pagePath,
        selectedYear: selectedYear,
      ),
    );
  }

  void _openF004(Kn02F002AdvcPayStuBean stu) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Kn02F004AdvcLsnFeePayPerLsnPage(
        stuId: stu.stuId,
        stuName: stu.displayName,
        knBgColor: widget.knBgColor,
        knFontColor: widget.knFontColor,
        pagePath: widget.pagePath,
        selectedYear: selectedYear,
      ),
    );
  }

  void _showPayTypeBottomSheet(Kn02F002AdvcPayStuBean stu) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                stu.displayName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.calendar_month,
                  color: widget.knBgColor),
              title: const Text('预支付学费（按月）'),
              onTap: () {
                Navigator.pop(context);
                _openF003(stu);
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_list_numbered,
                  color: Colors.blue),
              title: const Text('预支付学费（按课时）'),
              onTap: () {
                Navigator.pop(context);
                _openF004(stu);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _getCardColor(int index) {
    final colors = [
      Colors.pink.shade300,
      Colors.purple.shade300,
      Colors.indigo.shade300,
      Colors.teal.shade300,
      Colors.orange.shade300,
      Colors.cyan.shade400,
    ];
    return colors[index % colors.length];
  }

  Widget _buildPayStyleTags(Kn02F002AdvcPayStuBean stu) {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      alignment: WrapAlignment.center,
      children: [
        if (stu.hasMonthly)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: widget.knBgColor.withOpacity(0.15),
              border: Border.all(color: widget.knBgColor, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              stu.monthlySubjectNames != null &&
                      stu.monthlySubjectNames!.isNotEmpty
                  ? '按月 ${stu.monthlySubjectNames}'
                  : '按月',
              style: TextStyle(
                  fontSize: 10,
                  color: widget.knBgColor,
                  fontWeight: FontWeight.bold),
            ),
          ),
        if (stu.hasPerLsn)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.12),
              border: Border.all(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              stu.perLsnSubjectNames != null &&
                      stu.perLsnSubjectNames!.isNotEmpty
                  ? '按课时 ${stu.perLsnSubjectNames}'
                  : '按课时',
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentCard(Kn02F002AdvcPayStuBean stu, int index) {
    final cardColor = _getCardColor(index);
    return Card(
      elevation: 3,
      shadowColor: cardColor.withOpacity(0.3),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _onStudentTap(stu),
        borderRadius: BorderRadius.circular(16),
        splashColor: cardColor.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: cardColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor.withOpacity(0.8), cardColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                stu.displayName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KnElementTextStyle.cardTitle(context,
                    fontSize: 13, color: cardColor),
              ),
              const SizedBox(height: 6),
              _buildPayStyleTags(stu),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
        title: '学费预先支付',
        subtitle: widget.pagePath,
        context: context,
        appBarBackgroundColor: widget.knBgColor,
        titleColor: Color.fromARGB(
          widget.knFontColor.alpha,
          widget.knFontColor.red - 20,
          widget.knFontColor.green - 20,
          widget.knFontColor.blue - 20,
        ),
        subtitleBackgroundColor: Color.fromARGB(
          255,
          (widget.knBgColor.red * 0.6).round(),
          (widget.knBgColor.green * 0.6).round(),
          (widget.knBgColor.blue * 0.6).round(),
        ),
        subtitleTextColor: Colors.white,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
        currentNavIndex: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: widget.knFontColor),
            onPressed: _fetchStudents,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索学生...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // 学生人数提示
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '共 ${_filteredStudents.length} 名学生',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          // 学生卡片列表
          Expanded(
            child: _isLoading
                ? Center(
                    child: KnLoadingIndicator(color: widget.knBgColor))
                : _filteredStudents.isEmpty
                    ? const Center(child: Text('没有找到学生'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) => _buildStudentCard(
                            _filteredStudents[index], index),
                      ),
          ),
        ],
      ),
    );
  }
}
