import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

/// A readable error that screens can show to the user.
class ApplicationException implements Exception {
  ApplicationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cancellation workflow for job applications.
///
///  1. The applicant calls [requestCancellation]  -> the admin is notified.
///     Nothing is cancelled yet; the request is stored as `cancelRequest`.
///  2. The admin calls [decideCancellation]       -> the applicant is notified.
///     Approve -> status becomes "Cancelled". Decline -> application stays.
///
/// IMPORTANT: this runs inside the app, so Firestore Security Rules are the
/// only real protection. See the rules in README_STANDALONE.md.
class ApplicationService {
  ApplicationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Set<String> _finalStatuses = {
    'hired',
    'accepted',
    'rejected',
    'cancelled',
  };

  static String _normalize(Object? status) =>
      status?.toString().trim().toLowerCase() ?? '';

  static ApplicationException _friendly(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return ApplicationException(
        'Not allowed by Firestore rules. Update the rules for the '
            'applications collection (see README_STANDALONE.md).',
      );
    }
    return ApplicationException('Something went wrong. Please try again.');
  }

  // ------------------------------------------------------------------
  // 1. APPLICANT asks to cancel
  // ------------------------------------------------------------------
  static Future<void> requestCancellation({
    required String applicationId,
    String? reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApplicationException('Please login first.');

    final ref = _db.collection('applications').doc(applicationId);
    final cleanReason = reason?.trim() ?? '';

    Map<String, dynamic> application;

    try {
      // Transaction: two quick taps can never create two requests.
      application = await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);

        if (!snap.exists) {
          throw ApplicationException('Application was not found.');
        }

        final data = snap.data()!;

        if (data['userId'] != user.uid) {
          throw ApplicationException(
            'You can only cancel your own applications.',
          );
        }

        if (_finalStatuses.contains(_normalize(data['status']))) {
          throw ApplicationException(
            'This application can no longer be cancelled.',
          );
        }

        final existing = data['cancelRequest'];
        if (existing is Map && existing['status'] == 'pending') {
          throw ApplicationException(
            'A cancellation request is already waiting for approval.',
          );
        }

        tx.update(ref, {
          'cancelRequest': {
            'status': 'pending',
            'reason': cleanReason,
            'requestedAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return data;
      });
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }

    // The request is saved. Telling the admin is best effort.
    String? publisherId;
    try {
      final job =
      await _db.collection('jobs').doc('${application['jobId']}').get();
      publisherId = job.data()?['publisherId']?.toString();
    } catch (_) {}

    await NotificationService.instance.notifyCancellationRequested(
      applicationId: applicationId,
      jobId: '${application['jobId'] ?? ''}',
      jobTitle: '${application['jobTitle'] ?? 'a job'}',
      publisherId: publisherId,
      reason: cleanReason,
    );
  }

  // ------------------------------------------------------------------
  // 2. ADMIN approves or declines
  // ------------------------------------------------------------------
  static Future<void> decideCancellation({
    required String applicationId,
    required bool approve,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApplicationException('Please login first.');

    final ref = _db.collection('applications').doc(applicationId);

    Map<String, dynamic> application;

    try {
      application = await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);

        if (!snap.exists) {
          throw ApplicationException('Application was not found.');
        }

        final data = snap.data()!;
        final request = data['cancelRequest'];

        if (request is! Map || request['status'] != 'pending') {
          throw ApplicationException('There is no pending cancellation request.');
        }

        final update = <String, dynamic>{
          'cancelRequest.status': approve ? 'approved' : 'declined',
          'cancelRequest.decidedAt': FieldValue.serverTimestamp(),
          'cancelRequest.decidedBy': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (approve) {
          update['status'] = 'Cancelled';
          update['previousStatus'] = data['status'] ?? 'Applied';
          update['cancelledAt'] = FieldValue.serverTimestamp();
        }

        tx.update(ref, update);
        return data;
      });
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }

    await NotificationService.instance.notifyCancellationDecision(
      applicationId: applicationId,
      applicantUid: '${application['userId'] ?? ''}',
      jobTitle: '${application['jobTitle'] ?? 'the position'}',
      company: '${application['company'] ?? 'the company'}',
      approved: approve,
      currentStatus: approve
          ? 'Cancelled'
          : '${application['status'] ?? 'Applied'}',
    );
  }
}
