import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ServicioFacial {
  ServicioFacial._();
  static final ServicioFacial instancia = ServicioFacial._();

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  late Interpreter _interpreter;

  Future<void> cargarModelo() async {
    _interpreter = await Interpreter.fromAsset('models/mobilefacenet.tflite');
  }

  Future<String?> capturarYSubir(File imagen) async {
    try {
      print('📷 Analizando imagen en: ${imagen.path}');
      final input = InputImage.fromFilePath(imagen.path);
      final rostros = await _detector.processImage(input);
      print('👤 Rostros detectados: ${rostros.length}');

      if (rostros.isEmpty) {
        print('⚠️ No se detectó ningún rostro en la imagen');
        return null;
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print('⚠️ Usuario no autenticado');
        return null;
      }
      final storageRef = FirebaseStorage.instance.ref(
        'perfiles_faciales/$uid.jpg',
      );
      final uploadTask = storageRef.putFile(imagen);
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).update(
          {'fotoPerfil': downloadUrl},
        );
        print('✅ Imagen subida y URL guardada en Firestore');
        return downloadUrl;
      } else {
        print('⚠️ Upload failed, state: ${snapshot.state}');
        return null;
      }
    } on FirebaseException catch (e) {
      print('🛑 FirebaseException: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected error: $e');
      return null;
    }
  }

  /// Verifica que el nuevo rostro coincida con el registrado
  /// con verificación básica de ángulo y tamaño.
  Future<bool> verificarRostroBasico(File nuevaImagen) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Obtener URL imagen referencia
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();
      final refUrl = doc.data()?['fotoPerfil'] as String?;
      if (refUrl == null) return false;

      final ref = FirebaseStorage.instance.refFromURL(refUrl);
      final bytes = await ref.getData();
      if (bytes == null) return false;

      final tempFile = File('${Directory.systemTemp.path}/${user.uid}_ref.jpg');
      await tempFile.writeAsBytes(bytes);

      final rostrosRef = await _detector.processImage(
        InputImage.fromFilePath(tempFile.path),
      );
      final rostrosNew = await _detector.processImage(
        InputImage.fromFilePath(nuevaImagen.path),
      );
      if (rostrosRef.isEmpty || rostrosNew.isEmpty) return false;

      final f1 = rostrosRef.first;
      final f2 = rostrosNew.first;
      final y1 = f1.headEulerAngleY ?? 0.0;
      final y2 = f2.headEulerAngleY ?? 0.0;
      final ratioW = (f1.boundingBox.width / f2.boundingBox.width).abs();
      final ratioH = (f1.boundingBox.height / f2.boundingBox.height).abs();
      final angleDiff = (y1 - y2).abs();

      print('🧠 Ángulo Y referencia: $y1');
      print('🧠 Ángulo Y nueva: $y2');
      print('📏 Ratio ancho: $ratioW');
      print('📏 Ratio alto: $ratioH');
      print('↩️ Diferencia de ángulo: $angleDiff');

      const maxRatio = 1.6;
      const maxAngle = 25.0;
      return (ratioW < maxRatio && ratioH < maxRatio && angleDiff < maxAngle);
    } catch (e) {
      print('❌ Error en verificarRostroBasico: $e');
      return false;
    }
  }

  /// Procesa una imagen para obtener embeddings faciales.
  Future<List<double>> procesarRostro(File imagen, Face face) async {
    final bytes = await imagen.readAsBytes();
    final image = img.decodeImage(bytes)!;

    final crop = img.copyCrop(
      image,
      x: face.boundingBox.left.toInt(),
      y: face.boundingBox.top.toInt(),
      width: face.boundingBox.width.toInt(),
      height: face.boundingBox.height.toInt(),
    );

    final resized = img.copyResizeCropSquare(crop, size: 112);

    final input = List.generate(
      112,
      (y) => List.generate(112, (x) {
        final pixel = resized.getPixel(x, y); // pixel es un Pixel object
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        return [(r - 128) / 128.0, (g - 128) / 128.0, (b - 128) / 128.0];
      }),
    );

    // Flatten input to 1D float32
    final inputTensor = List<double>.filled(112 * 112 * 3, 0);
    int idx = 0;
    for (var row in input) {
      for (var pixel in row) {
        for (var val in pixel) {
          inputTensor[idx++] = val;
        }
      }
    }

    final output = List.filled(1 * 192, 0.0).reshape([1, 192]);
    _interpreter.run([inputTensor], output);
    return List<double>.from(output[0]);
  }

  /// Calcula distancia Euclidiana entre dos embeddings.
  double calcularDistancia(List<double> e1, List<double> e2) {
    double suma = 0.0;
    for (int i = 0; i < e1.length; i++) {
      suma += pow(e1[i] - e2[i], 2);
    }
    return sqrt(suma);
  }

  /// Verificación avanzada de rostro con embeddings.
  Future<bool> verificarRostroAvanzado(File nuevaImagen) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Obtener URL imagen referencia
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();
      final refUrl = doc.data()?['fotoPerfil'] as String?;
      if (refUrl == null) return false;

      final ref = FirebaseStorage.instance.refFromURL(refUrl);
      final bytes = await ref.getData();
      if (bytes == null) return false;

      final tempFile = File('${Directory.systemTemp.path}/${user.uid}_ref.jpg');
      await tempFile.writeAsBytes(bytes);

      // Detectar rostros en ambas imágenes
      final rostrosRef = await _detector.processImage(
        InputImage.fromFilePath(tempFile.path),
      );
      final rostrosNew = await _detector.processImage(
        InputImage.fromFilePath(nuevaImagen.path),
      );

      if (rostrosRef.isEmpty || rostrosNew.isEmpty) {
        print('❌ No se detectó rostro en alguna de las imágenes');
        return false;
      }

      // Obtener embeddings
      final embeddingRef = await procesarRostro(tempFile, rostrosRef.first);
      final embeddingNew = await procesarRostro(nuevaImagen, rostrosNew.first);

      final distancia = calcularDistancia(embeddingRef, embeddingNew);

      print('🔎 Distancia embeddings: $distancia');

      const umbral = 1.0; // Ajustar según pruebas
      return distancia < umbral;
    } catch (e) {
      print('❌ Error en verificarRostroAvanzado: $e');
      return false;
    }
  }
}
