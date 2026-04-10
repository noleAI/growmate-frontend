# Jira Template - Data Team (GrowMate MVP + Phase 2)

Use this file as a copy-paste source when creating Jira issues.
Scope is aligned to 6 Data packages required by UI and API contracts.

---

## EPIC TEMPLATE

Project: DATA
Issue Type: Epic
Epic Name: [GrowMate] Data Readiness for MVP + Phase 2 UI
Summary: Deliver production-ready data contracts, seed datasets, and quality guardrails for quiz, diagnosis, intervention, and runtime decision flows.
Description:
- Goal: Ensure frontend UI and backend responses remain stable and correct for MVP demo and Phase 2 polish.
- Out of scope: model training pipeline, infra scaling, and mobile client code changes.
- In scope: quiz templates, diagnosis scenarios, intervention catalog, thresholds/config, enum freeze, QA golden datasets.
Epic Acceptance Criteria:
1. All 6 stories below are Done.
2. Required seed data is loaded in staging and validated.
3. Backend can return stable payloads without fallback defaults for mandatory fields.
4. Data dictionary is approved by Backend + Frontend.
Labels: growmate, data-contract, mvp, phase2

---

## STORY 1 - QUIZ DATASET (PACKAGE 1)

Project: DATA
Issue Type: Story
Summary: [MVP][Data Pack 1] Seed quiz_question_template for THPT Derivative
Priority: Highest
Labels: growmate, quiz, seed, mvp
Description:
- Objective: Provide clean quiz data for all 3 question types required by UI.
- Target table: public.quiz_question_template.
- Minimum volume: 20 active derivative questions.
- Distribution target: MULTIPLE_CHOICE >= 8, TRUE_FALSE_CLUSTER >= 4, SHORT_ANSWER >= 8.
Data Contract Rules:
1. question_type must be one of MULTIPLE_CHOICE, TRUE_FALSE_CLUSTER, SHORT_ANSWER.
2. part_no must match type: 1/2/3 respectively.
3. payload must include:
- MULTIPLE_CHOICE: options[], correct_option_id, explanation.
- TRUE_FALSE_CLUSTER: sub_questions[], general_hint.
- SHORT_ANSWER: exact_answer, accepted_answers[], explanation.
Subtasks:
1. Prepare seed SQL from CSV source.
2. Validate payload JSON schema for each record.
3. Load into staging and verify query filters by subject=math, exam_year=2026, is_active=true.
Acceptance Criteria:
1. At least 20 active records inserted and queryable.
2. 0 invalid payload rows.
3. No constraint violations in quiz schema.
4. Frontend fetch list call returns non-empty data and mixed question types.
Deliverables:
- SQL seed file.
- Row count report by question_type.
- Validation report (invalid count = 0).
Estimate: 3 SP
Dependencies: None

---

## STORY 2 - DIAGNOSIS SCENARIOS (PACKAGE 2)

Project: DATA
Issue Type: Story
Summary: [MVP][Data Pack 2] Build diagnosis scenario dataset for normal/hitl/recovery
Priority: Highest
Labels: growmate, diagnosis, mvp, scenario
Description:
- Objective: Provide stable diagnosis payload content for major UI decision branches.
- Required scenarios: normal_success, hitl_pending, recovery_mode, fallback_safe.
- Fields must be complete for API mapping.
Mandatory Fields Per Scenario:
1. diagnosisId
2. title
3. gapAnalysis
4. diagnosisReason
5. strengths[]
6. needsReview[]
7. confidence (0..1)
8. riskLevel (low|medium|high)
9. mode (normal|recovery|hitl_pending)
10. requiresHITL (boolean)
11. nextSuggestedTopic
12. interventionPlan[]
Subtasks:
1. Draft 4 scenario payloads.
2. Review wording quality for Vietnamese and English fallback quality.
3. Validate confidence/risk/mode consistency.
Acceptance Criteria:
1. All 4 scenarios pass backend schema validation.
2. No null values in mandatory fields.
3. requiresHITL=true appears at least in hitl_pending scenario.
4. mode=recovery appears at least in recovery scenario.
Deliverables:
- JSON scenario bundle.
- Mapping sheet: scenario -> expected UI branch.
Estimate: 2 SP
Dependencies: Story 5 (enum freeze) should be aligned before final sign-off.

---

## STORY 3 - INTERVENTION PLAN CATALOG (PACKAGE 3)

