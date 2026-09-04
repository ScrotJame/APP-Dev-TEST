// ignore_for_file: non_constant_identifier_names

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:vimes_test/commons/enums.dart';
import 'package:vimes_test/models/GRN_model.dart';
import 'package:vimes_test/models/document_model.dart';
import 'package:vimes_test/models/product_model.dart';
import 'package:vimes_test/models/supplies_model.dart';
import 'package:vimes_test/models/user_model.dart';
import 'package:vimes_test/repositories/document_repository.dart';
import 'package:vimes_test/repositories/grn_repositories.dart';
import 'package:vimes_test/repositories/product_repository.dart';
import 'package:vimes_test/repositories/user_session_repository.dart';
import 'package:vimes_test/utils/currency_ultis.dart';

part 'entry_note_state.dart';

typedef GoodsReceivedCubit = EntryNoteCubit;
typedef GoodsReceivedState = EntryNoteState;

class EntryNoteCubit extends Cubit<EntryNoteState> {
  final GRNRepository goodsReceivedRepository;
  final UserSessionRepository userSessionRepository;
  final DocumentRepository documentRepository;
  final ProductRepository productRepository;
  final _uuid = const Uuid();

  EntryNoteCubit({
    required this.goodsReceivedRepository,
    required this.userSessionRepository,
    required this.documentRepository,
    ProductRepository? productRepository,
  })  : productRepository = productRepository ?? FirestoreProductRepository(),
        super(
          EntryNoteState(
            note: GoodsReceivedNoteModel.empty(
              id: const Uuid().v4(),
              noteNumber: '',
            ),
            items: [
              SuppliesModel(
                id: const Uuid().v4(),
                stt: 1,
              ),
            ],
          ),
        );

  // Khởi tạo thông tin phiếu mới, danh sách loại chứng từ và danh mục sản phẩm
  Future<void> initNewNote() async {
    emit(state.copyWith(loadStatus: LoadStatus.LOADING));
    try {
      final user = await userSessionRepository.getCurrentUser();

      final unit = user?.unit ?? '';
      final department = user?.department ?? '';
      final noteNumber = await goodsReceivedRepository.generateNoteNumber(
        unit: unit,
        department: department,
      );

      final types = await documentRepository.getDocumentTypes();
      final products = await productRepository.getProducts();

      final initialItems = state.items.isEmpty
          ? [SuppliesModel(id: _uuid.v4(), stt: 1)]
          : state.items;

      // Auto-fill người lập phiếu và tự động ký theo role
      final autoSign = _autoSignByRole(user);

      emit(
        state.copyWith(
          loadStatus: LoadStatus.INITIAL,
          currentUser: user,
          documentTypes: types,
          productsCatalog: products,
          items: initialItems,
          note: state.note.copyWith(
            noteNumber: noteNumber,
            date: DateTime.now(),
            unit: unit,
            department: department,
            preparedBy: user?.displayName ?? '',
            deliveryPerson: autoSign.deliveryPerson,
            storekeeper: autoSign.storekeeper,
            chiefAccountant: autoSign.chiefAccountant,
          ),
        ),
      );
    } catch (e) {
      emit(state.copyWith(loadStatus: LoadStatus.FAILURE, msg: '$e'));
    }
  }

  // Helper: ánh xạ role người dùng → tự động ký đúng ô
  ({String deliveryPerson, String storekeeper, String chiefAccountant})
      _autoSignByRole(UserModel? user) {
    final role = (user?.role ?? '').toLowerCase().trim();
    final name = user?.displayName ?? '';
    return (
      deliveryPerson: role == 'delivery' ? name : '',
      storekeeper: (role == 'warehouse_keeper' || role == 'warehouse_manager')
          ? name
          : '',
      chiefAccountant: role == 'chief_accountant' ? name : '',
    );
  }

  // Cập nhật chữ ký thủ công từ UI (Tab 3)
  void kyPhieu({
    String? deliveryPerson,
    String? storekeeper,
    String? chiefAccountant,
  }) {
    emit(
      state.copyWith(
        note: state.note.copyWith(
          deliveryPerson: deliveryPerson ?? state.note.deliveryPerson,
          storekeeper: storekeeper ?? state.note.storekeeper,
          chiefAccountant: chiefAccountant ?? state.note.chiefAccountant,
        ),
      ),
    );
  }

  // Điều hướng giữa các bước lập phiếu
  void setStep(int step) {
    emit(state.copyWith(currentStep: step));
  }

