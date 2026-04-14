# Plan Cá Nhân — Huy (Frontend Developer)

> Trích từ TEAM_TASK_PLAN.md — Cập nhật 15/04/2026
> Vai trò: **Frontend (UI/UX + Logic)** — Flutter screens, animations, BLoC/Cubit, repositories, API integration

---

## TỔNG QUAN NHIỆM VỤ

| Phase | Tuần | Mục | Mô tả | Độ phức tạp |
|-------|------|-----|--------|-------------|
| **P0** | 1-2 | 1 | Cập nhật Roadmap/Today/Quiz models cho 1 chủ đề | ⭐⭐ |
| **P0** | 1-2 | 3c-3e | Quota indicator, giới hạn input, xử lý hết quota | ⭐⭐ |
| **P1** | 3-4 | 4d+5 | LeaderboardPage + XP + Badges | ⭐⭐⭐⭐ |
| **P1** | 3-4 | 7b | Hệ thống Tim (Lives) + animations | ⭐⭐⭐ |
| **P1** | 3-4 | 11 | Sổ tay công thức + LaTeX + offline | ⭐⭐⭐ |
| **P2** | 5-6 | 3a | OnboardingPage 4 bước + classification | ⭐⭐⭐⭐ |
| **P2** | 5-6 | 4c | Spam/AFK/Resume dialogs | ⭐⭐⭐ |
| **P2** | 5-6 | 6 | Chống leak (FLAG_SECURE, disable select) | ⭐⭐ |
| **P2** | 5-6 | 7a | Mode selection (Luyện thi / Trải nghiệm) | ⭐⭐ |
| **P3** | 7-8 | 3b | ChatVoice (Speech-to-Text) | ⭐⭐⭐ |
| **P3** | 7-8 | 5b | Multiplayer Quiz (Kahoot-style) | ⭐⭐⭐⭐⭐ |
| **P3** | 7-8 | 8b | Linh vật (4 Mascots + animations) | ⭐⭐⭐⭐ |
| **P3** | 7-8 | 9 | LaTeX + MANIM video + Error chain UI | ⭐⭐⭐ |
| **P3** | 7-8 | 10 | Google Calendar integration | ⭐⭐⭐ |

---

## PHASE 1 — P0: Nền Tảng (Tuần 1-2)

### ✅ Mục 1: Thu Hẹp Scope — Frontend

**Files cần sửa:**
- `lib/features/roadmap/presentation/pages/thpt_roadmap_page.dart`
- `lib/features/today/presentation/pages/today_page.dart`
- `lib/features/quiz/domain/entities/quiz_question_template.dart`
- `lib/core/network/mock_api_service.dart`

**Tasks:**
- [x] **1.1** Thêm `hypothesisTag` vào `QuizQuestionTemplate` model — mapping câu hỏi → 1 trong 4 hypotheses (H01-H04)
- [x] **1.2** Cập nhật Roadmap UI — focus chỉ hiện "Đạo hàm cơ bản" với 4 sub-topics (Lượng giác, Mũ & Log, Chain Rule, Quy tắc tính)
- [x] **1.3** Redesign Today page — hero section hiện chủ đề duy nhất + progress bar tổng
- [x] **1.4** Cập nhật mock API data cho 4 hypotheses mới (21 câu: 12 MC + 3 TF + 6 SA, mỗi hypothesis đều có)

**Dependency**: Chờ Khang finalize 4 hypothesis IDs + Hưng import data vào Supabase

---

### ✅ Mục 3c-3e: Quota & Token Management — Frontend

**Files cần tạo/sửa:**
- `lib/features/chat/` (tạo mới nếu chưa có)
- `lib/features/chat/data/repositories/quota_repository.dart` (NEW)
- `lib/features/chat/presentation/cubit/quota_cubit.dart` (NEW)
- `lib/features/chat/presentation/widgets/quota_indicator.dart` (NEW)
- `lib/features/chat/presentation/widgets/quota_exceeded_dialog.dart` (NEW)

**Tasks:**
- [x] **3.1** Tạo `QuotaRepository` — gọi `GET /api/v1/quota`, trả về `{used, limit, remaining}`
- [x] **3.2** Tạo `QuotaCubit` — quản lý state quota, auto-refresh khi mở chat
- [x] **3.3** Tạo `QuotaIndicator` widget — badge nhỏ hiện số lượt còn lại (💬 15)
- [x] **3.4** Thêm `maxLength: 300` vào chat TextField + character counter
- [x] **3.5** Tạo `QuotaExceededDialog` — popup thân thiện khi hết quota

**Dependency**: Chờ Hưng tạo table `user_token_usage` + API `/quota`

---

## PHASE 2 — P1: Gamification (Tuần 3-4)

### ✅ Mục 4d+5: Leaderboard + XP + Badges

