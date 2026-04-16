# GrowMate Frontend – Audit & Refinement Plan

**Ngày tạo:** 16/04/2026  
**Dựa trên:** `API_INVENTORY.md` (25 HTTP endpoints + 2 WebSocket)  
**Phạm vi:** Kiểm tra tích hợp API, mock data, UI/UX consistency

---

## Mục lục

1. [Tổng quan tích hợp API](#1-tổng-quan-tích-hợp-api)
2. [Chi tiết: API đã tích hợp vs chưa tích hợp](#2-chi-tiết-api-đã-tích-hợp-vs-chưa-tích-hợp)
3. [Danh sách Mock Data cần thay thế](#3-danh-sách-mock-data-cần-thay-thế)
4. [Vấn đề UI/UX chưa hợp lí](#4-vấn-đề-uiux-chưa-hợp-lí)
5. [Vấn đề đồng bộ UI/UX](#5-vấn-đề-đồng-bộ-uiux)
6. [Kế hoạch hành động (Action Plan)](#6-kế-hoạch-hành-động-action-plan)

---

## 1. Tổng quan tích hợp API

### Ma trận trạng thái

| Trạng thái | Số lượng | Tỷ lệ |
|---|---|---|
| ✅ Đã có Real implementation | 14 | 52% |
| ⚠️ Có Real nhưng đang bị gating bởi `useMockApi=true` | 14 | 52% |
| 🟡 Có endpoint nhưng chưa dùng trong UI flow | 4 | 15% |
| ❌ Chưa có implementation (100% mock/local) | 7 | 26% |
| 🔌 WebSocket đã có implementation | 2/2 | 100% |

> **Lưu ý quan trọng:** Feature flag `USE_MOCK_API` default = `true`, `USE_AGENTIC_BACKEND` default = `false`.  
> Tức là production đang chạy **100% mock data** cho ApiService layer + mock repositories cho Leaderboard/Lives/Formula/Onboarding.

---

## 2. Chi tiết: API đã tích hợp vs chưa tích hợp

### ✅ Đã có Real Implementation (sẵn sàng khi bật `USE_MOCK_API=false`)

| # | API Endpoint | Backend Path | Frontend Implementation | File |
|---|---|---|---|---|
| 1 | **Create Session** | `POST /sessions` | `RealAgenticApiService.createSession()` | `real_agentic_api_service.dart` |
| 2 | **Update Session** | `PATCH /sessions/{id}` | `RealAgenticApiService.updateSession()` | `real_agentic_api_service.dart` |
| 3 | **Interact** | `POST /sessions/{id}/interact` | `RealAgenticApiService.interact()` | `real_agentic_api_service.dart` |
| 4 | **Orchestrator Step** | `POST /orchestrator/step` | `RealAgenticApiService.orchestratorStep()` | `real_agentic_api_service.dart` |
| 5 | **Get Belief State** | `GET /inspection/belief-state/{id}` | `RealAgenticApiService.getBeliefState()` | `real_agentic_api_service.dart` |
| 6 | **Get Particle State** | `GET /inspection/particle-state/{id}` | `RealAgenticApiService.getParticleState()` | `real_agentic_api_service.dart` |
| 7 | **Get Q-Values** | `GET /inspection/q-values` | `RealAgenticApiService.getQValues()` | `real_agentic_api_service.dart` |
| 8 | **Get Audit Logs** | `GET /inspection/audit-logs/{id}` | `RealAgenticApiService.getAuditLogs()` | `real_agentic_api_service.dart` |
| 9 | **Get Leaderboard** | `GET /leaderboard` | `RealLeaderboardRepository.getLeaderboard()` | `real_leaderboard_repository.dart` |
| 10 | **Get My Rank** | `GET /leaderboard/me` | `RealLeaderboardRepository.getMyRank()` | `real_leaderboard_repository.dart` |
| 11 | **Get Badges** | `GET /badges` | `RealLeaderboardRepository.getAllBadges()` | `real_leaderboard_repository.dart` |
| 12 | **Add XP** | `POST /xp/add` | `RealLeaderboardRepository.addXp()` | `real_leaderboard_repository.dart` |
| 13 | **Get Lives** | `GET /lives` | `RealLivesRepository.getLives()` | `real_lives_repository.dart` |
| 14 | **Consume Life** | `POST /lives/lose` | `RealLivesRepository.loseLife()` | `real_lives_repository.dart` |
| 15 | **Regenerate Life** | `POST /lives/regen` | `RealLivesRepository.restoreLife()` | `real_lives_repository.dart` |
| 16 | **Get Formulas** | `GET /formulas` | `RealFormulaRepository.getAllCategories()` | `real_formula_repository.dart` |
| 17 | **Get Onboarding Questions** | `GET /onboarding/questions` | `RealOnboardingRepository.getDiagnosticQuestions()` | `real_onboarding_repository.dart` |
| 18 | **Submit Onboarding** | `POST /onboarding/submit` | `RealOnboardingRepository.submitOnboarding()` | `real_onboarding_repository.dart` |
| 19 | **Get Next Question** | `GET /quiz/next` | `QuizApiRepository.getNextQuestion()` | `quiz_api_repository.dart` |
| 20 | **Submit Quiz Answer** | `POST /quiz/submit` | `QuizApiRepository.submitAnswer()` | `quiz_api_repository.dart` |
| 21 | **Get Pending Session** | `GET /sessions/pending` | `SessionRecoveryRepository.getPendingSession()` | `session_recovery_repository.dart` |

### ✅ WebSocket Implementations

| # | WebSocket | Frontend Implementation | File |
|---|---|---|---|
| 1 | **Behavior Telemetry** `/ws/v1/behavior/{id}` | `AgenticWsService.connectBehavior()` | `ws_service.dart` |
| 2 | **Dashboard Stream** `/ws/v1/dashboard/stream/{id}` | `AgenticWsService.connectDashboard()` | `ws_service.dart` |

### ❌ API Chưa có Frontend Implementation

| # | API Endpoint | Backend Path | Trạng thái | Ghi chú |
|---|---|---|---|---|
| 1 | **Health Check** | `GET /health` | ❌ Chưa dùng | Không cần thiết cho user-facing flow, nhưng cần cho health monitoring / connection check UI |
| 2 | **Get Quota** | `GET /quota` | ✅ Đã sửa | `QuotaRepository` đã migrate sang `RestApiClient` (có retry, auth, logging) |
| 3 | **Get Config** | `GET /configs/{category}` | ❌ Không có | Chưa có frontend repository nào gọi endpoint này |
| 4 | **Upload Config** | `POST /configs/{category}` | ❌ Không có | Admin-only, có thể bỏ qua cho MVP |
| 5 | **Get User Profile** | `GET /user/profile` | ⚠️ Dùng Supabase trực tiếp | `ProfileRepository` gọi Supabase table trực tiếp, **không gọi backend REST API** |
| 6 | **Update User Profile** | `PUT /user/profile` | ⚠️ Dùng Supabase trực tiếp | `ProfileRepository.updateProfile()` upsert trực tiếp Supabase, **không gọi backend** |
| 7 | **Session Recovery (alias)** | `GET /session/pending` | ⚠️ Trùng lặp | Duplicate endpoint, `SessionRecoveryRepository` đã gọi `/sessions/pending` |

### 🟡 API có implementation nhưng chưa kết nối vào UI flow

| # | Vấn đề | Chi tiết |
|---|---|---|
| 1 | `QuizApiRepository` chưa dùng trong `QuizBloc`/`QuizCubit` | Repository đã tạo nhưng `QuizPage` vẫn dùng `QuizRepository` (local Supabase + mock fallback). `QuizApiRepository` chỉ được register khi `useMockApi=false` nhưng chưa inject vào flow nào |
| 2 | `SessionRecoveryRepository` chưa gọi trong `ResumeBanner` | `ResumeBanner` widget trên `TodayPage` hardcode dismiss logic, không gọi `getPendingSession()` để check session thật |
| 3 | ~~`Add XP` chưa auto-trigger sau quiz~~ | ✅ ĐÃ XỬ LÝ: `quiz_page.dart` gọi `LeaderboardCubit.addXp(eventType: 'correct_answer')` khi isCorrect = true |
| 4 | Agentic backend disabled mặc định | `USE_AGENTIC_BACKEND=false` nên toàn bộ `AgenticSessionCubit`, `AiCompanionCubit`, WebSocket services đều không hoạt động |

---

## 3. Danh sách Mock Data cần thay thế

### 🔴 Nghiêm trọng – Core flow đang 100% mock

| # | Feature | Mock File/Location | Data giả | Ảnh hưởng |
|---|---|---|---|---|
| 1 | **Quiz Questions** | `quiz_repository.dart` L95-620 | 20 câu hỏi hardcoded (`mock_mc_*`, `mock_tf_*`, `mock_sa_*`) | Toàn bộ Quiz flow dùng local data thay vì `GET /quiz/next` |
| 2 | **Diagnosis Pipeline** | `mock_api_service.dart` (464 dòng) | `MockApiService` trả diagnosis cycle giả (autoCycle: success → hitl → recovery) | Orchestrator pipeline không bao giờ chạy thật |
| 3 | **Chat AI** | `chat_repository.dart` L12-95 | Responses hardcoded theo keyword matching | Chat không gọi backend LLM, chỉ trả text cố định |
| 4 | **Leaderboard** | `mock_leaderboard_repository.dart` L9-190 | 20 users giả lập + 10 badge definitions | Khi `useMockApi=true`, leaderboard hiển thị data cố định |
| 5 | **Lives** | `mock_lives_repository.dart` | 3 tim, regen 8 giây (thay vì 8 giờ) | Timer hồi sinh sai hoàn toàn so với production |

### 🟡 Đáng chú ý – Dữ liệu bổ trợ mock

| # | Feature | Mock File/Location | Data giả |
|---|---|---|---|
| 6 | **Streak Counter** | `today_page.dart` L78-88 | SharedPreferences counter tự tăng, không từ API XP/streak data |
| 7 | **Progress/Mastery Map** | `mock_user_progress_generator.dart` L73-98 | 5 topics hardcoded (Đạo hàm, Giới hạn, Tích phân...) với score cố định |
| 8 | **Formula Handbook** | `mock_formula_data.dart` + `mock_formula_repository.dart` | Formulas hardcoded, không load từ `GET /formulas` |
| 9 | **Onboarding Questions** | `mock_onboarding_data.dart` + `mock_onboarding_repository.dart` | Questions local, không từ `GET /onboarding/questions` |
| 10 | **Study Goals** | `real_onboarding_repository.dart` L42-57 | Hardcoded 2 goals (exam_prep, explore) vì backend không có endpoint riêng |
| 11 | **Profile UID fallback** | `profile_cubit.dart` L194-195 | Fallback `return 'mock-user'` khi Supabase chưa login |
| 12 | **Notification** | `notification_repository.dart` | Mock local notifications, không có backend push notification |
| 13 | **Spaced Repetition** | `spaced_repetition_repository.dart` | 100% local implementation |
| 14 | **Study Schedule** | `study_schedule_repository.dart` | 100% local, Google Calendar service là skeleton |
| 15 | **Session History** | `session_history_repository.dart` | 100% local SharedPreferences/SecureStorage |
| 16 | **Offline Mode** | `offline_mode_repository.dart` | Queued signals pattern sẵn sàng nhưng dependent vào mock `submitSignals()` |

---

## 4. Vấn đề UI/UX chưa hợp lí

### 🔴 Nghiêm trọng

| # | Trang | Vấn đề | Mô tả |
|---|---|---|---|
| 1 | **TodayPage** | Streak popup sai data | Streak tự tăng mỗi ngày mở app (L79), không phản ánh hoạt động học thật sự. XP bonus = `streakDays * 10` là giả |
| 2 | **QuizPage** | Không có loading trước khi fetch question | Quiz load question từ local repo nên instant, nhưng khi chuyển sang backend API sẽ cần loading state giữa các câu |
| 3 | **ChatPage** | Voice input placeholder | `VoiceInputButton` chỉ hiển thị placeholder, không hoạt động (L8, L42: `TODO: Wire up speech_to_text`) |
| 4 | **ModeSelectionPage** | Exam Prep mode nhưng Lives chưa sync | User chọn Exam Prep nhưng lives indicator dùng mock data (8 giây regen thay vì 8 giờ) |
| 5 | **ResumeBanner** | Không check backend pending session | Banner hiển thị cố định, không gọi `GET /sessions/pending` để check xem có session dang dở không |
| 6 | **CreateRoomPage** | Multiplayer stub | `TODO: WebSocket join room` (L78), trang chỉ là skeleton |

### 🟡 Cần cải thiện

| # | Trang | Vấn đề | Mô tả |
|---|---|---|---|
| 7 | **ProgressPage** | Mastery data hardcoded | `MockUserProgressGenerator.fromUserProfile()` trả data cố định, không phản ánh belief state thật từ `GET /inspection/belief-state` |
| 8 | **ProfileScreen** | `subscriptionTier` always = 'free' | Code L233 hardcode `_subscriptionTier = 'free'` khi hydrate, bỏ qua giá trị từ profile |
| 9 | **ExplanationPage** | MANIM video placeholder | L98 comment `// MANIM video placeholder` - placeholder chưa có nội dung |
| 10 | **LeaderboardPage** | Không có pull-to-refresh | Leaderboard load 1 lần, user không thể refresh thủ công |
| 11 | ~~**QuotaRepository**~~ | ✅ ĐÃ SỬA | `QuotaRepository` đã dùng `RestApiClient` chung |

---

## 5. Vấn đề đồng bộ UI/UX

### 🔴 Không nhất quán giữa các trang

| # | Vấn đề | Trang A | Trang B | Mô tả |
|---|---|---|---|---|
| 1 | **Profile model mismatch** | Backend API (`GET /user/profile`) | Frontend `UserProfile` model | Backend trả `display_name, study_goal, daily_minutes, user_level, onboarded_at`. Frontend model dùng `full_name, grade_level, active_subjects, learning_preferences, recovery_mode_enabled, consent_*` — **hai schema khác nhau** |
| 2 | **Dual profile access** | `ProfileRepository` gọi Supabase `profiles` table trực tiếp | Backend `GET /user/profile` endpoint | Cùng data nhưng 2 đường access, có thể gây ra race condition hoặc stale data |
| 3 | **Streak data không nhất quán** | `TodayPage` dùng `SharedPreferences.streak_days` | `LeaderboardEntry` có `currentStreak` từ API | 2 nguồn streak khác nhau, hiển thị khác nhau giữa TodayPage vs LeaderboardPage |
| 4 | **XP không đồng bộ** | `TodayPage.StreakPopup` hiển thị `xpBonus = streak * 10` | `LeaderboardEntry.weeklyXp` từ API | XP streak bonus tính local, không sync với backend `POST /xp/add` |
| 5 | **Lives regen timer** | MockLivesRepository: 8 giây regen | Backend API: 8+ giờ regen | Timer hoàn toàn sai, dẫn đến kỳ vọng user sai khi chuyển sang production |
| 6 | **Quiz answer flow** | `QuizRepository` → `ApiService.submitAnswer()` (legacy mock) | `QuizApiRepository` → `RestApiClient POST /quiz/submit` | 2 quiz submission paths tồn tại song song, `QuizBloc` chỉ dùng cái cũ |
| 7 | **Navigation guard không check onboarding từ backend** | `AppRouter` check `SharedPreferences.isOnboarded_*` | Backend endpoint `POST /onboarding/submit` sets `onboarded_at` | Frontend lưu onboarded flag local, backend lưu riêng → un-sync nếu user đổi device |

### 🟡 Style / Pattern không nhất quán

| # | Vấn đề | Chi tiết |
|---|---|---|
| 8 | **Error state handling** | `TodayPage` và `ProgressPage` mỗi trang tự định nghĩa `_ErrorStateWidget` riêng, style/layout khác nhau thay vì dùng shared widget |
| 9 | **Loading state handling** | `TodayPage` dùng shimmer skeletons, `ProgressPage` dùng `CircularProgressIndicator` đơn giản — không nhất quán |
| 10 | **i18n approach** | Đa số dùng `context.t(vi:, en:)`, nhưng `ProfileScreen` dùng `AppStrings.of(context).pick(vi:, en:)` — 2 API khác nhau cho cùng mục đích |
| 11 | **Bottom navigation** | `GrowMateBottomNavBar` hiển thị trên tất cả main pages nhưng `QuizPage` không có → user stuck nếu muốn navigate back mà không hoàn thành quiz |

---

## 6. Kế hoạch hành động (Action Plan)

### Phase 1: Critical – Kết nối Backend API (Sprint 1, ~3-5 ngày)

#### 1.1 Bật feature flag flow
- [ ] Thay đổi default `USE_MOCK_API` thành `false` khi backend sẵn sàng
- [ ] Thay đổi default `USE_AGENTIC_BACKEND` thành `true` khi backend sẵn sàng
- [ ] Test toggle qua `.env` hoặc `--dart-define`

#### 1.2 Quiz flow chuyển sang backend API
- [ ] Integrate `QuizApiRepository.getNextQuestion()` vào `QuizBloc`/`QuizCubit` thay cho local `QuizRepository`
- [ ] Integrate `QuizApiRepository.submitAnswer()` thay cho `ApiService.submitAnswer()`
- [ ] Thêm `X-Quiz-Signature` header cho quiz submit (HMAC validation)
- [ ] Handle `429 Too Many Requests` khi vượt daily session limit

#### 1.3 Session management
- [ ] Integrate `ResumeBanner` gọi `SessionRecoveryRepository.getPendingSession()` để check session thật
- [ ] Thêm `POST /sessions` (create session) trước khi bắt đầu quiz flow mới
- [ ] Thêm `PATCH /sessions/{id}` (update status = completed/abandoned) khi kết thúc/thoát quiz

#### 1.4 Profile sync
- [ ] Quyết định: giữ Supabase direct access hay chuyển sang backend `GET/PUT /user/profile`
- [ ] Nếu chuyển: tạo `RealProfileRepository` dùng `RestApiClient`
- [ ] Sync onboarding flag từ backend `onboarded_at` thay vì chỉ dùng `SharedPreferences`

#### 1.5 XP & Streak sync
- [x] Gọi `POST /xp/add` khi user trả lời đúng quiz — `addXp(eventType: 'correct_answer')` trong `quiz_page.dart`
- [ ] Lấy streak data từ `GET /leaderboard/me` thay vì SharedPreferences
- [ ] Gỡ bỏ mock streak counter trong `TodayPage._checkDailyStreak()`

---

### Phase 2: Important – Gỡ Mock Data (Sprint 2, ~3 ngày)

#### 2.1 Gỡ Mock Services
- [ ] Khi `useMockApi=false`: verify `MockApiService` không còn được dùng ở bất kỳ đâu
- [ ] Verify `SupabaseHybridApiService` fallback chain hoạt động đúng

#### 2.2 Chat AI
- [ ] Tạo `RealChatRepository` gọi backend LLM endpoint (hoặc integrate vào orchestrator interact flow)
- [ ] Hoặc: integrate Supabase Edge Functions cho chat

#### 2.3 Progress / Mastery
- [ ] Tạo repo lấy belief state thật từ `GET /inspection/belief-state/{sessionId}` để hiển thị mastery map
- [ ] Thay thế `MockUserProgressGenerator` bằng data thật

#### 2.4 Notification
- [ ] Evaluate: cần backend push notification endpoint hay giữ local notification
- [ ] Nếu cần: integrate Supabase Realtime hoặc FCM

---

### Phase 3: Polish – UI/UX Consistency (Sprint 3, ~2 ngày)

#### 3.1 Shared widgets
- [ ] Tạo shared `GrowMateErrorWidget` thay vì mỗi page tự định nghĩa
- [ ] Tạo shared `GrowMateLoadingWidget` với shimmer skeleton consistent
- [ ] Thống nhất i18n approach: dùng `context.t()` everywhere, deprecate `AppStrings.pick()`

#### 3.2 UI fixes
- [ ] Fix `ProfileScreen._subscriptionTier` hardcode = 'free' → lấy từ profile data
- [ ] Thêm pull-to-refresh cho `LeaderboardPage`
- [ ] Gỡ/disable `VoiceInputButton` hoặc implement speech-to-text
- [ ] Gỡ `CreateRoomPage` multiplayer stub hoặc tag "Coming Soon"
- [ ] Gỡ `ExplanationPage` MANIM placeholder hoặc tag "Coming Soon"

#### 3.3 QuotaRepository refactor
- [x] Chuyển `QuotaRepository` sang dùng `RestApiClient` chung (có retry, auth, logging)

#### 3.4 Navigation
- [ ] Thêm back/exit option cho `QuizPage` (confirm dialog trước khi abandon session)
- [ ] Đồng bộ onboarding guard: check `onboarded_at` từ backend profile thay vì chỉ SharedPreferences

---

### Phase 4: FE↔BE Contract Fixes (HOÀN THÀNH — 16/04/2026)

> Tất cả 9 fixes đã được implement và `flutter analyze` cho kết quả 0 issues.

| # | Fix | File(s) | Trạng thái |
|---|---|---|---|
| 1 | `LeaderboardEntry.fromJson` — safe nullable casts; thay `recentBadges` bằng `badgeCount` + `longestStreak` | `leaderboard_entry.dart`, `mock_leaderboard_repository.dart` | ✅ |
| 2 | `addXp` interface mở rộng từ `(int points)` thành `({eventType, extraData})` — khớp backend `correct_answer`/`daily_login`/etc. | `leaderboard_repository.dart`, `real_*`, `mock_*`, `leaderboard_cubit.dart`, `quiz_page.dart` | ✅ |
| 3 | `QuizNextQuestion.fromJson` — extract `o['text']` từ Map options; đọc field `question_type` thay vì `type` | `quiz_api_models.dart` | ✅ |
| 4 | `QuizNextResponse.fromJson` — đọc `session_id` từ `next_question` sub-object (không phải top level) | `quiz_api_models.dart` | ✅ |
| 5 | `createSession` thêm `mode`, `classificationLevel`, `onboardingResults` params | `agentic_api_service.dart`, `real_agentic_api_service.dart`, `agentic_session_repository.dart` | ✅ |
| 6 | `interact` thêm `mode`, `classificationLevel` params | `agentic_api_service.dart`, `real_agentic_api_service.dart` | ✅ |
| 7 | HMAC signing cho `/sessions/{id}/interact` trong `RealAgenticApiService` | `real_agentic_api_service.dart` | ✅ |
| 8 | `QuotaRepository` migrate sang `RestApiClient` (retry + auth tự động) | `quota_repository.dart` | ✅ |
| 9 | Quiz cubit: thêm `QuizNoLivesState`, xử lý `ForbiddenException` (403), truyền `livesRemaining`/`canPlay`/`nextRegenInSeconds` vào `QuizSubmitSuccessState` | `quiz_cubit.dart` | ✅ |

---

### Phase 5: Nice-to-have (Backlog)

- [ ] Health check endpoint integration (network indicator thông minh hơn)
- [ ] Config endpoint integration (remote feature flags)
- [ ] Google Calendar integration cho Smart Schedule
- [ ] Multiplayer WebSocket rooms
- [ ] Speech-to-text cho Chat voice input
- [ ] MANIM animation videos cho Explanation

---

## Appendix: File Reference Map

### API Service Layer
```
lib/core/network/
├── api_service.dart              # Legacy ApiService interface (diagnosis/quiz mock)
├── agentic_api_service.dart      # Agentic backend interface (session/orchestrator)
├── api_config.dart               # Base URLs, timeouts, retry config
├── mock_api_service.dart         # 🔴 464-line mock diagnosis pipeline
├── rest_api_client.dart          # Shared REST client with auth/retry
└── ws_service.dart               # WebSocket service (behavior + dashboard)

lib/core/services/
├── real_api_service.dart         # Real REST ApiService (legacy endpoints)
├── real_agentic_api_service.dart # Real REST for agentic backend
└── supabase_hybrid_api_service.dart # Supabase RPC + mock fallback hybrid
```

### Feature Repositories (Mock → Real pairs)
```
features/leaderboard/data/repositories/
├── leaderboard_repository.dart        # Interface
├── mock_leaderboard_repository.dart   # 🔴 320 lines mock
└── real_leaderboard_repository.dart   # ✅ Real REST

features/quiz/data/repositories/
├── lives_repository.dart              # Interface
├── mock_lives_repository.dart         # 🔴 Mock (8s regen!)
├── real_lives_repository.dart         # ✅ Real REST
├── quiz_repository.dart               # 🔴 800+ lines local/mock questions
└── quiz_api_repository.dart           # ✅ Real REST (unused in flow!)

features/onboarding/data/repositories/
├── onboarding_repository.dart         # Interface
├── mock_onboarding_repository.dart    # 🔴 Mock questions
└── real_onboarding_repository.dart    # ✅ Real REST

features/progress/data/repositories/
├── formula_repository.dart            # Interface
├── mock_formula_repository.dart       # 🔴 Mock formulas
└── real_formula_repository.dart       # ✅ Real REST
```

### Gating Logic
```
lib/main.dart L64-86:
  USE_MOCK_API = 'true'           ← Controls ApiService + feature repos
  USE_SUPABASE_RPC_DATA_PLANE = 'true'  ← Controls Supabase hybrid
  USE_AGENTIC_BACKEND = 'false'   ← Controls agentic session/WS
```
