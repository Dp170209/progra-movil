// lib/servicios/servicios.dart
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as img;

class ServicioFacial {
  ServicioFacial._();
  static final instancia = ServicioFacial._();

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  late final Interpreter _interpreter;

  Future<void> init() async {
    _interpreter = await Interpreter.fromAsset('models/facenet.tflite');
  }

  Future<bool> capturarYRegistrar(File imagen) async {
    final input = InputImage.fromFilePath(imagen.path);
    final rostros = await _detector.processImage(input);
    if (rostros.isEmpty) return false;
    final bbox = rostros.first.boundingBox;

    final tensorImage = await _preprocesar(imagen, bbox);

    final embedding = _runModel(tensorImage);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref('perfiles_faciales/$uid.jpg');
    await ref.putFile(imagen);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      'fotoPerfil': url,
      'faceEmbedding': embedding,
    }, SetOptions(merge: true));

    return true;
  }

  Future<bool> verificarRostro(File nuevaImagen, {double umbral = 1.0}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
    final stored = doc.data()?['faceEmbedding'] as List<dynamic>?;
    if (stored == null) return false;
    final List<double> embeddingRef =
        stored.map((e) => (e as num).toDouble()).toList();
    final input = InputImage.fromFilePath(nuevaImagen.path);
    final rostrosNew = await _detector.processImage(input);
    if (rostrosNew.isEmpty) return false;
    final tensorImage = await _preprocesar(
      nuevaImagen,
      rostrosNew.first.boundingBox,
    );
    final embeddingNew = _runModel(tensorImage);

    double sum = 0;
    for (int i = 0; i < embeddingRef.length; i++) {
      final diff = embeddingRef[i] - embeddingNew[i];
      sum += diff * diff;
    }
    final distancia = sqrt(sum);

    return distancia < umbral;
  }

  Future<TensorImage> _preprocesar(File file, Rect bbox) async {
    final bytes = await file.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception("No se pudo decodificar la imagen.");
    }

    final crop = img.copyCrop(
      original,
      bbox.left.toInt().clamp(0, original.width - 1),
      bbox.top.toInt().clamp(0, original.height - 1),
      bbox.width.toInt().clamp(0, original.width - bbox.left.toInt()),
      bbox.height.toInt().clamp(0, original.height - bbox.top.toInt()),
    );

    final resized = img.copyResize(crop, width: 160, height: 160);
    final tensorImage = TensorImage.fromImage(resized);
    final processor =
        ImageProcessorBuilder().add(NormalizeOp(127.5, 127.5)).build();

    return processor.process(tensorImage);
  }

  List<double> _runModel(TensorImage image) {
    final outputShape = [1, 128];
    final outputBuffer = TensorBuffer.createFixedSize(
      outputShape,
      TfLiteType.float32,
    );
    _interpreter.run(image.buffer, outputBuffer.buffer);
    return outputBuffer.getDoubleList();
  }

  void dispose() {
    _detector.close();
    _interpreter.close();
  }
}
