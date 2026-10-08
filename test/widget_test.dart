import 'package:flutter_test/flutter_test.dart';
import 'package:pacman/main.dart';

void main() {
  testWidgets('Pacman game renders initial screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PacmanApp());
    await tester.pump();

    // Verify header stats exist
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('HIGH SCORE'), findsOneWidget);

    // Verify start overlay exists
    expect(find.text('PAC-MAN'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });
}
