import 'package:careerly/features/cv_builder/domain/resume_document.dart';
import 'package:careerly/features/cv_builder/presentation/widgets/builder_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StructuredCvPreview shows name and project content', (
    tester,
  ) async {
    final doc = ResumeDocument.fromAnalyzedFixture(
      analysisId: 'a1',
      fileName: 'aylin.pdf',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StructuredCvPreview(document: doc, zoom: 1)),
      ),
    );
    expect(find.textContaining('Aylin Demir'), findsWidgets);
    expect(find.textContaining('Campus Event App'), findsOneWidget);
    expect(find.textContaining('Flutter'), findsWidgets);
  });
}
