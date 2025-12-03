import 'package:flutter/material.dart';

class SwipeableListItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final String? leftSwipeLabel;
  final String? rightSwipeLabel;
  final IconData? leftSwipeIcon;
  final IconData? rightSwipeIcon;
  final Color? leftSwipeColor;
  final Color? rightSwipeColor;

  const SwipeableListItem({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftSwipeLabel,
    this.rightSwipeLabel,
    this.leftSwipeIcon,
    this.rightSwipeIcon,
    this.leftSwipeColor,
    this.rightSwipeColor,
  });

  @override
  State<SwipeableListItem> createState() => _SwipeableListItemState();
}

class _SwipeableListItemState extends State<SwipeableListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  double _dragExtent = 0;
  bool _dragUnderway = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    _controller.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragUnderway) return;

    final delta = details.primaryDelta ?? 0;
    _dragExtent += delta;

    setState(() {
      _animation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(_dragExtent / context.size!.width, 0),
      ).animate(_controller);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragUnderway) return;
    _dragUnderway = false;

    final threshold = context.size!.width * 0.3;

    if (_dragExtent.abs() > threshold) {
      // Trigger action
      if (_dragExtent > 0 && widget.onSwipeRight != null) {
        widget.onSwipeRight!();
      } else if (_dragExtent < 0 && widget.onSwipeLeft != null) {
        widget.onSwipeLeft!();
      }
    }

    // Reset position
    _dragExtent = 0;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // Background actions
          Positioned.fill(
            child: Row(
              children: [
                // Right swipe action (on the left side)
                if (widget.onSwipeRight != null)
                  Expanded(
                    child: Container(
                      color: widget.rightSwipeColor ?? Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.rightSwipeIcon != null)
                            Icon(widget.rightSwipeIcon, color: Colors.white),
                          if (widget.rightSwipeLabel != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              widget.rightSwipeLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                // Left swipe action (on the right side)
                if (widget.onSwipeLeft != null)
                  Expanded(
                    child: Container(
                      color: widget.leftSwipeColor ?? Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.leftSwipeLabel != null) ...[
                            Text(
                              widget.leftSwipeLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (widget.leftSwipeIcon != null)
                            Icon(widget.leftSwipeIcon, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Main content
          SlideTransition(position: _animation, child: widget.child),
        ],
      ),
    );
  }
}
