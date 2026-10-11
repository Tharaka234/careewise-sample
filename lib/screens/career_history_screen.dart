
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CareerStyle {
  static const blue = Color(0xFF2563EB);
  static const navy = Color(0xFF173B8F);
  static const indigo = Color(0xFF4F46E5);
  static const background = Color(0xFFF5F7FC);
  static const dark = Color(0xFF17233C);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE7ECF4);

  static BoxDecoration card({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: navy.withOpacity(0.035),
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
        colors: [navy, blue, indigo],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: blue.withOpacity(0.18),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    );
  }

  static Widget heading(String title, {String? subtitle}) {
    return Column(
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
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  static Widget iconBox(
      IconData icon, {
        Color color = blue,
        Color backgroundColor = const Color(0xFFEEF4FF),
        double size = 46,
      }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size * 0.49),
    );
  }

  static Widget button({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
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
  State<CareerHistoryScreen> createState() =>
      _CareerHistoryScreenState();
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

  Future<void> _deleteRecommendation(String id) async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFDC2626),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete assessment?',
                style: TextStyle(fontSize: 19),
              ),
            ),
          ],
        ),
        content: const Text(
          'This saved career recommendation will be permanently deleted.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.uid != _streamUserId) {
      _setupStream();
    }

    return Scaffold(
      backgroundColor: CareerStyle.background,
      appBar: AppBar(
        backgroundColor: CareerStyle.background,
        surfaceTintColor: CareerStyle.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Career History',
          style: TextStyle(
            color: CareerStyle.dark,
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
      )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(
              child: CircularProgressIndicator(
                color: CareerStyle.blue,
              ),
            );
          }

          if (snapshot.hasError) {
            return _empty(
              Icons.cloud_off_outlined,
              'Unable to load history',
              'Please check your connection and try again.',
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
                  ),
                  const SizedBox(height: 16),
                  _searchAndSort(),
                  const SizedBox(height: 17),
                  if (filtered.isEmpty)
                    _emptyCard(docs.isEmpty)
                  else
                    ...filtered.map(
                          (doc) => _historyCard(
                        doc.id,
                        doc.data(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
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
                  color: Colors.white.withOpacity(0.07),
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
                  color: Colors.white.withOpacity(0.05),
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
                      color: Colors.white.withOpacity(0.17),
                      borderRadius: BorderRadius.circular(18),
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
                      color: Color(0xFFE1EAFF),
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
                      color: Colors.white.withOpacity(0.17),
                      borderRadius: BorderRadius.circular(12),
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

  Widget _searchAndSort() {
    return Column(
      children: [
        Container(
          decoration: CareerStyle.card(radius: 16),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search career goals, skills, careers...',
              hintStyle: const TextStyle(
                color: CareerStyle.muted,
                fontSize: 12.5,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: CareerStyle.blue,
              ),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                onPressed: () {
                  _search.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
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
            const Icon(
              Icons.filter_list_rounded,
              color: CareerStyle.muted,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Sort assessments',
                style: TextStyle(
                  color: CareerStyle.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<String>(
              initialValue: _sort,
              onSelected: (value) => setState(() => _sort = value),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'Newest first',
                  child: Text('Newest first'),
                ),
                PopupMenuItem(
                  value: 'Oldest first',
                  child: Text('Oldest first'),
                ),
              ],
              child: Row(
                children: [
                  Text(
                    _sort,
                    style: const TextStyle(
                      color: CareerStyle.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: CareerStyle.blue,
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
      ) {
    final education = CareerStyle.field(data, 'education');
    final skills = CareerStyle.field(data, 'skills');
    final interests = CareerStyle.field(data, 'interests');
    final goal = CareerStyle.field(data, 'careerGoal');
    final recommendation =
    CareerStyle.field(data, 'recommendation', '');

    final timestamp = data['createdAt'] is Timestamp
        ? data['createdAt'] as Timestamp
        : null;

    final careers = CareerStyle.careers(recommendation);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: CareerStyle.card(radius: 23),
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CareerStyle.iconBox(
                  Icons.auto_awesome_rounded,
                  size: 52,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Career Analysis',
                        style: TextStyle(
                          color: CareerStyle.dark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Personalized career assessment',
                        style: TextStyle(
                          color: CareerStyle.muted,
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
                      : () => _deleteRecommendation(id),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: CareerStyle.muted,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CareerStyle.date(timestamp),
                    style: const TextStyle(
                      color: CareerStyle.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: CareerStyle.border),
            const SizedBox(height: 16),
            _previewField(
              Icons.flag_outlined,
              'Career Goal',
              goal,
            ),
            const SizedBox(height: 13),
            _previewField(
              Icons.school_outlined,
              'Education',
              education,
            ),
            if (careers.isNotEmpty) ...[
              const SizedBox(height: 19),
              const Text(
                'Recommended Career Paths',
                style: TextStyle(
                  color: CareerStyle.dark,
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
                      color: const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: CareerStyle.blue,
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
                            style: const TextStyle(
                              color: CareerStyle.dark,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.north_east_rounded,
                          color: CareerStyle.blue,
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
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: CareerStyle.blue, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: CareerStyle.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CareerStyle.dark,
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

  Widget _emptyCard(bool noHistory) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 43,
      ),
      decoration: CareerStyle.card(radius: 22),
      child: Column(
        children: [
          CareerStyle.iconBox(
            noHistory
                ? Icons.history_edu_rounded
                : Icons.search_off_rounded,
            size: 78,
          ),
          const SizedBox(height: 20),
          Text(
            noHistory
                ? 'No Career History Yet'
                : 'No Matching Assessments',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CareerStyle.dark,
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
            style: const TextStyle(
              color: CareerStyle.muted,
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
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CareerStyle.iconBox(icon, size: 76),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: CareerStyle.dark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CareerStyle.muted,
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

  @override
  Widget build(BuildContext context) {
    final result = CareerStyle.parse(recommendation);

    return Scaffold(
      backgroundColor: CareerStyle.background,
      appBar: AppBar(
        backgroundColor: CareerStyle.background,
        surfaceTintColor: CareerStyle.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Career Recommendation',
          style: TextStyle(
            color: CareerStyle.dark,
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
              ),
              const SizedBox(height: 14),
              _profileCard(),
              const SizedBox(height: 25),
              CareerStyle.heading(
                'AI Career Insights',
                subtitle: 'Your personalized career recommendations',
              ),
              const SizedBox(height: 14),
              if (result != null)
                _structuredResult(result)
              else
                _panel(
                  child: SelectableText(
                    recommendation.isEmpty
                        ? 'Recommendation unavailable.'
                        : recommendation,
                    style: const TextStyle(
                      color: CareerStyle.dark,
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
              color: Colors.white.withOpacity(0.17),
              borderRadius: BorderRadius.circular(18),
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
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Explore your strengths, discover career paths and plan your next steps.',
            style: TextStyle(
              color: Color(0xFFE1EAFF),
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

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: CareerStyle.card(radius: 21),
      child: child,
    );
  }

  Widget _profileCard() {
    return _panel(
      child: Column(
        children: [
          _profileRow(
            Icons.school_outlined,
            'Education',
            education,
          ),
          const Divider(height: 27, color: CareerStyle.border),
          _profileRow(
            Icons.code_rounded,
            'Skills',
            skills,
          ),
          const Divider(height: 27, color: CareerStyle.border),
          _profileRow(
            Icons.favorite_border_rounded,
            'Interests',
            interests,
          ),
          const Divider(height: 27, color: CareerStyle.border),
          _profileRow(
            Icons.flag_outlined,
            'Career Goal',
            careerGoal,
          ),
        ],
      ),
    );
  }

  Widget _profileRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CareerStyle.iconBox(icon, size: 42),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: CareerStyle.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: CareerStyle.dark,
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

  Widget _structuredResult(Map<String, dynamic> result) {
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

            return _careerCard(entry.key + 1, career);
          }),
        ],
        if (strengths.isNotEmpty) ...[
          const SizedBox(height: 12),
          CareerStyle.heading('Your Strengths'),
          const SizedBox(height: 13),
          _panel(
            child: Column(
              children: strengths
                  .map(
                    (item) => _bullet(
                  item.toString(),
                  Icons.check_circle_outline_rounded,
                  const Color(0xFF059669),
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
          ),
          const SizedBox(height: 13),
          _panel(
            child: Column(
              children: actionPlan.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor:
                        const Color(0xFFEEF4FF),
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: CareerStyle.blue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            color: CareerStyle.dark,
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
          CareerStyle.heading('Recommended Tools'),
          const SizedBox(height: 13),
          _panel(
            child: Column(
              children: tools
                  .map(
                    (tool) => _bullet(
                  tool.toString(),
                  Icons.build_outlined,
                  CareerStyle.blue,
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
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(result),
              style: const TextStyle(
                color: CareerStyle.dark,
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
      decoration: CareerStyle.card(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F5FF),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: CareerStyle.blue,
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
                    style: const TextStyle(
                      color: CareerStyle.dark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: CareerStyle.blue,
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
                  ),
                  const SizedBox(height: 9),
                  Text(
                    whySuitable,
                    style: const TextStyle(
                      color: CareerStyle.muted,
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
                  ),
                if (learningAreas.isNotEmpty)
                  _careerList(
                    'Learning Areas',
                    Icons.menu_book_outlined,
                    learningAreas,
                  ),
                if (technologies.isNotEmpty)
                  _careerList(
                    'Technologies',
                    Icons.computer_rounded,
                    technologies,
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
      ) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniHeading(icon, title),
          const SizedBox(height: 10),
          ...items.map(
                (item) => _bullet(
              item.toString(),
              Icons.check_circle_outline_rounded,
              CareerStyle.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniHeading(IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          color: CareerStyle.blue,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: CareerStyle.dark,
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
              style: const TextStyle(
                color: CareerStyle.dark,
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
