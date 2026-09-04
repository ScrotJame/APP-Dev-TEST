import 'package:equatable/equatable.dart';

// Model chi tiết vật tư phiếu nhập kho
class SuppliesModel extends Equatable {
  final String id;
  final int stt;
  final String itemDescription;
  final String itemCode;
  final String unit;
  final double documentQuantity;
  final double actualQuantity;
  final double unitPrice;

  const SuppliesModel({
    required this.id,
    required this.stt,
    this.itemDescription = '',
    this.itemCode = '',
    this.unit = '',
    this.documentQuantity = 0,
    this.actualQuantity = 0,
    this.unitPrice = 0,
  });

  double get totalPrice => actualQuantity * unitPrice;

  // Backward compatibility getter
  double get thanhTien => totalPrice;
  String get tenNhanHieuQuyCach => itemDescription;
  String get maSo => itemCode;
  String get donViTinh => unit;
  double get soLuongTheoDocument => documentQuantity;
  double get soLuongThucNhap => actualQuantity;
  double get donGia => unitPrice;

  SuppliesModel copyWith({
    int? stt,
    String? itemDescription,
    String? itemCode,
    String? unit,
    double? documentQuantity,
    double? actualQuantity,
    double? unitPrice,
  }) {
    return SuppliesModel(
      id: id,
      stt: stt ?? this.stt,
      itemDescription: itemDescription ?? this.itemDescription,
      itemCode: itemCode ?? this.itemCode,
      unit: unit ?? this.unit,
      documentQuantity: documentQuantity ?? this.documentQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stt': stt,
      'itemDescription': itemDescription,
      'itemCode': itemCode,
      'unit': unit,
      'documentQuantity': documentQuantity,
      'actualQuantity': actualQuantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory SuppliesModel.fromMap(String id, Map<String, dynamic> map) {
    return SuppliesModel(
      id: id,
      stt: (map['stt'] ?? 0) as int,
      itemDescription: (map['itemDescription'] ?? map['tenNhanHieuQuyCach'] ?? '') as String,
      itemCode: (map['itemCode'] ?? map['maSo'] ?? '') as String,
      unit: (map['unit'] ?? map['donViTinh'] ?? '') as String,
      documentQuantity:
          (map['documentQuantity'] ?? map['soLuongTheoDocument'] ?? 0).toDouble(),
      actualQuantity:
          (map['actualQuantity'] ?? map['soLuongThucNhap'] ?? 0).toDouble(),
      unitPrice: (map['unitPrice'] ?? map['donGia'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    stt,
    itemDescription,
    itemCode,
    unit,
    documentQuantity,
    actualQuantity,
    unitPrice,
  ];
}

typedef SupplyItem = SuppliesModel;
typedef ChiTietVatTu = SuppliesModel;