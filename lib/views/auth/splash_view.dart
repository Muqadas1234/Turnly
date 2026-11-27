import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../viewmodels/auth_viewmodel.dart';

const _violet = Color(0xFF6BFFFE);
const _blue = Color(0xFF4DFED9);
const _lavender = Color(0xFFA4FFFE);
const _navy = Color(0xFF082623);

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  static const _minDisplay = Duration(milliseconds: 2400);

  late final AnimationController _intro; // one-shot entrance
  late final AnimationController _orbit; // looping: ring dot, stars, clock
  late final AnimationController _float; // looping: gentle bobbing
  late final AnimationController _spin; // looping: loader ring
  late final AnimationController _exit; // fade out before handoff

  late final Animation<double> _exitFade;
  late final Animation<double> _hero;
  late final Animation<double> _heroScale;
  late final Animation<double> _text;
  late final Animation<double> _scene;
  late final Animation<double> _foot;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _exitFade = ReverseAnimation(_exit);
    _hero = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _heroScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _text = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
    );
    _scene = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );
    _foot = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _intro.forward();
    _boot();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(_minDisplay);
    if (!mounted) return;

    await _exit.forward();
    if (!mounted) return;

    // If checkAuth() navigates internally, split it into loadAuth() (start it
    // in initState) + navigate (call here) so auth runs during the animation.
    Get.find<AuthViewModel>().checkAuth();
  }

  @override
  void dispose() {
    _intro.dispose();
    _orbit.dispose();
    _float.dispose();
    _spin.dispose();
    _exit.dispose();
    super.dispose();
  }

  Widget _reveal(Animation<double> a, Widget child, {double dy = 0.0}) {
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, dy), end: Offset.zero)
            .animate(a),
        child: child,
      ),
    );
  }

  Widget _orb(double size, Color color, {double alpha = 0.35, bool rim = true}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.25),
            ],
          ),
          border: rim
              ? Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1.2,
          )
              : null,
        ),
      ),
    );
  }

  Widget _floating(double dy, double phase, Widget child) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, c) => Transform.translate(
        offset: Offset(0, (_float.value - 0.5) * dy * phase),
        child: c,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF33D6C8),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _navy,
        body: FadeTransition(
          opacity: _exitFade,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              final u = math.min(w, h * 0.46); // text unit
              final heroS = math.min(w * 0.8, h * 0.40);
              final sceneH = h * 0.30;
              final bottomInset = MediaQuery.of(context).padding.bottom;

              return Container(
                width: w,
                height: h,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF082623),
                      Color(0xFF0C4540),
                      Color(0xFF1A9E94),
                      Color(0xFF33D6C8),
                    ],
                    stops: [0.0, 0.38, 0.78, 1.0],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // ---- Background orbs ----
                    Positioned(
                      left: -w * 0.25,
                      top: -w * 0.42,
                      child: _orb(w * 0.8, _violet, alpha: 0.38),
                    ),
                    Positioned(
                      right: -w * 0.35,
                      top: h * 0.02,
                      child: _orb(w * 0.6, _blue, alpha: 0.18),
                    ),
                    Positioned(
                      right: -w * 0.22,
                      top: h * 0.12,
                      child: _orb(w * 0.42, _violet, alpha: 0.45),
                    ),
                    Positioned(
                      left: -w * 0.55,
                      top: h * 0.46,
                      child: _orb(w * 0.95, _blue, alpha: 0.22),
                    ),

                    // ---- Stars ----
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _orbit,
                          builder: (_, __) => CustomPaint(
                            painter: _StarPainter(_orbit.value),
                          ),
                        ),
                      ),
                    ),

                    // ---- Floating mini tickets ----
                    Positioned(
                      top: h * 0.07,
                      left: w * 0.09,
                      child: _reveal(
                        _hero,
                        _floating(
                          10,
                          1,
                          Transform.rotate(
                            angle: -0.5,
                            child: CustomPaint(
                              size: Size(w * 0.13, w * 0.085),
                              painter: const _TicketPainter(glass: true),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.325,
                      right: w * 0.07,
                      child: _reveal(
                        _hero,
                        _floating(
                          10,
                          -1,
                          Transform.rotate(
                            angle: 0.6,
                            child: CustomPaint(
                              size: Size(w * 0.12, w * 0.08),
                              painter: const _TicketPainter(glass: true),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ---- Bottom scene ----
                    Positioned(
                      left: 0,
                      right: 0,
                      top: h * 0.60,
                      height: sceneH,
                      child: _reveal(
                        _scene,
                        _QueueScene(width: w, height: sceneH),
                        dy: 0.06,
                      ),
                    ),

                    // ---- Hero ----
                    Positioned(
                      top: h * 0.263 - heroS * 0.4,
                      left: 0,
                      right: 0,
                      height: heroS * 0.8,
                      child: FadeTransition(
                        opacity: _hero,
                        child: ScaleTransition(
                          scale: _heroScale,
                          child: Center(
                            child: _Hero(
                              size: heroS,
                              orbit: _orbit,
                              float: _float,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ---- Wordmark + copy ----
                    Positioned(
                      top: h * 0.385,
                      left: 0,
                      right: 0,
                      child: _reveal(
                        _text,
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Turnly',
                              style: TextStyle(
                                fontSize: u * 0.155,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                letterSpacing: -u * 0.006,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: _violet.withValues(alpha: 0.5),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            CustomPaint(
                              size: Size(u * 0.16, 10),
                              painter: _SwooshPainter(),
                            ),
                            SizedBox(height: h * 0.02),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Your time. '),
                                  TextSpan(
                                    text: 'Your turn.',
                                    style: TextStyle(
                                      color: const Color(0xFF7BFFFE),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: u * 0.062,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: h * 0.012),
                            Text(
                              'Book a token from home.\n'
                                  'Follow your turn live. Arrive just in time.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: u * 0.038,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.62),
                              ),
                            ),
                          ],
                        ),
                        dy: 0.15,
                      ),
                    ),

                    // ---- Footer ----
                    Positioned(
                      bottom: bottomInset + h * 0.03,
                      left: 0,
                      right: 0,
                      child: FadeTransition(
                        opacity: _foot,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: AnimatedBuilder(
                                animation: _spin,
                                builder: (_, __) => CustomPaint(
                                  painter: _LoaderPainter(_spin.value),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'MADE FOR YOUR TIME',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 5,
                                color: _lavender.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: w * 0.1,
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '\u00A9 ${DateTime.now().year} TURNLY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 2,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: w * 0.1,
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Hero: glass tile + orbit ring (back half behind, front half over)
// ============================================================

class _Hero extends StatelessWidget {
  const _Hero({
    required this.size,
    required this.orbit,
    required this.float,
  });

  final double size;
  final Animation<double> orbit;
  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    final box = Size(size, size * 0.8);
    return SizedBox(
      width: box.width,
      height: box.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([orbit, float]),
        builder: (_, __) {
          final bob = (float.value - 0.5) * 12;
          final theta = orbit.value * 2 * math.pi + 0.6;
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: box,
                painter: _OrbitPainter(theta: theta, front: false),
              ),
              Transform.translate(
                offset: Offset(0, bob),
                child: _GlassTile(
                  size: size * 0.5,
                  minuteAngle: orbit.value * 2 * math.pi * 2,
                ),
              ),
              CustomPaint(
                size: box,
                painter: _OrbitPainter(theta: theta, front: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  const _GlassTile({required this.size, required this.minuteAngle});

  final double size;
  final double minuteAngle;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.3;
    const depth = 14.0;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateX(0.10)
        ..rotateY(-0.16)
        ..rotateZ(-0.06),
      child: SizedBox(
        width: size + depth,
        height: size + depth,
        child: Stack(
          children: [
            // Thickness / underside
            Positioned(
              left: depth,
              top: depth,
              width: size,
              height: size,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6BFFFD), Color(0xFF2FD0CB)],
                  ),
                ),
              ),
            ),
            // Glass face
            Positioned(
              left: 0,
              top: 0,
              width: size,
              height: size,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF63FFF2),
                      Color(0xFF2A9A8F),
                      Color(0xFF2FB8AF),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.38),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _violet.withValues(alpha: 0.55),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.center,
                              colors: [
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Transform.rotate(
                        angle: -0.38,
                        child: CustomPaint(
                          size: Size(size * 0.62, size * 0.4),
                          painter: _TicketPainter(minuteAngle: minuteAngle),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.theta, required this.front});

  final double theta;
  final bool front;

  @override
  void paint(Canvas canvas, Size size) {
    final rx = size.width * 0.46;
    final ry = size.width * 0.19;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.42);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );
    final a = front ? 1.0 : 0.4;
    final shader = LinearGradient(
      colors: [
        _violet.withValues(alpha: a),
        const Color(0xFFCCFFFF).withValues(alpha: a),
        const Color(0xFF5CFFC9).withValues(alpha: a),
      ],
    ).createShader(rect);
    final start = front ? 0.0 : math.pi;

    // glow
    canvas.drawArc(
      rect,
      start,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // crisp line
    canvas.drawArc(
      rect,
      start,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );

    // orbiting dot (drawn on whichever half it is currently on)
    final isFront = math.sin(theta) > 0;
    if (isFront == front) {
      final p = Offset(rx * math.cos(theta), ry * math.sin(theta));
      canvas.drawCircle(
        p,
        size.width * 0.05,
        Paint()
          ..color = const Color(0xFF9FFFE6).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(p, size.width * 0.03, Paint()..color = Colors.white);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.theta != theta || old.front != front;
}

class _TicketPainter extends CustomPainter {
  const _TicketPainter({this.minuteAngle = 0, this.glass = false});

  final double minuteAngle;
  final bool glass;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(h * 0.22)),
      );
    final nr = h * 0.15;
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, h / 2), radius: nr))
      ..addOval(Rect.fromCircle(center: Offset(w, h / 2), radius: nr));
    final ticket = Path.combine(PathOperation.difference, body, notches);

    final c = Offset(w / 2, h / 2);
    final cr = h * 0.33;

    if (glass) {
      canvas.drawPath(
        ticket,
        Paint()..color = Colors.white.withValues(alpha: 0.10),
      );
      canvas.drawPath(
        ticket,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.28),
      );
      canvas.drawCircle(
        c,
        cr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.22),
      );
      _hands(canvas, c, cr, Colors.white.withValues(alpha: 0.35), 1.4);
    } else {
      canvas.drawPath(
        ticket,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFCCFFFD)],
          ).createShader(Offset.zero & size),
      );
      canvas.drawCircle(c, cr, Paint()..color = const Color(0xFF1B635D));
      _hands(canvas, c, cr, Colors.white, h * 0.05);
    }
  }

  void _hands(Canvas canvas, Offset c, double cr, Color color, double sw) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    Offset tip(double clockAngle, double len) =>
        c + Offset(math.sin(clockAngle), -math.cos(clockAngle)) * len;

    canvas.drawLine(c, tip(-0.5, cr * 0.5), paint); // hour
    canvas.drawLine(c, tip(minuteAngle + 2.2, cr * 0.78), paint); // minute
  }

  @override
  bool shouldRepaint(_TicketPainter old) =>
      old.minuteAngle != minuteAngle || old.glass != glass;
}

class _SwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.5,
        -size.height * 0.5,
        size.width,
        size.height * 0.45,
      );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0x008BFFFD), Color(0xFF8BFFFD), Color(0xFF5CFFFB)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.t);

  final double t;

  // x, y (fractions), radius, phase
  static const _stars = <List<double>>[
    [0.64, 0.030, 1.6, 0.0],
    [0.71, 0.060, 1.2, 1.5],
    [0.45, 0.075, 1.0, 3.0],
    [0.19, 0.185, 1.8, 2.0],
    [0.13, 0.275, 1.1, 4.0],
    [0.06, 0.340, 1.3, 0.8],
    [0.82, 0.200, 1.3, 2.6],
    [0.88, 0.360, 1.0, 5.0],
    [0.55, 0.305, 1.1, 3.6],
    [0.30, 0.395, 1.2, 1.1],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final tw = 0.3 + 0.5 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 3 + s[3]));
      canvas.drawCircle(
        Offset(size.width * s[0], size.height * s[1]),
        s[2],
        Paint()..color = Colors.white.withValues(alpha: tw),
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(3);
    canvas.drawArc(
      r,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = Colors.white.withValues(alpha: 0.14),
    );
    canvas.drawArc(
      r,
      t * 2 * math.pi,
      1.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = _lavender,
    );
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.t != t;
}

// ============================================================
// Bottom scene: phone, queue silhouettes, counter building
// ============================================================

class _QueueScene extends StatelessWidget {
  const _QueueScene({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final w = width;
    final sH = height;

    return SizedBox(
      width: w,
      height: sH,
      child: ClipRect(
        child: Stack(
          children: [
            CustomPaint(size: Size(w, sH), painter: _ScenePainter()),

            // Ticket sign
            Positioned(
              left: w * 0.715,
              top: sH * 0.17,
              width: w * 0.16,
              height: sH * 0.14,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A403B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _blue.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      child: Text(
                        'A042',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Color(0xFFBFFFF0),
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Check badge
            Positioned(
              left: w * 0.885,
              top: sH * 0.14,
              width: w * 0.1,
              height: w * 0.1,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF126A62),
                  border: Border.all(color: _blue, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: w * 0.06,
                  color: const Color(0xFFBFFFF0),
                ),
              ),
            ),

            // Phone
            Positioned(
              left: w * 0.07,
              top: sH * 0.06,
              width: w * 0.28,
              height: sH * 0.84,
              child: Transform.rotate(
                angle: -0.18,
                child: _Phone(width: w * 0.28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final check = width * 0.42;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.2),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF33B8AD), Color(0xFF145A54)],
        ),
        border: Border.all(color: _violet.withValues(alpha: 0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF55FFF6).withValues(alpha: 0.4),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: width * 0.08),
          Container(
            width: width * 0.3,
            height: width * 0.06,
            decoration: BoxDecoration(
              color: const Color(0xFF0A332F),
              borderRadius: BorderRadius.circular(width),
            ),
          ),
          const Spacer(),
          Container(
            width: check,
            height: check,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1BA893).withValues(alpha: 0.35),
              border: Border.all(color: _blue, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.5),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              size: check * 0.62,
              color: const Color(0xFF6FFFD9),
            ),
          ),
          SizedBox(height: width * 0.07),
          Text(
            'Your Token\nis Booked!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: width * 0.105,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: width * 0.07),
          Container(
            width: width * 0.62,
            height: 5,
            decoration: BoxDecoration(
              color: _lavender.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: width * 0.62,
            height: 5,
            decoration: BoxDecoration(
              color: _lavender.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final sH = size.height;

    // ---- Floor: translucent ellipse + glowing rim ----
    final floor = Rect.fromCenter(
      center: Offset(w * 0.5, sH * 1.02),
      width: w * 1.32,
      height: sH * 1.04,
    );
    canvas.drawOval(
      floor,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF55FFF6).withValues(alpha: 0.30),
            const Color(0xFF2AA094).withValues(alpha: 0.05),
          ],
        ).createShader(floor),
    );

    final rimShader = LinearGradient(
      colors: [_violet, const Color(0xFFCCFFFF), _blue],
    ).createShader(floor);
    canvas.drawArc(
      floor,
      math.pi * 1.02,
      math.pi * 0.96,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..shader = rimShader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawArc(
      floor,
      math.pi * 1.02,
      math.pi * 0.96,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..shader = rimShader,
    );
    canvas.drawArc(
      floor.deflate(sH * 0.09),
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.22),
    );

    // ---- Building (curved canopy) ----
    final bx = w * 0.62;
    final roof = Path()
      ..moveTo(bx, sH * 0.40)
      ..quadraticBezierTo(w * 0.72, sH * 0.12, w * 1.05, sH * 0.04)
      ..lineTo(w * 1.05, sH * 0.80)
      ..lineTo(bx, sH * 0.80)
      ..close();
    canvas.drawPath(
      roof,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF66FFF7).withValues(alpha: 0.55),
            const Color(0xFF2A9A8F).withValues(alpha: 0.25),
          ],
        ).createShader(Rect.fromLTWH(bx, 0, w - bx, sH)),
    );
    final roofEdge = Path()
      ..moveTo(bx, sH * 0.40)
      ..quadraticBezierTo(w * 0.72, sH * 0.12, w * 1.05, sH * 0.04);
    canvas.drawPath(
      roofEdge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // ---- Doorway + counter ----
    final door = Rect.fromLTRB(w * 0.775, sH * 0.43, w * 0.905, sH * 0.78);
    canvas.drawRect(
      door,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE8FFFF).withValues(alpha: 0.9),
            const Color(0xFF7BFFF9).withValues(alpha: 0.7),
          ],
        ).createShader(door),
    );
    _person(
      canvas,
      w * 0.835,
      sH * 0.70,
      sH * 0.27,
      const Color(0xFF2A8279),
      0.95,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.745, sH * 0.66, w * 0.93, sH * 0.70),
      Paint()..color = _violet.withValues(alpha: 0.7),
    );

    // ---- Queue (far to near, so near people overlap far ones) ----
    final xs = <double>[];
    var x = w * 0.39;
    for (var i = 0; i < 8; i++) {
      xs.add(x);
      x += w * 0.058 * math.pow(0.9, i);
    }
    for (var i = 7; i >= 0; i--) {
      _person(
        canvas,
        xs[i],
        sH * (0.76 - 0.022 * i),
        sH * (0.31 - 0.028 * i),
        const Color(0xFF289086),
        1.0 - i * 0.06,
      );
    }

    // Faded person standing behind the phone
    _person(
      canvas,
      w * 0.05,
      sH * 0.80,
      sH * 0.30,
      const Color(0xFF289086),
      0.4,
    );

    // Customer waiting beside the counter
    _person(
      canvas,
      w * 0.945,
      sH * 0.72,
      sH * 0.26,
      const Color(0xFF36A89E),
      0.95,
    );
  }

  void _person(
      Canvas canvas,
      double x,
      double feet,
      double ph,
      Color base,
      double alpha,
      ) {
    final headR = ph * 0.095;
    final top = feet - ph;
    final shoulderY = feet - ph * 0.80;
    final hipY = feet - ph * 0.36;
    final torsoW = ph * 0.34;

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, feet),
        width: ph * 0.6,
        height: ph * 0.11,
      ),
      Paint()..color = const Color(0xFF0A332F).withValues(alpha: 0.4 * alpha),
    );

    // One gradient shared by every body part, so the figure reads as one piece
    final topColor = Color.lerp(base, const Color(0xFF80FFF6), 0.55)!;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          topColor.withValues(alpha: alpha),
          base.withValues(alpha: alpha),
        ],
      ).createShader(
        Rect.fromLTRB(x - ph * 0.3, top, x + ph * 0.3, feet),
      );

    // Legs
    final legW = ph * 0.11;
    for (final dx in [-ph * 0.075, ph * 0.075]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x + dx - legW / 2, hipY - ph * 0.02, x + dx + legW / 2, feet),
          Radius.circular(legW * 0.4),
        ),
        fill,
      );
    }

    // Arms
    final armW = ph * 0.075;
    for (final dx in [-(torsoW / 2 + armW * 0.35), torsoW / 2 + armW * 0.35]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x + dx - armW / 2,
            shoulderY + ph * 0.02,
            x + dx + armW / 2,
            hipY + ph * 0.06,
          ),
          Radius.circular(armW * 0.5),
        ),
        fill,
      );
    }

    // Torso (jacket) with sloped shoulders
    final torso = RRect.fromLTRBAndCorners(
      x - torsoW / 2,
      shoulderY,
      x + torsoW / 2,
      hipY,
      topLeft: Radius.circular(torsoW * 0.42),
      topRight: Radius.circular(torsoW * 0.42),
      bottomLeft: Radius.circular(torsoW * 0.1),
      bottomRight: Radius.circular(torsoW * 0.1),
    );
    canvas.drawRRect(torso, fill);

    // Neck + head
    canvas.drawRect(
      Rect.fromLTRB(x - headR * 0.35, top + headR * 1.8, x + headR * 0.35, shoulderY + 2),
      fill,
    );
    canvas.drawCircle(Offset(x, top + headR), headR, fill);

    // Rim light so the figures separate from the background
    canvas.drawRRect(
      torso,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = Colors.white.withValues(alpha: 0.16 * alpha),
    );
    canvas.drawCircle(
      Offset(x, top + headR),
      headR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = Colors.white.withValues(alpha: 0.2 * alpha),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}