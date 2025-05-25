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

  Future<void> registrarHabito(String recordatorioId, String titulo) async {
    final habito = Habito(
      id: recordatorioId,
      fechaHora: DateTime.now(),
      titulo: titulo,
    );
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

  Future<Map<String, int>> conteoPorTitulo() async {
    final habitos = await obtenerHabitos();
    final mapa = <String, int>{};
    for (var h in habitos) {
      final titulo = h.titulo.trim();
      if (titulo.isEmpty) continue;
      mapa[titulo] = (mapa[titulo] ?? 0) + 1;
    }
    return mapa;
  }

  Future<String?> habitoMasFrecuente() async {
    final conteo = await conteoPorTitulo();
    if (conteo.isEmpty) return null;
    return conteo.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Future<String?> tituloMasRepetido() async {
    final habitos = await obtenerHabitos();
    if (habitos.isEmpty) return null;

    final mapa = <String, int>{};
    for (var h in habitos) {
      final t = h.titulo.trim();
      if (t.isEmpty) continue;
      mapa[t] = (mapa[t] ?? 0) + 1;
    }

    return mapa.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
