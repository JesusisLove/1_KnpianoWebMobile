// [固定排课新潮界面] 2026-02-12 视图切换组件

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 视图模式枚举
enum ViewMode {
  grid, // 新潮界面（网格视图）
  list, // 传统界面（列表视图）
}

/// 视图模式偏好存储
class ViewModePreference {
  static const String _key = 'fixed_lesson_view_mode';

  /// 获取保存的视图模式
  static Future<ViewMode> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    return value == 'list' ? ViewMode.list : ViewMode.grid;
  }

  /// 保存视图模式
  static Future<void> setViewMode(ViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ViewMode.list ? 'list' : 'grid');
  }
}

/// 视图切换按钮组件
class ViewModeToggle extends StatelessWidget {
  final ViewMode currentMode;
  final ValueChanged<ViewMode> onModeChanged;
  final Color activeColor;

  const ViewModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.grid_view,
            label: '网格',
            isSelected: currentMode == ViewMode.grid,
            onTap: () => _changeMode(ViewMode.grid),
          ),
          _buildToggleButton(
            icon: Icons.list,
            label: '列表',
            isSelected: currentMode == ViewMode.list,
            onTap: () => _changeMode(ViewMode.list),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : Colors.white,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeMode(ViewMode mode) {
    if (mode != currentMode) {
      onModeChanged(mode);
      ViewModePreference.setViewMode(mode);
    }
  }
}
