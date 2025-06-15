import 'package:flutter/material.dart';
import '../modelos/recordatorio.dart';
import '../repositorios/repositorio_habito.dart';

class CrearRecordatorioProvider with ChangeNotifier {
  final TextEditingController tituloCtrl = TextEditingController();
  DateTime fechaSeleccionada = DateTime.now();
  String prioridadSeleccionada = 'media';
  bool cargandoSugerencia = true;

  CrearRecordatorioProvider({int? sugerenciaHora}) {
    final ahora = DateTime.now();
    fechaSeleccionada =
        sugerenciaHora != null
            ? DateTime(ahora.year, ahora.month, ahora.day, sugerenciaHora)
            : ahora;
    _cargarTituloSugerido();
  }

  Future<void> _cargarTituloSugerido() async {
    final repo = RepositorioHabitos();
    final sugerido = await repo.tituloMasRepetido();
    if (sugerido != null && tituloCtrl.text.trim().isEmpty) {
      tituloCtrl.text = sugerido;
    }
    cargandoSugerencia = false;
    notifyListeners();
  }

  void cambiarFecha(DateTime nuevaFecha) {
    fechaSeleccionada = nuevaFecha;
    notifyListeners();
  }

  void cambiarPrioridad(String prioridad) {
    prioridadSeleccionada = prioridad;
    notifyListeners();
  }

  Recordatorio construirRecordatorio() {
    return Recordatorio(
      id: '',
      titulo: tituloCtrl.text.trim(),
      fechaHora: fechaSeleccionada,
      prioridad: prioridadSeleccionada,
    );
  }

  bool esValido() {
    return tituloCtrl.text.trim().isNotEmpty;
  }

  void limpiar() {
    tituloCtrl.clear();
    prioridadSeleccionada = 'media';
    fechaSeleccionada = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    tituloCtrl.dispose();
    super.dispose();
  }
}
