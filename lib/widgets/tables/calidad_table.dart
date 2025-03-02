import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:renagro1/widgets/widgets.dart';
import 'package:renagro1/services/calidad_service.dart';

class CalidadTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String searchQuery;
  final CalidadService _calidadService = CalidadService();
  final VoidCallback onEstadoUpdated;
  final String userRole;

  CalidadTable({
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
                    dataRowMaxHeight: 100,
                    headingRowHeight: 50,
                    headingRowColor: MaterialStateColor.resolveWith((states) => const Color.fromARGB(64, 26, 43, 86)),
                    columns: const [
                      DataColumn(label: Text('Entrevista')),
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: SizedBox(width: 73, child: Text('Registrador Login', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 73, child: Text('Registrador Nombre', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 68, child: Text('Supervisor Login', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 100, child: Text('Supervisor Nombre', softWrap: true,))),
                      DataColumn(label: Text('Problemas')),
                      DataColumn(label: Text('Estado')),
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
                          _buildLinkCell(entity['llave_entrevista'] ?? 'N/A', entity['url_entrevista'] ?? '', searchQuery),
                          DataCell(Text(entity['fecha_entrevista'] ?? 'N/A')),
                          DataCell(Text(entity['registrador'] ?? 'N/A')),
                          DataCell(SizedBox(width: 110, child: Text(entity['registrador_nombre'] ?? 'N/A', softWrap: true,))),
                          DataCell(Text(entity['supervisor'] ?? 'N/A')),
                          DataCell(SizedBox(width: 110, child: Text(entity['supervisor_nombre'] ?? 'N/A', softWrap: true,))),
                          DataCell(
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
                              width: 400, // Fixed width for "Problemas" column
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Text(
                                  entity['problemas'] ?? 'N/A',
                                  softWrap: true, // Allow the text to wrap inside the container
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.all(10),
                              child: statusDisplay(context, entity['estado_entrevista'] ?? 'N/A', entity['llave_entrevista'] ?? 'N/A', entity['id_entrevista'] ?? 'N/A')
                            ),
                          ),
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

  DataCell _buildLinkCell(String text, String url, String searchQuery) {
    return DataCell(
      InkWell(
        child: RichText(
          text: TextSpan(
            children: [_highlightMatch(text, searchQuery)],
            style: const TextStyle(
              color: Colors.red, // Make text red
              decoration: TextDecoration.underline, // Underline text
              decorationColor: Colors.red, // Red underline
            ),
          ),
        ),
        onTap: () => _launchURL(url),
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

  void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget statusDisplay (BuildContext context, String state, String llaveEntrevista, String idEntrevista) {
    if (state == 'Completed') {
      if (userRole == 'Interviewer') {
        return Text(state);
      }
      else {
        return Column(
          children: [
            CustomSmallButton(
              buttonAction: () => _updateEstado(context, llaveEntrevista, 'ApprovedBySupervisor', idEntrevista),
              buttonColor: Colors.green,
              buttonText: 'Aprobar',
              textColor: Colors.white
            ),
            const SizedBox(height: 10),
            CustomSmallButton(
              buttonAction: () => _updateEstado(context, llaveEntrevista, 'RejectedBySupervisor', idEntrevista),
              buttonColor: Colors.red,
              buttonText: 'Rechazar',
              textColor: Colors.white
            ),
          ],
        );
      }
    } else {
      return Text(state);
    }
  }

  void _updateEstado(BuildContext context, String llave, String estado, String id) async {
    try {
      await _calidadService.updateEstadoEntrevista(llave, estado, id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado')),
      );
      onEstadoUpdated();  // Call the callback to refresh the data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado: $e')),
      );
    }
  }
}
