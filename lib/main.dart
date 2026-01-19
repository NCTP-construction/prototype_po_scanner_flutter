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
      title: 'Construction Site Manager',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SiteListPage(),
    );
  }
}

class ConstructionSite {
  final String name;
  final String date;
  final String filledBy;
  final String imageUrl;

  ConstructionSite({
    required this.name,
    required this.date,
    required this.filledBy,
    required this.imageUrl,
  });
}

class SiteCard extends StatelessWidget {
  final ConstructionSite site;
  const SiteCard({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Column(
        children: [
          // 75% Photo Area
          AspectRatio(
            aspectRatio: 16 / 9, // Standard wide-screen photo ratio
            child: Image.network(
              site.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image),
              ),
            ),
          ),
          // 25% Text Area
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(site.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: ${site.date}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      "By: ${site.filledBy}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SiteListPage extends StatelessWidget {
  SiteListPage({super.key});
  final List<ConstructionSite> sites = [
    ConstructionSite(
      name: "Skyline Tower - Phase 1",
      date: "2024-05-18",
      filledBy: "Alex Rivera",
      imageUrl: "https://images.unsplash.com/photo-1541888946425-d81bb19480c5?auto=format&fit=crop&w=800&q=80",
    ),
    ConstructionSite(
      name: "Bridge Inspection - North",
      date: "2024-05-19",
      filledBy: "Sarah Chen",
      imageUrl: "https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=800&q=80",
    ),
    ConstructionSite(
      name: "Underground Drainage",
      date: "2024-05-20",
      filledBy: "Mike Johnson",
      imageUrl: "https://images.unsplash.com/photo-1581094271901-8022df4466f9?auto=format&fit=crop&w=800&q=80",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Construction Sites"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: sites.isEmpty
          ? const Center(child: Text("No forms filled yet. Tap + to start."))
          : ListView.builder(
              itemCount: sites.length,
              itemBuilder: (context, index) {
                final site = sites[index];
                return SiteCard(site: site);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // This is where you will navigate to your "Form" page later
          print("Navigate to New Form");
        },
        child: const Icon(Icons.add),
      ),
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
      var uri = Uri.parse('http://192.168.1.166:8000/upload-po'); // Use your IP
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
