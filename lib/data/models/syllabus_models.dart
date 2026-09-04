import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class University {
  final String id;
  final String name;
  final String shortName;
  final String state;
  final String country;

  const University({
    required this.id,
    required this.name,
    required this.shortName,
    this.state = '',
    this.country = 'India',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'state': state,
        'country': country,
      };

  factory University.fromJson(Map<String, dynamic> json) => University(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'General MSc Chemistry',
        shortName: json['short_name']?.toString() ?? 'GENERAL',
        state: json['state']?.toString() ?? '',
        country: json['country']?.toString() ?? 'India',
      );
}

class SyllabusSubject {
  final String id;
  final String? universityId;
  final String name;
  final String? code;
  final int semester;
  final String? description;
  final int sortOrder;
  final bool isActive;

  const SyllabusSubject({
    required this.id,
    this.universityId,
    required this.name,
    this.code,
    required this.semester,
    this.description,
    this.sortOrder = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'university_id': universityId,
        'name': name,
        'code': code,
        'semester': semester,
        'description': description,
        'sort_order': sortOrder,
        'is_active': isActive,
      };

  factory SyllabusSubject.fromJson(Map<String, dynamic> json) => SyllabusSubject(
        id: json['id']?.toString() ?? '',
        universityId: json['university_id']?.toString(),
        name: json['name']?.toString() ?? 'Chemistry Subject',
        code: json['code']?.toString(),
        semester: (json['semester'] as num? ?? 1).toInt(),
        description: json['description']?.toString(),
        sortOrder: (json['sort_order'] as num? ?? 0).toInt(),
        isActive: json['is_active'] as bool? ?? true,
      );
}

class SyllabusUnit {
  final String id;
  final String subjectId;
  final String name;
  final int? unitNumber;
  final String? description;
  final int sortOrder;

  const SyllabusUnit({
    required this.id,
    required this.subjectId,
    required this.name,
    this.unitNumber,
    this.description,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject_id': subjectId,
        'name': name,
        'unit_number': unitNumber,
        'description': description,
        'sort_order': sortOrder,
      };

  factory SyllabusUnit.fromJson(Map<String, dynamic> json) => SyllabusUnit(
        id: json['id']?.toString() ?? '',
        subjectId: json['subject_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unit',
        unitNumber: json['unit_number'] as int?,
        description: json['description']?.toString(),
        sortOrder: (json['sort_order'] as num? ?? 0).toInt(),
      );
}

class SyllabusTopic {
  final String id;
  final String unitId;
  final String name;
  final String? description;
  final int sortOrder;
  final String importance; // 'high', 'medium', 'low'
  final bool hasMechanism;
  final List<String> mechanismIds;

  const SyllabusTopic({
    required this.id,
    required this.unitId,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.importance = 'medium',
    this.hasMechanism = false,
    this.mechanismIds = const [],
  });

  Color get importanceColor {
    switch (importance.toLowerCase()) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.warning;
      case 'low':
      default:
        return AppColors.success;
    }
  }

  String get importanceLabel {
    switch (importance.toLowerCase()) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
      default:
        return 'Low Priority';
    }
  }

  String get importanceEmoji {
    switch (importance.toLowerCase()) {
      case 'high':
        return '🔥';
      case 'medium':
        return '🟡';
      case 'low':
      default:
        return '🟢';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'unit_id': unitId,
        'name': name,
        'description': description,
        'sort_order': sortOrder,
        'importance': importance,
        'has_mechanism': hasMechanism,
        'mechanism_ids': mechanismIds,
      };

  factory SyllabusTopic.fromJson(Map<String, dynamic> json) => SyllabusTopic(
        id: json['id']?.toString() ?? '',
        unitId: json['unit_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Topic',
        description: json['description']?.toString(),
        sortOrder: (json['sort_order'] as num? ?? 0).toInt(),
        importance: json['importance']?.toString() ?? 'medium',
        hasMechanism: json['has_mechanism'] as bool? ?? false,
        mechanismIds: List<String>.from(json['mechanism_ids'] as List? ?? []),
      );
}
