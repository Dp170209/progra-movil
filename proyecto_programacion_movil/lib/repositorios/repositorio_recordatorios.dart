import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/recordatorio.dart';

class RepositorioRecordatorios {
  final _ref = FirebaseFirestore.instance.collection('recordatorios');

Stream<List<Recordatorio>> obtenerRecordatorios(String uid) {
  return _ref.where('uid', isEqualTo: uid).snapshots().map(
    (snapshot) {

      return snapshot.docs.map((doc) {
        try {
          return Recordatorio.fromJson(doc.id, doc.data());
        } catch (e) {
          return null;
        }
      }).whereType<Recordatorio>().toList(); 
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
  await _ref.doc(recordatorio.id).update(recordatorio.toJson());
}

}
