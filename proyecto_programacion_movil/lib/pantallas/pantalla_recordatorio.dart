// lib/pantallas/pantalla_recordatorio.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modelos/recordatorio.dart';
import '../providers/recordatorio_provider.dart';

class PantallaRecordatorios extends StatelessWidget {
  const PantallaRecordatorios({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecordatorioProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Recordatorios')),
      body: StreamBuilder<List<Recordatorio>>(
        stream: prov.recordatorios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return const Center(child: Text('No tienes recordatorios aún.'));
          }

          final listaFiltrada = prov.filtrar(lista);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: prov.filtroPrioridad,
                  onChanged: (valor) {
                    if (valor != null) prov.filtroPrioridad = valor;
                  },
                  items: const [
                    DropdownMenuItem(value: 'todas', child: Text('Todas las prioridades')),
                    DropdownMenuItem(value: 'alta', child: Text('Alta')),
                    DropdownMenuItem(value: 'media', child: Text('Media')),
                    DropdownMenuItem(value: 'baja', child: Text('Baja')),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: listaFiltrada.length,
                  itemBuilder: (context, index) {
                    final r = listaFiltrada[index];
                    final esCompletado = r.estado == 'completado';
                    return ListTile(
                      title: Text(
                        r.titulo,
                        style: TextStyle(
                          decoration: esCompletado
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(
                        '${r.fechaHora.toLocal().toString().split('.')[0]} — ${prov.calcularTiempoRestante(r.fechaHora)}\nPrioridad: ${r.prioridad.toUpperCase()}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              esCompletado ? Icons.check_circle_outline : Icons.check_circle,
                              color: esCompletado ? Colors.grey : Colors.green,
                            ),
                            tooltip: esCompletado ? 'Marcar como pendiente' : 'Marcar como completado',
                            onPressed: () => prov.alternarEstado(context, r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar',
                            onPressed: () => _confirmarBorrado(context, r.id),
                          ),
                        ],
                      ),
                      onTap: () => _editarDialog(context, r),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab_texto',
            icon: const Icon(Icons.auto_mode),
            label: const Text('Texto Inteligente'),
            onPressed: () => _crearPorTexto(context),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'fab_voz',
            icon: const Icon(Icons.mic),
            label: const Text('Voz Inteligente'),
            onPressed: () => prov.agregarPorVoz(context),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'fab_agregar',
            child: const Icon(Icons.add),
            onPressed: () => _crearDialog(context),
          ),
        ],
      ),
    );
  }

  void _crearDialog(BuildContext context) {
    final prov = context.read<RecordatorioProvider>();
    final tituloCtrl = TextEditingController();
    DateTime? seleccionada;
    String prioridad = 'media';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo Recordatorio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final ahora = DateTime.now();
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: ahora,
                    firstDate: ahora,
                    lastDate: DateTime(2100),
                  );
                  if (fecha != null) {
                    final hora = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (hora != null) {
                      seleccionada = DateTime(
                        fecha.year, fecha.month, fecha.day, hora.hour, hora.minute,
                      );
                    }
                  }
                },
                child: const Text('Seleccionar fecha y hora'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: prioridad,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: const [
                  DropdownMenuItem(value: 'alta', child: Text('Alta')),
                  DropdownMenuItem(value: 'media', child: Text('Media')),
                  DropdownMenuItem(value: 'baja', child: Text('Baja')),
                ],
                onChanged: (valor) => prioridad = valor ?? prioridad,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final titulo = tituloCtrl.text.trim();
              if (titulo.isEmpty || seleccionada == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Título y fecha son obligatorios')),
                );
                return;
              }
              final nuevo = Recordatorio(
                id: '', titulo: titulo, fechaHora: seleccionada!, prioridad: prioridad,
              );
              prov.agregarRecordatorio(context, nuevo);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _crearPorTexto(BuildContext context) {
    final prov = context.read<RecordatorioProvider>();
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear recordatorio por texto'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Ej: Llamar al doctor mañana a las 5 PM'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => prov.crearPorTexto(context, ctrl.text.trim()), child: const Text('Crear')),
        ],
      ),
    );
  }

  void _editarDialog(BuildContext context, Recordatorio r) {
    final prov = context.read<RecordatorioProvider>();
    final tituloCtrl = TextEditingController(text: r.titulo);
    DateTime seleccionada = r.fechaHora;
    String prioridad = r.prioridad.toLowerCase();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Recordatorio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Título')),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final nuevaFecha = await showDatePicker(
                      context: context,
                      initialDate: seleccionada,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (nuevaFecha != null) {
                      final hora = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(seleccionada),
                      );
                      if (hora != null) {
                        setState(() => seleccionada = DateTime(
                          nuevaFecha.year, nuevaFecha.month, nuevaFecha.day, hora.hour, hora.minute,
                        ));
                      }
                    }
                  },
                  child: const Text('Editar fecha y hora'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: prioridad,
                  decoration: const InputDecoration(labelText: 'Prioridad'),
                  items: const [
                    DropdownMenuItem(value: 'alta', child: Text('Alta')),
                    DropdownMenuItem(value: 'media', child: Text('Media')),
                    DropdownMenuItem(value: 'baja', child: Text('Baja')),
                  ],
                  onChanged: (valor) => setState(() => prioridad = valor ?? prioridad),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(onPressed: () {
              final actualizado = Recordatorio(
                id: r.id,
                titulo: tituloCtrl.text.trim(),
                fechaHora: seleccionada,
                estado: r.estado,
                prioridad: prioridad,
              );
              prov.editarRecordatorio(context, actualizado);
              Navigator.pop(context);
            }, child: const Text('Actualizar')),
          ],
        ),
      ),
    );
  }

  void _confirmarBorrado(BuildContext context, String id) {
    final prov = context.read<RecordatorioProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar recordatorio?'),
        content: const Text('Se eliminará este recordatorio. ¿Deseas continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () {
            prov.eliminar(context, id);
            Navigator.pop(context);
          }, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
