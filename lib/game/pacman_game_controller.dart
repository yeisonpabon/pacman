import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/game_models.dart';
import 'maze_data.dart';

class PacmanGameController extends ChangeNotifier {
  // Game lifecycle
  GameState _gameState = GameState.ready;
  GameState get gameState => _gameState;

  int _score = 0;
  int get score => _score;

  int _highScore = 0;
  int get highScore => _highScore;

  int _lives = 3;
  int get lives => _lives;

  int _level = 1;
  int get level => _level;

  int _dotsRemaining = 0;
  int get dotsRemaining => _dotsRemaining;

  List<List<int>> _maze = [];
  List<List<int>> get maze => _maze;

  late Pacman _pacman;
  Pacman get pacman => _pacman;

  late List<Ghost> _ghosts;
  List<Ghost> get ghosts => _ghosts;

  final List<ScorePopup> _popups = [];
  List<ScorePopup> get popups => _popups;

  double _frightenedTimeRemaining = 0.0;
  double get frightenedTimeRemaining => _frightenedTimeRemaining;
  static const double kFrightenedDuration = 8.0;

  int _ghostEatMultiplier = 200;

  double _deathTimer = 0.0;
  double _readyTimer = 1.2;
  double _pulseTimer = 0.0;
  double get pulseTimer => _pulseTimer;

  bool _skirtWave = false;
  bool get skirtWave => _skirtWave;
  double _skirtWaveTimer = 0.0;

  Timer? _gameLoopTimer;

  // Track ghost last decision tile to avoid redundant turn calculations
  final Map<GhostType, GridPos> _ghostLastDecision = {};

  PacmanGameController() {
    _initGame();
  }

  void _initGame() {
    _maze = MazeData.createFreshMaze();
    _dotsRemaining = MazeData.countTotalDots();
    _score = 0;
    _lives = 3;
    _level = 1;
    _frightenedTimeRemaining = 0.0;
    _ghostEatMultiplier = 200;
    _popups.clear();

    _pacman = Pacman(
      x: MazeData.pacmanStartX,
      y: MazeData.pacmanStartY,
    );

    _ghosts = [
      Ghost(
        type: GhostType.blinky,
        x: MazeData.blinkyStartX,
        y: MazeData.blinkyStartY,
        homeX: MazeData.blinkyStartX,
        homeY: MazeData.blinkyStartY,
        currentDir: Direction.left,
        state: GhostState.chase,
        houseTimer: 0.0,
      ),
      Ghost(
        type: GhostType.pinky,
        x: MazeData.pinkyStartX,
        y: MazeData.pinkyStartY,
        homeX: MazeData.pinkyStartX,
        homeY: MazeData.pinkyStartY,
        currentDir: Direction.up,
        state: GhostState.inHouse,
        houseTimer: 1.5,
      ),
      Ghost(
        type: GhostType.inky,
        x: MazeData.inkyStartX,
        y: MazeData.inkyStartY,
        homeX: MazeData.inkyStartX,
        homeY: MazeData.inkyStartY,
        currentDir: Direction.up,
        state: GhostState.inHouse,
        houseTimer: 4.0,
      ),
      Ghost(
        type: GhostType.clyde,
        x: MazeData.clydeStartX,
        y: MazeData.clydeStartY,
        homeX: MazeData.clydeStartX,
        homeY: MazeData.clydeStartY,
        currentDir: Direction.up,
        state: GhostState.inHouse,
        houseTimer: 6.5,
      ),
    ];

    _ghostLastDecision.clear();
    _gameState = GameState.ready;
    _readyTimer = 1.2;

    _startGameLoop();
  }

