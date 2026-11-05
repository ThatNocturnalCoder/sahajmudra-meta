import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import '../constants/isl_data.dart';
import '../services/progress_service.dart';
import '../services/ai_service.dart';
import '../services/meta_service.dart';

class TutorScreen extends StatefulWidget {
  final String letter;
  final bool autoAdvance;
  final VoidCallback? onCorrect;
  final String? customDescription;
  final bool isGreeting;
  final bool isNumber;

  const TutorScreen({
    super.key,
    required this.letter,
    this.autoAdvance = false,
    this.onCorrect,
    this.customDescription,
    this.isGreeting = false,
    this.isNumber = false,
  });

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  int _cameraIndex = 0;

  bool _isAnalyzing = false;
  bool _showSuccess = false;

  String _feedbackText = 'Show your hand in the frame';
  bool _isCorrect = false;
  int _currentScore = 0;
  int _sessionBest = 0;
  int _attemptCount = 0;

  Timer? _analysisTimer;
  Timer? _advanceTimer;

  String get _referenceImage {
  if (widget.isNumber) {
    return 'assets/images/numbers/${widget.letter}.png';
  } else if (widget.isGreeting) {
    return 'assets/images/greetings/${widget.letter}.png';
  }
  return 'assets/images/letters/${widget.letter.toUpperCase()}.png';
}

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      // Prefer back camera for hand gestures
      final backIdx = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back);
      await _startCamera(backIdx >= 0 ? backIdx : 0);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _startCamera(int index) async {
    try {
      final cam = _cameras[index % _cameras.length];
      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      await _cameraCtrl?.dispose();
      if (mounted) {
        setState(() {
          _cameraCtrl = ctrl;
          _cameraReady = true;
          _cameraIndex = index % _cameras.length;
        });
        _startAnalysisLoop();
      }
    } catch (e) {
      debugPrint('Camera start error: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _analysisTimer?.cancel();
    setState(() => _cameraReady = false);
    await _startCamera(_cameraIndex + 1);
  }

  void _startAnalysisLoop() {
  _analysisTimer?.cancel();
  _advanceTimer?.cancel();

  // First feedback after 2s
  Future.delayed(const Duration(milliseconds: 2000), () {
    if (mounted && !_isAnalyzing && _cameraReady && !_showSuccess) {
      _captureAndAnalyze();
    }
  });

  // Repeat every 3s
  _analysisTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
    if (mounted && !_isAnalyzing && _cameraReady && !_showSuccess) {
      _captureAndAnalyze();
    }
  });

  // Auto-advance after 8s regardless — for demo flow
}

    Future<void> _captureAndAnalyze() async {
    if (!_cameraReady || _cameraCtrl == null) return;
    if (!_cameraCtrl!.value.isInitialized) return;
    setState(() => _isAnalyzing = true);

    try {
      final description = widget.customDescription ??
          ISLData.letterDescriptions[widget.letter] ??
          ISLData.numberDescriptions[widget.letter] ??
          ISLData.greetingDescriptions[widget.letter] ??
          '';

      AIFeedback? feedback;

      // Meta Muse Spark vision feedback (needs MODEL_API_KEY via --dart-define)
      if (MetaService.isConfigured) {
        final shot = await _cameraCtrl!.takePicture();
        final bytes = await shot.readAsBytes();
        feedback = await MetaService.analyzeImage(
          letter: widget.letter,
          islDescription: description,
          imageBytes: bytes,
        );
      }

      // If the Meta call is unavailable or fails, fall back to the old scorer
      feedback ??= await AIService.analyzeSign(
        letter: widget.letter,
        islDescription: description,
        landmarks: null,
      );

      // Never let a "not correct" verdict pass the 70 threshold
      final score = feedback.isCorrect
          ? feedback.score
          : (feedback.score > 69 ? 69 : feedback.score);
      _applyFeedback(score: score, text: feedback.text);
    } catch (e) {
      debugPrint('Analyze error: $e');
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _applyFeedback({required int score, required String text}) {
  if (!mounted) return;
  setState(() {
    _currentScore = score;
    _isCorrect = score >= 70;
    _feedbackText = text;
    _isAnalyzing = false;
    _attemptCount++;
    if (score > _sessionBest) _sessionBest = score;
  });

  ProgressService.recordAttempt(widget.letter, score);

  // Only auto-advance if explicitly enabled AND score is genuinely good
  if (_isCorrect && widget.autoAdvance && _attemptCount >= 1) {
    setState(() => _showSuccess = true);
    _analysisTimer?.cancel();
    _advanceTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSuccess = false);
        widget.onCorrect?.call();
      }
    });
  }
}

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _advanceTimer?.cancel();
    _cameraCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      _buildReferenceCard(),
                      const SizedBox(height: 12),
                      _buildCameraSection(),
                      const SizedBox(height: 12),
                      _buildFeedbackCard(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Success overlay
          if (_showSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

    Widget _buildAppBar() {
    if (widget.autoAdvance) return const SizedBox.shrink(); // embedded: header lives in the practice screen
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Sign ${widget.letter}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Best: $_sessionBest%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Reference image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                _referenceImage,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    widget.letter,
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'HOW TO SIGN ${widget.letter}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.customDescription ?? ISLData.letterDescriptions[widget.letter] ?? '',
                  style: AppText.bodySmall.copyWith(
                      fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _cameraReady
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _cameraReady ? 'LIVE' : 'CAMERA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _cameraReady
                            ? AppColors.primary
                            : AppColors.textHint,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_cameraReady) ...[
                    const SizedBox(width: 8),
                    _PulsingDot(),
                  ],
                ],
              ),
              if (_cameras.length >= 2)
                GestureDetector(
                  onTap: _flipCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flip_camera_android,
                            size: 16,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Flip',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isCorrect
                    ? AppColors.success
                    : _cameraReady
                        ? AppColors.primary
                        : AppColors.divider,
                width: _cameraReady ? 2.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: _cameraReady && _cameraCtrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraCtrl!),
                        // Guide frame
                        Center(
                          child: Container(
                            width: 170,
                            height: 220,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        // Analyzing pill
                        if (_isAnalyzing)
                          Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Analysing...',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Score badge
                        if (_isCorrect && _attemptCount > 0)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('$_currentScore% ✓',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                              color: Colors.white54, strokeWidth: 2),
                          SizedBox(height: 12),
                          Text('Loading camera...',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    Color cardColor;
    Color textColor;
    IconData icon;

    if (_isAnalyzing) {
      cardColor = AppColors.primary.withValues(alpha: 0.08);
      textColor = AppColors.primary;
      icon = Icons.hourglass_empty;
    } else if (_isCorrect) {
      cardColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      icon = Icons.check_circle_outline;
    } else if (_attemptCount > 0) {
      cardColor = AppColors.accent.withValues(alpha: 0.1);
      textColor = AppColors.accent;
      icon = Icons.lightbulb_outline;
    } else {
      cardColor = AppColors.cardBg;
      textColor = AppColors.textSecondary;
      icon = Icons.pan_tool_outlined;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_attemptCount > 0) ...[
                  Row(
                    children: [
                      Text('$_currentScore%',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textColor)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _currentScore / 100,
                            minHeight: 6,
                            backgroundColor: AppColors.divider,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Text(_feedbackText,
                    style: TextStyle(
                        fontSize: 13, color: textColor, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 20),
            Text(
              'Correct! 🎉',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.autoAdvance
                  ? 'Moving to next letter...'
                  : 'Great job!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}