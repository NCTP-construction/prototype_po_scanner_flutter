import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:convert';

import 'package:prototype_po_scanner/models/daily_report_model.dart';
import 'package:prototype_po_scanner/models/user_model.dart';
import 'package:prototype_po_scanner/services/image_service.dart';
import 'package:prototype_po_scanner/services/database_helper.dart';

class EntryFormScreen extends StatefulWidget {
  final List<String>? initialImages;
  const EntryFormScreen({super.key, this.initialImages});

  @override
  State<StatefulWidget> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  // Simulated database of all employees
  // List<TransportLog> _transportLogs = [];

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final ImageService _imageService = ImageService();

  late DailyReportModel _formData;

  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _equipments = [];

  // Initialize state of form
  @override
  void initState() {
    super.initState();
    _formData = DailyReportModel(
      date: DateTime.now(),
      author: User(userId: "1", username: 'tifaky', fullName: "tifaky"),
      siteName: "report.site_name".tr(),
      imagePaths: widget.initialImages ?? [],
    );

    _initAppData();
  }

  Future<void> _initAppData() async {
    // 1. INSTANT LOAD: Get data from local SQLite cache using the generic method
    // final p = await DatabaseHelper.instance.getMasterCache('cache_projects');
    final s = await DatabaseHelper.instance.getMasterCache('cache_staff');
    final m = await DatabaseHelper.instance.getMasterCache('cache_materials');
    final e = await DatabaseHelper.instance.getMasterCache('cache_assets');

    // Update the UI immediately so the user doesn't wait
    if (mounted) {
      setState(() {
        _staff = s;
        _materials = m;
        _equipments = e;
      });
    }

    // 2. SILENT UPDATE: Try to fetch fresh data from Supabase in the background
    try {
      final supabase = Supabase.instance.client;

      final freshProjects = await supabase.from('projects').select('id, name');
      final freshStaff = await supabase
          .from('staff')
          .select('id, full_name, employment_type');
      final freshMaterials = await supabase
          .from('materials')
          .select('id, name, current_stock');
      final freshEquipments = await supabase
          .from('assets')
          .select('id, model, is_internal, renter_name');

      // 3. Update Local SQLite Cache using the generic save method
      await DatabaseHelper.instance.saveMasterCache(
        'cache_projects',
        freshProjects,
      );
      await DatabaseHelper.instance.saveMasterCache('cache_staff', freshStaff);
      await DatabaseHelper.instance.saveMasterCache(
        'cache_materials',
        freshMaterials,
      );
      await DatabaseHelper.instance.saveMasterCache(
        'cache_assets',
        freshEquipments,
      );

      // 4. Update UI again if the user is still on the screen
      if (mounted) {
        setState(() {
          _staff = freshStaff;
          _materials = freshMaterials;
          _equipments = freshEquipments;
        });
      }
    } catch (e) {
      // If offline, this block silently fails, and the user continues using the cached data from step 1.
      debugPrint("Offline mode: Using cached master data. Error: $e");
    }
  }

