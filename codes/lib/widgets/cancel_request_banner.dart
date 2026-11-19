import 'package:flutter/material.dart';

import '../services/application_service.dart';

const _amber = Color(0xFFD97706);
const _grey = Color(0xFF6B7280);

bool _isFinal(String status) {
  const finals = {'hired', 'accepted', 'rejected', 'cancelled'};
  return finals.contains(status.trim().toLowerCase());
}

/// Shown on the ADMIN application card when the applicant asked to cancel.
/// The admin decides: Approve -> application becomes "Cancelled",
/// Decline -> the application stays active. Either way the applicant is told.
class CancelRequestBanner extends StatefulWidget {
  const CancelRequestBanner({
    super.key,
    required this.applicationId,
    required this.data,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
  });

  final String applicationId;
  final Map<String, dynamic> data;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;

  @override
  State<CancelRequestBanner> createState() => _CancelRequestBannerState();
}

class _CancelRequestBannerState extends State<CancelRequestBanner> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve cancellation?' : 'Decline request?'),
        content: Text(
          approve
              ? 'The application will be marked as Cancelled and the applicant will be notified.'
              : 'The application stays active and the applicant will be notified that the request was declined.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              approve ? const Color(0xFF059669) : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Yes, approve' : 'Yes, decline'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    String message;
    var failed = false;

    try {
      await ApplicationService.decideCancellation(
        applicationId: widget.applicationId,
        approve: approve,
      );
      message = approve
          ? 'Cancellation approved. The applicant was notified.'
          : 'Request declined. The applicant was notified.';
    } on ApplicationException catch (e) {
      message = e.message;
      failed = true;
    } catch (_) {
      message = 'Could not save your decision. Please try again.';
      failed = true;
    }

    if (!mounted) return;
    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        failed ? const Color(0xFFDC2626) : const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status']?.toString() ?? 'Applied';
    final request = widget.data['cancelRequest'];

    if (request is! Map ||
        request['status'] != 'pending' ||
        _isFinal(status)) {
      return const SizedBox.shrink();
    }

    final reason = request['reason']?.toString().trim() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: widget.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_busy_outlined, color: _amber, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CANCELLATION REQUESTED',
                  style: TextStyle(
                    color: _amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The applicant wants to cancel this application.',
            style: TextStyle(
              color: widget.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: $reason',
              style: TextStyle(
                color: widget.mutedColor,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _decide(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: BorderSide(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _decide(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Replaces the hiring pipeline on the admin card once an application is cancelled.
class CancelledApplicationNotice extends StatelessWidget {
  const CancelledApplicationNotice({
    super.key,
    required this.isDark,
    required this.textColor,
  });

  final bool isDark;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _grey.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _grey.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy_outlined, color: _grey, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cancelled by the applicant (approved).',
              style: TextStyle(
                color: textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
