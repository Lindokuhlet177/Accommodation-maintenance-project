import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Navy circle with an icon, surrounded by small tool icons that
/// fly in from different directions.
/// Used on Submitted (✓), Confirm Resolution (?) and Completed (smiley).
class StatusBadge extends StatefulWidget {
  final IconData icon;
  final bool animate;

  const StatusBadge({super.key, required this.icon, this.animate = true});

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScale;

  /// Each tool icon and its final position, measured from the centre.
  /// The icon flies in along the same direction from further out.
  static const List<(IconData, Offset)> _tools = [
    (Icons.settings, Offset(-47, -56)),            // top left
    (Icons.home_repair_service, Offset(47, -56)),  // top right
    (Icons.fire_extinguisher, Offset(79, -6)),     // right
    (Icons.hardware, Offset(47, 56)),              // bottom right
    (Icons.format_paint, Offset(-47, 56)),         // bottom left
    (Icons.warning, Offset(-79, -6)),              // left
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Circle pops in during the first half, with a bounce
    _circleScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0; // show the finished picture straight away
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the phone's "reduce motion" accessibility setting
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Progress (0 → 1) for tool number [index], staggered one after another.
  double _toolProgress(int index) {
    final start = 0.15 + index * 0.08;  // each icon starts a little later
    final end = (start + 0.45).clamp(0.0, 1.0);
    return Interval(start, end, curve: Curves.easeOutBack)
        .transform(_controller.value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 150,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none, // icons may start outside the box
            children: [
              // ---------- Tool icons flying in ----------
              for (var i = 0; i < _tools.length; i++)
                _buildTool(_tools[i].$1, _tools[i].$2, _toolProgress(i)),

              // ---------- Navy circle popping in ----------
              Transform.scale(
                scale: _circleScale.value,
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.navy,
                  child: Icon(widget.icon, size: 54, color: AppColors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTool(IconData icon, Offset target, double t) {
    // Start 3× further out along the same direction, end at the target
    final start = target * 3;
    final position = Offset.lerp(start, target, t)!;

    return Transform.translate(
      offset: position,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0), // easeOutBack can go slightly past 1
        child: Icon(icon, size: 22, color: AppColors.navy),
      ),
    );
  }
}