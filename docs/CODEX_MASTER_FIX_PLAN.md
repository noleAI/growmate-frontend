# GrowMate — Master Fix Plan for Codex GPT-5.4 (Extra High)

> **Mục tiêu**: Sửa toàn bộ bug backend XP/Leaderboard, tích hợp đầy đủ API còn thiếu, và cải thiện UI/UX cho demo Hackathon.
> **Ngày tạo**: 2026-04-19

---

## MỤC LỤC
1. [BUG #1: Leaderboard trống — RLS + access_token](#1-bug-1-leaderboard-trống)
2. [BUG #2: Frontend XP daily_login guard](#2-bug-2-frontend-xp-daily_login-guard)
3. [API chưa tích hợp vào Frontend](#3-api-chưa-tích-hợp-vào-frontend)
4. [Mock Data Status](#4-mock-data-status)
5. [Logic & UX Issues](#5-logic--ux-issues)
6. [UI/UX Improvements cho Hackathon](#6-uiux-improvements-cho-hackathon)
7. [Checklist Thực Thi](#7-checklist-thực-thi)

---

## 1. BUG #1: Leaderboard trống

### Confirmed Root Cause (2 lớp)

**Lớp 1 — Backend không truyền `access_token`**:

File `backend/api/routes/leaderboard.py` dòng 162-220. Endpoint `GET /leaderboard` gọi 4 Supabase functions mà KHÔNG truyền `access_token`:
- `list_user_xp_rows()` (dòng 172)
- `count_user_xp_rows()` (dòng 176)
- `list_user_badges()` (dòng 185)
- `list_user_profiles_by_ids()` (dòng 194)

Khi không có `access_token`, `get_supabase_client(None)` dùng anon key singleton → Supabase coi request là anonymous → RLS chặn.

**Lớp 2 — RLS policies chỉ cho phép đọc row của chính mình**:

Đã xác nhận từ Supabase Dashboard:

| Table | Policy | Cmd | Effect |
|-------|--------|-----|--------|
| `user_xp` | `user_xp_select_own` | SELECT | `auth.uid() = user_id` — chỉ thấy XP của mình |
| `user_badges` | `user_badges_select_own` | SELECT | `auth.uid() = user_id` — chỉ thấy badge của mình |
| `user_profiles` | `user_profiles_select_own` | SELECT | `auth.uid() = user_id` — chỉ thấy profile của mình |

**Kết quả**: Kể cả có fix access_token, mỗi user vẫn chỉ thấy 1 row (của chính mình) → leaderboard chỉ hiện 1 người hoặc rỗng.

### Fix Part A — Supabase RLS Migration

Chạy SQL sau trong Supabase SQL Editor:

```sql
-- ========================================
-- LEADERBOARD RLS FIX — Cho phép authenticated users đọc cross-user data
-- ========================================

-- 1. user_xp: Cho phép tất cả authenticated users đọc tất cả XP rows
CREATE POLICY "leaderboard_read_all_xp"
ON public.user_xp
FOR SELECT
TO authenticated
USING (true);

-- 2. user_badges: Cho phép tất cả authenticated users đọc tất cả badges
CREATE POLICY "leaderboard_read_all_badges"
ON public.user_badges
FOR SELECT
TO authenticated
USING (true);

-- 3. user_profiles: Cho phép tất cả authenticated users đọc display_name & avatar
CREATE POLICY "leaderboard_read_all_profiles"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (true);
```

> **LƯU Ý BẢO MẬT**: Cho MVP/Hackathon chấp nhận được vì các bảng chỉ chứa public info.
> Cho production, có thể tạo view chỉ expose cột cần thiết.

### Fix Part B — Backend Code

File: `backend/api/routes/leaderboard.py` dòng 162-220

Thêm `access_token=access_token` vào 4 function calls:

```diff
     rows = await list_user_xp_rows(
         period=normalized_period,
         limit=limit,
+        access_token=access_token,
     )
-    total_players = await count_user_xp_rows()
+    total_players = await count_user_xp_rows(access_token=access_token)

     badge_lists = await asyncio.gather(
         *[
             list_user_badges(
                 user_id=str(row.get("user_id", "")),
+                access_token=access_token,
             )
             for row in rows
         ]
     )

     user_ids = [str(row.get("user_id", "")).strip() for row in rows]
     try:
         profiles_by_id = await list_user_profiles_by_ids(
             user_ids=user_ids,
+            access_token=access_token,
         )
     except Exception:
         profiles_by_id = {}
```

---

## 2. BUG #2: Frontend XP daily_login guard

File: `lib/features/today/presentation/pages/today_page.dart` dòng 77-137

**Vấn đề**: `_checkDailyStreak()` gọi `repo.addXp(eventType: 'daily_login')` mỗi khi `TodayPage` initState. Guard `SharedPreferences('streak_popup_date')` chỉ set SAU khi API call thành công (dòng 126). Nếu app crash trước → lần sau gọi lại.

Backend cũng có guard (`last_active_date == today` → return `xp_added: 0`), nhưng frontend nên guard trước để tránh unnecessary API calls.

```diff
   if (lastShown == today) return;

+  // Optimistic guard: set flag BEFORE API call to prevent duplicate calls
+  await prefs.setString('streak_popup_date', today);
+
   int streakDays = 1;
   int xpBonus = 10;
   var shouldShowPopup = false;
   try {
     final repo = context.read<LeaderboardRepository>();
     final response = await repo.addXp(eventType: 'daily_login');
     streakDays = response.currentStreak;
     xpBonus = response.xpAdded;
     shouldShowPopup = xpBonus > 0 && streakDays > 0;
   } catch (_) {
     // ...fallback logic stays the same...
   }
-  await prefs.setString('streak_popup_date', today);
   if (!mounted || !shouldShowPopup) return;
   // ...popup logic stays the same...
```

---

## 3. API chưa tích hợp vào Frontend

### 3A. Inspection APIs — không có UI hiển thị data thực

Backend endpoints (tất cả authenticated):
- `GET /api/v1/inspection/belief-state/{session_id}` → Bayesian beliefs
- `GET /api/v1/inspection/particle-state/{session_id}` → Particle filter
- `GET /api/v1/inspection/q-values` → Q-Learning table
- `GET /api/v1/inspection/audit-logs/{session_id}` → Audit trail
- `GET /api/v1/inspection/runtime-metrics` → System metrics
- `GET /api/v1/inspection/runtime-alerts` → Alert evaluation

Frontend hiện tại: `InspectionCubit` và `InspectionBottomSheet` chỉ show dev mode toggle. Không hiển thị data thực.

**Cần**: Expand `InspectionBottomSheet` hoặc tạo `InspectionDashboardPage` với:
- Belief state bar chart (hypotheses H01-H04)
- Particle distribution radar/pie chart (focused/confused/exhausted/frustrated)
- Q-values table
- Runtime metrics cards

### 3B. WebSocket Dashboard Stream (`/ws/v1/dashboard/stream`)

Backend: WebSocket stream phát real-time AI orchestrator state.
Frontend: `AgenticWsService` chỉ kết nối `/ws/v1/behavior/{session_id}`, KHÔNG kết nối dashboard stream.

**Cần**: Thêm dashboard stream + `AgenticPipelineViewer` widget (xem mục 6A).

### 3C. Orchestrator Step (`POST /api/v1/orchestrator/step`)

Backend: Endpoint chạy 1 bước orchestrator decision.
Frontend: Chỉ dùng `POST /sessions/{id}/interact`. Cần tích hợp cho Agentic demo.

### 3D. Quiz Completion XP Events

Backend hỗ trợ: `correct_answer`, `daily_login`, `complete_quiz`, `perfect_score`.
Frontend chỉ gọi: `correct_answer` (quiz_page.dart ~dòng 2523) và `daily_login` (today_page.dart dòng 95).

**Thiếu**: `complete_quiz` khi quiz kết thúc, `perfect_score` khi accuracy == 100%.

```dart
// Thêm vào quiz completion handler:
await context.read<LeaderboardCubit>().addXp(eventType: 'complete_quiz');
if (accuracy == 1.0) {
  await context.read<LeaderboardCubit>().addXp(eventType: 'perfect_score');
}
```

### 3E. Weekly XP Reset

Backend `_apply_leaderboard_order()` sort theo `weekly_xp`. Nhưng KHÔNG có cron/trigger reset `weekly_xp` về 0 mỗi tuần. Cần Supabase Edge Function hoặc pg_cron.

---

## 4. Mock Data Status

`.env` hiện tại: `USE_MOCK_API=false` → production mode → tất cả mock repos KHÔNG dùng.

Mock files vẫn tồn tại nhưng chỉ activate khi `useMockApi=true` (main.dart dòng 361-366). Không cần xóa.

---

## 5. Logic & UX Issues

### 5A. Leaderboard Empty State

Khi entries rỗng, chỉ hiện text "Chưa có dữ liệu". Cần card + CTA → Quiz page.

### 5B. Session Complete/Abandon Lifecycle

Verify quiz_page.dart gọi `PATCH /sessions/{id}` với `status: "completed"` khi xong.

---

## 6. UI/UX Improvements cho Hackathon

### 6A. Agentic AI Pipeline Visualization (ĐIỂM NHẤN CHO BGK)

File mới: `lib/features/agentic_session/presentation/widgets/agentic_pipeline_viewer.dart`

```
┌─────────────────────────────────────────┐
│ 🧠 AI đang phân tích...                │
├─────────────────────────────────────────┤
│ ✅ Step 1: Academic Agent               │
│    Bayesian belief: H01=0.7 H02=0.2    │
│ ✅ Step 2: Empathy Agent                │
│    Particle: focused=70% confused=15%   │
│ 🔄 Step 3: Strategy Agent              │
│    Q-Learning → "review_theory" (0.82) │
│ ⏳ Step 4: Decision Engine             │
│    Aggregating results...               │
└─────────────────────────────────────────┘
```

- Staggered fade-in animation
- Confidence color coding (xanh > 0.7, vàng 0.4-0.7, đỏ < 0.4)
- i18n: `context.t(vi: '...', en: '...')`

### 6B. Quiz Result XP Breakdown + Badge Animation

### 6C. Chat AI Typing Indicator

---

## 7. Checklist Thực Thi

### P0 — Critical Bugs (sửa ngay)
- [ ] **Supabase SQL**: Chạy 3 `CREATE POLICY` (mục 1A)
- [ ] **Backend** `leaderboard.py`: Thêm `access_token` vào 4 calls (mục 1B)
- [ ] **Frontend** `today_page.dart`: Fix daily_login guard (mục 2)

### P1 — Missing XP Events
- [ ] `quiz_page.dart`: Thêm `addXp('complete_quiz')`
- [ ] `quiz_page.dart`: Thêm `addXp('perfect_score')`

### P2 — Agentic Visualization (Hackathon wow-factor)
- [ ] Tạo `AgenticPipelineViewer` widget
- [ ] Kết nối WebSocket `/ws/v1/dashboard/stream`
- [ ] Expand `InspectionBottomSheet` với real inspection data

### P3 — UX Polish
- [ ] Leaderboard empty state + CTA
- [ ] Quiz result XP breakdown popup
- [ ] Weekly XP reset cron job

---

## Files Summary

### Backend
| File | Dòng | Action |
|------|------|--------|
| `backend/api/routes/leaderboard.py` | 172, 176, 185, 194 | Thêm `access_token=access_token` |

### Frontend
| File | Action |
|------|--------|
| `today_page.dart` | Fix daily_login guard (dòng 86-126) |
| `quiz_page.dart` | Thêm complete_quiz + perfect_score XP events |
| `leaderboard_page.dart` | Empty state card + CTA |
| `ws_service.dart` | Thêm dashboard stream |
| **[NEW]** `agentic_pipeline_viewer.dart` | AI pipeline viewer widget |

### Supabase SQL
| Statement | Table |
|-----------|-------|
| `CREATE POLICY "leaderboard_read_all_xp"` | `user_xp` |
| `CREATE POLICY "leaderboard_read_all_badges"` | `user_badges` |
| `CREATE POLICY "leaderboard_read_all_profiles"` | `user_profiles` |

---

## Ghi Chú Cho Codex

1. Repo backend: `growmate_backend/backend/` — Python, FastAPI
2. Repo frontend: `growmate_frontend/lib/` — Flutter/Dart
3. `.env` frontend: `USE_MOCK_API=false`
4. Backend: `https://growmate-backend-716335368825.europe-west1.run.app`
5. Supabase: `iqbmzsmebpqnrqxbsone.supabase.co`
6. KHÔNG thay đổi cấu trúc thư mục hoặc rename file có sẵn
7. Giữ nguyên comment/docstring hiện có
8. Dùng `context.t(vi: '...', en: '...')` cho text mới
9. Design system: `GrowMateColors`, `GrowMateLayout`, `ZenCard`, `ZenButton`
