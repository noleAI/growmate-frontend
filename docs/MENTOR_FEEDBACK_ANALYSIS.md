# Phân Tích Chi Tiết Góp Ý Mentor

> Tổng hợp sau buổi họp với Mentor — Ngày 14/04/2026

---

## 1. Giảm Scope Toán Học — Chỉ Chọn 1 Chủ Đề

**Hiện trạng:** Backend đang track 8 hypotheses (H01-H08) bao phủ nhiều dạng: Chain Rule, Product/Quotient Rule, Trig derivatives, Power/Exponential, Notation issues...

**Mentor muốn gì:** Thay vì ôm đồm nhiều chủ đề đạo hàm, nhóm nên chọn **1 trong 2 hướng**:

| Hướng | Mô tả | Ví dụ cụ thể |
|-------|--------|---------------|
| **Bổ trợ kiến thức** | Dạy lại từ gốc, lấp lỗ hổng nền tảng | Chỉ tập trung vào "Đạo hàm cơ bản" — công thức, quy tắc tính, áp dụng đơn giản |
| **Ôn tập kỹ năng** | Luyện đề, rèn tốc độ, drill pattern | Chỉ tập trung vào "Luyện đề đạo hàm thi THPT" — các dạng hay ra, mẹo giải nhanh |

**Tại sao quan trọng:** MVP mà scope rộng → dữ liệu câu hỏi thưa → Bayesian belief cập nhật chậm → trải nghiệm cá nhân hóa kém. Chọn 1 chủ đề = ít câu hỏi hơn nhưng **chất lượng cao hơn**, belief converge nhanh hơn, demo thuyết phục hơn.

**Hành động cụ thể:**
- Thu gọn `derivative_priors.json` và hypotheses xuống 3-4 hypotheses cho 1 chủ đề duy nhất
- Tập trung viết 50-100 câu hỏi chất lượng cao cho chủ đề đó thay vì 20 câu rải 8 chủ đề
- Cập nhật HTN planner (`htn_rules.yaml`) cho learning path ngắn gọn hơn

---

## 2. Xác Định Cụ Thể Chức Năng Chatbot

**Hiện trạng:** Backend có 3 agents (Academic, Empathy, Strategy) + Orchestrator, nhưng chưa rõ chatbot UI sẽ trả lời những gì.

**Mentor muốn gì:** Định nghĩa rõ ràng **chatbot làm được gì** và **không làm gì**.

**Phân loại chức năng cần xác định:**

```
✅ ĐƯỢC PHÉP (In-scope):
├── Giải thích lời giải bài quiz vừa làm sai
├── Gợi ý bài tiếp theo dựa trên belief hiện tại
├── Nhắc nhở lịch học, động viên tinh thần
├── Trả lời câu hỏi về công thức đạo hàm
└── Hướng dẫn phương pháp học tập

❌ KHÔNG ĐƯỢC PHÉP (Out-of-scope):
├── Giải bài hộ (chỉ gợi ý, không đưa đáp án trực tiếp)
├── Bàn luận chủ đề ngoài toán (chính trị, game, v.v.)
├── Tư vấn tâm lý chuyên sâu (chỉ nhắc nghỉ ngơi)
└── Trả lời về môn khác (Lý, Hóa, Anh...)
```

**Hành động cụ thể:**
- Viết 1 file `CHATBOT_POLICY.md` liệt kê rõ allowed/disallowed topics
- Trong system prompt của LLM, hardcode policy này
- Thêm keyword filter trước khi gọi LLM — nếu câu hỏi off-topic → trả lời template ngay, không tốn token

---

## 3. Cá Nhân Hóa — Chi Tiết Từng Điểm

### 3a. Thu thập dữ liệu cá nhân → Plan cá nhân

**Hiện trạng:** Đã có `behavioral_signals` (typing speed, idle time, correction count). Chưa có profile ban đầu.

