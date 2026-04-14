# MVP GAP ANALYSIS & KẾ HOẠCH HÀNH ĐỘNG
## GrowMate – GDGoC Hackathon Vietnam 2026
**Ngày đánh giá:** 14/04/2026 (cập nhật chiều) | **Deadline MVP:** 17/04/2026 (còn ~3 ngày)

---

## 1. TỔNG QUAN ĐÁNH GIÁ

### 1.1. Tình trạng tổng thể

| Thành phần | Hoàn thành | Trạng thái | Ghi chú |
|------------|-----------|-----------|---------|
| **Backend – Core Agents** | ~75% | ⚠️ PARTIAL | Logic Bayesian/PF/Q-Learning hoạt động; thiếu Quiz Pool & KG data |
| **Backend – API & Infra** | ~90% | ✅ GẦN XONG | 11 REST + 2 WS endpoints, Dockerfile sẵn sàng |
| **Frontend – UI/Screens** | ~95% | ✅ GẦN XONG | 3 màn hình chính + nhiều màn phụ + Haptic + Plan Tree + De-Stress palette |
| **Frontend – Tích hợp BE** | ~90% | ✅ GẦN XONG | Code tích hợp sẵn (Quiz↔Agentic bridge, WS, API); chỉ chờ bật flag khi BE deploy |
| **Dữ liệu (Quiz, KG)** | ~40% | ❌ THIẾU | Schema Supabase có, nhưng quiz data chưa nạp vào backend |
| **Inspection Dashboard** | ~85% | ✅ GẦN XONG | Belief + Q-values + Decision Log + Plan Tree timeline visualization |
| **Deployment (Cloud Run)** | ~50% | ⚠️ CHƯA DEPLOY | Dockerfile sẵn, chưa deploy thật |
| **End-to-End Testing** | ~10% | ❌ CHƯA TEST | Unit tests pass, nhưng E2E chưa chạy |

### 1.2. Kết luận nhanh

**CÓ THỂ SHIP MVP ĐÚNG HẠN** nếu team tập trung vào các blocker chính trong 3 ngày còn lại. Core logic backend mạnh, **frontend UI gần như hoàn chỉnh** (F3-F8 đã xong). Vấn đề chính còn lại: **backend chưa wire Supabase quiz data**, **chưa deploy Cloud Run**, và **chưa test end-to-end**. Frontend chỉ cần bật 2 feature flags khi backend sẵn sàng.

---

## 2. PHÂN TÍCH GAP CHI TIẾT

### 2.1. BACKEND GAPS

#### 🔴 BLOCKER – Phải sửa ngay

| # | Gap | Mô tả | File liên quan | Ước lượng |
|---|-----|-------|---------------|-----------|
| B1 | **Quiz data có trong Supabase nhưng Backend chưa kết nối** | Hưng đã insert quiz data vào bảng `quiz_question_template` trên Supabase (schema có `topic_code`, `payload` với options/correct_answer, `difficulty_level`, `metadata`). Tuy nhiên backend primitives `P01_serve_mcq` và `P04_select_next_question` trong `htn_executor.py` là **stub trả hardcoded mock** (`{"q_id": "q_default"}`, `{"question_id": "q_next"}`), KHÔNG query Supabase. Cần viết logic query `quiz_question_template` từ Supabase cho 2 primitives này. | `backend/agents/academic_agent/htn_executor.py:24-44` | 2-3 giờ |
| B2 | **Knowledge Graph chưa có file/table** | Không có file `knowledge_graph.json` hay table trong Supabase chứa 15 node đồ thị tri thức Đạo hàm với quan hệ prerequisites. Proposal yêu cầu "Knowledge Graph 15 node ~20 cạnh". Backend cấu hình có reference đến KG nhưng data thực chưa tồn tại. | `backend/data/` (thiếu file) | 2 giờ |
| B3 | **EIG (Expected Information Gain) chưa implement** | Quiz selection cần tối đa hóa EIG: `EIG(q) = H(belief) - E[H(belief|answer_q)]`. Primitive `P04_select_next_question` hiện trả stub `{"question_id": "q_next"}`, không tính EIG thực sự. Cần: (1) query pool câu hỏi từ Supabase, (2) tính EIG dựa trên current belief + likelihoods, (3) trả question có EIG cao nhất. | `backend/agents/academic_agent/htn_executor.py:42-44` | 2-3 giờ |

#### ⚠️ PARTIAL – Cần hoàn thiện

