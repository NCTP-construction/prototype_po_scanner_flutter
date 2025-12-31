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

  Future<void> _startScan() async {
    print("Camera button pressed!");

    // Open Camera
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo == null) return;

    // Setup the Request
    var uri = Uri.parse('http://192.168.1.110:8000/upload-po');
    var request = http.MultipartRequest('POST', uri);

    // Attach file
    var multipartFile = await http.MultipartFile.fromPath('file', photo.path);
    request.files.add(multipartFile);

    try {
      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // Update UI with the result
        setState(() {
          _scannedOrders.add(
            PurchaseOrder(
              vendorName: data['vendor'],
              totalAmount: data['total'],
              date: data['date'],
            ),
          );
        });
      } else {
        print("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Connection error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Scanned POs')),
      body: ListView.builder(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        // tooltip: 'Increment',
        child: const Icon(Icons.camera_alt),
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
