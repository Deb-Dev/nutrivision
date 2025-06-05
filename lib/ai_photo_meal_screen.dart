import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'services/ai_food_recognition_service.dart';
import 'ai_meal_confirmation_screen.dart';

class AIPhotoMealScreen extends StatefulWidget {
  const AIPhotoMealScreen({super.key});

  @override
  State<AIPhotoMealScreen> createState() => _AIPhotoMealScreenState();
}

class _AIPhotoMealScreenState extends State<AIPhotoMealScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _hasPermissions = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // AI Analysis state
  bool _isAnalyzing = false;
  FoodRecognitionResult? _analysisResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    // Check permissions first
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;

    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        setState(() => _hasPermissions = false);
        return;
      }
    }

    if (!photosStatus.isGranted) {
      await Permission.photos.request();
    }

    setState(() => _hasPermissions = true);

    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();

      // Copy to app documents directory for persistent storage
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'meal_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(
        image.path,
      ).copy(path.join(appDir.path, fileName));

      setState(() {
        _selectedImage = savedImage;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        // Copy to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'meal_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(
          image.path,
        ).copy(path.join(appDir.path, fileName));

        setState(() {
          _selectedImage = savedImage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      // Initialize AI service if needed
      if (!AIFoodRecognitionService.isAvailable) {
        await AIFoodRecognitionService.initialize();
      }

      // Analyze the image
      final result = await AIFoodRecognitionService.analyzeMealPhoto(
        _selectedImage!,
      );

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      if (result.isSuccessful && result.recognizedItems.isNotEmpty) {
        // Navigate to results screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                _AIResultsScreen(image: _selectedImage!, result: result),
          ),
        );
      } else {
        // Show error or no results found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorMessage ?? 'No food items detected in the image',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisResult = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions) {
      return _buildPermissionsScreen();
    }

    if (_selectedImage != null) {
      return _buildImagePreviewScreen();
    }

    return _buildCameraScreen();
  }

  Widget _buildPermissionsScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Photo Meal Logging'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Camera permission required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please grant camera and photo permissions to use AI meal logging',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Grant Permissions'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open App Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Meal Photo'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library),
            tooltip: 'Select from Gallery',
          ),
        ],
      ),
      body: Column(
        children: [
          // Photography Tips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tips: Use good lighting, take photo from above, ensure food is clearly visible',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Camera Preview
          Expanded(
            child: _isCameraInitialized
                ? CameraPreview(_cameraController!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Initializing camera...'),
                      ],
                    ),
                  ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade300,
                  child: IconButton(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library, size: 28),
                  ),
                ),

                // Capture button
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green,
                  child: IconButton(
                    onPressed: _isCameraInitialized ? _takePicture : null,
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Switch camera button (for future enhancement)
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade300,
                  child: IconButton(
                    onPressed: () {
                      // TODO: Implement camera switching
                    },
                    icon: const Icon(Icons.flip_camera_android, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Photo Preview'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _retakePhoto,
            icon: const Icon(Icons.refresh),
            tooltip: 'Retake Photo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Preview
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_selectedImage!, fit: BoxFit.contain),
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Analyze Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeImage,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.psychology),
                    label: Text(
                      _isAnalyzing ? 'Analyzing...' : 'Analyze with AI',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Retake Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _retakePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Retake Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// AI Results Screen to display analysis results
class _AIResultsScreen extends StatelessWidget {
  final File image;
  final FoodRecognitionResult result;

  const _AIResultsScreen({required this.image, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis Results'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Save/Log meal functionality (User Story 3.3)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Save meal functionality coming in next story!',
                  ),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: const Icon(Icons.save),
            tooltip: 'Save Meal',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(image, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 16),

            // Analysis Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Analysis Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${result.recognizedItems.length} food item${result.recognizedItems.length != 1 ? 's' : ''} detected',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Analysis completed in ${result.processingTime.toStringAsFixed(1)}s',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recognized Food Items
            const Text(
              'Recognized Food Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...result.recognizedItems.map((item) => _buildFoodItemCard(item)),

            const SizedBox(height: 16),

            // Total Nutrition Summary
            _buildNutritionSummary(),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit & Adjust'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AIMealConfirmationScreen(
                            image: image,
                            aiResult: result,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Meal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemCard(RecognizedFoodItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(
                      item.confidence,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(item.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(item.confidence),
                    ),
                  ),
                ),
              ],
            ),

            if (item.estimatedServing.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.straighten, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Estimated: ${item.estimatedServing}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],

            // Nutrition info if available
            const SizedBox(height: 8),
            const Divider(),
            _buildNutritionInfo(item.nutritionalEstimate),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInfo(NutritionalEstimate nutrition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutritional Estimate',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNutrientChip(
              'Calories',
              '${nutrition.calories.toStringAsFixed(0)} kcal',
              Colors.orange,
            ),
            _buildNutrientChip(
              'Protein',
              '${nutrition.protein.toStringAsFixed(1)}g',
              Colors.red,
            ),
            _buildNutrientChip(
              'Carbs',
              '${nutrition.carbs.toStringAsFixed(1)}g',
              Colors.blue,
            ),
            _buildNutrientChip(
              'Fat',
              '${nutrition.fat.toStringAsFixed(1)}g',
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutrientChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var item in result.recognizedItems) {
      totalCalories += item.nutritionalEstimate.calories;
      totalProtein += item.nutritionalEstimate.protein;
      totalCarbs += item.nutritionalEstimate.carbs;
      totalFat += item.nutritionalEstimate.fat;
    }

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Total Meal Nutrition',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalNutrient(
                  'Calories',
                  '${totalCalories.toStringAsFixed(0)} kcal',
                  Colors.orange,
                ),
                _buildTotalNutrient(
                  'Protein',
                  '${totalProtein.toStringAsFixed(1)}g',
                  Colors.red,
                ),
                _buildTotalNutrient(
                  'Carbs',
                  '${totalCarbs.toStringAsFixed(1)}g',
                  Colors.blue,
                ),
                _buildTotalNutrient(
                  'Fat',
                  '${totalFat.toStringAsFixed(1)}g',
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalNutrient(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
