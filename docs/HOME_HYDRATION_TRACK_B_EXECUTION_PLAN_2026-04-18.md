# Home Hydration Track B Execution Plan (2026-04-18)

## Summary

Mục tiêu của đợt này:
- Chặn nhầm `mock mode` bằng startup guard rõ ràng, có fail-fast theo policy `Release+Override`.
- Hoàn thành Track B trong phạm vi Home-only (không mở rộng sang Progress/Chat/Recovery), giảm nhiễu thị giác và làm rõ hành động chính ngay khi vào Home.

Phạm vi thực hiện:
- `main.dart`: startup guard + global mock-mode indicator.
- `TodayPage` và widget liên quan: tái cấu trúc hierarchy, primary CTA logic, compact feature hub.
- Test: unit + widget + manual QA checklist cho các hành vi mới.

Ngoài phạm vi:
- Không thay đổi backend API contract.
- Không làm lại kiến trúc routing tổng thể.
- Không chỉnh deep UX cho Progress/Chat/Recovery trong đợt này.

## Startup Mock-Mode Guard

### Decision đã chốt

- Flag hiện có: `USE_MOCK_API`.
- Flag mới: `ALLOW_MOCK_API_IN_NON_DEBUG` (default `false`).
- Policy: `Release+Override`.
  - `debug`: cho phép chạy mock mode, hiển thị indicator dev.
  - `profile/release`:
    - nếu `USE_MOCK_API=true` và `ALLOW_MOCK_API_IN_NON_DEBUG=false` => fail-fast ngay startup.
    - nếu `USE_MOCK_API=true` và `ALLOW_MOCK_API_IN_NON_DEBUG=true` => cho chạy nhưng hiển thị cảnh báo override rõ ràng trên UI.

### Implementation chi tiết

1. Thêm config mới ở startup:
- Thêm compile-time default:
  - `const String _allowMockApiInNonDebugFromDefine = String.fromEnvironment('ALLOW_MOCK_API_IN_NON_DEBUG', defaultValue: 'false');`
- Thêm runtime resolved value:
  - `late final bool allowMockApiInNonDebug;`
- Resolve từ `.env` ưu tiên, fallback `--dart-define`, giống pattern cờ hiện có.

2. Thêm startup guard function:
- Tạo hàm private trong `main.dart`, ví dụ `_enforceMockModeGuard()`.
- Logic:
  - Nếu `!useMockApi`: return.
  - Nếu `kDebugMode`: return.
  - Nếu `allowMockApiInNonDebug`: log warning rõ ràng và return.
  - Ngược lại: throw `StateError` với message hành động cụ thể:
    - set `USE_MOCK_API=false`, hoặc
    - bật explicit override `ALLOW_MOCK_API_IN_NON_DEBUG=true` cho demo nội bộ.
- Gọi guard ngay sau khi resolve flags và trước `runApp`.

3. Logging startup:
- Log 1 dòng trạng thái cờ:
  - `useMockApi`, `allowMockApiInNonDebug`, `buildMode`.
- Nếu rơi vào override path ở non-debug: log warning có prefix dễ grep (`[MOCK-OVERRIDE]`).

4. Global top ribbon indicator:
- Tạo widget mới trong `lib/core/widgets/` (ví dụ `mock_mode_indicator.dart`).
- Render ở `MaterialApp.builder` dạng overlay top-level toàn app.
- Hiển thị:
  - Debug + mock: ribbon vàng, label `DEV • MOCK API`.
  - Non-debug + mock override: ribbon đỏ, label `MOCK OVERRIDE`.
  - Không mock: ẩn hoàn toàn.
- Vị trí: top safe area, không che khuất toàn bộ UI, ưu tiên height nhỏ (24-28).

5. Cập nhật tài liệu cấu hình:
- `.env.example`: thêm `ALLOW_MOCK_API_IN_NON_DEBUG=false` và comment cảnh báo.
- `README.md`: cập nhật phần Runtime Modes, nêu rõ behavior fail-fast/override.

## Track B Home-Only (TodayPage)

### Decision đã chốt

- Phạm vi chỉ Home.
- Feature hub theo mẫu `4 tiles + More`.
- Primary action đặt trong primary card (không đặt trọng tâm CTA ở resume banner).

### Hierarchy mục tiêu

Thứ tự block trên Home:
1. Greeting/date + trạng thái ngắn.
2. Primary card duy nhất quyết định hành động chính.
3. Resume info banner (chỉ thông tin phụ, nếu có pending).
4. Pulse metrics (2-3 chỉ số ngắn).
5. Feature hub rút gọn + mục `Xem thêm`.

### Primary card behavior

- `pending session`:
  - headline hướng resume.
  - CTA chính: `Tiếp tục phiên học`.
  - action: dùng flow `_resumePendingSession(...)`.
- `ready` (không pending, có insight hợp lệ):
  - CTA chính: `Bắt đầu phiên tiếp theo`.
  - action: vào quiz route hiện tại.
