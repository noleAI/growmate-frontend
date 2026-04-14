# MVP UI/UX & Integration Readiness Review

**Dự án:** GrowMate — Your smart and friendly study partner  
**Đội:** noleAI  
**Review date:** 2026-04-14  
**Reviewer role:** UX Lead + Product Engineer (Frontend & Integration)  
**Phạm vi:** Đánh giá frontend Flutter (chưa tích hợp backend REST API)  

---

## 1. MVP UX EVALUATION

### Core User Flow Analysis

Dựa trên Proposal §6.2 (3 màn hình chính) và codebase thực tế, luồng MVP chính là:

```
Welcome → Login/Register → Data Consent → Today (Home)
  → Quiz (làm bài) → Diagnosis (kết quả AI) → Intervention (can thiệp/HITL)
  → Session Complete → Quay lại Today
  → Recovery (nếu kiệt sức) → Quay lại Today
```

### Checklist đánh giá

| Tiêu chí | Trạng thái | Chi tiết |
|----------|-----------|---------|
| Core user flow đầy đủ | ✅ Đạt | 7 màn hình core hoàn chỉnh: Today → Quiz → Diagnosis → Intervention → SessionComplete + Recovery, MindfulBreak |
| Auth flow | ✅ Đạt | Welcome, Login, Register, ForgotPassword, DataConsent đầy đủ với redirect logic |
| Loading states | ✅ Đạt | Quiz loading, ThinkingHero, ResultLoading, submit transition, FutureBuilder loading đều có |
| Error states | ✅ Đạt | ZenErrorCard tái sử dụng, _ResultErrorView, _fetchError handling, _RouteDataErrorPage |
| Empty states | ✅ Đạt | _EmptyHeroCard, _isQuestionBankEmpty, _AiSystemPanel null snapshot, empty history |
| Success states | ✅ Đạt | QuizSubmitSuccessState, SessionComplete celebration, badge unlock, toast messages |
| Confirmation / fallback | ✅ Đạt | _confirmLeaveQuiz dialog, AiResultModal decision moment, HITL uncertainty dialog |
| Adaptive UI states | ⚠️ Đạt một phần | Recovery mode gradient thay đổi, intervention mode switch. Nhưng chưa có UI runtime adaptation dựa trên Particle Filter state (focused/confused/exhausted) |
| Human-in-the-loop flow | ✅ Đạt | Uncertainty dialog trong InterventionPage, AiResultModal accept/reject plan, HITL confirm API |
| Trust / transparency | ✅ Đạt | ResultScreen hiển thị confidence score, risk level, diagnosis reason, AI decision transparency section, Inspection BottomSheet |
| De-stress UI | ✅ Đạt | Pastel gradients, ZenCard, ZenButton, micro-animations (AnimatedSwitcher, AnimatedSlide), breathing animation trong Recovery |
| i18n (VI/EN) | ✅ Đạt | context.t() pattern xuyên suốt toàn app, AppLanguageCubit |
| Dark mode | ✅ Đạt | ThemeModeCubit, AppTheme.lightThemeFor/darkThemeFor, isDark checks |
| Navigation | ✅ Đạt | GoRouter với auth guard, consent guard, proper redirect logic |
| Offline awareness | ✅ Đạt | NetworkStatusIndicator, OfflineModeRepository, queued signals |

### Đánh giá tổng hợp

> **MVP Status: ĐẠT**

App đã vượt xa yêu cầu "3 màn hình chính" trong Proposal. Toàn bộ core user flow hoạt động end-to-end với mock data. Các trạng thái hệ thống (loading, error, empty, success, confirmation) được xử lý ở tất cả màn hình quan trọng. HITL flow và trust/transparency đã được triển khai tốt.

**Điểm chưa hoàn thiện:** Adaptive UI theo trạng thái tinh thần (focused/confused/exhausted) từ Empathy Agent chưa thay đổi giao diện runtime — chỉ logic mode `recovery` vs `normal` được phản ánh. Đây là gap sẽ cần data thật từ backend Particle Filter.

---

## 2. UX GAPS

### GAP-01: Thiếu Onboarding / First-time User Guidance

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | Sau DataConsent, user mới vào TodayPage thấy EmptyHeroCard với CTA "Bắt đầu phiên đầu tiên" nhưng không có giải thích GrowMate hoạt động thế nào, quiz là gì, AI sẽ làm gì |
| **Vì sao ảnh hưởng MVP** | User persona (Lan Anh 17 tuổi) có thể bối rối về kỳ vọng sản phẩm ⇒ drop-off ngay phiên đầu. BGK demo cũng cần hiểu flow nhanh |
| **Mức độ** | **Important** |

