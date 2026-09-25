import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/resume_document.dart';
import '../templates/cv_templates.dart';

/// Builds a searchable (text) PDF from [ResumeDocument]. Template switch does
/// not alter structured content — only layout.
abstract final class ResumePdfRenderer {
  static Future<pw.Document> buildDocument(ResumeDocument doc) {
    return templateBuilderFor(doc.templateId)(doc);
  }

  static Future<Uint8List> buildBytes(ResumeDocument doc) async {
    final document = await buildDocument(doc);
    return document.save();
  }

  static Future<void> sharePdf(ResumeDocument doc) async {
    final bytes = await buildBytes(doc);
    await Printing.sharePdf(bytes: bytes, filename: doc.exportFileName());
  }

  static Future<void> layoutPdf(ResumeDocument doc) async {
    final bytes = await buildBytes(doc);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: doc.exportFileName(),
    );
  }
}
