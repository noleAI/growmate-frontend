# Frontend Sync Plan — Backend API Changes (2026-04-18)

> **Mục đích**: Liệt kê tất cả thay đổi Frontend cần thực hiện để đồng bộ với backend mới nhất (`growmate_backend`).
> **Người tạo**: Auto-generated from codebase diff analysis
> **Ngày**: 2026-04-18

---

## Tổng quan thay đổi Backend

Backend hiện tại có các module API sau:
- **Session** (`/api/v1/sessions`) — tạo, cập nhật, pending, interact
- **Quiz** (`/api/v1/quiz`) — next, submit, result, history
- **Leaderboard/XP/Badges** (`/api/v1/leaderboard`, `/xp/add`, `/badges`)
- **Lives** (`/api/v1/lives`) — get, lose, regen
- **Quota** (`/api/v1/quota`) — daily quota
- **Onboarding** (`/api/v1/onboarding`) — questions, submit
- **User Profile** (`/api/v1/user/profile`) — get, update
- **Formula Handbook** (`/api/v1/formulas`)
- **Chatbot** (`/api/v1/chatbot`) — chat, chat/image, quota, history, delete history ⚠️ **MỚI**
- **Orchestrator** (`/api/v1/orchestrator/step`)
- **Inspection** (`/api/v1/inspection`) — belief, particle, q-values, audit, metrics, alerts
- **Session Recovery** (`/api/v1/session/pending`) — compat route
- **WebSocket** (`/ws/v1/behavior`, `/ws/v1/dashboard/stream`)

---

## MỤC LỤC THAY ĐỔI

| # | Khu vực | Mức ưu tiên | Trạng thái FE hiện tại |
|---|---------|-------------|----------------------|
| 1 | Quiz Submit — fields mới | **P0** | Thiếu `question_index`, `total_questions`, `time_taken_sec` |
| 2 | Quiz Submit Response — fields mới | **P0** | Thiếu `score`, `max_score`, `progress_percent`, `quiz_summary` |
| 3 | Session Pending — fields mới | **P0** | Thiếu `mode`, `pause_state`, `next_question_index`, `resume_context_version` |
| 4 | Chatbot API — hoàn toàn mới | **P0** | Chưa có repository/model nào |
| 5 | Quota Repository — sai endpoint | **P1** | Gọi `/chatbot/quota` thay vì `/quota` |
| 6 | Legacy ApiService — cần deprecate | **P1** | Vẫn dùng `/quiz/submit-answer` (không tồn tại ở backend) |
| 7 | Session Create — idempotent behavior | **P1** | Chưa handle reuse session |
| 8 | Lives trong quiz submit response | **P1** | Model đã có nhưng chưa dùng ở UI |
| 9 | Leaderboard — thiếu `longest_streak` | **P2** | Model thiếu field |
| 10 | Onboarding questions — field mapping | **P2** | Parse `question` thay vì `content` |
| 11 | Formula Handbook — chưa tích hợp | **P2** | Không có repository |
| 12 | Chatbot Image Upload | **P2** | Chưa có |
| 13 | Session History — chuyển sang backend API | **P2** | Đang dùng SharedPreferences local |
| 14 | Backend Profile — thiếu `created_at`, `updated_at` | **P3** | Model thiếu fields |
| 15 | WebSocket — behavior telemetry auth | **P3** | Chưa gửi JWT qua WS |

---

## CHI TIẾT TỪNG MỤC

---

### 1. [P0] Quiz Submit — Thêm fields request

**Vấn đề**: Backend `POST /api/v1/quiz/submit` nhận thêm `question_index`, `total_questions`, `time_taken_sec`. Frontend `QuizApiRepository.submitAnswer()` chưa gửi `question_index` và `total_questions`.

**File cần sửa**:
- `lib/features/quiz/data/repositories/quiz_api_repository.dart`
  - Thêm params `questionIndex` và `totalQuestions` vào `submitAnswer()`
  - Gửi `question_index` và `total_questions` trong body

**Mẫu body đúng theo backend**:
```json
{
  "session_id": "<id>",
  "question_id": "MATH_DERIV_1",
  "selected_option": "A",
  "answer": null,
  "answers": null,
  "time_taken_sec": 12.4,
  "mode": "exam_prep",
  "question_index": 0,
  "total_questions": 10
}
```

---

### 2. [P0] Quiz Submit Response — Parse fields mới