  void nextStep() {
    if (state.currentStep < 2) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  // Chọn loại chứng từ tham chiếu
  Future<void> selectDocumentType(String type) async {
    emit(state.copyWith(
      selectedDocumentType: type,
      selectedDocument: null,
      documentsByType: [],
      loadDocumentStatus: LoadStatus.LOADING,
      note: state.note.copyWith(
        documentType: type,
        documentNumber: '',
        documentDate: null,
        issuingUnit: '',
      ),
    ));
    try {
      final list = await documentRepository.getDocumentsByType(type);
      emit(state.copyWith(
        loadDocumentStatus: LoadStatus.INITIAL,
        documentsByType: list,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadDocumentStatus: LoadStatus.FAILURE,
        msg: '$e',
      ));
    }
  }

  // Chọn chứng từ cụ thể và tự động điền vào phiếu
  void selectDocument(DocumentModel document) {
    emit(state.copyWith(
      selectedDocument: document,
      note: state.note.copyWith(
        contractNumber: document.documentNumber,
        documentType: document.documentType,
        documentNumber: document.documentNumber,
        documentDate: document.documentDate,
        issuingUnit: document.issuingUnit,
      ),
    ));
  }

  // Cập nhật thông tin chung của phiếu
  void updateHeader(
    GoodsReceivedNoteModel Function(GoodsReceivedNoteModel) update,
  ) {
    emit(state.copyWith(note: update(state.note)));
  }

  // Thêm một dòng vật tư mới vào danh sách
  void addItem() {
    final newItem = SuppliesModel(
      id: _uuid.v4(),
      stt: state.items.length + 1,
    );
    emit(state.copyWith(items: [...state.items, newItem]));
  }

  // Xoá một dòng vật tư và đánh lại số thứ tự
  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    var list = [...state.items]..removeAt(index);
    if (list.isEmpty) {
      list = [SuppliesModel(id: _uuid.v4(), stt: 1)];
    } else {
      list = [
        for (var i = 0; i < list.length; i++) list[i].copyWith(stt: i + 1),
      ];
    }
    emit(state.copyWith(items: list));
  }

  // Cập nhật thông tin của một dòng vật tư
  void updateItem(
    int index,
    SuppliesModel Function(SuppliesModel) update,
  ) {
    if (index < 0 || index >= state.items.length) return;
    final list = [...state.items];
    list[index] = update(list[index]);
    emit(state.copyWith(items: list));
  }

  // Chọn sản phẩm từ danh mục để điền vào dòng
  void selectProduct(int index, ProductModel product) {
    if (index < 0 || index >= state.items.length) return;
    final list = [...state.items];
    list[index] = list[index].copyWith(
      itemDescription: product.itemDescription,
      itemCode: product.itemCode,
      unit: product.unit,
      unitPrice: product.defaultUnitPrice > 0
          ? product.defaultUnitPrice
          : list[index].unitPrice,
    );
    emit(state.copyWith(items: list));
  }

  // Cập nhật tên vật tư và tự động khớp mã, đơn vị tính, đơn giá nếu tìm thấy
  void updateItemDescription(int index, String description) {
    if (index < 0 || index >= state.items.length) return;
    final list = [...state.items];
    final current = list[index];

    final normalized = description.trim().toLowerCase();
    ProductModel? matched;
    for (final p in state.productsCatalog) {
      if (p.itemDescription.trim().toLowerCase() == normalized) {
        matched = p;
        break;
      }
    }

    if (matched != null) {
      list[index] = current.copyWith(
        itemDescription: description,
        itemCode: matched.itemCode,
        unit: matched.unit,
        unitPrice: matched.defaultUnitPrice > 0
            ? matched.defaultUnitPrice
            : current.unitPrice,
      );
    } else {
      list[index] = current.copyWith(itemDescription: description);
    }
    emit(state.copyWith(items: list));
  }

  // Cập nhật mã vật tư và tự động khớp tên, đơn vị tính, đơn giá nếu tìm thấy
  void updateItemCode(int index, String code) {
    if (index < 0 || index >= state.items.length) return;
    final list = [...state.items];
    final current = list[index];

    final normalized = code.trim().toLowerCase();
    ProductModel? matched;
    for (final p in state.productsCatalog) {
      if (p.itemCode.trim().toLowerCase() == normalized) {
        matched = p;
        break;
      }
    }

    if (matched != null) {
      list[index] = current.copyWith(
        itemCode: code,
        itemDescription: matched.itemDescription,
        unit: matched.unit,
        unitPrice: matched.defaultUnitPrice > 0
            ? matched.defaultUnitPrice
            : current.unitPrice,
      );
    } else {
      list[index] = current.copyWith(itemCode: code);
    }
    emit(state.copyWith(items: list));
  }

  // Bật / tắt ô tích ghi nợ tiền hàng
  void toggleDebt(bool isDebt) {
    emit(state.copyWith(
      isDebt: isDebt,
      debtType: isDebt ? state.debtType : 'all',
      paidAmount: isDebt ? state.paidAmount : 0.0,
    ));
  }

  // Chọn loại nợ: 'all' (Nợ tất cả) hoặc 'partial' (Nợ 1 phần)
  void setDebtType(String type) {
    if (type == 'all') {
      emit(state.copyWith(debtType: 'all', paidAmount: 0.0));
    } else {
      emit(state.copyWith(debtType: 'partial'));
    }
  }

