import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../analyze/domain/analysis_models.dart';

enum CvTemplateId { classicAts, modernAts, student, tech }

enum CvDocumentLanguage { en, tr }

enum SectionCompletion { empty, partial, complete }

enum BuilderStartPoint { blank, fromAnalyzed, fromExisting }

/// Canonical structured CV — templates only render; they never own content.
class ResumeDocument extends Equatable {
  const ResumeDocument({
    required this.id,
    required this.title,
    required this.language,
    required this.templateId,
    required this.personal,
    required this.summary,
    required this.education,
    required this.experience,
    required this.projects,
    required this.skillGroups,
    required this.languages,
    required this.certifications,
    required this.awards,
    required this.customSections,
    required this.sectionOrder,
    required this.sectionVisibility,
    required this.createdAt,
    required this.updatedAt,
    this.sourceAnalysisId,
    this.parentDocumentId,
  });

  final String id;
  final String title;
  final CvDocumentLanguage language;
  final CvTemplateId templateId;
  final PersonalDetails personal;
  final String summary;
  final List<EducationEntry> education;
  final List<ExperienceEntry> experience;
  final List<ProjectEntry> projects;
  final List<SkillGroup> skillGroups;
  final List<LanguageEntry> languages;
  final List<CertificationEntry> certifications;
  final List<AwardEntry> awards;
  final List<CustomSection> customSections;
  final List<String> sectionOrder;
  final Map<String, bool> sectionVisibility;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sourceAnalysisId;
  final String? parentDocumentId;

  static const defaultSectionOrder = [
    'personal',
    'summary',
    'education',
    'experience',
    'projects',
    'skills',
    'languages',
    'certifications',
    'awards',
  ];

