import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gestores/gestor_recordatorios.dart';
import '../modelos/recordatorio.dart';
import '../repositorios/repositorio_habito.dart';

class PantallaCrearRecordatorio extends StatefulWidget {
  final int? sugerenciaHora;
  const PantallaCrearRecordatorio({this.sugerenciaHora, Key? key})
    : super(key: key);

  @override
  _PantallaCrearRecordatorioState createState() =>
      _PantallaCrearRecordatorioState();
}

class _PantallaCrearRecordatorioState extends State<PantallaCrearRecordatorio> {
  final _tituloCtrl = TextEditingController();
  late DateTime _fechaSeleccionada;
  bool _cargandoSugerencia = true;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _fechaSeleccionada =
        widget.sugerenciaHora != null
            ? DateTime(
              ahora.year,
              ahora.month,
              ahora.day,
              widget.sugerenciaHora!,
            )
            : ahora;

    _cargarTituloSugerido();
  }

  Future<void> _cargarTituloSugerido() async {
    final repo = RepositorioHabitos();
    final sugerido = await repo.tituloMasRepetido();

    if (sugerido != null && _tituloCtrl.text.trim().isEmpty) {
      setState(() {
        _tituloCtrl.text = sugerido;
      });
    }

    setState(() {
      _cargandoSugerencia = false;
    });
  }

  Future<void> _pickDateTime() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (fecha == null) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaSeleccionada),
    );
    if (hora == null) return;
    setState(() {
      _fechaSeleccionada = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  void _guardar() {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ Título obligatorio')));
      return;
    }
    final nuevo = Recordatorio(
      id: '',
      titulo: titulo,
      fechaHora: _fechaSeleccionada,
    );
    Provider.of<GestorRecordatorios>(context, listen: false).agregar(nuevo);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Recordatorio creado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Recordatorio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('${_fechaSeleccionada.toLocal()}'.split('.')[0]),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _pickDateTime,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _guardar,
              child:
                  _cargandoSugerencia
                      ? const CircularProgressIndicator()
                      : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
