import 'package:flutter/material.dart';
import 'package:my_first_app/widgets/checkprinting.dart';
import 'package:my_first_app/widgets/paymenttype.dart';
import '../../database_helper.dart';
import '../../widgets/supplier_list.dart';
import '../../widgets/preview_printing_dialog.dart';

import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:my_first_app/widgets/license_manager.dart';
import 'package:my_first_app/widgets/user_manual_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  // Use it only after calling `hiddenWindowAtLaunch`
  windowManager.waitUntilReadyToShow().then((_) async {
    // Hide window title bar
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setSize(Size(800, 600));
    await windowManager.center();
    await windowManager.show();
    await windowManager.setSkipTaskbar(false);
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class AddEmployeeDialog extends StatefulWidget {
  const AddEmployeeDialog({super.key});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers live safely inside the State object
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _numberController = TextEditingController();
  final _remarksController = TextEditingController();
  String _selectedGender = 'Male';

  @override
  void dispose() {
    // Safely dispose when the widget is completely unmounted
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Employee"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Number'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 8),
              // StatefulBuilder is no longer needed! Use regular setState
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other']
                    .map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGender = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              Map<String, dynamic> employeeRow = {
                'name': _nameController.text,
                'address': _addressController.text,
                'email': _emailController.text,
                'number': _numberController.text,
                'gender': _selectedGender,
                'remarks': _remarksController.text,
              };

              try {
                await DatabaseHelper.instance.insertEmployee(employeeRow);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Employee added successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class EditEmployeeDialog extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EditEmployeeDialog({super.key, required this.employee});

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  // Late initialization allows us to grab data from the 'widget' property safely
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _numberController;
  late TextEditingController _remarksController;
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    // Pre-fill the controllers using the existing employee data passed into the widget
    _nameController = TextEditingController(
      text: widget.employee['name'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.employee['address'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.employee['email'] ?? '',
    );
    _numberController = TextEditingController(
      text: widget.employee['number'] ?? '',
    );
    _remarksController = TextEditingController(
      text: widget.employee['remarks'] ?? '',
    );
    _selectedGender = widget.employee['gender'] ?? 'Male';
  }

  @override
  void dispose() {
    // Completely safe execution because Flutter manages this widget lifecycle
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Employee"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Number'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other']
                    .map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGender = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                await DatabaseHelper.instance.updateEmployee({
                  'id': widget.employee['id'], // Grab original ID
                  'name': _nameController.text,
                  'address': _addressController.text,
                  'email': _emailController.text,
                  'number': _numberController.text,
                  'gender': _selectedGender,
                  'remarks': _remarksController.text,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Employee updated successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
                }
              }
            }
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedMenu = "Transaction";
  int hoveredIndex = 0;
  bool showPanel = false;
  Map<String, dynamic>? _selectedEmployee;
  String _searchQuery = "";

  final TextEditingController _activationKeyController =
      TextEditingController();

  bool _isTrialValid = true;
  bool _isCheckingLicense = true;

  final TextEditingController _bannerKeyController = TextEditingController();

  int _remainingDays = 7;
  bool _isPermanentlyUnlocked = false;

  @override
  void initState() {
    super.initState();
    _verifyAppLicense();
  }

  Future<void> _verifyAppLicense() async {
    // Fetches the structured class state payload from LicenseManager
    TrialState state = await LicenseManager.instance.checkLicenseStatus();
    setState(() {
      _isTrialValid = state.isValid;
      _remainingDays = state.remainingDays;
      _isPermanentlyUnlocked = state.isUnlocked;
      _isCheckingLicense = false;
    });
  }

  @override
  void dispose() {
    _activationKeyController.dispose();
    _bannerKeyController.dispose();
    super.dispose();
  }

  final Map<String, List<String>> menuItems = {
    "Transaction": ["Check Printing"],
    "Master": ["Employee", "Supplier/Payee", "Payment Type"],
    "Reports": ["Print Report"],
    "About": [],
    "Quit": [],
  };

  final List<Map<String, dynamic>> menus = [
    {"title": "Transaction", "icon": Icons.analytics_outlined},
    {"title": "Master", "icon": Icons.folder_open_outlined},
    {"title": "Reports", "icon": Icons.insert_chart_outlined_rounded},
    {"title": "About", "icon": Icons.help_outline_rounded},
    {"title": "Quit", "icon": Icons.power_settings_new_rounded},
  ];

  void _openSupplierListDialog() {
    showDialog(context: context, builder: (_) => const SupplierListDialog());
  }

  void _openPaymentListDialog() {
    showDialog(context: context, builder: (_) => const PaymentTypeListDialog());
  }

  void onHoverMenu(String title, int index) {
    setState(() {
      selectedMenu = title;
      hoveredIndex = index;
      showPanel = true;
    });
  }

  void _openCheckPrintingDialog() {
    showDialog(
      context: context,
      builder: (_) => const CheckPrintingListDialog(),
    );
  }

  void _openEmployeeListDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        const Color winBackground = Color(0xFFF0F0E8);
        const Color winHeaderStart = Color(0xFF99B4D1);
        const Color winHeaderEnd = Color(0xFFB4CBE2);
        const Color winGridHeader = Color(0xFFF3F3ED);
        const Color winBorder = Color(0xFF7A96DF);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Container(
                width: 1100,
                height: 650,
                decoration: BoxDecoration(
                  color: winBackground,
                  border: Border.all(color: winBorder, width: 3),
                ),
                child: Column(
                  children: [
                    // 1. WINDOW TITLE BAR
                    Container(
                      height: 30,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [winHeaderStart, winHeaderEnd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Employee List",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // 2. SEARCH UTILITY BAR
                    // 2. SEARCH UTILITY BAR
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Text(
                            "Search: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 250,
                            height: 24,
                            child: TextField(
                              // FIX: Handle search state updates inside the dialog
                              onChanged: (value) {
                                setDialogState(() {
                                  _searchQuery = value.trim().toLowerCase();
                                });
                              },
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                // Optional visual cue: Add a clear button if text is entered
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 12),
                                        onPressed: () {
                                          // This requires a TextEditingController if you want to clear the physical text,
                                          // but updating the variable is the core logic.
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 0,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.zero,
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. MAIN DATA GRID AREA
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                decoration: BoxDecoration(
                                  color: winGridHeader,
                                  border: Border(
                                    right: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),

                              Expanded(
                                child: StreamBuilder<List<Map<String, dynamic>>>(
                                  stream:
                                      DatabaseHelper.instance.employeeStream,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    // 1. Grab raw stream snapshot results
                                    final rawEmployees = snapshot.data ?? [];

                                    // 2. Safely filter elements dynamically based on search query
                                    final employees = rawEmployees.where((emp) {
                                      if (_searchQuery.isEmpty)
                                        return true; // Show everything if search box is empty

                                      final name = (emp['name'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                      final email = (emp['email'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                      final address = (emp['address'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                      final number = (emp['number'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                      final code = (emp['id'] ?? '')
                                          .toString()
                                          .toLowerCase();

                                      return name.contains(_searchQuery) ||
                                          email.contains(_searchQuery) ||
                                          address.contains(_searchQuery) ||
                                          number.contains(_searchQuery) ||
                                          code.contains(_searchQuery);
                                    }).toList();

                                    return SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Table(
                                        // 1. Force strict column distribution to fill 100% of horizontal space
                                        columnWidths: const {
                                          0: FlexColumnWidth(3), // Name
                                          1: FlexColumnWidth(3), // Email
                                          2: FlexColumnWidth(
                                            4.5,
                                          ), // Address (Widened for long strings)
                                          3: FlexColumnWidth(
                                            2.5,
                                          ), // Telephone No.
                                          4: FlexColumnWidth(
                                            1.5,
                                          ), // Gender (Narrow column)
                                          5: FlexColumnWidth(3.5), // Remarks
                                        },
                                        // 2. Implements your uniform clean retro gridlines
                                        border: TableBorder.all(
                                          color: Colors.grey.shade300,
                                          width: 0.5,
                                        ),
                                        children: [
                                          // HEADER ROW
                                          TableRow(
                                            decoration: BoxDecoration(
                                              color: winGridHeader,
                                            ),
                                            children: [
                                              _buildEmployeeHeaderCell("Name"),
                                              _buildEmployeeHeaderCell("Email"),
                                              _buildEmployeeHeaderCell(
                                                "Address",
                                              ),
                                              _buildEmployeeHeaderCell(
                                                "Telephone No.",
                                              ),
                                              _buildEmployeeHeaderCell(
                                                "Gender",
                                              ),
                                              _buildEmployeeHeaderCell(
                                                "Remarks",
                                              ),
                                            ],
                                          ),

                                          // DATA ROWS
                                          ...employees.map((emp) {
                                            final isSelected =
                                                _selectedEmployee?['id']
                                                    .toString() ==
                                                emp['id'].toString();

                                            // 3. Applies your smooth background selection highlight colors
                                            final rowColor = isSelected
                                                ? Colors.blue.withOpacity(0.3)
                                                : Colors.transparent;

                                            return TableRow(
                                              decoration: BoxDecoration(
                                                color: rowColor,
                                              ),
                                              children: [
                                                _buildEmployeeDataCell(
                                                  emp['name'] ?? '',
                                                  emp,
                                                  setDialogState,
                                                ),
                                                _buildEmployeeDataCell(
                                                  emp['email'] ?? '',
                                                  emp,
                                                  setDialogState,
                                                ),
                                                _buildEmployeeDataCell(
                                                  emp['address'] ?? '',
                                                  emp,
                                                  setDialogState,
                                                ),
                                                _buildEmployeeDataCell(
                                                  emp['number'] ?? '',
                                                  emp,
                                                  setDialogState,
                                                ),
                                                _buildEmployeeDataCell(
                                                  emp['gender'] ?? '',
                                                  emp,
                                                  setDialogState,
                                                ),
                                                _buildEmployeeDataCell(
                                                  emp['remarks'] ?? '',
                                                  emp,
                                                  setDialogState,
                                                ),
                                              ],
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // FIX: 4. ACTION BUTTONS FOOTER (Placed right below the Expanded grid container)
                    Container(
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          _buildWinButton(
                            "Add",
                            Icons.insert_drive_file_outlined,
                            onClick: () => _showAddEmployeeDialog(context),
                          ),
                          const SizedBox(width: 8),
                          _buildWinButton(
                            "Edit",
                            Icons.edit_note,
                            onClick: () {
                              if (_selectedEmployee == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please select an employee from the grid first.",
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              _showEditEmployeeDialog(
                                context,
                                _selectedEmployee!,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildWinButton(
                            "Delete",
                            Icons.delete_forever_outlined,
                            iconColor: Colors.red,
                            onClick: () {
                              if (_selectedEmployee == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please select an employee from the grid first.",
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              // Call our new dialog function
                              _showDeleteConfirmation(
                                context,
                                _selectedEmployee!,
                                () {
                                  // Clear selection state in the parent list modal instantly
                                  setDialogState(() {
                                    _selectedEmployee = null;
                                  });
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildWinButton(
                            "Close",
                            Icons.exit_to_app,
                            onClick: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddEmployeeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => const AddEmployeeDialog(),
    );
  }

  void _showEditEmployeeDialog(
    BuildContext context,
    Map<String, dynamic> employee,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) =>
          EditEmployeeDialog(employee: employee),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> employee,
    VoidCallback onDeleted,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text(
            "Confirm Delete",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to delete ${employee['name']}? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () async {
                // 1. Convert ID safely to an integer
                final int? empId = int.tryParse(employee['id'].toString());
                if (empId != null) {
                  // 2. Perform database removal
                  await DatabaseHelper.instance.deleteEmployee(empId);
                  // 3. Clear UI selection state
                  onDeleted();
                }
                // 4. Close the confirmation modal
                Navigator.pop(ctx);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmployeeHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmployeeDataCell(
    String text,
    Map<String, dynamic> emp,
    StateSetter setDialogState,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior
          .opaque, // Ensures clicking empty spatial boxes triggers selection
      onTap: () {
        setDialogState(() {
          _selectedEmployee = emp;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black),
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis, // Clean visual truncating for tight boxes
        ),
      ),
    );
  }

  // Reusable template widget for classic desktop buttons
  Widget _buildWinButton(
    String label,
    IconData icon, {
    Color? iconColor,
    VoidCallback? onClick,
  }) {
    return InkWell(
      onTap: onClick ?? () {},
      child: Container(
        width: 55,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0E8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.blue.shade800),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget menuButton(String title, IconData icon, int index) {
    final bool isSelected = selectedMenu == title;

    return MouseRegion(
      onEnter: (_) => onHoverMenu(title, index),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // <--- 1. WRAP WITH GESTURE DETECTOR
        onTap: () {
          // 2. CHECK FOR MAIN BUTTON CLICKS HERE DIRECTLY
          if (title == "Quit") {
            exit(
              0,
            ); // Closes the app instantly when the sidebar tab is clicked!
          }
          if (title == "About") {
            showDialog(
              context: context,
              builder: (context) =>
                  const UserManualDialog(), // 👈 Mounts the manual view overlay
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          height: 72,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 20,
                  bottom: 20,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ REMOVED WHITE BACKGROUND BOXES
  Widget subMenuBox(String title) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: 110,
        height: 74,
        decoration: BoxDecoration(
          // Uses transparent background and a soft gray border for layout structure
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (title == "Check Printing") {
                _openCheckPrintingDialog();
              } else if (title == "Employee") {
                _openEmployeeListDialog();
              } else if (title == "Supplier/Payee") {
                _openSupplierListDialog();
              } else if (title == "Payment Type") {
                _openPaymentListDialog();
              } else if (title == "Print Report") {
                // Open the new modern preview dialog
                showDialog(
                  context: context,
                  builder: (context) => const PreviewPrintingDialog(),
                );
              } else if (title == "Quit") {
                exit(0);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 20,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSubMenus = menuItems[selectedMenu] ?? [];

    if (_isCheckingLicense) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. MAIN SYSTEM DASHBOARD FRAME
          AbsorbPointer(
            absorbing: !_isTrialValid,
            child: Row(
              children: [
                // SIDEBAR
                Container(
                  width: 124,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 12,
                        offset: Offset(4, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      for (int i = 0; i < menus.length; i++)
                        menuButton(menus[i]["title"], menus[i]["icon"], i),
                    ],
                  ),
                ),

                // MAIN CONTENT CANVAS WITH DYNAMIC TOP BANNER
                // RIGHT CONTENT CONTAINER CANVAS
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: double
                        .infinity, // <-- Forces the column layout canvas to fill your window boundary exactly
                    color: const Color(0xFFF8FAFC),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .stretch, // <-- Forces children to stretch to the horizontal edges
                      children: [
                        // ACTUAL MAIN CONTAINER CANVAS SECTION
                        Expanded(
                          child: Container(
                            color: const Color(0xFFF8FAFC),
                            // Put your future main dashboard content or text panels inside here
                          ),
                        ),

                        // BANNER IS LOCKED AT THE REAR HORIZONTAL PLANE Boundaries
                        if (!_isPermanentlyUnlocked && _isTrialValid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              border: Border(
                                top: BorderSide(color: Colors.amber.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.amber.shade900,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text:
                                              "Evaluation Mode: Your free trial expires in ",
                                        ),
                                        TextSpan(
                                          text: "$_remainingDays days. ",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              "To unlock features permanently, call ",
                                        ),
                                        const TextSpan(
                                          text: "09178345848 ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: "for an activation key.",
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // INLINE QUICK REDEEM KEY INPUT FIELD
                                SizedBox(
                                  width: 180,
                                  height: 32,
                                  child: TextField(
                                    controller: _bannerKeyController,
                                    decoration: InputDecoration(
                                      hintText: "Enter Key Code",
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: Colors.amber.shade400,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: Colors.amber.shade400,
                                        ),
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade800,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 32),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  onPressed: () async {
                                    String key = _bannerKeyController.text
                                        .trim();
                                    bool success = await LicenseManager.instance
                                        .redeemActivationKey(key);
                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "System successfully activated!",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _bannerKeyController.clear();
                                      _verifyAppLicense();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Invalid or spent activation key!",
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    "Activate",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. CONTEXTUAL SUBMENU PANEL (Adjusted top positioning to account for banner height shifts)
          if (showPanel && currentSubMenus.isNotEmpty)
            Positioned(
              left: 140,
              top: 36 + (hoveredIndex * 82.5),
              child: AbsorbPointer(
                absorbing: !_isTrialValid,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: currentSubMenus.map(subMenuBox).toList(),
                ),
              ),
            ),

          // 🛑 UNESCAPABLE HARD TRIAL EXPIRATION SHIELD
          if (!_isTrialValid)
            Container(
              color: const Color(0xFF0F172A),
              child: Center(
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_clock_outlined,
                        size: 64,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Trial Period Expired",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Your 7-day free evaluation window has concluded. To safely unlock this system permanently and maintain your local database records, please enter your activation key.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _activationKeyController,
                        decoration: InputDecoration(
                          hintText: "Enter Activation Key (e.g. KEY-1234)",
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.shade400,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          String key = _activationKeyController.text.trim();
                          bool success = await LicenseManager.instance
                              .redeemActivationKey(key);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Success! App fully activated."),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _verifyAppLicense();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Invalid or already used key!"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: const Text("Activate System"),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.blueAccent,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Please contact: 09178345848",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => exit(0),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text("Exit Application"),
                      ),
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
