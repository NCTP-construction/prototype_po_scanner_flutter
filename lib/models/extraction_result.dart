class ExtractionResult {
  final String documentType;
  final Map<String, ExtractedField> fields;

  ExtractionResult({required this.documentType, required this.fields});
  factory ExtractionResult.fromJson(Map<String, dynamic> json) {
    var fieldsJson = json['fields'] as Map<String, dynamic>;
    Map<String, ExtractedField> parsedFields = {};

    fieldsJson.forEach((key, value) {
      parsedFields[key] = ExtractedField.fromJson(value);
    });

    return ExtractionResult(
      documentType: json['document_type'],
      fields: parsedFields,
    );
  }
}

class ExtractedField {
  final String value;
  final double confidence;

  ExtractedField({required this.value, required this.confidence});
  factory ExtractedField.fromJson(Map<String, dynamic> json) {
    return ExtractedField(
      value: json['value'],
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}
