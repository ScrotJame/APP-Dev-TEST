import 'dart:math';

class SlipNoteUtils {
  SlipNoteUtils._();

  static const Map<String, String> _unitMap = {
    'hà nội': 'HN',
    'ha noi': 'HN',
    'hồ chí minh': 'HCM',
    'ho chi minh': 'HCM',
    'tp. hcm': 'HCM',
    'tp.hcm': 'HCM',
    'đà nẵng': 'DN',
    'da nang': 'DN',
    'hải phòng': 'HP',
    'hai phong': 'HP',
    'cần thơ': 'CT',
    'can tho': 'CT',
    'biên hòa': 'BH',
    'bien hoa': 'BH',
  };

  static const Map<String, String> _departmentMap = {
    'receiving': 'RC',
    'storage': 'ST',
    'shipping': 'SP',
    'administrative': 'ADZ',
    'administrative zone': 'ADZ',
    'warehouse': 'ST',
  };

  static String getUnitCode(String unit) {
    final key = unit.toLowerCase().trim();
    if (_unitMap.containsKey(key)) return _unitMap[key]!;

    final words = unit.trim().split(RegExp(r'\s+'));
    return words
        .take(3)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
  }

  static String getDepartmentCode(String department) {
    final lower = department.toLowerCase().trim();
    for (final entry in _departmentMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    return department
        .trim()
        .substring(0, min(3, department.trim().length))
        .toUpperCase();
  }

  static String generateSuffix5([Random? random]) {
    final rng = random ?? Random();
    return List.generate(5, (_) => rng.nextInt(10).toString()).join();
  }

  static String generateNoteNumber({
    required String unit,
    required String department,
    required int year,
    required String suffix5,
  }) {
    final unitCode = getUnitCode(unit);
    final deptCode = getDepartmentCode(department);
    final year2Digits = (year % 100).toString().padLeft(2, '0');
    return '$unitCode-$deptCode-$year2Digits-$suffix5';
  }
}
