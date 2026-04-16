# GrowMate — Đánh giá Agentic AI

> **Ngày rà soát:** 16/04/2026  
> **Phạm vi:** Frontend (Flutter) + Backend (FastAPI)  
> **Kết luận:** Hệ thống hiện tại là **Adaptive Learning System**, chưa phải Agentic AI đúng nghĩa.

---

## 1. Định nghĩa Agentic AI

Agentic AI là hệ thống AI có khả năng:

1. **Autonomous reasoning** — LLM tự suy luận, không chỉ chạy rule cố định
2. **Tool use** — Agent gọi tools/APIs bên ngoài để thu thập thông tin
3. **Planning & re-planning** — Lập kế hoạch, tự điều chỉnh khi thất bại
4. **Goal-seeking** — Phân rã mục tiêu lớn thành sub-goals
5. **Self-reflection** — Đánh giá lại quyết định, học từ sai lầm
6. **Knowledge retrieval (RAG)** — Truy vấn cơ sở kiến thức khi cần

---

## 2. Kiến trúc hiện tại

### 2.1 Pipeline tổng quan

```
[Học sinh trả lời + behavior signals]
    ↓
[1. ACADEMIC AGENT] — Bayesian belief update
    • 4 hypotheses: H01_Trig, H02_ExpLog, H03_Chain, H04_Rules
    • Output: belief_dist, entropy, confidence
    ↓
[2. EMPATHY AGENT] — Particle Filter (100 particles)
    • Tracks 2D state: [confusion, fatigue]
    • Output: confusion, fatigue, uncertainty, q_state
    ↓
[3. STRATEGY AGENT] — Q-Learning (8 states × 5 actions)
    • Epsilon-greedy action selection
    • Output: selected_action, q_values, epsilon
    ↓
[4. ORCHESTRATOR ENGINE] — Deterministic utility scoring
    • StateAggregator → PolicyEngine → MonitoringEngine
    • Output: final_action, hitl_triggered
    ↓
[5. LLM (Gemini 2.5-Flash)] — Chỉ tạo text tutor
    • KHÔNG tham gia quyết định
    • Tạo câu nhắn ngắn < 30 ký tự
    ↓
[Action gửi về Frontend qua REST + WebSocket]
```

### 2.2 Frontend Integration

| Component | File | Vai trò |
|---|---|---|
| `AgenticApiService` | `lib/core/network/agentic_api_service.dart` | Interface REST API |
| `AgenticWsService` | `lib/core/network/ws_service.dart` | WebSocket 2 channels (behavior + dashboard) |
| `AgenticSessionRepository` | `lib/features/agentic_session/data/repositories/` | Kết nối UI ↔ Backend |
| `AgenticSessionCubit` | `lib/features/agentic_session/presentation/cubit/` | Quản lý session lifecycle |
| `AiCompanionCubit` | `lib/features/ai_companion/presentation/` | Quản lý UI state (orb, blocks, HITL) |
| `SessionToCompanionBridge` | `lib/features/ai_companion/presentation/` | Map backend events → UI |

### 2.3 Backend Agents

| Agent | Algorithm | File | Vai trò |
|---|---|---|---|
| **Academic** | Bayesian Inference | `agents/academic_agent/bayesian_tracker.py` | Theo dõi mastery trên 4 hypotheses |
| **Empathy** | Particle Filter | `agents/empathy_agent/particle_filter.py` | Ước lượng confusion + fatigue |
| **Strategy** | Q-Learning | `agents/strategy_agent/q_learning.py` | Chọn action tối ưu |
| **Orchestrator** | Deterministic Utility | `orchestrator/engine.py` | Tổng hợp → quyết định cuối |

### 2.4 Dữ liệu và State

| Layer | Lưu ở đâu | Tần suất |
|---|---|---|
| In-memory session state | Python dict (RAM) | Mỗi step |
| Q-table | Supabase `q_table` | Mỗi step (async) |
| Episodic memory | Supabase `episodic_memory` | Mỗi 5 steps (async) |
| Belief snapshots | Supabase | Mỗi 3 steps (async) |

### 2.5 Communication

- **REST:** `POST /sessions/{id}/interact` — submit answer, nhận action response
- **REST:** `POST /sessions/{id}/orchestrator-step` — full pipeline step
- **WebSocket:** `/ws/v1/behavior/{sessionId}` — frontend gửi behavioral signals
- **WebSocket:** `/ws/v1/dashboard/stream/{sessionId}` — backend broadcast dashboard updates
- **Auth:** HMAC signing cho interact endpoint, JWT cho các route khác

