import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/analytics/billing_analytics.dart';
import '../../../core/storage/local_store.dart';
import '../domain/job_application.dart';

/// Local-first tracker. Newest first; no CV or job text is stored here.
class ApplicationsController extends StateNotifier<List<JobApplication>> {
  ApplicationsController(this._store, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now,
      super(const []) {
    state = _read();
  }

  final LocalStore _store;
  final DateTime Function() _now;

  static const storageKey = 'job_applications_json';

  Future<JobApplication> create({
    required String jobTitle,
    String? company,
    String? jobUrl,
    String? jobMatchId,
    int? matchScore,
    String? cvVersionId,
    ApplicationStatus status = ApplicationStatus.saved,
  }) async {
    final now = _now();
    final item = JobApplication(
      id: const Uuid().v4(),
      jobTitle: jobTitle.trim(),
      company: company?.trim().isEmpty ?? true ? null : company!.trim(),
      jobUrl: jobUrl,
      jobMatchId: jobMatchId,
      matchScore: matchScore,
      cvVersionId: cvVersionId,
      status: status,
      appliedAt: status == ApplicationStatus.applied ? now : null,
      createdAt: now,
      updatedAt: now,
    );
    state = [item, ...state];
    await _write();
    BillingAnalytics.track('application_created', {
      'status': status.name,
      'fromMatch': jobMatchId != null,
    });
    return item;
  }

  /// Returns the existing entry for a match instead of creating a duplicate.
  JobApplication? forMatch(String jobMatchId) {
    for (final item in state) {
      if (item.jobMatchId == jobMatchId) return item;
    }
    return null;
  }

  Future<void> update(JobApplication next) async {
    final previous = state.where((a) => a.id == next.id).firstOrNull;
    if (previous == null) return;
    final now = _now();
    var value = next.copyWith(updatedAt: now);
    if (next.status == ApplicationStatus.applied && next.appliedAt == null) {
      value = value.copyWith(appliedAt: now);
    }
    state = [for (final a in state) a.id == next.id ? value : a];
    await _write();
    if (previous.status != value.status) {
      BillingAnalytics.track('application_status_changed', {
        'from': previous.status.name,
        'to': value.status.name,
      });
    }
  }

  Future<void> setStatus(String id, ApplicationStatus status) async {
    final item = state.where((a) => a.id == id).firstOrNull;
    if (item == null) return;
    await update(item.copyWith(status: status));
  }

  Future<void> delete(String id) async {
    state = state.where((a) => a.id != id).toList();
    await _write();
  }

  /// Clears in-memory applications after the signed-in user changes.
  void clearUserData() {
    state = const [];
  }

  List<JobApplication> _read() {
    final raw = _store.readString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(JobApplication.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _write() => _store.writeString(
    storageKey,
    jsonEncode(state.map((a) => a.toJson()).toList()),
  );
}

final applicationsControllerProvider =
    StateNotifierProvider<ApplicationsController, List<JobApplication>>((ref) {
      final store = ref.watch(localStoreProvider);
      final controller = ApplicationsController(store);
      store.addUserDataResetListener(controller.clearUserData);
      ref.onDispose(
        () => store.removeUserDataResetListener(controller.clearUserData),
      );
      return controller;
    });
