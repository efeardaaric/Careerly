import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:careerly/app/theme/app_theme.dart';
import 'package:careerly/core/widgets/app_button.dart';
import 'package:careerly/core/widgets/app_states.dart';
import 'package:careerly/core/widgets/processing_stage_view.dart';
import 'package:careerly/features/analyze/presentation/widgets/cv_score_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('ProcessingStageView shows headline stage and cancel', (
    tester,
  ) async {
    var cancelled = false;
    await tester.pumpWidget(
      _wrap(
        ProcessingStageView(
          headline: 'Working…',
          stageLabel: 'Reading structure',
          progress: 0.5,
          cancelLabel: 'Cancel',
          onCancel: () => cancelled = true,
          hint: 'This may take a moment',
        ),
      ),
    );

    expect(find.text('Working…'), findsOneWidget);
    expect(find.text('Reading structure'), findsOneWidget);
    expect(find.text('This may take a moment'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    expect(cancelled, isTrue);
  });

  testWidgets('CvScoreIndicator maps low scores to critical color', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const CvScoreIndicator(score: 20, size: 64, animate: false)),
    );
    final text = tester.widget<Text>(find.text('20'));
    expect(text.style?.color, AppColors.critical);
  });

  testWidgets('ScoreBadge thresholds align with CvScoreIndicator', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const ScoreBadge(score: 70, size: 48)));
    final text = tester.widget<Text>(find.text('70'));
    expect(text.style?.color, AppColors.actionBlue);
  });

  testWidgets('AppButton destructive uses critical foreground', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppButton(
          label: 'Delete',
          variant: AppButtonVariant.destructive,
          expanded: false,
          onPressed: () {},
        ),
      ),
    );
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.style?.foregroundColor?.resolve({}), AppColors.critical);
  });

  testWidgets('AppTagChip renders tokenized label', (tester) async {
    await tester.pumpWidget(_wrap(const AppTagChip(label: 'Flutter')));
    expect(find.text('Flutter'), findsOneWidget);
  });
}
