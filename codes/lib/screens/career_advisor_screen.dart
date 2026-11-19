import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import 'jobs_screen.dart';
import 'admin_profile_screen.dart';

class CareerAdvisorScreen extends StatefulWidget {
  const CareerAdvisorScreen({super.key});

  @override
  State<CareerAdvisorScreen> createState() =>
      _CareerAdvisorScreenState();
}

class _CareerAdvisorScreenState extends State<CareerAdvisorScreen> {
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
    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _AdvisorColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            backgroundColor: colors.pageBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: Padding(
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
                        color: isDark
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
            ),
            title: Text(
              'CareerWise AI',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth > 700 ? 32.0 : 18.0;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding:
                      EdgeInsets.fromLTRB(horizontal, 16, horizontal, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHero(colors),
                          const SizedBox(height: 24),
                          _buildProgress(colors),
                          const SizedBox(height: 22),
                          _buildForm(constraints.maxWidth > 700, colors),
                          if (result != null) ...[
                            const SizedBox(height: 32),
                            _buildResults(colors),
                          ],
                          const SizedBox(height: 28),
                          Center(
                            child: Text(
                              'CAREERWISE  •  YOUR FUTURE, YOUR WAY',
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textSecondary,
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
      },
    );
  }

  // Premium Emerald Gradient Hero
  Widget _buildHero(_AdvisorColors colors) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF044E36),
            Color(0xFF059669),
            Color(0xFF10B981),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.28),
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
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
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
                    color: Color(0xFFD1FAE5),
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
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
    );
  }

  // Progress indicator
  Widget _buildProgress(_AdvisorColors colors) {
    return Row(
      children: [
        _progressItem('01', 'Your profile', true, colors),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: colors.cardBorder,
          ),
        ),
        _progressItem('02', 'AI analysis', false, colors),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: colors.cardBorder,
          ),
        ),
        _progressItem('03', 'Your results', false, colors),
      ],
    );
  }

  Widget _progressItem(
    String number,
    String label,
    bool active,
    _AdvisorColors colors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? colors.primary : colors.cardBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? colors.primary : colors.cardBorder,
            ),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: active ? colors.textPrimary : colors.textSecondary,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Main form
  Widget _buildForm(bool wide, _AdvisorColors colors) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.04),
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
            Text(
              'Build your career profile',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A few details will help us personalize your recommendations.',
              style: TextStyle(
                color: colors.textSecondary,
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
                      colors: colors,
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
                      colors: colors,
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
                      colors: colors,
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
                      colors: colors,
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
                colors: colors,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Skills',
                hint: 'e.g. Java, Flutter, SQL',
                helper: 'Your existing skills',
                icon: Icons.code_rounded,
                controller: _skills,
                maxLines: 3,
                colors: colors,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Interests',
                hint: 'e.g. AI, Mobile Development',
                helper: 'Topics you enjoy',
                icon: Icons.favorite_border_rounded,
                controller: _interests,
                maxLines: 3,
                colors: colors,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Career goals',
                hint: 'e.g. Become a Full Stack Developer',
                helper: 'What you want to achieve',
                icon: Icons.flag_outlined,
                controller: _goals,
                maxLines: 3,
                colors: colors,
              ),
            ],
            const SizedBox(height: 26),
            _buildGenerateButton(colors),
            const SizedBox(height: 13),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 13,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Your information is used to personalize your advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
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
    required _AdvisorColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: TextStyle(
            color: colors.textSecondary,
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
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
          ),
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
            hintStyle: TextStyle(
              color: colors.isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : const Color(0xFFA1A9BB),
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                bottom: maxLines == 1 ? 0 : 0,
              ),
              child: Icon(
                icon,
                size: 20,
                color: colors.primary,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
            ),
            filled: true,
            fillColor: colors.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                color: colors.inputBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                color: colors.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                color: colors.accent,
                width: 1.8,
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

  Widget _buildGenerateButton(_AdvisorColors colors) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading
              ? LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.6),
                    colors.accent.withValues(alpha: 0.6),
                  ],
                )
              : LinearGradient(
                  colors: [
                    colors.primary,
                    colors.accent,
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.32),
                    blurRadius: 16,
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
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AI result section
  Widget _buildResults(_AdvisorColors colors) {
    final careers = result?['careers'] as List<dynamic>? ?? [];
    final strengths = result?['strengths'] as List<dynamic>? ?? [];
    final actions = result?['actionPlan'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: colors.isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: colors.cardBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: colors.primary,
                size: 29,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your career insights',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Your personalized AI recommendations are ready.',
                      style: TextStyle(
                        color: colors.textSecondary,
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
          colors,
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
            colors: colors,
          );
        }),
        if (strengths.isNotEmpty) ...[
          const SizedBox(height: 18),
          _resultHeading(
            'Your strengths',
            'What you already bring to your career journey.',
            Icons.workspace_premium_outlined,
            colors,
          ),
          const SizedBox(height: 14),
          _listCard(strengths, Icons.check_circle_outline,
              const Color(0xFF10B981), colors),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 24),
          _resultHeading(
            'Your action plan',
            'Steps to help you move towards your goals.',
            Icons.route_outlined,
            colors,
          ),
          const SizedBox(height: 14),
          _actionCard(actions, colors),
        ],
      ],
    );
  }

  Widget _resultHeading(
    String title,
    String subtitle,
    IconData icon,
    _AdvisorColors colors,
  ) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: colors.tagBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Icon(icon, color: colors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textSecondary,
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
    required _AdvisorColors colors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.04),
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
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.accent],
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
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          _detailTitle(
              'Why this career suits you', Icons.lightbulb_outline, colors),
          const SizedBox(height: 7),
          Text(
            why,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.65,
            ),
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 18),
            _detailTitle(
                'Skills to develop', Icons.psychology_outlined, colors),
            const SizedBox(height: 10),
            _tagList(skills, colors),
          ],
          if (learning.isNotEmpty) ...[
            const SizedBox(height: 18),
            _detailTitle('Learning areas', Icons.menu_book_outlined, colors),
            const SizedBox(height: 10),
            _tagList(learning, colors),
          ],
          if (technologies.isNotEmpty) ...[
            const SizedBox(height: 18),
            _detailTitle('Technologies', Icons.devices_outlined, colors),
            const SizedBox(height: 10),
            _tagList(technologies, colors),
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
              icon: Icon(Icons.search_rounded, size: 19, color: colors.primary),
              label: Text(
                'Explore related jobs',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: colors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.accent.withValues(alpha: 0.5)),
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

  Widget _detailTitle(String title, IconData icon, _AdvisorColors colors) {
    return Row(
      children: [
        Icon(icon, size: 17, color: colors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _tagList(List<dynamic> values, _AdvisorColors colors) {
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
            color: colors.tagBg,
            border: Border.all(color: colors.tagBorder),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              color: colors.tagText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _listCard(
    List<dynamic> values,
    IconData icon,
    Color color,
    _AdvisorColors colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.cardBorder, width: 1.2),
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
                    style: TextStyle(
                      color: colors.textSecondary,
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

  Widget _actionCard(List<dynamic> actions, _AdvisorColors colors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.cardBorder, width: 1.2),
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
                    color: colors.tagBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.tagBorder),
                  ),
                  child: Text(
                    '${entry.key + 1}',
                    style: TextStyle(
                      color: colors.primary,
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
                      style: TextStyle(
                        color: colors.textSecondary,
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

class _AdvisorColors {
  final bool isDark;
  final Color pageBg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color accent;
  final Color inputFill;
  final Color inputBorder;
  final Color tagBg;
  final Color tagBorder;
  final Color tagText;

  _AdvisorColors({required this.isDark})
      : pageBg = isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4),
        cardBg = isDark ? const Color(0xFF132A1F) : Colors.white,
        cardBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFD1FAE5),
        textPrimary = isDark ? Colors.white : const Color(0xFF0F172A),
        textSecondary =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        primary = const Color(0xFF059669),
        accent = const Color(0xFF10B981),
        inputFill =
            isDark ? const Color(0xFF0A1F16) : const Color(0xFFF7FDF9),
        inputBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.40)
            : const Color(0xFFD1FAE5),
        tagBg = isDark ? const Color(0xFF0E2319) : const Color(0xFFECFDF5),
        tagBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFA7F3D0),
        tagText = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
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
        Icon(icon, size: 16, color: const Color(0xFFD1FAE5)),
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