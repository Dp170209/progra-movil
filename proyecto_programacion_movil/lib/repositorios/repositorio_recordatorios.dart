// lib/repositorios/repositorio_recordatorios.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modelos/recordatorio.dart';

class RepositorioRecordatorios {
  /// Referencia a /usuarios/{uid}/recordatorios
  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('recordatorios');
  }

  /// Devuelve un stream con la lista de recordatorios del usuario actual
  Stream<List<Recordatorio>> obtenerRecordatorios() {
    return _col.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return Recordatorio.fromJson(doc.id, doc.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<Recordatorio>()
          .toList();
    });
  }

  /// Agrega un nuevo recordatorio para el usuario actual
  Future<void> agregarRecordatorio(Recordatorio recordatorio) {
    return _col.add(recordatorio.toJson());
  }

  /// Elimina el recordatorio con el ID dado
  Future<void> eliminarRecordatorio(String id) {
    return _col.doc(id).delete();
  }

  /// Actualiza el recordatorio con el ID dado
  Future<void> editarRecordatorio(Recordatorio recordatorio) {
    return _col.doc(recordatorio.id).update(recordatorio.toJson());
  }
}
