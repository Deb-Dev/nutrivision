import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    print('✅ Environment loaded successfully');
  } catch (e) {
    print('❌ Error loading environment: $e');
    return;
  }

  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  print(
    '🔑 API Key: ${apiKey.isEmpty ? 'EMPTY' : '${apiKey.substring(0, 10)}...'}',
  );

  if (apiKey.isEmpty) {
    print('❌ No API key found');
    return;
  }

  try {
    // Test creating the model
    final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
    print('✅ Model created successfully');

    // Test a simple text generation
    final response = await model.generateContent([
      Content.text('Say "Hello, NutriVision!" if you can read this message.'),
    ]);

    print('✅ API Response: ${response.text}');
    print('🎉 Gemini AI service is working correctly!');
  } catch (e) {
    print('❌ Error testing Gemini AI: $e');
  }
}
