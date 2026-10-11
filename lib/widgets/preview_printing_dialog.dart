// SECTION 1: IMPORTS & STATE INITIALIZATION
import 'package:flutter/material.dart';
import '../widgets/check_reports_dialog.dart';

class PreviewPrintingDialog extends StatefulWidget {
  const PreviewPrintingDialog({super.key});

  @override
  State<PreviewPrintingDialog> createState() => _PreviewPrintingDialogState();
}

class _PreviewPrintingDialogState extends State<PreviewPrintingDialog> {
  String _destination = "Preview";
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  // NEW HELPER: LAUNCH CALENDAR FOR "FROM" DATE
  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020), // Earliest selectable year
      lastDate: DateTime(2035), // Latest selectable year
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  // NEW HELPER: LAUNCH CALENDAR FOR "TO" DATE
  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  // SECTION 2: DIALOG CONTAINER FRAME & TAB CONTROLLER
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 780,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Preview / Printing Reports",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Select an access clearance level to filter available sheets.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                // UPDATE IN SECTION 2: ADD THE ONTAP PROPERTY TO TABBAR
                child: TabBar(
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelColor: const Color(0xFF1E293B),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // FIX: Track tab index switches
                  onTap: (index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                  tabs: const [
                    Tab(text: "User Level Reports"),
                    Tab(text: "Management (Boss Only)"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // SECTION 3: TAB VIEWS HUB & DIALOG ACTION BUTTONS
              SizedBox(
                height: 380,
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildReportConfigurationContent(
                      "DAILY TRANSACTIONS SUMMARY",
                    ),
                    _buildReportConfigurationContent(
                      "CHECKS ISSUED (COMPREHENSIVE PERIOD)",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // UPDATE IN SECTION 3: IMPLEMENT THE OKAY BUTTON SUBMIT LOGIC
                  ElevatedButton(
                    onPressed: () {
                      // 1. Determine which report type name to use based on the tab index
                      String reportType = _currentTabIndex == 0
                          ? "DAILY TRANSACTIONS SUMMARY"
                          : "CHECKS ISSUED (COMPREHENSIVE PERIOD)";

                      // 2. Format the DateTime parameters cleanly into string dates
                      String formattedFrom =
                          "${_fromDate.month.toString().padLeft(2, '0')}/${_fromDate.day.toString().padLeft(2, '0')}/${_fromDate.year}";
                      String formattedTo =
                          "${_toDate.month.toString().padLeft(2, '0')}/${_toDate.day.toString().padLeft(2, '0')}/${_toDate.year}";

                      // 3. Print debug telemetry tracking to the console logs
                      debugPrint("Running Action Target: $_destination");
                      debugPrint("Report Type Selected: $reportType");
                      debugPrint(
                        "Date Filters: $formattedFrom to $formattedTo",
                      );

                      // 4. Dismiss the options modal prompt overlay frame first
                      Navigator.pop(context);

                      // 5. Handle route targeting based on selected destination parameters
                      if (_destination == "Preview") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportPreviewScreen(
                              reportTitle: reportType,
                              fromDate: formattedFrom,
                              toDate: formattedTo,
                            ),
                          ),
                        );
                      } else {
                        // Provide immediate feedback if sending directly to print hardware
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Opening $reportType in $_destination mode...',
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.teal.shade700,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.shade400,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Okay",
                      style: TextStyle(fontWeight: FontWeight.w600),
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

  // SECTION 4: CONTEXT CONFIGURATION CONTENT PANEL
  // UPDATED SECTION 4: REMOVED DROPDOWN FROM THE LAYOUT PANEL
  Widget _buildReportConfigurationContent(String reportTitleKey) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  reportTitleKey,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildSectionCard(
                  title: "Destination",
                  child: Column(
                    children: [
                      _buildRadioRow("Preview", Icons.picture_as_pdf_outlined),
                      const SizedBox(height: 8),
                      _buildRadioRow("Printer", Icons.print_outlined),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: _buildSectionCard(
                  title: "Period Covered",
                  child: Column(
                    children: [
                      _buildInlineDateInput(
                        prefix: "From:",
                        dateVal:
                            "${_fromDate.month.toString().padLeft(2, '0')}/${_fromDate.day.toString().padLeft(2, '0')}/${_fromDate.year}",
                        onTap: () => _selectFromDate(context),
                      ),
                      const SizedBox(height: 10),
                      _buildInlineDateInput(
                        prefix: "To:",
                        dateVal:
                            "${_toDate.month.toString().padLeft(2, '0')}/${_toDate.day.toString().padLeft(2, '0')}/${_toDate.year}",
                        onTap: () => _selectToDate(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SECTION 5: MODULAR UI HELPER ATOMS
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioRow(String label, IconData icon) {
    final bool isSelected = _destination == label;
    return InkWell(
      onTap: () => setState(() => _destination = label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blueAccent.shade100 : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.blueAccent : const Color(0xFF94A3B8),
              size: 18,
            ),
            const SizedBox(width: 10),
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.blueAccent : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.blueAccent.shade700
                    : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATE IN SECTION 5: MODULAR DATE WIDGET WITH TAP LISTENER
  Widget _buildInlineDateInput({
    required String prefix,
    required String dateVal,
    required VoidCallback onTap, // Added explicit click hook parameter
  }) {
    return Row(
      children: [
        SizedBox(
          width: 45,
          child: Text(
            prefix,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: onTap, // Triggers our system calendar builder framework
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateVal,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
