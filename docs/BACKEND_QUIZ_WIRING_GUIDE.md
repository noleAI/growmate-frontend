# HƯỚNG DẪN: Wire Backend ↔ Supabase Quiz Data
## GrowMate – Cho Đức, Khang, Hưng
**Ngày:** 14/04/2026 | **Ưu tiên:** 🔴 BLOCKER cho MVP

---

## 0. TL;DR — AI CẦN LÀM GÌ?

| Người | File | Việc cần làm | Ước lượng |
|-------|------|-------------|-----------|
| **Đức** | `htn_executor.py` | Thay 2 stub `_serve_mcq` + `_select_next_question` bằng query Supabase thật | 2-3h |
| **Đức** | `htn_node.py` | Thêm `SkipTask` repair strategy | 1h |
| **Khang** | `bayesian_tracker.py` | Thêm logic map `error_pattern` từ quiz option → evidence type | 1h |
| **Khang** | `htn_executor.py` | Implement EIG trong `_select_next_question` | 2-3h |
| **Hưng** | Supabase data | Thêm `error_pattern` cho mỗi option sai trong `payload.options` | 1-2h |
| **Hưng** | `backend/data/` | Tạo `knowledge_graph.json` (15 nodes, ~20 edges) | 2h |

---

## 1. HIỆN TRẠNG: Stub trong `htn_executor.py`

File: `backend/agents/academic_agent/htn_executor.py`

12 primitives đều là **stub trả hardcoded**. Hai cái cần sửa ngay:

```python
# ❌ HIỆN TẠI — STUB:
async def _serve_mcq(ctx: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "status": "success",
        "payload": {"q_id": ctx.get("question_id", "q_default")},  # ← hardcoded!
    }

async def _select_next_question(ctx: Dict[str, Any]) -> Dict[str, Any]:
    return {"status": "success", "payload": {"question_id": "q_next"}}  # ← hardcoded!
```

---

## 2. SUPABASE SCHEMA: `quiz_question_template`

> Frontend (Hưng) đã insert data thành công. Backend cần query cùng table.

```sql
create table public.quiz_question_template (
  id              uuid primary key default gen_random_uuid(),
  subject         text not null default 'math',
  topic_code      text,                    -- 'derivative'
  topic_name      text,
  exam_year       integer not null default 2026,
  question_type   text not null,           -- 'MULTIPLE_CHOICE' | 'TRUE_FALSE_CLUSTER' | 'SHORT_ANSWER'
  part_no         smallint not null,       -- 1=MCQ, 2=TF, 3=SA
  difficulty_level integer not null default 2,  -- 1-5
  content         text not null,           -- Nội dung câu hỏi (có thể chứa LaTeX)
  media_url       text,
  payload         jsonb not null,          -- ⬇️ Xem cấu trúc bên dưới
  metadata        jsonb not null default '{}',
  is_active       boolean not null default true,
  created_at      timestamptz
);
```

### Cấu trúc `payload` cho MCQ:
```json
{
  "options": [
    {
      "id": "A",
      "content": "f'(x) = 2x·cos(x²)",
      "is_correct": true
    },
    {
      "id": "B",
      "content": "f'(x) = cos(x²)",
      "is_correct": false,
      "error_pattern": "E_MISSING_INNER"    // ← Hưng cần thêm field này!
    },
    {
      "id": "C",
      "content": "f'(x) = -sin(x²)",
      "is_correct": false,
      "error_pattern": "E_WRONG_TRIG_FORMULA"
    },
    {
      "id": "D",
      "content": "f'(x) = 2x·sin(x²)",
      "is_correct": false,
      "error_pattern": "E_WRONG_SIGN"
    }
  ],
  "correct_option_id": "A",
  "explanation": "Áp dụng chain rule: d/dx[sin(x²)] = cos(x²)·2x",
  "hint": "Hãy xem lại quy tắc đạo hàm hàm hợp."
}
```

---

## 3. EVIDENCE TYPES (đã có trong `derivative_priors.json`)

9 loại evidence cho `answer_pattern`:

| Evidence | Mapping hypothesis | Ý nghĩa |
|----------|-------------------|----------|
| `E_MISSING_INNER` | H01_Chain (0.55) | Quên đạo hàm hàm trong (chain rule) |
| `E_WRONG_OPERATOR` | H02_ProdQuot (0.52) | Sai phép toán tích/thương |
| `E_WRONG_TRIG_FORMULA` | H03_Trig (0.58) | Sai công thức lượng giác |
| `E_WRONG_POWER_EXP` | H04_PowerExp (0.54) | Sai quy tắc lũy thừa/mũ |
| `E_WRONG_SIGN` | H05_Notation (0.48) | Sai dấu / ký hiệu |
| `E_CASCADE_ERROR` | H06_SecondDeriv (0.58) | Lỗi lan truyền (đạo hàm cấp 2) |
| `E_CONCEPTUAL_MISMATCH` | H07_Concept (0.42) | Hiểu sai khái niệm đạo hàm |
| `E_AMBIGUOUS_ERROR` | (phân bố đều) | Không rõ lỗi gì |
| `E_CORRECT` | H08_Proficient (0.92) | Trả lời đúng |

Thêm 3 loại evidence khác: `hint_used`, `slow_response`, `skip_question`.

---

## 4. ĐỨC: Sửa `htn_executor.py`

### 4.1. Thêm imports

```python
import asyncio
from core.supabase_client import get_supabase_client
```

### 4.2. Thay `_serve_mcq`

```python
async def _serve_mcq(ctx: Dict[str, Any]) -> Dict[str, Any]:
    """Serve a quiz question from Supabase by ID, or a random one for the topic."""
    question_id = ctx.get("question_id")
    topic_code = ctx.get("topic_code", "derivative")

    client = get_supabase_client()

    if question_id:
        # Serve specific question
        response = await asyncio.to_thread(
            lambda: client.table("quiz_question_template")
            .select("*")
            .eq("id", question_id)
            .eq("is_active", True)
            .single()
            .execute()
        )
    else:
        # Serve first available question for topic
        response = await asyncio.to_thread(
            lambda: client.table("quiz_question_template")
            .select("*")
            .eq("topic_code", topic_code)
            .eq("is_active", True)
            .order("difficulty_level")
            .limit(1)
            .execute()
        )

    data = getattr(response, "data", None)
    if not data:
        return {"status": "failed", "error": "No question found"}

    question = data if isinstance(data, dict) else data[0]
    return {
        "status": "success",
        "payload": {
            "q_id": question["id"],
            "content": question["content"],
            "question_type": question["question_type"],
            "difficulty_level": question["difficulty_level"],
            "payload": question["payload"],
            "metadata": question.get("metadata", {}),
        },
    }
```

### 4.3. Thay `_select_next_question` (Đức khung, Khang EIG)

```python
async def _select_next_question(ctx: Dict[str, Any]) -> Dict[str, Any]:
    """Select next question using EIG (Expected Information Gain)."""
    topic_code = ctx.get("topic_code", "derivative")
    answered_ids = ctx.get("answered_question_ids", [])
    belief_state = ctx.get("belief_state", {})

    client = get_supabase_client()

    # 1. Query pool of unanswered questions
    query = (
        client.table("quiz_question_template")
        .select("id, content, question_type, difficulty_level, payload, metadata")
        .eq("topic_code", topic_code)
        .eq("is_active", True)
    )
    response = await asyncio.to_thread(lambda: query.execute())

    pool = getattr(response, "data", []) or []
    # Filter out already-answered
    pool = [q for q in pool if q["id"] not in answered_ids]

    if not pool:
        return {"status": "success", "payload": {"question_id": None, "pool_exhausted": True}}

    # 2. EIG selection (Khang implement — xem Section 5)
    if belief_state:
        best_q = _select_by_eig(pool, belief_state)
    else:
        # Fallback: chọn câu difficulty thấp nhất
        best_q = min(pool, key=lambda q: q.get("difficulty_level", 5))

    return {
        "status": "success",
        "payload": {
            "question_id": best_q["id"],
            "question_type": best_q["question_type"],
            "difficulty_level": best_q["difficulty_level"],
        },
    }
```

### 4.4. Context cần được bổ sung

Hiện `ctx` được pass từ `execute_primitive(task_id, context)`. Orchestrator/HTN Planner cần inject thêm vào context:
- `belief_state`: current Bayesian beliefs dict `{H01_Chain: 0.22, ...}`
- `answered_question_ids`: list các question IDs đã trả lời
- `topic_code`: `"derivative"`
- `empathy_state`: cho SkipTask repair

Kiểm tra file `htn_planner.py` để xem `context` được build ở đâu trước khi gọi `execute_primitive()`.

---

## 5. KHANG: Implement EIG trong `htn_executor.py`

