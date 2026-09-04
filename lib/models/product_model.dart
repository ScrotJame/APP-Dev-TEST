import 'package:equatable/equatable.dart';

// Model danh mục vật tư / hàng hoá (Product / Supplies Catalog Item)
class ProductModel extends Equatable {
  final String id;
  final String itemDescription; // Tên / nhãn hiệu / hàng hoá
  final String itemCode; // Mã số
  final String unit; // Đơn vị tính
  final double defaultUnitPrice; // Đơn giá mặc định

  const ProductModel({
    required this.id,
    required this.itemDescription,
    required this.itemCode,
    required this.unit,
    this.defaultUnitPrice = 0,
  });

  // Backward compatibility getters
  String get name => itemDescription;
  String get tenVatTu => itemDescription;
  String get code => itemCode;
  String get maVatTu => itemCode;
  String get donViTinh => unit;
  double get donGiaMacDinh => defaultUnitPrice;

  ProductModel copyWith({
    String? itemDescription,
    String? itemCode,
    String? unit,
    double? defaultUnitPrice,
  }) {
    return ProductModel(
      id: id,
      itemDescription: itemDescription ?? this.itemDescription,
      itemCode: itemCode ?? this.itemCode,
      unit: unit ?? this.unit,
      defaultUnitPrice: defaultUnitPrice ?? this.defaultUnitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemDescription': itemDescription,
      'tenVatTu': itemDescription,
      'itemCode': itemCode,
      'maVatTu': itemCode,
      'unit': unit,
      'donViTinh': unit,
      'defaultUnitPrice': defaultUnitPrice,
      'donGiaMacDinh': defaultUnitPrice,
    };
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      itemDescription:
          (map['itemDescription'] ?? map['tenVatTu'] ?? map['name'] ?? '')
              as String,
      itemCode:
          (map['itemCode'] ?? map['maVatTu'] ?? map['code'] ?? '') as String,
      unit: (map['unit'] ?? map['donViTinh'] ?? '') as String,
      defaultUnitPrice: (map['defaultUnitPrice'] ??
              map['donGiaMacDinh'] ??
              map['unitPrice'] ??
              0)
          .toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemDescription,
    itemCode,
    unit,
    defaultUnitPrice,
  ];
}
