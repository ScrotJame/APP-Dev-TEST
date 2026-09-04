// Utility chuyển đổi số tiền sang chữ tiếng Việt
class CurrencyUtils {
  static const _digitWords = [
    'không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'
  ];

  // Chuyển đổi số tiền thành chuỗi chữ tiếng Việt
  static String amountToWords(num amount) {
    final integerAmount = amount.round();
    if (integerAmount == 0) return 'Không đồng';

    final isNegative = integerAmount < 0;
    var n = integerAmount.abs();

    final List<String> threeDigitGroups = [];
    while (n > 0) {
      threeDigitGroups.add((n % 1000).toString().padLeft(3, '0'));
      n ~/= 1000;
    }
    if (threeDigitGroups.isEmpty) threeDigitGroups.add('000');

    const unitScale = ['', ' nghìn', ' triệu', ' tỷ', ' nghìn tỷ', ' triệu tỷ'];

    final result = <String>[];
    for (var i = threeDigitGroups.length - 1; i >= 0; i--) {
      final group = threeDigitGroups[i];
      if (group == '000') continue;
      final groupText = _readThreeDigits(group, hasHigherMagnitude: i < threeDigitGroups.length - 1);
      result.add('$groupText${unitScale[i]}');
    }

    var text = result.join(' ').trim();
    text = text[0].toUpperCase() + text.substring(1);
    return '${isNegative ? 'Âm ' : ''}$text đồng';
  }

  // Backward compatibility alias
  static String soTienBangChu(num soTien) => amountToWords(soTien);

  // Đọc cụm ba chữ số thành lời
  static String _readThreeDigits(String group, {required bool hasHigherMagnitude}) {
    final hundreds = int.parse(group[0]);
    final tens = int.parse(group[1]);
    final units = int.parse(group[2]);

    final parts = <String>[];

    if (hundreds != 0 || hasHigherMagnitude) {
      parts.add('${_digitWords[hundreds]} trăm');
    }

    if (tens == 0) {
      if (units != 0 && (hundreds != 0 || hasHigherMagnitude)) parts.add('lẻ');
    } else if (tens == 1) {
      parts.add('mười');
    } else {
      parts.add('${_digitWords[tens]} mươi');
    }

    if (units == 1 && tens > 1) {
      parts.add('mốt');
    } else if (units == 5 && tens >= 1) {
      parts.add('lăm');
    } else if (units != 0) {
      parts.add(_digitWords[units]);
    }

    return parts.join(' ');
  }
}