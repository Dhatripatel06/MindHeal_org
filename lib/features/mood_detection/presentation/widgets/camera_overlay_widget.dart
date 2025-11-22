import 'dart:math';

import 'package:flutter/material.dart';

class CameraOverlayWidget extends StatelessWidget {
  final List<Rect> detectedFaces;
  final Map<String, double> emotions;
  final bool showOverlay;

  const CameraOverlayWidget({
    Key? key,
    required this.detectedFaces,
    required this.emotions,
    required this.showOverlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showOverlay) return const SizedBox.shrink();

    return Stack(
      children: [
        // Face detection rectangles
        ...detectedFaces.map((face) => _buildFaceRect(face)),
        
        // Emotion overlay
        if (emotions.isNotEmpty)
          Positioned(
            top: 20,
            left: 20,
            child: _buildEmotionOverlay(),
          ),
        
        // Scanning animation
        if (showOverlay && detectedFaces.isEmpty)
          const Center(child: _ScanningAnimation()),
      ],
    );
  }

  Widget _buildFaceRect(Rect face) {
    return Positioned(
      left: face.left,
      top: face.top,
      child: Container(
        width: face.width,
        height: face.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.green,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Corner indicators
            _buildCornerIndicator(Alignment.topLeft),
            _buildCornerIndicator(Alignment.topRight),
            _buildCornerIndicator(Alignment.bottomLeft),
            _buildCornerIndicator(Alignment.bottomRight),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerIndicator(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildEmotionOverlay() {
    final topEmotion = emotions.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            topEmotion.key.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${(topEmotion.value * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningAnimation extends StatefulWidget {
  const _ScanningAnimation();

  @override
  State<_ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<_ScanningAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue.withOpacity(0.7),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              Transform.rotate(
                angle: _controller.value * 2 * pi,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        Colors.blue.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Scanning...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