**Cần thêm:**
- **Onboarding quiz** (5-10 câu): Xác định trình độ ban đầu, mục tiêu (thi ĐH hay học cho biết), thời gian rảnh mỗi ngày
- **Classification**: Dựa vào kết quả onboarding → phân loại user thành nhóm:
  ```
  Beginner (< 40% đúng)  → Plan: Bổ trợ kiến thức, 15 phút/ngày
  Intermediate (40-70%)  → Plan: Hỗn hợp, 20 phút/ngày
  Advanced (> 70%)       → Plan: Luyện đề nâng cao, 25 phút/ngày
  ```
- Mỗi nhóm có **prompt template khác nhau** cho chatbot (ngôn ngữ đơn giản hơn cho Beginner, chuyên sâu hơn cho Advanced)

### 3b. ChatVoice (Speech-to-Text)

**Mục đích:** Học sinh có thể **nói** câu hỏi thay vì gõ → tiện lợi hơn, đặc biệt khi đang làm bài trên giấy.

**Triển khai:**
- Dùng package `speech_to_text` (Flutter) hoặc Google Cloud Speech-to-Text API
- Flow: User nhấn mic → STT chuyển thành text → gửi text vào chatbot pipeline bình thường
- **Lưu ý:** Tiếng Việt có dấu, cần chọn model STT hỗ trợ tốt Vietnamese (Google STT hoặc Whisper API)

### 3c. Policy — AI biết nói gì và không được nói gì

Đây là phần **quan trọng nhất** theo Mentor. Cần tạo hệ thống **guardrails**:

```python
# Ví dụ policy enforcement trong backend
FORBIDDEN_TOPICS = ["chính trị", "bạo lực", "tình dục", "tôn giáo"]
MAX_RESPONSE_LENGTH = 500  # ký tự
MUST_INCLUDE_DISCLAIMER = True  # "Mình là AI, nếu cần hỗ trợ chuyên sâu..."

def check_policy(user_input: str, bot_response: str) -> str:
    # Pre-check: filter input
    if any(topic in user_input.lower() for topic in FORBIDDEN_TOPICS):
        return "Mình chỉ hỗ trợ về toán học thôi nhé! 📚"
    
    # Post-check: truncate response
    if len(bot_response) > MAX_RESPONSE_LENGTH:
        bot_response = bot_response[:MAX_RESPONSE_LENGTH] + "..."
    
    return bot_response
```

### 3d. Thêm if-else để phản hồi nhanh

**Ý nghĩa:** Không phải câu hỏi nào cũng cần gọi LLM (tốn 2-5 giây + token). Nhiều câu hỏi lặp lại có thể trả lời bằng **template**:

```
User: "Công thức đạo hàm sin x là gì?"
→ IF match pattern "công thức đạo hàm {func}"
→ THEN lookup bảng công thức → trả lời ngay (< 100ms)
→ ELSE gọi LLM

User: "Giải thích bài vừa sai"
→ IF có context quiz gần nhất
→ THEN dùng template explanation có sẵn
→ ELSE gọi LLM với context
```

**Lợi ích:** Giảm 60-70% số lần gọi LLM → tiết kiệm chi phí, phản hồi nhanh hơn.

### 3e. Quản lý token — Giới hạn ký tự

**Hiện trạng:** Chưa có rõ ràng limit.

**Cần làm:**
- **Input limit:** Giới hạn user input ≤ 300 ký tự (đủ cho 1 câu hỏi toán)
- **Context window management:** Chỉ gửi 5 tin nhắn gần nhất + system prompt (không gửi toàn bộ lịch sử)
- **Output limit:** Set `max_tokens=500` trong LLM call
- **Daily quota:** Mỗi user free tier = 20 lượt chat/ngày → hiện counter trên UI
- **Budget alert:** Monitor tổng token usage, alert khi vượt ngưỡng

---

## 4. Xem Xét Hành Vi Người Dùng

### 4a. Nghiên cứu thời gian học

**Cần thu thập & phân tích:**
- Thời điểm học phổ biến nhất (sáng/chiều/tối)
- Thời lượng trung bình mỗi session
- Thời điểm user thường bỏ giữa chừng