  // Cập nhật số tiền đã trả trước / thanh toán (khi nợ 1 phần)
  void setPaidAmount(double amount) {
    final sanitized = amount < 0 ? 0.0 : amount;
    emit(state.copyWith(paidAmount: sanitized));
  }

  // Kiểm tra tính hợp lệ của dữ liệu phiếu nhập
  String? validate() {
    if (state.note.noteNumber.isEmpty) return 'Số phiếu không được để trống';
    if (state.items.isEmpty) return 'Phiếu phải có ít nhất 1 dòng vật tư';
    for (final item in state.items) {
      if (item.itemDescription.isEmpty && item.itemCode.isEmpty) {
        return 'Dòng ${item.stt}: vui lòng nhập tên hoặc mã vật tư';
      }
      if (item.actualQuantity <= 0) {
        return 'Dòng ${item.stt}: số lượng thực nhập phải lớn hơn 0';
      }
    }
    if (state.isDebt && state.debtType == 'partial') {
      if (state.paidAmount < 0) {
        return 'Số tiền đã thanh toán không được âm';
      }
      if (state.paidAmount > state.totalAmount) {
        return 'Số tiền đã thanh toán không được lớn hơn tổng giá trị phiếu';
      }
    }
    return null;
  }

  // Lưu phiếu nhập kho và danh sách chi tiết vật tư
  Future<void> saveNote() async {
    final error = validate();
    if (error != null) {
      emit(state.copyWith(loadStatus: LoadStatus.FAILURE, msg: error));
      return;
    }
    emit(state.copyWith(loadStatus: LoadStatus.SAVING));
    try {
      // Tự động tính trạng thái dựa trên chữ ký
      final status = state.note.isFullySigned ? 'approved' : 'pending';
      final noteToSave = state.note.copyWith(
        status: status,
        isDebt: state.isDebt,
        debtType: state.isDebt ? state.debtType : '',
        paidAmount: state.actualPaidAmount,
        debtAmount: state.debtAmount,
      );
      await goodsReceivedRepository.saveGoodsReceived(
        note: noteToSave,
        items: state.items,
        totalAmount: state.totalAmount,
        totalAmountInWords: state.totalAmountInWords,
      );
      emit(state.copyWith(
        loadStatus: LoadStatus.SUCCESS,
        note: noteToSave,
      ));
    } catch (e) {
      emit(state.copyWith(loadStatus: LoadStatus.FAILURE, msg: '$e'));
    }
  }

  // Lưu nháp phiếu nhập kho (trạng thái 'draft', không bắt buộc đủ chữ ký hay vật tư)
  Future<void> saveDraft() async {
    if (state.note.noteNumber.isEmpty) {
      emit(state.copyWith(
        loadStatus: LoadStatus.FAILURE,
        msg: 'Số phiếu không được để trống khi lưu nháp',
      ));
      return;
    }
    emit(state.copyWith(loadStatus: LoadStatus.SAVING));
    try {
      final noteToSave = state.note.copyWith(
        status: 'draft',
        isDebt: state.isDebt,
        debtType: state.isDebt ? state.debtType : '',
        paidAmount: state.actualPaidAmount,
        debtAmount: state.debtAmount,
      );
      await goodsReceivedRepository.saveGoodsReceived(
        note: noteToSave,
        items: state.items,
        totalAmount: state.totalAmount,
        totalAmountInWords: state.totalAmountInWords,
      );
      emit(state.copyWith(
        loadStatus: LoadStatus.SUCCESS,
        note: noteToSave,
      ));
    } catch (e) {
      emit(state.copyWith(loadStatus: LoadStatus.FAILURE, msg: '$e'));
    }
  }

  // Backward compatibility alias methods
  Future<void> khoiTaoPhieuMoi() => initNewNote();
  Future<void> chonLoaiDocument(String loai) => selectDocumentType(loai);
  void chonDocument(DocumentModel ct) => selectDocument(ct);
  void capNhatHeader(
    GoodsReceivedNoteModel Function(GoodsReceivedNoteModel) update,
  ) =>
      updateHeader(update);
  void themDong() => addItem();
  void xoaDong(int index) => removeItem(index);
  void capNhatDong(
    int index,
    SuppliesModel Function(SuppliesModel) update,
  ) =>
      updateItem(index, update);
  void chuyenBuoc(int step) => setStep(step);
  void buocTiepTheo() => nextStep();
  void buocTruoc() => previousStep();
  Future<void> luuPhieu() => saveNote();
  Future<void> luuNhap() => saveDraft();
  void batTatNo(bool isDebt) => toggleDebt(isDebt);
  void chonLoaiNo(String type) => setDebtType(type);
  void capNhatTienDaTra(double tien) => setPaidAmount(tien);
}