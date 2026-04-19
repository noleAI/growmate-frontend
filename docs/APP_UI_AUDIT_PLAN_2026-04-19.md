# App UI Audit Plan (2026-04-19)

## Summary

App hiện đã có nền tảng UI khá tốt với `AppTheme`, `ZenCard`, `ZenButton`, và palette switching. Điểm yếu chính không nằm ở thiếu component, mà ở việc nhiều màn hình đã phát triển độc lập nên hierarchy, intro/header, loading, và empty state chưa đồng nhất.

Mục tiêu của đợt này:
- Giữ nguyên design system hiện có, không thay đổi ngôn ngữ thị giác quá mạnh.
- Tăng cảm giác polished ở các màn hình người dùng nhìn thấy nhiều nhất.
- Gom các pattern lặp lại thành widget dùng chung để những lượt polish sau nhanh hơn.

## Audit Findings

### 1. Cần thống nhất phần mở đầu màn hình

- `Login`, `Register`, `Progress`, `Profile`, `Leaderboard` đang mở đầu theo nhiều cách khác nhau.
- Một số màn hình chỉ có `Text + subtitle`, một số dùng card hero, một số phụ thuộc hoàn toàn vào `AppBar`.
- Kết quả là app chưa có nhịp thị giác đồng nhất khi điều hướng giữa các tab và flow auth.

### 2. Empty state còn rời rạc

- Empty state ở `Leaderboard`, `Progress`, và một số màn hình khác đang dùng layout và ngôn ngữ khác nhau.
- Một số nơi chỉ hiện text trống, chưa có CTA rõ ràng cho hành động tiếp theo.

### 3. Theme dùng chung vẫn còn khoảng trống

- `OutlinedButton`, `TabBar`, và `RefreshIndicator` chưa được tinh chỉnh đầy đủ ở theme global.
- Nhiều màn hình đã đẹp cục bộ nhưng thiếu “lớp hoàn thiện” chung ở toàn app.

### 4. Auth flow cần cảm giác cao cấp hơn

- `Welcome` đã có motion tương đối tốt.
- `Login` và `Register` vẫn còn khá thẳng, giống form functional hơn là một flow mở đầu sản phẩm.

### 5. Home và Quiz vẫn là vùng cần xử lý theo phase riêng

- `TodayPage` và `QuizPage` đã custom sâu, logic dày, nhiều state song song.
- Không nên refactor mạnh trong lượt polish này nếu chưa tách component trước.

## Implemented In This Pass

### Shared primitives

- Thêm `ZenScreenHeader` để chuẩn hóa eyebrow, title, subtitle, icon, và context chips.
- Thêm `ZenEmptyState` để chuẩn hóa trạng thái rỗng + CTA.

### Screen upgrades

- Polished `Login` và `Register` bằng screen header mới.
- Polished `Progress` và `Profile/Settings` bằng intro card nhất quán hơn.
- Chuẩn hóa empty state ở `Leaderboard` và `Progress`.
- Tăng một lớp polish theme global cho các control hay dùng.

## Next Phases

### Phase 2

- Tách `TodayPage` thành các widget file riêng cho hero, feature hub, agent mission, quick actions.
- Chuẩn hóa loading skeleton cho Home và Quiz.

### Phase 3

- Rà spacing hard-coded toàn bộ app và thay dần bằng `GrowMateLayout` tokens.
- Chuẩn hóa icon sizes theo 3 cấp: supportive, section, hero.
- Thêm visual regression test cho các màn hình lõi.