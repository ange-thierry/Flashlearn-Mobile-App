import 'package:flutter/material.dart';
import '../models/models.dart';

const List<Map<String, dynamic>> defaultFields = [
  {
    'id': 'math',
    'name': 'Mathematics',
    'icon': '📐',
    'colorValue': 0xFF5C4E8A,
    'desc': 'Algebra, calculus & geometry',
    'gradientHex': ['2D1B69', '5C4E8A'],
  },
  {
    'id': 'science',
    'name': 'Science',
    'icon': '🔬',
    'colorValue': 0xFF1A6B4A,
    'desc': 'Physics, chemistry & biology',
    'gradientHex': ['0D3D2A', '1A6B4A'],
  },
  {
    'id': 'history',
    'name': 'History',
    'icon': '🏛',
    'colorValue': 0xFF8B3A1A,
    'desc': 'World events & civilizations',
    'gradientHex': ['4A1800', '8B3A1A'],
  },
  {
    'id': 'geography',
    'name': 'Geography',
    'icon': '🌍',
    'colorValue': 0xFF1A4F8B,
    'desc': 'Countries, capitals & landscapes',
    'gradientHex': ['0D2A50', '1A4F8B'],
  },
  {
    'id': 'literature',
    'name': 'Literature',
    'icon': '📖',
    'colorValue': 0xFF7A2352,
    'desc': 'Authors, genres & literary terms',
    'gradientHex': ['3D0F29', '7A2352'],
  },
  {
    'id': 'cs',
    'name': 'Computer Science',
    'icon': '💻',
    'colorValue': 0xFF2A5A1A,
    'desc': 'Algorithms & data structures',
    'gradientHex': ['122A09', '2A5A1A'],
  },
];

/// Per-field gradient cache for admin-created fields.
/// Populated by AppProvider when the Firestore admin_fields stream fires.
final Map<String, List<Color>> _adminGradientCache = {};

void setAdminFieldGradient(String fieldId, List<String> hex) {
  if (hex.length >= 2) {
    _adminGradientCache[fieldId] = [
      Color(int.parse('FF${hex[0]}', radix: 16)),
      Color(int.parse('FF${hex[1]}', radix: 16)),
    ];
  }
}

void removeAdminFieldGradient(String fieldId) {
  _adminGradientCache.remove(fieldId);
}

List<Color> fieldGradient(String fieldId) {
  final idx = defaultFields.indexWhere((x) => x['id'] == fieldId);
  if (idx != -1) {
    final hex = defaultFields[idx]['gradientHex'] as List;
    return [
      Color(int.parse('FF${hex[0]}', radix: 16)),
      Color(int.parse('FF${hex[1]}', radix: 16)),
    ];
  }
  // Admin-created field — use its registered gradient or a sensible default
  return _adminGradientCache[fieldId] ??
      [const Color(0xFF3730A3), const Color(0xFF5B5FEF)];
}

Color fieldColor(String fieldId) {
  final idx = defaultFields.indexWhere((x) => x['id'] == fieldId);
  if (idx != -1) return Color(defaultFields[idx]['colorValue'] as int);
  return _adminGradientCache[fieldId]?.last ?? const Color(0xFF5B5FEF);
}

List<FieldModel> get builtInFields =>
    defaultFields.map((m) => FieldModel.fromMap(m)).toList();
