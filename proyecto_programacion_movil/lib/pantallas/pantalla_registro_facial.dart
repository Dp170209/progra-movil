// lib/pantallas/pantalla_registro_facial.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../servicios/servicios.dart';
import 'pantalla_inicio.dart';

/// Pantalla para capturar y registrar la foto de perfil facial.
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
    if (mounted) setState(() {});
  }

  /// Helper para transición fade
  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder:
          (_, animation, __) => FadeTransition(opacity: animation, child: page),
    );
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

      // Procesa y sube si hay rostro
      final exito = await ServicioFacial.instancia.capturarYRegistrar(archivo);
      if (!exito) {
        setState(() {
          _message =
              '❌ No se detectó rostro o hubo un error al subir la imagen.\nAsegúrate de que haya buena luz y tu rostro esté centrado.';
        });
      } else {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushReplacement(_fadeRoute(const PantallaInicio()));
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
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF3D3D3D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vista previa de cámara con overlay guía
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
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white70,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                            _message.isEmpty
                                ? Positioned(
                                  bottom:
                                      MediaQuery.of(context).size.height * 0.4,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    'Alinea tu rostro aquí',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                )
                                : Container(),
                          ],
                        ),
              ),
              // Sección de controles
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    if (_message.isNotEmpty)
                      Text(
                        _message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                onPressed: _tomarSelfie,
                                icon: const Icon(Icons.camera_alt, size: 24),
                                label: const Text('Capturar Selfie'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed:
                          () => Navigator.of(
                            context,
                          ).pushReplacement(_fadeRoute(const PantallaInicio())),
                      child: const Text('Omitir (más tarde)'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