```
session_analytics:
├── avg_session_duration: 12 phút
├── peak_hours: 19:00 - 21:00
├── drop_off_point: sau câu 7-8 (quiz fatigue)
└── best_performance_window: 15:00 - 17:00
```

→ Dùng data này để **suggest thời gian học tối ưu** cho từng user.

### 4b. Tần số âm thanh phù hợp

Nếu app có **nhạc nền / âm thanh** khi học:
- Nghiên cứu cho thấy **binaural beats 10-12 Hz (alpha waves)** giúp tập trung
- **Lo-fi music 60-70 BPM** giúp giảm stress khi ôn thi
- Cho user chọn: Yên lặng / Nhạc tập trung / Tiếng mưa / Custom
- Track xem user nào học tốt hơn với nhạc nào → personalize

### 4c. Xử lý user bỏ dở / không nghiêm túc

| Trường hợp | Cách phát hiện | Xử lý |
|------------|---------------|-------|
| **Bỏ dở giữa quiz** | Session timeout > 5 phút | Lưu state, nhắc nhở lần sau "Bạn còn bài dở, tiếp tục nhé!" |
| **Spam/Random answer** | Trả lời < 2 giây liên tục, accuracy < 20% | Cảnh báo nhẹ nhàng, có thể pause quiz |
| **Học môn khác** | Chat off-topic nhiều lần | Redirect: "Mình giỏi toán thôi, quay lại luyện bài nhé!" |
| **AFK (Away)** | Idle > 3 phút trong quiz | Auto-pause, không tính thời gian |

### 4d. Bảng xếp hạng & Vinh danh

**Thiết kế Leaderboard:**

```
🏆 Bảng xếp hạng tuần
┌──────┬──────────────┬──────────┬────────┐
│ Hạng │ Tên          │ Điểm XP  │ Streak │
├──────┼──────────────┼──────────┼────────┤
│ 🥇 1 │ Minh Anh     │ 2,400    │ 🔥 14  │
│ 🥈 2 │ Hoàng Nam    │ 2,150    │ 🔥 10  │
│ 🥉 3 │ Thu Hà       │ 1,980    │ 🔥 7   │
└──────┴──────────────┴──────────┴────────┘
```

**Hệ thống vinh danh:**
- **Push notification:** "Chúc mừng bạn lọt Top 10 tuần này! 🎉"
- **Badge đặc biệt** trên profile: "Chiến thần Đạo hàm", "7 ngày không nghỉ"
- **Tổng kết tuần:** Email/notification recap: "Tuần này bạn đã giải 45 bài, tăng 20% so với tuần trước"
- **Leaderboard theo trường/lớp** (nếu có): tạo competitive spirit

---

## 5. Học Cùng Nhau — Hướng Kahoot

### 5a. Linked Users (Study Buddy)

**Cơ chế:**
- User gửi **invite link** cho bạn bè
- 2-4 người vào cùng 1 quiz session (real-time via WebSocket — đã có ws endpoint)
- Mỗi người làm bài riêng, nhưng thấy **tiến độ của nhau** real-time

### 5b. Kahoot-style Quiz Battle

```
┌─────────────────────────────────────┐
│  🎯 Câu 5/10 — Ai nhanh hơn?      │
│                                     │
│  Đạo hàm của sin(2x) = ?           │
│                                     │
│  ┌─────────┐  ┌─────────┐          │
│  │ 2cos(2x)│  │ cos(2x) │          │
│  └─────────┘  └─────────┘          │
│  ┌─────────┐  ┌─────────┐          │
│  │ -cos(2x)│  │2sin(2x) │          │
│  └─────────┘  └─────────┘          │
│                                     │
│  ⏱️ 15s     👥 Minh: 4/4 | Hà: 3/4│
└─────────────────────────────────────┘
```

