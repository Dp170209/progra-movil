import 'dart:convert';
import 'package:http/http.dart' as http;

class ServicioOpenAI {
  static final instance = ServicioOpenAI._();
  ServicioOpenAI._();

  final _apiKey = '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'; // 🔑 Reemplaza con tu clave real

  Future<Map<String, dynamic>?> procesarFrase(String frase) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {
          "role": "system",
          "content":
  "Eres un asistente que ayuda a crear recordatorios. Hoy es ${DateTime.now().toLocal().toIso8601String()}. "
  "Dado un mensaje como 'llamar a mamá mañana a las 5 PM', responde solo con un JSON que contenga dos claves: 'titulo' y 'fecha'. "
  "La 'fecha' debe estar en formato ISO 8601 con hora local (UTC-5), no UTC. No agregues ningún texto extra, solo el JSON puro."

        },
        {
          "role": "user",
          "content": frase,
        }
      ],
      "temperature": 0.2,
    });

     final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final contenido = json['choices'][0]['message']['content'];

      try {
        final mapa = jsonDecode(contenido);
        if (mapa is Map<String, dynamic> &&
            mapa.containsKey('titulo') &&
            mapa.containsKey('fecha')) {
          return mapa;
        }
      } catch (e) {
        print('❌ Error al parsear JSON: $e\nContenido: $contenido');
      }
    } else {
      print('❌ Error desde OpenAI: ${response.body}');
    }

    return null;
  }
}