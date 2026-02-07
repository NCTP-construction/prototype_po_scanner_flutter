class SiteFormModel {
  String siteName;
  DateTime date;
  String author;
  List<String> internalEmployees;
  List<String> externalWorkers;
  List<Map<String, dynamic>> materials;

  SiteFormModel({
    this.siteName = '',
    required this.date,
    this.author = '',
    this.internalEmployees = const [],
    this.externalWorkers = const [],
    this.materials = const [],
  });
}
