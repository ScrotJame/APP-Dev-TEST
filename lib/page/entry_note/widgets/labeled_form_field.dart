import 'package:flutter/material.dart';
import 'package:vimes_test/commons/app_colors.dart';

/// Helper tạo InputDecoration đồng bộ bo góc 10px theo chuẩn thiết kế
InputDecoration appInputDecoration({
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool isReadOnly = false,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: isReadOnly,
    fillColor: isReadOnly ? const Color(0xFFF8FAFC) : Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isReadOnly
            ? AppColors.cardBorder.withValues(alpha: 0.7)
            : AppColors.cardBorder,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
    ),
  );
}

/// Widget bọc field với nhãn hiển thị rõ ràng PHÍA TRÊN trường nhập liệu
class LabeledFormField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final Widget child;
  final Widget? trailing;

  const LabeledFormField({
    super.key,
    required this.label,
    this.isRequired = false,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                  letterSpacing: 0.1,
                ),
                children: [
                  if (isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Widget ô thông tin chỉ đọc (Read-only) với nhãn bên trên và kiểu dáng đồng bộ
class LabeledReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final Widget? prefixIcon;
  final TextStyle? valueStyle;

  const LabeledReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.prefixIcon,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LabeledFormField(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              prefixIcon!,
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: valueStyle ??
                    theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
