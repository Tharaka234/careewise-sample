import 'dart:async';

import 'package:flutter/material.dart';

import 'package:careerwise_sample/screens/notification_settings_screen.dart';
import 'package:careerwise_sample/services/notification_service.dart';
import 'package:careerwise_sample/services/notification_types.dart';
import 'admin_profile_screen.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {
  // =========================================================
  // FILTERS
  // =========================================================

  static const String filterAll = 'All';
  static const String filterJobs = 'Jobs';
  static const String filterUpdates = 'Updates';
  static const String filterAnnouncements = 'Announcements';

  String selectedFilter = filterAll;

  // =========================================================
  // DATA
  // =========================================================

  late final Stream<List<NotificationHistoryItem>> _stream =
      NotificationService.instance.watchHistory();

  StreamSubscription<Set<String>>? _dismissedSubscription;

  Set<String> _dismissed = <String>{};

  List<NotificationHistoryItem> _currentVisibleItems = const [];

  @override
  void initState() {
    super.initState();

    _dismissedSubscription =
        NotificationService.instance.watchDismissedHistory().listen(
      (ids) {
        if (!mounted) return;

        setState(() {
          _dismissed = ids;
        });
      },
    );
  }

  @override
  void dispose() {
    _dismissedSubscription?.cancel();
    super.dispose();
  }

  // =========================================================
  // VISIBILITY
  // =========================================================

  bool _visibleToUser(NotificationHistoryItem item) {
    if (_dismissed.contains(item.id)) {
      return false;
    }

    if (item.audience == HistoryAudience.admins &&
        !NotificationService.instance.isAdmin) {
      return false;
    }

    return true;
  }

  // =========================================================
  // FILTER
  // =========================================================

  bool _matchesFilter(NotificationHistoryItem item) {
    switch (selectedFilter) {
      case filterJobs:
        return item.type == NotificationTypes.newJob;

      case filterUpdates:
        return item.type == NotificationTypes.jobUpdated ||
            item.type == NotificationTypes.jobDeleted;

      case filterAnnouncements:
        return item.category == null;

      case filterAll:
      default:
        return true;
    }
  }

  int _filterCount(
    List<NotificationHistoryItem> items,
    String filter,
  ) {
    switch (filter) {
      case filterJobs:
        return items
            .where((item) => item.type == NotificationTypes.newJob)
            .length;

      case filterUpdates:
        return items
            .where((item) =>
                item.type == NotificationTypes.jobUpdated ||
                item.type == NotificationTypes.jobDeleted)
            .length;

      case filterAnnouncements:
        return items.where((item) => item.category == null).length;

      default:
        return items.length;
    }
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> _deleteNotifications(
    List<NotificationHistoryItem> items,
  ) async {
    if (items.isEmpty) return;

    final ids = items.map((item) => item.id).toList();

    setState(() {
      _dismissed = {
        ..._dismissed,
        ...ids,
      };
    });

    try {
      await NotificationService.instance.dismissHistory(ids);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _dismissed = _dismissed.difference(ids.toSet());
      });

      _showMessage(
        'Could not remove notification.',
        error: true,
      );

      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF042618),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
            ),
          ),
          content: Text(
            ids.length == 1
                ? 'Notification removed'
                : '${ids.length} notifications removed',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: const Color(0xFF6EE7B7),
            onPressed: () {
              if (!mounted) return;

              setState(() {
                _dismissed = _dismissed.difference(ids.toSet());
              });

              NotificationService.instance.restoreHistory(ids);
            },
          ),
        ),
      );
  }

  // =========================================================
  // CLEAR ALL BOTTOM SHEET
  // =========================================================

  Future<void> _showClearConfirmation(_NotificationColors colors) async {
    if (_currentVisibleItems.isEmpty) {
      _showMessage('No notifications to clear.');
      return;
    }

    final bool? shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(
              24,
              12,
              24,
              24,
            ),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.cardBorder, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.cardBorder,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.delete_sweep_outlined,
                    size: 34,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Clear notifications?',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This will remove ${_currentVisibleItems.length} '
                  'notification${_currentVisibleItems.length == 1 ? '' : 's'} '
                  'currently shown in your notification history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          side: BorderSide(
                            color: colors.cardBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: colors.textPrimary,
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
                          Icons.delete_outline_rounded,
                          size: 19,
                        ),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
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

    if (shouldDelete == true) {
      await _deleteNotifications(_currentVisibleItems);
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor:
              error ? const Color(0xFFDC2626) : const Color(0xFF042618),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
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
        final colors = _NotificationColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          body: StreamBuilder<List<NotificationHistoryItem>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error, colors);
              }

              if (!snapshot.hasData) {
                return _buildLoadingState(colors);
              }

              final allVisibleItems =
                  snapshot.data!.where(_visibleToUser).toList();

              allVisibleItems.sort(
                (a, b) {
                  final aDate =
                      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

                  final bDate =
                      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

                  return bDate.compareTo(aDate);
                },
              );

              final filteredItems =
                  allVisibleItems.where(_matchesFilter).toList();

              _currentVisibleItems = filteredItems;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeroHeader(allVisibleItems, colors),
                  ),
                  SliverToBoxAdapter(
                    child: _buildFilterSection(allVisibleItems, colors),
                  ),
                  if (filteredItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(colors),
                    )
                  else
                    ..._buildGroupedNotifications(filteredItems, colors),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 30),
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
  // PREMIUM EMERALD HEADER
  // =========================================================

  Widget _buildHeroHeader(
    List<NotificationHistoryItem> items,
    _NotificationColors colors,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF044E36),
            Color(0xFF059669),
            Color(0xFF10B981),
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
            top: -50,
            right: -35,
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
            top: 80,
            right: 70,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
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
                26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _glassHeaderButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          Navigator.maybePop(context);
                        },
                      ),
                      const Spacer(),
                      // THEME TOGGLE BUTTON
                      _glassHeaderButton(
                        icon: colors.isDark
                            ? Icons.wb_sunny_rounded
                            : Icons.nightlight_round,
                        onTap: () {
                          AdminThemeManager.toggleTheme();
                        },
                      ),
                      const SizedBox(width: 10),
                      _glassHeaderButton(
                        icon: Icons.settings_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const NotificationSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 29,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Stay updated with your career journey',
                              style: TextStyle(
                                color: Color(0xFFD1FAE5),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${items.length} notification${items.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                items.isEmpty
                                    ? 'You\'re all caught up'
                                    : 'Latest career updates for you',
                                style: const TextStyle(
                                  color: Color(0xFFD1FAE5),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (items.isNotEmpty)
                          TextButton(
                            onPressed: () => _showClearConfirmation(colors),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'Clear all',
                              style: TextStyle(
                                fontSize: 12,
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
          ),
        ],
      ),
    );
  }

  Widget _glassHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
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
              color: Colors.white.withValues(alpha: 0.22),
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
  // FILTER SECTION
  // =========================================================

  Widget _buildFilterSection(
    List<NotificationHistoryItem> items,
    _NotificationColors colors,
  ) {
    final filters = [
      filterAll,
      filterJobs,
      filterUpdates,
      filterAnnouncements,
    ];

    return Container(
      padding: const EdgeInsets.only(
        top: 22,
        bottom: 8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: filters.map(
            (filter) {
              final selected = selectedFilter == filter;
              final count = _filterCount(items, filter);

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? colors.primary : colors.chipBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? colors.primary : colors.chipBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selected
                                ? colors.primary.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: selected ? 14 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filterIcon(filter),
                            size: 17,
                            color: selected
                                ? Colors.white
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            filter,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : colors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 7),
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : colors.countBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : colors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  IconData _filterIcon(String filter) {
    switch (filter) {
      case filterJobs:
        return Icons.work_outline_rounded;

      case filterUpdates:
        return Icons.auto_awesome_outlined;

      case filterAnnouncements:
        return Icons.campaign_outlined;

      default:
        return Icons.grid_view_rounded;
    }
  }

  // =========================================================
  // GROUP NOTIFICATIONS
  // =========================================================

  List<Widget> _buildGroupedNotifications(
    List<NotificationHistoryItem> items,
    _NotificationColors colors,
  ) {
    final today = <NotificationHistoryItem>[];
    final yesterday = <NotificationHistoryItem>[];
    final earlier = <NotificationHistoryItem>[];

    final now = DateTime.now();

    final todayDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    for (final item in items) {
      final time = item.createdAt;

      if (time == null) {
        today.add(item);
        continue;
      }

      final itemDate = DateTime(
        time.year,
        time.month,
        time.day,
      );

      if (itemDate == todayDate) {
        today.add(item);
      } else if (itemDate == yesterdayDate) {
        yesterday.add(item);
      } else {
        earlier.add(item);
      }
    }

    final slivers = <Widget>[];

    if (today.isNotEmpty) {
      slivers.add(
        _buildGroupTitle(
          'TODAY',
          today.length,
          colors,
        ),
      );

      slivers.add(
        _buildNotificationGroup(today, colors),
      );
    }

    if (yesterday.isNotEmpty) {
      slivers.add(
        _buildGroupTitle(
          'YESTERDAY',
          yesterday.length,
          colors,
        ),
      );

      slivers.add(
        _buildNotificationGroup(yesterday, colors),
      );
    }

    if (earlier.isNotEmpty) {
      slivers.add(
        _buildGroupTitle(
          'EARLIER',
          earlier.length,
          colors,
        ),
      );

      slivers.add(
        _buildNotificationGroup(earlier, colors),
      );
    }

    return slivers;
  }

  Widget _buildGroupTitle(
    String title,
    int count,
    _NotificationColors colors,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          22,
          20,
          11,
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.60),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                color: colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationGroup(
    List<NotificationHistoryItem> items,
    _NotificationColors colors,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDismissibleCard(item, colors),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  // =========================================================
  // DISMISSIBLE
  // =========================================================

  Widget _buildDismissibleCard(
    NotificationHistoryItem item,
    _NotificationColors colors,
  ) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _deleteNotifications([item]);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFF87171),
              Color(0xFFDC2626),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 25,
            ),
            SizedBox(height: 3),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: _buildNotificationCard(item, colors),
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _buildNotificationCard(
    NotificationHistoryItem item,
    _NotificationColors colors,
  ) {
    final style = _getNotificationStyle(item, colors.isDark);

    final isDeleted = item.type == NotificationTypes.jobDeleted;

    final isJob = item.jobId != null &&
        !isDeleted &&
        (item.type == NotificationTypes.newJob ||
            item.type == NotificationTypes.jobUpdated);

    return Material(
      color: colors.cardBg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isJob
            ? () {
                NotificationService.instance.openHistoryItem(item);
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colors.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black26
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: style.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      15,
                      16,
                      10,
                      16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: style.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            style.icon,
                            color: style.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      style.label.toUpperCase(),
                                      style: TextStyle(
                                        color: style.color,
                                        fontSize: 9.5,
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _timeAgo(item.createdAt),
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_isRecent(item.createdAt)) ...[
                                    const SizedBox(width: 7),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: style.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 7),
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 15.5,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.15,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                item.body,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (item.category != null) ...[
                                const SizedBox(height: 13),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.isDark
                                        ? const Color(0xFF0E2319)
                                        : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: colors.cardBorder,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.sell_outlined,
                                        color: style.color,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          item.category!,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (isJob) ...[
                                const SizedBox(height: 15),
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    NotificationService.instance
                                        .openHistoryItem(item);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.type ==
                                                  NotificationTypes.jobUpdated
                                              ? 'View changes'
                                              : 'View opportunity',
                                          style: TextStyle(
                                            color: style.color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: style.color,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          color: colors.cardBg,
                          splashRadius: 20,
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: colors.textSecondary,
                            size: 21,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colors.cardBorder,
                              width: 1.2,
                            ),
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteNotifications([item]);
                            }
                          },
                          itemBuilder: (context) {
                            return const [
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Remove notification',
                                      style: TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // NOTIFICATION STYLE
  // =========================================================

  _NotificationStyle _getNotificationStyle(
    NotificationHistoryItem item,
    bool isDark,
  ) {
    if (item.type == NotificationTypes.newJob) {
      return _NotificationStyle(
        label: 'New opportunity',
        icon: Icons.work_outline_rounded,
        color: const Color(0xFF059669),
        background: isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.40)
            : const Color(0xFFD1FAE5),
      );
    }

    if (item.type == NotificationTypes.jobUpdated) {
      return _NotificationStyle(
        label: 'Job updated',
        icon: Icons.auto_awesome_outlined,
        color: const Color(0xFFD97706),
        background: isDark
            ? const Color(0xFF78350F).withValues(alpha: 0.35)
            : const Color(0xFFFEF3C7),
      );
    }

    if (item.type == NotificationTypes.jobDeleted) {
      return _NotificationStyle(
        label: 'Job removed',
        icon: Icons.work_off_outlined,
        color: const Color(0xFFEF4444),
        background: isDark
            ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
            : const Color(0xFFFEE2E2),
      );
    }

    return _NotificationStyle(
      label: 'Announcement',
      icon: Icons.campaign_outlined,
      color: const Color(0xFF10B981),
      background: isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.40)
          : const Color(0xFFECFDF5),
    );
  }

  // =========================================================
  // RECENT INDICATOR
  // =========================================================

  bool _isRecent(DateTime? time) {
    if (time == null) return true;

    final difference = DateTime.now().difference(time);

    return difference.inHours < 12;
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState(_NotificationColors colors) {
    String title;
    String description;
    IconData icon;

    switch (selectedFilter) {
      case filterJobs:
        title = 'No job alerts yet';
        description =
            'New career opportunities will appear here when they become available.';
        icon = Icons.work_outline_rounded;
        break;

      case filterUpdates:
        title = 'No updates yet';
        description =
            'Changes to jobs and other important updates will appear here.';
        icon = Icons.auto_awesome_outlined;
        break;

      case filterAnnouncements:
        title = 'No announcements';
        description =
            'CareerWise announcements and important news will appear here.';
        icon = Icons.campaign_outlined;
        break;

      default:
        title = 'You\'re all caught up!';
        description =
            'There are no notifications right now. We\'ll let you know when something important happens.';
        icon = Icons.notifications_none_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          30,
          30,
          30,
          60,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors.isDark
                      ? [
                          const Color(0xFF064E3B),
                          const Color(0xFF042F23),
                        ]
                      : [
                          const Color(0xFFD1FAE5),
                          const Color(0xFFA7F3D0),
                        ],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                icon,
                color: colors.primary,
                size: 47,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 320,
              ),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 22),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.tune_rounded,
                size: 17,
              ),
              label: const Text(
                'Notification settings',
              ),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoadingState(_NotificationColors colors) {
    return Container(
      color: colors.pageBg,
      child: Column(
        children: [
          _buildLoadingHeader(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      color: colors.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Loading notifications...',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _buildLoadingHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF044E36),
            Color(0xFF059669),
            Color(0xFF10B981),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _glassHeaderButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () {
                  Navigator.maybePop(context);
                },
              ),
              const SizedBox(height: 28),
              const Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Stay updated with your career journey',
                style: TextStyle(
                  color: Color(0xFFD1FAE5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildErrorState(Object? error, _NotificationColors colors) {
    return Container(
      color: colors.pageBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                10,
                18,
                10,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.maybePop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.cloud_off_outlined,
                          color: Color(0xFFEF4444),
                          size: 39,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Couldn\'t load notifications',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TIME
  // =========================================================

  String _timeAgo(DateTime? time) {
    if (time == null) {
      return 'Just now';
    }

    final difference = DateTime.now().difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${time.day}/${time.month}/${time.year}';
  }
}

// ===========================================================
// NOTIFICATION COLORS HELPER
// ===========================================================

class _NotificationColors {
  final bool isDark;
  final Color pageBg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color accent;
  final Color chipBg;
  final Color chipBorder;
  final Color countBg;

  _NotificationColors({required this.isDark})
      : pageBg = isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4),
        cardBg = isDark ? const Color(0xFF132A1F) : Colors.white,
        cardBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFE2E8F0),
        textPrimary = isDark ? Colors.white : const Color(0xFF0F172A),
        textSecondary =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        primary = const Color(0xFF059669),
        accent = const Color(0xFF10B981),
        chipBg = isDark ? const Color(0xFF132A1F) : Colors.white,
        chipBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFD1FAE5),
        countBg = isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.40)
            : const Color(0xFFD1FAE5);
}

// ===========================================================
// NOTIFICATION STYLE MODEL
// ===========================================================

class _NotificationStyle {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _NotificationStyle({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });
}