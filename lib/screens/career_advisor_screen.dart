
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import 'jobs_screen.dart';

class CareerAdvisorScreen extends StatefulWidget {
  const CareerAdvisorScreen({super.key});

  @override
  State<CareerAdvisorScreen> createState() =>
      _CareerAdvisorScreenState();
}

class _CareerAdvisorScreenState extends State<CareerAdvisorScreen> {
  static const Color navy = Color(0xFF172554);
  static const Color primary = Color(0xFF5267E8);
  static const Color violet = Color(0xFF8664E9);
  static const Color background = Color(0xFFF5F7FC);
  static const Color muted = Color(0xFF78839A);
  static const Color darkText = Color(0xFF202B45);

  final _formKey = GlobalKey<FormState>();
  final _education = TextEditingController();
  final _skills = TextEditingController();
  final _interests = TextEditingController();
  final _goals = TextEditingController();

  final AIService _aiService = AIService();

  bool isLoading = false;
  Map<String, dynamic>? result;

  @override
  void dispose() {
    _education.dispose();
    _skills.dispose();
    _interests.dispose();
    _goals.dispose();
    super.dispose();
  }

  Future<void> getCareerAdvice() async {
    if (isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      result = null;
    });

    try {
      final education = _education.text.trim();
      final skills = _skills.text.trim();
      final interests = _interests.text.trim();
      final goals = _goals.text.trim();

      final aiResult = await _aiService.getCareerRecommendation(
        education: education,
        skills: skills,
        interests: interests,
        careerGoal: goals,
      );

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await _aiService.saveCareerRecommendation(
          userId: user.uid,
          education: education,
          skills: skills,
          interests: interests,
          careerGoal: goals,
          recommendation: jsonEncode(aiResult),
        );
      }

      if (!mounted) return;

