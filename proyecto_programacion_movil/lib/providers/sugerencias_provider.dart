import 'package:flutter/material.dart';
import '../repositorios/repositorio_habito.dart';

class SugerenciasProvider extends ChangeNotifier {
  Map<int, int> _histograma = {};
  int? _mejorHora;
  int _tareasHoy = 0;
  bool _sobrecargado = false;
  bool _loading = true;

  Map<int, int> get histograma => _histograma;
  int? get mejorHora => _mejorHora;
  int get tareasHoy => _tareasHoy;
  bool get sobrecargado => _sobrecargado;
  bool get loading => _loading;

  SugerenciasProvider() {
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    _loading = true;
    notifyListeners();
    try {
      final repo = RepositorioHabitos();
      final hist = await repo.conteoPorHora();
      final mh = await repo.mejorHora();
      final horaActual = DateTime.now().hour;
      final tareasHoyLocal = hist[horaActual] ?? 0;

      _histograma = hist;
      _mejorHora = mh;
      _tareasHoy = tareasHoyLocal;
      _sobrecargado = tareasHoyLocal > 5;
    } catch (e) {
      print('Error cargando datos: $e');
      _histograma = {};
      _mejorHora = null;
      _tareasHoy = 0;
      _sobrecargado = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