---

## 3. Đánh giá theo tiêu chí Agentic AI

### ✅ Cái đã có

| Tiêu chí | Trạng thái | Chi tiết |
|---|---|---|
| Multi-agent architecture | ✅ | 3 agent chuyên biệt + 1 orchestrator |
| Autonomous decision-making | ✅ | Orchestrator tự chọn action không cần human approval |
| State persistence & learning | ✅ | Q-table cập nhật theo thời gian, episodic memory lưu lịch sử |
| Self-monitoring + HITL | ✅ | Khi total uncertainty vượt threshold → trigger Human-in-the-Loop |
| Real-time behavior tracking | ✅ | WebSocket gửi typing speed, idle time, correction rate |
| Observable reasoning | ✅ | Dashboard hiển thị belief distributions, Q-values, particle states |
| Multi-layer decision | ✅ | Academic → Empathy → Strategy → Orchestrator |

### ❌ Cái thiếu

| Tiêu chí | Trạng thái | Vấn đề cụ thể |
|---|---|---|
| **LLM-driven reasoning** | ❌ | LLM (Gemini) chỉ dùng tạo text tutor SAU KHI quyết định xong. LLM không tham gia suy luận hay ra quyết định. Tất cả quyết định dựa trên Bayesian math + Q-table + utility scoring. |
| **Tool use** | ❌ | Agent không gọi bất kỳ tool/API bên ngoài nào. Chỉ tính toán nội bộ (nhân ma trận, update weights). Không search knowledge base, không query database, không gọi external service. |
| **Dynamic re-planning** | ❌ | HTN Planner tồn tại trong code nhưng phần lớn là **stub/mock**. Primitive tasks return fake results. Không có khả năng thay đổi kế hoạch giữa session khi phát hiện approach hiện tại không hiệu quả. |
| **Goal-seeking behavior** | ❌ | Action space cố định 5 actions: `next_question`, `show_hint`, `drill_practice`, `de_stress`, `hitl`. Không có sub-goal decomposition, không tự đặt mục tiêu phụ. |
| **RAG (Knowledge Retrieval)** | ❌ | Không có vector store, không embed sách giáo khoa hay công thức. Khi HS sai, agent không truy vấn tài liệu liên quan để giải thích. |
| **Self-reflection** | ❌ | Agent không tự đánh giá lại quyết định. Chỉ log episodic memory rồi tiếp tục. Không có bước "chiến lược hiện tại có hiệu quả không?" |
| **NLU cho câu trả lời tự do** | ❌ | Không phân tích câu trả lời text/tự luận bằng LLM. Chỉ xử lý MCQ (đúng/sai) và structured response. |

---

## 4. Lộ trình nâng cấp thành Agentic AI

### Bước 1: LLM Function-Calling Wrapper (Ưu tiên cao nhất)

**Mục tiêu:** LLM trở thành bộ não ra quyết định, gọi 3 agent hiện tại như tools.

**Hiện tại:**
```
Student answer → Academic Agent → Empathy Agent → Strategy Agent → Utility Score → Action
                                                                     (rule-based)
```

**Sau nâng cấp:**
```
Student answer → LLM Reasoning Engine
                    ↕ function calls
                 ┌─ get_academic_beliefs() → Bayesian posterior
                 ├─ get_empathy_state()    → confusion, fatigue
                 ├─ get_strategy_suggestion() → Q-learning recommendation
                 ├─ search_knowledge_base(topic) → relevant formulas
                 └─ get_student_history(n=5) → recent interactions
                    ↕ reasoning
                 LLM decides final action with explanation
```

**Triển khai:**

