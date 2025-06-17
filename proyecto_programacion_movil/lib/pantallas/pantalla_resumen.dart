// lib/pantallas/pantalla_resumen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/resumen_provider.dart';

class PantallaResumen extends StatelessWidget {
  const PantallaResumen({super.key});

  @override
  Widget build(BuildContext context) {
    final resumenProv = context.watch<ResumenProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen Diario')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/recordatorios'),
        icon: const Icon(Icons.add_task),
        label: const Text('Agregar tarea'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Confetti si todas las tareas están completadas
          if (resumenProv.total > 0 && resumenProv.completados == resumenProv.total)
            Lottie.asset(
              'assets/confetti.json',
              repeat: false,
              height: 150,
            ),

          // Tarjeta de progreso
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progreso',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: resumenProv.progreso,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(resumenProv.progreso * 100).toStringAsFixed(0)}% completado',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Lista de tareas urgentes
          if (resumenProv.urgentes.isNotEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Tareas urgentes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...resumenProv.urgentes.map(
                      (r) => ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(r.titulo),
                        subtitle: Text(
                          '${r.fechaHora.toLocal()}'.split('.')[0],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
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
              borderRadius: BorderRadius.circular(12),
            ),
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
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
              ),
              onPressed: () => resumenProv.leerResumen(),
            ),
          ),
        ],
      ),
    );
  }
}
