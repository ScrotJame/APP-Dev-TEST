import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:vimes_test/commons/app_colors.dart';
import 'package:vimes_test/commons/enums.dart';
import 'package:vimes_test/models/GRN_model.dart';
import 'package:vimes_test/repositories/grn_repositories.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GRNRepository grnRepository;
  StreamSubscription<List<GoodsReceivedNoteModel>>? _notesSubscription;

  HomeCubit({required this.grnRepository}) : super(const HomeState());

  // Tải danh sách phiếu thực tế từ Firebase Firestore và bắt đầu lắng nghe real-time stream
  Future<void> fetchNotes() async {
    emit(state.copyWith(loadStatus: LoadStatus.LOADING));
    try {
      final notes = await grnRepository.getAllNotes();
      emit(state.copyWith(
        loadStatus: LoadStatus.SUCCESS,
        notes: notes,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LoadStatus.FAILURE,
        errorMessage: 'Lỗi khi tải danh sách phiếu từ Firestore: $e',
      ));
    }
    _subscribeRealtime();
  }

  // Đăng ký lắng nghe real-time stream từ repository
  void _subscribeRealtime() {
    _notesSubscription?.cancel();
    _notesSubscription = grnRepository.watchAllNotes().listen(
      (notes) {
        emit(state.copyWith(
          loadStatus: LoadStatus.SUCCESS,
          notes: notes,
        ));
      },
      onError: (e) {
        if (state.notes.isEmpty) {
          emit(state.copyWith(
            loadStatus: LoadStatus.FAILURE,
            errorMessage: 'Lỗi khi đồng bộ danh sách phiếu từ Firestore: $e',
          ));
        }
      },
    );
  }

  // Bắt đầu theo dõi real-time stream
  void startListeningRealtime() => _subscribeRealtime();

  // Cập nhật từ khóa tìm kiếm
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  // Chọn bộ lọc trạng thái
  void selectStatus(ReceiptStatus status) {
    emit(state.copyWith(selectedStatus: status));
  }

  // Làm mới danh sách phiếu
  Future<void> refresh() => fetchNotes();

  // Alias tương thích tiếng Việt
  Future<void> taiDanhSachPhieu() => fetchNotes();
  void theoDoiRealtime() => _subscribeRealtime();
  void timKiem(String tuKhoa) => updateSearchQuery(tuKhoa);
  void chonTrangThai(ReceiptStatus status) => selectStatus(status);

  @override
  Future<void> close() {
    _notesSubscription?.cancel();
    return super.close();
  }
}