**Tính năng:**
- **Countdown timer** mỗi câu (10-20 giây)
- **Điểm = đúng + nhanh** (giống Kahoot)
- **Reaction animations** khi ai đó trả lời đúng
- **Kết quả cuối:** Xếp hạng + highlight câu hay sai chung → "Cả nhóm đều sai câu 7, cùng ôn lại nhé!"

---

## 6. Chống Leak Nội Dung

**Mục đích:** Bảo vệ ngân hàng câu hỏi — tài sản quan trọng nhất của app.

| Lớp | Biện pháp | Chi tiết |
|-----|-----------|----------|
| **API** | Không trả về đáp án trước khi user submit | API chỉ gửi `question + options`, đáp án check server-side |
| **Client** | Obfuscate response | Không cache đáp án trong local storage |
| **Screenshot** | Flag `FLAG_SECURE` (Android) | Ngăn chụp màn hình khi đang làm quiz |
| **Rate limit** | Giới hạn số quiz/ngày | Ngăn bot crawl toàn bộ câu hỏi |
| **Randomization** | Shuffle thứ tự câu + đáp án | Mỗi lần làm bài khác nhau |
| **Watermark** | Invisible watermark trên ảnh/diagram | Nếu leak, trace được source |
| **API Security** | Request signing + token rotation | Ngăn replay attack |

**Code ví dụ cho Android FLAG_SECURE:**
```kotlin
// MainActivity.kt
window.setFlags(
    WindowManager.LayoutParams.FLAG_SECURE,
    WindowManager.LayoutParams.FLAG_SECURE
)
```

---

## 7. Gameplay Hóa Trải Nghiệm Học

### 7a. Chia theo dạng đề + Chia theo người học

```
📚 Chế độ học:
├── 🎓 Luyện thi (Exam Prep)
│   ├── Đề minh họa THPT
│   ├── Đề theo dạng (Chain Rule, Trig...)
│   └── Timer + áp lực giống thi thật
│
└── 🎮 Trải nghiệm (Explore)
    ├── Học chậm, giải thích kỹ
    ├── Không timer
    └── Nhiều animation, hint miễn phí
```

### 7b. Hệ thống Tim (Lives) — Giống Duolingo

```
❤️ ❤️ ❤️  — 3 cơ hội

Sai 1 câu → ❤️ ❤️ 🖤
Sai 2 câu → ❤️ 🖤 🖤  
Sai 3 câu → 🖤 🖤 🖤 → "Hết lượt! Quay lại lúc 00:00 nhé 💤"

Hồi sinh:
- Tự động: +1 tim mỗi 8 giờ (max 3)
- Xem video review bài sai: +1 tim ngay
- Mời bạn bè: +1 tim
- Premium: ❤️ vô hạn
```

**Tâm lý:** Hệ thống tim tạo **scarcity** → user trân trọng mỗi lượt → suy nghĩ kỹ hơn thay vì spam bừa.

### 7c. Plan học tập + Nhắc nhở

```
📅 Plan tuần của bạn:
┌────────┬─────────────────────────────┬────────┐
│ Thứ    │ Nội dung                    │ Status │
├────────┼─────────────────────────────┼────────┤
│ Thứ 2  │ Ôn công thức cơ bản        │ ✅     │
│ Thứ 3  │ Luyện 10 bài Chain Rule    │ ⬜     │
│ Thứ 4  │ Quiz tổng hợp              │ ⬜     │
│ Thứ 5  │ Review bài sai             │ ⬜     │
│ Thứ 6  │ Thử thách: 20 bài/15 phút │ ⬜     │
│ Thứ 7  │ Nghỉ ngơi 🧘              │ ⬜     │
│ CN     │ Mini test đánh giá tuần    │ ⬜     │
└────────┴─────────────────────────────┴────────┘
```

Push notification: "⏰ 19:00 rồi! Hôm nay bạn cần luyện 10 bài Chain Rule. Bắt đầu thôi!"

---

## 8. Chụp Hình + Linh Vật — Gamification Cảm Xúc

### 8a. Feature "Tương lai của bạn"

