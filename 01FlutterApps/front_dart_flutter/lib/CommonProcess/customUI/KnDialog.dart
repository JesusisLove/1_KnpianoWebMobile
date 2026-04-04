import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/providers/theme_provider.dart';

/// KnDialog.dart
/// 公共提示框组件
///
/// 提供四类统一封装：
///   A类：KnDialog.showLoading()  — 进度对话框（返回 dismiss 函数）
///   B类：KnDialog.showConfirm()  — 确认对话框（取消 / 确定）
///   C类：KnDialog.showInfo()     — 信息/提示对话框（仅确定）
///   D类：KnDialog.showSnackBar() — SnackBar 轻提示
///
/// 圆角（dialogRadius）通过 ThemeProvider 读取，随整体主题自动变化，无需调用方传入。
/// 字体通过 Theme.of(dialogContext).textTheme 继承，确保 Google Fonts 正确生效。

/// SnackBar 类型枚举
enum KnSnackType {
  success, // 成功 → Colors.green
  error,   // 失败/错误 → Colors.red
  warning, // 警告 → Colors.orange
  info,    // 普通信息 → bgColor（主题色）
}

class KnDialog {
  // ─────────────────────────────────────────────────────────────
  // A类：进度对话框（Loading）
  // ─────────────────────────────────────────────────────────────
  /// 显示进度对话框，返回 dismiss 函数。
  /// 调用方必须在 finally 块中调用 dismiss()，确保无论成功/失败都能关闭。
  ///
  /// 示例：
  ///   final dismiss = KnDialog.showLoading(context, bgColor, fontColor, KnMsg.i.loadingStuInfoSave);
  ///   try {
  ///     await _save();
  ///   } finally {
  ///     dismiss();
  ///   }
  static VoidCallback showLoading(
    BuildContext context,
    Color bgColor,
    Color fontColor,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final dialogRadius = Provider.of<ThemeProvider>(dialogContext, listen: false)
            .currentConfig.shapes.dialogRadius;
        final textTheme = Theme.of(dialogContext).textTheme;

        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dialogRadius)),
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: bgColor),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(color: bgColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    };
  }

  // ─────────────────────────────────────────────────────────────
  // B类：确认对话框（取消 / 确定）
  // ─────────────────────────────────────────────────────────────
  /// 显示确认对话框。
  /// onConfirm：异步回调，点击「确定」后执行，规范写法为 async/await。
  /// 点击「取消」默认仅关闭对话框。
  ///
  /// 示例：
  ///   KnDialog.showConfirm(
  ///     context, bgColor, fontColor,
  ///     KnMsg.i.titleDeleteConfirm,
  ///     KnMsg.i.confirmLessonDelete.replaceFirst('%s', subjectName),
  ///     onConfirm: () async {
  ///       await _delete();
  ///       if (mounted) setState(() {});
  ///     },
  ///   );
  static void showConfirm(
    BuildContext context,
    Color bgColor,
    Color fontColor,
    String title,
    String message, {
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final dialogRadius = Provider.of<ThemeProvider>(dialogContext, listen: false)
            .currentConfig.shapes.dialogRadius;
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dialogRadius)),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏：bgColor背景 + fontColor文字
                Container(
                  width: double.infinity,
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: fontColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 内容区：白底 + bgColor文字/按钮
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message, style: textTheme.bodyMedium?.copyWith(color: bgColor)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text('取消', style: textTheme.labelLarge?.copyWith(color: bgColor)),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              await onConfirm();
                            },
                            child: Text('确定', style: textTheme.labelLarge?.copyWith(color: bgColor)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // C类：信息/提示对话框（仅确定按钮）
  // ─────────────────────────────────────────────────────────────
  /// 显示信息/提示对话框。
  /// onConfirm：可选，不传则默认仅关闭对话框。
  /// 动态错误内容（$responseBody / $e 等）直接传入 message 参数。
  ///
  /// 示例①：成功后跳转（传 onConfirm）
  ///   KnDialog.showInfo(
  ///     context, bgColor, fontColor,
  ///     KnMsg.i.titleSubmitSuccess, KnMsg.i.successStuInfoSave,
  ///     onConfirm: () {
  ///       Navigator.of(context).pop();
  ///       Navigator.of(context).pop(true);
  ///     },
  ///   );
  ///
  /// 示例②：仅显示错误（不传 onConfirm）
  ///   KnDialog.showInfo(
  ///     context, bgColor, fontColor,
  ///     KnMsg.i.titleError, errorMessage,
  ///   );
  static void showInfo(
    BuildContext context,
    Color bgColor,
    Color fontColor,
    String title,
    String message, {
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final dialogRadius = Provider.of<ThemeProvider>(dialogContext, listen: false)
            .currentConfig.shapes.dialogRadius;
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dialogRadius)),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏：bgColor背景 + fontColor文字
                Container(
                  width: double.infinity,
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: fontColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 内容区：白底 + bgColor文字/按钮
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message, style: textTheme.bodyMedium?.copyWith(color: bgColor)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              if (onConfirm != null) {
                                onConfirm();
                              }
                            },
                            child: Text('确定', style: textTheme.labelLarge?.copyWith(color: bgColor)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // D类：SnackBar 轻提示
  // ─────────────────────────────────────────────────────────────
  /// 显示 SnackBar。
  /// type 决定背景色：success=绿 / error=红 / warning=橙 / info=bgColor
  /// bgColor 仅 type=info 时有效，需传入主题色。
  ///
  /// 示例：
  ///   KnDialog.showSnackBar(context, KnMsg.i.snackBadDebtUndo, type: KnSnackType.success);
  ///   KnDialog.showSnackBar(context, errorMessage, type: KnSnackType.error);
  ///   KnDialog.showSnackBar(context, KnMsg.i.snackStudentWithdrawn.replaceFirst('%s', count.toString()),
  ///     type: KnSnackType.info, bgColor: widget.knBgColor);
  static void showSnackBar(
    BuildContext context,
    String message, {
    KnSnackType type = KnSnackType.info,
    Color? bgColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final Color backgroundColor;
    switch (type) {
      case KnSnackType.success:
        backgroundColor = Colors.green;
        break;
      case KnSnackType.error:
        backgroundColor = Colors.red;
        break;
      case KnSnackType.warning:
        backgroundColor = Colors.orange;
        break;
      case KnSnackType.info:
        backgroundColor = bgColor ?? Colors.grey[800]!;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        duration: duration,
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
