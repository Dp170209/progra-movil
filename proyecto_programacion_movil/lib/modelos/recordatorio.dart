class Recordatorio {
  final String id;
  final String titulo;
  final DateTime fechaHora;
  final String estado;

  Recordatorio({
    required this.id,
    required this.titulo,
    required this.fechaHora,
    this.estado = 'pendiente',
  });

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'fechaHora': fechaHora.toIso8601String(),
    'estado': estado,
  };

  factory Recordatorio.fromJson(String id, Map<String, dynamic> json) {
    final fechaRaw = json['fechaHora'] as String;
    return Recordatorio(
      id: id,
      titulo: json['titulo'] ?? '',
      fechaHora: DateTime.parse(fechaRaw),
      estado: json['estado'] ?? 'pendiente',
    );
  }

  Recordatorio copyWith({String? titulo, DateTime? fechaHora, String? estado}) {
    return Recordatorio(
      id: id,
      titulo: titulo ?? this.titulo,
      fechaHora: fechaHora ?? this.fechaHora,
      estado: estado ?? this.estado,
    );
  }
}
