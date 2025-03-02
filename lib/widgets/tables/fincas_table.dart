import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FincasTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String llaveQuery;
  final String productorQuery;
  final String parcelaQuery;
  final String codigoQuery;
  final VoidCallback onEstadoUpdated;
  final String userRole;

  const FincasTable({
    super.key,
    required this.data,
    required this.llaveQuery,
    required this.productorQuery,
    required this.parcelaQuery,
    required this.codigoQuery,
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
    final tableHeight = size.height - 280;

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
                    dataRowMaxHeight: 130,
                    headingRowHeight: 50,
                    headingRowColor: MaterialStateColor.resolveWith((states) => const Color.fromARGB(64, 26, 43, 86)),
                    columns: const [
                      DataColumn(label: SizedBox(width: 70, child: Text('Entrevista', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 70, child: Text('Fecha', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 63, child: Text('Productor', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 77, child: Text('Coordenada Entrevista', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 70, child: Text('Finca/Parcela', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 88, child: Text('Codigo Finca/Parcela', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 70, child: Text('Tareaje', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 70, child: Text('Región', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 70, child: Text('Territorio', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 73, child: Text('Registrador Login', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 73, child: Text('Registrador Nombre', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 73, child: Text('Supervisor Login', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 73, child: Text('Supervisor Nombre', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 90, child: Text('Coordenada Finca/Parcela', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 90, child: Text('Finca/Parcela Geolocalizada', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 90, child: Text('Tipo Captura Coordenadas', softWrap: true,))),
                      DataColumn(label: SizedBox(width: 70, child: Text('Creada', softWrap: true,))),
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
                          DataCell(RichText(text: _highlightMatch(entity['llave_entrevista'] ?? 'N/A', llaveQuery))),
                          DataCell(Text(entity['fecha_entrevista'] ?? 'N/A', softWrap: true,)),
                          DataCell(SizedBox(width: 100, child: RichText(text: _highlightMatch(entity['nombre_productor'] ?? 'N/A', productorQuery)))),
                          _buildLinkCell(entity['coordenadas_entrevista'] ?? 'N/A', 'https://www.google.com/maps?q=${entity['coordenadas_entrevista'] ?? 'N/A'}', ''),
                          DataCell(SizedBox(width: 100, child: RichText(text: _highlightMatch(entity['nombre_parcela'] ?? 'N/A', parcelaQuery)))),
                          DataCell(RichText(text: _highlightMatch(entity['codigo_parcela'] ?? 'N/A', codigoQuery))),
                          DataCell(Text(entity['area_parcela'].toString(), softWrap: true,)),
                          DataCell(
                            RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  const TextSpan(text: 'Region: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${entity['regionalizacion']?['region'] ?? 'N/A'}\n'),
                                  const TextSpan(text: 'Zona: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${entity['regionalizacion']?['zona'] ?? 'N/A'}\n'),
                                  const TextSpan(text: 'Subzona: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${entity['regionalizacion']?['subzona'] ?? 'N/A'}\n'),
                                  const TextSpan(text: 'Area: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${entity['regionalizacion']?['area'] ?? 'N/A'}'),
                                ],
                              ),
                              softWrap: true,
                            ),
                          ),
                          DataCell(
                            RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  const TextSpan(text: 'Region: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${entity['territorio']?['region'] ?? 'N/A'}\n'),
                                  const TextSpan(text: 'Provincia: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${entity['territorio']?['provincia'] ?? 'N/A'}\n'),
                                  const TextSpan(text: 'Municipio: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${entity['territorio']?['municipio'] ?? 'N/A'}\n'),
                                  const TextSpan(text: 'Distrito: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${entity['territorio']?['distrito'] ?? 'N/A'}\n'),
                                  const TextSpan(text: 'Seccion: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${entity['territorio']?['seccion'] ?? 'N/A'}\n'),
                                  const TextSpan(text: 'Paraje: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${entity['territorio']?['paraje'] ?? 'N/A'}'),
                                ],
                              ),
                              softWrap: true,
                            ),
                          ),
                          DataCell(Text(entity['registrador'] ?? 'N/A', softWrap: true,)),
                          DataCell(SizedBox(width: 100, child: Text(entity['registrador_nombre'] ?? 'N/A', softWrap: true,))),
                          DataCell(Text(entity['supervisor'] ?? 'N/A', softWrap: true,)),
                          DataCell(SizedBox(width: 100, child: Text(entity['supervisor_nombre'] ?? 'N/A', softWrap: true,))),
                          _buildLinkCell(entity['coordenadas_parcela'] ?? 'N/A', 'https://www.google.com/maps?q=${entity['coordenadas_entrevista'] ?? 'N/A'}', ''),
                          DataCell(Text(entity['parcela_geolocalizda'] ?? 'N/A', softWrap: true,)),
                          DataCell(Text(entity['tipo_captura_coordenadas'] ?? 'N/A', softWrap: true,)),
                          DataCell(SizedBox(width: 100, child: Text(entity['creado'] ?? 'N/A', softWrap: true,))),
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
        child: SizedBox(
          width: 150,
          child: RichText(
            text: TextSpan(
              children: [TextSpan(text: text)], // Removed _highlightMatch for simplicity
              style: const TextStyle(
                color: Colors.red, // Make text blue
                decoration: TextDecoration.underline, // Underline text
                decorationColor: Colors.red, // Blue underline
              ),
            ),
          ),
        ),
        onTap: () => _launchURL(url),
      ),
    );
  }

  void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
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