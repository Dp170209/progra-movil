class Habito {
  final String id;
  final DateTime fechaHora;
  final String titulo;

  Habito({required this.id, required this.fechaHora, required this.titulo});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fechaHora': fechaHora.toIso8601String(),
      'titulo': titulo,
    };
  }

  factory Habito.fromMap(Map<String, dynamic> map) {
    return Habito(
      id: map['id'],
      fechaHora: DateTime.parse(map['fechaHora']),
      titulo: map['titulo'] ?? '',
    );
  }
}
