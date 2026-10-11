import 'package:flutter/material.dart';

import 'package:careerwise_sample/services/notification_service.dart';
import 'package:careerwise_sample/services/notification_types.dart';
import 'package:careerwise_sample/services/push_sender.dart';

/// Admin-only screen used to send CareerWise announcements.
class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() =>
      _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // =========================================================
  // COLORS
  // =========================================================

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color indigo = Color(0xFF4F46E5);

  static const Color background = Color(0xFFF6F8FC);
  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE8EDF5);

  // =========================================================
  // STATE
  // =========================================================

  static const String _categoryPrefix = 'category:';

  String _audience = NotificationTopics.allUsers;

  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // =========================================================
  // HELPERS
  // =========================================================

  bool get _isCategoryAudience =>
      _audience.startsWith(_categoryPrefix);

  String? get _selectedCategory {
    if (!_isCategoryAudience) {
      return null;
    }

    return _audience.substring(_categoryPrefix.length);
  }

  String get _audienceName {
    if (_audience == NotificationTopics.allUsers) {
      return 'Everyone';
    }

    if (_audience == NotificationTopics.admins) {
      return 'Admins only';
    }

    if (_isCategoryAudience) {
      return _selectedCategory ?? 'Selected category';
    }

    return 'Selected audience';
  }

  IconData get _audienceIcon {
    if (_audience == NotificationTopics.admins) {
      return Icons.admin_panel_settings_outlined;
    }

    if (_isCategoryAudience) {
      return Icons.work_outline_rounded;
    }

    return Icons.groups_2_outlined;
  }

  Color get _audienceColor {
    if (_audience == NotificationTopics.admins) {
      return const Color(0xFF7C3AED);
    }

    if (_isCategoryAudience) {
      return const Color(0xFF0F766E);
    }

    return primary;
  }

  Color get _audienceBackground {
    if (_audience == NotificationTopics.admins) {
      return const Color(0xFFF4EEFF);
    }

    if (_isCategoryAudience) {
      return const Color(0xFFECFDF5);
    }

    return const Color(0xFFEEF4FF);
  }

  // =========================================================
  // SEND ANNOUNCEMENT
  // =========================================================

  Future<void> _send() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final confirmed = await _showConfirmation();

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final result =
      await NotificationService.instance.broadcastAnnouncement(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),

        // Keep the same behavior as your existing implementation.
        topic: _isCategoryAudience
            ? NotificationTopics.allUsers
            : _audience,

        category: _isCategoryAudience
            ? _selectedCategory
            : null,
      );

      if (!mounted) return;

      switch (result) {
        case PushResult.sent:
          _showSuccessMessage();

          _titleController.clear();
          _bodyController.clear();

          setState(() {
            _audience = NotificationTopics.allUsers;
          });

          break;

        case PushResult.notConfigured:
          _showSnack(
            'Announcement saved to history, but push notification '
                'delivery is not configured.',
            error: true,
          );
          break;

        default:
          _showSnack(
            'Could not send the announcement. Please check the debug console.',
            error: true,
          );
      }
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Something went wrong while sending the announcement.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // =========================================================
  // CONFIRM SEND
  // =========================================================

  Future<bool?> _showConfirmation() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(
              22,
              12,
              22,
              24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DDE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: primary,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Send announcement?',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'This announcement will be sent to $_audienceName.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8EDF5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleController.text.trim(),
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _bodyController.text.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          minimumSize: const Size(0, 52),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        icon: const Icon(
                          Icons.send_rounded,
                          size: 17,
                        ),
                        label: const Text('Send now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // SUCCESS
  // =========================================================

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF15803D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Announcement sent successfully.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _showSnack(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: error
              ? const Color(0xFFDC2626)
              : const Color(0xFF172033),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                color: Colors.white,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              40,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 760,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(
                          'AUDIENCE',
                          'Choose who should receive this announcement',
                        ),

                        const SizedBox(height: 11),

                        _audienceCard(),

                        const SizedBox(height: 25),

                        _sectionLabel(
                          'MESSAGE',
                          'Write a clear and useful announcement',
                        ),

                        const SizedBox(height: 11),

                        _messageCard(),

                        const SizedBox(height: 20),

                        _previewCard(),

                        const SizedBox(height: 24),

                        _sendButton(),

                        const SizedBox(height: 14),

                        const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Only administrators can send announcements',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10.5,
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
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryDark,
            primary,
            indigo,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -55,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          Positioned(
            left: -55,
            bottom: -70,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Positioned(
            right: 75,
            bottom: 30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                14,
                20,
                27,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _headerButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          Navigator.maybePop(context);
                        },
                      ),

                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.13),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              color: Color(0xFFDCE7FF),
                              size: 15,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                letterSpacing: 0.7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Container(
                        width: 59,
                        height: 59,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
                          ),
                        ),
                        child: const Icon(
                          Icons.campaign_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 16),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send Announcement',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              'Share important updates with CareerWise users',
                              style: TextStyle(
                                color: Color(0xFFDCE7FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 23),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 19,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'Announcements are sent as push notifications '
                                'and also saved to notification history.',
                            style: TextStyle(
                              color: Color(0xFFE5EDFF),
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SECTION LABEL
  // =========================================================

  Widget _sectionLabel(
      String title,
      String subtitle,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.15,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // AUDIENCE CARD
  // =========================================================

  Widget _audienceCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _audienceBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _audienceIcon,
                  color: _audienceColor,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Announcement audience',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'Select everyone, administrators, or a specific job category.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            value: _audience,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            decoration: _inputDecoration(
              label: 'Audience',
              icon: Icons.people_alt_outlined,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: NotificationTopics.allUsers,
                child: Row(
                  children: [
                    Icon(
                      Icons.groups_2_outlined,
                      size: 19,
                      color: primary,
                    ),
                    SizedBox(width: 10),
                    Text('Everyone'),
                  ],
                ),
              ),

              const DropdownMenuItem<String>(
                value: NotificationTopics.admins,
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 19,
                      color: Color(0xFF7C3AED),
                    ),
                    SizedBox(width: 10),
                    Text('Admins only'),
                  ],
                ),
              ),

              ...JobCategories.all.map(
                    (category) {
                  return DropdownMenuItem<String>(
                    value: '$_categoryPrefix$category',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.work_outline_rounded,
                          size: 18,
                          color: Color(0xFF0F766E),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            onChanged: _isSending
                ? null
                : (value) {
              if (value == null) return;

              setState(() {
                _audience = value;
              });
            },
          ),

          const SizedBox(height: 14),

          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _audienceBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  _audienceIcon,
                  color: _audienceColor,
                  size: 17,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    _audienceDescription(),
                    style: TextStyle(
                      color: _audienceColor,
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _audienceDescription() {
    if (_audience == NotificationTopics.admins) {
      return 'Only CareerWise administrators will receive this announcement.';
    }

    if (_isCategoryAudience) {
      return 'This announcement targets users interested in '
          '${_selectedCategory ?? 'this category'}.';
    }

    return 'This announcement is intended for CareerWise users '
        'who receive platform announcements.';
  }

  // =========================================================
  // MESSAGE CARD
  // =========================================================

  Widget _messageCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _IconBox(
                icon: Icons.edit_note_rounded,
                iconColor: primary,
                background: Color(0xFFEEF4FF),
              ),

              SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Announcement details',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Keep your message short, clear and informative.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'Title',
            style: TextStyle(
              color: textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _titleController,
            maxLength: 60,
            enabled: !_isSending,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(
              hint: 'e.g. CareerWise Career Fair 2026',
              icon: Icons.title_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an announcement title';
              }

              return null;
            },
            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 8),

          const Text(
            'Message',
            style: TextStyle(
              color: textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _bodyController,
            maxLength: 200,
            maxLines: 5,
            minLines: 4,
            enabled: !_isSending,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(
              hint:
              'Write the announcement message users should receive...',
              icon: Icons.notes_rounded,
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an announcement message';
              }

              return null;
            },
            onChanged: (_) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PREVIEW
  // =========================================================

  Widget _previewCard() {
    final title = _titleController.text.trim().isEmpty
        ? 'Your announcement title'
        : _titleController.text.trim();

    final body = _bodyController.text.trim().isEmpty
        ? 'Your announcement message will appear here.'
        : _bodyController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          'PREVIEW',
          'How the announcement will appear to users',
        ),

        const SizedBox(height: 11),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF9FAFF),
              ],
            ),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: border,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EEFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: Color(0xFF7C3AED),
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAREERWISE',
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 9.5,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      title,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      body,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 11),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _audienceBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _audienceName,
                        style: TextStyle(
                          color: _audienceColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SEND BUTTON
  // =========================================================

  Widget _sendButton() {
    return SizedBox(
      width: double.infinity,
      height: 57,
      child: ElevatedButton(
        onPressed: _isSending ? null : _send,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          const Color(0xFFB8C8E8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isSending
              ? const Row(
            key: ValueKey('sending'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 11),
              Text(
                'Sending announcement...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
              : const Row(
            key: ValueKey('send'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.send_rounded,
                size: 20,
              ),
              SizedBox(width: 9),
              Text(
                'Send Announcement',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration _inputDecoration({
    String? label,
    String? hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,

      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 12.5,
      ),

      hintStyle: const TextStyle(
        color: Color(0xFFADB7C6),
        fontSize: 12.5,
      ),

      prefixIcon: Icon(
        icon,
        color: primary,
        size: 20,
      ),

      filled: true,
      fillColor: const Color(0xFFF9FBFD),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: border,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primary,
          width: 1.6,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.5,
        ),
      ),
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ===========================================================
// SMALL ICON BOX
// ===========================================================

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color background;

  const _IconBox({
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 49,
      height: 49,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 24,
      ),
    );
  }
}