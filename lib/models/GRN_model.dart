// ignore_for_file: file_names, non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// Model phiếu nhập kho (Goods Received Note)
class GoodsReceivedNoteModel extends Equatable {
  final String id;
  final String noteNumber;
  final DateTime date;
  final String unit;
  final String department;
  final String delivererName;
  final String contractNumber;
  final String documentType;
  final String documentNumber;
  final DateTime? documentDate;
  final String issuingUnit;
  final String warehouse;
  final String preparedBy;
  final String deliveryPerson;
  final String storekeeper;
  final String chiefAccountant;
  final String attachedOriginalDocument;
  final String createdBy;
  final double totalAmount;
  final String totalAmountInWords;
  final int itemCount;
  final String status;
  final bool isDebt;
  final String debtType;
  final double paidAmount;
  final double debtAmount;

  const GoodsReceivedNoteModel({
    required this.id,
    required this.noteNumber,
    required this.date,
    this.unit = '',
    this.department = '',
    this.delivererName = '',
    this.contractNumber = '',
    this.documentType = '',
    this.documentNumber = '',
    this.documentDate,
    this.issuingUnit = '',
    this.warehouse = '',
    this.preparedBy = '',
    this.deliveryPerson = '',
    this.storekeeper = '',
    this.chiefAccountant = '',
    this.attachedOriginalDocument = '',
    this.createdBy = '',
    this.totalAmount = 0,
    this.totalAmountInWords = '',
    this.itemCount = 0,
    this.status = 'approved',
    this.isDebt = false,
    this.debtType = '',
    this.paidAmount = 0,
    this.debtAmount = 0,
  });

  factory GoodsReceivedNoteModel.empty({
    required String id,
    required String noteNumber,
  }) {
    return GoodsReceivedNoteModel(
      id: id,
      noteNumber: noteNumber,
      date: DateTime.now(),
    );
  }

  // Backward compatibility factory
  factory GoodsReceivedNoteModel.rong({
    required String id,
    required String soPhieu,
  }) =>
      GoodsReceivedNoteModel.empty(id: id, noteNumber: soPhieu);

  // Backward compatibility getters
  String get soPhieu => noteNumber;
  DateTime get ngay => date;
  String get donVi => unit;
  String get boPhan => department;
  String get hoTenNguoiGiao => delivererName;
  String get theoSoHopDong => contractNumber;
  String get nhapTaiKho => warehouse;
  String get nguoiLapPhieu => preparedBy;
  String get nguoiGiaoHang => deliveryPerson;
  String get thuKho => storekeeper;
  String get ketToanTruong => chiefAccountant;
  String get DocumentGocKem => attachedOriginalDocument;
  String get documentGocKem => attachedOriginalDocument;

  /// Phiếu hoàn thành khi cả người giao hàng + thủ kho đã ký
  bool get isFullySigned =>
      deliveryPerson.trim().isNotEmpty && storekeeper.trim().isNotEmpty;

  GoodsReceivedNoteModel copyWith({
    String? noteNumber,
    DateTime? date,
    String? unit,
    String? department,
    String? delivererName,
    String? contractNumber,
    String? documentType,
    String? documentNumber,
    DateTime? documentDate,
    String? issuingUnit,
    String? warehouse,
    String? preparedBy,
    String? deliveryPerson,
    String? storekeeper,
    String? chiefAccountant,
    String? attachedOriginalDocument,
    String? createdBy,
    double? totalAmount,
    String? totalAmountInWords,
    int? itemCount,
    String? status,
    bool? isDebt,
    String? debtType,
    double? paidAmount,
    double? debtAmount,
    // Backward compatibility params
    String? soPhieu,
    DateTime? ngay,
    String? donVi,
    String? boPhan,
    String? hoTenNguoiGiao,
    String? theoSoHopDong,
    String? nhapTaiKho,
    String? nguoiLapPhieu,
    String? nguoiGiaoHang,
    String? thuKho,
    String? ketToanTruong,
    String? DocumentGocKem,
    double? tongSoTien,
    String? tongSoTienBangChu,
  }) {
    return GoodsReceivedNoteModel(
      id: id,
      noteNumber: noteNumber ?? soPhieu ?? this.noteNumber,
      date: date ?? ngay ?? this.date,
      unit: unit ?? donVi ?? this.unit,
      department: department ?? boPhan ?? this.department,
      delivererName: delivererName ?? hoTenNguoiGiao ?? this.delivererName,
      contractNumber: contractNumber ?? theoSoHopDong ?? this.contractNumber,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      documentDate: documentDate ?? this.documentDate,
      issuingUnit: issuingUnit ?? this.issuingUnit,
      warehouse: warehouse ?? nhapTaiKho ?? this.warehouse,
      preparedBy: preparedBy ?? nguoiLapPhieu ?? this.preparedBy,
      deliveryPerson: deliveryPerson ?? nguoiGiaoHang ?? this.deliveryPerson,
      storekeeper: storekeeper ?? thuKho ?? this.storekeeper,
      chiefAccountant: chiefAccountant ?? ketToanTruong ?? this.chiefAccountant,
      attachedOriginalDocument:
          attachedOriginalDocument ?? DocumentGocKem ?? this.attachedOriginalDocument,
      createdBy: createdBy ?? this.createdBy,
      totalAmount: totalAmount ?? tongSoTien ?? this.totalAmount,
      totalAmountInWords: totalAmountInWords ?? tongSoTienBangChu ?? this.totalAmountInWords,
      itemCount: itemCount ?? this.itemCount,
      status: status ?? this.status,
      isDebt: isDebt ?? this.isDebt,
      debtType: debtType ?? this.debtType,
      paidAmount: paidAmount ?? this.paidAmount,
      debtAmount: debtAmount ?? this.debtAmount,
    );
  }

