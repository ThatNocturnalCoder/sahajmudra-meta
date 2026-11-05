import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import '../constants/isl_data.dart';
import '../services/ai_service.dart';
import '../services/meta_service.dart';


class SetuScreen extends StatefulWidget {
  const SetuScreen({super.key});

  @override
  State<SetuScreen> createState() => _SetuScreenState();
}

class _SetuScreenState extends State<SetuScreen> {
  int _activeMode = -1; // -1=none, 0=sign→text, 1=voice→sign, 2=text→sign

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_pattern.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Setu 🌉',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Bridge between sign and speech',
                          style: AppText.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Mode selector tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _ModeTab(
                        icon: Icons.sign_language,
                        label: 'Sign→Text',
                        active: _activeMode == 0,
                        color: AppColors.primary,
                        onTap: () => setState(() =>
                            _activeMode = _activeMode == 0 ? -1 : 0),
                      ),
                      const SizedBox(width: 8),
                      _ModeTab(
                        icon: Icons.mic,
                        label: 'Voice→Sign',
                        active: _activeMode == 1,
                        color: AppColors.teal,
                        onTap: () => setState(() =>
                            _activeMode = _activeMode == 1 ? -1 : 1),
                      ),
                      const SizedBox(width: 8),
                      _ModeTab(
                        icon: Icons.keyboard,
                        label: 'Text→Sign',
                        active: _activeMode == 2,
                        color: const Color(0xFF6A1B9A),
                        onTap: () => setState(() =>
                            _activeMode = _activeMode == 2 ? -1 : 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _activeMode == 0
                      ? const _SignToTextMode()
                      : _activeMode == 1
                          ? const _TextToSignMode(key: ValueKey('voice'), voice: true)
                          : _activeMode == 2
                              ? const _TextToSignMode(key: ValueKey('text'))
                              : _buildIntro(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _SetuCard(
            icon: Icons.sign_language,
            title: 'Sign → Text',
            subtitle: 'Show a sign, get the word',
            color: AppColors.primary,
            onTap: () => setState(() => _activeMode = 0),
          ),
          const SizedBox(height: 14),
          _SetuCard(
            icon: Icons.mic_outlined,
            title: 'Voice → Sign',
            subtitle: 'Speak a letter or word, see its sign',
            color: AppColors.teal,
            onTap: () => setState(() => _activeMode = 1),
          ),
          const SizedBox(height: 14),
          _SetuCard(
            icon: Icons.keyboard_outlined,
            title: 'Text → Sign',
            subtitle: 'Type a letter or word, see its sign',
            color: const Color(0xFF6A1B9A),
            onTap: () => setState(() => _activeMode = 2),
          ),
        ],
      ),
    );
  }
}

// ── Mode 0: Sign → Text ──
class _SignToTextMode extends StatefulWidget {
  const _SignToTextMode();

  @override
  State<_SignToTextMode> createState() => _SignToTextModeState();
}

class _SignToTextModeState extends State<_SignToTextMode> {
  CameraController? _ctrl;
  bool _cameraReady = false;
  bool _scanning = false;
  String _detectedSign = '';
  String _detectedDesc = '';
  Timer? _scanTimer;
  bool _busy = false;
  int _confidence = 0;
  String _reason = '';

  // Only signs that are single, static handshapes with distinct descriptions.
  Map<String, String> _candidates() {
    final m = Map.of(ISLData.numberDescriptions);
    ISLData.letterDescriptions.forEach((k, v) {
      if (k != 'J' && k != 'Z') m[k] = v; // J and Z need movement
    });
    return m;
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final ctrl = CameraController(back, ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg);
    await ctrl.initialize();
    if (mounted) setState(() { _ctrl = ctrl; _cameraReady = true; });
  }