### GAP-02: Quiz không có xác nhận nộp toàn bộ bài

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | Nút "Gửi bài" submit **từng câu đang active**, không phải toàn bộ quiz. User có 20 câu nhưng chỉ submit 1 câu hiện tại → diagnosis chỉ dựa trên 1 câu trả lời. UX label "Gửi bài" gây hiểu nhầm là nộp cả bài |
| **Vì sao ảnh hưởng MVP** | Core flow bị lệch: user nghĩ đã nộp bài hoàn chỉnh nhưng diagnosis chỉ có 1 câu ⇒ kết quả AI không có ý nghĩa, giảm trust. Đối với demo BGK, đây là confusion point |
| **Mức độ** | **Critical** |

### GAP-03: Thiếu visual feedback cho trạng thái tinh thần (Empathy Agent output)

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | Proposal §6.2 mô tả 3 chế độ UI (focused/confused/exhausted) nhưng code hiện tại chỉ phân biệt `normal` vs `recovery` mode. Không có visual indicator (badge, icon, color change) cho trạng thái tinh thần ước lượng |
| **Vì sao ảnh hưởng MVP** | Đây là selling point cốt lõi của Empathy Agent + Particle Filter. Nếu UI không phản ánh trạng thái thì BGK không thể kiểm chứng cơ chế Agentic thứ 3 hoạt động |
| **Mức độ** | **Critical** |

### GAP-04: Diagnosis Result Screen gradient hardcoded sáng, không tương thích dark mode

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | `result_screen.dart` line 417-421 hardcode gradient `Color(0xFFEFF6FF)` và `Color(0xFFE0ECFF)`, không dùng `theme.colorScheme`. Tương tự intervention_page.dart line 131-134 |
| **Vì sao ảnh hưởng MVP** | Demo trên dark mode sẽ có card trắng lóa giữa nền tối ⇒ UI broken, giảm ấn tượng chuyên nghiệp |
| **Mức độ** | **Important** |

### GAP-05: Không có xác nhận trước khi tự động chuyển sang Intervention

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | Sau Diagnosis, nếu user accept plan, app tự động navigate sang InterventionPage sau 720ms delay mà không có animation hay confirm nào rõ ràng. User có thể không nhận ra đã chuyển context |
| **Vì sao ảnh hưởng MVP** | Gây jarring transition. Proposal §6.3 yêu cầu "tôn trọng lựa chọn" — transition cần feel intentional |
| **Mức độ** | **Important** |

### GAP-06: Thiếu trạng thái khi timer hết trong Quiz

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | Timer countdown tới 0 nhưng không trigger hành động nào (không auto-submit, không warning, không stop timer ở negative). User có thể tiếp tục làm bài sau khi hết giờ |
| **Vì sao ảnh hưởng MVP** | Vấn đề UX cơ bản cho quiz có thời gian. Nếu demo tới BGK mà timer = 00:00 nhưng vẫn làm bài được → giảm trust vào tính nghiêm túc của hệ thống |
| **Mức độ** | **Important** |

---

## 3. UI/UX IMPROVEMENTS

### IMP-01: Thêm short onboarding tooltip/coach-mark ở TodayPage lần đầu

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | User mới không biết bắt đầu từ đâu |
| **Giải pháp** | Thêm 1 overlay card (hoặc expanded EmptyHeroCard) với 3 bullet ngắn: ① Làm quiz → ② AI chẩn đoán → ③ Nhận lộ trình. Hiển thị 1 lần, dismiss vĩnh viễn bằng SharedPreferences flag |
| **Lợi ích** | Giảm first-session drop-off; BGK hiểu flow ngay |

### IMP-02: Rõ ràng hóa submit quiz flow

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | "Gửi bài" gây nhầm lẫn giữa submit 1 câu vs toàn bộ |
| **Giải pháp** | **Option A (Recommended):** Đổi label thành "Nộp bài (X/20 đã trả lời)" và submit toàn bộ answers đã có. Hiện confirm dialog trước khi nộp nếu chưa trả lời hết. **Option B:** Giữ submit per-question nhưng đổi label thành "Gửi câu này" và thêm "Nộp toàn bộ bài" ở cuối |
| **Lợi ích** | Tránh confusion, đảm bảo diagnosis nhận đầy đủ evidence |

