import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/po_model.dart';
import '../models/extraction_result.dart';
import 'review_extraction_screen.dart';
import 'entry_form_screen.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.title});
  final String title;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  List<PurchaseOrder> _scannedOrders = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo == null) return;

    setState(() => _isLoading = true);

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fileName = p.basename(photo.path);
      final String permanentPath = p.join(appDocDir.path, fileName);
      await File(photo.path).copy(permanentPath);

      // 1. Try to hit the AI Server
      var uri = Uri.parse('http://192.168.1.166:8000/upload-po');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', permanentPath),
      );

      // Set a timeout! If the network is bad, don't make the user wait forever.
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // SUCCESS: AI worked. Parse data and go to the Validation Screen.
        final result = ExtractionResult.fromJson(jsonDecode(response.body));
        setState(() => _isLoading = false);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewExtractionScreen(
              extractionResult: result,
              originalImagePath: photo.path,
            ),
          ),
        );
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      // 2. OFFLINE FALLBACK: The network failed or timed out.
      setState(() => _isLoading = false);

      if (!mounted) return;

      // Alert the user that they are offline
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Offline: AI Unavailable. Proceeding to manual entry.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Route them to your standard manual EntryFormScreen,
      // passing the photo so they don't have to take it again!
      // (You will need to update EntryFormScreen to accept an initial image)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EntryFormScreen(initialImages: [photo.path]),
        ),
      );
    }
  }

  void _showPickerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Gallery'),
                onTap: () {
                  _pickAndUploadImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  _pickAndUploadImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Scanned POs')),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: _scannedOrders.length,
            itemBuilder: (context, index) {
              final item = _scannedOrders[index];
              return ListTile(
                title: Text(item.vendorName),
                subtitle: Text(item.date),
                trailing: Text("\$${item.totalAmount}"),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPickerMenu,
        // tooltip: 'Increment',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
