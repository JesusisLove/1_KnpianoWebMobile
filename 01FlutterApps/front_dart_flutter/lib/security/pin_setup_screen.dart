// [应用锁定功能] 2026-02-17 PIN设置・变更画面
// 支持两种模式：
//   setup  - 首次设置（不需要确认当前PIN）
//   change - PIN变更（需要先确认当前PIN）

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_lock_provider.dart';
import 'pin_storage_service.dart';

enum PinSetupMode { setup, change }

enum _Step { confirmCurrent, enterNew, confirmNew }

class PinSetupScreen extends StatefulWidget {
  final PinSetupMode mode;

  const PinSetupScreen({super.key, required this.mode});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final PinStorageService _storage = PinStorageService();

  _Step _step = _Step.enterNew;
  String _firstPin = '';
  String _inputPin = '';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.mode == PinSetupMode.change) {
      _step = _Step.confirmCurrent;
    }
  }

  String get _title {
    switch (_step) {
      case _Step.confirmCurrent:
        return '请输入当前PIN码';
      case _Step.enterNew:
        return '请设置新的PIN码（4位数字）';
      case _Step.confirmNew:
        return '请再次输入确认';
    }
  }

  void _onDigitPressed(String digit) {
    if (_inputPin.length >= 4) return;
    setState(() {
      _inputPin += digit;
      _hasError = false;
    });
    if (_inputPin.length == 4) {
      _handleInput();
    }
  }

  void _onDeletePressed() {
    if (_inputPin.isEmpty) return;
    setState(() {
      _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _handleInput() async {
    switch (_step) {
      case _Step.confirmCurrent:
        final isCorrect = await _storage.verifyPin(_inputPin);
        if (!mounted) return;
        if (isCorrect) {
          setState(() {
            _step = _Step.enterNew;
            _inputPin = '';
            _hasError = false;
          });
        } else {
          setState(() {
            _inputPin = '';
            _hasError = true;
            _errorMessage = 'PIN码错误，请重新输入';
          });
        }
        break;

      case _Step.enterNew:
        setState(() {
          _firstPin = _inputPin;
          _step = _Step.confirmNew;
          _inputPin = '';
          _hasError = false;
        });
        break;

      case _Step.confirmNew:
        if (_inputPin == _firstPin) {
          await _storage.savePin(_inputPin);
          if (!mounted) return;
          if (widget.mode == PinSetupMode.setup) {
            Provider.of<AppLockProvider>(context, listen: false)
                .onPinSetupComplete();
          } else {
            // change模式：保存完成后关闭画面
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN码修改完成')),
            );
            Navigator.of(context).pop();
          }
        } else {
          setState(() {
            _step = _Step.enterNew;
            _firstPin = '';
            _inputPin = '';
            _hasError = true;
            _errorMessage = '两次输入不一致，请重新设置';
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChangeMode = widget.mode == PinSetupMode.change;
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            if (isChangeMode) ...[
              AppBar(
                title: const Text('修改PIN码'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: const Color(0xFF667eea),
              ),
            ] else ...[
              const SizedBox(height: 60),
            ],
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Color(0xFF667eea),
            ),
            const SizedBox(height: 16),
            const Text(
              'KN Piano Studio',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            // PIN点状显示
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _inputPin.length
                        ? const Color(0xFF667eea)
                        : Colors.grey[300],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // 错误提示
            SizedBox(
              height: 24,
              child: _hasError
                  ? Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Color(0xFFe74c3c),
                        fontSize: 13,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            // 数字键盘
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildKeyRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildKeyRow(['7', '8', '9']),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              Expanded(child: _buildDigitKey('0')),
              Expanded(child: _buildDeleteKey()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> digits) {
    return Row(
      children: digits.map((d) => Expanded(child: _buildDigitKey(d))).toList(),
    );
  }

  Widget _buildDigitKey(String digit) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onDigitPressed(digit),
          child: Container(
            height: 64,
            alignment: Alignment.center,
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _onDeletePressed,
          child: Container(
            height: 64,
            alignment: Alignment.center,
            child: const Icon(
              Icons.backspace_outlined,
              color: Colors.black54,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
