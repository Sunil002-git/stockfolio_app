import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

class OtpInputField extends StatefulWidget {
  final void Function(String otp)? onCompleted;
  final void Function(String otp)? onChanged;
  final int length;

  const OtpInputField({
    super.key,
    this.onCompleted,
    this.onChanged,
    this.length = 6,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // called every time a digit box changes
  void _onChanged(String value, int index) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < widget.length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      // move focus to last filled box
      final lastIndex = (digits.length - 1).clamp(0, widget.length - 1);
      _focusNodes[lastIndex].requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    // Notify parent of current full otp value
    final otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(otp);

    // call onCompleted when all boxes are filled
    if (otp.length == widget.length) {
      widget.onCompleted?.call(otp);
    }
  }

  // handle backspace - move focus to previous box
  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (e) => _onKeyEvent(e, index),
          child: SizedBox(
            width: 46,
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.brand, width: 2,
                      ),
                    ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (v) => _onChanged(v, index),
            ),
          ),
        );
      }),
    );
  }
}
