import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../providers/ai_meal_logging_providers.dart';
import 'ai_meal_confirmation_page.dart';

/// Modern AI photo meal capture page with Riverpod state management
class AIPhotoMealPage extends ConsumerStatefulWidget {
  const AIPhotoMealPage({super.key});

  @override
  ConsumerState<AIPhotoMealPage> createState() => _AIPhotoMealPageState();
}

class _AIPhotoMealPageState extends ConsumerState<AIPhotoMealPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final ImagePicker _imagePicker = ImagePicker();

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

    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        ref.read(aIMealPhotoNotifierProvider.notifier).setPermissions(false);
        return;
      }
    }

    ref.read(aIMealPhotoNotifierProvider.notifier).setPermissions(true);

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
          ref
              .read(aIMealPhotoNotifierProvider.notifier)
              .setCameraInitialized(true);
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

      ref
          .read(aIMealPhotoNotifierProvider.notifier)
          .setSelectedImage(savedImage);
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

        ref
            .read(aIMealPhotoNotifierProvider.notifier)
            .setSelectedImage(savedImage);
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
    print('🔍 [UI] Analyze button clicked - starting analysis flow');

    final state = ref.read(aIMealPhotoNotifierProvider);
    if (state.selectedImage == null) {
      print('❌ [UI] No image selected, canceling analysis');
      return;
    }

    print('✅ [UI] Image selected: ${state.selectedImage!.path}');
    print('📤 [UI] Calling analyzeMealPhoto on provider...');

    await ref.read(aIMealPhotoNotifierProvider.notifier).analyzeMealPhoto();

    // Navigate to confirmation page if analysis was successful
    final updatedState = ref.read(aIMealPhotoNotifierProvider);
    print(
      '📥 [UI] Analysis completed. Result: ${updatedState.analysisResult?.isSuccessful ?? false}',
    );

    if (updatedState.analysisResult != null) {
      if (updatedState.analysisResult!.isSuccessful) {
        print(
          '✅ [UI] Analysis successful! Found ${updatedState.analysisResult!.recognizedItems.length} items',
        );
        if (mounted) {
          print('🚀 [UI] Navigating to confirmation page...');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AIMealConfirmationPage(
                analysisResult: updatedState.analysisResult!,
                imageFile: updatedState.selectedImage!,
              ),
            ),
          );
        } else {
          print('⚠️ [UI] Widget not mounted, skipping navigation');
        }
      } else {
        print(
          '❌ [UI] Analysis failed: ${updatedState.analysisResult!.errorMessage}',
        );
      }
    } else {
      print('❌ [UI] No analysis result returned');
      if (updatedState.errorMessage != null) {
        print('❌ [UI] Error message: ${updatedState.errorMessage}');
      }
    }
  }

  void _retakePhoto() {
    ref.read(aIMealPhotoNotifierProvider.notifier).setSelectedImage(null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aIMealPhotoNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Photo Meal Logging'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: state.selectedImage == null
            ? _buildCameraView(state)
            : _buildImagePreview(state),
      ),
    );
  }

  Widget _buildCameraView(AIMealPhotoState state) {
    if (!state.hasPermissions) {
      return _buildPermissionDenied();
    }

    if (!state.isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Tips section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips for better recognition:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              const Text('• Good lighting and clear view of all food items'),
              const Text('• Avoid cluttered backgrounds'),
              const Text('• Place food on a contrasting surface'),
              const Text('• Capture from directly above when possible'),
            ],
          ),
        ),

        // Camera preview
        Expanded(
          flex: 4,
          child: SizedBox(
            width: double.infinity,
            child: CameraPreview(_cameraController!),
          ),
        ),

        // Controls
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                FloatingActionButton(
                  heroTag: "gallery",
                  onPressed: _pickFromGallery,
                  backgroundColor: Colors.grey[600],
                  child: const Icon(Icons.photo_library),
                ),

                // Camera capture button
                FloatingActionButton.large(
                  heroTag: "camera",
                  onPressed: _takePicture,
                  backgroundColor: Colors.green[600],
                  child: const Icon(Icons.camera_alt, size: 32),
                ),

                // Switch camera button (placeholder)
                FloatingActionButton(
                  heroTag: "switch",
                  onPressed: () {}, // TODO: Implement camera switching
                  backgroundColor: Colors.grey[600],
                  child: const Icon(Icons.flip_camera_android),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(AIMealPhotoState state) {
    return Column(
      children: [
        // Image preview
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(state.selectedImage!, fit: BoxFit.contain),
            ),
          ),
        ),

        // Analysis status or error
        if (state.isAnalyzing)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Analyzing your meal...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'This may take a few seconds',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

        if (state.errorMessage != null && !state.isAnalyzing)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isAnalyzing ? null : _retakePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isAnalyzing ? null : _analyzeImage,
                  icon: state.isAnalyzing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(state.isAnalyzing ? 'Analyzing...' : 'Analyze'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Camera Permission Required',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'To use AI-powered meal logging, please grant camera permission in your device settings.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
