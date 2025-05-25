import 'dart:convert';
import 'package:http/http.dart' as http;

class ServicioOpenAI {
  static final instance = ServicioOpenAI._();
  ServicioOpenAI._();

  final String _apiKey =
      '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'; // 🔑 Reemplaza con tu API Key

  Future<Map<String, dynamic>?> procesarFrase(String frase) async {
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {
          'role': 'system',
          'content':
              'Eres un asistente que convierte frases en recordatorios JSON. Solo responde en JSON.',
        },
        {
          'role': 'user',
          'content': '''
Convierte esta frase a un recordatorio:
"$frase"

Ejemplo de salida:
{
  "titulo": "Llamar al doctor",
  "fecha": "2025-05-30T15:00:00"
}
''',
        },
      ],
      'temperature': 0.4,
    });

    final respuesta = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: body,
    );

    if (respuesta.statusCode == 200) {
      final json = jsonDecode(respuesta.body);
      final texto = json['choices'][0]['message']['content'];

      try {
        return jsonDecode(texto);
      } catch (e) {
        print('❌ Error al parsear JSON: $texto');
        return null;
      }
    } else {
      print('❌ Error desde OpenAI: ${respuesta.body}');
      return null;
    }
  }
}
