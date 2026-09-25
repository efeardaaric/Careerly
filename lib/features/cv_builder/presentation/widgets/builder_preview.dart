import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/resume_document.dart';
import '../../pdf/resume_pdf_renderer.dart';
import '../../templates/cv_templates.dart';

/// Live CV preview. On web, [PdfPreview] frequently fails (PDF.js / fonts);
/// we render a structured A4 layout from the same [ResumeDocument] instead.
/// Native/desktop still prefer raster PDF preview with structured fallback.
class BuilderPreview extends StatefulWidget {
  const BuilderPreview({
    super.key,
    required this.document,
    required this.zoom,
    required this.onZoom,
  });

  final ResumeDocument document;
  final double zoom;
  final ValueChanged<double> onZoom;

  @override
  State<BuilderPreview> createState() => _BuilderPreviewState();
}

class _BuilderPreviewState extends State<BuilderPreview> {
  Object? _pdfError;

  @override
  void didUpdateWidget(covariant BuilderPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document ||
        oldWidget.document.templateId != widget.document.templateId) {
      _pdfError = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final useStructured = kIsWeb || _pdfError != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Text(
                l10n.builderPreviewTab,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.builderZoomOut,
                onPressed: () => widget.onZoom(widget.zoom - 0.1),
                icon: const Icon(Icons.zoom_out),
              ),
              Text('${(widget.zoom * 100).round()}%'),
              IconButton(
                tooltip: l10n.builderZoomIn,
                onPressed: () => widget.onZoom(widget.zoom + 0.1),
                icon: const Icon(Icons.zoom_in),
              ),
            ],
          ),
        ),
        if (useStructured && !kIsWeb && _pdfError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.builderPreviewFallback,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.secondaryText),
            ),
          ),
        Expanded(
          child: ColoredBox(
            color: AppColors.canvas,
            child: useStructured
                ? StructuredCvPreview(
                    document: widget.document,
                    zoom: widget.zoom,
                  )
                : PdfPreview(
                    maxPageWidth: 595 * widget.zoom,
                    build: (format) =>
                        ResumePdfRenderer.buildBytes(widget.document),
                    allowPrinting: false,
                    allowSharing: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    pdfFileName: widget.document.exportFileName(),
                    initialPageFormat: PdfPageFormat.a4,
                    onError: (context, error) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _pdfError == null) {
                          setState(() => _pdfError = error);
                        }
                      });
                      return StructuredCvPreview(
                        document: widget.document,
                        zoom: widget.zoom,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// Widget A4 preview from canonical [ResumeDocument] — same content as PDF.
class StructuredCvPreview extends StatelessWidget {
  const StructuredCvPreview({
    super.key,
    required this.document,
    required this.zoom,
  });

  final ResumeDocument document;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final pageWidth = 595.0 * zoom.clamp(0.6, 1.6);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: pageWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl * zoom.clamp(0.6, 1.6)),
                  child: _CvPageBody(document: document),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CvPageBody extends StatelessWidget {
  const _CvPageBody({required this.document});

  final ResumeDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = document.personal;
    final name = p.fullName.trim().isEmpty ? document.title : p.fullName;
    final contact = [
      p.email,
      p.phone,
      p.location,
      p.linkedin,
      p.website,
    ].where((e) => e.trim().isNotEmpty).join(' · ');

    final accent = switch (document.templateId) {
      CvTemplateId.modernAts => AppColors.actionBlue,
      CvTemplateId.tech || CvTemplateId.student => AppColors.deepNavy,
      CvTemplateId.classicAts => AppColors.deepNavy,
    };

    final order = _previewOrder(document);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (contact.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(contact, style: theme.textTheme.bodySmall),
        ],
        if (document.templateId == CvTemplateId.modernAts) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(height: 2, color: AppColors.actionBlue),
        ],
        const SizedBox(height: AppSpacing.md),
        for (final key in order) ..._section(context, key),
        for (final custom in document.customSections)
          if (custom.title.trim().isNotEmpty || custom.bullets.isNotEmpty) ...[
            Text(
              (custom.title.isEmpty ? 'Custom' : custom.title).toUpperCase(),
              style: theme.textTheme.titleSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            for (final b in custom.bullets)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.xxs,
                ),
                child: Text('• $b', style: theme.textTheme.bodyMedium),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  List<String> _previewOrder(ResumeDocument doc) {
    final visible = visibleOrder(doc);
    final preferred = switch (doc.templateId) {
      CvTemplateId.student => const [
        'summary',
        'education',
        'projects',
        'experience',
        'skills',
        'languages',
        'certifications',
        'awards',
      ],
      CvTemplateId.tech => const [
        'summary',
        'skills',
        'projects',
        'experience',
        'education',
        'languages',
        'certifications',
        'awards',
      ],
      _ => visible,
    };
    if (identical(preferred, visible)) return visible;
    return [
      ...preferred.where(visible.contains),
      ...visible.where((k) => !preferred.contains(k)),
    ];
  }

  List<Widget> _section(BuildContext context, String key) {
    final theme = Theme.of(context);
    final title = sectionTitle(document, key).toUpperCase();
    final accent = document.templateId == CvTemplateId.modernAts
        ? AppColors.actionBlue
        : AppColors.deepNavy;

    Widget? body;
    switch (key) {
      case 'summary':
        if (document.summary.trim().isEmpty) return const [];
        body = Text(document.summary, style: theme.textTheme.bodyMedium);
      case 'education':
        if (document.education.isEmpty) return const [];
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in document.education)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  [
                    e.school,
                    e.degree,
                    e.field,
                    if (e.endDate.isNotEmpty) '(${e.endDate})',
                  ].where((x) => x.trim().isNotEmpty).join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      case 'experience':
        if (document.experience.isEmpty) return const [];
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in document.experience) ...[
              Text(
                [
                  e.title,
                  e.organization,
                ].where((x) => x.trim().isNotEmpty).join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final b in e.bullets)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xs,
                    bottom: AppSpacing.xxs,
                  ),
                  child: Text('• $b', style: theme.textTheme.bodyMedium),
                ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        );
      case 'projects':
        if (document.projects.isEmpty) return const [];
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in document.projects) ...[
              Text(
                p.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (p.tech.isNotEmpty)
                Text(
                  'Tech: ${p.tech.join(', ')}',
                  style: theme.textTheme.bodySmall,
                ),
              for (final b in p.bullets)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xs,
                    bottom: AppSpacing.xxs,
                  ),
                  child: Text('• $b', style: theme.textTheme.bodyMedium),
                ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        );
      case 'skills':
        if (document.skillGroups.isEmpty) return const [];
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final g in document.skillGroups)
              Text(
                g.label.trim().isEmpty
                    ? g.skills.join(', ')
                    : '${g.label}: ${g.skills.join(', ')}',
                style: theme.textTheme.bodyMedium,
              ),
          ],
        );
      case 'languages':
        if (document.languages.isEmpty) return const [];
        body = Text(
          document.languages
              .map((l) => l.level.isEmpty ? l.name : '${l.name} (${l.level})')
              .join(' · '),
          style: theme.textTheme.bodyMedium,
        );
      case 'certifications':
        if (document.certifications.isEmpty) return const [];
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in document.certifications)
              Text(
                [
                  c.name,
                  c.issuer,
                  c.date,
                ].where((x) => x.trim().isNotEmpty).join(' · '),
                style: theme.textTheme.bodyMedium,
              ),
          ],
        );
      case 'awards':
        if (document.awards.isEmpty) return const [];
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final a in document.awards)
              Text(
                a.year.isEmpty ? a.title : '${a.title} · ${a.year}',
                style: theme.textTheme.bodyMedium,
              ),
          ],
        );
      default:
        return const [];
    }

    return [
      Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: AppSpacing.xxs),
      body,
      const SizedBox(height: AppSpacing.sm),
    ];
  }
}
