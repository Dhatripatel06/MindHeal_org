import 'dart:math';
import 'package:flutter/material.dart';

class WaveformVisualizer extends StatefulWidget {
  final List<double> audioData;
  final bool isRecording;
  final Color color;

  const WaveformVisualizer({
    Key? key,
    required this.audioData,
    required this.isRecording,
    required this.color,
  }) : super(key: key);

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: WaveformPainter(
          audioData: widget.audioData,
          isRecording: widget.isRecording,
          color: widget.color,
          animation: _animationController,
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> audioData;
  final bool isRecording;
  final Color color;
  final Animation<double> animation;
  final Random _random = Random();

  WaveformPainter({
    required this.audioData,
    required this.isRecording,
    required this.color,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barWidth = 3.0;
    final barSpacing = 2.0;
    final totalBarWidth = barWidth + barSpacing;
    final barCount = (size.width / totalBarWidth).floor();

    for (int i = 0; i < barCount; i++) {
      final x = i * totalBarWidth;
      double height;

      if (isRecording) {
        // Generate animated random heights for recording
        height = (_random.nextDouble() * 0.7 + 0.3) * size.height * 0.8;
      } else if (audioData.isNotEmpty) {
        // Use actual audio data
        final dataIndex = (i * audioData.length / barCount).floor();
        if (dataIndex < audioData.length) {
          height = audioData[dataIndex].abs() * size.height * 0.8;
        } else {
          height = 0;
        }
      } else {
        // Static state
        height = size.height * 0.1;
      }

      // Add some animation variation
      if (isRecording) {
        height *= (0.8 + 0.4 * sin(animation.value * 2 * pi + i * 0.5));
      }

      final rect = Rect.fromCenter(
        center: Offset(x + barWidth / 2, centerY),
        width: barWidth,
        height: height,
      );

      // Gradient effect
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.8),
          color.withOpacity(0.3),
        ],
      );

      paint.shader = gradient.createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.audioData != audioData ||
           oldDelegate.isRecording != isRecording ||
           oldDelegate.color != color;
  }
}
