
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:careerwise_sample/model/job.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;

  const JobDetailsScreen({
    super.key,
    required this.job,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  static const Color primary = Color(0xFF2563EB);
  static const Color deepBlue = Color(0xFF173B8F);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color background = Color(0xFFF5F7FC);
  static const Color dark = Color(0xFF17233C);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE7ECF4);

  bool isApplying = false;
  bool hasApplied = false;
  bool isChecking = true;
  String? statusError;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => isChecking = false);
      }
      return;
    }

    try {
      final result = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .where('jobId', isEqualTo: widget.job.id)
          .limit(1)
          .get();

      if (!mounted) return;

      setState(() {
        hasApplied = result.docs.isNotEmpty;
        isChecking = false;
        statusError = null;
      });
    } catch (e) {
      debugPrint('Application check error: $e');

      if (!mounted) return;

      setState(() {
        isChecking = false;
        statusError = 'Unable to check your application status.';
      });
    }
  }

  Future<void> _confirmApplication() async {
    if (isApplying || hasApplied || isChecking || statusError != null) {
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      _showSnackBar('Please log in before applying.', error: true);
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: primary,
                    size: 31,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ready to apply?',
                  style: TextStyle(
                    color: dark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'You are about to submit your application for this opportunity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.job.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: dark,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.job.company,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          foregroundColor: dark,
                          side: const BorderSide(color: border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext, true),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Confirm Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      await _applyForJob();
    }
  }

  Future<void> _applyForJob() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || isApplying || hasApplied) return;

    setState(() => isApplying = true);

    try {
      final existing = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .where('jobId', isEqualTo: widget.job.id)
          .limit(1)
          .get();

      if (!mounted) return;

      if (existing.docs.isNotEmpty) {
        setState(() {
          hasApplied = true;
          isApplying = false;
        });

        _showSnackBar('You have already applied for this job.');
        return;
      }

      await FirebaseFirestore.instance
          .collection('applications')
          .add({
        'userId': user.uid,
        'jobId': widget.job.id,
        'jobTitle': widget.job.title,
        'company': widget.job.company,
        'status': 'Applied',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        hasApplied = true;
        isApplying = false;
      });

      _showSnackBar('Application submitted successfully!');
    } catch (e) {
      debugPrint('Apply job error: $e');

      if (!mounted) return;

      setState(() => isApplying = false);

      _showSnackBar(
        'Could not submit your application. Please try again.',
        error: true,
      );
    }
  }

  void _showSnackBar(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          error ? const Color(0xFFDC2626) : const Color(0xFF15803D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: dark,
            size: 19,
          ),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(
            color: dark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 17),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: primary,
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'CareerWise',
                    style: TextStyle(
                      color: primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 25),
                _sectionHeader(
                  'Job Overview',
                  'Everything you need to know at a glance',
                ),
                const SizedBox(height: 14),
                _buildOverview(),
                const SizedBox(height: 25),
                _sectionHeader(
                  'About This Position',
                  'Discover more about this opportunity',
                ),
                const SizedBox(height: 14),
                _buildDescription(),
                const SizedBox(height: 20),
                _buildStatusCard(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildApplyBar(),
    );
  }

  Widget _buildHeroCard() {
    final job = widget.job;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepBlue,
            primary,
            indigo,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -75,
              right: -50,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -85,
              right: 65,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.045),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                          ),
                        ),
                        child: const Icon(
                          Icons.business_center_rounded,
                          color: Colors.white,
                          size: 31,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'JOB OPPORTUNITY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    job.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        color: Color(0xFFE4EDFF),
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          job.company,
                          style: const TextStyle(
                            color: Color(0xFFE4EDFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFE4EDFF),
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          job.location.trim().isEmpty
                              ? 'Location not specified'
                              : job.location,
                          style: const TextStyle(
                            color: Color(0xFFE4EDFF),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Text(
                      job.jobType.trim().isEmpty
                          ? 'Employment opportunity'
                          : job.jobType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: dark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoCard(
                Icons.schedule_rounded,
                'Employment',
                widget.job.jobType,
                const Color(0xFFEEF4FF),
                primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                Icons.payments_outlined,
                'Salary',
                widget.job.salary,
                const Color(0xFFECFDF5),
                const Color(0xFF059669),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _infoCard(
          Icons.location_on_outlined,
          'Work Location',
          widget.job.location,
          const Color(0xFFF4EEFF),
          const Color(0xFF7C3AED),
          horizontal: true,
        ),
      ],
    );
  }

  Widget _infoCard(
      IconData icon,
      String label,
      String value,
      Color iconBg,
      Color iconColor, {
        bool horizontal = false,
      }) {
    final iconBox = Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );

    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.trim().isEmpty ? 'Not specified' : value,
          style: const TextStyle(
            color: dark,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: dark.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: horizontal
          ? Row(
        children: [
          iconBox,
          const SizedBox(width: 14),
          Expanded(child: textContent),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconBox,
          const SizedBox(height: 14),
          textContent,
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final description = widget.job.description.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: dark.withOpacity(0.025),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: primary,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Role Description',
                style: TextStyle(
                  color: dark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: border),
          const SizedBox(height: 17),
          SelectableText(
            description.isEmpty
                ? 'No description has been provided for this position.'
                : description,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13.5,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (isChecking) {
      return _noticeCard(
        Icons.hourglass_top_rounded,
        'Checking application status',
        'Please wait while we check your application.',
        const Color(0xFFEEF4FF),
        primary,
      );
    }

    if (statusError != null) {
      return Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFB45309),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                statusError!,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isChecking = true;
                  statusError = null;
                });
                _checkApplicationStatus();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (hasApplied) {
      return _noticeCard(
        Icons.check_circle_rounded,
        'Application Submitted',
        'You have already applied for this opportunity. Track your progress in My Applications.',
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
      );
    }

    return _noticeCard(
      Icons.auto_awesome_rounded,
      'Your next opportunity starts here',
      'Review the job details and submit your application when you are ready.',
      const Color(0xFFEEF4FF),
      primary,
    );
  }

  Widget _noticeCard(
      IconData icon,
      String title,
      String subtitle,
      Color cardColor,
      Color iconColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: border),
          ),
          boxShadow: [
            BoxShadow(
              color: dark.withOpacity(0.045),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: isApplying ||
                    isChecking ||
                    hasApplied ||
                    statusError != null
                    ? null
                    : _confirmApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: hasApplied
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFDBEAFE),
                  disabledForegroundColor: hasApplied
                      ? const Color(0xFF047857)
                      : deepBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                icon: isChecking || isApplying
                    ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : Icon(
                  hasApplied
                      ? Icons.check_circle_rounded
                      : Icons.send_rounded,
                  size: 20,
                ),
                label: Text(
                  isChecking
                      ? 'Checking Application...'
                      : isApplying
                      ? 'Submitting Application...'
                      : hasApplied
                      ? 'Already Applied'
                      : statusError != null
                      ? 'Retry Status Check Above'
                      : 'Apply for this Job',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
