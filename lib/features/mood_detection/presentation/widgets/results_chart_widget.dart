import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ResultsChartWidget extends StatefulWidget {
  final Map<String, double> emotionData;

  const ResultsChartWidget({Key? key, required this.emotionData}) : super(key: key);

  @override
  State<ResultsChartWidget> createState() => _ResultsChartWidgetState();
}

class _ResultsChartWidgetState extends State<ResultsChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    touchedIndex = -1;
                    return;
                  }
                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: _buildPieChartSections(),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final emotions = widget.emotionData.entries.toList();
    
    return emotions.asMap().entries.map((entry) {
      final index = entry.key;
      final emotion = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final opacity = _animationController.value;

      return PieChartSectionData(
        color: _getEmotionColor(emotion.key).withOpacity(opacity),
        value: emotion.value * 100,
        title: isTouched ? '${emotion.key}\n${(emotion.value * 100).toInt()}%' : '${(emotion.value * 100).toInt()}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'fear':
        return Colors.orange;
      case 'surprise':
        return Colors.purple;
      case 'disgust':
        return Colors.brown;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
