import '../models/user_model.dart';
import 'package:easy_localization/easy_localization.dart';

// Climate options
enum WeatherCondition { sunny, mild, rainy }

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

// Main Report Model
class DailyReportModel {
  // Metadata
  DateTime date;
  WeatherCondition climate;
  String siteName;
  final User author;

  // List of Strings (Simple)
  List<String> internalManpower;
  List<String> miscTools;
  List<String> miscWork;
  List<String> imagePaths;
  List<String> consumableMaterials;

  // Lists of Objects (Complex)
  List<ExternalWorker> externalManpower;
  List<Equipment> equipments;

  List<TransportLog> transportLogs;

  DailyReportModel({
    required this.date,
    required this.siteName,
    required this.author,
    this.climate = WeatherCondition.sunny, // Default
    this.internalManpower = const [],
    this.miscTools = const [],
    this.miscWork = const [],
    this.externalManpower = const [],
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
      'climate': climate.name, // Saves as "soleil", "mitige", etc.
      'internal_manpower': internalManpower,
      'external_manpower': externalManpower.map((e) => e.toJson()).toList(),
      'equipments': equipments.map((e) => e.toJson()).toList(),
      'consumable_materials': consumableMaterials,
      'transport_logs': transportLogs.map((e) => e.toJson()).toList(),
      'misc_tools': miscTools,
      'misc_work': miscWork,
      'image_paths': imagePaths,
    };
  }
}
