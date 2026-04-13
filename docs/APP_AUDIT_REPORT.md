# 🔍 App Audit Report - GrowMate Frontend

> Ngày kiểm tra: 2026-04-12
> Trạng thái: `flutter analyze` sạch, 23/23 tests pass

---

## 📊 TỔNG QUAN

| Metric | Giá trị |
|--------|--------|
| Total features | 18 |
| Complete features | 10 |
| Partial features | 6 |
| Missing presentation | 2 |
| Hardcoded colors | 224+ instances |
| Hardcoded strings (non-i18n) | 50+ instances |
| Orphaned files | 2 |
| Empty `.gitkeep` dirs | 38 |

---

## ✅ FEATURES HOÀN CHỈNH (Ready for MVP)

| Feature | Status | Notes |
|---------|--------|-------|
| **Auth** (login/register/forgot-password) | ✅ Full | Welcome, Login, Register, ForgotPassword + AuthBloc |
| **Today** (home dashboard) | ✅ Full | Main dashboard với stats, AI insights |
| **Quiz** | ✅ Functional | Bloc/Cubit, 3 question types, scoring engine |
| **Intervention** | ✅ Full | Page routed, feedback submission works |
| **Recovery** | ✅ Full | Recovery screen, sound service integration |
| **Session Complete** | ✅ Full | Summary, achievements, next steps |
| **Notifications** | ✅ Full | Streams, study reminders, deep-linking |
| **Schedule** | ✅ Full | CRUD, Google Calendar integration |
| **Roadmap** | ✅ Full | Static THPT roadmap content (1382 lines) |
| **Wellness/Mindful Break** | ✅ Full | Breathing exercise, programmable audio |
| **Privacy** (export/terms/policy) | ✅ Full | DataExportPage, PrivacyPolicyPage, TermsOfServicePage |

---

## ⚠️ FEATURES CHƯA HOÀN CHỈNH

### 1. **Diagnosis** - Partial
| Component | Status |
|-----------|--------|
| `DiagnosisRepository` | ✅ Exists, wired to ApiService |
| `ResultScreen` | ✅ Routed at `/diagnosis` |
| `DiagnosisPage` | ❌ **KHÔNG CÓ ROUTE** - unreachable! |
| Domain layer | ❌ `.gitkeep` stubs |

**Vấn đề:**
- `DiagnosisPage` tồn tại nhưng không có route → user không thể truy cập
- `/diagnosis` route hiện trỏ vào `ResultScreen` (chỉ hiển thị kết quả)
- Có thể `DiagnosisPage` là UI cũ, `ResultScreen` là UI mới → cần xác nhận

### 2. **Profile** - Conflict
| File | Status |
|------|--------|
| `lib/presentation/screens/profile_screen.dart` (2337 lines) | ✅ Routed, fully featured |
| `lib/features/profile/presentation/pages/profile_page.dart` | ❌ **ORPHANED** - không route |

**Vấn đề:**
- `ProfilePage` là shell đơn giản với subject chips (onTap: `// Coming soon`)
- `ProfileScreen` là UI thật với đầy đủ settings
- → `ProfilePage` là dead code, nên xóa

### 3. **Spaced Repetition (Review)** - Data only, NO UI
| Component | Status |
|-----------|--------|
| `SpacedReviewItem` model | ✅ |
| `SpacedRepetitionRepository` (SM-2 algorithm) | ✅ |
| **UI/Review Session Flow** | ❌ **KHÔNG CÓ** |

**Vấn đề:**
- Algorithm hoàn chỉnh (SM-2 với ease factor, interval calculation)
- Không có màn hình để user thực hiện spaced review
- Hiện tại chỉ hiển thị danh sách due items trong `ProgressPage`
- **Đây là gap lớn cho MVP** - spaced repetition là core feature

### 4. **Achievement** - Data only, NO dedicated UI
| Component | Status |
|-----------|--------|
| `AchievementBadge` model | ✅ |
| `AchievementRepository` (5 badges) | ✅ |
| **Achievement Page** | ❌ **KHÔNG CÓ** |

**Vấn đề:**
- 5 badges được định nghĩa: `first_session`, `streak_3_days`, `recovery_wise`, `focus_guardian`, `weekly_commitment`
- Chỉ hiển thị inline trong ProgressPage (tối đa 6 badges) và SessionCompletePage (newly unlocked)
- Không có trang achievements gallery hay progress tracking

### 5. **Inspection** - Dev-mode only
| Component | Status |
|-----------|--------|
| `InspectionRuntimeStore` (in-memory) | ✅ |
| `InspectionCubit` | ✅ |
| `InspectionBottomSheet` | ✅ |
| **Persistence** | ❌ Không có |
| **Public UI** | ❌ Chỉ hiển thị khi `devModeEnabled = true` |

**Vấn đề:**
- Feature chỉ dành cho developers để debug AI decisions
- Không có dashboard cho regular users
- Dữ liệu mất khi restart app (in-memory only)

### 6. **Offline Mode** - Data only, NO toggle UI
| Component | Status |
|-----------|--------|
| `OfflineModeRepository` (signal queue) | ✅ |
| **Toggle/Status UI** | ❌ **KHÔNG CÓ** |

**Vấn đề:**
- Signal queue hoạt động ngầm
- User không thể bật/tắt offline mode từ UI
- Không có indicator hiển thị trạng thái offline

