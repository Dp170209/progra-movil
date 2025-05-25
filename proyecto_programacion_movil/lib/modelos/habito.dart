class Habito {
  final String id;
  final DateTime fechaHora;

  Habito({required this.id, required this.fechaHora});

  Map<String, dynamic> toMap() {
    return {'id': id, 'fechaHora': fechaHora.toIso8601String()};
  }

  factory Habito.fromMap(Map<String, dynamic> map) {
    return Habito(id: map['id'], fechaHora: DateTime.parse(map['fechaHora']));
  }
}
