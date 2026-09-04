import 'package:flutter_test/flutter_test.dart';
import 'package:vimes_test/commons/enums.dart';
import 'package:vimes_test/models/document_model.dart';
import 'package:vimes_test/models/product_model.dart';
import 'package:vimes_test/models/user_model.dart';
import 'package:vimes_test/page/entry_note/entry_note_cubit.dart';
import 'package:vimes_test/repositories/document_repository.dart';
import 'package:vimes_test/repositories/grn_repositories.dart';
import 'package:vimes_test/repositories/product_repository.dart';
import 'package:vimes_test/repositories/user_session_repository.dart';

class MockDocumentRepository implements DocumentRepository {
  @override
  Future<List<String>> getDocumentTypes() async => ['Hóa đơn GTGT', 'Phiếu xuất kho'];

  @override
  Future<List<DocumentModel>> getDocumentsByType(String documentType) async => [
        DocumentModel(
          id: 'doc-1',
          documentType: documentType,
          documentNumber: 'HD-001',
          documentDate: DateTime(2026, 8, 1),
          issuingUnit: 'VIMES Hà Nội',
        ),
      ];

}

class MockUserSessionRepository implements UserSessionRepository {
  final UserModel? _mockUser;

  MockUserSessionRepository([this._mockUser]);

  @override
  Future<UserModel?> getCurrentUser() async {
    return _mockUser ??
        const UserModel(
          uid: 'test-user',
          displayName: 'Nguyen Van Test',
          email: 'test@vimes.vn',
          role: 'staff',
          department: 'Receiving',
          unit: 'Hà Nội',
          isActive: true,
        );
  }

}