| # | Gap | Mô tả | File liên quan | Ước lượng |
|---|-----|-------|---------------|-----------|
| B4 | **HTN Plan Repair thiếu strategy "Skip"** | `_select_repair_strategy()` chỉ trả về `AltMethod` hoặc `InsertTask`. Proposal yêu cầu 3 strategy: Insert, Alternative, Skip. Chưa có logic Skip (bỏ qua task khi mệt mỏi). | `backend/agents/academic_agent/htn_node.py:128-141` | 1 giờ |
| B5 | **Audit Log trả mảng rỗng** | Endpoint `GET /api/v1/inspection/{session_id}/audit-logs` tồn tại nhưng có thể trả `[]` nếu orchestrator chưa ghi audit entry đầy đủ cho mọi quyết định. | `backend/api/routes/inspection.py`, `backend/agents/orchestrator.py` | 1 giờ |
| B6 | **Gemini LLM chưa hoạt động** | `LLMService` depends on `GCP_PROJECT_ID` env var và Vertex AI SDK. Nếu thiếu cấu hình → fallback text cứng. Cần ít nhất test fallback hoạt động smooth. | `backend/core/llm_service.py` | 1 giờ |
| B7 | **WebSocket Dashboard chưa test integration** | WS endpoint `/ws/v1/dashboard/stream/{session_id}` tồn tại nhưng chưa integration test với frontend. | `backend/api/ws/` | 1 giờ |

#### ✅ ĐÃ HOÀN THÀNH

| Thành phần | Chi tiết |
|-----------|---------|
| Bayesian Tracker | 8 hypotheses (H01-H08), priors + likelihoods trong `derivative_priors.json`, entropy calc ✓ |
| Particle Filter | 100 hạt, 4 states (focused/confused/exhausted/frustrated), uncertainty quantification ✓ |
| Q-Learning | α=0.15, γ=0.9, ε-greedy, episodic memory → Supabase ✓ |
| Orchestrator | State aggregation, policy engine, utility comparison, HITL trigger (threshold 0.85) ✓ |
| HTN Planner | Template YAML, compound/primitive tasks, repair với retry limit ✓ |
| FastAPI Endpoints | 11 REST + 2 WS, async, JWT auth ✓ |
| Expert Configs | `derivative_priors.json`, `htn_rules.yaml`, `strategy.yaml`, `orchestrator.yaml` ✓ |
| Unit Tests | ~30 tests pass: Bayesian, PF, Q-Learning, HTN repair, orchestrator ✓ |
| Dockerfile | Multi-stage build, port 8080, Cloud Run ready ✓ |

---

### 2.2. FRONTEND GAPS

#### 🔴 BLOCKER – Phải sửa ngay

| # | Gap | Mô tả | File liên quan | Ước lượng |
|---|-----|-------|---------------|-----------|
| F1 | **Agentic Backend flag TẮT** | `useAgenticBackend = false` trong `main.dart:50`. Toàn bộ code tích hợp agentic (AgenticSessionCubit, WsService, AgenticApiService) không được kích hoạt. **Chờ backend deploy xong mới bật.** | `lib/main.dart:50` | 5 phút |
| F2 | **Mock API đang BẬT** | `useMockApi = true` trong `main.dart:45`. Mọi API call trả mock data, không gọi backend thật. **Chờ backend deploy xong mới tắt.** | `lib/main.dart:45` | 5 phút |

#### ⚠️ PARTIAL – Cần hoàn thiện

| # | Gap | Mô tả | File liên quan | Ước lượng |
|---|-----|-------|---------------|-----------|
| F7 | **Adaptive UI modes chưa đầy đủ** | Recovery mode có, nhưng focused mode vs support mode (chuyển giải thích trực quan) chưa implement rõ. | `lib/features/intervention/` | 2-3 giờ |

#### ✅ ĐÃ HOÀN THÀNH

