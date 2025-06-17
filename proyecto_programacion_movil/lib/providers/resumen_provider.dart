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
    // Escucha el stream de recordatorios y notifica cambios
    _sub = _gestor.recordatorios.listen((lista) {
      _todos = lista;
      notifyListeners();
    });
  }

  // Datos crudos
  List<Recordatorio> get allRecordatorios => _todos;

  // Cálculos para la UI
  int get total => _todos.length;
  int get completados =>
      _todos.where((r) => r.estado == 'completado').length;
  List<Recordatorio> get pendientes {
    final list = _todos.where((r) => r.estado != 'completado').toList();
    list.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    return list;
  }

  List<Recordatorio> get urgentes => pendientes.take(3).toList();

  double get progreso => total > 0 ? completados / total : 0.0;

  // Texto para TTS
  String get textoResumen {
    final buf = StringBuffer();
    buf.writeln('Hoy completaste $completados de $total tareas.');
    if (urgentes.isNotEmpty) {
      buf.writeln(
        'Tareas urgentes: ${urgentes.map((r) => r.titulo).join(', ')}.');
    }
    buf.writeln(
      'Recomendación: Prioriza las tareas más próximas para mantener el ritmo.');
    if (pendientes.isEmpty) {
      buf.writeln('¡Felicidades! No te quedan pendientes.');
    } else {
      buf.writeln(
        'Te quedan ${pendientes.length} tarea${pendientes.length > 1 ? 's' : ''} pendientes.');
    }
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
