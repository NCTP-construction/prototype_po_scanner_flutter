import '../models/user_model.dart';
import 'package:easy_localization/easy_localization.dart';

// Climate options
enum WeatherCondition { sunny, mild, rainy }

enum EmploymentType { internal, external }

extension WeatherConditionExtension on WeatherCondition {
  String get translatedName {
    switch (this) {
      case WeatherCondition.sunny:
        return 'report.climate.sunny'.tr();
      case WeatherCondition.mild:
        return 'report.climate.mild'.tr();
      case WeatherCondition.rainy:
        return 'report.climate.rainy'.tr();
    }
  }
}

// External worker sub-objects
class ExternalWorker {
  String name;
  int hoursWorked;
  String agency;

  ExternalWorker({
    required this.name,
    required this.hoursWorked,
    required this.agency,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'hours_worked': hoursWorked,
    'agency': agency,
  };
}

// External Equipment class
class Equipment {
  String equipmentName;
  bool isInternal; // true for internal, false for external
  String? renterName;

  Equipment({
    required this.equipmentName,
    this.isInternal = true,
    this.renterName,
  });

  Map<String, dynamic> toJson() => {
    'asset_id': isInternal ? null : null,
    'equipment_name': equipmentName,
    'is_internal': isInternal,
    'renter_name': renterName,
  };
}

class TransportLog {
  String type; // "8x4" or "6x4"
  int tripCount;
  String workDescription; // "Site debris", "Material delivery", etc.

  TransportLog({
    required this.type,
    required this.tripCount,
    required this.workDescription,
  });

  // For Database/JSON conversion
  Map<String, dynamic> toJson() => {
    'type': type,
    'trip_count': tripCount,
    'work_description': workDescription,
  };

  factory TransportLog.fromJson(Map<String, dynamic> json) => TransportLog(
    type: json['type'],
    tripCount: json['trip_count'],
    workDescription: json['work_description'],
  );
}

class MaterialEntry {
  final String? materialId;
  final String name;
  final double quantity;
  final String source;

  MaterialEntry({
    this.materialId,
    required this.name,
    required this.quantity,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'material_id': materialId,
    'name': name,
    'quantity': quantity,
    'source': source,
  };
}

class LaborEntry {
  final String? staffId; // The UUID from the 'staff' table
  final String fullName; // For UI display
  final EmploymentType type;
  final double hoursWorked; // Matches DECIMAL(4,2) in DB
  final bool isOvertime; // Matches BOOLEAN in DB
  final String? agencyName;

  LaborEntry({
    this.staffId,
    required this.fullName,
    required this.type,
    this.hoursWorked = 8.0,
    this.isOvertime = false,
    this.agencyName,
  });

  // This version matches the labor_logs table columns exactly
  Map<String, dynamic> toJson() => {
    'staff_id': staffId, // Links to the 'staff' table
    'hours_worked': hoursWorked, // Matches the 'hours_worked' column
    'is_overtime': isOvertime, // Matches the 'is_overtime' column
  };
}

// Main Report Model
class DailyReportModel {
  // Metadata
  DateTime date;
  WeatherCondition climate;
  String siteName;
  final User author;

  // List of Strings (Simple)
  // List<String> internalManpower;
  List<String> imagePaths;
  List<MaterialEntry> consumableMaterials;

  // Lists of Objects (Complex)
  List<LaborEntry> laborEntries;
  List<Equipment> equipments;
  List<TransportLog> transportLogs;

  DailyReportModel({
    required this.date,
    required this.siteName,
    required this.author,
    this.climate = WeatherCondition.sunny, // Default
    this.laborEntries = const [],
    this.equipments = const [],
    this.consumableMaterials = const [],
    this.transportLogs = const [],
    this.imagePaths = const [],
  });

  // PREPARE FOR DATABASE: Convert the whole report to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'author': author.toJson(),
      'climate': climate.name,
      'project_id': siteName,

      'site_name': siteName,
      'labor_entries': laborEntries.map((e) => e.toJson()).toList(),
      'equipments': equipments.map((e) => e.toJson()).toList(),
      'consumable_materials': consumableMaterials
          .map((e) => e.toJson())
          .toList(),
      'transport_logs': transportLogs.map((e) => e.toJson()).toList(),
      'image_paths': imagePaths,
    };
  }
}
