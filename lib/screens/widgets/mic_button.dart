import 'package:flutter/material.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final bool useDemoMode;
  final VoidCallback onTap;

  const MicButton({
    Key? key,
    required this.isListening,
    required this.useDemoMode,
    required this.onTap,
  }) : super(key: key);

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse 2
            if (widget.isListening)
              Container(
                width: 90 + (_controller.value * 50),
                height: 90 + (_controller.value * 50),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (widget.useDemoMode ? Colors.purple : const Color(0xFF00E5FF))
                      .withOpacity((1 - _controller.value) * 0.2),
                ),
              ),
            // Outer pulse 1
            if (widget.isListening)
              Container(
                width: 90 + ((_controller.value + 0.5) % 1.0 * 50),
                height: 90 + ((_controller.value + 0.5) % 1.0 * 50),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (widget.useDemoMode ? Colors.purple : const Color(0xFF00E5FF))
                      .withOpacity((1 - (_controller.value + 0.5) % 1.0) * 0.3),
                ),
              ),
            // Main Button
            GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: widget.isListening
                        ? (widget.useDemoMode
                            ? [Colors.purpleAccent, Colors.deepPurple]
                            : [const Color(0xFF00E5FF), const Color(0xFF00838F)])
                        : [const Color(0xFF3F51B5), const Color(0xFF1A237E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isListening
                              ? (widget.useDemoMode ? Colors.purple : const Color(0xFF00E5FF))
                              : const Color(0xFF3F51B5))
                          .withOpacity(widget.isListening ? 0.6 : 0.3),
                      blurRadius: widget.isListening ? 20 : 10,
                      spreadRadius: widget.isListening ? 5 : 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
