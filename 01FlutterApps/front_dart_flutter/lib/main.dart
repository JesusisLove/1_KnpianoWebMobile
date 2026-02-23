import 'package:flutter/material.dart';
import 'package:kn_piano/ApiConfig/KnApiConfig.dart';
// [Flutter页面主题改造] 2026-01-17 添加主题系统Provider
import 'package:provider/provider.dart';
import 'theme/providers/theme_provider.dart';
import 'HomePage.dart'; // 确保这里正确导入HomePage.dart
// [应用锁定功能] 2026-02-17 添加锁定功能相关导入
import 'security/app_lock_provider.dart';
import 'security/app_lock_screen.dart';
import 'security/pin_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置默认值
  KnConfig.apiBaseUrl = "http://10.8.0.10:8080";

  // 尝试加载配置（带超时）
  try {
    await KnConfig.load().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        print('配置加载超时，使用默认值');
      },
    );
  } catch (e) {
    print('配置加载失败: $e，使用默认值');
  }

  // [Flutter页面主题改造] 2026-01-17 初始化主题Provider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // [应用锁定功能] 2026-02-17 初始化锁定Provider
  final appLockProvider = AppLockProvider();
  await appLockProvider.initialize();

  runApp(
    // [应用锁定功能] 2026-02-17 改为MultiProvider，同时提供ThemeProvider和AppLockProvider
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: appLockProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // [Flutter页面主题改造] 2026-01-17 从Provider获取主题数据
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '一对一教学管理系统',
          // [Flutter页面主题改造] 2026-01-17 应用动态主题
          theme: themeProvider.themeData,
          home: HomePage(currentNavIndex: 0),
          // [应用锁定功能] 2026-02-17 使用builder将锁屏层叠加在Navigator整体之上
          // 无论用户当前在第几层子页面，时间到锁屏立即出现在最顶层
          // 解锁后Navigator状态完全保留，用户看到锁之前的那个页面
          // 使用Listener代替GestureDetector，确保触摸事件穿透到子页面（不消费事件）
          builder: (context, child) {
            return Consumer<AppLockProvider>(
              builder: (context, lockProvider, _) {
                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => lockProvider.onUserActivity(),
                  child: Stack(
                    children: [
                      // Navigator整体（包含所有层级的子页面）
                      // [BUG FIX] 当锁屏或PIN设置画面覆盖时，用ExcludeFocus排除主app的焦点遍历，
                      // 避免Flutter Web在Chrome获得焦点时对未布局的FocusNode调用rect，
                      // 导致 "RenderBox was not laid out" 断言错误。
                      ExcludeFocus(
                        excluding: !lockProvider.isPinSet || lockProvider.isLocked,
                        child: child!,
                      ),
                      // PIN设置画面（首次启动，未设置PIN时显示）
                      if (!lockProvider.isPinSet)
                        const PinSetupScreen(mode: PinSetupMode.setup),
                      // PIN输入画面（已锁定时显示，盖在所有子页面上方）
                      if (lockProvider.isPinSet && lockProvider.isLocked)
                        const AppLockScreen(),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