  void _startScan() {
    setState(() { _scanning = true; _detectedSign = ''; });
    _scanTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _detect();
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _detect();
    });
  }

  void _stopScan() {
    _scanTimer?.cancel();
    setState(() => _scanning = false);
  }

    Future<void> _detect() async {
    if (_busy || _ctrl == null || !_ctrl!.value.isInitialized) return;
    if (!MetaService.isConfigured) {
      setState(() => _reason = 'MODEL_API_KEY is not set.');
      return;
    }
    _busy = true;
    try {
      final shot = await _ctrl!.takePicture();
      final bytes = await shot.readAsBytes();
      final candidates = _candidates();
      final r = await MetaService.identifySign(
          imageBytes: bytes, candidates: candidates);
      if (!mounted) return;
      if (r == null) {
        setState(() {
          _detectedSign = '';
          _reason = 'Could not reach the AI. Try again.';
        });
        return;
      }
      final sign = r['sign'] as String;
      final conf = (r['confidence'] as num).toInt();
      final why = (r['reason'] ?? '') as String;
      setState(() {
        if (sign == 'NONE' || conf < 50) {
          _detectedSign = '';
          _detectedDesc = '';
          _reason = 'No clear sign found. $why';
        } else {
          _detectedSign = sign;
          _detectedDesc = candidates[sign] ?? '';
          _confidence = conf;
          _reason = why;
        }
      });
    } catch (e) {
      debugPrint('Detect error: $e');
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Camera
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _scanning ? AppColors.primary : AppColors.divider,
                width: _scanning ? 2.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: _cameraReady && _ctrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_ctrl!),
                        if (_scanning)
                          Center(
                            child: Container(
                              width: 160,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white54, strokeWidth: 2)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cameraReady
                  ? (_scanning ? _stopScan : _startScan)
                  : null,
              icon: Icon(_scanning ? Icons.stop : Icons.search),
              label: Text(_scanning ? 'Stop' : 'Detect Sign'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _scanning ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
          if (_detectedSign.isEmpty && _reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_reason, style: AppText.bodySmall),
          ],
          if (_detectedSign.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/images/letters/$_detectedSign.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(_detectedSign,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detected: $_detectedSign ($_confidence%)',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success)),
                        const SizedBox(height: 4),
                        Text(_detectedDesc,
                            style: AppText.bodySmall
                                .copyWith(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Mode 1 & 2: Text → Sign (voice: true adds a microphone) ──
class _TextToSignMode extends StatefulWidget {
  final bool voice;
  const _TextToSignMode({super.key, this.voice = false});

  @override
  State<_TextToSignMode> createState() => _TextToSignModeState();
}

class _TextToSignModeState extends State<_TextToSignMode> {
  final _controller = TextEditingController();
  final _recorder = AudioRecorder();
  List<_SignResult> _results = [];
  bool _recording = false;
  bool _transcribing = false;
  String _status = '';

  static const _numWords = {
    'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
    'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
  };

  String _normalize(String s) {
    final words = s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    return words.map((w) => _numWords[w] ?? w).join(' ');
  }

  void _convert() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    final results = <_SignResult>[];

    String? greeting;
    for (final k in ISLData.greetingDescriptions.keys) {
      if (k.toLowerCase() == input.toLowerCase()) greeting = k;
    }
    if (greeting != null) {
      results.add(_SignResult(
        display: greeting,
        imagePath: 'assets/images/greetings/$greeting.png',
        description: ISLData.greetingDescriptions[greeting]!,
      ));
    } else {
      for (final char in input.toUpperCase().split('')) {
        if (ISLData.letterDescriptions.containsKey(char)) {
          results.add(_SignResult(
            display: char,
            imagePath: 'assets/images/letters/$char.png',
            description: ISLData.letterDescriptions[char]!,
          ));
        } else if (ISLData.numberDescriptions.containsKey(char)) {
          results.add(_SignResult(
            display: char,
            imagePath: 'assets/images/numbers/$char.png',
            description: ISLData.numberDescriptions[char]!,
          ));
        }
      }
    }
    setState(() => _results = results);
  }

  Future<void> _toggleRecord() async {
    if (_transcribing) return;
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _transcribing = true;
        _status = 'Transcribing...';
      });
      String? text;
      if (path != null) text = await MetaService.transcribe(path);
      if (!mounted) return;
      setState(() => _transcribing = false);
      if (text == null || text.isEmpty) {
        setState(() => _status = 'Could not understand. Please try again.');
        return;
      }
      setState(() => _status = 'Heard: "$text"');
      _controller.text = _normalize(text).toUpperCase();
      _convert();
    } else {
      if (!await _recorder.hasPermission()) {
        setState(() => _status = 'Microphone permission denied.');
        return;
      }
      final dir = await getTemporaryDirectory();
      await _recorder.start(
        const RecordConfig(
            encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        path: '${dir.path}/setu_voice.wav',
      );
      setState(() {
        _recording = true;
        _status = 'Listening... tap again to stop';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.voice
                        ? 'Tap the mic and say a word or number'
                        : 'Type any word and see it spelled in ISL',
                    style: AppText.bodySmall),
                const SizedBox(height: 12),
                if (widget.voice) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleRecord,
                      icon: Icon(_recording ? Icons.stop : Icons.mic),
                      label: Text(_recording
                          ? 'Stop'
                          : (_transcribing ? 'Working...' : 'Speak')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _recording ? AppColors.error : AppColors.teal,
                      ),
                    ),
                  ),
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_status, style: AppText.bodySmall),
                  ],
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'e.g. ISL, INDIA, 123',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _convert(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _convert,
                      child: const Text('Convert'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
                'Showing ${_results.length} sign${_results.length > 1 ? 's' : ''}:',
                style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _results.map((r) {
                return Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.asset(
                            r.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(r.display,
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(r.display,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
  }
}

class _SignResult {
  final String display;
  final String imagePath;
  final String description;
  const _SignResult({
    required this.display,
    required this.imagePath,
    required this.description,
  });
}

// ── Supporting widgets ──
class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.12)
                : AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.4)
                  : AppColors.divider,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: active ? color : AppColors.textHint,
                  size: 20),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color:
                          active ? color : AppColors.textHint)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetuCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SetuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.bodySmall),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}