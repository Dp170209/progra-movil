import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pantalla_inicio.dart';
import 'package:provider/provider.dart';
import '../providers/registro_facial_provider.dart';

class PantallaRegistroFacial extends StatelessWidget {
  const PantallaRegistroFacial({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RegistroFacialProvider>();
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
              Expanded(
                child:
                    !prov.initialized
                        ? const Center(child: CircularProgressIndicator())
                        : (prov.controller == null ||
                            !prov.controller!.value.isInitialized)
                        ? Center(
                          child:
                              prov.message.isNotEmpty
                                  ? Text(
                                    prov.message,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.redAccent,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                  : const CircularProgressIndicator(),
                        )
                        : Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(prov.controller!),
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
                            prov.message.isEmpty
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
                    if (prov.message.isNotEmpty)
                      Text(
                        prov.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child:
                          prov.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                onPressed: () => prov.tomarSelfie(context),
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
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 500,
                            ),
                            pageBuilder:
                                (_, animation, __) => FadeTransition(
                                  opacity: animation,
                                  child: const PantallaInicio(),
                                ),
                          ),
                        );
                      },
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
