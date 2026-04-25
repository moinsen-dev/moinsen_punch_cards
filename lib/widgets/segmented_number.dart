import 'package:flutter/material.dart';

class SegmentedNumber extends StatefulWidget {
  final int number;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool isSpinning;

  const SegmentedNumber({
    super.key,
    required this.number,
    this.size = 40,
    this.activeColor,
    this.inactiveColor,
    this.isSpinning = false,
  });

  @override
  State<SegmentedNumber> createState() => _SegmentedNumberState();
}

class _SegmentedNumberState extends State<SegmentedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<int> _spinAnimation;
  int _displayNumber = 0;
  int _previousNumber = 0;
  bool _isCounting = false;

  static const List<List<bool>> _segments = [
    // 0
    [true, true, true, false, true, true, true],
    // 1
    [false, false, true, false, false, true, false],
    // 2
    [true, false, true, true, true, false, true],
    // 3
    [true, false, true, true, false, true, true],
    // 4
    [false, true, true, true, false, true, false],
    // 5
    [true, true, false, true, false, true, true],
    // 6
    [true, true, false, true, true, true, true],
    // 7
    [true, false, true, false, false, true, false],
    // 8
    [true, true, true, true, true, true, true],
    // 9
    [true, true, true, true, false, true, true],
  ];

  @override
  void initState() {
    super.initState();
    _displayNumber = widget.number;
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _setupAnimation();

    if (widget.isSpinning) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(SegmentedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.number != oldWidget.number && !widget.isSpinning) {
      if (widget.number > oldWidget.number &&
          widget.number - oldWidget.number <= 1000) {
        _previousNumber = oldWidget.number;
        _isCounting = true;
        _spinController.duration = const Duration(milliseconds: 600);
        _spinController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              _isCounting = false;
              _displayNumber = widget.number;
            });
          }
        });
      } else {
        _displayNumber = widget.number;
      }
    }
    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _isCounting = false;
        _spinController.duration = const Duration(milliseconds: 800);
        _spinController.repeat();
      } else {
        _spinController.stop();
        _spinController.reset();
      }
    }
  }

  void _setupAnimation() {
    _spinAnimation = IntTween(
      begin: 0,
      end: 9,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.linear,
    ))
      ..addListener(() {
        setState(() {
          if (_isCounting) {
            final progress = Curves.easeOut.transform(_spinController.value);
            _displayNumber =
                (_previousNumber + (widget.number - _previousNumber) * progress)
                    .round();
          } else if (widget.isSpinning) {
            _displayNumber = _spinAnimation.value;
          } else {
            _displayNumber = widget.number;
          }
        });
      });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final absoluteNumber = _displayNumber.abs();
    final hundreds = (absoluteNumber ~/ 100) % 10;
    final tens = (absoluteNumber ~/ 10) % 10;
    final ones = absoluteNumber % 10;
    final digitCount = absoluteNumber >= 100 ? 3 : (absoluteNumber >= 10 ? 2 : 1);

    final activeColor =
        widget.activeColor ?? Theme.of(context).colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? activeColor.withAlpha(128);

    return Container(
      width: widget.size * (digitCount * 1.0 + 0.5),
      height: widget.size * 1.5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (digitCount >= 3)
            _buildDigit(hundreds, activeColor, inactiveColor),
          if (digitCount >= 2)
            _buildDigit(tens, activeColor, inactiveColor),
          _buildDigit(ones, activeColor, inactiveColor),
        ],
      ),
    );
  }

  Widget _buildDigit(int digit, Color activeColor, Color inactiveColor) {
    final segments = _segments[digit];
    final segmentWidth = widget.size * 0.15;
    final segmentLength = widget.size * 0.4;

    return SizedBox(
      width: widget.size,
      height: widget.size * 1.3,
      child: Stack(
        children: [
          // Horizontal segments (top, middle, bottom)
          Positioned(
            top: 0,
            left: segmentWidth,
            child: _buildSegment(segments[0], true, segmentWidth, segmentLength,
                activeColor, inactiveColor),
          ),
          Positioned(
            top: (widget.size * 1.3 - segmentWidth) / 2,
            left: segmentWidth,
            child: _buildSegment(segments[3], true, segmentWidth, segmentLength,
                activeColor, inactiveColor),
          ),
          Positioned(
            bottom: 0,
            left: segmentWidth,
            child: _buildSegment(segments[6], true, segmentWidth, segmentLength,
                activeColor, inactiveColor),
          ),
          // Vertical segments (top-left, top-right, bottom-left, bottom-right)
          Positioned(
            top: segmentWidth / 2,
            left: 0,
            child: _buildSegment(segments[1], false, segmentWidth,
                segmentLength, activeColor, inactiveColor),
          ),
          Positioned(
            top: segmentWidth / 2,
            right: 0,
            child: _buildSegment(segments[2], false, segmentWidth,
                segmentLength, activeColor, inactiveColor),
          ),
          Positioned(
            bottom: segmentWidth / 2,
            left: 0,
            child: _buildSegment(segments[4], false, segmentWidth,
                segmentLength, activeColor, inactiveColor),
          ),
          Positioned(
            bottom: segmentWidth / 2,
            right: 0,
            child: _buildSegment(segments[5], false, segmentWidth,
                segmentLength, activeColor, inactiveColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(bool isActive, bool isHorizontal, double width,
      double length, Color activeColor, Color inactiveColor) {
    return Container(
      width: isHorizontal ? length : width,
      height: isHorizontal ? width : length,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(width / 2),
      ),
    );
  }
}