**Flow:**
1. User chụp ảnh selfie
2. AI xử lý ảnh → biến thành **avatar hoạt hình** (style Ghibli/chibi)
3. Hiển thị: "Nếu bạn chăm chỉ, tương lai bạn sẽ là..." → avatar mặc áo cử nhân/tiến sĩ
4. Avatar này trở thành **profile picture** của user

**Công nghệ:** Dùng Stable Diffusion API hoặc các AI avatar service (Lensa-like) — hoặc đơn giản hơn: cho user chọn từ bộ template avatar có sẵn.

### 8b. Linh vật (Mascot System)

```
🐱 Mèo Toán — Dễ thương, kiên nhẫn (cho Beginner)
🦊 Cáo Thông Minh — Nhanh nhẹn, thử thách (cho Advanced)  
🐢 Rùa Kiên Trì — Chậm mà chắc (cho user hay bỏ dở)
🦉 Cú Đêm — Học khuya hiệu quả (cho user học 21:00+)
```

- Linh vật **thay đổi biểu cảm** theo performance: vui khi đúng, buồn khi sai, ngủ khi AFK
- Chatbot **nhân cách hóa** theo linh vật: "Mèo Toán thấy bạn giỏi quá! 🐱"
- User có thể **unlock linh vật mới** bằng XP → collection motivation

---

## 9. Toán Học: LaTeX + MANIM + AI Chain Lỗi

### 9a. LaTeX rendering

**Hiện trạng:** Cần đảm bảo tất cả công thức toán hiển thị đẹp.

**Flutter packages:** `flutter_math_fork` hoặc `katex_flutter`

```dart
// Ví dụ render LaTeX
Math.tex(r'\frac{d}{dx}[\sin(x)] = \cos(x)')
```

### 9b. MANIM — Animation giải toán

**MANIM** (Mathematical Animation Engine) tạo video animation giải thích bước giải:

- Pre-render các animation cho từng dạng bài phổ biến
- Khi user sai → play animation tương ứng thay vì chỉ hiện text
- Ví dụ: Animation vẽ đồ thị hàm số, rồi highlight tiếp tuyến, rồi hiện công thức đạo hàm

**Triển khai thực tế cho MVP:**
- Pre-render 20-30 animation clips bằng MANIM → lưu MP4 trên CDN
- Map mỗi clip với hypothesis/error type
- Khi cần → stream video clip tương ứng

### 9c. AI chain lỗi

**Ý nghĩa:** Khi user mắc lỗi, AI không chỉ nói "sai" mà **trace ngược chuỗi lỗi**:

```
User sai câu: Đạo hàm sin(2x)
│
├── Lỗi bề mặt: Quên nhân 2 (hệ số bên trong)
│   └── Lỗi gốc: Chưa hiểu Chain Rule
│       └── Lỗi nền tảng: Chưa nắm hàm hợp
│
→ AI recommends: "Bạn cần ôn lại khái niệm hàm hợp trước,
   rồi mới học Chain Rule nhé!"
```

Đây chính là thế mạnh của **Bayesian Hypothesis Tracking** đã có — cần làm nó rõ ràng hơn trong UI.

---

## 10. Nhắc Lịch Qua Google Calendar

**Triển khai:**
- Dùng **Google Calendar API** để tạo event tự động
- Khi AI tạo plan học → sync sang Google Calendar của user
- User nhận notification từ GCal (đã quen dùng) → không cần build notification riêng

```
📅 Google Calendar Event:
Title: "GrowMate — Luyện 10 bài Chain Rule"
Time: 19:00 - 19:20
Description: "Mở app GrowMate để bắt đầu!"
Reminder: 15 phút trước
Recurrence: Thứ 2-6
```

**Flutter package:** `googleapis` + `google_sign_in` cho OAuth2

---

## 11. Chi Tiết Phần Tiến Trình — Sổ Tay Công Thức

**Hiện trạng:** ProgressPage hiện mastery % theo topic chung chung ("Đạo hàm — 65%").