```python
# backend/agents/orchestrator.py — Phiên bản mới

import google.generativeai as genai

TOOLS = [
    {
        "name": "get_academic_beliefs",
        "description": "Lấy phân phối xác suất P(H|E) cho các hypothesis về kiến thức HS",
        "parameters": {"session_id": "string"}
    },
    {
        "name": "get_empathy_state", 
        "description": "Lấy trạng thái cảm xúc: confusion, fatigue, uncertainty",
        "parameters": {"session_id": "string"}
    },
    {
        "name": "get_strategy_suggestion",
        "description": "Lấy gợi ý action từ Q-Learning agent",
        "parameters": {"session_id": "string", "state_key": "string"}
    },
    {
        "name": "search_formula_bank",
        "description": "Tìm công thức liên quan đến concept",
        "parameters": {"topic": "string", "top_k": "integer"}
    },
    {
        "name": "get_student_history",
        "description": "Lấy N tương tác gần nhất của HS",
        "parameters": {"session_id": "string", "n": "integer"}
    },
]

SYSTEM_PROMPT = """
Bạn là gia sư AI GrowMate cho học sinh Toán THPT Việt Nam.

Bạn có quyền truy cập các tool để hiểu trạng thái học sinh:
- get_academic_beliefs: Xem HS yếu ở đâu (Bayesian beliefs)
- get_empathy_state: Xem HS có mệt/bối rối không (Particle Filter)
- get_strategy_suggestion: Xem Q-Learning gợi ý gì
- search_formula_bank: Tìm công thức liên quan
- get_student_history: Xem lịch sử gần đây

Quy trình:
1. Gọi tool để thu thập thông tin
2. Suy luận tình huống cụ thể của HS
3. Quyết định action phù hợp nhất
4. Giải thích ngắn gọn lý do

Actions khả dụng: next_question, show_hint, drill_practice, de_stress, hitl
"""
```

**Lợi ích:**
- Pipeline cũ (Bayesian/PF/Q-Learning) vẫn chạy bình thường → không phải viết lại
- LLM thêm layer reasoning phía trên → quyết định thông minh hơn
- Có thể giải thích lý do cho mỗi quyết định (explainability)

---

### Bước 2: RAG Pipeline (Ưu tiên cao)

**Mục tiêu:** Agent truy vấn kiến thức sách giáo khoa khi cần giải thích.

**Triển khai:**

```sql
-- Supabase migration: thêm vector column
ALTER TABLE formula_bank ADD COLUMN embedding vector(768);

-- Hoặc tạo bảng riêng
CREATE TABLE knowledge_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source TEXT NOT NULL,           -- 'sgk_toan_12', 'cong_thuc', 'bai_giai_mau'
    chapter TEXT,                   -- 'dao_ham', 'tich_phan', 'luong_giac'
    content TEXT NOT NULL,          -- Nội dung chunk
    embedding vector(768),          -- text-embedding-004
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX ON knowledge_chunks 
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 50);
```

```python
# backend/core/knowledge_retriever.py

class KnowledgeRetriever:
    async def search(self, query: str, top_k: int = 3) -> list[dict]:
        embedding = await self.embed(query)
        results = await supabase.rpc(
            "match_knowledge_chunks",
            {"query_embedding": embedding, "match_count": top_k}
        )
        return results
    
    async def get_relevant_formulas(self, hypothesis: str) -> list[dict]:
        """Khi HS yếu H03_Chain → tìm công thức đạo hàm hợp"""
        topic_map = {
            "H01_Trig": "đạo hàm lượng giác sin cos tan",
            "H02_ExpLog": "đạo hàm hàm mũ logarit",
            "H03_Chain": "quy tắc đạo hàm hàm hợp chain rule",
            "H04_Rules": "công thức đạo hàm cơ bản",
        }
        query = topic_map.get(hypothesis, hypothesis)
        return await self.search(query, top_k=3)
```

**Data cần embed:**
- Sách giáo khoa Toán 12 (các chương trọng tâm THPT)
- Bảng công thức đạo hàm, tích phân, lượng giác
- Bài giải mẫu cho các dạng hay gặp
- Mẹo giải nhanh, lỗi sai thường gặp

---

### Bước 3: Tool Registry (Ưu tiên trung bình)

**Mục tiêu:** Cho LLM gọi được nhiều tools hơn.

```python
# backend/core/tool_registry.py

TOOL_REGISTRY = {
    # Agent tools (đã có)
    "get_academic_beliefs": academic_agent.get_beliefs,
    "get_empathy_state": empathy_agent.get_state,
    "get_strategy_suggestion": strategy_agent.suggest,
    
    # Knowledge tools (mới)
    "search_formula_bank": knowledge_retriever.search,
    "search_similar_questions": question_selector.find_similar,
    
    # History tools (mới)  
    "get_student_history": memory_store.get_recent,
    "get_session_summary": memory_store.summarize_session,
    
    # Generation tools (mới)
    "generate_explanation": llm_service.explain_mistake,
    "generate_practice_drill": question_selector.create_drill,
    "generate_hint": llm_service.create_hint,
}
```

