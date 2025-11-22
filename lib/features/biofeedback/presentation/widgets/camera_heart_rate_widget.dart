import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/camera_heart_rate_provider.dart';

class CameraHeartRateWidget extends StatefulWidget {
  final Function(int bpm, double confidence)? onMeasurementComplete;
  
  const CameraHeartRateWidget({
    super.key,
    this.onMeasurementComplete,
  });

  @override
  State<CameraHeartRateWidget> createState() => _CameraHeartRateWidgetState();
}

class _CameraHeartRateWidgetState extends State<CameraHeartRateWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraHeartRateProvider>().initializeCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraHeartRateProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Heart Rate Monitor'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: [
              if (provider.state == MeasurementState.measuring)
                IconButton(
                  onPressed: () => provider.stopMeasurement(),
                  icon: const Icon(Icons.stop),
                ),
            ],
          ),
          body: Column(
            children: [
              // Camera Preview Section
              Expanded(
                flex: 3,
                child: _buildCameraSection(context, provider),
              ),
              
              // Waveform Section
              Expanded(
                flex: 2,
                child: _buildWaveformSection(context, provider),
              ),
              
              // Controls Section
              Expanded(
                flex: 2,
                child: _buildControlsSection(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraSection(BuildContext context, CameraHeartRateProvider provider) {
    if (!provider.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        SizedBox.expand(
          child: CameraPreview(provider.controller!),
        ),
        
        // Overlay with finger placement guide
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
          ),
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _getStatusColor(provider.state),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint,
                    size: 60,
                    color: _getStatusColor(provider.state),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Place finger here',
                    style: TextStyle(
                      color: _getStatusColor(provider.state),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (provider.state == MeasurementState.measuring) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${provider.measurementProgress}/15s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformSection(BuildContext context, CameraHeartRateProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey),
        ),
      ),
      child: Column(
        children: [
          // BPM Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetricDisplay('BPM', provider.currentBPM.toString(), Colors.red),
              _buildMetricDisplay(
                'Confidence',
                '${(provider.confidence * 100).toInt()}%',
                Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Waveform Chart
          Expanded(
            child: provider.waveformData.isNotEmpty
                ? _buildWaveformChart(provider.waveformData)
                : const Center(
                    child: Text(
                      'Waveform will appear here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection(BuildContext context, CameraHeartRateProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey),
        ),
      ),
      child: Column(
        children: [
          // Status Message
          Text(
            provider.statusMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Control Buttons
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  context,
                  provider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(BuildContext context, CameraHeartRateProvider provider) {
    switch (provider.state) {
      case MeasurementState.idle:
        return ElevatedButton(
          onPressed: provider.isInitialized 
              ? () => provider.startMeasurement()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Start Measurement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        );

      case MeasurementState.measuring:
        return ElevatedButton(
          onPressed: () => provider.stopMeasurement(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Stop Measurement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        );

      case MeasurementState.completed:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (widget.onMeasurementComplete != null) {
                    widget.onMeasurementComplete!(
                      provider.currentBPM,
                      provider.confidence,
                    );
                  }
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save Result',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => provider.reset(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );

      case MeasurementState.error:
        return ElevatedButton(
          onPressed: () => provider.reset(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Try Again',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricDisplay(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformChart(List<double> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        backgroundColor: Colors.transparent,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.2),
            ),
          ),
        ],
        minY: data.isNotEmpty ? data.reduce((a, b) => a < b ? a : b) - 10 : 0,
        maxY: data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) + 10 : 100,
      ),
    );
  }

  Color _getStatusColor(MeasurementState state) {
    switch (state) {
      case MeasurementState.idle:
        return Colors.white;
      case MeasurementState.measuring:
        return Colors.green;
      case MeasurementState.completed:
        return Colors.blue;
      case MeasurementState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