**Vấn đề**: Backend trả thêm `score`, `max_score`, `progress_percent`, `last_question_index`, `total_questions`, `quiz_summary` trong response. Frontend `QuizSubmitResponse` chỉ parse `is_correct`, `explanation`, `lives_remaining`, `can_play`, `next_regen_in_seconds`.

**File cần sửa**:
- `lib/features/quiz/data/models/quiz_api_models.dart` — class `QuizSubmitResponse`
  - Thêm fields: `score`, `maxScore`, `progressPercent`, `lastQuestionIndex`, `totalQuestions`, `quizSummary`

**Response mẫu từ backend**:
```json
{
  "session_id": "<id>",
  "question_id": "MATH_DERIV_1",
  "is_correct": true,
  "explanation": "...",
  "score": 1.0,
  "max_score": 1.0,
  "progress_percent": 10,
  "last_question_index": 1,
  "total_questions": 10,
  "quiz_summary": {
    "answered_count": 1,
    "correct_count": 1,
    "total_score": 1.0,
    "max_score": 1.0,
    "accuracy_percent": 100
  }
}
```

---

### 3. [P0] Session Pending — Parse fields mới

**Vấn đề**: Backend `GET /sessions/pending` trả thêm `mode`, `pause_state`, `pause_reason`, `next_question_index`, `resume_context_version`. Frontend chưa có model cho pending session response.

**File cần tạo/sửa**:
- **[NEW]** `lib/features/session_recovery/data/models/pending_session.dart` — model class
- **[NEW]** `lib/features/session_recovery/data/repositories/pending_session_repository.dart` — gọi `GET /sessions/pending`

**Response mẫu từ backend**:
```json
{
  "has_pending": true,
  "session": {
    "session_id": "<uuid>",
    "status": "active",
    "last_question_index": 3,
    "next_question_index": 3,
    "total_questions": 10,
    "progress_percent": 30,
    "mode": "exam_prep",
    "pause_state": false,
    "pause_reason": null,
    "resume_context_version": 1,
    "last_active_at": "...",
    "abandoned_at": null
  }
}
```

---

### 4. [P0] Chatbot API — Hoàn toàn mới

**Vấn đề**: Backend có module chatbot hoàn chỉnh tại `/api/v1/chatbot/` nhưng Frontend chưa có repository hay model nào.

**Endpoints cần tích hợp**:
| Method | Path | Mô tả |
|--------|------|--------|
| `POST` | `/chatbot/chat` | Gửi tin nhắn, nhận reply |
| `POST` | `/chatbot/chat/image` | Gửi ảnh + câu hỏi |
| `GET` | `/chatbot/quota` | Quota chat hàng ngày |
| `GET` | `/chatbot/history?limit=40` | Lịch sử chat |
| `DELETE` | `/chatbot/history` | Xoá lịch sử chat |

**File cần tạo**:
- **[NEW]** `lib/features/chat/data/models/chat_models.dart`
  - `ChatMessage(role, content, createdAt, attachment?)`
  - `ChatResponse(reply, isBlocked, remainingQuota)`
  - `ChatQuotaStatus(used, limit, remaining, isUnlimited, resetAt)`
- **[NEW]** `lib/features/chat/data/repositories/chat_repository.dart`
  - `sendMessage(message, history) → ChatResponse`
  - `sendMessageWithImage(message, imageBytes, mimeType) → ChatResponse`
  - `getChatQuota() → ChatQuotaStatus`
  - `getChatHistory(limit) → List<ChatMessage>`
  - `deleteChatHistory() → void`

**Request mẫu `POST /chatbot/chat`**:
```json
{
  "message": "Giải thích đạo hàm hàm hợp",
  "history": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ]
}
```

**Response**: `{"reply": "...", "is_blocked": false, "remaining_quota": 29}`

---

### 5. [P1] Quota Repository — Sửa endpoint path

**Vấn đề**: `QuotaRepository.fetchQuota()` gọi `/chatbot/quota` trước, fallback `/quota`. Nhưng backend có 2 quota riêng biệt:
- `/api/v1/quota` — quota session/quiz hàng ngày
- `/api/v1/chatbot/quota` — quota chat hàng ngày (có thêm `is_unlimited`)

**File cần sửa**:
- `lib/features/quota/data/repositories/quota_repository.dart`
  - Gọi thẳng `/quota` cho quiz quota (bỏ fallback logic)
- `lib/features/quota/data/models/quota_status.dart`
  - Kiểm tra model có match response `{used, limit, remaining, reset_at}`

---

### 6. [P1] Legacy ApiService — Deprecate

