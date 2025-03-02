// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

Future<void> printDocument(List<Map<String, dynamic>> data, String userName, String userRole, List<DateTime?> datePeriod) async {
  final pdf = pw.Document();
  final timestampFile = DateFormat('dd.MM.yyyy_HH-mm-ss').format(DateTime.now());
  final timestampPdf = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

  // Handle optional dates
  final String timestampPeriodStart = datePeriod.isNotEmpty && datePeriod[0] != null
      ? DateFormat('dd/MM/yyyy').format(datePeriod[0]!)
      : 'Todo';
  final String timestampPeriodEnd = datePeriod.length > 1 && datePeriod[1] != null
      ? ' - ${DateFormat("dd/MM/yyyy").format(datePeriod[1]!)}'
      : '';

  const int rowsPerPage = 30; // Adjust based on your needs
  final int totalPages = (data.length / rowsPerPage).ceil();

  for (int page = 0; page < totalPages; page++) {
    final start = page * rowsPerPage;
    final end = start + rowsPerPage;
    final pageData = data.sublist(start, end < data.length ? end : data.length);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Usuario: ',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.TextSpan(
                          text: '$userName ($userRole)',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Periodo Seleccionado: ',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.TextSpan(
                          text: timestampPeriodStart,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.TextSpan(
                          text: timestampPeriodEnd,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Fecha/Hora: ',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.TextSpan(
                          text: timestampPdf,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Reporte de Actividad',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: [
                  'No.',
                  'Registrador Cedula',
                  'Registrador Login',
                  'Registrador Nombre',
                  'Supervisor Login',
                  'Supervisor Nombre',
                  'Numero de Fincas',
                  'Total Area (Tareas)'
                ],
                data: pageData.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> row = entry.value;
                  return [
                    start + index + 1, // Row number
                    row['registrador_cedula'] ?? 'N/A',
                    row['registrador'] ?? 'N/A',
                    row['registrador_nombre'] ?? 'N/A',
                    row['supervisor'] ?? 'N/A',
                    row['supervisor_nombre'] ?? 'N/A',
                    row['total_parcelas']?.toString() ?? 'N/A',
                    row['total_area']?.toString() ?? 'N/A',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xff1d3b6f),
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 8,
                ),
                cellHeight: 20,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerLeft,
                  6: pw.Alignment.centerLeft,
                  7: pw.Alignment.centerLeft,
                },
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FixedColumnWidth(70),
                  2: const pw.FixedColumnWidth(70),
                  3: const pw.FixedColumnWidth(100),
                  4: const pw.FixedColumnWidth(70),
                  5: const pw.FixedColumnWidth(100),
                  6: const pw.FixedColumnWidth(70),
                  7: const pw.FixedColumnWidth(70),
                },
              ),
              pw.Spacer(),
              pw.Text(
                'Página ${page + 1} de $totalPages',
                style: const pw.TextStyle(
                  fontSize: 9,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  final bytes = await pdf.save();
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  // ignore: unused_local_variable
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'reporte_actividad_$timestampFile.pdf')
    ..click();
  html.Url.revokeObjectUrl(url);
}
