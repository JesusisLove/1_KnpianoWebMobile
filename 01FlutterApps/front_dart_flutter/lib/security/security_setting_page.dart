// [应用锁定功能] 2026-02-18 安全设置页面
// 集中管理安全相关设置：
//   1. 修改PIN码
//   2. 自动锁定时间选择（1/2/5/10/30分钟）

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../CommonProcess/customUI/KnAppBar.dart';
import '../theme/kn_theme_colors.dart';
import 'app_lock_provider.dart';
import 'pin_setup_screen.dart';

class SecuritySettingPage extends StatelessWidget {
  final Color knBgColor;
  final Color knFontColor;
  final String pagePath;

  const SecuritySettingPage({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  /// 可选的自动锁定时间列表（秒数 → 显示标签）
  /// 0 = 从不自动锁定（不启动计时器）
  static const List<(int, String)> _timeoutOptions = [
    (60, '1 分钟'),
    (120, '2 分钟（默认）'),
    (300, '5 分钟'),
    (600, '10 分钟'),
    (1800, '30 分钟'),
    (0, '从不'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KnAppBar(
        title: '安全设置',
        subtitle: '$pagePath >> 安全设置',
        context: context,
        appBarBackgroundColor: knBgColor.withOpacity(0.2),
        subtitleBackgroundColor: knBgColor,
        titleColor: KnThemeColors.getPrimaryTextColor(context),
        currentNavIndex: 4,
      ),
      body: Consumer<AppLockProvider>(
        builder: (context, lockProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── PIN码管理 ──────────────────────────────
              _SectionHeader(title: 'PIN码管理', color: knBgColor),
              const SizedBox(height: 8),
              _SettingCard(
                icon: Icons.pin,
                title: '修改PIN码',
                subtitle: '变更应用解锁密码',
                color: knBgColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PinSetupScreen(mode: PinSetupMode.change),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),

              const SizedBox(height: 24),

              // ── 自动锁定时间 ───────────────────────────
              _SectionHeader(title: '自动锁定时间', color: knBgColor),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '无操作超过设定时间后自动锁定应用',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              ..._timeoutOptions.map((option) {
                final (seconds, label) = option;
                final isSelected = lockProvider.timeoutSeconds == seconds;
                return _TimeoutOptionCard(
                  label: label,
                  isSelected: isSelected,
                  color: knBgColor,
                  onTap: () async {
                    await lockProvider.updateTimeout(seconds);
                    if (context.mounted) {
                      final message = seconds == 0
                          ? '已设置为从不自动锁定'
                          : '自动锁定时间已设置为$label';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ── 内部组件 ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: trailing,
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class _TimeoutOptionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TimeoutOptionCard({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? color : Colors.black87,
          ),
        ),
        trailing: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? color : Colors.grey,
        ),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
