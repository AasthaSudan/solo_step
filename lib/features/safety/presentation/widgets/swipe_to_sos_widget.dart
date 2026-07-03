import 'package:flutter/material.dart';

class SwipeToSosWidget extends StatefulWidget {
  final VoidCallback onSOS;

  const SwipeToSosWidget({super.key, required this.onSOS});

  @override
  State<SwipeToSosWidget> createState() => _SwipeToSosWidgetState();
}

class _SwipeToSosWidgetState extends State<SwipeToSosWidget> with TickerProviderStateMixin {
  late AnimationController _dragController;
  late AnimationController _pulseController;
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dragController.addListener(() {
      setState(() {
        _dragPosition = _dragController.value;
      });
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _dragController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isCompleted) return;
    
    setState(() {
      _dragPosition += details.delta.dx;
      // Clamp between 0 and max draggable width
      if (_dragPosition < 0) _dragPosition = 0;
      if (_dragPosition > maxWidth - 70) _dragPosition = maxWidth - 70;
    });
  }

  void _onDragEnd(DragEndDetails details, double maxWidth) {
    if (_isCompleted) return;

    if (_dragPosition > (maxWidth - 70) * 0.8) {
      // Completed swipe
      setState(() {
        _isCompleted = true;
        _dragPosition = maxWidth - 70;
      });
      widget.onSOS();
    } else {
      // Snap back
      _dragController.value = _dragPosition;
      _dragController.animateTo(0, curve: Curves.easeOutBack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        
        return Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            color: const Color(0xFF2C1010),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Text
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  _isCompleted ? 'SOS SENT' : 'SWIPE TO SOS ➔',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 16,
                  ),
                ),
              ),
              
              // Pulse effect behind the draggable button
              if (!_isCompleted)
                Positioned(
                  left: _dragPosition,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(alpha: 0.4 * (1 - _pulseController.value)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.8 * (1 - _pulseController.value)),
                              spreadRadius: _pulseController.value * 20,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Draggable Button
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxWidth),
                  onHorizontalDragEnd: (details) => _onDragEnd(details, maxWidth),
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.redAccent, Colors.red],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
