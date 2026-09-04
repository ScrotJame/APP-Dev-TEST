import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vimes_test/commons/enums.dart';
import 'package:vimes_test/models/document_model.dart';
import 'package:vimes_test/models/product_model.dart';
import 'package:vimes_test/page/entry_note/entry_note_cubit.dart';
import 'package:vimes_test/page/entry_note/widgets/labeled_form_field.dart';
import 'package:vimes_test/page/entry_note/widgets/signature_card.dart';
import 'package:vimes_test/page/entry_note/widgets/status_banner.dart';
import 'package:vimes_test/page/home/home_page.dart';
import 'package:vimes_test/repositories/document_repository.dart';
import 'package:vimes_test/repositories/grn_repositories.dart';
import 'package:vimes_test/repositories/product_repository.dart';
import 'package:vimes_test/repositories/user_session_repository.dart';

class GoodsReceivedFormScreen extends StatefulWidget {
  const GoodsReceivedFormScreen({super.key});

  @override
  State<GoodsReceivedFormScreen> createState() => _GoodsReceivedFormScreenState();
}

class _GoodsReceivedFormScreenState extends State<GoodsReceivedFormScreen>
    with SingleTickerProviderStateMixin {
  late GoodsReceivedCubit _cubit;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _cubit = GoodsReceivedCubit(
      goodsReceivedRepository:
          RepositoryProvider.of<GRNRepository>(context),
      userSessionRepository:
          RepositoryProvider.of<UserSessionRepository>(context),
      documentRepository: RepositoryProvider.of<DocumentRepository>(context),
      productRepository: RepositoryProvider.of<ProductRepository>(context),
    );
    _cubit.initNewNote();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          title: const Text('Phiếu Nhập Kho'),
          actions: [
            BlocBuilder<GoodsReceivedCubit, GoodsReceivedState>(
              builder: (context, state) {
                return TextButton.icon(
                  onPressed: state.loadStatus == LoadStatus.SAVING
                      ? null
                      : () => _confirmSaveDraft(context),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text(
                    'Lưu nháp',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Về trang chủ',
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                }
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: BlocBuilder<GoodsReceivedCubit, GoodsReceivedState>(
              builder: (context, state) => _buildRoundedTabHeader(state),
            ),
          ),
        ),
        bottomNavigationBar: BlocBuilder<GoodsReceivedCubit, GoodsReceivedState>(
          builder: (context, state) => _buildBottomActionBar(context, state),
        ),
        body: BlocConsumer<GoodsReceivedCubit, GoodsReceivedState>(
          listener: (context, state) {
            if (state.loadStatus == LoadStatus.FAILURE) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.msg),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
            if (state.loadStatus == LoadStatus.SUCCESS) {
              final isDraft = state.note.status == 'draft';
              final message = isDraft
                  ? 'Lưu nháp phiếu nhập kho thành công!'
                  : 'Lưu phiếu nhập kho thành công!';
              Navigator.of(context).pop(message);
            }
          },
          builder: (context, state) {
            if (state.loadStatus == LoadStatus.LOADING) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Thông tin chung & Chứng từ tham chiếu
                _buildTab1GeneralInfo(context, state),

                // TAB 2: Bảng nhập chi tiết sản phẩm / vật tư
                _buildTab2SuppliesTable(context, state),

                // TAB 3: Xác nhận & Ký duyệt
                _buildTab3Signatures(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // Header Tab viền bo tròn kèm chỉ báo hoàn thành (tick xanh)
  // ==========================================================================
  Widget _buildRoundedTabHeader(GoodsReceivedState state) {
    final primary = AppColors.accentPrimary;
    final activeIndex = _tabController.index;

    final isTab0Complete = state.note.noteNumber.isNotEmpty &&
        (state.note.delivererName.trim().isNotEmpty ||
            state.note.warehouse.trim().isNotEmpty);

    final isTab1Complete = state.items.isNotEmpty &&
        state.items.every((it) =>
            (it.itemDescription.trim().isNotEmpty ||
                it.itemCode.trim().isNotEmpty) &&
            it.actualQuantity > 0);

    final isTab2Complete = state.note.isFullySigned;

    Widget buildTabItem({
      required int index,
      required IconData icon,
      required String label,
      required bool isCompleted,
    }) {
      final isActive = activeIndex == index;
      return Expanded(
        child: InkWell(
          onTap: () => _tabController.animateTo(index),
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? primary.withValues(alpha: 0.12)
                  : (isCompleted
                      ? AppColors.statusApprovedBg.withValues(alpha: 0.45)
                      : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive
                    ? primary
                    : (isCompleted
                        ? AppColors.statusApprovedBorder
                        : Colors.grey.shade300),
                width: isActive ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isActive
                      ? primary
                      : (isCompleted
                          ? AppColors.statusApprovedText
                          : Colors.grey.shade600),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? primary
                          : (isCompleted
                              ? AppColors.statusApprovedText
                              : Colors.grey.shade700),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCompleted) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: AppColors.statusApprovedText,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          buildTabItem(
            index: 0,
            icon: Icons.description_outlined,
            label: 'Thông tin',
            isCompleted: isTab0Complete,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.chevron_right, size: 16, color: Colors.blueGrey),
          ),
          buildTabItem(
            index: 1,
            icon: Icons.table_chart_outlined,
            label: 'Vật tư',
            isCompleted: isTab1Complete,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.chevron_right, size: 16, color: Colors.blueGrey),
          ),
          buildTabItem(
            index: 2,
            icon: Icons.draw_outlined,
            label: 'Ký duyệt',
            isCompleted: isTab2Complete,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Nút hành động cố định ở Bottom Bar: phân biệt rõ nút chính và nút phụ
  // ==========================================================================
  Widget _buildBottomActionBar(BuildContext context, GoodsReceivedState state) {
    final activeIndex = _tabController.index;
    final isApproved = state.note.isFullySigned;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.8)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          if (activeIndex == 2) ...[
            OutlinedButton.icon(
              onPressed: state.loadStatus == LoadStatus.SAVING
                  ? null
                  : () => _confirmSaveDraft(context),
              label: const Text(
                'Lưu nháp',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: activeIndex < 2
                ? FilledButton.icon(
                    onPressed: () => _tabController.animateTo(activeIndex + 1),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(                          'Tiếp tục',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: state.loadStatus == LoadStatus.SAVING
                        ? null
                        : _cubit.saveNote,
                    icon: state.loadStatus == LoadStatus.SAVING
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      state.loadStatus == LoadStatus.SAVING
                          ? 'Đang lưu...'
                          : (isApproved
                              ? 'Lưu & Hoàn thành'
                              : 'Lưu (Chờ duyệt)'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isApproved
                          ? AppColors.statusApprovedText
                          : AppColors.accentNavy,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: Thông tin chung & Chứng từ tham chiếu
  // ==========================================================================
  Widget _buildTab1GeneralInfo(BuildContext context, GoodsReceivedState state) {
    final theme = Theme.of(context);
    final fmtDate = DateFormat('dd/MM/yyyy');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ 1: Thông tin phiếu nhập kho
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined,
                          color: AppColors.accentNavy, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'THÔNG TIN PHIẾU NHẬP KHO',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentNavy,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  LabeledReadOnlyField(
                    label: 'Số phiếu',
                    value: state.note.noteNumber.isEmpty
                        ? 'Đang tạo...'
                        : state.note.noteNumber,
                    prefixIcon: const Icon(Icons.tag_rounded,
                        size: 18, color: AppColors.textSub),
                  ),
                  const SizedBox(height: 12),
                  LabeledReadOnlyField(
                    label: 'Ngày lập phiếu',
                    value: fmtDate.format(state.note.date),
                    prefixIcon: const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textSub),
                  ),
                  const SizedBox(height: 12),
                  LabeledReadOnlyField(
                    label: 'Đơn vị',
                    value: state.note.unit.isEmpty ? '—' : state.note.unit,
                    prefixIcon: const Icon(Icons.business_outlined,
                        size: 18, color: AppColors.textSub),
                  ),
                  const SizedBox(height: 12),
                  LabeledReadOnlyField(
                    label: 'Bộ phận',
                    value: state.note.department.isEmpty
                        ? '—'
                        : state.note.department,
                    prefixIcon: const Icon(Icons.apartment_outlined,
                        size: 18, color: AppColors.textSub),
                  ),
                  const SizedBox(height: 12),
                  LabeledFormField(
                    label: 'Họ tên người giao hàng',
                    child: TextFormField(
                      initialValue: state.note.delivererName,
                      decoration: appInputDecoration(
                        hintText: 'Nhập họ và tên người giao',
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            size: 20, color: AppColors.textSub),
                      ),
                      onChanged: (v) => _cubit
                          .updateHeader((p) => p.copyWith(delivererName: v)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LabeledFormField(
                    label: 'Nhập tại kho',
                    child: TextFormField(
                      initialValue: state.note.warehouse,
                      decoration: appInputDecoration(
                        hintText: 'Nhập tên kho / địa điểm nhập',
                        prefixIcon: const Icon(Icons.warehouse_outlined,
                            size: 20, color: AppColors.textSub),
                      ),
                      onChanged: (v) =>
                          _cubit.updateHeader((p) => p.copyWith(warehouse: v)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Thẻ 2: Chứng từ tham chiếu kèm theo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attachment_rounded,
                          color: AppColors.accentNavy, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'CHỨNG TỪ THAM CHIẾU KÈM THEO',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentNavy,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  LabeledFormField(
                    label: 'Loại chứng từ',
                    child: DropdownButtonFormField<String>(
                      decoration: appInputDecoration(
                        hintText: 'Chọn loại chứng từ',
                        prefixIcon: const Icon(Icons.category_outlined,
                            size: 20, color: AppColors.textSub),
                      ),
                      initialValue: state.selectedDocumentType,
                      items: state.documentTypes
                          .map(
                            (type) => DropdownMenuItem(
                                value: type, child: Text(type)),
                          )
                          .toList(),
                      onChanged: (type) {
                        if (type != null) _cubit.selectDocumentType(type);
                      },
                    ),
                  ),
                  if (state.selectedDocumentType != null) ...[
                    const SizedBox(height: 12),
                    if (state.loadDocumentStatus == LoadStatus.LOADING)
                      const LinearProgressIndicator()
                    else
                      LabeledFormField(
                        label: 'Số chứng từ',
                        child: DropdownButtonFormField<DocumentModel>(
                          decoration: appInputDecoration(
                            hintText: 'Chọn số chứng từ',
                            prefixIcon: const Icon(Icons.receipt_outlined,
                                size: 20, color: AppColors.textSub),
                          ),
                          initialValue: state.selectedDocument,
                          items: state.documentsByType
                              .map(
                                (ct) => DropdownMenuItem(
                                  value: ct,
                                  child: Text(ct.documentNumber),
                                ),
                              )
                              .toList(),
                          onChanged: (ct) {
                            if (ct != null) _cubit.selectDocument(ct);
                          },
                        ),
                      ),
                  ],
                  if (state.selectedDocument != null) ...[
                    const SizedBox(height: 12),
                    LabeledReadOnlyField(
                      label: 'Ngày chứng từ',
                      value: fmtDate
                          .format(state.selectedDocument!.documentDate),
                      prefixIcon: const Icon(Icons.event_outlined,
                          size: 18, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 12),
                    LabeledReadOnlyField(
                      label: 'Đơn vị phát hành',
                      value: state.selectedDocument!.issuingUnit,
                      prefixIcon: const Icon(
                          Icons.corporate_fare_outlined,
                          size: 18,
                          color: AppColors.textSub),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 2: Bảng nhập chi tiết sản phẩm / vật tư
  // ==========================================================================
  Widget _buildTab2SuppliesTable(
      BuildContext context, GoodsReceivedState state) {
    final theme = Theme.of(context);
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thẻ tóm tắt thông tin nhanh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_rounded,
                        size: 18, color: AppColors.accentNavy),
                    const SizedBox(width: 8),
                    Text(
                      'Số phiếu: ${state.note.noteNumber.isEmpty ? "—" : state.note.noteNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentNavy,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${state.items.length} dòng vật tư',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.accentPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bảng nhập chi tiết sản phẩm / vật tư
          _SuppliesStickyTable(
            items: state.items,
            productsCatalog: state.productsCatalog,
            onSelectProduct: (index, product) =>
                _cubit.selectProduct(index, product),
            onUpdateDescription: (index, text) =>
                _cubit.updateItemDescription(index, text),
            onUpdateCode: (index, text) =>
                _cubit.updateItemCode(index, text),
            onUpdateUnit: (index, text) => _cubit.updateItem(
                index, (d) => d.copyWith(unit: text)),
            onUpdateDocQty: (index, qty) => _cubit.updateItem(
                index, (d) => d.copyWith(documentQuantity: qty)),
            onUpdateActualQty: (index, qty) => _cubit.updateItem(
                index, (d) => d.copyWith(actualQuantity: qty)),
            onUpdateUnitPrice: (index, price) => _cubit.updateItem(
                index, (d) => d.copyWith(unitPrice: price)),
            onRemoveItem: (index) => _cubit.removeItem(index),
          ),
          const SizedBox(height: 12),

          // Nút thêm dòng vật tư
          OutlinedButton.icon(
            onPressed: _cubit.addItem,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: const Text(
              'Thêm dòng vật tư',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: const BorderSide(color: AppColors.accentPrimary),
              foregroundColor: AppColors.accentPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Thẻ Quản lý công nợ & Thanh toán (Nợ tất cả / Nợ 1 phần)
          _DebtPaymentCard(
            state: state,
            cubit: _cubit,
          ),
          const SizedBox(height: 16),

          // Thẻ tổng cộng giá trị phiếu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng cộng tiền hàng:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSub,
                      ),
                    ),
                    Text(
                      currencyFmt.format(state.totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Bằng chữ: ${state.totalAmountInWords}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: Xác nhận & Ký duyệt
  // ==========================================================================
  Widget _buildTab3Signatures(BuildContext context, GoodsReceivedState state) {
    final theme = Theme.of(context);
    final currencyFmt = NumberFormat('#,###', 'vi_VN');
    final note = state.note;
    final isApproved = note.isFullySigned;
    final currentUser = state.currentUser;

    final missingSignatures = <String>[];
    if (note.deliveryPerson.trim().isEmpty) missingSignatures.add('Người giao hàng');
    if (note.storekeeper.trim().isEmpty) missingSignatures.add('Thủ kho');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Thẻ tóm tắt thông tin phiếu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          color: AppColors.accentNavy, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'TÓM TẮT PHIẾU NHẬP KHO',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentNavy,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Số phiếu:',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSub)),
                      Text(
                        note.noteNumber.isNotEmpty
                            ? note.noteNumber
                            : '(Chưa có số)',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Số loại vật tư:',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSub)),
                      Text(
                        '${state.items.length} mặt hàng',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tổng cộng tiền:',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSub)),
                      Text(
                        '${currencyFmt.format(state.totalAmount)} đ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!state.isDebt)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thanh toán / Công nợ:',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSub),
                        ),
                        Text(
                          'Thanh toán đủ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thanh toán / Công nợ:',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSub),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.debtType == 'all'
                              ? 'Nợ tất cả (${currencyFmt.format(state.totalAmount)} đ)'
                              : 'Nợ 1 phần: Còn nợ ${currencyFmt.format(state.debtAmount)} đ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: state.debtType == 'all'
                                ? AppColors.statusRejectedText
                                : AppColors.statusPendingText,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Banner trạng thái ký duyệt
            if (isApproved)
              const StatusBanner(
                type: StatusBannerType.approved,
                title: 'Đủ điều kiện Hoàn thành',
                message:
                    'Đã có đủ chữ ký của Người giao hàng và Thủ kho. Phiếu sẽ hoàn thành khi lưu.',
              )
            else
              StatusBanner(
                type: StatusBannerType.pending,
                title: 'Chưa đủ chữ ký (Chờ duyệt)',
                message:
                    'Còn thiếu: ${missingSignatures.join(' và ')}. Phiếu sẽ ở trạng thái Chờ duyệt nếu lưu bây giờ.',
              ),
            const SizedBox(height: 20),

            Text(
              'DANH SÁCH CHỮ KÝ',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 10),

            // 1. Người lập phiếu (readonly)
            SignatureCard(
              title: '1. Người lập phiếu',
              roleNote: 'Tự động điền theo tài khoản hiện tại',
              isRequired: true,
              isReadOnly: true,
              signerName: note.preparedBy,
              badgeText: 'Đã lập & ký',
              onTapEdit: null,
              onTapQuickSign: null,
              onTapClear: null,
            ),
            const SizedBox(height: 12),

            // 2. Người giao hàng (bắt buộc)
            SignatureCard(
              title: '2. Người giao hàng',
              roleNote: currentUser?.role == 'delivery'
                  ? 'Khớp vai trò của bạn (Người giao hàng)'
                  : 'Bắt buộc để hoàn thành phiếu',
              isRequired: true,
              isReadOnly: false,
              signerName: note.deliveryPerson,
              badgeText: currentUser?.role == 'delivery' &&
                      note.deliveryPerson.isNotEmpty
                  ? 'Đã ký tự động'
                  : 'Đã ký',
              onTapEdit: () => _showSignDialog(
                context: context,
                title: 'Người giao hàng',
                currentName: note.deliveryPerson,
                suggestedName: currentUser?.displayName,
                onSaved: (val) => _cubit.kyPhieu(deliveryPerson: val),
              ),
              onTapQuickSign: currentUser != null &&
                      currentUser.displayName.isNotEmpty
                  ? () =>
                      _cubit.kyPhieu(deliveryPerson: currentUser.displayName)
                  : null,
              onTapClear: note.deliveryPerson.isNotEmpty
                  ? () => _cubit.kyPhieu(deliveryPerson: '')
                  : null,
            ),
            const SizedBox(height: 12),

            // 3. Thủ kho (bắt buộc)
            SignatureCard(
              title: '3. Thủ kho',
              roleNote: (currentUser?.role == 'warehouse_keeper' ||
                      currentUser?.role == 'warehouse_manager')
                  ? 'Khớp vai trò của bạn (Thủ kho)'
                  : 'Bắt buộc để hoàn thành phiếu',
              isRequired: true,
              isReadOnly: false,
              signerName: note.storekeeper,
              badgeText: (currentUser?.role == 'warehouse_keeper' ||
                          currentUser?.role == 'warehouse_manager') &&
                      note.storekeeper.isNotEmpty
                  ? 'Đã ký tự động'
                  : 'Đã ký',
              onTapEdit: () => _showSignDialog(
                context: context,
                title: 'Thủ kho',
                currentName: note.storekeeper,
                suggestedName: currentUser?.displayName,
                onSaved: (val) => _cubit.kyPhieu(storekeeper: val),
              ),
              onTapQuickSign: currentUser != null &&
                      currentUser.displayName.isNotEmpty
                  ? () => _cubit.kyPhieu(storekeeper: currentUser.displayName)
                  : null,
              onTapClear: note.storekeeper.isNotEmpty
                  ? () => _cubit.kyPhieu(storekeeper: '')
                  : null,
            ),
            const SizedBox(height: 12),

            // 4. Kế toán trưởng (tuỳ chọn)
            SignatureCard(
              title: '4. Kế toán trưởng',
              roleNote: currentUser?.role == 'chief_accountant'
                  ? 'Khớp vai trò của bạn (Kế toán trưởng)'
                  : 'Tùy chọn (không bắt buộc)',
              isRequired: false,
              isReadOnly: false,
              signerName: note.chiefAccountant,
              badgeText: currentUser?.role == 'chief_accountant' &&
                      note.chiefAccountant.isNotEmpty
                  ? 'Đã ký tự động'
                  : 'Đã ký',
              onTapEdit: () => _showSignDialog(
                context: context,
                title: 'Kế toán trưởng',
                currentName: note.chiefAccountant,
                suggestedName: currentUser?.displayName,
                onSaved: (val) => _cubit.kyPhieu(chiefAccountant: val),
              ),
              onTapQuickSign: currentUser != null &&
                      currentUser.displayName.isNotEmpty
                  ? () =>
                      _cubit.kyPhieu(chiefAccountant: currentUser.displayName)
                  : null,
              onTapClear: note.chiefAccountant.isNotEmpty
                  ? () => _cubit.kyPhieu(chiefAccountant: '')
                  : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSignDialog({
    required BuildContext context,
    required String title,
    required String currentName,
    String? suggestedName,
    required void Function(String) onSaved,
  }) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Ký xác nhận: $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledFormField(
              label: 'Họ và tên người ký',
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: appInputDecoration(
                  hintText: 'Nhập họ và tên',
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      size: 20, color: AppColors.textSub),
                ),
              ),
            ),
            if (suggestedName != null && suggestedName.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  controller.text = suggestedName;
                },
                icon: const Icon(Icons.badge_outlined, size: 16),
                label: Text('Dùng tên tài khoản ($suggestedName)'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              onSaved(val);
              Navigator.of(dialogCtx).pop();
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSaveDraft(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded,
                color: AppColors.textSub, size: 22),
            SizedBox(width: 8),
            Text('Lưu nháp phiếu?'),
          ],
        ),
        content: const Text(
          'Phiếu nhập kho sẽ được lưu với trạng thái "Lưu nháp". Bạn có thể quay lại chỉnh sửa và hoàn thiện bất cứ lúc nào.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.save_as_rounded, size: 16),
            label: const Text('Xác nhận lưu nháp'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textSub,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      _cubit.saveDraft();
    }
  }
}

// ============================================================================
// BẢNG DỮ LIỆU VẬT TƯ: Cột STT & Tên cố định bên trái, các cột còn lại cuộn ngang
// ============================================================================
class _SuppliesStickyTable extends StatelessWidget {
  final List<dynamic> items;
  final List<ProductModel> productsCatalog;
  final void Function(int index, ProductModel product) onSelectProduct;
  final void Function(int index, String text) onUpdateDescription;
  final void Function(int index, String text) onUpdateCode;
  final void Function(int index, String text) onUpdateUnit;
  final void Function(int index, double qty) onUpdateDocQty;
  final void Function(int index, double qty) onUpdateActualQty;
  final void Function(int index, double price) onUpdateUnitPrice;
  final void Function(int index) onRemoveItem;

  const _SuppliesStickyTable({
    required this.items,
    required this.productsCatalog,
    required this.onSelectProduct,
    required this.onUpdateDescription,
    required this.onUpdateCode,
    required this.onUpdateUnit,
    required this.onUpdateDocQty,
    required this.onUpdateActualQty,
    required this.onUpdateUnitPrice,
    required this.onRemoveItem,
  });

  static const double rowHeight = 64.0;
  static const double headerHeight = 48.0;
  static const double colSttWidth = 48.0;
  static const double colNameWidth = 165.0; // Ô B thu nhỏ theo yêu cầu
  static const double colCodeWidth = 130.0;
  static const double colUnitWidth = 90.0;
  static const double colDocQtyWidth = 110.0;
  static const double colActualQtyWidth = 110.0;
  static const double colPriceWidth = 130.0;
  static const double colTotalWidth = 140.0;
  static const double colActionWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final borderColor = Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CỘT CỐ ĐỊNH BÊN TRÁI (STT + Tên/ nhãn hiệu/ hàng hoá)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  right:
                      BorderSide(color: Colors.blueGrey.shade200, width: 1.5),
                ),
              ),
              child: Column(
                children: [
                  // Header 2 hàng của phần cố định
                  Container(
                    height: headerHeight,
                    color: Colors.blueGrey.shade50,
                    child: Row(
                      children: [
                        _buildHeaderCell(
                          width: colSttWidth,
                          title: 'STT',
                        ),
                        Container(width: 1, color: borderColor),
                        _buildHeaderCell(
                          width: colNameWidth,
                          title: 'Tên/ nhãn hiệu/\nhàng hoá',
                          align: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: borderColor),

                  // Các dòng dữ liệu phần cố định
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    return Container(
                      height: rowHeight,
                      decoration: BoxDecoration(
                        color:
                            index.isEven ? Colors.white : Colors.grey.shade50,
                        border: Border(
                          bottom: BorderSide(color: borderColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Cột STT (A)
                          SizedBox(
                            width: colSttWidth,
                            child: Center(
                              child: Text(
                                '${item.stt}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          Container(width: 1, color: borderColor),

                          // Cột Tên hàng hoá (B) kèm Autocomplete gợi ý
                          SizedBox(
                            width: colNameWidth,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: _ProductAutocompleteField(
                                key: ValueKey('desc_${item.id}'),
                                initialValue: item.itemDescription,
                                productsCatalog: productsCatalog,
                                hintText: 'Tên vật tư...',
                                onSelected: (product) =>
                                    onSelectProduct(index, product),
                                onChanged: (val) =>
                                    onUpdateDescription(index, val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // CỘT CUỘN NGANG BÊN PHẢI (Mã, ĐVT, SL Chứng từ, SL Thực nhập, Đơn giá, Thành tiền, Xoá)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    // Header 2 hàng của phần cuộn ngang
                    Container(
                      height: headerHeight,
                      color: Colors.blueGrey.shade50,
                      child: Row(
                        children: [
                          _buildHeaderCell(
                            width: colCodeWidth,
                            title: 'Mã số',
                          ),
                          Container(width: 1, color: borderColor),
                          _buildHeaderCell(
                            width: colUnitWidth,
                            title: 'Đơn vị\ntính',
                          ),
                          Container(width: 1, color: borderColor),
                          _buildHeaderCell(
                            width: colDocQtyWidth,
                            title: 'Số lượng\nTheo CT',
                          ),
                          Container(width: 1, color: borderColor),
                          _buildHeaderCell(
                            width: colActualQtyWidth,
                            title: 'Số lượng\nThực nhập',
                          ),
                          Container(width: 1, color: borderColor),
                          _buildHeaderCell(
                            width: colPriceWidth,
                            title: 'Đơn giá',
                          ),
                          Container(width: 1, color: borderColor),
                          _buildHeaderCell(
                            width: colTotalWidth,
                            title: 'Thành tiền',
                          ),
                          Container(width: 1, color: borderColor),
                          _buildHeaderCell(
                            width: colActionWidth,
                            title: 'Xoá',
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: borderColor),

                    // Các dòng dữ liệu phần cuộn ngang
                    ...List.generate(items.length, (index) {
                      final item = items[index];
                      return Container(
                        height: rowHeight,
                        decoration: BoxDecoration(
                          color:
                              index.isEven ? Colors.white : Colors.grey.shade50,
                          border: Border(
                            bottom: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Mã số (C)
                            SizedBox(
                              width: colCodeWidth,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: _CodeAutocompleteField(
                                  key: ValueKey('code_${item.id}'),
                                  initialValue: item.itemCode,
                                  productsCatalog: productsCatalog,
                                  hintText: 'Mã VT',
                                  onSelected: (product) =>
                                      onSelectProduct(index, product),
                                  onChanged: (val) =>
                                      onUpdateCode(index, val),
                                ),
                              ),
                            ),
                            Container(width: 1, color: borderColor),

                            // Đơn vị tính (D)
                            SizedBox(
                              width: colUnitWidth,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _EditableCell(
                                  key: ValueKey('unit_${item.id}'),
                                  initialValue: item.unit,
                                  hintText: 'ĐVT',
                                  textAlign: TextAlign.center,
                                  onChanged: (v) => onUpdateUnit(index, v),
                                ),
                              ),
                            ),
                            Container(width: 1, color: borderColor),

                            // SL Theo chứng từ (1)
                            SizedBox(
                              width: colDocQtyWidth,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _EditableCell(
                                  key: ValueKey('docQty_${item.id}'),
                                  initialValue: item.documentQuantity == 0
                                      ? ''
                                      : item.documentQuantity
                                          .toString()
                                          .replaceAll(RegExp(r'\.0$'), ''),
                                  hintText: '0',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  textAlign: TextAlign.right,
                                  onChanged: (v) => onUpdateDocQty(
                                      index, double.tryParse(v) ?? 0),
                                ),
                              ),
                            ),
                            Container(width: 1, color: borderColor),

                            // SL Thực nhập (2)
                            SizedBox(
                              width: colActualQtyWidth,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _EditableCell(
                                  key: ValueKey('actQty_${item.id}'),
                                  initialValue: item.actualQuantity == 0
                                      ? ''
                                      : item.actualQuantity
                                          .toString()
                                          .replaceAll(RegExp(r'\.0$'), ''),
                                  hintText: '0',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  textAlign: TextAlign.right,
                                  onChanged: (v) => onUpdateActualQty(
                                      index, double.tryParse(v) ?? 0),
                                ),
                              ),
                            ),
                            Container(width: 1, color: borderColor),

                            // Đơn giá (3)
                            SizedBox(
                              width: colPriceWidth,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _EditableCell(
                                  key: ValueKey('price_${item.id}'),
                                  initialValue: item.unitPrice == 0
                                      ? ''
                                      : item.unitPrice
                                          .toString()
                                          .replaceAll(RegExp(r'\.0$'), ''),
                                  hintText: '0',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  textAlign: TextAlign.right,
                                  onChanged: (v) => onUpdateUnitPrice(
                                      index, double.tryParse(v) ?? 0),
                                ),
                              ),
                            ),
                            Container(width: 1, color: borderColor),

                            // Thành tiền (4) - Tự động tính = Đơn giá * Thực nhập
                            SizedBox(
                              width: colTotalWidth,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    currencyFmt.format(item.totalPrice),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: item.totalPrice > 0
                                          ? Colors.blue.shade900
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, color: borderColor),

                            // Nút Xoá dòng
                            SizedBox(
                              width: colActionWidth,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  tooltip: 'Xoá dòng này',
                                  onPressed: () => onRemoveItem(index),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header ô tên cột
  Widget _buildHeaderCell({
    required double width,
    required String title,
    String symbol = '',
    TextAlign align = TextAlign.center,
  }) {
    return SizedBox(
      width: width,
      height: headerHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                title,
                textAlign: align,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          if (symbol.isNotEmpty) ...[
            Container(height: 1, color: Colors.grey.shade300),
            Container(
              height: 22,
              alignment: Alignment.center,
              color: Colors.blueGrey.shade100,
              child: Text(
                symbol,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget ô nhập liệu có thể chỉnh sửa dạng inline
class _EditableCell extends StatefulWidget {
  final String initialValue;
  final String hintText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextAlign textAlign;
  final ValueChanged<String> onChanged;

  const _EditableCell({
    super.key,
    required this.initialValue,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.textAlign = TextAlign.start,
    required this.onChanged,
  });

  @override
  State<_EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<_EditableCell> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        widget.initialValue != _controller.text &&
        widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textAlign: widget.textAlign,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      onChanged: widget.onChanged,
      onSubmitted: (val) {
        _focusNode.unfocus();
      },
    );
  }
}

// Ô nhập Tên hàng hoá kèm Autocomplete gợi ý
class _ProductAutocompleteField extends StatelessWidget {
  final String initialValue;
  final List<ProductModel> productsCatalog;
  final String hintText;
  final ValueChanged<ProductModel> onSelected;
  final ValueChanged<String> onChanged;

  const _ProductAutocompleteField({
    super.key,
    required this.initialValue,
    required this.productsCatalog,
    required this.hintText,
    required this.onSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ProductModel>(
      initialValue: TextEditingValue(text: initialValue),
      displayStringForOption: (ProductModel option) => option.itemDescription,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<ProductModel>.empty();
        }
        final query = textEditingValue.text.toLowerCase().trim();
        return productsCatalog.where((ProductModel option) {
          return option.itemDescription.toLowerCase().contains(query) ||
              option.itemCode.toLowerCase().contains(query);
        });
      },
      onSelected: onSelected,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        if (initialValue != textEditingController.text &&
            !focusNode.hasFocus) {
          textEditingController.text = initialValue;
        }

        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
          onChanged: onChanged,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 320),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final ProductModel option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.itemDescription,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Mã: ${option.itemCode} | ĐVT: ${option.unit}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// Ô nhập Mã vật tư kèm Autocomplete gợi ý
class _CodeAutocompleteField extends StatelessWidget {
  final String initialValue;
  final List<ProductModel> productsCatalog;
  final String hintText;
  final ValueChanged<ProductModel> onSelected;
  final ValueChanged<String> onChanged;

  const _CodeAutocompleteField({
    super.key,
    required this.initialValue,
    required this.productsCatalog,
    required this.hintText,
    required this.onSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ProductModel>(
      initialValue: TextEditingValue(text: initialValue),
      displayStringForOption: (ProductModel option) => option.itemCode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<ProductModel>.empty();
        }
        final query = textEditingValue.text.toLowerCase().trim();
        return productsCatalog.where((ProductModel option) {
          return option.itemCode.toLowerCase().contains(query) ||
              option.itemDescription.toLowerCase().contains(query);
        });
      },
      onSelected: onSelected,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        if (initialValue != textEditingController.text &&
            !focusNode.hasFocus) {
          textEditingController.text = initialValue;
        }

        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
          onChanged: onChanged,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 260),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final ProductModel option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.itemCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            option.itemDescription,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}


/// ---------------------------------------------------------------------------
/// Widget Thẻ Quản Lý Công Nợ & Thanh Toán (Nợ tất cả / Nợ 1 phần)
/// ---------------------------------------------------------------------------
class _DebtPaymentCard extends StatefulWidget {
  final GoodsReceivedState state;
  final GoodsReceivedCubit cubit;

  const _DebtPaymentCard({
    required this.state,
    required this.cubit,
  });

  @override
  State<_DebtPaymentCard> createState() => _DebtPaymentCardState();
}

class _DebtPaymentCardState extends State<_DebtPaymentCard> {
  late TextEditingController _paidController;

  @override
  void initState() {
    super.initState();
    final initialPaid = widget.state.paidAmount;
    _paidController = TextEditingController(
      text: initialPaid > 0 ? initialPaid.toStringAsFixed(0) : '',
    );
  }

  @override
  void didUpdateWidget(covariant _DebtPaymentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.debtType == 'all' && oldWidget.state.debtType != 'all') {
      _paidController.text = '';
    }
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = widget.cubit;
    final currencyFmt = NumberFormat('#,###', 'vi_VN');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state.isDebt
              ? (state.debtType == 'all'
                  ? AppColors.statusRejectedBorder.withValues(alpha: 0.7)
                  : AppColors.statusPendingBorder.withValues(alpha: 0.7))
              : AppColors.cardBorder,
          width: state.isDebt ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Ô tích Nợ
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: state.isDebt
                      ? (state.debtType == 'all'
                          ? AppColors.statusRejectedBg
                          : AppColors.statusPendingBg)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: state.isDebt
                      ? (state.debtType == 'all'
                          ? AppColors.statusRejectedText
                          : AppColors.statusPendingText)
                      : AppColors.accentNavy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CÔNG NỢ & THANH TOÁN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      state.isDebt
                          ? 'Đang bật chế độ ghi nợ tiền hàng'
                          : 'Mặc định: Thanh toán đủ khi nhập kho',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: state.isDebt ? Colors.red.shade700 : AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              // Ô tích Nợ
              InkWell(
                onTap: () => cubit.toggleDebt(!state.isDebt),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: state.isDebt,
                        activeColor: const Color(0xFFDC2626),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (val) => cubit.toggleDebt(val ?? false),
                      ),
                      const Text(
                        'Nợ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Khi tích chọn Nợ: hiển thị tùy chọn Nợ tất cả & Nợ 1 phần
          if (state.isDebt) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            const Text(
              'Hình thức ghi nợ:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 8),

            // 2 Lựa chọn: Nợ tất cả vs Nợ 1 phần
            Row(
              children: [
                // Nợ tất cả
                Expanded(
                  child: InkWell(
                    onTap: () => cubit.setDebtType('all'),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: state.debtType == 'all'
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: state.debtType == 'all'
                              ? const Color(0xFFDC2626)
                              : Colors.grey.shade300,
                          width: state.debtType == 'all' ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.debtType == 'all'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: state.debtType == 'all'
                                ? const Color(0xFFDC2626)
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nợ tất cả',
                              style: TextStyle(
                                fontWeight: state.debtType == 'all'
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: state.debtType == 'all'
                                    ? const Color(0xFF991B1B)
                                    : AppColors.textMain,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Nợ 1 phần
                Expanded(
                  child: InkWell(
                    onTap: () => cubit.setDebtType('partial'),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: state.debtType == 'partial'
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: state.debtType == 'partial'
                              ? const Color(0xFFD97706)
                              : Colors.grey.shade300,
                          width: state.debtType == 'partial' ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.debtType == 'partial'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: state.debtType == 'partial'
                                ? const Color(0xFFD97706)
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nợ 1 phần',
                              style: TextStyle(
                                fontWeight: state.debtType == 'partial'
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: state.debtType == 'partial'
                                    ? const Color(0xFF92400E)
                                    : AppColors.textMain,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Chi tiết theo từng loại nợ
            if (state.debtType == 'all') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiền ghi nợ toàn bộ:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    Text(
                      '${currencyFmt.format(state.totalAmount)} đ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Giao diện khi chọn Nợ 1 phần
              TextFormField(
                controller: _paidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền đã thanh toán (trả trước)',
                  hintText: 'Nhập số tiền đã trả...',
                  suffixText: 'đ',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  errorText: state.paidAmount > state.totalAmount
                      ? 'Số tiền đã thanh toán vượt quá tổng giá trị phiếu'
                      : null,
                ),
                onChanged: (val) {
                  final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                  final parsed = double.tryParse(clean) ?? 0.0;
                  cubit.setPaidAmount(parsed);
                },
              ),
              const SizedBox(height: 8),

              // Gợi ý tỷ lệ nhanh
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.pie_chart_outline, size: 14),
                    label: const Text('Trả 30%', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      final val = (state.totalAmount * 0.3).roundToDouble();
                      _paidController.text = val.toStringAsFixed(0);
                      cubit.setPaidAmount(val);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.pie_chart_outline, size: 14),
                    label: const Text('Trả 50%', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      final val = (state.totalAmount * 0.5).roundToDouble();
                      _paidController.text = val.toStringAsFixed(0);
                      cubit.setPaidAmount(val);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.pie_chart_outline, size: 14),
                    label: const Text('Trả 70%', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      final val = (state.totalAmount * 0.7).roundToDouble();
                      _paidController.text = val.toStringAsFixed(0);
                      cubit.setPaidAmount(val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Thẻ phân tích: Đã thanh toán & Còn nợ
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Đã thanh toán:',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                        ),
                        Text(
                          '${currencyFmt.format(state.actualPaidAmount)} đ',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số tiền còn nợ:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${currencyFmt.format(state.debtAmount)} đ',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}