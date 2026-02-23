import 'package:flutter/material.dart';
import '../01LessonMngmnt/1LessonSchedual/kn01L002LsnStatistic.dart';
import '../01LessonMngmnt/1LessonSchedual/kn01L003ExtraPiesesIntoOne.dart';
import '../01LessonMngmnt/1LessonSchedual/kn01L003ExtraToSche.dart';
import '../02LsnFeeMngmnt/Kn02F003AdvcLsnFeePayPage.dart';
import '../02LsnFeeMngmnt/kn02F002LsnFeeDetail.dart';
import '../Constants.dart';

class PageIdMapping extends StatelessWidget {
  final String pageId;
  final String stuId;
  final String stuName;
  final int selectedYear;

  const PageIdMapping({
    super.key,
    required this.pageId,
    required this.stuId,
    required this.stuName,
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    // 立即调用导航方法，不能使用 FutureBuilder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToPage(context);
    });

    // 返回一个空的容器，因为这个 widget 不应该被渲染
    return Container();
  }

  Future<void> _navigateToPage(BuildContext context) async {
    late Widget page;
    switch (pageId) {
      case Constants.kn01L002LsnStatistic: // 迁移至课程进度统计画面
        page = Kn01L002LsnStatistic(
          stuId: stuId,
          stuName: stuName,
          knBgColor: Constants.lessonThemeColor,
          knFontColor: Colors.white,
          pagePath: "上课进度管理 >> 在课学生一览",
          selectedYear: selectedYear,
        );
        break;

      case Constants.kn01L003ExtraToSche:
        page = ExtraToSchePage(
          stuId: stuId,
          stuName: stuName,
          knBgColor: Constants.lessonThemeColor,
          knFontColor: Colors.white,
          pagePath: "加课消化管理 >> 在课学生一览",
          selectedYear: selectedYear,
        );
        break;

      case Constants.kn01L003ExtraPiesesIntoOne:
        page = Kn01L003ExtraPiesesIntoOne(
          stuId: stuId,
          stuName: stuName,
          knBgColor: Constants.lessonThemeColor,
          knFontColor: Colors.white,
          pagePath: "碎课拼成整课 >> 在课学生一览",
          selectedYear: selectedYear,
        );
        break;

      case Constants.stuLsnFeeListPage: // 迁移至课程费用详细画面
        page = LsnFeeDetail(
          stuId: stuId,
          stuName: stuName,
          knBgColor: Constants.lsnfeeThemeColor,
          knFontColor: Colors.white,
          pagePath: "学费支付管理 >> 在课学生一览",
          selectedYear: selectedYear,
        );
        break;

      case Constants.kn02F003AdvcLsnFeePayPage: // 迁移至课费预支付画面
        page = Kn02F003AdvcLsnFeePayPage(
          stuId: stuId,
          stuName: stuName,
          knBgColor: Constants.lsnfeeThemeColor,
          knFontColor: Colors.white,
          pagePath: "学费预先支付 >> 在课学生一览",
          selectedYear: selectedYear,
        );
        break;

      default:
        page = const Scaffold(body: Center(child: Text('未定义页面')));
        break;
    }

    // 使用 pushReplacement 而不是 push,因为pageIdMapping不是窗体页面
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
