import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_profile_screen.dart';
import 'career_advisor_screen.dart';

// ==========================================================
// DYNAMIC THEME COLOR PALETTE (PREMIUM GREEN THEME)
// ==========================================================

class _RecColors {
  final bool isDark;

  const _RecColors({required this.isDark});

  Color get pageBg => isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get cardSurface => isDark ? const Color(0xFF0F1E17) : const Color(0xFFF8FAF9);

  // Brand / Emerald Accents
  Color get primary => isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  Color get primaryAccent => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  Color get primaryDark => isDark ? const Color(0xFF059669) : const Color(0xFF047857);

  // Text Colors
  Color get textPrimary => isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F241B);
  Color get textSecondary => isDark ? const Color(0xFFA7C1B3) : const Color(0xFF4B6354);
  Color get textMuted => isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

  // Icon Boxes & Badges
  Color get iconBoxBg => isDark ? const Color(0x3310B981) : const Color(0x1F059669);
}

class AdminRecommendationsScreen extends StatefulWidget {
  const AdminRecommendationsScreen({super.key});

  @override
  State<AdminRecommendationsScreen> createState() =>
      _AdminRecommendationsScreenState();
}

class _AdminRecommendationsScreenState
    extends State<AdminRecommendationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedDocIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _RecColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('career_recommendations')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              final allDocs = snapshot.data?.docs ?? [];
              final filteredDocs = _filterRecommendations(allDocs);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      colors: colors,
                      totalCount: allDocs.length,
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search Bar & Launch Advisor Banner
                              _buildSearchAndAdvisorBanner(colors),

                              const SizedBox(height: 20),

                              // Content list
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData)
                                _loadingCard(colors)
                              else if (snapshot.hasError)
                                _errorCard(
                                  'Error loading recommendations: ${snapshot.error}',
                                  colors,
                                )
                              else if (filteredDocs.isEmpty)
                                _emptyCard(
                                  title: _searchQuery.isEmpty
                                      ? 'No AI recommendations found'
                                      : 'No matching recommendations',
                                  subtitle: _searchQuery.isEmpty
                                      ? 'AI career advice assessments will appear here as users explore.'
                                      : 'Try searching with a different career goal, skill or education.',
                                  colors: colors,
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredDocs.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final doc = filteredDocs[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>? ??
                                            {};
                                    return _recommendationCard(
                                      docId: doc.id,
                                      data: data,
                                      colors: colors,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // FILTER
  // =========================================================

  List<QueryDocumentSnapshot> _filterRecommendations(
      List<QueryDocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      final careerGoal = data['careerGoal']?.toString().toLowerCase() ?? '';
      final skills = data['skills']?.toString().toLowerCase() ?? '';
      final education = data['education']?.toString().toLowerCase() ?? '';
      final interests = data['interests']?.toString().toLowerCase() ?? '';
      final recommendation =
          data['recommendation']?.toString().toLowerCase() ?? '';

      return careerGoal.contains(_searchQuery) ||
          skills.contains(_searchQuery) ||
          education.contains(_searchQuery) ||
          interests.contains(_searchQuery) ||
          recommendation.contains(_searchQuery);
    }).toList();
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader({
    required _RecColors colors,
    required int totalCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.isDark
              ? const [Color(0xFF03442C), Color(0xFF065F46), Color(0xFF047857)]
              : const [Color(0xFF047857), Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: colors.isDark ? 0.35 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _headerIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.maybePop(context),
                      ),
                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.26),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFC084FC),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '$totalCount AI Assessments',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),


                    ],
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.psychology_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Recommendations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Platform AI career advice and guidance assessments',
                              style: TextStyle(
                                color: Color(0xFFE2FBEA),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SEARCH & ADVISOR BANNER
  // =========================================================

  Widget _buildSearchAndAdvisorBanner(_RecColors colors) {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim().toLowerCase();
            });
          },
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            hintText: 'Search assessments by goal, skills, or education...',
            hintStyle: TextStyle(
              color: colors.textMuted,
              fontSize: 13.5,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colors.primary,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: colors.textMuted,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: colors.cardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.cardBorder, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.cardBorder, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary, width: 1.8),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Hero CTA to launch Career Advisor
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFC084FC).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF9333EA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Career Advisor Engine',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Generate custom career roadmaps and skill assessments',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CareerAdvisorScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Open Advisor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // RECOMMENDATION CARD
  // =========================================================

  Widget _recommendationCard({
    required String docId,
    required Map<String, dynamic> data,
    required _RecColors colors,
  }) {
    final careerGoal = data['careerGoal']?.toString().trim() ?? 'Career Guidance';
    final education = data['education']?.toString().trim() ?? 'Not specified';
    final skills = data['skills']?.toString().trim() ?? 'Not specified';
    final interests = data['interests']?.toString().trim() ?? '';
    final recommendation = data['recommendation']?.toString().trim() ?? '';
    final userId = data['userId']?.toString().trim() ?? '';

    final isExpanded = _expandedDocIds.contains(docId);

    String formattedDate = '';
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      formattedDate = '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: (colors.isDark ? Colors.black : const Color(0xFF059669))
                .withValues(alpha: colors.isDark ? 0.35 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      careerGoal,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 13,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            education,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (formattedDate.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Skills & Interests pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _infoPill(
                icon: Icons.code_rounded,
                label: 'Skills: $skills',
                color: colors.primary,
                colors: colors,
              ),
              if (interests.isNotEmpty)
                _infoPill(
                  icon: Icons.favorite_border_rounded,
                  label: 'Interests: $interests',
                  color: const Color(0xFF8B5CF6),
                  colors: colors,
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Recommendation text box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI RECOMMENDATION ADVICE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation,
                  maxLines: isExpanded ? 50 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedDocIds.remove(docId);
                      } else {
                        _expandedDocIds.add(docId);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isExpanded ? 'Show less' : 'Read full advice...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Footer with user ID copy
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 13,
                color: colors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'User: $userId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: colors.textMuted,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy Recommendation',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: colors.primary,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: recommendation));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: const Text(
                        'AI Recommendation copied to clipboard!',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String label,
    required Color color,
    required _RecColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: colors.isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LOADING / ERROR / EMPTY STATES
  // =========================================================

  Widget _loadingCard(_RecColors colors) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Center(
        child: CircularProgressIndicator(color: colors.primary),
      ),
    );
  }

  Widget _errorCard(String error, _RecColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: colors.isDark ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Text(
        error,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _emptyCard({
    required String title,
    required String subtitle,
    required _RecColors colors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 48,
            color: colors.isDark
                ? const Color(0xFF335242)
                : const Color(0xFFA7C1B3),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