### IMP-03: Thêm mental state indicator nhẹ

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | UI không phản ánh output Empathy Agent |
| **Giải pháp** | Tại TopAppBar hoặc TodayPage, thêm chip nhỏ hiển thị trạng thái: 🟢 Tập trung / 🟡 Hơi mệt / 🔴 Cần nghỉ. Giá trị lấy từ API response `mentalState` field (mock: dựa trên focusScore last session) |
| **Lợi ích** | Chứng minh Particle Filter → UI reactive; tăng trust + wow factor |

### IMP-04: Fix hardcoded colors cho dark mode

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | Gradient cards dùng Color(0xFF...) cố định |
| **Giải pháp** | Thay bằng `theme.colorScheme.primaryContainer` / `surfaceContainerLow` cho gradient. Hoặc dùng pattern `isDark ? darkVariant : lightVariant` |
| **Lợi ích** | UI không bị vỡ trong dark mode demo |

### IMP-05: Timer hết giờ behavior

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Vấn đề** | Timer đếm tới 0 nhưng không có hành động |
| **Giải pháp** | Khi timer = 0: ① hiện warning card "Hết giờ"; ② disable thêm câu trả lời mới; ③ auto-focus nút "Nộp bài". Tùy chọn: auto-submit sau 5 giây nếu đã trả lời ≥1 câu |
| **Lợi ích** | UX quiz chuyên nghiệp, phù hợp demo |

---

## 4. API INTEGRATION READINESS

### Architecture Analysis

| Khía cạnh | Đánh giá | Chi tiết |
|-----------|---------|---------|
| **API abstraction layer** | ✅ Tốt | `ApiService` abstract interface với 6 methods rõ ràng. `MockApiService`, `RealApiService`, `SupabaseHybridApiService` — swap bằng feature flag `useMockApi` |
| **State management** | ✅ Tốt | `flutter_bloc` pattern xuyên suốt: AuthBloc, QuizCubit, ResultCubit, InterventionBloc, InspectionCubit. States rõ ràng (loading/success/failure) |
| **Data flow & Repository pattern** | ✅ Tốt | Clean separation: Repository → ApiService → Backend. QuizRepository, DiagnosisRepository, InterventionRepository nhận sessionId |
| **Session management** | ✅ Tốt | `LearningSessionManager` quản lý sessionId động; token storage qua `GlobalTokenStorage` |
| **Feature flags** | ✅ Tốt | `useMockApi`, `useSupabaseRpcDataPlane` cho phép switch giữa mock/real dễ dàng |
| **Behavioral signal pipeline** | ✅ Tốt | `BehavioralSignalService` thu thập và batch submit mỗi 5s qua `submitSignals` API |
| **Error handling cho API calls** | ⚠️ Cần cải thiện | Quiz page có try-catch nhưng Bloc/Cubit không có retry policy nhất quán. Timeout handling chưa rõ |
| **Hardcoded data** | ⚠️ Một số chỗ | `SessionCompletePage` hardcode `durationMinutes: 12`, `focusScore: 3.4`, `confidenceScore: 0.83` — cần thay bằng data từ API response |
| **Missing API fields** | ⚠️ Cần bổ sung | API response không có field `mentalState` (focused/confused/exhausted), `uncertaintyScore` riêng, `beliefDistribution` cho UI. Mock data chưa map đầy đủ Proposal schema |
| **Retry & timeout** | ⚠️ Cần bổ sung | `ApiConfig` định nghĩa retry config nhưng `RealApiService` chưa implement exponential backoff. `MockApiService` delay cố định 1s |
| **Offline queue** | ✅ Tốt | `OfflineModeRepository` queue signals khi offline, flush khi online |

### Hardcoded Values cần thay thế

| File | Vị trí | Giá trị hardcode | Cần thay bằng |
|------|--------|------------------|---------------|
| `session_complete_page.dart` | Line 73-76 | `durationMinutes: 12`, `focusScore: 3.4/2.8`, `confidenceScore: 0.83/0.72` | Lấy từ last diagnosis API response hoặc session state |
| `quiz_page.dart` | Line 1072 | `'Giải tích 12'` subject hardcode | Lấy từ session/topic configuration |
| `intervention_page.dart` | Line 370, 398 | Hardcoded suggestion text | Lấy từ API `interventionPlan.suggestion` field |
| `mock_api_service.dart` | Toàn file | Vietnamese strings hardcode | OK cho mock, nhưng cần ensure real API trả i18n-ready data |

### Đánh giá tổng hợp