**Files cần tạo:**
```
lib/features/leaderboard/
├── data/
│   ├── models/
│   │   ├── leaderboard_entry.dart
│   │   └── user_badge.dart
│   └── repositories/
│       └── leaderboard_repository.dart
└── presentation/
    ├── pages/
    │   └── leaderboard_page.dart
    ├── cubit/
    │   ├── leaderboard_cubit.dart
    │   └── leaderboard_state.dart
    └── widgets/
        ├── leaderboard_card.dart
        ├── top_three_podium.dart
        ├── my_rank_banner.dart
        └── period_tab_bar.dart
```

**Tasks:**
- [ ] **4.1** Tạo feature folder + models (`LeaderboardEntry`, `UserBadge`)
- [ ] **4.2** Tạo `LeaderboardRepository` — gọi API `/leaderboard`, `/badges`
- [ ] **4.3** Tạo `LeaderboardCubit` — state management + load/switch period
- [ ] **4.4** Build `LeaderboardPage` — top 3 podium + remaining list
- [ ] **4.5** Build `TopThreePodium` widget — 🥇🥈🥉 animation
- [ ] **4.6** Build `MyRankBanner` — highlight user hiện tại
- [ ] **4.7** Build `PeriodTabBar` — Tuần / Tháng / Tổng
- [ ] **4.8** Badge showcase grid — badges đã có + chưa unlock (greyed)
- [ ] **4.9** Toast notification khi đạt badge mới
- [ ] **4.10** Cập nhật BottomNavBar — thêm tab Leaderboard hoặc gắn vào Progress
- [ ] **4.11** Tích hợp XP vào quiz flow — sau submit → add XP → refresh
- [ ] **4.12** Push notification khi đạt badge

**Dependency**: Chờ Hưng tạo tables XP/badges + API endpoints

---

### ✅ Mục 7b: Hệ Thống Tim (Lives)

**Files cần tạo:**
```
lib/features/quiz/presentation/widgets/lives_indicator.dart       (NEW)
lib/features/quiz/presentation/widgets/out_of_lives_screen.dart   (NEW)
lib/features/quiz/presentation/cubit/lives_cubit.dart             (NEW)
lib/features/quiz/presentation/cubit/lives_state.dart             (NEW)
lib/features/quiz/data/repositories/lives_repository.dart         (NEW)
```

**Tasks:**
- [ ] **7.1** Tạo `LivesRepository` — gọi API `/lives`
- [ ] **7.2** Tạo `LivesCubit` — load lives, lose life, check canPlay
- [ ] **7.3** Build `LivesIndicator` widget — ❤️❤️❤️ animation
- [ ] **7.4** Build `OutOfLivesScreen` — countdown + nút xem bài sai + mời bạn
- [ ] **7.5** Animation mất tim (tim vỡ, rung nhẹ)
- [ ] **7.6** Guard quiz navigation — redirect nếu hết tim
- [ ] **7.7** Countdown timer stream đếm ngược hồi sinh

**Dependency**: Chờ Hưng tạo table `user_lives` + API `/lives`

---

### ✅ Mục 11: Sổ Tay Công Thức

**Files cần tạo:**
```
lib/features/progress/presentation/widgets/formula_handbook_tab.dart   (NEW)
lib/features/progress/presentation/widgets/formula_category_card.dart  (NEW)
lib/features/progress/presentation/widgets/formula_detail_card.dart    (NEW)
lib/features/progress/presentation/widgets/mastery_indicator.dart      (NEW)
lib/features/progress/presentation/cubit/formula_cubit.dart            (NEW)
lib/features/progress/data/repositories/formula_repository.dart        (NEW)
lib/features/progress/data/models/formula.dart                         (NEW)
```

**Tasks:**
- [ ] **11.1** Tạo `Formula` model + `FormulaCategory` model
- [ ] **11.2** Tạo `FormulaRepository` — gọi API `/formulas`, cache offline
- [ ] **11.3** Tạo `FormulaCubit` — load, filter, search formulas
- [ ] **11.4** Thêm tab "Sổ tay" vào ProgressPage
- [ ] **11.5** Build `FormulaCategoryCard` — card cho mỗi nhóm công thức
- [ ] **11.6** Build `FormulaDetailCard` — flutter_math_fork render LaTeX + ví dụ
- [ ] **11.7** Build `MasteryIndicator` — ✅ đã thuộc / 🔄 đang học / 🔒 chưa mở
- [ ] **11.8** Search bar tìm kiếm công thức nhanh
- [ ] **11.9** Offline storage cho formulas

**Dependency**: Chờ Hưng tạo `formula_handbook.json` + API `/formulas`

---

## PHASE 3 — P2: Nâng Cao (Tuần 5-6)

### ✅ Mục 3a: Onboarding Quiz

**Files cần tạo:**
```
lib/features/onboarding/
├── data/
│   └── repositories/
│       └── onboarding_repository.dart
└── presentation/
    ├── pages/
    │   ├── onboarding_welcome_page.dart
    │   ├── onboarding_goal_page.dart
    │   ├── onboarding_quiz_page.dart
    │   └── onboarding_result_page.dart
    ├── cubit/
    │   ├── onboarding_cubit.dart
    │   └── onboarding_state.dart
    └── widgets/
        ├── goal_selection_card.dart
        ├── level_result_animation.dart
        └── study_plan_preview.dart
```