| Thành phần | Chi tiết |
|-----------|---------|
| 3 màn hình chính | TodayPage (Home), ProgressPage, ProfileScreen ✓ |
| Quiz Display | QuizPage với MCQ + TF Cluster + Short Answer + answer tracking ✓ |
| HITL Popup | Đúng text tiếng Việt theo proposal ✓ |
| Behavioral Signals | Typing speed, correction rate, idle time, 5s batching ✓ |
| WebSocket Service | Behavior + Dashboard channels ✓ |
| Supabase Auth | JWT, login/register/logout, session restore ✓ |
| Agentic Models | Tất cả Dart models từ backend Pydantic schemas ✓ |
| AgenticApiService | 11 endpoints mapped ✓ |
| AgenticSessionCubit | 6 methods, 8 phases, WS subscriptions ✓ |
| Recovery Screen | Breathing animation, countdown timer ✓ |
| Intervention Flow | Bloc + HITL handling + recovery routing ✓ |
| Navigation | GoRouter với 15+ routes ✓ |
| Offline Support | OfflineModeRepository với signal buffering ✓ |
| **~~F3~~ Android Release Signing** | ✅ `build.gradle.kts` cấu hình `signingConfigs` từ `key.properties` (fallback debug nếu thiếu). Template file `android/key.properties.template` đã tạo. `key.properties` đã nằm trong `.gitignore`. |
| **~~F4~~ Plan Tree Visualization** | ✅ `inspection_bottom_sheet.dart` — Timeline-style `_PlanStepRow` widget với status detection (✓=completed xanh lá, →=active xanh primary, pending=gray), dot + connector line, status chip. |
| **~~F5~~ De-Stress Palette Auto-Switch** | ✅ `main.dart` — Tự động chuyển sang `AppColorPalette.mintCream` (pastel teal `#2DAA90`) khi `AgenticPhase.recovery`; khôi phục palette cũ khi hết recovery. |
| **~~F6~~ Haptic Feedback** | ✅ `quiz_page.dart` — `HapticFeedback.selectionClick()` khi chọn MCQ, `.lightImpact()` khi toggle T/F, `.mediumImpact()` khi submit answer. |
| **~~F8~~ Quiz ↔ Agentic Bridge** | ✅ `quiz_page.dart` — `AgenticSessionCubit` obtained via try-catch `didChangeDependencies()`, `startSession()` on quiz load, `submitAnswer()` with `_buildAgenticResponseData()` on each answer, `_onAgenticStateChanged()` routes to recovery. |

---

### 2.3. DỮ LIỆU & NỘI DUNG GAPS

| # | Gap | Mô tả | Ước lượng |
|---|-----|-------|-----------|
| D1 | **~~Quiz Bank (15-20 câu Đạo hàm)~~** | ✅ **ĐÃ CÓ trong Supabase** – Hưng đã insert data vào bảng `quiz_question_template` (topic_code=`derivative`, 3 types: MULTIPLE_CHOICE, TRUE_FALSE_CLUSTER, SHORT_ANSWER). Schema + example CSV + crawl spec đã hoàn chỉnh. **Vấn đề thực sự:** Backend HTN executor cần query Supabase thay vì trả mock. | 0h (data) / 2-3h (wiring) |
| D2 | **Knowledge Graph (15 nodes)** | Cần tạo JSON: nodes (chain_rule, product_rule, trig_deriv, power_exp, notation, second_deriv, concept_understanding, proficient) + edges (prerequisites). | 2 giờ (Hưng) |
| D3 | **Intervention Catalog kiểm tra** | File `intervention_catalog.json` tồn tại – cần verify nội dung phù hợp với 8 hypotheses. | 30 phút |
| D4 | **Diagnosis Scenarios kiểm tra** | File `diagnosis_scenarios.json` tồn tại – cần verify format và coverage. | 30 phút |
| D5 | **Quiz metadata thiếu `error_pattern` mapping** | Câu hỏi trong Supabase có `payload.options` nhưng cần kiểm tra xem mỗi option sai có field `error_pattern` (map đến E_MISSING_INNER, E_WRONG_OPERATOR, etc. trong `derivative_priors.json`) hay chưa. Nếu thiếu, cần bổ sung vào `metadata` hoặc `payload` để Bayesian tracker nhận evidence đúng. | 1-2 giờ (Hưng) |

---

### 2.4. DEPLOYMENT & TESTING GAPS

| # | Gap | Mô tả | Ước lượng |
|---|-----|-------|-----------|
| T1 | **Chưa deploy Backend lên Cloud Run** | Dockerfile sẵn nhưng chưa deploy. Cần GCP project + Supabase credentials. | 1-2 giờ |
| T2 | **Chưa test E2E trên thiết bị thật** | Cần: Login → Quiz → Bayesian update → HTN step → Empathy check → HITL → Recovery → Session complete. | 2-3 giờ |
| T3 | **Chưa test p95 latency < 4.5s** | Acceptance criteria yêu cầu p95 < 4.5s. Cần chạy ≥10 sessions liên tiếp. | 1 giờ |
| T4 | **Chưa quay video demo dự phòng** | Proposal yêu cầu "Video demo dự phòng cho 4 kịch bản Agentic". | 2-3 giờ |
| T5 | **Inspection Dashboard (Streamlit) chưa có** | Proposal mention Streamlit dashboard riêng cho BGK. Frontend có bottom sheet nhưng Streamlit chưa tồn tại. | 4-6 giờ (hoặc dùng Flutter bottom sheet thay thế) |

---

## 3. MA TRẬN ƯU TIÊN

### 3.1. Phân loại theo MoSCoW và Impact/Effort