  void _startGameLoop() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _tick(0.016);
    });
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    super.dispose();
  }

  /// Start or resume game.
  void startGame() {
    if (_gameState == GameState.ready) {
      _gameState = GameState.playing;
      notifyListeners();
    } else if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      notifyListeners();
    } else if (_gameState == GameState.gameOver) {
      restartGame();
    }
  }

  void togglePause() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
      notifyListeners();
    } else if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      notifyListeners();
    }
  }

  void restartGame() {
    _score = 0;
    _lives = 3;
    _level = 1;
    _maze = MazeData.createFreshMaze();
    _dotsRemaining = MazeData.countTotalDots();
    _frightenedTimeRemaining = 0.0;
    _ghostEatMultiplier = 200;
    _popups.clear();
    _resetPositions();
    _gameState = GameState.ready;
    _readyTimer = 1.0;
    notifyListeners();
  }

  void nextLevel() {
    _level++;
    _maze = MazeData.createFreshMaze();
    _dotsRemaining = MazeData.countTotalDots();
    _frightenedTimeRemaining = 0.0;
    _ghostEatMultiplier = 200;
    _popups.clear();
    _resetPositions();
    _gameState = GameState.ready;
    _readyTimer = 1.0;
    notifyListeners();
  }

  void _resetPositions() {
    _pacman.reset(MazeData.pacmanStartX, MazeData.pacmanStartY);
    for (final ghost in _ghosts) {
      ghost.reset();
    }
    _ghostLastDecision.clear();
  }

  /// Handle directional inputs from user (touch or keyboard).
  void setDirection(Direction dir) {
    if (dir == Direction.none) return;

    if (_gameState == GameState.ready) {
      _gameState = GameState.playing;
    } else if (_gameState == GameState.gameOver) {
      restartGame();
      return;
    } else if (_gameState == GameState.victory) {
      nextLevel();
      return;
    }

    if (_gameState != GameState.playing) return;

    if (_pacman.currentDir == Direction.none) {
      final int cx = _pacman.x.round();
      final int cy = _pacman.y.round();
      if (_isWalkableForPacman((cx + dir.dx) % MazeData.cols, cy + dir.dy)) {
        _pacman.currentDir = dir;
        _pacman.nextDir = dir;
        return;
      }
    }

    // Immediate 180-degree turnaround if opposite
    if (dir == _pacman.currentDir.opposite && _pacman.currentDir != Direction.none) {
      _pacman.currentDir = dir;
      _pacman.nextDir = dir;
    } else {
      _pacman.nextDir = dir;
    }
  }

  // Main 60 FPS update tick
  void _tick(double dt) {
    // Pulse animation for energizers
    _pulseTimer = (_pulseTimer + dt * 4) % (2 * math.pi);

    // Ghost skirt animation
    _skirtWaveTimer += dt;
    if (_skirtWaveTimer >= 0.15) {
      _skirtWave = !_skirtWave;
      _skirtWaveTimer = 0.0;
    }

    // Update floating popups
    for (int i = _popups.length - 1; i >= 0; i--) {
      _popups[i].y -= dt * 0.8;
      _popups[i].opacity -= dt * 0.8;
      if (_popups[i].opacity <= 0) {
        _popups.removeAt(i);
      }
    }

    if (_gameState == GameState.pacmanDying) {
      _deathTimer -= dt;
      _pacman.mouthAngle += (2 * math.pi * dt / 1.0);
      if (_deathTimer <= 0) {
        if (_lives <= 0) {
          _gameState = GameState.gameOver;
        } else {
          _resetPositions();
          _gameState = GameState.ready;
          _readyTimer = 1.0;
        }
      }
      notifyListeners();
      return;
    }

    if (_gameState == GameState.ready) {
      _readyTimer -= dt;
      if (_readyTimer <= 0) {
        _gameState = GameState.playing;
      }
      notifyListeners();
      return;
    }

    if (_gameState != GameState.playing) {
      notifyListeners();
      return;
    }

    // Frightened mode countdown
    if (_frightenedTimeRemaining > 0) {
      _frightenedTimeRemaining -= dt;
      if (_frightenedTimeRemaining <= 0) {
        _frightenedTimeRemaining = 0;
        for (final ghost in _ghosts) {
          if (ghost.state == GhostState.frightened) {
            ghost.state = GhostState.chase;
          }
        }
      }
    }

    // Pacman mouth chomp animation
    if (_pacman.currentDir != Direction.none) {
      if (_pacman.mouthOpening) {
        _pacman.mouthAngle += dt * 3.5;
        if (_pacman.mouthAngle >= 0.38 * math.pi) {
          _pacman.mouthOpening = false;
        }
      } else {
        _pacman.mouthAngle -= dt * 3.5;
        if (_pacman.mouthAngle <= 0.05 * math.pi) {
          _pacman.mouthOpening = true;
        }
      }
    }

    // Update Pac-Man
    _updatePacman(dt);

    // Update Ghosts
    _updateGhosts(dt);

    // Check collisions
    _checkCollisions();

    // High score check
    if (_score > _highScore) {
      _highScore = _score;
    }

    notifyListeners();
  }

  void _updatePacman(double dt) {
    final double speed = 4.6 + (_level - 1) * 0.15;
    final double step = speed * dt;

    final int cx = _pacman.x.round();
    final int cy = _pacman.y.round();

    // Check queued turn
    if (_pacman.nextDir != _pacman.currentDir && _pacman.nextDir != Direction.none) {
      final double distX = (_pacman.x - cx).abs();
      final double distY = (_pacman.y - cy).abs();
      const double turnSnap = 0.35;

      if (distX < turnSnap && distY < turnSnap) {
        final int targetX = (cx + _pacman.nextDir.dx) % MazeData.cols;
        final int targetY = cy + _pacman.nextDir.dy;

        if (_isWalkableForPacman(targetX, targetY)) {
          _pacman.x = cx.toDouble();
          _pacman.y = cy.toDouble();
          _pacman.currentDir = _pacman.nextDir;
        }
      }
    }

    if (_pacman.currentDir == Direction.none) return;

    final double nextX = _pacman.x + _pacman.currentDir.dx * step;
    final double nextY = _pacman.y + _pacman.currentDir.dy * step;

    // Check wall collision ahead
    final int forwardX = (cx + _pacman.currentDir.dx) % MazeData.cols;
    final int forwardY = cy + _pacman.currentDir.dy;

    if (!_isWalkableForPacman(forwardX, forwardY)) {
      if (_pacman.currentDir.dx > 0 && nextX > cx) {
        _pacman.x = cx.toDouble();
        _pacman.currentDir = Direction.none;
      } else if (_pacman.currentDir.dx < 0 && nextX < cx) {
        _pacman.x = cx.toDouble();
        _pacman.currentDir = Direction.none;
      } else if (_pacman.currentDir.dy > 0 && nextY > cy) {
        _pacman.y = cy.toDouble();
        _pacman.currentDir = Direction.none;
      } else if (_pacman.currentDir.dy < 0 && nextY < cy) {
        _pacman.y = cy.toDouble();
        _pacman.currentDir = Direction.none;
      } else {
        _pacman.x = nextX;
        _pacman.y = nextY;
      }
    } else {
      _pacman.x = nextX;
      _pacman.y = nextY;
    }

    // Tunnel wrap-around at row 6
    if (_pacman.x < -0.5) {
      _pacman.x = MazeData.cols - 0.5;
    } else if (_pacman.x > MazeData.cols - 0.5) {
      _pacman.x = -0.5;
    }

    // Eating dots
    _eatDotsAt(_pacman.x, _pacman.y);
  }

  bool _isWalkableForPacman(int x, int y) {
    if (y < 0 || y >= MazeData.rows) return false;
    final int wrappedX = (x + MazeData.cols) % MazeData.cols;
    final int tile = _maze[y][wrappedX];
    return tile != MazeData.tileWall &&
        tile != MazeData.tileDoor &&
        tile != MazeData.tileGhostHouse;
  }

  void _eatDotsAt(double px, double py) {
    final int cx = px.round();
    final int cy = py.round();

    if (cy < 0 || cy >= MazeData.rows) return;
    final int wrappedX = (cx + MazeData.cols) % MazeData.cols;

    final double dist = math.sqrt(math.pow(px - cx, 2) + math.pow(py - cy, 2));
    if (dist < 0.45) {
      final int tile = _maze[cy][wrappedX];
      if (tile == MazeData.tileDot) {
        _maze[cy][wrappedX] = MazeData.tileEmpty;
        _score += 10;
        _dotsRemaining--;
        _checkVictory();
      } else if (tile == MazeData.tilePowerPellet) {
        _maze[cy][wrappedX] = MazeData.tileEmpty;
        _score += 50;
        _dotsRemaining--;
        _triggerFrightenedMode();
        _checkVictory();
      }
    }
  }

  void _triggerFrightenedMode() {
    _frightenedTimeRemaining = kFrightenedDuration;
    _ghostEatMultiplier = 200;

    for (final ghost in _ghosts) {
      if (ghost.state == GhostState.chase) {
        ghost.state = GhostState.frightened;
        ghost.currentDir = ghost.currentDir.opposite;
      }
    }
  }

  void _checkVictory() {
    if (_dotsRemaining <= 0) {
      _gameState = GameState.victory;
      notifyListeners();
    }
  }

  void _updateGhosts(double dt) {
    final math.Random random = math.Random();

    for (final ghost in _ghosts) {
      // 1. Ghost inside the house
      if (ghost.state == GhostState.inHouse) {
        ghost.houseTimer -= dt;
        // Bob up and down inside the house
        ghost.y = ghost.homeY + math.sin(_pulseTimer * 1.5) * 0.25;
        if (ghost.houseTimer <= 0) {
          ghost.state = GhostState.exiting;
        }
        continue;
      }

      // 2. Ghost exiting the house
      if (ghost.state == GhostState.exiting) {
        const double exitX = 7.0;
        const double exitY = 5.0; // Outside corridor above door
        final double speed = 3.0;

        if ((ghost.x - exitX).abs() > 0.05) {
          ghost.x += (exitX - ghost.x).sign * speed * dt;
        } else {
          ghost.x = exitX;
          if (ghost.y > exitY) {
            ghost.y -= speed * dt;
            ghost.currentDir = Direction.up;
          } else {
            ghost.y = exitY;
            ghost.currentDir = Direction.left;
            ghost.state = _frightenedTimeRemaining > 0
                ? GhostState.frightened
                : GhostState.chase;
            _ghostLastDecision[ghost.type] = const GridPos(7, 5);
          }
        }
        continue;
      }

      // 3. Movement speed depending on state
      double speed = 3.8 + (_level - 1) * 0.15;
      if (ghost.state == GhostState.frightened) {
        speed = 2.2;
      } else if (ghost.state == GhostState.eaten) {
        speed = 6.5;
      }

      final double step = speed * dt;

      // When returning to house as eaten eyes:
      if (ghost.state == GhostState.eaten) {
        const double entranceX = 7.0;
        const double entranceY = 5.0;
        final double distToEntrance = math.sqrt(
            math.pow(ghost.x - entranceX, 2) + math.pow(ghost.y - entranceY, 2));

        if (distToEntrance < 0.35) {
          // Go down through door to spawn
          ghost.x = entranceX;
          ghost.y += step;
          ghost.currentDir = Direction.down;
          if (ghost.y >= ghost.homeY) {
            ghost.y = ghost.homeY;
            ghost.state = GhostState.exiting;
          }
          continue;
        }
      }

      final int cx = ghost.x.round();
      final int cy = ghost.y.round();
      final GridPos currentCell = GridPos(cx, cy);

      // Decision at intersection / tile center
      final double distToCenter =
          math.sqrt(math.pow(ghost.x - cx, 2) + math.pow(ghost.y - cy, 2));

      if (distToCenter < 0.25 && _ghostLastDecision[ghost.type] != currentCell) {
        _ghostLastDecision[ghost.type] = currentCell;

        // Choose next direction
        ghost.currentDir = _chooseGhostDirection(ghost, cx, cy, random);
      }

      // Move forward in current direction
      if (ghost.currentDir != Direction.none) {
        ghost.x += ghost.currentDir.dx * step;
        ghost.y += ghost.currentDir.dy * step;

        // Tunnel wrap
        if (ghost.x < -0.5) {
          ghost.x = MazeData.cols - 0.5;
        } else if (ghost.x > MazeData.cols - 0.5) {
          ghost.x = -0.5;
        }
      }
    }
  }

  Direction _chooseGhostDirection(
      Ghost ghost, int cx, int cy, math.Random random) {
    final List<Direction> validDirs = [];
    final List<Direction> allDirs = [
      Direction.up,
      Direction.left,
      Direction.down,
      Direction.right
    ];

    for (final dir in allDirs) {
      // Classic Pac-Man rule: Ghosts cannot immediately reverse direction
      if (ghost.currentDir != Direction.none && dir == ghost.currentDir.opposite) {
        continue;
      }

      final int nx = (cx + dir.dx) % MazeData.cols;
      final int ny = cy + dir.dy;

      if (_isWalkableForGhost(ghost, nx, ny)) {
        validDirs.add(dir);
      }
    }

    if (validDirs.isEmpty) {
      // Dead end, must reverse
      return ghost.currentDir.opposite;
    }

    if (ghost.state == GhostState.frightened) {
      // Random wandering when frightened
      return validDirs[random.nextInt(validDirs.length)];
    }

    // Determine target coordinate
    double targetX;
    double targetY;

    if (ghost.state == GhostState.eaten) {
      targetX = 7.0;
      targetY = 5.0; // House entrance
    } else {
      switch (ghost.type) {
        case GhostType.blinky:
          // Directly targets Pacman
          targetX = _pacman.x;
          targetY = _pacman.y;
          break;
        case GhostType.pinky:
          // Targets 3 tiles ahead of Pacman
          targetX = _pacman.x + 3 * _pacman.currentDir.dx;
          targetY = _pacman.y + 3 * _pacman.currentDir.dy;
          break;
        case GhostType.inky:
          // Targets flank / patrol
          final double blinkyDistX = _pacman.x - _ghosts[0].x;
          final double blinkyDistY = _pacman.y - _ghosts[0].y;
          targetX = _pacman.x + blinkyDistX * 0.5;
          targetY = _pacman.y + blinkyDistY * 0.5;
          break;
        case GhostType.clyde:
          // If close to Pacman, wanders to bottom-left corner
          final double distToPacman = math.sqrt(
              math.pow(ghost.x - _pacman.x, 2) + math.pow(ghost.y - _pacman.y, 2));
          if (distToPacman > 4.5) {
            targetX = _pacman.x;
            targetY = _pacman.y;
          } else {
            targetX = 1.0;
            targetY = 15.0; // Bottom-left corner
          }
          break;
      }
    }

    // Pick direction closest to target tile
    Direction bestDir = validDirs.first;
    double minDistance = double.infinity;

    for (final dir in validDirs) {
      final double nx = ((cx + dir.dx) % MazeData.cols).toDouble();
      final double ny = (cy + dir.dy).toDouble();
      final double d =
          math.pow(nx - targetX, 2) + math.pow(ny - targetY, 2).toDouble();
      if (d < minDistance) {
        minDistance = d;
        bestDir = dir;
      }
    }

    return bestDir;
  }

  bool _isWalkableForGhost(Ghost ghost, int x, int y) {
    if (y < 0 || y >= MazeData.rows) return false;
    final int wrappedX = (x + MazeData.cols) % MazeData.cols;
    final int tile = _maze[y][wrappedX];

    if (tile == MazeData.tileWall) return false;

    // Ghost door is only walkable if exiting or eaten returning home
    if (tile == MazeData.tileDoor) {
      return ghost.state == GhostState.exiting ||
          ghost.state == GhostState.eaten;
    }

    // Ghost house interior is only walkable for ghosts in house or returning eaten
    if (tile == MazeData.tileGhostHouse) {
      return ghost.state == GhostState.inHouse ||
          ghost.state == GhostState.eaten;
    }

    return true;
  }

  void _checkCollisions() {
    for (final ghost in _ghosts) {
      if (ghost.state == GhostState.inHouse ||
          ghost.state == GhostState.exiting ||
          ghost.state == GhostState.eaten) {
        continue;
      }

      final double dist = math.sqrt(
          math.pow(_pacman.x - ghost.x, 2) + math.pow(_pacman.y - ghost.y, 2));

      if (dist < 0.6) {
        if (ghost.state == GhostState.frightened) {
          // Pac-Man eats the ghost!
          ghost.state = GhostState.eaten;
          _score += _ghostEatMultiplier;
          _popups.add(ScorePopup(
            points: _ghostEatMultiplier,
            x: ghost.x,
            y: ghost.y,
          ));
          _ghostEatMultiplier *= 2;
        } else if (ghost.state == GhostState.chase) {
          // Pac-Man is caught!
          _lives--;
          _gameState = GameState.pacmanDying;
          _deathTimer = 1.2;
          break;
        }
      }
    }
  }
}
