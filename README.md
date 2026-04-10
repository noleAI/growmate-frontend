# GrowMate Frontend

GrowMate là ứng dụng Flutter cho MVP "smart and friendly study partner" tại GDGoC Hackathon Vietnam 2026.

Ứng dụng tập trung vào 3 mục tiêu chính:
- Cá nhân hóa lộ trình học dựa trên kết quả làm bài.
- Kết hợp tín hiệu học tập và trạng thái cảm xúc để đề xuất can thiệp phù hợp.
- Duy trì trải nghiệm UI nhẹ nhàng, dễ dùng, phù hợp học sinh THPT.

## Highlights

- Auth flow đầy đủ: Welcome, Login, Register, Forgot Password.
- Luồng học MVP: Today -> Quiz -> Diagnosis -> Intervention -> Session Complete.
- Route guard bằng go_router theo trạng thái đăng nhập.
- State management bằng flutter_bloc.
- Chế độ chạy hybrid: mock core + Supabase data-plane.
- Design system tái sử dụng qua các widget dùng chung.

## Tech Stack

- Flutter (Material 3)
- flutter_bloc
- go_router
- shared_preferences
- supabase_flutter
- flutter_dotenv

## Cấu trúc dự án

```text
lib/
	app/
		i18n/
		router/
		theme/
	core/
		constants/
		models/
		network/
		services/
	data/
		models/
		repositories/
	features/
		auth/
		today/
		quiz/
		diagnosis/
		intervention/
		progress/
		profile/
		session/
	shared/
		widgets/
```

## Điều kiện chạy

- Flutter SDK (stable)
- Android Studio hoặc VS Code (Flutter/Dart extension)

## Thiết lập nhanh

1. Cài dependencies:

```bash
flutter pub get
```

2. Tạo file môi trường từ mẫu:

PowerShell:

```powershell
Copy-Item .env.example .env
```

Bash:

```bash
cp .env.example .env
```

3. Cập nhật giá trị trong .env:
- SUPABASE_URL
- SUPABASE_ANON_KEY

4. Chạy ứng dụng:

```bash
flutter run
```

## Biến môi trường và fallback

Ứng dụng hỗ trợ 2 cách nạp biến cấu hình:
- Ưu tiên từ file .env.
- Fallback qua --dart-define:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Nếu chưa cấu hình Supabase, ứng dụng sẽ fallback sang mock mode cho một số luồng.

## Runtime Modes

Trong [lib/main.dart](lib/main.dart), có 2 cờ chính:
- useMockApi: bật mock API nội bộ.
- useSupabaseRpcDataPlane: bật ghi/đọc data-plane qua Supabase RPC.

Khuyến nghị cho môi trường demo MVP:
- useMockApi = true
- useSupabaseRpcDataPlane = true

## Chất lượng mã nguồn

Phân tích mã nguồn:

```bash
flutter analyze
```

Chạy toàn bộ test:

```bash
flutter test
```

Chạy integration flow chính:

```bash
flutter test test/integration/e2e_flow_test.dart
```

## Supabase Schema

Các script SQL chính:
- [supabase_migration.sql](supabase_migration.sql): profile + auth/RLS nền tảng.
- [supabase_agentic_schema_v2.sql](supabase_agentic_schema_v2.sql): schema Agentic mở rộng.

Thứ tự khởi tạo khuyến nghị:
1. supabase_migration.sql
2. supabase_agentic_schema_v2.sql

## Tài liệu tham chiếu

Hồ sơ proposal:
- [docs/Proposal_Final.docx](docs/Proposal_Final.docx)
- [docs/Proposal_Final.pdf](docs/Proposal_Final.pdf)
- [docs/Kế Hoạch Hackathon MVP Chi Tiết.docx](docs/K%E1%BA%BF%20Ho%E1%BA%A1ch%20Hackathon%20MVP%20Chi%20Ti%E1%BA%BFt.docx)

Tài liệu handover dữ liệu:
- [docs/data_crawl_spec_for_quiz_question_template.md](docs/data_crawl_spec_for_quiz_question_template.md)
- [docs/data_request_to_data_team_vi.md](docs/data_request_to_data_team_vi.md)
- [docs/quiz_question_template_import_ready_example.csv](docs/quiz_question_template_import_ready_example.csv)

## Roadmap gần hạn

- Hoàn thiện Inspection Dashboard realtime.
- Mở rộng tập câu hỏi theo nhiều chuyên đề/môn học.
- Calibrate model với dữ liệu thực tế.
- Chuẩn hóa dashboard B2B cho phụ huynh/nhà trường.

## Team

- Team: noleAI
- Product slogan: Your smart and friendly study partner
