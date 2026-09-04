import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vimes_test/commons/app_colors.dart';
import 'package:vimes_test/commons/enums.dart';
import 'package:vimes_test/models/GRN_model.dart';
import 'package:vimes_test/models/supplies_model.dart';
import 'package:vimes_test/page/entry_note_detail/entry_note_detail_cubit.dart';
import 'package:vimes_test/repositories/grn_repositories.dart';

class EntryNoteDetailPage extends StatelessWidget {
  final String noteId;
  final GoodsReceivedNoteModel? initialNote;
  final List<SuppliesModel>? initialItems;

  const EntryNoteDetailPage({
    super.key,
    required this.noteId,
    this.initialNote,
    this.initialItems,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = EntryNoteDetailCubit(
          grnRepository: RepositoryProvider.of<GRNRepository>(context),
          initialNote: initialNote,
          initialItems: initialItems,
        );
        cubit.loadNoteDetail(noteId);
        return cubit;
      },
      child: const _EntryNoteDetailView(),
    );
  }
}

class _EntryNoteDetailView extends StatelessWidget {
  const _EntryNoteDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        foregroundColor: Colors.white,
        elevation: 0,
        title: BlocBuilder<EntryNoteDetailCubit, EntryNoteDetailState>(
          builder: (context, state) {
            final code = state.note?.noteNumber ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết phiếu nhập kho',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                if (code.isNotEmpty)
                  Text(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'In phiếu nhập kho',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng in phiếu đang được kết nối máy in WMS.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Chia sẻ / Xuất file',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã tạo liên kết tài liệu phiếu nhập kho.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<EntryNoteDetailCubit, EntryNoteDetailState>(
        builder: (context, state) {
          if (state.loadStatus == LoadStatus.LOADING && state.note == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải dữ liệu phiếu nhập kho...',
                    style: TextStyle(color: Color(0xFF475569)),
                  ),
                ],
              ),
            );
          }

