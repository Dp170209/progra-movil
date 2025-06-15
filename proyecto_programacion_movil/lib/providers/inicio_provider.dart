import 'dart:async';
import 'package:flutter/material.dart';

class InicioProvider extends ChangeNotifier {
  static const List<String> _quotes = [
    'El éxito es la suma de pequeños esfuerzos repetidos día tras día.',
    'No cuentes los días, haz que los días cuenten.',
    'La productividad es la clave del mañana.',
  ];
  static const List<String> _tips = [
    'Técnica Pomodoro: 25 min trabajo + 5 min descanso.',
    'Pausa y estira cada hora.',
    'Organiza tareas de 5 en 5 para evitar sobrecarga.',
  ];

  int _quoteIndex = 0;
  int _tipIndex = 0;
  Timer? _timer;

  int get quoteIndex => _quoteIndex;
  int get tipIndex => _tipIndex;
  String get currentQuote => _quotes[_quoteIndex];
  String get currentTip => _tips[_tipIndex];

  InicioProvider() {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _quoteIndex = (_quoteIndex + 1) % _quotes.length;
      _tipIndex = (_tipIndex + 1) % _tips.length;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
