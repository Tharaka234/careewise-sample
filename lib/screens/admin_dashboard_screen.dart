import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_job_screen.dart';
import 'package:careerwise_sample/services/notification_service.dart';
import 'admin_broadcast_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_users_screen.dart';
import 'admin_recommendations_screen.dart';

// =====================================================
// DYNAMIC THEME COLOR PALETTE (PREMIUM GREEN THEME)
// =====================================================

class _AdminColors {
  final bool isDark;

  const _AdminColors({required this.isDark});

  // Backgrounds:
  // Light Mode: Fresh, soothing emerald/mint green tint (Tailwind emerald-50 style)
  // Dark Mode: Deep, luxurious obsidian forest green
  Color get pageBg => isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get appBarBg => isDark ? const Color(0xFF0E1B15) : Colors.white;
  Color get appBarBorder => isDark ? const Color(0xFF1A3325) : const Color(0xFFE2EFE7);

  // Brand / Emerald Accent Colors
  Color get primary => isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  Color get primaryAccent => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  Color get primaryDark => isDark ? const Color(0xFF059669) : const Color(0xFF047857);

  // Text Colors
  Color get textPrimary => isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F241B);
  Color get textSecondary => isDark ? const Color(0xFFA7C1B3) : const Color(0xFF4B6354);
  Color get textMuted => isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

  // Dividers & Badges
  Color get divider => isDark ? const Color(0xFF1C3426) : const Color(0xFFE5EFE9);
  Color get badgeBg => isDark ? const Color(0x3310B981) : const Color(0x1F059669);
  Color get badgeText => isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey _jobsSectionKey = GlobalKey();
  final GlobalKey _applicationsSectionKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  // =====================================================
  // CHECK ADMIN
  // =====================================================

  Future<DocumentSnapshot?> _getAdminDocument() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();
  }

  // =====================================================
  // FETCH USER DETAILS FOR CANDIDATE APPLICANTS
  // =====================================================

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    // Dynamic Theme Listener
    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _AdminColors(isDark: isDark);

        return FutureBuilder<DocumentSnapshot?>(
          future: _getAdminDocument(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: colors.pageBg,
                body: Center(
                  child: CircularProgressIndicator(
                    color: colors.primary,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: colors.pageBg,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error checking admin access:\n\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _accessDeniedScreen(
                'You are not an administrator.',
                colors,
              );
            }

            final data =
                snapshot.data!.data() as Map<String, dynamic>?;

            if (data?['role'] != 'admin') {
              return _accessDeniedScreen(
                'You are not an administrator.',
                colors,
              );
            }

            final adminName =
                data?['name']?.toString().trim().isNotEmpty == true
                    ? data!['name'].toString()
                    : 'Admin';

            return _buildDashboard(context, adminName, colors);
          },
        );
      },
    );
  }

  // =====================================================
  // ACCESS DENIED
  // =====================================================

  Widget _accessDeniedScreen(String message, _AdminColors colors) {
    return Scaffold(
      backgroundColor: colors.pageBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: colors.isDark ? 0.3 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Access Denied',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 15,
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

  // =====================================================
  // ADMIN PROFILE
  // =====================================================

  void _showAdminProfile(
    BuildContext context,
    String adminName,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProfileScreen(
          adminName: adminName,
        ),
      ),
    );
  }

  // =====================================================
  // MAIN DASHBOARD
  // =====================================================

  Widget _buildDashboard(
    BuildContext context,
    String adminName,
    _AdminColors colors,
  ) {
    return Scaffold(
      backgroundColor: colors.pageBg,

      // =================================================
      // APP BAR
      // =================================================
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: colors.appBarBg,
        surfaceTintColor: colors.appBarBg,
        titleSpacing: 14,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: colors.appBarBorder,
            height: 1,
          ),
        ),

        // Responsive AppBar title
        title: LayoutBuilder(
          builder: (context, constraints) {
            final showAdminBadge = constraints.maxWidth >= 215;

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors.isDark
                          ? const [Color(0xFF047857), Color(0xFF059669)]
                          : const [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 10),

                Flexible(
                  child: Text(
                    'CareerWise',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                if (showAdminBadge) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.badgeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        color: colors.badgeText,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),

        actions: [
          // Theme Toggle Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            decoration: BoxDecoration(
              color: colors.isDark
                  ? const Color(0x3310B981)
                  : const Color(0x18059669),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: colors.isDark
                  ? 'Switch to Light Theme'
                  : 'Switch to Dark Theme',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  colors.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  key: ValueKey<bool>(colors.isDark),
                  color: colors.isDark ? const Color(0xFFFBBF24) : colors.primary,
                  size: 20,
                ),
              ),
              onPressed: () {
                AdminThemeManager.toggleTheme();
              },
            ),
          ),

          // Admin Profile Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: colors.isDark ? 0.2 : 0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Admin Profile',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {
                _showAdminProfile(
                  context,
                  adminName,
                );
              },
              icon: Icon(
                Icons.person_rounded,
                color: colors.primary,
                size: 20,
              ),
            ),
          ),

          // Broadcast Announcement Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: colors.isDark ? 0.2 : 0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Send announcement',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                Icons.campaign_outlined,
                color: colors.primary,
                size: 22,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminBroadcastScreen(),
                  ),
                );
              },
            ),
          ),

          // Logout Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: colors.isDark ? 0.2 : 0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Logout',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 19,
              ),
              onPressed: () async {
                await NotificationService.instance.onBeforeLogout();
                await FirebaseAuth.instance.signOut();
              },
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // =================================================
      // BODY
      // =================================================
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. WELCOME BANNER
              _welcomeBanner(
                context,
                adminName,
                colors,
              ),

              const SizedBox(height: 28),

              // 2. OVERVIEW SECTION HEADER
              _sectionHeader(
                title: 'Dashboard Overview',
                subtitle: 'Real-time metrics & insights',
                icon: Icons.dashboard_outlined,
                colors: colors,
              ),

              const SizedBox(height: 16),

              // 3. STATISTICS GRID
              _statisticsGrid(colors),

              const SizedBox(height: 34),

              // 4. JOB MANAGEMENT HEADER (WITH LIVE ACTIVE BADGE)
              Container(
                key: _jobsSectionKey,
                child: _sectionHeader(
                  title: 'Job Management',
                  subtitle: 'Manage and publish career opportunities',
                  icon: Icons.work_outline_rounded,
                  colors: colors,
                  streamCollection: 'jobs',
                  countSuffix: 'Active Jobs',
                ),
              ),

              const SizedBox(height: 16),

              // 5. ADD JOB HERO CALLOUT
              _addJobButton(
                context: context,
                colors: colors,
              ),

              const SizedBox(height: 16),

              // 6. JOBS LIST
              _jobsList(context, colors),

              const SizedBox(height: 36),

              // 7. JOB APPLICATIONS HEADER (WITH LIVE APPLICANTS BADGE)
              Container(
                key: _applicationsSectionKey,
                child: _sectionHeader(
                  title: 'Job Applications',
                  subtitle: 'Review applicants & track hiring pipeline',
                  icon: Icons.groups_outlined,
                  colors: colors,
                  streamCollection: 'applications',
                  countSuffix: 'Applicants',
                ),
              ),

              const SizedBox(height: 16),

              // 8. APPLICATIONS LIST
              _applicationsList(colors),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // WELCOME BANNER
  // =====================================================

  Widget _welcomeBanner(
    BuildContext context,
    String adminName,
    _AdminColors colors,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isNarrow ? 20 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors.isDark
                  ? const [
                      Color(0xFF064E3B),
                      Color(0xFF047857),
                      Color(0xFF065F46),
                    ]
                  : const [
                      Color(0xFF065F46),
                      Color(0xFF059669),
                      Color(0xFF10B981),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: colors.isDark ? 0.15 : 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: colors.isDark ? 0.25 : 0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Good to see you 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      adminName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isNarrow ? 26 : 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isNarrow
                          ? 'Manage jobs, applications and career recommendations.'
                          : 'Manage jobs, applications and\ncareer recommendations from here.',
                      maxLines: isNarrow ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Container(
                padding: EdgeInsets.all(
                  isNarrow ? 14 : 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: isNarrow ? 36 : 42,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // SECTION HEADER (WITH OPTIONAL LIVE BADGE)
  // =====================================================

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required _AdminColors colors,
    String? streamCollection,
    String? countSuffix,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: colors.isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        if (streamCollection != null) ...[
          const SizedBox(width: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection(streamCollection).snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.6),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count ${countSuffix ?? ''}'.trim(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // =====================================================
  // STATISTICS GRID
  // =====================================================

  Widget _statisticsGrid(_AdminColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 750 ? 4 : 2;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: constraints.maxWidth >= 750 ? 150 : 154,
          ),
          children: [
            _statCard(
              collection: 'users',
              title: 'Total Users',
              icon: Icons.people_alt_outlined,
              color: colors.isDark
                  ? const Color(0xFF34D399)
                  : const Color(0xFF059669),
              colors: colors,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminUsersScreen(),
                  ),
                );
              },
            ),

            _statCard(
              collection: 'jobs',
              title: 'Total Jobs',
              icon: Icons.work_outline_rounded,
              color: colors.isDark
                  ? const Color(0xFF22D3EE)
                  : const Color(0xFF0891B2),
              colors: colors,
              onTap: () => _scrollToSection(_jobsSectionKey),
            ),

            _statCard(
              collection: 'applications',
              title: 'Applications',
              icon: Icons.description_outlined,
              color: colors.isDark
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFFD97706),
              colors: colors,
              onTap: () => _scrollToSection(_applicationsSectionKey),
            ),

            _statCard(
              collection: 'career_recommendations',
              title: 'AI Recommendations',
              icon: Icons.psychology_outlined,
              color: colors.isDark
                  ? const Color(0xFFC084FC)
                  : const Color(0xFF7C3AED),
              colors: colors,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminRecommendationsScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // STAT CARD
  // =====================================================

  Widget _statCard({
    required String collection,
    required String title,
    required IconData icon,
    required Color color,
    required _AdminColors colors,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        int count = 0;

        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }

        return Container(
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (colors.isDark ? Colors.black : const Color(0xFF059669))
                    .withValues(alpha: colors.isDark ? 0.35 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              mouseCursor: SystemMouseCursors.click,
              splashColor: color.withValues(alpha: 0.14),
              highlightColor: color.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: colors.isDark ? 0.22 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 22,
                          ),
                        ),

                        // Interactive arrow action button
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: colors.isDark ? 0.18 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(
                                alpha: colors.isDark ? 0.3 : 0.22,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_outward_rounded,
                            size: 16,
                            color: color,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    Text(
                      '$count',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.0,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.0,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // ADD JOB HERO ACTION CARD (PREMIUM CALLOUT DESIGN)
  // =====================================================

  Widget _addJobButton({
    required BuildContext context,
    required _AdminColors colors,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.isDark
              ? const [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF065F46)]
              : const [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: colors.isDark ? 0.15 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: colors.isDark ? 0.35 : 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddJobScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_business_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Post a New Career Opportunity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Publish openings & attract qualified talent',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: colors.primaryDark,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Job',
                        style: TextStyle(
                          color: colors.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // JOB LIST
  // =====================================================

  Widget _jobsList(BuildContext context, _AdminColors colors) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingCard(colors);
        }

        if (snapshot.hasError) {
          return _errorCard(
            'Error loading jobs:\n\n${snapshot.error}',
            colors,
          );
        }

        final jobs = snapshot.data?.docs ?? [];

        if (jobs.isEmpty) {
          return _emptyCard(
            icon: Icons.work_off_outlined,
            title: 'No jobs found',
            subtitle: 'Add your first job using the button above.',
            colors: colors,
          );
        }

        return Column(
          children: jobs.map((document) {
            final data = document.data() as Map<String, dynamic>;

            return _jobCard(
              context,
              document.id,
              data,
              colors,
            );
          }).toList(),
        );
      },
    );
  }

  // =====================================================
  // JOB CARD (REDESIGNED PREMIUM EXECUTIVE VIEW)
  // =====================================================

  Widget _jobCard(
    BuildContext context,
    String jobId,
    Map<String, dynamic> data,
    _AdminColors colors,
  ) {
    final title = data['title']?.toString() ?? 'Unknown Job';
    final company = data['company']?.toString() ?? 'Unknown Company';
    final location = data['location']?.toString() ?? 'Unknown Location';
    final salary = data['salary']?.toString() ?? 'Salary not specified';
    final jobType = data['jobType']?.toString() ?? 'Full Time';
    final description = data['description']?.toString() ?? '';

    // Company Avatar Initial
    final initial = company.trim().isNotEmpty
        ? company.trim()[0].toUpperCase()
        : (title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : 'J');

    // Job type color & dot indicator
    Color jobTypeColor = colors.primary;
    if (jobType.toLowerCase().contains('part')) {
      jobTypeColor = const Color(0xFFF59E0B);
    } else if (jobType.toLowerCase().contains('remote')) {
      jobTypeColor = const Color(0xFF8B5CF6);
    } else if (jobType.toLowerCase().contains('contract')) {
      jobTypeColor = const Color(0xFF06B6D4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (colors.isDark ? Colors.black : const Color(0xFF059669))
                .withValues(alpha: colors.isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left decorative accent bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.primary,
                      colors.primaryAccent,
                    ],
                  ),
                ),
              ),

              // Main Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Avatar, Title & Job Type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Company Initial Avatar
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: colors.isDark
                                    ? const [Color(0xFF064E3B), Color(0xFF059669)]
                                    : const [Color(0xFF059669), Color(0xFF10B981)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      size: 15,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        company,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Job Type Pill with glowing indicator dot
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: jobTypeColor.withValues(alpha: colors.isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: jobTypeColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: jobTypeColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: jobTypeColor.withValues(alpha: 0.6),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  jobType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: jobTypeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Location & Salary Pills
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _featurePill(
                            icon: Icons.location_on_rounded,
                            label: location,
                            iconColor: colors.primary,
                            colors: colors,
                          ),
                          _featurePill(
                            icon: Icons.payments_rounded,
                            label: salary,
                            iconColor: const Color(0xFF10B981),
                            colors: colors,
                          ),
                        ],
                      ),

                      // Description Container
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.isDark
                                ? const Color(0xFF0F1E17)
                                : const Color(0xFFF7FAF8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              height: 1.45,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      Divider(color: colors.divider, height: 1),

                      const SizedBox(height: 12),

                      // Action Buttons (Edit & Delete - Perfectly Aligned & Modern)
                      Row(
                        children: [
                          // 1. EDIT JOB BUTTON
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: colors.isDark
                                      ? [
                                          const Color(0xFF064E3B).withValues(alpha: 0.35),
                                          const Color(0xFF10B981).withValues(alpha: 0.18),
                                        ]
                                      : [
                                          const Color(0xFF059669).withValues(alpha: 0.12),
                                          const Color(0xFF10B981).withValues(alpha: 0.06),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colors.primary.withValues(
                                    alpha: colors.isDark ? 0.45 : 0.35,
                                  ),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primary.withValues(
                                      alpha: colors.isDark ? 0.15 : 0.08,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _editJob(context, jobId, data),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 17,
                                          color: colors.primary,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          'Edit Job',
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 2. DELETE BUTTON
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: colors.isDark
                                      ? [
                                          Colors.redAccent.withValues(alpha: 0.28),
                                          Colors.redAccent.withValues(alpha: 0.14),
                                        ]
                                      : [
                                          Colors.redAccent.withValues(alpha: 0.12),
                                          Colors.redAccent.withValues(alpha: 0.06),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(
                                    alpha: colors.isDark ? 0.45 : 0.35,
                                  ),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(
                                      alpha: colors.isDark ? 0.15 : 0.08,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _confirmDeleteJob(
                                    context,
                                    jobId,
                                    title,
                                    colors,
                                  ),
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        SizedBox(width: 7),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // FEATURE PILL HELPER
  // =====================================================

  Widget _featurePill({
    required IconData icon,
    required String label,
    required Color iconColor,
    required _AdminColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.isDark
            ? const Color(0xFF0F1E17)
            : const Color(0xFFF4F9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EDIT JOB
  // =====================================================

  Future<void> _editJob(
    BuildContext context,
    String jobId,
    Map<String, dynamic> data,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddJobScreen(
          jobId: jobId,
          existingJob: data,
        ),
      ),
    );
  }

  // =====================================================
  // DELETE CONFIRMATION
  // =====================================================

  void _confirmDeleteJob(
    BuildContext context,
    String jobId,
    String jobTitle,
    _AdminColors colors,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: colors.cardBorder, width: 1.2),
          ),
          title: Text(
            'Delete Job?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$jobTitle"?\n\nThis action cannot be undone.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _deleteJob(
                  context,
                  jobId,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // DELETE JOB
  // =====================================================

  Future<void> _deleteJob(
    BuildContext context,
    String jobId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job deleted successfully.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete job:\n$e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // =====================================================
  // APPLICATION LIST
  // =====================================================

  Widget _applicationsList(_AdminColors colors) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingCard(colors);
        }

        if (snapshot.hasError) {
          return _errorCard(
            'Error loading applications:\n\n${snapshot.error}',
            colors,
          );
        }

        final applications = snapshot.data?.docs ?? [];

        if (applications.isEmpty) {
          return _emptyCard(
            icon: Icons.description_outlined,
            title: 'No applications yet',
            subtitle:
                'Applications will appear here when users apply for jobs.',
            colors: colors,
          );
        }

        return Column(
          children: applications.map((document) {
            final data = document.data() as Map<String, dynamic>;

            return _applicationCard(
              context,
              document.id,
              data,
              colors,
            );
          }).toList(),
        );
      },
    );
  }

  // =====================================================
  // APPLICATION CARD (REDESIGNED CANDIDATE PIPELINE VIEW)
  // =====================================================

  Widget _applicationCard(
    BuildContext context,
    String applicationId,
    Map<String, dynamic> data,
    _AdminColors colors,
  ) {
    final jobTitle = data['jobTitle']?.toString() ?? 'Unknown Job';
    final company = data['company']?.toString() ?? 'Unknown Company';
    final userId = data['userId']?.toString() ?? 'Unknown User';
    final status = data['status']?.toString() ?? 'Applied';
    final appliedAt =
        data['appliedAt'] is Timestamp ? data['appliedAt'] as Timestamp : null;

    // Status Accent Color for indicator & accent bar
    Color statusColor = const Color(0xFF3B82F6);
    switch (status.toLowerCase()) {
      case 'under review':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'shortlisted':
        statusColor = const Color(0xFF8B5CF6);
        break;
      case 'interview':
      case 'interviewed':
        statusColor = const Color(0xFF06B6D4);
        break;
      case 'accepted':
      case 'hired':
        statusColor = const Color(0xFF10B981);
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (colors.isDark ? Colors.black : const Color(0xFF059669))
                .withValues(alpha: colors.isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status accent bar
              Container(
                width: 5,
                color: statusColor,
              ),

              // Main Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Header & Status Chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(
                                alpha: colors.isDark ? 0.22 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.assignment_ind_rounded,
                              color: statusColor,
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 13),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jobTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      size: 14,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        company,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          _statusChip(status, colors),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Candidate Identity Card (Name, Avatar, Email, UID)
                      _applicantIdentityBox(context, userId, colors),

                      const SizedBox(height: 12),

                      // Recruitment Pipeline Visual Tracker
                      _buildApplicationPipeline(status, colors),

                      const SizedBox(height: 12),

                      // Applied Date row
                      if (appliedAt != null)
                        Row(
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 15,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Submitted on ${_formatDate(appliedAt)}',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 14),

                      // Action Button to update status
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary.withValues(
                              alpha: colors.isDark ? 0.16 : 0.08,
                            ),
                            foregroundColor: colors.primary,
                            elevation: 0,
                            side: BorderSide(
                              color: colors.primary.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () {
                            _showStatusDialog(
                              context,
                              applicationId,
                              status,
                              colors,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Update Application Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: colors.primary,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: colors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // APPLICANT IDENTITY CARD (FETCHES CANDIDATE NAME/EMAIL)
  // =====================================================

  Widget _applicantIdentityBox(
    BuildContext context,
    String userId,
    _AdminColors colors,
  ) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(userId),
      builder: (context, snapshot) {
        String displayName = 'Candidate';
        String email = '';
        String initials = 'C';

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          final first = (data['firstName'] ?? '').toString().trim();
          final last = (data['lastName'] ?? '').toString().trim();
          final fullName = '$first $last'.trim();
          if (fullName.isNotEmpty) {
            displayName = fullName;
            if (first.isNotEmpty && last.isNotEmpty) {
              initials = '${first[0]}${last[0]}'.toUpperCase();
            } else if (first.isNotEmpty) {
              initials = first[0].toUpperCase();
            }
          }
          email = (data['email'] ?? '').toString().trim();
        } else {
          final shortId = userId.length > 8 ? userId.substring(0, 8) : userId;
          displayName = 'Applicant #$shortId';
          if (userId.isNotEmpty) {
            initials = userId[0].toUpperCase();
          }
        }

        final shortId = userId.length > 8 ? userId.substring(0, 8) : userId;

        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: colors.isDark ? const Color(0xFF0F1E17) : const Color(0xFFF7FAF8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: colors.cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with Initials
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors.isDark
                        ? const [Color(0xFF047857), Color(0xFF10B981)]
                        : const [Color(0xFF059669), Color(0xFF34D399)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Name, Email / Phone, UID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'APPLICANT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    if (email.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            size: 13,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],

                    Row(
                      children: [
                        Icon(
                          Icons.fingerprint_rounded,
                          size: 13,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'ID: $shortId...',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: userId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Applicant ID copied: $userId'),
                                backgroundColor: const Color(0xFF10B981),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
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

  // =====================================================
  // RECRUITMENT PIPELINE STEPPER
  // =====================================================

  Widget _buildApplicationPipeline(String status, _AdminColors colors) {
    int currentStep = 1;
    bool isRejected = false;
    final lower = status.toLowerCase();

    if (lower == 'under review') {
      currentStep = 2;
    } else if (lower == 'shortlisted' || lower.contains('interview')) {
      currentStep = 3;
    } else if (lower == 'hired' || lower == 'accepted') {
      currentStep = 4;
    } else if (lower == 'rejected') {
      currentStep = 4;
      isRejected = true;
    }

    final steps = ['Applied', 'Review', 'Interview', isRejected ? 'Rejected' : 'Hired'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF0C1712) : const Color(0xFFF4F9F5),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: colors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = (index ~/ 2) + 1;
            final isPassed = currentStep > stepBefore;
            return Expanded(
              child: Container(
                height: 2,
                color: isPassed
                    ? (isRejected ? Colors.redAccent : colors.primary)
                    : (colors.isDark ? const Color(0xFF1F382B) : const Color(0xFFD8EBE0)),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final stepNum = stepIndex + 1;
          final isDone = currentStep >= stepNum;
          final isCurrent = currentStep == stepNum;

          Color stepColor;
          if (isCurrent && isRejected) {
            stepColor = Colors.redAccent;
          } else if (isDone) {
            stepColor = colors.primary;
          } else {
            stepColor = colors.isDark ? const Color(0xFF274435) : const Color(0xFFCBD5E1);
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isDone ? stepColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: stepColor, width: 1.8),
                ),
                child: Center(
                  child: isDone
                      ? Icon(
                          (isCurrent && isRejected)
                              ? Icons.close_rounded
                              : Icons.check_rounded,
                          size: 10,
                          color: Colors.white,
                        )
                      : Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: stepColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? (isRejected ? Colors.redAccent : colors.primary)
                      : (isDone ? colors.textPrimary : colors.textSecondary),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // =====================================================
  // STATUS CHIP (GLOWING STATUS DOT & MODERN BADGE)
  // =====================================================

  Widget _statusChip(String status, _AdminColors colors) {
    Color color = Colors.blue;
    IconData icon = Icons.schedule_rounded;

    switch (status.toLowerCase()) {
      case 'under review':
        color = const Color(0xFFF59E0B);
        icon = Icons.visibility_outlined;
        break;

      case 'shortlisted':
        color = const Color(0xFF8B5CF6);
        icon = Icons.star_outline_rounded;
        break;

      case 'interview':
      case 'interviewed':
        color = const Color(0xFF06B6D4);
        icon = Icons.groups_outlined;
        break;

      case 'accepted':
      case 'hired':
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_outline_rounded;
        break;

      case 'rejected':
        color = const Color(0xFFEF4444);
        icon = Icons.cancel_outlined;
        break;

      case 'applied':
      default:
        color = const Color(0xFF3B82F6);
        icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: colors.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: colors.isDark ? 0.45 : 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // STATUS DIALOG
  // =====================================================

  void _showStatusDialog(
    BuildContext context,
    String applicationId,
    String currentStatus,
    _AdminColors colors,
  ) {
    final statuses = [
      'Applied',
      'Under Review',
      'Shortlisted',
      'Interviewed',
      'Hired',
      'Rejected',
    ];

    String initialStatus = currentStatus;

    if (currentStatus == 'Interview') {
      initialStatus = 'Interviewed';
    }

    if (currentStatus == 'Accepted') {
      initialStatus = 'Hired';
    }

    if (!statuses.contains(initialStatus)) {
      initialStatus = 'Applied';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        String selectedStatus = initialStatus;

        return StatefulBuilder(
          builder: (
            context,
            setState,
          ) {
            return AlertDialog(
              backgroundColor: colors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: colors.cardBorder, width: 1.2),
              ),
              title: Text(
                'Update Application Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontSize: 18,
                ),
              ),
              content: DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                isExpanded: true,
                dropdownColor: colors.cardBg,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Application Status',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                ),
                items: statuses.map(
                  (status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('applications')
                          .doc(applicationId)
                          .update({
                        'status': selectedStatus,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Application status updated successfully.',
                          ),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to update status:\n$e',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================================================
  // LOADING CARD
  // =====================================================

  Widget _loadingCard(_AdminColors colors) {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder, width: 1.2),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: colors.primary,
        ),
      ),
    );
  }

  // =====================================================
  // ERROR CARD
  // =====================================================

  Widget _errorCard(String message, _AdminColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: colors.isDark ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  // =====================================================
  // EMPTY CARD
  // =====================================================

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required _AdminColors colors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 46,
            color: colors.isDark
                ? const Color(0xFF335242)
                : const Color(0xFFA7C1B3),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DATE FORMAT
  // =====================================================

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
