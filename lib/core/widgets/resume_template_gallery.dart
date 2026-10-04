import 'package:flutter/material.dart';

import '../../app/localization/l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../../features/cv_builder/domain/resume_document.dart';

/// Abstract layout thumbnails. No invented personal data or template counts.
class ResumeTemplateGallery extends StatelessWidget {
  const ResumeTemplateGallery({
    super.key,
    required this.onSelected,
    this.grid = false,
    this.query = '',
  });

  final ValueChanged<CvTemplateId> onSelected;
  final bool grid;
  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.builderTemplateClassic,
      l10n.builderTemplateModern,
      l10n.builderTemplateStudent,
      l10n.builderTemplateTech,
    ];
    const colors = [
      AppColors.purple,
      AppColors.cyan,
      AppColors.olive,
      Color(0xFFBE9D77),
    ];
    final indices = [
      for (var i = 0; i < labels.length; i++)
        if (labels[i].toLowerCase().contains(query.trim().toLowerCase())) i,
    ];
    Widget card(int index) => Semantics(
      button: true,
      label: labels[index],
      child: Material(
        color: colors[index],
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelected(CvTemplateId.values[index]),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: ResumeLayoutThumbnail(
                      template: CvTemplateId.values[index],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  labels[index],
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (indices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l10n.emptyGenericTitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    if (grid) {
      return LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: indices.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth >= 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 218,
          ),
          itemBuilder: (_, index) => card(indices[index]),
        ),
      );
    }
    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemBuilder: (_, index) => SizedBox(width: 156, child: card(index)),
      ),
    );
  }
}

class SearchableResumeTemplateGallery extends StatefulWidget {
  const SearchableResumeTemplateGallery({super.key, required this.onSelected});
  final ValueChanged<CvTemplateId> onSelected;

  @override
  State<SearchableResumeTemplateGallery> createState() =>
      _SearchableGalleryState();
}

class _SearchableGalleryState extends State<SearchableResumeTemplateGallery> {
  String _query = '';

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: AppLocalizations.of(context).builderTemplate,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      ResumeTemplateGallery(
        grid: true,
        query: _query,
        onSelected: widget.onSelected,
      ),
    ],
  );
}

class ResumeLayoutThumbnail extends StatelessWidget {
  const ResumeLayoutThumbnail({
    super.key,
    this.template = CvTemplateId.classicAts,
  });
  final CvTemplateId template;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 0.707,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(painter: _ResumeLayoutPainter(template)),
      ),
    ),
  );
}

class _ResumeLayoutPainter extends CustomPainter {
  const _ResumeLayoutPainter(this.template);
  final CvTemplateId template;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()..color = const Color(0xFF414741);
    final muted = Paint()..color = const Color(0xFFD2D6D0);
    final left = size.width * .13;
    final contentWidth = size.width * .74;
    canvas.drawRect(
      Rect.fromLTWH(left, size.height * .10, contentWidth * .66, 4),
      ink,
    );
    canvas.drawRect(
      Rect.fromLTWH(left, size.height * .16, contentWidth * .42, 2),
      muted,
    );
    for (var section = 0; section < 4; section++) {
      final y = size.height * (.25 + section * .17);
      canvas.drawRect(Rect.fromLTWH(left, y, contentWidth * .4, 2.5), ink);
      for (var line = 0; line < 3; line++) {
        canvas.drawRect(
          Rect.fromLTWH(
            left,
            y + 8 + line * 5,
            contentWidth * (line == 2 ? .7 : 1),
            1.5,
          ),
          muted,
        );
      }
    }
    if (template != CvTemplateId.classicAts) {
      final accent = switch (template) {
        CvTemplateId.modernAts => AppColors.cyan,
        CvTemplateId.student => AppColors.olive,
        _ => AppColors.purple,
      };
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, 5),
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_ResumeLayoutPainter oldDelegate) =>
      oldDelegate.template != template;
}
