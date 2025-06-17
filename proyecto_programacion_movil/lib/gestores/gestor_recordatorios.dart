// lib/gestores/gestor_recordatorios.dart

import 'package:flutter/material.dart';
import '../modelos/recordatorio.dart';
import '../repositorios/repositorio_recordatorios.dart';
import '../servicios/servicio_notificaciones.dart';

class GestorRecordatorios extends ChangeNotifier {
  final RepositorioRecordatorios _repo = RepositorioRecordatorios();

  GestorRecordatorios();

  Stream<List<Recordatorio>> get recordatorios => _repo.obtenerRecordatorios();

  /// Agrega un recordatorio y programa su notificación (1 hora antes)
  Future<void> agregar(Recordatorio r) async {
    await _repo.agregarRecordatorio(r);
    notifyListeners();
    await ServicioNotificaciones.instancia.scheduleNotificacion(
      id: r.hashCode,
      titulo: 'Recordatorio: ${r.titulo}',
      cuerpo: 'Te queda 1 hora para: ${r.titulo}',
      fechaHora: r.fechaHora,
    );
  }

  /// Elimina el recordatorio y cancela su notificación
  Future<void> eliminar(String id) async {
    await _repo.eliminarRecordatorio(id);
    notifyListeners();
    await ServicioNotificaciones.instancia.cancelNotificacion(
      id.hashCode,
    );
  }

  /// Edita el recordatorio: cancela y vuelve a programar la notificación
  Future<void> editar(Recordatorio r) async {
    await _repo.editarRecordatorio(r);
    notifyListeners();
    await ServicioNotificaciones.instancia.cancelNotificacion(
      r.hashCode,
    );
    await ServicioNotificaciones.instancia.scheduleNotificacion(
      id: r.hashCode,
      titulo: 'Recordatorio: ${r.titulo}',
      cuerpo: 'Te queda 1 hora para: ${r.titulo}',
      fechaHora: r.fechaHora,
    );
  }

  /// Marca como completado y cancela la notificación
  Future<void> marcarComoCompletado(Recordatorio r) async {
    final actualizado = r.copyWith(estado: 'completado');
    await _repo.editarRecordatorio(actualizado);
    notifyListeners();
    await ServicioNotificaciones.instancia.cancelNotificacion(
      r.hashCode,
    );
  }

  /// Alterna estado y gestiona la notificación acorde
  Future<void> alternarEstado(Recordatorio r) async {
    final nuevoEstado = r.estado == 'pendiente' ? 'completado' : 'pendiente';
    final actualizado = r.copyWith(estado: nuevoEstado);
    await _repo.editarRecordatorio(actualizado);
    notifyListeners();

    if (nuevoEstado == 'completado') {
      await ServicioNotificaciones.instancia.cancelNotificacion(
        r.hashCode,
      );
    } else {
      await ServicioNotificaciones.instancia.scheduleNotificacion(
        id: r.hashCode,
        titulo: 'Recordatorio: ${r.titulo}',
        cuerpo: 'Te queda 1 hora para: ${r.titulo}',
        fechaHora: r.fechaHora,
      );
    }
  }
}
