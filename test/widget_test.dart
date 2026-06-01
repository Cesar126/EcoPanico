import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco_panico/main.dart';

void main() {
  testWidgets('EcoPanicoApp builds successfully smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EcoPanicoApp(),
      ),
    );

    // Verify that the splash title is rendered
    expect(find.text('ECO PÁNICO'), findsWidgets);
  });
}
