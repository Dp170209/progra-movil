import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_programacion_movil/pantallas/pantalla_inicio.dart';
import '../servicios/servicios.dart';
import 'package:flutter/widgets.dart';

class RegistroFacialProvider extends ChangeNotifier {
  CameraController? _controller;
  bool _isLoading = false;
  String _message = '';
  bool _initialized = false;

  CameraController? get controller => _controller;
  bool get isLoading => _isLoading;
  String get message => _message;
  bool get initialized => _initialized;

  RegistroFacialProvider() {
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final camController = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = camController;
      await camController.initialize();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      _message = 'Error al inicializar cámara: $e';
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> tomarSelfie(BuildContext context) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _isLoading = true;
    _message = '';
    notifyListeners();

    try {
      final XFile foto = await _controller!.takePicture();
      final File archivo = File(foto.path);

      final url = await ServicioFacial.instancia.capturarYSubir(archivo);
      if (url == null) {
        _message =
            '❌ No se detectó rostro o hubo un error al subir la imagen.\nAsegúrate de que haya buena luz y tu rostro esté centrado.';
        notifyListeners();
      } else {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'fotoPerfil': url,
        }, SetOptions(merge: true));
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder:
                  (_, animation, __) => FadeTransition(
                    opacity: animation,
                    child: const PantallaInicio(),
                  ),
            ),
          );
        }
      }
    } catch (e) {
      _message = 'Error al procesar la imagen: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
