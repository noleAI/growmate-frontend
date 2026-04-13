# GrowMate Backend Integration Readiness Checklist

> Checklist này dùng để theo dõi tiến độ chuẩn bị tích hợp Backend API.
> Cập nhật trạng thái khi hoàn thành từng mục.

---

## ✅ ĐÃ HOÀN THÀNH

| # | Task | File | Mô tả | Trạng thái |
|---|------|------|-------|-----------|
| 1 | API Contract Specification | `docs/API_CONTRACT_SPECIFICATION.md` | Tài liệu chi tiết 13 endpoints với request/response schemas | ✅ Done |
| 2 | Exception Hierarchy | `lib/core/error/app_exceptions.dart` | 12 exception types với helper functions | ✅ Done |
| 3 | API Config Manager | `lib/core/network/api_config.dart` | Centralized config, environment-aware, từ `.env` | ✅ Done |
| 4 | RealApiService Production-Ready | `lib/core/services/real_api_service.dart` | Auth headers, retry, timeout, error handling | ✅ Done |
| 5 | Learning Session Manager | `lib/core/services/learning_session_manager.dart` | Dynamic session lifecycle, thay thế hardcoded ID | ✅ Done |
| 6 | HTTP Logger | `lib/core/network/http_logger.dart` | Request/response logging (debug only) | ✅ Done |

---

## 🟡 NÊN CÓ (Recommended)

| # | Task | Độ ưu tiên | Ước lượng | Mô tả |
|---|------|-----------|-----------|-------|
| 7 | Entity Models (Freezed) | 🔴 Cao | 1-2 ngày | Tạo models cho Answer, Diagnosis, Intervention, HITL với `fromJson`/`toJson` |
| 8 | Auth Token Storage | 🔴 Cao | 0.5 ngày | Lưu access/refresh tokens trong `flutter_secure_storage` |
| 9 | Main.dart Refactor | 🔴 Cao | 0.5 ngày | Dùng `SessionManager` thay vì hardcoded `'session_demo_001'` |
| 10 | Unit Tests - API Layer | 🟡 Trung bình | 1-2 ngày | Test `RealApiService`, error handling, retry logic |
| 11 | Integration Test Setup | 🟡 Trung bình | 1 ngày | Mock server (JSON Server) cho end-to-end testing |
| 12 | API Error UI | 🟡 Trung bình | 0.5 ngày | Snackbar/dialog hiển thị lỗi từ `AppException` |
| 13 | Network Status Indicator | 🟢 Thấp | 0.5 ngày | Widget hiển thị trạng thái kết nối |
| 14 | Analytics Integration | 🟢 Thấp | 1 ngày | Firebase Crashlytics/Sentry cho error tracking |

---

## 🔴 BẮT BUỘC TRƯỚC KHI TÍCH HỢP

Trước khi backend API sẵn sàng, **PHẢI** hoàn thành:

### 1. Cập nhật `main.dart`

Thay đổi cần thiết:

```dart
// TRƯỚC (hardcoded)
_quizRepository = QuizRepository(
  apiService: _apiService,
  sessionId: 'session_demo_001',  // ❌ HARDCODED
);

// SAU (dynamic)
final sessionManager = LearningSessionManager();
final sessionId = await sessionManager.getActiveSessionId();

_quizRepository = QuizRepository(
  apiService: _apiService,
  sessionId: sessionId,  // ✅ DYNAMIC
);
```

### 2. Cấu hình `.env`

Điền thông tin thật:

```env
# Supabase (đã có)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# REST API (thêm mới)
API_BASE_URL=https://api.growmate.vn/v1
# Hoặc development:
# API_BASE_URL=http://localhost:8080/api/v1
```

### 3. Chuyển đổi từ Mock sang Real API

Trong `main.dart`:

```dart
// TRƯỚC
const bool useMockApi = true;  // ❌ Dùng mock

// SAU
const bool useMockApi = false;  // ✅ Dùng real API
// Hoặc tốt hơn, đọc từ environment:
const bool useMockApi = bool.fromEnvironment('USE_MOCK_API', defaultValue: false);
```

### 4. Inject Auth Token vào RealApiService

```dart
_apiService = RealApiService(
  getAccessToken: () async {
    // Lấy token từ Supabase hoặc secure storage
    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  },
  getRefreshToken: () async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.refreshToken;
  },
  onTokenRefresh: (newAccess, newRefresh) async {
    // Supabase tự handle việc này, nhưng nếu dùng custom backend:
    // Lưu tokens mới vào secure storage
  },
);
```

---

## 📋 BACKEND REQUIREMENTS

Team backend cần cung cấp:

| # | Yêu cầu | Mô tả |
|---|---------|-------|
| B1 | **API Endpoints** | Implement 13 endpoints trong `API_CONTRACT_SPECIFICATION.md` |
| B2 | **Authentication** | JWT-based auth với access/refresh tokens |
| B3 | **Error Format** | Unified error response: `{ status, code, message, details }` |
| B4 | **CORS** | Cho phép requests từ app (nếu web-based) |
| B5 | **Rate Limiting** | Implement rate limits theo spec |
| B6 | **API Documentation** | Swagger/OpenAPI docs (optional nhưng recommended) |
| B7 | **Staging Environment** | Server staging để test trước khi deploy production |

---

## 🧪 TESTING PLAN

### Phase 1: Unit Tests
- [ ] Test `RealApiService` với mock HTTP client
- [ ] Test retry logic với various delay scenarios
- [ ] Test token refresh flow
- [ ] Test error parsing từ various HTTP status codes

### Phase 2: Integration Tests
- [ ] Setup mock server (JSON Server / MockAPI.io)
- [ ] Test login → quiz → diagnosis → intervention flow
- [ ] Test offline mode → queue → flush
- [ ] Test session lifecycle (create → use → complete)

### Phase 3: E2E Tests
- [ ] Test với staging server thật
- [ ] Test auth flow (login, register, logout, token refresh)
- [ ] Test complete learning session end-to-end
- [ ] Test error scenarios (network loss, server error, 401)

---

## 📊 PROGRESS

```
Phase 1: Foundation (Tasks 1-6)     ████████████████████ 100%
Phase 2: Pre-Integration (Tasks 7-9) ░░░░░░░░░░░░░░░░░░░░   0%
Phase 3: Testing (Tasks 10-11)       ░░░░░░░░░░░░░░░░░░░░   0%
Phase 4: Polish (Tasks 12-14)        ░░░░░░░░░░░░░░░░░░░░   0%
```

**Overall Readiness: ~40% → 65%** (sau khi hoàn thành Phase 1)

---

## 🚀 NEXT STEPS

1. **Ngay bây giờ:** Review `API_CONTRACT_SPECIFICATION.md` và gửi cho team backend
2. **Tiếp theo:** Implement Tasks 7-9 (Entity Models, Token Storage, Main refactor)
3. **Khi backend sẵn sàng:** Chuyển `useMockApi = false` và test với API thật
4. **Sau tích hợp:** Implement Tasks 10-14 cho production readiness

---

*Cập nhật lần cuối: 2026-04-12*
