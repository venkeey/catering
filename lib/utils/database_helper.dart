import 'package:mysql1/mysql1.dart';

class DatabaseHelper {
  static Map<String, dynamic> rowToMap(ResultRow row) {
    final fields = <String, dynamic>{};
    for (var field in row.fields.keys) {
      fields[field] = row[field];
    }
    return fields;
  }

  static List<Map<String, dynamic>> rowsToList(Results results) {
    return results.map((row) => rowToMap(row)).toList();
  }

  static String? stringValue(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static int? intValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? doubleValue(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool? boolValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }

  static DateTime? dateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<String>? stringListValue(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      if (value.isEmpty) return [];
      return value.split(',').map((e) => e.trim()).toList();
    }
    return null;
  }

  static Map<String, double>? mapValue(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((key, value) => MapEntry(
        key.toString(),
        doubleValue(value) ?? 0.0,
      ));
    }
    if (value is String) {
      if (value.isEmpty) return {};
      try {
        final map = <String, double>{};
        final pairs = value.split(',');
        for (var pair in pairs) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            final key = parts[0].trim();
            final value = doubleValue(parts[1].trim());
            if (value != null) {
              map[key] = value;
            }
          }
        }
        return map;
      } catch (e) {
        return {};
      }
    }
    return null;
  }
} 