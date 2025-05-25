// lib/gestores/gestor_recordatorios.dart

import 'package:flutter/material.dart';
import '../modelos/recordatorio.dart';
import '../repositorios/repositorio_recordatorios.dart';

class GestorRecordatorios extends ChangeNotifier {
  final RepositorioRecordatorios _repo = RepositorioRecordatorios();

  GestorRecordatorios();

  Stream<List<Recordatorio>> get recordatorios => _repo.obtenerRecordatorios();

  Future<void> agregar(Recordatorio r) async {
    await _repo.agregarRecordatorio(r);
    notifyListeners();
  }

  Future<void> eliminar(String id) async {
    await _repo.eliminarRecordatorio(id);
    notifyListeners();
  }

  Future<void> editar(Recordatorio r) async {
    await _repo.editarRecordatorio(r);
    notifyListeners();
  }

  Future<void> marcarComoCompletado(Recordatorio r) async {
    final actualizado = r.copyWith(estado: 'completado');
    await _repo.editarRecordatorio(actualizado);
    notifyListeners();
  }

  Future<void> alternarEstado(Recordatorio r) async {
    final nuevoEstado = r.estado == 'pendiente' ? 'completado' : 'pendiente';
    final actualizado = r.copyWith(estado: nuevoEstado);
    await _repo.editarRecordatorio(actualizado);
    notifyListeners();
  }
}
