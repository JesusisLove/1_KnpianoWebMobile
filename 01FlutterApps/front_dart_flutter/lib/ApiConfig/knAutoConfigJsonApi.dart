import 'package:flutter/services.dart' show rootBundle;

/// ========================================
/// 多环境配置管理（2026/01/03更新）
/// ========================================
///
/// 【设计目的】
/// 不同的运行环境需要不同的配置：
///   - 本地开发：   使用 localhost:8080
///   - VPN开发：    使用 10.8.0.10:8080
///   - NAS测试：    使用 192.168.50.101:8964
///   - NAS生产：    使用 192.168.50.101:xxxx
///
/// 【使用方法】
/// 通过 --dart-define=ENV=xxx 参数指定环境：
///
///   flutter run -d chrome --dart-define=ENV=local     # 本地开发
///   flutter run -d chrome --dart-define=ENV=vpn       # VPN开发
///   flutter build web --release --dart-define=ENV=test   # 构建测试环境
///   flutter build web --release --dart-define=ENV=prod   # 构建生产环境
///
/// 【优点】
///   ✅ 不需要修改 pubspec.yaml
///   ✅ 一次构建，多处部署
///   ✅ 命令行控制环境
///   ✅ 不容易出错
///   ✅ CI/CD 友好
///
/// 【配置文件位置】
///   - kn-local-config/apiconfig.json       (ENV=local)
///   - kn-vpn-config/apiconfig.json         (ENV=vpn)
///   - kn-nas-test-config/apiconfig.json    (ENV=test)
///   - kn-nas-config/apiconfig.json         (ENV=prod)

class ApiJsonConfigAutoGet {
  /// 从启动参数读取环境变量，默认为 'local'
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'local');

  /// 根据环境变量返回对应的配置文件路径
  static String get _configPath {
    switch (environment) {
      case 'local':
        print('📍 当前环境: 本地开发环境 (local)');
        return 'kn-local-config/apiconfig.json';
      case 'vpn':
        print('📍 当前环境: VPN开发环境 (vpn)');
        return 'kn-vpn-config/apiconfig.json';
      case 'test':
        print('📍 当前环境: NAS测试环境 (test)');
        return 'kn-nas-test-config/apiconfig.json';
      case 'prod':
        print('📍 当前环境: NAS生产环境 (prod)');
        return 'kn-nas-config/apiconfig.json';
      default:
        print('⚠️  未知环境: $environment，使用默认配置 (local)');
        return 'kn-local-config/apiconfig.json';
    }
  }

  /// 获取配置文件路径（保留向后兼容）
  static Future<String> get configJsonFile async {
    return _configPath;
  }

  /// 加载配置文件内容
  static Future<String> loadConfigFile() async {
    final configPath = _configPath;
    try {
      final content = await rootBundle.loadString(configPath);
      print('✅ 成功加载配置文件: $configPath');
      return content;
    } catch (e) {
      print('❌ 加载配置文件失败: $configPath');
      print('   错误信息: $e');
      rethrow;
    }
  }
}
