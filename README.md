# GrowMate Frontend

GrowMate là ứng dụng Flutter cho MVP "smart and friendly study partner" trong khuôn khổ GDGoC Hackathon Vietnam 2026.

Mục tiêu của app là giúp học sinh học tập nhẹ nhàng, có chẩn đoán học thuật rõ ràng, can thiệp phù hợp trạng thái cảm xúc, và trải nghiệm UI de-stress.

## Tài liệu tham chiếu

Repo hiện có 3 tài liệu chính trong thư mục `docs/`:

- `docs/Proposal_Final.docx`
- `docs/Proposal_Final.pdf`
- `docs/Kế Hoạch Hackathon MVP Chi Tiết.docx`

Các tài liệu này mô tả tầm nhìn sản phẩm, kiến trúc Agentic đa tác tử, KPI, roadmap MVP 12 ngày, và strategy demo/inspection dashboard.

## Trạng thái hiện tại của frontend

Phiên bản hiện tại đã triển khai đầy đủ luồng MVP cần demo:

- Auth flow production-style (Welcome, Login, Register, Forgot Password)
- Persistent mock token với auto-login bằng `SharedPreferences`
- Route guard bằng `go_router` theo trạng thái đăng nhập
- Luồng học chính: Today -> Quiz -> Diagnosis -> Intervention -> Session Complete
- Logout từ Profile
- Design system de-stress với reusable widgets (`ZenButton`, `ZenCard`, `ZenTextField`, ...)
- BLoC cho các flow chính (Auth, Quiz, Diagnosis, Intervention)

## Kiến trúc kỹ thuật

Frontend stack:

- Flutter (Material 3)
- `flutter_bloc` cho state management
- `go_router` cho navigation + guard
- `shared_preferences` cho local persistence

Tổ chức mã nguồn theo feature:

- `lib/features/auth/`
- `lib/features/quiz/`
- `lib/features/diagnosis/`
- `lib/features/intervention/`
- `lib/features/today/`, `progress/`, `profile/`, `session/`
- `lib/app/router/` (route constants + router config)
- `lib/shared/widgets/` (design system components)

## Route map chính

Auth routes:

- `/welcome`
- `/login`
- `/register`
- `/forgot-password`

App routes:

- `/home`
- `/progress`
- `/profile`
- `/quiz`
- `/diagnosis`
- `/intervention`
- `/session-complete`

## Auth flow

`AuthBloc` hỗ trợ các event/state bắt buộc:

- Events: `AppStarted`, `LoginRequested`, `RegisterRequested`, `LogoutRequested`
- States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthError`

Logic:

- App khởi động -> `AppStarted` -> restore session từ local storage
- Chưa login -> redirect về `/welcome`
- Đã login -> vào `/home`
- Logout -> clear token + quay lại auth flow

## Cài đặt nhanh

Yêu cầu:

- Flutter SDK (khuyến nghị stable)
- Android Studio / VS Code với Flutter extension

Cài dependencies:

```bash
flutter pub get
```

Chạy app:

```bash
flutter run
```

Phân tích mã nguồn:

```bash
flutter analyze
```

Chạy test:

```bash
flutter test
```

## Mock API / Backend mode

Trong `lib/main.dart` có cờ:

- `useMockApi = true`: chạy mock data nội bộ để demo nhanh
- `useMockApi = false`: chuyển sang `RealApiService` (cần backend endpoint thật)

## Test coverage hiện có

- Unit/widget test cho các flow chính
- Integration flow test cho chuỗi:
	- Auth -> Today -> Quiz -> Diagnosis -> Intervention

Lưu ý: khi chạy integration test bằng `flutter test`, plugin có thể cảnh báo setup tùy môi trường; cảnh báo này không ảnh hưởng kết quả pass/fail trong trạng thái hiện tại.

## Định hướng mở rộng

Theo proposal và roadmap:

- Tích hợp Inspection Dashboard realtime
- Mở rộng nhiều chuyên đề/môn học
- Calibrate model với dữ liệu thực
- Hoàn thiện B2B dashboard cho phụ huynh/nhà trường

## Team

Đội thi: **noleAI**

Slogan sản phẩm: **Your smart and friendly study partner**
