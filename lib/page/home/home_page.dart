import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vimes_test/commons/app_colors.dart';
import 'package:vimes_test/commons/enums.dart';
import 'package:vimes_test/models/GRN_model.dart';
import 'package:vimes_test/page/entry_note/entry_note_page.dart';
import 'package:vimes_test/page/entry_note_detail/entry_note_detail_page.dart';
import 'package:vimes_test/page/home/home_cubit.dart';
import 'package:vimes_test/repositories/auth_repository.dart';
import 'package:vimes_test/repositories/grn_repositories.dart';

// Export AppColors & ReceiptStatus để tương thích toàn dự án
export 'package:vimes_test/commons/app_colors.dart';
export 'package:vimes_test/page/home/home_cubit.dart' show ReceiptStatus;

/// ---------------------------------------------------------------------------
/// MÀN HÌNH CHÍNH (HOME_PAGE) - KHO VẬN WMS VIMES
/// ---------------------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        grnRepository: RepositoryProvider.of<GRNRepository>(context),
      )..fetchNotes(),
      child: const _HomePageView(),
    );
  }
}

class _HomePageView extends StatefulWidget {
  const _HomePageView();

  @override
  State<_HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<_HomePageView> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy • HH:mm');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final filteredList = state.filteredNotes;
            final totalCount = state.totalCount;
            final debtCount = state.debtCount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. App Bar với bộ chỉ số tổng quan
                _buildTopAppBar(
                  context,
                  totalCount: totalCount,
                  debtCount: debtCount,
                ),

                // 2. Ô tìm kiếm
                _buildSearchSection(context),

                // 3. Thanh lọc trạng thái (Chips)
                _buildFilterChips(context, state),

