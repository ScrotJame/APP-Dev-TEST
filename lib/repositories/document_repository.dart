import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vimes_test/models/document_model.dart';

abstract class DocumentRepository { 

  Future<List<String>> getDocumentTypes();
  Future<List<DocumentModel>> getDocumentsByType(String documentType);

}

class FirestoreDocumentRepository implements DocumentRepository {
  final FirebaseFirestore firestore;

  FirestoreDocumentRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('chung_tu');

  @override
  Future<List<String>> getDocumentTypes() async {
    final snapshot = await _col.get();
    final typeSet = <String>{};
    for (final doc in snapshot.docs) {
      final type = (doc.data()['documentType'] ?? '') as String;
      if (type.isNotEmpty) typeSet.add(type);
    }
    final list = typeSet.toList()..sort();
    return list;
  }

  @override
  Future<List<DocumentModel>> getDocumentsByType(
    String documentType,
  ) async {
    final snapshot = await _col
        .where('documentType', isEqualTo: documentType)
        .orderBy('documentNumber')
        .get();
    return snapshot.docs
        .map((doc) => DocumentModel.fromMap(doc.id, doc.data()))
        .toList();
  }

}
