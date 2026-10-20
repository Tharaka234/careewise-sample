import 'package:flutter/material.dart';

import 'package:careerwise_sample/services/notification_service.dart';
import 'package:careerwise_sample/services/notification_types.dart';
import 'package:careerwise_sample/services/push_sender.dart';
import 'admin_profile_screen.dart';

// ==========================================================
// DYNAMIC THEME COLOR PALETTE (PREMIUM GREEN THEME)
// ==========================================================

class _BroadcastColors {
  final bool isDark;

  const _BroadcastColors({required this.isDark});

  // Backgrounds:
  // Light: Soft emerald-mint tint (#F0FDF4)
  // Dark: Deep luxurious obsidian forest green (#0A140F)
  Color get pageBg => isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get cardSurface => isDark ? const Color(0xFF0F1E17) : const Color(0xFFF8FAF9);

  // Inputs
  Color get inputBg => isDark ? const Color(0xFF0E1A14) : const Color(0xFFF7FAF8);
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

/// Admin-only screen used to send CareerWise announcements.
class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

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

  bool get _isCategoryAudience => _audience.startsWith(_categoryPrefix);

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

  Color _getAudienceColor(_BroadcastColors colors) {
    if (_audience == NotificationTopics.admins) {
      return const Color(0xFF8B5CF6);
    }
    if (_isCategoryAudience) {
      return colors.isDark ? const Color(0xFF34D399) : const Color(0xFF0F766E);
    }
    return colors.primary;
  }

  Color _getAudienceBackground(_BroadcastColors colors) {
    if (_audience == NotificationTopics.admins) {
      return colors.isDark ? const Color(0x338B5CF6) : const Color(0xFFF3E8FF);
    }
    if (_isCategoryAudience) {
      return colors.isDark ? const Color(0x3310B981) : const Color(0xFFECFDF5);
    }
    return colors.isDark ? const Color(0x33059669) : const Color(0xFFE8F7F0);
  }

  // =========================================================
  // SEND ANNOUNCEMENT
  // =========================================================

  Future<void> _send(_BroadcastColors colors) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final confirmed = await _showConfirmation(colors);

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
        topic: _isCategoryAudience
            ? NotificationTopics.allUsers
            : _audience,
        category: _isCategoryAudience ? _selectedCategory : null,
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
            'Announcement saved to history, but push notification delivery is not configured.',
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
        'Something went wrong while sending the announcement: $e',
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
  // CONFIRM SEND BOTTOM SHEET
  // =========================================================