                // 4. Danh sách phiếu nhập thực tế hoặc trạng thái rỗng / tải
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => context.read<HomeCubit>().refresh(),
                    color: AppColors.accentPrimary,
                    backgroundColor: AppColors.cardBg,
                    child: _buildListContent(context, state, filteredList),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<dynamic>(
            MaterialPageRoute(
              builder: (_) => const GoodsReceivedFormScreen(),
            ),
          );
          if (result != null && context.mounted) {
            final String message;
            final Color bgColor;
            final IconData icon;

            if (result == 'draft' ||
                (result is String && result.toLowerCase().contains('nháp'))) {
              message = result is String && result.isNotEmpty
                  ? result
                  : 'Lưu nháp phiếu nhập kho thành công!';
              bgColor = const Color(0xFF0F172A); // Slate 900
              icon = Icons.edit_note_rounded;
            } else {
              message = result is String && result.isNotEmpty
                  ? result
                  : 'Lưu phiếu nhập kho thành công!';
              bgColor = const Color(0xFF16A34A); // Green 600
              icon = Icons.check_circle_outline_rounded;
            }

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: bgColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        elevation: 3,
        backgroundColor: AppColors.accentNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Tạo phiếu nhập',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// NỘI DUNG DANH SÁCH (LOADING / ERROR / EMPTY / LIST)
  /// -------------------------------------------------------------------------
  Widget _buildListContent(
    BuildContext context,
    HomeState state,
    List<GoodsReceivedNoteModel> filteredList,
  ) {
    if (state.loadStatus == LoadStatus.LOADING && state.notes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang tải danh sách phiếu từ Firebase...',
              style: TextStyle(color: AppColors.textSub, fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    if (state.loadStatus == LoadStatus.FAILURE && state.notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.statusRejectedBorder,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSub),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<HomeCubit>().fetchNotes(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentNavy,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredList.isEmpty) {
      return _buildEmptyState(state.searchQuery.isNotEmpty);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: filteredList.length,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildReceiptCard(context, filteredList[index]);
      },
    );
  }

  /// -------------------------------------------------------------------------
  /// APP BAR: ĐẬM CHẤT LOGISTICS + CHỈ SỐ TỔNG QUAN
  /// -------------------------------------------------------------------------
  Widget _buildTopAppBar(
    BuildContext context, {
    required int totalCount,
    required int debtCount,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.navSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VIMES WMS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Quản lý nhập kho',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Nút làm mới dữ liệu & Đăng xuất
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    tooltip: 'Làm mới từ Firestore',
                    onPressed: () => context.read<HomeCubit>().fetchNotes(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                    tooltip: 'Đăng xuất',
                    onPressed: () => _confirmSignOut(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Hai thẻ chỉ số nhanh: TỔNG PHIẾU NHẬP & PHIẾU NỢ
          Row(
            children: [
              Expanded(
                child: _buildMetricBadge(
                  label: 'TỔNG PHIẾU NHẬP',
                  value: '$totalCount',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF38BDF8), // Sky 400
                  onTap: () => context.read<HomeCubit>().selectStatus(ReceiptStatus.all),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricBadge(
                  label: 'PHIẾU NỢ',
                  value: '$debtCount',
                  icon: Icons.assignment_late_outlined,
                  color: const Color(0xFFF87171), // Red 400
                  onTap: () => context.read<HomeCubit>().selectStatus(ReceiptStatus.debt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.navSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF334155), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// THANH TÌM KIẾM
  /// -------------------------------------------------------------------------
  Widget _buildSearchSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => context.read<HomeCubit>().updateSearchQuery(val),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textMain),
          decoration: InputDecoration(
            hintText: 'Tìm theo số phiếu, bên giao, kho...',
            hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, size: 19, color: AppColors.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 17, color: AppColors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      context.read<HomeCubit>().updateSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// BỘ LỌC TRẠNG THÁI (CHIPS)
  /// -------------------------------------------------------------------------
  Widget _buildFilterChips(BuildContext context, HomeState state) {
    final statusList = ReceiptStatus.values;
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: statusList.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statusList[index];
          final isSelected = state.selectedStatus == status;
          final count = state.getCountByStatus(status);

          return InkWell(
            onTap: () => context.read<HomeCubit>().selectStatus(status),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navSurface : AppColors.cardBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.navSurface : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSub,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// THẺ PHIẾU NHẬP KHO THỰC TẾ (CLICK ĐỂ XEM CHI TIẾT)
  /// -------------------------------------------------------------------------
  Widget _buildReceiptCard(BuildContext context, GoodsReceivedNoteModel note) {
    final status = _parseStatus(note.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final detailResult = await Navigator.of(context).push<dynamic>(
              MaterialPageRoute(
                builder: (_) => EntryNoteDetailPage(
                  noteId: note.id,
                  initialNote: note,
                ),
              ),
            );
            if (detailResult is String &&
                detailResult.isNotEmpty &&
                context.mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          detailResult,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dải màu indicator biểu thị trạng thái bên trái
                Container(
                  width: 5,
                  color: status.borderColor,
                ),

                // Nội dung chính của Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card: Số phiếu (Monospace) + Badge Trạng Thái
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.noteNumber.isNotEmpty
                                      ? note.noteNumber
                                      : 'PNK-${note.id.substring(0, 8).toUpperCase()}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _dateFormat.format(note.date),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (note.isDebt) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2.5),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: note.debtType == 'all'
                                          ? const Color(0xFFFEE2E2)
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: note.debtType == 'all'
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    child: Text(
                                      note.debtType == 'all'
                                          ? 'Nợ tất cả'
                                          : 'Nợ 1 phần',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: note.debtType == 'all'
                                            ? const Color(0xFF991B1B)
                                            : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                                _buildStatusBadge(status),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Thông tin giao nhận
                        _buildInfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Bên giao: ',
                          value: note.delivererName.isNotEmpty
                              ? note.delivererName
                              : 'Chưa cập nhật bên giao',
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          icon: Icons.warehouse_outlined,
                          label: 'Kho nhập: ',
                          value: note.warehouse.isNotEmpty
                              ? note.warehouse
                              : 'Kho Tổng VIMES',
                        ),

                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        const SizedBox(height: 8),

                        // Footer Card: Số mặt hàng & Tổng tiền
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.category_outlined,
                                      size: 13, color: AppColors.textSub),
                                  const SizedBox(width: 4),
                                  Text(
                                    note.itemCount > 0
                                        ? '${note.itemCount} mặt hàng'
                                        : 'Xem chi tiết',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Tổng tiền: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSub,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  _currencyFormat.format(note.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReceiptStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: status.borderColor, width: 0.8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: status.textColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// TRẠNG THÁI RỖNG (EMPTY STATE)
  /// -------------------------------------------------------------------------
  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 32,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSearching
                    ? 'Không tìm thấy phiếu nhập'
                    : 'Chưa có phiếu nhập kho nào',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isSearching
                    ? 'Thử điều chỉnh từ khóa tìm kiếm hoặc chọn bộ lọc trạng thái khác.'
                    : 'Nhấn nút "Tạo phiếu nhập" bên dưới để lập phiếu nhập kho đầu tiên vào hệ thống.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSub),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ReceiptStatus _parseStatus(String status) {
    final s = status.toLowerCase();
    if (s == 'pending' || s == 'chờ duyệt') return ReceiptStatus.pending;
    if (s == 'draft' || s == 'lưu nháp') return ReceiptStatus.draft;
    if (s == 'rejected' || s == 'từ chối') return ReceiptStatus.rejected;
    return ReceiptStatus.approved;
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusRejectedBorder,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await RepositoryProvider.of<AuthRepository>(context).signOut();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
