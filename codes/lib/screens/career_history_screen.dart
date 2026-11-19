import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_profile_screen.dart';

// ============================================================
// EMERALD GREEN THEME DESIGN SYSTEM & STYLES
// ============================================================

class CareerHistoryColors {
  final bool isDark;
  final Color pageBg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color tagBg;
  final Color tagBorder;
  final Color searchFill;
  final Color iconBg;

  CareerHistoryColors({required this.isDark})
      : pageBg = isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4),
        cardBg = isDark ? const Color(0xFF132A1F) : Colors.white,
        cardBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFD1FAE5),
        textPrimary = isDark ? Colors.white : const Color(0xFF0F172A),
        textSecondary =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        primary = const Color(0xFF059669),
        primaryDark = const Color(0xFF044E36),
        accent = const Color(0xFF10B981),
        tagBg = isDark ? const Color(0xFF0E2319) : const Color(0xFFECFDF5),
        tagBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFA7F3D0),
        searchFill = isDark ? const Color(0xFF0A1F16) : Colors.white,
        iconBg = isDark ? const Color(0xFF0E2319) : const Color(0xFFECFDF5);
}

class CareerStyle {
  // Emerald Brand Colors
  static const primary = Color(0xFF059669);
  static const primaryDark = Color(0xFF044E36);
  static const accent = Color(0xFF10B981);
  static const mintLight = Color(0xFFECFDF5);
  static const mintBorder = Color(0xFFA7F3D0);

