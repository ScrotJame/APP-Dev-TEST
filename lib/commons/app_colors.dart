import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// BẢNG MÀU CHUYÊN BIỆT CHO HỆ THỐNG KHO VẬN / ENTERPRISE WMS
/// ---------------------------------------------------------------------------
class AppColors {
  // Nền & Khung
  static const Color navBackground = Color(0xFF0F172A); // Slate 900 trầm ổn
  static const Color navSurface = Color(0xFF1E293B); // Slate 800
  static const Color scaffoldBg = Color(0xFFF1F5F9); // Slate 100
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Điểm nhấn & Hành động chính
  static const Color accentNavy = Color(0xFF1E3A8A); // Blue 900
  static const Color accentPrimary = Color(0xFF2563EB); // Blue 600
  static const Color accentHover = Color(0xFF1D4ED8);

  // Chữ
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Trạng thái phiếu (Màu mang thông tin nghiệp vụ)
  // 1. Chờ duyệt (Pending/Amber)
  static const Color statusPendingText = Color(0xFF92400E);
  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusPendingBorder = Color(0xFFF59E0B);

  // 2. Hoàn thành (Success/Green)
  static const Color statusApprovedText = Color(0xFF166534);
  static const Color statusApprovedBg = Color(0xFFDCFCE7);
  static const Color statusApprovedBorder = Color(0xFF22C55E);

  // 3. Lưu nháp (Draft/Slate)
  static const Color statusDraftText = Color(0xFF334155);
  static const Color statusDraftBg = Color(0xFFF1F5F9);
  static const Color statusDraftBorder = Color(0xFF94A3B8);

  // 4. Từ chối / Hủy (Danger/Red)
  static const Color statusRejectedText = Color(0xFF991B1B);
  static const Color statusRejectedBg = Color(0xFFFEE2E2);
  static const Color statusRejectedBorder = Color(0xFFEF4444);
}