  Map<String, dynamic> toMap({
    double? totalAmount,
    String? totalAmountInWords,
    int? itemCount,
    String? status,
    bool? isDebt,
    String? debtType,
    double? paidAmount,
    double? debtAmount,
  }) {
    final finalAmount = totalAmount ?? this.totalAmount;
    final finalAmountInWords = totalAmountInWords ?? this.totalAmountInWords;
    final finalItemCount = itemCount ?? this.itemCount;
    final finalStatus = status ?? this.status;
    final finalIsDebt = isDebt ?? this.isDebt;
    final finalDebtType = debtType ?? this.debtType;
    final finalPaidAmount = paidAmount ?? this.paidAmount;
    final finalDebtAmount = debtAmount ?? this.debtAmount;
    return {
      'noteNumber': noteNumber,
      'soPhieu': noteNumber,
      'date': Timestamp.fromDate(date),
      'ngay': Timestamp.fromDate(date),
      'unit': unit,
      'donVi': unit,
      'department': department,
      'boPhan': department,
      'delivererName': delivererName,
      'hoTenNguoiGiao': delivererName,
      'contractNumber': contractNumber,
      'theoSoHopDong': contractNumber,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'documentDate':
          documentDate != null ? Timestamp.fromDate(documentDate!) : null,
      'issuingUnit': issuingUnit,
      'warehouse': warehouse,
      'nhapTaiKho': warehouse,
      'preparedBy': preparedBy,
      'nguoiLapPhieu': preparedBy,
      'deliveryPerson': deliveryPerson,
      'nguoiGiaoHang': deliveryPerson,
      'storekeeper': storekeeper,
      'thuKho': storekeeper,
      'chiefAccountant': chiefAccountant,
      'ketToanTruong': chiefAccountant,
      'totalAmount': finalAmount,
      'tongSoTien': finalAmount,
      'totalAmountInWords': finalAmountInWords,
      'tongSoTienBangChu': finalAmountInWords,
      'itemCount': finalItemCount,
      'soLuongMatHang': finalItemCount,
      'status': finalStatus,
      'isDebt': finalIsDebt,
      'debtType': finalDebtType,
      'paidAmount': finalPaidAmount,
      'debtAmount': finalDebtAmount,
      'attachedOriginalDocument': attachedOriginalDocument,
      'DocumentGocKem': attachedOriginalDocument,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory GoodsReceivedNoteModel.fromMap(String id, Map<String, dynamic> map) {
    return GoodsReceivedNoteModel(
      id: id,
      noteNumber: (map['noteNumber'] ?? map['soPhieu'] ?? '') as String,
      date: (map['date'] as Timestamp?)?.toDate() ??
          (map['ngay'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      unit: (map['unit'] ?? map['donVi'] ?? '') as String,
      department: (map['department'] ?? map['boPhan'] ?? '') as String,
      delivererName:
          (map['delivererName'] ?? map['hoTenNguoiGiao'] ?? '') as String,
      contractNumber:
          (map['contractNumber'] ?? map['theoSoHopDong'] ?? '') as String,
      documentType: (map['documentType'] ?? '') as String,
      documentNumber: (map['documentNumber'] ?? '') as String,
      documentDate: (map['documentDate'] as Timestamp?)?.toDate(),
      issuingUnit: (map['issuingUnit'] ?? '') as String,
      warehouse: (map['warehouse'] ?? map['nhapTaiKho'] ?? '') as String,
      preparedBy: (map['preparedBy'] ?? map['nguoiLapPhieu'] ?? '') as String,
      deliveryPerson:
          (map['deliveryPerson'] ?? map['nguoiGiaoHang'] ?? '') as String,
      storekeeper: (map['storekeeper'] ?? map['thuKho'] ?? '') as String,
      chiefAccountant:
          (map['chiefAccountant'] ?? map['ketToanTruong'] ?? '') as String,
      attachedOriginalDocument: (map['attachedOriginalDocument'] ??
          map['DocumentGocKem'] ??
          map['documentGocKem'] ??
          '') as String,
      createdBy: (map['createdBy'] ?? '') as String,
      totalAmount: (map['totalAmount'] ?? map['tongSoTien'] ?? 0).toDouble(),
      totalAmountInWords: (map['totalAmountInWords'] ?? map['tongSoTienBangChu'] ?? '') as String,
      itemCount: (map['itemCount'] ?? map['soLuongMatHang'] ?? 0) as int,
      status: (map['status'] ?? 'approved') as String,
      isDebt: (map['isDebt'] ?? false) as bool,
      debtType: (map['debtType'] ?? '') as String,
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      debtAmount: (map['debtAmount'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    noteNumber,
    date,
    unit,
    department,
    delivererName,
    contractNumber,
    documentType,
    documentNumber,
    documentDate,
    issuingUnit,
    warehouse,
    preparedBy,
    deliveryPerson,
    storekeeper,
    chiefAccountant,
    attachedOriginalDocument,
    createdBy,
    totalAmount,
    totalAmountInWords,
    itemCount,
    status,
    isDebt,
    debtType,
    paidAmount,
    debtAmount,
  ];
}

typedef GRNKho = GoodsReceivedNoteModel;
typedef GoodsReceivedKho = GoodsReceivedNoteModel;
typedef GoodsReceivedNote = GoodsReceivedNoteModel;