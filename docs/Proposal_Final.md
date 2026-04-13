# HỒ SƠ DỰ ÁN
## GDGoC HACKATHON VIETNAM 2026

**Tên đội:** noleAI

### Thành viên

| STT | Họ và tên | Vai trò |
|-----|-----------|---------|
| 1 | Phùng Bảo Khang | Team Leader / AI Architect |
| 2 | Nguyễn Minh Đức | Backend & Agent Developer |
| 3 | Hy Huê Hưng | Data/API Integration & Prompt Designer |
| 4 | Thái Quang Huy | Product Owner / UX-UI / Flutter Dev |

---

# GROWMATE
### *Your smart and friendly study partner*

---

## Mục lục

1. [TÓM TẮT ĐIỀU HÀNH](#1-tóm-tắt-điều-hành)
2. [PHÂN TÍCH VẤN ĐỀ](#2-phân-tích-vấn-đề)
3. [GIẢI PHÁP: KIẾN TRÚC AGENTIC MULTI-AGENT](#3-giải-pháp-kiến-trúc-agentic-multi-agent)
4. [THIẾT KẾ KỸ THUẬT & KIẾN TRÚC HỆ THỐNG](#4-thiết-kế-kỹ-thuật--kiến-trúc-hệ-thống)
5. [YÊU CẦU CHỨC NĂNG & PHẠM VI TRIỂN KHAI](#5-yêu-cầu-chức-năng--phạm-vi-triển-khai)
6. [TRẢI NGHIỆM NGƯỜI DÙNG & ĐẠO ĐỨC AI](#6-trải-nghiệm-người-dùng--đạo-đức-ai)
7. [TÁC ĐỘNG, MÔ HÌNH KINH DOANH & ĐO LƯỜNG THÀNH CÔNG](#7-tác-động-mô-hình-kinh-doanh--đo-lường-thành-công)
8. [TÍNH KHẢ THI, KẾ HOẠCH THỰC HIỆN & RỦI RO](#8-tính-khả-thi-kế-hoạch-thực-hiện--rủi-ro)
9. [KẾT LUẬN & LỜI KÊU GỌI HÀNH ĐỘNG](#9-kết-luận--lời-kêu-gọi-hành-động)

---

## 1. TÓM TẮT ĐIỀU HÀNH

### 1.1. THÔNG ĐIỆP CỐT LÕI

GrowMate là hệ thống Gia sư AI Đa tác tử (Multi-Agent AI Tutor) với kiến trúc Agentic thực thụ, được xây dựng dựa trên bốn cơ chế kỹ thuật kiểm chứng được, loại bỏ hoàn toàn sự phụ thuộc vào suy luận không ổn định của LLM cho các quyết định quan trọng:

1. **Bayesian Hypothesis Tracking** (Theo dõi giả thuyết bằng xác suất Bayes): Hệ thống chẩn đoán lỗ hổng kiến thức bằng cách duy trì và cập nhật liên tục phân phối niềm tin (belief distribution) trên không gian giả thuyết. Mỗi tương tác của học sinh là một bằng chứng (evidence) được sử dụng để cập nhật xác suất hậu nghiệm theo định luật Bayes, với hàm hợp lý (likelihood) được học từ dữ liệu lỗi thực tế, đảm bảo độ tin cậy và khả năng hiệu chuẩn (calibration).

2. **HTN Planning với Plan Repair** (Lập kế hoạch phân cấp và tự sửa chữa): Lộ trình học tập được biểu diễn dưới dạng cây nhiệm vụ phân cấp (Hierarchical Task Network) với các điều kiện tiên quyết và hiệu ứng rõ ràng. Khi gặp phản hồi bất ngờ hoặc thất bại, Agent thực hiện chẩn đoán nguyên nhân và áp dụng chiến lược sửa chữa cục bộ (local repair) để điều chỉnh kế hoạch, thay vì xóa bỏ và sinh lại kế hoạch từ đầu.

3. **Particle Filter State Estimation** (Ước lượng trạng thái bằng bộ lọc hạt): Trạng thái tinh thần của học sinh (tập trung, bối rối, kiệt sức, thất vọng) được mô hình hóa như một biến ẩn (hidden state) và được ước lượng trực tuyến thông qua bộ lọc hạt (Particle Filter). Cơ chế này cung cấp khả năng lượng hóa độ bất định (uncertainty quantification), cho phép hệ thống tự nhận biết khi nào niềm tin chưa đủ vững để ra quyết định tự chủ và cần kích hoạt cơ chế con người trong vòng lặp (HITL).

4. **RL Strategy Policy với Memory Consolidation** (Chính sách chiến lược học tăng cường và hợp nhất bộ nhớ): Hệ thống duy trì bộ nhớ đa thành phần gồm bộ nhớ tình tiết (episodic), bộ nhớ ngữ nghĩa (semantic) và bảng giá trị chiến lược (Q-table). Chính sách lựa chọn hành động được tối ưu hóa liên tục thông qua học tăng cường (Q-Learning) dựa trên phản hồi thực tế, giúp hệ thống thích nghi với sở thích và phản ứng của từng học sinh, cải thiện chất lượng quyết định theo thời gian.

**Khác biệt then chốt:** Mọi quyết định của GrowMate đều xuất phát từ các mô hình xác suất đã được hiệu chuẩn và chính sách học được từ dữ liệu, không phải từ các luật cứng hay suy luận văn bản của LLM. Hệ thống có cơ chế tự giám sát (self-monitoring), tự đo lường độ bất định và minh bạch hóa quá trình ra quyết định thông qua nhật ký kiểm toán (audit log) và bảng điều khiển trạng thái nội bộ.

---

### 1.2. VẤN ĐỀ CỐT LÕI & CƠ HỘI

Theo báo cáo của UNICEF Việt Nam và Bộ GD&ĐT (2024), hơn 50% học sinh THPT chịu áp lực thành tích nặng nề và khoảng 20% thanh thiếu niên gặp vấn đề sức khỏe tâm thần liên quan đến học tập. Qua khảo sát nội bộ với n=120 học sinh và phỏng vấn sâu n=15 học sinh lớp 12, đội ngũ xác định hai vấn đề cấp bách mà các giải pháp hiện tại chưa giải quyết triệt để:

1. **Học mù quáng do thiếu chẩn đoán gốc rễ:** Đa số học sinh khi làm sai bài tập phức tạp không xác định được nguyên nhân thực sự, thường nhầm lẫn giữa hổng kiến thức nền tảng và lỗi kỹ thuật. Hệ quả là học sinh lãng phí thời gian làm lại các dạng bài tương tự mà không lấp được lỗ hổng cốt lõi.

2. **Kiệt sức vô hình do thiếu phát hiện trạng thái tinh thần:** Học sinh thường học liên tục trong thời gian dài mà không nhận ra dấu hiệu suy giảm hiệu suất hoặc bối rối tích tụ. Các công cụ hiện có chỉ dựa trên ngưỡng thời gian cứng nhắc, không có khả năng ước lượng trạng thái tinh thần từ tín hiệu hành vi đa chiều với lượng hóa độ bất định.

**Cơ hội thị trường:** GrowMate lấp đầy khoảng trống này bằng kiến trúc Agentic thực thụ, mang lại trải nghiệm học tập cá nhân hóa, hiệu quả và bền vững.

---

### 1.3. KIẾN TRÚC AGENTIC CỐT LÕI

GrowMate triển khai bốn cơ chế Agentic kiểm chứng được:

| Cơ chế | Mô tả tóm tắt | Giá trị mang lại | Kiểm chứng |
|--------|---------------|-----------------|------------|
| Bayesian Hypothesis Tracking | Duy trì và cập nhật phân phối niềm tin trên không gian giả thuyết nguyên nhân theo định luật Bayes khi nhận bằng chứng mới. | Chẩn đoán gốc rễ chính xác, lượng hóa độ tin cậy, tránh suy đoán sai. | Dashboard hiển thị belief evolution, entropy giảm, likelihood từ error model. |
| HTN Planning với Plan Repair | Biểu diễn lộ trình học tập dưới dạng cây nhiệm vụ phân cấp có ngữ nghĩa hình thức. Tự động sửa chữa cục bộ khi gặp thất bại mà không xóa kế hoạch. | Lộ trình linh hoạt, thích nghi với phản hồi thực tế, bảo toàn tiến độ đã đạt. | Dashboard hiển thị plan tree, repair event, failure diagnosis. |
| Particle Filter State Estimation | Ước lượng trạng thái tinh thần ẩn từ tín hiệu hành vi đa chiều qua bộ lọc hạt, cung cấp lượng hóa độ bất định và ra quyết định dựa trên expected utility. | Phát hiện sớm bối rối/kiệt sức, can thiệp phù hợp, kích hoạt HITL khi uncertainty cao. | Dashboard hiển thị particle distribution, uncertainty score, utility values. |
| RL Strategy Policy | Học chính sách lựa chọn chiến lược tối ưu qua Q-Learning dựa trên phản hồi thực tế, duy trì bộ nhớ đa thành phần để cải thiện quyết định theo thời gian. | Cá nhân hóa sâu, thích nghi với sở thích và phản ứng của từng học sinh. | Dashboard hiển thị Q-value updates, strategy shift, learning curve. |

**Minh bạch & Tự giám sát:** Mọi quyết định đều được ghi nhật ký kiểm toán (audit log) và hiển thị trạng thái nội bộ qua Inspection Dashboard. Hệ thống tự đo lường độ bất định và kích hoạt cơ chế Human-in-the-Loop khi độ tin cậy thấp.

---

### 1.4. LỘ TRÌNH PHÁT TRIỂN TRONG HACKATHON

#### Giai đoạn 1: MVP Core Agentic (06/04 – 17/04)

**Mục tiêu:** Xây dựng prototype end-to-end cho use-case cốt lõi (chẩn đoán lỗ hổng chuyên đề Đạo hàm và phát hiện trạng thái bối rối/kiệt sức), chứng minh 4 cơ chế Agentic hoạt động đúng thiết kế qua demo trực tiếp và inspection dashboard.

**Phạm vi trọng tâm:**
- Academic Agent: Bayesian Hypothesis Tracking với belief update, entropy, information gain; HTN Planning với plan repair cục bộ.
- Empathy Agent: Particle Filter State Estimation với 100 hạt, uncertainty quantification; decision dựa trên expected utility; HITL trigger.
- Memory System: Episodic store lưu experience tuple; Q-Learning strategy update từ reward người dùng.
- Orchestrator: Điều phối action dựa trên utility comparison và confidence thresholds.
- Giao diện: Flutter app tối giản (3 màn hình chính).
- Inspection Dashboard: Hiển thị realtime belief distribution, plan tree, particle distribution, Q-values, và decision log.
- Hạ tầng: FastAPI backend, Supabase database, Cloud Run deployment.

**Deliverable:**
- APK Android chạy ổn định, demo end-to-end không lỗi.
- Inspection dashboard hoạt động realtime, log minh bạch khớp hành động.
- Video demo dự phòng cho 4 kịch bản Agentic.
- Báo cáo kỹ thuật MVP mô tả cơ chế và kết quả kiểm chứng.

#### Giai đoạn 2: Hoàn thiện & Tối ưu Demo (18/04 – 09/05)

**Mục tiêu:** Mở rộng độ phủ kịch bản, tăng độ ổn định hệ thống, tinh chỉnh tham số mô hình, hoàn thiện UX và chuẩn bị demo chung kết.

**Lộ trình dài hạn (Post-Hackathon):**
- **Tháng 6-7/2026:** Triển khai beta với 200 học sinh, huấn luyện mô hình v1.
- **Tháng 8-9/2026:** Mở rộng đa môn (Lý, Hóa, Anh), tích hợp long-term memory.
- **Tháng 10-12/2026:** Hợp tác B2B với trường học, triển khai dashboard phụ huynh.
- **2027+:** Trở thành nền tảng gia sư AI chuẩn mực, hỗ trợ hàng trăm nghìn học sinh.

---

### 1.5. TÁC ĐỘNG DỰ KIẾN VÀ CHỈ SỐ ĐO LƯỜNG

#### 1.5.1. CÁC CHỈ SỐ TRỌNG YẾU (KEY HIGHLIGHTS)

- **Kiểm chứng cơ chế Agentic (MVP):** Chứng minh thành công 4 cơ chế kỹ thuật hoạt động đúng thiết kế thông qua Inspection Dashboard và audit log minh bạch.
- **Hiệu năng hệ thống:** Độ trễ chẩn đoán p95 < 4.5 giây trong MVP; tối ưu xuống < 3 giây cho bản demo chung kết.
- **Chất lượng mô hình:** Đạt Calibration Error (ECE) < 0.1 sau khi huấn luyện mô hình v1 trên dữ liệu thực; tỷ lệ hội tụ niềm tin > 80% trong tối đa 3 bằng chứng.
- **Tác động giáo dục:** Giảm 30-40% thời gian học vô ích; cải thiện điểm số dự kiến 1.0-1.5 điểm sau 4 tuần sử dụng.
- **Sức khỏe tinh thần:** Giảm 20-30% nguy cơ kiệt sức học đường; tỷ lệ false positive cho phát hiện mệt mỏi < 10%.
- **Tăng trưởng người dùng:** Tỷ lệ duy trì (Retention) > 60% sau 7 ngày; tỷ lệ chuyển đổi free-to-paid đạt 3-5%.

#### 1.5.2. CHIẾN LƯỢC ĐO LƯỜNG VÀ BÁO CÁO

1. **Hackathon:** Tập trung kiểm chứng cơ chế qua inspection dashboard và log minh bạch.
2. **Giai đoạn 2:** Bắt đầu thu thập metrics chất lượng mô hình từ testing nội bộ.
3. **Post-Hackathon:** Triển khai evaluation suite đầy đủ với dữ liệu thực.

#### 1.5.3. TÁC ĐỘNG XÃ HỘI KỲ VỌNG

1. **Bình đẳng hóa giáo dục:** Cung cấp gia sư AI chất lượng cao với chi phí tiếp cận thấp.
2. **Bảo vệ sức khỏe tinh thần:** Giảm nguy cơ kiệt sức học đường thông qua phát hiện sớm và can thiệp phù hợp.
3. **Hỗ trợ phụ huynh và giáo viên:** Cung cấp công cụ chẩn đoán và báo cáo minh bạch.
4. **Đổi mới công nghệ giáo dục:** Tiên phong ứng dụng Agentic AI thực thụ với kiến trúc kiểm chứng được.

---

## 2. PHÂN TÍCH VẤN ĐỀ

### 2.1. VẤN ĐỀ THỰC TRẠNG

Học sinh lớp 12 Việt Nam đang đối mặt với hai thách thức lớn trong quá trình ôn thi THPT Quốc gia:

1. **Mất phương hướng trong chẩn đoán lỗi sai:** Khi làm sai bài tập, đặc biệt là các dạng toán phức tạp như Tích phân hay Hàm số, đa số học sinh không thể tự xác định nguyên nhân gốc rễ. Nhiều em nhầm lẫn giữa hổng kiến thức nền tảng (Đạo hàm, Giới hạn) và lỗi kỹ thuật (tính toán, đọc đề).

2. **Kiệt sức tích tụ không được phát hiện:** Học sinh thường duy trì các phiên học kéo dài liên tục trên 2 giờ do áp lực điểm số. Các dấu hiệu suy giảm hiệu suất thường bị bỏ qua cho đến khi học sinh rơi vào trạng thái kiệt sức.

3. **Thiếu công cụ đồng hành thích nghi và thấu cảm:** Học sinh cần một hệ thống không chỉ cung cấp nội dung học tập mà còn có khả năng điều chỉnh chiến lược dựa trên phản hồi liên tục.

---

### 2.2. CÁC BÊN LIÊN QUAN (STAKEHOLDERS)

**Học sinh lớp 12 (Người dùng chính):**
- **Nhu cầu:** Lộ trình học tập rõ ràng, công cụ chẩn đoán chính xác, cơ chế nhắc nhở nghỉ ngơi hợp lý.
- **Mối quan tâm:** Sợ bị giám sát quá mức, lo ngại về quyền riêng tư dữ liệu hành vi.

**Phụ huynh (Người chi trả và hỗ trợ):**
- **Nhu cầu:** Thông tin minh bạch về tiến độ học tập của con.
- **Mối quan tâm:** Lo ngại con học vẹt hoặc phụ thuộc quá mức vào công cụ.

**Giáo viên và Nhà trường (Đối tác hỗ trợ):**
- **Nhu cầu:** Công cụ chẩn đoán nhanh, báo cáo tổng hợp theo lớp.
- **Mối quan tâm:** Thiếu công cụ tích hợp với hệ thống hiện có.

---

### 2.3. PAIN POINTS VÀ GIẢI PHÁP TƯƠNG ỨNG

**Pain Point 1: Học mù quáng – Không xác định được lỗ hổng gốc rễ**
- **Giải pháp:** Academic Agent sử dụng Bayesian Hypothesis Tracking để duy trì phân phối xác suất trên không gian giả thuyết nguyên nhân.

**Pain Point 2: Kiệt sức và bối rối vô hình**
- **Giải pháp:** Empathy Agent sử dụng Particle Filter State Estimation để ước lượng trạng thái tinh thần từ tín hiệu hành vi đa chiều.

**Pain Point 3: Lộ trình cứng nhắc – Không thích nghi với phản hồi thực tế**
- **Giải pháp:** HTN Planning với Plan Repair cho phép biểu diễn kế hoạch dưới dạng cây nhiệm vụ phân cấp có ngữ nghĩa hình thức.

**Pain Point 4: Thiếu công cụ phục hồi kịp thời**
- **Giải pháp:** Recovery Mode với nội dung nhẹ nhàng (flashcard, lý thuyết tóm tắt, bài tập đơn giản).

**Pain Point 5: Chiến lược can thiệp không cá nhân hóa**
- **Giải pháp:** RL Strategy Policy với Memory Consolidation cho phép hệ thống học chính sách lựa chọn chiến lược tối ưu cho từng học sinh.

**Pain Point 6: Phụ huynh thiếu thông tin tổng quan**
- **Giải pháp:** Báo cáo tổng hợp định kỳ hiển thị tiến độ lấp lỗ hổng và xu hướng trạng thái tinh thần.

**Pain Point 7: Thiếu cơ chế kiểm chứng mastery trước khi chuyển chủ đề**
- **Giải pháp:** Hệ thống tự động đánh giá mức độ thành thạo dựa trên lịch sử tương tác và kết quả quiz.

---

### 2.4. PHÂN TÍCH ĐỐI THỦ CẠNH TRANH

**Nhóm 1: Nền tảng khóa học và kho đề (Hocmai, Viettel Study, VioEdu)**
- Điểm mạnh: Nội dung phong phú, kho đề lớn bám sát chương trình.
- Điểm yếu: Không có cơ chế chẩn đoán gốc rễ dựa trên xác suất; không có phát hiện trạng thái tinh thần từ hành vi.

**Nhóm 2: Nền tảng học tập thích nghi quốc tế (Khan Academy, Duolingo)**
- Điểm mạnh: Hệ thống mastery learning bài bản, miễn phí.
- Điểm yếu: Không hỗ trợ tiếng Việt sâu và không bám sát chương trình THPT Việt Nam.

**Nhóm 3: Chatbot AI tổng quát (ChatGPT, Gemini, Claude)**
- Điểm mạnh: Khả năng giải thích linh hoạt bằng ngôn ngữ tự nhiên.
- Điểm yếu: Không có đồ thị tri thức có cấu trúc để truy vết lỗ hổng; không có bộ nhớ dài hạn cá nhân hóa.

**Nhóm 4: Ứng dụng quản lý thời gian và tập trung (Forest, Focus To-Do)**
- Điểm mạnh: Hỗ trợ quản lý thời gian học tập.
- Điểm yếu: Chỉ tập trung vào đếm thời gian, không hiểu ngữ cảnh học tập.

**Kết luận:** Chưa có giải pháp nào trên thị trường tích hợp đồng thời bốn cơ chế Agentic thực thụ mà GrowMate hướng đến.

---

### 2.5. PERSONAS VÀ EMPATHY MAPPING

**Persona chính: Nguyễn Thị Lan Anh, 17 tuổi**
- Học sinh lớp 12 chuyên Toán, trường THPT Chuyên Lê Hồng Phong, TP.HCM.
- Mục tiêu: Đạt 9.0+ môn Toán THPTQG.
- Hiện trạng: Học lực khá (21-22 điểm thử), kẹt ở mức này suốt 3 tháng dù dành 3-4 tiếng mỗi ngày ôn Toán.
- Pain point: *"Em làm rất nhiều đề Tích phân nhưng vẫn sai những câu vận dụng. Em không biết mình yếu phần nào..."*

**Empathy Map:**
- **Nghĩ và Cảm thấy:** Áp lực phải đạt điểm cao, mệt mỏi nhưng không muốn thừa nhận.
- **Nghe:** Phụ huynh nhắc nhở học tập, giáo viên nhấn mạnh tầm quan trọng kỳ thi.
- **Thấy:** Đề thi thử với nhiều câu khó, đồng hồ đếm ngược thời gian.
- **Nỗi đau:** Lãng phí thời gian học vô ích, không biết gốc rễ vấn đề, kiệt sức tích tụ.
- **Kỳ vọng:** Công cụ chẩn đoán chính xác lỗ hổng, lộ trình linh hoạt, trải nghiệm học tập nhẹ nhàng và tích cực.

---

### 2.6. USER JOURNEY MAPPING

**Hành trình hiện tại (không có GrowMate):**
1. Mở kho đề, chọn ngẫu nhiên đề Tích phân → choáng ngợp với danh sách bài dài.
2. Làm sai, xem lời giải nhưng không hiểu tại sao sai → cảm giác bối rối tăng dần.
3. Học 2 tiếng liên tục không nghỉ → hiệu suất giảm mạnh.
4. Kết thúc với cảm giác mệt mỏi và tự trách.

**Hành trình với GrowMate:**
1. Màn hình hiển thị đề xuất ôn tập rõ ràng dựa trên phiên trước → cảm thấy an tâm.
2. Academic Agent phân tích lỗi → belief hội tụ về "Hổng Đạo hàm" → hỏi xác nhận trước khi chuyển.
3. Ôn tập đúng trọng tâm → cảm giác tiến bộ rõ rệt.
4. Kết thúc phiên tích cực với tổng kết rõ ràng.

---

### 2.7. YÊU CẦU DỮ LIỆU VÀ CHIẾN LƯỢC KHỞI TẠO

#### 2.7.1. CHIẾN LƯỢC PHÂN TẦNG DỮ LIỆU

| Giai đoạn | Nguồn tham số | Mục đích | Cơ chế kỹ thuật |
|-----------|--------------|---------|----------------|
| MVP (Hackathon) | Expert Priors & Synthetic Data | Chứng minh cơ chế Agentic | Tham số nạp qua file cấu hình (JSON/YAML) |
| Giai đoạn 2 | Tinh chỉnh từ Log & Testing | Tối ưu tham số cho use-case demo | Grid search nhỏ trên tập log |
| Post-Hackathon | Dữ liệu thực & Huấn luyện ML | Đạt độ chính xác và calibration tối ưu | Tích hợp qua abstraction layer |

#### 2.7.2. YÊU CẦU DỮ LIỆU CHO MVP (06/04 – 17/04)

| Loại dữ liệu | Mô tả | Nguồn | Khối lượng | Sử dụng |
|-------------|-------|-------|-----------|---------|
| Knowledge Graph | Đồ thị tri thức chuyên đề Đạo hàm với node khái niệm và quan hệ prerequisite | Xây dựng thủ công | 15 node, ~20 cạnh | Cung cấp cấu trúc truy vết cho Bayesian tracking |
| Task Library | Thư viện tác vụ HTN | Định nghĩa bởi AI Architect và PO | 8-10 methods cơ bản | Sinh plan tree |
| Expert Priors | Xác suất tiên nghiệm cho không gian giả thuyết | Ước lượng bởi giáo viên chuyên môn | 5 giá trị prior | Khởi tạo belief state |
| Quiz Bank | Ngân hàng câu hỏi kiểm tra chuyên đề Đạo hàm | Biên soạn thủ công | 15-20 câu hỏi | Cung cấp evidence cho chẩn đoán |
| Synthetic Users | Dữ liệu người dùng mô phỏng | Sinh tự động bằng script | 50 phiên mô phỏng | Kiểm thử luồng E2E |

---

## 3. GIẢI PHÁP: KIẾN TRÚC AGENTIC MULTI-AGENT

### 3.1. TỔNG QUAN KIẾN TRÚC MULTI-AGENT

GrowMate là hệ thống Gia sư AI Đa tác tử với kiến trúc Agentic thực thụ, được xây dựng dựa trên bốn cơ chế kỹ thuật kiểm chứng được. Hệ thống bao gồm ba tác tử chuyên biệt điều phối bởi Orchestrator, vận hành theo vòng lặp **Observe → Estimate → Decide → Act → Learn**:

- **Academic Agent:** Chẩn đoán lỗ hổng kiến thức bằng cách duy trì và cập nhật phân phối niềm tin trên không gian giả thuyết theo định luật Bayes. Lập kế hoạch học tập dưới dạng cây nhiệm vụ phân cấp (HTN) với khả năng tự sửa chữa cục bộ.

- **Empathy Agent:** Giám sát sức khỏe tinh thần bằng cách ước lượng trạng thái ẩn từ tín hiệu hành vi đa chiều qua bộ lọc hạt (Particle Filter). Ra quyết định can thiệp dựa trên cực đại hóa utility kỳ vọng.

- **Memory System:** Duy trì bộ nhớ đa thành phần và học chính sách lựa chọn chiến lược tối ưu qua Q-Learning.

- **Orchestrator:** Điều phối đa mục tiêu, tổng hợp trạng thái từ các agent, áp dụng policy logic để chọn hành động tối ưu, và thực hiện tự giám sát dựa trên độ bất định để kích hoạt HITL.

**Luồng xử lý tổng quát:**
1. **Observe:** Thu thập câu trả lời, tín hiệu hành vi, và phản hồi.
2. **Estimate:** Cập nhật belief về lỗ hổng kiến thức và trạng thái tinh thần.
3. **Decide:** Tổng hợp trạng thái, tính action distribution, đánh giá uncertainty.
4. **Act:** Thực thi hành động thông qua công cụ tương ứng.
5. **Learn:** Ghi nhận outcome và reward, cập nhật Q-values.

---

### 3.2. ACADEMIC AGENT: BAYESIAN HYPOTHESIS TRACKING VÀ HTN PLANNING

#### 3.2.1. KHÔNG GIAN GIẢ THUYẾT VÀ ABSTRACTION LAYER

Không gian giả thuyết định nghĩa tập hợp các nguyên nhân có thể giải thích lỗi sai của học sinh. Mỗi giả thuyết được biểu diễn dưới dạng đối tượng có cấu trúc:
- `id`: Định danh duy nhất (ví dụ: H_DERIV_GAP, H_CALC_ERR).
- `description`: Mô tả ngữ nghĩa liên kết với khái niệm trong đồ thị tri thức.
- `prior`: Xác suất tiên nghiệm P(H).
- `likelihood_fn`: Hàm tính likelihood P(E|H) từ bằng chứng.

| Thành phần | MVP (Hackathon) | Giai đoạn 2 & Post-Hackathon |
|-----------|----------------|------------------------------|
| Prior P(H) | Khởi tạo từ expert knowledge. Ví dụ: P(H_DERIV_GAP) = 0.35 | Học từ phân phối lỗi thực tế |
| Likelihood P(E\|H) | Expert rules định nghĩa dạng bảng hoặc hàm heuristic | Giữ nguyên interface predict_likelihood() |
| Abstraction | Codebase sử dụng ErrorModelInterface, nạp expert config từ JSON | Nạp trained model weights từ Model Registry |

#### 3.2.2. CƠ CHẾ CẬP NHẬT BAYES

Khi học sinh đưa ra câu trả lời hoặc thực hiện hành động, hệ thống xử lý như bằng chứng E và cập nhật phân phối niềm tin theo định luật Bayes:

```
P(H | E) = [P(E | H) × P(H)] / P(E)
```

**Quy trình cập nhật:**
1. Truy vấn likelihood từ implementation hiện tại.
2. Tính joint probability = likelihood × prior.
3. Chuẩn hóa để thu được posterior distribution.
4. Cập nhật belief state, tính entropy và information gain.
5. Ghi log chi tiết.

#### 3.2.3. LỰA CHỌN QUIZ TỐI ĐA HÓA THÔNG TIN

Khi entropy > ngưỡng, Academic Agent chọn quiz có độ lợi thông tin kỳ vọng (EIG) cao nhất:

```
EIG(q) = Entropy(belief) - E[Entropy(belief | answer_q)]
```

#### 3.2.4. HTN PLANNING VỚI PLAN REPAIR

Kế hoạch học tập được biểu diễn dưới dạng Hierarchical Task Network (HTN):
- **Plan Tree:** Cây nhiệm vụ phân cấp với preconditions, effects, và status.
- **Task Library:** Định nghĩa phương pháp phân rã cho các goal chẩn đoán và remediation.
- **Plan Repair:** Khi gặp failure, Agent chẩn đoán nguyên nhân và áp dụng repair strategy cục bộ (insert, alternative, skip).

---

### 3.3. EMPATHY AGENT: PARTICLE FILTER STATE ESTIMATION

#### 3.3.1. MÔ HÌNH TRẠNG THÁI VÀ ABSTRACTION LAYER

Trạng thái tinh thần được mô hình hóa như biến ẩn với không gian trạng thái **S = {focused, confused, exhausted, frustrated}**. Mô hình bao gồm:
- **Transition Model P(s_t | s_{t-1}):** Mô tả động lực học chuyển trạng thái.
- **Observation Model P(signals | s):** Ánh xạ từ tín hiệu hành vi sang phân phối xác suất trạng thái.

#### 3.3.2. THUẬT TOÁN BỘ LỌC HẠT

Hệ thống duy trì tập hợp N hạt (mặc định 100) để xấp xỉ phân phối trạng thái. Với mỗi batch tín hiệu:
1. **Predict:** Sample trạng thái mới từ transition model.
2. **Update Weights:** Tính trọng số từ observation model likelihood.
3. **Resample:** Tái lấy mẫu để tránh suy biến.
4. **Estimate:** Tính belief distribution và uncertainty từ normalized entropy.

#### 3.3.3. RA QUYẾT ĐỊNH DỰA TRÊN EXPECTED UTILITY

```
EU(action) = Σ P(s | belief) × Utility(action, s)
```

---

### 3.4. MEMORY SYSTEM VÀ RL STRATEGY POLICY

#### 3.4.1. BỘ NHỚ ĐA THÀNH PHẦN

| Thành phần | Mô tả | Giai đoạn |
|-----------|-------|----------|
| Episodic Store | Lưu experience tuple (state, action, outcome, reward, timestamp) | MVP |
| Q-Table | Lưu giá trị Q(state, action) cho strategy selection. Cập nhật online qua Q-Learning | MVP |
| Semantic Store | Lưu trữ tri thức tổng hợp (patterns, statistics) trích xuất từ episodic memory | Phase 2 |
| Consolidation Job | Job định kỳ trích xuất patterns và cập nhật semantic memory | Phase 2 |

#### 3.4.2. CHÍNH SÁCH Q-LEARNING

```
Q(s, a) ← Q(s, a) + α × [r + γ × max Q(s', a') - Q(s, a)]
```

---

### 3.5. ORCHESTRATOR VÀ CƠ CHẾ TỰ GIÁM SÁT

#### 3.5.1. POLICY NETWORK ĐIỀU PHỐI

**Kiến trúc Policy Network:**
1. **Input:** State embedding tổng hợp từ Academic Agent, Empathy Agent, và Memory System.
2. **Architecture:** Multi-layer perceptron với 2-3 hidden layers, activation ReLU, output softmax cho action distribution.
3. **Output:** Phân phối xác suất trên tập hành động điều phối (diagnose, remediate, recover, encourage, hitl).

#### 3.5.2. HIỆU CHUẨN ĐỘ TIN CẬY VÀ HITL

Orchestrator tích hợp cơ chế hiệu chuẩn và tự giám sát:
- **Confidence Calibration:** Hiệu chuẩn bằng temperature scaling hoặc isotonic regression, duy trì ECE < 0.1.
- **Self-Monitoring và HITL:** Tính toán độ bất định tổng hợp từ Academic uncertainty, Empathy uncertainty, và Policy uncertainty. Nếu vượt ngưỡng → kích hoạt HITL.

---

### 3.6. BẢNG ÁNH XẠ GIẢI PHÁP – PAIN POINT

| Pain Point | Cơ chế Agentic giải quyết | Kết quả kỳ vọng |
|-----------|--------------------------|----------------|
| Học mù quáng, không biết lỗ hổng | Bayesian Hypothesis Tracking với likelihood hiệu chuẩn, truy vết trên đồ thị tri thức | Chẩn đoán gốc rễ chính xác >80%, giảm thời gian học vô ích 30-40% |
| Kiệt sức/bối rối vô hình | Particle Filter State Estimation với uncertainty quantification | Phát hiện sớm trạng thái, can thiệp phù hợp, giảm FPR <10% |
| Lộ trình cứng nhắc | HTN Planning với Plan Repair cục bộ | Kế hoạch thích nghi linh hoạt, không bị khóa vào kịch bản sai |
| Chiến lược không cá nhân hóa | RL Strategy Policy với Q-Learning | Chính sách tối ưu cho từng học sinh |
| Thiếu minh bạch quyết định | Inspection Dashboard với belief, plan, Q-values | Người dùng và BGK có thể kiểm tra trạng thái nội bộ |
| Phụ huynh thiếu thông tin | Báo cáo tổng hợp từ semantic memory | Phụ huynh nắm tiến độ và xu hướng |

---

### 3.7. ĐIỂM KHÁC BIỆT VÀ LỢI THẾ CẠNH TRANH

| Khía cạnh | Giải pháp hiện có | GrowMate |
|-----------|------------------|---------|
| Chẩn đoán lỗi | Lời giải tĩnh hoặc LLM suy luận không hiệu chuẩn | Bayesian tracking với likelihood từ error model hiệu chuẩn |
| Lập kế hoạch | Kịch bản cứng hoặc LLM sinh plan không cấu trúc | HTN plan tree với repair cục bộ, ngữ nghĩa hình thức |
| Phát hiện mệt mỏi | Ngưỡng thời gian/số lỗi cứng | Particle filter estimation với uncertainty, decision bằng utility |
| Thích nghi chiến lược | Rule-based hoặc EMA đơn giản | Q-Learning policy cải thiện liên tục từ feedback |
| Minh bạch | Không có hoặc log text | Dashboard inspect belief, plan, Q-values, decision rationale |
| Tự giám sát | Không có | Confidence calibration, HITL triggers dựa trên uncertainty |

---

### 3.8. BẢNG ĐẶC ĐIỂM AGENTIC KIỂM CHỨNG

| Đặc điểm | Triển khai kỹ thuật | Cơ chế kiểm chứng |
|---------|--------------------|--------------------|
| Planning | HTN với plan representation tree. Plan repair dựa trên failure diagnosis, sửa cục bộ không xóa plan. | Log: plan tree, failure diagnosis, repair strategy, plan modification. |
| Reasoning | Bayesian belief updating với likelihood từ error model. Uncertainty quantification bằng entropy. | Log: belief evolution, entropy reduction, information gain. Confidence calibrated (ECE < 0.1). |
| Autonomy | Policy network/RL policy chọn action. Decision có calibrated confidence. Self-monitoring trigger HITL. | Log: action distribution, confidence score, HITL trigger khi uncertainty cao. |
| Learning | Q-learning cập nhật strategy policy. Memory consolidation episodic → semantic. | Log: Q-value updates, strategy shift, learning curve qua sessions. |

---

## 4. THIẾT KẾ KỸ THUẬT & KIẾN TRÚC HỆ THỐNG

### 4.1. TỔNG QUAN KIẾN TRÚC

#### 4.1.1. MÔ HÌNH NGỮ CẢNH HỆ THỐNG (C1)

| Thực thể | Loại | Mô tả & Vai trò | Ghi chú MVP |
|---------|------|----------------|-------------|
| Học sinh | Người dùng chính | Tương tác trực tiếp với ứng dụng để làm bài tập, nhận chẩn đoán, và phản hồi đề xuất. | Demo trên thiết bị Android thật. HITL xác nhận thay đổi lộ trình. |
| Phụ huynh | Người dùng phụ | Xem báo cáo tổng hợp về tiến độ học tập và xu hướng sức khỏe tinh thần. | MVP hiển thị mock dashboard trong app. |
| Giáo viên/Chuyên gia | Đối tác hỗ trợ | Cung cấp expert priors, task library definitions, và tham gia gán nhãn dữ liệu. | MVP sử dụng expert knowledge đã định nghĩa sẵn. |
| GrowMate System | Hệ thống chính | Flutter App, FastAPI Backend, và Inspection Dashboard. | Live demo 2 luồng cốt lõi. Dashboard kiểm chứng realtime. |
| Supabase | Hệ thống ngoài | PostgreSQL, xác thực người dùng, Row Level Security. | Free tier. RLS bật sẵn. |
| Gemini API | Hệ thống ngoài | Hỗ trợ sinh nội dung giải thích khái niệm và thông điệp khích lệ. | Chỉ dùng cho content generation. Free tier đủ cho MVP. |
| Cloud Run | Hệ thống ngoài | Dịch vụ serverless triển khai backend. | Scale-to-zero, chi phí ~0 cho MVP. |

#### 4.1.2. MÔ HÌNH CONTAINER (C2)

| Container | Công nghệ | Chức năng chính | Ghi chú MVP |
|----------|----------|----------------|-------------|
| Flutter Mobile App | Flutter, Dart, flutter_bloc | Giao diện người dùng tối giản (De-stress UI), thu thập tín hiệu hành vi chính xác. | 3 màn hình chính. Batch metrics mỗi 5s. |
| Inspection Dashboard | Streamlit, Python | Hiển thị realtime trạng thái nội bộ: belief distribution, plan tree, particle state, Q-values, decision log. | Kết nối trực tiếp đến backend state stream. |
| FastAPI Backend | Python 3.11, FastAPI | API endpoints async, điều phối agent execution, quản lý session state, ghi audit log. | Serverless trên Cloud Run. |
| Orchestrator Engine | Python, NumPy | Tổng hợp trạng thái từ agents, thực thi policy logic, kích hoạt HITL, ghi audit log. | Policy logic deterministic cho MVP. |
| Academic Engine | Python, NumPy | Bayesian Tracker, HTN Planner, Plan Repair Engine. | Tham số prior/likelihood tải từ expert config. |
| Empathy Engine | Python, NumPy | Particle Filter Estimator, Utility Calculator. | Tham số observation/utility tải từ expert config. |
| Memory Engine | Python, Supabase | Episodic Store, Q-Learning Policy. | Q-table khởi tạo rỗng hoặc expert defaults. |
| Abstraction Layer | Python Interfaces | Định nghĩa ErrorModelInterface, ObservationModelInterface. | MVP chỉ dùng expert implementation nạp từ JSON/YAML. |
| Supabase Database | PostgreSQL, JSONB | Lưu trữ user data, đồ thị tri thức, episodic memory, expert config. | JSONB cho KG và config. TTL cho dữ liệu chi tiết. |
| Gemini API | Google Gemini Flash | Sinh nội dung giải thích khái niệm, lời khuyên, khích lệ. | Không dùng cho suy luận quyết định. |

---

### 4.4. TECH STACK & CÔNG NGHỆ

#### 4.4.1. BẢNG CÔNG NGHỆ PHÂN TẦNG

| Lớp | Công nghệ | Giai đoạn | Lý do lựa chọn |
|-----|----------|----------|----------------|
| Frontend | Flutter, Dart | MVP | Cross-platform (iOS/Android), hot reload, hiệu năng cao. |
| | flutter_bloc | MVP | Quản lý trạng thái reactive, tách biệt business logic và UI. |
| | Streamlit | MVP | Xây dựng inspection dashboard nhanh chóng với Python native. |
| Backend | Python 3.11 | MVP | Ngôn ngữ chuẩn cho AI/ML, hệ sinh thái thư viện phong phú. |
| | FastAPI | MVP | Framework web async hiệu năng cao. |
| | NumPy / SciPy | MVP | Tính toán số học tối ưu cho Bayesian updating, particle filter. |
| AI / Agentic | Abstraction Interfaces | MVP | Custom interfaces cho models, cho phép thay thế implementation. |
| | Expert Config (JSON/YAML) | MVP | Lưu trữ tham số expert priors, likelihood rules, utility table. |
| | Scikit-learn / XGBoost | Phase 2 | Huấn luyện error model và observation model. |
| | PyTorch | Phase 2 | Triển khai policy network. |
| | MLflow | Phase 2 | Quản lý vòng đời mô hình. |
| Database | Supabase (PostgreSQL) | MVP | JSONB, RLS, realtime subscriptions, auth tích hợp. |
| Deployment | Google Cloud Run | MVP | Serverless container, scale-to-zero, miễn phí cho mức độ thấp. |
| | GitHub Actions | MVP | CI/CD pipeline tự động. |
| Monitoring | Sentry | MVP | Theo dõi lỗi và performance. |
| LLM (Content) | Gemini 2.5 Flash | MVP | Tốc độ nhanh, chi phí thấp, phù hợp cho sinh nội dung. |

---

### 4.5. HIỆU NĂNG VÀ KHẢ NĂNG MỞ RỘNG

**Mục tiêu hiệu năng:**
- Độ trễ phản hồi: p95 latency dưới 3 giây cho tương tác chẩn đoán.
- Throughput: Hỗ trợ 200 người dùng đồng thời trong giai đoạn beta, scale lên 10.000 người dùng.
- Độ chính xác: Calibration error dưới 0.1, belief convergence trong tối đa 3 evidences cho 80% trường hợp.

**Tối ưu hóa:**
- Vectorization bằng NumPy.
- Caching kết quả truy vấn đồ thị tri thức và model predictions.
- Batch Processing tín hiệu hành vi mỗi 5 giây.
- Async Execution tách biệt luồng tính toán agent và ghi log/database.

---

### 4.6. BẢO MẬT VÀ RIÊNG TƯ

- **Mã hóa:** TLS 1.3 cho giao tiếp mạng, AES-256 cho dữ liệu at rest.
- **Row Level Security:** Áp dụng RLS trên Supabase.
- **Tuân thủ pháp lý:** Tuân thủ đầy đủ Nghị định 13/2023/NĐ-CP.
- **Data Minimization:** Tín hiệu hành vi chi tiết tự động xóa sau 24 giờ (TTL).

---

### 4.7. INSPECTION DASHBOARD

**Chức năng chính:**
- **Belief View:** Biểu đồ phân phối niềm tin qua thời gian, entropy curve, và information gain.
- **Plan View:** Cây kế hoạch HTN với màu sắc trạng thái nút, lịch sử repair, và failure diagnosis.
- **State Estimate View:** Phân phối hạt, belief distribution, uncertainty score, và utility values.
- **Q-Value View:** Bảng giá trị Q, learning curve qua sessions, và strategy shift history.
- **Decision Log:** Danh sách quyết định với rationale đầy đủ.

---

### 4.8. MA TRẬN KIỂM CHỨNG KỸ THUẬT

| Cơ chế | Thành phần kiểm chứng | Phương pháp | Kết quả kỳ vọng |
|--------|----------------------|------------|----------------|
| Bayesian Tracking | Belief evolution, entropy, likelihood | Log inspection, dashboard belief view | Belief hội tụ đúng giả thuyết, entropy giảm |
| HTN Planning | Plan tree, repair strategy, failure diagnosis | Log inspection, dashboard plan view | Plan repair cục bộ, không sinh lại, repair success rate >70% |
| Particle Filter | Particle distribution, uncertainty, utility | Log inspection, dashboard state view | Uncertainty lượng hóa chính xác, HITL trigger khi uncertainty cao |
| RL Policy | Q-value updates, learning curve, strategy shift | Log inspection, dashboard Q-value view | Q-values cải thiện, strategy thích nghi |
| Calibration | Confidence vs accuracy | Reliability diagram, ECE metric | ECE < 0.1, confidence phản ánh đúng accuracy |
| Self-Monitoring | HITL triggers, uncertainty thresholds | Log inspection, human evaluation | HITL accuracy >85% |

---

## 5. YÊU CẦU CHỨC NĂNG & PHẠM VI TRIỂN KHAI

### 5.1. YÊU CẦU CHỨC NĂNG

#### 5.1.6. MA TRẬN ƯU TIÊN MOSCOW CHO MVP

| Mức độ | Yêu cầu | Lý do |
|--------|---------|-------|
| MUST HAVE | FR-AC-02, 03, 04, 05, 06, 07, 08 | Core Bayesian tracking và HTN planning với repair. |
| MUST HAVE | FR-EM-03, 04, 05, 06 | Core particle filter estimation và decision dựa trên utility. |
| MUST HAVE | FR-ME-01, 02, 03 | Core Q-learning updates và recommendation. |
| MUST HAVE | FR-OR-03, 04, 05 | Self-monitoring, điều phối, và audit log. |
| MUST HAVE | FR-UI-01, 02, 03, 04 | Giao diện tương tác và inspection dashboard. |
| SHOULD HAVE | FR-AC-09, FR-EM-07, 08 | Giới hạn repair, recovery mode, intervention content. |
| COULD HAVE | FR-UI-05 (cơ bản) | De-stress UI cơ bản áp dụng nếu còn thời gian. |
| WON'T HAVE | FR-AC-11, FR-EM-09, FR-ME-04, 05, FR-OR-06, FR-UI-06 | Các yêu cầu phụ thuộc trained models, consolidation, policy network. |

---

### 5.3. PHẠM VI TRIỂN KHAI THEO GIAI ĐOẠN

#### 5.3.1. GIAI ĐOẠN 1: MVP CORE AGENTIC (06/04 – 17/04)

**In Scope:**

| Thành phần | Phạm vi chi tiết | Ghi chú kỹ thuật |
|-----------|-----------------|-----------------|
| Academic Agent | Bayesian Hypothesis Tracking; HTN Planning với repair strategies; KG 15 node Đạo hàm | Prior và likelihood khởi tạo từ expert knowledge/synthetic data |
| Empathy Agent | Particle Filter State Estimation với 100 hạt; Decision based on expected utility; HITL trigger | Observation model tham số khởi tạo từ expert rules |
| Memory System | Episodic Store; Q-Learning với reward người dùng; Recommend strategy ε-greedy | Q-table khởi tạo rỗng hoặc từ expert defaults |
| Orchestrator | Điều phối action dựa trên utility comparison và confidence thresholds | Policy logic deterministic cho MVP |
| Giao diện | Flutter App: 3 màn hình chính; thu thập tín hiệu hành vi chính xác | De-stress UI cơ bản |
| Inspection Dashboard | Belief view, Plan view, State view, Q-value view, Decision log realtime | Công cụ kiểm chứng Agentic cho BGK |
| Hạ tầng | FastAPI backend, Supabase database, Cloud Run deployment | Serverless, scale-to-zero |

**Out of Scope:** Huấn luyện mô hình trên dữ liệu thực, mở rộng đa môn học, dashboard phụ huynh nâng cao, voice input, RLHF pipeline.

#### 5.3.2. GIAI ĐOẠN 2: HOÀN THIỆN & TỐI ƯU DEMO (18/04 – 09/05)

**In Scope:** Mở rộng nội dung, tinh chỉnh tham số, tối ưu sản phẩm, chuẩn bị demo.

**Out of Scope (Post-Hackathon):** Thu thập dữ liệu thực quy mô lớn, mở rộng đa môn, triển khai B2B.

---

### 5.4. PHÂN CÔNG NHIỆM VỤ & LỘ TRÌNH THỰC HIỆN

#### 5.4.1. PHÂN CÔNG NHIỆM VỤ THEO GIAI ĐOẠN

| Thành viên | Vai trò | Trách nhiệm Giai đoạn 1 (06/04 – 17/04) | Trách nhiệm Giai đoạn 2 (18/04 – 09/05) |
|-----------|---------|----------------------------------------|----------------------------------------|
| Phùng Bảo Khang | Team Leader / AI Architect | Thiết kế kiến trúc Agentic; triển khai Bayesian Tracker, Particle Filter core logic; định nghĩa expert priors | Tinh chỉnh tham số mô hình; tối ưu thuật toán; calibrate thresholds |
| Nguyễn Minh Đức | Backend & Agent Developer | Xây dựng FastAPI backend, HTN Planner, Plan Repair Engine; Memory System; Abstraction Layer | Mở rộng task library; tối ưu API latency; triển khai fallback an toàn |
| Hy Huê Hưng | Data/API Integration & Prompt Designer | Xây dựng đồ thị tri thức 15 node; thiết kế expert config; phát triển Inspection Dashboard; thiết kế prompt template | Bổ sung quiz variations; tinh chỉnh prompt template; mở rộng dashboard |
| Thái Quang Huy | Product Owner / UX-UI / Flutter Dev | Phát triển Flutter app (3 màn hình chính); thu thập tín hiệu hành vi; viết tài liệu proposal, báo cáo MVP | Hoàn thiện De-stress UI; tinh chỉnh UX; hoàn thiện slide, kịch bản demo |

#### 5.4.3. LỘ TRÌNH CHI TIẾT THEO NGÀY (GIAI ĐOẠN 1)

| Ngày | Công việc chính | Deliverable | Người phụ trách |
|------|----------------|------------|----------------|
| 06/04 | Setup repo, CI/CD, Supabase project. Thiết kế architecture và abstraction layer. | Project skeleton, CI pipeline chạy được. | Toàn team |
| 07/04 | Triển khai Bayesian Tracker core logic với unit tests. Xây dựng KG 15 node. | Tracker tests pass, KG JSON hoàn thiện. | Khang, Hưng |
| 08/04 | Triển khai HTN Planner với repair logic. Triển khai Particle Filter estimator. | Planner repair tests pass. Filter updates correctly. | Đức, Khang |
| 09/04 | Triển khai Memory System (Episodic, Q-Learning). Phát triển Abstraction Layer & Config Loader. | Q-learning updates đúng. Config loader hoạt động. | Đức, Hưng |
| 10/04 | Phát triển Flutter UI cơ bản (3 màn hình). Tích hợp thu thập tín hiệu hành vi. | UI chạy được, tín hiệu thu thập chính xác. | Huy |
| 11/04 | Xây dựng FastAPI endpoints. Tích hợp backend agents. Kết nối Dashboard cơ bản. | API hoạt động, dashboard hiển thị state. | Đức, Hưng |
| 12/04 | Tích hợp end-to-end luồng chẩn đoán. Kiểm thử với synthetic users. | Luồng chẩn đoán chạy E2E. Log khớp hành động. | Toàn team |
| 13/04 | Tích hợp end-to-end luồng empathy. Hoàn thiện Inspection Dashboard. | Luồng empathy chạy E2E. Dashboard realtime đầy đủ. | Toàn team |
| 14/04 | Fix bugs tích hợp. Tối ưu latency backend. Kiểm thử trên thiết bị thật. | Latency < 4.5s. App ổn định trên Android. | Đức, Huy |
| 15/04 | Quay video demo dự phòng. Viết báo cáo kỹ thuật MVP. | Video demo sẵn sàng. Báo cáo MVP hoàn chỉnh. | Huy, Hưng |
| 16/04 | Dry-run nội bộ. Fix issues phát sinh. Build APK v1. | APK v1 ổn định. Dry-run pass. | Toàn team |
| 17/04 | Tổng kiểm tra. Submit proposal, APK, video, báo cáo. | Submission hoàn tất đúng hạn. | Toàn team |

---

## 6. TRẢI NGHIỆM NGƯỜI DÙNG & ĐẠO ĐỨC AI

### 6.1. TRIẾT LÝ THIẾT KẾ: "CÔNG NGHỆ VÔ HÌNH, MINH BẠCH HỮU HÌNH"

**Công nghệ Vô hình:**
- Giao diện tập trung: Mỗi màn hình chỉ hiển thị một nhiệm vụ duy nhất.
- Tương tác tự nhiên: Đề xuất và can thiệp xuất hiện đúng thời điểm.
- Thích nghi thầm lặng: Hệ thống điều chỉnh chiến lược mà không yêu cầu người dùng cấu hình thủ công.

**Minh bạch Hữu hình:**
- Giải thích quyết định: Mọi đề xuất đi kèm lý do ngắn gọn, dễ hiểu.
- Inspection Dashboard: Bảng điều khiển chi tiết cho giáo viên, phụ huynh nâng cao, và auditor.
- Audit Log: Mọi quyết định và cập nhật mô hình được ghi nhật ký đầy đủ.

---

### 6.2. DE-STRESS UI VÀ TƯƠNG TÁC THÍCH NGHI

**Nguyên tắc De-Stress UI:**
- Màu sắc tâm lý: Tông màu pastel dịu nhẹ (xanh ngọc, be, xám nhạt).
- Typography và Khoảng trắng: Font chữ tròn trịa (Nunito/Quicksand), khoảng trắng rộng rãi.
- Micro-interactions: Hiệu ứng chuyển động mượt mà, phản hồi xúc giác nhẹ nhàng.
- Không progress bar áp lực: Thay bằng danh sách "việc cần làm hôm nay" với biểu tượng cảm xúc.

**Tương tác thích nghi theo trạng thái:**
- Chế độ tập trung (focused): Hiển thị đầy đủ thông tin và tùy chọn nâng cao.
- Chế độ hỗ trợ (confused): Chuyển sang giải thích trực quan với hình ảnh minh họa.
- Chế độ phục hồi (exhausted): Recovery Mode với nền màu ấm hơn, nội dung nhẹ nhàng.

---

### 6.3. CƠ CHẾ HUMAN-IN-THE-LOOP (HITL)

**Kích hoạt HITL dựa trên độ bất định:**
- Popup xác nhận: *"Mình không chắc bạn đang mệt hay bối rối. Bạn muốn nghỉ 5 phút hay xem gợi ý giải thích?"*
- Ghi nhận phản hồi: Phản hồi của học sinh được ghi nhận làm ground truth.
- Tôn trọng lựa chọn: Nếu học sinh từ chối đề xuất, hệ thống tôn trọng quyết định và không ép buộc.

**HITL cho thay đổi quan trọng:** Mọi thay đổi lớn đến lộ trình học tập đều yêu cầu xác nhận của học sinh.

---

### 6.4. ĐẠO ĐỨC AI, CHÍNH SÁCH DỮ LIỆU & AN TOÀN NGƯỜI DÙNG

**Tuân thủ Nghị định 13/2023/NĐ-CP:**
- Minh bạch thu thập: Màn hình onboarding hiển thị rõ ràng dữ liệu được thu thập và mục đích sử dụng.
- Đồng thuận Opt-in: Người dùng phải chủ động đồng ý trước khi thu thập dữ liệu hành vi.
- Mục đích giới hạn: Dữ liệu chỉ sử dụng cho chức năng hệ thống và cải thiện mô hình.
- Lưu trữ có hạn: Dữ liệu hành vi chi tiết tự động xóa sau 24 giờ (TTL).

---

### 6.5. AN TOÀN CHO NGƯỜI DÙNG VỊ THÀNH NIÊN

- **Không quảng cáo:** Ứng dụng không hiển thị quảng cáo dưới bất kỳ hình thức nào.
- **Ngôn ngữ tích cực:** Mọi thông điệp được thiết kế theo nguyên tắc positive reinforcement.
- **Cơ chế báo cáo khẩn cấp:** Nếu hệ thống phát hiện dấu hiệu bất thường nghiêm trọng, popup hiển thị thông điệp hỗ trợ và số đường dây nóng tâm lý học đường.

---

### 6.7. TÓM TẮT CAM KẾT UX VÀ ĐẠO ĐỨC

| Khía cạnh | Cam kết | Cơ chế thực thi |
|-----------|---------|----------------|
| Trải nghiệm | De-stress UI, tối giản, không áp lực | Màu pastel, micro-interactions, không progress bar áp lực |
| Thích nghi | Giao diện điều chỉnh theo trạng thái tinh thần | Empathy Agent ước lượng state, UI chuyển chế độ dynamic |
| Minh bạch | Giải thích quyết định, inspection dashboard | Rationale trích xuất từ belief/uncertainty, dashboard realtime |
| Tự quyết | HITL cho thay đổi quan trọng và uncertainty cao | Popup xác nhận, tôn trọng lựa chọn, ghi nhận feedback |
| Riêng tư | Tuân thủ Nghị định 13, data minimization | Opt-in, TTL 24h, mã hóa, RLS, không chia sẻ bên thứ ba |
| Bảo mật | Mã hóa end-to-end, authentication an toàn | AES-256, TLS 1.3, JWT, Supabase Auth |
| An toàn | Fallback khi confidence thấp, không quảng cáo | Calibration monitoring, rule-based fallback, zero ads |
| Vị thành niên | Ngôn ngữ tích cực, báo cáo khẩn cấp | Positive reinforcement, hotline integration, phân quyền phụ huynh |
| Kiểm chứng | Audit log, báo cáo metrics công khai | Decision log đầy đủ, GitHub public, evaluation suite |

---

## 7. TÁC ĐỘNG, MÔ HÌNH KINH DOANH & ĐO LƯỜNG THÀNH CÔNG

### 7.1. TÁC ĐỘNG DỰ KIẾN VÀ CHỈ SỐ ĐO LƯỜNG

**Tác động giáo dục (Post-Hackathon):**
- Giảm 30-40% thời gian học vô ích thông qua chẩn đoán chính xác.
- Dự kiến tăng 1.0-1.5 điểm kiểm tra sau 4 tuần sử dụng.

**Tác động sức khỏe tinh thần (Post-Hackathon):**
- Giảm 20-30% nguy cơ kiệt sức học đường.
- Tăng cường nhận thức bản thân qua phản hồi minh bạch.

---

### 7.2. MÔ HÌNH KINH DOANH & CHIẾN LƯỢC GO-TO-MARKET

#### 7.2.1. GÓI DỊCH VỤ

| Gói | Đối tượng | Giá (VNĐ) | Tính năng cốt lõi |
|-----|----------|----------|-----------------|
| Basic (Miễn phí) | Học sinh | 0 | Chẩn đoán lỗ hổng cơ bản (tối đa 5 lần/tháng), 1 môn học. |
| Student Pro | Học sinh tự quản | 79.000/tháng | Chẩn đoán không giới hạn, HTN Planning với Repair, Empathy Agent đầy đủ, đa môn học. |
| Family | Phụ huynh + con | 129.000/tháng | Toàn bộ Student Pro cho tối đa 3 con, Dashboard phụ huynh nâng cao. |
| Campus | Trường học / Trung tâm | 15-25 triệu/năm | License 500+ học sinh, báo cáo tổng hợp khối lớp, API tích hợp LMS. |

---

### 7.3. PHÂN TÍCH CHI PHÍ – LỢI ÍCH

#### 7.3.2. DOANH THU DỰ KIẾN

| Nguồn doanh thu | Năm 1 (2026) | Năm 2 (2027) | Năm 3 (2028) | Ghi chú |
|----------------|-------------|-------------|-------------|---------|
| Gói Student Pro | 350 triệu | 1.200 triệu | 2.500 triệu | Đạt 5.000 users cuối năm 1, conversion 4% |
| Gói Family | 180 triệu | 600 triệu | 1.300 triệu | Đạt 1.000 users cuối năm 1, conversion 3% |
| Gói Campus | 50 triệu | 150 triệu | 300 triệu | Ký 5 trường năm 1, mở rộng B2B |
| **Tổng doanh thu** | **580 triệu** | **1.950 triệu** | **4.100 triệu** | Tăng trưởng bền vững nhờ data flywheel |

#### 7.3.3. ROI VÀ CHỈ SỐ TÀI CHÍNH

- Tổng chi phí 3 năm: ~2.200 triệu VNĐ
- Tổng doanh thu 3 năm: ~6.630 triệu VNĐ
- Lợi nhuận ròng 3 năm: ~4.430 triệu VNĐ
- **ROI (3 năm): ~200%**
- Thời gian hoàn vốn: ~10 tháng sau khi bắt đầu thu phí
- Gross Margin: > 85% ở quy mô 2.000 MAU
- LTV/CAC: > 12

---

### 7.5. LỘ TRÌNH PHÁT TRIỂN SAU HACKATHON

#### Cột mốc quan trọng

| Thời gian | Cột mốc | Chỉ số mục tiêu |
|-----------|---------|----------------|
| 09/05/2026 | Hoàn thành Hackathon, demo chung kết | MVP Agentic chạy ổn định, inspection dashboard minh bạch |
| 31/07/2026 | Kết thúc Beta, models v1 tích hợp | 200 users, ECE < 0.15, NPS ≥ 4.0 |
| 30/09/2026 | Ra mắt public, đạt product-market fit | 2.000 MAU, conversion 3-5%, retention 30 ngày > 40% |
| 31/12/2026 | Mở rộng đa môn, B2B thành công | 10.000 MAU, 5 hợp đồng B2B, doanh thu ổn định |
| Q4/2027 | Nền tảng quốc gia, gọi vốn Series A | 100.000+ users, tăng trưởng bền vững, mở rộng khu vực |

---

## 8. TÍNH KHẢ THI, KẾ HOẠCH THỰC HIỆN & RỦI RO

### 8.1. TÍNH KHẢ THI TỔNG THỂ

| Yếu tố | Đánh giá | Cơ sở |
|--------|---------|-------|
| Cơ chế Agentic | Cao | Bayesian, HTN, Particle Filter, Q-Learning là kỹ thuật đã kiểm chứng. Expert priors loại bỏ rủi ro mô hình không hội tụ. |
| Abstraction Layer | Cao | Thiết kế interface rõ ràng cho phép MVP dùng expert rules, sau này thay thế bằng ML models. |
| Hiệu năng MVP | Cao | Vectorization, caching, và giới hạn tham số đảm bảo latency < 4.5s. |
| Thu thập dữ liệu | Cao | MVP không phụ thuộc dữ liệu thực. Expert priors và synthetic data đủ để chứng minh cơ chế. |
| Tích hợp hệ thống | Trung bình | Tích hợp 4 cơ chế trong 12 ngày đòi hỏi coordination chặt chẽ. |

**Kết luận:** GrowMate có tính khả thi cao cho MVP Hackathon nhờ chiến lược expert priors giảm rủi ro dữ liệu, kiến trúc modular hỗ trợ mở rộng, và đội ngũ có năng lực phù hợp.

---

### 8.2. MA TRẬN QUẢN TRỊ RỦI RO

| Nhóm rủi ro | Mô tả rủi ro | Khả năng | Tác động | Giải pháp giảm thiểu |
|------------|-------------|---------|---------|---------------------|
| Kỹ thuật & Implement | Độ phức tạp tích hợp 4 cơ chế Agentic vượt quá timeline 12 ngày | Trung bình | Rất cao | Ưu tiên tuyệt đối core logic; chiến lược expert priors; daily standup & scope freeze; modular development |
| Demo & Trình bày | Demo fail do lỗi runtime hoặc kết quả không như kỳ vọng | Trung bình | Rất cao | Inspection Dashboard; synthetic testing; video fallback; dry-run ít nhất 3 lần |
| Hiệu năng | Latency cao do tính toán Particle Filter và Bayesian updating | Trung bình | Cao | Vectorization với NumPy; giới hạn tham số; caching; async processing |
| Thuyết phục BGK | BGK nghi ngờ tính Agentic khi dùng expert priors | Trung bình | Cao | Minh bạch kiến trúc; chứng minh cơ chế qua behavior; log & dashboard chi tiết; nhấn mạnh lộ trình data-driven |
| Logic Agent | Lỗi công thức hoặc logic repair dẫn đến hành vi vô lý | Thấp | Cao | Unit tests công thức; giới hạn repair count; dashboard debug; code review chéo |
| Dữ liệu | Thu thập dữ liệu thực chậm sau Hackathon | Trung bình | Trung bình | MVP không phụ thuộc dữ liệu; incentive program; hợp tác trường học |
| Bảo mật & Pháp lý | Vi phạm Nghị định 13 hoặc lộ dữ liệu người dùng | Thấp | Rất cao | Data minimization; RLS & mã hóa; opt-in rõ ràng; audit checklist |
| Nhân sự | Thành viên gặp sự cố không thể tiếp tục | Thấp | Cao | Tài liệu hóa code; phân công backup; git flow chuẩn |

---

### 8.3. TIÊU CHÍ NGHIỆM THU

#### 8.3.1. TIÊU CHÍ NGHIỆM THU MVP (NỘP VÒNG 1 – 17/04/2026)

1. **Cơ chế Agentic:** Hệ thống phải chứng minh Bayesian update, HTN repair, Particle filter estimation và Q-learning hoạt động đúng thiết kế qua Inspection Dashboard.
2. **Hiệu năng & Ổn định:** p95 latency chẩn đoán < 4.5 giây; không crash trong 10 phiên test liên tiếp.
3. **Minh bạch:** Inspection Dashboard hiển thị realtime trạng thái nội bộ khớp với log hệ thống.
4. **Sản phẩm:** APK chạy ổn định, tài liệu đầy đủ.

---

## 9. KẾT LUẬN & LỜI KÊU GỌI HÀNH ĐỘNG

### 9.1. GIÁ TRỊ CỐT LÕI & TÓM TẮT DỰ ÁN

**Giá trị cốt lõi:**
1. **Chẩn đoán gốc rễ chính xác:** Academic Agent sử dụng Bayesian Hypothesis Tracking để duy trì và cập nhật niềm tin xác suất về nguyên nhân lỗi sai.
2. **Lập kế hoạch động thông minh:** HTN Planning biểu diễn lộ trình học tập dưới dạng cây nhiệm vụ phân cấp. Plan Repair Engine chẩn đoán nguyên nhân và áp dụng chiến lược sửa chữa cục bộ.
3. **Đồng hành thấu cảm tin cậy:** Empathy Agent ước lượng trạng thái tinh thần từ tín hiệu hành vi đa chiều qua Particle Filter.
4. **Học hỏi và Thích nghi liên tục:** Memory System duy trì bộ nhớ đa thành phần và học chính sách lựa chọn chiến lược tối ưu qua Q-Learning.
5. **Minh bạch và Kiểm chứng được:** Inspection Dashboard hiển thị realtime trạng thái nội bộ.

**Tóm tắt dự án:**
- **Vấn đề:** Học sinh lớp 12 học mù quáng và kiệt sức vô hình.
- **Giải pháp:** Hệ thống Multi-Agent với 4 cơ chế Agentic kiểm chứng được.
- **Khác biệt:** Agentic thực thụ không phải LLM wrapper; cơ chế minh bạch qua inspection dashboard.
- **Tác động:** Giảm thời gian học vô ích, cải thiện điểm số bền vững, bảo vệ sức khỏe tinh thần.

---

### 9.2. CAM KẾT TỪ ĐỘI NGŨ

**Cam kết sản phẩm Hackathon:**
- Deliver MVP là APK Android chạy end-to-end ổn định trên thiết bị thật.
- Chứng minh thành công 4 cơ chế Agentic thông qua Inspection Dashboard realtime và audit log minh bạch.
- Minh bạch hóa kiến trúc và tham số.

**Cam kết tính toàn vẹn kỹ thuật:**
- Agentic thực thụ, không overclaim: GrowMate không phải LLM wrapper hay rule-based ngụy trang.
- Kiểm chứng được: Hệ thống cung cấp đầy đủ công cụ kiểm chứng.
- Kiến trúc bền vững: Thiết kế modular với abstraction layer.

**Cam kết mã nguồn mở:** Toàn bộ mã nguồn sẽ được công bố công khai trên GitHub sau khi hoàn thành vòng chung kết (sau 09/05/2026).

**Cam kết đạo đức và bảo mật:**
- Tuân thủ Nghị định 13/2023/NĐ-CP.
- Bảo vệ dữ liệu học sinh.
- An toàn cho vị thành niên: Không quảng cáo, ngôn ngữ tích cực.

---

### 9.3. LỜI KÊU GỌI HÀNH ĐỘNG

- **Đối với Ban Tổ chức và BGK:** Chúng tôi mong nhận được sự ghi nhận cho nỗ lực xây dựng Agentic AI thực thụ, kiểm chứng được, và có trách nhiệm.
- **Đối với Nhà trường và Giáo viên:** Chúng tôi mời quý thầy cô tham gia chương trình beta, cung cấp dữ liệu gán nhãn và phản hồi chuyên môn.
- **Đối với Nhà đầu tư và Đối tác:** GrowMate sở hữu technical moat vững chắc, mô hình kinh doanh bền vững, và thị trường tiềm năng lớn.
- **Đối với Cộng đồng Kỹ thuật:** Chúng tôi khuyến khích các developer và researcher tham gia đóng góp mã nguồn.

---

### 9.4. THÔNG TIN LIÊN HỆ

**Đội ngũ noleAI**

| Thành viên | Vai trò | Email |
|-----------|---------|-------|
| Phùng Bảo Khang | Team Leader / AI Architect | andykhang404@gmail.com |
| Nguyễn Minh Đức | Backend & Agent Developer | duc.061106@gmail.com |
| Hy Huê Hưng | Data/API Integration & Prompt Designer | hunghuehy310506@gmail.com |
| Thái Quang Huy | Product Owner / UX-UI / Flutter Dev | iamhuy29062006@gmail.com |

**Kênh truyền thông:**
- Website: https://growmate.edu.vn *(sẽ cập nhật sau giai đoạn 4)*
- GitHub: https://github.com/noleai/growmate *(cập nhật sau)*
- Email liên hệ: contact@growmate.edu.vn *(cập nhật sau giai đoạn 4)*

---

### 9.5. TÀI LIỆU THAM KHẢO

- Chính phủ nước CHXHCN Việt Nam (2023), *Nghị định số 13/2023/NĐ-CP quy định về bảo vệ dữ liệu cá nhân.*
- UNICEF Việt Nam & Bộ GD&ĐT (2024), *Đánh giá áp lực tâm lý học sinh THPT.*
- Yao, S., et al. (2022), *ReAct: Synergizing Reasoning and Acting in Language Models.*
- Russell, S., & Norvig, P. (2020), *Artificial Intelligence: A Modern Approach (4th Edition).*
- Sutton, R., & Barto, A. (2018), *Reinforcement Learning: An Introduction (2nd Edition).*
- LangChain (2025), *LangGraph Documentation: Building Stateful Multi-Actor Applications.*
- Supabase (2025), *PostgreSQL và Row Level Security Documentation.*

---

> **GrowMate** là minh chứng cho khả năng xây dựng Agentic AI thực thụ, kiểm chứng được, và có trách nhiệm trong lĩnh vực giáo dục. Với kiến trúc Multi-Agent dựa trên Bayesian tracking, HTN planning, Particle filter estimation, và RL policy, cùng lộ trình phát triển bài bản và cam kết minh bạch, GrowMate sẵn sàng trở thành người bạn đồng hành tin cậy cho hàng trăm nghìn học sinh Việt Nam trên hành trình chinh phục tri thức và bảo vệ sức khỏe tinh thần.
>
> — Đội ngũ **noleAI**
