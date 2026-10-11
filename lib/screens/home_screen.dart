import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:careerwise_sample/model/job.dart';
import 'package:careerwise_sample/services/job_service.dart';

import 'job_details_screen.dart';
import 'jobs_screen.dart';
import 'career_advisor_screen.dart';
import 'career_history_screen.dart';
import 'my_applications_screen.dart';
import 'profile_screen.dart';
import 'notification_settings_screen.dart';
import 'notification_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _primary = Color(0xFF2563EB);
  static const Color _indigo = Color(0xFF4F46E5);
  static const Color _dark = Color(0xFF111827);
  static const Color _grey = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    final String userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Career Explorer';

    final String initial =
    userName.isNotEmpty ? userName[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      bottomNavigationBar: _buildBottomNav(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width >= 700 ? 32 : 16,
            14,
            MediaQuery.of(context).size.width >= 700 ? 32 : 16,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, initial),
                  const SizedBox(height: 16),
                  _buildHero(context, userName),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    'Quick Actions',
                    trailing: 'Your career journey, in one place',
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildFeaturedHeader(context),
                  const SizedBox(height: 12),
                  _buildFeaturedJobs(),
                  const SizedBox(height: 20),
                  _buildCtaBanner(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================
  Widget _buildHeader(BuildContext context, String initial) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CareerWise',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your AI Career Companion',
                style: TextStyle(fontSize: 12, color: _grey),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => _open(
                    context, const NotificationHistoryScreen()),
                tooltip: 'Notification history',
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF374151),
                ),
              ),
            ),

          ],
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _open(context, const ProfileScreen()),
          child: Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFC7D2FE),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_primary, _indigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // HERO BANNER  (responsive: mobile + tablet + desktop)
  // ================================================================
  static const String _heroImage = 'assets/images/hero_student.jpg';

  Widget _buildHero(BuildContext context, String userName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final bool wide = w >= 700;

        final double height = wide ? 250 : 190;
        // image takes a fixed share of the banner width
        final double imageWidth = wide ? w * 0.36 : w * 0.36;

        return Container(
          height: height,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFDBEAFE),
                Color(0xFFC7D2FE),
                Color(0xFFDDD6FE),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Image fills the whole right side and fades into the gradient
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: imageWidth,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.0, 0.4],
                  ).createShader(rect),
                  child: Image.asset(
                    _heroImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.school_rounded,
                        size: wide ? 110 : 80,
                        color: _primary.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),

              // Text
              Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 18,
                  16,
                  imageWidth * 0.85,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hello, $userName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: wide ? 17 : 14,
                        fontWeight: FontWeight.w500,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Good to see you 👋',
                        style: TextStyle(
                          fontSize: wide ? 34 : 22,
                          fontWeight: FontWeight.w800,
                          color: _dark,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Take the next step towards your dream career with CareerWise.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: wide ? 15 : 12,
                        color: _grey,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: wide ? 18 : 12),
                    GestureDetector(
                      onTap: () =>
                          _open(context, const CareerAdvisorScreen()),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 20 : 14,
                          vertical: wide ? 13 : 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primary, _indigo],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Explore Career Paths',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: wide ? 14 : 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: wide ? 18 : 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // SECTION TITLE
  // ================================================================
  Widget _buildSectionTitle(String title, {String? trailing}) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 26,
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_primary, _indigo]),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              trailing,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: _grey),
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.arrow_forward_rounded, size: 14, color: _grey),
        ],
      ],
    );
  }

  // ================================================================
  // QUICK ACTIONS
  // ================================================================
  Widget _buildQuickActions(BuildContext context) {
    final items = <Widget>[
      _quickAction(
        context,
        icon: Icons.smart_toy_outlined,
        title: 'AI Career Advisor',
        subtitle: 'Get personalized career recommendations',
        color: _primary,
        tint: const Color(0xFFEFF6FF),
        page: const CareerAdvisorScreen(),
      ),
      _quickAction(
        context,
        icon: Icons.work_outline_rounded,
        title: 'Browse Jobs',
        subtitle: 'Find opportunities that match you',
        color: const Color(0xFF7C3AED),
        tint: const Color(0xFFF5F3FF),
        page: const JobsScreen(),
      ),
      _quickAction(
        context,
        icon: Icons.history_rounded,
        title: 'Career History',
        subtitle: 'View your past recommendations',
        color: const Color(0xFF10B981),
        tint: const Color(0xFFECFDF5),
        page: const CareerHistoryScreen(),
      ),
      _quickAction(
        context,
        icon: Icons.description_outlined,
        title: 'My Applications',
        subtitle: 'Track your job applications',
        color: const Color(0xFFF97316),
        tint: const Color(0xFFFFF7ED),
        page: const MyApplicationsScreen(),
      ),
      _quickAction(
        context,
        icon: Icons.tune_rounded,
        title: 'Notification Settings',
        subtitle: 'Manage your alerts and reminders',
        color: const Color(0xFF0D9488),
        tint: const Color(0xFFF0FDFA),
        page: const NotificationSettingsScreen(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // very narrow phones -> 2 x 2 grid, otherwise 4 in a row
        final int columns = constraints.maxWidth < 600 ? 2 : 4;
        final double gap = constraints.maxWidth >= 700 ? 14 : 8;

        final rows = <Widget>[];
        for (int i = 0; i < items.length; i += columns) {
          final rowItems = items.skip(i).take(columns).toList();
          final children = <Widget>[];
          for (int j = 0; j < rowItems.length; j++) {
            if (j > 0) children.add(SizedBox(width: gap));
            children.add(Expanded(child: rowItems[j]));
          }
          if (i > 0) rows.add(SizedBox(height: gap));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }

  Widget _quickAction(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required Color tint,
        required Widget page,
      }) {
    return GestureDetector(
      onTap: () => _open(context, page),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _dark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: _grey, height: 1.3),
            ),
            const Spacer(),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 13, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // FEATURED JOBS
  // ================================================================
  Widget _buildFeaturedHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.business_center_outlined, color: _primary, size: 26),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Featured Jobs',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _open(context, const JobsScreen()),
          child: const Row(
            children: [
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded, color: _primary, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedJobs() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _messageCard('Please login to see recommended jobs.');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _latestRecommendationStream(),
      builder: (context, recSnap) {
        if (recSnap.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (recSnap.hasError) {
          return _messageCard('Unable to load your career recommendation.');
        }
        if (!recSnap.hasData || recSnap.data!.docs.isEmpty) {
          return _messageCard(
            'Complete the AI Career Advisor to discover jobs that match your career path.',
          );
        }

        final latest = _getLatestRecommendation(recSnap.data!);
        if (latest == null) {
          return _messageCard(
            'Complete the AI Career Advisor to discover jobs that match your career path.',
          );
        }

        final data = latest.data() as Map<String, dynamic>;
        final career = _getCareerFromRecommendation(data['recommendation']);

        if (career == null || career.isEmpty) {
          return _messageCard(
            'Complete the AI Career Advisor to discover jobs that match your career path.',
          );
        }

        return StreamBuilder<List<Job>>(
          stream: JobService().getRelatedJobs(career),
          builder: (context, jobSnap) {
            if (jobSnap.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }
            if (jobSnap.hasError) {
              return _messageCard('Unable to load recommended jobs.');
            }

            final jobs = (jobSnap.data ?? []).take(5).toList();

            if (jobs.isEmpty) {
              return _messageCard('No jobs found for $career yet.');
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;

                // Desktop / tablet: cards share the row equally
                if (w >= 700) {
                  final shown = jobs.take(3).toList();
                  return SizedBox(
                    height: 160,
                    child: Row(
                      children: [
                        for (int i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 14),
                          Expanded(
                            child: i < shown.length
                                ? _buildJobCard(context, shown[i], i)
                                : const SizedBox(),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Mobile: horizontal scroll
                final double cardWidth = w * 0.72;
                return SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => SizedBox(
                      width: cardWidth,
                      child: _buildJobCard(context, jobs[i], i),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildJobCard(BuildContext context, Job job, int index) {
    const chipColors = [
      [Color(0xFFEFF6FF), Color(0xFF2563EB)],
      [Color(0xFFF5F3FF), Color(0xFF7C3AED)],
      [Color(0xFFECFDF5), Color(0xFF059669)],
    ];
    final c = chipColors[index % chipColors.length];
    final company = job.company.trim();
    final letter = company.isNotEmpty ? company[0].toUpperCase() : 'J';

    return GestureDetector(
      onTap: () => _open(context, JobDetailsScreen(job: job)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c[0],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: c[1],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c[0],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.jobType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: c[1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              job.company,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _grey),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    job.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _grey),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c[0],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 15, color: c[1]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }

  Widget _messageCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: _grey, height: 1.4),
      ),
    );
  }

  // ================================================================
  // CTA BANNER
  // ================================================================
  Widget _buildCtaBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF93C5FD)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready for your next step?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Get AI-powered career advice tailored just for you.',
                  style: TextStyle(color: Colors.white, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _open(context, const CareerAdvisorScreen()),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get Started',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 13, color: _primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SizedBox(
              height: 66,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _navItem(Icons.home_rounded, 'Home', true, () {}),
                      ),
                      Expanded(
                        child: _navItem(
                          Icons.work_outline_rounded,
                          'Jobs',
                          false,
                              () => _open(context, const JobsScreen()),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      Expanded(
                        child: _navItem(
                          Icons.history_rounded,
                          'History',
                          false,
                              () => _open(context, const CareerHistoryScreen()),
                        ),
                      ),
                      Expanded(
                        child: _navItem(
                          Icons.person_outline_rounded,
                          'Profile',
                          false,
                              () => _open(context, const ProfileScreen()),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: -24,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _open(context, const CareerAdvisorScreen()),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 5),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [_primary, Color(0xFF7C3AED)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'AI',
                          style: TextStyle(fontSize: 11, color: _grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      IconData icon,
      String label,
      bool active,
      VoidCallback onTap,
      ) {
    final color = active ? _primary : const Color(0xFF9CA3AF);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // FIRESTORE HELPERS
  // ================================================================
  Stream<QuerySnapshot> _latestRecommendationStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('career_recommendations')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  QueryDocumentSnapshot? _getLatestRecommendation(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) {
      return null;
    }

    final documents = List<QueryDocumentSnapshot>.from(snapshot.docs);

    documents.sort((a, b) {
      final tsA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
      final tsB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;

      if (tsA == null && tsB == null) return 0;
      if (tsA == null) return 1;
      if (tsB == null) return -1;

      return tsB.compareTo(tsA);
    });

    return documents.first;
  }

  Map<String, dynamic>? _parseRecommendation(dynamic value) {
    if (value == null) return null;

    try {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      if (value is String) {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String? _getCareerFromRecommendation(dynamic recommendation) {
    final parsed = _parseRecommendation(recommendation);
    if (parsed == null) return null;

    final careers = parsed['careers'];

    if (careers is List && careers.isNotEmpty) {
      final first = careers.first;
      if (first is Map && first['title'] != null) {
        final career = first['title'].toString().trim();
        if (career.isNotEmpty) return career;
      }
    }

    return null;
  }
}
