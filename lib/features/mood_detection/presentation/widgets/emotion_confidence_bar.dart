// import 'package:flutter/material.dart';

// class EmotionConfidenceBar extends StatefulWidget {
//   final String emotion;
//   final double confidence;
//   final Color color;

//   const EmotionConfidenceBar({
//     Key? key,
//     required this.emotion,
//     required this.confidence,
//     required this.color,
//   }) : super(key: key);

//   @override
//   State<EmotionConfidenceBar> createState() => _EmotionConfidenceBarState();
// }

// class _EmotionConfidenceBarState extends State<EmotionConfidenceBar>
//     with TickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _progressAnimation;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );
    
//     _progressAnimation = Tween<double>(begin: 0.0, end: widget.confidence).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
//       ),
//     );
    
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
//       ),
//     );
    
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ScaleTransition(
//       scale: _scaleAnimation,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 6),
//         child: Row(
//           children: [
//             // Emotion Label
//             SizedBox(
//               width: 85,
//               child: Text(
//                 _capitalizeFirst(widget.emotion),
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[700],
//                 ),
//               ),
//             ),
            
//             // Progress Bar Container
//             Expanded(
//               child: Container(
//                 height: 12,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: AnimatedBuilder(
//                   animation: _progressAnimation,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           widget.color.withOpacity(0.8),
//                           widget.color,
//                           widget.color.withOpacity(0.9),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                       boxShadow: [
//                         BoxShadow(
//                           color: widget.color.withOpacity(0.3),
//                           blurRadius: 6,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                   ),
//                   builder: (context, child) {
//                     return FractionallySizedBox(
//                       alignment: Alignment.centerLeft,
//                       widthFactor: _progressAnimation.value,
//                       child: child,
//                     );
//                   },
//                 ),
//               ),
//             ),
            
//             const SizedBox(width: 12),
            
//             // Percentage
//             Container(
//               width: 45,
//               alignment: Alignment.centerRight,
//               child: AnimatedBuilder(
//                 animation: _progressAnimation,
//                 builder: (context, child) {
//                   return Text(
//                     '${(_progressAnimation.value * 100).toInt()}%',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: widget.color,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _capitalizeFirst(String text) {
//     if (text.isEmpty) return text;
//     return text[0].toUpperCase() + text.substring(1);
//   }
// }



import 'package:flutter/material.dart';

class EmotionConfidenceBar extends StatelessWidget {
  final String emotion;
  final double confidence;
  final String emoji;

  const EmotionConfidenceBar({
    Key? key,
    required this.emotion,
    required this.confidence,
    required this.emoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  emotion.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getColorForEmotion(emotion),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForEmotion(emotion),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happiness':
        return const Color(0xFFFFD700); // Gold
      case 'surprise':
        return const Color(0xFFFF69B4); // Pink
      case 'neutral':
        return const Color(0xFF808080); // Gray
      case 'sadness':
        return const Color(0xFF4169E1); // Royal Blue
      case 'anger':
        return const Color(0xFFDC143C); // Crimson
      case 'fear':
        return const Color(0xFF9370DB); // Purple
      case 'disgust':
        return const Color(0xFF8B4513); // Brown
      default:
        return Colors.black;
    }
  }
}