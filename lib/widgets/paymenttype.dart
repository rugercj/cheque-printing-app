import 'package:flutter/material.dart';
import '../database_helper.dart';

class AddEditPaymentTypeDialog extends StatefulWidget {
  final Map<String, dynamic>? paymentType;

  const AddEditPaymentTypeDialog({super.key, this.paymentType});

  @override
  State<AddEditPaymentTypeDialog> createState() =>
      _AddEditPaymentTypeDialogState();
}

class _AddEditPaymentTypeDialogState extends State<AddEditPaymentTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _typeController = TextEditingController();

  bool get isEditMode => widget.paymentType != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _typeController.text = widget.paymentType!['type_name'] ?? '';
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  void _savePaymentType() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> row = {'type_name': _typeController.text.trim()};

    if (isEditMode) {
      row['id'] = widget.paymentType!['id'];
      await DatabaseHelper.instance.updatePaymentType(row);
    } else {
      await DatabaseHelper.instance.insertPaymentType(row);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 450,
        height: 180,
        color: const Color(0xFFF0F0F0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Title Bar
              Container(
                height: 30,
                color: const Color(0xFF99B4D1),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditMode ? "Edit Payment Type" : "Add Payment Type",
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
              // Body Input Space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 110,
                        child: Text(
                          "Payment Type *:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _typeController,
                          style: const TextStyle(fontSize: 13),
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
                            errorStyle: TextStyle(height: 0),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? '' : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFE1E1E1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildFormButton("Save", _savePaymentType),
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

  Widget _buildFormButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 80,
      height: 24,
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

class PaymentTypeListDialog extends StatefulWidget {
  const PaymentTypeListDialog({super.key});

  @override
  State<PaymentTypeListDialog> createState() => _PaymentTypeListDialogState();
}

class _PaymentTypeListDialogState extends State<PaymentTypeListDialog> {
  Map<String, dynamic>? selectedPayment;
  String searchQuery = "";

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> payment,
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
            "Are you sure you want to delete '${payment['type_name']}'? This action cannot be undone.",
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
                final int? id = int.tryParse(payment['id'].toString());
                if (id != null) {
                  await DatabaseHelper.instance.deletePaymentType(id);
                  onDeleted();
                }
                Navigator.pop(ctx);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width:
            600, // Slightly narrower since there is only one layout field column
        height: 500,
        color: const Color(0xFFF0F0F0),
        child: Column(
          children: [
            // Top Window Header Bar
            Container(
              height: 30,
              color: const Color(0xFF99B4D1),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Payment Method Configuration",
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

            // Search Ribbon
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
                    width: 300,
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
                      onChanged: (val) => setState(
                        () => searchQuery = val.trim().toLowerCase(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Full Width Table Box Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                width: double.infinity,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: DatabaseHelper.instance.paymentTypeStream,
                  builder: (context, snapshot) {
                    final items = (snapshot.data ?? []).where((p) {
                      if (searchQuery.isEmpty) return true;
                      return (p['type_name'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery);
                    }).toList();

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(
                            1,
                          ), // Auto-stretches 100% across the container panel box
                        },
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5),
                            ),
                            children: [
                              _buildHeaderCell("Payment Option / Method Type"),
                            ],
                          ),
                          ...items.map((payment) {
                            final isSelected =
                                selectedPayment?['id'] == payment['id'];
                            return TableRow(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF3399FF)
                                    : Colors.transparent,
                              ),
                              children: [
                                _buildDataCell(
                                  payment['type_name'] ?? '',
                                  TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 13,
                                  ),
                                  payment,
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

            // Base Desktop Action Buttons Panel
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildDesktopButton(
                    Icons.insert_drive_file_outlined,
                    "Add",
                    () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddEditPaymentTypeDialog(),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildDesktopButton(Icons.edit_note, "Edit", () {
                    if (selectedPayment != null) {
                      showDialog(
                        context: context,
                        builder: (context) => AddEditPaymentTypeDialog(
                          paymentType: selectedPayment,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select an item to modify.'),
                        ),
                      );
                    }
                  }),
                  const SizedBox(width: 6),
                  _buildDesktopButton(
                    Icons.delete_forever_outlined,
                    "Delete",
                    () {
                      if (selectedPayment != null) {
                        _showDeleteConfirmation(context, selectedPayment!, () {
                          setState(() => selectedPayment = null);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select an item to delete.'),
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

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildDataCell(
    String text,
    TextStyle style,
    Map<String, dynamic> payment,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => selectedPayment = payment),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          text,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

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