---

### Bước 4: ReAct Reasoning Loop (Ưu tiên trung bình)

**Mục tiêu:** LLM suy luận theo chuỗi Thought → Action → Observation.

```python
# backend/agents/reasoning_loop.py

class ReActLoop:
    MAX_STEPS = 5
    
    async def run(self, session_id: str, student_input: dict) -> dict:
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
        messages.append({"role": "user", "content": self._format_input(student_input)})
        
        for step in range(self.MAX_STEPS):
            response = await self.llm.generate(
                messages=messages,
                tools=TOOL_REGISTRY,
            )
            
            if response.tool_calls:
                # Agent muốn gọi tool
                for call in response.tool_calls:
                    result = await self.execute_tool(call)
                    messages.append({
                        "role": "tool", 
                        "content": json.dumps(result)
                    })
            else:
                # Agent đã có đủ thông tin, trả về quyết định
                return self.parse_decision(response.text)
        
        # Fallback nếu quá nhiều bước
        return {"action": "next_question", "reason": "max_steps_reached"}
```

**Ví dụ chuỗi reasoning thực tế:**

```
👤 Input: HS trả lời sai câu "Tính đạo hàm y = sin(2x+1)"
          Chọn: y' = cos(2x+1) (thiếu nhân 2)

🤔 Thought 1: HS quên quy tắc chain rule. Cần xác nhận bằng belief data.

🔧 Action 1: get_academic_beliefs(session_id="abc123")
📊 Observation 1: {
    "H01_Trig": 0.20, "H02_ExpLog": 0.10, 
    "H03_Chain": 0.55, "H04_Rules": 0.15
    "entropy": 0.72, "confidence": 0.28
}

🤔 Thought 2: Đúng rồi, H03_Chain = 0.55 (cao nhất). HS yếu chain rule.
              Kiểm tra cảm xúc trước khi quyết định.

🔧 Action 2: get_empathy_state(session_id="abc123")
📊 Observation 2: {
    "confusion": 0.6, "fatigue": 0.3, "uncertainty": 0.5
}

🤔 Thought 3: Confusion = 0.6 (trung bình cao), fatigue thấp. 
              HS còn tỉnh táo nhưng đang bối rối.
              Nên cho hint cụ thể, không phải drill.
              Tìm công thức chain rule để nhắc.

🔧 Action 3: search_formula_bank("đạo hàm hàm hợp chain rule")
📊 Observation 3: [
    "(f∘g)'(x) = f'(g(x)) · g'(x)",
    "Ví dụ: (sin(2x))' = cos(2x) · (2x)' = 2cos(2x)"
]

✅ Decision: {
    "action": "show_hint",
    "content": "Nhớ quy tắc đạo hàm hàm hợp nhé: [sin(u)]' = cos(u) · u'. Ở đây u = 2x+1, vậy u' = ?",
    "reason": "HS yếu chain rule (H03=0.55), confusion vừa phải, fatigue thấp → hint cụ thể hiệu quả hơn drill"
}
```

---

### Bước 5: Self-Reflection (Ưu tiên thấp hơn)

**Mục tiêu:** Sau mỗi N interactions, LLM đánh giá lại chiến lược.

```python
# backend/agents/reflection.py

class ReflectionEngine:
    REFLECT_EVERY_N = 5
    
    async def maybe_reflect(self, session_id: str, step: int) -> dict | None:
        if step % self.REFLECT_EVERY_N != 0:
            return None
        
        history = await self.memory.get_recent(session_id, n=self.REFLECT_EVERY_N)
        beliefs = await self.academic.get_beliefs(session_id)
        empathy = await self.empathy.get_state(session_id)
        
        prompt = f"""
        Xem lại {self.REFLECT_EVERY_N} tương tác gần nhất của session {session_id}:
        
        Lịch sử: {json.dumps(history, ensure_ascii=False)}
        Beliefs hiện tại: {json.dumps(beliefs)}
        Empathy hiện tại: {json.dumps(empathy)}
        
        Trả lời:
        1. Entropy có giảm không? (Chiến lược đang hiệu quả?)
        2. Accuracy có tăng không?
        3. Confusion có giảm không?
        4. Cần thay đổi approach không? Nếu có, đổi gì?
        5. Nên tiếp tục hay chuyển sang topic khác?
        """
        
        reflection = await self.llm.generate(prompt)
        
        if reflection.should_change:
            await self.update_strategy(session_id, reflection.recommendation)
        
        return reflection
```