---

## 🐛 BUGS & ISSUES CẦN SỬA

### P0 - Compile/Logic Issues
| # | File | Vấn đề | Mức độ |
|---|------|--------|--------|
| 1 | `progress_page.dart` ~line 93 | `_onRetry` callback rỗng → tap "Retry" không làm gì | **P1** |
| 2 | `progress_page.dart` `_SpacedReviewSection` | `_onRetry` rỗng | **P1** |
| 3 | `progress_page.dart` `_AchievementSection` | `_onRetry` rỗng | **P1** |

### P1 - UX Issues
| # | File | Vấn đề | Mức độ |
|---|------|--------|--------|
| 4 | `diagnosis_page.dart` | KHÔNG CÓ ROUTE → user không thể truy cập | **P1** |
| 5 | `profile_page.dart` | ORPHANED → dead code | **P2** |
| 6 | `quiz_page.dart` | Hardcoded accepted answers cho 1 câu đạo hàm | **P2** |

### P2 - Theme/Consistency
| # | File | Vấn đề | Số lượng |
|---|------|--------|----------|
| 7 | `diagnosis_page.dart` | Hardcoded colors (gradients, cards) | 30+ |
| 8 | `recovery_screen.dart` | Hardcoded gradient background + orange tones | 20+ |
| 9 | `session_complete_page.dart` | Hardcoded green gradients | 15+ |
| 10 | `today_page.dart` | Hardcoded progress bar + stat accent colors | 10+ |
| 11 | `progress_page.dart` | Hardcoded progress bar color | 5+ |
| **Total** | | **224+ hardcoded color instances** | |

### P3 - i18n
| # | File | Vấn đề |
|---|------|--------|
| 12 | `diagnosis_page.dart` | 20+ hardcoded Vietnamese strings |
| 13 | `recovery_screen.dart` | 10+ hardcoded strings |
| 14 | `session_complete_page.dart` | 10+ hardcoded strings |
| 15 | `today_page.dart` | 15+ hardcoded strings |

---

## 📋 MVP READINESS CHECKLIST

Dựa trên README goals:

### Goal 1: "Personalized study roadmap based on quiz results"
| Requirement | Status |
|-------------|--------|
| Quiz flow (question → answer → diagnosis) | ✅ Working |
| Roadmap display | ⚠️ Static content only (ThptRoadmapPage) |
| Personalized recommendations | ⚠️ Based on diagnosis results, but not dynamically generated |
| **MVP Readiness** | **~70%** |

### Goal 2: "Combine learning signals and emotional state for interventions"
| Requirement | Status |
|-------------|--------|
| Behavioral signal collection | ✅ Working |
| Mood state tracking | ✅ Working |
| Intervention suggestions | ✅ Working |
| Recovery mode | ✅ Working |
| HITL (Human-in-the-loop) | ⚠️ Backend-dependent |
| **MVP Readiness** | **~85%** |

### Goal 3: "Light UI for high school students"
| Requirement | Status |
|-------------|--------|
| Zen widget system | ✅ Complete (ZenButton, ZenCard, ZenPageContainer) |
| Dark mode support | ⚠️ Partial (224 hardcoded colors break this) |
| Vietnamese i18n | ⚠️ Partial (50+ hardcoded strings) |
| Responsive layout | ✅ Uses LayoutBuilder, SafeArea |
| **MVP Readiness** | **~75%** |

---

## 🔧 RECOMMENDED FIXES (Theo thứ tự ưu tiên)

### Sprint 1: Critical Fixes (P0-P1)
1. **Sửa `_onRetry` callbacks trong ProgressPage** → gán proper retry logic
2. **Quyết định về `DiagnosisPage`** → hoặc xóa, hoặc thêm route
3. **Xóa `ProfilePage` orphaned** → chỉ giữ `ProfileScreen`
4. **Thêm Spaced Review UI** → tối thiểu 1 màn hình review session

### Sprint 2: Theme Consistency (P2)
5. **Replace hardcoded colors với `theme.colorScheme`** trong:
   - `diagnosis_page.dart`
   - `recovery_screen.dart`
   - `session_complete_page.dart`
   - `today_page.dart`
   - `progress_page.dart`

### Sprint 3: i18n (P3)
6. **Extract hardcoded strings** → `app_strings.dart` với `context.t()`

### Sprint 4: Missing Features
7. **Spaced Review Session Page** → interactive review flow
8. **Achievement Page** → badge gallery + progress tracking
9. **Offline Mode Toggle** → settings switch + status indicator
10. **Inspection Dashboard** → public-facing AI transparency (optional)

---

## 📈 OVERALL MVP READINESS: ~75%

| Area | Readiness |
|------|-----------|
| Core Quiz→Diagnosis→Intervention flow | 85% |
| User Management (auth, profile) | 90% |
| Personalization (roadmap, recommendations) | 60% |
| Emotional/Behavioral Tracking | 85% |
| UI Polish (theme, i18n) | 70% |
| Offline Support | 50% |

**Để đạt MVP-ready (90%+):**
- Cần sửa 3 P0 issues (1-2 ngày)
- Cần theme consistency (2-3 ngày)
- Cần spaced review UI (2-3 ngày)
- Tổng ước lượng: **5-8 ngày làm việc**
