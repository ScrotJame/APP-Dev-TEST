import 'package:flutter/material.dart';
import 'package:vimes_test/commons/app_colors.dart';

enum StatusBannerType { pending, approved, rejected, info, draft }

/// Widget hiển thị banner trạng thái dạng hộp bo góc với nền nhạt, viền màu,
/// icon và thông điệp giải thích trực quan theo chuẩn Modern WMS.
class StatusBanner extends StatelessWidget {
  final String title;
  final String? message;
  final StatusBannerType type;
  final IconData? icon;
  final Widget? trailing;

  const StatusBanner({
    super.key,
    required this.title,
    this.message,
    this.type = StatusBannerType.pending,
    this.icon,
    this.trailing,
  });

  /// Factory helper từ chuỗi trạng thái Firestore thông dụng
  factory StatusBanner.fromStatusString({
    Key? key,
    required String status,
    required String title,
    String? message,
    IconData? icon,
    Widget? trailing,
  }) {
    StatusBannerType type;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
      case 'success':
        type = StatusBannerType.approved;
        break;
      case 'rejected':
      case 'cancelled':
      case 'error':
        type = StatusBannerType.rejected;
        break;
      case 'draft':
      case 'nháp':
      case 'lưu nháp':
        type = StatusBannerType.draft;
        break;
      case 'pending':
      default:
        type = StatusBannerType.pending;
        break;
    }

    return StatusBanner(
      key: key,
      title: title,
      message: message,
      type: type,
      icon: icon,
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData defaultIcon;

    switch (type) {
      case StatusBannerType.approved:
        bgColor = AppColors.statusApprovedBg;
        borderColor = AppColors.statusApprovedBorder;
        textColor = AppColors.statusApprovedText;
        defaultIcon = Icons.check_circle_rounded;
        break;
      case StatusBannerType.rejected:
        bgColor = AppColors.statusRejectedBg;
        borderColor = AppColors.statusRejectedBorder;
        textColor = AppColors.statusRejectedText;
        defaultIcon = Icons.cancel_rounded;
        break;
      case StatusBannerType.info:
        bgColor = const Color(0xFFEFF6FF); // Blue 50
        borderColor = const Color(0xFF93C5FD); // Blue 300
        textColor = const Color(0xFF1D4ED8); // Blue 700
        defaultIcon = Icons.info_outline_rounded;
        break;
      case StatusBannerType.draft:
        bgColor = AppColors.statusDraftBg;
        borderColor = AppColors.statusDraftBorder;
        textColor = AppColors.statusDraftText;
        defaultIcon = Icons.edit_note_rounded;
        break;
      case StatusBannerType.pending:
        bgColor = AppColors.statusPendingBg;
        borderColor = AppColors.statusPendingBorder;
        textColor = AppColors.statusPendingText;
        defaultIcon = Icons.pending_actions_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.8), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? defaultIcon,
            color: textColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.1,
                  ),
                ),
                if (message != null && message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
