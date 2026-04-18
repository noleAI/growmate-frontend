# Home Hydration + UI/UX Improvement Plan (2026-04-18)

## Summary

Ưu tiên số 1 là bỏ cảm giác `mock/stale rồi mới refresh` sau login. Sau đó mới chỉnh Home và các flow chính theo hướng de-stress hơn, nhưng vẫn giữ cấu trúc app đa tính năng hiện tại ở mức vừa phải.

Mặc định được chốt cho plan này:
- Ưu tiên ổn định dữ liệu trước.
- Home đi theo hướng lai: vẫn có feature hub, nhưng phải giảm độ ồn và tăng thứ bậc nội dung.
- Không thay đổi phạm vi sản phẩm lớn; chỉ chỉnh kiến trúc hydrate, first paint, information hierarchy, loading/empty/error states, và một số hành vi UX sai nhịp.

## Implementation Changes

### 1. Track A: Sửa tận gốc hiện tượng Home stale/mock sau login

- Thêm một lớp trạng thái riêng cho Home, ví dụ `HomeHydrationCubit` hoặc view-model tương đương, để gom 4 nguồn dữ liệu mở màn:
  - session history
  - diagnosis snapshot/confidence
  - pending session/resume
  - streak/login bonus
- `TodayPage` không tự suy luận first paint trực tiếp từ local default nữa; nó chỉ render theo `HomeHydrationState`.

- Định nghĩa lại contract first paint:
  - Nếu chưa hydrate xong dữ liệu mở màn, Home chỉ được hiện skeleton trung tính.
  - Không được hiện AI recommendation, emotion, confidence, pulse metrics, hay “gợi ý tiếp theo” từ state local mặc định.
  - Empty state chỉ dùng khi đã xác nhận không có dữ liệu thực, không dùng như placeholder tạm.

- Chuẩn hóa nguồn dữ liệu:
  - `SessionHistoryRepository` vẫn có thể đọc local cache, nhưng phải phân biệt rõ `cached` và `remote-confirmed`.
  - `TodayPage` không dùng snapshot local để dựng hero như thể đó là dữ liệu thật cuối cùng.
  - Diagnosis cache chỉ được dùng như fallback mềm; nếu dùng cache thì UI phải thể hiện đó là trạng thái tạm, không phải “AI vừa phân tích xong”.

- Bỏ cơ chế “false ready” trong Home:
  - Loại phụ thuộc UX vào timer `_aiReady` kiểu thời gian cố định.
  - Chuyển sang readiness theo dữ liệu thật: `loading`, `partial`, `ready`, `empty`, `error`.

- Chặn nhầm mock mode:
  - App startup phải log rõ và có một indicator dev-only khi `USE_MOCK_API=true`.
  - Trong production/demo config, mock mode phải fail-fast hoặc hiện cảnh báo rõ, không để user tưởng đang dùng data thật.

- Chỉnh login-to-home handoff:
  - Sau auth/consent/onboarding, cho phép vào app shell nhanh, nhưng Home section đầu phải giữ skeleton cho đến khi hydration batch đầu tiên hoàn tất.
  - Không để route vào Home xong mới hiện nội dung “giả chắc chắn” rồi đổi sang nội dung thật.

- Tách rõ 3 loại state cho Home hero:
  - `loading`: skeleton
  - `empty`: chưa có phiên học thật nào
  - `ready`: có history/pending/diagnosis đủ để dựng insight
  - `error`: lỗi mạng hoặc lỗi hydrate, có retry cục bộ

### 2. Track B: Chỉnh Home UI/UX theo hướng de-stress nhưng vẫn giữ feature hub

- Thiết kế lại hierarchy của Home:
  - Khối 1: greeting/date + trạng thái học hiện tại
  - Khối 2: primary card duy nhất cho hành động chính
  - Khối 3: resume banner nếu có pending session
  - Khối 4: 2-3 chỉ số ngắn gọn
  - Khối 5: feature hub rút gọn
- Feature hub không còn là trọng tâm thị giác đầu trang; nó là lớp khám phá thứ cấp.

- Chỉnh primary card:
  - Nếu có pending session: CTA chính là `Tiếp tục phiên học`
  - Nếu không có pending session nhưng có insight: CTA chính là `Bắt đầu phiên tiếp theo`
  - Nếu chưa có dữ liệu: CTA chính là `Làm phiên đầu tiên`
