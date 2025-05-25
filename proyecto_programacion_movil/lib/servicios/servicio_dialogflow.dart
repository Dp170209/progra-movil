import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class ServicioDialogflow {
  static final instance = ServicioDialogflow._();
  ServicioDialogflow._();

  static const _scopes = ['https://www.googleapis.com/auth/cloud-platform'];

  Future<Map<String, dynamic>?> procesarFrase(String texto) async {
    // 1. Cargar JSON desde assets
    final jsonStr = await rootBundle.loadString('assets/clave_dialogflow.json');
    final jsonMap = jsonDecode(jsonStr);

    // 2. Obtener project_id
    final projectId = jsonMap['project_id'];

    // 3. Credenciales desde el JSON completo
    final credentials = ServiceAccountCredentials.fromJson(jsonStr);
    final client = await clientViaServiceAccount(credentials, _scopes);

    // 4. URI y cuerpo para la petición
    final uri = Uri.parse(
      'https://dialogflow.googleapis.com/v2/projects/$projectId/agent/sessions/flutter-session:detectIntent',
    );

    final body = {
      "queryInput": {
        "text": {
          "text": texto,
          "languageCode": "es"
        }
      }
    };

    // 5. Petición a Dialogflow
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    // 6. Procesar respuesta
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final params = data['queryResult']?['parameters'];
      return params is Map<String, dynamic> ? params : null;
    } else {
      print('❌ Error desde Dialogflow: ${response.body}');
      return null;
    }
  }
}
