
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';

// ==========================================
// MAIN
// ==========================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('====================================');
  debugPrint('CAREERWISE FIREBASE INITIALIZED');
  debugPrint(
    'PROJECT ID: ${Firebase.app().options.projectId}',
  );
  debugPrint('====================================');

  // Run Wi-Fi / Firestore test without
  // blocking the application startup.
  unawaited(testWifiFirestoreConnection());

  // Register Firebase background notifications.
  if (NotificationService.isSupported) {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }

  // Initialize notification service.
  try {
    await NotificationService.instance.init();
    debugPrint('Notification service initialized');
  } catch (e) {
    debugPrint('Notification initialization error: $e');
  }

  runApp(const CareerWiseApp());
}

// ==========================================
// WIFI / FIRESTORE CONNECTION TEST
// ==========================================

Future<void> testWifiFirestoreConnection() async {
  debugPrint('');
  debugPrint('========== WIFI FIRESTORE TEST START ==========');

  debugPrint(
    'PROJECT ID: ${Firebase.app().options.projectId}',
  );

  debugPrint(
    'AUTH USER: ${FirebaseAuth.instance.currentUser != null}',
  );

  try {
    final result = await FirebaseFirestore.instance
        .collection('jobs')
        .limit(1)
        .get(
      const GetOptions(source: Source.server),
    )
        .timeout(const Duration(seconds: 15));

    debugPrint('WIFI FIRESTORE SUCCESS');
    debugPrint('JOBS DOCUMENT COUNT: ${result.docs.length}');
    debugPrint('DATA FROM CACHE: ${result.metadata.isFromCache}');
  } on TimeoutException catch (e) {
    debugPrint('WIFI FIRESTORE FAILED');
    debugPrint('ERROR TYPE: TIMEOUT');
    debugPrint('ERROR: $e');
  } on FirebaseException catch (e) {
    debugPrint('WIFI FIRESTORE FAILED');
    debugPrint('ERROR CODE: ${e.code}');
    debugPrint('ERROR MESSAGE: ${e.message}');

    if (e.code == 'unavailable') {
      debugPrint(
        'POSSIBLE NETWORK ISSUE: Firestore server unavailable',
      );
    } else if (e.code == 'permission-denied') {
      debugPrint(
        'POSSIBLE RULES ISSUE: Check Firestore permissions',
      );
    } else if (e.code == 'failed-precondition') {
      debugPrint(
        'POSSIBLE INDEX ISSUE: Check Firestore indexes',
      );
    }
  } catch (e) {
    debugPrint('WIFI FIRESTORE FAILED');
    debugPrint('ERROR: $e');
  }

  debugPrint('========== WIFI FIRESTORE TEST END ==========');
  debugPrint('');
}

// ==========================================
// FIRESTORE DIAGNOSTIC TEST
// ==========================================

Future<void> testCareerWiseData(String uid) async {
  debugPrint('');
  debugPrint('========== CAREERWISE FIRESTORE TEST ==========');

  debugPrint(
    'PROJECT ID: ${Firebase.app().options.projectId}',
  );

  // ------------------------------------------
  // TEST 1: JOBS
  // ------------------------------------------

  try {
    final jobs = await FirebaseFirestore.instance
        .collection('jobs')
        .limit(5)
        .get(
      const GetOptions(source: Source.server),
    )
        .timeout(const Duration(seconds: 15));

    debugPrint('JOBS FOUND: ${jobs.docs.length}');

    for (final doc in jobs.docs) {
      debugPrint('JOB DOCUMENT: ${doc.id}');
    }
  } on FirebaseException catch (e) {
    debugPrint('JOBS FIREBASE ERROR: ${e.code}');
    debugPrint('JOBS ERROR MESSAGE: ${e.message}');
  } on TimeoutException catch (e) {
    debugPrint('JOBS TIMEOUT: $e');
  } catch (e) {
    debugPrint('JOBS ERROR: $e');
  }

  // ------------------------------------------
  // TEST 2: APPLICATIONS
  // ------------------------------------------

  try {
    final applications = await FirebaseFirestore.instance
        .collection('applications')
        .where('userId', isEqualTo: uid)
        .limit(5)
        .get(
      const GetOptions(source: Source.server),
    )
        .timeout(const Duration(seconds: 15));

    debugPrint(
      'APPLICATIONS FOUND: ${applications.docs.length}',
    );

    for (final doc in applications.docs) {
      debugPrint('APPLICATION DOCUMENT: ${doc.id}');
    }
  } on FirebaseException catch (e) {
    debugPrint('APPLICATIONS FIREBASE ERROR: ${e.code}');
    debugPrint('APPLICATIONS ERROR MESSAGE: ${e.message}');
  } on TimeoutException catch (e) {
    debugPrint('APPLICATIONS TIMEOUT: $e');
  } catch (e) {
    debugPrint('APPLICATIONS ERROR: $e');
  }

  // ------------------------------------------
  // TEST 3: PRIVATE NOTIFICATIONS
  // ------------------------------------------

  try {
    final notifications = await FirebaseFirestore.instance
        .collection('notification_history')
        .where('audience', isEqualTo: 'user')
        .where('recipientUid', isEqualTo: uid)
        .limit(5)
        .get(
      const GetOptions(source: Source.server),
    )
        .timeout(const Duration(seconds: 15));

    debugPrint(
      'PRIVATE NOTIFICATIONS FOUND: '
          '${notifications.docs.length}',
    );

    for (final doc in notifications.docs) {
      debugPrint('NOTIFICATION DOCUMENT: ${doc.id}');
    }
  } on FirebaseException catch (e) {
    debugPrint('NOTIFICATIONS FIREBASE ERROR: ${e.code}');
    debugPrint('NOTIFICATIONS ERROR MESSAGE: ${e.message}');
  } on TimeoutException catch (e) {
    debugPrint('NOTIFICATIONS TIMEOUT: $e');
  } catch (e) {
    debugPrint('NOTIFICATIONS ERROR: $e');
  }

  debugPrint('========== TEST COMPLETED ==========');
  debugPrint('');
}

