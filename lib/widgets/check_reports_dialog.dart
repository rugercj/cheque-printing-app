// SECTION 1: IMPORTS & ASYNC DATA FETCHING STATE
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure intl package is in your pubspec.yaml for date parsing
import '../database_helper.dart'; // Adjust this import path to match your project structure

class ReportPreviewScreen extends StatefulWidget {
  final String reportTitle;
  final String fromDate; // Passed in format MM/DD/YYYY
  final String toDate; // Passed in format MM/DD/YYYY

  const ReportPreviewScreen({
    super.key,
    required this.reportTitle,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  List<Map<String, dynamic>> _filteredChecks = [];
  bool _isLoading = true;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchAndFilterReportData();
  }

  Future<void> _fetchAndFilterReportData() async {
    try {
      // 1. Fetch raw rows directly from your checks table schema
      final List<Map<String, dynamic>> allChecks = await DatabaseHelper.instance
          .queryAllChecks();

      // 2. Setup parsing format rules matching your UI string parameters
      DateFormat uiFormat = DateFormat("MM/DD/yyyy");
      DateTime filterStart = uiFormat.parse(widget.fromDate);
      DateTime filterEnd = uiFormat.parse(widget.toDate);

      List<Map<String, dynamic>> temporaryList = [];
      double runningTotal = 0.0;

      for (var check in allChecks) {
        String rawDateStr = check['check_date'] ?? '';
        if (rawDateStr.isEmpty) continue;

        DateTime checkDate;
        try {
          // Supports both common DB storage conventions (ISO-8601 or MM/DD/YYYY text patterns)
          if (rawDateStr.contains('-')) {
            checkDate = DateTime.parse(rawDateStr);
          } else {
            checkDate = uiFormat.parse(rawDateStr);
          }
        } catch (_) {
          continue; // Skips formatting error anomalies safely
        }

        // 3. Keep rows that fall precisely within the selected date range
        // Normalize time elements so only year/month/day bounds match
        DateTime cleanCheck = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
        );
        DateTime cleanStart = DateTime(
          filterStart.year,
          filterStart.month,
          filterStart.day,
        );
        DateTime cleanEnd = DateTime(
          filterEnd.year,
          filterEnd.month,
          filterEnd.day,
        );

        if ((cleanCheck.isAfter(cleanStart) ||
                cleanCheck.isAtSameMomentAs(cleanStart)) &&
            (cleanCheck.isBefore(cleanEnd) ||
                cleanCheck.isAtSameMomentAs(cleanEnd))) {
          temporaryList.add(check);

          // Calculate cumulative summation
          double amount = double.tryParse(check['amount'].toString()) ?? 0.0;
          runningTotal += amount;
        }
      }

      if (mounted) {
        setState(() {
          _filteredChecks = temporaryList;
          _totalAmount = runningTotal;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error generating check report: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // SECTION 2: TOP APPBAR TOOLBAR & SCAFFOLD FRAME
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF64748B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Text(
          "Print Preview - ${widget.reportTitle}",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 20),
            onPressed: () {},
          ),
          const VerticalDivider(
            color: Colors.white24,
            indent: 12,
            endIndent: 12,
          ),
          IconButton(
            icon: const Icon(Icons.print, size: 20, color: Colors.blueAccent),
            onPressed: () {},
            tooltip: "Send to Physical Printer",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                child: Container(
                  width: 850,
                  constraints: const BoxConstraints(minHeight: 550),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildDocumentContent(),
                ),
              ),
            ),
    );
  }

  // SECTION 3: TEXT METADATA HEADERS AND DATA TABLE ROWS
  Widget _buildDocumentContent() {
    // Number formatting formatter for accounting decimals
    final currencyFormatter = NumberFormat("₱#,##0.00", "en_US");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              const Text(
                "CHECK PRINTING SYSTEM",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.reportTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Period Covered: ${widget.fromDate}  To: ${widget.toDate}",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const Text(
              "Page: 1 of 1",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.2), // Date
            1: FlexColumnWidth(4.5), // Payee Name
            2: FlexColumnWidth(2), // Check No
            3: FlexColumnWidth(2.5), // Bank Name
            4: FlexColumnWidth(1.3), // Cleared Indicator
            5: FlexColumnWidth(3.2), // Amount String
          },
          border: const TableBorder(
            top: BorderSide(color: Color(0xFF0F172A), width: 1.5),
            bottom: BorderSide(color: Color(0xFF0F172A), width: 1.5),
            horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
          ),
          children: [
            // TABLE COLUMN GRID SYSTEM HEADERS
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _buildDocHeaderCell("Date"),
                _buildDocHeaderCell("Payee"),
                _buildDocHeaderCell("Check No."),
                _buildDocHeaderCell("Bank Name"),
                _buildDocHeaderCell("Cleared"),
                _buildDocHeaderCell("Amount", alignRight: true),
              ],
            ),

            // MAP REAL RECORD DATABASE ELEMENTS DYNAMICALLY
            ..._filteredChecks.map((check) {
              double parsedAmount =
                  double.tryParse(check['amount'].toString()) ?? 0.0;

              // Handle your database boolean standard mapping integer values (1 = Yes, 0 = No)
              String clearedStatus =
                  (check['is_cleared'] == 1 || check['is_cleared'] == true)
                  ? "Yes"
                  : "No";

              return TableRow(
                children: [
                  _buildDocDataCell(check['check_date']?.toString() ?? ''),
                  _buildDocDataCell(check['payee_name']?.toString() ?? ''),
                  _buildDocDataCell(check['check_no']?.toString() ?? '-'),
                  _buildDocDataCell(check['bank_name']?.toString() ?? '-'),
                  _buildDocDataCell(clearedStatus),
                  _buildDocDataCell(
                    currencyFormatter.format(parsedAmount),
                    alignRight: true,
                  ),
                ],
              );
            }),
          ],
        ),

        // Fallback display panel if array matches no results
        if (_filteredChecks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: const Text(
              "No check transactions found matching the selected date ranges.",
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        // SECTION 4: BOOKKEEPING LEDGER SUMMARY CALCULATION
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Total:  ",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text(
                          currencyFormatter.format(_totalAmount),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 170,
                    height: 2,
                    color: const Color(
                      0xFF0F172A,
                    ), // Modern clean double balance underline accent
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocHeaderCell(String label, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildDocDataCell(String value, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        value,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF334155),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
