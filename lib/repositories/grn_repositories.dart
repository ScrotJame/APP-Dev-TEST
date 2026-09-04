
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vimes_test/models/GRN_model.dart';
import 'package:vimes_test/models/supplies_model.dart';
import 'package:vimes_test/utils/slip_note_utils.dart';

abstract class GRNRepository {

  Future<void> saveGRN({
    required GoodsReceivedNoteModel note,
    required List<SuppliesModel> items,
    required double totalAmount,
    required String totalAmountInWords,
  });

  Future<void> saveGoodsReceived({
    required GoodsReceivedNoteModel note,
    required List<SuppliesModel> items,
    required double totalAmount,
    required String totalAmountInWords,
  }) => saveGRN(
    note: note,
    items: items,
    totalAmount: totalAmount,
    totalAmountInWords: totalAmountInWords,
  );

  Future<String> generateNoteNumber({
    required String unit,
    required String department,
  });

  Future<GoodsReceivedNoteModel?> getNoteDetail(String noteId);

  Future<List<SuppliesModel>> getItemsList(String noteId);

  Future<List<GoodsReceivedNoteModel>> getAllNotes();

  Stream<List<GoodsReceivedNoteModel>> watchAllNotes();

  Future<void> updateSignatures({
    required String noteId,
    String? deliveryPerson,
    String? storekeeper,
    String? chiefAccountant,
    required String status,
  });
}

typedef GoodsReceivedRepository = GRNRepository;

class FirestoreGRNRepository implements GRNRepository {
  final FirebaseFirestore firestore;

  FirestoreGRNRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notesCollection =>
      firestore.collection('phieu_nhap_kho');

  @override
  Future<void> saveGRN({
    required GoodsReceivedNoteModel note,
    required List<SuppliesModel> items,
    required double totalAmount,
    required String totalAmountInWords,
  }) async {
    final batch = firestore.batch();

    final noteRef = _notesCollection.doc(note.id);
    batch.set(
      noteRef,
      note.toMap(
        totalAmount: totalAmount,
        totalAmountInWords: totalAmountInWords,
        itemCount: items.length,
      ),
    );

    final itemsCollection = noteRef.collection('chi_tiet');
    for (final item in items) {
      final itemRef = itemsCollection.doc(item.id);
      batch.set(itemRef, item.toMap());
    }

    await batch.commit();
  }

  @override
  Future<void> saveGoodsReceived({
    required GoodsReceivedNoteModel note,
    required List<SuppliesModel> items,
    required double totalAmount,
    required String totalAmountInWords,
  }) => saveGRN(
    note: note,
    items: items,
    totalAmount: totalAmount,
    totalAmountInWords: totalAmountInWords,
  );

  @override
  Future<String> generateNoteNumber({
    required String unit,
    required String department,
  }) async {
    final year = DateTime.now().year;
    final rng = Random();

    for (var i = 0; i < 10; i++) {
      final suffix = SlipNoteUtils.generateSuffix5(rng);
      final noteNumber = SlipNoteUtils.generateNoteNumber(
        unit: unit,
        department: department,
        year: year,
        suffix5: suffix,
      );

      final existing = await _notesCollection
          .where('noteNumber', isEqualTo: noteNumber)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        final legacyExisting = await _notesCollection
            .where('soPhieu', isEqualTo: noteNumber)
            .limit(1)
            .get();
        if (legacyExisting.docs.isEmpty) return noteNumber;
      }
    }

