import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';


// Model chứng từ kèm theo
class DocumentModel extends Equatable {
  final String id;
  final String documentType;
  final String documentNumber;
  final DateTime documentDate;
  final String issuingUnit;

  const DocumentModel({
    required this.id,
    required this.documentType,
    required this.documentNumber,
    required this.documentDate,
    required this.issuingUnit,
  });

  DocumentModel copyWith({
    String? documentType,
    String? documentNumber,
    DateTime? documentDate,
    String? issuingUnit,
  }) {
    return DocumentModel(
      id: id,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      documentDate: documentDate ?? this.documentDate,
      issuingUnit: issuingUnit ?? this.issuingUnit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentType': documentType,
      'documentNumber': documentNumber,
      'documentDate': Timestamp.fromDate(documentDate),
      'issuingUnit': issuingUnit,
    };
  }

  factory DocumentModel.fromMap(String id, Map<String, dynamic> map) {
    return DocumentModel(
      id: id,
      documentType: (map['documentType'] ?? '') as String,
      documentNumber: (map['documentNumber'] ?? '') as String,
      documentDate:
          (map['documentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      issuingUnit: (map['issuingUnit'] ?? '') as String,
    );
  }

  @override
  List<Object?> get props => [
    id,
    documentType,
    documentNumber,
    documentDate,
    issuingUnit,
  ];
}