**Tasks:**
- [ ] **OB.1** Tạo feature folder + `OnboardingRepository`
- [ ] **OB.2** Tạo `OnboardingCubit` — 4 bước state
- [ ] **OB.3** Build Welcome page — "Chào mừng! Mình tìm hiểu bạn nhé"
- [ ] **OB.4** Build Goal page — chọn Luyện thi / Trải nghiệm
- [ ] **OB.5** Build Quiz page — 10 câu chẩn đoán
- [ ] **OB.6** Build Result page — level reveal + plan preview
- [ ] **OB.7** Confetti/encouraging animation theo level
- [ ] **OB.8** Cập nhật `app_router.dart` — redirect first-time users
- [ ] **OB.9** Cache user level local

**Dependency**: Chờ Hưng soạn 10 câu + API onboarding, Khang tạo user classifier

---

### ✅ Mục 4c: Xử Lý User Bỏ Dở

**Tasks:**
- [ ] **4c.1** Spam warning dialog — "Chậm lại suy nghĩ kỹ nhé! 🤔"
- [ ] **4c.2** Resume banner trên TodayPage — session dở dang
- [ ] **4c.3** AFK overlay — mờ khi idle > 3 phút
- [ ] **4c.4** Session recovery flow — check `/session/pending` → resume banner
- [x] **4c.5** AFK timer client-side — `QuizSessionGuard` + `AfkOverlay` (3 phút idle → mờ + pause timer)
- [x] **4c.6** Spam detection client-side — `SpamWarningDialog` (answer time < 2s → cảnh báo)

---

### ✅ Mục 6: Chống Leak Nội Dung

**Tasks:**
- [x] **6.1** FLAG_SECURE trên Android — `MainActivity.kt` (đã thêm FLAG_SECURE)
- [x] **6.2** Disable text selection trên quiz content (SelectionContainer.disabled)
- [ ] **6.3** Xóa local cache đáp án — quiz data không chứa correct_answer
- [x] **6.4** Obfuscate quiz state — không log data ra console (đã kiểm tra: không có print/log nào)

---

### ✅ Mục 7a: Chia Chế Độ Học

**Tasks:**
- [x] **7a.1** Mode selection screen — 2 card lớn (🎓 Luyện thi / 🎮 Trải nghiệm) → `mode_selection_page.dart`
- [x] **7a.2** Mode state management — `StudyModeCubit` + `StudyModeRepository` (SharedPreferences)
- [ ] **7a.3** Conditional UI — timer hiện/ẩn, hint hiện/ẩn theo mode (cần wire vào quiz_page)

---

## PHASE 4 — P3: Premium Features (Tuần 7-8)

### Mục 3b: ChatVoice (STT)
- [ ] Thêm `speech_to_text` package
- [ ] Tạo `SpeechService`
- [ ] Mic button + long-press + animation pulse
- [ ] Permission handling
- [ ] Listening overlay + waveform

### Mục 5b: Multiplayer Quiz
- [ ] Multiplayer screens (create room, waiting, battle, results)
- [ ] WebSocket integration (real-time events)
- [ ] `MultiplayerCubit` state management
- [ ] Invite deep link

### Mục 8b: Linh Vật (Mascots)
- [ ] Design 4 mascot SVG/Lottie
- [ ] Mascot widget + animation theo context
- [ ] Mascot selection page
- [ ] `MascotCubit` + expression triggers

### Mục 9: LaTeX + MANIM
- [ ] LaTeX rendering toàn app (đã có `flutter_math_fork`)
- [ ] Video player cho MANIM clips
- [ ] Error chain tree/flow UI

### Mục 10: Google Calendar
- [ ] Thêm `google_sign_in`, `googleapis`
- [ ] Google OAuth flow + Calendar scope
- [ ] `CalendarService` — sync study plan
- [ ] Calendar sync toggle trong Settings

---

## THỨ TỰ ƯU TIÊN THỰC HIỆN

```
Tuần 1: [1.1] Quiz model → [1.2] Roadmap UI → [1.3] Today page → [3.1-3.5] Quota
Tuần 2: [1.4] Mock data → Polish P0 → Integration test
Tuần 3: [4.1-4.8] Leaderboard → [7.1-7.3] Lives indicator
Tuần 4: [4.9-4.12] Badge/XP → [7.4-7.7] Out-of-lives → [11.1-11.5] Formula tab
Tuần 5: [OB.1-OB.9] Onboarding 4 bước
Tuần 6: [4c.1-4c.6] Spam/AFK → [6.1-6.4] Anti-leak → [7a.1-7a.3] Mode
Tuần 7: STT + Multiplayer screens
Tuần 8: Mascots + MANIM + Calendar
```