Thêm function `_select_by_eig` vào `htn_executor.py`:

```python
import json
import math
import os

# Load likelihoods once at module level
_LIKELIHOODS = {}
try:
    _priors_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
        "data", "derivative_priors.json"
    )
    with open(_priors_path, "r", encoding="utf-8") as f:
        _config = json.load(f)
    _LIKELIHOODS = _config.get("likelihoods", {}).get("answer_pattern", {})
except FileNotFoundError:
    pass


def _compute_entropy(belief: dict) -> float:
    """Shannon entropy of belief distribution."""
    return -sum(p * math.log(p) for p in belief.values() if p > 0)


def _bayesian_posterior(belief: dict, evidence: str) -> dict:
    """Compute posterior after observing evidence."""
    likelihoods = _LIKELIHOODS.get(evidence, {})
    if not likelihoods:
        return belief

    unnormalized = {h: belief.get(h, 0) * likelihoods.get(h, 0) for h in belief}
    total = sum(unnormalized.values())
    if total <= 0:
        return belief
    return {h: v / total for h, v in unnormalized.items()}


def _select_by_eig(pool: list, belief: dict) -> dict:
    """
    Select question maximizing Expected Information Gain (EIG).
    
    EIG(q) = H(current_belief) - Σ_outcomes P(outcome) × H(posterior(outcome))
    
    Mỗi option sai có error_pattern → dùng làm possible outcome.
    Option đúng → E_CORRECT.
    """
    current_entropy = _compute_entropy(belief)
    best_q, best_eig = pool[0], -1.0

    for q in pool:
        options = q.get("payload", {}).get("options", [])
        if not options:
            continue

        expected_posterior_entropy = 0.0
        valid_outcomes = 0

        for option in options:
            if option.get("is_correct", False):
                evidence = "E_CORRECT"
            else:
                evidence = option.get("error_pattern", "E_AMBIGUOUS_ERROR")

            if evidence not in _LIKELIHOODS:
                continue

            # P(outcome) = Σ P(E|H) × P(H)
            p_outcome = sum(
                _LIKELIHOODS[evidence].get(h, 0) * belief.get(h, 0)
                for h in belief
            )
            if p_outcome <= 0:
                continue

            posterior = _bayesian_posterior(belief, evidence)
            expected_posterior_entropy += p_outcome * _compute_entropy(posterior)
            valid_outcomes += 1

        if valid_outcomes > 0:
            eig = current_entropy - expected_posterior_entropy
            if eig > best_eig:
                best_eig = eig
                best_q = q

    return best_q
```

---

## 6. KHANG: Update `bayesian_tracker.py`

File: `backend/agents/academic_agent/bayesian_tracker.py`

### Hiện tại (line 32-35):
```python
async def process(self, input_data: AgentInput) -> AgentOutput:
    if input_data.user_response:
        evidence = input_data.user_response.get("evidence", "E_CORRECT")
        self.update_evidence("answer_pattern", evidence)
```

### Cần sửa thành:
```python
async def process(self, input_data: AgentInput) -> AgentOutput:
    if input_data.user_response:
        # Ưu tiên evidence đã được xác định sẵn
        evidence = input_data.user_response.get("evidence")

        if not evidence:
            # Auto-detect evidence từ quiz answer:
            # Frontend gửi selected_option + question payload
            selected = input_data.user_response.get("selected_option")
            options = input_data.user_response.get("options", [])
            
            if selected and options:
                chosen = next((o for o in options if o.get("id") == selected), None)
                if chosen:
                    if chosen.get("is_correct", False):
                        evidence = "E_CORRECT"
                    else:
                        evidence = chosen.get("error_pattern", "E_AMBIGUOUS_ERROR")
            
            if not evidence:
                evidence = "E_CORRECT"

        self.update_evidence("answer_pattern", evidence)

    return AgentOutput(
        action="belief_updated",
        payload={"belief_dist": self.beliefs},
        confidence=1.0 - self.get_entropy(),
    )
```

### Giải thích flow:

```
Frontend: submitAnswer(questionId, {selected_option: "B"})
    ↓
API: POST /step {response: {selected_option: "B", options: [...]}}
    ↓
Orchestrator → AgentInput(user_response={selected_option: "B", options: [...]})
    ↓
BayesianTracker.process() → tìm option B → lấy error_pattern → update beliefs
```

