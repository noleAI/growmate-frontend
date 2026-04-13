# GrowMate API Contract Specification

> Tài liệu này định nghĩa các API endpoints mà frontend cần từ backend REST API.
> Dùng làm reference để team backend phát triển và team frontend tích hợp.
> 
> **Version:** 1.0.0
> **Last Updated:** 2026-04-12
> **Base URL:** `https://api.growmate.vn/v1` (production)

---

## Mục lục

1. [Authentication](#1-authentication)
2. [Quiz](#2-quiz)
3. [Diagnosis](#3-diagnosis)
4. [Signals](#4-signals)
5. [Intervention](#5-intervention)
6. [Memory](#6-memory)
7. [Session](#7-session)
8. [Error Responses](#8-error-responses)

---

## 1. Authentication

### 1.1. Login
- **Endpoint:** `POST /auth/login`
- **Request Body:**
```json
{
  "email": "string (required, valid email)",
  "password": "string (required, min 6 chars)"
}
```
- **Response 200:**
```json
{
  "status": "success",
  "data": {
    "access_token": "string (JWT)",
    "refresh_token": "string (JWT)",
    "expires_in": 3600,
    "token_type": "Bearer",
    "user": {
      "id": "string (UUID)",
      "email": "string",
      "display_name": "string",
      "role": "student | mentor | admin",
      "created_at": "ISO 8601 datetime"
    }
  }
}
```

### 1.2. Register
- **Endpoint:** `POST /auth/register`
- **Request Body:**
```json
{
  "name": "string (required)",
  "email": "string (required, valid email)",
  "password": "string (required, min 6 chars)",
  "confirm_password": "string (required, must match password)"
}
```
- **Response 201:** (same structure as Login)

### 1.3. Refresh Token
- **Endpoint:** `POST /auth/refresh`
- **Request Body:**
```json
{
  "refresh_token": "string (required)"
}
```
- **Response 200:**
```json
{
  "status": "success",
  "data": {
    "access_token": "string (JWT)",
    "refresh_token": "string (JWT)",
    "expires_in": 3600
  }
}
```

### 1.4. Logout
- **Endpoint:** `POST /auth/logout`
- **Headers:** `Authorization: Bearer <token>`
- **Response 200:**
```json
{
  "status": "success",
  "message": "Logged out successfully"
}
```

### 1.5. Password Reset
- **Endpoint:** `POST /auth/forgot-password`
- **Request Body:**
```json
{
  "email": "string (required, valid email)"
}
```
- **Response 200:**
```json
{
  "status": "success",
  "message": "Password reset link sent to your email"
}
```

---

## 2. Quiz

### 2.1. Submit Answer
- **Endpoint:** `POST /quiz/submit-answer`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "sessionId": "string (UUID, required)",
  "questionId": "string (required)",
  "answerText": "string (required)",
  "context": {
    "timeSpent": "number (seconds, optional)",
    "attempts": "number (optional)",
    "hintsUsed": "boolean (optional)"
  }
}
```
- **Response 200:**
```json
{
  "status": "success",
  "message": "Answer accepted and queued for diagnosis.",
  "data": {
    "sessionId": "string (UUID)",
    "answerId": "string (UUID, newly created)",
    "questionId": "string",
    "answerText": "string",
    "isCorrect": "boolean (if auto-evaluable)",
    "score": "number (optional)",
    "maxScore": "number (optional)",
    "receivedAt": "ISO 8601 datetime",
    "pipeline": {
      "nextStep": "diagnosis",
      "estimatedSeconds": 2
    }
  }
}
```

### 2.2. Fetch Question Templates
> **Note:** Hiện tại frontend đọc trực tiếp từ Supabase. Nếu backend REST cần hỗ trợ:

- **Endpoint:** `GET /quiz/questions?subject=math&examYear=2026&limit=6`
- **Headers:** `Authorization: Bearer <token>`
- **Response 200:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "string (UUID)",
      "subject": "math",
      "topicCode": "DERIVATIVE_01",
      "topicName": "Đạo hàm cơ bản",
      "examYear": 2026,
      "questionType": "MULTIPLE_CHOICE | TRUE_FALSE_CLUSTER | SHORT_ANSWER",
      "partNo": 1,
      "difficultyLevel": 2,
      "content": "string (question text)",
      "mediaUrl": "string (optional)",
      "payload": {
        "options": [
          { "id": "A", "text": "string" }
        ],
        "correct_option_id": "A",
        "explanation": "string"
      },
      "metadata": {},
      "isActive": true,
      "createdAt": "ISO 8601 datetime"
    }
  ]
}
```

---

## 3. Diagnosis

### 3.1. Get Diagnosis Result
- **Endpoint:** `POST /diagnosis/get`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "sessionId": "string (UUID, required)",
  "answerId": "string (UUID, required)"
}
```
- **Response 200:**
```json
{
  "status": "success",
  "message": "Diagnosis completed.",
  "data": {
    "sessionId": "string (UUID)",
    "answerId": "string (UUID)",
    "diagnosisId": "string (UUID)",
    "title": "string (headline for user)",
    "gapAnalysis": "string",
    "diagnosisReason": "string",
    "strengths": ["string"],
    "needsReview": ["string"],
    "mode": "normal | recovery | hitl_pending",
    "requiresHITL": false,
    "recoveryMode": false,
    "riskLevel": "low | medium | high",
    "confidence": 0.91,
    "uncertaintyScore": 0.15,
    "summary": "string (internal summary)",
    "interventionPlan": [
      {
        "id": "int_breath_01",
        "title": "Box breathing 4-4-4",
        "durationMinutes": 3,
        "type": "breathing | grounding | journaling | practice | theory"
      }
    ],
    "hitl": null
  }
}
```

**Khi HITL được trigger:**
```json
{
  "data": {
    "mode": "hitl_pending",
    "requiresHITL": true,
    "riskLevel": "high",
    "confidence": 0.41,
    "interventionPlan": [],
    "hitl": {
      "ticketId": "string (UUID)",
      "status": "pending",
      "reason": "low_confidence_high_risk",
      "priority": "urgent"
    }
  }
}
```

### 3.2. Confirm HITL Decision
- **Endpoint:** `POST /diagnosis/hitl/confirm`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "sessionId": "string (UUID, required)",
  "diagnosisId": "string (UUID, required)",
  "approved": "boolean (required)",
  "reviewerNote": "string (optional)"
}
```
- **Response 200:**
```json
{
  "status": "success",
  "message": "HITL approved and intervention unlocked.",
  "data": {
    "sessionId": "string (UUID)",
    "diagnosisId": "string (UUID)",
    "hitlDecision": "approved | rejected",
    "reviewerNote": "string",
    "finalMode": "normal | recovery",
    "interventionPlan": [
      {
        "id": "string",
        "title": "string",
        "durationMinutes": 4,
        "type": "string"
      }
    ]
  }
}
```

---

## 4. Signals

### 4.1. Submit Behavioral Signals (Batch)
- **Endpoint:** `POST /signals/batch`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "sessionId": "string (UUID, required)",
  "signals": [
    {
      "questionId": "string",
      "typingSpeed": "number (keystrokes/min)",
      "idleTime": "number (seconds)",
      "correctionRate": "number (percentage 0-100)",
      "responseTime": "number (seconds, optional)",
      "capturedAt": "ISO 8601 datetime",
      "trigger": "string (e.g., 'answer_submit', 'idle_detected')"
    }
  ]
}
```
- **Response 200:**
```json
{
  "status": "success",
  "message": "Signals accepted.",
  "data": {
    "sessionId": "string (UUID)",
    "acceptedCount": 3,
    "receivedAt": "ISO 8601 datetime"
  }
}
```

---

## 5. Intervention

### 5.1. Submit Intervention Feedback
- **Endpoint:** `POST /intervention/feedback`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "sessionId": "string (UUID, required)",
  "submissionId": "string (UUID, required)",
  "diagnosisId": "string (UUID, required)",
  "optionId": "string (required)",
  "optionLabel": "string (required)",
  "mode": "normal | recovery (required)",
  "remainingRestSeconds": 0,
  "skipped": false
}
```
- **Response 200:**
```json
{
  "status": "success",
  "message": "Đã ghi nhận lựa chọn của bạn và cập nhật Q-values thành công.",
  "data": {
    "sessionId": "string (UUID)",
    "submissionId": "string (UUID)",
    "diagnosisId": "string (UUID)",
    "selectedOption": {
      "id": "string",
      "label": "string",
      "mode": "normal | recovery",
      "remainingRestSeconds": 0,
      "skipped": false
    },
    "updatedQValues": {
      "review_theory": 0.79,
      "easier_practice": 0.77,
      "take_rest": 0.80
    }
  }
}
```

---

## 6. Memory

### 6.1. Save Interaction Feedback
- **Endpoint:** `POST /memory/interaction-feedback`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "sessionId": "string (UUID, required)",
  "submissionId": "string (UUID, required)",
  "diagnosisId": "string (UUID, required)",
  "eventName": "Plan Accepted | Plan Rejected | Intervention Completed | Session Abandoned",
  "memoryScope": "session | user | topic (required)",
  "reason": "string (optional)",
  "metadata": {
    "nextSuggestedTopic": "string (optional)",
    "...": "any additional context"
  }
}
```
- **Response 200:**
```json
{
  "status": "success",
  "message": "Interaction feedback stored in episodic memory.",
  "data": {
    "sessionId": "string (UUID)",
    "submissionId": "string (UUID)",
    "diagnosisId": "string (UUID)",
    "eventName": "string",
    "memoryScope": "string",
    "reason": "string",
    "nextSuggestedTopic": "string",
    "eventId": "string (UUID)",
    "savedAt": "ISO 8601 datetime",
    "metadata": {}
  }
}
```

---

## 7. Session

### 7.1. Start Learning Session
- **Endpoint:** `POST /sessions/start`
- **Headers:** `Authorization: Bearer <token>`
- **Response 201:**
```json
{
  "status": "success",
  "data": {
    "sessionId": "string (UUID)",
    "startTime": "ISO 8601 datetime",
    "status": "active"
  }
}
```

### 7.2. Complete Session
- **Endpoint:** `POST /sessions/:id/complete`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "status": "completed | paused | cancelled"
}
```
- **Response 200:**
```json
{
  "status": "success",
  "data": {
    "sessionId": "string (UUID)",
    "endTime": "ISO 8601 datetime",
    "status": "completed"
  }
}
```

### 7.3. Get Active Session
- **Endpoint:** `GET /sessions/active`
- **Headers:** `Authorization: Bearer <token>`
- **Response 200:** (same as Start, or 404 if no active session)

### 7.4. Get Session History
- **Endpoint:** `GET /sessions/history?limit=20&offset=0`
- **Headers:** `Authorization: Bearer <token>`
- **Response 200:**
```json
{
  "status": "success",
  "data": {
    "items": [
      {
        "sessionId": "string (UUID)",
        "startTime": "ISO 8601 datetime",
        "endTime": "ISO 8601 datetime",
        "status": "completed | paused | cancelled",
        "totalScore": 8.5,
        "questionsAnswered": 12
      }
    ],
    "total": 45,
    "limit": 20,
    "offset": 0
  }
}
```

---

## 8. Error Responses

### 8.1. Standard Error Format
Tất cả error responses đều có cấu trúc:
```json
{
  "status": "error",
  "code": "string (machine-readable error code)",
  "message": "string (human-readable message in Vietnamese)",
  "details": {}
}
```

### 8.2. Error Codes

| HTTP Code | Error Code | Mô tả |
|-----------|-----------|-------|
| 400 | `VALIDATION_ERROR` | Request body không hợp lệ |
| 401 | `UNAUTHORIZED` | Thiếu token hoặc token không hợp lệ |
| 401 | `TOKEN_EXPIRED` | Access token hết hạn |
| 403 | `FORBIDDEN` | Không có quyền truy cập |
| 404 | `NOT_FOUND` | Resource không tồn tại |
| 409 | `CONFLICT` | Resource đã tồn tại (e.g., email đăng ký) |
| 422 | `UNPROCESSABLE_ENTITY` | Dữ liệu không hợp lệ về mặt logic |
| 429 | `RATE_LIMITED` | Quá số lần request |
| 500 | `INTERNAL_ERROR` | Lỗi server |
| 503 | `SERVICE_UNAVAILABLE` | Server đang bảo trì |

### 8.3. Example: Validation Error
```json
{
  "status": "error",
  "code": "VALIDATION_ERROR",
  "message": "Dữ liệu không hợp lệ",
  "details": {
    "email": "Email không hợp lệ",
    "password": "Mật khẩu cần ít nhất 6 ký tự"
  }
}
```

### 8.4. Example: Token Expired
```json
{
  "status": "error",
  "code": "TOKEN_EXPIRED",
  "message": "Phiên đăng nhập hết hạn, vui lòng đăng nhập lại"
}
```

---

## 9. Authentication Flow

### 9.1. Headers
Tất cả requests (trừ auth endpoints) cần có:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

### 9.2. Token Refresh Flow
1. Access token hết hạn → Server trả về `401 TOKEN_EXPIRED`
2. Frontend tự động gọi `POST /auth/refresh` với refresh_token
3. Nếu thành công → Lưu tokens mới và retry request ban đầu
4. Nếu thất bại → Logout và redirect về login page

### 9.3. Token Storage
- Frontend lưu tokens trong `flutter_secure_storage` (encrypted)
- Access token: TTL 1 giờ
- Refresh token: TTL 30 ngày

---

## 10. Rate Limiting

| Endpoint | Limit |
|----------|-------|
| `/auth/login` | 5 requests / phút |
| `/auth/register` | 3 requests / phút |
| `/quiz/submit-answer` | 30 requests / phút |
| `/signals/batch` | 60 requests / phút |
| All others | 100 requests / phút |

---

## Phụ lục: Mapping với Supabase RPC

| REST Endpoint | Supabase RPC Function |
|---------------|----------------------|
| `POST /sessions/start` | `start_learning_session()` |
| `POST /signals/batch` | `insert_behavioral_signals_batch()` |
| `POST /intervention/feedback` | `upsert_q_value()` |
| `POST /memory/interaction-feedback` | `save_interaction_feedback()` |
| `POST /sessions/:id/complete` | `complete_learning_session()` |
| (internal) | `insert_audit_event()` |

> **Lưu ý:** Backend có thể dùng Supabase RPC trực tiếp hoặc implement logic tương đương.
