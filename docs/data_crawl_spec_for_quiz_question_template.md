# Data Crawl Spec for quiz_question_template (MVP + Phase 2)

## 1) Goal
Provide crawl output that can be inserted to `public.quiz_question_template` directly (or via simple ETL), so frontend quiz UI works without fallback.

Primary runtime table used by app: `public.quiz_question_template`.
Raw table `public.question_bank` can still be used as source-of-truth archive.

## 2) Required Deliverables from Data Team
1. `quiz_templates_normalized.ndjson` (preferred) OR `quiz_templates_normalized.csv`
2. `crawl_raw_dump.csv` (for traceability)
3. `dedup_report.csv` (duplicate source IDs, duplicate stems)
4. `quality_report.md` (validation summary)

## 3) Required Coverage for MVP
Minimum records for topic `derivative`:
1. 10 x `MULTIPLE_CHOICE`
2. 4 x `TRUE_FALSE_CLUSTER`
3. 6 x `SHORT_ANSWER`

Total minimum: 20 active templates.

## 4) Normalized Target Schema (one template per row)
Mandatory fields:
1. `subject` (text): `math`
2. `topic_code` (text): slug, example `derivative`
3. `topic_name` (text): display name, example `Đạo hàm`
4. `exam_year` (int): `2026`
5. `question_type` (text enum): `MULTIPLE_CHOICE | TRUE_FALSE_CLUSTER | SHORT_ANSWER`
6. `part_no` (smallint enum): `1 | 2 | 3`
7. `difficulty_level` (int): `1..5`
8. `content` (text): question stem
9. `payload` (json)
10. `metadata` (json)
11. `is_active` (bool): `true|false`

Optional fields:
1. `media_url` (text)

## 5) Payload Shape by Question Type

### 5.1 MULTIPLE_CHOICE (part_no = 1)
`payload` must include:
1. `options` (array of 4 objects): `[{"id":"A","text":"..."}, ...]`
2. `correct_option_id` (text): `A|B|C|D`
3. `explanation` (text)

### 5.2 TRUE_FALSE_CLUSTER (part_no = 2)
`payload` must include:
1. `sub_questions` (array of 4 objects)
2. each sub-question: `id`, `text`, `is_true`, `explanation`
3. `general_hint` (text)

Example sub-question object:
`{"id":"a","text":"...","is_true":true,"explanation":"..."}`

### 5.3 SHORT_ANSWER (part_no = 3)
`payload` must include:
1. `exact_answer` (text)
2. `accepted_answers` (array of strings)
3. `explanation` (text)

Optional:
1. `unit` (text)
2. `tolerance` (number)

## 6) Metadata Standard
Put source trace into `metadata`:
1. `source_question_id`
2. `source_provider`
3. `crawl_time`
4. `quality_status` (`draft|reviewed`)
5. `tags` (array or pipe string)

Example metadata:
`{"source_question_id":"MATH_DERIV_001","source_provider":"toanmath","quality_status":"reviewed","tags":["dao_ham","co_ban"]}`

## 7) Mapping from Existing question_bank-style Fields
Input (raw) -> Output (normalized):
1. `subject` (`Toán`) -> `subject = math`
2. `topic` (`Đạo hàm`) -> `topic_code = derivative`, `topic_name = Đạo hàm`
3. `difficulty` -> `difficulty_level`
4. `question_text` -> `content`
5. `canonical_answer`, `accepted_answers`, `hint_1`, `solution_short` -> `payload`
6. `source`, `question_id`, `quality_status`, `tags` -> `metadata`

Note: if raw `answer_type = Trắc nghiệm`, map to `question_type = MULTIPLE_CHOICE` only. Data team must crawl extra sources for TRUE_FALSE_CLUSTER and SHORT_ANSWER coverage.

