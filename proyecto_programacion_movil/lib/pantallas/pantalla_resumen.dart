// lib/pantallas/pantalla_resumen.dart
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/recordatorios'),
          icon: const Icon(Icons.add_task),
          label: const Text('Agregar tarea'),
        ),
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
                final completados = todos.where((r) => r.estado == 'completado').length;
                final pendientes = todos
                    .where((r) => r.estado != 'completado')
                    .toList()
                  ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
                final urgentes = pendientes.take(3).toList();
                final progreso = total > 0 ? completados / total : 0.0;

                // Construir texto para TTS
                final buffer = StringBuffer();
                buffer.writeln('Hoy completaste $completados de $total tareas.');
                if (urgentes.isNotEmpty) {
                  buffer.writeln(
                      'Tareas urgentes: ' + urgentes.map((r) => r.titulo).join(', ') + '.');
                }
                buffer.writeln(
                    'Recomendación: Prioriza las tareas más próximas para mantener el ritmo.');
                if (pendientes.isEmpty) {
                  buffer.writeln('¡Felicidades! No te quedan pendientes.');
                } else {
                  buffer.writeln(
                      'Te quedan ${pendientes.length} tarea${pendientes.length > 1 ? 's' : ''} pendientes.');
                }
                final resumenTexto = buffer.toString();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Confetti si completado
                    if (total > 0 && completados == total)
                      Lottie.asset(
                        'assets/confetti.json',
                        repeat: false,
                        height: 150,
                      ),

                    // Tarjeta de progreso
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progreso',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progreso,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(progreso * 100).toStringAsFixed(0)}% completado',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lista de urgentes
                    if (urgentes.isNotEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('⚠️ Tareas urgentes',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              const SizedBox(height: 8),
                              ...urgentes
                                  .map((r) => ListTile(
                                        leading: const Icon(Icons.warning, color: Colors.red),
                                        title: Text(r.titulo),
                                        subtitle: Text(
                                          '${r.fechaHora.toLocal()}'.split('.')[0],
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Recomendación general
                    Card(
                      color: Colors.blue.shade50,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Recomendación: Prioriza las tareas más próximas para mantener el ritmo.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón TTS
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Escuchar resumen'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                        ),
                        onPressed: () => _leerResumen(resumenTexto),
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