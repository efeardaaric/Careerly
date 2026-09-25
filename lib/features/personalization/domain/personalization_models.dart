enum CareerStage {
  student,
  intern,
  newGraduate,
  professional,
  careerChanger;

  String get storageKey => name;

  static CareerStage? fromStorage(String? value) {
    if (value == null) return null;
    for (final item in CareerStage.values) {
      if (item.storageKey == value) return item;
    }
    return null;
  }
}

enum CareerGoal {
  internship,
  partTime,
  fullTime,
  graduateProgram,
  notSure;

  String get storageKey => name;

  static CareerGoal? fromStorage(String? value) {
    if (value == null) return null;
    for (final item in CareerGoal.values) {
      if (item.storageKey == value) return item;
    }
    return null;
  }
}

enum CvLanguagePreference {
  turkish,
  english,
  both;

  String get storageKey => name;

  static CvLanguagePreference? fromStorage(String? value) {
    if (value == null) return null;
    for (final item in CvLanguagePreference.values) {
      if (item.storageKey == value) return item;
    }
    return null;
  }
}

/// Suggested interest fields for multi-select personalization.
abstract final class InterestFields {
  static const all = <String>[
    'software',
    'data',
    'finance',
    'marketing',
    'product',
    'design',
    'engineering',
    'healthcare',
    'education',
    'other',
  ];
}
