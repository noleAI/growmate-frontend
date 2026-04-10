# Data Request to Data Team (Quiz)

## 1) Chốt table đích để Data crawl
- Table đích để app đọc trực tiếp: public.quiz_question_template
- public.question_bank chỉ là kho raw, không phải nguồn trả trực tiếp cho UI

## 2) Trạng thái file cũ / đã loại bỏ
- docs/quiz_question_template_derivative.csv: đã loại khỏi repo vì vẫn ở format raw (question_text, answer_type, canonical_answer), không đúng schema import đích.
- docs/question_bank_rows.csv: không tồn tại trong repo hiện tại; nếu Data team còn giữ bản local thì chỉ dùng làm raw tham khảo, không dùng để import trực tiếp.

## 3) File Data cần bàn giao
1. quiz_templates_normalized.ndjson hoặc csv theo schema đích
2. crawl_raw_dump.csv (de trace)
3. dedup_report.csv
4. quality_report.md
5. import_sql.sql hoặc import_job_note.md (mô tả cách import đã chạy)
6. import_result_report.md (số dòng insert/update/fail + lý do)

## 4) Schema row bắt buộc cho quiz_question_template
- subject
- topic_code
- topic_name
- exam_year
- question_type: MULTIPLE_CHOICE | TRUE_FALSE_CLUSTER | SHORT_ANSWER
- part_no: 1 | 2 | 3
- difficulty_level: 1..5
- content
- payload (json)
- metadata (json)
- is_active
- media_url (optional)

## 5) Rule payload bắt buộc
- MULTIPLE_CHOICE: options(4), correct_option_id, explanation
- TRUE_FALSE_CLUSTER: sub_questions(4), general_hint
- SHORT_ANSWER: exact_answer, accepted_answers, explanation

## 6) Coverage MVP tối thiểu
- MULTIPLE_CHOICE >= 10
- TRUE_FALSE_CLUSTER >= 4
- SHORT_ANSWER >= 6
- Tổng >= 20 record active cho derivative

## 7) Rule quality trước khi handover
1. Không null field bắt buộc
2. Đúng enum question_type và part_no
3. options đúng 4 đáp án A/B/C/D
4. true_false cluster có đúng 4 sub_questions
5. accepted_answers của short answer không rỗng
6. Formula và lời giải đã spell-check

## 8) Mẫu import-ready để Data follow
- docs/quiz_question_template_import_ready_example.csv

## 9) Message gửi team Data (copy)
Team Data vui lòng crawl và import trực tiếp lên Supabase theo schema quiz_question_template (không gửi raw-only question_bank). Vui lòng follow đúng file docs/data_crawl_spec_for_quiz_question_template.md và docs/quiz_question_template_import_ready_example.csv. Scope MVP derivative cần tối thiểu 20 record active, đủ 3 question types, pass toàn bộ hard validation rules.

## 10) Yêu cầu import trực tiếp lên Supabase (Data own)
1. Import vào table public.quiz_question_template (upsert theo metadata.source_question_id nếu có).
2. Đảm bảo question_type, part_no, payload đúng enum/rules trước khi ghi DB.
3. Sau import gửi import_result_report.md gồm:
	- số record input, số insert, số update, số reject
	- danh sách reject top 20 + lý do
	- thống kê theo question_type
4. Chạy query verify sau import và gửi kết quả:
	- tổng record active theo topic_code='derivative'
	- breakdown theo 3 question_type
5. Xác nhận app đọc được dữ liệu thật (không fallback mock) qua ít nhất 1 screenshot/query response.