  Future<bool?> _showConfirmation(_BroadcastColors colors) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.cardBorder,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 22),

                // Icon badge
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: colors.iconBoxBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: colors.primary,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Send Announcement?',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'This broadcast will be dispatched to $_audienceName.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 18),

                // Mini preview container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: colors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleController.text.trim(),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _bodyController.text.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                          height: 1.4,
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
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          minimumSize: const Size(0, 50),
                          side: BorderSide(color: colors.cardBorder, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: colors.isDark
                                ? const [Color(0xFF059669), Color(0xFF047857)]
                                : const [Color(0xFF059669), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(context, true),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Send Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
        );
      },
    );
  }

  // =========================================================
  // SUCCESS / ERROR NOTIFICATIONS
  // =========================================================

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Announcement broadcast sent successfully!',
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
              : const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _BroadcastColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(colors),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 40),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel(
                              'AUDIENCE',
                              'Choose who should receive this broadcast alert',
                              colors,
                            ),
                            const SizedBox(height: 11),
                            _audienceCard(colors),

                            const SizedBox(height: 24),

                            _sectionLabel(
                              'MESSAGE DETAILS',
                              'Write a clear, concise and impactful announcement',
                              colors,
                            ),
                            const SizedBox(height: 11),
                            _messageCard(colors),

                            const SizedBox(height: 24),

                            _previewCard(colors),

                            const SizedBox(height: 26),

                            _sendButton(colors),

                            const SizedBox(height: 14),

                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 14,
                                    color: colors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Only verified CareerWise administrators can send broadcast announcements',
                                    style: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 11,
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
      },
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(_BroadcastColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.isDark
              ? const [
                  Color(0xFF03442C),
                  Color(0xFF065F46),
                  Color(0xFF047857),
                ]
              : const [
                  Color(0xFF047857),
                  Color(0xFF059669),
                  Color(0xFF10B981),
                ],
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
          // Background ambient circles
          Positioned(
            right: -45,
            top: -55,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
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
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Back button, Admin Badge, and Theme Toggle button
                  Row(
                    children: [
                      _headerButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.maybePop(context),
                      ),
                      const Spacer(),

                      // Admin pill badge
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
                              Icons.admin_panel_settings_outlined,
                              color: Colors.white,
                              size: 15,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'ADMIN BROADCAST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Header icon and titles
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.campaign_outlined,
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
                              'Broadcast Announcement',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Send instant push notifications and alerts to platform users',
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

                  const SizedBox(height: 20),

                  // Informational tip container
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Announcements are instantly broadcasted as push notifications to devices and securely archived in candidates\' notification history.',
                            style: TextStyle(
                              color: Color(0xFFF0FDF4),
                              fontSize: 12,
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
  // SECTION LABEL
  // =========================================================

  Widget _sectionLabel(
    String title,
    String subtitle,
    _BroadcastColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // AUDIENCE CARD
  // =========================================================

  Widget _audienceCard(_BroadcastColors colors) {
    final audColor = _getAudienceColor(colors);
    final audBg = _getAudienceBackground(colors);

    return _card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: audBg,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: audColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  _audienceIcon,
                  color: audColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Audience',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Choose whether to alert all users, administrators, or users in a particular industry category.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: _audience,
            isExpanded: true,
            dropdownColor: colors.cardBg,
            borderRadius: BorderRadius.circular(16),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              label: 'Selected Audience',
              icon: Icons.people_alt_outlined,
              colors: colors,
            ),
            items: [
              DropdownMenuItem<String>(
                value: NotificationTopics.allUsers,
                child: Row(
                  children: [
                    Icon(
                      Icons.groups_2_outlined,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    const Text('Everyone (All registered users)'),
                  ],
                ),
              ),
              const DropdownMenuItem<String>(
                value: NotificationTopics.admins,
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 20,
                      color: Color(0xFF8B5CF6),
                    ),
                    SizedBox(width: 10),
                    Text('Admins only'),
                  ],
                ),
              ),
              ...JobCategories.all.map((category) {
                return DropdownMenuItem<String>(
                  value: '$_categoryPrefix$category',
                  child: Row(
                    children: [
                      Icon(
                        Icons.work_outline_rounded,
                        size: 19,
                        color: colors.isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF0F766E),
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
              }),
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

          // Live pill status summary
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: audBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: audColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _audienceIcon,
                  color: audColor,
                  size: 17,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _audienceDescription(),
                    style: TextStyle(
                      color: audColor,
                      fontSize: 12,
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
      return 'Targeting candidates subscribed or interested in ${_selectedCategory ?? 'this category'}.';
    }
    return 'Broadcast will be delivered to every active user across the platform.';
  }

  // =========================================================
  // MESSAGE CARD
  // =========================================================

  Widget _messageCard(_BroadcastColors colors) {
    return _card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(
                icon: Icons.edit_note_rounded,
                iconColor: colors.primary,
                background: colors.iconBoxBg,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Announcement Content',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Keep your notification title and body engaging, accurate, and easy to read.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'Announcement Title *',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _titleController,
            maxLength: 60,
            enabled: !_isSending,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              hint: 'e.g. CareerWise Tech Career Fair 2026',
              icon: Icons.title_rounded,
              colors: colors,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an announcement title';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 8),

          Text(
            'Announcement Message *',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _bodyController,
            maxLength: 250,
            maxLines: 5,
            minLines: 4,
            enabled: !_isSending,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14.5,
              height: 1.45,
            ),
            decoration: _inputDecoration(
              hint:
                  'Write the announcement message details that users will read upon receiving...',
              icon: Icons.notes_rounded,
              alignLabelWithHint: true,
              colors: colors,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an announcement message';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PREVIEW CARD (MOBILE NOTIFICATION SIMULATION)
  // =========================================================

  Widget _previewCard(_BroadcastColors colors) {
    final title = _titleController.text.trim().isEmpty
        ? 'Your announcement title'
        : _titleController.text.trim();

    final body = _bodyController.text.trim().isEmpty
        ? 'Your announcement message will appear here in the preview.'
        : _bodyController.text.trim();

    final audColor = _getAudienceColor(colors);
    final audBg = _getAudienceBackground(colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          'LIVE PREVIEW',
          'Simulated appearance on user mobile devices',
          colors,
        ),
        const SizedBox(height: 11),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.cardBorder, width: 1.2),
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
              // Top preview row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors.isDark
                            ? const [Color(0xFF047857), Color(0xFF059669)]
                            : const [Color(0xFF059669), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'CAREERWISE',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 10,
                                letterSpacing: 0.9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: colors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'NOW',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: audBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: audColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'Target: $_audienceName',
                        style: TextStyle(
                          color: audColor,
                          fontSize: 10.5,
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
  // SEND BUTTON (LUSH EMERALD GRADIENT)
  // =========================================================

  Widget _sendButton(_BroadcastColors colors) {
    return Container(
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
          onTap: _isSending ? null : () => _send(colors),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isSending
                  ? const Row(
                      key: ValueKey('sending'),
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          'Broadcasting announcement...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Send Announcement',
                          style: TextStyle(
                            fontSize: 15.5,
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
    required _BroadcastColors colors,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: TextStyle(
        color: colors.textSecondary,
        fontSize: 13,
      ),
      hintStyle: TextStyle(
        color: colors.textMuted,
        fontSize: 13.5,
      ),
      prefixIcon: Icon(
        icon,
        color: colors.primary,
        size: 20,
      ),
      filled: true,
      fillColor: colors.inputBg,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
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
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  // =========================================================
  // CARD CONTAINER
  // =========================================================

  Widget _card({
    required Widget child,
    required _BroadcastColors colors,
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
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 24,
      ),
    );
  }
}