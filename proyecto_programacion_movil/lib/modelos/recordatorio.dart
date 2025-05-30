class Recordatorio {
  final String id;
  final String titulo;
  final DateTime fechaHora;
  final String estado;
  final String prioridad;
  

  Recordatorio({
    required this.id,
    required this.titulo,
    required this.fechaHora,
    this.estado = 'pendiente',
    this.prioridad = 'Media',
  });

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'fechaHora': fechaHora.toIso8601String(),
    'estado': estado,
    'prioridad': prioridad,
  };

  factory Recordatorio.fromJson(String id, Map<String, dynamic> json) {
    final fechaRaw = json['fechaHora'] as String;
    return Recordatorio(
      id: id,
      titulo: json['titulo'] ?? '',
      fechaHora: DateTime.parse(fechaRaw),
      estado: json['estado'] ?? 'pendiente',
      prioridad: json['prioridad'] ?? 'Media',
    );
  }

  Recordatorio copyWith({String? titulo, DateTime? fechaHora, String? estado, String? prioridad,}) {
    return Recordatorio(
      id: id,
      titulo: titulo ?? this.titulo,
      fechaHora: fechaHora ?? this.fechaHora,
      estado: estado ?? this.estado,
      prioridad: prioridad ?? this.prioridad,
    );
  }
}