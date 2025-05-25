// lib/modelos/recordatorio.dart
class Recordatorio {
  final String id;
  final String titulo;
  final DateTime fechaHora;

  Recordatorio({
    required this.id,
    required this.titulo,
    required this.fechaHora,
  });

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'fechaHora': fechaHora.toIso8601String(),
    // ya no necesitas 'uid'
  };

  factory Recordatorio.fromJson(String id, Map<String, dynamic> json) {
    final fechaRaw = json['fechaHora'] as String;
    return Recordatorio(
      id: id,
      titulo: json['titulo'] ?? '',
      fechaHora: DateTime.parse(fechaRaw),
    );
  }
}
