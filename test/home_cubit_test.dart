import 'package:flutter_test/flutter_test.dart';
import 'package:vimes_test/commons/enums.dart';
import 'package:vimes_test/models/GRN_model.dart';
import 'package:vimes_test/models/supplies_model.dart';
import 'package:vimes_test/page/home/home_cubit.dart';
import 'package:vimes_test/repositories/grn_repositories.dart';

void main() {
  group('HomeCubit Tests', () {
    late InMemoryGRNRepository grnRepo;

    setUp(() {
      grnRepo = InMemoryGRNRepository();
    });

    test('Trạng thái khởi tạo của HomeCubit là INITIAL và danh sách rỗng', () {
      final cubit = HomeCubit(grnRepository: grnRepo);
      expect(cubit.state.loadStatus, LoadStatus.INITIAL);
      expect(cubit.state.notes, isEmpty);
      expect(cubit.state.filteredNotes, isEmpty);
      expect(cubit.state.totalCount, 0);
      cubit.close();
    });

    test('Tải danh sách phiếu nhập kho từ repository thành công', () async {
      final note1 = GoodsReceivedNoteModel(
        id: 'n1',
        noteNumber: 'PNK-001',
        date: DateTime(2026, 9, 1),
        delivererName: 'Phan Hữu Dũng',
        warehouse: 'Kho A',
        status: 'approved',
      );
      final note2 = GoodsReceivedNoteModel(
        id: 'n2',
        noteNumber: 'PNK-002',
        date: DateTime(2026, 9, 2),
        delivererName: 'Thiết Bị Y Tế Á Châu',
        warehouse: 'Kho B',
        status: 'pending',
      );

      await grnRepo.saveGRN(
        note: note1,
        items: const [SuppliesModel(id: 'i1', stt: 1, actualQuantity: 5)],
        totalAmount: 1000000,
        totalAmountInWords: 'Một triệu đồng',
      );
      await grnRepo.saveGRN(
        note: note2,
        items: const [SuppliesModel(id: 'i2', stt: 1, actualQuantity: 10)],
        totalAmount: 2000000,
        totalAmountInWords: 'Hai triệu đồng',
      );

      final cubit = HomeCubit(grnRepository: grnRepo);
      await cubit.fetchNotes();

      expect(cubit.state.loadStatus, LoadStatus.SUCCESS);
      expect(cubit.state.totalCount, 2);
      expect(cubit.state.notes.length, 2);
      // Sắp xếp ngày mới nhất lên đầu
      expect(cubit.state.filteredNotes.first.noteNumber, 'PNK-002');
      cubit.close();
    });

    test('Tìm kiếm theo số phiếu và tên bên giao', () async {
      final note1 = GoodsReceivedNoteModel(
        id: 'n1',
        noteNumber: 'PNK-001',
        date: DateTime(2026, 9, 1),
        delivererName: 'Dược Hậu Giang',
        warehouse: 'Kho Chẵn',
      );
      final note2 = GoodsReceivedNoteModel(
        id: 'n2',
        noteNumber: 'PNK-002',
        date: DateTime(2026, 9, 2),
        delivererName: 'Thiết Bị Y Tế Á Châu',
        warehouse: 'Kho Lẻ',
      );

      await grnRepo.saveGRN(
        note: note1,
        items: const [],
        totalAmount: 100,
        totalAmountInWords: 'Một trăm',
      );
      await grnRepo.saveGRN(
        note: note2,
        items: const [],
        totalAmount: 200,
        totalAmountInWords: 'Hai trăm',
      );

      final cubit = HomeCubit(grnRepository: grnRepo);
      await cubit.fetchNotes();

      cubit.updateSearchQuery('Hậu Giang');
      expect(cubit.state.filteredNotes.length, 1);
      expect(cubit.state.filteredNotes.first.noteNumber, 'PNK-001');

      cubit.updateSearchQuery('002');
      expect(cubit.state.filteredNotes.length, 1);
      expect(cubit.state.filteredNotes.first.noteNumber, 'PNK-002');

      cubit.updateSearchQuery('Kho Lẻ');
      expect(cubit.state.filteredNotes.length, 1);

      cubit.updateSearchQuery('Không có');
      expect(cubit.state.filteredNotes, isEmpty);

      cubit.close();
    });

    test('Lọc danh sách theo trạng thái (ReceiptStatus)', () async {
      final note1 = GoodsReceivedNoteModel(
        id: 'n1',
        noteNumber: 'PNK-001',
        date: DateTime(2026, 9, 1),
        status: 'approved',
      );
      final note2 = GoodsReceivedNoteModel(
        id: 'n2',
        noteNumber: 'PNK-002',
        date: DateTime(2026, 9, 2),
        status: 'pending',
      );

      await grnRepo.saveGRN(
        note: note1,
        items: const [],
        totalAmount: 100,
        totalAmountInWords: 'Một trăm',
      );
      await grnRepo.saveGRN(
        note: note2,
        items: const [],
        totalAmount: 200,
        totalAmountInWords: 'Hai trăm',
      );

      final cubit = HomeCubit(grnRepository: grnRepo);
      await cubit.fetchNotes();

      cubit.selectStatus(ReceiptStatus.pending);
      expect(cubit.state.filteredNotes.length, 1);
      expect(cubit.state.filteredNotes.first.noteNumber, 'PNK-002');

      cubit.selectStatus(ReceiptStatus.approved);
      expect(cubit.state.filteredNotes.length, 1);
      expect(cubit.state.filteredNotes.first.noteNumber, 'PNK-001');

      cubit.selectStatus(ReceiptStatus.all);
      expect(cubit.state.filteredNotes.length, 2);

      cubit.close();
    });

    test('Lọc danh sách theo phiếu nợ (ReceiptStatus.debt) và đếm debtCount', () async {
      final note1 = GoodsReceivedNoteModel(
        id: 'n1',
        noteNumber: 'PNK-001',
        date: DateTime(2026, 9, 1),
        isDebt: false,
      );
      final note2 = GoodsReceivedNoteModel(
        id: 'n2',
        noteNumber: 'PNK-002',
        date: DateTime(2026, 9, 2),
        isDebt: true,
        debtType: 'all',
        debtAmount: 500000,
      );

      await grnRepo.saveGRN(
        note: note1,
        items: const [],
        totalAmount: 100,
        totalAmountInWords: 'Một trăm',
      );
      await grnRepo.saveGRN(
        note: note2,
        items: const [],
        totalAmount: 500000,
        totalAmountInWords: 'Năm trăm nghìn',
      );

      final cubit = HomeCubit(grnRepository: grnRepo);
      await cubit.fetchNotes();

      expect(cubit.state.debtCount, 1);
      expect(cubit.state.getCountByStatus(ReceiptStatus.debt), 1);

      cubit.selectStatus(ReceiptStatus.debt);
      expect(cubit.state.filteredNotes.length, 1);
      expect(cubit.state.filteredNotes.first.noteNumber, 'PNK-002');
      expect(cubit.state.filteredNotes.first.isDebt, true);

      cubit.close();
    });

    test('Cập nhật danh sách theo thời gian thực (Real-time Stream) khi có phiếu mới được lưu', () async {
      final cubit = HomeCubit(grnRepository: grnRepo);
      await cubit.fetchNotes();
      expect(cubit.state.totalCount, 0);

      // Lưu phiếu mới vào repository
      final newNote = GoodsReceivedNoteModel(
        id: 'realtime-1',
        noteNumber: 'PNK-REALTIME-001',
        date: DateTime(2026, 9, 4),
        delivererName: 'Nhà cung cấp Realtime',
        status: 'pending',
      );
      await grnRepo.saveGRN(
        note: newNote,
        items: const [],
        totalAmount: 1500000,
        totalAmountInWords: 'Một triệu năm trăm nghìn đồng',
      );

      // Đợi stream phát tín hiệu real-time
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.totalCount, 1);
      expect(cubit.state.notes.first.noteNumber, 'PNK-REALTIME-001');
      expect(cubit.state.loadStatus, LoadStatus.SUCCESS);

      cubit.close();
    });
  });
}