      setState(() {
        result = aiResult;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFCC3D52),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'CareerWise AI',
          style: TextStyle(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: navy),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth > 700 ? 32.0 : 18.0;

            return SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 24),
                      _buildProgress(),
                      const SizedBox(height: 22),
                      _buildForm(constraints.maxWidth > 700),
                      if (result != null) ...[
                        const SizedBox(height: 32),
                        _buildResults(),
                      ],
                      const SizedBox(height: 28),
                      const Center(
                        child: Text(
                          'CAREERWISE  •  YOUR FUTURE, YOUR WAY',
                          style: TextStyle(
                            fontSize: 10,
                            color: muted,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Premium gradient hero
  Widget _buildHero() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF182B69),
            Color(0xFF4659C9),
            Color(0xFF7958D8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -65,
            child: _decorativeCircle(190),
          ),
          Positioned(
            right: 85,
            bottom: -100,
            child: _decorativeCircle(170),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 15,
                        color: Color(0xFFFFD98C),
                      ),
                      SizedBox(width: 7),
                      Text(
                        'AI-POWERED CAREER GUIDANCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Your future starts\nwith the right path.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Discover career opportunities that match your '
                      'skills, interests and ambitions.',
                  style: TextStyle(
                    color: Color(0xFFE2E7FF),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    _HeroFeature(
                      icon: Icons.explore_outlined,
                      label: 'Explore',
                    ),
                    SizedBox(width: 18),
                    _HeroFeature(
                      icon: Icons.psychology_outlined,
                      label: 'Discover',
                    ),
                    SizedBox(width: 18),
                    _HeroFeature(
                      icon: Icons.rocket_launch_outlined,
                      label: 'Grow',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.055),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
    );
  }

  // Progress indicator
  Widget _buildProgress() {
    return Row(
      children: [
        _progressItem('01', 'Your profile', true),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFFDCE2F2),
          ),
        ),
        _progressItem('02', 'AI analysis', false),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFFDCE2F2),
          ),
        ),
        _progressItem('03', 'Your results', false),
      ],
    );
  }

  Widget _progressItem(String number, String label, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? primary : const Color(0xFFDCE2F2),
            ),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: active ? navy : muted,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Main form
  Widget _buildForm(bool wide) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECF5)),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.045),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Build your career profile',
              style: TextStyle(
                color: navy,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'A few details will help us personalize your recommendations.',
              style: TextStyle(
                color: muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (wide) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Education',
                      hint: 'e.g. BSc Computer Science',
                      helper: 'Your current qualification',
                      icon: Icons.school_outlined,
                      controller: _education,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _buildField(
                      label: 'Skills',
                      hint: 'e.g. Java, Flutter, SQL',
                      helper: 'Your existing skills',
                      icon: Icons.code_rounded,
                      controller: _skills,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Interests',
                      hint: 'e.g. AI, Mobile Development',
                      helper: 'Topics you enjoy',
                      icon: Icons.favorite_border_rounded,
                      controller: _interests,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _buildField(
                      label: 'Career goals',
                      hint: 'e.g. Become a Full Stack Developer',
                      helper: 'What you want to achieve',
                      icon: Icons.flag_outlined,
                      controller: _goals,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildField(
                label: 'Education',
                hint: 'e.g. BSc Computer Science',
                helper: 'Your current qualification',
                icon: Icons.school_outlined,
                controller: _education,
                maxLines: 1,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Skills',
                hint: 'e.g. Java, Flutter, SQL',
                helper: 'Your existing skills',
                icon: Icons.code_rounded,
                controller: _skills,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Interests',
                hint: 'e.g. AI, Mobile Development',
                helper: 'Topics you enjoy',
                icon: Icons.favorite_border_rounded,
                controller: _interests,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Career goals',
                hint: 'e.g. Become a Full Stack Developer',
                helper: 'What you want to achieve',
                icon: Icons.flag_outlined,
                controller: _goals,
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 26),
            _buildGenerateButton(),
            const SizedBox(height: 13),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 13,
                    color: muted,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Your information is used to personalize your advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
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

  Widget _buildField({
    required String label,
    required String hint,
    required String helper,
    required IconData icon,
    required TextEditingController controller,
    required int maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: darkText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: const TextStyle(
            color: muted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: maxLines == 1
              ? TextInputType.text
              : TextInputType.multiline,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your ${label.toLowerCase()}.';
            }
            if (value.trim().length < 2) {
              return 'Please provide a little more information.';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFA1A9BB),
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                bottom: maxLines == 1 ? 0 : 0,
              ),
              child: Icon(
                icon,
                size: 20,
                color: primary,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FD),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE3E8F2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE3E8F2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFDA5262),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFDA5262),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading
              ? const LinearGradient(
            colors: [Color(0xFF8A99D9), Color(0xFF9B8BD5)],
          )
              : const LinearGradient(
            colors: [Color(0xFF4764E8), Color(0xFF815BE2)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? []
              : [
            BoxShadow(
              color: primary.withOpacity(0.23),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : getCareerAdvice,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.auto_awesome, size: 20),
              const SizedBox(width: 10),
              Text(
                isLoading
                    ? 'Analyzing your profile...'
                    : 'Generate my career path',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AI result section
  Widget _buildResults() {
    final careers = result?['careers'] as List<dynamic>? ?? [];
    final strengths = result?['strengths'] as List<dynamic>? ?? [];
    final actions = result?['actionPlan'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF0FF),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFDCE5FF)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: primary,
                size: 29,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your career insights',
                      style: TextStyle(
                        color: navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Your personalized AI recommendations are ready.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _resultHeading(
          'Career recommendations',
          'Explore these career paths based on your profile.',
          Icons.work_outline,
        ),
        const SizedBox(height: 14),
        ...careers.asMap().entries.map((entry) {
          final raw = entry.value;
          if (raw is! Map) return const SizedBox.shrink();

          final career = Map<String, dynamic>.from(raw);
          return _careerCard(
            number: entry.key + 1,
            title: career['title']?.toString() ?? 'Career',
            why: career['whySuitable']?.toString() ?? '',
            skills: career['skillsToDevelop'] as List<dynamic>? ?? [],
            learning: career['learningAreas'] as List<dynamic>? ?? [],
            technologies: career['technologies'] as List<dynamic>? ?? [],
          );
        }),
        if (strengths.isNotEmpty) ...[
          const SizedBox(height: 18),
          _resultHeading(
            'Your strengths',
            'What you already bring to your career journey.',
            Icons.workspace_premium_outlined,
          ),
          const SizedBox(height: 14),
          _listCard(strengths, Icons.check_circle_outline, const Color(0xFF169C77)),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 24),
          _resultHeading(
            'Your action plan',
            'Steps to help you move towards your goals.',
            Icons.route_outlined,
          ),
          const SizedBox(height: 14),
          _actionCard(actions),
        ],
      ],
    );
  }

  Widget _resultHeading(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EDFF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _careerCard({
    required int number,
    required String title,
    required String why,
    required List<dynamic> skills,
    required List<dynamic> learning,
    required List<dynamic> technologies,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE6EAF3)),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primary, violet],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          _detailTitle('Why this career suits you', Icons.lightbulb_outline),
          const SizedBox(height: 7),
          Text(
            why,
            style: const TextStyle(
              color: Color(0xFF596579),
              fontSize: 13,
              height: 1.65,
            ),
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 18),
            _detailTitle('Skills to develop', Icons.psychology_outlined),
            const SizedBox(height: 10),
            _tagList(skills),
          ],
          if (learning.isNotEmpty) ...[
            const SizedBox(height: 18),
            _detailTitle('Learning areas', Icons.menu_book_outlined),
            const SizedBox(height: 10),
            _tagList(learning),
          ],
          if (technologies.isNotEmpty) ...[
            const SizedBox(height: 18),
            _detailTitle('Technologies', Icons.devices_outlined),
            const SizedBox(height: 10),
            _tagList(technologies),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobsScreen(career: title),
                  ),
                );
              },
              icon: const Icon(Icons.search_rounded, size: 19),
              label: const Text(
                'Explore related jobs',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: const BorderSide(color: Color(0xFFC9D4FA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _tagList(List<dynamic> values) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FF),
            border: Border.all(color: const Color(0xFFE0E5FF)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            value.toString(),
            style: const TextStyle(
              color: Color(0xFF475AC0),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _listCard(List<dynamic> values, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Column(
        children: values.map((value) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Color(0xFF596579),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _actionCard(List<dynamic> actions) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Column(
        children: actions.asMap().entries.map((entry) {
          final isLast = entry.key == actions.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        color: Color(0xFF596579),
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroFeature({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFDCE4FF)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}