import 'package:flutter/material.dart';
import '../modelos/recordatorio.dart';
import '../repositorios/repositorio_recordatorios.dart';

class GestorRecordatorios extends ChangeNotifier {
  final String uid;
  final RepositorioRecordatorios _repo = RepositorioRecordatorios();

  GestorRecordatorios(this.uid);

  Stream<List<Recordatorio>> get recordatorios =>
      _repo.obtenerRecordatorios(uid);

  Future<void> agregar(Recordatorio r) => _repo.agregarRecordatorio(r);
  Future<void> eliminar(String id) => _repo.eliminarRecordatorio(id);
  Future<void> editar(Recordatorio r) => _repo.editarRecordatorio(r);
}
