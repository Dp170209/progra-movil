// lib/repositorios/repositorio_habitos.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modelos/habito.dart';

class RepositorioHabitos {
  CollectionReference<Map<String, dynamic>> get _colHabitos {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('habitos');
  }

  Future<void> registrarHabito(String recordatorioId) async {
    final habito = Habito(id: recordatorioId, fechaHora: DateTime.now());
    await _colHabitos.doc(recordatorioId).set(habito.toMap());
  }

  Future<void> eliminarHabito(String recordatorioId) async {
    await _colHabitos.doc(recordatorioId).delete();
  }

  Future<List<Habito>> obtenerHabitos() async {
    final snap = await _colHabitos.get();
    return snap.docs.map((d) => Habito.fromMap(d.data())).toList();
  }

  Future<Map<int, int>> conteoPorHora() async {
    final habitos = await obtenerHabitos();
    final mapa = <int, int>{};
    for (var h in habitos) {
      final hora = h.fechaHora.hour;
      mapa[hora] = (mapa[hora] ?? 0) + 1;
    }
    return mapa;
  }

  Future<int?> mejorHora() async {
    final mapa = await conteoPorHora();
    if (mapa.isEmpty) return null;
    return mapa.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
