import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Working product name
  ///
  /// In en, this message translates to:
  /// **'Careerly AI'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Clarity for every application.'**
  String get tagline;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later release'**
  String get comingSoon;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Profile.'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Know how your CV performs.'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'See a clear readiness score and the exact fixes that move you forward.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Match every application.'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Compare your CV to a real job description and close the gaps that matter.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Built for ATS. Written for people.'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Stay parser-safe while sounding confident, specific, and human.'**
  String get onboardingBody3;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Careerly'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to save your progress. Mock sign-in is for Phase 1 only.'**
  String get authWelcomeSubtitle;

  /// No description provided for @authMockBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo auth — not production'**
  String get authMockBanner;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordHint;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authOrEmail.
  ///
  /// In en, this message translates to:
  /// **'or continue with email'**
  String get authOrEmail;

  /// No description provided for @authSwitchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authSwitchToSignIn;

  /// No description provided for @authSwitchToSignUp.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authSwitchToSignUp;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authEmailRequired;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authPasswordRequired;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGenericError;

  /// No description provided for @authSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in.'**
  String get authSuccess;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @personalizationProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String personalizationProgress(int current, int total);

  /// No description provided for @personalizationStep1Title.
  ///
  /// In en, this message translates to:
  /// **'What best describes you?'**
  String get personalizationStep1Title;

  /// No description provided for @personalizationStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tailor guidance to your stage.'**
  String get personalizationStep1Subtitle;

  /// No description provided for @careerStageStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get careerStageStudent;

  /// No description provided for @careerStageIntern.
  ///
  /// In en, this message translates to:
  /// **'Intern'**
  String get careerStageIntern;

  /// No description provided for @careerStageNewGraduate.
  ///
  /// In en, this message translates to:
  /// **'New Graduate'**
  String get careerStageNewGraduate;

  /// No description provided for @careerStageProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get careerStageProfessional;

  /// No description provided for @careerStageCareerChanger.
  ///
  /// In en, this message translates to:
  /// **'Career Changer'**
  String get careerStageCareerChanger;

  /// No description provided for @personalizationStep2Title.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get personalizationStep2Title;

  /// No description provided for @personalizationStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the opportunity type that fits right now.'**
  String get personalizationStep2Subtitle;

  /// No description provided for @goalInternship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get goalInternship;

  /// No description provided for @goalPartTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get goalPartTime;

  /// No description provided for @goalFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get goalFullTime;

  /// No description provided for @goalGraduateProgram.
  ///
  /// In en, this message translates to:
  /// **'Graduate Program'**
  String get goalGraduateProgram;

  /// No description provided for @goalNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet'**
  String get goalNotSure;

  /// No description provided for @personalizationStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Fields & CV language'**
  String get personalizationStep3Title;

  /// No description provided for @personalizationStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Select areas of interest and how you write your CV.'**
  String get personalizationStep3Subtitle;

  /// No description provided for @fieldSoftware.
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get fieldSoftware;

  /// No description provided for @fieldData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get fieldData;

  /// No description provided for @fieldFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get fieldFinance;

  /// No description provided for @fieldMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get fieldMarketing;

  /// No description provided for @fieldProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get fieldProduct;

  /// No description provided for @fieldDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get fieldDesign;

  /// No description provided for @fieldEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get fieldEngineering;

  /// No description provided for @fieldHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get fieldHealthcare;

  /// No description provided for @fieldEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get fieldEducation;

  /// No description provided for @fieldOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get fieldOther;

  /// No description provided for @cvLanguagePreference.
  ///
  /// In en, this message translates to:
  /// **'Preferred CV language'**
  String get cvLanguagePreference;

  /// No description provided for @cvLanguageTr.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get cvLanguageTr;

  /// No description provided for @cvLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get cvLanguageEn;

  /// No description provided for @cvLanguageBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get cvLanguageBoth;

  /// No description provided for @personalizationReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your workspace is ready.'**
  String get personalizationReadyTitle;

  /// No description provided for @personalizationReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Start with your CV whenever you are ready. No scores until we analyze real content.'**
  String get personalizationReadyBody;

  /// No description provided for @personalizationGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get personalizationGoHome;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get navAnalyze;

  /// No description provided for @navJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get navJobs;

  /// No description provided for @navBuilder.
  ///
  /// In en, this message translates to:
  /// **'Builder'**
  String get navBuilder;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingNamed.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String homeGreetingNamed(String greeting, String name);

  /// No description provided for @homeGreetingAnonymous.
  ///
  /// In en, this message translates to:
  /// **'{greeting}'**
  String homeGreetingAnonymous(String greeting);

  /// No description provided for @homeStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your workspace is ready. Upload a CV when you want a score.'**
  String get homeStatusEmpty;

  /// No description provided for @homeStatusScored.
  ///
  /// In en, this message translates to:
  /// **'Your CV readiness is {score}/100. A few focused fixes can push it higher.'**
  String homeStatusScored(int score);

  /// No description provided for @homeCvCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your CV'**
  String get homeCvCardTitle;

  /// No description provided for @homeCvCardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No CV yet'**
  String get homeCvCardEmptyTitle;

  /// No description provided for @homeCvCardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start with your CV to unlock analysis, job match, and builder tools.'**
  String get homeCvCardEmptyBody;

  /// No description provided for @homeCvCardScoredTitle.
  ///
  /// In en, this message translates to:
  /// **'{fileName}'**
  String homeCvCardScoredTitle(String fileName);

  /// No description provided for @homeCvCardScoredBody.
  ///
  /// In en, this message translates to:
  /// **'Last analysis {date}. Scores reflect your CV content, not a hiring guarantee.'**
  String homeCvCardScoredBody(String date);

  /// No description provided for @homeStartWithCv.
  ///
  /// In en, this message translates to:
  /// **'Start with your CV'**
  String get homeStartWithCv;

  /// No description provided for @homeAnalyzeMyCv.
  ///
  /// In en, this message translates to:
  /// **'Analyze My CV'**
  String get homeAnalyzeMyCv;

  /// No description provided for @homeViewAnalysis.
  ///
  /// In en, this message translates to:
  /// **'View analysis'**
  String get homeViewAnalysis;

  /// No description provided for @homeAnalyzeAgain.
  ///
  /// In en, this message translates to:
  /// **'Analyze again'**
  String get homeAnalyzeAgain;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @homeActionAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze CV'**
  String get homeActionAnalyze;

  /// No description provided for @homeActionMatch.
  ///
  /// In en, this message translates to:
  /// **'Match a Job'**
  String get homeActionMatch;

  /// No description provided for @homeActionBuild.
  ///
  /// In en, this message translates to:
  /// **'Build CV'**
  String get homeActionBuild;

  /// No description provided for @homeActionTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate CV'**
  String get homeActionTranslate;

  /// No description provided for @homeRecentMatches.
  ///
  /// In en, this message translates to:
  /// **'Recent job matches'**
  String get homeRecentMatches;

  /// No description provided for @homeRecentMatchesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No job matches yet. Paste a job description when you are ready.'**
  String get homeRecentMatchesEmpty;

  /// No description provided for @homeCareerProgress.
  ///
  /// In en, this message translates to:
  /// **'Career progress'**
  String get homeCareerProgress;

  /// No description provided for @homeCareerProgressEmpty.
  ///
  /// In en, this message translates to:
  /// **'Progress appears after your first real analysis — we never invent scores.'**
  String get homeCareerProgressEmpty;

  /// No description provided for @homeCareerProgressScored.
  ///
  /// In en, this message translates to:
  /// **'Baseline readiness recorded. Improve findings to see progress over time.'**
  String get homeCareerProgressScored;

  /// No description provided for @analyzeTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyzeTitle;

  /// No description provided for @analyzeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready when your CV is'**
  String get analyzeEmptyTitle;

  /// No description provided for @analyzeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Upload a PDF or DOCX. Careerly will score ATS readiness and surface clear fixes — never fabricated experience.'**
  String get analyzeEmptyBody;

  /// No description provided for @analyzeEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Learn what we check'**
  String get analyzeEmptyCta;

  /// No description provided for @analyzeWhatWeCheck.
  ///
  /// In en, this message translates to:
  /// **'What Careerly checks'**
  String get analyzeWhatWeCheck;

  /// No description provided for @analyzeCheckAts.
  ///
  /// In en, this message translates to:
  /// **'ATS structure and parseability'**
  String get analyzeCheckAts;

  /// No description provided for @analyzeCheckContent.
  ///
  /// In en, this message translates to:
  /// **'Content clarity and impact'**
  String get analyzeCheckContent;

  /// No description provided for @analyzeCheckSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills relevance and specificity'**
  String get analyzeCheckSkills;

  /// No description provided for @analyzeUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your CV'**
  String get analyzeUploadTitle;

  /// No description provided for @analyzeUploadBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF or DOCX to see a structured readiness score and the highest-impact fixes.'**
  String get analyzeUploadBody;

  /// No description provided for @analyzeSelectCv.
  ///
  /// In en, this message translates to:
  /// **'Select CV'**
  String get analyzeSelectCv;

  /// No description provided for @analyzeSupportedFormats.
  ///
  /// In en, this message translates to:
  /// **'PDF or DOCX · max 10 MB'**
  String get analyzeSupportedFormats;

  /// No description provided for @analyzeChangeFile.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get analyzeChangeFile;

  /// No description provided for @analyzeRemoveFile.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get analyzeRemoveFile;

  /// No description provided for @analyzeStartCta.
  ///
  /// In en, this message translates to:
  /// **'Analyze my CV'**
  String get analyzeStartCta;

  /// No description provided for @analyzePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your CV is analyzed on this device. Careerly does not invent experience, skills, or metrics.'**
  String get analyzePrivacyNote;

  /// No description provided for @analyzeScoreDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is Careerly\'s structured readiness score — not an acceptance probability or a universal ATS standard.'**
  String get analyzeScoreDisclaimer;

  /// No description provided for @analyzePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file picker. Try again.'**
  String get analyzePickFailed;

  /// No description provided for @analyzeErrorExtension.
  ///
  /// In en, this message translates to:
  /// **'Please choose a PDF or DOCX file.'**
  String get analyzeErrorExtension;

  /// No description provided for @analyzeErrorTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is larger than 10 MB.'**
  String get analyzeErrorTooLarge;

  /// No description provided for @analyzeErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'That file appears empty. Choose another CV.'**
  String get analyzeErrorEmpty;

  /// No description provided for @analyzeErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'File is unavailable. Please select it again.'**
  String get analyzeErrorUnavailable;

  /// No description provided for @analyzeErrorCancelled.
  ///
  /// In en, this message translates to:
  /// **'File selection was cancelled.'**
  String get analyzeErrorCancelled;

  /// No description provided for @analyzeErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed. Try again.'**
  String get analyzeErrorGeneric;

  /// No description provided for @analyzeErrorUnreadable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read text from this CV.'**
  String get analyzeErrorUnreadable;

  /// No description provided for @analyzeErrorScanned.
  ///
  /// In en, this message translates to:
  /// **'Scanned CV detected. OCR support is not available in this build.'**
  String get analyzeErrorScanned;

  /// No description provided for @analyzeProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing'**
  String get analyzeProcessingTitle;

  /// No description provided for @analyzeProcessingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Reading your CV carefully'**
  String get analyzeProcessingHeadline;

  /// No description provided for @analyzeProcessingHint.
  ///
  /// In en, this message translates to:
  /// **'Scores come from Careerly\'s on-device rules. The same CV produces the same score.'**
  String get analyzeProcessingHint;

  /// No description provided for @analyzeStageReading.
  ///
  /// In en, this message translates to:
  /// **'Reading structure'**
  String get analyzeStageReading;

  /// No description provided for @analyzeStageDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting sections'**
  String get analyzeStageDetecting;

  /// No description provided for @analyzeStageAts.
  ///
  /// In en, this message translates to:
  /// **'Checking ATS'**
  String get analyzeStageAts;

  /// No description provided for @analyzeStageReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing content'**
  String get analyzeStageReviewing;

  /// No description provided for @analyzeReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review sections'**
  String get analyzeReviewTitle;

  /// No description provided for @analyzeReviewHeadline.
  ///
  /// In en, this message translates to:
  /// **'Confirm what we detected'**
  String get analyzeReviewHeadline;

  /// No description provided for @analyzeReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Fix uncertain sections before scoring. Careerly will not invent missing experience.'**
  String get analyzeReviewBody;

  /// No description provided for @analyzeReviewConfidence.
  ///
  /// In en, this message translates to:
  /// **'Parser confidence: {level}'**
  String analyzeReviewConfidence(String level);

  /// No description provided for @analyzeContinueToScore.
  ///
  /// In en, this message translates to:
  /// **'Continue to score'**
  String get analyzeContinueToScore;

  /// No description provided for @sectionStatusDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get sectionStatusDetected;

  /// No description provided for @sectionStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get sectionStatusMissing;

  /// No description provided for @sectionStatusNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get sectionStatusNeedsReview;

  /// No description provided for @sectionStatusLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get sectionStatusLowConfidence;

  /// No description provided for @sectionStatusUserCorrected.
  ///
  /// In en, this message translates to:
  /// **'Corrected'**
  String get sectionStatusUserCorrected;

  /// No description provided for @sectionChangeType.
  ///
  /// In en, this message translates to:
  /// **'This section is…'**
  String get sectionChangeType;

  /// No description provided for @sectionMarkDetected.
  ///
  /// In en, this message translates to:
  /// **'Looks correct'**
  String get sectionMarkDetected;

  /// No description provided for @sectionMarkMissing.
  ///
  /// In en, this message translates to:
  /// **'Mark missing'**
  String get sectionMarkMissing;

  /// No description provided for @parserConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get parserConfidenceHigh;

  /// No description provided for @parserConfidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get parserConfidenceMedium;

  /// No description provided for @parserConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get parserConfidenceLow;

  /// No description provided for @analyzeResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'CV analysis'**
  String get analyzeResultsTitle;

  /// No description provided for @analyzeNoResultsYet.
  ///
  /// In en, this message translates to:
  /// **'Run an analysis to see your readiness score.'**
  String get analyzeNoResultsYet;

  /// No description provided for @analyzeOverallScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'CV readiness score'**
  String get analyzeOverallScoreTitle;

  /// No description provided for @analyzeOverallScoreBody.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {level}. Scores explain readiness gaps you can fix — not hiring odds.'**
  String analyzeOverallScoreBody(String level);

  /// No description provided for @analyzeTopImprovements.
  ///
  /// In en, this message translates to:
  /// **'Top improvements'**
  String get analyzeTopImprovements;

  /// No description provided for @analyzeImproveMyCv.
  ///
  /// In en, this message translates to:
  /// **'Improve my CV'**
  String get analyzeImproveMyCv;

  /// No description provided for @analyzeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Score breakdown'**
  String get analyzeBreakdown;

  /// No description provided for @analyzeWhatsWorking.
  ///
  /// In en, this message translates to:
  /// **'What’s working'**
  String get analyzeWhatsWorking;

  /// No description provided for @analyzeAtsSection.
  ///
  /// In en, this message translates to:
  /// **'ATS compatibility'**
  String get analyzeAtsSection;

  /// No description provided for @analyzeAllFindings.
  ///
  /// In en, this message translates to:
  /// **'All findings'**
  String get analyzeAllFindings;

  /// No description provided for @analyzeDoneToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get analyzeDoneToHome;

  /// No description provided for @analyzeReturningTitle.
  ///
  /// In en, this message translates to:
  /// **'Your latest analysis'**
  String get analyzeReturningTitle;

  /// No description provided for @analyzeReturningBody.
  ///
  /// In en, this message translates to:
  /// **'Results for {fileName} are ready. Review findings or analyze a new file.'**
  String analyzeReturningBody(String fileName);

  /// No description provided for @analyzeLastScan.
  ///
  /// In en, this message translates to:
  /// **'Last scan {date}'**
  String analyzeLastScan(String date);

  /// No description provided for @analyzeViewResults.
  ///
  /// In en, this message translates to:
  /// **'View results'**
  String get analyzeViewResults;

  /// No description provided for @analyzeAgain.
  ///
  /// In en, this message translates to:
  /// **'Analyze a new CV'**
  String get analyzeAgain;

  /// No description provided for @scoreOutOf100.
  ///
  /// In en, this message translates to:
  /// **'/100'**
  String get scoreOutOf100;

  /// No description provided for @scoreSemantic.
  ///
  /// In en, this message translates to:
  /// **'Careerly readiness score {score} out of 100'**
  String scoreSemantic(int score);

  /// No description provided for @scoreCategoryAts.
  ///
  /// In en, this message translates to:
  /// **'ATS compatibility'**
  String get scoreCategoryAts;

  /// No description provided for @scoreCategoryContent.
  ///
  /// In en, this message translates to:
  /// **'Content & impact'**
  String get scoreCategoryContent;

  /// No description provided for @scoreCategoryExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience presentation'**
  String get scoreCategoryExperience;

  /// No description provided for @scoreCategorySkills.
  ///
  /// In en, this message translates to:
  /// **'Skills presentation'**
  String get scoreCategorySkills;

  /// No description provided for @scoreCategoryStructure.
  ///
  /// In en, this message translates to:
  /// **'Structure & readability'**
  String get scoreCategoryStructure;

  /// No description provided for @scoreCategoryLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language & grammar'**
  String get scoreCategoryLanguage;

  /// No description provided for @scoreCategoryBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics & contact'**
  String get scoreCategoryBasics;

  /// No description provided for @findingSeverityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get findingSeverityCritical;

  /// No description provided for @findingSeverityImprove.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get findingSeverityImprove;

  /// No description provided for @findingSeverityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get findingSeverityGood;

  /// No description provided for @findingWhyMatters.
  ///
  /// In en, this message translates to:
  /// **'Why it matters'**
  String get findingWhyMatters;

  /// No description provided for @findingEvidence.
  ///
  /// In en, this message translates to:
  /// **'Detected evidence'**
  String get findingEvidence;

  /// No description provided for @findingAction.
  ///
  /// In en, this message translates to:
  /// **'Recommended action'**
  String get findingAction;

  /// No description provided for @findingImproveWithAi.
  ///
  /// In en, this message translates to:
  /// **'Improve with AI'**
  String get findingImproveWithAi;

  /// No description provided for @findingImproveWithAiBody.
  ///
  /// In en, this message translates to:
  /// **'AI rewrites will be available when the analysis service is connected. Suggestions will never invent employers, metrics, or skills you did not provide.'**
  String get findingImproveWithAiBody;

  /// No description provided for @suggestionDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample rewrite (demo)'**
  String get suggestionDemoTitle;

  /// No description provided for @suggestionBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get suggestionBefore;

  /// No description provided for @suggestionAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get suggestionAfter;

  /// No description provided for @suggestionDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Demo only — Accept does not overwrite your CV in Phase 2.'**
  String get suggestionDemoNote;

  /// No description provided for @suggestionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get suggestionAccept;

  /// No description provided for @suggestionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get suggestionEdit;

  /// No description provided for @suggestionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get suggestionReject;

  /// No description provided for @suggestionDecisionSaved.
  ///
  /// In en, this message translates to:
  /// **'Preference noted. Your CV file was not changed.'**
  String get suggestionDecisionSaved;

  /// No description provided for @jobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobsTitle;

  /// No description provided for @jobsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Match CV to a role'**
  String get jobsEmptyTitle;

  /// No description provided for @jobsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Compare your analyzed CV to a job description you paste. Skills are never invented.'**
  String get jobsEmptyBody;

  /// No description provided for @jobsEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'New Job Match'**
  String get jobsEmptyCta;

  /// No description provided for @jobsHowItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How Job Match works'**
  String get jobsHowItWorksTitle;

  /// No description provided for @jobsHowItWorks1.
  ///
  /// In en, this message translates to:
  /// **'Select an analyzed CV.'**
  String get jobsHowItWorks1;

  /// No description provided for @jobsHowItWorks2.
  ///
  /// In en, this message translates to:
  /// **'Paste the job title and description (URL is optional metadata).'**
  String get jobsHowItWorks2;

  /// No description provided for @jobsHowItWorks3.
  ///
  /// In en, this message translates to:
  /// **'See alignment score, skill evidence, and truthful Optimize CV suggestions.'**
  String get jobsHowItWorks3;

  /// No description provided for @jobsNewMatch.
  ///
  /// In en, this message translates to:
  /// **'New Job Match'**
  String get jobsNewMatch;

  /// No description provided for @jobsSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved matches'**
  String get jobsSavedTitle;

  /// No description provided for @jobsSavedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved matches yet. Run a match and tap Save.'**
  String get jobsSavedEmpty;

  /// No description provided for @jobsNoCvTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze a CV first'**
  String get jobsNoCvTitle;

  /// No description provided for @jobsNoCvBody.
  ///
  /// In en, this message translates to:
  /// **'Job Match needs an analyzed CV so evidence stays truthful.'**
  String get jobsNoCvBody;

  /// No description provided for @jobsNoCvCta.
  ///
  /// In en, this message translates to:
  /// **'Analyze CV First'**
  String get jobsNoCvCta;

  /// No description provided for @jobsSelectCvTitle.
  ///
  /// In en, this message translates to:
  /// **'Select CV'**
  String get jobsSelectCvTitle;

  /// No description provided for @jobsSelectCvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the analyzed CV to compare against the job.'**
  String get jobsSelectCvSubtitle;

  /// No description provided for @jobsSelectCvContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get jobsSelectCvContinue;

  /// No description provided for @jobsJobInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get jobsJobInfoTitle;

  /// No description provided for @jobsJobInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste the posting. We never scrape websites — a URL is only for your notes.'**
  String get jobsJobInfoSubtitle;

  /// No description provided for @jobsJobTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobsJobTitleLabel;

  /// No description provided for @jobsJobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Software Engineering Intern'**
  String get jobsJobTitleHint;

  /// No description provided for @jobsCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company (optional)'**
  String get jobsCompanyLabel;

  /// No description provided for @jobsCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Campus Labs'**
  String get jobsCompanyHint;

  /// No description provided for @jobsUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Job URL (optional)'**
  String get jobsUrlLabel;

  /// No description provided for @jobsUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Metadata only — not scraped'**
  String get jobsUrlHint;

  /// No description provided for @jobsDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Job description'**
  String get jobsDescriptionLabel;

  /// No description provided for @jobsDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the full posting text here…'**
  String get jobsDescriptionHint;

  /// No description provided for @jobsDescriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Paste a fuller job description (at least a short paragraph).'**
  String get jobsDescriptionTooShort;

  /// No description provided for @jobsAnalyzeCta.
  ///
  /// In en, this message translates to:
  /// **'Analyze match'**
  String get jobsAnalyzeCta;

  /// No description provided for @jobsProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Matching your CV'**
  String get jobsProcessingTitle;

  /// No description provided for @jobsProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'Comparing evidence in your CV to this posting — no fake percentages.'**
  String get jobsProcessingBody;

  /// No description provided for @jobsStageReadingJob.
  ///
  /// In en, this message translates to:
  /// **'Reading the job description'**
  String get jobsStageReadingJob;

  /// No description provided for @jobsStageMatchingSkills.
  ///
  /// In en, this message translates to:
  /// **'Matching skills & keywords'**
  String get jobsStageMatchingSkills;

  /// No description provided for @jobsStageScoring.
  ///
  /// In en, this message translates to:
  /// **'Scoring alignment'**
  String get jobsStageScoring;

  /// No description provided for @jobsStageSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Drafting Optimize CV suggestions'**
  String get jobsStageSuggestions;

  /// No description provided for @jobsResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Match results'**
  String get jobsResultsTitle;

  /// No description provided for @jobsMatchScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get jobsMatchScoreLabel;

  /// No description provided for @jobsScoreDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Alignment with this posting — not hiring probability.'**
  String get jobsScoreDisclaimer;

  /// No description provided for @jobsBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get jobsBreakdownTitle;

  /// No description provided for @jobsSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Skill evidence'**
  String get jobsSkillsTitle;

  /// No description provided for @jobsSkillsMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get jobsSkillsMatched;

  /// No description provided for @jobsSkillsPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get jobsSkillsPartial;

  /// No description provided for @jobsSkillsNotDemonstrated.
  ///
  /// In en, this message translates to:
  /// **'Not demonstrated'**
  String get jobsSkillsNotDemonstrated;

  /// No description provided for @jobsSkillsUnclear.
  ///
  /// In en, this message translates to:
  /// **'Unclear'**
  String get jobsSkillsUnclear;

  /// No description provided for @jobsKeywordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get jobsKeywordsTitle;

  /// No description provided for @jobsKeywordsCovered.
  ///
  /// In en, this message translates to:
  /// **'Covered'**
  String get jobsKeywordsCovered;

  /// No description provided for @jobsKeywordsMissing.
  ///
  /// In en, this message translates to:
  /// **'Not in CV'**
  String get jobsKeywordsMissing;

  /// No description provided for @jobsRecommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Optimize CV'**
  String get jobsRecommendationsTitle;

  /// No description provided for @jobsRecommendationsBody.
  ///
  /// In en, this message translates to:
  /// **'Suggestions stay truthful. Accept records a preference — your file is not overwritten.'**
  String get jobsRecommendationsBody;

  /// No description provided for @jobsVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification questions'**
  String get jobsVerificationTitle;

  /// No description provided for @jobsLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning opportunities'**
  String get jobsLearningTitle;

  /// No description provided for @jobsWorkingWellTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s working'**
  String get jobsWorkingWellTitle;

  /// No description provided for @jobsSaveMatch.
  ///
  /// In en, this message translates to:
  /// **'Save match'**
  String get jobsSaveMatch;

  /// No description provided for @jobsSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Match saved to Jobs.'**
  String get jobsSavedSnack;

  /// No description provided for @jobsCategoryCoreSkills.
  ///
  /// In en, this message translates to:
  /// **'Core skills'**
  String get jobsCategoryCoreSkills;

  /// No description provided for @jobsCategoryExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience / projects'**
  String get jobsCategoryExperience;

  /// No description provided for @jobsCategoryResponsibilities.
  ///
  /// In en, this message translates to:
  /// **'Responsibilities'**
  String get jobsCategoryResponsibilities;

  /// No description provided for @jobsCategoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get jobsCategoryEducation;

  /// No description provided for @jobsCategoryTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get jobsCategoryTools;

  /// No description provided for @jobsCategoryLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language / other'**
  String get jobsCategoryLanguage;

  /// No description provided for @jobsErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Job Match could not finish. Try again.'**
  String get jobsErrorGeneric;

  /// No description provided for @jobsRecentMatchScore.
  ///
  /// In en, this message translates to:
  /// **'{score}% match'**
  String jobsRecentMatchScore(int score);

  /// No description provided for @jobsRecentMatchMeta.
  ///
  /// In en, this message translates to:
  /// **'{role} · {company}'**
  String jobsRecentMatchMeta(String role, String company);

  /// No description provided for @homeRecentMatchesCta.
  ///
  /// In en, this message translates to:
  /// **'View matches'**
  String get homeRecentMatchesCta;

  /// No description provided for @builderTitle.
  ///
  /// In en, this message translates to:
  /// **'Builder'**
  String get builderTitle;

  /// No description provided for @builderEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No CVs yet'**
  String get builderEmptyTitle;

  /// No description provided for @builderEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a structured CV, pick an ATS-safe template, and export a searchable PDF. Content stays the same when you switch templates.'**
  String get builderEmptyBody;

  /// No description provided for @builderEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Create new CV'**
  String get builderEmptyCta;

  /// No description provided for @builderHomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Professional CV Builder'**
  String get builderHomeHeadline;

  /// No description provided for @builderHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a template, tell your story, and create a CV that is ready to share.'**
  String get builderHomeBody;

  /// No description provided for @builderCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get builderCreateNew;

  /// No description provided for @builderUseExisting.
  ///
  /// In en, this message translates to:
  /// **'Use existing'**
  String get builderUseExisting;

  /// No description provided for @builderFromAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Create from analyzed CV'**
  String get builderFromAnalyzed;

  /// No description provided for @builderFromAnalyzedHint.
  ///
  /// In en, this message translates to:
  /// **'Analyze a CV first to unlock this start point.'**
  String get builderFromAnalyzedHint;

  /// No description provided for @builderPickExistingHint.
  ///
  /// In en, this message translates to:
  /// **'Open a CV from Your CVs below.'**
  String get builderPickExistingHint;

  /// No description provided for @builderYourCvs.
  ///
  /// In en, this message translates to:
  /// **'Your CVs'**
  String get builderYourCvs;

  /// No description provided for @builderQuickSetup.
  ///
  /// In en, this message translates to:
  /// **'Quick setup'**
  String get builderQuickSetup;

  /// No description provided for @builderCvLanguage.
  ///
  /// In en, this message translates to:
  /// **'CV language (independent of app language)'**
  String get builderCvLanguage;

  /// No description provided for @builderLangEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get builderLangEn;

  /// No description provided for @builderLangTr.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get builderLangTr;

  /// No description provided for @builderTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get builderTemplate;

  /// No description provided for @builderTemplateClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic ATS'**
  String get builderTemplateClassic;

  /// No description provided for @builderTemplateModern.
  ///
  /// In en, this message translates to:
  /// **'Modern ATS'**
  String get builderTemplateModern;

  /// No description provided for @builderTemplateStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get builderTemplateStudent;

  /// No description provided for @builderTemplateTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get builderTemplateTech;

  /// No description provided for @builderStartEditing.
  ///
  /// In en, this message translates to:
  /// **'Start editing'**
  String get builderStartEditing;

  /// No description provided for @builderRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get builderRename;

  /// No description provided for @builderDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get builderDuplicate;

  /// No description provided for @builderDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get builderDelete;

  /// No description provided for @builderDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this CV?'**
  String get builderDeleteConfirmTitle;

  /// No description provided for @builderDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the local draft. It cannot be undone.'**
  String get builderDeleteConfirmBody;

  /// No description provided for @builderCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get builderCancel;

  /// No description provided for @builderSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get builderSave;

  /// No description provided for @builderSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get builderSaving;

  /// No description provided for @builderSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get builderSaved;

  /// No description provided for @builderSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get builderSaveError;

  /// No description provided for @builderExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get builderExportPdf;

  /// No description provided for @builderExportError.
  ///
  /// In en, this message translates to:
  /// **'PDF export failed. Try again.'**
  String get builderExportError;

  /// No description provided for @builderChangeTemplate.
  ///
  /// In en, this message translates to:
  /// **'Change template'**
  String get builderChangeTemplate;

  /// No description provided for @builderTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate (new version)'**
  String get builderTranslate;

  /// No description provided for @builderTranslateDone.
  ///
  /// In en, this message translates to:
  /// **'Translated version created.'**
  String get builderTranslateDone;

  /// No description provided for @builderCheckCv.
  ///
  /// In en, this message translates to:
  /// **'Check CV'**
  String get builderCheckCv;

  /// No description provided for @builderCheckResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Structured CV check'**
  String get builderCheckResultTitle;

  /// No description provided for @builderCheckResultBody.
  ///
  /// In en, this message translates to:
  /// **'Overall score {score}. Same ATS/scoring engines — no re-upload.'**
  String builderCheckResultBody(int score);

  /// No description provided for @builderOpenAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Open full analysis'**
  String get builderOpenAnalysis;

  /// No description provided for @builderTailorJob.
  ///
  /// In en, this message translates to:
  /// **'Tailor to job'**
  String get builderTailorJob;

  /// No description provided for @builderCloseEditor.
  ///
  /// In en, this message translates to:
  /// **'Close editor'**
  String get builderCloseEditor;

  /// No description provided for @builderEditTab.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get builderEditTab;

  /// No description provided for @builderPreviewTab.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get builderPreviewTab;

  /// No description provided for @builderPreviewFallback.
  ///
  /// In en, this message translates to:
  /// **'PDF preview unavailable — showing structured layout (same content).'**
  String get builderPreviewFallback;

  /// No description provided for @builderMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get builderMoreActions;

  /// No description provided for @builderZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get builderZoomIn;

  /// No description provided for @builderZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get builderZoomOut;

  /// No description provided for @builderAddCustomSection.
  ///
  /// In en, this message translates to:
  /// **'Add custom section'**
  String get builderAddCustomSection;

  /// No description provided for @builderCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom section title'**
  String get builderCustomTitle;

  /// No description provided for @builderBulletsHint.
  ///
  /// In en, this message translates to:
  /// **'Bullets (one per line)'**
  String get builderBulletsHint;

  /// No description provided for @builderSectionPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get builderSectionPersonal;

  /// No description provided for @builderSectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get builderSectionSummary;

  /// No description provided for @builderSectionEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get builderSectionEducation;

  /// No description provided for @builderSectionExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get builderSectionExperience;

  /// No description provided for @builderSectionProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get builderSectionProjects;

  /// No description provided for @builderSectionSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get builderSectionSkills;

  /// No description provided for @builderSectionLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get builderSectionLanguages;

  /// No description provided for @builderSectionCerts.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get builderSectionCerts;

  /// No description provided for @builderSectionAwards.
  ///
  /// In en, this message translates to:
  /// **'Awards / Activities'**
  String get builderSectionAwards;

  /// No description provided for @builderHideSection.
  ///
  /// In en, this message translates to:
  /// **'Hide section'**
  String get builderHideSection;

  /// No description provided for @builderShowSection.
  ///
  /// In en, this message translates to:
  /// **'Show section'**
  String get builderShowSection;

  /// No description provided for @builderSectionHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden from preview and PDF.'**
  String get builderSectionHidden;

  /// No description provided for @builderMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get builderMoveUp;

  /// No description provided for @builderMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get builderMoveDown;

  /// No description provided for @builderCompletionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get builderCompletionEmpty;

  /// No description provided for @builderCompletionPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get builderCompletionPartial;

  /// No description provided for @builderCompletionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get builderCompletionComplete;

  /// No description provided for @builderFieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get builderFieldFullName;

  /// No description provided for @builderFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get builderFieldEmail;

  /// No description provided for @builderFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get builderFieldPhone;

  /// No description provided for @builderFieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get builderFieldLocation;

  /// No description provided for @builderFieldLinkedin.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get builderFieldLinkedin;

  /// No description provided for @builderFieldWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get builderFieldWebsite;

  /// No description provided for @builderFieldSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get builderFieldSchool;

  /// No description provided for @builderFieldDegree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get builderFieldDegree;

  /// No description provided for @builderFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get builderFieldTitle;

  /// No description provided for @builderFieldOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get builderFieldOrganization;

  /// No description provided for @builderFieldProjectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get builderFieldProjectName;

  /// No description provided for @builderFieldTech.
  ///
  /// In en, this message translates to:
  /// **'Tech (comma-separated)'**
  String get builderFieldTech;

  /// No description provided for @builderFieldSkillGroup.
  ///
  /// In en, this message translates to:
  /// **'Skill group label'**
  String get builderFieldSkillGroup;

  /// No description provided for @builderFieldSkillsCsv.
  ///
  /// In en, this message translates to:
  /// **'Skills (comma-separated, no star bars)'**
  String get builderFieldSkillsCsv;

  /// No description provided for @builderFieldLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get builderFieldLanguage;

  /// No description provided for @builderFieldLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get builderFieldLevel;

  /// No description provided for @builderFieldCertName.
  ///
  /// In en, this message translates to:
  /// **'Certification'**
  String get builderFieldCertName;

  /// No description provided for @builderFieldIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get builderFieldIssuer;

  /// No description provided for @builderFieldAward.
  ///
  /// In en, this message translates to:
  /// **'Award / activity'**
  String get builderFieldAward;

  /// No description provided for @builderAddEducation.
  ///
  /// In en, this message translates to:
  /// **'Add education'**
  String get builderAddEducation;

  /// No description provided for @builderAddExperience.
  ///
  /// In en, this message translates to:
  /// **'Add experience'**
  String get builderAddExperience;

  /// No description provided for @builderAddProject.
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get builderAddProject;

  /// No description provided for @builderAddSkillGroup.
  ///
  /// In en, this message translates to:
  /// **'Add skill group'**
  String get builderAddSkillGroup;

  /// No description provided for @builderAddLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add language'**
  String get builderAddLanguage;

  /// No description provided for @builderAddCert.
  ///
  /// In en, this message translates to:
  /// **'Add certification'**
  String get builderAddCert;

  /// No description provided for @builderAddAward.
  ///
  /// In en, this message translates to:
  /// **'Add award'**
  String get builderAddAward;

  /// No description provided for @builderAiImprove.
  ///
  /// In en, this message translates to:
  /// **'AI improve'**
  String get builderAiImprove;

  /// No description provided for @builderAiModeImprove.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get builderAiModeImprove;

  /// No description provided for @builderAiModeConcise.
  ///
  /// In en, this message translates to:
  /// **'Concise'**
  String get builderAiModeConcise;

  /// No description provided for @builderAiModeProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get builderAiModeProfessional;

  /// No description provided for @builderAiOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get builderAiOriginal;

  /// No description provided for @builderAiSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get builderAiSuggested;

  /// No description provided for @builderAiWhy.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get builderAiWhy;

  /// No description provided for @builderAiNeedsFact.
  ///
  /// In en, this message translates to:
  /// **'We need a real fact from you — nothing was invented.'**
  String get builderAiNeedsFact;

  /// No description provided for @builderAiAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get builderAiAccept;

  /// No description provided for @builderAiTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get builderAiTryAgain;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileMockUser.
  ///
  /// In en, this message translates to:
  /// **'Demo user'**
  String get profileMockUser;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get profileLanguage;

  /// No description provided for @profilePreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferences;

  /// No description provided for @profileCareerStage.
  ///
  /// In en, this message translates to:
  /// **'Career stage'**
  String get profileCareerStage;

  /// No description provided for @profileGoal.
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get profileGoal;

  /// No description provided for @profileFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get profileFields;

  /// No description provided for @profileCvLanguage.
  ///
  /// In en, this message translates to:
  /// **'CV language'**
  String get profileCvLanguage;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get profilePrivacy;

  /// No description provided for @profilePrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'CVs are personal data. Use Delete account data to wipe all local Careerly data on this device. Server-side deletion requires a configured backend account (see EXTERNAL_ACTIONS.md).'**
  String get profilePrivacyBody;

  /// No description provided for @profileResetDemo.
  ///
  /// In en, this message translates to:
  /// **'Reset demo onboarding'**
  String get profileResetDemo;

  /// No description provided for @profileResetDemoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear local progress and return to language selection?'**
  String get profileResetDemoConfirm;

  /// No description provided for @profileResetDemoAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get profileResetDemoAction;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account data'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently wipe all Careerly data stored on this device (CVs, analysis, matches, billing cache)? This cannot be undone.'**
  String get profileDeleteAccountConfirm;

  /// No description provided for @profileDeleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileDeleteAccountAction;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String profileVersion(String version);

  /// No description provided for @profileSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get profileSubscription;

  /// No description provided for @profileSubscriptionSoon.
  ///
  /// In en, this message translates to:
  /// **'Plans unlock after core analysis value — not before.'**
  String get profileSubscriptionSoon;

  /// No description provided for @billingPlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get billingPlanFree;

  /// No description provided for @billingPlanPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get billingPlanPro;

  /// No description provided for @billingStatusFree.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get billingStatusFree;

  /// No description provided for @billingStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get billingStatusActive;

  /// No description provided for @billingStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get billingStatusExpired;

  /// No description provided for @billingStatusBillingIssue.
  ///
  /// In en, this message translates to:
  /// **'Billing issue'**
  String get billingStatusBillingIssue;

  /// No description provided for @billingPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Your own CV data stays readable if Pro expires. Creation and premium tools follow your plan.'**
  String get billingPlanBody;

  /// No description provided for @billingUpgradeCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get billingUpgradeCta;

  /// No description provided for @billingManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get billingManageSubscription;

  /// No description provided for @billingManageBody.
  ///
  /// In en, this message translates to:
  /// **'Cancel or change plans in the App Store or Google Play for your account. Careerly never fakes a cancel button.'**
  String get billingManageBody;

  /// No description provided for @billingDevOverride.
  ///
  /// In en, this message translates to:
  /// **'Dev plan override (debug only)'**
  String get billingDevOverride;

  /// No description provided for @billingDevClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get billingDevClear;

  /// No description provided for @billingLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan limit reached'**
  String get billingLimitTitle;

  /// No description provided for @billingLimitBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used this Free allowance. Upgrade for more — your saved CV data stays available to read.'**
  String get billingLimitBody;

  /// No description provided for @billingNearLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost at your Free limit'**
  String get billingNearLimitTitle;

  /// No description provided for @billingNearLimitBody.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {limit} remaining this period.'**
  String billingNearLimitBody(int remaining, int limit);

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Careerly Pro'**
  String get paywallTitle;

  /// No description provided for @paywallHeadline.
  ///
  /// In en, this message translates to:
  /// **'Build every application\nwith more clarity.'**
  String get paywallHeadline;

  /// No description provided for @paywallBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already seen Careerly\'s core value. Pro unlocks more analyses, job matches, AI rewrites, templates, and translation — without locking the CV you already entered.'**
  String get paywallBody;

  /// No description provided for @paywallValue1.
  ///
  /// In en, this message translates to:
  /// **'More CV analyses each month'**
  String get paywallValue1;

  /// No description provided for @paywallValue2.
  ///
  /// In en, this message translates to:
  /// **'Extra Job Matches against pasted roles'**
  String get paywallValue2;

  /// No description provided for @paywallValue3.
  ///
  /// In en, this message translates to:
  /// **'Additional truthful AI rewrite assists'**
  String get paywallValue3;

  /// No description provided for @paywallValue4.
  ///
  /// In en, this message translates to:
  /// **'Premium templates and bilingual export'**
  String get paywallValue4;

  /// No description provided for @paywallChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get paywallChoosePlan;

  /// No description provided for @paywallMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallMonthly;

  /// No description provided for @paywallYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get paywallYearly;

  /// No description provided for @paywallPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Prices come from the App Store / Google Play. Demo labels appear only in debug builds.'**
  String get paywallPriceNote;

  /// No description provided for @paywallCta.
  ///
  /// In en, this message translates to:
  /// **'Continue with Pro'**
  String get paywallCta;

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestore;

  /// No description provided for @paywallRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get paywallRestoreSuccess;

  /// No description provided for @paywallRestoreEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to restore on this account.'**
  String get paywallRestoreEmpty;

  /// No description provided for @paywallSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pro is active. Thank you.'**
  String get paywallSuccess;

  /// No description provided for @paywallError.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not finish. Try again or restore.'**
  String get paywallError;

  /// No description provided for @paywallLegal.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use and Privacy Policy placeholders. Subscription renews unless cancelled in the store.'**
  String get paywallLegal;

  /// No description provided for @emptyGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyGenericTitle;

  /// No description provided for @emptyGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Content will appear when this feature is available.'**
  String get emptyGenericBody;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again. If the problem continues, restart the app.'**
  String get errorGenericBody;

  /// No description provided for @loadingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingGeneric;

  /// No description provided for @offlineHint.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Some features need a connection later.'**
  String get offlineHint;

  /// No description provided for @semanticScoreBadge.
  ///
  /// In en, this message translates to:
  /// **'Score badge placeholder'**
  String get semanticScoreBadge;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @homeReadyNamed.
  ///
  /// In en, this message translates to:
  /// **'Ready for\nyour next move,\n{name}?'**
  String homeReadyNamed(String name);

  /// No description provided for @homeReadyPlain.
  ///
  /// In en, this message translates to:
  /// **'Ready for\nyour next move?'**
  String get homeReadyPlain;

  /// No description provided for @profileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get profileFirstName;

  /// No description provided for @profileUsageAnalyses.
  ///
  /// In en, this message translates to:
  /// **'CV analyses'**
  String get profileUsageAnalyses;

  /// No description provided for @profileUsageMatches.
  ///
  /// In en, this message translates to:
  /// **'Job matches'**
  String get profileUsageMatches;

  /// No description provided for @profileUsageMeter.
  ///
  /// In en, this message translates to:
  /// **'{used} / {limit} used'**
  String profileUsageMeter(int used, int limit);

  /// No description provided for @jobsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get jobsDelete;

  /// No description provided for @productCvQuality.
  ///
  /// In en, this message translates to:
  /// **'CV Quality'**
  String get productCvQuality;

  /// No description provided for @productAtsReadability.
  ///
  /// In en, this message translates to:
  /// **'ATS Readability'**
  String get productAtsReadability;

  /// No description provided for @productJobMatch.
  ///
  /// In en, this message translates to:
  /// **'Job Match'**
  String get productJobMatch;

  /// No description provided for @productJobMatchLocked.
  ///
  /// In en, this message translates to:
  /// **'Add a target job to unlock'**
  String get productJobMatchLocked;

  /// No description provided for @productScoreDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Careerly analysis of CV structure, content, and job requirements. Not an employer\'s ATS score.'**
  String get productScoreDisclaimer;

  /// No description provided for @productBiggestOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Biggest opportunities'**
  String get productBiggestOpportunities;

  /// No description provided for @productBandNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get productBandNeedsWork;

  /// No description provided for @productBandDeveloping.
  ///
  /// In en, this message translates to:
  /// **'Developing'**
  String get productBandDeveloping;

  /// No description provided for @productBandStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get productBandStrong;

  /// No description provided for @productBandExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get productBandExcellent;

  /// No description provided for @productQualityImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact and achievements'**
  String get productQualityImpact;

  /// No description provided for @productQualityExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience quality'**
  String get productQualityExperience;

  /// No description provided for @productQualitySkills.
  ///
  /// In en, this message translates to:
  /// **'Skills and tools'**
  String get productQualitySkills;

  /// No description provided for @productQualityStructure.
  ///
  /// In en, this message translates to:
  /// **'Structure and completeness'**
  String get productQualityStructure;

  /// No description provided for @productQualityWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing quality'**
  String get productQualityWriting;

  /// No description provided for @productQualityConcise.
  ///
  /// In en, this message translates to:
  /// **'Conciseness'**
  String get productQualityConcise;

  /// No description provided for @optimizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Improve your CV'**
  String get optimizeTitle;

  /// No description provided for @optimizeIntro.
  ///
  /// In en, this message translates to:
  /// **'Careerly checked each experience and project line. Nothing changes until you accept it, and scores update only after Careerly re-checks the edited CV.'**
  String get optimizeIntro;

  /// No description provided for @optimizeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No line-level fixes found. Your experience and project lines pass Careerly\'s checks.'**
  String get optimizeEmpty;

  /// No description provided for @optimizeNoCv.
  ///
  /// In en, this message translates to:
  /// **'Analyze a CV first to see suggestions.'**
  String get optimizeNoCv;

  /// No description provided for @optimizeImpactHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH IMPACT'**
  String get optimizeImpactHigh;

  /// No description provided for @optimizeImpactMedium.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM IMPACT'**
  String get optimizeImpactMedium;

  /// No description provided for @optimizeImpactLow.
  ///
  /// In en, this message translates to:
  /// **'SMALL FIX'**
  String get optimizeImpactLow;

  /// No description provided for @optimizeKindWeakOpening.
  ///
  /// In en, this message translates to:
  /// **'Lead with what you did'**
  String get optimizeKindWeakOpening;

  /// No description provided for @optimizeKindFirstPerson.
  ///
  /// In en, this message translates to:
  /// **'Drop the first person'**
  String get optimizeKindFirstPerson;

  /// No description provided for @optimizeKindTooLong.
  ///
  /// In en, this message translates to:
  /// **'Shorten this line'**
  String get optimizeKindTooLong;

  /// No description provided for @optimizeKindNoMetric.
  ///
  /// In en, this message translates to:
  /// **'Add a real result'**
  String get optimizeKindNoMetric;

  /// No description provided for @optimizeKindFormatting.
  ///
  /// In en, this message translates to:
  /// **'Clean up wording'**
  String get optimizeKindFormatting;

  /// No description provided for @optimizeWhyWeakOpening.
  ///
  /// In en, this message translates to:
  /// **'Phrases like \"responsible for\" describe duties, not contribution. An action verb makes your part clear.'**
  String get optimizeWhyWeakOpening;

  /// No description provided for @optimizeWhyFirstPerson.
  ///
  /// In en, this message translates to:
  /// **'CV lines usually start with the action. Removing \"I\" keeps them tight.'**
  String get optimizeWhyFirstPerson;

  /// No description provided for @optimizeWhyTooLong.
  ///
  /// In en, this message translates to:
  /// **'Long lines are skimmed. One idea per line is easier to read.'**
  String get optimizeWhyTooLong;

  /// No description provided for @optimizeWhyNoMetric.
  ///
  /// In en, this message translates to:
  /// **'A number you can verify (people, items, time saved) makes impact concrete.'**
  String get optimizeWhyNoMetric;

  /// No description provided for @optimizeWhyFormatting.
  ///
  /// In en, this message translates to:
  /// **'Small spacing and wording fixes. Meaning stays the same.'**
  String get optimizeWhyFormatting;

  /// No description provided for @optimizeQuestionOutcome.
  ///
  /// In en, this message translates to:
  /// **'What did you deliver or change here? Write it in your own words — Careerly won\'t invent it.'**
  String get optimizeQuestionOutcome;

  /// No description provided for @optimizeQuestionMetric.
  ///
  /// In en, this message translates to:
  /// **'Do you know roughly how many people, posts, items, or hours this involved? Only add numbers you can stand behind.'**
  String get optimizeQuestionMetric;

  /// No description provided for @optimizeOriginal.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get optimizeOriginal;

  /// No description provided for @optimizeSuggested.
  ///
  /// In en, this message translates to:
  /// **'Careerly suggestion'**
  String get optimizeSuggested;

  /// No description provided for @optimizeYourVersion.
  ///
  /// In en, this message translates to:
  /// **'Your version'**
  String get optimizeYourVersion;

  /// No description provided for @optimizeAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get optimizeAccept;

  /// No description provided for @optimizeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get optimizeEdit;

  /// No description provided for @optimizeSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get optimizeSkip;

  /// No description provided for @optimizeUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get optimizeUndo;

  /// No description provided for @optimizeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get optimizeSave;

  /// No description provided for @optimizeEditHint.
  ///
  /// In en, this message translates to:
  /// **'Use only facts that are true.'**
  String get optimizeEditHint;

  /// No description provided for @optimizeStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get optimizeStatusAccepted;

  /// No description provided for @optimizeStatusEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get optimizeStatusEdited;

  /// No description provided for @optimizeStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get optimizeStatusSkipped;

  /// No description provided for @optimizeRewrite.
  ///
  /// In en, this message translates to:
  /// **'Rewrite with AI'**
  String get optimizeRewrite;

  /// No description provided for @optimizeModeImpact.
  ///
  /// In en, this message translates to:
  /// **'Stronger impact'**
  String get optimizeModeImpact;

  /// No description provided for @optimizeModeConcise.
  ///
  /// In en, this message translates to:
  /// **'More concise'**
  String get optimizeModeConcise;

  /// No description provided for @optimizeModeProfessional.
  ///
  /// In en, this message translates to:
  /// **'More professional'**
  String get optimizeModeProfessional;

  /// No description provided for @optimizeModeJobTargeted.
  ///
  /// In en, this message translates to:
  /// **'Job targeted'**
  String get optimizeModeJobTargeted;

  /// No description provided for @optimizeModeGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar only'**
  String get optimizeModeGrammar;

  /// No description provided for @optimizeApply.
  ///
  /// In en, this message translates to:
  /// **'Apply {count} changes and re-score'**
  String optimizeApply(int count);

  /// No description provided for @optimizeAiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI rewrites are temporarily unavailable. Your analysis and rule-based suggestions still work.'**
  String get optimizeAiUnavailable;

  /// No description provided for @optimizeAiKeptOriginal.
  ///
  /// In en, this message translates to:
  /// **'The AI rewrite added details that aren\'t in your CV, so Careerly kept your line.'**
  String get optimizeAiKeptOriginal;

  /// No description provided for @optimizeAiFailed.
  ///
  /// In en, this message translates to:
  /// **'The rewrite didn\'t complete. Try again.'**
  String get optimizeAiFailed;

  /// No description provided for @optimizeRescoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t re-score the edited CV. Your previous analysis is unchanged.'**
  String get optimizeRescoreFailed;

  /// No description provided for @optimizeResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Re-checked by Careerly'**
  String get optimizeResultTitle;

  /// No description provided for @optimizeResultUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Scores didn\'t move. Your edits are saved, but they didn\'t change what the checks measure.'**
  String get optimizeResultUnchanged;

  /// No description provided for @optimizeVersions.
  ///
  /// In en, this message translates to:
  /// **'CV versions'**
  String get optimizeVersions;

  /// No description provided for @optimizeVersionOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get optimizeVersionOriginal;

  /// No description provided for @optimizeVersionOptimized.
  ///
  /// In en, this message translates to:
  /// **'Optimized'**
  String get optimizeVersionOptimized;

  /// No description provided for @optimizeRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get optimizeRestore;

  /// No description provided for @optimizeJobMatchRerun.
  ///
  /// In en, this message translates to:
  /// **'Run the job match again to see your updated match.'**
  String get optimizeJobMatchRerun;

  /// No description provided for @optimizeOpenInBuilder.
  ///
  /// In en, this message translates to:
  /// **'Open in Builder'**
  String get optimizeOpenInBuilder;

  /// No description provided for @optimizeBuilderNote.
  ///
  /// In en, this message translates to:
  /// **'Builder exports a searchable PDF in a Careerly template. Your original file\'s layout isn\'t copied.'**
  String get optimizeBuilderNote;

  /// No description provided for @appsTitle.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get appsTitle;

  /// No description provided for @appsIntro.
  ///
  /// In en, this message translates to:
  /// **'Keep track of where you applied and which CV you sent.'**
  String get appsIntro;

  /// No description provided for @appsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No applications yet. Add one from a job match or start here.'**
  String get appsEmpty;

  /// No description provided for @appsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add application'**
  String get appsAdd;

  /// No description provided for @appsAddFromMatch.
  ///
  /// In en, this message translates to:
  /// **'Add to applications'**
  String get appsAddFromMatch;

  /// No description provided for @appsAlreadyTracked.
  ///
  /// In en, this message translates to:
  /// **'Already in your applications'**
  String get appsAlreadyTracked;

  /// No description provided for @appsAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to applications'**
  String get appsAdded;

  /// No description provided for @appsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get appsAll;

  /// No description provided for @appsStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get appsStatusSaved;

  /// No description provided for @appsStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get appsStatusPreparing;

  /// No description provided for @appsStatusApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get appsStatusApplied;

  /// No description provided for @appsStatusInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get appsStatusInterview;

  /// No description provided for @appsStatusOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get appsStatusOffer;

  /// No description provided for @appsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get appsStatusRejected;

  /// No description provided for @appsFieldRole.
  ///
  /// In en, this message translates to:
  /// **'Role title'**
  String get appsFieldRole;

  /// No description provided for @appsFieldCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get appsFieldCompany;

  /// No description provided for @appsFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get appsFieldStatus;

  /// No description provided for @appsFieldCv.
  ///
  /// In en, this message translates to:
  /// **'CV version sent'**
  String get appsFieldCv;

  /// No description provided for @appsFieldCvCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current CV'**
  String get appsFieldCvCurrent;

  /// No description provided for @appsFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get appsFieldNotes;

  /// No description provided for @appsFieldNext.
  ///
  /// In en, this message translates to:
  /// **'Next action'**
  String get appsFieldNext;

  /// No description provided for @appsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get appsSave;

  /// No description provided for @appsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete application'**
  String get appsDelete;

  /// No description provided for @appsMatch.
  ///
  /// In en, this message translates to:
  /// **'{score}% match'**
  String appsMatch(int score);

  /// No description provided for @appsAppliedOn.
  ///
  /// In en, this message translates to:
  /// **'Applied {date}'**
  String appsAppliedOn(String date);

  /// No description provided for @appsOpen.
  ///
  /// In en, this message translates to:
  /// **'View applications'**
  String get appsOpen;

  /// No description provided for @homeOverviewLabel.
  ///
  /// In en, this message translates to:
  /// **'{day} · Career overview'**
  String homeOverviewLabel(String day);

  /// No description provided for @homeImproveCta.
  ///
  /// In en, this message translates to:
  /// **'Improve my CV · {count} fixes'**
  String homeImproveCta(int count);

  /// No description provided for @homeImproveCtaNone.
  ///
  /// In en, this message translates to:
  /// **'Improve my CV'**
  String get homeImproveCtaNone;

  /// No description provided for @homeJobMatchAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a job'**
  String get homeJobMatchAdd;

  /// No description provided for @homeStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next steps'**
  String get homeStepsTitle;

  /// No description provided for @homeStepAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze your CV'**
  String get homeStepAnalyze;

  /// No description provided for @homeStepAnalyzeHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a PDF or DOCX to get your scores.'**
  String get homeStepAnalyzeHint;

  /// No description provided for @homeStepAnalyzeDone.
  ///
  /// In en, this message translates to:
  /// **'CV quality {score}/100'**
  String homeStepAnalyzeDone(int score);

  /// No description provided for @homeStepImprove.
  ///
  /// In en, this message translates to:
  /// **'Fix weak lines'**
  String get homeStepImprove;

  /// No description provided for @homeStepImproveHint.
  ///
  /// In en, this message translates to:
  /// **'Available after your first analysis.'**
  String get homeStepImproveHint;

  /// No description provided for @homeStepImprovePending.
  ///
  /// In en, this message translates to:
  /// **'{count} line fixes waiting for your review'**
  String homeStepImprovePending(int count);

  /// No description provided for @homeStepImproveDone.
  ///
  /// In en, this message translates to:
  /// **'Optimized version saved'**
  String get homeStepImproveDone;

  /// No description provided for @homeStepImproveNone.
  ///
  /// In en, this message translates to:
  /// **'No line fixes needed right now'**
  String get homeStepImproveNone;

  /// No description provided for @homeStepMatch.
  ///
  /// In en, this message translates to:
  /// **'Match a job posting'**
  String get homeStepMatch;

  /// No description provided for @homeStepMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a job description to see your gaps.'**
  String get homeStepMatchHint;

  /// No description provided for @homeStepMatchDone.
  ///
  /// In en, this message translates to:
  /// **'{score}% match · {title}'**
  String homeStepMatchDone(int score, String title);

  /// No description provided for @homeStepTrack.
  ///
  /// In en, this message translates to:
  /// **'Track your applications'**
  String get homeStepTrack;

  /// No description provided for @homeStepTrackHint.
  ///
  /// In en, this message translates to:
  /// **'Keep status, CV version and next step in one place.'**
  String get homeStepTrackHint;

  /// No description provided for @homeStepTrackDone.
  ///
  /// In en, this message translates to:
  /// **'{count} applications tracked'**
  String homeStepTrackDone(int count);

  /// No description provided for @homeAppsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get homeAppsActive;

  /// No description provided for @homeNoMatchesHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your next application starts here.'**
  String get homeNoMatchesHeadline;

  /// No description provided for @homeToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get homeToolsTitle;

  /// No description provided for @labelNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get labelNoMatches;

  /// No description provided for @labelNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match'**
  String get labelNoMatch;

  /// No description provided for @labelNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get labelNoResults;

  /// No description provided for @labelNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get labelNoDocuments;

  /// No description provided for @labelSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get labelSections;

  /// No description provided for @labelEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get labelEvidence;

  /// No description provided for @labelWhatsWorking.
  ///
  /// In en, this message translates to:
  /// **'What\'s working'**
  String get labelWhatsWorking;

  /// No description provided for @labelWhyStronger.
  ///
  /// In en, this message translates to:
  /// **'Why it\'s stronger'**
  String get labelWhyStronger;

  /// No description provided for @labelTopPriority.
  ///
  /// In en, this message translates to:
  /// **'01 — Top priority'**
  String get labelTopPriority;

  /// No description provided for @labelBiggestGap.
  ///
  /// In en, this message translates to:
  /// **'01 — Biggest gap'**
  String get labelBiggestGap;

  /// No description provided for @improveThis.
  ///
  /// In en, this message translates to:
  /// **'Improve this →'**
  String get improveThis;

  /// No description provided for @jobsHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Job match'**
  String get jobsHeaderLabel;

  /// No description provided for @jobsHeaderHeadline.
  ///
  /// In en, this message translates to:
  /// **'See what the\nrole is asking for.'**
  String get jobsHeaderHeadline;

  /// No description provided for @analyzeHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'CV analysis'**
  String get analyzeHeaderLabel;

  /// No description provided for @analyzeHeaderHeadline.
  ///
  /// In en, this message translates to:
  /// **'Let\'s see what\nyour CV says.'**
  String get analyzeHeaderHeadline;

  /// No description provided for @builderHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'My CVs'**
  String get builderHeaderLabel;

  /// No description provided for @builderHeaderHeadline.
  ///
  /// In en, this message translates to:
  /// **'Design your next CV.'**
  String get builderHeaderHeadline;

  /// No description provided for @profileHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileHeaderLabel;

  /// No description provided for @alignmentStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong alignment'**
  String get alignmentStrong;

  /// No description provided for @alignmentGood.
  ///
  /// In en, this message translates to:
  /// **'Good alignment'**
  String get alignmentGood;

  /// No description provided for @alignmentPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial alignment'**
  String get alignmentPartial;

  /// No description provided for @alignmentWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak alignment'**
  String get alignmentWeak;

  /// No description provided for @onboardingKicker1.
  ///
  /// In en, this message translates to:
  /// **'Know'**
  String get onboardingKicker1;

  /// No description provided for @onboardingHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Your CV,\ndecoded.'**
  String get onboardingHeadline1;

  /// No description provided for @onboardingKicker2.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get onboardingKicker2;

  /// No description provided for @onboardingHeadline2.
  ///
  /// In en, this message translates to:
  /// **'See what the\nrole is asking for.'**
  String get onboardingHeadline2;

  /// No description provided for @onboardingKicker3.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get onboardingKicker3;

  /// No description provided for @onboardingHeadline3.
  ///
  /// In en, this message translates to:
  /// **'Turn insight\ninto a stronger CV.'**
  String get onboardingHeadline3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