          if (state.loadStatus == LoadStatus.FAILURE && state.note == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không thể tải thông tin phiếu',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Quay lại danh sách'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final note = state.note;
          if (note == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final fmtDate = DateFormat('dd/MM/yyyy • HH:mm');
          final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Thẻ Header tổng quan phiếu
                _buildHeaderCard(context, note, fmtDate),
                const SizedBox(height: 14),

                // 2. Thẻ Chứng từ tham chiếu đính kèm
                _buildDocumentCard(context, note),
                const SizedBox(height: 14),

                // 3. Bảng danh sách chi tiết vật tư
                _buildSuppliesSection(context, state, currencyFmt),
                const SizedBox(height: 14),

                // 4. Thẻ Tổng giá trị phiếu
                _buildSummaryCard(context, state, currencyFmt),
                const SizedBox(height: 14),

                // 5. Khu vực chữ ký các bên xác nhận
                _buildSignaturesCard(context, note),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // 1. THẺ THÔNG TIN CHUNG PHIẾU NHẬP KHO
  // ==========================================================================
  Widget _buildHeaderCard(
    BuildContext context,
    GoodsReceivedNoteModel note,
    DateFormat fmtDate,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row đầu: Số phiếu & Badge trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SỐ PHIẾU NHẬP KHO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.noteNumber.isNotEmpty ? note.noteNumber : 'Chưa có số',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF22C55E)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Color(0xFF166534)),
                        SizedBox(width: 4),
                        Text(
                          'Đã nhập kho',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (note.isDebt) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: note.debtType == 'all'
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: note.debtType == 'all'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            note.debtType == 'all'
                                ? Icons.warning_amber_rounded
                                : Icons.pie_chart_outline,
                            size: 13,
                            color: note.debtType == 'all'
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF92400E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            note.debtType == 'all' ? 'Nợ tất cả' : 'Nợ 1 phần',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: note.debtType == 'all'
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Lưới thông tin chi tiết
          _buildInfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Ngày lập phiếu',
            value: fmtDate.format(note.date),
          ),
          const SizedBox(height: 8),
          _buildInfoTile(
            icon: Icons.business_outlined,
            label: 'Đơn vị / Bộ phận',
            value: [
              if (note.unit.isNotEmpty) note.unit,
              if (note.department.isNotEmpty) note.department,
            ].join(' - ').ifEmpty('—'),
          ),
          const SizedBox(height: 8),
          _buildInfoTile(
            icon: Icons.person_pin_outlined,
            label: 'Người giao hàng',
            value: note.delivererName.ifEmpty('—'),
            highlightValue: true,
          ),
          const SizedBox(height: 8),
          _buildInfoTile(
            icon: Icons.warehouse_outlined,
            label: 'Nhập tại kho',
            value: note.warehouse.ifEmpty('—'),
            highlightValue: true,
          ),
          if (note.contractNumber.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoTile(
              icon: Icons.handshake_outlined,
              label: 'Theo hợp đồng số',
              value: note.contractNumber,
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. THẺ CHỨNG TỪ THAM CHIẾU KÈM THEO
  // ==========================================================================
  Widget _buildDocumentCard(BuildContext context, GoodsReceivedNoteModel note) {
    final fmtDate = DateFormat('dd/MM/yyyy');
    final hasDoc = note.documentType.isNotEmpty ||
        note.documentNumber.isNotEmpty ||
        note.issuingUnit.isNotEmpty ||
        note.attachedOriginalDocument.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'CHỨNG TỪ THAM CHIẾU KÈM THEO',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          if (!hasDoc)
            const Text(
              'Không có chứng từ tham chiếu đính kèm.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            )
          else ...[
            _buildInfoTile(
              icon: Icons.category_outlined,
              label: 'Loại chứng từ',
              value: note.documentType.ifEmpty('—'),
            ),
            const SizedBox(height: 8),
            _buildInfoTile(
              icon: Icons.confirmation_number_outlined,
              label: 'Số chứng từ',
              value: note.documentNumber.ifEmpty('—'),
              highlightValue: true,
            ),
            if (note.documentDate != null) ...[
              const SizedBox(height: 8),
              _buildInfoTile(
                icon: Icons.event_note_outlined,
                label: 'Ngày chứng từ',
                value: fmtDate.format(note.documentDate!),
              ),
            ],
            if (note.issuingUnit.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoTile(
                icon: Icons.domain_outlined,
                label: 'Đơn vị phát hành',
                value: note.issuingUnit,
              ),
            ],
            if (note.attachedOriginalDocument.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoTile(
                icon: Icons.attach_file_outlined,
                label: 'Tài liệu gốc kèm theo',
                value: note.attachedOriginalDocument,
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. BẢNG DANH SÁCH CHI TIẾT VẬT TƯ / HÀNG HOÁ
  // ==========================================================================
  Widget _buildSuppliesSection(
    BuildContext context,
    EntryNoteDetailState state,
    NumberFormat currencyFmt,
  ) {
    final items = state.items;
    final borderColor = const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tiêu đề danh sách
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.table_chart_outlined,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DANH SÁCH VẬT TƯ, HÀNG HÓA',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Phiếu nhập kho này chưa có chi tiết vật tư.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
                columnSpacing: 20,
                horizontalMargin: 16,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
                border: TableBorder(
                  horizontalInside: BorderSide(color: borderColor, width: 1),
                ),
                columns: const [
                  DataColumn(
                    label: Center(child: Text('STT', textAlign: TextAlign.center)),
                  ),
                  DataColumn(
                    label: Text('Tên, nhãn hiệu, quy cách'),
                  ),
                  DataColumn(
                    label: Text('Mã số'),
                  ),
                  DataColumn(
                    label: Text('ĐVT'),
                  ),
                  DataColumn(
                    label: Text('SL theo CT', textAlign: TextAlign.right),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('SL thực nhập', textAlign: TextAlign.right),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Đơn giá', textAlign: TextAlign.right),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Thành tiền', textAlign: TextAlign.right),
                    numeric: true,
                  ),
                ],
                rows: items.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Center(
                          child: Text(
                            '${item.stt}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            item.itemDescription.ifEmpty('—'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.itemCode.ifEmpty('—'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(Text(item.unit.ifEmpty('—'))),
                      DataCell(
                        Text(
                          _formatQty(item.documentQuantity),
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatQty(item.actualQuantity),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      DataCell(Text(currencyFmt.format(item.unitPrice))),
                      DataCell(
                        Text(
                          currencyFmt.format(item.totalPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 4. THẺ TỔNG GIÁ TRỊ PHIẾU
  // ==========================================================================
  Widget _buildSummaryCard(
    BuildContext context,
    EntryNoteDetailState state,
    NumberFormat currencyFmt,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG CỘNG TIỀN HÀNG:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                currencyFmt.format(state.totalAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bằng chữ: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              Expanded(
                child: Text(
                  state.totalAmountInWords,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          // Thông tin Công nợ & Thanh toán
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: state.note?.isDebt == true
                  ? (state.note?.debtType == 'all'
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFFFFBEB))
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.note?.isDebt == true
                    ? (state.note?.debtType == 'all'
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFFDE68A))
                    : const Color(0xFFBBF7D0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          state.note?.isDebt == true
                              ? (state.note?.debtType == 'all'
                                  ? Icons.money_off_rounded
                                  : Icons.pie_chart_rounded)
                              : Icons.check_circle_rounded,
                          size: 18,
                          color: state.note?.isDebt == true
                              ? (state.note?.debtType == 'all'
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFD97706))
                              : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TÌNH TRẠNG CÔNG NỢ:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                            color: state.note?.isDebt == true
                                ? (state.note?.debtType == 'all'
                                    ? const Color(0xFF991B1B)
                                    : const Color(0xFF92400E))
                                : const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      state.note?.isDebt == true
                          ? (state.note?.debtType == 'all'
                              ? 'Nợ tất cả (100%)'
                              : 'Nợ 1 phần')
                          : 'Đã thanh toán đủ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: state.note?.isDebt == true
                            ? (state.note?.debtType == 'all'
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD97706))
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                if (state.note?.isDebt == true) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đã thanh toán / trả trước:',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                      Text(
                        currencyFmt.format(state.note?.paidAmount ?? 0),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số tiền còn nợ lại:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        currencyFmt.format(
                          state.note?.debtAmount != null && (state.note?.debtAmount ?? 0) > 0
                              ? state.note!.debtAmount
                              : (state.note?.debtType == 'all'
                                  ? state.totalAmount
                                  : (state.totalAmount - (state.note?.paidAmount ?? 0)).clamp(0, state.totalAmount)),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 5. KHU VỰC CHỮ KÝ XÁC NHẬN CÁC BÊN (có nút Ký xác nhận nếu phiếu pending)
  // ==========================================================================
  Widget _buildSignaturesCard(
    BuildContext context,
    GoodsReceivedNoteModel note,
  ) {
    final cubit = context.read<EntryNoteDetailCubit>();
    final isFullySigned = note.isFullySigned;
    final canSign = note.status != 'rejected' && (!isFullySigned || note.status == 'pending' || note.status == 'draft');

    final missingSignatures = <String>[];
    if (note.deliveryPerson.trim().isEmpty) missingSignatures.add('Người giao hàng');
    if (note.storekeeper.trim().isEmpty) missingSignatures.add('Thủ kho');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.draw_outlined, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'XÁC NHẬN KÝ DUYỆT PHIẾU',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Banner trạng thái chữ ký
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isFullySigned ? AppColors.statusApprovedBg : AppColors.statusPendingBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFullySigned ? AppColors.statusApprovedBorder : AppColors.statusPendingBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isFullySigned ? Icons.check_circle : Icons.pending_actions,
                  size: 16,
                  color: isFullySigned ? AppColors.statusApprovedText : AppColors.statusPendingText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isFullySigned
                        ? 'Đủ chữ ký – Hoàn thành'
                        : missingSignatures.isEmpty
                            ? 'Chờ duyệt'
                            : 'Chờ ký: ${missingSignatures.join(', ')}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isFullySigned ? AppColors.statusApprovedText : AppColors.statusPendingText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Các ô chữ ký
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSignatureBox(
                  context: context,
                  role: 'Người lập phiếu',
                  name: note.preparedBy.ifEmpty(note.createdBy).ifEmpty('—'),
                  isSigned: note.preparedBy.trim().isNotEmpty || note.createdBy.trim().isNotEmpty,
                  canSign: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSignatureBox(
                  context: context,
                  role: 'Người giao hàng',
                  name: note.deliveryPerson.trim().isNotEmpty ? note.deliveryPerson : '—',
                  isSigned: note.deliveryPerson.trim().isNotEmpty,
                  canSign: canSign && note.deliveryPerson.trim().isEmpty,
                  onSign: (name) => cubit.kyXacNhan(deliveryPerson: name),
                  suggestedName: note.delivererName.trim().isNotEmpty ? note.delivererName : null,
                  noteSubtitle: (note.deliveryPerson.trim().isEmpty && note.delivererName.trim().isNotEmpty)
                      ? 'Bên giao: ${note.delivererName}'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSignatureBox(
                  context: context,
                  role: 'Thủ kho',
                  name: note.storekeeper.trim().isNotEmpty ? note.storekeeper : '—',
                  isSigned: note.storekeeper.trim().isNotEmpty,
                  canSign: canSign && note.storekeeper.trim().isEmpty,
                  onSign: (name) => cubit.kyXacNhan(storekeeper: name),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSignatureBox(
                  context: context,
                  role: 'Kế toán trưởng',
                  name: note.chiefAccountant.trim().isNotEmpty ? note.chiefAccountant : '—',
                  isSigned: note.chiefAccountant.trim().isNotEmpty,
                  canSign: canSign && note.chiefAccountant.trim().isEmpty,
                  onSign: (name) => cubit.kyXacNhan(chiefAccountant: name),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureBox({
    required BuildContext context,
    required String role,
    required String name,
    required bool isSigned,
    required bool canSign,
    void Function(String name)? onSign,
    String? suggestedName,
    String? noteSubtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSigned ? AppColors.statusApprovedBg.withValues(alpha: 0.3) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSigned ? AppColors.statusApprovedBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            role,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          const Text(
            '(Ký, ghi rõ họ tên)',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
            ),
          ),
          if (noteSubtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              noteSubtitle,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          if (isSigned) ...[
            const Icon(Icons.check_circle, size: 18, color: AppColors.statusApprovedText),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
          ] else if (canSign && onSign != null) ...[
            FilledButton.icon(
              onPressed: () => _showSignDialog(
                context,
                role,
                onSign,
                suggestedName: suggestedName,
              ),
              icon: const Icon(Icons.draw, size: 14),
              label: const Text('Ký xác nhận', style: TextStyle(fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentNavy,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              name == '—' ? 'Chưa ký' : name,
              style: const TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _showSignDialog(
    BuildContext context,
    String role,
    void Function(String) onSign, {
    String? suggestedName,
  }) {
    final controller = TextEditingController(text: suggestedName ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Ký xác nhận: $role'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Họ và tên người ký',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                onSign(val);
                Navigator.of(dialogCtx).pop();
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // HELPER WIDGETS
  // ==========================================================================
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    bool highlightValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: highlightValue ? FontWeight.w600 : FontWeight.w500,
              color: highlightValue ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toString();
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
