/// Maze constants and layout data.
class MazeData {
  static const int cols = 15;
  static const int rows = 17;

  static const int tileEmpty = 0;
  static const int tileWall = 1;
  static const int tileDot = 2;
  static const int tilePowerPellet = 3;
  static const int tileDoor = 4;
  static const int tileGhostHouse = 5;

  /// 15x17 symmetrical mini Pac-Man maze layout.
  static const List<List<int>> template = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // 0
    [1, 3, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 3, 1], // 1 (power pellets at corners)
    [1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1], // 2
    [1, 2, 1, 1, 2, 1, 2, 2, 2, 1, 2, 1, 1, 2, 1], // 3
    [1, 2, 2, 2, 2, 1, 1, 2, 1, 1, 2, 2, 2, 2, 1], // 4
    [1, 1, 1, 2, 1, 2, 2, 2, 2, 2, 1, 2, 1, 1, 1], // 5
    [0, 0, 0, 2, 1, 1, 1, 4, 1, 1, 1, 2, 0, 0, 0], // 6 (tunnels on left/right, door at 7,6)
    [1, 1, 1, 2, 1, 5, 5, 5, 5, 5, 1, 2, 1, 1, 1], // 7 (ghost house inside)
    [1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1], // 8 (ghost house bottom)
    [1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1], // 9
    [1, 2, 1, 1, 2, 1, 2, 0, 2, 1, 2, 1, 1, 2, 1], // 10 (Pac-Man spawn at 7, 10)
    [1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 2, 1], // 11
    [1, 1, 2, 1, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 1], // 12
    [1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 1], // 13
    [1, 3, 1, 1, 2, 2, 2, 1, 2, 2, 2, 1, 1, 3, 1], // 14 (power pellets at corners)
    [1, 2, 2, 2, 2, 1, 2, 2, 2, 1, 2, 2, 2, 2, 1], // 15
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // 16
  ];

  static const double pacmanStartX = 7.0;
  static const double pacmanStartY = 10.0;

  static const double blinkyStartX = 7.0;
  static const double blinkyStartY = 5.0;

  static const double pinkyStartX = 7.0;
  static const double pinkyStartY = 7.0;

  static const double inkyStartX = 6.0;
  static const double inkyStartY = 7.0;

  static const double clydeStartX = 8.0;
  static const double clydeStartY = 7.0;

  /// Returns a fresh deep-copy of the maze layout.
  static List<List<int>> createFreshMaze() {
    return List.generate(
      rows,
      (y) => List<int>.from(template[y]),
    );
  }

  /// Total dots and power pellets in the template.
  static int countTotalDots() {
    int count = 0;
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (template[y][x] == tileDot || template[y][x] == tilePowerPellet) {
          count++;
        }
      }
    }
    return count;
  }
}