  void _addLaborEntry() async {
    EmploymentType selectedType = EmploymentType.internal;
    String? selectedStaffId;
    String selectedName = "";
    bool isOvertime = false;
    double hours = 8.0;

    final TextEditingController nameController = TextEditingController();
    final TextEditingController agencyController = TextEditingController();

    // Simulated list of internal staff synced from Supabase/Sqflite
    // final List<Map<String, String>> internalStaffDb = [
    //   {'id': 'uuid-101', 'name': 'Jean Dupont', 'role': 'Mason'},
    //   {'id': 'uuid-102', 'name': 'Marie Curie', 'role': 'Foreman'},
    // ];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("report.sections.resources.labor.add_labor".tr()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Toggle Type
                    SegmentedButton<EmploymentType>(
                      segments: [
                        ButtonSegment(
                          value: EmploymentType.internal,
                          label: Text(
                            "report.sections.resources.labor.internal_employee"
                                .tr(),
                          ),
                        ),
                        ButtonSegment(
                          value: EmploymentType.external,
                          label: Text(
                            "report.sections.resources.labor.external".tr(),
                          ),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (val) =>
                          setDialogState(() => selectedType = val.first),
                    ),
                    const SizedBox(height: 20),

                    // 2. Input Fields based on Type
                    if (selectedType == EmploymentType.internal)
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText:
                              "report.sections.resources.labor.select_employee"
                                  .tr(),
                        ),
                        items: _staff.map((s) {
                          return DropdownMenuItem<String>(
                            value: s['id'] as String,
                            child: Text(s['full_name']! as String),
                          );
                        }).toList(),
                        onChanged: (String? selectedId) {
                          if (selectedId != null) {
                            setDialogState(() {
                              // Find the full name matching the selected UUID to display in the UI
                              selectedName =
                                  _staff.firstWhere(
                                        (s) => s['id'] == selectedId,
                                      )['full_name']
                                      as String;
                              selectedStaffId = selectedId;
                            });
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Please select an employee' : null,
                      )
                    else ...[
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText:
                              "report.sections.resources.labor.worker_name"
                                  .tr(),
                        ),
                      ),
                      TextField(
                        controller: agencyController,
                        decoration: InputDecoration(
                          labelText:
                              "report.sections.resources.labor.agency_name"
                                  .tr(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 15),

                    // 3. Hours & Overtime
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText:
                                  "report.sections.resources.labor.hours_worked"
                                      .tr(),
                              suffixText: "hrs",
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                hours = double.tryParse(val) ?? 8.0,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            Text(
                              "report.sections.resources.labor.overtime".tr(),
                            ),
                            Checkbox(
                              value: isOvertime,
                              onChanged: (val) =>
                                  setDialogState(() => isOvertime = val!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("cancel".tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _formData.laborEntries = [
                        ..._formData.laborEntries,
                        LaborEntry(
                          staffId: selectedStaffId,
                          fullName: selectedType == EmploymentType.internal
                              ? selectedName
                              : nameController.text,
                          type: selectedType,
                          hoursWorked: hours,
                          isOvertime: isOvertime,
                          agencyName: selectedType == EmploymentType.external
                              ? agencyController.text
                              : null,
                        ),
                      ];
                    });
                    Navigator.pop(context);
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

  void _addEquipment() async {
    String? selectedEquipmentId;
    String selectedEquipmentName = "";
    bool isInternal = true;
    String renter = '';

    final TextEditingController renterController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    final result = await showDialog<Equipment>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                "report.sections.resources.equipment.add_equipment".tr(),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text(
                      "report.sections.resources.equipment.internal_machine_title"
                          .tr(),
                    ),
                    value: isInternal,
                    onChanged: (val) {
                      setDialogState(() {
                        isInternal = val;
                        // Reset selections when toggling
                        selectedEquipmentId = null;
                        selectedEquipmentName = '';
                        nameController.clear();
                        renterController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  if (isInternal)
                    // Internal: pick from company asset DB
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText:
                            "report.sections.resources.equipment.select_equipment"
                                .tr(),
                      ),
                      value: selectedEquipmentId,
                      items: _equipments.map((e) {
                        return DropdownMenuItem<String>(
                          value: e['id'] as String,
                          child: Text(e['model'] as String),
                        );
                      }).toList(),
                      onChanged: (String? selectedId) {
                        if (selectedId != null) {
                          final match = _equipments.firstWhere(
                            (e) => e['id'] == selectedId,
                          );
                          setDialogState(() {
                            selectedEquipmentId = selectedId;
                            selectedEquipmentName = match['model'] as String;
                          });
                        }
                      },
                    )
                  else ...[
                    // External: free-text name + renter
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText:
                            "report.sections.resources.equipment.equipment_name"
                                .tr(),
                      ),
                      onChanged: (val) {
                        setDialogState(() => selectedEquipmentName = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: renterController,
                      decoration: InputDecoration(
                        labelText:
                            "report.sections.resources.equipment.renter_name"
                                .tr(),
                      ),
                      onChanged: (val) {
                        setDialogState(() => renter = val);
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("button.cancel".tr()),
                ),
                ElevatedButton(
                  onPressed: selectedEquipmentName.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          Equipment(
                            equipmentName: selectedEquipmentName,
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
    String selectedSource = "inventory";
    String? selectedMaterialId;
    String selectedMaterialName = "";

    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                "report.sections.resources.materials.add_material".tr(),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: "inventory",
                          label: Text(
                            "report.sections.resources.materials.stock".tr(),
                          ),
                        ),
                        ButtonSegment(
                          value: "purchase_on_site",
                          label: Text(
                            "report.sections.resources.materials.purchase".tr(),
                          ),
                        ),
                      ],
                      selected: {selectedSource},
                      onSelectionChanged: (val) =>
                          setDialogState(() => selectedSource = val.first),
                    ),
                    const SizedBox(height: 20),
                    // MATERIAL NAME: Dropdown for Stock or TextField for Purchase
                    if (selectedSource == "inventory")
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText:
                              "report.sections.resources.materials.select_material"
                                  .tr(),
                        ),
                        items: _materials.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'],
                            child: Text(item['name']! as String),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedMaterialId = val;
                            selectedMaterialName = _materials.firstWhere(
                              (e) => e['id'] == val,
                            )['name']!;
                          });
                        },
                      )
                    else
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText:
                              "report.sections.resources.materials.description"
                                  .tr(),
                          hintText:
                              "report.sections.resources.materials.materials_hint"
                                  .tr(),
                        ),
                      ),
                    const SizedBox(height: 15),
                    // QUANTITY INPUT
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            "report.sections.resources.materials.quantity".tr(),
                        suffixText: selectedSource == "inventory"
                            ? ""
                            : "Units",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("button.cancel".tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    final String name = selectedSource == "inventory"
                        ? selectedMaterialName
                        : nameController.text.trim();
                    final double? qty = double.tryParse(
                      quantityController.text,
                    );
                    if (name.isNotEmpty && qty != null) {
                      setState(() {
                        _formData.consumableMaterials = [
                          ..._formData.consumableMaterials,
                          MaterialEntry(
                            materialId: selectedSource == "inventory"
                                ? selectedMaterialId
                                : null,
                            name: name,
                            quantity: qty,
                            source: selectedSource,
                          ),
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      // 1. Prepare data
      final String jsonPayload = jsonEncode(_formData.toJson());

      // 2. Async operation (The "Async Gap" happens here)
      await DatabaseHelper.instance.insertReport({
        'project_id': _formData.siteName,
        'report_date': _formData.date.toIso8601String(),
        'payload': jsonPayload,
        'is_synced': 0,
      });

      // 3. GUARD: Check if the widget is still in the tree before using context
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('messages.report_saved'.tr())));

      Navigator.pop(context);
    } catch (e) {
      // Also guard error feedback
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
            // Labor / Manpower input
            // Title
            Text(
              "report.sections.resources.labor.title".tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10), // Blank Divider
            // List of employees added
            Column(
              children: _formData.laborEntries
                  .map(
                    (worker) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: worker.type == EmploymentType.internal
                            ? Colors.blue.shade100
                            : Colors.orange.shade100,
                        child: Icon(
                          worker.type == EmploymentType.internal
                              ? Icons.badge
                              : Icons.engineering,
                          color: worker.type == EmploymentType.internal
                              ? Colors.blue
                              : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(worker.fullName),
                      subtitle: Text(
                        worker.type == EmploymentType.internal
                            ? "report.sections.resources.labor.internal_employee"
                                  .tr()
                            : "${"report.sections.resources.labor.internal_employee".tr()}:${worker.agencyName ?? "report.sections.resources.labor.independent".tr()}",
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${worker.hoursWorked}h",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (worker.isOvertime)
                            Text(
                              "report.sections.resources.labor.overtime".tr(),
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      onLongPress: () =>
                          setState(() => _formData.laborEntries.remove(worker)),
                    ),
                  )
                  .toList(),
            ),
            // The Button to input external workers
            OutlinedButton.icon(
              onPressed: _addLaborEntry,
              icon: const Icon(Icons.person_add),
              label: Text("report.sections.resources.labor.add_labor".tr()),
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
                "report.sections.resources.equipment.add_equipment".tr(),
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
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          item.source == 'inventory'
                              ? Icons.warehouse
                              : Icons.shopping_cart,
                          size: 20,
                          color: item.source == 'inventory'
                              ? Colors.blue
                              : Colors.green,
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          "Source: ${item.source == 'inventory' ? 'Warehouse' : 'On-site Purchase'}",
                        ),
                        trailing: Text(
                          "x${item.quantity}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onLongPress: () {
                          setState(() {
                            _formData.consumableMaterials.remove(item);
                          });
                        },
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "report.sections.transport.title".tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            _buildTransportSection("8x4"),
            _buildTransportSection("6x4"),

            OutlinedButton.icon(
              onPressed: _addTransportLog,
              icon: const Icon(Icons.add_road),
              label: Text("report.sections.transport.add_trip".tr()),
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
