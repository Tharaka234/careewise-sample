
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' show FontFeature;

import 'interview_history_screen.dart';

class AIMockInterviewScreen extends StatefulWidget {
  final String applicationId;
  final String jobTitle;
  final String company;

  const AIMockInterviewScreen({
    super.key,
    required this.applicationId,
    required this.jobTitle,
    required this.company,
  });

  @override
  State<AIMockInterviewScreen> createState() =>
      _AIMockInterviewScreenState();
}

class _AIMockInterviewScreenState extends State<AIMockInterviewScreen> {
  static const Color primary = Color(0xFF059669);
  static const Color background = Color(0xFFF0FDF4);
  static const Color dark = Color(0xFF10251D);

  static const String _apiKey =
  String.fromEnvironment('GEMINI_API_KEY');

  // Use the same working model as Career Advisor.
  static const String _model = 'gemini-3.8-flash';

  final TextEditingController _answerController =
  TextEditingController();

  final List<String> _answers = [];

  List<String> _questions = [];
  Map<String, dynamic>? _feedback;

  int _currentIndex = 0;

  bool _loading = true;
  bool _submitting = false;
  bool _saving = false;
  // ============================================================
// INTERVIEW TIMER
// ============================================================

  static const int _questionDuration = 120; // 2 minutes

  Timer? _questionTimer;
  DateTime? _timerDeadline;

  int _remainingSeconds = _questionDuration;

  bool _timerEnabled = true;
  bool _timeExpired = false;

  String? _error;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  @override
  void dispose() {
    _stopQuestionTimer(); // Stop interview timer
    _answerController.dispose();
    super.dispose();
  }

  // ============================================================
  // GEMINI API
  // ============================================================