| Ưu tiên | Task | Impact | Effort | Deadline |
|---------|------|--------|--------|----------|
| 🔴 P0 | B1: Wire HTN → Supabase quiz | BLOCKER | 2-3h | 14/04 |
| 🔴 P0 | B2: Knowledge Graph data | BLOCKER | 2h | 14/04 |
| 🔴 P0 | B3: EIG implementation | BLOCKER | 2-3h | 15/04 |
| 🔴 P0 | F1+F2: Bật feature flags (chờ BE deploy) | BLOCKER | 5 phút | 15/04 |
| ✅ DONE | ~~F3: Android signing~~ | — | — | ✅ 14/04 |
| 🔴 P0 | T1: Deploy Cloud Run | BLOCKER | 1-2h | 15/04 |
| 🔴 P0 | T2: E2E test trên device | BLOCKER | 2-3h | 16/04 |
| 🟡 P1 | B4: HTN Skip strategy | SHOULD | 1h | 15/04 |
| 🟡 P1 | B5: Audit log đầy đủ | SHOULD | 1h | 15/04 |
| ✅ DONE | ~~F8: Quiz ↔ Agentic bridge~~ | — | — | ✅ 14/04 |
| ✅ DONE | ~~F4: Plan Tree visualization~~ | — | — | ✅ 14/04 |
| 🟡 P1 | T4: Quay video demo | MUST | 2-3h | 16/04 |
| ✅ DONE | ~~F5: De-Stress palette auto-switch~~ | — | — | ✅ 14/04 |
| ✅ DONE | ~~F6: Haptic feedback~~ | — | — | ✅ 14/04 |
| 🟢 P2 | B6: Gemini LLM test | SHOULD | 1h | 16/04 |
| 🟢 P2 | T5: Streamlit Dashboard | COULD | 4-6h | Bỏ nếu hết thời gian |
| ⚪ P3 | F7: Adaptive UI modes | COULD | 2-3h | Post-MVP |

---

## 4. KẾ HOẠCH HÀNH ĐỘNG 3 NGÀY

### NGÀY 1: 14/04/2026 (Hôm nay) – DATA & CORE FIXES

**Mục tiêu:** Hoàn thành tất cả data gaps + backend core fixes. Đến cuối ngày backend phải chạy E2E cơ bản với data thật.

#### Buổi sáng (4 tiếng)

| Thời gian | Task | Người | Deliverable |
|-----------|------|-------|-----------|
| 08:00-10:00 | **[B1] Wire HTN primitives → Supabase quiz data** – Thay stub `_serve_mcq()` và `_select_next_question()` trong `htn_executor.py` bằng logic thực: query `quiz_question_template` từ Supabase (filter `topic_code='derivative'`, `is_active=true`), trả câu hỏi với đầy đủ payload (options, correct_answer, hint). | Đức | P01 + P04 query Supabase thật |
| 08:00-10:00 | **[D5] Bổ sung error_pattern cho quiz options** – Kiểm tra data quiz hiện tại trong Supabase. Mỗi option sai cần có `error_pattern` mapping đến evidence type trong `derivative_priors.json` (E_MISSING_INNER, E_WRONG_OPERATOR, etc.). Nếu thiếu → update payload/metadata. | Hưng | Options có error_pattern mapping |
| 10:00-12:00 | **[B3] Implement EIG** – Trong `_select_next_question()`, sau khi load quiz pool từ Supabase: (1) Lấy current `belief` từ context, (2) Cho mỗi question q, tính EIG(q) = H(current_belief) - Σ_outcomes P(outcome) × H(posterior(outcome)), (3) Trả question có EIG cao nhất. Cần import `derivative_priors.json` likelihoods. | Khang | EIG selection hoạt động |
| 08:00-10:00 | **[B2] Tạo Knowledge Graph** – 15 nodes Đạo hàm: `chain_rule`, `product_rule`, `quotient_rule`, `trig_deriv`, `power_rule`, `exp_rule`, `log_rule`, `implicit_deriv`, `higher_order`, `notation`, `limit_concept`, `continuity`, `derivative_definition`, `application_tangent`, `application_extrema`. Mỗi node có: `id`, `name_vi`, `description`, `prerequisites[]`, `related_hypotheses[]`. | Hưng | `backend/data/knowledge_graph.json` |

#### Buổi chiều (4 tiếng)

