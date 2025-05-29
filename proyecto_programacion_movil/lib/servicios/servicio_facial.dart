import 'dart:io';
import 'dart:math'; // Para usar sqrt
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ServicioFacialEmbeddings {
  static final ServicioFacialEmbeddings instancia =
      ServicioFacialEmbeddings._();
  late Interpreter _interpreter;

  ServicioFacialEmbeddings._();

  Future<void> cargarModelo() async {
    _interpreter = await Interpreter.fromAsset('models/mobilefacenet.tflite');
  }

  Future<List<double>> procesarRostro(File imagen, Face face) async {
    final bytes = await imagen.readAsBytes();
    final image = img.decodeImage(bytes)!;

    // Recortamos el rostro detectado
    final crop = img.copyCrop(
      image,
      x: face.boundingBox.left.toInt(),
      y: face.boundingBox.top.toInt(),
      width: face.boundingBox.width.toInt(),
      height: face.boundingBox.height.toInt(),
    );

    // Redimensionamos a 112x112
    final resized = img.copyResizeCropSquare(crop, size: 112);

    // Convertimos a Float32 normalizado
    final input = List.generate(
      112,
      (y) => List.generate(112, (x) {
        final pixel = resized.getPixel(x, y); // Pixel object
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        return [(r - 128) / 128.0, (g - 128) / 128.0, (b - 128) / 128.0];
      }),
    );

    final inputTensor = [
      for (var row in input)
        for (var pixel in row) ...pixel,
    ];

    final output = List.filled(192, 0.0).reshape([1, 192]);

    _interpreter.run([inputTensor], output);
    return List<double>.from(output[0]);
  }

  double calcularDistancia(List<double> e1, List<double> e2) {
    double suma = 0.0;
    for (int i = 0; i < e1.length; i++) {
      suma += pow(e1[i] - e2[i], 2);
    }
    return sqrt(suma);
  }
}
