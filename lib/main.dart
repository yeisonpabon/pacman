import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/maze_data.dart';
import 'game/pacman_game_controller.dart';
import 'models/game_models.dart';
import 'widgets/arcade_dpad.dart';
import 'widgets/game_board_painter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PacmanApp());
}

class PacmanApp extends StatelessWidget {
  const PacmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pac-Man Mini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070A12),
        fontFamily: 'monospace',
      ),
      home: const PacmanGameScreen(),
    );
  }
}

class PacmanGameScreen extends StatefulWidget {
  const PacmanGameScreen({super.key});

  @override
  State<PacmanGameScreen> createState() => _PacmanGameScreenState();
}

class _PacmanGameScreenState extends State<PacmanGameScreen> {
  late final PacmanGameController _controller;
  final FocusNode _focusNode = FocusNode();
  Offset _dragDelta = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = PacmanGameController();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _controller.setDirection(Direction.up);
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      _controller.setDirection(Direction.down);
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _controller.setDirection(Direction.left);
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      _controller.setDirection(Direction.right);
    } else if (key == LogicalKeyboardKey.space) {
      if (_controller.gameState == GameState.ready) {
        _controller.startGame();
      } else {
        _controller.togglePause();
      }
    } else if (key == LogicalKeyboardKey.keyR) {
      _controller.restartGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      // Header Stats Bar
                      _buildHeader(),

                      // Energizer Power Bar (if active)
                      _buildPowerBar(),

                      // Game Board Area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: MazeData.cols / MazeData.rows,
                              child: _buildBoardWithGestures(),
                            ),
                          ),
                        ),
                      ),

                      // Arcade D-Pad Controls
                      ArcadeDpad(
                        isPaused: _controller.gameState == GameState.paused,
                        onDirectionChanged: _controller.setDirection,
                        onPauseToggle: _controller.togglePause,
                        onRestart: _controller.restartGame,
                      ),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SCORE',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                _controller.score.toString().padLeft(5, '0'),
                style: const TextStyle(
                  color: Color(0xFFFDE047),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          // High Score
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'HIGH SCORE',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                _controller.highScore.toString().padLeft(5, '0'),
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          // Lives & Round
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ROUND ${_controller.level}',
                style: const TextStyle(
                  color: Color(0xFFF472B6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  math.max(0, _controller.lives),
                  (index) => Container(
                    margin: const EdgeInsets.only(left: 3),
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPowerBar() {
    final double remaining = _controller.frightenedTimeRemaining;
    if (remaining <= 0) {
      return const SizedBox(height: 6);
    }

    final double progress = (remaining / PacmanGameController.kFrightenedDuration).clamp(0.0, 1.0);
    final bool isWarning = remaining < 2.5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: isWarning ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: (isWarning ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)).withValues(alpha: 0.8),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardWithGestures() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => _dragDelta = Offset.zero,
      onPanUpdate: (details) {
        _dragDelta += details.delta;
        if (_dragDelta.distance > 18) {
          if (_dragDelta.dx.abs() > _dragDelta.dy.abs()) {
            _controller.setDirection(
              _dragDelta.dx > 0 ? Direction.right : Direction.left,
            );
          } else {
            _controller.setDirection(
              _dragDelta.dy > 0 ? Direction.down : Direction.up,
            );
          }
          _dragDelta = Offset.zero;
        }
      },
      onTap: () {
        if (_controller.gameState == GameState.ready) {
          _controller.startGame();
        } else if (_controller.gameState == GameState.paused) {
          _controller.togglePause();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E3A8A), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: GameBoardPainter(controller: _controller),
              ),
            ),
            _buildOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    switch (_controller.gameState) {
      case GameState.ready:
        return _buildMessageOverlay(
          title: 'PAC-MAN',
          subtitle: 'TOUCH OR PRESS TO PLAY',
          titleColor: const Color(0xFFFFD700),
          actionText: 'START',
          onAction: _controller.startGame,
        );

      case GameState.paused:
        return _buildMessageOverlay(
          title: 'PAUSED',
          subtitle: 'GAME ON HOLD',
          titleColor: const Color(0xFF38BDF8),
          actionText: 'RESUME',
          onAction: _controller.togglePause,
        );

      case GameState.gameOver:
        return _buildMessageOverlay(
          title: 'GAME OVER',
          subtitle: 'SCORE: ${_controller.score}',
          titleColor: const Color(0xFFEF4444),
          actionText: 'TRY AGAIN',
          onAction: _controller.restartGame,
        );

      case GameState.victory:
        return _buildMessageOverlay(
          title: 'VICTORY!',
          subtitle: 'ALL DOTS CLEARED!',
          titleColor: const Color(0xFF4ADE80),
          actionText: 'NEXT ROUND',
          onAction: _controller.nextLevel,
        );

      case GameState.playing:
      case GameState.pacmanDying:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMessageOverlay({
    required String title,
    required String subtitle,
    required Color titleColor,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              shadows: [
                Shadow(
                  color: titleColor.withValues(alpha: 0.7),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: titleColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
