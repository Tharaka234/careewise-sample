import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:careerwise_sample/services/notification_service.dart';
import 'package:careerwise_sample/services/notification_types.dart';
import 'admin_profile_screen.dart';

// ==========================================================
// DYNAMIC THEME COLOR PALETTE (PREMIUM GREEN THEME)
// ==========================================================

class _AddJobColors {
  final bool isDark;

  const _AddJobColors({required this.isDark});

  // Backgrounds:
  // Light Mode: Fresh, soothing emerald/mint green tint (Tailwind emerald-50 style)
  // Dark Mode: Deep, luxurious obsidian forest green
  Color get pageBg => isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get appBarBg => isDark ? const Color(0xFF0E1B15) : Colors.white;
  Color get appBarBorder => isDark ? const Color(0xFF1A3325) : const Color(0xFFE2EFE7);

  // Inputs
  Color get inputBg => isDark ? const Color(0xFF0F1E17) : const Color(0xFFF7FAF8);
  Color get inputBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFE2EFE7);

  // Brand / Emerald Accent Colors
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

class AddJobScreen extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? existingJob;

  const AddJobScreen({
    super.key,
    this.jobId,
    this.existingJob,
  });

  bool get isEditMode => jobId != null && existingJob != null;

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final salaryController = TextEditingController();

  String selectedJobType = 'Full Time';
  String selectedCategory = JobCategories.fallback;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditMode) {
      final job = widget.existingJob!;

      titleController.text = job['title']?.toString() ?? '';
      companyController.text = job['company']?.toString() ?? '';
      locationController.text = job['location']?.toString() ?? '';
      descriptionController.text = job['description']?.toString() ?? '';
      salaryController.text = job['salary']?.toString() ?? '';

      final jobType = job['jobType']?.toString();

      if (jobType != null &&
          [
            'Full Time',
            'Part Time',
            'Internship',
            'Contract',
          ].contains(jobType)) {
        selectedJobType = jobType;
      }

      final category = job['category']?.toString();

      if (category != null && JobCategories.all.contains(category)) {
        selectedCategory = category;
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    companyController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    salaryController.dispose();
    super.dispose();
  }

  // ==========================================================
  // SAVE JOB
  // ==========================================================

  Future<void> saveJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final jobData = {
        'title': titleController.text.trim(),
        'company': companyController.text.trim(),
        'location': locationController.text.trim(),
        'description': descriptionController.text.trim(),
        'salary': salaryController.text.trim(),
        'jobType': selectedJobType,
        'category': selectedCategory,
      };

      if (widget.isEditMode) {
        await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .update({
          ...jobData,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // NOTIFICATIONS: tell subscribers this job was edited.
        unawaited(
          NotificationService.instance.notifyJobUpdated(
            jobId: widget.jobId!,
            title: titleController.text.trim(),
            company: companyController.text.trim(),
            category: selectedCategory,
          ),
        );
      } else {
        final newJob = await FirebaseFirestore.instance
            .collection('jobs')
            .add({
          ...jobData,
          'publisherId': FirebaseAuth.instance.currentUser?.uid ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // NOTIFICATIONS: tell everyone subscribed to this category.
        unawaited(
          NotificationService.instance.notifyNewJobPosted(
            jobId: newJob.id,
            title: titleController.text.trim(),
            company: companyController.text.trim(),
            category: selectedCategory,
          ),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.isEditMode
                      ? 'Job updated successfully!'
                      : 'Job added successfully!',
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.isEditMode
                      ? 'Failed to update job:\n$e'
                      : 'Failed to add job:\n$e',
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    required _AddJobColors colors,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: colors.textMuted,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: colors.primary,
        size: 20,
      ),
      filled: true,
      fillColor: colors.inputBg,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colors.inputBorder,
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colors.inputBorder,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colors.primary,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.6,
        ),
      ),
    );
  }

  // ==========================================================
  // FIELD LABEL
  // ==========================================================

  Widget fieldLabel(
    String title,
    _AddJobColors colors, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION CARD
  // ==========================================================

  Widget sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    required _AddJobColors colors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
                .withValues(alpha: colors.isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.iconBoxBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.isEditMode;

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _AddJobColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: colors.appBarBg,
            foregroundColor: colors.textPrimary,
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: colors.appBarBorder,
                height: 1,
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors.isDark
                          ? const [Color(0xFF047857), Color(0xFF059669)]
                          : const [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isEdit
                        ? Icons.edit_rounded
                        : Icons.add_business_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'Edit Job' : 'Add New Job',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              // Theme Toggle button in AppBar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                      colors.isDark
                          ? Icons.wb_sunny_rounded
                          : Icons.nightlight_round,
                      key: ValueKey<bool>(colors.isDark),
                      color: colors.isDark
                          ? const Color(0xFFFBBF24)
                          : colors.primary,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    AdminThemeManager.toggleTheme();
                  },
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              18,
              20,
              18,
              35,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 850,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // HEADER BANNER (LUSH EMERALD GRADIENT)
                      // ==================================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
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
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: colors.isDark ? 0.15 : 0.25,
                            ),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(
                                alpha: colors.isDark ? 0.35 : 0.3,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.work_outline_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEdit
                                        ? 'Update Job Posting'
                                        : 'Create a New Job',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isEdit
                                        ? 'Update the information for this job posting.'
                                        : 'Add a new opportunity for CareerWise users.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // BASIC INFORMATION
                      // ==================================================
                      sectionCard(
                        title: 'Basic Information',
                        subtitle: 'Enter the main details about the job.',
                        icon: Icons.info_outline_rounded,
                        colors: colors,
                        children: [
                          fieldLabel('Job Title', colors),

                          TextFormField(
                            controller: titleController,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: inputDecoration(
                              hint: 'e.g. Software Engineer',
                              icon: Icons.work_outline_rounded,
                              colors: colors,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter job title';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          fieldLabel('Company', colors),

                          TextFormField(
                            controller: companyController,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: inputDecoration(
                              hint: 'e.g. ABC Technologies',
                              icon: Icons.business_rounded,
                              colors: colors,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter company name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          fieldLabel('Location', colors),

                          TextFormField(
                            controller: locationController,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: inputDecoration(
                              hint: 'e.g. Colombo, Sri Lanka',
                              icon: Icons.location_on_outlined,
                              colors: colors,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter location';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // JOB DETAILS
                      // ==================================================
                      sectionCard(
                        title: 'Job Details',
                        subtitle: 'Set the employment type and salary.',
                        icon: Icons.badge_outlined,
                        colors: colors,
                        children: [
                          fieldLabel('Job Type', colors),

                          DropdownButtonFormField<String>(
                            initialValue: selectedJobType,
                            dropdownColor: colors.cardBg,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: inputDecoration(
                              hint: 'Select job type',
                              icon: Icons.schedule_rounded,
                              colors: colors,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            items: [
                              'Full Time',
                              'Part Time',
                              'Internship',
                              'Contract',
                            ].map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  style: TextStyle(color: colors.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                selectedJobType = value;
                              });
                            },
                          ),

                          const SizedBox(height: 18),

                          fieldLabel('Job Category', colors),

                          DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            isExpanded: true,
                            dropdownColor: colors.cardBg,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: inputDecoration(
                              hint: 'Select job category',
                              icon: Icons.category_outlined,
                              colors: colors,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            items: JobCategories.all.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  style: TextStyle(color: colors.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                selectedCategory = value;
                              });
                            },
                          ),

                          const SizedBox(height: 18),

                          fieldLabel('Salary', colors),

                          TextFormField(
                            controller: salaryController,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: inputDecoration(
                              hint: 'e.g. Rs. 100,000 - 150,000',
                              icon: Icons.payments_outlined,
                              colors: colors,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter salary';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // DESCRIPTION
                      // ==================================================
                      sectionCard(
                        title: 'Job Description',
                        subtitle:
                            'Describe the role, responsibilities and requirements.',
                        icon: Icons.description_outlined,
                        colors: colors,
                        children: [
                          fieldLabel('Description', colors),

                          TextFormField(
                            controller: descriptionController,
                            maxLines: 7,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: inputDecoration(
                              hint:
                                  'Enter job description, responsibilities, requirements and skills...',
                              icon: Icons.article_outlined,
                              colors: colors,
                            ).copyWith(
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter job description';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      // ==================================================
                      // SUBMIT / UPDATE BUTTON (LUSH EMERALD GRADIENT)
                      // ==================================================
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: colors.isDark
                                ? const [Color(0xFF059669), Color(0xFF047857)]
                                : const [Color(0xFF059669), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(
                                alpha: colors.isDark ? 0.35 : 0.3,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isLoading ? null : saveJob,
                            child: Center(
                              child: isLoading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Saving...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isEdit
                                              ? Icons.save_rounded
                                              : Icons.add_circle_outline_rounded,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          isEdit ? 'Update Job' : 'Add Job',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Center(
                        child: Text(
                          'All fields marked with * are required',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}