> **Integration Readiness: TẠM ỔN — Cần 3-5 fix nhỏ trước khi integrate**

**Kiến trúc tốt:** ApiService abstraction, feature flags, repository pattern, bloc pattern đều production-ready. Chuyển từ mock sang real API chỉ cần `useMockApi = false` + đảm bảo API response schema khớp.

**Các vấn đề chính cần fix trước khi integrate:**

1. **Thay hardcoded values** trong SessionCompletePage bằng data từ API response
2. **Bổ sung mental state field** vào API response parsing (ResultModel cần `mentalState`, `particleDistribution`)
3. **Implement retry/timeout** trong RealApiService theo ApiConfig
4. **Quiz submit flow** cần rõ ràng giữa per-question vs batch submit — align với backend endpoint design
5. **Ensure API response schema mapping** — mock data schema cần match production API contract

---

## 5. IMPLEMENTATION PLAN

> Plan được thiết kế để GPT-5.3-Codex có thể thực hiện trực tiếp.  
> Ưu tiên theo thứ tự: Critical gaps → Important gaps → Integration readiness.

---

### Module A: Quiz Page (`features/quiz/presentation/pages/quiz_page.dart`)

#### Task A.1: Rõ ràng hóa submit flow (Critical — GAP-02)

**Issue:** Nút "Gửi bài" submit 1 câu hiện tại nhưng label gây hiểu nhầm là nộp cả bài.

**Thay đổi cần làm:**
1. Đổi label nút submit:
   - Khi đang ở giữa quiz: `"Gửi câu ${currentNumber}"` (vi) / `"Submit Q${currentNumber}"` (en)
   - Thêm nút riêng "Nộp toàn bộ bài" xuất hiện ở cuối question list hoặc ở question navigator sheet
2. Khi user nhấn "Nộp toàn bộ bài":
   - Hiện confirm dialog: "Bạn đã trả lời X/20 câu. Bạn có muốn nộp bài?" 
   - Nếu confirm → gọi `_submitCurrentAnswer()` cho câu cuối + navigate sang diagnosis
   - Nếu chưa trả lời câu nào → hiện warning
3. Giữ nút "Gửi câu" cho per-question submit vẫn luôn hiển thị

**Expected behavior:** User phân biệt rõ submit 1 câu vs nộp cả bài. Confirm dialog tránh nộp bài nhầm.

**Gợi ý kỹ thuật:** Tạo method `_submitEntireQuiz()` gọi tất cả persisted drafts, gom thành 1 batch request. Nếu backend chỉ nhận per-answer, iterate `_selectedOptionByQuestion`, `_trueFalseDraftByQuestion`, `_shortAnswerDraftByQuestion` và submit lần lượt.

---

#### Task A.2: Xử lý timer hết giờ (Important — GAP-06)

**Issue:** Timer đếm tới 0 nhưng không có hành động nào.

**Thay đổi cần làm:**
1. Trong `_countdownTimer` callback, khi `_remainingTime.inSeconds <= 0`:
   - Set `_isTimerExpired = true` (thêm state variable mới)
   - Cancel timer
2. Khi `_isTimerExpired = true`:
   - Hiện banner card (dùng `ZenCard`) màu warning: "⏰ Hết giờ! Bạn có thể nộp bài ngay hoặc tiếp tục hoàn thành."
   - Timer text đổi thành `"00:00"` với màu `colorScheme.error`
   - Nút nộp bài tự động focus (wrap trong `Scrollable.ensureVisible`)
3. Không disable input (cho phép user hoàn thành) — chỉ visual warning

**Expected behavior:** Khi hết giờ, user thấy rõ ràng timer hết nhưng không bị ép dừng. Visual cue mạnh.

---

### Module B: Diagnosis Result Screen (`features/diagnosis/presentation/pages/result_screen.dart`)

#### Task B.1: Fix dark mode hardcoded gradient (Important — GAP-04)

**Issue:** Gradient dùng `Color(0xFFEFF6FF)` / `Color(0xFFE0ECFF)` cố định.

**Thay đổi cần làm:**
1. Line 417-421: Thay gradient bằng:
   ```dart
   gradient: LinearGradient(
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
     colors: [
       theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
       theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
     ],
   ),
   ```
2. Line 423-428: Thay boxShadow color bằng `theme.colorScheme.shadow.withValues(alpha: 0.1)`

**Expected behavior:** Hero card hòa hợp với cả light và dark theme.

---

#### Task B.2: Smoother transition sang Intervention (Important — GAP-05)

