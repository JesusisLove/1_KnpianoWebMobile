// [课程排他公共模块] 2026-02-13
// 课程冲突检测公共服务
//
// 提供统一的冲突检测响应处理逻辑，适用于：
// - 课程表（传统版、新潮版）
// - 固定排课（传统版、新潮版）
// - 将来可能新增的其他排课模块

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ConflictInfo.dart';
import 'ConflictWarningDialog.dart';

/// 冲突检测服务 - 处理API响应并显示冲突对话框
class ConflictCheckService {
  /// 处理保存操作的响应
  ///
  /// [context] Flutter上下文
  /// [response] HTTP响应
  /// [newSchedule] 新排课信息（用于时间轴可视化）
  /// [onSuccess] 保存成功回调
  /// [onForceRetry] 用户确认强制保存时的回调
  /// [onError] 错误回调
  ///
  /// 返回值：true表示需要强制重试，false表示处理完成
  static Future<bool> handleSaveResponse({
    required BuildContext context,
    required http.Response response,
    required NewScheduleInfo newSchedule,
    required VoidCallback onSuccess,
    required String errorPrefix,
  }) async {
    final responseBody = utf8.decode(response.bodyBytes);

    // 尝试解析为JSON
    dynamic responseData;
    try {
      responseData = json.decode(responseBody);
    } catch (_) {
      // 非JSON响应，按原有逻辑处理
      if (response.statusCode == 200) {
        onSuccess();
        return false;
      } else {
        _showErrorDialog(context, '$errorPrefix: $responseBody');
        return false;
      }
    }

    // 处理JSON响应
    if (responseData is Map<String, dynamic>) {
      final result = ConflictCheckResult.fromJson(responseData);

      if (result.success) {
        // 保存成功
        onSuccess();
        return false;
      } else if (result.hasConflict) {
        // 检测到冲突
        if (result.isSameStudentConflict) {
          // 同一学生自我冲突，严格禁止
          await ConflictWarningDialog.showSameStudentConflict(
            context,
            result.conflicts,
            newSchedule: newSchedule,
          );
          return false;
        } else {
          // 不同学生冲突，显示警告让用户确认
          final confirmed = await ConflictWarningDialog.show(
            context,
            result.conflicts,
            newSchedule: newSchedule,
          );
          return confirmed; // 返回是否需要强制重试
        }
      } else {
        // 其他错误
        _showErrorDialog(context, result.message);
        return false;
      }
    } else {
      // 响应不是预期的Map格式，按成功处理（兼容旧版后端）
      if (response.statusCode == 200) {
        onSuccess();
      } else {
        _showErrorDialog(context, errorPrefix);
      }
      return false;
    }
  }

  /// 计算课程结束时间
  static String calculateEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    final startHour = int.parse(parts[0]);
    final startMinute = int.parse(parts[1]);

    final totalMinutes = startHour * 60 + startMinute + durationMinutes;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;

    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  /// 构建NewScheduleInfo
  static NewScheduleInfo buildNewScheduleInfo({
    required String hour,
    required String minute,
    required int classDuration,
    String? stuName,
  }) {
    final startTime = '$hour:$minute';
    final endTime = calculateEndTime(startTime, classDuration);
    return NewScheduleInfo(
      startTime: startTime,
      endTime: endTime,
      stuName: stuName,
    );
  }

  /// 显示错误对话框
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('操作失败'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示进度对话框
  static void showProgressDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 关闭进度对话框
  static void closeProgressDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