void main() {
  group('EntryNoteCubit Tests', () {
    late EntryNoteCubit cubit;
    late InMemoryGRNRepository grnRepo;
    late InMemoryProductRepository productRepo;
    late MockDocumentRepository docRepo;
    late MockUserSessionRepository sessionRepo;

    final testProducts = [
      const ProductModel(
        id: 'p1',
        itemDescription: 'Paracetamol 500mg',
        itemCode: 'VT-PARA-500',
        unit: 'Hộp',
        defaultUnitPrice: 45000,
      ),
      const ProductModel(
        id: 'p2',
        itemDescription: 'Bơm kim tiêm 5ml',
        itemCode: 'VT-BKT-05ML',
        unit: 'Hộp',
        defaultUnitPrice: 125000,
      ),
    ];

    setUp(() {
      grnRepo = InMemoryGRNRepository();
      productRepo = InMemoryProductRepository(testProducts);
      docRepo = MockDocumentRepository();
      sessionRepo = MockUserSessionRepository();

      cubit = EntryNoteCubit(
        goodsReceivedRepository: grnRepo,
        userSessionRepository: sessionRepo,
        documentRepository: docRepo,
        productRepository: productRepo,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state has 1 empty item row and step 0', () {
      expect(cubit.state.currentStep, 0);
      expect(cubit.state.items.length, 1);
      expect(cubit.state.items.first.stt, 1);
      expect(cubit.state.items.first.itemDescription, '');
    });

    test('Navigation between step 0 and step 1', () {
      expect(cubit.state.currentStep, 0);
      cubit.nextStep();
      expect(cubit.state.currentStep, 1);
      cubit.previousStep();
      expect(cubit.state.currentStep, 0);
      cubit.setStep(1);
      expect(cubit.state.currentStep, 1);
    });

    test('Auto-fill when typing exact Product Name', () async {
      await cubit.initNewNote();
      cubit.updateItemDescription(0, 'Paracetamol 500mg');

      final item = cubit.state.items.first;
      expect(item.itemDescription, 'Paracetamol 500mg');
      expect(item.itemCode, 'VT-PARA-500');
      expect(item.unit, 'Hộp');
      expect(item.unitPrice, 45000);
    });

    test('Auto-fill when typing exact Product Code', () async {
      await cubit.initNewNote();
      cubit.updateItemCode(0, 'VT-BKT-05ML');

      final item = cubit.state.items.first;
      expect(item.itemCode, 'VT-BKT-05ML');
      expect(item.itemDescription, 'Bơm kim tiêm 5ml');
      expect(item.unit, 'Hộp');
      expect(item.unitPrice, 125000);
    });

    test('Calculation of totalPrice and totalAmount', () async {
      await cubit.initNewNote();
      cubit.selectProduct(0, testProducts[0]); // Paracetamol: 45000
      cubit.updateItem(0, (d) => d.copyWith(actualQuantity: 10)); // 10 * 45000 = 450000

      expect(cubit.state.items.first.totalPrice, 450000);
      expect(cubit.state.totalAmount, 450000);

      // Add second item
      cubit.addItem();
      cubit.selectProduct(1, testProducts[1]); // Bơm kim tiêm: 125000
      cubit.updateItem(1, (d) => d.copyWith(actualQuantity: 2)); // 2 * 125000 = 250000

      expect(cubit.state.items[1].totalPrice, 250000);
      expect(cubit.state.totalAmount, 700000);
      expect(cubit.state.totalAmountInWords, 'Bảy trăm nghìn đồng');
    });

    test('Removing item reorders STT and never leaves list empty', () async {
      await cubit.initNewNote();
      cubit.addItem(); // Now 2 items (stt 1, 2)
      expect(cubit.state.items.length, 2);

      cubit.removeItem(0);
      expect(cubit.state.items.length, 1);
      expect(cubit.state.items.first.stt, 1);

      cubit.removeItem(0);
      expect(cubit.state.items.length, 1);
      expect(cubit.state.items.first.stt, 1);
    });

    test('Debt management: toggleDebt, setDebtType and calculations', () async {
      await cubit.initNewNote();
      cubit.selectProduct(0, testProducts[0]); // 45000
      cubit.updateItem(0, (d) => d.copyWith(actualQuantity: 10)); // Total: 450000

      // Default: no debt
      expect(cubit.state.isDebt, false);
      expect(cubit.state.debtAmount, 0.0);
      expect(cubit.state.actualPaidAmount, 450000.0);

      // Toggle debt ON -> default 'all'
      cubit.toggleDebt(true);
      expect(cubit.state.isDebt, true);
      expect(cubit.state.debtType, 'all');
      expect(cubit.state.debtAmount, 450000.0);
      expect(cubit.state.actualPaidAmount, 0.0);

      // Set debt type 'partial' and paidAmount = 200000
      cubit.setDebtType('partial');
      cubit.setPaidAmount(200000);
      expect(cubit.state.debtType, 'partial');
      expect(cubit.state.paidAmount, 200000.0);
      expect(cubit.state.actualPaidAmount, 200000.0);
      expect(cubit.state.debtAmount, 250000.0); // 450000 - 200000 = 250000

      // Validation fails if paidAmount > totalAmount
      cubit.setPaidAmount(500000);
      final error = cubit.validate();
      expect(error, contains('không được lớn hơn'));

      // Valid paidAmount
      cubit.setPaidAmount(100000);
      expect(cubit.validate(), isNull);
    });

    test('Saving note correctly writes debt information', () async {
      await cubit.initNewNote();
      cubit.updateHeader((p) => p.copyWith(
            deliveryPerson: 'Shipper A',
            storekeeper: 'Thu Kho B',
          ));
      cubit.selectProduct(0, testProducts[0]);
      cubit.updateItem(0, (d) => d.copyWith(actualQuantity: 2)); // Total: 90000

      cubit.toggleDebt(true);
      cubit.setDebtType('partial');
      cubit.setPaidAmount(30000);

      await cubit.saveNote();
      expect(cubit.state.loadStatus, LoadStatus.SUCCESS);

      final savedNote = await grnRepo.getNoteDetail(cubit.state.note.id);
      expect(savedNote, isNotNull);
      expect(savedNote!.isDebt, true);
      expect(savedNote.debtType, 'partial');
      expect(savedNote.paidAmount, 30000.0);
      expect(savedNote.debtAmount, 60000.0);
    });

    test('Saving draft note sets status to draft without strict validation', () async {
      await cubit.initNewNote();
      // Even without signatures and without items filled, draft can be saved
      await cubit.saveDraft();
      expect(cubit.state.loadStatus, LoadStatus.SUCCESS);

      final savedNote = await grnRepo.getNoteDetail(cubit.state.note.id);
      expect(savedNote, isNotNull);
      expect(savedNote!.status, 'draft');
    });

    test('Saving draft fails if note number is empty', () async {
      await cubit.initNewNote();
      cubit.updateHeader((p) => p.copyWith(noteNumber: ''));
      await cubit.luuNhap();
      expect(cubit.state.loadStatus, LoadStatus.FAILURE);
      expect(cubit.state.msg, contains('Số phiếu không được để trống'));
    });
  });
}
