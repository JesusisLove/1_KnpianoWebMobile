import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kn_piano/03StuDocMngmnt/1studentBasic/knstu001_list.dart';
import 'package:kn_piano/03StuDocMngmnt/2subjectBasic/knsub001_list.dart';
import 'package:kn_piano/05SettingMngmnt/4FixedLesson/knfixlsn001_list.dart';
// [Flutter页面主题改造] 2026-01-18 添加Provider支持，用于检测当前主题
import 'package:provider/provider.dart';
import '01LessonMngmnt/1LessonSchedual/CalendarPage.dart';
import '02LsnFeeMngmnt/Kn02f005FeeMonthlyReportPage.dart';
import '02LsnFeeMngmnt/Kn02F006ExtraLsnReport.dart';
import '03StuDocMngmnt/3bankBasic/kn03D003Bnk_list.dart';
import '03StuDocMngmnt/4stuDoc/kn03D004StuDoc_list.dart';
import '04IntegratMngmnt/Kn04I003LsnCounting.dart';
import '04IntegratMngmnt/SubSubjectOfStudentsListBySubject.dart';
import '04IntegratMngmnt/3SuspensionOfLesson/StudentLeaveListPage.dart';
import '05SettingMngmnt/5BatchArrangeLessonManual/Kn05S002WeekCalculatorSchedual.dart';
// [Flutter页面主题改造] 2026-01-18 添加主题设置页面导入
import '05SettingMngmnt/6ThemeSetting/ThemeSettingPage.dart';
// [应用锁定功能] 2026-02-18 添加安全设置页面导入（含PIN修改和自动锁定时间设置）
import 'security/security_setting_page.dart';
import 'ApiConfig/KnApiConfig.dart';
import 'CommonProcess/StudentNameMenuCommon.dart';
import 'Constants.dart' as consts;
import 'Constants.dart'; // 引入包含全局常量的文件
// [Flutter页面主题改造] 2026-01-17 添加主题系统支持
import 'theme/kn_theme_colors.dart';
import 'theme/providers/theme_provider.dart';

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  late int currentNavIndex;

  HomePage({
    super.key,
    required this.currentNavIndex,
  });

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // 钢琴Logo Widget
  Widget _buildPianoLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // 钢琴键盘图标
          Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Stack(
              children: [
                // 白键
                Positioned(
                  bottom: 0,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Expanded(child: _PianoKey(isBlack: false)),
                      SizedBox(width: 1),
                      Expanded(child: _PianoKey(isBlack: false)),
                      SizedBox(width: 1),
                      Expanded(child: _PianoKey(isBlack: false)),
                      SizedBox(width: 1),
                      Expanded(child: _PianoKey(isBlack: false)),
                    ],
                  ),
                ),
                // 黑键
                Positioned(
                  bottom: 15,
                  left: 15,
                  right: 15,
                  child: Row(
                    children: [
                      Expanded(child: _PianoKey(isBlack: true)),
                      SizedBox(width: 8),
                      Expanded(child: _PianoKey(isBlack: true)),
                      SizedBox(width: 8),
                      Expanded(child: SizedBox()),
                      SizedBox(width: 8),
                      Expanded(child: _PianoKey(isBlack: true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 标题
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ).createShader(bounds),
            child: const Text(
              'KN Piano Studio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            '钢琴课程管理系统${KnConfig.environmentName}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // [Flutter页面主题改造] 2026-01-17 改造为使用主题系统获取颜色
  // 获取页面标题和描述
  Map<String, dynamic> _getPageInfo(int index) {
    // 从主题系统获取模块颜色渐变
    final gradient = KnModuleMapper.getModuleGradientByIndex(context, index);

    switch (index) {
      case 0:
        return {
          'title': '上课管理',
          'subtitle': '课程安排与进度跟踪',
          'gradient': gradient,
        };
      case 1:
        return {
          'title': '学费管理',
          'subtitle': '学费收支与财务统计',
          'gradient': gradient,
        };
      case 2:
        return {
          'title': '档案管理',
          'subtitle': '学生信息与档案维护',
          'gradient': gradient,
        };
      case 3:
        return {
          'title': '综合管理',
          'subtitle': '统计分析与综合查询',
          'gradient': gradient,
        };
      case 4:
        return {
          'title': '设置管理',
          'subtitle': '系统配置与个性化设置',
          'gradient': gradient,
        };
      default:
        return {
          'title': '管理系统',
          'subtitle': '欢迎使用',
          'gradient': gradient,
        };
    }
  }

  // 创建方块按钮
  Widget _buildSquareButton({
    required IconData iconData,
    required String text,
    required String description,
    required VoidCallback onPressed,
    required List<Color> gradient,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50, // 图标的宽度
                  height: 50, // 图标的高度
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    iconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                // 每个按钮的名称显示【例如：加课消化管理】
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 每个按钮里的功能描述【例如：管理补课安排】
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // [Flutter页面主题改造] 2026-01-18 创建童话风格按钮（手绘风格边框、白色背景）
  Widget _buildFairytaleButton({
    required IconData iconData,
    required String text,
    required String description,
    required VoidCallback onPressed,
    required Color borderColor,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // 手绘风格：使用双重边框模拟手绘效果
        // [Flutter页面主题改造] 2026-01-19 调细边框线宽度
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          // 外层阴影模拟手绘的不规则感
          BoxShadow(
            color: borderColor.withOpacity(0.15),
            blurRadius: 0,
            spreadRadius: 2,
            offset: const Offset(3, 3),
          ),
          // 内层柔和阴影
          BoxShadow(
            color: borderColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 装饰性小元素（角落的小星星/小点）
              Positioned(
                top: 8,
                right: 12,
                child: Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 14,
                    color: borderColor.withOpacity(0.6),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 12,
                child: Text(
                  '·',
                  style: TextStyle(
                    fontSize: 24,
                    color: borderColor.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 主要内容 - 使用Center确保完全居中
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 图标容器 - 简单线条风格
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: borderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor.withOpacity(0.3),
                            width: 1, // [Flutter页面主题改造] 2026-01-19 调细边框线宽度
                          ),
                        ),
                        child: Icon(
                          iconData,
                          color: borderColor.withOpacity(0.8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 按钮名称 - 使用模块主题颜色
                      Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: borderColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 功能描述 - 使用模块主题颜色（稍淡）
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: borderColor.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [Flutter页面主题改造] 2026-01-18 修改方块网格布局，根据主题选择按钮样式
  Widget _buildGridButtons(
      List<Map<String, dynamic>> buttonData, List<Color> gradient) {
    // 检测当前是否为童话风格主题
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isFairytaleTheme = themeProvider.currentThemeId == 'fairytale';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28), // 左右边距大小调整
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 32, // 方块按钮间的纵向间距
          mainAxisSpacing: 48, // 方块按钮间的横向间距
          childAspectRatio: 1.2,
        ),
        itemCount: buttonData.length,
        itemBuilder: (context, index) {
          final button = buttonData[index];
          // 根据主题选择按钮样式
          if (isFairytaleTheme) {
            return _buildFairytaleButton(
              iconData: button['icon'],
              text: button['text'],
              description: button['description'],
              onPressed: button['onPressed'],
              borderColor: gradient[0], // 使用主色作为边框颜色
            );
          } else {
            return _buildSquareButton(
              iconData: button['icon'],
              text: button['text'],
              description: button['description'],
              onPressed: button['onPressed'],
              gradient: gradient,
            );
          }
        },
      ),
    );
  }

  List<Widget> getPageWidgets(int index) {
    switch (index) {
      case 0:
        // 上课管理页面 - [Flutter页面主题改造] 2026-01-26 使用主题系统动态颜色
        final lessonColor = KnThemeColors.getLessonColors(context).primary;
        final lessonButtons = [
          {
            'icon': Icons.schedule,
            'text': "学生课程表",
            'description': "课程表排课签到",
            'onPressed': () {
              DateTime dateTime = DateTime.now();
              String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          CalendarPage(focusedDay: formattedDate)));
            },
          },
          {
            'icon': Icons.timeline,
            'text': "上课进度管理",
            'description': "跟踪课程进度",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StudentNameMenuCommon(
                            knBgColor: lessonColor,
                            knFontColor: Colors.white,
                            pagePath: "上课进度管理>>在课学生一览",
                            pageId: Constants.kn01L002LsnStatistic,
                            strUri: Constants.lsnInfoStuName,
                          )));
            },
          },
          {
            'icon': Icons.add_circle_outline,
            'text': "加课消化管理",
            'description': "管理补课安排",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StudentNameMenuCommon(
                            knBgColor: lessonColor,
                            knFontColor: Colors.white,
                            pagePath: "加课消化管理>>在课学生一览",
                            pageId: Constants.kn01L003ExtraToSche,
                            strUri: Constants.lsnExtraInfoStuName,
                          )));
            },
          },
          {
            'icon': Icons.merge_type,
            'text': "碎课拼成整课",
            'description': "整合零散课时",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StudentNameMenuCommon(
                            knBgColor: lessonColor,
                            knFontColor: Colors.white,
                            pagePath: "碎课拼成整课>>在课学生一览",
                            pageId: Constants.kn01L003ExtraPiesesIntoOne,
                            strUri: Constants.piceseLsnStuName,
                          )));
            },
          },
        ];
        // [Flutter页面主题改造] 2026-01-17 使用主题系统颜色
        return [
          _buildGridButtons(lessonButtons,
              KnModuleMapper.getModuleGradientByIndex(context, 0))
        ];

      case 1:
        // 学费管理页面 - [Flutter页面主题改造] 2026-01-26 使用主题系统动态颜色
        final feeColor = KnThemeColors.getFeeColors(context).primary;
        final feeButtons = [
          {
            'icon': Icons.payment,
            'text': "学费支付管理",
            'description': "处理学费缴纳",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StudentNameMenuCommon(
                            knBgColor: feeColor,
                            knFontColor: Colors.white,
                            pagePath: "学费支付管理>>在课学生一览",
                            pageId: Constants.stuLsnFeeListPage,
                            strUri: Constants.apiStuNameByYear,
                          )));
            },
          },
          {
            'icon': Icons.forward,
            'text': "学费预先支付",
            'description': "提前缴费管理",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StudentNameMenuCommon(
                            knBgColor: feeColor,
                            knFontColor: Colors.white,
                            pagePath: "学费预先支付>>在课学生一览",
                            pageId: Constants.kn02F003AdvcLsnFeePayPage,
                            strUri: Constants.apiCurrentStuName,
                            disableYearPicker: true,
                          )));
            },
          },
          {
            'icon': Icons.assessment,
            'text': "学费月度报告",
            'description': "财务统计报告",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MonthlyIncomeReportPage(
                            knBgColor: feeColor,
                            knFontColor: Colors.white,
                            pagePath: "学费管理",
                          )));
            },
          },
          {
            'icon': Icons.assignment_add,
            'text': "加课处理报告",
            'description': "查看加课支付/未支付状况",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Kn02F006ExtraLsnReport(
                            knBgColor: feeColor,
                            knFontColor: Colors.white,
                            pagePath: "学费管理",
                          )));
            },
          },
        ];
        // [Flutter页面主题改造] 2026-01-17 使用主题系统颜色
        return [
          _buildGridButtons(
              feeButtons, KnModuleMapper.getModuleGradientByIndex(context, 1))
        ];

      case 2:
        // 档案管理页面 - [Flutter页面主题改造] 2026-01-26 使用主题系统动态颜色
        final archiveColor = KnThemeColors.getArchiveColors(context).primary;
        final docButtons = [
          {
            'icon': Icons.school,
            'text': "学生基本信息",
            'description': "入学报名登记",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StuEditList(
                            knBgColor: archiveColor,
                            knFontColor: Colors.white,
                            pagePath: "档案管理",
                          )));
            },
          },
          {
            'icon': Icons.book,
            'text': "科目基本信息",
            'description': "钢琴乐理等科目管理",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SubjectViewPage(
                            knBgColor: archiveColor,
                            knFontColor: Colors.white,
                            pagePath: "档案管理",
                          )));
            },
          },
          {
            'icon': Icons.account_balance,
            'text': "银行基本信息",
            'description': "支付银行登记管理",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BankViewPage(
                            knBgColor: archiveColor,
                            knFontColor: Colors.white,
                            pagePath: "档案管理",
                          )));
            },
          },
          {
            'icon': Icons.folder_open,
            'text': "学生档案管理",
            'description': "学生各科目档案记录",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StudentDocPage(
                            knBgColor: archiveColor,
                            knFontColor: Colors.white,
                            pagePath: "档案管理",
                          )));
            },
          },
        ];
        // [Flutter页面主题改造] 2026-01-17 使用主题系统颜色
        return [
          _buildGridButtons(
              docButtons, KnModuleMapper.getModuleGradientByIndex(context, 2))
        ];

      case 3:
        // 综合管理页面 - [Flutter页面主题改造] 2026-01-26 使用主题系统动态颜色
        final summaryColor = KnThemeColors.getSummaryColors(context).primary;
        final integrationButtons = [
          {
            'icon': Icons.person_off,
            'text': "学生休学退学",
            'description': "学生休学退学处理",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StudentLeaveListPage(
                            knBgColor: summaryColor,
                            knFontColor: Colors.white,
                            pagePath: "综合管理",
                          )));
            },
          },
          {
            'icon': Icons.emoji_events,
            'text': "钢琴级别查看",
            'description': "学生钢琴级别查看",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SubSubjectOfStudentsListBySubject(
                            knBgColor: summaryColor,
                            knFontColor: Colors.white,
                            pagePath: "综合管理",
                          )));
            },
          },
          {
            'icon': Icons.analytics,
            'text': "课时统计查看",
            'description': "课程进度统计分析",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Kn04I003LsnCounting(
                            knBgColor: summaryColor,
                            knFontColor: Colors.white,
                            pagePath: "学费管理",
                          )));
            },
          },
          {
            'icon': Icons.receipt_long,
            'text': "年度账单明细",
            'description': "年度财务报表",
            'onPressed': () {},
          },
        ];
        // [Flutter页面主题改造] 2026-01-17 使用主题系统颜色
        return [
          _buildGridButtons(integrationButtons,
              KnModuleMapper.getModuleGradientByIndex(context, 3))
        ];

      case 4:
        // 设置管理页面
        final settingsButtons = [
          {
            'icon': Icons.calendar_month,
            'text': "周次排课设置",
            'description': "钢琴自动排课处理",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Kn05S002WeekCalculatorSchedual(
                            knBgColor: consts.Constants.settngThemeColor,
                            knFontColor: Colors.white,
                            pagePath: "设置管理",
                          )));
            },
          },
          // [应用锁定功能] 2026-02-18 安全设置（PIN修改 + 自动锁定时间）
          // [页面布局调整] 2026-02-21 从第5位移到第2位，替换多国语言切换卡片
          {
            'icon': Icons.security,
            'text': "安全设置",
            'description': "PIN码与自动锁定时间",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SecuritySettingPage(
                            knBgColor: consts.Constants.settngThemeColor,
                            knFontColor: Colors.white,
                            pagePath: "设置管理",
                          )));
            },
          },
          {
            'icon': Icons.settings,
            'text': "固定排课设置",
            'description': "固定上课时间配置",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ClassSchedulePage(
                            knBgColor: consts.Constants.settngThemeColor,
                            knFontColor: Colors.white,
                            pagePath: "设置管理",
                          )));
            },
          },
          {
            'icon': Icons.palette,
            'text': "选项设置",
            // [页面布局调整] 2026-02-21 多国语言切换功能合并到选项设置
            'description': "主题风格与语言切换",
            'onPressed': () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ThemeSettingPage(
                            knBgColor: consts.Constants.settngThemeColor,
                            knFontColor: Colors.white,
                            pagePath: "设置管理",
                          )));
            },
          },
        ];
        // [Flutter页面主题改造] 2026-01-17 使用主题系统颜色
        return [
          _buildGridButtons(settingsButtons,
              KnModuleMapper.getModuleGradientByIndex(context, 4))
        ];

      default:
        return [const Text("未定义页面")];
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageInfo = _getPageInfo(widget.currentNavIndex);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Logo区域
              _buildPianoLogo(),

              // [Flutter页面主题改造] 2026-01-18 页面标题区域，上课管理模块使用背景图片
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // 上课管理模块(index=0)使用背景图片，其他模块使用渐变色
                  // image: widget.currentNavIndex == 0
                  // ? null
                  // const DecorationImage(
                  // image: AssetImage('images/lesson_header_bg.jpg'),
                  // fit: BoxFit.cover,
                  // )
                  // : null,
                  gradient:
                      // widget.currentNavIndex != 0
                      //     ?
                      LinearGradient(
                    colors: pageInfo['gradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  // : null
                  ,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: pageInfo['gradient'][0].withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pageInfo['title'],
                            style: TextStyle(
                              fontSize: 24,
                              // [Flutter页面主题改造] 2026-01-20 fontWeight从JSON配置读取
                              fontWeight: Provider.of<ThemeProvider>(context, listen: false)
                                  .currentConfig.typography.elements.moduleTitle.fontWeight,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pageInfo['subtitle'],
                            style: TextStyle(
                              fontSize: 14,
                              // [Flutter页面主题改造] 2026-01-20 fontWeight从JSON配置读取
                              fontWeight: Provider.of<ThemeProvider>(context, listen: false)
                                  .currentConfig.typography.elements.moduleSubtitle.fontWeight,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

              // 功能按钮区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      bottom: 100, top: 36), // 功能按钮区域与第一行方块按钮的间距 top:10
                  child: Column(
                    children: getPageWidgets(widget.currentNavIndex),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          // [Flutter页面主题改造] 2026-01-18 上课管理图标改为双音符♫，支持选中颜色变化
          // [Flutter页面主题改造] 2026-01-19 修复底部导航栏文字对齐问题
          // [Flutter页面主题改造] 2026-01-20 修复上课管理图标被遮挡问题，fontSize从24调整为20
          items: [
            // [Flutter页面主题改造] 2026-01-21 修复音符图标垂直居中问题，添加height:1.0
            BottomNavigationBarItem(
                icon: const SizedBox(
                    height: 24,
                    child: Center(
                        child: Text('♫',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                                height: 1.0)))),
                activeIcon: SizedBox(
                    height: 24,
                    child: Center(
                        child: Text('♫',
                            style: TextStyle(
                                fontSize: 20,
                                color: _getPageInfo(0)['gradient'][0],
                                height: 1.0)))),
                label: '上课管理'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.attach_money), label: '学费管理'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.engineering), label: '档案管理'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: '综合管理'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: '设置管理'),
          ],
          currentIndex: widget.currentNavIndex,
          selectedItemColor: _getPageInfo(widget.currentNavIndex)['gradient']
              [0],
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12, // 统一字体大小以确保对齐
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      widget.currentNavIndex = index;
    });
  }
}

// 钢琴键组件
class _PianoKey extends StatelessWidget {
  final bool isBlack;

  const _PianoKey({required this.isBlack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isBlack ? 20 : 30,
      decoration: BoxDecoration(
        color: isBlack ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: isBlack
            ? null
            : Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
    );
  }
}
