import '../../../../core/network/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../offline/data/repositories/offline_mode_repository.dart';
import '../../domain/entities/quiz_question_template.dart';
import '../../domain/usecases/thpt_math_2026_scoring.dart';

class QuizRepository {
  QuizRepository({
    required ApiService apiService,
    required this.sessionId,
    OfflineModeRepository? offlineModeRepository,
    SupabaseClient? supabaseClient,
  }) : _apiService = apiService,
       _offlineModeRepository =
           offlineModeRepository ?? OfflineModeRepository.instance,
       _supabaseClient = supabaseClient ?? _tryResolveSupabaseClient();

  final ApiService _apiService;
  final String sessionId;
  final OfflineModeRepository _offlineModeRepository;
  final SupabaseClient? _supabaseClient;

  Future<List<QuizQuestionTemplate>> fetchQuestionTemplates({
    String subject = 'math',
    int examYear = 2026,
    int limit = 8,
  }) async {
    final client = _supabaseClient;
    if (client == null) {
      return _fallbackQuestionTemplates(
        subject: subject,
        examYear: examYear,
        limit: limit,
      );
    }

    try {
      final rows = await client
          .from('quiz_question_template')
          .select()
          .eq('subject', subject)
          .eq('exam_year', examYear)
          .eq('is_active', true)
          .order('part_no', ascending: true)
          .order('difficulty_level', ascending: true)
          .limit(limit);

      final templates = rows
          .whereType<Map>()
          .map((item) {
            final json = Map<String, dynamic>.from(item);
            final rawContent = json['content']?.toString() ?? '';
            final rawType = json['question_type']?.toString() ?? '';
            final questionType = _tryParseQuestionType(rawType);
            final sanitizedContent = _sanitizeContentByQuestionType(
              rawContent,
              rawType,
            );

            final normalizedPayload = _normalizeQuestionPayload(
              payload: json['payload'],
              questionType: questionType,
              rawContent: rawContent,
            );

            json['content'] = _normalizeQuestionContent(
              content: sanitizedContent,
              questionType: questionType,
            );
            json['payload'] = normalizedPayload;

            return QuizQuestionTemplate.fromJson(json);
          })
          .toList(growable: false);

      if (templates.isEmpty) {
        return _fallbackQuestionTemplates(
          subject: subject,
          examYear: examYear,
          limit: limit,
        );
      }

      return templates;
    } catch (_) {
      return _fallbackQuestionTemplates(
        subject: subject,
        examYear: examYear,
        limit: limit,
      );
    }
  }

