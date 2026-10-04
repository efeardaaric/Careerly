import 'package:careerly/core/storage/local_store.dart';
import 'package:careerly/features/applications/application/applications_controller.dart';
import 'package:careerly/features/applications/domain/job_application.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  final now = DateTime.utc(2026, 10, 1, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.create();
  });

  test('create persists newest first and survives reload', () async {
    final ctrl = ApplicationsController(store, clock: () => now);
    await ctrl.create(jobTitle: 'Data Analyst Intern', company: 'Example Co');
    await ctrl.create(jobTitle: 'Flutter Developer', company: '  ');

    expect(ctrl.state.first.jobTitle, 'Flutter Developer');
    expect(ctrl.state.first.company, isNull);
    expect(ctrl.state.first.status, ApplicationStatus.saved);

    final reloaded = ApplicationsController(store);
    expect(reloaded.state.map((a) => a.jobTitle), [
      'Flutter Developer',
      'Data Analyst Intern',
    ]);
  });

  test('moving to applied stamps appliedAt once', () async {
    final ctrl = ApplicationsController(store, clock: () => now);
    final item = await ctrl.create(jobTitle: 'Product Intern');
    expect(item.appliedAt, isNull);

    await ctrl.setStatus(item.id, ApplicationStatus.applied);
    expect(ctrl.state.single.appliedAt, now);

    await ctrl.setStatus(item.id, ApplicationStatus.interview);
    expect(ctrl.state.single.appliedAt, now);
    expect(ctrl.state.single.status, ApplicationStatus.interview);
  });

  test('match link prevents duplicates and keeps the real match score', () async {
    final ctrl = ApplicationsController(store, clock: () => now);
    expect(ctrl.forMatch('m1'), isNull);
    await ctrl.create(jobTitle: 'BI Intern', jobMatchId: 'm1', matchScore: 62);
    expect(ctrl.forMatch('m1')!.matchScore, 62);
  });

  test('delete removes the entry', () async {
    final ctrl = ApplicationsController(store, clock: () => now);
    final item = await ctrl.create(jobTitle: 'MIS Intern');
    await ctrl.delete(item.id);
    expect(ctrl.state, isEmpty);
    expect(ApplicationsController(store).state, isEmpty);
  });
}
