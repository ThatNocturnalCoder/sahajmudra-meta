import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class LandmarkPoint {
  final double x, y, z;
  const LandmarkPoint(this.x, this.y, this.z);
  Map<String, double> toMap() => {'x': x, 'y': y, 'z': z};
}

class BrainResponse {
  final String feedbackText;
  final int confidenceScore; // 0-100
  final bool isCorrect;
  final String? audioUrl;

  const BrainResponse({
    required this.feedbackText,
    required this.confidenceScore,
    required this.isCorrect,
    this.audioUrl,
  });

  factory BrainResponse.fromJson(Map<String, dynamic> json) => BrainResponse(
    feedbackText: json['feedback'] as String? ?? 'Keep practicing!',
    confidenceScore: json['score'] as int? ?? 0,
    isCorrect: (json['score'] as int? ?? 0) >= 70,
    audioUrl: json['audio_url'] as String?,
  );

  factory BrainResponse.error() => const BrainResponse(
    feedbackText: 'Could not connect to AI. Check your internet.',
    confidenceScore: 0,
    isCorrect: false,
  );

  factory BrainResponse.noHand() => const BrainResponse(
    feedbackText: 'No hand detected. Show your hand clearly to the camera.',
    confidenceScore: 0,
    isCorrect: false,
  );
}

class BrainService {
  // Replace with your actual API Gateway invoke URL after Lambda setup
  static const String _apiUrl = 'YOUR_API_GATEWAY_URL';

  static final AudioPlayer _player = AudioPlayer();
  static bool _isCalling = false;

  static Future<BrainResponse> analyzeLandmarks({
    required String targetLetter,
    required List<LandmarkPoint> landmarks,
  }) async {
    if (_isCalling) return BrainResponse.noHand();
    if (landmarks.isEmpty) return BrainResponse.noHand();

    _isCalling = true;
    try {
      final payload = {
        'letter': targetLetter,
        'landmarks': landmarks.map((l) => l.toMap()).toList(),
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = BrainResponse.fromJson(data);
        if (result.audioUrl != null) {
          await _player.play(UrlSource(result.audioUrl!));
        }
        return result;
      }
      return BrainResponse.error();
    } catch (_) {
      return BrainResponse.error();
    } finally {
      _isCalling = false;
    }
  }

  static void dispose() => _player.dispose();
}