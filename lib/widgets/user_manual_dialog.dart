import 'package:flutter/material.dart';

class UserManualDialog extends StatefulWidget {
  const UserManualDialog({super.key});

  @override
  State<UserManualDialog> createState() => _UserManualDialogState();
}

class _UserManualDialogState extends State<UserManualDialog> {
  // Tracks which chapter is currently clicked and viewed
  String _selectedChapter = "1. Getting Started";

  // Define our retro theme palette to match your existing modal dialogs
  final Color winBackground = const Color(0xFFF0F0E8);
  final Color winHeaderStart = const Color(0xFF99B4D1);
  final Color winHeaderEnd = const Color(0xFFB4CBE2);
  final Color winGridHeader = const Color(0xFFF3F3ED);
  final Color winBorder = const Color(0xFF7A96DF);

  // Chapter content map containing step-by-step documentation data
  final Map<String, List<String>> _manualContent = {
    "1. Getting Started": [
      "Welcome to the Check Printing Management System!",
      "• Launching the App: Upon launching, the application operates on a 7-Day Free Evaluation Trial.",
      "• Free Trial Status: Monitor your remaining trial days via the dark banner at the bottom of your workspace screen.",
      "• Permanent Unlock: To purchase a full license and activate the system forever, call our desk directly at 09178345848 or 09359460625. Once you enter your secret Activation Key, the bottom banner will self-hide automatically.",
    ],
    "2. Managing Masters List": [
      "Save time by entering repetitive data once into the central secure database structures:",
      "• Navigation: Hover over the 'Master' category on the left sidebar to reveal its hidden contextual panel.",
      "• Data Types: Choose from 'Employee', 'Supplier/Payee', or 'Payment Type' submenus.",
      "• CRUD Controls: Click 'Add' to register a new profile. Use 'Edit' or 'Delete' after highlights. The system auto-populates these entries directly into your check drafting dropdown options to eliminate typing mistakes!",
    ],
    "3. Check Printing Log": [
      "Draft, review, log, and process system transactions effortlessly:",
      "• Access: Open the 'Transaction' sidebar choice and click the 'Check Printing' option box.",
      "• Form Entry: Provide the voucher date, payee name, amount, and specific item remarks.",
      "• Automation Matrix: The application automatically converts raw numeric balances into financial currency wording text strings instantly (e.g., ₱300,000.00 outputs as 'THREE HUNDRED THOUSAND PESOS ONLY ***').",
    ],
    "4. Printer Calibration": [
      "Ensure pixel-perfect positioning across any physical office hardware check leaves:",
      "• Alignment: Open the Layout Calibration tools under your printing layout panel.",
      "• Coordinates: Adjust 'Horizontal Offset (X)' and 'Vertical Offset (Y)' values in points to fine-tune alignments left, right, up, or down.",
      "• Multi-Print Execution: Choose between printing raw 'Check' layouts or executing 'Voucher Layouts' to bundle physical accounting distribution slips alongside your check documents.",
    ],
    "5. Financial Reports": [
      "Extract structured ledgers for quick audits using role-based access configurations:",
      "• User-Level Reports: Extract standard dynamic 'Daily Transactions Summaries' across flexible time blocks.",
      "• Management Reports: Switch to the security-restricted 'Management (Boss Only)' tier to review comprehensive ledger matrices across selected fiscal years.",
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 1000,
        height: 600,
        decoration: BoxDecoration(
          color: winBackground,
          border: Border.all(color: winBorder, width: 3),
        ),
        child: Column(
          children: [
            // 1. WINDOW TITLE BAR
            Container(
              height: 32,
              decoration: BoxDecoration(
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
                  const Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "System Operations User Manual & Guide",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.black,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 2. MAIN INTERACTIVE CONTENT CANVAS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT SIDEBAR: CHAPTER LIST SELECTIONS
                    Container(
                      width: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: ListView(
                        children: _manualContent.keys.map((String key) {
                          final bool isSelected = _selectedChapter == key;
                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: const Color(
                              0xFF3B82F6,
                            ).withOpacity(0.15),
                            title: Text(
                              key,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF1D4ED8)
                                    : Colors.black87,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedChapter = key;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // RIGHT PANEL: CONTENT VIEWER
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedChapter,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const Divider(thickness: 1, height: 24),
                              ..._manualContent[_selectedChapter]!.map((text) {
                                final bool isBullet = text.startsWith('•');
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 12.0,
                                    left: isBullet ? 12.0 : 0.0,
                                  ),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: isBullet
                                          ? Colors.black87
                                          : Colors.black,
                                      fontWeight: isBullet
                                          ? FontWeight.w400
                                          : FontWeight.w500,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. BOTTOM FOOTER BAR
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: winGridHeader,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        size: 16,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Technical Desk Walkthrough Support: 09178345848 / 09359460625",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: const Text(
                      "Close Guide",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