**Vấn đề**: `ApiService` interface và `MockApiService` dùng endpoints không tồn tại ở backend:
- `/quiz/submit-answer` → backend chỉ có `/quiz/submit`
- `/quiz/submit-batch` → backend không có endpoint này
- `getDiagnosis()` → backend không có endpoint riêng, dùng `/sessions/{id}/interact`
- `confirmHITL()` → backend không có endpoint riêng

**File cần sửa**:
- `lib/core/network/api_service.dart` — đánh dấu `@Deprecated` hoặc loại bỏ
- `lib/core/network/mock_api_service.dart` — update mock cho phù hợp API thực
- Tất cả files import `ApiService` cần chuyển sang dùng:
  - `QuizApiRepository` cho quiz flow
  - `AgenticApiService` cho interact/orchestrator flow

---

### 7. [P1] Session Create — Handle idempotent behavior

**Vấn đề**: Backend `POST /sessions` có behavior idempotent: nếu user đã có active session, API trả lại session cũ thay vì tạo mới. Frontend cần handle case này.

**File cần sửa**:
- Bloc/Cubit gọi create session cần check response và nhận ra đây có thể là session cũ
- Nếu `initial_state` chứa progress > 0, nên show resume UI thay vì start fresh

---

### 8. [P1] Lives trong Quiz Submit Response

**Vấn đề**: Khi mode ≠ `explore` và user trả lời sai, backend response kèm `lives_remaining`, `can_play`, `next_regen_in_seconds`. Model `QuizSubmitResponse` đã có fields này nhưng UI quiz chưa hiển thị/handle.

**File cần sửa**:
- Quiz Bloc/Cubit — sau khi submit sai ở exam_prep mode:
  - Cập nhật LivesInfo state
  - Nếu `can_play == false` → navigate sang màn hình chờ hồi tim
- `lib/features/quiz/presentation/` — thêm UI handler cho `403 no_lives_remaining`

---

### 9. [P2] Leaderboard — Thiếu fields

**Vấn đề**: Backend trả thêm `longest_streak`, `badge_count`, `xp` (ranking XP) cho mỗi entry. Frontend `LeaderboardEntry` chưa có tất cả.

**File cần sửa**:
- `lib/features/leaderboard/data/models/leaderboard_entry.dart`
  - Thêm: `longestStreak`, `badgeCount`, `xp` (nullable)
- `lib/features/leaderboard/data/repositories/real_leaderboard_repository.dart`
  - Parse thêm fields từ response

---

### 10. [P2] Onboarding Questions — Field mapping

**Vấn đề**: `RealOnboardingRepository.getDiagnosticQuestions()` parse `q['content']` cho questionText, nhưng backend onboarding trả `question` (không phải `content`).

**Backend response**:
```json
{
  "questions": [
    {
      "question_id": "onb_01",
      "question": "Đạo hàm của x^2 là gì?",
      "options": ["2x", "x", "x^2", "2"],
      "difficulty": "easy"
    }
  ]
}
```

**File cần sửa**:
- `lib/features/onboarding/data/repositories/real_onboarding_repository.dart`
  - Line ~41: đổi `q['content']` → `q['question'] ?? q['content'] ?? ''`
  - Xử lý options dạng plain string (backend trả `["2x", "x", ...]` thay vì `[{"id":"A","text":"2x"},...]`)

---

### 11. [P2] Formula Handbook — Chưa tích hợp

**Vấn đề**: Backend có endpoint `GET /api/v1/formulas?category=all&search=...` trả danh sách công thức với mastery status. Frontend chưa có repository.

**File cần tạo**:
- **[NEW]** `lib/features/roadmap/data/models/formula_models.dart`
  - `FormulaCategory(id, name, description, formulaCount, masteryPercent, formulas)`
  - `Formula(id, title, latex, explanation, example, difficulty, masteryPercent, masteryStatus)`
- **[NEW]** `lib/features/roadmap/data/repositories/formula_repository.dart`
  - `getFormulas(category, search) → FormulaResponse`

---

### 12. [P2] Chatbot Image Upload

**Vấn đề**: Backend hỗ trợ `POST /chatbot/chat/image` (multipart form: `message` + `image` file). Frontend chat feature chưa có image upload.

**File cần sửa**:
- `lib/core/network/rest_api_client.dart` — thêm method `postMultipart()` cho file upload
- Chat repository (mục 4) cần implement `sendMessageWithImage()`

---

### 13. [P2] Session History — Chuyển sang Backend API

