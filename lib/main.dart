import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PO Scanner',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ScannerPage(title: 'PO Scanner'),
    );
  }
}

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
    print("Camera button pressed!");

    // Open Camera
    final XFile? photo = await _picker.pickImage(source: source);

    if (photo == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      var uri = Uri.parse('http://192.168.1.110:8000/upload-po'); // Use your IP
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', photo.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _scannedOrders.add(
            PurchaseOrder(
              vendorName: data['vendor'],
              totalAmount: data['total'],
              date: data['date'],
            ),
          );
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
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

class PurchaseOrder {
  final String vendorName;
  final double totalAmount;
  final String date;

  PurchaseOrder({
    required this.vendorName,
    required this.totalAmount,
    required this.date,
  });
}
