import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prototype_po_scanner/models/daily_report_model.dart';
import 'package:prototype_po_scanner/models/user_model.dart';
import 'package:prototype_po_scanner/services/image_service.dart';

class EntryFormScreen extends StatefulWidget {
  const EntryFormScreen({super.key});

  @override
  State<StatefulWidget> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  // Simulated database of all employees
  final List<String> _allInternalEmployees = [
    "Jean Dupont",
    "Marie Curie",
    "Pierre Gasly",
    "Charles Leclerc",
    "Esteban Ocon",
    "Lucas Bernard",
  ];

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final ImageService _imageService = ImageService();

  late DailyReportModel _formData;

  // Initialize state of form
  @override
  void initState() {
    super.initState();
    _formData = DailyReportModel(
      date: DateTime.now(),
      author: User(userId: "1", username: 'tifaky', fullName: "tifaky"),
      siteName: "Enter Site Name",
    );
  }

  // Helper functions for fields input
  void _addExternalWorker() async {
    final worker = await showDialog<ExternalWorker>(
      context: context,
      builder: (context) {
        String name = '';
        String agency = '';
        int hours = 0;

        return AlertDialog(
          title: const Text("Add Agency Worker"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Shrink to fit content
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Worker Name"),
                onChanged: (val) => name = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Agency Name"),
                onChanged: (val) => agency = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Hours Worked"),
                keyboardType: TextInputType.number,
                onChanged: (val) => hours = int.tryParse(val) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty && agency.isNotEmpty) {
                  // Return the Object, not just a string!
                  Navigator.pop(
                    context,
                    ExternalWorker(
                      name: name,
                      agency: agency,
                      hoursWorked: hours,
                    ),
                  );
                }
              },
              child: const Text("ADD"),
            ),
          ],
        );
      },
    );

    // If we got a valid worker object back, add it to the report
    if (worker != null) {
      setState(() {
        _formData.externalManpower = [..._formData.externalManpower, worker];
      });
    }
  }

  void _showInternalWorkerPicker() async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Internal Workers"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allInternalEmployees.length,
                  itemBuilder: (context, index) {
                    final worker = _allInternalEmployees[index];
                    final isSelected = _formData.internalManpower.contains(
                      worker,
                    );
                    return CheckboxListTile(
                      title: Text(worker),
                      value: isSelected,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _formData.internalManpower = [
                              ..._formData.internalManpower,
                              worker,
                            ];
                          } else {
                            _formData.internalManpower = _formData
                                .internalManpower
                                .where((name) => name != worker)
                                .toList();
                          }
                        });
                        setDialogState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("DONE"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInternalMaterialpicker() async {
    final TextEditingController _newMaterialController =
        TextEditingController();
    await showDialog(context: context, builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Select Internal Materials"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(
                        controller: _newMaterialController,
                        decoration: const InputDecoration(
                          hintText: "New material name...",
                          isDense: true
                        ),
                      ),
                      ),
                      IconButton(
                        onPressed: () {
                          String newItem = _newMaterialController.text.trim();
                        }, 
                        icon: const Icon(Icons.add_circle, color: Colors.blue))

                  ],)
                ],
              ),
            ),
          )
        })
    });
  }

  Future<void> _pickPhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      String safePath = await _imageService.saveImagePermanently(photo.path);
      setState(() {
        _formData.imagePaths = [..._formData.imagePaths, safePath];
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Processing Data...')));
    }
  }

  // widget / interface render
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Daily Report")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Site name
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Site Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter site name' : null,
              onSaved: (value) => _formData.siteName = value!,
            ),
            const SizedBox(height: 16), // Blank Divider
            // Date and Climate
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text("Date"),
                    subtitle: Text(
                      "${_formData.date.day}/${_formData.date.month}/${_formData.date.year}",
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _formData.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _formData.date = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<WeatherCondition>(
                    initialValue: _formData.climate,
                    decoration: const InputDecoration(
                      labelText: "Climate",
                      border: UnderlineInputBorder(),
                    ),
                    items: WeatherCondition.values.map((weather) {
                      return DropdownMenuItem(
                        value: weather,
                        child: Text(
                          weather.name[0].toUpperCase() +
                              weather.name.substring(1),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() => _formData.climate = newValue!);
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 40),

            // Resources (Materials and Manpower)
            const Text(
              "Resources",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10), // Blank Divider
            // Internal Manpower input
            // Title
            const Text(
              "Manpower - Internal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10), // Blank Divider
            // List of employees added
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _formData.internalManpower.map((worker) {
                return InputChip(
                  label: Text(worker),
                  onDeleted: () {
                    setState(() {
                      _formData.internalManpower.remove(worker);
                    });
                  },
                );
              }).toList(),
            ),
            // Button to input internal workers
            OutlinedButton.icon(
              onPressed: _showInternalWorkerPicker,
              icon: const Icon(Icons.person_search),
              label: const Text("Select Employees"),
            ),

            // External Manpower input
            // Title
            const Text(
              "Manpower - External (Agency)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10), // Blank Divider
            // List of employees added
            Column(
              children: _formData.externalManpower.map((worker) {
                return ListTile(
                  leading: const Icon(
                    Icons.badge_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(worker.name),
                  subtitle: Text("${worker.agency} • ${worker.hoursWorked}h"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _formData.externalManpower.remove(worker);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            // The Button to input external workers
            OutlinedButton.icon(
              onPressed: _addExternalWorker,
              icon: const Icon(Icons.add),
              label: const Text("Add External Worker"),
            ),

            const SizedBox(height: 40),
            const Text(
              "Materials",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const Divider(height: 40),
            const Text(
              "Site Photos & POs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _formData.imagePaths.length + 1,
                itemBuilder: (context, index) {
                  if (index == _formData.imagePaths.length) {
                    return GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 100,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        Image.file(
                          File(_formData.imagePaths[index]),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _formData.imagePaths.removeAt(index);
                              });
                            },
                            child: const Icon(Icons.cancel, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("SUBMIT REPORT"),
            ),
          ],
        ),
      ),
    );
  }
}
