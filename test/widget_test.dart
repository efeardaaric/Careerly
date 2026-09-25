import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:careerly/app/app.dart';
import 'package:careerly/core/config/app_config.dart';
import 'package:careerly/core/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppConfig.bootstrap();
  });

  testWidgets('Careerly app boots to splash then language', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: const CareerlyApp(),
      ),
    );

    await tester.pump();
    expect(find.text('Careerly AI'), findsWidgets);

    // Allow splash delay + route transition to settle.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);
  });
}
