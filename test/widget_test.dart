import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_tracker/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const FitnessApp());
    expect(find.text('Fitness Tracker'), findsOneWidget);
  });
}