- `empty`:
  - CTA chính: `Làm phiên đầu tiên`.
  - wording trung tính, không ám chỉ AI đã phân tích xong.
- `loading/error`:
  - giữ skeleton/error cục bộ.
  - error có retry trực tiếp, không phụ thuộc pull-to-refresh toàn trang.

### Resume banner

- Chuyển về vai trò thông tin phụ:
  - giữ trạng thái phiên dở (`mode/progress/next question/last active`).
  - giữ action bỏ phiên (`discard`).
- Không dùng như nơi quyết định CTA chính để tránh trùng vai với primary card.

### Feature hub (compact)

- Hiển thị trực tiếp 4 tile chính:
  - Quiz
  - Review
  - Focus
  - Schedule
- Tile phụ gom vào `Xem thêm` (compact group):
  - Roadmap
  - Versus
  - Relax
  - Mascot
  - Mood check
- Yêu cầu UX:
  - giảm độ dày đầu trang.
  - giữ điều hướng cũ, không đổi route contract.

## Public Interfaces / Config

- Thêm env/config public:
  - `ALLOW_MOCK_API_IN_NON_DEBUG`.
- Không đổi API backend.
- Không thêm type contract ra ngoài feature; tận dụng `HomeHydrationState` hiện tại và bổ sung logic render ở layer presentation.

## Acceptance Criteria

1. Startup guard:
- Ở `profile/release`, `USE_MOCK_API=true` và không override => app fail-fast trước khi render app shell.
- Ở `profile/release`, có override explicit => app chạy được và có cảnh báo UI rõ ràng.
- Ở `debug`, mock mode hiển thị indicator dev-only.

2. Home hierarchy/CTA:
- Người dùng luôn thấy đúng một primary CTA theo context (`pending`, `ready`, `empty`) trong primary card.
- Resume banner không còn là CTA chính.
- Feature hub đầu trang chỉ còn 4 tile chính + lối vào `Xem thêm`.

3. Không regression chính:
- Hành vi route của các tile cũ vẫn đúng.
- Pull-to-refresh và retry hydrate vẫn hoạt động.
- Không xuất hiện wording gây hiểu nhầm “AI đã phân tích xong” khi state `empty/loading/error`.

## Test Matrix

### Unit tests

- `mock mode guard`:
  - mock + debug => pass.
  - mock + profile/release + no override => throw `StateError`.
  - mock + profile/release + override => pass.
  - non-mock => pass.

### Widget tests

- Indicator:
  - debug/mock => tìm thấy ribbon `DEV • MOCK API`.
  - non-debug/mock override => tìm thấy ribbon `MOCK OVERRIDE`.
  - non-mock => không có ribbon.

- Today/Home:
  - pending => primary card hiển thị CTA resume.
  - ready/no pending => CTA start next session.
  - empty => CTA first session.
  - loading => skeleton.
  - error => có retry control.
  - feature hub mặc định 4 tile chính, mở `Xem thêm` thấy tile phụ.

### Manual QA

- Startup:
  - debug mock run.
  - release/profile mock no-override fail-fast.
  - release/profile mock override warning ribbon.

- Home:
  - user mới (không history).
  - user có pending session.
  - user có history ready.
  - network chậm/offline gây hydrate error.
  - mở `Xem thêm` và điều hướng qua tile phụ.

## Risks & Mitigations

- Rủi ro 1: Fail-fast chặn nhầm luồng demo nội bộ.
  - Giảm thiểu: explicit override `ALLOW_MOCK_API_IN_NON_DEBUG=true` + ribbon đỏ bắt buộc.

- Rủi ro 2: Trùng/nhầm CTA giữa primary card và resume banner.
  - Giảm thiểu: chuẩn hóa vai trò banner là phụ, CTA chính chỉ ở primary card.

- Rủi ro 3: Regression điều hướng khi rút gọn hub.
  - Giảm thiểu: widget test route trigger cho 4 tile chính + nhóm `Xem thêm`.

- Rủi ro 4: Người dùng hiểu nhầm data freshness.
  - Giảm thiểu: giữ contract hydration hiện tại, wording trung tính cho empty/error/loading.

## Rollback Plan

- Rollback mềm (không revert toàn bộ):
  - Tắt guard bằng cấu hình tạm thời: `ALLOW_MOCK_API_IN_NON_DEBUG=true` cho môi trường cần demo.
  - Tạm ẩn ribbon bằng feature flag nội bộ nếu có lỗi layout.

- Rollback code:
  - Revert commit Track B Home-only nếu phát sinh regression UX lớn.
  - Revert riêng commit startup guard nếu gây block release không mong muốn.

- Điều kiện rollback:
  - Crash/fail-fast sai môi trường production.
  - Mất đường dẫn điều hướng chính từ Home.
  - Tỷ lệ lỗi hydrate/retry tăng bất thường sau deploy.
