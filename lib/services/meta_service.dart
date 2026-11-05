import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart'; // ignore: depend_on_referenced_packages
import 'ai_service.dart';


class MetaService {
  // Passed at run time with --dart-define, never saved in the code.
  static const String _apiKey = String.fromEnvironment('MODEL_API_KEY');
  static const String _url = 'https://api.meta.ai/v1/chat/completions';
  static const String _model = 'muse-spark-1.3';

  static bool get isConfigured => _apiKey.isNotEmpty;
  static bool _isCalling = false;

  static const Map<String, dynamic> _schema = {
    'type': 'object',
    'properties': {
      'correct': {'type': 'boolean'},
      'score': {'type': 'integer', 'description': '0-100 match to the target handshape'},
      'issues': {'type': 'array', 'items': {'type': 'string'}},
      'tip': {'type': 'string', 'description': 'one short, kind correction'},
    },
    'required': ['correct', 'score', 'issues', 'tip'],
  };

  static const String _system =
      'You are a sign language practice coach. Compare the learner\'s hand in the photo '
      'to the target handshape. Be strict and accurate: reserve 90-100 for a clearly correct '
      'shape. If the image is blurry or the hand is missing or partly out of frame, say so '
      'and set correct to false. Judge the handshape only; ignore left/right hand and '
      'mirroring. Make the tip consistent with the score: only say "close" above 60, and '
      'below 40 say what to change first. Only describe what you can actually see.';
    /// Speech → text with Muse Voice Transcribe. [wavPath]: mono 16-bit PCM WAV.
  static Future<String?> transcribe(String wavPath) async {
    if (!isConfigured) return null;
    try {
      final req = http.MultipartRequest(
          'POST', Uri.parse('https://api.meta.ai/v1/asr/transcribe'));
      req.headers['Authorization'] = 'Bearer $_apiKey';
      req.files.add(http.MultipartFile.fromString(
        'request',
        jsonEncode({
          'mode': 'PUSH_TO_TALK',
          'model': 'muse-voice-transcribe-1.0',
          'audioEncoding': 'WAV',
          'languageBias': ['English'],
          'keywords': ['Namaste', 'ISL', 'India'],
        }),
        contentType: MediaType('application', 'json'),
      ));
      req.files.add(await http.MultipartFile.fromPath('audio', wavPath));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        debugPrint('ASR ${streamed.statusCode}: $body');
        return null;
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      return (data['transcript'] as String?)?.trim();
    } catch (e) {
      debugPrint('ASR error: $e');
      return null;
    }
  }

  /// Returns null if the call fails, so the caller can fall back to the local scorer.
  static Future<AIFeedback?> analyzeImage({
    required String letter,
    required String islDescription,
    required Uint8List imageBytes,
  }) async {
    if (!isConfigured || _isCalling) return null;
    _isCalling = true;
    try {
      final b64 = base64Encode(imageBytes);
      final body = {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': _system},
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Target sign: $letter. Target handshape: $islDescription '
                    'How close is the learner\'s hand?'
              },
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$b64'}
              },
            ],
          },
        ],
        'response_format': {
          'type': 'json_schema',
          'json_schema': {'name': 'SignFeedback', 'schema': _schema},
        },
      };

      final res = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = decoded['choices'][0]['message']['content'] as String;
      final data = jsonDecode(content) as Map<String, dynamic>;
      final score = (data['score'] as num).toInt().clamp(0, 100);
      return AIFeedback(
        text: data['tip'] as String,
        score: score,
        isCorrect: data['correct'] == true && score >= 70,
      );
    } catch (_) {
      return null;
    } finally {
      _isCalling = false;
    }
  }
    /// Sign → Text: returns the closest sign key from [candidates] (key → description),
  /// or null on failure. Result map: {'sign': 'L', 'confidence': 85, 'reason': '...'}
  static Future<Map<String, dynamic>?> identifySign({
    required Uint8List imageBytes,
    required Map<String, String> candidates,
  }) async {
    if (!isConfigured || _isCalling) return null;
    _isCalling = true;
    try {
      final list = candidates.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      final schema = {
        'type': 'object',
        'properties': {
          'sign': {
            'type': 'string',
            'enum': [...candidates.keys, 'NONE'],
          },
          'confidence': {'type': 'integer', 'description': '0-100'},
          'reason': {'type': 'string', 'description': 'one short sentence on what you see'},
        },
        'required': ['sign', 'confidence', 'reason'],
      };
      final body = {
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': 'You identify Indian Sign Language handshapes from a photo. '
                'Choose the ONE sign from the list whose description best matches the hand. '
                'If no hand is visible, or nothing matches well, answer NONE with low confidence. '
                'Judge handshape only, and only describe what you can actually see.'
          },
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Candidate signs:\n$list\n\nWhich sign is the person making?'},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,${base64Encode(imageBytes)}'}
              },
            ],
          },
        ],
        'response_format': {
          'type': 'json_schema',
          'json_schema': {'name': 'SignGuess', 'schema': schema},
        },
      };
      final res = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = decoded['choices'][0]['message']['content'] as String;
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    } finally {
      _isCalling = false;
    }
  }
}