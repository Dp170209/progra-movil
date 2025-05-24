class Recordatorio {
  final String id;
  final String titulo;
  final DateTime fechaHora;
  final String uid;

  Recordatorio({
    required this.id,
    required this.titulo,
    required this.fechaHora,
    required this.uid,
  });

Map<String, dynamic> toJson() => {
  'titulo': titulo,
  'fechaHora': fechaHora.toIso8601String(),
  'uid': uid,
};



factory Recordatorio.fromJson(String id, Map<String, dynamic> json) {
  try {
    final fechaRaw = json['fechaHora'];

    return Recordatorio(
      id: id,
      titulo: json['titulo'] ?? '',
      fechaHora: DateTime.parse(fechaRaw), // Esto puede fallar si está mal formateado
      uid: json['uid'] ?? '',
    );
  } catch (e) {
    rethrow;
  }
}

}
