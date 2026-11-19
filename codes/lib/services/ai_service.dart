
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AIService {
  // Gemini configuration
  static const String _apiKey =
  String.fromEnvironment('GEMINI_API_KEY');

  // Replace with a model available to your API key.
  static const String _model = 'gemini-3.8-flash';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ==========================================================
  // Generate Career Recommendation
  // ==========================================================

  Future<Map<String, dynamic>> getCareerRecommendation({
    required String interests,
    required String skills,
    required String education,
    required String careerGoal,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'Please login to generate career recommendations.',
        );
      }

      if (_apiKey.isEmpty) {
        throw Exception(
          'Gemini API key is missing. Run with '
              '--dart-define=GEMINI_API_KEY=your_key',
        );
      }

      final prompt = '''
You are an AI career advisor for a mobile application called CareerWise.

Analyze the user's education, skills, interests, and career goals.

USER INFORMATION

Education:
$education

Skills:
$skills

Interests:
$interests

Career Goal:
$careerGoal

Provide a personalized career analysis.

Return ONLY valid JSON.
Do not use markdown or code fences.
Do not add explanations outside the JSON.

Use exactly this structure:

{
  "careers": [
    {
      "title": "Career name",
      "whySuitable": "Why this career is suitable",
      "skillsToDevelop": ["Skill 1", "Skill 2", "Skill 3"],
      "learningAreas": ["Learning area 1", "Learning area 2"],
      "technologies": ["Technology 1", "Technology 2"]
    }
  ],
  "strengths": ["Strength 1", "Strength 2"],
  "actionPlan": ["Action 1", "Action 2", "Action 3"]
}

RULES:
- Provide exactly 3 career recommendations.
- Career titles must be short and searchable job titles.
- Base recommendations on the user's education, skills,
  interests, and career goal.
- Avoid generic recommendations.
- Make recommendations practical for university students
  or early-career professionals.
- Suggest different career paths when appropriate.
- Keep explanations concise.
- skillsToDevelop must contain practical skills.
- learningAreas must contain useful learning topics.
- technologies must contain relevant technologies,
  tools, or platforms.
- strengths must reflect the user's information.
- actionPlan must contain realistic next steps.
''';

      final decoded = await _askGeminiJson(
        prompt,
        temperature: 0.7,
      );

      if (!decoded.containsKey('careers')) {
        throw Exception(
          'AI response does not contain career recommendations.',
        );
      }

      if (!decoded.containsKey('strengths')) {
        throw Exception(
          'AI response does not contain strengths.',
        );
      }

      if (!decoded.containsKey('actionPlan')) {
        throw Exception(
          'AI response does not contain an action plan.',
        );
      }

      final careers = decoded['careers'];

      if (careers is! List || careers.length != 3) {
        throw Exception(
          'AI response must contain exactly 3 career recommendations.',
        );
      }

      if (decoded['strengths'] is! List ||
          decoded['actionPlan'] is! List) {
        throw Exception(
          'Invalid strengths or action plan format.',
        );
      }

      for (final career in careers) {
        if (career is! Map ||
            career['title'] is! String ||
            career['whySuitable'] is! String ||
            career['skillsToDevelop'] is! List ||
            career['learningAreas'] is! List ||
            career['technologies'] is! List) {
          throw Exception(
            'A career recommendation has an invalid structure.',
          );
        }
      }

      return decoded;
    } on TimeoutException {
      throw Exception(
        'The AI took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw Exception(
        'Cannot connect to the AI service. Check your internet.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ==========================================================
  // Gemini REST API
  // ==========================================================

  Future<Map<String, dynamic>> _askGeminiJson(
      String prompt, {
        double temperature = 0.5,
        int maxOutputTokens = 2048,
      }) async {
    final uri = Uri.parse(
      '$_baseUrl/$_model:generateContent',
    );

    final response = await http
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
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
          'responseMimeType': 'application/json',
          'temperature': temperature,
          'maxOutputTokens': maxOutputTokens,
        },
      }),
    )
        .timeout(const Duration(seconds: 90));

    Map<String, dynamic> data;

    try {
      final parsed = jsonDecode(response.body);

      data = parsed is Map<String, dynamic>
          ? parsed
          : <String, dynamic>{};
    } on FormatException {
      throw Exception(
        'Gemini returned an invalid response.',
      );
    }

    if (response.statusCode == 429) {
      throw Exception(
        'AI quota has been reached. Please try again later.',
      );
    }

    if (response.statusCode != 200) {
      final error = data['error'];

      final message = error is Map
          ? error['message']?.toString()
          : null;

      throw Exception(
        message ?? 'The AI service is unavailable.',
      );
    }

    final candidates = data['candidates'];

    dynamic parts;

    if (candidates is List && candidates.isNotEmpty) {
      final candidate = candidates.first;

      if (candidate is Map) {
        final content = candidate['content'];

        if (content is Map) {
          parts = content['parts'];
        }
      }
    }

    final text = parts is List
        ? parts
        .whereType<Map>()
        .map((part) => part['text']?.toString() ?? '')
        .join()
        .trim()
        : '';

    if (text.isEmpty) {
      throw Exception(
        'Gemini returned an empty response.',
      );
    }

    final clean = text
        .replaceFirst(
      RegExp(r'^```json\s*', caseSensitive: false),
      '',
    )
        .replaceFirst(
      RegExp(r'^```\s*'),
      '',
    )
        .replaceFirst(
      RegExp(r'\s*```$'),
      '',
    )
        .trim();

    try {
      final result = jsonDecode(clean);

      if (result is! Map<String, dynamic>) {
        throw const FormatException();
      }

      return result;
    } on FormatException {
      throw Exception(
        'Gemini returned invalid JSON. Please try again.',
      );
    }
  }

  // ==========================================================
  // Save Career Recommendation to Firestore
  // ==========================================================

  Future<void> saveCareerRecommendation({
    required String userId,
    required String education,
    required String skills,
    required String interests,
    required String careerGoal,
    required String recommendation,
  }) async {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('Please login first.');
    }

    if (currentUser.uid != userId) {
      throw Exception(
        'You cannot save recommendations for another user.',
      );
    }

    await FirebaseFirestore.instance
        .collection('career_recommendations')
        .add({
      'userId': userId,
      'education': education,
      'skills': skills,
      'interests': interests,
      'careerGoal': careerGoal,
      'recommendation': recommendation,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
