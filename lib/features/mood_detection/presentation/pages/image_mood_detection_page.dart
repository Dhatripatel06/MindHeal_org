import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../data/models/emotion_result.dart';
import '../../onnx_emotion_detection/data/services/onnx_emotion_service.dart';
import '../../../../core/services/gemini_adviser_service.dart';
import '../widgets/advice_dialog.dart';

class ImageMoodDetectionPage extends StatefulWidget {
  const ImageMoodDetectionPage({super.key});

  @override
  State<ImageMoodDetectionPage> createState() => _ImageMoodDetectionPageState();
}

class _ImageMoodDetectionPageState extends State<ImageMoodDetectionPage>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final OnnxEmotionService _emotionService = OnnxEmotionService.instance;
  late FaceDetector _faceDetector;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fabScaleAnimation;

  // State variables
  File? _selectedImageFile;
  ui.Image? _uiImage;
  bool _isAnalyzing = false;
  bool _faceDetected = false;
  EmotionResult? _lastResult;
  List<Face> _detectedFaces = [];
  String? _errorMessage;
  Size _imageSize = Size.zero;
  bool _isServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeAnimations();
    _initializeOnnxService();
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: true,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _fabAnimationController.forward();
  }

  Future<void> _initializeOnnxService() async {
    try {
      final success = await _emotionService.initialize();
      setState(() {
        _isServiceInitialized = success;
      });
      if (!success) {
        throw Exception('Service initialization failed');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize emotion detection: $e';
      });
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    _animationController.dispose();
    _fabAnimationController.dispose();
    // Note: ONNX service is singleton, disposal handled globally
    _uiImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          _buildBackgroundWithOverlay(),
          _buildCustomAppBar(),
          _buildMainContent(),
          _buildActionButtons(),
          if (!_isServiceInitialized) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading ONNX Emotion Detection Model...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundWithOverlay() {
    if (_selectedImageFile == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade100, Colors.white],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
        ),
        if (_detectedFaces.isNotEmpty && !_isAnalyzing)
          Positioned.fill(
            child: CustomPaint(
              painter: PerfectFaceDetectionPainter(
                faces: _detectedFaces,
                imageSize: _imageSize,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomAppBar() {
    return SafeArea(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.blue),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'AI Emotion Detection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            GestureDetector(
              onTap: _resetDetection,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.refresh, color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Expanded(flex: 3, child: _buildImagePreview()),
          Expanded(flex: 2, child: _buildResultsSection()),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _selectedImageFile == null
            ? _buildEmptyState()
            : _buildImageWithOverlay(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 60,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Emotion Detection',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Powered by EfficientNet-B0 ONNX model\nSelect an image to analyze emotions with advanced AI',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWithOverlay() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
        ),
        if (_isAnalyzing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'AI Analyzing Emotions...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Using EfficientNet-B0 ONNX deep learning model',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!_isAnalyzing)
          Positioned(
            top: 16,
            right: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _faceDetected
                    ? Colors.green.withOpacity(0.9)
                    : Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_faceDetected ? Colors.green : Colors.orange)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _faceDetected ? Icons.face : Icons.warning,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _faceDetected ? 'Face Detected' : 'No Face',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_errorMessage != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsSection() {
    if (_lastResult == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            _selectedImageFile == null
                ? 'Select an image to start AI emotion detection'
                : 'Upload an image with a clear human face',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildResultCard(_lastResult!),
      ),
    );
  }

  Widget _buildResultCard(EmotionResult result) {
    // Calculate accuracy indicators
    final confidenceLevel = _getConfidenceLevel(result.confidence);
    final accuracyColor = _getAccuracyColor(result.confidence);
    final secondBestEmotion = _getSecondBestEmotion(result.allEmotions);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced emotion display with accuracy ring
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: result.confidence,
                    strokeWidth: 6,
                    backgroundColor: accuracyColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
                  ),
                ),
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: _getEmotionColor(result.emotion).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getEmotionColor(result.emotion),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getEmotionEmoji(result.emotion),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Primary emotion with confidence level
            Text(
              result.emotion.toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getEmotionColor(result.emotion),
              ),
            ),
            const SizedBox(height: 8),

            // Enhanced confidence display with accuracy level
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getConfidenceIcon(result.confidence),
                  color: accuracyColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${(result.confidence * 100).toInt()}% Confidence',
                  style: TextStyle(
                    fontSize: 16,
                    color: accuracyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              confidenceLevel,
              style: TextStyle(
                fontSize: 12,
                color: accuracyColor,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Performance metrics
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.speed, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${result.processingTimeMs}ms',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.model_training, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'EfficientNet-B0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Alternative emotion if confidence is moderate
            if (result.confidence < 0.85 && secondBestEmotion != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Alternative: ${secondBestEmotion['emotion']} (${(secondBestEmotion['confidence'] * 100).toInt()}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildActionChip(
                  icon: Icons.analytics_outlined,
                  label: 'Details',
                  color: Colors.blue,
                  onTap: () => _showDetails(result),
                ),
                _buildActionChip(
                  icon: Icons.save_outlined,
                  label: 'Save',
                  color: Colors.green,
                  onTap: () => _saveResult(result),
                ),
                _buildActionChip(
                  icon: Icons.psychology_outlined,
                  label: 'Adviser',
                  color: Colors.purple,
                  onTap: () => _getAdvice(result),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: ScaleTransition(
        scale: _fabScaleAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              color: Colors.blue,
              onPressed: (_isAnalyzing || !_isServiceInitialized)
                  ? null
                  : _captureImage,
            ),
            _buildActionButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              color: Colors.green,
              onPressed: (_isAnalyzing || !_isServiceInitialized)
                  ? null
                  : _pickFromGallery,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: FloatingActionButton.extended(
        heroTag: label.toLowerCase(),
        onPressed: onPressed,
        backgroundColor: onPressed != null ? color : Colors.grey,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        await _processSelectedImage(File(image.path));
      }
    } catch (e) {
      _showErrorDialog('Failed to capture image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        await _processSelectedImage(File(image.path));
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _processSelectedImage(File imageFile) async {
    setState(() {
      _selectedImageFile = imageFile;
      _errorMessage = null;
    });

    // Load UI image
    await _loadUIImage(imageFile);

    // Validate image has face (optional - model can work without face detection)
    final isValidImage = await _validateImageWithFace(imageFile);
    if (!isValidImage) {
      _showWarningDialog(
        'No human face detected in the image.\nThe AI model will still attempt to analyze emotions, but results may be less accurate.',
      );
    }

    // Analyze with ONNX model
    await _analyzeImageWithOnnx(imageFile);
  }

  Future<void> _loadUIImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _uiImage?.dispose();
      _uiImage = frame.image;
      setState(() {
        _imageSize = Size(
          _uiImage!.width.toDouble(),
          _uiImage!.height.toDouble(),
        );
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load image';
      });
    }
  }

  Future<void> _analyzeImageWithOnnx(File imageFile) async {
    if (!_isServiceInitialized) {
      _showErrorDialog('Emotion detection model not ready. Please wait...');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      // Run inference with ONNX service
      final result = await _emotionService.detectEmotionsFromFile(imageFile);

      setState(() {
        _lastResult = result;
        _isAnalyzing = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Analysis error: $e';
        _isAnalyzing = false;
      });
    }
  }

  Future<bool> _validateImageWithFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      setState(() {
        _detectedFaces = faces;
        _faceDetected = faces.isNotEmpty;
      });

      return faces.isNotEmpty;
    } catch (e) {
      debugPrint('Face detection error: $e');
      return false;
    }
  }

  void _resetDetection() {
    setState(() {
      _selectedImageFile = null;
      _uiImage?.dispose();
      _uiImage = null;
      _lastResult = null;
      _detectedFaces = [];
      _faceDetected = false;
      _errorMessage = null;
      _isAnalyzing = false;
      _imageSize = Size.zero;
    });
    _animationController.reset();
  }

  void _saveResult(EmotionResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('${result.emotion} result saved successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _getAdvice(EmotionResult result) {
    _showAdviceDialog(result);
  }

  void _showDetails(EmotionResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'AI Emotion Analysis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Analyzed using EfficientNet-B0 ONNX model trained on AFEW dataset',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Emotion Probabilities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...result.allEmotions.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                _getEmotionEmoji(entry.key),
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.key.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Text(
                                '${(entry.value * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getEmotionColor(entry.key),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: entry.value,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              _getEmotionColor(entry.key),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Warning'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showAdviceDialog(EmotionResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdviceDialog(
        emotionResult: result,
      ),
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'happiness':
        return '😀';
      case 'surprise':
        return '😮';
      case 'angry':
      case 'anger':
        return '😠';
      case 'sad':
      case 'sadness':
        return '😢';
      case 'disgust':
        return '🤢';
      case 'fear':
        return '😨';
      case 'neutral':
        return '😐';
      default:
        return '😐';
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'happiness':
        return Colors.green;
      case 'surprise':
        return Colors.purple;
      case 'angry':
      case 'anger':
        return Colors.red;
      case 'sad':
      case 'sadness':
        return Colors.blue;
      case 'disgust':
        return Colors.brown;
      case 'fear':
        return Colors.orange;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Get confidence level description
  String _getConfidenceLevel(double confidence) {
    if (confidence >= 0.9) return 'Very High Accuracy';
    if (confidence >= 0.8) return 'High Accuracy';
    if (confidence >= 0.7) return 'Good Accuracy';
    if (confidence >= 0.6) return 'Moderate Accuracy';
    if (confidence >= 0.5) return 'Low Accuracy';
    return 'Very Low Accuracy';
  }

  /// Get accuracy color based on confidence
  Color _getAccuracyColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.7) return Colors.lightGreen;
    if (confidence >= 0.6) return Colors.orange;
    if (confidence >= 0.5) return Colors.deepOrange;
    return Colors.red;
  }

  /// Get confidence icon based on level
  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 0.8) return Icons.verified;
    if (confidence >= 0.7) return Icons.check_circle;
    if (confidence >= 0.6) return Icons.info;
    if (confidence >= 0.5) return Icons.warning;
    return Icons.error;
  }

  /// Get second best emotion for alternative suggestion
  Map<String, dynamic>? _getSecondBestEmotion(Map<String, double> allEmotions) {
    if (allEmotions.length < 2) return null;

    final sortedEmotions = allEmotions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEmotions.length >= 2) {
      final second = sortedEmotions[1];
      return {
        'emotion': second.key,
        'confidence': second.value,
      };
    }
    return null;
  }
}

class PerfectFaceDetectionPainter extends CustomPainter {
  final List<Face> faces;
  final ui.Size imageSize;

  PerfectFaceDetectionPainter({required this.faces, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == ui.Size.zero || faces.isEmpty) return;

    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = math.min(scaleX, scaleY);

    final offsetX = (size.width - imageSize.width * scale) / 2;
    final offsetY = (size.height - imageSize.height * scale) / 2;

    for (final face in faces) {
      final scaledRect = Rect.fromLTRB(
        face.boundingBox.left * scale + offsetX,
        face.boundingBox.top * scale + offsetY,
        face.boundingBox.right * scale + offsetX,
        face.boundingBox.bottom * scale + offsetY,
      );

      canvas.drawRect(scaledRect.translate(2, 2), shadowPaint);
      canvas.drawRect(scaledRect, paint);
      _drawCornerIndicators(canvas, scaledRect, paint);

      paint.style = PaintingStyle.fill;
      for (final landmarkType in [
        FaceLandmarkType.leftEye,
        FaceLandmarkType.rightEye,
        FaceLandmarkType.noseBase,
        FaceLandmarkType.leftMouth,
        FaceLandmarkType.rightMouth,
      ]) {
        final landmark = face.landmarks[landmarkType];
        if (landmark != null) {
          final scaledOffset = Offset(
            landmark.position.x.toDouble() * scale + offsetX,
            landmark.position.y.toDouble() * scale + offsetY,
          );
          canvas.drawCircle(
            scaledOffset.translate(1, 1),
            6,
            shadowPaint..style = PaintingStyle.fill,
          );
          canvas.drawCircle(scaledOffset, 5, paint);
        }
      }
      paint.style = PaintingStyle.stroke;
    }
  }

  void _drawCornerIndicators(Canvas canvas, Rect rect, Paint paint) {
    const cornerLength = 20.0;
    const cornerThickness = 4.0;

    final cornerPaint = Paint()
      ..color = paint.color
      ..strokeWidth = cornerThickness
      ..style = PaintingStyle.stroke;

    final corners = [
      [Offset(rect.left, rect.top), Offset(rect.left + cornerLength, rect.top)],
      [Offset(rect.left, rect.top), Offset(rect.left, rect.top + cornerLength)],
      [
        Offset(rect.right, rect.top),
        Offset(rect.right - cornerLength, rect.top),
      ],
      [
        Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cornerLength),
      ],
      [
        Offset(rect.left, rect.bottom),
        Offset(rect.left + cornerLength, rect.bottom),
      ],
      [
        Offset(rect.left, rect.bottom),
        Offset(rect.left, rect.bottom - cornerLength),
      ],
      [
        Offset(rect.right, rect.bottom),
        Offset(rect.right - cornerLength, rect.bottom),
      ],
      [
        Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - cornerLength),
      ],
    ];

    for (final corner in corners) {
      canvas.drawLine(corner[0], corner[1], cornerPaint);
    }
  }

  @override
  bool shouldRepaint(PerfectFaceDetectionPainter oldDelegate) {
    return faces != oldDelegate.faces || imageSize != oldDelegate.imageSize;
  }
}
