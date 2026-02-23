// ignore_for_file: file_names
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'knAutoConfigJsonApi.dart';

class KnConfig {
  static late String apiBaseUrl;
  static late String environmentName; // 环境名称

  static Future<void> load() async {
    try {
      /*  自动获取在【pubspec.yaml】里配置的这些api文件
        #  - kn-config/apiconfig.json
        #  - kn-localhost-config/apiconfig.json
        #  - kn-lan-config/apiconfig.json
          - kn-vpn-config/apiconfig.json
      */
      final configFilePath = await ApiJsonConfigAutoGet.configJsonFile;
      final jsonString = await ApiJsonConfigAutoGet.loadConfigFile();
      final jsonResponse = json.decode(jsonString);
      apiBaseUrl = jsonResponse['apiBaseUrl'];

      // 根据配置文件路径判断当前环境
      if (configFilePath.contains('kn-local-config') ||
          configFilePath.contains('kn-vpn-config')) {
        environmentName = '（本地开发环境）';
      } else if (configFilePath.contains('kn-nas-test-config')) {
        environmentName = '（NAS测试环境）';
      } else if (configFilePath.contains('kn-nas-config')) {
        environmentName = ''; // 生产环境不显示后缀
      } else {
        environmentName = ''; // 默认不显示
      }

      if (kDebugMode) {
        print('Current environment: $environmentName');
        print('API Base URL: $apiBaseUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load configuration: $e');
      }
      // 根据实际情况，你可能还想在这里抛出异常或进行其他错误处理
    }
  }
}
