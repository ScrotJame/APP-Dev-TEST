import 'package:flutter_test/flutter_test.dart';
import 'package:vimes_test/commons/enums.dart';
import 'package:vimes_test/models/GRN_model.dart';
import 'package:vimes_test/models/supplies_model.dart';
import 'package:vimes_test/page/entry_note_detail/entry_note_detail_cubit.dart';
import 'package:vimes_test/repositories/grn_repositories.dart';

void main() {
  group('EntryNoteDetailCubit Tests', () {
    late InMemoryGRNRepository grnRepo;

    setUp(() {
      grnRepo = InMemoryGRNRepository();
    });

    test('Trạng thái khởi tạo chính xác khi không có initialNote', () {
      final cubit = EntryNoteDetailCubit(grnRepository: grnRepo);
      expect(cubit.state.loadStatus, LoadStatus.INITIAL);
      expect(cubit.state.note, isNull);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.totalAmount, 0);
      expect(cubit.state.itemsCount, 0);
      cubit.close();
    });

    test('Trạng thái khởi tạo SUCCESS khi truyền initialNote', () {
      final note = GoodsReceivedNoteModel(
        id: 'note-1',
        noteNumber: 'PNK-2026-0001',
        date: DateTime(2026, 9, 1),
        totalAmount: 1500000,
        totalAmountInWords: 'Một triệu năm trăm nghìn đồng',
      );
      final items = [
        const SuppliesModel(
          id: 'item-1',
          stt: 1,
          itemDescription: 'Bông y tế',
          actualQuantity: 10,
          documentQuantity: 10,
          unitPrice: 150000,
        ),
      ];
      final cubit = EntryNoteDetailCubit(
        grnRepository: grnRepo,
        initialNote: note,
        initialItems: items,
      );

      expect(cubit.state.loadStatus, LoadStatus.SUCCESS);
      expect(cubit.state.note?.noteNumber, 'PNK-2026-0001');
      expect(cubit.state.items.length, 1);
      expect(cubit.state.totalAmount, 1500000);
      expect(cubit.state.itemsCount, 1);
      expect(cubit.state.totalActualQuantity, 10);
      cubit.close();
    });

    test('Tải chi tiết phiếu thành công từ repository', () async {
      final note = GoodsReceivedNoteModel(
        id: 'note-repo-1',
        noteNumber: 'PNK-2026-9999',
        date: DateTime(2026, 9, 4),
        warehouse: 'Kho A',
      );
      final items = [
        const SuppliesModel(
          id: 'i1',
          stt: 1,
          itemDescription: 'Khẩu trang',
          actualQuantity: 50,
          documentQuantity: 50,
          unitPrice: 30000,
        ),
        const SuppliesModel(
          id: 'i2',
          stt: 2,
          itemDescription: 'Cồn 70 độ',
          actualQuantity: 20,
          documentQuantity: 20,
          unitPrice: 25000,
        ),
      ];

      await grnRepo.saveGRN(
        note: note,
        items: items,
        totalAmount: 2000000,
        totalAmountInWords: 'Hai triệu đồng',
      );

      final cubit = EntryNoteDetailCubit(grnRepository: grnRepo);
      await cubit.loadNoteDetail('note-repo-1');

      expect(cubit.state.loadStatus, LoadStatus.SUCCESS);
      expect(cubit.state.note?.noteNumber, 'PNK-2026-9999');
      expect(cubit.state.items.length, 2);
      expect(cubit.state.totalAmount, 50 * 30000 + 20 * 25000);
      expect(cubit.state.totalActualQuantity, 70);
      expect(cubit.state.itemsCount, 2);
      cubit.close();
    });

    test('Báo lỗi FAILURE khi không tìm thấy phiếu trong repository', () async {
      final cubit = EntryNoteDetailCubit(grnRepository: grnRepo);
      await cubit.loadNoteDetail('non-existing-id');

      expect(cubit.state.loadStatus, LoadStatus.FAILURE);
      expect(cubit.state.errorMessage, contains('Không tìm thấy'));
      cubit.close();
    });
  });
}