  // Backward compatibility aliases
  static const blue = Color(0xFF059669);
  static const navy = Color(0xFF044E36);
  static const indigo = Color(0xFF10B981);
  static const background = Color(0xFFF0FDF4);
  static const dark = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFD1FAE5);

  static BoxDecoration card({
    double radius = 20,
    required CareerHistoryColors colors,
  }) {
    return BoxDecoration(
      color: colors.cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: colors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: colors.isDark
              ? Colors.black.withValues(alpha: 0.30)
              : colors.primaryDark.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration gradient({double radius = 25}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDark, primary, accent],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.28),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    );
  }

  static Widget heading(
    String title, {
    String? subtitle,
    required CareerHistoryColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  static Widget iconBox(
    IconData icon, {
    required CareerHistoryColors colors,
    Color? color,
    Color? backgroundColor,
    double size = 46,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.iconBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.tagBorder),
      ),
      child: Icon(
        icon,
        color: color ?? colors.primary,
        size: size * 0.49,
      ),
    );
  }

  static Widget button({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 51,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [primaryDark, primary, accent],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  static String date(Timestamp? timestamp) {
    if (timestamp == null) return 'Date unavailable';

    final date = timestamp.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} '
        '${date.year} • $hour:$minute $period';
  }

  static String field(
    Map<String, dynamic> data,
    String key, [
    String fallback = 'Not provided',
  ]) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  static Map<String, dynamic>? parse(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  static List<dynamic> list(dynamic value) {
    return value is List ? value : [];
  }

  static List<Map<String, dynamic>> careers(String value) {
    final decoded = parse(value);
    return list(decoded?['careers'])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

// ============================================================
// CAREER HISTORY SCREEN
// ============================================================

class CareerHistoryScreen extends StatefulWidget {
  const CareerHistoryScreen({super.key});

  @override
  State<CareerHistoryScreen> createState() => _CareerHistoryScreenState();
}

class _CareerHistoryScreenState extends State<CareerHistoryScreen> {
  final TextEditingController _search = TextEditingController();

  String _sort = 'Newest first';
  bool _deleting = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _historyStream;
  String? _streamUserId;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    final user = FirebaseAuth.instance.currentUser;
    _streamUserId = user?.uid;

    if (user != null) {
      _historyStream = FirebaseFirestore.instance
          .collection('career_recommendations')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    } else {
      _historyStream = null;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _deleteRecommendation(String id, CareerHistoryColors colors) async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23),
          side: BorderSide(color: colors.cardBorder),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete assessment?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This saved career recommendation will be permanently deleted.',
          style: TextStyle(
            height: 1.5,
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      await FirebaseFirestore.instance
          .collection('career_recommendations')
          .doc(id)
          .delete();

      if (!mounted) return;

      _snack('Assessment deleted successfully.');
    } catch (e) {
      debugPrint('Delete recommendation error: $e');
      if (!mounted) return;
      _snack('Unable to delete assessment.', error: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFDC2626)
              : const Color(0xFF059669),
          content: Text(message),
        ),
      );
  }

  Widget _buildBackButton(
    BuildContext context,
    CareerHistoryColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: colors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black26
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.uid != _streamUserId) {
      _setupStream();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = CareerHistoryColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            backgroundColor: colors.pageBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: _buildBackButton(context, colors),
            title: Text(
              'Career History',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: user == null
              ? _empty(
                  Icons.lock_outline_rounded,
                  'Sign in required',
                  'Please log in to view your career history.',
                  colors,
                )
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _historyStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData && !snapshot.hasError) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colors.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _empty(
                        Icons.cloud_off_outlined,
                        'Unable to load history',
                        'Please check your connection and try again.',
                        colors,
                      );
                    }

                    final docs = [...?snapshot.data?.docs];

                    docs.sort((a, b) {
                      final aTime = a.data()['createdAt'];
                      final bTime = b.data()['createdAt'];

                      final aDate = aTime is Timestamp
                          ? aTime.toDate()
                          : DateTime(1970);
                      final bDate = bTime is Timestamp
                          ? bTime.toDate()
                          : DateTime(1970);

                      return _sort == 'Newest first'
                          ? bDate.compareTo(aDate)
                          : aDate.compareTo(bDate);
                    });

                    final query = _search.text.trim().toLowerCase();

                    final filtered = docs.where((doc) {
                      final data = doc.data();

                      final careers = CareerStyle.careers(
                        CareerStyle.field(data, 'recommendation', ''),
                      );

                      final careerNames = careers
                          .map((c) => c['title']?.toString() ?? '')
                          .join(' ');

                      final searchText = [
                        CareerStyle.field(data, 'careerGoal'),
                        CareerStyle.field(data, 'education'),
                        CareerStyle.field(data, 'skills'),
                        CareerStyle.field(data, 'interests'),
                        careerNames,
                      ].join(' ').toLowerCase();

                      return searchText.contains(query);
                    }).toList();

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _hero(docs.length),
                            const SizedBox(height: 25),
                            CareerStyle.heading(
                              'Saved Assessments',
                              subtitle:
                                  'Revisit your AI-powered career insights',
                              colors: colors,
                            ),
                            const SizedBox(height: 16),
                            _searchAndSort(colors),
                            const SizedBox(height: 17),
                            if (filtered.isEmpty)
                              _emptyCard(docs.isEmpty, colors)
                            else
                              ...filtered.map(
                                (doc) => _historyCard(
                                  doc.id,
                                  doc.data(),
                                  colors,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _hero(int count) {
    return Container(
      decoration: CareerStyle.gradient(radius: 27),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -55,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: 45,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 57,
                    height: 57,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Your Career Journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Every career insight brings you closer to your future.',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$count Saved Assessments',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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

  Widget _searchAndSort(CareerHistoryColors colors) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.searchFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black26
                    : colors.primaryDark.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _search,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search career goals, skills, careers...',
              hintStyle: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colors.primary,
              ),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                      ),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: colors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sort assessments',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<String>(
              initialValue: _sort,
              color: colors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.cardBorder),
              ),
              onSelected: (value) => setState(() => _sort = value),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'Newest first',
                  child: Text(
                    'Newest first',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: _sort == 'Newest first'
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'Oldest first',
                  child: Text(
                    'Oldest first',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: _sort == 'Oldest first'
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
              child: Row(
                children: [
                  Text(
                    _sort,
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _historyCard(
    String id,
    Map<String, dynamic> data,
    CareerHistoryColors colors,
  ) {
    final education = CareerStyle.field(data, 'education');
    final skills = CareerStyle.field(data, 'skills');
    final interests = CareerStyle.field(data, 'interests');
    final goal = CareerStyle.field(data, 'careerGoal');
    final recommendation = CareerStyle.field(data, 'recommendation', '');

    final timestamp = data['createdAt'] is Timestamp
        ? data['createdAt'] as Timestamp
        : null;

    final careers = CareerStyle.careers(recommendation);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: CareerStyle.card(radius: 23, colors: colors),
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CareerStyle.iconBox(
                  Icons.auto_awesome_rounded,
                  colors: colors,
                  size: 52,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Career Analysis',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Personalized career assessment',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete assessment',
                  onPressed: _deleting
                      ? null
                      : () => _deleteRecommendation(id, colors),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: colors.textSecondary,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CareerStyle.date(timestamp),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.cardBorder),
            const SizedBox(height: 16),
            _previewField(
              Icons.flag_outlined,
              'Career Goal',
              goal,
              colors,
            ),
            const SizedBox(height: 13),
            _previewField(
              Icons.school_outlined,
              'Education',
              education,
              colors,
            ),
            if (careers.isNotEmpty) ...[
              const SizedBox(height: 19),
              Text(
                'Recommended Career Paths',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...careers.take(3).toList().asMap().entries.map(
                (entry) {
                  final title = CareerStyle.field(
                    entry.value,
                    'title',
                    'Career',
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.tagBg,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: colors.tagBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: colors.primary,
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.north_east_rounded,
                          color: colors.primary,
                          size: 17,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 15),
            CareerStyle.button(
              label: 'View Full Recommendation',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CareerHistoryDetailScreen(
                      education: education,
                      skills: skills,
                      interests: interests,
                      careerGoal: goal,
                      recommendation: recommendation,
                      date: CareerStyle.date(timestamp),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewField(
    IconData icon,
    String label,
    String value,
    CareerHistoryColors colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.primary, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(bool noHistory, CareerHistoryColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 43,
      ),
      decoration: CareerStyle.card(radius: 22, colors: colors),
      child: Column(
        children: [
          CareerStyle.iconBox(
            noHistory
                ? Icons.history_edu_rounded
                : Icons.search_off_rounded,
            colors: colors,
            size: 78,
          ),
          const SizedBox(height: 20),
          Text(
            noHistory
                ? 'No Career History Yet'
                : 'No Matching Assessments',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            noHistory
                ? 'Generate your first AI career recommendation to start building your career journey.'
                : 'Try another search to find your saved recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          CareerStyle.button(
            label: noHistory ? 'Get Career Advice' : 'Clear Search',
            icon: noHistory
                ? Icons.auto_awesome_rounded
                : Icons.refresh_rounded,
            onPressed: () {
              if (noHistory) {
                Navigator.maybePop(context);
              } else {
                _search.clear();
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _empty(
    IconData icon,
    String title,
    String message,
    CareerHistoryColors colors,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CareerStyle.iconBox(icon, colors: colors, size: 76),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FULL RECOMMENDATION DETAILS SCREEN
// ============================================================

class CareerHistoryDetailScreen extends StatelessWidget {
  final String education;
  final String skills;
  final String interests;
  final String careerGoal;
  final String recommendation;
  final String date;

  const CareerHistoryDetailScreen({
    super.key,
    required this.education,
    required this.skills,
    required this.interests,
    required this.careerGoal,
    required this.recommendation,
    required this.date,
  });

  Widget _buildBackButton(BuildContext context, CareerHistoryColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: colors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black26
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = CareerStyle.parse(recommendation);

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = CareerHistoryColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            backgroundColor: colors.pageBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: _buildBackButton(context, colors),
            title: Text(
              'Career Recommendation',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                physics: const BouncingScrollPhysics(),
                children: [
                  _detailHero(),
                  const SizedBox(height: 25),
                  CareerStyle.heading(
                    'Your Profile',
                    subtitle: 'Information used for your assessment',
                    colors: colors,
                  ),
                  const SizedBox(height: 14),
                  _profileCard(colors),
                  const SizedBox(height: 25),
                  CareerStyle.heading(
                    'AI Career Insights',
                    subtitle: 'Your personalized career recommendations',
                    colors: colors,
                  ),
                  const SizedBox(height: 14),
                  if (result != null)
                    _structuredResult(result, colors)
                  else
                    _panel(
                      colors: colors,
                      child: SelectableText(
                        recommendation.isEmpty
                            ? 'Recommendation unavailable.'
                            : recommendation,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                          height: 1.7,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailHero() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: CareerStyle.gradient(radius: 27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Career Blueprint',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Explore your strengths, discover career paths and plan your next steps.',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white,
                size: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required Widget child,
    required CareerHistoryColors colors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: CareerStyle.card(radius: 21, colors: colors),
      child: child,
    );
  }

  Widget _profileCard(CareerHistoryColors colors) {
    return _panel(
      colors: colors,
      child: Column(
        children: [
          _profileRow(
            Icons.school_outlined,
            'Education',
            education,
            colors,
          ),
          Divider(height: 27, color: colors.cardBorder),
          _profileRow(
            Icons.code_rounded,
            'Skills',
            skills,
            colors,
          ),
          Divider(height: 27, color: colors.cardBorder),
          _profileRow(
            Icons.favorite_border_rounded,
            'Interests',
            interests,
            colors,
          ),
          Divider(height: 27, color: colors.cardBorder),
          _profileRow(
            Icons.flag_outlined,
            'Career Goal',
            careerGoal,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _profileRow(
    IconData icon,
    String label,
    String value,
    CareerHistoryColors colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CareerStyle.iconBox(icon, colors: colors, size: 42),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _structuredResult(
    Map<String, dynamic> result,
    CareerHistoryColors colors,
  ) {
    final careers = CareerStyle.list(result['careers']);
    final strengths = CareerStyle.list(result['strengths']);
    final actionPlan = CareerStyle.list(result['actionPlan']);
    final tools = CareerStyle.list(result['tools']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (careers.isNotEmpty) ...[
          ...careers.asMap().entries.map((entry) {
            if (entry.value is! Map) {
              return const SizedBox.shrink();
            }

            final career = Map<String, dynamic>.from(
              entry.value as Map,
            );

            return _careerCard(entry.key + 1, career, colors);
          }),
        ],
        if (strengths.isNotEmpty) ...[
          const SizedBox(height: 12),
          CareerStyle.heading('Your Strengths', colors: colors),
          const SizedBox(height: 13),
          _panel(
            colors: colors,
            child: Column(
              children: strengths
                  .map(
                    (item) => _bullet(
                      item.toString(),
                      Icons.check_circle_outline_rounded,
                      colors.primary,
                      colors,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (actionPlan.isNotEmpty) ...[
          const SizedBox(height: 24),
          CareerStyle.heading(
            'Your Action Plan',
            subtitle: 'Practical steps toward your career goals',
            colors: colors,
          ),
          const SizedBox(height: 13),
          _panel(
            colors: colors,
            child: Column(
              children: actionPlan.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: colors.tagBg,
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        if (tools.isNotEmpty) ...[
          const SizedBox(height: 24),
          CareerStyle.heading('Recommended Tools', colors: colors),
          const SizedBox(height: 13),
          _panel(
            colors: colors,
            child: Column(
              children: tools
                  .map(
                    (tool) => _bullet(
                      tool.toString(),
                      Icons.build_outlined,
                      colors.primary,
                      colors,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (careers.isEmpty &&
            strengths.isEmpty &&
            actionPlan.isEmpty &&
            tools.isEmpty)
          _panel(
            colors: colors,
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(result),
              style: TextStyle(
                color: colors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
      ],
    );
  }

  Widget _careerCard(
    int number,
    Map<String, dynamic> career,
    CareerHistoryColors colors,
  ) {
    final title = CareerStyle.field(
      career,
      'title',
      'Career Path',
    );

    final whySuitable = CareerStyle.field(
      career,
      'whySuitable',
      '',
    );

    final skills = CareerStyle.list(
      career['skillsToDevelop'],
    );

    final learningAreas = CareerStyle.list(
      career['learningAreas'],
    );

    final technologies = CareerStyle.list(
      career['technologies'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: CareerStyle.card(radius: 22, colors: colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.tagBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              border: Border(
                bottom: BorderSide(color: colors.cardBorder),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.primary,
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (whySuitable.isNotEmpty) ...[
                  _miniHeading(
                    Icons.lightbulb_outline_rounded,
                    'Why This Career Fits You',
                    colors,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    whySuitable,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                ],
                if (skills.isNotEmpty)
                  _careerList(
                    'Skills to Develop',
                    Icons.code_rounded,
                    skills,
                    colors,
                  ),
                if (learningAreas.isNotEmpty)
                  _careerList(
                    'Learning Areas',
                    Icons.menu_book_outlined,
                    learningAreas,
                    colors,
                  ),
                if (technologies.isNotEmpty)
                  _careerList(
                    'Technologies',
                    Icons.computer_rounded,
                    technologies,
                    colors,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _careerList(
    String title,
    IconData icon,
    List<dynamic> items,
    CareerHistoryColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniHeading(icon, title, colors),
          const SizedBox(height: 10),
          ...items.map(
            (item) => _bullet(
              item.toString(),
              Icons.check_circle_outline_rounded,
              colors.primary,
              colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniHeading(
    IconData icon,
    String title,
    CareerHistoryColors colors,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: colors.primary,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bullet(
    String text,
    IconData icon,
    Color color,
    CareerHistoryColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12.5,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
