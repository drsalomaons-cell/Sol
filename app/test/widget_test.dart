import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('Sol exige configurar o backend antes de mostrar dados', (WidgetTester tester) async {
    await tester.pumpWidget(const SolApp());
    expect(find.text('SOL'), findsOneWidget);
    expect(find.textContaining('chave pública do Supabase'), findsOneWidget);
  });
}
