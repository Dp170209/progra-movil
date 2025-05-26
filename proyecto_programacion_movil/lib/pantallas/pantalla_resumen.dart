// En tu pubspec.yaml asegúrate de tener:
// flutter_tts: ^3.5.2
// lottie: ^2.2.0

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../gestores/gestor_recordatorios.dart';
import '../modelos/recordatorio.dart';

class PantallaResumen extends StatefulWidget {
  const PantallaResumen({super.key});

  @override
  State<PantallaResumen> createState() => _PantallaResumenState();
}

class _PantallaResumenState extends State<PantallaResumen> {
  late final GestorRecordatorios _gestor;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _gestor = GestorRecordatorios();
  }

  @override
  void dispose() {
    _gestor.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _leerResumen(String texto) async {
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(texto);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gestor,
      child: Scaffold(
        appBar: AppBar(title: const Text('Resumen Diario')),
        body: Consumer<GestorRecordatorios>(
          builder: (context, gestor, _) {
            return StreamBuilder<List<Recordatorio>>(
              stream: gestor.recordatorios,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final todos = snapshot.data ?? [];
                final total = todos.length;
                final completados =
                    todos.where((r) => r.estado == 'completado').length;
                final pendientes = todos
                    .where((r) => r.estado != 'completado')
                    .toList();
                pendientes.sort(
                    (a, b) => a.fechaHora.compareTo(b.fechaHora));
                final urgentes = pendientes.take(3).toList();

                // Generar texto de resumen
                final buffer = StringBuffer();
                buffer.writeln(
                    'Hoy completaste $completados de $total tareas.');
                if (urgentes.isNotEmpty) {
                  buffer.writeln(
                      'Tareas urgentes: ' +
                          urgentes.map((r) => r.titulo).join(', ') +
                          '.');
                }
                buffer.writeln(
                    'Recomendación: Prioriza las tareas más próximas para mantener el ritmo.');
                buffer.writeln('');
                if (pendientes.isEmpty) {
                  buffer.writeln('¡Felicidades! No te quedan pendientes.');
                } else {
                  buffer.writeln(
                      'Te quedan ${pendientes.length} tarea${pendientes.length > 1 ? 's' : ''} pendientes.');
                }
                final resumenTexto = buffer.toString();

                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView(
                        children: [
                          Text(
                            'Resumen Diario',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '• Tareas hechas: $completados/$total',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                          const SizedBox(height: 12),
                          if (urgentes.isNotEmpty) ...[
                            Text(
                              '• Tareas urgentes:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            ...urgentes.map(
                                (r) => Text('  - ${r.titulo}')),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            '• Recomendación:',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                          const Text(
                              '  Prioriza las tareas más próximas.'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Escuchar resumen'),
                            onPressed: () => _leerResumen(resumenTexto),
                          ),
                        ],
                      ),
                    ),
                    if (total > 0 && completados == total)
                      Positioned.fill(
                        child: Lottie.asset(
                          'assets/confetti.json',
                          repeat: false,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
