import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

import '../domain/resume_document.dart';

/// Shared A4 geometry — templates only change presentation, never content.
abstract final class CvPageFormat {
  static const PdfPageFormat a4 = PdfPageFormat.a4;
  static const double margin = 36;
}

class CvFontBundle {
  const CvFontBundle({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;

  static Future<CvFontBundle> load() async {
    // Noto covers TR/EN Latin Extended for searchable PDF text.
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );
    return CvFontBundle(regular: regular, bold: bold);
  }
}

typedef CvTemplateBuilder = Future<pw.Document> Function(ResumeDocument doc);

CvTemplateBuilder templateBuilderFor(CvTemplateId id) {
  return switch (id) {
    CvTemplateId.classicAts => ClassicAtsTemplate.build,
    CvTemplateId.modernAts => ModernAtsTemplate.build,
    CvTemplateId.student => StudentTemplate.build,
    CvTemplateId.tech => TechTemplate.build,
  };
}

String sectionTitle(ResumeDocument doc, String key) {
  final tr = doc.language == CvDocumentLanguage.tr;
  return switch (key) {
    'summary' => tr ? 'Özet' : 'Summary',
    'education' => tr ? 'Eğitim' : 'Education',
    'experience' => tr ? 'Deneyim' : 'Experience',
    'projects' => tr ? 'Projeler' : 'Projects',
    'skills' => tr ? 'Beceriler' : 'Skills',
    'languages' => tr ? 'Diller' : 'Languages',
    'certifications' => tr ? 'Sertifikalar' : 'Certifications',
    'awards' => tr ? 'Ödüller / Aktiviteler' : 'Awards / Activities',
    _ => key,
  };
}

bool isVisible(ResumeDocument doc, String key) =>
    doc.sectionVisibility[key] ?? true;

List<String> visibleOrder(ResumeDocument doc) => doc.sectionOrder
    .where((k) => k != 'personal' && isVisible(doc, k))
    .toList();

/// Classic single-column ATS-safe layout.
abstract final class ClassicAtsTemplate {
  static Future<pw.Document> build(ResumeDocument doc) async {
    final fonts = await CvFontBundle.load();
    final theme = pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);
    final pdf = pw.Document(
      title: doc.title,
      author: doc.personal.fullName,
      theme: theme,
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: CvPageFormat.a4,
        margin: const pw.EdgeInsets.all(CvPageFormat.margin),
        theme: theme,
        build: (context) => [
          _header(doc, size: 18, accent: PdfColors.black),
          pw.SizedBox(height: 10),
          ..._sections(doc, headingStyle: _classicHeading),
        ],
      ),
    );
    return pdf;
  }
}

/// Modern ATS: slightly stronger header rule, still single-column searchable text.
abstract final class ModernAtsTemplate {
  static Future<pw.Document> build(ResumeDocument doc) async {
    final fonts = await CvFontBundle.load();
    final theme = pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);
    final pdf = pw.Document(
      title: doc.title,
      author: doc.personal.fullName,
      theme: theme,
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: CvPageFormat.a4,
        margin: const pw.EdgeInsets.all(CvPageFormat.margin),
        theme: theme,
        build: (context) => [
          _header(doc, size: 20, accent: PdfColor.fromInt(0xFF1F5EFF)),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 6, bottom: 12),
            height: 2,
            color: PdfColor.fromInt(0xFF1F5EFF),
          ),
          ..._sections(doc, headingStyle: _modernHeading),
        ],
      ),
    );
    return pdf;
  }
}

/// Student-friendly: education & projects emphasized via order-safe headings.
abstract final class StudentTemplate {
  static Future<pw.Document> build(ResumeDocument doc) async {
    final fonts = await CvFontBundle.load();
    final theme = pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);
    final preferred = [
      'summary',
      'education',
      'projects',
      'experience',
      'skills',
      'languages',
      'certifications',
      'awards',
    ];
    final order = [
      ...preferred.where((k) => visibleOrder(doc).contains(k)),
      ...visibleOrder(doc).where((k) => !preferred.contains(k)),
    ];
    final pdf = pw.Document(
      title: doc.title,
      author: doc.personal.fullName,
      theme: theme,
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: CvPageFormat.a4,
        margin: const pw.EdgeInsets.all(CvPageFormat.margin),
        theme: theme,
        build: (context) => [
          _header(doc, size: 18, accent: PdfColor.fromInt(0xFF10233F)),
          pw.SizedBox(height: 8),
          ..._sectionsForOrder(doc, order, headingStyle: _classicHeading),
        ],
      ),
    );
    return pdf;
  }
}

/// Tech: compact skills-first presentation still as plain text groups (no bars).
abstract final class TechTemplate {
  static Future<pw.Document> build(ResumeDocument doc) async {
    final fonts = await CvFontBundle.load();
    final theme = pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);
    final preferred = [
      'summary',
      'skills',
      'projects',
      'experience',
      'education',
      'languages',
      'certifications',
      'awards',
    ];
    final order = [
      ...preferred.where((k) => visibleOrder(doc).contains(k)),
      ...visibleOrder(doc).where((k) => !preferred.contains(k)),
    ];
    final pdf = pw.Document(
      title: doc.title,
      author: doc.personal.fullName,
      theme: theme,
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: CvPageFormat.a4,
        margin: const pw.EdgeInsets.all(CvPageFormat.margin),
        theme: theme,
        build: (context) => [
          _header(doc, size: 18, accent: PdfColor.fromInt(0xFF10233F)),
          pw.SizedBox(height: 8),
          ..._sectionsForOrder(doc, order, headingStyle: _techHeading),
        ],
      ),
    );
    return pdf;
  }
}