## 8) Hard Validation Rules (must pass before handover)
1. No null in mandatory fields.
2. `question_type` in allowed enum only.
3. `part_no` matches question type.
4. `difficulty_level` in [1..5].
5. `accepted_answers` is non-empty for SHORT_ANSWER.
6. `options` size = 4 and unique IDs for MULTIPLE_CHOICE.
7. `sub_questions` size = 4 for TRUE_FALSE_CLUSTER.
8. Formula text sanity check and typo check passed.
9. Duplicate ratio < 5% by normalized stem hash.

## 9) NDJSON Example Records

### 9.1 MULTIPLE_CHOICE
{"subject":"math","topic_code":"derivative","topic_name":"Đạo hàm","exam_year":2026,"question_type":"MULTIPLE_CHOICE","part_no":1,"difficulty_level":2,"content":"Hàm số nào đồng biến trên R?","payload":{"options":[{"id":"A","text":"y = 2^x"},{"id":"B","text":"y = (1/2)^x"},{"id":"C","text":"y = -x^2"},{"id":"D","text":"y = -|x|"}],"correct_option_id":"A","explanation":"Cơ số > 1 thì hàm mũ đồng biến."},"metadata":{"source_question_id":"MATH_DERIV_MC_001","source_provider":"toanmath","quality_status":"reviewed","tags":["dao_ham","trac_nghiem"]},"is_active":true}

### 9.2 TRUE_FALSE_CLUSTER
{"subject":"math","topic_code":"derivative","topic_name":"Đạo hàm","exam_year":2026,"question_type":"TRUE_FALSE_CLUSTER","part_no":2,"difficulty_level":3,"content":"Xét tính đúng/sai các mệnh đề sau.","payload":{"sub_questions":[{"id":"a","text":"Hàm số đạt cực đại tại x=1","is_true":true,"explanation":"Đạo hàm đổi dấu + sang -."},{"id":"b","text":"Giá trị nhỏ nhất trên [-1;2] bằng -3","is_true":false,"explanation":"Tính tại các mốc cho min = -5."},{"id":"c","text":"Đồ thị có đúng 2 tiệm cận","is_true":true,"explanation":"1 đứng, 1 ngang."},{"id":"d","text":"y' < 0 với mọi x trong (1;3)","is_true":true,"explanation":"Bảng biến thiên cho thấy hàm giảm."}],"general_hint":"Lập bảng biến thiên trước."},"metadata":{"source_question_id":"MATH_DERIV_TF_001","source_provider":"internal_collector","quality_status":"reviewed"},"is_active":true}

### 9.3 SHORT_ANSWER
{"subject":"math","topic_code":"derivative","topic_name":"Đạo hàm","exam_year":2026,"question_type":"SHORT_ANSWER","part_no":3,"difficulty_level":2,"content":"Tính đạo hàm của hàm số y = 4x^3 + 2x^2 - 5","payload":{"exact_answer":"12x^2 + 4x","accepted_answers":["12x^2+4x","4x+12x^2"],"explanation":"Áp dụng quy tắc đạo hàm lũy thừa."},"metadata":{"source_question_id":"MATH_DERIV_SA_001","source_provider":"internal_collector","quality_status":"reviewed"},"is_active":true}

## 10) Handover Gate
Data handover is accepted only if:
1. Validation report says pass for all hard rules.
2. Data import to Supabase completes without manual patch.
3. Import report includes insert/update/reject stats and reject reasons.
4. Frontend fetch shows mixed type templates in quiz flow.

## 11) Post-import Verify Queries (Data must attach result)
1. Total active rows for derivative:
```sql
select count(*) as total_active
from public.quiz_question_template
where topic_code = 'derivative' and is_active = true;
```

2. Breakdown by question_type:
```sql
select question_type, count(*) as cnt
from public.quiz_question_template
where topic_code = 'derivative' and is_active = true
group by question_type
order by question_type;
```

3. Quick payload sanity:
```sql
select id, question_type, part_no
from public.quiz_question_template
where topic_code = 'derivative' and is_active = true
order by updated_at desc
limit 20;
```
