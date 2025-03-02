import 'package:flutter/material.dart';

class ActividadTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String searchQuery;
  final VoidCallback onEstadoUpdated;
  final String userRole;

  const ActividadTable({
    super.key,
    required this.data,
    required this.searchQuery,
    required this.onEstadoUpdated,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    // Get the size of the viewport
    final size = MediaQuery.of(context).size;
    final ScrollController scrollControllerVertical = ScrollController();
    final ScrollController scrollControllerHorizontal = ScrollController();
    
    // Calculate the height to use for the table based on other UI elements
    final tableHeight = size.height - 230;

    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      controller: scrollControllerHorizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: scrollControllerHorizontal,
        child: Column(
          children: [
            SizedBox(
              height: tableHeight,
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                scrollbarOrientation: ScrollbarOrientation.left,
                controller: scrollControllerVertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  controller: scrollControllerVertical,
                  child: DataTable(
                    columnSpacing: 60,
                    dataRowMaxHeight: 53,
                    headingRowHeight: 50,
                    headingRowColor: MaterialStateColor.resolveWith((states) => const Color.fromARGB(64, 26, 43, 86)),
                    columns: const [
                      DataColumn(label: SizedBox(width: 73, child: Text('Registrador Cedula', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 73, child: Text('Registrador Login', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 73, child: Text('Registrador Nombre', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 68, child: Text('Supervisor Login', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 100, child: Text('Supervisor Nombre', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 70, child: Text('Numero de Fincas', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 68, child: Text('Total Area (Tareas)', softWrap: true,))),
                    ],
                    rows: data.asMap().entries.map<DataRow>((entry) {
                      int index = entry.key;
                      Map<String, dynamic> entity = entry.value;
                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            return index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                          },
                        ),
                        cells: <DataCell>[
                          DataCell(RichText(text: _highlightMatch(entity['registrador_cedula'] ?? 'N/A', searchQuery))),
                          DataCell(Text(entity['registrador'] ?? 'N/A')),
                          DataCell(Text(entity['registrador_nombre'] ?? 'N/A', softWrap: true,)),
                          DataCell(Text(entity['supervisor'] ?? 'N/A')),
                          DataCell(Text(entity['supervisor_nombre'] ?? 'N/A', softWrap: true,)),
                          DataCell(Text(entity['total_parcelas'].toString(), softWrap: true,)),
                          DataCell(Text(entity['total_area'].toString(), softWrap: true,)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _highlightMatch(String text, String pattern) {
    if (pattern.isEmpty) return TextSpan(text: text);
    final String lowerText = text.toLowerCase();
    final String lowerPattern = pattern.toLowerCase();
    final int patternLength = pattern.length;

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight = lowerText.indexOf(lowerPattern);

    while (indexOfHighlight != -1) {
        if (indexOfHighlight > start) {
            spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
        }
        spans.add(TextSpan(
            text: text.substring(indexOfHighlight, indexOfHighlight + patternLength),
            style: const TextStyle(backgroundColor: Colors.yellow),
        ));
        start = indexOfHighlight + patternLength;
        indexOfHighlight = lowerText.indexOf(lowerPattern, start);
    }
    if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start)));
    }
    return TextSpan(children: spans);
  }
}
