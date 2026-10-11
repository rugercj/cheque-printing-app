import 'package:flutter/material.dart';
import '../database_helper.dart';

class SupplierListDialog extends StatefulWidget {
  const SupplierListDialog({super.key});

  @override
  State<SupplierListDialog> createState() => _SupplierListDialogState();
}

class AddEditSupplierDialog extends StatefulWidget {
  final Map<String, dynamic>? supplier; // Pass this if you are editing

  const AddEditSupplierDialog({super.key, this.supplier});

  @override
  State<AddEditSupplierDialog> createState() => _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends State<AddEditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool get isEditMode => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.supplier!['name'] ?? '';
      _addressController.text = widget.supplier!['address'] ?? '';
      _phoneController.text = widget.supplier!['telephoneno'] ?? '';
      _remarksController.text = widget.supplier!['remarks'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    // Explicitly typing as Map<String, dynamic> solves the layout crash
    final Map<String, dynamic> row = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'telephoneno': _phoneController.text.trim(),
      'remarks': _remarksController.text.trim(),
    };

    if (isEditMode) {
      // Now safety casting or directly applying an int here works perfectly!
      row['id'] = widget.supplier!['id'];
      await DatabaseHelper.instance.updateSupplier(row);
    } else {
      await DatabaseHelper.instance.insertSupplier(row);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 500,
        height: 380,
        color: const Color(0xFFF0F0F0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Window Header Bar
              Container(
                height: 30,
                color: const Color(0xFF99B4D1),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditMode ? "Edit Supplier" : "Add New Supplier",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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

              // Form Input Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildFormRow(
                        "Name *:",
                        _nameController,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),
                      _buildFormRow(
                        "Address *:",
                        _addressController,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),
                      _buildFormRow("Telephone:", _phoneController),
                      const SizedBox(height: 12),
                      _buildFormRow(
                        "Remarks / Contact:",
                        _remarksController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons Bottom Bar
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFE1E1E1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildFormButton("Save", _saveSupplier),
                    const SizedBox(width: 8),
                    _buildFormButton("Cancel", () => Navigator.pop(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormRow(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              fillColor: Colors.white,
              filled: true,
              errorStyle: TextStyle(
                height: 0,
              ), // Suppresses expanded error text heights
            ),
            validator: isRequired
                ? (value) => (value == null || value.trim().isEmpty) ? '' : null
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFormButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 80,
      height: 28,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F0F0),
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade500),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _SupplierListDialogState extends State<SupplierListDialog> {
  Map<String, dynamic>? selectedSupplier;
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ), // Sharp desktop window edges
      child: Container(
        width: 1100,
        height: 650,
        color: const Color(0xFFF0F0F0), // Classic light gray window background
        child: Column(
          children: [
            // Window Header Bar
            Container(
              height: 30,
              color: const Color(0xFF99B4D1),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Supplier List",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

            // Search Bar Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text(
                    "Search: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 350,
                    height: 28,
                    child: TextField(
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Table Section matching the grid style
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                width: double.infinity,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: DatabaseHelper.instance.supplierStream,
                  builder: (context, snapshot) {
                    final suppliers = (snapshot.data ?? []).where((supplier) {
                      if (searchQuery.isEmpty) return true;

                      // Safely extract and format every field to downcase text
                      final String id = (supplier['id'] ?? '')
                          .toString()
                          .toLowerCase();
                      final String name = (supplier['name'] ?? '')
                          .toString()
                          .toLowerCase();
                      final String address = (supplier['address'] ?? '')
                          .toString()
                          .toLowerCase();
                      final String phone = (supplier['telephoneno'] ?? '')
                          .toString()
                          .toLowerCase();
                      final String remarks = (supplier['remarks'] ?? '')
                          .toString()
                          .toLowerCase();

                      // Return true if the query matches ANY of the columns
                      return id.contains(searchQuery) ||
                          name.contains(searchQuery) ||
                          address.contains(searchQuery) ||
                          phone.contains(searchQuery) ||
                          remarks.contains(searchQuery);
                    }).toList();

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        // Column 0 is now 'Name'. We redistributed the layout percentages.
                        columnWidths: const {
                          0: FlexColumnWidth(3), // Name
                          1: FlexColumnWidth(
                            4.5,
                          ), // Address (widened to consume extra space)
                          2: FlexColumnWidth(2.5), // Telephone No.
                          3: FlexColumnWidth(3), // Contact
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        children: [
                          // HEADER ROW (Removed Code column)
                          TableRow(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5),
                            ),
                            children: [
                              _buildTableHeaderCell("Name"),
                              _buildTableHeaderCell("Address"),
                              _buildTableHeaderCell("Telephone No."),
                              _buildTableHeaderCell("Contact"),
                            ],
                          ),

                          // DATA ROWS (Removed Code/ID cells)
                          ...suppliers.map((supplier) {
                            final isSelected =
                                selectedSupplier?['id'] == supplier['id'];
                            final rowColor = isSelected
                                ? const Color(0xFF3399FF)
                                : Colors.transparent;
                            final textStyle = TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 13,
                            );

                            return TableRow(
                              decoration: BoxDecoration(color: rowColor),
                              children: [
                                _buildTableCell(
                                  supplier['name'] ?? '',
                                  textStyle,
                                  supplier,
                                ),
                                _buildTableCell(
                                  supplier['address'] ?? '',
                                  textStyle,
                                  supplier,
                                ),
                                _buildTableCell(
                                  supplier['telephoneno'] ?? '',
                                  textStyle,
                                  supplier,
                                ),
                                _buildTableCell(
                                  supplier['remarks'] ?? '',
                                  textStyle,
                                  supplier,
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
            ),

            // Bottom Control Action Bar matching layout
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.start, // Aligns buttons to bottom-left
                children: [
                  _buildDesktopButton(
                    Icons.insert_drive_file_outlined,
                    "Add",
                    () {
                      // Open dialog with no supplier data passed (isEditMode will be false)
                      showDialog(
                        context: context,
                        builder: (context) => const AddEditSupplierDialog(),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildDesktopButton(Icons.edit_note, "Edit", () {
                    // Verify a row item is selected first before modifying
                    if (selectedSupplier != null) {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            AddEditSupplierDialog(supplier: selectedSupplier),
                      );
                    } else {
                      // Optional: Provide visual feedback if no row is highlighted
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a supplier to edit.'),
                        ),
                      );
                    }
                  }),
                  const SizedBox(width: 6),
                  _buildDesktopButton(
                    Icons.delete_forever_outlined,
                    "Delete",
                    () {
                      if (selectedSupplier != null) {
                        _showDeleteConfirmation(context, selectedSupplier!, () {
                          setState(() {
                            selectedSupplier =
                                null; // Clears row highlights upon successful delete
                          });
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select a supplier to delete.',
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(width: 6),
                  _buildDesktopButton(
                    Icons.exit_to_app,
                    "Close",
                    () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> supplier,
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
            "Are you sure you want to delete ${supplier['name']}? This action cannot be undone.",
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black, fontSize: 13),
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
                final int? supplierId = int.tryParse(supplier['id'].toString());
                if (supplierId != null) {
                  // 2. Perform database removal
                  await DatabaseHelper.instance.deleteSupplier(supplierId);
                  // 3. Clear UI selection state via callback
                  onDeleted();
                }
                // 4. Close the confirmation modal
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Delete", style: TextStyle(fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildTableCell(
    String text,
    TextStyle style,
    Map<String, dynamic> supplier,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior
          .opaque, // Ensures clicking transparent areas registers
      onTap: () {
        setState(() {
          selectedSupplier = supplier;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          text,
          style: style,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis, // Prevents text breaks on long strings
        ),
      ),
    );
  }

  // Visual helper function to build the square desktop-style buttons seen in your screenshot
  Widget _buildDesktopButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 75,
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFE1E1E1),
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade400),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade900),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