---

### Bước 6: Dynamic HTN Re-planning (Ưu tiên thấp)

**Mục tiêu:** Thay HTN stub bằng LLM-based plan generation.

Hiện tại HTN planner có cấu trúc cây cố định trong `htn_rules.yaml`. Cần cho LLM tự tạo plan dựa trên tình huống:

```python
# Thay vì plan cố định:
# M01_standard_flow → [assess, pinpoint, intervene, validate]

# LLM tự generate plan:
async def generate_plan(self, context: dict) -> list[str]:
    prompt = f"""
    Học sinh: mastery={context['confidence']}, confusion={context['confusion']}
    Topic: {context['topic']}, đã làm {context['step']} câu
    
    Lập kế hoạch 3-5 bước tiếp theo. Mỗi bước là 1 action.
    Có thể thay đổi plan ở bước tiếp nếu cần.
    """
    plan = await self.llm.generate(prompt)
    return plan.steps  # ["show_hint", "drill_practice", "next_question", ...]
```

---

## 5. So sánh trước và sau

| Khía cạnh | Hiện tại (Adaptive) | Sau nâng cấp (Agentic) |
|---|---|---|
| **Ra quyết định** | Utility score cố định | LLM reasoning với context |
| **Giải thích** | Không có | LLM giải thích tại sao chọn action |
| **Kiến thức** | Hardcoded trong code | RAG truy vấn SGK + công thức |
| **Hint** | Template text cố định | LLM tạo hint cá nhân hóa dựa trên lỗi cụ thể |
| **Lập kế hoạch** | HTN cố định / stub | LLM dynamic planning |
| **Học từ kinh nghiệm** | Q-table update (số) | Q-table + LLM reflection (ngữ nghĩa) |
| **Xử lý câu tự do** | Không hỗ trợ | LLM phân tích NLU |

---

## 6. Ước lượng effort

| Bước | Công việc | Backend | Frontend | Tổng |
|---|---|---|---|---|
| 1 | LLM function-calling wrapper | 2-3 ngày | 0.5 ngày (update response parsing) | ~3 ngày |
| 2 | RAG pipeline + embed data | 3-4 ngày | 1 ngày (hiển thị knowledge cards) | ~4 ngày |
| 3 | Tool registry mở rộng | 1-2 ngày | 0 | ~2 ngày |
| 4 | ReAct reasoning loop | 2-3 ngày | 1 ngày (hiển thị reasoning trace) | ~3 ngày |
| 5 | Self-reflection engine | 1-2 ngày | 0.5 ngày (hiển thị reflection summary) | ~2 ngày |
| 6 | Dynamic HTN re-planning | 2-3 ngày | 0 | ~3 ngày |
| **Tổng** | | | | **~17 ngày** |

---

## 7. Rủi ro và lưu ý

1. **Chi phí LLM:** Function-calling + RAG tăng số lần gọi LLM. Cần cache và rate limiting.
2. **Latency:** ReAct loop có thể mất 2-5 giây (nhiều round-trip). Cần streaming response.
3. **Fallback:** Khi LLM fail/timeout, vẫn dùng pipeline cũ (Bayesian + Q-Learning) làm fallback.
4. **Testing:** Cần test LLM output quality với test set bài Toán THPT thực tế.
5. **Data quality:** RAG chỉ tốt khi data SGK được chunk và embed chính xác.

---

## 8. Kết luận

GrowMate có **kiến trúc multi-agent mạnh** với Bayesian Inference, Particle Filter, Q-Learning, và Orchestrator Engine. Đây là nền tảng tốt hơn phần lớn các edtech hiện có.

Tuy nhiên, để gọi là **Agentic AI**, hệ thống cần bổ sung **LLM reasoning loop** — cho LLM trở thành bộ não ra quyết định, gọi các agent hiện tại như tools, và có khả năng suy luận, giải thích, truy vấn kiến thức.

**Bước 1 (LLM function-calling wrapper) là đủ để chuyển từ "Adaptive" sang "Agentic"** mà không cần viết lại pipeline cũ.
