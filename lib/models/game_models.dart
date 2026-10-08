import 'dart:math' as math;

/// Directions for Pac-Man and Ghost movement.
enum Direction {
  none(0, 0),
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  final int dx;
  final int dy;
  const Direction(this.dx, this.dy);

  Direction get opposite {
    switch (this) {
      case Direction.up:
        return Direction.down;
      case Direction.down:
        return Direction.up;
      case Direction.left:
        return Direction.right;
      case Direction.right:
        return Direction.left;
      case Direction.none:
        return Direction.none;
    }
  }

  double get angle {
    switch (this) {
      case Direction.right:
        return 0;
      case Direction.down:
        return math.pi / 2;
      case Direction.left:
        return math.pi;
      case Direction.up:
        return 3 * math.pi / 2;
      case Direction.none:
        return 0;
    }
  }
}

/// The four classic Pac-Man ghosts.
enum GhostType {
  blinky, // Red: Direct aggressive chaser
  pinky,  // Pink: Ambush / interceptor
  inky,   // Cyan: Flanker / patrol
  clyde,  // Orange: Shy / wanderer
}

/// Ghost behavioral states.
enum GhostState {
  inHouse,
  exiting,
  chase,
  frightened,
  eaten,
}

/// Game lifecycle state.
enum GameState {
  ready,      // Waiting to start
  playing,    // Active gameplay
  paused,     // Temporarily paused
  pacmanDying,// Death animation playing
  gameOver,   // Lost all lives
  victory,    // Ate all dots!
}

/// Pac-Man character representation.
class Pacman {
  double x;
  double y;
  Direction currentDir;
  Direction nextDir;
  double mouthAngle; // For chomping animation
  bool mouthOpening;

  Pacman({
    required this.x,
    required this.y,
    this.currentDir = Direction.none,
    this.nextDir = Direction.none,
    this.mouthAngle = 0.2,
    this.mouthOpening = true,
  });

  void reset(double startX, double startY) {
    x = startX;
    y = startY;
    currentDir = Direction.none;
    nextDir = Direction.none;
    mouthAngle = 0.2;
    mouthOpening = true;
  }
}

/// Ghost character representation.
class Ghost {
  final GhostType type;
  double x;
  double y;
  Direction currentDir;
  GhostState state;
  double houseTimer; // Countdown to exit house
  double homeX;      // Spawn X
  double homeY;      // Spawn Y

  Ghost({
    required this.type,
    required this.x,
    required this.y,
    required this.homeX,
    required this.homeY,
    this.currentDir = Direction.none,
    this.state = GhostState.inHouse,
    this.houseTimer = 0.0,
  });

  void reset() {
    x = homeX;
    y = homeY;
    currentDir = Direction.none;
    if (type == GhostType.blinky) {
      state = GhostState.chase;
      houseTimer = 0.0;
    } else if (type == GhostType.pinky) {
      state = GhostState.inHouse;
      houseTimer = 1.5;
    } else if (type == GhostType.inky) {
      state = GhostState.inHouse;
      houseTimer = 4.0;
    } else {
      state = GhostState.inHouse;
      houseTimer = 7.0;
    }
  }
}

/// Floating score popup when Pac-Man eats a ghost.
class ScorePopup {
  final int points;
  final double x;
  double y;
  double opacity;

  ScorePopup({
    required this.points,
    required this.x,
    required this.y,
    this.opacity = 1.0,
  });
}

/// Represents an integer grid position in the maze.
class GridPos {
  final int x;
  final int y;
  const GridPos(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPos &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

