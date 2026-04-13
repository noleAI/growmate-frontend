-- =============================================================================
-- Fix TRUE_FALSE_CLUSTER payload: Thêm sub_questions bị thiếu
-- Chạy trên Supabase SQL Editor
-- =============================================================================

-- Câu 1: "Dùng định nghĩa để tính đạo hàm của hàm số f(x) = 2x³"
-- f'(x) = 6x² → f'(1) = 6 (không phải -6), f'(0) = 0, f'(2) = 24
UPDATE quiz_question_template
SET payload = jsonb_set(
  payload,
  '{sub_questions}',
  '[
    {"id":"a","text":"Với bất kì x₀: f''(x₀) = lim [f(x)-f(x₀)]/(x-x₀)","is_true":true,"explanation":"Đúng theo định nghĩa đạo hàm."},
    {"id":"b","text":"f''(1) = -6","is_true":false,"explanation":"Sai. f''(x) = 6x² → f''(1) = 6, không phải -6."},
    {"id":"c","text":"f''(0) = 0","is_true":true,"explanation":"Đúng. f''(0) = 6(0)² = 0."},
    {"id":"d","text":"f''(2) = 24","is_true":true,"explanation":"Đúng. f''(2) = 6(4) = 24."}
  ]'::jsonb
)
WHERE id = '38171940-c51d-429e-9c62-1d67053ae0fc';


-- Câu 2: "Cho hàm số y = 2x³, x₀ = -1"
-- f'(-1) = 6, PTTT: y = 6x + 4, đi qua A(0;4), cắt y=3x tại x=-4/3, vuông góc với y=-1/6x
UPDATE quiz_question_template
SET payload = jsonb_set(
  payload,
  '{sub_questions}',
  '[
    {"id":"a","text":"Hệ số góc của tiếp tuyến của (C) tại điểm M bằng 6","is_true":true,"explanation":"Đúng. f''(x) = 6x² → f''(-1) = 6."},
    {"id":"b","text":"Phương trình tiếp tuyến của (C) tại M đi qua điểm A(0;4)","is_true":true,"explanation":"Đúng. PTTT: y = 6(x+1) - 2 = 6x + 4. Thay x=0 → y = 4."},
    {"id":"c","text":"Phương trình tiếp tuyến của (C) tại M cắt đường thẳng d: y = 3x tại điểm có hoành độ bằng 4","is_true":false,"explanation":"Sai. 6x + 4 = 3x → x = -4/3, không phải 4."},
    {"id":"d","text":"Phương trình tiếp tuyến của (C) tại M vuông góc với đường thẳng Δ: y = -1/6 x","is_true":true,"explanation":"Đúng. Tích hệ số góc: 6 × (-1/6) = -1."}
  ]'::jsonb
)
WHERE id = '71b9bd42-59cb-464b-97e8-9cc18008cfe6';


-- Câu 3: "Cho hàm số y = x² + 3x + 1, tiếp tuyến tại giao điểm với trục tung"
-- y'' = 2x + 3, tại x=0 → k = 3, PTTT: y = 3x + 1
UPDATE quiz_question_template
SET payload = jsonb_set(
  payload,
  '{sub_questions}',
  '[
    {"id":"a","text":"Hệ số góc của phương trình tiếp tuyến bằng 3","is_true":true,"explanation":"Đúng. f''(x) = 2x + 3 → f''(0) = 3."},
    {"id":"b","text":"Phương trình tiếp tuyến đi qua điểm A(1;3)","is_true":false,"explanation":"Sai. PTTT: y = 3x + 1. Thay x = 1 → y = 4, không phải 3."},
    {"id":"c","text":"Phương trình tiếp tuyến cắt đường thẳng y = 2x + 1 tại điểm có hoành độ bằng 0","is_true":true,"explanation":"Đúng. 3x + 1 = 2x + 1 → x = 0."},
    {"id":"d","text":"Phương trình tiếp tuyến vuông góc với đường thẳng y = -1/3 x + 1","is_true":true,"explanation":"Đúng. Tích hệ số góc: 3 × (-1/3) = -1."}
  ]'::jsonb
)
WHERE id = 'a6a7616c-1d9f-4ce6-a0ad-1e4e08b07aa6';


