import 'package:flutter_test/flutter_test.dart';
import 'package:persamaan_diferensial_tahap1/main.dart';

void main() {
  testWidgets('DiffSolver app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DiffSolverApp());
    expect(find.text('DiffSolver'), findsOneWidget);
    expect(find.text('Masukkan Persamaan Diferensial:'), findsOneWidget);
  });
}
