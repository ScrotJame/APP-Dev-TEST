import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vimes_test/commons/enums.dart';
import 'package:vimes_test/models/GRN_model.dart';
import 'package:vimes_test/models/supplies_model.dart';
import 'package:vimes_test/repositories/grn_repositories.dart';
import 'package:vimes_test/utils/currency_ultis.dart';

part 'entry_note_detail_state.dart';

class EntryNoteDetailCubit extends Cubit<EntryNoteDetailState> {
  final GRNRepository grnRepository;

  EntryNoteDetailCubit({
    required this.grnRepository,
    GoodsReceivedNoteModel? initialNote,
    List<SuppliesModel>? initialItems,
  }) : super(
          EntryNoteDetailState(
            note: initialNote,
            items: initialItems ?? const [],
            loadStatus: initialNote != null ? LoadStatus.SUCCESS : LoadStatus.INITIAL,
          ),
        );

  // Tải thông tin chi tiết phiếu nhập và danh sách vật tư kèm theo
  Future<void> loadNoteDetail(String noteId) async {
    emit(state.copyWith(loadStatus: LoadStatus.LOADING));
    try {
      final note = await grnRepository.getNoteDetail(noteId);
      final items = await grnRepository.getItemsList(noteId);

      if (note == null && state.note == null) {
        emit(state.copyWith(
          loadStatus: LoadStatus.FAILURE,
          errorMessage: 'Không tìm thấy thông tin phiếu nhập kho #$noteId',
        ));
        return;
      }

      emit(state.copyWith(
        loadStatus: LoadStatus.SUCCESS,
        note: note ?? state.note,
        items: items.isNotEmpty ? items : state.items,
      ));
    } catch (e) {
      if (state.note != null) {
        emit(state.copyWith(loadStatus: LoadStatus.SUCCESS));
      } else {
        emit(state.copyWith(
          loadStatus: LoadStatus.FAILURE,
          errorMessage: 'Lỗi khi tải chi tiết phiếu nhập kho: $e',
        ));
      }
    }
  }

  // Alias tương thích tiếng Việt
  Future<void> taiChiTietPhieu(String noteId) => loadNoteDetail(noteId);

  // Ký xác nhận phiếu (từ màn hình chi tiết): cập nhật Firestore + reload state
  Future<void> kyXacNhan({
    String? deliveryPerson,
    String? storekeeper,
    String? chiefAccountant,
  }) async {
    final note = state.note;
    if (note == null) return;

    final updatedNote = note.copyWith(
      deliveryPerson: deliveryPerson ?? note.deliveryPerson,
      storekeeper: storekeeper ?? note.storekeeper,
      chiefAccountant: chiefAccountant ?? note.chiefAccountant,
    );
    final newStatus = updatedNote.isFullySigned ? 'approved' : 'pending';

    emit(state.copyWith(loadStatus: LoadStatus.SAVING));
    try {
      await grnRepository.updateSignatures(
        noteId: note.id,
        deliveryPerson: deliveryPerson,
        storekeeper: storekeeper,
        chiefAccountant: chiefAccountant,
        status: newStatus,
      );
      emit(state.copyWith(
        loadStatus: LoadStatus.SUCCESS,
        note: updatedNote.copyWith(status: newStatus),
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LoadStatus.FAILURE,
        errorMessage: 'Lỗi khi cập nhật chữ ký: $e',
      ));
    }
  }
}
