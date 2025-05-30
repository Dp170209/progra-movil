import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_programacion_movil/repositorios/repositorio_habito.dart';
import 'package:proyecto_programacion_movil/servicios/servicio_voz.dart';
import '../gestores/gestor_recordatorios.dart';
import '../modelos/recordatorio.dart';
import '../servicios/servicio_openai.dart';

class PantallaRecordatorios extends StatefulWidget {
  const PantallaRecordatorios({super.key});

  @override
  State<PantallaRecordatorios> createState() => _PantallaRecordatoriosState();
}

class _PantallaRecordatoriosState extends State<PantallaRecordatorios> {
  String filtroPrioridad = 'todas';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GestorRecordatorios(),
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
                  if (lista.isEmpty) {
                    return const Center(
                      child: Text('No tienes recordatorios aún.'),
                    );
                  }

                  final listaFiltrada =
                      filtroPrioridad == 'todas'
                          ? lista
                          : lista
                              .where((r) => r.prioridad == filtroPrioridad)
                              .toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton<String>(
                          value: filtroPrioridad,
                          onChanged: (valor) {
                            if (valor != null) {
                              setState(() {
                                filtroPrioridad = valor;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'todas',
                              child: Text('Todas las prioridades'),
                            ),
                            DropdownMenuItem(
                              value: 'alta',
                              child: Text('Alta'),
                            ),
                            DropdownMenuItem(
                              value: 'media',
                              child: Text('Media'),
                            ),
                            DropdownMenuItem(
                              value: 'baja',
                              child: Text('Baja'),
                            ),
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
                                  decoration:
                                      esCompletado
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                ),
                              ),
                              subtitle: Text(
                                '${r.fechaHora.toLocal()}'.split('.')[0] +
                                    ' — ${calcularTiempoRestante(r.fechaHora)}\nPrioridad: ${r.prioridad.toUpperCase()}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      esCompletado
                                          ? Icons.check_circle_outline
                                          : Icons.check_circle,
                                      color:
                                          esCompletado
                                              ? Colors.grey
                                              : Colors.green,
                                    ),
                                    tooltip:
                                        esCompletado
                                            ? 'Marcar como pendiente'
                                            : 'Marcar como completado',
                                    onPressed: () async {
                                      await gestor.alternarEstado(r);
                                      if (!esCompletado) {
                                        await RepositorioHabitos()
                                            .registrarHabito(r.id, r.titulo);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '✅ Hábito registrado',
                                            ),
                                          ),
                                        );
                                      } else {
                                        await RepositorioHabitos()
                                            .eliminarHabito(r.id);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '🔄 Marcado como pendiente y hábito eliminado',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Eliminar',
                                    onPressed:
                                        () => _confirmarBorrado(
                                          context,
                                          gestor,
                                          r,
                                        ),
                                  ),
                                ],
                              ),
                              onTap: () => _editarDialog(context, gestor, r),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
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
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎙️ Escuchando...')),
                  );
                  final comando = await ServicioVoz.instance.escucharComando();
                  if (comando == null || comando.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ No te escuché bien')),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⏳ Procesando con OpenAI...')),
                  );
                  final json = await ServicioOpenAI.instance.procesarFrase(
                    comando,
                  );
                  if (json == null ||
                      !json.containsKey('titulo') ||
                      !json.containsKey('fecha')) {
                    await ServicioVoz.instance.hablar('No entendí tu mensaje');
                    return;
                  }
                  try {
                    final fechaUtc = DateTime.parse(json['fecha']);
                    final fecha = fechaUtc.toLocal();
                    final titulo = json['titulo'] as String;
                    final nuevo = Recordatorio(
                      id: '',
                      titulo: titulo,
                      fechaHora: fecha,
                      prioridad: 'media', // prioridad por defecto
                    );
                    Provider.of<GestorRecordatorios>(
                      context,
                      listen: false,
                    ).agregar(nuevo);
                    final respuesta =
                        'Recordatorio "$titulo" para ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')} creado';
                    await ServicioVoz.instance.hablar(respuesta);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('✅ $respuesta')));
                  } catch (e) {
                    await ServicioVoz.instance.hablar(
                      'La fecha no parece válida',
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'fab_agregar',
                child: const Icon(Icons.add),
                onPressed: () {
                  final gestor = Provider.of<GestorRecordatorios>(
                    context,
                    listen: false,
                  );
                  _crearDialog(context, gestor);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String calcularTiempoRestante(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = fecha.difference(ahora);

    if (diferencia.isNegative) return '⏰ Ya vencido';

    final dias = diferencia.inDays;
    final horas = diferencia.inHours % 24;
    final minutos = diferencia.inMinutes % 60;

    if (dias > 0) return 'En $dias día${dias > 1 ? 's' : ''} y $horas h';
    if (horas > 0) return 'En $horas h y $minutos min';
    return 'En $minutos min';
  }

  void _crearDialog(BuildContext context, GestorRecordatorios gestor) {
    final tituloCtrl = TextEditingController();
    DateTime? seleccionada;
    String prioridad = 'media'; 

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
                          fecha.year,
                          fecha.month,
                          fecha.day,
                          hora.hour,
                          hora.minute,
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
                  onChanged: (valor) {
                    if (valor != null) prioridad = valor;
                  },
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
                  final titulo = tituloCtrl.text.trim();
                  if (titulo.isEmpty || seleccionada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Título y fecha son obligatorios'),
                      ),
                    );
                    return;
                  }

                  final nuevo = Recordatorio(
                    id: '',
                    titulo: titulo,
                    fechaHora: seleccionada!,
                    prioridad: prioridad,
                  );
                  gestor.agregar(nuevo);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Recordatorio creado')),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _crearPorTexto(BuildContext context) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Crear recordatorio por texto'),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Ej: Llamar al doctor mañana a las 5 PM',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final texto = ctrl.text.trim();
                  if (texto.isEmpty) return;

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⏳ Procesando con OpenAI...')),
                  );

                  final json = await ServicioOpenAI.instance.procesarFrase(
                    texto,
                  );
                  if (json == null ||
                      !json.containsKey('titulo') ||
                      !json.containsKey('fecha')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ No se entendió el mensaje'),
                      ),
                    );
                    return;
                  }

                  try {
                    final fechaRaw = json['fecha'];
                    final titulo = json['titulo'];

                    if (fechaRaw == null || titulo == null) throw Exception();

                    final fechaUtc = DateTime.parse(fechaRaw);
                    final fecha = fechaUtc.toLocal();

                    final nuevo = Recordatorio(
                      id: '',
                      titulo: titulo,
                      fechaHora: fecha,
                    );

                    final gestor = Provider.of<GestorRecordatorios>(
                      context,
                      listen: false,
                    );
                    gestor.agregar(nuevo);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Recordatorio creado')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Fecha no válida')),
                    );
                  }
                },
                child: const Text('Crear'),
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
  String prioridad = r.prioridad.toLowerCase(); // Aseguramos coincidencia exacta

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                      setState(() {
                        seleccionada = DateTime(
                          nuevaFecha.year,
                          nuevaFecha.month,
                          nuevaFecha.day,
                          hora.hour,
                          hora.minute,
                        );
                      });
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
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() {
                      prioridad = valor;
                    });
                  }
                },
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
                final titulo = tituloCtrl.text.trim();
                if (titulo.isEmpty) return;

                final actualizado = Recordatorio(
                  id: r.id,
                  titulo: titulo,
                  fechaHora: seleccionada,
                  estado: r.estado,
                  prioridad: prioridad,
                );
                gestor.editar(actualizado);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Recordatorio actualizado')),
                );
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    },
  );
}


  void _confirmarBorrado(
    BuildContext context,
    GestorRecordatorios gestor,
    Recordatorio r,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('¿Eliminar recordatorio?'),
            content: Text('Se eliminará "${r.titulo}". ¿Deseas continuar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  gestor.eliminar(r.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🗑 Recordatorio eliminado')),
                  );
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}