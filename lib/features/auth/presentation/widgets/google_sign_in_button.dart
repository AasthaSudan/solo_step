import 'package:flutter/material.dart';

/// A custom, vector-drawn Google Logo to avoid depending on external asset files.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double rectSize = size.width;
    final double center = rectSize / 2;
    
    // We will build paths to render the 4 sections of the G logo perfectly.
    // The G logo is a circle with a cutout on the right side and a horizontal bar.
    final double outerRadius = rectSize / 2;
    final double innerRadius = rectSize * 0.28; // standard proportion
    final double thickness = outerRadius - innerRadius;
    
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // We can define paths for each color segment.
    // However, a very robust way is to draw a stroked path.
    // Let's use a stroke with StrokeCap.butt for precise arcs.
    final double strokeWidth = thickness;
    final double arcRadius = (outerRadius + innerRadius) / 2;
    final Rect arcRect = Rect.fromCircle(center: Offset(center, center), radius: arcRadius);
    
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // Angle definitions in radians
    // 0 is right, pi/2 is bottom, pi is left, -pi/2 is top.
    
    // 1. Red (Top segment)
    // Coarsely from -140 degrees (-2.44 rad) to -40 degrees (-0.7 rad)
    strokePaint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, -2.45, 1.75, false, strokePaint);

    // 2. Yellow (Left segment)
    // From 140 degrees (2.44 rad) to -140 degrees (-2.44 rad)
    strokePaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, -3.7, 1.3, false, strokePaint);

    // 3. Green (Bottom segment)
    // From 40 degrees (0.7 rad) to 140 degrees (2.44 rad)
    strokePaint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.9, 1.55, false, strokePaint);

    // 4. Blue (Right segment + bar)
    // From -40 degrees (-0.7 rad) to 40 degrees (0.7 rad)
    strokePaint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.75, 1.7, false, strokePaint);

    // Blue horizontal bar starting from center to the right
    final double barHeight = strokeWidth;
    final Rect barRect = Rect.fromLTWH(
      center,
      center - barHeight / 2,
      outerRadius,
      barHeight,
    );
    canvas.drawRect(barRect, paint..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A premium, responsive Google Sign-In button with hover and press micro-animations.
class GoogleSignInButton extends StatefulWidget {
  final VoidCallback onPressed;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Dynamic text scale
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    
    // Scale on press and hover
    double scale = 1.0;
    if (_isPressed) {
      scale = 0.96;
    } else if (_isHovered) {
      scale = 1.02;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 14 * textScaleFactor,
              horizontal: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
              ],
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogo(size: 22),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: const Color(0xFF1F1F1F),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
