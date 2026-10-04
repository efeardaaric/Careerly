import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:careerly/core/widgets/processing_stage_view.dart';
import 'package:careerly/core/widgets/resume_template_gallery.dart';
import 'package:careerly/features/cv_builder/domain/resume_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget localized(Widget child, {double scale = 1}) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets(
    'template search filters cards without changing their selection',
    (tester) async {
      CvTemplateId? selected;
      await tester.pumpWidget(
        localized(
          SearchableResumeTemplateGallery(
            onSelected: (value) => selected = value,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Modern');
      await tester.pump();
      expect(find.byType(ResumeLayoutThumbnail), findsOneWidget);
      await tester.tap(find.text('Modern ATS'));
      expect(selected, CvTemplateId.modernAts);
      await tester.enterText(find.byType(TextField), 'does not exist');
      await tester.pump();
      expect(find.byType(ResumeLayoutThumbnail), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('all four gallery cards select the corresponding real template', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(720, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    CvTemplateId? selected;
    await tester.pumpWidget(
      localized(
        ResumeTemplateGallery(
          grid: true,
          onSelected: (value) => selected = value,
        ),
      ),
    );
    for (var index = 0; index < CvTemplateId.values.length; index++) {
      await tester.tap(find.byType(InkWell).at(index));
      expect(selected, CvTemplateId.values[index]);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('template grid fits a narrow phone with enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      localized(
        SingleChildScrollView(
          child: ResumeTemplateGallery(grid: true, onSelected: (_) {}),
        ),
        scale: 1.5,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'processing scrolls on small screens and keeps cancel available',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var cancelled = false;
      await tester.pumpWidget(
        localized(
          ProcessingStageView(
            headline: 'Reading your resume carefully',
            stageLabel: 'Checking structure',
            progress: .4,
            stages: const [
              'Reading structure',
              'Detecting sections',
              'Checking readability',
              'Reviewing content',
            ],
            cancelLabel: 'Cancel',
            onCancel: () => cancelled = true,
          ),
          scale: 1.5,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      expect(cancelled, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
