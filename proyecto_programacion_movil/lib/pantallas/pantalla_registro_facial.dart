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
  _PantallaRegistroFacialState createState() => _PantallaRegistroFacialState();
}

class _PantallaRegistroFacialState extends State<PantallaRegistroFacial> {
  late List<CameraDescription> _camaras;
  CameraController? _controller;
  bool _cargando = false;
  String _mensaje = '';

  @override
  void initState() {
    super.initState();
    _initCamaras();
  }

  Future<void> _initCamaras() async {
    _camaras = await availableCameras();
    final camaraFrontal = _camaras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _camaras.first,
    );
    _controller = CameraController(
      camaraFrontal,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _tomarSelfie() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _cargando = true;
      _mensaje = '';
    });
    try {
      final XFile foto = await _controller!.takePicture();
      final File archivo = File(foto.path);
      final url = await ServicioFacial.instancia.capturarYSubir(archivo);
      if (url == null) {
        setState(() => _mensaje = 'No se detectó ningún rostro en la foto.');
      } else {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'fotoPerfil': url,
        }, SetOptions(merge: true));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => _mensaje = 'Error al procesar la imagen: $e');
    } finally {
      setState(() => _cargando = false);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Registro facial')),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
          const SizedBox(height: 16),
          if (_mensaje.isNotEmpty)
            Text(_mensaje, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          _cargando
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                onPressed: _tomarSelfie,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capturar selfie'),
              ),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            child: const Text('Omitir (más tarde)'),
          ),
        ],
      ),
    );
  }
}