  Future<Map<String, dynamic>> _askGemini(String prompt) async {
    if (_apiKey.trim().isEmpty) {
      throw Exception(
        'Gemini API key is missing. '
            'Check Android Studio Run Configuration.',
      );
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
    );

    http.Response response;

    try {
      response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey.trim(),
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 2048,
            'responseMimeType': 'application/json',
          },
        }),
      ).timeout(const Duration(seconds: 120));
    } on TimeoutException {
      throw Exception(
        'Gemini request timed out. '
            'Please check your internet connection and retry.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    }

    if (response.statusCode != 200) {
      String apiMessage = 'Unknown API error';

      try {
        final errorJson = jsonDecode(response.body);
        apiMessage =
            errorJson['error']?['message']?.toString() ??
                apiMessage;
      } catch (_) {
        // Keep fallback message.
      }

      switch (response.statusCode) {
        case 400:
          throw Exception(
            'Invalid Gemini request: $apiMessage',
          );
        case 401:
        case 403:
          throw Exception(
            'Gemini API access denied: $apiMessage',
          );
        case 404:
          throw Exception(
            'Gemini model "$_model" was not found '
                'or is unavailable: $apiMessage',
          );
        case 429:
          throw Exception(
            'Gemini API quota exceeded. '
                'Please try again later. $apiMessage',
          );
        default:
          throw Exception(
            'Gemini API error (${response.statusCode}): '
                '$apiMessage',
          );
      }
    }

    dynamic responseJson;

    try {
      responseJson = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Gemini returned invalid response data.');
    }

    if (responseJson is! Map<String, dynamic>) {
      throw Exception('Unexpected Gemini response.');
    }

    final candidates = responseJson['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates.');
    }

    final candidate = candidates.first;

    if (candidate is! Map) {
      throw Exception('Invalid Gemini candidate.');
    }

    final content = candidate['content'];

    if (content is! Map || content['parts'] is! List) {
      throw Exception(
        'Gemini did not return text. '
            'Please try again.',
      );
    }

    final parts = content['parts'] as List;

    final text = parts
        .whereType<Map>()
        .map((part) => part['text']?.toString() ?? '')
        .join()
        .trim();

    if (text.isEmpty) {
      throw Exception('Gemini returned empty text.');
    }

    try {
      final decoded = jsonDecode(text);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object');
      }

      return decoded;
    } on FormatException {
      throw Exception(
        'Gemini returned an unexpected JSON format. '
            'Please retry.',
      );
    }

  }


  // ============================================================
  // INTERVIEW TIMER FUNCTIONS
  // ============================================================

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
    _timerDeadline = null;

    if (!_timerEnabled || _feedback != null) {
      return;
    }

    _timerDeadline = DateTime.now().add(
      const Duration(seconds: _questionDuration),
    );

    _questionTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final deadline = _timerDeadline;

        if (deadline == null) {
          timer.cancel();
          return;
        }

        final milliseconds = deadline
            .difference(DateTime.now())
            .inMilliseconds;

        final remaining = milliseconds <= 0
            ? 0
            : (milliseconds / 1000).ceil();

        setState(() {
          _remainingSeconds = remaining;
          _timeExpired = remaining == 0;
        });

        if (remaining == 0) {
          timer.cancel();
        }
      },
    );
  }

  void _resetQuestionTimer() {
    _questionTimer?.cancel();
    _timerDeadline = null;

    setState(() {
      _remainingSeconds = _questionDuration;
      _timeExpired = false;
    });

    _startQuestionTimer();
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
    _timerDeadline = null;
  }

  void _toggleQuestionTimer(bool enabled) {
    _stopQuestionTimer();

    setState(() {
      _timerEnabled = enabled;
      _remainingSeconds = _questionDuration;
      _timeExpired = false;
    });

    if (enabled && !_loading && !_submitting) {
      _startQuestionTimer();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }


  // ============================================================
  // GENERATE QUESTIONS
  // ============================================================

  Future<void> _generateQuestions() async {

    if (_loading && _questions.isNotEmpty) return;
    _stopQuestionTimer();
    setState(() {
      _loading = true;
      _error = null;
      _feedback = null;
      _questions = [];
      _answers.clear();
      _currentIndex = 0;
      _answerController.clear();

      _remainingSeconds = _questionDuration;
      _timeExpired = false;
    });

    try {
      final result = await _askGemini('''
You are an experienced professional interview coach.

Job title: ${widget.jobTitle}
Company: ${widget.company}

Generate exactly five realistic mock interview questions
for a university student or early-career job applicant.

Requirements:
- Include technical or role-specific questions.
- Include a problem-solving question.
- Include a behavioral question.
- Make questions clear and concise.
- Do not claim knowledge of the company's actual interview process.

Return ONLY a JSON object with exactly this structure:

{
  "questions": [
    "Question 1",
    "Question 2",
    "Question 3",
    "Question 4",
    "Question 5"
  ]
}
''');

      final rawQuestions = result['questions'];

      if (rawQuestions is! List) {
        throw Exception('Invalid interview questions format.');
      }

      final questions = rawQuestions
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();

      if (questions.length != 5) {
        throw Exception(
          'AI did not generate exactly 5 questions. Retry.',
        );
      }

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _loading = false;
        _error = null;
      });
      _startQuestionTimer();
    } catch (e) {
      debugPrint('Interview question error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // NEXT QUESTION
  // ============================================================

  Future<void> _nextQuestion() async {
    if (_loading || _submitting || _saving) return;
    if (_questions.isEmpty) return;

    final answer = _answerController.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your answer.'),
        ),
      );
      return;
    }

    if (_answers.length > _currentIndex) {
      _answers[_currentIndex] = answer;
    } else {
      _answers.add(answer);
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _error = null;
      });

      // Restore previous answer when navigating forward
      _answerController.text =
      _currentIndex < _answers.length
          ? _answers[_currentIndex]
          : '';
    } else {
      await _finishInterview();
    }
  }
  void _previousQuestion() {
    if (_currentIndex == 0 || _loading || _submitting) return;

    final currentAnswer = _answerController.text.trim();

    // Save current draft before going back
    if (_answers.length > _currentIndex) {
      _answers[_currentIndex] = currentAnswer;
    } else {
      _answers.add(currentAnswer);
    }

    setState(() {
      _currentIndex--;
      _error = null;
    });

    _answerController.text = _answers[_currentIndex];
  }

  // ============================================================
  // EVALUATE INTERVIEW
  // ============================================================

  Future<void> _finishInterview() async {
    if (_submitting || _saving) return;

    if (_answers.length != _questions.length) {
      setState(() {
        _error = 'Please answer all interview questions.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final responses = List.generate(
        _questions.length,
            (index) => {
          'question': _questions[index],
          'answer': _answers[index],
        },
      );

      final result = await _askGemini('''
You are a professional AI interview practice evaluator.

Job title: ${widget.jobTitle}

Evaluate these mock interview responses:

${jsonEncode(responses)}

Give fair, practical, constructive feedback.

Evaluate:
- Relevance of each answer
- Technical understanding where applicable
- Problem-solving ability shown in the answers
- Clarity and completeness

The score is a practice estimate, not a hiring prediction.
Do not infer protected or sensitive personal traits.

Return ONLY valid JSON:

{
  "score": 75,
  "summary": "Overall assessment of the interview",
  "strengths": [
    "Strength 1",
    "Strength 2"
  ],
  "improvements": [
    "Improvement 1",
    "Improvement 2"
  ],
  "tips": [
    "Preparation tip 1",
    "Preparation tip 2"
  ]
}

Score must be an integer from 0 to 100.
''');

      final rawScore = result['score'];

      final parsedScore = rawScore is num
          ? rawScore.toInt()
          : int.tryParse(rawScore.toString()) ?? 0;

      result['score'] = parsedScore.clamp(0, 100).toInt();

      if (!mounted) return;

      setState(() {
        _feedback = result;
        _submitting = false;
        _error = null;
      });

      await _saveInterview();
    } catch (e) {
      debugPrint('Interview evaluation error: $e');

      if (!mounted) return;

      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // SAVE TO FIRESTORE
  // ============================================================

  Future<void> _saveInterview() async {
    if (_saving || _feedback == null) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _saveError = 'Please sign in again to save results.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      final responses = List.generate(
        _questions.length,
            (index) => {
          'question': _questions[index],
          'answer': _answers[index],
        },
      );

      await FirebaseFirestore.instance
          .collection('mock_interviews')
          .add({
        'userId': user.uid,
        'applicationId': widget.applicationId,
        'jobTitle': widget.jobTitle,
        'company': widget.company,
        'questions': responses,
        'feedback': _feedback,
        'score': _feedback!['score'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _saving = false;
        _saveError = null;
      });
    } catch (e) {
      debugPrint('Firestore interview save error: $e');

      if (!mounted) return;

      setState(() {
        _saving = false;
        _saveError = 'Could not save interview: $e';
      });
    }
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: background,

        appBar: AppBar(
          title: const Text('AI Interview Coach'),
          backgroundColor: background,


        ),



      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _loading || _submitting
                ? _loadingView()
                : _feedback != null
                ? _resultView()
                : _error != null && _questions.isEmpty
                ? _errorView()
                : _questionView(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING UI
  // ============================================================

  Widget _loadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: primary),
        const SizedBox(height: 24),
        Text(
          _submitting
              ? 'Evaluating your interview...'
              : 'Preparing your interview questions...',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: dark,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _submitting
              ? 'Generating your score and feedback'
              : 'Creating questions for ${widget.jobTitle}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR UI
  // ============================================================

  Widget _errorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          size: 56,
          color: Colors.redAccent,
        ),
        const SizedBox(height: 18),
        const Text(
          'Unable to prepare interview',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _error ?? 'Something went wrong.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black87),
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: _generateQuestions,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }


  // ============================================================
  // PREMIUM QUESTION TIMER UI
  // ============================================================

  Widget _buildInterviewTimer() {
    final progress =
        _remainingSeconds / _questionDuration;

    final isWarning =
        _timerEnabled && _remainingSeconds <= 30;

    final timerColor = isWarning
        ? const Color(0xFFDC2626)
        : primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isWarning
              ? const Color(0xFFFECACA)
              : const Color(0xFFE1EBE5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: timerColor,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'Interview Timer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
              ),

              Switch(
                value: _timerEnabled,
                activeTrackColor: primary,
                onChanged: _toggleQuestionTimer,
              ),
            ],
          ),

          if (_timerEnabled) ...[
            const SizedBox(height: 18),

            Center(
              child: Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: timerColor,
                  letterSpacing: 1.5,
                  fontFeatures: const [
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor:
                const Color(0xFFE6EFEB),
                valueColor: AlwaysStoppedAnimation<Color>(
                  timerColor,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                _timeExpired
                    ? 'Time is up! You can still finish your answer.'
                    : isWarning
                    ? 'Hurry up! Less than 30 seconds remaining.'
                    : 'Take your time and answer confidently.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isWarning
                      ? timerColor
                      : const Color(0xFF64766E),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Timer disabled. Practice at your own pace.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64766E),
              ),
            ),
          ],
        ],
      ),
    );
  }


  // ============================================================
  // QUESTIONS UI
  // ============================================================


  Widget _questionView() {
    if (_questions.isEmpty) {
      return const Center(
        child: Text('No interview questions available.'),
      );
    }

    final isLastQuestion = _currentIndex == _questions.length - 1;
    final progress = (_currentIndex + 1) / _questions.length;

    const deepGreen = Color(0xFF123F35);
    const mutedText = Color(0xFF64766E);
    const borderColor = Color(0xFFE1EBE5);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PREMIUM INTERVIEW HEADER
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF066B50),
                  Color(0xFF059669),
                  Color(0xFF10B981),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFA7F3D0),
                            size: 16,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'AI PRACTICE SESSION',
                            style: TextStyle(
                              color: Color(0xFFD1FAE5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.psychology_outlined,
                      color: Color(0xFFA7F3D0),
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 23),
                Text(
                  widget.jobTitle,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.business_outlined,
                      color: Color(0xFFD1FAE5),
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.company,
                        style: const TextStyle(
                          color: Color(0xFFD1FAE5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Build confidence, one question at a time.',
                  style: TextStyle(
                    color: Color(0xFFB7D5C9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Interview Timer
          _buildInterviewTimer(),
          // PROGRESS CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                    Text(
                      '${_currentIndex + 1} of ${_questions.length}',
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // SEGMENTED PROGRESS INDICATOR
                Row(
                  children: List.generate(_questions.length, (index) {
                    final completed = index <= _currentIndex;

                    return Expanded(
                      child: Container(
                        height: 8,
                        margin: EdgeInsets.only(
                          right: index == _questions.length - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: completed
                              ? primary
                              : const Color(0xFFE6EFEB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),
                Text(
                  isLastQuestion
                      ? 'Final question! You are almost done.'
                      : '${(progress * 100).round()}% of your interview reached',
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // QUESTION AND ANSWER CARD
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        color: primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QUESTION ${(_currentIndex + 1).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.auto_awesome,
                      color: primary,
                      size: 19,
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Text(
                  _questions[_currentIndex],
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),

                const SizedBox(height: 26),
                const Divider(color: borderColor),
                const SizedBox(height: 18),

                Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      color: primary,
                      size: 23,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Your Answer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Written response',
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _answerController,
                  minLines: 6,
                  maxLines: 10,
                  maxLength: 3000,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: dark,
                  ),
                  decoration: InputDecoration(
                    hintText:
                    'Write your answer here...\n\n'
                        'Explain your approach and give a real example '
                        'when possible.',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9AABA2),
                      fontSize: 14,
                      height: 1.6,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF6FAF8),
                    contentPadding: const EdgeInsets.all(18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // HELPFUL TIP
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9F4),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: primary,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Interview tip: Be specific, explain your '
                              'reasoning, and use examples from your '
                              'own experience.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF426557),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // PREVIOUS / NEXT BUTTONS
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 330;

                    final previousButton = OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: const BorderSide(color: primary),
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );

                    final nextButton = ElevatedButton.icon(
                      onPressed: _nextQuestion,
                      icon: Icon(
                        isLastQuestion
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward,
                        size: 19,
                      ),
                      label: Text(
                        isLastQuestion
                            ? 'Finish Interview'
                            : 'Next Question',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 54),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );

                    if (_currentIndex == 0) {
                      return SizedBox(
                        width: double.infinity,
                        child: nextButton,
                      );
                    }

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          nextButton,
                          const SizedBox(height: 10),
                          previousButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: previousButton),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: nextButton,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 15,
                color: mutedText,
              ),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Your completed interview can be saved to your history',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============================================================
  // RESULTS UI
  // ============================================================

  Widget _resultView() {
    final feedback = _feedback!;
    final score = feedback['score'] ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          const Text(
            'Interview Completed!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Here is your personalized AI interview feedback.',
            style: TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 24),

          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: primary,
                    size: 55,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '$score / 100',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'AI Practice Score',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    feedback['summary']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          _feedbackSection(
            'Your Strengths',
            feedback['strengths'],
            Icons.check_circle_outline,
          ),

          _feedbackSection(
            'Areas to Improve',
            feedback['improvements'],
            Icons.trending_up,
          ),

          _feedbackSection(
            'Preparation Tips',
            feedback['tips'],
            Icons.lightbulb_outline,
          ),

          const SizedBox(height: 16),

          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(
                  color: primary,
                ),
              ),
            ),

          if (_saveError != null) ...[
            Text(
              _saveError!,
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _saveInterview,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Saving'),
            ),
          ],

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving
                  ? null
                  : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Applications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEEDBACK SECTION
  // ============================================================

  Widget _feedbackSection(
      String title,
      dynamic items,
      IconData icon,
      ) {
    final values = items is List
        ? items.map((e) => e.toString()).toList()
        : <String>[];

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (values.isEmpty)
              const Text('No feedback available.'),

            ...values.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '• $item',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