| Thời gian | Task | Người | Deliverable |
|-----------|------|-------|-----------|
| 13:00-14:00 | **[B4] Thêm Skip strategy** – Trong `_select_repair_strategy()`, thêm logic: nếu `context.get("empathy_state", {}).get("dominant") == "exhausted"` → return `"SkipTask"`. Trong `_apply_repair()`, thêm case SkipTask: mark current as skipped, advance to next. | Đức | Skip repair hoạt động |
| 14:00-15:00 | **[B5] Audit Log đầy đủ** – Verify orchestrator ghi audit entry cho mọi decision (diagnose, remediate, recover, encourage, hitl). Đảm bảo `inspection/audit-logs` endpoint trả data thực. | Đức | Audit logs populated |
| 15:00-17:00 | **[B3 cont.] Test EIG + Quiz flow** – Test luồng: create session → interact (answer wrong, error_pattern từ Supabase quiz option) → Bayesian update → P04 chọn question mới dựa EIG → verify belief evolution. | Khang | Unit test pass |
| 15:00-17:00 | **[D3+D4] Verify intervention & diagnosis data** – Kiểm tra `intervention_catalog.json` và `diagnosis_scenarios.json` khớp với 8 hypotheses. Sửa nếu cần. | Hưng | Data verified |

#### Buổi tối (nếu cần)

| Thời gian | Task | Người | Deliverable |
|-----------|------|-------|-----------|
| 19:00-21:00 | **[T1] Deploy Backend lên Cloud Run** – `gcloud run deploy`, set env vars (SUPABASE_URL, SUPABASE_KEY, GCP_PROJECT_ID). Test health endpoint. | Đức | Backend live trên Cloud Run |

---

### NGÀY 2: 15/04/2026 – TÍCH HỢP & E2E

**Mục tiêu:** Backend deploy xong → Frontend bật flags kết nối thật → chạy E2E trên thiết bị, fix bugs.

> **LƯU Ý:** Các task FE trước đây dự kiến cho ngày 2-3 (F3, F4, F5, F6, F8) đã hoàn thành ngày 14/04. Huy rảnh tay để hỗ trợ integration + E2E testing.

#### Buổi sáng (4 tiếng)

| Thời gian | Task | Người | Deliverable |
|-----------|------|-------|-----------|
| 08:00-08:30 | **[F1+F2] Bật feature flags** – `useAgenticBackend = true`, `useMockApi = false` trong `main.dart`. Cập nhật `ApiConfig.baseUrl` trỏ đến Cloud Run URL. *(Chỉ bật khi T1 deploy xong)* | Huy | Flags bật |
| 08:00-10:00 | **[B6] Test Gemini LLM fallback** – Verify rằng khi thiếu GCP credentials, backend vẫn trả fallback text hợp lý (không crash). Test cả trường hợp có Vertex AI hoạt động. | Khang | LLM fallback smooth |
| 08:30-12:00 | **[B7] Test WebSocket integration** – Kết nối Flutter WS → Backend WS. Verify: behavior signals đến backend, dashboard updates đến frontend. | Khang + Huy | WS hoạt động 2 chiều |
| 10:00-12:00 | **Smoke test agentic flow trên emulator** – Sau khi bật flags: startSession → submitAnswer → verify AgenticSessionCubit receives state updates → Inspection bottom sheet shows real data. | Huy | Agentic flow hoạt động |

#### Buổi chiều (4 tiếng)

| Thời gian | Task | Người | Deliverable |
|-----------|------|-------|-----------|
| 13:00-17:00 | **[T2] E2E Test trên thiết bị thật** – Build APK debug, install trên Android. Chạy full flow: Đăng nhập → Home → Bắt đầu Quiz → Trả lời 3-5 câu → Bayesian belief update (kiểm tra Inspection) → Empathy detect fatigue → HITL popup → Recovery → Session complete. Fix mọi bugs gặp phải. | **Toàn team** | E2E chạy thông |
| 14:00-15:00 | **[T3] Test p95 latency** – Chạy 10 sessions liên tiếp, đo thời gian phản hồi mỗi orchestrator step. Target: p95 < 4.5s. | Đức | Latency đạt yêu cầu |

#### Buổi tối

| Thời gian | Task | Người | Deliverable |
|-----------|------|-------|-----------|
| 19:00-21:00 | **Fix bugs từ E2E test** | Toàn team | Bugs fixed |

---

### NGÀY 3: 16/04/2026 – POLISH, VIDEO & SUBMISSION

**Mục tiêu:** Fix remaining bugs, quay video demo, dry-run, build APK final.

> **LƯU Ý:** F3 (Android signing), F6 (Haptic) đã hoàn thành. Chỉ cần tạo keystore thật + `flutter build apk --release`.

#### Buổi sáng (4 tiếng)