**Issue:** Auto-navigate sau 720ms delay không có visual feedback.

**Thay đổi cần làm:**
1. Trước khi navigate (trong listener `state.navigateToIntervention`):
   - Hiện overlay card với text: "Đang chuyển sang bước can thiệp..." + `CircularProgressIndicator`
   - Dùng `AnimatedOpacity` fade-in
2. Tăng delay từ 720ms lên 1200ms để user kịp đọc
3. Thêm `context.t()` cho text overlay

**Expected behavior:** User thấy rõ ràng app đang chuyển context, transition feel intentional.

---

### Module C: Intervention Page (`features/intervention/presentation/pages/intervention_page.dart`)

#### Task C.1: Fix dark mode hardcoded gradient (Important — GAP-04)

**Issue:** Line 131-134 dùng `Color(0xFFEFF7E8)` / `Color(0xFFEAF2F5)` cố định.

**Thay đổi cần làm:**
1. Thay gradient colors bằng:
   ```dart
   colors: [
     theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
     theme.colorScheme.surfaceContainerLow,
     theme.colorScheme.surface,
   ],
   ```
2. Line 370 `Color(0xFFFAF9F6)` → `theme.colorScheme.surfaceContainerLowest`
3. Line 536 `Colors.white.withValues(alpha: 0.86)` → `theme.colorScheme.surface.withValues(alpha: 0.86)`

**Expected behavior:** Intervention page đẹp trong cả light và dark mode.

---

### Module D: Today Page (`features/today/presentation/pages/today_page.dart`)

#### Task D.1: Thêm mental state indicator (Critical — GAP-03)

**Issue:** Không có visual indicator cho trạng thái tinh thần từ Empathy Agent.

**Thay đổi cần làm:**
1. Thêm widget `_MentalStateChip` ở dưới date label (sau line 83):
   ```dart
   _MentalStateChip(latestSession: latestSession)
   ```
2. Widget logic:
   - Nếu không có session history: ẩn
   - Nếu `focusScore >= 3.5`: chip 🟢 "Tập trung" / "Focused"
   - Nếu `focusScore >= 2.5`: chip 🟡 "Hơi mệt" / "Slightly tired"  
   - Nếu `focusScore < 2.5`: chip 🔴 "Cần nghỉ" / "Needs rest"
3. Chip style: Container với border radius 999, padding 8x4, color = `tertiaryContainer`
4. **(Integration prep):** Khi backend API ready, thay focusScore logic bằng field `mentalState` từ API response

**Expected behavior:** User thấy trạng thái tinh thần hiện tại. BGK thấy output Empathy Agent → UI reactive.

---

#### Task D.2: Thêm first-time onboarding card (Important — GAP-01)

**Issue:** User mới không hiểu flow của GrowMate.

**Thay đổi cần làm:**
1. Thêm `_OnboardingCard` widget hiển thị khi:
   - `history.isEmpty` (chưa có session nào)
   - SharedPreferences key `onboarding_dismissed` = false
2. Nội dung card (vi/en):
   - Title: "Chào mừng bạn đến GrowMate! 🌱"
   - 3 steps: ① Làm quiz để AI hiểu lỗ hổng → ② Nhận chẩn đoán cá nhân hóa → ③ Theo lộ trình AI gợi ý
   - Nút: "Mình hiểu rồi" → dismiss + save flag
3. Hiển thị **trước** `_EmptyHeroCard`
4. Dùng `ZenCard` + icon `Icons.school_rounded`

**Expected behavior:** User mới hiểu ngay phải làm gì. Card biến mất vĩnh viễn sau dismiss.

---

### Module E: Session Complete Page (`features/session/presentation/pages/session_complete_page.dart`)

#### Task E.1: Thay hardcoded values bằng dynamic data (Integration)

**Issue:** `durationMinutes`, `focusScore`, `confidenceScore` hardcoded.

**Thay đổi cần làm:**
1. Thêm query parameters cho session complete route:
   - `duration`, `focus`, `confidence` (từ diagnosis response)
2. Trong `_recordCompletion`, parse từ `params`:
   ```dart
   final durationMinutes = int.tryParse(params['duration'] ?? '') ?? 12;
   final focusScore = double.tryParse(params['focus'] ?? '') ?? (mode == 'recovery' ? 2.8 : 3.4);
   final confidenceScore = double.tryParse(params['confidence'] ?? '') ?? (mode == 'recovery' ? 0.72 : 0.83);
   ```
3. Cập nhật navigation từ InterventionPage → SessionComplete để truyền values

