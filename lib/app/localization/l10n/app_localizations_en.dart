// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Careerly AI';

  @override
  String get tagline => 'Clarity for every application.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get signOut => 'Sign out';

  @override
  String get comingSoon => 'Coming in a later release';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change this anytime in Profile.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get onboardingTitle1 => 'Know how your CV performs.';

  @override
  String get onboardingBody1 =>
      'See a clear readiness score and the exact fixes that move you forward.';

  @override
  String get onboardingTitle2 => 'Match every application.';

  @override
  String get onboardingBody2 =>
      'Compare your CV to a real job description and close the gaps that matter.';

  @override
  String get onboardingTitle3 => 'Built for ATS. Written for people.';

  @override
  String get onboardingBody3 =>
      'Stay parser-safe while sounding confident, specific, and human.';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get authWelcomeTitle => 'Welcome to Careerly';

  @override
  String get authWelcomeSubtitle =>
      'Create an account to save your progress. Mock sign-in is for Phase 1 only.';

  @override
  String get authMockBanner => 'Demo auth — not production';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authPasswordHint => 'At least 8 characters';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authOrEmail => 'or continue with email';

  @override
  String get authSwitchToSignIn => 'Already have an account? Sign in';

  @override
  String get authSwitchToSignUp => 'New here? Create an account';

  @override
  String get authEmailRequired => 'Enter a valid email address.';

  @override
  String get authPasswordRequired => 'Password must be at least 8 characters.';

  @override
  String get authGenericError => 'Something went wrong. Please try again.';

  @override
  String get authEmailConfirmation =>
      'Check your email to confirm your account, then sign in.';

  @override
  String get authSuccess => 'You\'re signed in.';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String personalizationProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get personalizationStep1Title => 'What best describes you?';

  @override
  String get personalizationStep1Subtitle =>
      'We\'ll tailor guidance to your stage.';

  @override
  String get careerStageStudent => 'Student';

  @override
  String get careerStageIntern => 'Intern';

  @override
  String get careerStageNewGraduate => 'New Graduate';

  @override
  String get careerStageProfessional => 'Professional';

  @override
  String get careerStageCareerChanger => 'Career Changer';

  @override
  String get personalizationStep2Title => 'What are you looking for?';

  @override
  String get personalizationStep2Subtitle =>
      'Pick the opportunity type that fits right now.';

  @override
  String get goalInternship => 'Internship';

  @override
  String get goalPartTime => 'Part-time';

  @override
  String get goalFullTime => 'Full-time';

  @override
  String get goalGraduateProgram => 'Graduate Program';

  @override
  String get goalNotSure => 'Not sure yet';

  @override
  String get personalizationStep3Title => 'Fields & CV language';

  @override
  String get personalizationStep3Subtitle =>
      'Select areas of interest and how you write your CV.';

  @override
  String get fieldSoftware => 'Software';

  @override
  String get fieldData => 'Data';

  @override
  String get fieldFinance => 'Finance';

  @override
  String get fieldMarketing => 'Marketing';

  @override
  String get fieldProduct => 'Product';

  @override
  String get fieldDesign => 'Design';

  @override
  String get fieldEngineering => 'Engineering';

  @override
  String get fieldHealthcare => 'Healthcare';

  @override
  String get fieldEducation => 'Education';

  @override
  String get fieldOther => 'Other';

  @override
  String get cvLanguagePreference => 'Preferred CV language';

  @override
  String get cvLanguageTr => 'Turkish';

  @override
  String get cvLanguageEn => 'English';

  @override
  String get cvLanguageBoth => 'Both';

  @override
  String get personalizationReadyTitle => 'Your workspace is ready.';

  @override
  String get personalizationReadyBody =>
      'Start with your CV whenever you are ready. No scores until we analyze real content.';

  @override
  String get personalizationGoHome => 'Go to Home';

  @override
  String get navHome => 'Home';

  @override
  String get navAnalyze => 'Analyze';

  @override
  String get navJobs => 'Jobs';

  @override
  String get navBuilder => 'Builder';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String homeGreetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String homeGreetingAnonymous(String greeting) {
    return '$greeting';
  }

  @override
  String get homeStatusEmpty =>
      'Your workspace is ready. Upload a CV when you want a score.';

  @override
  String homeStatusScored(int score) {
    return 'Your CV readiness is $score/100. A few focused fixes can push it higher.';
  }

  @override
  String get homeCvCardTitle => 'Your CV';

  @override
  String get homeCvCardEmptyTitle => 'No CV yet';

  @override
  String get homeCvCardEmptyBody =>
      'Start with your CV to unlock analysis, job match, and builder tools.';

  @override
  String homeCvCardScoredTitle(String fileName) {
    return '$fileName';
  }

  @override
  String homeCvCardScoredBody(String date) {
    return 'Last analysis $date. Scores reflect your CV content, not a hiring guarantee.';
  }

  @override
  String get homeStartWithCv => 'Start with your CV';

  @override
  String get homeAnalyzeMyCv => 'Analyze My CV';

  @override
  String get homeViewAnalysis => 'View analysis';

  @override
  String get homeAnalyzeAgain => 'Analyze again';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeActionAnalyze => 'Analyze CV';

  @override
  String get homeActionMatch => 'Match a Job';

  @override
  String get homeActionBuild => 'Build CV';

  @override
  String get homeActionTranslate => 'Translate CV';

  @override
  String get homeRecentMatches => 'Recent job matches';

  @override
  String get homeRecentMatchesEmpty =>
      'No job matches yet. Paste a job description when you are ready.';

  @override
  String get homeCareerProgress => 'Career progress';

  @override
  String get homeCareerProgressEmpty =>
      'Progress appears after your first real analysis — we never invent scores.';

  @override
  String get homeCareerProgressScored =>
      'Baseline readiness recorded. Improve findings to see progress over time.';

  @override
  String get analyzeTitle => 'Analyze';

  @override
  String get analyzeEmptyTitle => 'Ready when your CV is';

  @override
  String get analyzeEmptyBody =>
      'Upload a PDF or DOCX. Careerly will score ATS readiness and surface clear fixes — never fabricated experience.';

  @override
  String get analyzeEmptyCta => 'Learn what we check';

  @override
  String get analyzeWhatWeCheck => 'What Careerly checks';

  @override
  String get analyzeCheckAts => 'ATS structure and parseability';

  @override
  String get analyzeCheckContent => 'Content clarity and impact';

  @override
  String get analyzeCheckSkills => 'Skills relevance and specificity';

  @override
  String get analyzeUploadTitle => 'Upload your CV';

  @override
  String get analyzeUploadBody =>
      'Choose a PDF or DOCX to see a structured readiness score and the highest-impact fixes.';

  @override
  String get analyzeSelectCv => 'Select CV';

  @override
  String get analyzeSupportedFormats => 'PDF or DOCX · max 10 MB';

  @override
  String get analyzeChangeFile => 'Change';

  @override
  String get analyzeRemoveFile => 'Remove';

  @override
  String get analyzeStartCta => 'Analyze my CV';

  @override
  String get analyzePrivacyNote =>
      'Your CV is analyzed on this device. Careerly does not invent experience, skills, or metrics.';

  @override
  String get analyzeScoreDisclaimer =>
      'This is Careerly\'s structured readiness score — not an acceptance probability or a universal ATS standard.';

  @override
  String get analyzePickFailed => 'Could not open the file picker. Try again.';

  @override
  String get analyzeErrorExtension => 'Please choose a PDF or DOCX file.';

  @override
  String get analyzeErrorTooLarge => 'This file is larger than 10 MB.';

  @override
  String get analyzeErrorEmpty => 'That file appears empty. Choose another CV.';

  @override
  String get analyzeErrorUnavailable =>
      'File is unavailable. Please select it again.';

  @override
  String get analyzeErrorCancelled => 'File selection was cancelled.';

  @override
  String get analyzeErrorGeneric => 'Analysis failed. Try again.';

  @override
  String get analyzeErrorUnreadable => 'We couldn\'t read text from this CV.';

  @override
  String get analyzeErrorScanned =>
      'Scanned CV detected. OCR support is not available in this build.';

  @override
  String get analyzeProcessingTitle => 'Analyzing';

  @override
  String get analyzeProcessingHeadline => 'Reading your CV carefully';

  @override
  String get analyzeProcessingHint =>
      'Scores come from Careerly\'s on-device rules. The same CV produces the same score.';

  @override
  String get analyzeStageReading => 'Reading structure';

  @override
  String get analyzeStageDetecting => 'Detecting sections';

  @override
  String get analyzeStageAts => 'Checking ATS';

  @override
  String get analyzeStageReviewing => 'Reviewing content';

  @override
  String get analyzeReviewTitle => 'Review sections';

  @override
  String get analyzeReviewHeadline => 'Confirm what we detected';

  @override
  String get analyzeReviewBody =>
      'Fix uncertain sections before scoring. Careerly will not invent missing experience.';

  @override
  String analyzeReviewConfidence(String level) {
    return 'Parser confidence: $level';
  }

  @override
  String get analyzeContinueToScore => 'Continue to score';

  @override
  String get sectionStatusDetected => 'Detected';

  @override
  String get sectionStatusMissing => 'Missing';

  @override
  String get sectionStatusNeedsReview => 'Needs review';

  @override
  String get sectionStatusLowConfidence => 'Low confidence';

  @override
  String get sectionStatusUserCorrected => 'Corrected';

  @override
  String get sectionChangeType => 'This section is…';

  @override
  String get sectionMarkDetected => 'Looks correct';

  @override
  String get sectionMarkMissing => 'Mark missing';

  @override
  String get parserConfidenceHigh => 'High';

  @override
  String get parserConfidenceMedium => 'Medium';

  @override
  String get parserConfidenceLow => 'Low';

  @override
  String get analyzeResultsTitle => 'CV analysis';

  @override
  String get analyzeNoResultsYet =>
      'Run an analysis to see your readiness score.';

  @override
  String get analyzeOverallScoreTitle => 'CV readiness score';

  @override
  String analyzeOverallScoreBody(String level) {
    return 'Confidence: $level. Scores explain readiness gaps you can fix — not hiring odds.';
  }

  @override
  String get analyzeTopImprovements => 'Top improvements';

  @override
  String get analyzeImproveMyCv => 'Improve my CV';

  @override
  String get analyzeBreakdown => 'Score breakdown';

  @override
  String get analyzeWhatsWorking => 'What’s working';

  @override
  String get analyzeAtsSection => 'ATS compatibility';

  @override
  String get analyzeAllFindings => 'All findings';

  @override
  String get analyzeDoneToHome => 'Back to Home';

  @override
  String get analyzeReturningTitle => 'Your latest analysis';

  @override
  String analyzeReturningBody(String fileName) {
    return 'Results for $fileName are ready. Review findings or analyze a new file.';
  }

  @override
  String analyzeLastScan(String date) {
    return 'Last scan $date';
  }

  @override
  String get analyzeViewResults => 'View results';

  @override
  String get analyzeAgain => 'Analyze a new CV';

  @override
  String get scoreOutOf100 => '/100';

  @override
  String scoreSemantic(int score) {
    return 'Careerly readiness score $score out of 100';
  }

  @override
  String get scoreCategoryAts => 'ATS compatibility';

  @override
  String get scoreCategoryContent => 'Content & impact';

  @override
  String get scoreCategoryExperience => 'Experience presentation';

  @override
  String get scoreCategorySkills => 'Skills presentation';

  @override
  String get scoreCategoryStructure => 'Structure & readability';

  @override
  String get scoreCategoryLanguage => 'Language & grammar';

  @override
  String get scoreCategoryBasics => 'Basics & contact';

  @override
  String get findingSeverityCritical => 'Critical';

  @override
  String get findingSeverityImprove => 'Improve';

  @override
  String get findingSeverityGood => 'Good';

  @override
  String get findingWhyMatters => 'Why it matters';

  @override
  String get findingEvidence => 'Detected evidence';

  @override
  String get findingAction => 'Recommended action';

  @override
  String get findingImproveWithAi => 'Improve with AI';

  @override
  String get findingImproveWithAiBody =>
      'AI rewrites will be available when the analysis service is connected. Suggestions will never invent employers, metrics, or skills you did not provide.';

  @override
  String get suggestionDemoTitle => 'Sample rewrite (demo)';

  @override
  String get suggestionBefore => 'Before';

  @override
  String get suggestionAfter => 'After';

  @override
  String get suggestionDemoNote =>
      'Demo only — Accept does not overwrite your CV in Phase 2.';

  @override
  String get suggestionAccept => 'Accept';

  @override
  String get suggestionEdit => 'Edit';

  @override
  String get suggestionReject => 'Reject';

  @override
  String get suggestionDecisionSaved =>
      'Preference noted. Your CV file was not changed.';

  @override
  String get jobsTitle => 'Jobs';

  @override
  String get jobsEmptyTitle => 'Match CV to a role';

  @override
  String get jobsEmptyBody =>
      'Compare your analyzed CV to a job description you paste. Skills are never invented.';

  @override
  String get jobsEmptyCta => 'New Job Match';

  @override
  String get jobsHowItWorksTitle => 'How Job Match works';

  @override
  String get jobsHowItWorks1 => 'Select an analyzed CV.';

  @override
  String get jobsHowItWorks2 =>
      'Paste the job title and description (URL is optional metadata).';

  @override
  String get jobsHowItWorks3 =>
      'See alignment score, skill evidence, and truthful Optimize CV suggestions.';

  @override
  String get jobsNewMatch => 'New Job Match';

  @override
  String get jobsSavedTitle => 'Saved matches';

  @override
  String get jobsSavedEmpty =>
      'No saved matches yet. Run a match and tap Save.';

  @override
  String get jobsNoCvTitle => 'Analyze a CV first';

  @override
  String get jobsNoCvBody =>
      'Job Match needs an analyzed CV so evidence stays truthful.';

  @override
  String get jobsNoCvCta => 'Analyze CV First';

  @override
  String get jobsSelectCvTitle => 'Select CV';

  @override
  String get jobsSelectCvSubtitle =>
      'Choose the analyzed CV to compare against the job.';

  @override
  String get jobsSelectCvContinue => 'Continue';

  @override
  String get jobsJobInfoTitle => 'Job details';

  @override
  String get jobsJobInfoSubtitle =>
      'Paste the posting. We never scrape websites — a URL is only for your notes.';

  @override
  String get jobsJobTitleLabel => 'Job title';

  @override
  String get jobsJobTitleHint => 'e.g. Software Engineering Intern';

  @override
  String get jobsCompanyLabel => 'Company (optional)';

  @override
  String get jobsCompanyHint => 'e.g. Campus Labs';

  @override
  String get jobsUrlLabel => 'Job URL (optional)';

  @override
  String get jobsUrlHint => 'Metadata only — not scraped';

  @override
  String get jobsDescriptionLabel => 'Job description';

  @override
  String get jobsDescriptionHint => 'Paste the full posting text here…';

  @override
  String get jobsDescriptionTooShort =>
      'Paste a fuller job description (at least a short paragraph).';

  @override
  String get jobsAnalyzeCta => 'Analyze match';

  @override
  String get jobsProcessingTitle => 'Matching your CV';

  @override
  String get jobsProcessingBody =>
      'Comparing evidence in your CV to this posting — no fake percentages.';

  @override
  String get jobsStageReadingJob => 'Reading the job description';

  @override
  String get jobsStageMatchingSkills => 'Matching skills & keywords';

  @override
  String get jobsStageScoring => 'Scoring alignment';

  @override
  String get jobsStageSuggestions => 'Drafting Optimize CV suggestions';

  @override
  String get jobsResultsTitle => 'Match results';

  @override
  String get jobsMatchScoreLabel => 'Match';

  @override
  String get jobsScoreDisclaimer =>
      'Alignment with this posting — not hiring probability.';

  @override
  String get jobsBreakdownTitle => 'Breakdown';

  @override
  String get jobsSkillsTitle => 'Skill evidence';

  @override
  String get jobsSkillsMatched => 'Matched';

  @override
  String get jobsSkillsPartial => 'Partial';

  @override
  String get jobsSkillsNotDemonstrated => 'Not demonstrated';

  @override
  String get jobsSkillsUnclear => 'Unclear';

  @override
  String get jobsKeywordsTitle => 'Keywords';

  @override
  String get jobsKeywordsCovered => 'Covered';

  @override
  String get jobsKeywordsMissing => 'Not in CV';

  @override
  String get jobsRecommendationsTitle => 'Optimize CV';

  @override
  String get jobsRecommendationsBody =>
      'Suggestions stay truthful. Accept records a preference — your file is not overwritten.';

  @override
  String get jobsVerificationTitle => 'Verification questions';

  @override
  String get jobsLearningTitle => 'Learning opportunities';

  @override
  String get jobsWorkingWellTitle => 'What\'s working';

  @override
  String get jobsSaveMatch => 'Save match';

  @override
  String get jobsSavedSnack => 'Match saved to Jobs.';

  @override
  String get jobsCategoryCoreSkills => 'Core skills';

  @override
  String get jobsCategoryExperience => 'Experience / projects';

  @override
  String get jobsCategoryResponsibilities => 'Responsibilities';

  @override
  String get jobsCategoryEducation => 'Education';

  @override
  String get jobsCategoryTools => 'Tools';

  @override
  String get jobsCategoryLanguage => 'Language / other';

  @override
  String get jobsErrorGeneric => 'Job Match could not finish. Try again.';

  @override
  String jobsRecentMatchScore(int score) {
    return '$score% match';
  }

  @override
  String jobsRecentMatchMeta(String role, String company) {
    return '$role · $company';
  }

  @override
  String get homeRecentMatchesCta => 'View matches';

  @override
  String get builderTitle => 'Builder';

  @override
  String get builderEmptyTitle => 'No CVs yet';

  @override
  String get builderEmptyBody =>
      'Create a structured CV, pick an ATS-safe template, and export a searchable PDF. Content stays the same when you switch templates.';

  @override
  String get builderEmptyCta => 'Create new CV';

  @override
  String get builderHomeHeadline => 'Professional CV Builder';

  @override
  String get builderHomeBody =>
      'Choose a template, tell your story, and create a CV that is ready to share.';

  @override
  String get builderCreateNew => 'Create new';

  @override
  String get builderUseExisting => 'Use existing';

  @override
  String get builderFromAnalyzed => 'Create from analyzed CV';

  @override
  String get builderFromAnalyzedHint =>
      'Analyze a CV first to unlock this start point.';

  @override
  String get builderPickExistingHint => 'Open a CV from Your CVs below.';

  @override
  String get builderYourCvs => 'Your CVs';

  @override
  String get builderQuickSetup => 'Quick setup';

  @override
  String get builderCvLanguage => 'CV language (independent of app language)';

  @override
  String get builderLangEn => 'English';

  @override
  String get builderLangTr => 'Turkish';

  @override
  String get builderTemplate => 'Template';

  @override
  String get builderTemplateClassic => 'Classic ATS';

  @override
  String get builderTemplateModern => 'Modern ATS';

  @override
  String get builderTemplateStudent => 'Student';

  @override
  String get builderTemplateTech => 'Tech';

  @override
  String get builderStartEditing => 'Start editing';

  @override
  String get builderRename => 'Rename';

  @override
  String get builderDuplicate => 'Duplicate';

  @override
  String get builderDelete => 'Delete';

  @override
  String get builderDeleteConfirmTitle => 'Delete this CV?';

  @override
  String get builderDeleteConfirmBody =>
      'This removes the local draft. It cannot be undone.';

  @override
  String get builderCancel => 'Cancel';

  @override
  String get builderSave => 'Save';

  @override
  String get builderSaving => 'Saving…';

  @override
  String get builderSaved => 'Saved';

  @override
  String get builderSaveError => 'Save failed';

  @override
  String get builderExportPdf => 'Export PDF';

  @override
  String get builderExportError => 'PDF export failed. Try again.';

  @override
  String get builderChangeTemplate => 'Change template';

  @override
  String get builderTranslate => 'Translate (new version)';

  @override
  String get builderTranslateDone => 'Translated version created.';

  @override
  String get builderCheckCv => 'Check CV';

  @override
  String get builderCheckResultTitle => 'Structured CV check';

  @override
  String builderCheckResultBody(int score) {
    return 'Overall score $score. Same ATS/scoring engines — no re-upload.';
  }

  @override
  String get builderOpenAnalysis => 'Open full analysis';

  @override
  String get builderTailorJob => 'Tailor to job';

  @override
  String get builderCloseEditor => 'Close editor';

  @override
  String get builderEditTab => 'Edit';

  @override
  String get builderPreviewTab => 'Preview';

  @override
  String get builderPreviewFallback =>
      'PDF preview unavailable — showing structured layout (same content).';

  @override
  String get builderMoreActions => 'More actions';

  @override
  String get builderZoomIn => 'Zoom in';

  @override
  String get builderZoomOut => 'Zoom out';

  @override
  String get builderAddCustomSection => 'Add custom section';

  @override
  String get builderCustomTitle => 'Custom section title';

  @override
  String get builderBulletsHint => 'Bullets (one per line)';

  @override
  String get builderSectionPersonal => 'Personal details';

  @override
  String get builderSectionSummary => 'Summary';

  @override
  String get builderSectionEducation => 'Education';

  @override
  String get builderSectionExperience => 'Experience';

  @override
  String get builderSectionProjects => 'Projects';

  @override
  String get builderSectionSkills => 'Skills';

  @override
  String get builderSectionLanguages => 'Languages';

  @override
  String get builderSectionCerts => 'Certifications';

  @override
  String get builderSectionAwards => 'Awards / Activities';

  @override
  String get builderHideSection => 'Hide section';

  @override
  String get builderShowSection => 'Show section';

  @override
  String get builderSectionHidden => 'Hidden from preview and PDF.';

  @override
  String get builderMoveUp => 'Move up';

  @override
  String get builderMoveDown => 'Move down';

  @override
  String get builderCompletionEmpty => 'Empty';

  @override
  String get builderCompletionPartial => 'Partial';

  @override
  String get builderCompletionComplete => 'Complete';

  @override
  String get builderFieldFullName => 'Full name';

  @override
  String get builderFieldEmail => 'Email';

  @override
  String get builderFieldPhone => 'Phone';

  @override
  String get builderFieldLocation => 'Location';

  @override
  String get builderFieldLinkedin => 'LinkedIn';

  @override
  String get builderFieldWebsite => 'Website';

  @override
  String get builderFieldSchool => 'School';

  @override
  String get builderFieldDegree => 'Degree';

  @override
  String get builderFieldTitle => 'Title';

  @override
  String get builderFieldOrganization => 'Organization';

  @override
  String get builderFieldProjectName => 'Project name';

  @override
  String get builderFieldTech => 'Tech (comma-separated)';

  @override
  String get builderFieldSkillGroup => 'Skill group label';

  @override
  String get builderFieldSkillsCsv => 'Skills (comma-separated, no star bars)';

  @override
  String get builderFieldLanguage => 'Language';

  @override
  String get builderFieldLevel => 'Level';

  @override
  String get builderFieldCertName => 'Certification';

  @override
  String get builderFieldIssuer => 'Issuer';

  @override
  String get builderFieldAward => 'Award / activity';

  @override
  String get builderAddEducation => 'Add education';

  @override
  String get builderAddExperience => 'Add experience';

  @override
  String get builderAddProject => 'Add project';

  @override
  String get builderAddSkillGroup => 'Add skill group';

  @override
  String get builderAddLanguage => 'Add language';

  @override
  String get builderAddCert => 'Add certification';

  @override
  String get builderAddAward => 'Add award';

  @override
  String get builderAiImprove => 'AI improve';

  @override
  String get builderAiModeImprove => 'Improve';

  @override
  String get builderAiModeConcise => 'Concise';

  @override
  String get builderAiModeProfessional => 'Professional';

  @override
  String get builderAiOriginal => 'Original';

  @override
  String get builderAiSuggested => 'Suggested';

  @override
  String get builderAiWhy => 'Why';

  @override
  String get builderAiNeedsFact =>
      'We need a real fact from you — nothing was invented.';

  @override
  String get builderAiAccept => 'Accept';

  @override
  String get builderAiTryAgain => 'Try again';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileMockUser => 'Demo user';

  @override
  String get profileLanguage => 'App language';

  @override
  String get profilePreferences => 'Preferences';

  @override
  String get profileCareerStage => 'Career stage';

  @override
  String get profileGoal => 'Looking for';

  @override
  String get profileFields => 'Fields';

  @override
  String get profileCvLanguage => 'CV language';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profilePrivacy => 'Privacy & data';

  @override
  String get profilePrivacyBody =>
      'CVs are personal data. Use Delete account data to wipe all local Careerly data on this device. Server-side deletion requires a configured backend account (see EXTERNAL_ACTIONS.md).';

  @override
  String get profileResetDemo => 'Reset demo onboarding';

  @override
  String get profileResetDemoConfirm =>
      'Clear local progress and return to language selection?';

  @override
  String get profileResetDemoAction => 'Reset';

  @override
  String get profileDeleteAccount => 'Delete account data';

  @override
  String get profileDeleteAccountConfirm =>
      'Permanently wipe all Careerly data stored on this device (CVs, analysis, matches, billing cache)? This cannot be undone.';

  @override
  String get profileDeleteAccountAction => 'Delete';

  @override
  String profileVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profileSubscription => 'Subscription';

  @override
  String get profileSubscriptionSoon =>
      'Plans unlock after core analysis value — not before.';

  @override
  String get billingPlanFree => 'Free';

  @override
  String get billingPlanPro => 'Pro';

  @override
  String get billingStatusFree => 'Free plan';

  @override
  String get billingStatusActive => 'Active';

  @override
  String get billingStatusExpired => 'Expired';

  @override
  String get billingStatusBillingIssue => 'Billing issue';

  @override
  String get billingPlanBody =>
      'Your own CV data stays readable if Pro expires. Creation and premium tools follow your plan.';

  @override
  String get billingUpgradeCta => 'Upgrade to Pro';

  @override
  String get billingManageSubscription => 'Manage subscription';

  @override
  String get billingManageBody =>
      'Cancel or change plans in the App Store or Google Play for your account. Careerly never fakes a cancel button.';

  @override
  String get billingDevOverride => 'Dev plan override (debug only)';

  @override
  String get billingDevClear => 'Clear';

  @override
  String get billingLimitTitle => 'Plan limit reached';

  @override
  String get billingLimitBody =>
      'You\'ve used this Free allowance. Upgrade for more — your saved CV data stays available to read.';

  @override
  String get billingNearLimitTitle => 'Almost at your Free limit';

  @override
  String billingNearLimitBody(int remaining, int limit) {
    return '$remaining of $limit remaining this period.';
  }

  @override
  String get paywallTitle => 'Careerly Pro';

  @override
  String get paywallHeadline => 'Build every application\nwith more clarity.';

  @override
  String get paywallBody =>
      'You\'ve already seen Careerly\'s core value. Pro unlocks more analyses, job matches, AI rewrites, templates, and translation — without locking the CV you already entered.';

  @override
  String get paywallValue1 => 'More CV analyses each month';

  @override
  String get paywallValue2 => 'Extra Job Matches against pasted roles';

  @override
  String get paywallValue3 => 'Additional truthful AI rewrite assists';

  @override
  String get paywallValue4 => 'Premium templates and bilingual export';

  @override
  String get paywallChoosePlan => 'Choose a plan';

  @override
  String get paywallMonthly => 'Monthly';

  @override
  String get paywallYearly => 'Yearly';

  @override
  String get paywallPriceNote =>
      'Prices come from the App Store / Google Play. Demo labels appear only in debug builds.';

  @override
  String get paywallCta => 'Continue with Pro';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallRestoreSuccess => 'Purchases restored.';

  @override
  String get paywallRestoreEmpty => 'Nothing to restore on this account.';

  @override
  String get paywallSuccess => 'Pro is active. Thank you.';

  @override
  String get paywallError => 'Purchase could not finish. Try again or restore.';

  @override
  String get paywallLegal =>
      'Terms of Use and Privacy Policy placeholders. Subscription renews unless cancelled in the store.';

  @override
  String get emptyGenericTitle => 'Nothing here yet';

  @override
  String get emptyGenericBody =>
      'Content will appear when this feature is available.';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericBody =>
      'Please try again. If the problem continues, restart the app.';

  @override
  String get loadingGeneric => 'Loading…';

  @override
  String get offlineHint =>
      'You appear to be offline. Some features need a connection later.';

  @override
  String get semanticScoreBadge => 'Score badge placeholder';

  @override
  String get close => 'Close';

  @override
  String homeReadyNamed(String name) {
    return 'Ready for\nyour next move,\n$name?';
  }

  @override
  String get homeReadyPlain => 'Ready for\nyour next move?';

  @override
  String get profileFirstName => 'First name';

  @override
  String get profileUsageAnalyses => 'CV analyses';

  @override
  String get profileUsageMatches => 'Job matches';

  @override
  String profileUsageMeter(int used, int limit) {
    return '$used / $limit used';
  }

  @override
  String get jobsDelete => 'Delete';

  @override
  String get productCvQuality => 'CV Quality';

  @override
  String get productAtsReadability => 'ATS Readability';

  @override
  String get productJobMatch => 'Job Match';

  @override
  String get productJobMatchLocked => 'Add a target job to unlock';

  @override
  String get productScoreDisclaimer =>
      'Careerly analysis of CV structure, content, and job requirements. Not an employer\'s ATS score.';

  @override
  String get productBiggestOpportunities => 'Biggest opportunities';

  @override
  String get productBandNeedsWork => 'Needs work';

  @override
  String get productBandDeveloping => 'Developing';

  @override
  String get productBandStrong => 'Strong';

  @override
  String get productBandExcellent => 'Excellent';

  @override
  String get productQualityImpact => 'Impact and achievements';

  @override
  String get productQualityExperience => 'Experience quality';

  @override
  String get productQualitySkills => 'Skills and tools';

  @override
  String get productQualityStructure => 'Structure and completeness';

  @override
  String get productQualityWriting => 'Writing quality';

  @override
  String get productQualityConcise => 'Conciseness';

  @override
  String get optimizeTitle => 'Improve your CV';

  @override
  String get optimizeIntro =>
      'Careerly checked each experience and project line. Nothing changes until you accept it, and scores update only after Careerly re-checks the edited CV.';

  @override
  String get optimizeEmpty =>
      'No line-level fixes found. Your experience and project lines pass Careerly\'s checks.';

  @override
  String get optimizeNoCv => 'Analyze a CV first to see suggestions.';

  @override
  String get optimizeImpactHigh => 'HIGH IMPACT';

  @override
  String get optimizeImpactMedium => 'MEDIUM IMPACT';

  @override
  String get optimizeImpactLow => 'SMALL FIX';

  @override
  String get optimizeKindWeakOpening => 'Lead with what you did';

  @override
  String get optimizeKindFirstPerson => 'Drop the first person';

  @override
  String get optimizeKindTooLong => 'Shorten this line';

  @override
  String get optimizeKindNoMetric => 'Add a real result';

  @override
  String get optimizeKindFormatting => 'Clean up wording';

  @override
  String get optimizeWhyWeakOpening =>
      'Phrases like \"responsible for\" describe duties, not contribution. An action verb makes your part clear.';

  @override
  String get optimizeWhyFirstPerson =>
      'CV lines usually start with the action. Removing \"I\" keeps them tight.';

  @override
  String get optimizeWhyTooLong =>
      'Long lines are skimmed. One idea per line is easier to read.';

  @override
  String get optimizeWhyNoMetric =>
      'A number you can verify (people, items, time saved) makes impact concrete.';

  @override
  String get optimizeWhyFormatting =>
      'Small spacing and wording fixes. Meaning stays the same.';

  @override
  String get optimizeQuestionOutcome =>
      'What did you deliver or change here? Write it in your own words — Careerly won\'t invent it.';

  @override
  String get optimizeQuestionMetric =>
      'Do you know roughly how many people, posts, items, or hours this involved? Only add numbers you can stand behind.';

  @override
  String get optimizeOriginal => 'Current';

  @override
  String get optimizeSuggested => 'Careerly suggestion';

  @override
  String get optimizeYourVersion => 'Your version';

  @override
  String get optimizeAccept => 'Accept';

  @override
  String get optimizeEdit => 'Edit';

  @override
  String get optimizeSkip => 'Skip';

  @override
  String get optimizeUndo => 'Undo';

  @override
  String get optimizeSave => 'Save';

  @override
  String get optimizeEditHint => 'Use only facts that are true.';

  @override
  String get optimizeStatusAccepted => 'Accepted';

  @override
  String get optimizeStatusEdited => 'Edited';

  @override
  String get optimizeStatusSkipped => 'Skipped';

  @override
  String get optimizeRewrite => 'Rewrite with AI';

  @override
  String get optimizeModeImpact => 'Stronger impact';

  @override
  String get optimizeModeConcise => 'More concise';

  @override
  String get optimizeModeProfessional => 'More professional';

  @override
  String get optimizeModeJobTargeted => 'Job targeted';

  @override
  String get optimizeModeGrammar => 'Grammar only';

  @override
  String optimizeApply(int count) {
    return 'Apply $count changes and re-score';
  }

  @override
  String get optimizeAiUnavailable =>
      'AI rewrites are temporarily unavailable. Your analysis and rule-based suggestions still work.';

  @override
  String get optimizeAiKeptOriginal =>
      'The AI rewrite added details that aren\'t in your CV, so Careerly kept your line.';

  @override
  String get optimizeAiFailed => 'The rewrite didn\'t complete. Try again.';

  @override
  String get optimizeRescoreFailed =>
      'Couldn\'t re-score the edited CV. Your previous analysis is unchanged.';

  @override
  String get optimizeResultTitle => 'Re-checked by Careerly';

  @override
  String get optimizeResultUnchanged =>
      'Scores didn\'t move. Your edits are saved, but they didn\'t change what the checks measure.';

  @override
  String get optimizeVersions => 'CV versions';

  @override
  String get optimizeVersionOriginal => 'Original';

  @override
  String get optimizeVersionOptimized => 'Optimized';

  @override
  String get optimizeRestore => 'Restore';

  @override
  String get optimizeJobMatchRerun =>
      'Run the job match again to see your updated match.';

  @override
  String get optimizeOpenInBuilder => 'Open in Builder';

  @override
  String get optimizeBuilderNote =>
      'Builder exports a searchable PDF in a Careerly template. Your original file\'s layout isn\'t copied.';

  @override
  String get appsTitle => 'Applications';

  @override
  String get appsIntro =>
      'Keep track of where you applied and which CV you sent.';

  @override
  String get appsEmpty =>
      'No applications yet. Add one from a job match or start here.';

  @override
  String get appsAdd => 'Add application';

  @override
  String get appsAddFromMatch => 'Add to applications';

  @override
  String get appsAlreadyTracked => 'Already in your applications';

  @override
  String get appsAdded => 'Added to applications';

  @override
  String get appsAll => 'All';

  @override
  String get appsStatusSaved => 'Saved';

  @override
  String get appsStatusPreparing => 'Preparing';

  @override
  String get appsStatusApplied => 'Applied';

  @override
  String get appsStatusInterview => 'Interview';

  @override
  String get appsStatusOffer => 'Offer';

  @override
  String get appsStatusRejected => 'Rejected';

  @override
  String get appsFieldRole => 'Role title';

  @override
  String get appsFieldCompany => 'Company';

  @override
  String get appsFieldStatus => 'Status';

  @override
  String get appsFieldCv => 'CV version sent';

  @override
  String get appsFieldCvCurrent => 'Current CV';

  @override
  String get appsFieldNotes => 'Notes';

  @override
  String get appsFieldNext => 'Next action';

  @override
  String get appsSave => 'Save';

  @override
  String get appsDelete => 'Delete application';

  @override
  String appsMatch(int score) {
    return '$score% match';
  }

  @override
  String appsAppliedOn(String date) {
    return 'Applied $date';
  }

  @override
  String get appsOpen => 'View applications';

  @override
  String homeOverviewLabel(String day) {
    return '$day · Career overview';
  }

  @override
  String homeImproveCta(int count) {
    return 'Improve my CV · $count fixes';
  }

  @override
  String get homeImproveCtaNone => 'Improve my CV';

  @override
  String get homeJobMatchAdd => 'Add a job';

  @override
  String get homeStepsTitle => 'Your next steps';

  @override
  String get homeStepAnalyze => 'Analyze your CV';

  @override
  String get homeStepAnalyzeHint => 'Upload a PDF or DOCX to get your scores.';

  @override
  String homeStepAnalyzeDone(int score) {
    return 'CV quality $score/100';
  }

  @override
  String get homeStepImprove => 'Fix weak lines';

  @override
  String get homeStepImproveHint => 'Available after your first analysis.';

  @override
  String homeStepImprovePending(int count) {
    return '$count line fixes waiting for your review';
  }

  @override
  String get homeStepImproveDone => 'Optimized version saved';

  @override
  String get homeStepImproveNone => 'No line fixes needed right now';

  @override
  String get homeStepMatch => 'Match a job posting';

  @override
  String get homeStepMatchHint => 'Paste a job description to see your gaps.';

  @override
  String homeStepMatchDone(int score, String title) {
    return '$score% match · $title';
  }

  @override
  String get homeStepTrack => 'Track your applications';

  @override
  String get homeStepTrackHint =>
      'Keep status, CV version and next step in one place.';

  @override
  String homeStepTrackDone(int count) {
    return '$count applications tracked';
  }

  @override
  String get homeAppsActive => 'Active';

  @override
  String get homeNoMatchesHeadline => 'Your next application starts here.';

  @override
  String get homeToolsTitle => 'Tools';

  @override
  String get labelNoMatches => 'No matches yet';

  @override
  String get labelNoMatch => 'No match';

  @override
  String get labelNoResults => 'No results';

  @override
  String get labelNoDocuments => 'No documents';

  @override
  String get labelSections => 'Sections';

  @override
  String get labelEvidence => 'Evidence';

  @override
  String get labelWhatsWorking => 'What\'s working';

  @override
  String get labelWhyStronger => 'Why it\'s stronger';

  @override
  String get labelTopPriority => '01 — Top priority';

  @override
  String get labelBiggestGap => '01 — Biggest gap';

  @override
  String get improveThis => 'Improve this →';

  @override
  String get jobsHeaderLabel => 'Job match';

  @override
  String get jobsHeaderHeadline => 'See what the\nrole is asking for.';

  @override
  String get analyzeHeaderLabel => 'CV analysis';

  @override
  String get analyzeHeaderHeadline => 'Let\'s see what\nyour CV says.';

  @override
  String get builderHeaderLabel => 'My CVs';

  @override
  String get builderHeaderHeadline => 'Design your next CV.';

  @override
  String get profileHeaderLabel => 'Profile';

  @override
  String get alignmentStrong => 'Strong alignment';

  @override
  String get alignmentGood => 'Good alignment';

  @override
  String get alignmentPartial => 'Partial alignment';

  @override
  String get alignmentWeak => 'Weak alignment';

  @override
  String get onboardingKicker1 => 'Know';

  @override
  String get onboardingHeadline1 => 'Your CV,\ndecoded.';

  @override
  String get onboardingKicker2 => 'Match';

  @override
  String get onboardingHeadline2 => 'See what the\nrole is asking for.';

  @override
  String get onboardingKicker3 => 'Build';

  @override
  String get onboardingHeadline3 => 'Turn insight\ninto a stronger CV.';
}