| Thời gian | Task | Người | Deliverable |
|-----------|------|-------|-----------|
| 08:00-10:00 | **Fix tất cả bugs còn lại** – Từ E2E test hôm qua. Ưu tiên: crash bugs > UX bugs > visual bugs. | Toàn team | Zero crash bugs |
| 08:00-09:00 | **Tạo keystore + build APK release** – `keytool -genkey ...`, copy vào `android/key.properties` (đã có template), `flutter build apk --release`. Signing config đã sẵn trong `build.gradle.kts`. | Huy | APK signed |
| 10:00-12:00 | **[T4] Quay video demo dự phòng** – 4 kịch bản: (1) Bayesian diagnosis hội tụ đúng "hổng Chain Rule", (2) HTN plan repair khi unexpected answer, (3) Particle Filter phát hiện kiệt sức → Recovery, (4) Q-Learning thay đổi strategy sau reward. Mỗi kịch bản ghi cả app + inspection dashboard. | Hưng + Huy | 4 video sẵn sàng |

#### Buổi chiều (4 tiếng)

| Thời gian | Task | Người | Deliverable |
|-----------|------|-------|-----------|
| 13:00-14:00 | **Dry-run demo nội bộ lần 1** – Chạy full demo trước team, tìm issues. | Toàn team | Issues identified |
| 14:00-15:00 | **Fix issues từ dry-run** | Toàn team | Issues resolved |
| 15:00-16:00 | **Dry-run demo nội bộ lần 2** – Verify fixes, time demo. | Toàn team | Demo smooth |
| 16:00-17:00 | **Build APK v1 final** – `flutter build apk --release`. Test install trên device. Verify không crash. | Huy | APK v1 stable |

#### Buổi tối

| Thời gian | Task | Người | Deliverable |
|-----------|------|-------|-----------|
| 19:00-21:00 | **Chuẩn bị submission** – Kiểm tra checklist: APK ✓, Video ✓, Proposal ✓, Source code ✓. | Toàn team | Ready to submit |

---

### NGÀY 4: 17/04/2026 – SUBMISSION

| Thời gian | Task | Người | Deliverable |
|-----------|------|-------|-----------|
| 08:00-09:00 | Dry-run cuối cùng | Toàn team | Pass |
| 09:00-10:00 | Fix nếu phát sinh | Toàn team | Clean |
| 10:00-12:00 | **Submit** – APK, video, proposal, source code | Toàn team | ✅ Submitted |

---

## 5. CHI TIẾT KỸ THUẬT CHO CÁC TASK QUAN TRỌNG

### 5.1. [B1] Quiz Data – Thực trạng & Cần wire

**✅ Data đã có trong Supabase** (`quiz_question_template`):
- Hưng đã insert quiz data theo schema chuẩn
- 3 question types: `MULTIPLE_CHOICE` (part_no=1), `TRUE_FALSE_CLUSTER` (part_no=2), `SHORT_ANSWER` (part_no=3)  
- `topic_code = 'derivative'`, `difficulty_level` 1-5
- `payload` chứa options/correct_answer/explanation
- Frontend `QuizRepository` đã query thành công từ Supabase

**❌ Backend HTN executor KHÔNG query Supabase** – Đây là gap thực sự:
```python
# htn_executor.py hiện tại (STUB):
async def _serve_mcq(ctx):
    return {"status": "success", "payload": {"q_id": "q_default"}}  # ← hardcoded!

async def _select_next_question(ctx):
    return {"status": "success", "payload": {"question_id": "q_next"}}  # ← hardcoded!
```

**Cần sửa thành:**
```python
async def _serve_mcq(ctx):
    """Query quiz_question_template từ Supabase, trả câu hỏi cho student."""
    question_id = ctx.get("question_id")
    supabase = ctx.get("supabase_client")
    result = await supabase.table("quiz_question_template") \
        .select("*") \
        .eq("id", question_id) \
        .single() \
        .execute()
    return {"status": "success", "payload": result.data}

async def _select_next_question(ctx):
    """Query pool → tính EIG → chọn question tốt nhất."""
    supabase = ctx.get("supabase_client")
    belief = ctx.get("belief_state", {})
    pool = await supabase.table("quiz_question_template") \
        .select("*") \
        .eq("topic_code", "derivative") \
        .eq("is_active", True) \
        .execute()
    # Tính EIG cho mỗi câu → chọn max
    best_q = select_by_eig(pool.data, belief, likelihoods)
    return {"status": "success", "payload": {"question_id": best_q["id"]}}
```

**⚠️ Cần kiểm tra thêm:** Mỗi quiz option sai cần có `error_pattern` mapping (E_MISSING_INNER, E_WRONG_OPERATOR, etc.) để Bayesian tracker nhận evidence. Kiểm tra `payload.options` trong Supabase xem đã có field này chưa.

### 5.2. [B2] Knowledge Graph Format

```json
{
  "nodes": [
    {
      "id": "chain_rule",
      "name_vi": "Quy tắc chuỗi (Đạo hàm hàm hợp)",
      "description": "Đạo hàm của hàm hợp f(g(x)) = f'(g(x))·g'(x)",
      "related_hypotheses": ["H01_Chain"],
      "difficulty_weight": 0.8
    }
  ],
  "edges": [
    {
      "from": "derivative_definition",
      "to": "chain_rule",
      "type": "prerequisite"
    }
  ]
}
```

