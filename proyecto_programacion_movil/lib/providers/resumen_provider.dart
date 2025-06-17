// lib/providers/resumen_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../gestores/gestor_recordatorios.dart';
import '../modelos/recordatorio.dart';

class ResumenProvider extends ChangeNotifier {
  final GestorRecordatorios _gestor = GestorRecordatorios();
  final FlutterTts _flutterTts = FlutterTts();
  late final StreamSubscription<List<Recordatorio>> _sub;

  List<Recordatorio> _todos = [];

  ResumenProvider() {
    _sub = _gestor.recordatorios.listen((lista) {
      _todos = lista;
      notifyListeners();
    });
  }

  List<Recordatorio> get allRecordatorios => _todos;
  int get total => _todos.length;
  int get completados =>
      _todos.where((r) => r.estado == 'completado').length;
  List<Recordatorio> get pendientes {
    final list = _todos.where((r) => r.estado != 'completado').toList();
    list.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    return list;
  }
  double get progreso => total > 0 ? completados / total : 0.0;

  /// Genera el texto completo para TTS, incluyendo cada tarea pendiente y su prioridad
  String get textoResumen {
    final buf = StringBuffer();
    buf.writeln('Hoy completaste $completados de $total tareas.');
    if (pendientes.isEmpty) {
      buf.writeln('¡Felicidades! No te quedan tareas pendientes.');
    } else {
      buf.writeln('Tienes ${pendientes.length} tareas pendientes:');
      for (var r in pendientes) {
        final nivel = r.prioridad.toLowerCase();
        final nivelTexto = nivel == 'alta'
            ? 'Alta'
            : nivel == 'media'
                ? 'Media'
                : 'Baja';
        buf.writeln('Tarea ${r.titulo} con prioridad $nivelTexto.');
      }
    }
    buf.writeln('Recomendación: Prioriza las tareas más próximas para mantener el ritmo.');
    return buf.toString();
  }

  Future<void> leerResumen() async {
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(textoResumen);
  }

  @override
  void dispose() {
    _sub.cancel();
    _gestor.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}
