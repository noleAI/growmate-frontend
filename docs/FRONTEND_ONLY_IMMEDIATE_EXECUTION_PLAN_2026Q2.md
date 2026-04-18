# Frontend-Only Immediate Execution Plan (2026 Q2)

## 1. Scope
Tài liệu này chỉ bao gồm các hạng mục Frontend có thể triển khai ngay, không cần thay đổi API, schema, hay logic Backend.

## 2. Goals (2-3 tuần)
1. Giảm mất tiến độ làm bài khi người dùng thoát app hoặc mạng yếu.
2. Tăng độ mượt và độ rõ ràng của màn Quiz + Agentic timeline.
3. Nâng chất lượng UX, accessibility và độ an toàn khi release UI mới.

## 3. Frontend Tasks Can Start Now

### A. Quiz Local-First Reliability
1. Auto-save đáp án theo từng câu vào local storage ngay khi user thao tác.
2. Auto-restore khi user quay lại quiz hoặc mở lại app.
3. Chặn double-submit ở tầng UI bằng cờ submitting + debounce.
4. Hiển thị trạng thái local draft: saved, syncing, restored.

Done criteria:
1. Kill app giữa chừng, mở lại vẫn giữ đáp án đúng.
2. Bấm nút nộp liên tục không gửi trùng từ phía client.

### B. Agentic Timeline UX Upgrade
1. Thêm filter theo Academic, Empathy, Strategy.
2. Expand/collapse chi tiết từng step.
3. Thêm badge trạng thái từng step: running, completed, failed, fallback.
4. Thêm action copy step summary để QA/report lỗi nhanh.

Done criteria:
1. User đọc được tiến trình reasoning theo từng agent.
2. QA có thể copy trace ngắn gọn ngay từ UI.

### C. Performance Optimization (UI Layer)
1. Giảm rebuild không cần thiết bằng tách widget nhỏ.
2. Dùng bloc selector/buildWhen cho vùng state thay đổi.
3. Render timeline theo cửa sổ (ví dụ 20 step gần nhất, mở rộng khi cần).
4. Tối ưu animation để tránh drop frame khi trace dài.

Done criteria:
1. FPS >= 50 trên thiết bị Android tầm trung đã chọn.
2. Không giật khi đổi câu liên tục hoặc khi timeline cập nhật nhanh.

### D. Accessibility and UX Polish
1. Chế độ Reduced Motion để giảm animation.
2. Tăng contrast cho chip/trạng thái timeline.
3. Kiểm tra text scale 1.3-1.5 không vỡ layout.
4. Chuẩn hóa spacing/touch target cho thao tác trên mobile.

Done criteria:
1. Màn quiz dùng ổn định với text scale lớn.
2. Trạng thái timeline vẫn đọc rõ trong điều kiện ánh sáng mạnh.

### E. Frontend Telemetry and Diagnostics
1. Chuẩn hóa event client:
- quiz_started
- answer_changed
- answer_restored
- submit_clicked
- submit_succeeded
- submit_failed
- session_resumed
2. Log timing phía client:
- time_to_first_answer
- total_quiz_duration
- submit_latency_client
3. Gắn session correlation token ở client logs để debug.

Done criteria:
1. Có thể phân tích hành vi user bằng log client-only.
2. Có đủ dữ liệu để so sánh before/after sau mỗi bản release.

### F. Frontend QA Automation
1. Widget tests cho flow chọn đáp án và restore draft.
2. Integration test cho continue session và submit lock.
3. Golden tests cho Agentic timeline states.

Done criteria:
1. Regression chính của Quiz và Timeline được test tự động.
2. Build CI fail nếu UI regression ở vùng trọng yếu.

### G. Feature Flag at Client Side
1. Tạo cờ local cho timeline nâng cao.
2. Bật/tắt theo build flavor hoặc debug menu.
3. Chuẩn bị rollback UI nhanh không cần revert lớn.

Done criteria:
1. Có thể tắt tính năng mới trong vòng vài phút bằng config client.

## 4. Suggested Sprint Breakdown (10 working days)

### Sprint Day 1-2
1. Auto-save + auto-restore quiz draft.
2. Submit lock chống double-tap.

### Sprint Day 3-4
1. Filter và badge trạng thái Agentic timeline.
2. Expand/collapse step details.

### Sprint Day 5-6
1. Giảm rebuild và tối ưu render timeline.
2. Kiểm thử hiệu năng trên thiết bị tầm trung.

### Sprint Day 7
1. Reduced motion + contrast + text scale fixes.

### Sprint Day 8
1. Event telemetry phía client + timing metrics.

### Sprint Day 9
1. Widget/integration/golden tests cho luồng chính.

### Sprint Day 10
1. Stabilization, QA pass, release checklist.

## 5. Priority Matrix (Impact x Effort)
1. High Impact, Low/Medium Effort:
- Auto-save/restore draft
- Submit lock
- Timeline filter + status badge
2. High Impact, Medium Effort:
- Render optimization
- Integration tests
3. Medium Impact, Low Effort:
- Reduced motion
- Contrast and text-scale fixes
- Client telemetry events

## 6. Ownership Template (Frontend Only)
1. Frontend Lead: kiến trúc state và hiệu năng.
2. UI Engineer: timeline UX và accessibility.
3. QA Engineer: automation + regression matrix.
4. Product/Design: acceptance criteria và UX sign-off.

## 7. Definition of Done (Frontend Scope)
1. Tất cả task A-G hoàn tất theo done criteria.
2. Không có lỗi analyzer ở các file sửa đổi.
3. Test automation mới chạy pass trên CI nội bộ.
4. QA xác nhận 3 flow trọng yếu:
- làm bài bình thường
- continue bài dở
- timeline hiển thị đúng trạng thái

## 8. Out of Scope
1. Thay đổi API contract.
2. Logic chấm điểm/agent orchestration phía server.
3. Điều chỉnh schema dữ liệu backend.