Project: DATA
Issue Type: Story
Summary: [MVP][Data Pack 3] Create intervention option catalog for academic and recovery flows
Priority: High
Labels: growmate, intervention, catalog, mvp
Description:
- Objective: Provide intervention plans that UI can render directly.
- Required option fields: id, title, type.
- Required type coverage: review, practice, recovery, breath, grounding.
Subtasks:
1. Create canonical intervention option list.
2. Tag each option with deterministic type.
3. Provide recommended defaults for each diagnosis mode.
Acceptance Criteria:
1. Every option has non-empty id, title, type.
2. No duplicate id values.
3. At least 2 options for normal mode and 2 options for recovery mode.
4. skip_once fallback mapping documented.
Deliverables:
- JSON catalog file.
- Mode-to-option mapping table.
Estimate: 2 SP
Dependencies: Story 2

---

## STORY 4 - THRESHOLDS AND EXPERT CONFIG (PACKAGE 4)

Project: DATA
Issue Type: Story
Summary: [MVP/Phase2][Data Pack 4] Define runtime thresholds and expert config for decisions
Priority: High
Labels: growmate, config, threshold, hitl, recovery
Description:
- Objective: Centralize thresholds used by backend decision logic.
- Target storage: expert config payload (or equivalent config table).
- Required knobs:
1. idle_time_high_seconds
2. uncertainty_hitl_threshold
3. risk level mapping from uncertainty/confidence
4. fallback strategy priority
Subtasks:
1. Propose threshold defaults from MVP assumptions.
2. Run quick sanity check using scenario logs.
3. Publish versioned config (v1).
Acceptance Criteria:
1. Config can be loaded without code changes.
2. Version id and created_at are tracked.
3. Decision output is reproducible for same input.
Deliverables:
- Config JSON v1.
- Changelog note for each threshold.
Estimate: 3 SP
Dependencies: Story 2, Story 6

---

## STORY 5 - ENUM FREEZE + DATA DICTIONARY (PACKAGE 5)

Project: DATA
Issue Type: Story
Summary: [MVP][Data Pack 5] Freeze enums and publish data dictionary
Priority: Highest
Labels: growmate, enum, dictionary, contract, mvp
Description:
- Objective: Prevent UI breakage due to naming drift.
- Freeze these values:
1. question_type: MULTIPLE_CHOICE, TRUE_FALSE_CLUSTER, SHORT_ANSWER
2. mode: normal, recovery, hitl_pending
3. riskLevel: low, medium, high
4. intervention type: review, practice, recovery, breath, grounding
5. event names: Plan Accepted, Plan Rejected
Subtasks:
1. Publish dictionary table: field, type, allowed values, example.
2. Cross-check with backend serializers.
3. Sign-off with frontend owner.
Acceptance Criteria:
1. Single source of truth document is published.
2. Backend and Data agree on exact enum values.
3. No unresolved naming conflicts.
Deliverables:
- Data dictionary v1 (markdown or sheet).
- Enum freeze approval comment in Jira.
Estimate: 1 SP
Dependencies: None

---

## STORY 6 - QA GOLDEN DATASET (PACKAGE 6)

Project: DATA
Issue Type: Story
Summary: [MVP/Phase2][Data Pack 6] Build golden datasets for E2E QA and demo regression
Priority: High
Labels: growmate, qa, regression, phase2
Description:
- Objective: Enable deterministic QA across critical branches.
- Required E2E cases:
1. Correct answer -> normal diagnosis -> intervention academic.
2. High uncertainty -> HITL pending -> confirm path.
3. High idle signal -> recovery mode.
4. Fallback safe when plan is missing/partial.
Subtasks:
1. Build input and expected output pairs.
2. Tag each case with expected UI branch.
3. Add version id for regression tracking.
Acceptance Criteria:
1. All 4 cases are executable in staging.
2. Expected outputs are deterministic.
3. QA can validate pass/fail without manual interpretation.
Deliverables:
- Golden dataset JSON.
- Expected outcome matrix.
- Regression checklist.
Estimate: 3 SP
Dependencies: Stories 1-5

---

## GLOBAL DEFINITION OF DONE (APPLIES TO ALL 6 STORIES)

1. Data loaded in staging successfully.
2. Contract validation report attached in Jira.
3. No enum mismatch with backend.
4. Frontend smoke flow passes for quiz -> diagnosis -> intervention -> session complete.
5. Handover note includes rollback plan for seed/config changes.

---

## OPTIONAL SUBTASK TEMPLATE (COPY/PASTE)

Issue Type: Sub-task
Summary: [Data] <short action>
Description:
- Input:
- Output:
- Validation query:
- Risks:
Acceptance Criteria:
1. <clear measurable condition>
2. <clear measurable condition>

