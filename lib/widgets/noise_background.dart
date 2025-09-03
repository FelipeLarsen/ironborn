// ARQUIVO ATUALIZADO: lib/widgets/noise_background.dart

import 'dart:math';
import 'dart:typed_data'; // NOVO: Import necessário para Uint8List
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class NoiseBackground extends StatefulWidget {
  final double opacity;
  const NoiseBackground({super.key, this.opacity = 0.1});

  @override
  State<NoiseBackground> createState() => _NoiseBackgroundState();
}

class _NoiseBackgroundState extends State<NoiseBackground> {
  ui.Image? _noiseImage;

  @override
  void initState() {
    super.initState();
    _createNoiseImage();
  }

  void _createNoiseImage() async {
    const int width = 128;
    const int height = 128;
    final random = Random();
    // ALTERADO: A lista de píxeis agora é um Uint8List.
    final pixels = Uint8List(width * height * 4);
    for (int i = 0; i < pixels.length; i += 4) {
      // Canais R, G, B continuam a 0 (preto).
      pixels[i] = 0;
      pixels[i + 1] = 0;
      pixels[i + 2] = 0;
      // Canal Alfa (transparência) é um valor aleatório.
      pixels[i + 3] = random.nextInt(256);
    }

    // A chamada a decodeImageFromPixels agora funciona corretamente.
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (image) {
        if (mounted) {
          setState(() {
            _noiseImage = image;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_noiseImage == null) {
      return const SizedBox.shrink();
    }
    
    return Positioned.fill(
      child: Opacity(
        opacity: widget.opacity,
        child: CustomPaint(
          painter: _NoisePainter(_noiseImage!),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final ui.Image image;

  _NoisePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = ImageShader(
            image, TileMode.repeated, TileMode.repeated, Matrix4.identity().storage);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

