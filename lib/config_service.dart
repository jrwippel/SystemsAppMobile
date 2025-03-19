import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ConfigService {
  static late Map<String, dynamic> _config;

  static Future<void> loadConfig(String environment) async {
    final configString = await rootBundle.loadString('assets/config.json');
    final Map<String, dynamic> jsonConfig = json.decode(configString);
    _config = jsonConfig[environment] ?? {};
  }

  static String get apiBaseUrl => _config['apiBaseUrl'] ?? '';
}
