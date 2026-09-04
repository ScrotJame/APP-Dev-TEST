import 'package:flutter/material.dart';
import 'package:vimes_test/commons/app_colors.dart';

/// Widget thẻ ký duyệt từng vai trò (Người lập, Người giao hàng, Thủ kho, Kế toán trưởng)
/// Thiết kế Card bo góc 12px, typography nhất quán, tương tác trực quan.
class SignatureCard extends StatelessWidget {
  final String title;
  final String roleNote;
  final bool isRequired;
  final bool isReadOnly;
  final String signerName;
  final String badgeText;
  final VoidCallback? onTapEdit;
  final VoidCallback? onTapQuickSign;
  final VoidCallback? onTapClear;

  const SignatureCard({
    super.key,
    required this.title,
    required this.roleNote,
    required this.isRequired,
    required this.isReadOnly,
    required this.signerName,
    required this.badgeText,
    required this.onTapEdit,
    required this.onTapQuickSign,
    required this.onTapClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSigned = signerName.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isSigned
            ? AppColors.statusApprovedBg.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSigned
              ? AppColors.statusApprovedBorder
              : (isRequired ? AppColors.statusPendingBorder.withValues(alpha: 0.8) : AppColors.cardBorder),
          width: isSigned ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề vai trò + Huy hiệu trạng thái
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              if (isSigned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusApprovedBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusApprovedBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 13, color: AppColors.statusApprovedText),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.statusApprovedText,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isRequired ? AppColors.statusPendingBg : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRequired ? AppColors.statusPendingBorder : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    isRequired ? 'Chưa ký *' : 'Chưa ký (tùy chọn)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isRequired ? AppColors.statusPendingText : Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            roleNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 10),

          // Nội dung thông tin người ký hoặc nút ký
          if (isSigned) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.draw_rounded, color: AppColors.statusApprovedText, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      signerName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  if (!isReadOnly) ...[
                    if (onTapEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Đổi tên',
                        visualDensity: VisualDensity.compact,
                        onPressed: onTapEdit,
                      ),
                    if (onTapClear != null)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                        tooltip: 'Hủy ký',
                        visualDensity: VisualDensity.compact,
                        onPressed: onTapClear,
                      ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                if (onTapQuickSign != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTapQuickSign,
                      icon: const Icon(Icons.badge_outlined, size: 16),
                      label: const Text('Ký tên tôi'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (onTapEdit != null)
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onTapEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Nhập tên'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
