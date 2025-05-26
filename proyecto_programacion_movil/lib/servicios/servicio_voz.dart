import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ServicioVoz {
  static final ServicioVoz instance = ServicioVoz._();
  ServicioVoz._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  Future<String?> escucharComando({int segundos = 5}) async {
    bool disponible = await _speech.initialize();
    if (!disponible) return null;
    String? resultado;
    await _speech.listen(
      onResult: (val) {
        resultado = val.recognizedWords;
      },
    );
    await Future.delayed(Duration(seconds: segundos));
    await _speech.stop();
    return resultado;
  }

  Future<void> hablar(String texto) async {
    await _tts.speak(texto);
  }
}
