import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// True when the platform asks to reduce non-essential motion.
bool careerlyReduceMotion(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context);
}

/// Quiet press response. Does not steal the child's tap.
class CareerlyPressable extends StatefulWidget {
  const CareerlyPressable({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<CareerlyPressable> createState() => _CareerlyPressableState();
}

class _CareerlyPressableState extends State<CareerlyPressable> {
  bool _down = false;

  void _set(bool value) {
    if (!widget.enabled || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = careerlyReduceMotion(context);
    return Listener(
      onPointerDown: widget.enabled && !reduce ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: AppMotion.instant,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}

/// Remembers which scores and bars have already played their first reveal.
abstract final class CareerlyReveal {
  static final Set<String> _seen = {};

  static bool already(String? key) => key != null && _seen.contains(key);

  static void mark(String? key) {
    if (key != null) _seen.add(key);
  }
}

/// Abstract document plus a few signal nodes. Static; no looping motion.
class CareerlySignalMark extends StatelessWidget {
  const CareerlySignalMark({super.key, this.height = 112});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SignalPainter(),
      ),
    );
  }
}

class _SignalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final doc = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.12, 64, size.height * 0.76),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      doc,
      Paint()..color = AppColors.cream,
    );
    canvas.drawRRect(
      doc,
      Paint()
        ..color = AppColors.inkNavy.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke,
    );
    final line = Paint()
      ..color = AppColors.inkNavy.withValues(alpha: 0.16)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.28 + i * 0.12);
      canvas.drawLine(Offset(12, y), Offset(i.isEven ? 48 : 36, y), line);
    }
    canvas.drawLine(
      const Offset(12, 22),
      const Offset(34, 22),
      Paint()
        ..color = AppColors.cobalt
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final nodes = [
      Offset(size.width * 0.42, size.height * 0.28),
      Offset(size.width * 0.58, size.height * 0.48),
      Offset(size.width * 0.74, size.height * 0.32),
    ];
    final link = Paint()
      ..color = AppColors.cobalt.withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(64, 40), nodes[0], link);
    canvas.drawLine(nodes[0], nodes[1], link);
    canvas.drawLine(nodes[1], nodes[2], link);
    for (final node in nodes) {
      canvas.drawCircle(node, 4, Paint()..color = AppColors.cobalt);
      canvas.drawCircle(
        node,
        8,
        Paint()
          ..color = AppColors.cobalt.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Document silhouette with one scan pass while work is in progress.
class CareerlyScanDocument extends StatefulWidget {
  const CareerlyScanDocument({super.key, this.active = true});

  final bool active;

  @override
  State<CareerlyScanDocument> createState() => _CareerlyScanDocumentState();
}

class _CareerlyScanDocumentState extends State<CareerlyScanDocument>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(CareerlyScanDocument oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = careerlyReduceMotion(context);
    return RepaintBoundary(
      child: SizedBox(
        width: 120,
        height: 148,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = reduce || !widget.active ? 0.35 : _controller.value;
            return CustomPaint(
              painter: _ScanPainter(progress: t),
            );
          },
        ),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final page = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(page, Paint()..color = AppColors.surface);
    canvas.drawRRect(
      page,
      Paint()
        ..color = AppColors.inkNavy.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke,
    );
    final ink = Paint()
      ..color = AppColors.inkNavy.withValues(alpha: 0.16)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    for (var i = 0; i < 6; i++) {
      final y = 28.0 + i * 16;
      canvas.drawLine(
        Offset(16, y),
        Offset(i.isEven ? size.width - 22 : size.width - 40, y),
        ink,
      );
    }
    canvas.drawLine(
      const Offset(16, 16),
      const Offset(52, 16),
      Paint()
        ..color = AppColors.cobalt
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final y = 12 + (size.height - 24) * progress;
    canvas.drawLine(
      Offset(10, y),
      Offset(size.width - 10, y),
      Paint()
        ..color = AppColors.cobalt.withValues(alpha: 0.85)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Partial score arc. Not a full progress ring.
class CareerlyScoreArc extends StatelessWidget {
  const CareerlyScoreArc({
    super.key,
    required this.value,
    this.size = 72,
    this.color = AppColors.mint,
    this.trackColor = const Color(0x33FFFFFF),
  });

  final double value;
  final double size;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(
          value: value.clamp(0, 1),
          color: color,
          trackColor: trackColor,
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const start = 2.4;
    const sweep = 2.6;
    canvas.drawArc(rect.deflate(4), start, sweep, false, paint..color = trackColor);
    canvas.drawArc(
      rect.deflate(4),
      start,
      sweep * value,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