**⚠️ Quan trọng:** Orchestrator (`orchestrator.py` line 73) tạo `AgentInput` với `user_response=payload.get("response")`. Nên **`response` payload cần chứa cả `options`** (quiz options kèm `error_pattern`). Hai cách:

1. **Frontend gửi kèm options** khi submitAnswer (dễ nhất — Huy đã có quiz data trong memory)
2. **Backend query lại question** trong orchestrator trước khi tạo AgentInput (cleaner, nhưng thêm 1 Supabase call)

→ **Đề xuất:** Backend query lại question payload trong `run_session_step()` (vì question_id đã có trong payload):

```python
# orchestrator.py — trong run_session_step(), trước khi tạo agent_input:
if payload.get("question_id") and payload.get("response"):
    # Enrich response with question options for Bayesian evidence detection
    q_data = await self._fetch_question_options(payload["question_id"])
    if q_data:
        payload["response"]["options"] = q_data.get("payload", {}).get("options", [])
```

---

## 7. HƯNG: Thêm `error_pattern` vào quiz data

Mỗi option **SAI** trong `quiz_question_template.payload.options` cần thêm field `error_pattern`.

### Mapping guide:

| Nếu option sai vì... | `error_pattern` |
|----------------------|-----------------|
| Quên đạo hàm hàm trong (chain rule) | `E_MISSING_INNER` |
| Sai tích/thương rule | `E_WRONG_OPERATOR` |
| Sai công thức lượng giác | `E_WRONG_TRIG_FORMULA` |
| Sai lũy thừa/mũ | `E_WRONG_POWER_EXP` |
| Sai dấu | `E_WRONG_SIGN` |
| Lỗi lan truyền khi tính đạo hàm cấp 2 | `E_CASCADE_ERROR` |
| Hiểu sai khái niệm đạo hàm | `E_CONCEPTUAL_MISMATCH` |
| Không rõ/khó phân loại | `E_AMBIGUOUS_ERROR` |

### SQL update pattern:

```sql
-- Ví dụ: update 1 question
UPDATE quiz_question_template
SET payload = jsonb_set(
  payload,
  '{options}',
  '[
    {"id": "A", "content": "...", "is_correct": true},
    {"id": "B", "content": "...", "is_correct": false, "error_pattern": "E_MISSING_INNER"},
    {"id": "C", "content": "...", "is_correct": false, "error_pattern": "E_WRONG_TRIG_FORMULA"},
    {"id": "D", "content": "...", "is_correct": false, "error_pattern": "E_WRONG_SIGN"}
  ]'::jsonb
)
WHERE id = '<question-uuid>';
```

### TRUE_FALSE_CLUSTER:
- Mỗi sub-question sai → `error_pattern` trong sub-question metadata
- Hoặc đơn giản: TF sai = `E_CONCEPTUAL_MISMATCH`, TF đúng = `E_CORRECT`

### SHORT_ANSWER:
- Backend cần logic riêng so sánh answer → nếu sai thì dùng `E_AMBIGUOUS_ERROR` hoặc phân tích pattern nếu có thời gian.

---

## 8. HƯNG: Tạo `knowledge_graph.json`

File: `backend/data/knowledge_graph.json`