**Mentor muốn:** Chi tiết hơn, biến thành **sổ tay tra cứu**:

```
📊 Tiến trình Đạo hàm:
├── ✅ Bỏ túi công thức cơ bản (đã thuộc)
│   ├── (sin x)' = cos x
│   ├── (cos x)' = -sin x
│   └── (eˣ)' = eˣ
│
├── 🔄 Đang học: Chain Rule (60%)
│   ├── Công thức: [f(g(x))]' = f'(g(x)) · g'(x)
│   └── Ví dụ mẫu: sin(2x) → 2cos(2x)
│
└── 🔒 Chưa mở: Product Rule
    └── Cần hoàn thành Chain Rule trước
```

**Giá trị:** User mở app **không chỉ để quiz**, mà còn để **tra công thức** → tăng DAU (Daily Active Users). Giống như Notion nhưng cho công thức toán.

---

## 12. AI Chain Câu Hỏi Theo Template + Chunking Dữ Liệu

### 12a. Chain câu hỏi theo template

**Ý nghĩa:** Thay vì soạn thủ công hàng trăm câu hỏi, dùng AI để **sinh câu hỏi tự động** từ template:

```yaml
# Template
template: "Tính đạo hàm của {func}"
func_pool:
  - "sin({a}x)"        # a = random[2,3,4,5]
  - "cos({a}x + {b})" 
  - "e^({a}x)"
  - "{a}x^{n}"         # n = random[2,3,4]

# AI chain:
# 1. Chọn template → fill biến → tạo câu hỏi
# 2. AI tính đáp án → verify bằng symbolic math (SymPy)
# 3. AI tạo 3 đáp án sai (distractor) dựa trên common mistakes
# 4. Gắn metadata: difficulty, hypothesis_tag, topic
```

### 12b. Chunking dữ liệu (Google Draft System API)

**Ý nghĩa:** Khi có lượng lớn nội dung giáo trình, cần **chunking** (chia nhỏ) để:
- Embedding vectors cho RAG (Retrieval-Augmented Generation)
- Chatbot search đúng phần nội dung liên quan thay vì nhét cả sách vào prompt

```
Giáo trình Đạo hàm (50 trang)
    ↓ Chunking
├── Chunk 1: "Định nghĩa đạo hàm" (500 tokens)
├── Chunk 2: "Công thức cơ bản" (400 tokens)
├── Chunk 3: "Chain Rule" (600 tokens)
├── Chunk 4: "Bài tập mẫu Chain Rule" (500 tokens)
└── ...

User hỏi: "Chain rule là gì?"
    → Embedding search → match Chunk 3
    → Gửi Chunk 3 + System prompt vào LLM
    → Tiết kiệm token, trả lời chính xác hơn
```

**Google Generative AI API** (Gemini) hỗ trợ `Document` chunking + embedding native.

---

## Tóm Tắt Ưu Tiên Sprint Tiếp Theo

| Ưu tiên | Việc | Effort |
|---------|------|--------|
| 🔴 P0 | Thu hẹp scope → 1 chủ đề duy nhất | Thấp |
| 🔴 P0 | Viết chatbot policy (allowed/disallowed) | Thấp |
| 🔴 P0 | Thêm if-else fast-path + token limit | Trung bình |
| 🟠 P1 | Hệ thống tim (lives) + daily reset | Trung bình |
| 🟠 P1 | Leaderboard + badge vinh danh | Trung bình |
| 🟠 P1 | Sổ tay công thức trong Progress | Trung bình |
| 🟡 P2 | Chống leak (FLAG_SECURE, server-side answer) | Trung bình |
| 🟡 P2 | Kahoot-style multiplayer quiz | Cao |
| 🟡 P2 | Google Calendar integration | Trung bình |
| 🔵 P3 | MANIM animations | Cao |
| 🔵 P3 | Linh vật + avatar AI | Cao |
| 🔵 P3 | STT / Voice chat | Trung bình |
