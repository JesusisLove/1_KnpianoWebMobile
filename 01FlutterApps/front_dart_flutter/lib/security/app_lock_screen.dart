// [应用锁定功能] 2026-02-18 PIN输入画面（解锁画面）- Piano Notes主题重设计
// 锁定时显示的全屏PIN输入Widget。
// 覆盖全屏，放在应用Stack的最前层。

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_lock_provider.dart';
import 'pin_storage_service.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final PinStorageService _storage = PinStorageService();

  String _inputPin = '';
  bool _hasError = false;
  String _errorMessage = '';
  int _failCount = 0;
  DateTime? _lockoutUntil;
  Timer? _countdownTimer;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // ── 主题色（Piano Notes 玫瑰粉配色）────────────────────
  static const Color _primary = Color(0xFFEC4899); // pink-500
  static const Color _deep = Color(0xFFBE185D); // pink-800（按键文字）
  static const Color _accent = Color(0xFFF472B6); // pink-400（渐变浅端）
  static const Color _errorRed = Color(0xFFE53E3E);

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -28), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -28, end: 28), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 28, end: -20), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -20, end: 20), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 20, end: 0), weight: 1),
    ]).animate(_shakeController);
    _loadLockState();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLockState() async {
    final failCount = await _storage.getFailCount();
    final lockoutUntil = await _storage.getLockoutUntil();
    if (!mounted) return;
    setState(() {
      _failCount = failCount;
      _lockoutUntil = lockoutUntil;
    });
    if (_isLockedOut()) {
      _startCountdown();
    }
  }

  bool _isLockedOut() {
    if (_lockoutUntil == null) return false;
    return DateTime.now().isBefore(_lockoutUntil!);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_isLockedOut()) {
        _countdownTimer?.cancel();
        _storage.resetFailCount().then((_) {
          if (!mounted) return;
          setState(() {
            _failCount = 0;
            _lockoutUntil = null;
            _inputPin = '';
            _hasError = false;
          });
        });
      } else {
        setState(() {}); // 刷新倒计时显示
      }
    });
  }

  String _formatCountdown() {
    if (_lockoutUntil == null) return '00:00';
    final remaining = _lockoutUntil!.difference(DateTime.now());
    if (remaining.isNegative) return '00:00';
    final minutes =
        remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onDigitPressed(String digit) {
    if (_isLockedOut()) return;
    if (_inputPin.length >= 4) return;
    setState(() {
      _inputPin += digit;
      _hasError = false;
    });
    if (_inputPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_isLockedOut()) return;
    if (_inputPin.isEmpty) return;
    setState(() {
      _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _verifyPin() async {
    final isCorrect = await _storage.verifyPin(_inputPin);
    if (!mounted) return;

    if (isCorrect) {
      await _storage.resetFailCount();
      if (!mounted) return;
      Provider.of<AppLockProvider>(context, listen: false).unlock();
    } else {
      await _storage.incrementFailCount();
      if (!mounted) return;
      final failCount = await _storage.getFailCount();
      final lockoutUntil = await _storage.getLockoutUntil();
      if (!mounted) return;

      setState(() {
        _failCount = failCount;
        _lockoutUntil = lockoutUntil;
        _inputPin = '';
        _hasError = true;
      });
      _shakeController.forward(from: 0);

      if (_isLockedOut()) {
        _startCountdown();
      } else {
        final remaining = 3 - _failCount;
        if (remaining == 1) {
          setState(() {
            _errorMessage = 'PIN码错误，还可尝试1次，请谨慎输入';
          });
        } else {
          setState(() {
            _errorMessage = 'PIN码错误，还可尝试$remaining次';
          });
        }
      }
    }
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        // 背景：左上 → 右下 渐变
        // Color.fromARGB(透明度, 红, 绿, 蓝)
        //   透明度：0=完全透明  128=半透明  255=完全不透明
        //   红/绿/蓝：0～255，数值越大该色越浓
        // 让背景更淡：把透明度调小（如180）或把红绿蓝都调近255
        // 让背景更深：把红绿蓝调低，粉色感更强
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(
                  255, 255, 240, 247), // 左上：极淡粉白（透明度255，R255 G240 B247）
              Color.fromARGB(
                  255, 245, 235, 241), // 右下：柔和粉灰（透明度255，R245 G235 B241）
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildFloatingNotes(), // 背景装饰音符
              Positioned.fill(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    _buildHeader(),
                    const SizedBox(height: 36),
                    if (_isLockedOut()) ...[
                      _buildLockoutView(),
                    ] else ...[
                      _buildPinDots(),
                      const SizedBox(height: 14),
                      _buildErrorRow(),
                    ],
                    const SizedBox(height: 28),
                    _buildKeypad(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 背景浮动音符（装饰，不拦截触摸）────────────────────

  Widget _buildFloatingNotes() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // op = 透明度，范围 0.0（完全透明）→ 1.0（完全不透明）
            // 数值越小越淡（若隐若现），数值越大越清晰（装饰感更强）
            // 参考：0.03 雾蒙蒙 | 0.08 轻盈可见 | 0.15 明显 | 0.30 很深
            _note(Icons.music_note,
                top: 55, left: 18, size: 44, op: 0.6), // 左上，音符，轻盈
            _note(Icons.queue_music,
                top: 135, right: 22, size: 56, op: 0.7), // 右上，多音符，轻盈
            _note(Icons.music_note,
                top: 230, left: 55, size: 30, op: 0.6), // 左中，音符，最淡
            _note(Icons.piano,
                bottom: 180, right: 14, size: 50, op: 0.7), // 右下，钢琴，最深
            _note(Icons.music_note,
                bottom: 310, left: 8, size: 38, op: 0.6), // 左下偏上，音符
            _note(Icons.queue_music,
                bottom: 120, left: 35, size: 32, op: 0.7), // 左下，多音符
          ],
        ),
      ),
    );
  }

  Widget _note(
    IconData icon, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double op,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Icon(icon, size: size, color: _primary.withOpacity(op)),
    );
  }

  // ── 头部：渐变图标卡片 + 渐变标题 + 副标题 ─────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // 钢琴图标卡片（渐变底色 + 阴影）
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.piano, size: 44, color: Colors.white),
        ),
        const SizedBox(height: 20),
        // 渐变色标题文字（ShaderMask）
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_deep, _accent],
          ).createShader(bounds),
          child: const Text(
            'KN Piano Studio',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white, // ShaderMask 覆盖此色
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isLockedOut() ? '输入错误次数过多，请等待后重试' : '♩ 应用已锁定，请验证身份 ♩',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[500],
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ── 等待锁定倒计时 ─────────────────────────────────────

  Widget _buildLockoutView() {
    return Column(
      children: [
        Text('剩余等待时间', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        const SizedBox(height: 10),
        Text(
          _formatCountdown(),
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: _errorRed,
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }

  // ── PIN圆点（弹跳动画 + 摇晃动画 + 音符图标）──────────

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeAnimation.value, 0),
        child: child,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final filled = index < _inputPin.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack, // 轻微过冲，弹跳感
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: filled ? 26 : 18,
            height: filled ? 26 : 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: filled
                  ? const LinearGradient(
                      colors: [_primary, _accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: filled
                  ? null
                  : Border.all(color: _primary.withOpacity(0.4), width: 2),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: _primary.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: filled
                ? const Center(
                    child:
                        Icon(Icons.music_note, size: 13, color: Colors.white),
                  )
                : null,
          );
        }),
      ),
    );
  }

  // ── 错误提示行 ──────────────────────────────────────────

  Widget _buildErrorRow() {
    return SizedBox(
      height: 22,
      child: _hasError
          ? Text(
              _errorMessage,
              style: const TextStyle(color: _errorRed, fontSize: 13),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── 数字键盘 ────────────────────────────────────────────

  Widget _buildKeypad() {
    final disabled = _isLockedOut();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3'], disabled),
          const SizedBox(height: 14),
          _buildKeyRow(['4', '5', '6'], disabled),
          const SizedBox(height: 14),
          _buildKeyRow(['7', '8', '9'], disabled),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              Expanded(child: _buildDigitKey('0', disabled)),
              Expanded(child: _buildDeleteKey(disabled)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> digits, bool disabled) {
    return Row(
      children: digits
          .map((d) => Expanded(child: _buildDigitKey(d, disabled)))
          .toList(),
    );
  }

  Widget _buildDigitKey(String digit, bool disabled) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        // 外层提供阴影
        decoration: disabled
            ? null
            : BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        child: Material(
          // Material 提供底色与 InkWell 波纹裁剪
          color: disabled ? Colors.grey.shade200 : const Color(0xFFFFF0F7),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: disabled ? null : () => _onDigitPressed(digit),
            splashColor: _primary.withOpacity(0.18),
            highlightColor: _primary.withOpacity(0.08),
            child: SizedBox(
              height: 68,
              child: Center(
                child: Text(
                  digit,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: disabled ? Colors.grey.shade400 : _deep,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey(bool disabled) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: disabled
            ? null
            : BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        child: Material(
          color: disabled ? Colors.grey.shade200 : const Color(0xFFFFF0F7),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: disabled ? null : _onDeletePressed,
            splashColor: _primary.withOpacity(0.18),
            highlightColor: _primary.withOpacity(0.08),
            child: SizedBox(
              height: 68,
              child: Center(
                child: Icon(
                  Icons.backspace_outlined,
                  color: disabled ? Colors.grey.shade400 : _deep,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