```json
{
  "version": "1.0",
  "topic": "derivative",
  "nodes": [
    {
      "id": "derivative_definition",
      "name_vi": "Định nghĩa đạo hàm",
      "description": "Đạo hàm f'(x) = lim[h→0] (f(x+h) - f(x)) / h",
      "related_hypotheses": ["H07_Concept"],
      "difficulty_weight": 0.3
    },
    {
      "id": "power_rule",
      "name_vi": "Đạo hàm lũy thừa",
      "description": "(xⁿ)' = n·xⁿ⁻¹",
      "related_hypotheses": ["H04_PowerExp"],
      "difficulty_weight": 0.4
    },
    {
      "id": "exp_rule",
      "name_vi": "Đạo hàm hàm mũ",
      "description": "(eˣ)' = eˣ, (aˣ)' = aˣ·ln(a)",
      "related_hypotheses": ["H04_PowerExp"],
      "difficulty_weight": 0.5
    },
    {
      "id": "log_rule",
      "name_vi": "Đạo hàm logarit",
      "description": "(ln x)' = 1/x, (log_a x)' = 1/(x·ln a)",
      "related_hypotheses": ["H04_PowerExp"],
      "difficulty_weight": 0.5
    },
    {
      "id": "trig_deriv",
      "name_vi": "Đạo hàm lượng giác",
      "description": "(sin x)' = cos x, (cos x)' = -sin x, (tan x)' = 1/cos²x",
      "related_hypotheses": ["H03_Trig"],
      "difficulty_weight": 0.5
    },
    {
      "id": "product_rule",
      "name_vi": "Đạo hàm tích",
      "description": "(u·v)' = u'·v + u·v'",
      "related_hypotheses": ["H02_ProdQuot"],
      "difficulty_weight": 0.6
    },
    {
      "id": "quotient_rule",
      "name_vi": "Đạo hàm thương",
      "description": "(u/v)' = (u'·v - u·v') / v²",
      "related_hypotheses": ["H02_ProdQuot"],
      "difficulty_weight": 0.6
    },
    {
      "id": "chain_rule",
      "name_vi": "Quy tắc chuỗi (đạo hàm hàm hợp)",
      "description": "[f(g(x))]' = f'(g(x))·g'(x)",
      "related_hypotheses": ["H01_Chain"],
      "difficulty_weight": 0.8
    },
    {
      "id": "implicit_deriv",
      "name_vi": "Đạo hàm ẩn",
      "description": "Đạo hàm hai vế phương trình F(x,y) = 0 theo x",
      "related_hypotheses": ["H01_Chain", "H07_Concept"],
      "difficulty_weight": 0.8
    },
    {
      "id": "higher_order",
      "name_vi": "Đạo hàm cấp cao",
      "description": "f''(x), f'''(x) — đạo hàm của đạo hàm",
      "related_hypotheses": ["H06_SecondDeriv"],
      "difficulty_weight": 0.7
    },
    {
      "id": "notation",
      "name_vi": "Ký hiệu đạo hàm",
      "description": "f'(x), dy/dx, Df — các cách viết đạo hàm",
      "related_hypotheses": ["H05_Notation"],
      "difficulty_weight": 0.3
    },
    {
      "id": "limit_concept",
      "name_vi": "Giới hạn (nền tảng)",
      "description": "lim f(x) khi x→a — nền tảng của đạo hàm",
      "related_hypotheses": ["H07_Concept"],
      "difficulty_weight": 0.2
    },
    {
      "id": "continuity",
      "name_vi": "Tính liên tục",
      "description": "Hàm khả vi tại x₀ ⇒ liên tục tại x₀",
      "related_hypotheses": ["H07_Concept"],
      "difficulty_weight": 0.3
    },
    {
      "id": "application_tangent",
      "name_vi": "Ứng dụng: tiếp tuyến",
      "description": "Phương trình tiếp tuyến y - y₀ = f'(x₀)·(x - x₀)",
      "related_hypotheses": ["H07_Concept", "H05_Notation"],
      "difficulty_weight": 0.6
    },
    {
      "id": "application_extrema",
      "name_vi": "Ứng dụng: cực trị",
      "description": "f'(x₀) = 0, đổi dấu → cực đại/cực tiểu",
      "related_hypotheses": ["H06_SecondDeriv", "H07_Concept"],
      "difficulty_weight": 0.7
    }
  ],
  "edges": [
    {"from": "limit_concept", "to": "derivative_definition", "type": "prerequisite"},
    {"from": "limit_concept", "to": "continuity", "type": "prerequisite"},
    {"from": "continuity", "to": "derivative_definition", "type": "prerequisite"},
    {"from": "derivative_definition", "to": "power_rule", "type": "prerequisite"},
    {"from": "derivative_definition", "to": "notation", "type": "prerequisite"},
    {"from": "power_rule", "to": "exp_rule", "type": "prerequisite"},
    {"from": "power_rule", "to": "log_rule", "type": "prerequisite"},
    {"from": "power_rule", "to": "trig_deriv", "type": "prerequisite"},
    {"from": "power_rule", "to": "product_rule", "type": "prerequisite"},
    {"from": "product_rule", "to": "quotient_rule", "type": "prerequisite"},
    {"from": "power_rule", "to": "chain_rule", "type": "prerequisite"},
    {"from": "trig_deriv", "to": "chain_rule", "type": "related"},
    {"from": "chain_rule", "to": "implicit_deriv", "type": "prerequisite"},
    {"from": "derivative_definition", "to": "higher_order", "type": "prerequisite"},
    {"from": "chain_rule", "to": "higher_order", "type": "related"},
    {"from": "notation", "to": "higher_order", "type": "related"},
    {"from": "derivative_definition", "to": "application_tangent", "type": "prerequisite"},
    {"from": "notation", "to": "application_tangent", "type": "related"},
    {"from": "higher_order", "to": "application_extrema", "type": "prerequisite"},
    {"from": "application_tangent", "to": "application_extrema", "type": "related"}
  ]
}
```

