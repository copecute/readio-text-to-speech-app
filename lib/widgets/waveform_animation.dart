import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated sound wave visualizer shown when speaking or playing audio.
class WaveformAnimation extends StatefulWidget {
  final bool isPlaying;
  final Color? color;
  final double height;
  final int barCount;

  const WaveformAnimation({
    super.key,
    required this.isPlaying,
    this.color,
    this.height = 36,
    this.barCount = 18,
  });

  @override
  State<WaveformAnimation> createState() => _WaveformAnimationState();
}

class _WaveformAnimationState extends State<WaveformAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaveformAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final double phase = (index / widget.barCount) * 2 * math.pi;
              final double value = widget.isPlaying
                  ? (math.sin(_controller.value * 2 * math.pi + phase).abs() * 0.75 + 0.25)
                  : 0.15;
              final double barHeight = widget.height * value;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3.5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: effectiveColor.withAlpha(widget.isPlaying ? 230 : 90),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
