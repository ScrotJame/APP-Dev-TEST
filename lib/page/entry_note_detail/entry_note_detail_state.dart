part of 'entry_note_detail_cubit.dart';

// State quản lý màn hình xem chi tiết phiếu nhập kho
class EntryNoteDetailState extends Equatable {
  final LoadStatus loadStatus;
  final GoodsReceivedNoteModel? note;
  final List<SuppliesModel> items;
  final String errorMessage;

  const EntryNoteDetailState({
    this.loadStatus = LoadStatus.INITIAL,
    this.note,
    this.items = const [],
    this.errorMessage = '',
  });

  // Derived getters
  double get totalAmount {
    if (items.isNotEmpty) {
      return items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    }
    return note?.totalAmount ?? 0;
  }

  String get totalAmountInWords {
    if (note != null && note!.totalAmountInWords.isNotEmpty) {
      return note!.totalAmountInWords;
    }
    if (totalAmount > 0) {
      return CurrencyUtils.amountToWords(totalAmount.round());
    }
    return 'Không đồng';
  }

  double get totalActualQuantity =>
      items.fold<double>(0, (sum, item) => sum + item.actualQuantity);

  double get totalDocumentQuantity =>
      items.fold<double>(0, (sum, item) => sum + item.documentQuantity);

  int get itemsCount => items.length;

  EntryNoteDetailState copyWith({
    LoadStatus? loadStatus,
    GoodsReceivedNoteModel? note,
    List<SuppliesModel>? items,
    String? errorMessage,
  }) {
    return EntryNoteDetailState(
      loadStatus: loadStatus ?? this.loadStatus,
      note: note ?? this.note,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [loadStatus, note, items, errorMessage];
}
