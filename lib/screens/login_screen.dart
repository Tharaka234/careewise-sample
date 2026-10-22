
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

import 'register_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';

const emerald = Color(0xFF10B981);
const mint = Color(0xFF6EE7B7);
const darkGreen = Color(0xFF041B14);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  VideoPlayerController? _videoController;

  bool isLoading = false;
  bool isResettingPassword = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.asset(
      'assets/videos/career_background.mp4',
    );

    _videoController = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Background video unavailable: $e');
    }
  }

  Future<bool> checkAdmin(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(uid)
        .get();

    return doc.data()?['role'] == 'admin';
  }

  Future<void> login() async {
    if (isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Login failed');
      }


    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'invalid-email' => 'Invalid email address.',
        'invalid-credential' ||
        'wrong-password' => 'Incorrect email or password.',
        'user-not-found' => 'Account not found.',
        'too-many-requests' => 'Try again later.',
        'network-request-failed' => 'Check your internet connection.',
        _ => 'Unable to sign in. Please try again.',
      };

      _showMessage(message);
    } catch (e) {
      debugPrint('Login error: $e');
      _showMessage('Unable to complete sign in.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Please enter a valid email first.');
      return;
    }

    setState(() => isResettingPassword = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      _showMessage(
        'If an account exists, a reset email will be sent.',
      );
    } catch (e) {
      _showMessage('Unable to send password reset email.');
    } finally {
      if (mounted) {
        setState(() => isResettingPassword = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF123D2E),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      body: Stack(
        children: [
          Positioned.fill(child: _background()),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF02120D).withValues(alpha: 0.92),
                    const Color(0xFF06432D).withValues(alpha: 0.78),
                    const Color(0xFF02120D).withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 950;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop ? 40 : 16,
                    vertical: desktop ? 30 : 18,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight -
                          (desktop ? 60 : 36),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1200,
                        ),
                        child: desktop
                            ? Row(
                          children: [
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 55),
                                child: _CareerHero(),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: _loginCard(false),
                              ),
                            ),
                          ],
                        )
                            : _loginCard(true),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    final video = _videoController;

    if (video != null && video.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: video.value.size.width,
          height: video.value.size.height,
          child: VideoPlayer(video),
        ),
      );
    }

    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF03170F),
            Color(0xFF09523A),
            Color(0xFF03170F),
          ],
        ),
      ),
    );
  }

  Widget _loginCard(bool mobile) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 490),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 23 : 42,
              vertical: mobile ? 27 : 38,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF123D2E)
                  .withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: mint.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 35,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [mint, emerald],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Center(
                    child: Text(
                      'CareerWise',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Center(
                    child: Text(
                      'AI-Assisted Career Decision Support',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB4EBD4),
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Welcome back 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Sign in to continue your career journey.',
                    style: TextStyle(
                      color: Color(0xFFBCD5CA),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 27),

                  const _InputLabel('Email address'),
                  const SizedBox(height: 9),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    style: const TextStyle(color: Colors.white),
                    decoration: _input(
                      'Enter your email',
                      Icons.mail_outline,
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Email is required';
                      if (!RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(email)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  const _InputLabel('Password'),
                  const SizedBox(height: 9),

                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => login(),
                    style: const TextStyle(color: Colors.white),
                    decoration: _input(
                      'Enter your password',
                      Icons.lock_outline,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: mint,
                        ),
                      ),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty
                        ? 'Password is required'
                        : null,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading || isResettingPassword
                          ? null
                          : forgotPassword,
                      child: Text(
                        isResettingPassword
                            ? 'Sending...'
                            : 'Forgot Password?',
                        style: const TextStyle(
                          color: mint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emerald,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR',
                          style: TextStyle(color: mint),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const RegisterScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Create New Account'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  const Center(
                    child: Text(
                      'Your Career. Your Future. Your Choice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9DC5B5),
                        fontSize: 11,
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
  }

  InputDecoration _input(
      String hint,
      IconData icon, {
        Widget? suffix,
      }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF91B4A5)),
      prefixIcon: Icon(icon, color: mint),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF06271D),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF416858)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: mint, width: 1.6),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;

  const _InputLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CareerHero extends StatelessWidget {
  const _CareerHero();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '✦  AI-POWERED CAREER PLATFORM',
          style: TextStyle(
            color: mint,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),

        SizedBox(height: 28),

        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Your Smarter\n',
                style: TextStyle(color: mint),
              ),
              TextSpan(text: 'Career Journey'),
            ],
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),

        SizedBox(height: 22),

        Text(
          'Discover better opportunities, get personalized '
              'AI career guidance, and build your future with confidence.',
          style: TextStyle(
            color: Color(0xFFBBD6CA),
            fontSize: 16,
            height: 1.6,
          ),
        ),

        SizedBox(height: 38),

        _HeroFeature(
          Icons.work_outline_rounded,
          'Find Better Opportunities',
          'Discover jobs tailored to your skills',
        ),

        SizedBox(height: 24),

        _HeroFeature(
          Icons.psychology_outlined,
          'AI Career Guidance',
          'Get personalized career recommendations',
        ),

        SizedBox(height: 24),

        _HeroFeature(
          Icons.insights_rounded,
          'Track Your Progress',
          'Build your professional future',
        ),
      ],
    );
  }
}

class _HeroFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroFeature(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: emerald.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: mint.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(icon, color: mint, size: 25),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFB6D0C4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
