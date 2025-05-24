import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gestores/gestor_recordatorios.dart';
import '../modelos/recordatorio.dart';

class PantallaRecordatorios extends StatelessWidget {
  const PantallaRecordatorios({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return ChangeNotifierProvider(
      create: (_) => GestorRecordatorios(uid),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Mis Recordatorios')),
          body: Consumer<GestorRecordatorios>(
            builder: (context, gestor, _) {
              return StreamBuilder<List<Recordatorio>>(
                stream: gestor.recordatorios,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final lista = snapshot.data ?? [];
                  print('👤 UID actual: ${FirebaseAuth.instance.currentUser?.uid}');
                  print('📥 Documentos recibidos: ${lista.length}');

                  if (lista.isEmpty) {
                    return const Center(
                      child: Text('No tienes recordatorios aún.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final r = lista[index];
                      return ListTile(
                        title: Text(r.titulo),
                        subtitle: Text(
                          '${r.fechaHora.toLocal()}'.split('.')[0],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => gestor.eliminar(r.id),
                        ),
                        onTap: () => _editarDialog(context, gestor, r),
                      );
                    },
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              final gestor = Provider.of<GestorRecordatorios>(
                context,
                listen: false,
              );
              _crearDialog(context, gestor);
            },
          ),
        );
      },
    );
  }

  void _crearDialog(BuildContext context, GestorRecordatorios gestor) {
    final tituloCtrl = TextEditingController();
    DateTime? seleccionada;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Nuevo Recordatorio'),
            content: Column(
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
                    seleccionada = await showDatePicker(
                      context: context,
                      initialDate: ahora,
                      firstDate: ahora,
                      lastDate: DateTime(2100),
                    );
                    if (seleccionada != null) {
                      final hora = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (hora != null) {
                        seleccionada = DateTime(
                          seleccionada!.year,
                          seleccionada!.month,
                          seleccionada!.day,
                          hora.hour,
                          hora.minute,
                        );
                      }
                    }
                  },
                  child: const Text('Seleccionar fecha y hora'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  if (tituloCtrl.text.isNotEmpty && seleccionada != null) {
                    final nuevo = Recordatorio(
                      id: '',
                      titulo: tituloCtrl.text,
                      fechaHora: seleccionada!,
                      uid: FirebaseAuth.instance.currentUser!.uid,
                    );
                    gestor.agregar(nuevo);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _editarDialog(
    BuildContext context,
    GestorRecordatorios gestor,
    Recordatorio r,
  ) {
    final tituloCtrl = TextEditingController(text: r.titulo);
    DateTime seleccionada = r.fechaHora;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Editar Recordatorio'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
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
                        seleccionada = DateTime(
                          nuevaFecha.year,
                          nuevaFecha.month,
                          nuevaFecha.day,
                          hora.hour,
                          hora.minute,
                        );
                      }
                    }
                  },
                  child: const Text('Editar fecha y hora'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  final actualizado = Recordatorio(
                    id: r.id,
                    titulo: tituloCtrl.text,
                    fechaHora: seleccionada,
                    uid: r.uid,
                  );
                  gestor.editar(actualizado);
                  Navigator.pop(context);
                },
                child: const Text('Actualizar'),
              ),
            ],
          ),
    );
  }
}
