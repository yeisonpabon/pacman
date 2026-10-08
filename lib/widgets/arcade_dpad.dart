import 'package:flutter/material.dart';
import '../models/game_models.dart';

class ArcadeDpad extends StatelessWidget {
  final ValueChanged<Direction> onDirectionChanged;
  final VoidCallback onPauseToggle;
  final VoidCallback onRestart;
  final bool isPaused;

  const ArcadeDpad({
    super.key,
    required this.onDirectionChanged,
    required this.onPauseToggle,
    required this.onRestart,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    const double btnSize = 56.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Auxiliary buttons (Pause & Restart)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSmallButton(
                icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                label: isPaused ? 'RESUME' : 'PAUSE',
                color: const Color(0xFF3B82F6),
                onTap: onPauseToggle,
              ),
              const SizedBox(height: 12),
              _buildSmallButton(
                icon: Icons.refresh_rounded,
                label: 'RESTART',
                color: const Color(0xFFEF4444),
                onTap: onRestart,
              ),
            ],
          ),

          // Cross D-Pad
          SizedBox(
            width: btnSize * 3 + 12,
            height: btnSize * 3 + 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center accent circle
                Container(
                  width: btnSize * 0.9,
                  height: btnSize * 0.9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF334155), width: 2),
                  ),
                ),

                // UP
                Positioned(
                  top: 0,
                  child: _buildDirButton(
                    Direction.up,
                    Icons.arrow_upward_rounded,
                    btnSize,
                  ),
                ),

                // DOWN
                Positioned(
                  bottom: 0,
                  child: _buildDirButton(
                    Direction.down,
                    Icons.arrow_downward_rounded,
                    btnSize,
                  ),
                ),

                // LEFT
                Positioned(
                  left: 0,
                  child: _buildDirButton(
                    Direction.left,
                    Icons.arrow_back_rounded,
                    btnSize,
                  ),
                ),

                // RIGHT
                Positioned(
                  right: 0,
                  child: _buildDirButton(
                    Direction.right,
                    Icons.arrow_forward_rounded,
                    btnSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirButton(Direction dir, IconData icon, double size) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDirectionChanged(dir),
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
        highlightColor: const Color(0xFFFFD700).withValues(alpha: 0.2),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFF38BDF8),
            size: size * 0.55,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