**Vấn đề**: `SessionHistoryRepository` lưu history vào `SharedPreferences` (local). Backend đã có `GET /quiz/history` và `GET /quiz/sessions/{id}/result`.

**File cần sửa**:
- `lib/features/session/data/repositories/session_history_repository.dart`
  - Chuyển từ SharedPreferences sang gọi `QuizApiRepository.getQuizHistory()`
  - Hoặc tạo mới `RealSessionHistoryRepository` wrapping `QuizApiRepository`
- `lib/features/session/data/models/session_history_entry.dart`
  - Map từ `QuizHistoryItem` sang `SessionHistoryEntry`

---

### 14. [P3] Backend Profile — Thiếu fields

**Vấn đề**: Backend profile response có `created_at`, `updated_at` nhưng `BackendUserProfile` model chưa parse.

**File cần sửa**:
- `lib/data/repositories/backend_profile_repository.dart`
  - Thêm `createdAt`, `updatedAt` vào `BackendUserProfile`

---

### 15. [P3] WebSocket — Auth token

**Vấn đề**: `AgenticWsService` connect WebSocket không gửi JWT token. Backend WS endpoints có thể yêu cầu auth.

**File cần sửa**:
- `lib/core/network/ws_service.dart`
  - Thêm token vào URI query params hoặc custom headers khi connect

---

## CHECKLIST TÍCH HỢP (từ Backend Handoff)

Dựa trên `HANDOFF_FRONTEND.md` section 10:

- [ ] Đọc profile khi mở app để quyết định vào onboarding hay không → Cần `BackendProfileRepository.fetchProfile()` check `onboarded_at`
- [ ] Tạo session với `mode` rõ ràng (`exam_prep` hoặc `explore`) → OK, `AgenticApiService.createSession()` có param mode
- [ ] Trước và trong quiz, gọi `GET /lives` để hiển thị tim → `RealLivesRepository` đã có, cần wire vào quiz UI
- [ ] Handle `403 no_lives_remaining` → Cần thêm error handling trong quiz bloc
- [ ] Dùng `GET /sessions/pending` để hiện banner resume → Cần tạo `PendingSessionRepository` (mục 3)
- [ ] Chỉ render quiz data từ backend, không giữ đáp án đúng ở client → `QuizApiRepository` flow đã đúng; legacy `QuizRepository` vẫn giữ `correct_option_id` trong fallback mock data
- [ ] Nếu HMAC bật, gửi signature headers → `RestApiClient` + `HmacSigner` đã có, cần verify hoạt động đúng

---

## THỨ TỰ THỰC HIỆN ĐỀ XUẤT

### Phase 1 — P0 Critical (cần hoàn thành trước khi test E2E)
1. Sửa `QuizSubmitResponse` model (mục 2)
2. Sửa `QuizApiRepository.submitAnswer()` request body (mục 1)
3. Tạo `PendingSession` model + repository (mục 3)
4. Tạo `ChatRepository` + models (mục 4)

### Phase 2 — P1 Important (cần cho production)
5. Fix quota endpoint path (mục 5)
6. Deprecate legacy `ApiService` (mục 6)
7. Handle session create idempotent (mục 7)
8. Wire lives vào quiz UI (mục 8)

### Phase 3 — P2 Nice-to-have (enhancement)
9. Leaderboard model update (mục 9)
10. Onboarding field mapping fix (mục 10)
11. Formula handbook integration (mục 11)
12. Chatbot image upload (mục 12)
13. Session history migration (mục 13)

### Phase 4 — P3 Polish
14. Profile model fields (mục 14)
15. WebSocket auth (mục 15)

---

## LƯU Ý QUAN TRỌNG

### Error Codes cần handle
| HTTP | detail | Ý nghĩa |
|------|--------|---------|
| 400 | `Invalid mode...` | Mode không hợp lệ |
| 401 | `Could not validate credentials` | Token expired/invalid |
| 401 | `missing_signature_headers` | Thiếu HMAC headers |
| 401 | `signature_expired` | HMAC signature hết hạn |
| 403 | `no_lives_remaining` | Hết tim (exam_prep mode) |
| 429 | `quiz_rate_limit` | Vượt giới hạn session/ngày |
| 429 | `chat_quota_exceeded` | Hết quota chat |

### Backend API Base Path
- REST: `/api/v1`
- WebSocket: `/ws/v1`
- Tất cả protected endpoints cần header: `Authorization: Bearer <supabase_jwt>`

---

*Tài liệu này được generate tự động từ phân tích source code backend và frontend. Cập nhật lần cuối: 2026-04-18.*