### 5.3. [B3] EIG Implementation Pseudocode

```python
def select_question_by_eig(current_belief, quiz_pool, likelihoods):
    current_entropy = compute_entropy(current_belief)
    best_q, best_eig = None, -1
    
    for q in quiz_pool:
        expected_posterior_entropy = 0
        for option in q["options"]:
            error_pattern = option["error_pattern"]
            # P(outcome) = Σ P(E|H) × P(H)
            p_outcome = sum(
                likelihoods[error_pattern][h] * current_belief[h]
                for h in current_belief
            )
            # Posterior if this outcome observed
            posterior = bayesian_update(current_belief, error_pattern, likelihoods)
            expected_posterior_entropy += p_outcome * compute_entropy(posterior)
        
        eig = current_entropy - expected_posterior_entropy
        if eig > best_eig:
            best_eig = eig
            best_q = q
    
    return best_q
```

### 5.4. [F8] Quiz ↔ Agentic Session Bridge — ✅ ĐÃ IMPLEMENT

**Đã hoàn thành trong `quiz_page.dart`:**
```dart
// _QuizPageState — đã implement:
AgenticSessionCubit? _agenticCubit;
StreamSubscription<AgenticSessionState>? _agenticSub;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (_agenticCubit == null) {
    try {
      _agenticCubit = context.read<AgenticSessionCubit>();
      _agenticSub = _agenticCubit!.stream.listen(_onAgenticStateChanged);
    } catch (_) { _agenticCubit = null; }
  }
}

// Trong _loadQuestionsAndInit():
unawaited(_agenticCubit?.startSession(subject: 'math', topic: 'derivative'));

// Trong _submitCurrentAnswer():
if (_agenticCubit != null) {
  unawaited(_agenticCubit!.submitAnswer(
    questionId: _activeQuestion!.id,
    responseData: _buildAgenticResponseData(userAnswer),
  ));
}

// _onAgenticStateChanged → routes to recovery when state.isRecovery
// _buildAgenticResponseData → maps MCQ/TF/SA answers to Map<String,dynamic>
```

---

## 6. QUYẾT ĐỊNH CHIẾN LƯỢC

### 6.1. Streamlit Dashboard: BỎ hay LÀM?

**Đề xuất: BỎ Streamlit, dùng Flutter Inspection Bottom Sheet thay thế.**

Lý do:
- Flutter bottom sheet đã có ~95% (belief, Q-values, decision log, **Plan Tree timeline**)
- ~~Chỉ cần thêm Plan Tree visualization (2-3 giờ)~~ → **ĐÃ LÀM XONG**
- Tiết kiệm 4-6 giờ so với build Streamlit mới
- Demo trên cùng app, không cần switch giữa 2 ứng dụng
- Khi BGK hỏi → mở inspection sheet ngay trên app = ấn tượng hơn

### 6.2. Gemini LLM: BẮT BUỘC hay OPTIONAL?

**Đề xuất: OPTIONAL cho MVP, dùng fallback text.**

Lý do:
- Core value của GrowMate là cơ chế Agentic (Bayesian, PF, HTN, RL), KHÔNG phải LLM
- Fallback text trong `llm_service.py` đã đủ cho demo
- Nếu Vertex AI setup không kịp → vẫn demo được
- Cấu hình Vertex AI chỉ cần nếu muốn sinh nội dung giải thích tự nhiên hơn

### 6.3. Pastel Colors / De-Stress Palette: ~~BÂY GIỜ hay SAU?~~

**✅ ĐÃ LÀM — Auto-switch mintCream palette khi recovery.**

- `main.dart` tự động chuyển sang `AppColorPalette.mintCream` (primary `#2DAA90`, soft teal) khi `AgenticPhase.recovery` → khôi phục palette cũ khi kết thúc.
- Palette `mintCream` đã có sẵn trong `app_theme.dart` với đầy đủ ColorScheme (primaryContainer `#DDF7EF`, secondaryContainer `#E8F6F6`).
- Nếu muốn đổi default palette toàn app (không chỉ recovery) → sửa `AppColorPalette` default trong `color_palette_cubit.dart` (~5 phút, post-MVP).

---

## 7. CHECKLIST NGHIỆM THU MVP

### 7.1. Tiêu chí bắt buộc (từ Proposal Section 8.3.1)

