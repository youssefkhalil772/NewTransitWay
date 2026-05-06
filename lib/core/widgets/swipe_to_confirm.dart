import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SwipeToConfirm extends StatefulWidget {
  final String text;
  final VoidCallback onConfirm;
  final Color baseColor;
  final bool isLoading;

  const SwipeToConfirm({
    super.key,
    required this.text,
    required this.onConfirm,
    this.baseColor = const Color(0xFF39C449),
    this.isLoading = false,
  });

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragPosition = 0.0;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addListener(() {
      setState(() {
        _dragPosition = _controller.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    if (_confirmed || widget.isLoading) return;
    
    setState(() {
      _dragPosition += details.delta.dx;
      if (_dragPosition < 0) _dragPosition = 0;
      if (_dragPosition > maxWidth - 60.h) _dragPosition = maxWidth - 60.h;
    });
  }

  void _onPanEnd(DragEndDetails details, double maxWidth) {
    if (_confirmed || widget.isLoading) return;

    if (_dragPosition > (maxWidth - 60.h) * 0.8) {
      // Confirmed
      setState(() {
        _dragPosition = maxWidth - 60.h;
        _confirmed = true;
      });
      HapticFeedback.heavyImpact();
      widget.onConfirm();
    } else {
      // Snap back
      _controller.value = _dragPosition;
      _controller.animateTo(0.0, curve: Curves.easeOutBack);
      HapticFeedback.lightImpact();
    }
  }

  @override
  void didUpdateWidget(SwipeToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading && _confirmed) {
      // Reset if it finished loading and we stayed on the screen
      setState(() {
        _confirmed = false;
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = 60.h;
        final double width = constraints.maxWidth;
        final double maxDrag = width - height;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: widget.baseColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: widget.baseColor.withValues(alpha: 0.3)),
          ),
          child: Stack(
            children: [
              // Background Text
              Center(
                child: Padding(
                  padding: EdgeInsets.only(left: 30.w), // Shift right to balance thumb
                  child: Opacity(
                    opacity: (1 - (_dragPosition / maxDrag)).clamp(0.0, 1.0),
                    child: Text(
                      widget.isLoading ? "PROCESSING..." : widget.text,
                      style: TextStyle(
                        color: widget.baseColor.withValues(alpha: 0.8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Progress Fill
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragPosition + height,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.baseColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),

              // Draggable Thumb
              Positioned(
                left: _dragPosition,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanUpdate: (details) => _onPanUpdate(details, width),
                  onPanEnd: (details) => _onPanEnd(details, width),
                  child: Container(
                    width: height,
                    height: height,
                    decoration: BoxDecoration(
                      color: widget.baseColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.baseColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: widget.isLoading 
                        ? SizedBox(
                            width: 20.sp, 
                            height: 20.sp, 
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          )
                        : Icon(
                            _confirmed ? Icons.check : Icons.keyboard_double_arrow_right_rounded,
                            color: Colors.white,
                            size: 28.sp,
                          ),
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
