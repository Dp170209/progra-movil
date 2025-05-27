// lib/pantallas/pantalla_registro_facial.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../servicios/servicios.dart';

class PantallaRegistroFacial extends StatefulWidget {
  const PantallaRegistroFacial({super.key});

  @override
  State<PantallaRegistroFacial> createState() => _PantallaRegistroFacialState();
}

class _PantallaRegistroFacialState extends State<PantallaRegistroFacial> {
  CameraController? _controller;
  bool _isLoading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _tomarSelfie() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _isLoading = true;
      _message = '';
    });
    try {
      // Captura la foto
      final XFile foto = await _controller!.takePicture();
      final File archivo = File(foto.path);

      // ServicioFacial.detecta rostros y sube la imagen
      final url = await ServicioFacial.instancia.capturarYSubir(archivo);
      if (url == null) {
        setState(() {
          _message = 'No se detectó ningún rostro. Intenta de nuevo.';
        });
      } else {
        // Guarda la URL en Firestore
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .set({'fotoPerfil': url}, SetOptions(merge: true));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _message = 'Error al procesar la imagen: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Registro Facial')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vista previa de la cámara
          Expanded(child: CameraPreview(_controller!)),

          // Mensajes de estado
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // Botón de captura
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capturar Selfie'),
                    onPressed: _tomarSelfie,
                  ),
          ),

          // Omitir registro
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            child: const Text('Omitir (más tarde)'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
