
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  static const Color primary = Color(0xFF2563EB);
  static const Color deepBlue = Color(0xFF173B8F);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color background = Color(0xFFF5F7FC);
  static const Color dark = Color(0xFF17233C);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE7ECF4);

  final TextEditingController _searchController =
  TextEditingController();

  String _selectedFilter = 'All';
  final Set<String> _expandedIds = {};

  final List<String> _filters = const [
    'All',
    'In Progress',
    'Accepted',
    'Rejected',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isInProgress(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized != 'accepted' && normalized != 'rejected';
  }

  bool _matchesFilter(String status) {
    final normalized = status.trim().toLowerCase();

    switch (_selectedFilter) {
      case 'In Progress':
        return _isInProgress(status);
      case 'Accepted':
        return normalized == 'accepted';
      case 'Rejected':
        return normalized == 'rejected';
      default:
        return true;
    }
  }

  String _stringValue(
      Map<String, dynamic> data,
      String key,
      String fallback,
      ) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  DateTime? _dateValue(Map<String, dynamic> data) {
    final value = data['appliedAt'];
    return value is Timestamp ? value.toDate() : null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'under review':
        return const Color(0xFFD97706);
      case 'shortlisted':
        return const Color(0xFF7C3AED);
      case 'interview':
        return const Color(0xFF4F46E5);
      case 'accepted':
        return const Color(0xFF059669);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return primary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'under review':
        return Icons.visibility_outlined;
      case 'shortlisted':
        return Icons.star_outline_rounded;
      case 'interview':
        return Icons.groups_outlined;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Applications',
          style: TextStyle(
            color: dark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: user == null
          ? _messageState(
        Icons.lock_outline_rounded,
        'Sign in required',
        'Please log in to view your job applications.',
      )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return _messageState(
              Icons.cloud_off_outlined,
              'Unable to load applications',
              'Please check your connection and try again.',
            );
          }

          final docs = [
            ...?snapshot.data?.docs,
          ];

          docs.sort((a, b) {
            final aDate = _dateValue(a.data());
            final bDate = _dateValue(b.data());

            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;

            return bDate.compareTo(aDate);
          });

          final total = docs.length;

          final inProgress = docs.where((doc) {
            final status = _stringValue(
              doc.data(),
              'status',
              'Applied',
            );
            return _isInProgress(status);
          }).length;

          final accepted = docs.where((doc) {
            return _stringValue(
              doc.data(),
              'status',
              'Applied',
            ).toLowerCase() ==
                'accepted';
          }).length;

          final query =
          _searchController.text.trim().toLowerCase();

          final filtered = docs.where((doc) {
            final data = doc.data();

            final title = _stringValue(
              data,
              'jobTitle',
              'Unknown Job',
            ).toLowerCase();

            final company = _stringValue(
              data,
              'company',
              'Unknown Company',
            ).toLowerCase();

            final status = _stringValue(
              data,
              'status',
              'Applied',
            );

            final matchesSearch =
                title.contains(query) ||
                    company.contains(query);

            return matchesSearch && _matchesFilter(status);
          }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 800,
              ),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18, 8, 18, 30,
                ),
                children: [
                  _buildHero(total),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          'Total',
                          total,
                          Icons.description_outlined,
                          primary,
                          const Color(0xFFEEF4FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          'In Progress',
                          inProgress,
                          Icons.timelapse_rounded,
                          const Color(0xFFD97706),
                          const Color(0xFFFFF7ED),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          'Accepted',
                          accepted,
                          Icons.check_circle_outline_rounded,
                          const Color(0xFF059669),
                          const Color(0xFFECFDF5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _sectionHeading(
                    'Your applications',
                    '$total submitted applications',
                  ),
                  const SizedBox(height: 15),
                  _buildSearch(),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 19),
                  if (filtered.isEmpty)
                    _emptyResults(total == 0)
                  else
                    ...filtered.map(
                          (doc) => _applicationCard(
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

  Widget _buildHero(int total) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deepBlue, primary, indigo],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          children: [
            Positioned(
              right: -48,
              top: -60,
              child: Container(
                height: 190,
                width: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -85,
              child: Container(
                height: 145,
                width: 145,
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.work_history_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Your career journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Stay organized and track every opportunity in one place.',
                    style: TextStyle(
                      color: Color(0xFFE1EAFF),
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$total Applications',
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

  Widget _summaryCard(
      String title,
      int count,
      IconData icon,
      Color color,
      Color iconBg,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: const TextStyle(
              color: dark,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
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
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search jobs or companies...',
          hintStyle: const TextStyle(
            color: muted,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: primary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.close_rounded),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = filter == _selectedFilter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedFilter = filter);
            },
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: primary,
            side: BorderSide(
              color: selected ? primary : border,
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _applicationCard(
      String id,
      Map<String, dynamic> data,
      ) {
    final jobTitle = _stringValue(
      data,
      'jobTitle',
      'Unknown Job',
    );

    final company = _stringValue(
      data,
      'company',
      'Unknown Company',
    );

    final status = _stringValue(
      data,
      'status',
      'Applied',
    );

    final date = _dateValue(data);
    final expanded = _expandedIds.contains(id);
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: dark.withOpacity(0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFDBEAFE),
                            Color(0xFFEDE9FE),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Center(
                        child: Text(
                          company.isEmpty
                              ? 'C'
                              : company[0].toUpperCase(),
                          style: const TextStyle(
                            color: primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            style: const TextStyle(
                              color: dark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            company,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _statusChip(status),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: muted,
                            size: 14,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              color: muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
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
          const Divider(height: 1, color: border),
          InkWell(
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedIds.remove(id);
                } else {
                  _expandedIds.add(id);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.route_outlined,
                    color: color,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Application progress',
                      style: TextStyle(
                        color: dark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    expanded ? 'Hide' : 'View',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: primary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
              padding: const EdgeInsets.fromLTRB(
                19, 0, 19, 20,
              ),
              child: _timeline(status),
            )
                : const SizedBox(
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(status),
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(String status) {
    if (status.toLowerCase() == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: Color(0xFFDC2626),
            ),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'This application was not selected.',
                style: TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    const steps = [
      'Applied',
      'Under Review',
      'Shortlisted',
      'Interview',
      'Accepted',
    ];

    final current = steps.indexWhere(
          (step) => step.toLowerCase() == status.toLowerCase(),
    );

    if (current < 0) {
      return Text(
        'Current status: $status',
        style: const TextStyle(
          color: muted,
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 9),
        ...List.generate(steps.length, (index) {
          final reached = index <= current;
          final isCurrent = index == current;
          final last = index == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 25,
                child: Column(
                  children: [
                    Icon(
                      reached
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: reached
                          ? const Color(0xFF059669)
                          : const Color(0xFFCBD5E1),
                      size: 21,
                    ),
                    if (!last)
                      Container(
                        width: 2,
                        height: 29,
                        color: index < current
                            ? const Color(0xFF059669)
                            : border,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          steps[index],
                          style: TextStyle(
                            color: reached ? dark : muted,
                            fontSize: 12.5,
                            fontWeight: isCurrent
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        const Text(
                          'CURRENT',
                          style: TextStyle(
                            color: primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 4),
        const Text(
          'Progress is based on the current status provided by the administrator.',
          style: TextStyle(
            color: muted,
            fontSize: 10.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _emptyResults(bool noApplications) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              noApplications
                  ? Icons.work_outline_rounded
                  : Icons.search_off_rounded,
              size: 36,
              color: primary,
            ),
          ),
          const SizedBox(height: 19),
          Text(
            noApplications
                ? 'No applications yet'
                : 'No matching applications',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: dark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            noApplications
                ? 'Your job applications will appear here once you apply.'
                : 'Try a different search or filter to find your applications.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          if (noApplications)
            ElevatedButton.icon(
              onPressed: () => Navigator.maybePop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 19,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explore Jobs'),
            )
          else
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _selectedFilter = 'All');
              },
              child: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }

  Widget _messageState(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primary, size: 65),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: dark,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
