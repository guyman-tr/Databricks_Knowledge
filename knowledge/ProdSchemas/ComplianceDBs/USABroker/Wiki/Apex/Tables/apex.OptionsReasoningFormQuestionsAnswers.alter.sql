-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Apex/Tables/Apex.OptionsReasoningFormQuestionsAnswers.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers ALTER COLUMN ReasoningFormID COMMENT 'FK to Apex.OptionsReasoningForm. Links this question-answer pair to its parent reasoning form. Part of the UNIQUE constraint with KycQuestionID.';
ALTER TABLE main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers ALTER COLUMN KycQuestionID COMMENT 'Identifier of the KYC (Know Your Customer) suitability question that was changed. References the suitability questionnaire system (external). Part of the UNIQUE constraint with ReasoningFormID.';
ALTER TABLE main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers ALTER COLUMN ReasoningFormAnswerID COMMENT 'The customer''s selected reasoning for changing this question. Implicit FK to Dictionary.OptionsReasoningFormAnswers: 1=Other, 2=Incorrect Selection, 3=Changed Mind, 4=Lifestyle Change. See [Options Reasoning Form Answers](_glossary.md#options-reasoning-form-answers). NULL until the customer provides their reasoning.';
ALTER TABLE main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers ALTER COLUMN OldKycAnswerID COMMENT 'The answer ID the customer previously had for this KYC question before the change. Provides the "before" state for the audit trail. A value of 0 indicates the question was not previously answered.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:28 UTC
-- Statements: 4/4 succeeded
-- ====================
