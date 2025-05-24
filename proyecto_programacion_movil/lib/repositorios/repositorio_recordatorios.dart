import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/recordatorio.dart';

class RepositorioRecordatorios {
  final _ref = FirebaseFirestore.instance.collection('recordatorios');

Stream<List<Recordatorio>> obtenerRecordatorios(String uid) {
  return _ref.where('uid', isEqualTo: uid).snapshots().map(
    (snapshot) {
      print('📦 Firestore envió ${snapshot.docs.length} documentos.');
      for (final doc in snapshot.docs) {
        print('📝 Doc: ${doc.id} => ${doc.data()}');
      }

      return snapshot.docs.map((doc) {
        try {
          return Recordatorio.fromJson(doc.id, doc.data());
        } catch (e) {
          print('❌ Error al parsear recordatorio: ${doc.id} – $e');
          return null;
        }
      }).whereType<Recordatorio>().toList(); // Filtra los null
    },
  );
}



 Future<void> agregarRecordatorio(Recordatorio recordatorio) async {
  await _ref.add(recordatorio.toJson());
}


  Future<void> eliminarRecordatorio(String id) async {
    await _ref.doc(id).delete();
  }

  Future<void> editarRecordatorio(Recordatorio recordatorio) async {
    await _ref.doc(recordatorio.id).set(recordatorio.toJson());
  }
}
