import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../servicios/servicios.dart';

class PantallaLoginFacial extends StatefulWidget {
  const PantallaLoginFacial({super.key});

  @override
  State<PantallaLoginFacial> createState() => _PantallaLoginFacialState();
}

class _PantallaLoginFacialState extends State<PantallaLoginFacial> {
  CameraController? _controller;
  int _intentos = 0;
  bool _cargando = false;
  String _mensaje = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _verificar() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _cargando = true;
      _mensaje = '';
    });

    try {
      final foto = await _controller!.takePicture();
      final archivo = File(foto.path);

      final coincide = await ServicioFacial.instancia.verificarRostroAvanzado(
        archivo,
      );
      if (!mounted) return;

      if (coincide) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _intentos++;
        if (_intentos >= 3) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          setState(() {
            _mensaje = 'El rostro no coincide. Intento $_intentos de 3.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _mensaje = 'Error al capturar o verificar: $e';
      });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación Facial')),
      body: Column(
        children: [
          Expanded(
            child:
                _controller == null || !_controller!.value.isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_controller!),
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white70,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
          if (_mensaje.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _mensaje,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _cargando ? null : _verificar,
                  icon: const Icon(Icons.face),
                  label: const Text('Verificar rostro'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Omitir rostro y usar correo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
