
import 'package:flutter/material.dart';

import 'package:careerwise_sample/model/job.dart';
import 'package:careerwise_sample/services/job_service.dart';

import 'job_details_screen.dart';

class JobsScreen extends StatefulWidget {
  final String? career;

  const JobsScreen({
    super.key,
    this.career,
  });

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  static const Color primary = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF173A8A);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color background = Color(0xFFF6F8FC);
  static const Color textDark = Color(0xFF172033);
  static const Color textMuted = Color(0xFF64748B);

  final JobService _jobService = JobService();
  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';
  String _selectedType = 'All';
  String _sortBy = 'Default';

  final List<String> _jobTypes = [
    'All',
    'Full Time',
    'Part Time',
    'Internship',
    'Contract',
    'Remote',
  ];

  bool get _isCareerFiltered =>
      widget.career != null &&
          widget.career!.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Job> _filterJobs(List<Job> jobs) {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = jobs.where((job) {
      final searchableText = [
        job.title,
        job.company,
        job.location,
        job.description,
        job.jobType,
      ].join(' ').toLowerCase();

      final matchesSearch =
          query.isEmpty || searchableText.contains(query);

      final type = job.jobType.trim().toLowerCase();

      final matchesType =
          _selectedType == 'All' ||
              type == _selectedType.toLowerCase() ||
              (_selectedType == 'Full Time' &&
                  (type == 'full-time' || type == 'fulltime')) ||
              (_selectedType == 'Part Time' &&
                  (type == 'part-time' || type == 'parttime')) ||
              (_selectedType == 'Remote' &&
                  (type.contains('remote') ||
                      job.location.toLowerCase().contains('remote')));

      return matchesSearch && matchesType;
    }).toList();

    if (_sortBy == 'Title A-Z') {
      filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
      );
    } else if (_sortBy == 'Company A-Z') {
      filtered.sort(
            (a, b) => a.company.toLowerCase().compareTo(
          b.company.toLowerCase(),
        ),
      );
    }

    return filtered;
  }

  void _openJob(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsScreen(job: job),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sort opportunities',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 15),
                ...[
                  'Default',
                  'Title A-Z',
                  'Company A-Z',
                ].map((option) {
                  final selected = _sortBy == option;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                      Icons.check_circle_rounded,
                      color: primary,
                    )
                        : null,
                    onTap: () {
                      setState(() => _sortBy = option);
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: StreamBuilder<List<Job>>(
                stream: _isCareerFiltered
                    ? _jobService.getRelatedJobs(widget.career!)
                    : _jobService.getJobs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return _buildLoading();
                  }

                  if (snapshot.hasError) {
                    return _buildError(snapshot.error.toString());
                  }

                  final allJobs = snapshot.data ?? <Job>[];
                  final jobs = _filterJobs(allJobs);

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      18, 12, 18, 28,
                    ),
                    children: [
                      _buildHero(allJobs.length),
                      const SizedBox(height: 23),
                      _buildSearchBar(),
                      const SizedBox(height: 19),
                      _buildFilterHeader(),
                      const SizedBox(height: 12),
                      _buildFilters(),
                      const SizedBox(height: 25),
                      _buildResultsHeader(jobs.length),
                      const SizedBox(height: 14),

                      if (jobs.isEmpty)
                        _buildEmpty(allJobs.isEmpty)
                      else
                        ...jobs.map(
                              (job) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: 13,
                            ),
                            child: _buildJobCard(job),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 19,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              _isCareerFiltered
                  ? 'Related Opportunities'
                  : 'Available Jobs',
              style: const TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE8EDF5),
              ),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: primary,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(int count) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkBlue, primary, indigo],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -48,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFDE68A),
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'YOUR CAREER STARTS HERE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 19),
              Text(
                _isCareerFiltered
                    ? 'Explore jobs for\n${widget.career}'
                    : 'Find your next\nbig opportunity.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.17,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Discover opportunities and take the next step in your career journey.',
                style: TextStyle(
                  color: Color(0xFFE0E9FF),
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.work_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '$count available ${count == 1 ? 'job' : 'jobs'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE4EAF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'Search jobs, companies, locations...',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12.5,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: primary,
            size: 24,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterHeader() {
    return const Row(
      children: [
        Icon(
          Icons.tune_rounded,
          color: primary,
          size: 19,
        ),
        SizedBox(width: 8),
        Text(
          'Filter by job type',
          style: TextStyle(
            color: textDark,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _jobTypes.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = _jobTypes[index];
          final selected = _selectedType == type;

          return ChoiceChip(
            label: Text(type),
            selected: selected,
            showCheckmark: false,
            selectedColor: primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? primary
                  : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
            onSelected: (_) {
              setState(() => _selectedType = type);
            },
          );
        },
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Explore opportunities',
            style: TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '$count results',
          style: const TextStyle(
            color: textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 5),
        IconButton(
          onPressed: _showSortOptions,
          tooltip: 'Sort jobs',
          icon: const Icon(
            Icons.sort_rounded,
            color: primary,
            size: 23,
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard(Job job) {
    final jobType = job.jobType.trim();
    final salary = job.salary.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openJob(job),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE8EDF5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A)
                    .withOpacity(0.035),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFDBEAFE),
                          Color(0xFFEEF2FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.business_center_rounded,
                      color: darkBlue,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          job.company,
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: textMuted,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.location,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (jobType.isNotEmpty || salary.isNotEmpty) ...[
                const SizedBox(height: 13),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (jobType.isNotEmpty)
                      _infoChip(
                        Icons.schedule_outlined,
                        jobType,
                        const Color(0xFFEEF4FF),
                        primary,
                      ),
                    if (salary.isNotEmpty)
                      _infoChip(
                        Icons.payments_outlined,
                        salary,
                        const Color(0xFFECFDF5),
                        const Color(0xFF047857),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Divider(
                height: 1,
                color: Color(0xFFEEF2F7),
              ),
              const SizedBox(height: 13),
              const Row(
                children: [
                  Text(
                    'View job details',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: primary,
                    size: 19,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(
      IconData icon,
      String label,
      Color bg,
      Color fg,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool noJobsAtAll) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
            child: const Icon(
              Icons.search_off_rounded,
              color: primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 19),
          Text(
            noJobsAtAll
                ? 'No jobs available yet'
                : 'No matching jobs found',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            noJobsAtAll
                ? 'New opportunities will appear here when they are posted.'
                : 'Try another keyword or change your job type filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textMuted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          if (!noJobsAtAll) ...[
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedType = 'All';
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear filters'),
            ),
          ],
          if (noJobsAtAll && _isCareerFiltered) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const JobsScreen(),
                  ),
                );
              },
              child: const Text('Explore all jobs'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: primary),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 58,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load jobs',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
