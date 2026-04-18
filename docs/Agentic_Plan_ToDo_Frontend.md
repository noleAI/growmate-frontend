# 🎨 Chi Tiết Implementation To-Do List (Frontend Agentic Upgrade)

> File này liệt kê các task cần thiết cho **Frontend (Huy)** để bắt tay (integrate) với kiến trúc Agentic mới từ Backend. Mục tiêu: Nhẹ nhàng, dùng lại UI có sẵn hoặc bổ sung animation đơn giản để hoàn thành trong 1 ngày cuối.

---

## 📌 P0: BẮT BUỘC (Hoàn thành buổi sáng để gộp API)

### [ ] Task 1: Dọn đường - Cập nhật Model và Repository
*Gắn schema mới để Flutter đọc được data "Agentic" từ API.*
- **File cần sửa:** `lib/features/quiz/data/models/...` hoặc các API models liên quan đến `submit` và `interact`.
- **Hành động:**
  1. Parse thêm trường `is_intervened: bool` (nếu null mặc định là `false`).
  2. Parse thêm trường `agent_actions: List<AgentActionModel>` (nếu null mặc định mảng rỗng `[]`).
  3. Khởi tạo class `AgentActionModel` gồm `String actionType` và `Map<String, dynamic>? payload`.

### [ ] Task 2: Handler cho Proactive Interruption (Can Thiệp Chủ Động)
*Xử lý cờ ngắt luồng quiz khi user bị cuốn vào chuỗi sai/spam.*
- **File cần sửa:** `QuizCubit` hoặc `SessionBloc` & UI Screen (`battle_quiz_page.dart`...).
- **Hành động:**
  1. Khi nhận response từ API có `is_intervened == true`, **KHÔNG** load câu hỏi tiếp theo 🤡.
  2. Dùng text trong `content` backend trả về để hiện một cảnh báo (chọn 1 trong 2 cách):
      - *Nhanh nhất:* Bắn một cái `Snackbar` hiện chữ đậm dạng: *"🤖 Khoan đã! Bạn đang vội, mình tạm khoá lại để bạn bình tĩnh nhé!"*
      - *Đẹp hơn:* Hiện bottom sheet hoặc dialog popup chứa text.
  3. Sau khi user tắt dialog, Quiz vẫn đứng yên ở luồng cũ chờ submit lại hoặc cho nút "Đi tới sổ tay ôn tập".

### [ ] Task 3: Xử Lý Context-Aware Reasoning
*Render nội dung cá nhân hoá do LLM sinh ra.*
- **File cần sửa:** Widget hiển thị lời giải / Hint (ví dụ: `explanation_card.dart` hoặc chat item).
- **Hành động:**
  1. Lời giải bây giờ sẽ mang giọng điệu cá nhân hoá cao (có thể kèm các markdown list, bolding theo level của học sinh).
  2. Đảm bảo Widget render được đầy đủ markdown, emoji và cả LaTeX (dùng `flutter_math_fork`).
  3. (Tuỳ chọn) Nếu đang có avatar/mascot trên màn hình, khi render đoạn text này, thêm hiệu ứng mascot vẫy tay hoặc expression `mascot.talk()`.

---

## 📌 P1: NICE-TO-HAVE (Làm buổi chiều, tuỳ thời gian)

### [ ] Task 4: Toolkit Action Switch-case (AI điều kiển App)
*Biến App thành "con rối" dưới lệnh của Agent.*
- **File cần sửa:** `QuizCubit` hoặc `OrchestratorListener` (nơi xử lý event từ API xong).
- **Hành động:**
  1. Viết một hàm `handleAgentActions(List<AgentActionModel> actions)`.
  2. Lặp qua danh sách, switch-case biến `actionType`:
      ```dart
      switch (action.actionType) {
        case 'give_bonus_life':
          // Bắn pháo hoa (Confetti), hiện Toast: "Robot tặng bạn 1 tim vì cố gắng!"
          // Gọi hàm livesCubit.increaseLocalLife() để sync UI
          break;
        case 'open_handbook':
          // Pop ra màn hình Formula Handbook trỏ đúng vào topic_id (trong payload)
          break;
        case 'take_break':
          // Hiện Timer đếm ngược 1 phút bắt nghỉ ngơi.
          break;
      }
      ```
  3. Chỉ cần code bắt case `give_bonus_life` là demo sẽ rất "Agentic" và wow!

### [ ] Task 5: Auto-suggest Next Topic Wrap-up
*Khi làm xong quiz, agent chặn đường khuyên làm gì tiếp.*
- **File cần sửa:** Result Screen (`session_result_page.dart`).
- **Hành động:**
  1. Màn hình Result thường hiện Điểm, XP, Badges. Giờ thêm mục: **🕵️ Lời khuyên của Agent**.
  2. Lấy data từ `next_suggested_topic` hoặc cục action ở API End Session.
  3. Design 1 nút nổi bật (Outline button) như: `[ Ôn ngay Công thức Hàm Lượng Giác ]`, bấm vào thì push sang màn Progress sổ tay CT.

---

## 📝 Bí Kíp Sống Sót 1 Ngày Cuối (Dành cho Huy)
1. Hãy bắt đầu từ **Task 1 & 2** cùng lúc với Hưng (Backend) đang sửa Schema để tránh bị block.
2. Dùng lại hết tất cả Dialog/Toast/Confetti đã có trong app. Đừng design gì mới! "Agentic" ở đây là *AI tự gọi UI* chứ không phải *UI xịn xò chưa từng có*.
3. Test kĩ phần render text Markdown ở `Task 3` kẻo vỡ giao diện. Dữ liệu AI trả đôi khi hơi dài dại.
