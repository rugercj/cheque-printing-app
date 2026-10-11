import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../widgets/check_printer_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AddEditCheckDialog extends StatefulWidget {
  final Map<String, dynamic>? checkRecord;
  const AddEditCheckDialog({super.key, this.checkRecord});

  @override
  State<AddEditCheckDialog> createState() => _AddEditCheckDialogState();
}

class _AddEditCheckDialogState extends State<AddEditCheckDialog> {
  final _formKey = GlobalKey<FormState>();

  // Existing Controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _payeeController =
      TextEditingController(); // Maps to "Supplier"
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _typeController =
      TextEditingController(); // Payment Type
  final TextEditingController _noController =
      TextEditingController(); // Check No

  // NEW CONTROLLERS & STATES FROM THE IMAGE
  final TextEditingController _particularController = TextEditingController();
  final TextEditingController _cvNoController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  bool _isAcPayee = false; // "AC Payee" checkbox status

  bool get isEditMode => widget.checkRecord != null;
  // ADD THIS LINE HERE TO FIX THE DEFINITION ERROR:

  // Add this with your other controllers
  final FocusNode _amountFocusNode = FocusNode();

  // Selection states for your database mapping
  String? _selectedSupplier;
  String? _selectedPaymentType;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      // Load existing fields
      _dateController.text = widget.checkRecord!['check_date'] ?? '';
      _payeeController.text = widget.checkRecord!['payee_name'] ?? '';
      _typeController.text = widget.checkRecord!['payment_type'] ?? '';
      _noController.text = widget.checkRecord!['check_no'] ?? '';
      _particularController.text = widget.checkRecord!['particular'] ?? '';
      _cvNoController.text = widget.checkRecord!['cv_no'] ?? '';
      _bankController.text = widget.checkRecord!['bank_name'] ?? '';
      _isAcPayee = widget.checkRecord!['is_ac_payee'] == 1;

      _selectedSupplier = widget.checkRecord!['payee_name'];
      _selectedPaymentType = widget.checkRecord!['payment_type'];

