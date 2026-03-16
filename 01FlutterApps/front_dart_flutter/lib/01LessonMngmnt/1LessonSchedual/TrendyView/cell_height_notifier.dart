// [捏合缩放手势] 2026-03-16 单元格高度 Notifier
// 管理课程表时间格的动态高度（minHeight ~ maxHeight）
// 课程表新潮版和固定排课新潮版各自独立持有实例

import 'package:flutter/material.dart';

/// 单元格高度状态管理
/// 两个手指上下张开 → cellHeight 递增（上限 maxHeight）
/// 两个手指上下闭合 → cellHeight 递减（下限 minHeight）
class CellHeightNotifier extends ChangeNotifier {
  static const double minHeight = 4.0;
  static const double maxHeight = 24.0;
  static const double defaultHeight = 24.0;

  double _cellHeight = defaultHeight;

  double get cellHeight => _cellHeight;

  void update(double newHeight) {
    final clamped = newHeight.clamp(minHeight, maxHeight);
    if ((_cellHeight - clamped).abs() > 0.01) {
      _cellHeight = clamped;
      notifyListeners();
    }
  }
}