- [ ] **Bayesian update hoạt động:** Belief distribution thay đổi khi nhận evidence → verify qua Inspection Dashboard
- [ ] **HTN repair hoạt động:** Khi unexpected answer → plan repair cục bộ (không xóa plan) → verify qua Dashboard
- [ ] **Particle Filter hoạt động:** Trạng thái tinh thần ước lượng từ tín hiệu → uncertainty quantification → verify qua Dashboard
- [ ] **Q-Learning hoạt động:** Q-values cập nhật sau mỗi session → verify qua Dashboard
- [ ] **p95 latency < 4.5s:** Test 10 sessions → đo thời gian phản hồi
- [ ] **Không crash 10 sessions liên tiếp:** 10 sessions chạy ổn định
- [ ] **Inspection Dashboard realtime:** Trạng thái nội bộ khớp với log hệ thống
- [x] **Inspection Plan Tree:** Timeline visualization với status detection (completed/active/pending) ✓
- [ ] **APK chạy ổn định:** Install + chạy trên thiết bị Android thật

### 7.2. Checklist submission

- [x] APK Android signing config sẵn sàng (chỉ cần tạo keystore + build) ✓
- [ ] Video demo dự phòng (4 kịch bản Agentic)
- [ ] Proposal document (đã có)
- [ ] Source code (GitHub repo)
- [ ] Báo cáo kỹ thuật MVP

### 7.3. Frontend checklist (Huy)

- [x] F3: Android Release Signing (`build.gradle.kts` + `key.properties.template`) ✓
- [x] F4: Plan Tree Visualization (`inspection_bottom_sheet.dart`) ✓
- [x] F5: De-Stress Palette Auto-Switch (`main.dart` → mintCream on recovery) ✓
- [x] F6: Haptic Feedback (`quiz_page.dart` → selectionClick/lightImpact/mediumImpact) ✓
- [x] F8: Quiz ↔ Agentic Session Bridge (`quiz_page.dart` → didChangeDependencies/startSession/submitAnswer) ✓
- [ ] F1+F2: Bật feature flags (chờ backend deploy)
- [ ] F7: Adaptive UI modes (Post-MVP)

---

## 8. RỦI RO VÀ CONTINGENCY

| Rủi ro | Xác suất | Contingency |
|--------|---------|-------------|
| Cloud Run deploy fail | Trung bình | Chạy backend local + ngrok tunnel |
| Supabase rate limit | Thấp | Mock data cho demo cụ thể |
| Gemini API không kịp setup | Cao | Dùng fallback text (đã có) |
| E2E có bug nghiêm trọng | Trung bình | Video demo dự phòng (quay trước) |
| Latency > 4.5s | Trung bình | Giảm particle count (100→50), cache quiz pool |
| Android signing issues | Thấp | Submit debug APK + ghi chú |

---

## 9. TÓM TẮT

### Phải làm ngay hôm nay (14/04):
1. 🔴 **Đức:** Wire `P01_serve_mcq` + `P04_select_next_question` → query Supabase `quiz_question_template` (thay stub)
2. 🔴 **Hưng:** Verify quiz options có `error_pattern` mapping + Tạo `knowledge_graph.json` (15 nodes)
3. 🔴 **Khang:** Implement EIG quiz selection (dùng quiz từ Supabase + belief + likelihoods)
4. 🔴 **Đức:** Thêm Skip repair strategy + Audit log + Deploy backend lên Cloud Run

### Phải làm ngày 15/04:
5. 🔴 **Huy:** Bật feature flags (chờ BE deploy) — ~~bridge Quiz ↔ Agentic~~ ✅ đã xong
6. ~~🟡 **Huy:** Plan Tree visualization~~ ✅ đã xong 14/04
7. 🟡 **Khang+Huy:** Test WebSocket integration
8. 🔴 **Toàn team:** E2E test trên thiết bị

### Phải làm ngày 16/04:
9. ~~🔴 **Huy:** Android signing~~ ✅ đã xong 14/04 — Chỉ cần tạo keystore + `flutter build apk --release`
10. 🔴 **Hưng+Huy:** Quay 4 video demo
11. 🔴 **Toàn team:** Dry-run 2 lần + fix bugs

### Ngày 17/04:
12. ✅ **Submit**

---

> **Bottom line (cập nhật 14/04 chiều):** Core engine backend mạnh (~30 unit tests pass, 4 cơ chế Agentic). **Frontend gần như hoàn chỉnh** — F3 (signing), F4 (Plan Tree), F5 (De-Stress palette), F6 (Haptic), F8 (Quiz↔Agentic bridge) đều đã xong. Huy rảnh tay ngày 15-16 để tập trung **integration testing + E2E + video demo**. Vấn đề chính còn lại: **backend chưa wire Supabase quiz** (B1/B3), **chưa deploy Cloud Run** (T1), và **chưa test E2E** (T2).