      // Format initial loaded database amount with commas safely
      final initialAmount = widget.checkRecord!['amount']?.toString() ?? '';
      final parsedAmount = double.tryParse(initialAmount);
      if (parsedAmount != null) {
        List<String> parts = parsedAmount.toStringAsFixed(2).split('.');
        RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
        parts[0] = parts[0].replaceAllMapped(
          reg,
          (Match match) => '${match[1]},',
        );
        _amountController.text = parts.join('.');
      } else {
        _amountController.text = "0.00";
      }
    } else {
      // RESTORED: Default fallbacks for adding a brand new check entry
      _dateController.text = DateTime.now().toString().substring(0, 10);
      _amountController.text = "0.00";
      _cvNoController.text = "";
      _payeeController.text = '';
      _particularController.text = '';
      _bankController.text = '';
      _typeController.text = '';
      _noController.text = '';
      _isAcPayee = false;
    }

    // Comma formatting listener on focus loss
    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus) {
        final text = _amountController.text.trim().replaceAll(',', '');
        final value = double.tryParse(text);
        if (value != null) {
          List<String> parts = value.toStringAsFixed(2).split('.');
          RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
          parts[0] = parts[0].replaceAllMapped(
            reg,
            (Match match) => '${match[1]},',
          );
          setState(() {
            _amountController.text = parts.join('.');
          });
        } else if (text.isEmpty) {
          setState(() {
            _amountController.text = "0.00";
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    // Call dispose on your controllers here if you haven't already
    super.dispose();
  }

  /// Launch configuration management profile offset window dialog framework

  void _saveCheck() async {
    if (!_formKey.currentState!.validate()) return;

    // Combined original map parameters + new inputs
    // Combined original map parameters + new inputs
    final Map<String, dynamic> row = {
      'check_date': _dateController.text.trim(),
      'payee_name': _selectedSupplier?.trim() ?? '',
      // FIX: Strip commas before parsing into database numerical double
      'amount':
          double.tryParse(_amountController.text.trim().replaceAll(',', '')) ??
          0.0,

      'payment_type': _selectedPaymentType?.trim() ?? '',
      'check_no': _noController.text.trim(),
      'particular': _particularController.text.trim(),
      'cv_no': _cvNoController.text.trim(),
      'bank_name': _bankController.text.trim(),
      'is_ac_payee': _isAcPayee ? 1 : 0,
    };

    if (isEditMode) {
      row['id'] = widget.checkRecord!['id'];
      await DatabaseHelper.instance.updateCheck(row);
    } else {
      await DatabaseHelper.instance.insertCheck(row);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width:
            650, // FIX 1: Increased from 500 to 650 to prevent button squishing
        height:
            650, // FIX 2: Height extended slightly to fit vertical padding safely
        color: const Color(0xFFF0F0F0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(
                isEditMode ? "Edit Check Record" : "Add Check Entry",
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListView(
                    children: [
                      // Date field row helper (Top line without a text label in the image)
                      _buildRow("Date", _dateController),
                      const SizedBox(height: 10),
                      // FIXED: Explicitly separated and structured Amount Input field row
                      _buildRow(
                        "Amount (\₱):",
                        _amountController,
                        isRequired: true,
                        focusNode: _amountFocusNode,
                      ),
                      const SizedBox(height: 10),

                      // --- UPDATED: SUPPLIER DROPDOWN (STREAM FED) ---
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: DatabaseHelper.instance.supplierStream,
                        builder: (context, snapshot) {
                          final list = snapshot.data ?? [];
                          final items = list
                              .map((e) => e['name'].toString())
                              .toList();

                          if (_selectedSupplier != null &&
                              !items.contains(_selectedSupplier)) {
                            items.add(_selectedSupplier!);
                          }

                          return _buildDropdownRow(
                            "Supplier *:",
                            value: _selectedSupplier,
                            items: items,
                            isRequired: true,
                            onChanged: (val) =>
                                setState(() => _selectedSupplier = val),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const SizedBox(
                            width: 130,
                            child: Text(
                              "AC Payee:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: _isAcPayee,
                            onChanged: (val) =>
                                setState(() => _isAcPayee = val ?? false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _buildRow(
                        "Particular:",
                        _particularController,
                        isMultiline: true,
                      ),
                      const SizedBox(height: 10),
                      _buildRow("CV No.:", _cvNoController),
                      const SizedBox(height: 10),
                      _buildRow("Bank:", _bankController),
                      const SizedBox(height: 10),

                      // --- UPDATED: PAYMENT TYPE DROPDOWN (STREAM FED) ---
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: DatabaseHelper.instance.paymentTypeStream,
                        builder: (context, snapshot) {
                          final list = snapshot.data ?? [];
                          final items = list
                              .map((e) => e['type_name'].toString())
                              .toList();

                          if (_selectedPaymentType != null &&
                              !items.contains(_selectedPaymentType)) {
                            items.add(_selectedPaymentType!);
                          }

                          return _buildDropdownRow(
                            "Payment Type:",
                            value: _selectedPaymentType,
                            items: items,
                            onChanged: (val) =>
                                setState(() => _selectedPaymentType = val),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildRow("Check No:", _noController),
                    ],
                  ),
                ),
              ),
              _buildBottomActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownRow(
    String label, {
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 32, // Preserves matching row spacing
            child: DropdownButtonFormField<String>(
              value: value,
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13, color: Colors.black),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 0,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                fillColor: Colors.white,
                filled: true,
                errorStyle: TextStyle(height: 0),
              ),
              validator: isRequired
                  ? (v) => (v == null || v.trim().isEmpty) ? '' : null
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      height: 30,
      color: const Color(0xFF99B4D1),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Modified helper row builder to dynamically handle regular inputs vs large multiline comment boxes
  Widget _buildRow(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    bool isMultiline = false,
    FocusNode? focusNode, // Added this named parameter
  }) {
    return Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          child: Padding(
            padding: EdgeInsets.only(top: isMultiline ? 6.0 : 0),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            focusNode: focusNode, // Wired the focus node up here
            maxLines: isMultiline ? 3 : 1,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              fillColor: Colors.white,
              filled: true,
              errorStyle: TextStyle(height: 0),
            ),
            validator: isRequired
                ? (v) => (v == null || v.trim().isEmpty) ? '' : null
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFE1E1E1),
      child: Row(
        children: [
          // Core Action Controls left behind
          _buildFormBtn("Save", _saveCheck),
          const SizedBox(width: 4),
          _buildFormBtn("Cancel", () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildFormBtn(String label, VoidCallback action) {
    return SizedBox(
      width: 65, // Slightly narrowed to leave room for the printer bar
      height: 42, // Height matches the printer panel layout nicely
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F0F0),
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade500),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: EdgeInsets.zero,
        ),
        onPressed: action,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Interactive Radio row builder for state toggling
}

class CheckPrintingListDialog extends StatefulWidget {
  const CheckPrintingListDialog({super.key});

  @override
  State<CheckPrintingListDialog> createState() =>
      _CheckPrintingListDialogState();
}

class _CheckPrintingListDialogState extends State<CheckPrintingListDialog> {
  Map<String, dynamic>? selectedCheck;
  String searchQuery = "";
  bool _isPrinterSetupMode = false;

  double _calculateTotal(List<Map<String, dynamic>> checkList) {
    return checkList.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 1100,
        height: 650,
        color: const Color(0xFFF0F0F0),
        child: Column(
          children: [
            // Window Title Header
            _buildWindowHeader("Check Printing Log"),

            // Query Filter Bar
            _buildSearchSection(),

            // Scaled Column Table Box
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                width: double.infinity,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: DatabaseHelper.instance.checkStream,
                  builder: (context, snapshot) {
                    final allChecks = snapshot.data ?? [];
                    final filteredChecks = allChecks.where((c) {
                      if (searchQuery.isEmpty) return true;
                      final payee = (c['payee_name'] ?? '')
                          .toString()
                          .toLowerCase();
                      final checkNo = (c['check_no'] ?? '')
                          .toString()
                          .toLowerCase();
                      final bank = (c['bank_name'] ?? '')
                          .toString()
                          .toLowerCase();
                      return payee.contains(searchQuery) ||
                          checkNo.contains(searchQuery) ||
                          bank.contains(searchQuery);
                    }).toList();

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Table(
                              // NEW COLUMN WIDTH RATIOS: Redistributed weights for the new fields
                              columnWidths: const {
                                0: FlexColumnWidth(1.8), // Date
                                1: FlexColumnWidth(
                                  3.5,
                                ), // Payee / Supplier Name
                                2: FlexColumnWidth(1.8), // Amount
                                3: FlexColumnWidth(1.2), // Cleared Check Status
                                4: FlexColumnWidth(3.0), // Particular
                                5: FlexColumnWidth(1.2), // CV No
                                6: FlexColumnWidth(2.0), // Bank
                                7: FlexColumnWidth(2.0), // Payment Type
                                8: FlexColumnWidth(1.8), // Check No
                              },
                              border: TableBorder.all(
                                color: Colors.grey.shade300,
                                width: 0.5,
                              ),
                              children: [
                                // 1. TABLE HEADERS (Updated with new cells)
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                  ),
                                  children: [
                                    _buildHeaderCell("Date"),
                                    _buildHeaderCell("Payee / Supplier"),
                                    _buildHeaderCell("Amount"),
                                    _buildHeaderCell("Cleared"),
                                    _buildHeaderCell(
                                      "Particular",
                                    ), // NEW HEADER
                                    _buildHeaderCell("CV No"), // NEW HEADER
                                    _buildHeaderCell("Bank"), // NEW HEADER
                                    _buildHeaderCell("Pay Type"),
                                    _buildHeaderCell("Check No."),
                                  ],
                                ),

                                // 2. DYNAMIC TABLE DATA ROWS
                                ...filteredChecks.map((check) {
                                  final isSelected =
                                      selectedCheck?['id'] == check['id'];
                                  final rowColor = isSelected
                                      ? const Color(0xFF3399FF)
                                      : Colors.transparent;
                                  final style = TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 13,
                                  );

                                  return TableRow(
                                    decoration: BoxDecoration(color: rowColor),
                                    children: [
                                      _buildDataCell(
                                        check['check_date'] ?? '',
                                        style,
                                        check,
                                      ),
                                      _buildDataCell(
                                        check['payee_name'] ?? '',
                                        style,
                                        check,
                                      ),
                                      // REPLACE your old currency amount cell row with this:
                                      // REPLACE your amount data cell row with this clean string logic:
                                      _buildDataCell(
                                        () {
                                          final double rowAmt =
                                              double.tryParse(
                                                (check['amount'] ?? 0.0)
                                                    .toString(),
                                              ) ??
                                              0.0;
                                          final String amtRawStr = rowAmt
                                              .toStringAsFixed(2);
                                          List<String> parts = amtRawStr.split(
                                            '.',
                                          );
                                          RegExp reg = RegExp(
                                            r'(\d{1,3})(?=(\d{3})+(?!\d))',
                                          );
                                          parts[0] = parts[0].replaceAllMapped(
                                            reg,
                                            (Match match) => '${match[1]},',
                                          );
                                          return "₱${parts.join('.')}"; // Displays perfectly as: ₱400,000.00
                                        }(),
                                        style,
                                        check,
                                      ),

                                      _buildCheckmarkCell(
                                        check['is_cleared'] == 1,
                                        isSelected,
                                        check,
                                      ),

                                      // NEW ROWS VISIBLE IN THE MAIN APPLICATION
                                      _buildDataCell(
                                        check['particular'] ?? '',
                                        style,
                                        check,
                                      ),
                                      _buildDataCell(
                                        check['cv_no'] ?? '',
                                        style,
                                        check,
                                      ),
                                      _buildDataCell(
                                        check['bank_name'] ?? '',
                                        style,
                                        check,
                                      ),

                                      _buildDataCell(
                                        check['payment_type'] ?? '',
                                        style,
                                        check,
                                      ),
                                      _buildDataCell(
                                        check['check_no'] ?? '',
                                        style,
                                        check,
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        // Aggregate Bottom Ledger Total Bar
                        _buildTotalSummaryFooter(
                          _calculateTotal(filteredChecks),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Base Execution Buttons
            _buildControlActionBar(),
          ],
        ),
      ),
    );
  }

  void _openPrinterSetupDialog() async {
    final prefs = await SharedPreferences.getInstance();
    double savedOffsetX = prefs.getDouble('opt1_offset_x') ?? 0.0;
    double savedOffsetY = prefs.getDouble('opt1_offset_y') ?? 0.0;

    final TextEditingController setupXController = TextEditingController(
      text: savedOffsetX.toStringAsFixed(1),
    );
    final TextEditingController setupYController = TextEditingController(
      text: savedOffsetY.toStringAsFixed(1),
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (setupContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF0F0F0),
              title: const Text(
                "Printer Layout Calibration",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 700,
                height: 450,
                child: Row(
                  children: [
                    Container(
                      width: 220,
                      padding: const EdgeInsets.all(8),
                      color: const Color(0xFFE1E1E1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Fine-Tune Alignments (Points)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Positive shifts right/down. Negative shifts left/up.",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Horizontal Offset (X):",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextField(
                            controller: setupXController,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              isDense: true,
                              contentPadding: EdgeInsets.all(6),
                            ),
                            onChanged: (val) {
                              setDialogState(() {
                                savedOffsetX = double.tryParse(val) ?? 0.0;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Vertical Offset (Y):",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextField(
                            controller: setupYController,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              isDense: true,
                              contentPadding: EdgeInsets.all(6),
                            ),
                            onChanged: (val) {
                              setDialogState(() {
                                savedOffsetY = double.tryParse(val) ?? 0.0;
                              });
                            },
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(),
                              ),
                              onPressed: () async {
                                await prefs.setDouble(
                                  'opt1_offset_x',
                                  savedOffsetX,
                                );
                                await prefs.setDouble(
                                  'opt1_offset_y',
                                  savedOffsetY,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Printer settings updated successfully!",
                                      ),
                                    ),
                                  );
                                  Navigator.pop(setupContext);
                                }
                              },
                              child: const Text("Save Calibration"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PdfPreview(
                        build: (format) =>
                            CheckPrinterService.generatePhilippineCheck(
                              date:
                                  selectedCheck?['check_date'] ?? "2026-06-21",
                              payee:
                                  selectedCheck?['payee_name'] ??
                                  "SAMPLE SUPPLIER PROFILE COMPANY",
                              amount:
                                  double.tryParse(
                                    selectedCheck?['amount']?.toString() ?? '',
                                  ) ??
                                  7500.00,
                              amountInWords:
                                  CheckPrinterService.convertNumberToWords(
                                    double.tryParse(
                                          selectedCheck?['amount']
                                                  ?.toString() ??
                                              '',
                                        ) ??
                                        7500.00,
                                  ),
                              isAcPayee: selectedCheck?['is_ac_payee'] == 1,
                              offsetX: savedOffsetX,
                              offsetY: savedOffsetY,
                            ),
                        initialPageFormat: const PdfPageFormat(
                          CheckPrinterService.checkWidth,
                          CheckPrinterService.checkHeight,
                        ),
                        allowPrinting: true,
                        allowSharing: false,
                        canChangePageFormat: false,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(setupContext),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWindowHeader(String text) {
    return Container(
      height: 30,
      color: const Color(0xFF99B4D1),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text(
            "Search Payee/Check No: ",
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
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (val) =>
                  setState(() => searchQuery = val.trim().toLowerCase()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );

  Widget _buildDataCell(
    String text,
    TextStyle style,
    Map<String, dynamic> check,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => selectedCheck = check),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCheckmarkCell(
    bool isChecked,
    bool isSelected,
    Map<String, dynamic> check,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        // 1. Instantly highlight the row visually
        setState(() => selectedCheck = check);

        // 2. Prepare a map copy with the inverted clear status
        final Map<String, dynamic> updatedRow = Map.from(check);
        updatedRow['is_cleared'] = isChecked
            ? 0
            : 1; // Toggles 1 to 0 or 0 to 1

        // 3. Persist the change directly to the database helper
        await DatabaseHelper.instance.updateCheck(updatedRow);

        // 4. Update local selection instance to match the new database record
        setState(() {
          selectedCheck = updatedRow;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Icon(
          isChecked ? Icons.check_box_outlined : Icons.check_box_outline_blank,
          size: 18,
          color: isSelected
              ? Colors.white
              : Colors.blue.shade900, // Slightly darkened for better clarity
        ),
      ),
    );
  }

  Widget _buildTotalSummaryFooter(double finalSum) {
    // Formats the number with commas and 2 decimal places automatically
    final formattedSum = NumberFormat('#,##0.00', 'en_PH').format(finalSum);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border(top: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            "Total Balance Dynamic Amount: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "₱$formattedSum", // Displays: ₱1,000,000,000.00
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioRow(String label, bool targetMode) {
    final isSelected = (_isPrinterSetupMode == targetMode);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isPrinterSetupMode = targetMode),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 13,
              color: Colors.blue.shade900,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintActionBtn(String text, VoidCallback? onPressed) {
    return Container(
      width: 78,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF99B4D1),
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade500),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildReportOptionBtn(String text) {
    return Container(
      width: 78,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF99B4D1),
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade500),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: EdgeInsets.zero,
        ),
        onPressed: () {}, // Voucher layout handle goes here
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildControlActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildActionBtn(
            Icons.insert_drive_file_outlined,
            "Add",
            () => showDialog(
              context: context,
              builder: (context) => const AddEditCheckDialog(),
            ),
          ),
          const SizedBox(width: 6),
          _buildActionBtn(Icons.edit_note, "Edit", () {
            if (selectedCheck != null) {
              showDialog(
                context: context,
                builder: (context) =>
                    AddEditCheckDialog(checkRecord: selectedCheck),
              );
            }
          }),
          const SizedBox(width: 6),
          _buildActionBtn(Icons.delete_forever_outlined, "Delete", () async {
            if (selectedCheck != null) {
              await DatabaseHelper.instance.deleteCheck(selectedCheck!['id']);
              setState(() => selectedCheck = null);
            }
          }),

          // --- EMBEDDED CHECK PRINTING OPTIONS PANEL (MOVED HERE) ---
          const SizedBox(width: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(
                0xFFFFFFE0,
              ), // Light yellow tint matching image
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Radio Option Selector Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRadioRow("Preview", false),
                    _buildRadioRow("Printer Setup", true),
                  ],
                ),
                const SizedBox(width: 8),

                // Option 1 & Voucher layout selection buttons
                _buildPrintActionBtn("Option 1\n(Portrait)", () async {
                  if (!_isPrinterSetupMode) {
                    // --- PREVIEW MODE ---
                    if (selectedCheck == null) return;
                    final currentAmount =
                        double.tryParse(
                          (selectedCheck!['amount'] ?? 0.0).toString(),
                        ) ??
                        0.0;
                    final wordsText = CheckPrinterService.convertNumberToWords(
                      currentAmount,
                    );

                    // Fetch saved settings beforehand so standard previews also respect calibrated adjustments
                    final prefs = await SharedPreferences.getInstance();
                    double savedX = prefs.getDouble('opt1_offset_x') ?? 0.0;
                    double savedY = prefs.getDouble('opt1_offset_y') ?? 0.0;

                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: const Color(0xFFF0F0F0),
                        title: const Text(
                          "Cheque Preview",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: SizedBox(
                          width: 600,
                          height: 300,
                          child: PdfPreview(
                            build: (format) =>
                                CheckPrinterService.generatePhilippineCheck(
                                  date: selectedCheck!['check_date'] ?? '',
                                  payee: selectedCheck!['payee_name'] ?? '',
                                  amount: currentAmount,
                                  amountInWords: wordsText,
                                  isAcPayee: selectedCheck!['is_ac_payee'] == 1,
                                  offsetX:
                                      savedX, // Standard preview now honors alignment fixes!
                                  offsetY: savedY,
                                ),
                            initialPageFormat: const PdfPageFormat(
                              CheckPrinterService.checkWidth,
                              CheckPrinterService.checkHeight,
                            ),
                            allowPrinting: true,
                            allowSharing: false,
                            canChangePageFormat: false,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              "Close",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // --- PRINTER SETUP MODE ---
                    _openPrinterSetupDialog();
                  }
                }),
                const SizedBox(width: 3),
                // Wrap button inside functional interaction click detectors
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (selectedCheck == null) return;

                    final currentAmount =
                        double.tryParse(
                          (selectedCheck!['amount'] ?? 0.0).toString(),
                        ) ??
                        0.0;

                    final wordsText = CheckPrinterService.convertNumberToWords(
                      currentAmount,
                    );

                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: const Color(0xFFF0F0F0),
                        title: const Text(
                          "Check Voucher Document Preview",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: SizedBox(
                          width: 650,
                          height: 500,
                          child: PdfPreview(
                            build: (format) =>
                                CheckPrinterService.generateCheckVoucher(
                                  checkData: selectedCheck!,
                                  amount: currentAmount,
                                  amountInWords: wordsText,
                                ),
                            initialPageFormat: PdfPageFormat.letter,
                            allowPrinting: true,
                            allowSharing: true,
                            canChangePageFormat: false,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              "Close",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: AbsorbPointer(child: _buildReportOptionBtn("Voucher")),
                ),
              ],
            ),
          ),

          const Spacer(), // Automatically pushes the Close button to the far right end
          // --- CLOSE ACTION ---
          _buildActionBtn(
            Icons.exit_to_app,
            "Close",
            () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback tap) {
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
        onPressed: tap,
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