  static List<QuizQuestionTemplate> _fallbackQuestionTemplates({
    required String subject,
    required int examYear,
    required int limit,
  }) {
    final fallbackRows = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'mock_mc_01',
        'subject': subject,
        'topic_code': 'derivative_basic',
        'topic_name': 'Derivatives',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 1,
        'content': 'What is the derivative of f(x) = x^2?',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '2x'},
            <String, dynamic>{'id': 'B', 'text': 'x'},
            <String, dynamic>{'id': 'C', 'text': 'x^2'},
            <String, dynamic>{'id': 'D', 'text': '2'},
          ],
          'correct_option_id': 'A',
          'explanation': 'Use the power rule: d(x^n)/dx = n*x^(n-1).',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_tf_01',
        'subject': subject,
        'topic_code': 'derivative_rules',
        'topic_name': 'Derivative rules',
        'exam_year': examYear,
        'question_type': 'TRUE_FALSE_CLUSTER',
        'part_no': 2,
        'difficulty_level': 2,
        'content': 'Determine whether each statement is true or false.',
        'payload': <String, dynamic>{
          'general_hint': 'Recall product and chain rules.',
          'sub_questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'a',
              'text': 'd(x^3)/dx = 3x^2',
              'is_true': true,
              'explanation': 'Power rule.',
            },
            <String, dynamic>{
              'id': 'b',
              'text': 'd(2x)/dx = x',
              'is_true': false,
              'explanation': 'd(2x)/dx = 2.',
            },
          ],
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_sa_01',
        'subject': subject,
        'topic_code': 'derivative_polynomial',
        'topic_name': 'Polynomial derivatives',
        'exam_year': examYear,
        'question_type': 'SHORT_ANSWER',
        'part_no': 3,
        'difficulty_level': 2,
        'content': 'Compute the derivative of the function below.',
        'payload': <String, dynamic>{
          'exact_answer': '12x^2 + 4x',
          'accepted_answers': <String>['12x^2 + 4x', '4x + 12x^2'],
          'explanation': 'Apply derivative term by term.',
        },
        'metadata': <String, dynamic>{'formula': 'y = 4x^3 + 2x^2 - 5'},
        'is_active': true,
      },
    ];

    return fallbackRows
        .map(QuizQuestionTemplate.fromJson)
        .take(limit)
        .toList(growable: false);
  }

  /// Sanitizes duplicated option/sub-question blocks from content because
  /// options are already rendered by payload fields.
  static String _sanitizeContentByQuestionType(
    String content,
    String questionTypeRaw,
  ) {
    var output = content.trim();
    if (output.isEmpty) {
      return output;
    }

    QuizQuestionType? type;
    try {
      type = QuizQuestionType.fromStorageValue(questionTypeRaw);
    } catch (_) {
      type = null;
    }

    // Always strip MC option blocks if present.
    // Handles patterns like "A. ... B. ... C. ... D. ..." or "A) ... B) ..."
    // Also handles cases where answer text is on same line as question (no leading space)
    output = _stripBlockByMarkers(
      source: output,
      markerPattern: RegExp(r'([A-D])[\.)]\s+'),
      expectedSequence: const ['A', 'B', 'C'],
    );

    // Also try with lookbehind to avoid matching mid-word (e.g., "f'(3)")
    if (output.contains(RegExp(r'[A-D][\.)]\s+[A-Za-z]'))) {
      output = _stripBlockByMarkers(
        source: output,
        markerPattern: RegExp(r'(?<![a-zA-Z])([A-D])[\.)]\s+'),
        expectedSequence: const ['A', 'B', 'C'],
      );
    }

    if (type == QuizQuestionType.trueFalseCluster) {
      // Strip duplicated true/false statement list in content (a/b/c/d...).
      output = _stripBlockByMarkers(
        source: output,
        markerPattern: RegExp(r'(?<![\w\(])([a-d])[\.)]\s+'),
        expectedSequence: const ['a', 'b', 'c'],
      );
    }

    return _normalizeContentSpacing(output);
  }

  /// Removes text from the first marker onward when a full marker sequence
  /// (at least 3 markers) is detected, e.g. A./B./C. or a)/b)/c).
  static String _stripBlockByMarkers({
    required String source,
    required RegExp markerPattern,
    required List<String> expectedSequence,
  }) {
    final matches = markerPattern.allMatches(source).toList(growable: false);
    if (matches.length < expectedSequence.length) {
      return source;
    }

    var cutIndex = -1;
    final upperExpected = expectedSequence
        .map((token) => token.toUpperCase())
        .toList(growable: false);

    for (var i = 0; i <= matches.length - expectedSequence.length; i += 1) {
      var isSequenceMatch = true;
      for (var j = 0; j < expectedSequence.length; j += 1) {
        final marker = matches[i + j].group(1)?.toUpperCase();
        if (marker != upperExpected[j]) {
          isSequenceMatch = false;
          break;
        }
      }

      if (isSequenceMatch) {
        cutIndex = matches[i].start;
        break;
      }
    }

    if (cutIndex <= 0) {
      return source;
    }

    final trimmed = source.substring(0, cutIndex).trimRight();
    return trimmed.replaceAll(RegExp(r'[:;,\-–]\s*$'), '').trimRight();
  }

  static String _normalizeContentSpacing(String source) {
    var output = source.trim();

    output = output
        .replaceAll(RegExp(r'\(\s+'), '(')
        .replaceAll(RegExp(r'\s+\)'), ')')
        .replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1')
        .replaceAll(RegExp(r'([,.;:!?])(?=[a-zA-ZÀ-ỹ])'), r'$1 ');

    return _collapseWhitespace(output);
  }

  static QuizQuestionType? _tryParseQuestionType(String rawType) {
    try {
      return QuizQuestionType.fromStorageValue(rawType);
    } catch (_) {
      return null;
    }
  }

  static String _normalizeQuestionContent({
    required String content,
    required QuizQuestionType? questionType,
  }) {
    var output = _normalizeQuestionText(content);

    if (questionType == QuizQuestionType.trueFalseCluster) {
      output = _stripBlockByMarkers(
        source: output,
        markerPattern: RegExp(r'(?<![\w\(])([a-d])[\.)]\s+'),
        expectedSequence: const ['a', 'b', 'c'],
      );
    }

    return _normalizeContentSpacing(output);
  }

  static Map<String, dynamic> _normalizeQuestionPayload({
    required Object? payload,
    required QuizQuestionType? questionType,
    required String rawContent,
  }) {
    final normalizedPayload = _toStringMap(payload);

    if (questionType == QuizQuestionType.multipleChoice) {
      final options = _toListOfMaps(normalizedPayload['options']);
      final normalizedOptions = options
          .map((option) {
            final copy = Map<String, dynamic>.from(option);
            copy['id'] = (copy['id']?.toString() ?? '').trim().toUpperCase();
            copy['text'] = _normalizeQuestionText(
              copy['text']?.toString() ?? '',
            );
            return copy;
          })
          .toList(growable: false);

      var resolvedOptions = normalizedOptions;
      if (_looksLikePlaceholderOptions(normalizedOptions)) {
        final extracted = _extractMultipleChoiceOptionsFromContent(rawContent);
        if (extracted != null && extracted.length == normalizedOptions.length) {
          resolvedOptions = List<Map<String, dynamic>>.generate(
            normalizedOptions.length,
            (index) => <String, dynamic>{
              ...normalizedOptions[index],
              'text': _normalizeQuestionText(extracted[index]),
            },
            growable: false,
          );
        }
      }

      normalizedPayload['options'] = resolvedOptions;
      final correctId = normalizedPayload['correct_option_id']
          ?.toString()
          .trim();
      if (correctId != null && correctId.isNotEmpty) {
        normalizedPayload['correct_option_id'] = correctId.toUpperCase();
      }
      normalizedPayload['explanation'] = _normalizeQuestionText(
        normalizedPayload['explanation']?.toString() ?? '',
      );
      return normalizedPayload;
    }

    if (questionType == QuizQuestionType.trueFalseCluster) {
      normalizedPayload['general_hint'] = _normalizeQuestionText(
        normalizedPayload['general_hint']?.toString() ?? '',
      );

      final subQuestions = _toListOfMaps(normalizedPayload['sub_questions']);
      normalizedPayload['sub_questions'] = subQuestions
          .map((subQuestion) {
            final copy = Map<String, dynamic>.from(subQuestion);
            copy['id'] = (copy['id']?.toString() ?? '').trim().toLowerCase();
            copy['text'] = _normalizeQuestionText(
              copy['text']?.toString() ?? '',
            );
            copy['explanation'] = _normalizeQuestionText(
              copy['explanation']?.toString() ?? '',
            );
            return copy;
          })
          .toList(growable: false);

      return normalizedPayload;
    }

    if (questionType == QuizQuestionType.shortAnswer) {
      normalizedPayload['explanation'] = _normalizeQuestionText(
        normalizedPayload['explanation']?.toString() ?? '',
      );
      return normalizedPayload;
    }

    return normalizedPayload;
  }

  static bool _looksLikePlaceholderOptions(List<Map<String, dynamic>> options) {
    if (options.length < 2) {
      return false;
    }

    final placeholderPattern = RegExp(
      r'^option\s*[a-d]$',
      caseSensitive: false,
    );
    return options.every((option) {
      final text = option['text']?.toString().trim() ?? '';
      return placeholderPattern.hasMatch(text);
    });
  }

  static List<String>? _extractMultipleChoiceOptionsFromContent(
    String content,
  ) {
    final normalized = _normalizeQuestionText(content);
    final matches = RegExp(
      r'(?<![A-Za-z])([A-D])[\.)]\s+',
    ).allMatches(normalized).toList(growable: false);

    if (matches.length < 4) {
      return null;
    }

    for (var i = 0; i <= matches.length - 4; i += 1) {
      final markers = List<String>.generate(
        4,
        (index) => matches[i + index].group(1)?.toUpperCase() ?? '',
        growable: false,
      );

      if (markers.join() != 'ABCD') {
        continue;
      }

      final options = <String>[];
      for (var j = 0; j < 4; j += 1) {
        final start = matches[i + j].end;
        final end = j < 3 ? matches[i + j + 1].start : normalized.length;
        final optionText = normalized.substring(start, end).trim();
        final cleaned = optionText
            .replaceAll(RegExp(r'^[,;:.\-–\s]+|[,;:.\-–\s]+$'), '')
            .trim();
        options.add(cleaned);
      }

      if (options.every((item) => item.isNotEmpty)) {
        return options;
      }
    }

    return null;
  }

  static String _normalizeQuestionText(String source) {
    var output = source
        .replaceAll('\u00A0', ' ')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('₍', '(')
        .replaceAll('₎', ')')
        .replaceAll('ₓ', 'x')
        .replaceAll('ₜ', 't')
        .replaceAll('ₙ', 'n')
        .replaceAll('ₘ', 'm')
        .replaceAll('ₖ', 'k')
        .replaceAll('ₚ', 'p');

    output = _stripDanglingDollarSigns(output);
    return _collapseWhitespace(output);
  }

  static String _collapseWhitespace(String source) {
    return source.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static String _stripDanglingDollarSigns(String source) {
    var output = source;
    final matches = RegExp(
      r'(?<!\\)\$',
    ).allMatches(output).toList(growable: false);
    if (matches.isNotEmpty && matches.length.isOdd) {
      final dangling = matches.last;
      output =
          output.substring(0, dangling.start) + output.substring(dangling.end);
    }
    return output;
  }

  static Map<String, dynamic> _toStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _toListOfMaps(Object? value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<void> recordEvaluatedAttempt({
    required QuizQuestionTemplate question,
    required QuizQuestionUserAnswer userAnswer,
    required QuizQuestionEvaluation evaluation,
  }) async {
    final client = _supabaseClient;
    final uid = client?.auth.currentUser?.id;

    if (client == null || uid == null || uid.isEmpty) {
      return;
    }

    if (!_isUuid(question.id)) {
      return;
    }

    final payload = <String, dynamic>{
      'student_id': uid,
      'question_template_id': question.id,
      'question_type': question.questionType.storageValue,
      'user_answer': userAnswer.toJson(),
      'evaluation': evaluation.toJson(),
      'score': evaluation.score,
      'max_score': evaluation.maxScore,
      'is_correct': evaluation.isCorrect,
    };

    if (_isUuid(sessionId)) {
      payload['session_id'] = sessionId;
    }

    try {
      await client.from('quiz_question_attempts').insert(payload);
    } catch (_) {
      // Preserve quiz flow when tracking write fails.
    }
  }

  Future<Map<String, dynamic>> submitAnswer({
    required String questionId,
    required String answer,
    Map<String, dynamic>? context,
  }) {
    return _apiService.submitAnswer(
      sessionId: sessionId,
      questionId: questionId,
      answer: answer,
      context: context,
    );
  }

  Future<Map<String, dynamic>> submitSignals(
    List<Map<String, dynamic>> signals,
  ) async {
    final offlineEnabled = await _offlineModeRepository.isOfflineModeEnabled();

    if (offlineEnabled) {
      await _offlineModeRepository.enqueueSignals(signals);
      return <String, dynamic>{
        'status': 'queued',
        'message': 'Offline mode is enabled, signals are queued locally.',
        'data': <String, dynamic>{
          'queuedCount': signals.length,
          'sessionId': sessionId,
        },
      };
    }

    await _offlineModeRepository.flushQueuedSignals(
      submitter: (queuedSignals) {
        return _apiService.submitSignals(
          sessionId: sessionId,
          signals: queuedSignals,
        );
      },
    );

    try {
      return await _apiService.submitSignals(
        sessionId: sessionId,
        signals: signals,
      );
    } catch (_) {
      await _offlineModeRepository.enqueueSignals(signals);
      return <String, dynamic>{
        'status': 'queued',
        'message': 'Network unstable, signals are queued for next sync.',
        'data': <String, dynamic>{
          'queuedCount': signals.length,
          'sessionId': sessionId,
        },
      };
    }
  }

  static SupabaseClient? _tryResolveSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}
