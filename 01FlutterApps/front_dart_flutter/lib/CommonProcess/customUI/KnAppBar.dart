// [Flutter页面主题改造] 2026-01-17 改造KnAppBar支持主题系统
// 保持向后兼容性，现有代码无需修改即可继续使用
// [Flutter页面主题改造] 2026-01-20 标题fontWeight纳入JSON管理

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../HomePage.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/providers/theme_provider.dart';

// ignore: non_constant_identifier_names
PreferredSizeWidget KnAppBar({
  required String title,
  required String subtitle,
  required BuildContext context,
  // [Flutter页面主题改造] 2026-01-17 保留原有颜色参数用于向后兼容
  Color appBarBackgroundColor = const Color.fromRGBO(220, 237, 200, 1.0),
  Color titleColor = Colors.black,
  Color subtitleBackgroundColor = Colors.blue,
  Color subtitleTextColor = Colors.white,
  double titleFontSize = 18.0,
  double subtitleFontSize = 9.0,
  List<Widget>? actions,
  bool refreshPreviousPage = false,
  TabBar? bottom, // 修改为可选参数
  bool addInvisibleRightButton = false, // 新增参数：是否添加不可见的右侧按钮，使AppBar的布局左右对称
  int currentNavIndex = 0,
  // [Flutter页面主题改造] 2026-01-27 此参数已废弃，保留仅为向后兼容
  // KnAppBar已改用Stack布局实现Title绝对居中，无需手动平衡左右按钮数量
  @Deprecated('KnAppBar已改用Stack布局实现Title绝对居中，此参数不再生效')
  int leftBalanceCount = 0,
  // [Flutter页面主题改造] 2026-01-17 新增模块名称参数，用于自动获取主题颜色
  // 当传入moduleName时，将优先使用主题系统的颜色
  String? moduleName, // lesson, fee, archive, summary, setting
}) {
  final double topPadding = MediaQuery.of(context).padding.top;
  const double sidePadding = 16.0; // 侧边距

  // [Flutter页面主题改造] 2026-01-17 如果传入moduleName，使用主题系统颜色
  Color effectiveAppBarBgColor = appBarBackgroundColor;
  Color effectiveTitleColor = titleColor;
  Color effectiveSubtitleBgColor = subtitleBackgroundColor;
  Color effectiveSubtitleTextColor = subtitleTextColor;
  // [Flutter页面主题改造] 2026-01-20 标题fontWeight纳入JSON管理
  FontWeight effectiveTitleFontWeight = FontWeight.w700; // 默认值

  if (moduleName != null) {
    try {
      final moduleColor = context.getModuleColor(moduleName);
      effectiveAppBarBgColor = moduleColor.light;
      effectiveSubtitleBgColor = moduleColor.primary;
      effectiveTitleColor = context.themeColors.primaryText;
      effectiveSubtitleTextColor = Colors.white;
    } catch (e) {
      // 如果主题系统未初始化，使用传入的默认值
    }
  }

  // [Flutter页面主题改造] 2026-01-20 从JSON配置读取appBarTitle的fontWeight
  try {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    effectiveTitleFontWeight = themeProvider.currentConfig.typography.elements.appBarTitle.fontWeight;
  } catch (e) {
    // 如果主题系统未初始化，使用默认值FontWeight.w700
  }

  return PreferredSize(
    preferredSize: Size.fromHeight(kToolbarHeight +
        kToolbarHeight / 3 +
        (bottom?.preferredSize.height ?? 0)),
    child: Container(
      padding: EdgeInsets.only(top: topPadding),
      child: AppBar(
        backgroundColor: effectiveAppBarBgColor,
        elevation: 0,
        automaticallyImplyLeading: false, // 禁用自动生成的返回按钮
        // [Flutter页面主题改造] 2026-01-27 使用Stack布局实现Title绝对居中
        // Stack层叠布局：底层是按钮Row，顶层是居中的Title
        // 这样无论左右按钮数量是否对称，Title都会在屏幕正中央
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // 底层：按钮布局（左侧返回按钮，右侧actions和Home按钮）
                  Row(
                    children: [
                      const SizedBox(width: sidePadding),
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: effectiveTitleColor),
                        onPressed: () {
                          if (refreshPreviousPage) {
                            Navigator.of(context).pop(true); // 返回并刷新上一页
                          } else {
                            Navigator.of(context).pop(); // 普通返回
                          }
                        },
                      ),
                      const Spacer(), // 使用Spacer将左右按钮推向两端
                      if (actions != null) ...actions,
                      // 此处是在KnAppBar右侧添加了隐藏的按钮，为了使Title内容的布局可以在Bar里剧中显示。
                      if (!addInvisibleRightButton)
                        IconButton(
                          icon: Icon(Icons.home,
                              color: effectiveTitleColor), // 将透明图标改为可见的Home图标
                          onPressed: () {
                            // 使用Navigator.pushAndRemoveUntil来清除所有路由历史并返回到主页
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => HomePage(
                                        currentNavIndex: currentNavIndex,
                                      )),
                              (route) => false, // 这会清除所有路由历史
                            );
                          },
                        ),
                      const SizedBox(width: sidePadding),
                    ],
                  ),
                  // 顶层：Title绝对居中于屏幕
                  Center(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: effectiveTitleColor,
                        // [Flutter页面主题改造] 2026-01-20 fontWeight从JSON配置读取
                        fontWeight: effectiveTitleFontWeight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: kToolbarHeight / 3,
              color: effectiveSubtitleBgColor,
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: sidePadding),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: effectiveSubtitleTextColor),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottom: bottom, // 添加 bottom 参数
      ),
    ),
  );
}
