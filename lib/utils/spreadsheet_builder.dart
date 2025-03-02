// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';

Future<void> generateSpreadsheetReport(List<Map<String, dynamic>> data, String userName, String userRole, List<DateTime?> datePeriod) async {
  final timestampFile = DateFormat('dd.MM.yyyy_HH-mm-ss').format(DateTime.now());

  // Handle optional dates
  final String timestampPeriodStart = datePeriod.isNotEmpty && datePeriod[0] != null
      ? DateFormat('dd/MM/yyyy').format(datePeriod[0]!)
      : 'Todo';
  final String timestampPeriodEnd = datePeriod.length > 1 && datePeriod[1] != null
      ? ' - ${DateFormat("dd/MM/yyyy").format(datePeriod[1]!)}'
      : '';

  final String timestamp = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

  // Create CSV content
  List<List<dynamic>> csvData = [
    ['Usuario', 'Fecha/Hora', 'Periodo Seleccionado'],
    ['$userName ($userRole)', timestamp, '$timestampPeriodStart $timestampPeriodEnd'],
    [],
    ['No.', 'Registrador Cedula', 'Registrador Login', 'Registrador Nombre', 'Supervisor Login', 'Supervisor Nombre', 'Numero de Fincas', 'Total Area (Tareas)'],
  ];

  for (int i = 0; i < data.length; i++) {
    final row = data[i];
    csvData.add([
      (i + 1), // Row number
      row['registrador_cedula'] ?? 'N/A',
      row['registrador'] ?? 'N/A',
      row['registrador_nombre'] ?? 'N/A',
      row['supervisor'] ?? 'N/A',
      row['supervisor_nombre'] ?? 'N/A',
      row['total_parcelas']?.toString() ?? 'N/A',
      row['total_area']?.toString() ?? 'N/A',
    ]);
  }

  String csv = const ListToCsvConverter().convert(csvData);

  // Create CSV file and trigger download
  final blob = html.Blob([csv], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  // ignore: unused_local_variable
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'reporte_actividad_$timestampFile.csv')
    ..click();
  html.Url.revokeObjectUrl(url);
}
