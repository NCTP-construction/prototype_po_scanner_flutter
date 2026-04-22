import 'dart:io';
import 'package:flutter/material.dart';
import '../models/extraction_result.dart';
import '../services/database_helper.dart';
import 'dart:convert';

class ReviewExtractionScreen extends StatefulWidget {
  final ExtractionResult extractionResult;
  final String originalImagePath;

  const ReviewExtractionScreen({
    super.key,
    required this.extractionResult,
    required this.originalImagePath,
  });

  @override
  State<ReviewExtractionScreen> createState() => _ReviewExtractionScreenState();
}

class _ReviewExtractionScreenState extends State<ReviewExtractionScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    widget.extractionResult.fields.forEach((key, fieldData) {
      _controllers[key] = TextEditingController(text: fieldData.value);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveValidatedData() async {
    if (_formKey.currentState!.validate()) {
      // 1. Package the verified data
      final Map<String, dynamic> documentPayload = {
        'document_type':
            widget.extractionResult.documentType, // e.g., 'PURCHASE_ORDER'
        'vendor_name': _controllers['vendor_name']?.text,
        'total_amount': double.tryParse(
          _controllers['total_amount']?.text ?? '0',
        ),
        'date': _controllers['date']?.text,
        'image_path':
            widget.originalImagePath, // Save the local path to the photo
      };

      // 2. SAVE LOCALLY FIRST (SQLite)
      // The user can now close the app. Their work is safe.
      await DatabaseHelper.instance.insertReport({
        'project_id': null, // Assign to current project if context exists
        'report_date': DateTime.now().toIso8601String(),
        'payload': jsonEncode(documentPayload),
        'is_synced': 0, // Flags it for the SyncService!
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved locally! Will sync when online.'),
          ),
        );
        Navigator.pop(context); // Go back to scanner list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Extraction')),
      body: Column(
        children: [
          // Top Half: Show the original image so the user can compare
          Expanded(
            flex: 1,
            child: InteractiveViewer(
              child: Image.file(
                File(widget.originalImagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      "Detected Type: ${widget.extractionResult.documentType}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.extractionResult.fields.entries.map((entry) {
                      final key = entry.key;
                      final fieldData = entry.value;
                      final isLowConfidence = fieldData.confidence < 0.85;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _controllers[key],
                          decoration: InputDecoration(
                            labelText: key.replaceAll('_', ' ').toUpperCase(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isLowConfidence
                                    ? Colors.red
                                    : Colors.grey,
                                width: isLowConfidence ? 2 : 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            suffixIcon: isLowConfidence
                                ? const Icon(Icons.warning, color: Colors.red)
                                : const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