pw.Widget _header(
  ResumeDocument doc, {
  required double size,
  required PdfColor accent,
}) {
  final p = doc.personal;
  final contact = [
    p.email,
    p.phone,
    p.location,
    p.linkedin,
    p.website,
  ].where((e) => e.trim().isNotEmpty).join(' · ');
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        p.fullName.isEmpty ? doc.title : p.fullName,
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: pw.FontWeight.bold,
          color: accent,
        ),
      ),
      if (contact.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(contact, style: const pw.TextStyle(fontSize: 9)),
        ),
    ],
  );
}

pw.TextStyle get _classicHeading => pw.TextStyle(
  fontSize: 11,
  fontWeight: pw.FontWeight.bold,
  color: PdfColors.black,
);

pw.TextStyle get _modernHeading => pw.TextStyle(
  fontSize: 11,
  fontWeight: pw.FontWeight.bold,
  color: PdfColor.fromInt(0xFF1F5EFF),
);

pw.TextStyle get _techHeading => pw.TextStyle(
  fontSize: 10,
  fontWeight: pw.FontWeight.bold,
  color: PdfColor.fromInt(0xFF10233F),
);

List<pw.Widget> _sections(
  ResumeDocument doc, {
  required pw.TextStyle headingStyle,
}) => _sectionsForOrder(doc, visibleOrder(doc), headingStyle: headingStyle);

List<pw.Widget> _sectionsForOrder(
  ResumeDocument doc,
  List<String> order, {
  required pw.TextStyle headingStyle,
}) {
  final out = <pw.Widget>[];
  for (final key in order) {
    final body = _sectionBody(doc, key);
    if (body == null) continue;
    out.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(sectionTitle(doc, key).toUpperCase(), style: headingStyle),
            pw.SizedBox(height: 4),
            body,
          ],
        ),
      ),
    );
  }
  for (final custom in doc.customSections) {
    if (custom.title.trim().isEmpty && custom.bullets.isEmpty) continue;
    out.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              (custom.title.isEmpty ? 'Custom' : custom.title).toUpperCase(),
              style: headingStyle,
            ),
            pw.SizedBox(height: 4),
            ...custom.bullets.map(
              (b) =>
                  pw.Bullet(text: b, style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
  return out;
}

pw.Widget? _sectionBody(ResumeDocument doc, String key) {
  switch (key) {
    case 'summary':
      if (doc.summary.trim().isEmpty) return null;
      return pw.Text(doc.summary, style: const pw.TextStyle(fontSize: 10));
    case 'education':
      if (doc.education.isEmpty) return null;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: doc.education.map((e) {
          final head = [
            e.school,
            e.degree,
            e.field,
          ].where((x) => x.trim().isNotEmpty).join(' · ');
          final dates = [
            e.startDate,
            e.endDate,
          ].where((x) => x.trim().isNotEmpty).join(' – ');
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  dates.isEmpty ? head : '$head ($dates)',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (e.details.trim().isNotEmpty)
                  pw.Text(e.details, style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          );
        }).toList(),
      );
    case 'experience':
      if (doc.experience.isEmpty) return null;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: doc.experience.map((e) {
          final head = [
            e.title,
            e.organization,
            e.location,
          ].where((x) => x.trim().isNotEmpty).join(' · ');
          final dates = [
            e.startDate,
            e.endDate,
          ].where((x) => x.trim().isNotEmpty).join(' – ');
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  dates.isEmpty ? head : '$head ($dates)',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                ...e.bullets.map(
                  (b) => pw.Bullet(
                    text: b,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    case 'projects':
      if (doc.projects.isEmpty) return null;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: doc.projects.map((p) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  p.name,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (p.tech.isNotEmpty)
                  pw.Text(
                    'Tech: ${p.tech.join(', ')}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ...p.bullets.map(
                  (b) => pw.Bullet(
                    text: b,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    case 'skills':
      if (doc.skillGroups.isEmpty) return null;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: doc.skillGroups.map((g) {
          final skills = g.skills.join(', ');
          final line = g.label.trim().isEmpty ? skills : '${g.label}: $skills';
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
          );
        }).toList(),
      );
    case 'languages':
      if (doc.languages.isEmpty) return null;
      return pw.Text(
        doc.languages
            .map((l) => l.level.isEmpty ? l.name : '${l.name} (${l.level})')
            .join(' · '),
        style: const pw.TextStyle(fontSize: 10),
      );
    case 'certifications':
      if (doc.certifications.isEmpty) return null;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: doc.certifications
            .map(
              (c) => pw.Text(
                [
                  c.name,
                  c.issuer,
                  c.date,
                ].where((x) => x.trim().isNotEmpty).join(' · '),
                style: const pw.TextStyle(fontSize: 10),
              ),
            )
            .toList(),
      );
    case 'awards':
      if (doc.awards.isEmpty) return null;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: doc.awards
            .map(
              (a) => pw.Text(
                a.year.isEmpty ? a.title : '${a.title} · ${a.year}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            )
            .toList(),
      );
    default:
      return null;
  }
}
