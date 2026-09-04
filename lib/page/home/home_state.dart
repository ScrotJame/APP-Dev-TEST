part of 'home_cubit.dart';

/// ---------------------------------------------------------------------------
/// ENUM TRẠNG THÁI PHIẾU NHẬP KHO
/// ---------------------------------------------------------------------------
enum ReceiptStatus {
  all(
    label: 'Tất cả',
    bg: Colors.transparent,
    textColor: AppColors.textMain,
    borderColor: Colors.transparent,
  ),
  debt(
    label: 'Phiếu nợ',
    bg: AppColors.statusRejectedBg,
    textColor: AppColors.statusRejectedText,
    borderColor: AppColors.statusRejectedBorder,
  ),
  pending(
    label: 'Chờ duyệt',
    bg: AppColors.statusPendingBg,
    textColor: AppColors.statusPendingText,
    borderColor: AppColors.statusPendingBorder,
  ),
  approved(
    label: 'Hoàn thành',
    bg: AppColors.statusApprovedBg,
    textColor: AppColors.statusApprovedText,
    borderColor: AppColors.statusApprovedBorder,
  ),
  draft(
    label: 'Lưu nháp',
    bg: AppColors.statusDraftBg,
    textColor: AppColors.statusDraftText,
    borderColor: AppColors.statusDraftBorder,
  ),
  rejected(
    label: 'Từ chối',
    bg: AppColors.statusRejectedBg,
    textColor: AppColors.statusRejectedText,
    borderColor: AppColors.statusRejectedBorder,
  );

  final String label;
  final Color bg;
  final Color textColor;
  final Color borderColor;

  const ReceiptStatus({
    required this.label,
    required this.bg,
    required this.textColor,
    required this.borderColor,
  });
}

class HomeState extends Equatable {
  final LoadStatus loadStatus;
  final List<GoodsReceivedNoteModel> notes;
  final String searchQuery;
  final ReceiptStatus selectedStatus;
  final String errorMessage;

  const HomeState({
    this.loadStatus = LoadStatus.INITIAL,
    this.notes = const [],
    this.searchQuery = '',
    this.selectedStatus = ReceiptStatus.all,
    this.errorMessage = '',
  });

  // Lọc và sắp xếp theo ngày lập phiếu mới nhất
  List<GoodsReceivedNoteModel> get filteredNotes {
    final q = searchQuery.trim().toLowerCase();
    final list = notes.where((note) {
      if (selectedStatus != ReceiptStatus.all) {
        if (selectedStatus == ReceiptStatus.debt) {
          if (!note.isDebt) return false;
        } else {
          final s = note.status.toLowerCase();
          if (selectedStatus == ReceiptStatus.approved &&
              s != 'approved' &&
              s != 'hoàn thành' &&
              s.isNotEmpty) {
            return false;
          }
          if (selectedStatus == ReceiptStatus.pending &&
              s != 'pending' &&
              s != 'chờ duyệt') {
            return false;
          }
          if (selectedStatus == ReceiptStatus.draft &&
              s != 'draft' &&
              s != 'lưu nháp') {
            return false;
          }
          if (selectedStatus == ReceiptStatus.rejected &&
              s != 'rejected' &&
              s != 'từ chối') {
            return false;
          }
        }
      }

      if (q.isEmpty) return true;
      final matchesNumber = note.noteNumber.toLowerCase().contains(q);
      final matchesDeliverer = note.delivererName.toLowerCase().contains(q);
      final matchesWarehouse = note.warehouse.toLowerCase().contains(q);
      return matchesNumber || matchesDeliverer || matchesWarehouse;
    }).toList();

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  int get totalCount => notes.length;
  int get debtCount => notes.where((n) => n.isDebt).length;

  int getCountByStatus(ReceiptStatus status) {
    if (status == ReceiptStatus.all) return notes.length;
    if (status == ReceiptStatus.debt) return debtCount;
    return notes.where((n) {
      final s = n.status.toLowerCase();
      if (status == ReceiptStatus.approved) {
        return s == 'approved' || s == 'hoàn thành' || s.isEmpty;
      }
      if (status == ReceiptStatus.pending) {
        return s == 'pending' || s == 'chờ duyệt';
      }
      if (status == ReceiptStatus.draft) {
        return s == 'draft' || s == 'lưu nháp';
      }
      if (status == ReceiptStatus.rejected) {
        return s == 'rejected' || s == 'từ chối';
      }
      return false;
    }).length;
  }

  HomeState copyWith({
    LoadStatus? loadStatus,
    List<GoodsReceivedNoteModel>? notes,
    String? searchQuery,
    ReceiptStatus? selectedStatus,
    String? errorMessage,
  }) {
    return HomeState(
      loadStatus: loadStatus ?? this.loadStatus,
      notes: notes ?? this.notes,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        notes,
        searchQuery,
        selectedStatus,
        errorMessage,
      ];
}
