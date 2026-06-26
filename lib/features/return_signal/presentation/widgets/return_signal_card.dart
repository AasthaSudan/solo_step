import 'package:flutter/material.dart';
import '../../domain/entities/check_in.dart';

class ReturnSignalCard extends StatelessWidget {
  final CheckIn checkIn;
  final VoidCallback onImBack;

  const ReturnSignalCard({
    super.key,
    required this.checkIn,
    required this.onImBack,
  });

  static const String _dummyCountdown = '01h 42m';

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 520;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isWide ? 20 : 16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(157, 78, 221, 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color.fromRGBO(199, 125, 255, 0.3),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(157, 78, 221, 0.08),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: _SignalContent(checkIn: checkIn)),
                    const SizedBox(width: 16),
                    _ImBackButton(onPressed: onImBack, textScale: textScale),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SignalContent(checkIn: checkIn),
                    const SizedBox(height: 16),
                    _ImBackButton(onPressed: onImBack, textScale: textScale),
                  ],
                ),
        );
      },
    );
  }
}

class _SignalContent extends StatelessWidget {
  final CheckIn checkIn;

  const _SignalContent({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(199, 125, 255, 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFFE0AAFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Return Signal Armed',
                    style: TextStyle(
                      color: const Color(0xFFE0AAFF),
                      fontSize: 13 * textScale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    checkIn.activityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color.fromRGBO(255, 255, 255, 0.82),
                      fontSize: 14 * textScale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _InfoPill(
              icon: Icons.timer_outlined,
              label: ReturnSignalCard._dummyCountdown,
              color: const Color(0xFFC77DFF),
            ),
            _InfoPill(
              icon: Icons.more_time_rounded,
              label: '+ ${checkIn.graceMinutes}m grace',
              color: const Color(0xFF4285F4),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(220),
              fontSize: 12 * textScale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double textScale;

  const _ImBackButton({required this.onPressed, required this.textScale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9D4EDD),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color.fromRGBO(157, 78, 221, 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: Text(
          "I'm back",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