-- =============================================================================
-- Fix TRUE_FALSE_CLUSTER payload: Thêm sub_questions bị thiếu (2 câu còn lại)
-- Chạy trên Supabase SQL Editor
-- =============================================================================

-- Câu 4: "Viết được phương trình tiếp tuyến của đồ thị hàm số y = 4/(x-1) tại x₀ = -1"
-- y' = -4/(x-1)², y'(-1) = -1, PTTT: y = -x - 3
UPDATE quiz_question_template
SET payload = jsonb_set(
  payload,
  '{sub_questions}',
  '[
    {"id":"a","text":"Hệ số góc của phương trình tiếp tuyến bằng 1","is_true":false,"explanation":"Sai. y'' = -4/(x-1)² → y''(-1) = -4/4 = -1, không phải 1."},
    {"id":"b","text":"Phương trình tiếp tuyến đi qua điểm M(-1;2)","is_true":false,"explanation":"Sai. PTTT: y = -x - 3. Thay x=-1 → y = -2, không phải 2."},
    {"id":"c","text":"Phương trình tiếp tuyến cắt đường thẳng y = 2x + 1 tại điểm có hoành độ bằng 4/3","is_true":false,"explanation":"Sai. -x - 3 = 2x + 1 → x = -4/3, không phải 4/3."},
    {"id":"d","text":"Phương trình tiếp tuyến vuông góc với đường thẳng y = x + 1","is_true":true,"explanation":"Đúng. Tích hệ số góc: (-1) × 1 = -1."}
  ]'::jsonb
)
WHERE id = 'fd561871-2159-4173-a588-470bdcd4d35f';


-- Câu 5: "Cho hàm số f(x) = x³ − 3x² + 2x"
-- f'(x) = 3x² - 6x + 2, f'(3) = 11, f'(4) = 26, f'(5) = 47, f'(2) = 2, f'(-2) = 26
UPDATE quiz_question_template
SET payload = jsonb_set(
  payload,
  '{sub_questions}',
  '[
    {"id":"a","text":"Hàm số có đạo hàm là f''(x) = 3x² − 6x + 2","is_true":true,"explanation":"Đúng. Áp dụng đạo hàm đa thức cơ bản."},
    {"id":"b","text":"f''(3) = 6","is_true":false,"explanation":"Sai. f''(3) = 27 - 18 + 2 = 11, không phải 6."},
    {"id":"c","text":"f''(4) < f''(5)","is_true":true,"explanation":"Đúng. f''(4) = 26 < f''(5) = 47."},
    {"id":"d","text":"f''(2) + f''(-2) = 0","is_true":false,"explanation":"Sai. f''(2) = 2, f''(-2) = 26 → 2 + 26 = 28, không phải 0."}
  ]'::jsonb
)
WHERE id = 'fe7f8e42-2a46-42b4-a9a4-091a03f1cee5';


-- =============================================================================
-- VERIFY: Kiểm tra lại sau khi update tất cả 5 câu
-- =============================================================================

-- 1. Tổng số câu active theo loại
SELECT question_type, count(*) AS cnt
FROM quiz_question_template
WHERE topic_code = 'derivative' AND is_active = true
GROUP BY question_type
ORDER BY question_type;

-- 2. Kiểm tra tất cả 5 câu TRUE_FALSE_CLUSTER đều có 4 sub_questions
SELECT id, question_type,
  jsonb_array_length(payload->'sub_questions') AS sub_q_count
FROM quiz_question_template
WHERE question_type = 'TRUE_FALSE_CLUSTER'
  AND is_active = true
ORDER BY sub_q_count;