- Emotion/confidence chỉ hiện khi có dữ liệu thật hỗ trợ; không dựng từ default state.

- Giảm cảm giác “dashboard rời rạc”:
  - Giảm số tile hiển thị ngay trên Home.
  - Các tính năng phụ như roadmap, versus, schedule, mascot được hạ thị giác xuống dưới hoặc gom thành nhóm compact.
  - Giữ đúng tinh thần proposal: ít áp lực, ít nhiễu, không biến Home thành menu dày đặc.

- Đồng bộ loading/empty/error UX:
  - Skeleton phải giống layout thật, không dùng card giả khác hẳn layout cuối.
  - Error state phải retry theo từng khối, không bắt user pull-to-refresh toàn trang cho mọi lỗi.
  - Empty state phải nói rõ “chưa có dữ liệu học thật”, không dùng ngôn ngữ như AI đã phân tích rồi.

### 3. Cải thiện thêm các điểm UX liên quan trực tiếp

- Progress:
  - Chỉ hiển thị narrative khi có dữ liệu đủ tin cậy.
  - Nếu đang fallback từ history-derived hoặc mock-derived, wording phải trung tính hơn, tránh cảm giác AI “bịa”.
- Resume:
  - Banner resume phải thống nhất với start-session idempotent behavior.
  - Khi backend trả session reused/resumed, UI phải ưu tiên flow tiếp tục thay vì khởi đầu mới ngầm định.
- Chat:
  - Giữ quota, history, clear-chat như hiện tại, nhưng bảo đảm trạng thái quota/loading không gây hiểu nhầm rằng user đã bị khóa khi quota chưa load.
- Recovery:
  - Tăng độ khác biệt thị giác giữa normal mode và recovery mode, nhưng không đổi quá mạnh layout để tránh giật ngữ cảnh.

## Public Interfaces / Types

- Thêm một state model mới cho Home, ví dụ:
  - `HomeHydrationState`
  - `HomeDataSourceStatus`
  - `HomeHeroMode`
- `SessionHistoryRepository` cần trả thêm metadata nguồn dữ liệu hoặc được bọc bằng adapter riêng để biết:
  - cached/local
  - remote-confirmed
  - failed
- `TodayPage` chuyển từ logic local-state-heavy sang render theo state model mới.
- Có thể thêm một startup/dev config guard để phát hiện mock mode sai môi trường.

## Test Plan

- Widget tests cho Home:
  - login xong vào Home khi network chậm: chỉ thấy skeleton, không thấy hero stale
  - có local cache cũ + remote trả data mới: không hiện insight cũ như final state
  - không có lịch sử học: hiện empty state đúng
  - có pending session: CTA chính ưu tiên resume
  - hydrate lỗi: hiện error state có retry

- Repository/state tests:
  - phân biệt `cached` và `remote-confirmed`
  - không dựng `ready` state khi mới chỉ có local defaults
  - mock mode guard hoạt động đúng theo config

- Manual QA:
  - cold start sau login
  - reopen app với cache cũ
  - offline/slow network
  - user mới chưa có history
  - user có pending session
  - chuyển sang recovery mode
  - chat mở ngay sau login khi quota chưa load

## Acceptance Criteria

- Sau login không còn hiện Home với insight/mock/stale data rồi mới “nhảy” sang state mới.
- First paint của Home luôn là một trong 4 trạng thái rõ ràng: `loading`, `empty`, `ready`, `error`.
- Người dùng luôn hiểu hành động chính tiếp theo là gì trong vòng 3 giây đầu.
- Home bớt phân tán hơn nhưng vẫn giữ được feature hub rút gọn.
- Mock mode không thể bị nhầm là production/demo thật.
- Resume flow và progress wording không còn gây cảm giác “AI nói như chắc chắn” khi dữ liệu chưa đủ.

## Assumptions

- Không thu hẹp app về đúng “3 màn hình” như proposal; chỉ kéo Home gần proposal hơn về tinh thần.
- Chưa đụng sâu đến visual redesign toàn app; tập trung vào Home, Progress, Resume, Recovery, và startup state.
- Không thay đổi backend API; toàn bộ thay đổi nằm ở frontend state orchestration và presentation.