  factory ResumeDocument.blank({
    required CvDocumentLanguage language,
    required CvTemplateId templateId,
    String? title,
  }) {
    final now = DateTime.now().toUtc();
    return ResumeDocument(
      id: const Uuid().v4(),
      title:
          title ??
          (language == CvDocumentLanguage.tr ? 'Yeni CV' : 'Untitled CV'),
      language: language,
      templateId: templateId,
      personal: const PersonalDetails(),
      summary: '',
      education: const [],
      experience: const [],
      projects: const [],
      skillGroups: const [],
      languages: const [],
      certifications: const [],
      awards: const [],
      customSections: const [],
      sectionOrder: defaultSectionOrder,
      sectionVisibility: {for (final k in defaultSectionOrder) k: true},
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Seed from Phase 2/3 early-career fixture evidence — never invents new facts.
  factory ResumeDocument.fromAnalyzedFixture({
    required String analysisId,
    required String fileName,
    CvDocumentLanguage language = CvDocumentLanguage.en,
    CvTemplateId templateId = CvTemplateId.student,
  }) {
    final now = DateTime.now().toUtc();
    final tr = language == CvDocumentLanguage.tr;
    return ResumeDocument(
      id: const Uuid().v4(),
      title: fileName.replaceAll(
        RegExp(r'\.(pdf|docx)$', caseSensitive: false),
        '',
      ),
      language: language,
      templateId: templateId,
      personal: const PersonalDetails(
        fullName: 'Aylin Demir',
        email: 'aylin.demir@email.com',
        location: 'Istanbul',
      ),
      summary: tr
          ? 'Yazılım alanında staj arayan Bilgisayar Mühendisliği öğrencisi.'
          : 'Computer Science student seeking internship opportunities in software.',
      education: [
        EducationEntry(
          id: const Uuid().v4(),
          school: tr ? 'Üniversite' : 'University',
          degree: 'B.Sc. Computer Science',
          endDate: '2027',
        ),
      ],
      experience: [
        ExperienceEntry(
          id: const Uuid().v4(),
          organization: 'Campus Club',
          title: tr ? 'Pazarlama Stajyeri' : 'Marketing Intern',
          startDate: '2025',
          bullets: [
            tr
                ? 'Öğrenci topluluğu için etkinlik tanıtımına destek oldum.'
                : 'Supported event promotion for student community',
          ],
        ),
      ],
      projects: [
        ProjectEntry(
          id: const Uuid().v4(),
          name: 'Campus Event App',
          bullets: [
            tr
                ? 'Flutter ve Firebase ile kampüs etkinlik uygulaması geliştirdim.'
                : 'Built a campus event app using Flutter and Firebase',
          ],
          tech: const ['Flutter', 'Firebase'],
        ),
      ],
      skillGroups: [
        SkillGroup(
          id: const Uuid().v4(),
          label: tr ? 'Teknik' : 'Technical',
          skills: const ['Flutter', 'Dart', 'Python'],
        ),
        SkillGroup(
          id: const Uuid().v4(),
          label: tr ? 'Araçlar' : 'Tools',
          skills: const ['MS Office', 'Git'],
        ),
      ],
      languages: [
        LanguageEntry(
          id: const Uuid().v4(),
          name: tr ? 'Türkçe' : 'Turkish',
          level: tr ? 'Ana dil' : 'Native',
        ),
        LanguageEntry(
          id: const Uuid().v4(),
          name: tr ? 'İngilizce' : 'English',
          level: 'B2',
        ),
      ],
      certifications: const [],
      awards: [
        AwardEntry(
          id: const Uuid().v4(),
          title: tr
              ? 'Gönüllü · Coding Club mentor'
              : 'Volunteer · Coding Club mentor',
        ),
      ],
      customSections: const [],
      sectionOrder: defaultSectionOrder,
      sectionVisibility: {for (final k in defaultSectionOrder) k: true},
      createdAt: now,
      updatedAt: now,
      sourceAnalysisId: analysisId,
    );
  }

  /// Builds a version from parsed CV facts. Does not copy the sample fixture.
  factory ResumeDocument.fromEvidence({
    required CvEvidence evidence,
    required String analysisId,
    CvDocumentLanguage language = CvDocumentLanguage.en,
    CvTemplateId templateId = CvTemplateId.classicAts,
  }) {
    final now = DateTime.now().toUtc();
    final skillNames = evidence
        .linesFor('skills')
        .expand((line) => line.split(RegExp(r'[,;•]')))
        .map((s) => s.trim())
        .where((s) => s.length > 1 && s.length < 40)
        .toList();
    final experienceBullets = evidence.bulletsFor(const ['experience']);
    final projectLines = evidence.linesFor('projects');
    return ResumeDocument(
      id: const Uuid().v4(),
      title: evidence.displayName,
      language: language,
      templateId: templateId,
      personal: PersonalDetails(
        fullName: evidence.fullName ?? '',
        email: evidence.email ?? '',
        phone: evidence.phone ?? '',
        location: evidence.location ?? '',
        linkedin: evidence.linkedIn ?? '',
        website: evidence.portfolio ?? evidence.github ?? '',
      ),
      summary: evidence.summary ?? '',
      education: [
        for (final line in evidence.linesFor('education'))
          EducationEntry(id: const Uuid().v4(), school: line),
      ],
      experience: [
        if (experienceBullets.isNotEmpty)
          ExperienceEntry(
            id: const Uuid().v4(),
            bullets: experienceBullets,
          ),
      ],
      projects: [
        if (projectLines.isNotEmpty)
          ProjectEntry(
            id: const Uuid().v4(),
            name: projectLines.first,
            bullets: projectLines.length > 1
                ? projectLines.skip(1).toList()
                : projectLines,
          ),
      ],
      skillGroups: [
        if (skillNames.isNotEmpty)
          SkillGroup(
            id: const Uuid().v4(),
            label: language == CvDocumentLanguage.tr ? 'Yetenekler' : 'Skills',
            skills: skillNames,
          ),
      ],
      languages: [
        for (final line in evidence.linesFor('languages'))
          LanguageEntry(id: const Uuid().v4(), name: line),
      ],
      certifications: [
        for (final line in evidence.linesFor('certifications'))
          CertificationEntry(id: const Uuid().v4(), name: line),
      ],
      awards: const [],
      customSections: const [],
      sectionOrder: defaultSectionOrder,
      sectionVisibility: {for (final k in defaultSectionOrder) k: true},
      createdAt: now,
      updatedAt: now,
      sourceAnalysisId: analysisId,
    );
  }

  ResumeDocument copyWith({
    String? title,
    CvDocumentLanguage? language,
    CvTemplateId? templateId,
    PersonalDetails? personal,
    String? summary,
    List<EducationEntry>? education,
    List<ExperienceEntry>? experience,
    List<ProjectEntry>? projects,
    List<SkillGroup>? skillGroups,
    List<LanguageEntry>? languages,
    List<CertificationEntry>? certifications,
    List<AwardEntry>? awards,
    List<CustomSection>? customSections,
    List<String>? sectionOrder,
    Map<String, bool>? sectionVisibility,
    DateTime? updatedAt,
    String? parentDocumentId,
  }) {
    return ResumeDocument(
      id: id,
      title: title ?? this.title,
      language: language ?? this.language,
      templateId: templateId ?? this.templateId,
      personal: personal ?? this.personal,
      summary: summary ?? this.summary,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      projects: projects ?? this.projects,
      skillGroups: skillGroups ?? this.skillGroups,
      languages: languages ?? this.languages,
      certifications: certifications ?? this.certifications,
      awards: awards ?? this.awards,
      customSections: customSections ?? this.customSections,
      sectionOrder: sectionOrder ?? this.sectionOrder,
      sectionVisibility: sectionVisibility ?? this.sectionVisibility,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceAnalysisId: sourceAnalysisId,
      parentDocumentId: parentDocumentId ?? this.parentDocumentId,
    );
  }

  SectionCompletion completionFor(String key) {
    switch (key) {
      case 'personal':
        if (personal.fullName.trim().isEmpty && personal.email.trim().isEmpty) {
          return SectionCompletion.empty;
        }
        if (personal.fullName.trim().isEmpty || personal.email.trim().isEmpty) {
          return SectionCompletion.partial;
        }
        return SectionCompletion.complete;
      case 'summary':
        if (summary.trim().isEmpty) return SectionCompletion.empty;
        if (summary.trim().length < 40) return SectionCompletion.partial;
        return SectionCompletion.complete;
      case 'education':
        return education.isEmpty
            ? SectionCompletion.empty
            : SectionCompletion.complete;
      case 'experience':
        return experience.isEmpty
            ? SectionCompletion.empty
            : SectionCompletion.complete;
      case 'projects':
        return projects.isEmpty
            ? SectionCompletion.empty
            : SectionCompletion.complete;
      case 'skills':
        final n = skillGroups.fold<int>(0, (a, g) => a + g.skills.length);
        if (n == 0) return SectionCompletion.empty;
        if (n < 3) return SectionCompletion.partial;
        return SectionCompletion.complete;
      case 'languages':
        return languages.isEmpty
            ? SectionCompletion.empty
            : SectionCompletion.complete;
      case 'certifications':
        return certifications.isEmpty
            ? SectionCompletion.empty
            : SectionCompletion.complete;
      case 'awards':
        return awards.isEmpty
            ? SectionCompletion.empty
            : SectionCompletion.complete;
      default:
        return SectionCompletion.empty;
    }
  }

  String exportFileName() {
    final parts = personal.fullName.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : 'CV';
    final last = parts.length > 1 ? parts.last : 'Draft';
    final lang = language == CvDocumentLanguage.tr ? '_TR' : '_EN';
    return '${first}_${last}_CV$lang.pdf';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'language': language.name,
    'templateId': templateId.name,
    'personal': personal.toJson(),
    'summary': summary,
    'education': education.map((e) => e.toJson()).toList(),
    'experience': experience.map((e) => e.toJson()).toList(),
    'projects': projects.map((e) => e.toJson()).toList(),
    'skillGroups': skillGroups.map((e) => e.toJson()).toList(),
    'languages': languages.map((e) => e.toJson()).toList(),
    'certifications': certifications.map((e) => e.toJson()).toList(),
    'awards': awards.map((e) => e.toJson()).toList(),
    'customSections': customSections.map((e) => e.toJson()).toList(),
    'sectionOrder': sectionOrder,
    'sectionVisibility': sectionVisibility,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sourceAnalysisId': sourceAnalysisId,
    'parentDocumentId': parentDocumentId,
  };

  factory ResumeDocument.fromJson(Map<String, dynamic> json) {
    return ResumeDocument(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'CV',
      language: CvDocumentLanguage.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => CvDocumentLanguage.en,
      ),
      templateId: CvTemplateId.values.firstWhere(
        (e) => e.name == json['templateId'],
        orElse: () => CvTemplateId.classicAts,
      ),
      personal: PersonalDetails.fromJson(
        (json['personal'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      summary: json['summary'] as String? ?? '',
      education: (json['education'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(EducationEntry.fromJson)
          .toList(),
      experience: (json['experience'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ExperienceEntry.fromJson)
          .toList(),
      projects: (json['projects'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ProjectEntry.fromJson)
          .toList(),
      skillGroups: (json['skillGroups'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(SkillGroup.fromJson)
          .toList(),
      languages: (json['languages'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(LanguageEntry.fromJson)
          .toList(),
      certifications: (json['certifications'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(CertificationEntry.fromJson)
          .toList(),
      awards: (json['awards'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(AwardEntry.fromJson)
          .toList(),
      customSections: (json['customSections'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(CustomSection.fromJson)
          .toList(),
      sectionOrder:
          (json['sectionOrder'] as List?)?.cast<String>() ??
          defaultSectionOrder,
      sectionVisibility: Map<String, bool>.from(
        (json['sectionVisibility'] as Map?) ??
            {for (final k in defaultSectionOrder) k: true},
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      sourceAnalysisId: json['sourceAnalysisId'] as String?,
      parentDocumentId: json['parentDocumentId'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, language, templateId, updatedAt];
}

class PersonalDetails extends Equatable {
  const PersonalDetails({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.website = '',
  });

  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String linkedin;
  final String website;

  PersonalDetails copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? location,
    String? linkedin,
    String? website,
  }) {
    return PersonalDetails(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      linkedin: linkedin ?? this.linkedin,
      website: website ?? this.website,
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'location': location,
    'linkedin': linkedin,
    'website': website,
  };

  factory PersonalDetails.fromJson(Map<String, dynamic> json) {
    return PersonalDetails(
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      linkedin: json['linkedin'] as String? ?? '',
      website: json['website'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    fullName,
    email,
    phone,
    location,
    linkedin,
    website,
  ];
}

class EducationEntry extends Equatable {
  const EducationEntry({
    required this.id,
    this.school = '',
    this.degree = '',
    this.field = '',
    this.startDate = '',
    this.endDate = '',
    this.details = '',
  });

  final String id;
  final String school;
  final String degree;
  final String field;
  final String startDate;
  final String endDate;
  final String details;

  EducationEntry copyWith({
    String? school,
    String? degree,
    String? field,
    String? startDate,
    String? endDate,
    String? details,
  }) {
    return EducationEntry(
      id: id,
      school: school ?? this.school,
      degree: degree ?? this.degree,
      field: field ?? this.field,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'school': school,
    'degree': degree,
    'field': field,
    'startDate': startDate,
    'endDate': endDate,
    'details': details,
  };

  factory EducationEntry.fromJson(Map<String, dynamic> json) {
    return EducationEntry(
      id: json['id'] as String? ?? const Uuid().v4(),
      school: json['school'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      field: json['field'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      details: json['details'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, school, degree, field, startDate, endDate];
}

class ExperienceEntry extends Equatable {
  const ExperienceEntry({
    required this.id,
    this.organization = '',
    this.title = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.bullets = const [],
  });

  final String id;
  final String organization;
  final String title;
  final String location;
  final String startDate;
  final String endDate;
  final List<String> bullets;

  ExperienceEntry copyWith({
    String? organization,
    String? title,
    String? location,
    String? startDate,
    String? endDate,
    List<String>? bullets,
  }) {
    return ExperienceEntry(
      id: id,
      organization: organization ?? this.organization,
      title: title ?? this.title,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bullets: bullets ?? this.bullets,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization': organization,
    'title': title,
    'location': location,
    'startDate': startDate,
    'endDate': endDate,
    'bullets': bullets,
  };

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) {
    return ExperienceEntry(
      id: json['id'] as String? ?? const Uuid().v4(),
      organization: json['organization'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      bullets: (json['bullets'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    organization,
    title,
    location,
    startDate,
    endDate,
    bullets,
  ];
}

class ProjectEntry extends Equatable {
  const ProjectEntry({
    required this.id,
    this.name = '',
    this.url = '',
    this.bullets = const [],
    this.tech = const [],
  });

  final String id;
  final String name;
  final String url;
  final List<String> bullets;
  final List<String> tech;

  ProjectEntry copyWith({
    String? name,
    String? url,
    List<String>? bullets,
    List<String>? tech,
  }) {
    return ProjectEntry(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      bullets: bullets ?? this.bullets,
      tech: tech ?? this.tech,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'bullets': bullets,
    'tech': tech,
  };

  factory ProjectEntry.fromJson(Map<String, dynamic> json) {
    return ProjectEntry(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      bullets: (json['bullets'] as List?)?.cast<String>() ?? const [],
      tech: (json['tech'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  List<Object?> get props => [id, name, url, bullets, tech];
}

class SkillGroup extends Equatable {
  const SkillGroup({required this.id, this.label = '', this.skills = const []});

  final String id;
  final String label;
  final List<String> skills;

  SkillGroup copyWith({String? label, List<String>? skills}) {
    return SkillGroup(
      id: id,
      label: label ?? this.label,
      skills: skills ?? this.skills,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'skills': skills};

  factory SkillGroup.fromJson(Map<String, dynamic> json) {
    return SkillGroup(
      id: json['id'] as String? ?? const Uuid().v4(),
      label: json['label'] as String? ?? '',
      skills: (json['skills'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  List<Object?> get props => [id, label, skills];
}

class LanguageEntry extends Equatable {
  const LanguageEntry({required this.id, this.name = '', this.level = ''});

  final String id;
  final String name;
  final String level;

  LanguageEntry copyWith({String? name, String? level}) {
    return LanguageEntry(
      id: id,
      name: name ?? this.name,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'level': level};

  factory LanguageEntry.fromJson(Map<String, dynamic> json) {
    return LanguageEntry(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      level: json['level'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, level];
}

class CertificationEntry extends Equatable {
  const CertificationEntry({
    required this.id,
    this.name = '',
    this.issuer = '',
    this.date = '',
  });

  final String id;
  final String name;
  final String issuer;
  final String date;

  CertificationEntry copyWith({String? name, String? issuer, String? date}) {
    return CertificationEntry(
      id: id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'issuer': issuer,
    'date': date,
  };

  factory CertificationEntry.fromJson(Map<String, dynamic> json) {
    return CertificationEntry(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, issuer, date];
}

class AwardEntry extends Equatable {
  const AwardEntry({required this.id, this.title = '', this.year = ''});

  final String id;
  final String title;
  final String year;

  AwardEntry copyWith({String? title, String? year}) {
    return AwardEntry(
      id: id,
      title: title ?? this.title,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'year': year};

  factory AwardEntry.fromJson(Map<String, dynamic> json) {
    return AwardEntry(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? '',
      year: json['year'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, title, year];
}

class CustomSection extends Equatable {
  const CustomSection({
    required this.id,
    this.title = '',
    this.bullets = const [],
  });

  final String id;
  final String title;
  final List<String> bullets;

  CustomSection copyWith({String? title, List<String>? bullets}) {
    return CustomSection(
      id: id,
      title: title ?? this.title,
      bullets: bullets ?? this.bullets,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'bullets': bullets,
  };

  factory CustomSection.fromJson(Map<String, dynamic> json) {
    return CustomSection(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? '',
      bullets: (json['bullets'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  List<Object?> get props => [id, title, bullets];
}

class RewriteSuggestion extends Equatable {
  const RewriteSuggestion({
    required this.original,
    required this.suggested,
    required this.why,
    this.needsUserFact = false,
    this.missingFactPrompt,
  });

  final String original;
  final String suggested;
  final String why;
  final bool needsUserFact;
  final String? missingFactPrompt;

  factory RewriteSuggestion.fromJson(Map<String, dynamic> json) {
    return RewriteSuggestion(
      original: json['original'] as String? ?? '',
      suggested: json['suggested'] as String? ?? '',
      why: json['why'] as String? ?? '',
      needsUserFact: json['needsUserFact'] as bool? ?? false,
      missingFactPrompt: json['missingFactPrompt'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    original,
    suggested,
    why,
    needsUserFact,
    missingFactPrompt,
  ];
}
