import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vimes_test/models/product_model.dart';

abstract class ProductRepository {

  Future<List<ProductModel>> getProducts();

  Future<ProductModel?> findByName(String name);

  Future<ProductModel?> findByCode(String code);

}
class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore firestore;

  FirestoreProductRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('danh_muc_vat_tu');
 
  //Mock data product
  static final List<ProductModel> defaultProducts = [
    const ProductModel(
      id: 'sp-01',
      itemDescription: 'Paracetamol 500mg (Hộp 10 vỉ x 10 viên)',
      itemCode: 'VT-PARA-500',
      unit: 'Hộp',
      defaultUnitPrice: 45000,
    ),
    const ProductModel(
      id: 'sp-02',
      itemDescription: 'Bơm kim tiêm vô trùng 5ml (Hộp 100 cái)',
      itemCode: 'VT-BKT-05ML',
      unit: 'Hộp',
      defaultUnitPrice: 125000,
    ),
    const ProductModel(
      id: 'sp-03',
      itemDescription: 'Bông y tế thấm nước Bạch Tuyết 500g',
      itemCode: 'VT-BONG-500G',
      unit: 'Gói',
      defaultUnitPrice: 68000,
    ),
    const ProductModel(
      id: 'sp-04',
      itemDescription: 'Găng tay y tế Nitrile không bột (Hộp 100 chiếc)',
      itemCode: 'VT-GANG-NITRILE',
      unit: 'Hộp',
      defaultUnitPrice: 95000,
    ),
    const ProductModel(
      id: 'sp-05',
      itemDescription: 'Nước muối sinh lý Natri Clorid 0.9% 500ml',
      itemCode: 'VT-NMSL-500ML',
      unit: 'Chai',
      defaultUnitPrice: 8500,
    ),
    const ProductModel(
      id: 'sp-06',
      itemDescription: 'Khẩu trang y tế kháng khuẩn 4 lớp (Hộp 50 chiếc)',
      itemCode: 'VT-KT-4L',
      unit: 'Hộp',
      defaultUnitPrice: 35000,
    ),
    const ProductModel(
      id: 'sp-07',
      itemDescription: 'Cồn y tế Ethanol 70 độ 500ml',
      itemCode: 'VT-CON-70-500',
      unit: 'Chai',
      defaultUnitPrice: 18000,
    ),
    const ProductModel(
      id: 'sp-08',
      itemDescription: 'Băng gạc tiệt trùng y tế 10cm x 10cm',
      itemCode: 'VT-GAC-10X10',
      unit: 'Gói',
      defaultUnitPrice: 22000,
    ),
    const ProductModel(
      id: 'sp-09',
      itemDescription: 'Máy đo huyết áp bắp tay điện tử Omron',
      itemCode: 'TB-HA-OMRON',
      unit: 'Bộ',
      defaultUnitPrice: 850000,
    ),
    const ProductModel(
      id: 'sp-10',
      itemDescription: 'Nhiệt kế hồng ngoại đo trán Microlife',
      itemCode: 'TB-NK-MICRO',
      unit: 'Cái',
      defaultUnitPrice: 620000,
    ),
  ];

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final snapshot = await _col.get();
      if (snapshot.docs.isEmpty) {
        return defaultProducts;
      }
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      return defaultProducts;
    }
  }

  @override
  Future<ProductModel?> findByName(String name) async {
    final list = await getProducts();
    final normalized = name.trim().toLowerCase();
    for (final p in list) {
      if (p.itemDescription.trim().toLowerCase() == normalized) return p;
    }
    return null;
  }

  @override
  Future<ProductModel?> findByCode(String code) async {
    final list = await getProducts();
    final normalized = code.trim().toLowerCase();
    for (final p in list) {
      if (p.itemCode.trim().toLowerCase() == normalized) return p;
    }
    return null;
  }

}

class InMemoryProductRepository implements ProductRepository {
  final List<ProductModel> _products;

  InMemoryProductRepository([List<ProductModel>? initialProducts])
      : _products = initialProducts ?? List.from(FirestoreProductRepository.defaultProducts);

  @override
  Future<List<ProductModel>> getProducts() async {
    return List.from(_products);
  }

  @override
  Future<ProductModel?> findByName(String name) async {
    final normalized = name.trim().toLowerCase();
    try {
      return _products.firstWhere(
        (p) => p.itemDescription.trim().toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ProductModel?> findByCode(String code) async {
    final normalized = code.trim().toLowerCase();
    try {
      return _products.firstWhere(
        (p) => p.itemCode.trim().toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

}