    return SlipNoteUtils.generateNoteNumber(
      unit: unit,
      department: department,
      year: year,
      suffix5: DateTime.now().millisecondsSinceEpoch.toString().substring(8),
    );
  }

  @override
  Future<GoodsReceivedNoteModel?> getNoteDetail(String noteId) async {
    final doc = await _notesCollection.doc(noteId).get();
    if (!doc.exists || doc.data() == null) return null;
    return GoodsReceivedNoteModel.fromMap(doc.id, doc.data()!);
  }

  @override
  Future<List<SuppliesModel>> getItemsList(String noteId) async {
    final snapshot = await _notesCollection
        .doc(noteId)
        .collection('chi_tiet')
        .orderBy('stt')
        .get();
    return snapshot.docs
        .map((doc) => SuppliesModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<List<GoodsReceivedNoteModel>> getAllNotes() async {
    try {
      final snapshot = await _notesCollection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => GoodsReceivedNoteModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      final snapshot = await _notesCollection.get();
      final list = snapshot.docs
          .map((doc) => GoodsReceivedNoteModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
  }

  @override
  Stream<List<GoodsReceivedNoteModel>> watchAllNotes() {
    return _notesCollection.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => GoodsReceivedNoteModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }


  @override
  Future<void> updateSignatures({
    required String noteId,
    String? deliveryPerson,
    String? storekeeper,
    String? chiefAccountant,
    required String status,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (deliveryPerson != null) data['deliveryPerson'] = deliveryPerson;
    if (storekeeper != null) data['storekeeper'] = storekeeper;
    if (chiefAccountant != null) data['chiefAccountant'] = chiefAccountant;
    await _notesCollection.doc(noteId).update(data);
  }
}

class InMemoryGRNRepository implements GRNRepository {
  final Map<String, GoodsReceivedNoteModel> _notes = {};
  final Map<String, List<SuppliesModel>> _items = {};
  final StreamController<List<GoodsReceivedNoteModel>> _notesStreamController =
      StreamController<List<GoodsReceivedNoteModel>>.broadcast();

  void _notifyStream() {
    final list = _notes.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    if (!_notesStreamController.isClosed) {
      _notesStreamController.add(list);
    }
  }

  void dispose() {
    _notesStreamController.close();
  }

  @override
  Stream<List<GoodsReceivedNoteModel>> watchAllNotes() async* {
    final list = _notes.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    yield list;
    yield* _notesStreamController.stream;
  }


  @override
  Future<void> saveGRN({
    required GoodsReceivedNoteModel note,
    required List<SuppliesModel> items,
    required double totalAmount,
    required String totalAmountInWords,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _notes[note.id] = note.copyWith(
      totalAmount: totalAmount,
      totalAmountInWords: totalAmountInWords,
      itemCount: items.length,
    );
    _items[note.id] = List.from(items);
    _notifyStream();
  }

  @override
  Future<void> saveGoodsReceived({
    required GoodsReceivedNoteModel note,
    required List<SuppliesModel> items,
    required double totalAmount,
    required String totalAmountInWords,
  }) => saveGRN(
    note: note,
    items: items,
    totalAmount: totalAmount,
    totalAmountInWords: totalAmountInWords,
  );

  @override
  Future<String> generateNoteNumber({
    required String unit,
    required String department,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final suffix = SlipNoteUtils.generateSuffix5();
    return SlipNoteUtils.generateNoteNumber(
      unit: unit,
      department: department,
      year: DateTime.now().year,
      suffix5: suffix,
    );
  }

  @override
  Future<GoodsReceivedNoteModel?> getNoteDetail(String noteId) async {
    return _notes[noteId];
  }

  @override
  Future<List<SuppliesModel>> getItemsList(String noteId) async {
    return _items[noteId] ?? [];
  }

  @override
  Future<List<GoodsReceivedNoteModel>> getAllNotes() async {
    final list = _notes.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }


  @override
  Future<void> updateSignatures({
    required String noteId,
    String? deliveryPerson,
    String? storekeeper,
    String? chiefAccountant,
    required String status,
  }) async {
    if (_notes.containsKey(noteId)) {
      final existing = _notes[noteId]!;
      _notes[noteId] = existing.copyWith(
        deliveryPerson: deliveryPerson ?? existing.deliveryPerson,
        storekeeper: storekeeper ?? existing.storekeeper,
        chiefAccountant: chiefAccountant ?? existing.chiefAccountant,
        status: status,
      );
      _notifyStream();
    }
  }
}