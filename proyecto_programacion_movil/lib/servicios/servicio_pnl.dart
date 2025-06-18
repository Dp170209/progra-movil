import 'dart:convert';

import 'package:http/http.dart' as http;

class ServicioPNL {
  static final instance = ServicioPNL._();
  ServicioPNL._();

  final String _baseUrl = 'http://127.0.0.1:5000';

  Future<Map<String, dynamic>?> procesarFrase(String frase) async {
    final uri = Uri.parse('$_baseUrl/procesar');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'frase': frase}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('titulo') && data.containsKey('fecha')) {
          return data;
        } else {
          print('❌ Respuesta sin campos esperados: $data');
        }
      } else {
        print('❌ Error del servidor: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al conectar con el servidor PNL: $e');
    }

    return null;
  }
}