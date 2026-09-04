import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vimes_test/models/GRN_model.dart';
import 'package:vimes_test/models/product_model.dart';
import 'package:vimes_test/models/supplies_model.dart';
import 'package:vimes_test/models/user_model.dart';
import 'package:vimes_test/utils/currency_ultis.dart';
import 'package:vimes_test/utils/slip_note_utils.dart';

void main() {
  group('SlipNoteUtils Tests', () {
    test('generateNoteNumber formats correct code with unit and department', () {
      final code = SlipNoteUtils.generateNoteNumber(
        unit: 'Hà Nội',
        department: 'Receiving',
        year: 2026,
        suffix5: '12345',
      );
      expect(code, 'HN-RC-26-12345');
    });

    test('getUnitCode fallback works for unknown city', () {
      final code = SlipNoteUtils.getUnitCode('Quảng Ninh');
      expect(code, 'QN');
    });

    test('generateSuffix5 generates 5 digits', () {
      final suffix = SlipNoteUtils.generateSuffix5(Random(42));
      expect(suffix.length, 5);
      expect(int.tryParse(suffix), isNotNull);
    });
  });

  group('CurrencyUtils Tests', () {
    test('amountToWords converts integers to Vietnamese text correctly', () {
      expect(CurrencyUtils.amountToWords(0), 'Không đồng');
      expect(CurrencyUtils.amountToWords(1500000), 'Một triệu năm trăm nghìn đồng');
    });
  });

  group('SuppliesModel Tests', () {
    test('totalPrice is computed as actualQuantity * unitPrice', () {
      const item = SuppliesModel(
        id: '1',
        stt: 1,
        itemDescription: 'Vật tư A',
        itemCode: 'VT-01',
        unit: 'cái',
        documentQuantity: 10,
        actualQuantity: 8,
        unitPrice: 25000,
      );
      expect(item.totalPrice, 200000);
      expect(item.thanhTien, 200000); // Compatibility
    });

    test('toMap and fromMap bidirectional mapping', () {
      const item = SuppliesModel(
        id: 'test-id',
        stt: 1,
        itemDescription: 'Xi măng',
        itemCode: 'XM-01',
        unit: 'bao',
        documentQuantity: 50,
        actualQuantity: 50,
        unitPrice: 90000,
      );

      final map = item.toMap();
      final restored = SuppliesModel.fromMap('test-id', map);
      expect(restored.itemDescription, item.itemDescription);
      expect(restored.actualQuantity, item.actualQuantity);
      expect(restored.unitPrice, item.unitPrice);
      expect(restored.totalPrice, 4500000);
    });
  });

  group('GoodsReceivedNoteModel Tests', () {
    test('empty factory sets initial values correctly', () {
      final note = GoodsReceivedNoteModel.empty(
        id: 'grn-1',
        noteNumber: 'HN-RC-26-00001',
      );
      expect(note.id, 'grn-1');
      expect(note.noteNumber, 'HN-RC-26-00001');
      expect(note.soPhieu, 'HN-RC-26-00001');
      expect(note.date, isNotNull);
    });
  });

  group('UserModel Tests', () {
    test('unit property and backward compatibility getter donVi', () {
      const user = UserModel(
        uid: 'user-1',
        displayName: 'Nguyen Van A',
        email: 'a@vimes.vn',
        role: 'staff',
        department: 'Receiving',
        unit: 'Hà Nội',
        isActive: true,
      );
      expect(user.unit, 'Hà Nội');
      expect(user.donVi, 'Hà Nội');
    });
  });

  group('ProductModel Tests', () {
    test('bidirectional mapping and backward compatibility getters', () {
      const product = ProductModel(
        id: 'p-01',
        itemDescription: 'Paracetamol 500mg',
        itemCode: 'VT-PARA-500',
        unit: 'Hộp',
        defaultUnitPrice: 45000,
      );

      expect(product.tenVatTu, 'Paracetamol 500mg');
      expect(product.maVatTu, 'VT-PARA-500');
      expect(product.donViTinh, 'Hộp');
      expect(product.donGiaMacDinh, 45000);

      final map = product.toMap();
      final restored = ProductModel.fromMap('p-01', map);
      expect(restored, product);
    });
  });
}
