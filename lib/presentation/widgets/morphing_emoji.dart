import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:emotion_sense/core/constants/emotions.dart';

/// Morphing emoji widget that animates facial feature transitions between emotions.
class MorphingEmoji extends StatefulWidget {
  const MorphingEmoji(
      {super.key,
      required this.emotion,
      this.duration = const Duration(milliseconds: 400),
      this.curve = Curves.easeInOut,
      this.size = 120,
      this.showFaceCircle = false});
  final Emotion emotion;
  final Duration duration;
  final Curve curve;
  final double size;
  final bool showFaceCircle;

  @override
  State<MorphingEmoji> createState() => _MorphingEmojiState();
}

class _MorphingEmojiState extends State<MorphingEmoji>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;
  final math.Random _rand = math.Random();
  Timer? _blinkTimer;
  bool _inPreBlink = false; // brief squint before full blink for happy/funny

  double _eyeOpenness = 1.0;
  double _eyeWidth = 1.0;
  double _eyebrowY = 0.0;
  double _eyebrowAngle = 0.0;
  double _mouthCurve = 0.0;
  double _mouthOpenness = 0.0;
  Color _faceColor = const Color(0xFFFFD700);

  late double _targetEyeOpenness;
  late double _targetEyeWidth;
  late double _targetEyebrowY;
  late double _targetEyebrowAngle;
  late double _targetMouthCurve;
  late double _targetMouthOpenness;
  late Color _targetFaceColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve)
      ..addListener(_tick);
    _setTargetsForEmotion(widget.emotion);
    _controller.forward();

    // Blinking: quick close->open every 3-5s.
    _blinkController = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: this);
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.1).animate(
        CurvedAnimation(parent: _blinkController, curve: Curves.easeIn));
    _blinkController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Re-open slightly slower
        _blinkController.reverseDuration = const Duration(milliseconds: 160);
        _blinkController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // Rare double-blink (approx 8% chance) for lifelike feel (skip angry to keep intensity)
        if ((widget.emotion != Emotion.angry) && _rand.nextDouble() < 0.08) {
          _blinkController.forward(from: 0);
          return; // second blink; schedule after sequence ends
        }
        _scheduleNextBlink();
      }
    });
    _blinkAnim.addListener(() => setState(() {}));
    _scheduleNextBlink();
  }

  void _tick() {
    setState(() {
      _eyeOpenness = _lerp(_eyeOpenness, _targetEyeOpenness);
      _eyeWidth = _lerp(_eyeWidth, _targetEyeWidth);
      _eyebrowY = _lerp(_eyebrowY, _targetEyebrowY);
      _eyebrowAngle = _lerp(_eyebrowAngle, _targetEyebrowAngle);
      _mouthCurve = _lerp(_mouthCurve, _targetMouthCurve);
      _mouthOpenness = _lerp(_mouthOpenness, _targetMouthOpenness);
      _faceColor = Color.lerp(_faceColor, _targetFaceColor, _animation.value)!;
    });
  }

  double _lerp(double current, double target) =>
      current + (target - current) * _animation.value;

  void _setTargetsForEmotion(Emotion emotion) {
    switch (emotion) {
      case Emotion.neutral:
        _targetEyeOpenness = 1.0;
        _targetEyeWidth = 1.0;
        _targetEyebrowY = 0.0;
        _targetEyebrowAngle = 0.0;
        _targetMouthCurve = 0.0;
        _targetMouthOpenness = 0.0;
        _targetFaceColor = const Color(0xFFF5D76E); // softer gold
        break;
      case Emotion.happy:
        _targetEyeOpenness = 0.6;
        _targetEyeWidth = 1.2;
        _targetEyebrowY = -0.2;
        _targetEyebrowAngle = 0.1;
        _targetMouthCurve = 1.0;
        _targetMouthOpenness = 0.0;
        _targetFaceColor = const Color(0xFFFFD54F); // warm amber
        break;
      case Emotion.sad:
        _targetEyeOpenness = 0.8;
        _targetEyeWidth = 0.9;
        _targetEyebrowY = 0.3;
        _targetEyebrowAngle = -0.2;
        _targetMouthCurve = -0.8;
        _targetMouthOpenness = 0.0;
        _targetFaceColor = const Color(0xFF64B5F6); // calm blue
        break;
      case Emotion.angry:
        _targetEyeOpenness = 1.0;
        _targetEyeWidth = 0.8;
        _targetEyebrowY = 0.5;
        _targetEyebrowAngle = -0.3;
        _targetMouthCurve = -0.5;
        _targetMouthOpenness = 0.2;
        _targetFaceColor = const Color(0xFFE53935); // intense red
        break;
      case Emotion.surprised: // spec uses 'surprised'
        _targetEyeOpenness = 1.5;
        _targetEyeWidth = 1.3;
        _targetEyebrowY = -0.8;
        _targetEyebrowAngle = 0.0;
        _targetMouthCurve = 0.0;
        _targetMouthOpenness = 1.0;
        _targetFaceColor = const Color(0xFFBA68C8); // vivid purple
        break;
      case Emotion.funny:
        _targetEyeOpenness = 0.3;
        _targetEyeWidth = 1.3;
        _targetEyebrowY = -0.1;
        _targetEyebrowAngle = 0.15;
        _targetMouthCurve = 1.2;
        _targetMouthOpenness = 0.6;
        _targetFaceColor = const Color(0xFF81C784); // lively green
        break;
    }
  }

  @override
  void didUpdateWidget(covariant MorphingEmoji oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _setTargetsForEmotion(widget.emotion);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    final emotion = widget.emotion;
    // Base delay ranges per emotion (ms)
    int minDelay;
    int maxDelay;
    switch (emotion) {
      case Emotion.neutral:
        minDelay = 2500;
        maxDelay = 4200; // more frequent
        break;
      case Emotion.happy:
        minDelay = 2800;
        maxDelay = 4800;
        break;
      case Emotion.funny:
        minDelay = 2600;
        maxDelay = 4300; // slightly more than happy
        break;
      case Emotion.sad:
        minDelay = 3500;
        maxDelay = 6000; // slower
        break;
      case Emotion.surprised:
        minDelay = 3200;
        maxDelay = 5500;
        break;
      case Emotion.angry:
        minDelay = 4200;
        maxDelay = 7000; // least frequent
        break;
    }
    final delayMs = minDelay + _rand.nextInt(maxDelay - minDelay);
    _blinkTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      if (_blinkController.isAnimating) return;
      // Pre-blink squint for happy/funny
      if (emotion == Emotion.happy || emotion == Emotion.funny) {
        _inPreBlink = true;
        setState(() {});
        Timer(const Duration(milliseconds: 90), () {
          if (!mounted) return;
          _inPreBlink = false;
          _blinkController.forward(from: 0);
        });
      } else {
        _blinkController.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EmojiPainter(
        eyeOpenness: _computeEyeOpenness(),
        eyeWidth: _eyeWidth,
        eyebrowY: _eyebrowY,
        eyebrowAngle: _eyebrowAngle,
        mouthCurve: _mouthCurve,
        mouthOpenness: _mouthOpenness,
        faceColor: _faceColor,
        emotion: widget.emotion,
        showFaceCircle: widget.showFaceCircle,
      ),
      child: SizedBox(width: widget.size, height: widget.size),
    );
  }

  double _computeEyeOpenness() {
    // Apply pre-blink squint (reduce openness 20%)
    final base = _eyeOpenness * (_blinkAnim.value);
    if (_inPreBlink) return base * 0.8;
    return base;
  }
}

