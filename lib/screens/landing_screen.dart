import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _spinCtrl;
  late AnimationController _scatterCtrl;
  late AnimationController _welcomeCtrl;
  late AnimationController _mandalaCtrl;
  late AnimationController _riseCtrl;

  static const _letters = ['A', 'C', 'E', 'H', 'M', 'S'];
  static const _hands = [
    's1.png','s2.png','s3.png','s4.png','s5.png',
    's6.png','s7.png','s8.png','s1.png','s3.png',
  ];
    // Logo placement that matches the Android system splash
  static const double _logoStart = 157; // logo width at app start
  static const double _logoEnd = 130; // logo width once Welcome shows
  static const double _navShift = 22; // half the nav-bar height; tune if the logo jumps
  static const double _letterR = 112; // letters' orbit radius
  static const double _handR = 180; // hands' orbit radius
  static const double _textDrop = 70; // how far the Welcome text moves down
  static const double _buttonFromBottom = 245; // button top, measured from screen bottom

  bool _showRings = false;
  bool _scattered = false;
  bool _showWelcome = false;

  final _rng = math.Random(42);
  List<Offset> _letterTargets = [];
  List<Offset> _handTargets = [];
  List<double> _letterSpinAngles = [];
  List<double> _handSpinAngles = [];

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _scatterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _welcomeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _mandalaCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _riseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    SchedulerBinding.instance
        .addPostFrameCallback((_) => _startSequence());
  }

  Future<void> _startSequence() async {
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    setState(() => _showRings = true);
    _spinCtrl.repeat();
    await Future.delayed(const Duration(milliseconds: 2000));

    _letterSpinAngles = List.generate(
        _letters.length,
        (i) =>
            (2 * math.pi * i / _letters.length) +
            (_spinCtrl.value * 2 * math.pi));
    _handSpinAngles = List.generate(
        _hands.length,
        (i) =>
            (2 * math.pi * i / _hands.length) -
            (_spinCtrl.value * 2 * math.pi));

    _spinCtrl.stop();
    _computeScatterTargets();
    setState(() => _scattered = true);
    await _scatterCtrl.forward();

    setState(() => _showWelcome = true);
    _riseCtrl.forward(); // logo glides up first
    _mandalaCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    _welcomeCtrl.forward(); // then text and button fade in
  }

  void _computeScatterTargets() {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    // Welcome content occupies roughly:
    // Logo: top=10%  height~130px → y: 0.10h to 0.10h+130
    // Text: top~27%  height~120px → y: 0.27h to 0.27h+120
    // Button: top~43% height~56px → y: 0.43h to 0.43h+56
    // Mandala: bottom ~200px → y: h-200 to h
    // So safe scatter zones are:
    // Left strip: x < 40
    // Right strip: x > w-60
    // Top strip: y < 0.09h
    // Between logo bottom and text top: y: 0.10h+130 to 0.25h
    // Between button bottom and mandala top: y: 0.50h to h-220

    final zones = <_ScatterZone>[
      // Top strip
      _ScatterZone(0, 0, w, h * 0.09),
      // Left strip (full height)
      _ScatterZone(0, 0, 40, h),
      // Right strip (full height)
      _ScatterZone(w - 60, 0, w, h),
      // Gap between logo and text
      _ScatterZone(0, h * 0.22, w, h * 0.26),
      // Gap between button and mandala
      _ScatterZone(40, h * 0.50, w - 60, h - 220),
    ];

    _letterTargets = List.generate(_letters.length, (i) {
      final zone = zones[_rng.nextInt(zones.length)];
      return zone.random(_rng);
    });

    _handTargets = List.generate(_hands.length, (i) {
      final zone = zones[_rng.nextInt(zones.length)];
      return zone.random(_rng);
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _spinCtrl.dispose();
    _scatterCtrl.dispose();
    _welcomeCtrl.dispose();
    _mandalaCtrl.dispose();
    _riseCtrl.dispose();
    super.dispose();
  }

    Offset _getLetterPos(int i, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + _navShift;
    if (!_scattered) {
      final angle = (2 * math.pi * i / _letters.length) +
          (_spinCtrl.value * 2 * math.pi);
      return Offset(
          cx + _letterR * math.cos(angle), cy + _letterR * math.sin(angle));
    }
    if (_letterTargets.isEmpty) return Offset(cx, cy);
    final from = Offset(
      cx + _letterR * math.cos(_letterSpinAngles[i]),
      cy + _letterR * math.sin(_letterSpinAngles[i]),
    );
    final t = Curves.easeOutCubic.transform(_scatterCtrl.value);
    return Offset.lerp(from, _letterTargets[i], t)!;
  }

  Offset _getHandPos(int i, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + _navShift;
    if (!_scattered) {
      final angle = (2 * math.pi * i / _hands.length) -
          (_spinCtrl.value * 2 * math.pi);
      return Offset(
          cx + _handR * math.cos(angle), cy + _handR * math.sin(angle));
    }
    if (_handTargets.isEmpty) return Offset(cx, cy);
    final from = Offset(
      cx + _handR * math.cos(_handSpinAngles[i]),
      cy + _handR * math.sin(_handSpinAngles[i]),
    );
    final t = Curves.easeOutCubic.transform(_scatterCtrl.value);
    return Offset.lerp(from, _handTargets[i], t)!;
  }

  void _goToAuth() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const AuthScreen(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, __) => Opacity(
                opacity: _logoCtrl.value.clamp(0.0, 1.0),
                child: Image.asset(
                  'assets/images/bg_pattern.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Scattered / spinning hands + letters
          if (_showRings)
            AnimatedBuilder(
              animation:
                  Listenable.merge([_spinCtrl, _scatterCtrl]),
              builder: (_, __) {
                return Stack(children: [
                  ...List.generate(_hands.length, (i) {
                    final pos = _getHandPos(i, size);
                    final opacity = (_scattered
                            ? (1.0 - _scatterCtrl.value * 0.35)
                            : 1.0)
                        .clamp(0.0, 1.0);
                    return Positioned(
                      left: pos.dx - 22,
                      top: pos.dy - 22,
                      child: Opacity(
                        opacity: opacity,
                        child: Image.asset(
                          'assets/images/${_hands[i]}',
                          width: 44,
                          height: 44,
                        ),
                      ),
                    );
                  }),
                  ...List.generate(_letters.length, (i) {
                    final pos = _getLetterPos(i, size);
                    final opacity = (_scattered
                            ? (1.0 - _scatterCtrl.value * 0.3)
                            : 1.0)
                        .clamp(0.0, 1.0);
                    return Positioned(
                      left: pos.dx - 12,
                      top: pos.dy - 14,
                      child: Opacity(
                        opacity: opacity,
                        child: Text(
                          _letters[i],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary
                                .withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    );
                  }),
                ]);
              },
            ),

          // ── Mandala half — rises from bottom, stays fixed ──
          if (_showWelcome)
            AnimatedBuilder(
              animation: _mandalaCtrl,
              builder: (_, __) {
                final t = CurvedAnimation(
                  parent: _mandalaCtrl,
                  curve: Curves.easeOutCubic,
                ).value;
                return Positioned(
                  bottom: -20,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 220),
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Image.asset(
                        'assets/images/mandala_half.png',
                        width: size.width,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                );
              },
            ),

          // ── Logo: starts at the splash position, glides up on Welcome ──
          AnimatedBuilder(
            animation: _riseCtrl,
            builder: (_, __) {
              final t = Curves.easeInOutCubic.transform(_riseCtrl.value);
              final startTop = size.height / 2 + _navShift - _logoStart / 2;
              final endTop =
                  size.height * 0.08 - (_logoStart - _logoEnd) / 2;
              final scaleEnd = _logoEnd / _logoStart;
              return Positioned(
                top: startTop + (endTop - startTop) * t,
                left: 0,
                right: 0,
                child: Transform.scale(
                  scale: 1.0 + (scaleEnd - 1.0) * t,
                  child: Center(
                    child: Image.asset(
                      'assets/images/sahajmudra.png',
                      width: _logoStart,
                      height: _logoStart,
                    ),
                  ),
                ),
              );
            },
          ),
          // ── Welcome text — below logo with clear gap ──
          if (_showWelcome)
            AnimatedBuilder(
              animation: _welcomeCtrl,
              builder: (_, __) {
                // Logo bottom = 8% + 130px ≈ 8% + 17% = ~25%
                // Text starts at 27% giving a clear gap
                final textTop = size.height * 0.08 +
                    130 +
                    24 +
                    _textDrop; // logo top + logo height + gap
                return Positioned(
                  top: textTop,
                  left: 32,
                  right: 32,
                  child: Opacity(
                    opacity: _welcomeCtrl.value.clamp(0.0, 1.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Welcome title
                        Text(
                          'Welcome to SahajMudra',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Tagline
                        Text(
                          'Learn Indian Sign Language.\nBridge the silent divide.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // ── Start Learning button — centered between tagline and mandala ──
          if (_showWelcome)
            AnimatedBuilder(
              animation: _welcomeCtrl,
              builder: (_, __) {
                final buttonTop = size.height - _buttonFromBottom;

                return Positioned(
                  top: buttonTop,
                  left: 40,
                  right: 40,
                  child: Opacity(
                    opacity: _welcomeCtrl.value.clamp(0.0, 1.0),
                    child: ElevatedButton(
                      onPressed: _goToAuth,
                      child: const Text('Start Learning'),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ScatterZone {
  final double x1, y1, x2, y2;
  const _ScatterZone(this.x1, this.y1, this.x2, this.y2);

  Offset random(math.Random rng) {
    final x = x1 + rng.nextDouble() * (x2 - x1).abs();
    final y = y1 + rng.nextDouble() * (y2 - y1).abs();
    return Offset(x.clamp(x1, x2), y.clamp(y1, y2));
  }
}