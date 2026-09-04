part of 'entry_note_cubit.dart';

// State quản lý màn hình lập phiếu nhập kho (Goods Received Note State)
class EntryNoteState extends Equatable {
  final LoadStatus loadStatus;
  final GoodsReceivedNoteModel note;
  final List<SuppliesModel> items;
  final String msg;

  // Bước hiện tại trong quy trình lập phiếu (0: Thông tin chung, 1: Nhập chi tiết sản phẩm)
  final int currentStep;

  // Thông tin người dùng đăng nhập
  final UserModel? currentUser;

  // Thông tin chứng từ đính kèm
  final List<String> documentTypes;
  final LoadStatus loadDocumentStatus;
  final List<DocumentModel> documentsByType;
  final String? selectedDocumentType;
  final DocumentModel? selectedDocument;

  // Danh mục sản phẩm phục vụ tra cứu / tự động điền
  final List<ProductModel> productsCatalog;

  // Quản lý công nợ
  final bool isDebt;
  final String debtType; // 'all' (Nợ tất cả) | 'partial' (Nợ 1 phần)
  final double paidAmount; // Số tiền đã thanh toán / trả trước khi nợ 1 phần

  const EntryNoteState({
    this.loadStatus = LoadStatus.INITIAL,
    required this.note,
    this.items = const [],
    this.msg = '',
    this.currentStep = 0,
    this.currentUser,
    this.documentTypes = const [],
    this.loadDocumentStatus = LoadStatus.INITIAL,
    this.documentsByType = const [],
    this.selectedDocumentType,
    this.selectedDocument,
    this.productsCatalog = const [],
    this.isDebt = false,
    this.debtType = 'all',
    this.paidAmount = 0.0,
  });

  // Backward compatibility getters
  GoodsReceivedNoteModel get phieu => note;
  List<SuppliesModel> get chiTiet => items;
  UserModel? get userHienTai => currentUser;
  List<String> get danhSachLoaiDocument => documentTypes;
  List<DocumentModel> get danhSachDocumentTheoLoai => documentsByType;
  String? get loaiDocumentDangChon => selectedDocumentType;
  // ignore: non_constant_identifier_names
  DocumentModel? get DocumentDangChon => selectedDocument;
  DocumentModel? get documentDangChon => selectedDocument;
  int get buocHienTai => currentStep;
  List<ProductModel> get danhMucVatTu => productsCatalog;

  // Tính tổng tiền từ danh sách chi tiết vật tư
  double get totalAmount =>
      items.fold<double>(0, (sum, item) => sum + item.totalPrice);

  // Chuyển tổng tiền thành chữ tiếng Việt
  String get totalAmountInWords => CurrencyUtils.amountToWords(totalAmount);

  // Backward compatibility derived getters
  double get tongSoTien => totalAmount;
  String get tongSoTienBangChu => totalAmountInWords;

  // Tính số tiền còn nợ (derived value)
  double get debtAmount {
    if (!isDebt) return 0.0;
    if (debtType == 'all') return totalAmount;
    final remaining = totalAmount - paidAmount;
    return remaining < 0 ? 0.0 : remaining;
  }

  // Số tiền đã thanh toán thực tế (derived value)
  double get actualPaidAmount {
    if (!isDebt) return totalAmount;
    if (debtType == 'all') return 0.0;
    return paidAmount.clamp(0.0, totalAmount);
  }

  EntryNoteState copyWith({
    LoadStatus? loadStatus,
    GoodsReceivedNoteModel? note,
    List<SuppliesModel>? items,
    String? msg,
    int? currentStep,
    UserModel? currentUser,
    List<String>? documentTypes,
    LoadStatus? loadDocumentStatus,
    List<DocumentModel>? documentsByType,
    Object? selectedDocumentType = _sentinel,
    Object? selectedDocument = _sentinel,
    List<ProductModel>? productsCatalog,
    bool? isDebt,
    String? debtType,
    double? paidAmount,
    // Backward compatibility params
    GoodsReceivedNoteModel? phieu,
    List<SuppliesModel>? chiTiet,
    UserModel? userHienTai,
    List<String>? danhSachLoaiDocument,
    List<DocumentModel>? danhSachDocumentTheoLoai,
    Object? loaiDocumentDangChon = _sentinel,
    // ignore: non_constant_identifier_names
    Object? DocumentDangChon = _sentinel,
    int? buocHienTai,
    List<ProductModel>? danhMucVatTu,
  }) {
    final finalSelectedType = selectedDocumentType != _sentinel
        ? selectedDocumentType
        : loaiDocumentDangChon;
    final finalSelectedDoc = selectedDocument != _sentinel
        ? selectedDocument
        : DocumentDangChon;

    return EntryNoteState(
      loadStatus: loadStatus ?? this.loadStatus,
      note: note ?? phieu ?? this.note,
      items: items ?? chiTiet ?? this.items,
      msg: msg ?? this.msg,
      currentStep: currentStep ?? buocHienTai ?? this.currentStep,
      currentUser: currentUser ?? userHienTai ?? this.currentUser,
      documentTypes:
          documentTypes ?? danhSachLoaiDocument ?? this.documentTypes,
      loadDocumentStatus: loadDocumentStatus ?? this.loadDocumentStatus,
      documentsByType:
          documentsByType ?? danhSachDocumentTheoLoai ?? this.documentsByType,
      selectedDocumentType: finalSelectedType == _sentinel
          ? this.selectedDocumentType
          : finalSelectedType as String?,
      selectedDocument: finalSelectedDoc == _sentinel
          ? this.selectedDocument
          : finalSelectedDoc as DocumentModel?,
      productsCatalog:
          productsCatalog ?? danhMucVatTu ?? this.productsCatalog,
      isDebt: isDebt ?? this.isDebt,
      debtType: debtType ?? this.debtType,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    note,
    items,
    msg,
    currentStep,
    currentUser,
    documentTypes,
    loadDocumentStatus,
    documentsByType,
    selectedDocumentType,
    selectedDocument,
    productsCatalog,
    isDebt,
    debtType,
    paidAmount,
  ];
}

// Đối tượng đánh dấu không truyền giá trị mới
const _sentinel = Object();