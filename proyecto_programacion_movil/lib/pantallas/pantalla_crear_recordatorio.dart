import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crear_recordatorio_provider.dart';
import '../gestores/gestor_recordatorios.dart';

class PantallaCrearRecordatorio extends StatelessWidget {
  final int? sugerenciaHora;

  const PantallaCrearRecordatorio({Key? key, this.sugerenciaHora})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Aquí asumimos que el provider ya está inyectado desde la ruta
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Recordatorio')),
      body: const _Formulario(),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario();

  Future<void> _seleccionarFechaHora(BuildContext context) async {
    final provider = Provider.of<CrearRecordatorioProvider>(
      context,
      listen: false,
    );
    final fechaActual = provider.fechaSeleccionada;

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaActual,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (fecha == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(fechaActual),
    );
    if (hora == null) return;

    final nuevaFecha = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
    provider.cambiarFecha(nuevaFecha);
  }

  void _guardar(BuildContext context) {
    final provider = Provider.of<CrearRecordatorioProvider>(
      context,
      listen: false,
    );
    if (!provider.esValido()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ Título obligatorio')));
      return;
    }

    final nuevo = provider.construirRecordatorio();
    Provider.of<GestorRecordatorios>(context, listen: false).agregar(nuevo);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Recordatorio creado')));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CrearRecordatorioProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: prov.tituloCtrl,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text('${prov.fechaSeleccionada.toLocal()}'.split('.')[0]),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _seleccionarFechaHora(context),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: prov.prioridadSeleccionada,
            decoration: const InputDecoration(labelText: 'Prioridad'),
            onChanged: (valor) {
              if (valor != null) prov.cambiarPrioridad(valor);
            },
            items: const [
              DropdownMenuItem(value: 'alta', child: Text('Alta')),
              DropdownMenuItem(value: 'media', child: Text('Media')),
              DropdownMenuItem(value: 'baja', child: Text('Baja')),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _guardar(context),
            child:
                prov.cargandoSugerencia
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
