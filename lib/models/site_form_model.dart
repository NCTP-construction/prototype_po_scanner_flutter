import 'daily_report_model.dart';

class SiteFormModel {
  String siteName;
  DateTime date;
  String author;
  List<String> internalEmployees;
  List<String> externalWorkers;
  List<Equipment> equipments;
  List<Map<String, dynamic>> consumableMaterials; // ex: [{"material": "Cement", "quantity": 50, "unit": "bags"}]

  SiteFormModel({
    this.siteName = '',
    required this.date,
    this.author = '',
    this.internalEmployees = const [],
    this.externalWorkers = const [],
    this.equipments = const [],
    this.consumableMaterials = const [],
  });
}