class _EmojiPainter extends CustomPainter {
  _EmojiPainter(
      {required this.eyeOpenness,
      required this.eyeWidth,
      required this.eyebrowY,
      required this.eyebrowAngle,
      required this.mouthCurve,
      required this.mouthOpenness,
      required this.faceColor,
      required this.emotion,
      required this.showFaceCircle});
  final double eyeOpenness;
  final double eyeWidth;
  final double eyebrowY;
  final double eyebrowAngle;
  final double mouthCurve;
  final double mouthOpenness;
  final Color faceColor;
  final Emotion emotion;
  final bool showFaceCircle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    if (showFaceCircle) {
      // glow for high energy emotions
      if (emotion == Emotion.happy || emotion == Emotion.funny) {
        canvas.drawCircle(
          center,
          radius * 1.15,
          Paint()
            ..color = faceColor.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
        );
      }

      final facePaint = Paint()
        ..shader = RadialGradient(
                colors: [faceColor.withValues(alpha: 0.95), faceColor],
                radius: 0.9)
            .createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, facePaint);
    }

    _drawEyes(canvas, center, radius);
    _drawBrows(canvas, center, radius);
    _drawMouth(canvas, center, radius);
    _drawExtras(canvas, center, radius);
  }

  void _drawEyes(Canvas canvas, Offset center, double radius) {
    final baseY = center.dy - radius * 0.25;
    final separation = radius * 0.55;
    final eyeR = radius * 0.16 * eyeWidth;
    final eyeH = eyeR * eyeOpenness.clamp(0.1, 1.6);
    final paint = Paint()..color = Colors.black;

    for (final dir in [-1.0, 1.0]) {
      final c = Offset(center.dx + separation * 0.5 * dir, baseY);
      if (eyeOpenness > 0.12) {
        canvas.drawOval(
            Rect.fromCenter(center: c, width: eyeR * 2, height: eyeH * 2),
            paint);
      } else {
        canvas.drawLine(
            c - Offset(eyeR, 0), c + Offset(eyeR, 0), paint..strokeWidth = 3);
      }
    }
  }

  void _drawBrows(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final browLen = radius * 0.32;
    final yOffset = center.dy - radius * 0.55 + eyebrowY * radius * 0.18;

    // left brow
    final leftStart = Offset(center.dx - radius * 0.6, yOffset);
    final leftEnd =
        Offset(leftStart.dx + browLen, yOffset - browLen * eyebrowAngle);
    canvas.drawLine(leftStart, leftEnd, paint);
    // right brow
    final rightStart = Offset(center.dx + radius * 0.6, yOffset);
    final rightEnd =
        Offset(rightStart.dx - browLen, yOffset - browLen * eyebrowAngle);
    canvas.drawLine(rightStart, rightEnd, paint);
  }

  void _drawMouth(Canvas canvas, Offset center, double radius) {
    final mouthCenter = Offset(center.dx, center.dy + radius * 0.35);
    final width = radius * 0.55;
    final height = radius * 0.35 * mouthCurve.abs();
    final path = Path();
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (mouthOpenness > 0.15) {
      final openRect = Rect.fromCenter(
          center: mouthCenter,
          width: width,
          height: radius * 0.35 * mouthOpenness);
      path.addOval(openRect);
      paint.style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
      return;
    }

    path.moveTo(mouthCenter.dx - width / 2, mouthCenter.dy);
    if (mouthCurve > 0.05) {
      path.quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + height,
          mouthCenter.dx + width / 2, mouthCenter.dy);
    } else if (mouthCurve < -0.05) {
      path.quadraticBezierTo(mouthCenter.dx, mouthCenter.dy - height,
          mouthCenter.dx + width / 2, mouthCenter.dy);
    } else {
      path.lineTo(mouthCenter.dx + width / 2, mouthCenter.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawExtras(Canvas canvas, Offset center, double radius) {
    switch (emotion) {
      case Emotion.sad:
        final tearPaint = Paint()
          ..color = Colors.blueAccent.withValues(alpha: 0.6);
        final tearCenter =
            Offset(center.dx - radius * 0.35, center.dy + radius * 0.05);
        final tear = Path()
          ..moveTo(tearCenter.dx, tearCenter.dy)
          ..quadraticBezierTo(tearCenter.dx - 6, tearCenter.dy + 14,
              tearCenter.dx, tearCenter.dy + 20)
          ..quadraticBezierTo(tearCenter.dx + 6, tearCenter.dy + 14,
              tearCenter.dx, tearCenter.dy);
        canvas.drawPath(tear, tearPaint);
        break;
      case Emotion.angry:
        final veinPaint = Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        final veinOrigin =
            Offset(center.dx + radius * 0.62, center.dy - radius * 0.62);
        canvas.drawLine(
            veinOrigin, veinOrigin + const Offset(12, -12), veinPaint);
        canvas.drawLine(veinOrigin + const Offset(12, -12),
            veinOrigin + const Offset(6, -20), veinPaint);
        break;
      case Emotion.surprised:
        final sparklePaint = Paint()
          ..color = Colors.yellow.shade600
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        for (var i = 0; i < 4; i++) {
          final ang = i * math.pi / 2;
          final pos =
              center + Offset(math.cos(ang), math.sin(ang)) * radius * 1.25;
          canvas.drawLine(pos, pos + Offset(math.cos(ang), math.sin(ang)) * 10,
              sparklePaint);
        }
        break;
      case Emotion.funny:
        // small cheek circles
        final cheekPaint = Paint()
          ..color = Colors.pinkAccent.withValues(alpha: 0.5);
        canvas.drawCircle(center + Offset(-radius * 0.55, radius * 0.15),
            radius * 0.12, cheekPaint);
        canvas.drawCircle(center + Offset(radius * 0.55, radius * 0.15),
            radius * 0.12, cheekPaint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _EmojiPainter oldDelegate) => true;
}
