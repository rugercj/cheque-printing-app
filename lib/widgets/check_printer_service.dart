import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CheckPrinterService {
  // 8 inches x 3 inches converted to PDF points (1 inch = 72 points)
  static const double checkWidth = 8.0 * 72; // 576 points
  static const double checkHeight = 3.0 * 72; // 216 points

  // Standard Letter page dimensions in PDF points (8.5 x 11 inches)
  static const double voucherWidth = 8.5 * 72; // 612 points
  static const double voucherHeight = 11.0 * 72; // 792 points

  /// Utility engine to convert a numeric amount into English Words format for PH checks
  static String convertNumberToWords(double amount) {
    if (amount == 0) return "ZERO PESOS ONLY";

    final List<String> units = [
      "",
      "ONE",
      "TWO",
      "THREE",
      "FOUR",
      "FIVE",
      "SIX",
      "SEVEN",
      "EIGHT",
      "NINE",
    ];
    final List<String> teens = [
      "TEN",
      "ELEVEN",
      "TWELVE",
      "THIRTEEN",
      "FOURTEEN",
      "FIFTEEN",
      "SIXTEEN",
      "SEVENTEEN",
      "EIGHTEEN",
      "NINETEEN",
    ];
    final List<String> tens = [
      "",
      "",
      "TWENTY",
      "THIRTY",
      "FORTY",
      "FIFTY",
      "SIXTY",
      "SEVENTY",
      "EIGHTY",
      "NINETY",
    ];

    String convertLessThanOneThousand(int number) {
      String current = "";
      if (number >= 100) {
        current += "${units[number ~/ 100]} HUNDRED ";
        number %= 100;
      }
      if (number >= 10 && number <= 19) {
        current += "${teens[number - 10]} ";
      } else {
        if (number >= 20) {
          current += "${tens[number ~/ 10]} ";
          number %= 10;
        }
        if (number > 0) {
          current += "${units[number]} ";
        }
      }
      return current;
    }

    int pesoAmount = amount.toInt();
    int centavoAmount = ((amount - pesoAmount) * 100).round();

    String result = "";

    // Millions handler
    if (pesoAmount >= 1000000) {
      int millions = pesoAmount ~/ 1000000;
      result += "${convertLessThanOneThousand(millions)}MILLION ";
      pesoAmount %= 1000000;
    }

    // Thousands handler
    if (pesoAmount >= 1000) {
      int thousands = pesoAmount ~/ 1000;
      result += "${convertLessThanOneThousand(thousands)}THOUSAND ";
      pesoAmount %= 1000;
    }

    result += convertLessThanOneThousand(pesoAmount);

    if (result.trim().isEmpty) {
      result = "ZERO ";
    }

    result += "PESOS";

    // Standard Philippines check syntax for decimal cents tracking
    if (centavoAmount > 0) {
      result += " AND ${centavoAmount.toString().padLeft(2, '0')}/100";
    }

    return "${result.trim().replaceAll(RegExp(r'\s+'), ' ')} ONLY";
  }

  /// Helper layout generator to construct separated digit items for boxed date sheets
  static pw.Widget _buildBoxedDateRow(String rawDateText) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(rawDateText);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    // Split components into standardized Month, Day, Year format tokens
    String mm = parsedDate.month.toString().padLeft(2, '0');
    String dd = parsedDate.day.toString().padLeft(2, '0');
    String yyyy = parsedDate.year.toString().padLeft(4, '0');

    // Combine down into an exact MMDDYYYY sequence (8 elements total)
    String dateSequence = "$mm$dd$yyyy";
    List<String> digits = dateSequence.split('');

    // Pitch distance layout setup (approx. 14.5 points matches standard PH check boxes)
    const double singleDigitCellWidth = 14.5;

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: digits.map((digit) {
        return pw.Container(
          width: singleDigitCellWidth,
          alignment: pw.Alignment.center,
          child: pw.Text(
            digit,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              // Fixed-width courier font safeguards character pitch boundaries
              font: pw.Font.courierBold(),
            ),
          ),
        );
      }).toList(),
    );
  }

  static Future<Uint8List> generatePhilippineCheck({
    required String date,
    required String payee,
    required double amount,
    required String amountInWords,
    required bool isAcPayee,
    double offsetX = 0.0,
    double offsetY = 0.0,
  }) async {
    final pdf = pw.Document();

    // --- NEW: Load a true font to support rendering the custom ₱ Unicode symbol ---
    final ttfFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          checkWidth,
          checkHeight,
          marginTop: 0,
          marginBottom: 0,
          marginLeft: 0,
          marginRight: 0,
        ),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // 1. Crossing / "A/C PAYEE ONLY"
              if (isAcPayee)
                pw.Positioned(
                  left: 20 + offsetX,
                  top: 20 + offsetY,
                  child: pw.Transform.rotate(
                    angle: -0.1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      child: pw.Text(
                        'A/C PAYEE ONLY',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. Boxed Date field in Month-Day-Year (MMDDYYYY) Format
              pw.Positioned(
                left: 415 + offsetX,
                top: 24 + offsetY,
                child: _buildBoxedDateRow(date),
              ),

              // 3. Payee / "PAY TO THE ORDER OF"
              pw.Positioned(
                left: 90 + offsetX,
                top: 65 + offsetY,
                child: pw.Text(
                  payee.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              // 4. Numeric Amount
              pw.Positioned(
                right: 35 - offsetX,
                top: 65 + offsetY,
                child: pw.Builder(
                  builder: (pw.Context context) {
                    final String rawAmountStr = amount.toStringAsFixed(2);
                    List<String> parts = rawAmountStr.split('.');
                    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
                    parts[0] = parts[0].replaceAllMapped(
                      reg,
                      (Match match) => '${match[1]},',
                    );
                    final String formattedAmount = parts.join('.');

                    return pw.Text(
                      '₱ **$formattedAmount**', // <-- Displays as: ₱ **400,000.00**
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        font:
                            ttfFont, // <-- CRITICAL: Forces layout to render the loaded font
                      ),
                    );
                  },
                ),
              ),

              // 5. Amount in Words
              pw.Positioned(
                left: 50 + offsetX,
                top: 95 + offsetY,
                child: pw.Text(
                  '$amountInWords ***',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a clean corporate Document Layout for Check Vouchers
  static Future<Uint8List> generateCheckVoucher({
    required Map<String, dynamic> checkData,
    required double amount,
    required String amountInWords,
  }) async {
    final pdf = pw.Document();

    final String payee = (checkData['payee_name'] ?? '')
        .toString()
        .toUpperCase();
    final String dateStr = (checkData['check_date'] ?? '').toString();
    final String cvNo = (checkData['cv_no'] ?? '4').toString();
    final String checkNo = (checkData['check_no'] ?? '').toString();
    final String bankName = (checkData['bank_name'] ?? '').toString();
    // Formatter fallback helper for thousand currency structures
    final RegExp regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

    final pw.Font unicodeFontBold = await PdfGoogleFonts.robotoBold();

    String formatCurrency(double value) {
      String fixed = value.toStringAsFixed(2);
      List<String> parts = fixed.split('.');
      parts[0] = parts[0].replaceAllMapped(regex, (Match m) => '${m[1]},');
      return parts.join('.');
    }

    final String formattedAmount = formatCurrency(amount);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Category Tracker Band
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'CHECK PRINTING ENGINE',
                    style: pw.TextStyle(
                      fontSize: 9,
                      font: pw.Font.helvetica(),
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'DOCUMENT CLASSIFICATION: ACCOUNTS PAYABLE',
                    style: pw.TextStyle(
                      fontSize: 9,
                      font: pw.Font.helvetica(),
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 16),
              // Document Accent Title Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'CHECK VOUCHER',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CV No.: $cvNo',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Date: $dateStr',
                        style: pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              // Information Metadata Block Box
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Column(
                  children: [
                    // Payee Row
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 60,
                            child: pw.Text(
                              'PAYEE:',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              payee,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Divider(
                      height: 1,
                      thickness: 0.5,
                      color: PdfColors.grey300,
                    ),
                    // Particulars & Amount Grid System
                    // Particulars & Amount Grid System using a Table for matching heights
                    pw.Table(
                      border: const pw.TableBorder(
                        verticalInside: pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 0.5,
                        ),
                      ),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(), // Takes remaining horizontal space
                        1: pw.FixedColumnWidth(
                          140,
                        ), // Set exact width for Amount column
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            // Particulars Box Left Side
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'PARTICULARS',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                  pw.SizedBox(height: 6),
                                  pw.Text(
                                    (checkData['particular'] ??
                                            'Payment settlement transaction details.')
                                        .toString(),
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Amount Box Right Side
                            // Amount Box Right Side
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    'AMOUNT',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                  pw.SizedBox(height: 6),
                                  // Displays the actual ₱ sign alongside the formatted numbers using the loaded Unicode font
                                  pw.Text(
                                    '₱ $formattedAmount',
                                    style: pw.TextStyle(
                                      font: unicodeFontBold,
                                      fontSize: 13,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              pw.SizedBox(height: 24),
              // Distribution of Accounts Split Ledger section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Side Ledger: Accounts Table
                  pw.Expanded(
                    flex: 11,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Distribution of Account',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Table(
                          border: pw.TableBorder.all(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                          columnWidths: const {
                            0: pw.FlexColumnWidth(5),
                            1: pw.FlexColumnWidth(2),
                            2: pw.FlexColumnWidth(2),
                          },
                          children: [
                            // Table Header Array Row
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.grey100,
                              ),
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(6),
                                  child: pw.Text(
                                    'ACCOUNT TITLE',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(6),
                                  child: pw.Text(
                                    'DEBIT',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(6),
                                  child: pw.Text(
                                    'CREDIT',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            // Data Rows Placeholders matching physical print card structures
                            for (int i = 0; i < 4; i++)
                              pw.TableRow(
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(12),
                                    child: pw.Text(''),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(12),
                                    child: pw.Text(''),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(12),
                                    child: pw.Text(''),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Right Side Ledger: Legal Text and Tracking Elements
                  pw.Expanded(
                    flex: 9,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AMOUNT IN WORDS',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '***$amountInWords***',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.SizedBox(height: 24),

                        // Bank Tracking Meta
                        pw.Row(
                          children: [
                            pw.Text(
                              'Bank: ',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              bankName,
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Check No.: ',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(checkNo, style: pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 16),
                        // Acknowledgment Receipt Line
                        pw.Text(
                          'Received By:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 28),
                        pw.Container(height: 0.5, color: PdfColors.black),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Signature over Printed Name / Date',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              // Section 3: Bottom Verification Workflow Autographs Band
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Prepared By:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 35),
                        pw.Container(height: 0.5, color: PdfColors.grey400),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 24),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Certified Correct By:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 35),
                        pw.Container(height: 0.5, color: PdfColors.grey400),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 24),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Approved By:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 35),
                        pw.Container(height: 0.5, color: PdfColors.grey400),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Launches the interactive print preview modal
  static Future<void> previewCheck(
    pw.Context context,
    Uint8List pdfBytes,
  ) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Check_Print_Job',
    );
  }
}
