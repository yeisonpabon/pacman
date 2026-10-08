import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/maze_data.dart';
import '../game/pacman_game_controller.dart';
import '../models/game_models.dart';

class GameBoardPainter extends CustomPainter {
  final PacmanGameController controller;

  GameBoardPainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / MazeData.cols;
    final double cellH = size.height / MazeData.rows;
    final double cellSize = math.min(cellW, cellH);

    // 1. Draw Maze Background & Tiles
    _paintMaze(canvas, size, cellW, cellH, cellSize);

    // 2. Draw Pac-Man
    _paintPacman(canvas, cellW, cellH, cellSize);

    // 3. Draw Ghosts
    _paintGhosts(canvas, cellW, cellH, cellSize);

    // 4. Draw Floating Score Popups
    _paintPopups(canvas, cellW, cellH, cellSize);
  }

  void _paintMaze(
      Canvas canvas, Size size, double cellW, double cellH, double cellSize) {
    final Paint bgPaint = Paint()..color = const Color(0xFF090D16);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final Paint wallFill = Paint()..color = const Color(0xFF1E3A8A).withValues(alpha: 0.4);
    final Paint wallBorder = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint doorPaint = Paint()
      ..color = const Color(0xFFF472B6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final Paint dotPaint = Paint()..color = const Color(0xFFFBBF24);

    final double pulseScale = 0.28 + 0.08 * math.sin(controller.pulseTimer);
    final Paint powerPelletGlow = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    final Paint powerPelletPaint = Paint()..color = const Color(0xFFFFFBEB);

    for (int y = 0; y < MazeData.rows; y++) {
      for (int x = 0; x < MazeData.cols; x++) {
        final int tile = controller.maze[y][x];
        final double left = x * cellW;
        final double top = y * cellH;
        final double cx = left + cellW / 2;
        final double cy = top + cellH / 2;

        if (tile == MazeData.tileWall) {
          final RRect rrect = RRect.fromRectAndRadius(
            Rect.fromLTWH(left + 1, top + 1, cellW - 2, cellH - 2),
            const Radius.circular(4.0),
          );
          canvas.drawRRect(rrect, wallFill);
          canvas.drawRRect(rrect, wallBorder);
        } else if (tile == MazeData.tileDoor) {
          canvas.drawLine(
            Offset(left + 2, cy),
            Offset(left + cellW - 2, cy),
            doorPaint,
          );
        } else if (tile == MazeData.tileDot) {
          canvas.drawCircle(Offset(cx, cy), cellSize * 0.13, dotPaint);
        } else if (tile == MazeData.tilePowerPellet) {
          canvas.drawCircle(Offset(cx, cy), cellSize * (pulseScale + 0.1), powerPelletGlow);
          canvas.drawCircle(Offset(cx, cy), cellSize * pulseScale, powerPelletPaint);
        }
      }
    }
  }

  void _paintPacman(
      Canvas canvas, double cellW, double cellH, double cellSize) {
    final Pacman pacman = controller.pacman;
    final double cx = (pacman.x + 0.5) * cellW;
    final double cy = (pacman.y + 0.5) * cellH;
    final double radius = cellSize * 0.44;

    final Paint bodyPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    if (controller.gameState == GameState.pacmanDying) {
      // Dying animation: mouth opens wide and disappears
      final double mouthAngle = pacman.mouthAngle.clamp(0.0, math.pi);
      final double sweep = (2 * math.pi - 2 * mouthAngle).clamp(0.0, 2 * math.pi);
      if (sweep > 0.05) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          mouthAngle - math.pi / 2,
          sweep,
          true,
          bodyPaint,
        );
      }
      return;
    }

    // Normal Pac-Man chomp
    double baseAngle = pacman.currentDir.angle;
    if (pacman.currentDir == Direction.none) {
      baseAngle = 0; // Face right by default
    }

    final double mouthAngle = pacman.mouthAngle;
    final double startAngle = baseAngle + mouthAngle;
    final double sweepAngle = 2 * math.pi - 2 * mouthAngle;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      true,
      bodyPaint,
    );

    // Cute classic eye highlight when mouth is open
    if (mouthAngle > 0.1) {
      final double eyeOffsetX = -math.sin(baseAngle) * radius * 0.4;
      final double eyeOffsetY = math.cos(baseAngle) * radius * 0.4;
      final Paint eyePaint = Paint()..color = const Color(0xFF000000);
      canvas.drawCircle(
        Offset(cx + eyeOffsetX, cy + eyeOffsetY),
        radius * 0.12,
        eyePaint,
      );
    }
  }

  void _paintGhosts(
      Canvas canvas, double cellW, double cellH, double cellSize) {
    for (final ghost in controller.ghosts) {
      final double cx = (ghost.x + 0.5) * cellW;
      final double cy = (ghost.y + 0.5) * cellH;
      final double r = cellSize * 0.42;

      if (ghost.state == GhostState.eaten) {
        // Only draw eyes returning home
        _paintGhostEyes(canvas, cx, cy, r, ghost.currentDir, false);
        continue;
      }

      Color bodyColor;
      bool isFrightened = ghost.state == GhostState.frightened;

      if (isFrightened) {
        final double remaining = controller.frightenedTimeRemaining;
        if (remaining < 2.5 && ((remaining * 5).floor() % 2 == 1)) {
          bodyColor = const Color(0xFFFFFFFF); // Flashing white
        } else {
          bodyColor = const Color(0xFF2563EB); // Frightened blue
        }
      } else {
        switch (ghost.type) {
          case GhostType.blinky:
            bodyColor = const Color(0xFFEF4444); // Red
            break;
          case GhostType.pinky:
            bodyColor = const Color(0xFFF472B6); // Pink
            break;
          case GhostType.inky:
            bodyColor = const Color(0xFF06B6D4); // Cyan
            break;
          case GhostType.clyde:
            bodyColor = const Color(0xFFF97316); // Orange
            break;
        }
      }

      // Draw Ghost Body (Dome + Skirt)
      final Paint ghostBodyPaint = Paint()..color = bodyColor;
      final Path path = Path();

      // Top dome
      path.moveTo(cx - r, cy);
      path.arcTo(
        Rect.fromCircle(center: Offset(cx, cy - r * 0.15), radius: r),
        math.pi,
        math.pi,
        false,
      );

      // Sides and 3 wavy tentacles
      path.lineTo(cx + r, cy + r * 0.85);

      final double skirtY = cy + r * 0.85;
      final double waveDelta = controller.skirtWave ? 3.0 : -3.0;

      // 3 scallops
      final double scallopW = (2 * r) / 3;
      for (int i = 0; i < 3; i++) {
        final double startX = cx + r - i * scallopW;
        final double endX = startX - scallopW;
        final double midX = (startX + endX) / 2;
        path.quadraticBezierTo(
          midX,
          skirtY + waveDelta,
          endX,
          skirtY,
        );
      }

      path.close();
      canvas.drawPath(path, ghostBodyPaint);

      // Draw Eyes
      if (isFrightened) {
        _paintFrightenedFace(canvas, cx, cy, r, bodyColor == const Color(0xFFFFFFFF));
      } else {
        _paintGhostEyes(canvas, cx, cy, r, ghost.currentDir, true);
      }
    }
  }

  void _paintGhostEyes(Canvas canvas, double cx, double cy, double r,
      Direction dir, bool hasBody) {
    final Paint scleraPaint = Paint()..color = const Color(0xFFFFFFFF);
    final Paint pupilPaint = Paint()..color = const Color(0xFF1D4ED8);

    final double eyeRadius = r * 0.28;
    final double pupilRadius = r * 0.14;
    final double eyeSpacing = r * 0.42;
    final double eyeY = cy - r * 0.15;

    // Pupil offset in direction
    double pOffsetX = 0.0;
    double pOffsetY = 0.0;
    switch (dir) {
      case Direction.left:
        pOffsetX = -eyeRadius * 0.45;
        break;
      case Direction.right:
        pOffsetX = eyeRadius * 0.45;
        break;
      case Direction.up:
        pOffsetY = -eyeRadius * 0.45;
        break;
      case Direction.down:
        pOffsetY = eyeRadius * 0.45;
        break;
      case Direction.none:
        pOffsetX = -eyeRadius * 0.2;
        break;
    }

    // Left eye
    canvas.drawCircle(Offset(cx - eyeSpacing, eyeY), eyeRadius, scleraPaint);
    canvas.drawCircle(
      Offset(cx - eyeSpacing + pOffsetX, eyeY + pOffsetY),
      pupilRadius,
      pupilPaint,
    );

    // Right eye
    canvas.drawCircle(Offset(cx + eyeSpacing, eyeY), eyeRadius, scleraPaint);
    canvas.drawCircle(
      Offset(cx + eyeSpacing + pOffsetX, eyeY + pOffsetY),
      pupilRadius,
      pupilPaint,
    );
  }

  void _paintFrightenedFace(
      Canvas canvas, double cx, double cy, double r, bool isWhiteBody) {
    final Paint eyePaint = Paint()
      ..color = isWhiteBody ? const Color(0xFFEF4444) : const Color(0xFFFBBF24);

    final double eyeY = cy - r * 0.15;
    final double eyeSpacing = r * 0.35;

    // Small scared eyes
    canvas.drawCircle(Offset(cx - eyeSpacing, eyeY), r * 0.12, eyePaint);
    canvas.drawCircle(Offset(cx + eyeSpacing, eyeY), r * 0.12, eyePaint);

    // Wavy scared mouth
    final Paint mouthPaint = Paint()
      ..color = eyePaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Path mouthPath = Path();
    final double mouthY = cy + r * 0.35;
    mouthPath.moveTo(cx - r * 0.45, mouthY);
    mouthPath.lineTo(cx - r * 0.22, mouthY - 2.5);
    mouthPath.lineTo(cx, mouthY + 2.5);
    mouthPath.lineTo(cx + r * 0.22, mouthY - 2.5);
    mouthPath.lineTo(cx + r * 0.45, mouthY);

    canvas.drawPath(mouthPath, mouthPaint);
  }

  void _paintPopups(
      Canvas canvas, double cellW, double cellH, double cellSize) {
    for (final popup in controller.popups) {
      final double cx = (popup.x + 0.5) * cellW;
      final double cy = (popup.y + 0.5) * cellH;

      final TextSpan span = TextSpan(
        text: '+${popup.points}',
        style: TextStyle(
          color: const Color(0xFF00FFFF).withValues(alpha: popup.opacity.clamp(0.0, 1.0)),
          fontSize: cellSize * 0.85,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: popup.opacity.clamp(0.0, 1.0)),
              blurRadius: 4,
            ),
          ],
        ),
      );

      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant GameBoardPainter oldDelegate) => true;
}