**Expected behavior:** SessionComplete hiển thị data thực từ phiên học, không hardcode. Fallback values giữ nguyên cho mock mode.

**Gợi ý kỹ thuật:** Khi integrate real API, InterventionBloc hoặc ResultCubit sẽ hold diagnosis response chứa `duration`, `focusScore`, `confidenceScore` — pass qua query params.

---

### Module F: API Service Layer (`core/network/`, `core/services/`)

#### Task F.1: Bổ sung mental state field vào API response parsing (Integration)

**Issue:** `ResultModel` và mock API response chưa có field `mentalState`.

**Thay đổi cần làm:**
1. Trong `mock_api_service.dart`, thêm vào mỗi diagnosis response `data`:
   ```dart
   'mentalState': 'focused',  // hoặc 'confused', 'exhausted', 'frustrated'
   'uncertaintyScore': 0.12,
   'particleDistribution': {'focused': 0.65, 'confused': 0.20, 'exhausted': 0.10, 'frustrated': 0.05},
   ```
2. Trong `ResultModel` (diagnosis domain), thêm fields:
   ```dart
   final String mentalState;
   final double uncertaintyScore;
   final Map<String, double> particleDistribution;
   ```
3. Update `ResultModel.fromJson()` parsing

**Expected behavior:** Mock data và real API response đều chứa Empathy Agent output. UI có thể render mental state indicator.

---

#### Task F.2: Implement retry logic trong RealApiService (Integration)

**Issue:** `RealApiService` không có retry/backoff mặc dù `ApiConfig` đã define.

**Thay đổi cần làm:**
1. Tạo helper method `_withRetry<T>(Future<T> Function() action)`:
   - Max retries: `ApiConfig.maxRetries` (3)
   - Exponential backoff: `initialRetryDelay * retryMultiplier^attempt`
   - Retry chỉ cho network errors và 5xx, không retry 4xx
2. Wrap toàn bộ HTTP calls trong `RealApiService` bằng `_withRetry`
3. Thêm timeout handling: `ApiConfig.connectTimeout`, `receiveTimeout`

**Expected behavior:** API calls tự retry tối đa 3 lần khi gặp network error, với backoff delay tăng dần. Không retry cho client errors.

---

### Module G: Quiz Cubit/Repository (`features/quiz/`)

#### Task G.1: Chuẩn bị cho batch submit (Integration)

**Issue:** QuizCubit hiện chỉ submit 1 answer, cần support batch submit toàn bộ quiz.

**Thay đổi cần làm:**
1. Thêm method `submitBatchAnswers` vào `QuizRepository`:
   ```dart
   Future<Map<String, dynamic>> submitBatchAnswers({
     required List<Map<String, dynamic>> answers,
   })
   ```
2. Thêm `ApiService.submitBatchAnswers` vào interface (nếu backend hỗ trợ)
3. Trong `MockApiService`, implement mock batch submit (iterate + return combined diagnosis)
4. `QuizCubit` thêm method `submitAllAnswers(List<QuizQuestionUserAnswer>)`

**Expected behavior:** Frontend sẵn sàng gửi toàn bộ bài quiz cùng lúc khi backend endpoint ready.

**Gợi ý kỹ thuật:** Nếu backend chỉ nhận per-answer, frontend có thể iterate submit + gọi getDiagnosis một lần cuối cùng.

---

### Tóm tắt ưu tiên thực hiện

| Thứ tự | Task | Mức độ | Effort ước tính |
|--------|------|--------|----------------|
| 1 | A.1 — Rõ ràng hóa quiz submit flow | Critical | 2-3h |
| 2 | D.1 — Mental state indicator | Critical | 1-2h |
| 3 | F.1 — Bổ sung mental state vào API/model | Critical (Integration) | 1h |
| 4 | B.1 — Fix dark mode gradient (Diagnosis) | Important | 30min |
| 5 | C.1 — Fix dark mode gradient (Intervention) | Important | 30min |
| 6 | A.2 — Timer hết giờ behavior | Important | 1h |
| 7 | D.2 — Onboarding card | Important | 1-2h |
| 8 | B.2 — Smoother transition | Important | 1h |
| 9 | E.1 — Dynamic session complete values | Integration | 1h |
| 10 | F.2 — Retry logic RealApiService | Integration | 1-2h |
| 11 | G.1 — Batch submit preparation | Integration | 2h |

**Tổng effort ước tính:** ~12-16 giờ dev time

---

*End of MVP UX & Integration Readiness Review*
