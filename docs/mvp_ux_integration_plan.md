# MVP UI/UX & Integration Readiness Review

> **Dự án:** GrowMate — Multi-Agent AI Tutor  
> **Phiên bản:** MVP Core Agentic (Giai đoạn 1)  
> **Ngày review:** 2026-04-14  
> **Reviewer:** UX Lead / Product Engineer  
> **Tham chiếu:** `docs/Proposal_Final.md`, `docs/API_CONTRACT_SPECIFICATION.md`, `docs/API_READINESS_CHECKLIST.md`

---

## MỤC LỤC

1. [MVP UX Evaluation](#1-mvp-ux-evaluation)
2. [UX Gaps](#2-ux-gaps)
3. [UX Improvements](#3-ux-improvements)
4. [API Integration Readiness](#4-api-integration-readiness)
5. [Implementation Plan](#5-implementation-plan)

---

## 1. MVP UX Evaluation

### 1.1. Đánh giá Core User Flow

| Bước | Màn hình | Trạng thái hiện tại | Ghi chú |
|------|---------|---------------------|---------|
| 1. Welcome / Onboarding | `welcome_page.dart` | ✅ Có | Logo, tagline, 2 CTA (Đăng nhập / Tạo tài khoản). Thiếu Onboarding giới thiệu tính năng và Data Consent. |
| 2. Đăng nhập / Đăng ký | `login_page.dart`, `register_page.dart` | ✅ Có | Validation, error messages dạng friendly (emoji). Có Forgot Password. |
| 3. Trang chủ (Today) | `today_page.dart` | ✅ Có | AI Hero card, thinking state, compact stats, AI analysis panel, quick strips (review/mindful/schedule). |
| 4. Quiz (Làm bài) | `quiz_page.dart` | ✅ Có | Hiển thị câu hỏi từ Supabase, gõ/chọn đáp án, submit, behavioral signal collection. |
| 5. Diagnosis (Chẩn đoán) | `result_screen.dart` | ✅ Có | Hiển thị headline, gap analysis, strengths, needs review, HITL flow, CTA → Intervention. |
| 6. Intervention (Can thiệp) | `intervention_page.dart` | ✅ Có | Academic/Recovery mode, option selection, uncertainty prompt (HITL), recovery timer, Q-value feedback. |
| 7. Session Complete | `session_complete_page.dart` | ✅ Có | Summary, badges, next action suggestion, CTA → Home / Mindful Break / Progress. |
| 8. Recovery | `recovery_screen.dart` | ✅ Có | Breathing animation, reason display, CTA quay lại. |
| 9. Mindful Break | `mindful_break_page.dart` | ✅ Có | 90s timer, breathing phases, ambient sound (3 presets), volume control. |
| 10. Progress | `progress_page.dart` | ✅ Có | Session history, timeline view. |
| 11. Profile / Settings | `profile_screen.dart` | ✅ Có | Theme, color palette (5 lựa chọn), language, data export, legal pages. |
| 12. Inspection Dashboard | `inspection_bottom_sheet.dart` | ✅ Có | Belief view, mental state, Q-values, decision log — dạng bottom sheet trong app. |

### 1.2. Đánh giá System States

| State | Hiện trạng | Chi tiết |
|-------|-----------|---------|
| **Loading** | ✅ Đạt | `_ThinkingHero` (Today), `_LoadingStateWidget`, `CircularProgressIndicator` (Quiz submit), `LinearProgressIndicator` (Session Complete), `DiagnosisLoading` BLoC state. |
| **Error** | ⚠️ Đạt một phần | `_ErrorStateWidget` có retry button (Today). `QuizFailure`, `DiagnosisFailure` states tồn tại. `api_error_displayer.dart` có sẵn. Tuy nhiên **Error UI chưa nhất quán**: Intervention chỉ dùng toast, Quiz dùng inline message. |
| **Empty** | ⚠️ Đạt một phần | `_ReviewDueStrip` ẩn khi empty. Schedule empty có hint text. Nhưng **Today page khi chưa có session history → vẫn hiển thị hardcoded stats** ("6 ngày", "4/5 hoàn thành"). |
| **Success** | ✅ Đạt | `QuizSuccess` → navigate to Diagnosis. `DiagnosisSuccess` → render result. `feedbackRecorded` → show confirmation. Session Complete page. |
| **Confirmation** | ✅ Đạt | HITL popup xác nhận trước thay đổi lộ trình. Intervention uncertainty prompt. |
| **Fallback** | ✅ Đạt | Mock API service fallback khi backend chưa sẵn sàng. Recovery mode khi confidence thấp. Offline mode queue. |

### 1.3. Đánh giá Adaptive UI States

| State | Proposal yêu cầu | Hiện trạng |
|-------|------------------|-----------|
| **Focused** | Hiển thị đầy đủ thông tin, tùy chọn nâng cao | ⚠️ Chưa implement — UI không thay đổi theo trạng thái focused |
| **Confused** | Chuyển sang giải thích trực quan | ⚠️ Chưa implement — Intervention page có recovery/academic mode nhưng chưa thay đổi UI layout theo confused state |
| **Exhausted** | Recovery Mode, nền màu ấm hơn | ✅ Đạt một phần — Recovery screen và Mindful Break tồn tại, nhưng app-wide background tint chưa thay đổi |

### 1.4. Đánh giá Human-in-the-Loop (HITL)

| Yêu cầu | Hiện trạng |
|---------|-----------|
| Popup xác nhận khi uncertainty cao | ✅ Có — `showUncertaintyPrompt` trong `InterventionState`, HITL confirm trong `DiagnosisBloc` |
| Ghi nhận phản hồi làm ground truth | ✅ Có — `HITLConfirmed` event → `confirmHITL` API → update plan |
| Tôn trọng lựa chọn, không ép buộc | ✅ Có — "Skip this time" option luôn tồn tại trong intervention options |
| HITL cho thay đổi lộ trình quan trọng | ✅ Có — `requiresHitl` field trong `DiagnosisSuccess` |

### 1.5. Đánh giá Trust / Transparency

| Yêu cầu | Hiện trạng |
|---------|-----------|
| Giải thích quyết định | ✅ Có — `diagnosisReason` hiển thị trên result screen |
| Inspection Dashboard | ✅ Có — Bottom sheet với belief, mental state, Q-values, decision log |
| Audit Log | ✅ Có — `InspectionRuntimeStore` ghi addDecision, updateQValues, updateMentalState |
| Confidence display | ✅ Có — AI Hero card hiển thị confidence (0.87), AI analysis panel hiển thị "Độ tự tin 74%" |

### 1.6. Compliance (Nghị định 13/2023)

| Yêu cầu | Hiện trạng |
|---------|-----------|
| Màn hình onboarding hiển thị dữ liệu thu thập | ❌ **Thiếu** — Welcome page không có Data Consent / Onboarding flow |
| Opt-in trước khi thu thập hành vi | ❌ **Thiếu** — Behavioral signals tự động thu thập, không hỏi consent |
| Data export | ✅ Có — `DataExportPage` với `PrivacyRepository` |
| Terms of Service / Privacy Policy | ✅ Có — Pages tồn tại, link từ Profile |

---

### MVP STATUS: ⚠️ ĐẠT MỘT PHẦN

**Lý do:**
- Core flow (Quiz → Diagnosis → Intervention → Session Complete) **hoạt động E2E** với MockAPI và Supabase hybrid.
- De-stress UI (pastel theme, Plus Jakarta Sans / Space Grotesk, rounded components, animations) **đạt cơ bản**.
- HITL flow, Inspection Dashboard, Recovery mode **đã implement**.
- **Thiếu 2 phần critical:** Data Consent onboarding flow (bắt buộc theo Proposal §6.4) và Empty/hardcoded states trên Today page.
- Adaptive UI states (focused/confused/exhausted) **chưa implement** nhưng proposal liệt kê là COULD HAVE (FR-UI-05).

---

## 2. UX Gaps

### GAP-01: Thiếu Data Consent / Onboarding Flow

| | |
|---|---|
| **Vấn đề** | Welcome page chuyển thẳng sang Login/Register mà không có bước giới thiệu GrowMate thu thập dữ liệu hành vi nào, mục đích gì, và yêu cầu Opt-in. |
| **Vì sao ảnh hưởng MVP** | Proposal §6.4 cam kết "Màn hình onboarding hiển thị rõ ràng dữ liệu được thu thập và mục đích sử dụng" + "Người dùng phải chủ động đồng ý trước khi thu thập dữ liệu hành vi". Đây là yêu cầu tuân thủ Nghị định 13 — **bắt buộc cho demo trước BGK**. Thiếu phần này làm mất tính minh bạch, trực tiếp vi phạm cam kết đạo đức AI. |
| **Mức độ** | 🔴 **Critical** |

### GAP-02: Today Page hiển thị hardcoded data khi chưa có session thực

| | |
|---|---|
| **Vấn đề** | `_CompactStats` hiển thị cứng "6 ngày streak", "4/5 hoàn thành", "Tập trung: Tốt". `_AiSystemPanel` hiển thị cứng "Quy tắc đạo hàm cơ bản", "Đạo hàm hàm số hợp". `AIHero` hiển thị cứng confidence 0.87 và topic "Ứng dụng đạo hàm". |
| **Vì sao ảnh hưởng MVP** | Khi demo E2E, BGK sẽ thấy data tĩnh không khớp với phiên vừa hoàn thành → mất credibility. Khi tích hợp API, data này phải đến từ backend/session history nhưng UI chưa có cơ chế để thay thế. |
| **Mức độ** | 🔴 **Critical** |

### GAP-03: Error handling không nhất quán giữa các screen

| | |
|---|---|
| **Vấn đề** | Today page có `_ErrorStateWidget` với retry. Quiz dùng `QuizFailure` state nhưng hiển thị inline text. Intervention dùng toast message. Diagnosis dùng `DiagnosisFailure` nhưng UI rendering khác nhau. Không có global error boundary. |
| **Vì sao ảnh hưởng MVP** | Khi tích hợp API thật, network errors sẽ xảy ra thường xuyên hơn → trải nghiệm không nhất quán gây confusion, user không biết phải làm gì khi lỗi xảy ra. |
| **Mức độ** | 🟡 **Important** |

### GAP-04: Quiz Page thiếu explicit empty state khi không có câu hỏi

| | |
|---|---|
| **Vấn đề** | Nếu Supabase trả về 0 câu hỏi (quiz_question_template rỗng cho chuyên đề), Quiz page hành vi chưa rõ ràng — không có empty state design rõ ràng. |
| **Vì sao ảnh hưởng MVP** | Khi backend trả empty quiz bank → user bị stuck, không có hướng dẫn rõ ràng về tiếp theo. |
| **Mức độ** | 🟡 **Important** |

### GAP-05: Thiếu loading indicator khi navigate từ quiz submit → diagnosis

| | |
|---|---|
| **Vấn đề** | Sau `QuizSuccess`, app navigate sang `/diagnosis?submissionId=...`. `DiagnosisBloc` bắt đầu với `DiagnosisLoading`. Tuy nhiên, transition giữa quiz → diagnosis không có visual feedback rõ ràng — user thấy blank screen rồi loading. |
| **Vì sao ảnh hưởng MVP** | Khoảnh khắc "trắng" khi chuyển trang gây cảm giác app chậm hoặc bị lỗi. Backend thật có thể mất 1-4.5s → khoảng blank này dài hơn mock. |
| **Mức độ** | 🟡 **Important** |

### GAP-06: Intervention page không xử lý rõ trường hợp backend trả interventionPlan rỗng

| | |
|---|---|
| **Vấn đề** | `_buildOptionsFromBackend` đã có fallback tạo 3 default options khi `backendPlan` rỗng. Tuy nhiên, UI không phân biệt được đâu là AI-generated options vs fallback defaults → giảm transparency. |
| **Vì sao ảnh hưởng MVP** | BGK kiểm tra Inspection Dashboard thấy options nhưng không biết đó là fallback → câu hỏi về tính Agentic thật sự. |
| **Mức độ** | 🟡 **Important** |

---

## 3. UX Improvements

### IMP-01: Thêm Data Consent Step vào Welcome Flow

| | |
|---|---|
| **Vấn đề** | Thiếu hoàn toàn bước đồng thuận dữ liệu trước khi vào app |
| **Giải pháp** | Thêm 1 màn hình giữa Welcome → Login/Register hiển thị: (1) GrowMate thu thập những gì (tín hiệu hành vi: tốc độ gõ, thời gian idle, tỷ lệ sửa), (2) Mục đích sử dụng (ước lượng trạng thái tinh thần, cá nhân hóa lộ trình), (3) Toggle Opt-in rõ ràng, (4) Link đến Privacy Policy. Lưu consent vào `SharedPreferences` / Supabase user metadata. |
| **Lợi ích** | Tuân thủ Nghị định 13/2023. Tăng trust khi demo trước BGK. Chứng minh cam kết đạo đức AI. |

### IMP-02: Thay thế hardcoded stats trên Today page bằng data thật từ Session History

| | |
|---|---|
| **Vấn đề** | `_CompactStats` hiển thị cứng "6", "4/5", "Tốt". `_AiSystemPanel` hiển thị cứng. |
| **Giải pháp** | (1) Inject `SessionHistoryRepository` vào `TodayPage`. (2) Dùng `StreamBuilder<List<SessionHistoryEntry>>` để hiển thị streak thật, sessions hoàn thành thật, focus score trung bình. (3) `AIHero` card: lấy topic và confidence từ session history gần nhất hoặc backend `/sessions/active` response. (4) `_AiSystemPanel`: lấy strengths/needsReview từ diagnosis gần nhất. (5) Trường hợp empty (chưa có session nào): hiển thị "Chưa có phiên học" với CTA "Bắt đầu phiên đầu tiên". |
| **Lợi ích** | Data nhất quán giữa các phiên. BGK thấy dữ liệu thay đổi sau mỗi demo session → chứng minh hệ thống thực sự adaptive. Sẵn sàng cho API integration. |

### IMP-03: Chuẩn hóa Error UI Pattern

| | |
|---|---|
| **Vấn đề** | 3+ cách hiển thị lỗi khác nhau |
| **Giải pháp** | Tạo `ZenErrorCard` widget tái sử dụng với: icon, message, retry button (optional), dismiss button (optional). Áp dụng nhất quán cho Quiz (thay inline text), Diagnosis (thay plain text), Intervention (thay toast cho critical errors, giữ toast cho non-critical). |
| **Lợi ích** | UX nhất quán. User training: thấy error card → biết tap retry. Giảm confusion khi API thật gây lỗi. |

### IMP-04: Thêm Transition Animation từ Quiz → Diagnosis

| | |
|---|---|
| **Vấn đề** | Blank moment khi navigate |
| **Giải pháp** | Khi `QuizSuccess` emit → hiển thị inline "AI đang phân tích bài làm..." card (tương tự `_ThinkingHero`) trước khi navigate. Delay navigate 800ms để user đọc được feedback "Đã nhận bài" → smooth transition sang result screen có `DiagnosisLoading`. |
| **Lợi ích** | No blank screen. User biết system đang xử lý. Cảm giác AI "thinking" khớp với narrative sản phẩm. |

### IMP-05: Thêm badge cho fallback options trong Intervention

| | |
|---|---|
| **Vấn đề** | Không phân biệt AI-generated vs fallback options |
| **Giải pháp** | Khi `InterventionOption.fromBackend == false`, thêm subtle badge "Mặc định" / "Default" ở góc option card. Log rõ trong `InspectionRuntimeStore` rằng đang dùng fallback options. |
| **Lợi ích** | Minh bạch cho BGK khi inspect. Tăng trust. |

---

## 4. API Integration Readiness

### 4.1. Đánh giá tổng thể

| Tiêu chí | Đánh giá | Chi tiết |
|---------|---------|---------|
| **State management** | ✅ Tốt | `flutter_bloc` (BLoC + Cubit) phân tầng rõ: `QuizBloc`, `DiagnosisBloc`, `InterventionBloc`, `AuthBloc`, `InspectionCubit`, `ThemeModeCubit`, `ColorPaletteCubit`, `AppLanguageCubit`. Sealed class states với Equatable. |
| **Data flow** | ✅ Tốt | `ApiService` interface → `MockApiService` / `RealApiService` / `SupabaseHybridApiService`. Repository pattern. Feature flag `useMockApi` toggle. |
| **Hardcoded dependencies** | ⚠️ Có | Today page stats (GAP-02). `AIHero` confidence/topic. `_AiSystemPanel` content. `appVersion: '1.0.0+1'` hardcoded trong router. |
| **Missing states khi API trả data thật** | ⚠️ Có | Today page empty state. Quiz empty state. Diagnosis API trả response khác mock format → potential mapping mismatch. |
| **UX khi API fail / delay** | ⚠️ Tạm | Loading states tồn tại. Error states tồn tại nhưng không nhất quán (GAP-03). `NetworkStatusIndicator` đã tích hợp app-wide. Offline mode queue cho signals. Retry logic trong `RealApiService`. |
| **Async-friendly interactions** | ✅ Tốt | Tất cả BLoC handlers là `async`. Timer-based behavioral signals (5s batch). `unawaited()` cho non-critical fire-and-forget. `FutureBuilder` cho lazy loading. |

### 4.2. Kiến trúc API Layer — Đã sẵn sàng

```
ApiService (interface)
├── MockApiService        ← MVP hiện tại (useMockApi = true)
├── SupabaseHybridApiService ← Supabase RPC + Mock fallback
└── RealApiService        ← Production REST API (sẵn sàng, chưa dùng)
```

**Đã có:**
- `ApiService` interface với 6 methods: `submitAnswer`, `getDiagnosis`, `submitSignals`, `submitInterventionFeedback`, `confirmHITL`, `saveInteractionFeedback`
- `RealApiService` với auth headers, retry (max 2), timeout (30s), error parsing
- `ApiConfig` từ `.env` / `--dart-define`
- `HttpLogger` cho debug
- `LearningSessionManager` cho dynamic session ID
- `AuthTokenStorage` (GlobalTokenStorage)
- API Contract Specification document (13 endpoints)
- Error hierarchy (`app_exceptions.dart`)

**Chưa có:**
- Entity models với `fromJson`/`toJson` (hiện dùng raw `Map<String, dynamic>`)
- Token storage bằng `flutter_secure_storage` (hiện dùng `SharedPreferences`)
- Unit tests cho API layer

### 4.3. Data Contract Alignment

| API Endpoint | Mock Response Keys | API Contract Keys | Match? |
|-------------|-------------------|-------------------|--------|
| `submitAnswer` | `answerId`, `questionId`, `isCorrect` | `answerId`, `questionId`, `isCorrect` | ✅ |
| `getDiagnosis` | `diagnosisId`, `title`, `gapAnalysis`, `strengths`, `needsReview`, `mode`, `requiresHITL`, `confidence`, `interventionPlan` | Giống | ✅ |
| `confirmHITL` | `hitlDecision`, `finalMode`, `interventionPlan` | Giống | ✅ |
| `submitInterventionFeedback` | `updatedQValues`, `selectedOption` | Giống | ✅ |
| `saveInteractionFeedback` | `eventId`, `savedAt` | Giống | ✅ |

### 4.4. Risks khi tích hợp API thật

| Risk | Severity | Mitigation |
|------|---------|-----------|
| Backend response format khác mock → crash | 🔴 Cao | BLoC handlers sử dụng `?.toString() ?? ''` và fallback. Tuy nhiên, thiếu `fromJson` models → brittle parsing. |
| Latency > 4.5s → UX degradation | 🟡 Trung bình | Loading states tồn tại. Timeout 30s trong `RealApiService`. Nhưng cần thêm timeout-specific error message. |
| Token expired mid-session → lost progress | 🟡 Trung bình | `RealApiService` có retry nhưng chưa có explicit token refresh re-queue logic. |
| Backend unavailable → total block | 🟢 Thấp | `SupabaseHybridApiService` fallback. `OfflineModeRepository` queue. `NetworkStatusIndicator` app-wide. |

---

### INTEGRATION READINESS: ⚠️ TẠM ỔN (65%)

**Các vấn đề chính cần fix trước khi integrate:**
1. **Entity models** — Thay raw Map parsing bằng typed models với `fromJson`
2. **Today page hardcoded data** — Phải đến từ session history / API response
3. **Error UI chuẩn hóa** — Nhất quán trước khi api thật tạo errors không lường trước
4. **Data Consent** — Phải hoàn thành trước khi thu thập behavioral signals
5. **Token storage nâng cấp** — `SharedPreferences` → `flutter_secure_storage` cho production

---

## 5. Implementation Plan

> Plan dưới đây được thiết kế để GPT-5.3-Codex (hoặc AI coding agent tương đương) có thể thực hiện trực tiếp. Mỗi task self-contained, có context đầy đủ.

---

### Module A: Data Consent & Onboarding

#### TASK A-1: Tạo Data Consent Page

- **Issue:** Thiếu bước yêu cầu đồng thuận dữ liệu trước khi thu thập hành vi. Vi phạm Nghị định 13/2023 và cam kết Proposal §6.4.
- **Thay đổi UI/UX cần làm:**
  1. Tạo file `lib/features/auth/presentation/pages/data_consent_page.dart`
  2. Nội dung: Tiêu đề "GrowMate thu thập gì?", danh sách 3 loại dữ liệu (tốc độ gõ, thời gian idle, tỷ lệ sửa đáp án), mục đích sử dụng (ước lượng trạng thái tinh thần, cá nhân hóa lộ trình), link đến Privacy Policy page.
  3. Toggle switch `SwitchListTile` cho "Tôi đồng ý cho GrowMate thu thập tín hiệu hành vi".
  4. CTA "Tiếp tục" disabled khi chưa đồng ý.
  5. Style: `ZenPageContainer`, `ZenCard`, `ZenButton`. Dùng theme colors.
  6. Lưu consent: `SharedPreferences` key `data_consent_accepted` = true/false, kèm timestamp.
- **Expected behavior:** Sau Register, user thấy Data Consent page → toggle đồng ý → tap "Tiếp tục" → navigate to Home. Trở lại app (không phải lần đầu) → skip consent.
- **Gợi ý kỹ thuật:** Kiểm tra `SharedPreferences.getBool('data_consent_accepted')` trong router redirect. Nếu false/null sau khi authenticated → redirect sang `/consent`.

#### TASK A-2: Tích hợp Consent vào Router Flow

- **Issue:** Router hiện tại chỉ check authenticated, không check consent.
- **Thay đổi UI/UX cần làm:**
  1. Trong `app_routes.dart`: thêm `static const String dataConsent = '/consent';`
  2. Trong `app_router.dart`: thêm route `/consent` → `DataConsentPage()`.
  3. Trong redirect logic: sau `isAuthenticated && visitingAuthFlow` check, thêm kiểm tra consent. Nếu authenticated nhưng chưa consent → redirect `/consent`.
  4. Bypass consent check cho route `/consent` (tránh infinite redirect).
- **Expected behavior:** New user: Welcome → Login → Consent → Home. Returning user (đã consent): Welcome → Login → Home. User chưa consent quay lại: bất kỳ route → Consent.

#### TASK A-3: Guard Behavioral Signal Collection bằng Consent

- **Issue:** `BehavioralSignalCollector` / `BehavioralSignalService` tự động thu thập tín hiệu mà không kiểm tra consent.
- **Thay đổi UI/UX cần làm:**
  1. Trong `BehavioralSignalService` hoặc `BehavioralSignalCollector`: thêm check `SharedPreferences.getBool('data_consent_accepted') == true` trước khi collect/submit signals.
  2. Nếu consent == false, skip signal collection silently (không block core flow).
- **Expected behavior:** Không thu thập tín hiệu hành vi khi user chưa đồng ý. Core flow (quiz, diagnosis, intervention) vẫn hoạt động bình thường.

---

### Module B: Today Page — Thay Hardcoded Data

#### TASK B-1: CompactStats đọc từ Session History

- **Issue:** `_CompactStats` hiển thị cứng "6 ngày", "4/5 hoàn thành", "Tốt".
- **Thay đổi UI/UX cần làm:**
  1. Trong `TodayPage`, thêm `StreamBuilder<List<SessionHistoryEntry>>` wrap quanh `_CompactStats`.
  2. Tính streak từ `SessionHistoryRepository.instance.watchHistory()`: đếm ngày liên tiếp có session.
  3. Tính completed today: count sessions có `completedAt` trong hôm nay.
  4. Tính focus: trung bình `focusScore` từ sessions trong 24h → "Tốt" (≥3.5), "Ổn" (≥2.5), "Cần nghỉ" (<2.5).
  5. Khi danh sách sessions rỗng: hiển thị "0 ngày", "0/0", "—".
- **Expected behavior:** Stats phản ánh data thật. Sau khi hoàn thành 1 session → quay lại Today → thấy stats cập nhật.

#### TASK B-2: AI Hero Card đọc từ session gần nhất

- **Issue:** `AIHero` hiển thị cứng topic "Ứng dụng đạo hàm", confidence 0.87.
- **Thay đổi UI/UX cần làm:**
  1. Lấy session history gần nhất → trích `topic` và `confidenceScore`.
  2. Nếu chưa có session nào: hiển thị welcome message "AI chưa có dữ liệu. Làm bài đầu tiên để AI phân tích!" + CTA "Bắt đầu phiên đầu tiên".
  3. `reason` text: nếu có session → dùng `nextAction` từ session gần nhất. Nếu không → dùng default message.
- **Expected behavior:** Lần đầu mở app (chưa có session) → thấy empty state hero. Sau 1 session → hero hiển thị topic/confidence thật.

#### TASK B-3: AI Analysis Panel đọc từ diagnosis gần nhất

- **Issue:** `_AiSystemPanel` hiển thị cứng strengths/needs review.
- **Thay đổi UI/UX cần làm:**
  1. Lưu diagnosis result cuối cùng vào local storage (SharedPreferences JSON hoặc SessionHistoryEntry extended fields).
  2. `_AiSystemPanel` đọc cached diagnosis → hiển thị strengths, needsReview, confidence thật.
  3. Khi chưa có diagnosis: ẩn panel hoặc hiển thị "Chưa có phân tích AI. Hoàn thành phiên đầu tiên để AI đánh giá."
- **Expected behavior:** Panel cập nhật sau mỗi lần có diagnosis mới. Phản ánh đúng data thật.

---

### Module C: Error UI Chuẩn Hóa

#### TASK C-1: Tạo ZenErrorCard widget

- **Issue:** Error hiển thị không nhất quán giữa các screen.
- **Thay đổi UI/UX cần làm:**
  1. Tạo `lib/shared/widgets/zen_error_card.dart`.
  2. Props: `String message`, `VoidCallback? onRetry`, `VoidCallback? onDismiss`.
  3. Design: Container với `errorContainer` background, `error` border, warning icon, message text, Row of buttons (Retry + Dismiss).
  4. Kiểu dáng tương tự `_ErrorStateWidget` đã có trong `today_page.dart` nhưng reusable.
- **Expected behavior:** Import và sử dụng ở mọi nơi cần hiển thị error. Giao diện error nhất quán.

#### TASK C-2: Áp dụng ZenErrorCard vào Diagnosis và Quiz

- **Issue:** Diagnosis dùng plain text cho `DiagnosisFailure`. Quiz dùng inline message cho `QuizFailure`.
- **Thay đổi UI/UX cần làm:**
  1. `result_screen.dart`: khi state là `DiagnosisFailure` → render `ZenErrorCard(message: state.message, onRetry: () => bloc.add(DiagnosisRequested(...)))`.
  2. `quiz_page.dart`: khi `QuizFailure` → ngoài inline message, thêm `ZenErrorCard` nếu lỗi là network/server (không phải validation). Giữ inline text cho validation errors ("Vui lòng nhập kết quả trước khi gửi").
- **Expected behavior:** Network errors hiển thị card nổi bật với retry. Validation errors hiển thị inline nhẹ nhàng.

---

### Module D: Quiz Empty State & Transition

#### TASK D-1: Quiz Empty State

- **Issue:** Quiz page không có empty state khi Supabase trả 0 câu hỏi.
- **Thay đổi UI/UX cần làm:**
  1. Trong `quiz_page.dart`, khi fetch question templates trả về rỗng: hiển thị `ZenCard` với icon `Icons.quiz_outlined`, message "Mình chưa có câu hỏi cho chuyên đề này. Thử quay lại sau nhé!", CTA "Quay về Trang chủ".
  2. Không hiển thị đồng hồ bấm giờ hay input field khi không có câu hỏi.
- **Expected behavior:** User thấy rõ ràng rằng không có câu hỏi, không bị stuck.

#### TASK D-2: Smooth Transition Quiz → Diagnosis

- **Issue:** Blank moment khi navigate từ quiz success → diagnosis loading.
- **Thay đổi UI/UX cần làm:**
  1. Khi `QuizBloc` emit `QuizSuccess`: hiển thị inline card "✓ Đã nhận bài — AI đang phân tích..." (tương tự `_ThinkingHero` style) trong quiz page.
  2. Delay `Future.delayed(Duration(milliseconds: 900))` rồi mới `context.push('/diagnosis?submissionId=...')`.
  3. Card hiển thị animated dots hoặc circular progress.
- **Expected behavior:** User thấy confirmation "đã nhận bài" → smooth transition → diagnosis loading screen. Không có blank moment.

---

### Module E: Intervention Transparency

#### TASK E-1: Badge cho fallback options

- **Issue:** Không phân biệt AI options vs fallback defaults.
- **Thay đổi UI/UX cần làm:**
  1. Trong intervention page, khi render option có `fromBackend == false`: thêm `Container` nhỏ ở góc card với text "Mặc định" (vi) / "Default" (en), background `colors.surfaceContainerHigh`, rounded.
  2. Trong `InspectionRuntimeStore`: khi dùng fallback options, log decision "Using default intervention options — backend plan was empty".
- **Expected behavior:** BGK xem Inspection Dashboard thấy log rõ ràng. User thấy badge nhẹ trên default options. AI-generated options không có badge.

---

### Module F: API Integration Prep

#### TASK F-1: Entity Models cho API Response

- **Issue:** Tất cả API response đều parse bằng raw `Map<String, dynamic>` → brittle, error-prone.
- **Thay đổi UI/UX cần làm:**
  1. Tạo `lib/data/models/api_models.dart` (hoặc từng file riêng):
     - `SubmitAnswerResponse` với `fromJson`
     - `DiagnosisResponse` với `fromJson` (bao gồm `interventionPlan` list)
     - `HITLConfirmResponse` với `fromJson`
     - `InterventionFeedbackResponse` với `fromJson` (bao gồm `updatedQValues`)
     - `InteractionFeedbackResponse` với `fromJson`
  2. Trong mỗi BLoC: thay `response['data'] as Map<String, dynamic>` bằng `ModelClass.fromJson(response['data'])`.
  3. Mỗi model có `.fromJson()` static method và `toString()` override để debug.
- **Expected behavior:** Compile-time safety cho API response. Nếu backend thay đổi key → lỗi rõ ràng tại `fromJson`, không phải null runtime crash.

#### TASK F-2: Nâng cấp Token Storage

- **Issue:** Auth tokens lưu trong `SharedPreferences` (plain text) → bảo mật yếu.
- **Thay đổi UI/UX cần làm:**
  1. Thêm dependency `flutter_secure_storage` vào `pubspec.yaml`.
  2. Refactor `AuthRepository`: thay `SharedPreferences` bằng `FlutterSecureStorage` cho `_tokenKey`, `_emailKey`, `_nameKey`.
  3. Refactor `GlobalTokenStorage` trong `auth_token_storage.dart` tương tự.
  4. Mock mode giữ SharedPreferences (cho testing).
- **Expected behavior:** Tokens encrypted at-rest. Tuân thủ yêu cầu bảo mật Proposal §4.6 (AES-256 at rest).
- **Gợi ý kỹ thuật:** `FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true))`.

---

### Tổng kết Priority

| Priority | Module | Tasks | Estimated Effort |
|----------|--------|-------|-----------------|
| 🔴 P0 — Bắt buộc trước MVP submit | A: Data Consent | A-1, A-2, A-3 | 3-4 giờ |
| 🔴 P0 — Bắt buộc trước MVP submit | B: Today Hardcoded | B-1, B-2, B-3 | 3-4 giờ |
| 🟡 P1 — Nên có trước MVP | C: Error UI | C-1, C-2 | 2 giờ |
| 🟡 P1 — Nên có trước MVP | D: Quiz States | D-1, D-2 | 2 giờ |
| 🟢 P2 — Nên có trước API integration | E: Intervention | E-1 | 1 giờ |
| 🟢 P2 — Nên có trước API integration | F: API Prep | F-1, F-2 | 4-6 giờ |

**Tổng effort ước lượng: ~15-19 giờ dev time.**

---

*Document generated: 2026-04-14 by UX Lead / Product Engineer review.*
