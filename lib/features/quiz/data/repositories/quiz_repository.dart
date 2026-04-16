import '../../../../core/network/api_service.dart';
import '../../../../data/models/api_models.dart';
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
      // ── H04: Quy tắc tính (tổng, hiệu, tích, thương) ──────────────
      <String, dynamic>{
        'id': 'mock_mc_h04_01',
        'subject': subject,
        'topic_code': 'derivative_basic_rules',
        'topic_name': 'Quy tắc tính đạo hàm',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 1,
        'hypothesis_tag': 'H04',
        'content': 'Tính đạo hàm của hàm số f(x) = x^2 + 3x - 5.',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '2x + 3'},
            <String, dynamic>{'id': 'B', 'text': '2x - 3'},
            <String, dynamic>{'id': 'C', 'text': 'x^2 + 3'},
            <String, dynamic>{'id': 'D', 'text': '2x'},
          ],
          'correct_option_id': 'A',
          'explanation':
              'Áp dụng quy tắc tổng và công thức (x^n)\' = n·x^(n-1): f\'(x) = 2x + 3.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_mc_h04_02',
        'subject': subject,
        'topic_code': 'derivative_basic_rules',
        'topic_name': 'Quy tắc tính đạo hàm',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 2,
        'hypothesis_tag': 'H04',
        'content': 'Cho f(x) = x^3 · (2x + 1). Tính f\'(x).',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '8x^3 + 3x^2'},
            <String, dynamic>{'id': 'B', 'text': '6x^2 + 1'},
            <String, dynamic>{'id': 'C', 'text': '3x^2(2x + 1) + 2x^3'},
            <String, dynamic>{'id': 'D', 'text': '6x^3 + 3x^2'},
          ],
          'correct_option_id': 'A',
          'explanation':
              'Dùng quy tắc tích: (uv)\' = u\'v + uv\'. u=x^3, v=2x+1 → f\'(x) = 3x^2(2x+1) + x^3·2 = 8x^3 + 3x^2.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_mc_h04_03',
        'subject': subject,
        'topic_code': 'derivative_basic_rules',
        'topic_name': 'Quy tắc tính đạo hàm',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 2,
        'hypothesis_tag': 'H04',
        'content': 'Tính đạo hàm của f(x) = (x + 1) / (x - 1).',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '-2 / (x - 1)^2'},
            <String, dynamic>{'id': 'B', 'text': '2 / (x - 1)^2'},
            <String, dynamic>{'id': 'C', 'text': '1 / (x - 1)'},
            <String, dynamic>{'id': 'D', 'text': '(x - 1)^(-2)'},
          ],
          'correct_option_id': 'A',
          'explanation':
              'Dùng quy tắc thương: (u/v)\' = (u\'v - uv\') / v^2. → f\'(x) = (1·(x-1) - (x+1)·1) / (x-1)^2 = -2/(x-1)^2.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      // ── H01: Đạo hàm lượng giác ───────────────────────────────────
      <String, dynamic>{
        'id': 'mock_mc_h01_01',
        'subject': subject,
        'topic_code': 'derivative_trig',
        'topic_name': 'Đạo hàm lượng giác',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 1,
        'hypothesis_tag': 'H01',
        'content': 'Tính đạo hàm của f(x) = sin x + cos x.',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': 'cos x - sin x'},
            <String, dynamic>{'id': 'B', 'text': 'cos x + sin x'},
            <String, dynamic>{'id': 'C', 'text': '-sin x + cos x'},
            <String, dynamic>{'id': 'D', 'text': '-cos x - sin x'},
          ],
          'correct_option_id': 'A',
          'explanation':
              '(sin x)\' = cos x và (cos x)\' = -sin x. Vậy f\'(x) = cos x - sin x.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_mc_h01_02',
        'subject': subject,
        'topic_code': 'derivative_trig',
        'topic_name': 'Đạo hàm lượng giác',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 2,
        'hypothesis_tag': 'H01',
        'content': 'Tính đạo hàm của f(x) = tan x.',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '1 / cos^2(x)'},
            <String, dynamic>{'id': 'B', 'text': '1 / sin^2(x)'},
            <String, dynamic>{'id': 'C', 'text': 'sec x'},
            <String, dynamic>{'id': 'D', 'text': '-1 / cos^2(x)'},
          ],
          'correct_option_id': 'A',
          'explanation': '(tan x)\' = 1/cos^2(x). Đây là công thức cần nhớ.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_mc_h01_03',
        'subject': subject,
        'topic_code': 'derivative_trig',
        'topic_name': 'Đạo hàm lượng giác',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 1,
        'hypothesis_tag': 'H01',
        'content': 'Đạo hàm của hàm số y = 3sin x - 2cos x là:',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '3cos x + 2sin x'},
            <String, dynamic>{'id': 'B', 'text': '-3cos x + 2sin x'},
            <String, dynamic>{'id': 'C', 'text': '3cos x - 2sin x'},
            <String, dynamic>{'id': 'D', 'text': '-3sin x - 2cos x'},
          ],
          'correct_option_id': 'A',
          'explanation': 'y\' = 3·cos x - 2·(-sin x) = 3cos x + 2sin x.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      // ── H02: Đạo hàm mũ & logarit ────────────────────────────────
      <String, dynamic>{
        'id': 'mock_mc_h02_01',
        'subject': subject,
        'topic_code': 'derivative_exp_log',
        'topic_name': 'Đạo hàm mũ & logarit',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 1,
        'hypothesis_tag': 'H02',
        'content': 'Tính đạo hàm của f(x) = e^x + ln x.',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': 'e^x + 1/x'},
            <String, dynamic>{'id': 'B', 'text': 'e^x + x'},
            <String, dynamic>{'id': 'C', 'text': 'e^x - 1/x'},
            <String, dynamic>{'id': 'D', 'text': 'x·e^(x-1) + 1/x'},
          ],
          'correct_option_id': 'A',
          'explanation':
              '(e^x)\' = e^x và (ln x)\' = 1/x. Vậy f\'(x) = e^x + 1/x.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_mc_h02_02',
        'subject': subject,
        'topic_code': 'derivative_exp_log',
        'topic_name': 'Đạo hàm mũ & logarit',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 2,
        'hypothesis_tag': 'H02',
        'content': 'Cho f(x) = 2^x. Tính f\'(x).',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '2^x · ln 2'},
            <String, dynamic>{'id': 'B', 'text': 'x · 2^(x-1)'},
            <String, dynamic>{'id': 'C', 'text': '2^x / ln 2'},
            <String, dynamic>{'id': 'D', 'text': '2^x'},
          ],
          'correct_option_id': 'A',
          'explanation':
              'Công thức: (a^x)\' = a^x · ln a. Với a = 2: f\'(x) = 2^x · ln 2.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_mc_h02_03',
        'subject': subject,
        'topic_code': 'derivative_exp_log',
        'topic_name': 'Đạo hàm mũ & logarit',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 2,
        'hypothesis_tag': 'H02',
        'content': 'Tính đạo hàm của f(x) = log_2(x).',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '1 / (x · ln 2)'},
            <String, dynamic>{'id': 'B', 'text': '1 / (x · ln x)'},
            <String, dynamic>{'id': 'C', 'text': 'ln 2 / x'},
            <String, dynamic>{'id': 'D', 'text': '2 / x'},
          ],
          'correct_option_id': 'A',
          'explanation':
              'Công thức: (log_a(x))\' = 1/(x · ln a). Với a = 2: f\'(x) = 1/(x · ln 2).',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      // ── H03: Chain Rule (hàm hợp) ─────────────────────────────────
      <String, dynamic>{
        'id': 'mock_mc_h03_01',
        'subject': subject,
        'topic_code': 'derivative_chain_rule',
        'topic_name': 'Chain Rule',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 3,
        'hypothesis_tag': 'H03',
        'content': 'Tính đạo hàm của f(x) = sin(2x).',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '2cos(2x)'},
            <String, dynamic>{'id': 'B', 'text': 'cos(2x)'},
            <String, dynamic>{'id': 'C', 'text': '-2cos(2x)'},
            <String, dynamic>{'id': 'D', 'text': '2sin(2x)'},
          ],
          'correct_option_id': 'A',
          'explanation':
              'Chain Rule: (sin u)\' = cos u · u\'. Với u = 2x → f\'(x) = cos(2x) · 2 = 2cos(2x).',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_mc_h03_02',
        'subject': subject,
        'topic_code': 'derivative_chain_rule',
        'topic_name': 'Chain Rule',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 3,
        'hypothesis_tag': 'H03',
        'content': 'Tính đạo hàm của f(x) = e^(x^2).',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '2x · e^(x^2)'},
            <String, dynamic>{'id': 'B', 'text': 'e^(x^2)'},
            <String, dynamic>{'id': 'C', 'text': 'x^2 · e^(x^2-1)'},
            <String, dynamic>{'id': 'D', 'text': '2x · e^(2x)'},
          ],
          'correct_option_id': 'A',
          'explanation':
              'Chain Rule: (e^u)\' = e^u · u\'. Với u = x^2 → f\'(x) = e^(x^2) · 2x = 2x·e^(x^2).',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_mc_h03_03',
        'subject': subject,
        'topic_code': 'derivative_chain_rule',
        'topic_name': 'Chain Rule',
        'exam_year': examYear,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 3,
        'hypothesis_tag': 'H03',
        'content': 'Tính đạo hàm của f(x) = ln(3x + 1).',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '3 / (3x + 1)'},
            <String, dynamic>{'id': 'B', 'text': '1 / (3x + 1)'},
            <String, dynamic>{'id': 'C', 'text': '3ln(3x + 1)'},
            <String, dynamic>{'id': 'D', 'text': '(3x + 1) / 3'},
          ],
          'correct_option_id': 'A',
          'explanation':
              'Chain Rule: (ln u)\' = u\'/u. Với u = 3x+1 → f\'(x) = 3/(3x+1).',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      // ── TRUE_FALSE_CLUSTER — mixed hypotheses ──────────────────────
      <String, dynamic>{
        'id': 'mock_tf_h04_01',
        'subject': subject,
        'topic_code': 'derivative_basic_rules',
        'topic_name': 'Quy tắc tính đạo hàm',
        'exam_year': examYear,
        'question_type': 'TRUE_FALSE_CLUSTER',
        'part_no': 2,
        'difficulty_level': 2,
        'hypothesis_tag': 'H04',
        'content':
            'Xét tính đúng sai của mỗi khẳng định sau về quy tắc đạo hàm.',
        'payload': <String, dynamic>{
          'general_hint': 'Nhớ lại quy tắc tích, thương và đạo hàm lũy thừa.',
          'sub_questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'a',
              'text': '(x^3)\' = 3x^2',
              'is_true': true,
              'explanation': 'Đúng. Quy tắc lũy thừa: (x^n)\' = n·x^(n-1).',
            },
            <String, dynamic>{
              'id': 'b',
              'text': '(2x)\' = x',
              'is_true': false,
              'explanation': 'Sai. (2x)\' = 2, không phải x.',
            },
            <String, dynamic>{
              'id': 'c',
              'text': '(5)\' = 0',
              'is_true': true,
              'explanation': 'Đúng. Đạo hàm hằng số bằng 0.',
            },
            <String, dynamic>{
              'id': 'd',
              'text': '(x^2 + x)\' = 2x',
              'is_true': false,
              'explanation': 'Sai. (x^2 + x)\' = 2x + 1.',
            },
          ],
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_tf_h01_01',
        'subject': subject,
        'topic_code': 'derivative_trig',
        'topic_name': 'Đạo hàm lượng giác',
        'exam_year': examYear,
        'question_type': 'TRUE_FALSE_CLUSTER',
        'part_no': 2,
        'difficulty_level': 2,
        'hypothesis_tag': 'H01',
        'content':
            'Xét tính đúng sai của mỗi khẳng định sau về đạo hàm lượng giác.',
        'payload': <String, dynamic>{
          'general_hint': 'Nhớ công thức đạo hàm sin, cos, tan.',
          'sub_questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'a',
              'text': '(sin x)\' = cos x',
              'is_true': true,
              'explanation': 'Đúng. Công thức cơ bản.',
            },
            <String, dynamic>{
              'id': 'b',
              'text': '(cos x)\' = sin x',
              'is_true': false,
              'explanation': 'Sai. (cos x)\' = -sin x.',
            },
            <String, dynamic>{
              'id': 'c',
              'text': '(tan x)\' = 1/cos^2(x)',
              'is_true': true,
              'explanation': 'Đúng. (tan x)\' = 1/cos^2(x).',
            },
            <String, dynamic>{
              'id': 'd',
              'text': '(cot x)\' = 1/sin^2(x)',
              'is_true': false,
              'explanation': 'Sai. (cot x)\' = -1/sin^2(x).',
            },
          ],
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_tf_h03_01',
        'subject': subject,
        'topic_code': 'derivative_chain_rule',
        'topic_name': 'Chain Rule',
        'exam_year': examYear,
        'question_type': 'TRUE_FALSE_CLUSTER',
        'part_no': 2,
        'difficulty_level': 3,
        'hypothesis_tag': 'H03',
        'content':
            'Xét tính đúng sai của mỗi khẳng định sau về đạo hàm hàm hợp.',
        'payload': <String, dynamic>{
          'general_hint':
              'Áp dụng Chain Rule: [f(g(x))]\' = f\'(g(x)) · g\'(x).',
          'sub_questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'a',
              'text': '(sin 2x)\' = 2cos 2x',
              'is_true': true,
              'explanation': 'Đúng. Chain Rule: cos(2x)·2 = 2cos(2x).',
            },
            <String, dynamic>{
              'id': 'b',
              'text': '(e^(3x))\' = e^(3x)',
              'is_true': false,
              'explanation': 'Sai. (e^(3x))\' = 3·e^(3x).',
            },
            <String, dynamic>{
              'id': 'c',
              'text': '(ln(x^2))\' = 2/x',
              'is_true': true,
              'explanation': 'Đúng. (ln(x^2))\' = 2x/x^2 = 2/x.',
            },
            <String, dynamic>{
              'id': 'd',
              'text': '((2x+1)^3)\' = 3(2x+1)^2',
              'is_true': false,
              'explanation': 'Sai. Cần nhân thêm đạo hàm trong: 6(2x+1)^2.',
            },
          ],
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      // ── SHORT_ANSWER ───────────────────────────────────────────────
      <String, dynamic>{
        'id': 'mock_sa_h04_01',
        'subject': subject,
        'topic_code': 'derivative_basic_rules',
        'topic_name': 'Quy tắc tính đạo hàm',
        'exam_year': examYear,
        'question_type': 'SHORT_ANSWER',
        'part_no': 3,
        'difficulty_level': 2,
        'hypothesis_tag': 'H04',
        'content': 'Tính đạo hàm của hàm số y = 4x^3 + 2x^2 - 5.',
        'payload': <String, dynamic>{
          'exact_answer': '12x^2 + 4x',
          'accepted_answers': <String>['12x^2 + 4x', '4x + 12x^2', '12x^2+4x'],
          'explanation': 'Áp dụng quy tắc tổng: y\' = 12x^2 + 4x.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_sa_h02_01',
        'subject': subject,
        'topic_code': 'derivative_exp_log',
        'topic_name': 'Đạo hàm mũ & logarit',
        'exam_year': examYear,
        'question_type': 'SHORT_ANSWER',
        'part_no': 3,
        'difficulty_level': 2,
        'hypothesis_tag': 'H02',
        'content': 'Tính f\'(1) biết f(x) = e^x + ln x.',
        'payload': <String, dynamic>{
          'exact_answer': 'e + 1',
          'accepted_answers': <String>['e + 1', 'e+1', '1 + e'],
          'explanation': 'f\'(x) = e^x + 1/x → f\'(1) = e^1 + 1/1 = e + 1.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_sa_h01_01',
        'subject': subject,
        'topic_code': 'derivative_trig',
        'topic_name': 'Đạo hàm lượng giác',
        'exam_year': examYear,
        'question_type': 'SHORT_ANSWER',
        'part_no': 3,
        'difficulty_level': 2,
        'hypothesis_tag': 'H01',
        'content': 'Tính f\'(0) biết f(x) = 2sin x + cos x.',
        'payload': <String, dynamic>{
          'exact_answer': '2',
          'accepted_answers': <String>['2', '2.0'],
          'explanation': 'f\'(x) = 2cos x - sin x → f\'(0) = 2·1 - 0 = 2.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_sa_h03_01',
        'subject': subject,
        'topic_code': 'derivative_chain_rule',
        'topic_name': 'Chain Rule',
        'exam_year': examYear,
        'question_type': 'SHORT_ANSWER',
        'part_no': 3,
        'difficulty_level': 3,
        'hypothesis_tag': 'H03',
        'content': 'Tính đạo hàm của f(x) = (2x + 1)^4.',
        'payload': <String, dynamic>{
          'exact_answer': '8(2x + 1)^3',
          'accepted_answers': <String>['8(2x + 1)^3', '8(2x+1)^3'],
          'explanation': 'Chain Rule: 4(2x+1)^3 · 2 = 8(2x+1)^3.',
        },
        'metadata': <String, dynamic>{},
        'is_active': true,
      },
      <String, dynamic>{
        'id': 'mock_sa_h03_02',
        'subject': subject,
        'topic_code': 'derivative_chain_rule',
        'topic_name': 'Chain Rule',
        'exam_year': examYear,
        'question_type': 'SHORT_ANSWER',
        'part_no': 3,
        'difficulty_level': 3,
        'hypothesis_tag': 'H03',
        'content': 'Tính đạo hàm của f(x) = cos(x^2).',
        'payload': <String, dynamic>{
          'exact_answer': '-2x·sin(x^2)',
          'accepted_answers': <String>[
            '-2x·sin(x^2)',
            '-2xsin(x^2)',
            '-2x*sin(x^2)',
          ],
          'explanation': 'Chain Rule: -sin(x^2) · 2x = -2x·sin(x^2).',
        },
        'metadata': <String, dynamic>{},
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

  /// Xóa các trường nhạy cảm khỏi payload câu hỏi trước khi cache disk.
  ///
  /// Đảm bảo `correct_option_id` và `explanation` không bị lưu xuống bộ nhớ
  /// thiết bị. Chỉ dùng khi chuẩn bị dữ liệu để cache, KHÔNG dùng cho
  /// in-memory question pool (vì local scoring cần chúng).
  static Map<String, dynamic> stripSensitiveFieldsForCache(
    Map<String, dynamic> questionJson,
  ) {
    final payload = Map<String, dynamic>.from(
      questionJson['payload'] as Map? ?? <String, dynamic>{},
    );
    payload.remove('correct_option_id');
    payload.remove('explanation');
    // Strip from sub_questions in true/false cluster
    if (payload['sub_questions'] is List) {
      payload['sub_questions'] = (payload['sub_questions'] as List)
          .whereType<Map>()
          .map((sub) {
            final subCopy = Map<String, dynamic>.from(sub);
            subCopy.remove('explanation');
            return subCopy;
          })
          .toList(growable: false);
    }
    return <String, dynamic>{...questionJson, 'payload': payload};
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

  Future<SubmitAnswerResponse> submitAnswer({
    required String questionId,
    required String answer,
    Map<String, dynamic>? context,
  }) async {
    final response = await _apiService.submitAnswer(
      sessionId: sessionId,
      questionId: questionId,
      answer: answer,
      context: context,
    );
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    return SubmitAnswerResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> submitBatchAnswers({
    required List<Map<String, dynamic>> answers,
  }) {
    return _apiService.submitBatchAnswers(
      sessionId: sessionId,
      answers: answers,
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
