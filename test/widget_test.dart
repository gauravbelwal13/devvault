import 'package:devvault/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('DevVault app launches successfully', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DevVaultApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Foundation ready'), findsOneWidget);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}