15 nodes, 20 edges. Hưng review và chỉnh sửa nội dung toán học nếu cần.

---

## 9. ĐỨC: Thêm SkipTask Repair (`htn_node.py`)

File: `backend/agents/academic_agent/htn_node.py` (khoảng line 128-141)

### Tìm `_select_repair_strategy()` và thêm:

```python
def _select_repair_strategy(self, context: dict) -> str:
    # Nếu student kiệt sức → skip task
    empathy = context.get("empathy_state", {})
    dominant = empathy.get("dominant", "")
    fatigue = float(empathy.get("fatigue", 0.0))
    
    if dominant == "exhausted" or fatigue >= 0.75:
        return "SkipTask"
    
    # ... existing AltMethod / InsertTask logic ...
```

### Trong `_apply_repair()`, thêm case:

```python
if strategy == "SkipTask":
    self.status = "skipped"
    logger.info(f"Skipping task {self.task_id} due to student fatigue")
    return {"status": "skipped", "reason": "student_exhausted"}
```

---

## 10. ORCHESTRATOR: Enrichment cần thêm

File: `backend/agents/orchestrator.py` — trong `run_session_step()`

Hiện tại (line 73-78):
```python
agent_input = AgentInput(
    session_id=session_id,
    student_id=student_id,
    question_id=payload.get("question_id"),
    user_response=payload.get("response"),
    behavior_signals=payload.get("behavior_signals"),
    current_state=state.model_dump(),
)
```

**Cần thêm enrichment** trước khi tạo `agent_input`:

```python
# Enrich response with quiz options for evidence detection
response = payload.get("response") or {}
question_id = payload.get("question_id")
if question_id and response.get("selected_option"):
    from core.supabase_client import get_supabase_client
    try:
        q_resp = await asyncio.to_thread(
            lambda: get_supabase_client()
            .table("quiz_question_template")
            .select("payload")
            .eq("id", question_id)
            .single()
            .execute()
        )
        q_data = getattr(q_resp, "data", None)
        if q_data and "payload" in q_data:
            response["options"] = q_data["payload"].get("options", [])
            payload["response"] = response
    except Exception:
        pass  # Fallback: BayesianTracker sẽ dùng E_CORRECT mặc định
```

---

## 11. TEST FLOW SAU KHI SỬA

```
1. Start session → POST /api/v1/session/create
2. Get first question → HTN: P01_serve_mcq queries Supabase ✓
3. Submit wrong answer (option B, error_pattern = E_MISSING_INNER)
   → POST /api/v1/orchestrator/step
   → Orchestrator enriches response with quiz options
   → BayesianTracker detects E_MISSING_INNER → belief H01_Chain ↑
4. Select next question → P04 queries pool → EIG picks best question
5. Repeat → beliefs should converge on correct hypothesis
6. When fatigue ≥ 0.75 → HTN SkipTask → de-stress trigger
```

### Quick unit test:
```python
def test_eig_selection():
    belief = {"H01_Chain": 0.5, "H02_ProdQuot": 0.1, ...}
    pool = [q1_chain_heavy, q2_trig_heavy, q3_general]
    best = _select_by_eig(pool, belief)
    # Should pick question that best disambiguates H01_Chain
    assert best["id"] == q1_chain_heavy["id"]
```

---

## 12. CHECKLIST

- [ ] **Đức:** `_serve_mcq()` query Supabase thật
- [ ] **Đức:** `_select_next_question()` khung + filter answered
- [ ] **Đức:** SkipTask repair trong `htn_node.py`
- [ ] **Đức:** Orchestrator enrich response with quiz options
- [ ] **Khang:** `_select_by_eig()` function + unit test
- [ ] **Khang:** `bayesian_tracker.py` auto-detect evidence từ options
- [ ] **Hưng:** Thêm `error_pattern` cho tất cả MCQ options trong Supabase
- [ ] **Hưng:** Review + commit `knowledge_graph.json`
- [ ] **Hưng:** Verify TF/SA evidence mapping strategy
- [ ] **All:** Test E2E: wrong answer → belief update → next question selection
