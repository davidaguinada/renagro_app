import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

String apiUrl = '';

Future<void> loadConfig() async {
  try {
    final configString = await rootBundle.loadString('assets/config.json');
    final config = json.decode(configString);
    apiUrl = config['apiUrl'];
  } catch (e) {
    if (kDebugMode) {
      print('Error loading config file: $e');
    }
  }
}

