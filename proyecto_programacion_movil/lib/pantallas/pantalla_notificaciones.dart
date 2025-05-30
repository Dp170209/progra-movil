// lib/pantallas/pantalla_notificaciones.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gestores/gestor_notificaciones.dart';

class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<GestorNotificaciones>().cargarMensajes());
  }

  @override
  Widget build(BuildContext context) {
    final gestor = context.watch<GestorNotificaciones>();
    final mensajes = gestor.mensajes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpiar historial',
            onPressed: mensajes.isEmpty
                ? null
                : () async {
                    await gestor.limpiarMensajes();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('🗑️ Historial de notificaciones eliminado')),
                      );
                    }
                  },
          )
        ],
      ),
      body: mensajes.isEmpty
          ? const Center(
              child: Text(
                'No hay notificaciones registradas.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: mensajes.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(mensajes[i]),
              ),
            ),
    );
  }
}