// ==========================================
// CAREERWISE APP
// ==========================================

class CareerWiseApp extends StatelessWidget {
  const CareerWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareerWise',

      // Notification tap navigation.
      navigatorKey: appNavigatorKey,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),

      home: const AuthGate(),
    );
  }
}

// ==========================================
// AUTH GATE
// ==========================================

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _checkedUid;
  String? _adminFutureUid;
  Future<bool>? _adminFuture;

  // ------------------------------------------
  // ADMIN CHECK
  // ------------------------------------------

  Future<bool> checkAdmin(String uid) async {
    debugPrint('========== ADMIN CHECK ==========');

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get(
        const GetOptions(source: Source.server),
      )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        'Admin document exists: ${adminDoc.exists}',
      );

      if (!adminDoc.exists) {
        debugPrint('Normal user: no admin document');
        return false;
      }

      final role = adminDoc.data()?['role'];

      debugPrint('Admin role: $role');

      return role
          ?.toString()
          .trim()
          .toLowerCase() ==
          'admin';
    } on FirebaseException catch (e) {
      debugPrint('ADMIN FIREBASE ERROR: ${e.code}');
      debugPrint('ADMIN ERROR MESSAGE: ${e.message}');
      rethrow;
    } on TimeoutException catch (e) {
      debugPrint('ADMIN CHECK TIMEOUT: $e');
      rethrow;
    } catch (e) {
      debugPrint('ADMIN CHECK ERROR: $e');
      rethrow;
    }
  }

  // ------------------------------------------
  // CACHE ADMIN CHECK FUTURE
  // ------------------------------------------

  Future<bool> _getAdminFuture(String uid) {
    if (_adminFutureUid != uid || _adminFuture == null) {
      _adminFutureUid = uid;
      _adminFuture = checkAdmin(uid);
    }

    return _adminFuture!;
  }

  // ------------------------------------------
  // RETRY ADMIN CHECK
  // ------------------------------------------

  void _retryAdminCheck() {
    setState(() {
      _adminFuture = null;
    });
  }

  // ------------------------------------------
  // FIRESTORE TEST ONCE PER USER
  // ------------------------------------------

  void _runFirestoreTestOnce(String uid) {
    if (_checkedUid == uid) {
      return;
    }

    _checkedUid = uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      unawaited(testCareerWiseData(uid));
    });
  }

  // ------------------------------------------
  // AUTH STATE
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // AUTH LOADING
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // AUTH ERROR
        if (snapshot.hasError) {
          debugPrint(
            'AUTH ERROR: ${snapshot.error}',
          );

          return const Scaffold(
            body: Center(
              child: Text(
                'Authentication error. Please try again.',
              ),
            ),
          );
        }

        // USER LOGGED IN
        if (snapshot.hasData) {
          final user = snapshot.data!;

          _runFirestoreTestOnce(user.uid);

          return FutureBuilder<bool>(
            key: ValueKey(user.uid),
            future: _getAdminFuture(user.uid),
            builder: (context, adminSnapshot) {
              // ADMIN CHECK LOADING
              if (adminSnapshot.connectionState !=
                  ConnectionState.done) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // ADMIN CHECK ERROR
              if (adminSnapshot.hasError) {
                debugPrint(
                  'ADMIN CHECK FAILED: ${adminSnapshot.error}',
                );

                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to verify your account role.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check your internet connection '
                                'and try again.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _retryAdminCheck,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // ADMIN DASHBOARD
              if (adminSnapshot.data == true) {
                debugPrint(
                  'NAVIGATION: Admin Dashboard',
                );

                return const AdminDashboardScreen();
              }

              // NORMAL USER HOME
              debugPrint('NAVIGATION: Home Screen');

              return const HomeScreen();
            },
          );
        }

        // USER LOGGED OUT
        _checkedUid = null;
        _adminFutureUid = null;
        _adminFuture = null;

        return const LoginScreen();
      },
    );
  }
}