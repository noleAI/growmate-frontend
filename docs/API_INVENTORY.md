# GrowMate Backend - Complete API Inventory

**Last Updated:** April 16, 2026  
**Backend Version:** 1.0.0  
**API Version:** v1

---

## Table of Contents
1. [Health Check](#health-check)
2. [Session Management](#session-management)
3. [Quiz System](#quiz-system)
4. [Orchestrator](#orchestrator)
5. [Inspection & Debugging](#inspection--debugging)
6. [Configuration](#configuration)
7. [Quota Management](#quota-management)
8. [Session Recovery](#session-recovery)
9. [Leaderboard & XP System](#leaderboard--xp-system)
10. [Lives System](#lives-system)
11. [Formulas & Reference](#formulas--reference)
12. [Onboarding](#onboarding)
13. [User Profile](#user-profile)
14. [WebSocket Connections](#websocket-connections)

---

## Health Check

### Health Status
- **Method:** `GET`
- **Path:** `/health`
- **Authentication:** None
- **Description:** Returns API health status
- **Response:**
  ```json
  {
    "status": "healthy"
  }
  ```
- **Status Codes:** 200 OK
- **Related Files:** `main.py`

---

## Session Management

### Create Session
- **Method:** `POST`
- **Path:** `/api/v1/sessions`
- **Authentication:** Bearer Token (JWT)
- **Request Body:**
  ```json
  {
    "subject": "string (required)",
    "topic": "string (required)",
    "mode": "string or null (optional: 'exam_prep' or 'explore', defaults to 'explore')",
    "classification_level": "string or null (optional: 'beginner', 'intermediate', 'advanced')",
    "onboarding_results": "dict or null (optional)"
  }
  ```
- **Response Model:** `SessionResponse`
  ```json
  {
    "session_id": "string (UUID)",
    "status": "active",
    "start_time": "ISO 8601 timestamp",
    "initial_state": {
      "subject": "string",
      "topic": "string",
      "beliefs": "dict (Bayesian tracker beliefs)",
      "student_id": "string",
      "classification_level": "string",
      "mode": "string"
    }
  }
  ```
- **Status Codes:**
  - 200 OK: Session created successfully
  - 400 Bad Request: Invalid mode or parameters
  - 401 Unauthorized: Missing/invalid authentication
  - 429 Too Many Requests: Daily session limit exceeded (max 5 sessions/day)
- **Rate Limiting:** Daily limit enforced (default 5 sessions/day, configurable)
- **Side Effects:**
  - Creates learning session record in Supabase
  - Initializes memory store state with Bayesian tracker beliefs
  - Checks daily session count
- **Related Files:**
  - `api/routes/session.py` → `create_session()`
  - `models/requests.py` → `SessionCreateRequest`
  - `models/responses.py` → `SessionResponse`
  - `core/memory_store.py`
  - `core/supabase_client.py` → `count_daily_learning_sessions()`, `insert_learning_session()`

### Update Session
- **Method:** `PATCH`
- **Path:** `/api/v1/sessions/{session_id}`
- **Authentication:** Bearer Token (JWT)
- **Path Parameters:**
  - `session_id` (string, required): UUID of session to update
- **Request Body:**
  ```json
  {
    "status": "string (required: 'active', 'completed', or 'abandoned')"
  }
  ```
- **Response:**
  ```json
  {
    "status": "success",
    "session_id": "string",
    "session_status": "string"
  }
  ```
- **Status Codes:**
  - 200 OK: Session updated
  - 400 Bad Request: Invalid status value
  - 401 Unauthorized: Missing student identifier
  - 404 Not Found: Session not found
  - 500 Internal Server Error: Database operation failed
- **Side Effects:**
  - Updates session record with status and end_time in Supabase
  - Updates cached session state in memory store
  - Sets end_time only for 'completed' or 'abandoned' statuses
- **Related Files:**
  - `api/routes/session.py` → `update_session()`
  - `models/requests.py` → `UpdateSessionRequest`
  - `core/supabase_client.py` → `update_learning_session()`

### Get Pending Session
- **Method:** `GET`
- **Path:** `/api/v1/sessions/pending`
- **Authentication:** Bearer Token (JWT)
- **Description:** Retrieves the latest active (pending) session for the current user, used for session recovery
- **Response:**
  ```json
  {
    "has_pending": "boolean",
    "session": {
      "session_id": "string (UUID)",
      "status": "string",
      "last_question_index": "integer",
      "total_questions": "integer",
      "progress_percent": "integer (0-100)",
      "last_active_at": "ISO 8601 timestamp",
      "abandoned_at": "ISO 8601 timestamp or null"
    } or null
  }
  ```
- **Status Codes:**
  - 200 OK: Pending session retrieved
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Database operation failed
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/session.py` → `get_pending_session()`
  - `api/routes/session_recovery.py` → `get_pending_session()` (duplicate endpoint)
  - `core/supabase_client.py` → `get_latest_active_learning_session()`

### Interact with Session (Complex Orchestrator Flow)
- **Method:** `POST`
- **Path:** `/api/v1/sessions/{session_id}/interact`
- **Authentication:** Bearer Token (JWT) + Quiz Signature Validation (for quiz actions)
- **Path Parameters:**
  - `session_id` (string, required): UUID of session
- **Request Body:**
  ```json
  {
    "action_type": "string (required: e.g., 'submit_quiz', 'submit_answer', 'hint_request')",
    "quiz_id": "string or null (optional)",
    "response_data": {
      "behavior_signals": "dict (typing speed, correct_rate, etc.)",
      ...
    } or null,
    "xp_data": "dict or null (optional)",
    "mode": "string or null (optional: 'exam_prep' or 'explore')",
    "classification_level": "string or null (optional)",
    "onboarding_results": "dict or null (optional)",
    "analytics_data": "dict or null (optional)",
    "is_off_topic": "boolean (default: false)",
    "resume": "boolean (default: false)"
  }
  ```
- **Response Model:** `InteractionResponse`
  ```json
  {
    "next_node_type": "string (e.g., 'hint', 'backtrack_repair', 'hitl_pending')",
    "content": "string (feedback/hint text)",
    "plan_repaired": "boolean",
    "belief_entropy": "float (0.0-1.0)",
    "data_driven": {
      "diagnosis": "dict",
      "interventions": "list[dict]",
      "selectedIntervention": "dict or null",
      "formulaRecommendations": "list[FormulaRecommendationResponse]",
      "systemBehavior": "dict"
    } or null
  }
  ```
- **Status Codes:**
  - 200 OK: Interaction processed
  - 400 Bad Request: Invalid mode or parameters
  - 401 Unauthorized: Missing authentication
  - 403 Forbidden: No lives remaining (exam_prep mode only)
  - 500 Internal Server Error: Orchestrator failed
- **Headers Required:**
  - `X-Quiz-Signature`: HMAC signature for quiz actions (optional, required for 'submit_quiz'/'submit_answer')
- **Side Effects:**
  - Runs full orchestrator pipeline (academic, empathy, strategy agents)
  - Updates Bayesian beliefs
  - Triggers potential HITL intervention if uncertainty high
  - Deducts lives if incorrect answer in exam_prep mode
  - Falls back to legacy Bayesian/HTN route if orchestrator fails
- **Rate Limiting:** Daily session limit applies (5 sessions/day in exam_prep mode)
- **Related Files:**
  - `api/routes/session.py` → `interact()`
  - `models/requests.py` → `InteractionRequest`
  - `models/responses.py` → `InteractionResponse`, `DataDrivenResponse`
  - `api/routes/orchestrator_runtime.py` → `get_orchestrator()`
  - `core/security.py` → `verify_quiz_signature()`
  - `core/lives_engine.py` → `can_play()`, `check_regen()`

---

## Quiz System

### Get Next Question
- **Method:** `GET`
- **Path:** `/api/v1/quiz/next`
- **Authentication:** Bearer Token (JWT)
- **Query Parameters:**
  - `session_id` (string, required, min length 1): Session UUID
  - `index` (integer, optional, default 0, >= 0): Current question index
  - `total_questions` (integer, optional, default 10, ge 1, le 30): Total questions in session
  - `mode` (string, optional): 'exam_prep' or 'explore'
- **Description:** Retrieves the next question from quiz service based on current session state
- **Response:**
  ```json
  {
    "status": "string ('ok' or 'completed')",
    "session_id": "string",
    "mode": "string (if status='ok')",
    "timer_sec": "integer or null (45 for exam_prep, null for explore)",
    "next_question": {
      "question_id": "string",
      "content": "string (may contain LaTeX in $...$ for inline math)",
      "options": "list[string]",
      "type": "string (e.g., 'multiple_choice', 'short_answer')",
      "metadata": {
        "formula": "string (optional LaTeX formula)",
        "renderAsLatex": "boolean",
        "difficulty": "string (optional)",
        ...
      }
    } or null
  }
  ```
- **Status Codes:**
  - 200 OK: Question retrieved or session completed
  - 400 Bad Request: Invalid mode or parameters
  - 401 Unauthorized: Missing student identifier
  - 429 Too Many Requests: Daily session limit exceeded (exam_prep mode)
- **Rate Limiting:**
  - Soft guard: max 5 exam_prep sessions/day/user
  - Enforced at session creation and quiz flow
- **Side Effects:**
  - Calls `quiz_service.get_question_for_session()`
  - Does not modify state
- **Related Files:**
  - `api/routes/quiz.py` → `get_next_question()`
  - `core/quiz_service.py` → `get_question_for_session()`
  - `core/supabase_client.py` → `count_daily_learning_sessions()`

### Submit Quiz Answer
- **Method:** `POST`
- **Path:** `/api/v1/quiz/submit`
- **Authentication:** Bearer Token (JWT)
- **Security:** Requires valid Quiz HMAC Signature
- **Request Body:**
  ```json
  {
    "session_id": "string (required)",
    "question_id": "string (required)",
    "selected_option": "string or null (for multiple choice)",
    "answer": "string or null (for short answer)",
    "answers": "dict or null (for cluster/complex answers)",
    "time_taken_sec": "float or null (optional)",
    "mode": "string or null (optional: 'exam_prep' or 'explore')"
  }
  ```
- **Response:**
  ```json
  {
    "session_id": "string",
    "question_id": "string",
    "is_correct": "boolean",
    "explanation": "string",
    "lives_remaining": "integer (only if exam_prep mode and incorrect)",
    "can_play": "boolean (only if exam_prep mode and incorrect)",
    "next_regen_in_seconds": "integer (only if exam_prep mode and incorrect)"
  }
  ```
- **Status Codes:**
  - 200 OK: Answer submitted and evaluated
  - 400 Bad Request: Invalid question or answer format
  - 401 Unauthorized: Missing authentication
  - 500 Internal Server Error: Quiz evaluation failed
- **Headers Required:**
  - `X-Quiz-Signature`: HMAC signature (required)
- **Side Effects:**
  - Evaluates answer via quiz_service
  - If exam_prep mode and incorrect: deducts 1 life via `lose_life()`
  - Updates lives status (remaining, regen time)
- **Related Files:**
  - `api/routes/quiz.py` → `submit_quiz_answer()`
  - `models/requests.py` → `QuizSubmitRequest`
  - `core/quiz_service.py` → `submit_answer()`
  - `core/security.py` → `require_quiz_signature()`
  - `core/lives_engine.py` → `lose_life()`, `check_regen()`

---

## Orchestrator

### Run Orchestrator Step
- **Method:** `POST`
- **Path:** `/api/v1/orchestrator/step`
- **Authentication:** Bearer Token (JWT)
- **Request Body:**
  ```json
  {
    "session_id": "string (required)",
    "question_id": "string or null (optional)",
    "response": "dict or null (optional)",
    "behavior_signals": "dict or null (optional)",
    "xp_data": "dict or null (optional)",
    "mode": "string or null (optional: 'exam_prep' or 'explore')",
    "classification_level": "string or null (optional)",
    "onboarding_results": "dict or null (optional)",
    "analytics_data": "dict or null (optional)",
    "is_off_topic": "boolean (default: false)",
    "resume": "boolean (default: false)"
  }
  ```
- **Description:** Directly invokes the orchestrator pipeline for a session step
- **Response:**
  ```json
  {
    "status": "ok",
    "result": {
      "action": "string",
      "payload": {
        "text": "string"
      },
      "dashboard_update": {
        "academic": {
          "entropy": "float"
        }
      },
      "data_driven": "dict or null"
    }
  }
  ```
- **Status Codes:**
  - 200 OK: Step executed
  - 400 Bad Request: Invalid mode or parameters
  - 401 Unauthorized: Missing authentication
  - 500 Internal Server Error: Orchestrator execution failed
- **Side Effects:**
  - Calls orchestrator instance for session
  - Updates internal state (beliefs, particles, Q-values)
  - May trigger interventions
  - Manages orchestrator LRU cache (max 1024 sessions by default)
- **Related Files:**
  - `api/routes/orchestrator.py` → `run_orchestrator_step()`
  - `models/requests.py` → `OrchestratorStepRequest`
  - `api/routes/orchestrator_runtime.py` → `get_orchestrator()`
  - `agents/orchestrator.py` → `AgenticOrchestrator.run_session_step()`

---

## Inspection & Debugging

### Get Belief State
- **Method:** `GET`
- **Path:** `/api/v1/inspection/belief-state/{session_id}`
- **Authentication:** Bearer Token (JWT)
- **Path Parameters:**
  - `session_id` (string, required): Session UUID
- **Description:** Retrieves Bayesian tracker beliefs for a session (inspection dashboard use)
- **Response:**
  ```json
  {
    "session_id": "string",
    "beliefs": "dict (topic/concept -> belief_value)"
  }
  ```
- **Status Codes:** 200 OK
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/inspection.py` → `get_belief_state()`
  - `agents/academic_agent/bayesian_tracker.py`

### Get Particle State
- **Method:** `GET`
- **Path:** `/api/v1/inspection/particle-state/{session_id}`
- **Authentication:** Bearer Token (JWT)
- **Path Parameters:**
  - `session_id` (string, required): Session UUID
- **Description:** Retrieves empathy agent particle filter state summary
- **Response:**
  ```json
  {
    "session_id": "string",
    "state_summary": "dict (particles summary)"
  }
  ```
- **Status Codes:** 200 OK
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/inspection.py` → `get_particle_state()`
  - `agents/empathy_agent/particle_filter.py`

### Get Q-Values
- **Method:** `GET`
- **Path:** `/api/v1/inspection/q-values`
- **Authentication:** Bearer Token (JWT)
- **Description:** Retrieves strategy agent Q-learning table (global fallback or session-specific)
- **Response:**
  ```json
  {
    "q_table": "dict (state,action -> q_value)"
  }
  ```
- **Status Codes:** 200 OK
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/inspection.py` → `get_q_values()`
  - `agents/strategy_agent/q_learning.py`

### Get Audit Logs
- **Method:** `GET`
- **Path:** `/api/v1/inspection/audit-logs/{session_id}`
- **Authentication:** Bearer Token (JWT)
- **Path Parameters:**
  - `session_id` (string, required): Session UUID
- **Description:** Placeholder endpoint for audit logs (returns empty array)
- **Response:**
  ```json
  {
    "session_id": "string",
    "logs": "list (empty)"
  }
  ```
- **Status Codes:** 200 OK
- **Related Files:**
  - `api/routes/inspection.py` → `get_audit_logs()`

---

## Configuration

### Get Config
- **Method:** `GET`
- **Path:** `/api/v1/configs/{category}`
- **Authentication:** Bearer Token (JWT)
- **Path Parameters:**
  - `category` (string, required): Config category name
- **Description:** Retrieves configuration for a given category
- **Response:**
  ```json
  {
    "category": "string",
    "version": "v1.0",
    "payload": "dict"
  }
  ```
- **Status Codes:** 200 OK
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/config.py` → `get_config()`

### Upload Config
- **Method:** `POST`
- **Path:** `/api/v1/configs/{category}`
- **Authentication:** Bearer Token (JWT)
- **Path Parameters:**
  - `category` (string, required): Config category name
- **Request Body:**
  ```json
  {
    // Any configuration payload
  }
  ```
- **Description:** Updates configuration for a given category (admin-only in production)
- **Response:**
  ```json
  {
    "category": "string",
    "status": "updated"
  }
  ```
- **Status Codes:** 200 OK
- **Side Effects:** Updates config record (admin role check not yet implemented)
- **Related Files:**
  - `api/routes/config.py` → `upload_config()`

---

## Quota Management

### Get Quota
- **Method:** `GET`
- **Path:** `/api/v1/quota`
- **Authentication:** Bearer Token (JWT)
- **Description:** Retrieves daily API quota usage for current user (Vietnam timezone-aware)
- **Response:**
  ```json
  {
    "used": "integer (API calls used today)",
    "limit": "integer (20 calls/day free tier)",
    "remaining": "integer",
    "reset_at": "ISO 8601 timestamp (next midnight Vietnam time)"
  }
  ```
- **Status Codes:**
  - 200 OK: Quota retrieved
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to read quota usage
- **Timezone:** Vietnam (UTC+7)
- **Default Daily Quota:** 20 free calls
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/quota.py` → `get_quota()`
  - `core/supabase_client.py` → `get_user_token_usage()`

---

## Session Recovery

### Get Pending Session (Recovery)
- **Method:** `GET`
- **Path:** `/api/v1/session/pending`
- **Authentication:** Bearer Token (JWT)
- **Description:** Alias endpoint for session recovery; retrieves latest active session
- **Response:** Same as [Get Pending Session](#get-pending-session) under Session Management
- **Status Codes:** Same as Session Management endpoint
- **Related Files:**
  - `api/routes/session_recovery.py` → `get_pending_session()`

---

## Leaderboard & XP System

### Get Leaderboard
- **Method:** `GET`
- **Path:** `/api/v1/leaderboard`
- **Authentication:** Bearer Token (JWT)
- **Query Parameters:**
  - `period` (string, optional, default 'weekly'): 'weekly', 'monthly', or 'all_time'
  - `limit` (integer, optional, default 20, ge 1, le 100): Number of top players to return
- **Description:** Retrieves ranked leaderboard with player XP and badges
- **Response:**
  ```json
  {
    "period": "string",
    "total_players": "integer",
    "leaderboard": [
      {
        "rank": "integer",
        "user_id": "string",
        "display_name": "string or null",
        "avatar_url": "string or null",
        "xp": "integer (ranked by period)",
        "streak": "integer (current)",
        "badge_count": "integer",
        "weekly_xp": "integer",
        "total_xp": "integer",
        "current_streak": "integer",
        "longest_streak": "integer"
      }
    ]
  }
  ```
- **Status Codes:**
  - 200 OK: Leaderboard retrieved
  - 400 Bad Request: Invalid period
  - 500 Internal Server Error: Failed to load leaderboard
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/leaderboard.py` → `get_leaderboard()`
  - `core/supabase_client.py` → `list_user_xp_rows()`, `list_user_badges()`, `list_user_profiles_by_ids()`

### Get My Rank
- **Method:** `GET`
- **Path:** `/api/v1/leaderboard/me`
- **Authentication:** Bearer Token (JWT)
- **Query Parameters:**
  - `period` (string, optional, default 'weekly'): 'weekly', 'monthly', or 'all_time'
- **Description:** Retrieves current user's rank and stats on leaderboard
- **Response:**
  ```json
  {
    "period": "string",
    "rank": "integer or null",
    "user_id": "string",
    "display_name": "string or null",
    "avatar_url": "string or null",
    "weekly_xp": "integer",
    "total_xp": "integer",
    "current_streak": "integer",
    "longest_streak": "integer",
    "badge_count": "integer"
  }
  ```
- **Status Codes:**
  - 200 OK: User rank retrieved
  - 400 Bad Request: Invalid period
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to load user rank
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/leaderboard.py` → `get_my_rank()`
  - `core/supabase_client.py` → `list_all_user_xp_rows()`, `list_user_badges()`, `get_user_profile()`

### Add XP
- **Method:** `POST`
- **Path:** `/api/v1/xp/add`
- **Authentication:** Bearer Token (JWT)
- **Request Body:**
  ```json
  {
    "event_type": "string (required: e.g., 'quiz_correct', 'streak_daily')",
    "extra_data": "dict (optional: mastery_topics, etc.)"
  }
  ```
- **Description:** Awards XP to current user based on event type; updates streaks and evaluates badge candidates
- **Response:**
  ```json
  {
    "xp_added": "integer",
    "breakdown": {
      "total_xp": "integer",
      ...
    },
    "weekly_xp": "integer",
    "total_xp": "integer",
    "current_streak": "integer",
    "new_badges": [
      {
        "badge_type": "string (e.g., 'streak_7', 'top_10_weekly', 'mastery_calculus')",
        "badge_name": "string (Vietnamese)",
        "description": "string",
        "icon": "string (emoji)",
        "earned_at": "ISO 8601 timestamp"
      }
    ]
  }
  ```
- **Status Codes:**
  - 200 OK: XP added successfully
  - 400 Bad Request: Invalid event_type
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to add XP
- **Side Effects:**
  - Upserts XP row for user
  - Updates streak based on last_active_date
  - Evaluates badge candidates (streak_7, top_10_weekly, mastery_*)
  - Creates new badge records in Supabase
- **Badge Catalog:**
  - `streak_7`: 7-day consecutive learning streak
  - `top_10_weekly`: Rank in top 10 weekly leaderboard
  - `mastery_*`: 100% mastery on topic (e.g., `mastery_calculus`)
- **Related Files:**
  - `api/routes/leaderboard.py` → `add_xp()`
  - `models/requests.py` → `XpAddRequest`
  - `core/xp_engine.py` → `calculate_xp()`, `evaluate_badge_candidates()`, `resolve_streak_update()`
  - `core/supabase_client.py` → `upsert_user_xp()`, `create_user_badge()`, `list_all_user_xp_rows()`

### Get Badges
- **Method:** `GET`
- **Path:** `/api/v1/badges`
- **Authentication:** Bearer Token (JWT)
- **Description:** Retrieves all earned badges for current user with available/unclaimed badges
- **Response:**
  ```json
  {
    "user_id": "string",
    "earned_badges": [
      {
        "badge_type": "string",
        "badge_name": "string",
        "description": "string",
        "icon": "string",
        "earned_at": "ISO 8601 timestamp"
      }
    ],
    "available_badges": [
      {
        "badge_type": "string",
        "badge_name": "string",
        "description": "string",
        "icon": "string"
      }
    ]
  }
  ```
- **Status Codes:**
  - 200 OK: Badges retrieved
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to load badges
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/leaderboard.py` → `get_badges()`
  - `core/supabase_client.py` → `list_user_badges()`

---

## Lives System

### Get Lives
- **Method:** `GET`
- **Path:** `/api/v1/lives`
- **Authentication:** Bearer Token (JWT)
- **Description:** Retrieves current lives status including regeneration timing
- **Response:**
  ```json
  {
    "current": "integer (0-3)",
    "max": "integer (3)",
    "can_play": "boolean",
    "next_regen_at": "ISO 8601 timestamp or null",
    "next_regen_in_seconds": "integer or null"
  }
  ```
- **Status Codes:**
  - 200 OK: Lives retrieved
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to load lives
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/lives.py` → `get_lives()`
  - `core/lives_engine.py` → `check_regen()`
  - `core/supabase_client.py`

### Consume Life
- **Method:** `POST`
- **Path:** `/api/v1/lives/lose`
- **Authentication:** Bearer Token (JWT)
- **Description:** Deducts 1 life from current user (called when incorrect answer in exam_prep mode)
- **Request Body:** Empty
- **Response:**
  ```json
  {
    "remaining": "integer",
    "current": "integer (0-3)",
    "max": "integer (3)",
    "can_play": "boolean",
    "next_regen_at": "ISO 8601 timestamp or null",
    "next_regen_in_seconds": "integer or null"
  }
  ```
- **Status Codes:**
  - 200 OK: Life deducted
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to update lives
- **Side Effects:**
  - Deducts 1 life (minimum 0)
  - Triggers regen timer if lives hit 0
  - Updates lives record in Supabase
- **Related Files:**
  - `api/routes/lives.py` → `consume_life()`
  - `core/lives_engine.py` → `lose_life()`

### Regenerate Life
- **Method:** `POST`
- **Path:** `/api/v1/lives/regen`
- **Authentication:** Bearer Token (JWT)
- **Description:** Manually triggers life regeneration (typically via ad-watch or premium purchase)
- **Request Body:** Empty
- **Response:**
  ```json
  {
    "current": "integer (0-3)",
    "max": "integer (3)",
    "can_play": "boolean",
    "next_regen_at": "ISO 8601 timestamp or null",
    "next_regen_in_seconds": "integer or null"
  }
  ```
- **Status Codes:**
  - 200 OK: Life regenerated
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to regenerate lives
- **Side Effects:**
  - Adds 1 life (maximum 3)
  - Resets regen timer if applicable
  - Updates lives record in Supabase
- **Related Files:**
  - `api/routes/lives.py` → `regenerate_life()`
  - `core/lives_engine.py` → `regen_life()`

---

## Formulas & Reference

### Get Formulas
- **Method:** `GET`
- **Path:** `/api/v1/formulas`
- **Authentication:** Bearer Token (JWT)
- **Query Parameters:**
  - `category` (string, optional, default 'all'): 'all', 'basic_derivatives', 'arithmetic_rules', 'basic_trig', 'exp_log', 'chain_rule'
  - `search` (string, optional): Search query to filter formulas
- **Description:** Retrieves formula handbook organized by category with mastery tracking
- **Response (category='all'):**
  ```json
  {
    "category": "all",
    "categories": [
      {
        "id": "string",
        "name": "string",
        "description": "string",
        "formula_count": "integer",
        "mastery_percent": "float (0-100)",
        "formulas": "list[dict]"
      }
    ]
  }
  ```
- **Response (category=specific):**
  ```json
  {
    "category": "string",
    "formulas": [
      {
        "id": "string",
        "name": "string",
        "formula_text": "string (LaTeX)",
        "description": "string",
        "mastery_level": "float (0-100)",
        ...
      }
    ],
    "categories": "list[dict] (all categories)"
  }
  ```
- **Status Codes:**
  - 200 OK: Formulas retrieved
  - 400 Bad Request: Invalid category
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to load formulas
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/formulas.py` → `get_formulas()`
  - `core/formula_handbook_service.py` → `get_catalog_for_user()`

---

## Onboarding

### Get Onboarding Questions
- **Method:** `GET`
- **Path:** `/api/v1/onboarding/questions`
- **Authentication:** Bearer Token (JWT)
- **Description:** Retrieves onboarding diagnostic questions for initial student classification
- **Response:**
  ```json
  {
    "topic": "derivative",
    "total_questions": "integer",
    "questions": [
      {
        "question_id": "string",
        "content": "string",
        "options": "list[string]",
        "type": "string (e.g., 'multiple_choice')"
      }
    ]
  }
  ```
- **Status Codes:** 200 OK
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/onboarding.py` → `get_onboarding_questions()`
  - `core/onboarding_service.py` → `get_questions_for_client()`

### Submit Onboarding
- **Method:** `POST`
- **Path:** `/api/v1/onboarding/submit`
- **Authentication:** Bearer Token (JWT)
- **Request Body:**
  ```json
  {
    "answers": [
      {
        "question_id": "string",
        "selected": "string (option selected)",
        "time_taken_sec": "float or null (optional)"
      }
    ],
    "study_goal": "string or null (optional: 'exam_prep' or 'explore')",
    "daily_minutes": "integer or null (optional: 5-180)"
  }
  ```
- **Description:** Evaluates onboarding answers to classify student level and create study plan
- **Response:**
  ```json
  {
    "user_level": "string ('beginner', 'intermediate', 'advanced')",
    "accuracy_percent": "float (0-100)",
    "study_plan": {
      "daily_minutes": "integer",
      ...
    },
    "message": "string (Vietnamese feedback)",
    "onboarding_summary": {
      "total_questions": "integer",
      "answered_questions": "integer",
      "correct_answers": "integer",
      "avg_response_time_ms": "float"
    }
  }
  ```
- **Status Codes:**
  - 200 OK: Onboarding processed
  - 400 Bad Request: Invalid study_goal or daily_minutes
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to evaluate or persist onboarding
- **Validation:**
  - `study_goal`: must be 'exam_prep', 'explore', or null
  - `daily_minutes`: must be between 5 and 180 (if provided)
- **Side Effects:**
  - Calls onboarding_service to evaluate answers
  - Updates user profile with classification level and study preferences
  - Persists onboarded_at timestamp
- **Related Files:**
  - `api/routes/onboarding.py` → `submit_onboarding()`
  - `models/requests.py` → `OnboardingSubmitRequest`, `OnboardingAnswer`
  - `core/onboarding_service.py` → `evaluate_answers()`
  - `core/supabase_client.py` → `get_user_profile()`, `upsert_user_profile()`

---

## User Profile

### Get User Profile
- **Method:** `GET`
- **Path:** `/api/v1/user/profile`
- **Authentication:** Bearer Token (JWT)
- **Description:** Retrieves complete user profile information
- **Response:**
  ```json
  {
    "user_id": "string",
    "display_name": "string or null",
    "avatar_url": "string or null",
    "user_level": "string ('beginner', 'intermediate', 'advanced')",
    "study_goal": "string or null ('exam_prep' or 'explore')",
    "daily_minutes": "integer",
    "onboarded_at": "ISO 8601 timestamp or null",
    "created_at": "ISO 8601 timestamp",
    "updated_at": "ISO 8601 timestamp"
  }
  ```
- **Status Codes:**
  - 200 OK: Profile retrieved
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to load user profile
- **Side Effects:** None (read-only)
- **Related Files:**
  - `api/routes/user_profile.py` → `get_profile()`
  - `core/supabase_client.py` → `get_user_profile()`

### Update User Profile
- **Method:** `PUT`
- **Path:** `/api/v1/user/profile`
- **Authentication:** Bearer Token (JWT)
- **Request Body:**
  ```json
  {
    "display_name": "string or null (optional)",
    "avatar_url": "string or null (optional)",
    "study_goal": "string or null (optional: 'exam_prep' or 'explore')",
    "daily_minutes": "integer or null (optional: 5-180)"
  }
  ```
- **Description:** Updates user profile fields
- **Response:**
  ```json
  {
    "status": "updated",
    "user_id": "string",
    "display_name": "string or null",
    "avatar_url": "string or null",
    "user_level": "string",
    "study_goal": "string or null",
    "daily_minutes": "integer",
    "onboarded_at": "ISO 8601 timestamp or null",
    "created_at": "ISO 8601 timestamp",
    "updated_at": "ISO 8601 timestamp"
  }
  ```
- **Status Codes:**
  - 200 OK: Profile updated
  - 400 Bad Request: Invalid study_goal or daily_minutes
  - 401 Unauthorized: Missing student identifier
  - 500 Internal Server Error: Failed to update user profile
- **Validation:**
  - `study_goal`: must be 'exam_prep', 'explore', or null
  - `daily_minutes`: must be between 5 and 180 (if provided)
- **Side Effects:**
  - Upserts user profile in Supabase
  - Preserves user_level and onboarded_at from existing record
  - Only updates fields that are explicitly provided
- **Related Files:**
  - `api/routes/user_profile.py` → `update_profile()`
  - `models/requests.py` → `UserProfileUpdateRequest`
  - `core/supabase_client.py` → `get_user_profile()`, `upsert_user_profile()`

---

## WebSocket Connections

### Behavior Telemetry Stream (Empathy Agent)
- **Protocol:** WebSocket
- **Path:** `/ws/v1/behavior/{session_id}`
- **Authentication:** None (consider adding token validation in production)
- **Path Parameters:**
  - `session_id` (string, required): Session UUID
- **Description:** Real-time behavioral telemetry stream for empathy agent particle filter; detects confusion/fatigue and proposes interventions
- **Incoming Message Format (JSON):**
  ```json
  {
    "typing_speed": "float (chars/sec, optional)",
    "correct_rate": "float (0-1, optional)",
    "time_on_task_sec": "float (optional)",
    "pause_frequency": "integer (optional)",
    ...
  }
  ```
- **Outgoing Events:**
  1. **Intervention Proposed** (if uncertainty > threshold):
     ```json
     {
       "event": "intervention_proposed",
       "type": "recovery_mode",
       "confidence": "float (0-1)",
       "session_id": "string",
       "state_summary": {
         "confusion": "float",
         "fatigue": "float",
         "uncertainty": "float"
       }
     }
     ```
  2. **Invalid Payload**:
     ```json
     {
       "event": "invalid_payload",
       "message": "Expected valid JSON payload."
     }
     ```
- **Connection Management:**
  - Client sends telemetry data periodically
  - Server processes via particle_filter and responds with events
  - Connection closes on WebSocketDisconnect
- **Related Files:**
  - `api/ws/behavior.py` → `behavior_websocket()`, `ConnectionManager`
  - `agents/empathy_agent/particle_filter.py` → `process()`
  - `core/config.py` → `hitl_uncertainty_threshold` setting

### Dashboard Stream (Global & Session-Specific)
- **Protocol:** WebSocket
- **Paths:**
  - `/ws/v1/dashboard/stream` — Subscribe to all session updates (global)
  - `/ws/v1/dashboard/stream/{session_id}` — Subscribe to specific session updates
- **Authentication:** None (consider adding token validation in production)
- **Path Parameters (session-specific):**
  - `session_id` (string, required): Session UUID
- **Description:** Server-to-client push notifications for dashboard updates; receives state changes from orchestrator/agents
- **Expected Message Format (client):**
  - Clients typically send keep-alive or subscription confirm (content ignored server-side)
- **Outgoing Events:**
  - Session-specific updates sent to matched session subscribers
  - Global updates sent to all subscribers on `/stream`
  - Stale connections automatically removed on send failure
- **Connection Management:**
  - Multiple clients can subscribe to same session
  - Global listeners (`"*"` origin) receive all session updates
  - Automatic cleanup of disconnected websockets
  - Server manages active connections per session_id
- **Related Files:**
  - `api/ws/dashboard.py` → `websocket_dashboard_all()`, `websocket_dashboard_session()`, `DashboardConnectionManager`
  - `api/routes/orchestrator_runtime.py` → `_build_shared_dependencies()` uses `dashboard_ws_manager`

---

## Data Models Summary

### Request Models
- `SessionCreateRequest`: Create new learning session
- `InteractionRequest`: Session interaction (quiz submit, action)
- `UpdateSessionRequest`: Update session status
- `OrchestratorStepRequest`: Invoke orchestrator step directly
- `QuizSubmitRequest`: Submit quiz answer
- `XpAddRequest`: Award XP for event
- `OnboardingSubmitRequest`: Submit onboarding answers
- `OnboardingAnswer`: Individual onboarding answer
- `UserProfileUpdateRequest`: Update user profile
- `HitlResponseRequest`: HITL intervention response (referenced but not used in shown routes)

### Response Models
- `SessionResponse`: Session creation response
- `InteractionResponse`: Session interaction result
- `FormulaRecommendationResponse`: Formula recommendation
- `DataDrivenResponse`: Multi-agent diagnosis result
- `ConfigResponse`: Configuration response
- `InspectionBeliefResponse`: Belief state for inspection

---

## Authentication & Security

### Bearer Token Authentication
- **Type:** JWT Bearer Token
- **Location:** `Authorization: Bearer <token>` header
- **Extraction:** `get_bearer_token()` dependency
- **User Info:** `get_current_user()` dependency extracts `sub` (student_id) from token

### Quiz Signature Validation
- **Endpoints Requiring Signature:**
  - `POST /api/v1/quiz/submit`
  - `POST /api/v1/sessions/{session_id}/interact` (only when action_type is in QUIZ_LIFE_ACTIONS)
- **Header:** `X-Quiz-Signature`
- **Algorithm:** HMAC (configured secret, TTL typically 300 seconds)
- **Function:** `require_quiz_signature()` middleware, `verify_quiz_signature()` utility
- **Related Files:**
  - `core/security.py` → All auth functions

---

## Environment Configuration

### Settings (from `core/config.py` / `get_settings()`)
- `environment`: Dev/Production mode
- `supabase_url`: Supabase project URL
- `supabase_key`: Supabase API key
- `quiz_hmac_secret`: Secret for quiz signature validation
- `quiz_signature_ttl_seconds`: TTL for quiz signatures (default 300)
- `quiz_daily_session_limit`: Daily quiz session limit per user (default 5)
- `orchestrator_max_sessions`: LRU cache size for orchestrators (default 1024)
- `hitl_uncertainty_threshold`: Uncertainty threshold for HITL intervention (empathy agent)

---

## Rate Limiting & Quotas

1. **Daily Session Limit (Quiz):**
   - Max 5 sessions/day/user in exam_prep mode
   - Enforced at session creation and quiz flow
   - Returns 429 Too Many Requests when exceeded

2. **Daily API Quota:**
   - 20 API calls/day free tier
   - Tracks via token usage in Supabase
   - Resets at midnight Vietnam time (UTC+7)

---

## Error Handling

### Standard HTTP Status Codes
- `200 OK`: Successful request
- `400 Bad Request`: Invalid parameters or validation failure
- `401 Unauthorized`: Missing/invalid authentication
- `403 Forbidden`: Permission denied (e.g., no lives remaining)
- `404 Not Found`: Resource not found
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server-side failure

### Error Response Format
```json
{
  "detail": "string (error code or message)"
}
```

### App-Level Exceptions
- Defined in `core/error/app_exceptions.py`
- Surfaced through Bloc/Cubit error states in frontend
- Consistent error handling via `ApiErrorHandlerMixin` in repositories

---

## Architecture & Dependencies

### Route Organization
- Feature-based routing: one router per feature module
- Mounted on app via `app.include_router()` with prefix and tags
- Shared dependencies: `get_current_user`, `get_bearer_token`, `Depends()`

### Agent System (Orchestrator)
- **Academic Agent:** Bayesian belief tracking for knowledge/skills
- **Empathy Agent:** Particle filter for emotional/cognitive state
- **Strategy Agent:** Q-learning for intervention strategy selection
- **Orchestrator:** Coordinates agents and runs session steps

### Data Access Layer
- `core/supabase_client.py`: Async Supabase calls (RPC preferred)
- `core/memory_store.py`: In-memory session state caching
- `core/llm_service.py`: LLM integration for content generation
- `core/state_manager.py`: State management across agents

### Code Generation
- `freezed` + `json_serializable` for immutable models
- Generate with: `dart run build_runner build --delete-conflicting-outputs`
- `.freezed.dart` and `.g.dart` files committed to repo

---

## Deployment Notes

### CORS Configuration
- Currently allows all origins (`allow_origins=["*"]`)
- **Production:** Restrict to known frontend domains
- In `main.py` lifespan context

### App Startup
- Validates DataPackagesService at startup (Packages 2/3/4 files)
- Fails startup if data packages invalid
- Initializes LRU orchestrator cache

### Graceful Shutdown
- Cleanup orchestrators before eviction
- Best-effort resource teardown

---

## Related Configuration Files

- `configs/agents.yaml`: Agent configurations (Bayesian priors, particle filter params, Q-learning settings)
- `configs/htn_rules.yaml`: HTN planner rules
- `configs/orchestrator.yaml`: Orchestrator settings
- `configs/strategy.yaml`: Strategy agent configuration
- `.env`: Environment variables (secrets, URLs, settings)

---

## Generated Documents

- API Contract Specification: [docs/API_CONTRACT_SPECIFICATION.md](../docs/API_CONTRACT_SPECIFICATION.md)
- Backend Quiz Wiring Guide: [docs/BACKEND_QUIZ_WIRING_GUIDE.md](../docs/BACKEND_QUIZ_WIRING_GUIDE.md)
- API Readiness Checklist: [docs/API_READINESS_CHECKLIST.md](../docs/API_READINESS_CHECKLIST.md)

---

## Summary Statistics

- **Total HTTP Endpoints:** 25
- **Total WebSocket Endpoints:** 2
- **Authentication Required:** Yes (Bearer JWT)
- **Rate Limiting:** Daily session + quota limits
- **Agent System:** 3 agents (Academic, Empathy, Strategy)
- **Supported Platforms:** Android, Web, Windows
- **Primary Data Store:** Supabase (RPC preferred)
- **Caching Strategy:** In-memory orchestrator LRU cache (max 1024 sessions)

