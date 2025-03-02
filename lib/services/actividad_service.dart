import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:renagro1/globals.dart';
import 'package:http/http.dart' as http;

class ActividadService {
  final String _baseUrl = apiUrl;

  String formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    return formatter.format(date);
  }

  Future<Map<String, dynamic>> fetchFilteredData(Map<String, List<String>> filters, int itemsPerPage, int page) async {
    final uri = Uri.parse('$_baseUrl/actividad_agrupada');

    /*
    // Format dates
    final String formattedToday = formatDate(DateTime.now());
    final String formattedYesterday = formatDate(DateTime.now().subtract(const Duration(days: 1)));

    // Add default values for 'estado_entrevista' filter
    filters['fecha_entrevista'] = filters['fecha_entrevista'] ?? [formattedYesterday, formattedToday];
    filters['fecha_entrevista'] = filters['fecha_entrevista'] ?? ['05-03-2024', '06-03-2024'];
    */

    // Create the request payload with default empty lists for filters
    final payload = {
      "Filters": {
        "registrador_cedula_corta": (filters['registrador_cedula'])
            ?.map((cedula) => cedula.replaceAll('-', ''))
            .toList() ?? [],
        "registrador": filters['registrador'] ?? [],
        "supervisor": filters['supervisor'] ?? [],
        "fecha_entrevista": filters['fecha_entrevista'] ?? []
      },
      "itemsPerPage": itemsPerPage,
      "page": page
    };


    try {
      // Print the parameters in JSON format
      if (kDebugMode) {
        print('Fetch Data Parameters: ${jsonEncode(payload)}');
      }

      // Convert the payload to a JSON string
      String jsonString = jsonEncode(payload);

      // Encode the JSON string with UTF-8
      List<int> utf8Bytes = utf8.encode(jsonString);

      // Make the HTTP POST request
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: utf8Bytes,
      );

      // Check the response status code
      if (response.statusCode == 200) {
        // Parse the response body as a JSON object
        Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        // Extract the list of data from the 'results' key
        List<dynamic> dataList = data['results'];

        // Extract the total-documents value
        int totalDocuments = dataList[0]['total_documentos'];
        // Remove the first item (total-documents) from the dataList
        dataList.removeAt(0);

        // Convert dynamic list to List<Map<String, dynamic>>
        List<Map<String, dynamic>> resultList = List<Map<String, dynamic>>.from(dataList.map((item) => Map<String, dynamic>.from(item)));

        return {
          'data': resultList,
          'currentPage': page,
          'totalPages': (totalDocuments ~/ itemsPerPage) + 1,
          'totalDocuments' : totalDocuments,
        };
      } else {
        if (kDebugMode) {
          print('Error fetching data: ${response.statusCode} ${response.reasonPhrase}');
        }
        return {
          'data': [],
          'currentPage': 1,
          'totalPages': 1,
          'totalDocuments' : 0,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      return {
        'data': [],
        'currentPage': 1,
        'totalPages': 1,
        'totalDocuments' : 0,
      };
    }
  }

  Future<List<String>> fetchFilterOptions(String filterType, String userName, String query) async {
    if (filterType == 'registrador') {
      try {
        final uri = Uri.parse('$_baseUrl/registradores_subalternos');
        final response = await http.post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"usuario_consulta": userName}),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
          List<String> options = [];
          if (data['results'] != null && data['results']['registrador'] != null) {
            options = List<String>.from(data['results']['registrador']);
          }
          if (query.isNotEmpty) {
            options = options.where((option) => option.toLowerCase().contains(query.toLowerCase())).toList();
          }
          return options;
        } else {
          if (kDebugMode) {
            print('Error fetching $filterType: ${response.statusCode} ${response.reasonPhrase}');
          }
          return [];
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching $filterType options: $e');
        }
        return [];
      }
    } else if (filterType == 'supervisor') {
      try {
        final uri = Uri.parse('$_baseUrl/supervisores_subalternos');
        final response = await http.post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"usuario_consulta": userName}),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
          List<String> options = [];
          if (data['results'] != null && data['results']['supervisor'] != null) {
            options = List<String>.from(data['results']['supervisor']);
          }
          if (query.isNotEmpty) {
            options = options.where((option) => option.toLowerCase().contains(query.toLowerCase())).toList();
          }
          return options;
        } else {
          if (kDebugMode) {
            print('Error fetching $filterType: ${response.statusCode} ${response.reasonPhrase}');
          }
          return [];
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching $filterType options: $e');
        }
        return [];
      }
    } else {
      return [];
    }
  }

}