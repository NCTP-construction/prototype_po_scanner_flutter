import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prototype_po_scanner/models/daily_report_model.dart';
import 'package:prototype_po_scanner/models/user_model.dart';
import 'package:prototype_po_scanner/services/image_service.dart';
import 'package:easy_localization/easy_localization.dart';

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
  // List<TransportLog> _transportLogs = [];
  // List<String> _materials = [];
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
      siteName: "report.sections.resources.manpower_external.site_name".tr(),
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
          title: Text(
            "report.sections.resources.manpower_external.add_external_worker"
                .tr(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Shrink to fit content
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText:
                      "report.sections.resources.manpower_external.worker_name"
                          .tr(),
                ),
                onChanged: (val) => name = val,
              ),
              TextField(
                decoration: InputDecoration(
                  labelText:
                      "report.sections.resources.manpower_external.agency_name"
                          .tr(),
                ),
                onChanged: (val) => agency = val,
              ),
              TextField(
                decoration: InputDecoration(
                  labelText:
                      "report.sections.resources.manpower_external.hours_worked"
                          .tr(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) => hours = int.tryParse(val) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("button.cancel".tr()),
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
              child: Text("button.add".tr()),
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
              title: Text(
                "report.sections.resources.manpower_internal.select_internal_employees"
                    .tr(),
              ),
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
                  child: Text("button.done".tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addEquipment() async {
    final result = await showDialog<Equipment>(
      context: context,
      builder: (context) {
        String name = '';
        bool isInternal = true;
        String renter = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                "report.sections.resources.equipment.add_equipment".tr(),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText:
                          "report.sections.resources.equipment.equipment_name"
                              .tr(),
                    ),
                    onChanged: (val) => name = val,
                  ),
                  SwitchListTile(
                    title: Text(
                      "report.sections.resources.equipment.internal_machine_title"
                          .tr(),
                    ),
                    value: isInternal,
                    onChanged: (val) {
                      setDialogState(() => isInternal = val);
                    },
                  ),
                  if (!isInternal)
                    TextField(
                      decoration: InputDecoration(
                        labelText:
                            "report.sections.resources.equipment.renter_name"
                                .tr(),
                      ),
                      onChanged: (val) => renter = val,
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("button.cancel".tr()),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    Equipment(
                      equipmentName: name,
                      isInternal: isInternal,
                      renterName: isInternal ? null : renter,
                    ),
                  ),
                  child: Text("button.add".tr()),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        _formData.equipments = [..._formData.equipments, result];
      });
    }
  }

  void _addTransportLog() async {
    String selectedType = "8x4";
    int count = 1;
    final TextEditingController _workController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("transport.add_title".tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton(
                    segments: const [
                      ButtonSegment(value: "8x4", label: Text("8x4")),
                      ButtonSegment(value: "6x4", label: Text("6x4")),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (set) =>
                        setDialogState(() => selectedType = set.first),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _workController,
                    decoration: InputDecoration(
                      labelText: "transport.work_label".tr(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("transport.trips".tr()),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setDialogState(() {
                              if (count > 1) {
                                count--;
                              }
                            }),
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            "$count",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setDialogState(() => count++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("cancel".tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_workController.text.isNotEmpty) {
                      setState(() {
                        _formData.transportLogs = [
                          ..._formData.transportLogs,
                          TransportLog(
                            type: selectedType,
                            tripCount: count,
                            workDescription: _workController.text.trim(),
                          ),
                        ];
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text("add".tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addMaterials() async {
    final TextEditingController _controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("report.sections.resources.materials.add_material".tr()),
          content: TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "report.sections.resources.materials.materials_hint"
                  .tr(),
              labelText: "report.sections.resources.materials.description".tr(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("button.cancel".tr()),
            ),
            ElevatedButton(
              onPressed: () {
                String name = _controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _formData.consumableMaterials = [
                      ..._formData.consumableMaterials,
                      name,
                    ];
                  });
                  Navigator.pop(context);
                }
              },
              child: Text("button.add".tr()),
            ),
          ],
        );
      },
    );
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

  // Display components
  Widget _buildTransportSection(String truckType) {
    // Filter logs for this specific truck type
    final logs = _formData.transportLogs
        .where((l) => l.type == truckType)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          truckType,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        if (logs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text("—", style: TextStyle(color: Colors.grey)),
          ),
        ...logs.map(
          (log) => ListTile(
            dense: true,
            leading: const Icon(Icons.local_shipping, size: 20),
            title: Text(log.workDescription),
            trailing: Text(
              "x${log.tripCount}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onLongPress: () => setState(
              () => _formData.transportLogs.remove(log),
            ), // Remove on long press
          ),
        ),
        const Divider(),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('messages.processing_data'.tr())));
    }
  }

  // widget / interface render
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("report.new_report".tr())),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Site name
            TextFormField(
              decoration: InputDecoration(
                labelText: 'report.site_name'.tr(),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'report.enter_site_name'.tr() : null,
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
                    title: Text("report.date".tr()),
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
                    decoration: InputDecoration(
                      labelText: "report.climate.title".tr(),
                      border: UnderlineInputBorder(),
                    ),
                    items: WeatherCondition.values.map((weather) {
                      return DropdownMenuItem(
                        value: weather,
                        child: Text(weather.translatedName),
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
            Text(
              "report.sections.resources.title".tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10), // Blank Divider
            // Internal Manpower input
            // Title
            Text(
              "report.sections.resources.manpower_internal.title".tr(),
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
              label: Text(
                "report.sections.resources.manpower_internal.select_internal_employees"
                    .tr(),
              ),
            ),
            const SizedBox(height: 20),
            // External Manpower input
            // Title
            Text(
              "report.sections.resources.manpower_external.title".tr(),
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
              label: Text(
                "report.sections.resources.manpower_external.add_external_worker"
                    .tr(),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "report.sections.resources.equipment.title".tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Column(
              children: _formData.equipments.map((equipment) {
                return Card(
                  elevation: 0,
                  color: equipment.isInternal
                      ? Colors.blue.withValues(alpha: 0.05)
                      : Colors.orange.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.precision_manufacturing,
                      color: equipment.isInternal ? Colors.blue : Colors.orange,
                    ),
                    title: Text(
                      equipment.equipmentName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      equipment.isInternal
                          ? "report.sections.resources.equipment.internal_property"
                                .tr()
                          : "Rented from: ${equipment.renterName ?? "Unknown"}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => setState(
                        () => _formData.equipments.remove(equipment),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            OutlinedButton.icon(
              onPressed: _addEquipment, // Method from previous step
              icon: const Icon(Icons.add_outlined),
              label: Text(
                "report.sections.resources.equipment.add_engine".tr(),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
              ),
            ),

            // ========= CONSTRUCTION MATERIALS =========
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "report.sections.resources.materials.title".tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _formData.consumableMaterials.isEmpty
                  ? [
                      Text(
                        "report.sections.resources.materials.no_materials".tr(),
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ]
                  : _formData.consumableMaterials.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              " • ",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            // Tiny delete button for editing
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _formData.consumableMaterials = _formData
                                      .consumableMaterials
                                      .where((m) => m != item)
                                      .toList();
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
            const SizedBox(height: 12),

            // Button to trigger the simplified dialog
            OutlinedButton.icon(
              onPressed: _addMaterials,
              icon: const Icon(Icons.playlist_add),
              label: Text(
                "report.sections.resources.materials.add_material".tr(),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
              ),
            ),

            // ========= END CONSTRUCTION MATERIALS =========
            // ========= TRANSPORT =========
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "Transport Logs",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            _buildTransportSection("8x4"),
            _buildTransportSection("6x4"),

            OutlinedButton.icon(
              onPressed: _addTransportLog,
              icon: const Icon(Icons.add_road),
              label: const Text("Log New Trip"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
              ),
            ),

            // ========= END TRANSPORT =========
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
              child: Text("button.save".tr()),
            ),
          ],
        ),
      ),
    );
  }
}
